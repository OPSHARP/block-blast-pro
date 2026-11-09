// Adaptive Glassmorphic Banner Ad Widget powered by Google Mobile Ads
// Full-width adaptive banner for higher fill rates and eCPM
// Compliant with Play Store policies: automatically hidden when Remove Ads is active

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../core/ads/ad_service.dart';

class AdBannerWidget extends StatefulWidget {
  final AdService adService;

  const AdBannerWidget({super.key, required this.adService});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_bannerAd == null && !_isLoading) {
      _initBanner();
    }
  }

  Future<void> _initBanner() async {
    if (widget.adService.billingService.isAdsRemoved ||
        !widget.adService.isSupportedPlatform) {
      return;
    }

    _isLoading = true;
    final screenWidth = MediaQuery.sizeOf(context).width.truncate();

    final banner = await widget.adService.createAdaptiveBannerAd(
      screenWidth: screenWidth,
      onAdLoaded: () {
        if (mounted) {
          setState(() {
            _isLoaded = true;
          });
        }
      },
      onAdFailed: (error) {
        if (mounted) {
          setState(() {
            _isLoaded = false;
          });
        }
      },
    );

    if (mounted) {
      setState(() {
        _bannerAd = banner;
        _isLoading = false;
      });
    } else {
      banner?.dispose();
    }
  }

  @override
  void didUpdateWidget(covariant AdBannerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.adService.billingService.isAdsRemoved && _bannerAd != null) {
      _bannerAd?.dispose();
      _bannerAd = null;
      setState(() {
        _isLoaded = false;
      });
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.adService.billingService.isAdsRemoved ||
        !widget.adService.isSupportedPlatform ||
        !_isLoaded ||
        _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: AppColors.borderSubtle,
          width: 0.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}
