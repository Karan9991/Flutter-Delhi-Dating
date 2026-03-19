import 'package:flutter/foundation.dart';

class AdMobIds {
  AdMobIds._();

  // TODO: Replace these with your real AdMob IDs before release.
  static const String androidAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const String androidBannerTestId =
      'ca-app-pub-3940256099942544/6300978111';

  static String bannerAdUnitId() {
    if (kReleaseMode) {
      return 'ca-app-pub-XXXXXXXXXXXXXXXX/NNNNNNNNNN';
    }
    return androidBannerTestId;
  }
}
