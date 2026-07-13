import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../utils/platform_support.dart';

/// Google 공식 테스트 광고 단위 ID를 사용합니다.
class AdService {
  static const String _androidBannerId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _iosBannerId = 'ca-app-pub-3940256099942544/2934735716';
  static const String _androidInterstitialId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String _iosInterstitialId =
      'ca-app-pub-3940256099942544/4411468910';

  static String get bannerAdUnitId =>
      defaultTargetPlatform == TargetPlatform.iOS
          ? _iosBannerId
          : _androidBannerId;

  static String get interstitialAdUnitId =>
      defaultTargetPlatform == TargetPlatform.iOS
          ? _iosInterstitialId
          : _androidInterstitialId;

  static Future<void> initialize() async {
    if (!isAdMobSupported) return;
    await MobileAds.instance.initialize();
  }

  static BannerAd createBannerAd({required VoidCallback onLoaded}) {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => onLoaded(),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    )..load();
  }

  static void loadInterstitialAd({
    required void Function(InterstitialAd ad) onLoaded,
    VoidCallback? onFailed,
  }) {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: onLoaded,
        onAdFailedToLoad: (_) => onFailed?.call(),
      ),
    );
  }
}
