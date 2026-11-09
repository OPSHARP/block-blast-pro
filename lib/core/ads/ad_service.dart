// Google AdMob Integration Service for Block Blast Pro
// Manages Banner, Interstitial, and Rewarded live ads with platform guards and cooldowns

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../billing/billing_service.dart';

class AdService extends ChangeNotifier {
  // Google Official Test Ad Unit IDs (Default for public open-source verification)
  static const String testAndroidBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String testAndroidInterstitialId = 'ca-app-pub-3940256099942544/1033173712';
  static const String testAndroidRewardedId = 'ca-app-pub-3940256099942544/5224354917';

  // Configurable Ad Unit IDs via environment variables, defaulting to safe Google test IDs
  static const String androidBannerId = String.fromEnvironment(
    'ADMOB_ANDROID_BANNER_ID',
    defaultValue: testAndroidBannerId,
  );
  static const String androidInterstitialId = String.fromEnvironment(
    'ADMOB_ANDROID_INTERSTITIAL_ID',
    defaultValue: testAndroidInterstitialId,
  );
  static const String androidRewardedId = String.fromEnvironment(
    'ADMOB_ANDROID_REWARDED_ID',
    defaultValue: testAndroidRewardedId,
  );

  // iOS fallback (defaults to official test IDs)
  static const String iosBannerId = String.fromEnvironment(
    'ADMOB_IOS_BANNER_ID',
    defaultValue: 'ca-app-pub-3940256099942544/2934735716',
  );
  static const String iosInterstitialId = String.fromEnvironment(
    'ADMOB_IOS_INTERSTITIAL_ID',
    defaultValue: 'ca-app-pub-3940256099942544/4411468910',
  );
  static const String iosRewardedId = String.fromEnvironment(
    'ADMOB_IOS_REWARDED_ID',
    defaultValue: 'ca-app-pub-3940256099942544/1712485313',
  );

  final BillingService billingService;

  bool _isInitialized = false;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  bool _isInterstitialLoading = false;
  bool _isRewardedLoading = false;
  DateTime _lastInterstitialTime = DateTime.fromMillisecondsSinceEpoch(0);

  // Play Store Ad Experience Guidelines: 60s minimum interval between interstitial ads
  static const Duration _interstitialCooldown = Duration(seconds: 60);

  bool get isSupportedPlatform => !kIsWeb && (Platform.isAndroid || Platform.isIOS);
  bool get isInitialized => _isInitialized;
  bool get isInterstitialReady => _interstitialAd != null;
  bool get isRewardedReady => _rewardedAd != null;

  String get bannerAdUnitId =>
      kIsWeb ? '' : (Platform.isAndroid ? androidBannerId : iosBannerId);
  String get interstitialAdUnitId =>
      kIsWeb ? '' : (Platform.isAndroid ? androidInterstitialId : iosInterstitialId);
  String get rewardedAdUnitId =>
      kIsWeb ? '' : (Platform.isAndroid ? androidRewardedId : iosRewardedId);

  AdService({required this.billingService});

  Future<void> initialize() async {
    if (!isSupportedPlatform) {
      debugPrint('AdService: AdMob not supported on this platform. Mock mode enabled.');
      _isInitialized = true;
      return;
    }

    try {
      final initStatus = await MobileAds.instance.initialize();
      _isInitialized = true;
      debugPrint('AdService: MobileAds initialized successfully.');

      // Log mediation adapter statuses (verify Unity Ads adapter is loaded)
      initStatus.adapterStatuses.forEach((adapter, status) {
        debugPrint('AdService: Mediation adapter [$adapter] → ${status.state.name} | ${status.description}');
      });

      // Preload ads if ads are not removed
      if (!billingService.isAdsRemoved) {
        preloadInterstitialAd();
        preloadRewardedAd();
      }

      // Listen to billing updates to dispose ads if purchased
      billingService.addListener(_onBillingChanged);
    } catch (e) {
      debugPrint('AdService initialize error: $e');
    }
  }

  void _onBillingChanged() {
    if (billingService.isAdsRemoved) {
      _interstitialAd?.dispose();
      _interstitialAd = null;
      notifyListeners();
    }
  }

  // Preload Interstitial Ad
  void preloadInterstitialAd() {
    if (!isSupportedPlatform || billingService.isAdsRemoved || _isInterstitialLoading) return;
    if (_interstitialAd != null) return;

    _isInterstitialLoading = true;
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
          debugPrint('AdService: Interstitial ad loaded.');
          notifyListeners();
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          _isInterstitialLoading = false;
          debugPrint('AdService: Interstitial failed to load: ${error.message}');
          notifyListeners();
        },
      ),
    );
  }

  // Show Interstitial Ad (with frequency cooldown and ad removal check)
  void showInterstitialAd({VoidCallback? onDismissed}) {
    if (billingService.isAdsRemoved || !isSupportedPlatform) {
      onDismissed?.call();
      return;
    }

    // Cooldown check to prevent aggressive ad spamming
    final now = DateTime.now();
    if (now.difference(_lastInterstitialTime) < _interstitialCooldown) {
      debugPrint('AdService: Interstitial skipped due to frequency cooldown.');
      onDismissed?.call();
      return;
    }

    if (_interstitialAd == null) {
      debugPrint('AdService: Interstitial not ready.');
      preloadInterstitialAd();
      onDismissed?.call();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _lastInterstitialTime = DateTime.now();
        preloadInterstitialAd();
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('AdService: Failed to show interstitial: ${error.message}');
        ad.dispose();
        _interstitialAd = null;
        preloadInterstitialAd();
        onDismissed?.call();
      },
    );

    _interstitialAd!.show();
  }

  bool _isAdBlockDetected = false;
  bool get isAdBlockDetected => _isAdBlockDetected;

  /// Detects whether an ad-blocker or ad-filtering Private DNS (e.g. AdGuard, NextDNS)
  /// is intercepting Google AdMob network domains while internet is active.
  Future<bool> isAdBlockActive() async {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) return false;
    try {
      // 1. Check general internet connectivity first
      final general = await InternetAddress.lookup('clients3.google.com')
          .timeout(const Duration(milliseconds: 1500));
      if (general.isEmpty) return false; // Offline

      // 2. Check Google AdMob domain
      final adCheck = await InternetAddress.lookup('pagead2.googlesyndication.com')
          .timeout(const Duration(milliseconds: 1500));
      if (adCheck.isEmpty) {
        _isAdBlockDetected = true;
        return true;
      }
      for (final addr in adCheck) {
        if (addr.address == '0.0.0.0' || addr.address == '127.0.0.1' || addr.address == '::1') {
          _isAdBlockDetected = true;
          return true; // Sinkholed by DNS
        }
      }
      _isAdBlockDetected = false;
      return false;
    } catch (_) {
      // Ad domain lookup failed (e.g. NXDOMAIN, Connection Refused). Check if general web is reachable.
      try {
        final fallback = await InternetAddress.lookup('www.google.com')
            .timeout(const Duration(milliseconds: 1500));
        if (fallback.isNotEmpty) {
          _isAdBlockDetected = true;
          return true; // General internet is up, but AdMob is blocked!
        }
      } catch (_) {
        return false; // User is simply offline
      }
      return false;
    }
  }

  /// Displays a soft, non-intrusive compliance warning explaining that the reward ad could
  /// not be served due to Private DNS or an AdBlocker, with an option to unlock VIP ($4.99/mo).
  static Future<void> showAdBlockWarningDialog(
    BuildContext context, {
    BillingService? billingService,
  }) async {
    if (!context.mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E2235),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFFFF9100), width: 1.5),
        ),
        title: const Row(
          children: [
            Icon(Icons.shield_outlined, color: Color(0xFFFF9100), size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Ad Unavailable / Blocked',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Could not load the sponsored reward video.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: const Text(
                '• If you are using Private DNS (e.g. AdGuard, NextDNS) or an AdBlocker / VPN, please disable it temporarily to earn free rewards.\n\n• Or enjoy 100% ad-free gameplay with unlimited perks via VIP.',
                style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('GOT IT', style: TextStyle(color: Colors.white54)),
          ),
          if (billingService != null && !billingService.isAdsRemoved)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF9100),
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                billingService.buyRemoveAds();
              },
              child: const Text('GO VIP (\$4.99/MO)', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  // Preload Rewarded Ad
  void preloadRewardedAd() {
    if (!isSupportedPlatform || _isRewardedLoading) return;
    if (_rewardedAd != null) return;

    _isRewardedLoading = true;
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedLoading = false;
          _isAdBlockDetected = false;
          debugPrint('AdService: Rewarded ad loaded.');
          notifyListeners();
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isRewardedLoading = false;
          debugPrint('AdService: Rewarded ad failed to load: ${error.message}');
          // Probe for DNS ad-blocking in background
          isAdBlockActive().then((blocked) {
            _isAdBlockDetected = blocked;
          });
          notifyListeners();
        },
      ),
    );
  }

  // Show Rewarded Ad
  void showRewardedAd({
    required Function(int amount, String type) onUserEarnedReward,
    VoidCallback? onDismissed,
    BuildContext? context,
  }) {
    // If not supported platform (Web/Desktop), simulate reward grant
    if (!isSupportedPlatform) {
      debugPrint('AdService: Simulating rewarded ad completion on desktop/web.');
      onUserEarnedReward(1, 'revive');
      onDismissed?.call();
      return;
    }

    if (_rewardedAd == null) {
      debugPrint('AdService: Rewarded ad not ready. Preloading for next attempt.');
      preloadRewardedAd();
      onDismissed?.call();

      if (context != null && context.mounted) {
        isAdBlockActive().then((isBlocked) {
          if (isBlocked && context.mounted) {
            showAdBlockWarningDialog(context, billingService: billingService);
          } else if (context.mounted) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Video ad is loading. Please try again in a moment.'),
                duration: Duration(seconds: 2),
                backgroundColor: Color(0xFF1E2235),
              ),
            );
          }
        });
      }
      return;
    }

    bool earned = false;
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        preloadRewardedAd();
        if (earned) {
          onUserEarnedReward(1, 'revive');
        }
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('AdService: Failed to show rewarded: ${error.message}');
        ad.dispose();
        _rewardedAd = null;
        preloadRewardedAd();
        onDismissed?.call();

        if (context != null && context.mounted) {
          isAdBlockActive().then((isBlocked) {
            if (isBlocked && context.mounted) {
              showAdBlockWarningDialog(context, billingService: billingService);
            }
          });
        }
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        earned = true;
        debugPrint('AdService: User earned reward: ${reward.amount} ${reward.type}');
      },
    );
  }

  // Create Banner Ad with custom or default size
  BannerAd? createBannerAd({
    required Function() onAdLoaded,
    required Function(LoadAdError error) onAdFailed,
    AdSize size = AdSize.banner,
  }) {
    if (!isSupportedPlatform || billingService.isAdsRemoved) return null;

    final banner = BannerAd(
      adUnitId: bannerAdUnitId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('AdService: Banner ad loaded (${size.width}x${size.height}).');
          onAdLoaded();
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('AdService: Banner ad failed to load: ${error.message}');
          ad.dispose();
          onAdFailed(error);
        },
      ),
    );

    banner.load();
    return banner;
  }

  // Create Adaptive Banner Ad for presentation widgets (full-width, higher revenue)
  Future<BannerAd?> createAdaptiveBannerAd({
    required int screenWidth,
    required Function() onAdLoaded,
    required Function(LoadAdError error) onAdFailed,
  }) async {
    if (!isSupportedPlatform || billingService.isAdsRemoved) return null;

    // Use anchored adaptive banner for full-width responsive ads (20-30% higher eCPM)
    final AdSize? adaptiveSize =
        await AdSize.getLargeAnchoredAdaptiveBannerAdSize(screenWidth);

    return createBannerAd(
      size: adaptiveSize ?? AdSize.banner,
      onAdLoaded: onAdLoaded,
      onAdFailed: onAdFailed,
    );
  }

  @override
  void dispose() {
    billingService.removeListener(_onBillingChanged);
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }
}
