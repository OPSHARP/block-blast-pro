import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:block_blast_pro/data/repositories/prefs_save_repository.dart';
import 'package:block_blast_pro/core/billing/billing_service.dart';
import 'package:block_blast_pro/core/ads/ad_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BillingService Tests', () {
    late PrefsSaveRepository repo;
    late BillingService billingService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      repo = PrefsSaveRepository();
      billingService = BillingService(saveRepository: repo);
      await billingService.initialize();
    });

    test('initial state has ads enabled (isAdsRemoved = false)', () {
      expect(billingService.isAdsRemoved, isFalse);
    });

    test('buyRemoveAds succeeds and sets isAdsRemoved = true', () async {
      final success = await billingService.buyRemoveAds();
      expect(success, isTrue);
      expect(billingService.isAdsRemoved, isTrue);

      // Verify persisted offline
      final persisted = await repo.loadAdsRemoved();
      expect(persisted, isTrue);
    });

    test('displays \$4.99 / month remove ads subscription price', () {
      expect(BillingService.defaultPriceString, '\$4.99 / month');
      expect(billingService.displayPrice, '\$4.99 / month');
      expect(BillingService.removeAdsSubscriptionId, 'remove_ads_monthly');
    });

    test('restorePurchases restores previous state', () async {
      await repo.saveAdsRemoved(true);
      await billingService.restorePurchases();
      expect(billingService.isAdsRemoved, isTrue);
    });
  });

  group('AdService Tests', () {
    late PrefsSaveRepository repo;
    late BillingService billingService;
    late AdService adService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      repo = PrefsSaveRepository();
      billingService = BillingService(saveRepository: repo);
      await billingService.initialize();
      adService = AdService(billingService: billingService);
      await adService.initialize();
    });

    test('exposes live production AdMob ad unit IDs for Android and iOS fallbacks', () {
      expect(AdService.androidBannerId, 'ca-app-pub-6089131009548737/6672673336');
      expect(AdService.androidInterstitialId, 'ca-app-pub-6089131009548737/4046509998');
      expect(AdService.androidRewardedId, 'ca-app-pub-6089131009548737/2733428322');

      expect(AdService.iosBannerId, 'ca-app-pub-3940256099942544/2934735716');
      expect(AdService.iosInterstitialId, 'ca-app-pub-3940256099942544/4411468910');
      expect(AdService.iosRewardedId, 'ca-app-pub-3940256099942544/1712485313');
    });

    test('suppresses banner ad creation when ads are removed', () async {
      await billingService.setAdsRemoved(true);
      final banner = adService.createBannerAd(
        onAdLoaded: () {},
        onAdFailed: (err) {},
      );
      expect(banner, isNull);
    });

    test('rewarded ad triggers onUserEarnedReward callback on simulated platform', () {
      bool rewardGranted = false;
      adService.showRewardedAd(
        onUserEarnedReward: (amount, type) {
          rewardGranted = true;
          expect(type, 'revive');
        },
      );
      expect(rewardGranted, isTrue);
    });

    test('interstitial ad is suppressed when ads are removed', () async {
      await billingService.setAdsRemoved(true);
      bool dismissed = false;
      adService.showInterstitialAd(
        onDismissed: () {
          dismissed = true;
        },
      );
      expect(dismissed, isTrue);
    });

    test('isAdBlockActive returns false on desktop/testing environment', () async {
      final isBlocked = await adService.isAdBlockActive();
      expect(isBlocked, isFalse);
      expect(adService.isAdBlockDetected, isFalse);
    });
  });
}
