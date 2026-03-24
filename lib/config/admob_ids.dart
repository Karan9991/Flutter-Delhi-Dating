import 'package:flutter/foundation.dart';

class AdMobIds {
  AdMobIds._();

  // Test IDs (Google-provided)
  static const String androidAppTestId =
      'ca-app-pub-3940256099942544~3347511713';
  static const String androidBannerTestId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String androidInterstitialTestId =
      'ca-app-pub-3940256099942544/1033173712';
  static const String androidAppOpenTestId =
      'ca-app-pub-3940256099942544/3419835294';

  // Production IDs (Delhi Dating)
  static const String androidAppId = 'ca-app-pub-4228375379782984~5713814187';
  static const String androidBannerId =
      'ca-app-pub-4228375379782984/5574520871';
  static const String androidInterstitialId =
      'ca-app-pub-4228375379782984/1595180168';
  static const String androidAppOpenId =
      'ca-app-pub-4228375379782984/1427659205';

  static String bannerAdUnitId() =>
      kReleaseMode ? androidBannerId : androidBannerTestId;

  static String interstitialAdUnitId() =>
      kReleaseMode ? androidInterstitialId : androidInterstitialTestId;

  static String appOpenAdUnitId() =>
      kReleaseMode ? androidAppOpenId : androidAppOpenTestId;
}
