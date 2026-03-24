import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/admob_ids.dart';

class AdService with WidgetsBindingObserver {
  static const Duration _minInterstitialInterval = Duration(minutes: 2);
  static const Duration _minAppOpenInterval = Duration(hours: 4);

  InterstitialAd? _interstitialAd;
  bool _isShowingInterstitial = false;
  DateTime? _lastInterstitialShown;

  AppOpenAd? _appOpenAd;
  bool _isShowingAppOpen = false;
  DateTime? _lastAppOpenShown;
  DateTime? _suppressAppOpenUntil;
  bool _pendingAppOpen = false;
  bool _isAppForeground = true;
  bool _adsEnabled = true;

  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    _isAppForeground =
        lifecycle == null || lifecycle == AppLifecycleState.resumed;
    _pendingAppOpen = _isAppForeground;
    if (_adsEnabled) {
      _loadInterstitial();
      _loadAppOpen();
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _interstitialAd?.dispose();
    _appOpenAd?.dispose();
  }

  Future<void> showInterstitialIfAvailable() async {
    if (!_adsEnabled) return;
    if (_isShowingInterstitial) return;
    if (_interstitialAd == null) {
      _loadInterstitial();
      return;
    }
    if (_lastInterstitialShown != null &&
        DateTime.now().difference(_lastInterstitialShown!) <
            _minInterstitialInterval) {
      return;
    }

    final completer = Completer<void>();
    _isShowingInterstitial = true;
    _suppressAppOpenUntil = DateTime.now().add(const Duration(seconds: 20));
    _pendingAppOpen = false;
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _isShowingInterstitial = false;
        _lastInterstitialShown = DateTime.now();
        _loadInterstitial();
        completer.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        _isShowingInterstitial = false;
        _loadInterstitial();
        completer.complete();
      },
    );
    _interstitialAd!.show();
    await completer.future;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _isAppForeground = true;
      if (_adsEnabled) {
        _pendingAppOpen = true;
        _showAppOpenIfAvailable();
      }
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _isAppForeground = false;
    }
  }

  void _loadInterstitial() {
    if (!_adsEnabled) return;
    InterstitialAd.load(
      adUnitId: AdMobIds.interstitialAdUnitId(),
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) => _interstitialAd = ad,
        onAdFailedToLoad: (error) => _interstitialAd = null,
      ),
    );
  }

  void _loadAppOpen() {
    if (!_adsEnabled) return;
    if (_appOpenAd != null) return;
    AppOpenAd.load(
      adUnitId: AdMobIds.appOpenAdUnitId(),
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _showAppOpenIfAvailable();
        },
        onAdFailedToLoad: (error) => _appOpenAd = null,
      ),
    );
  }

  void _showAppOpenIfAvailable() {
    if (!_adsEnabled) return;
    if (!_pendingAppOpen || !_isAppForeground) {
      return;
    }
    if (_isShowingAppOpen || _isShowingInterstitial) {
      return;
    }
    if (_suppressAppOpenUntil != null &&
        DateTime.now().isBefore(_suppressAppOpenUntil!)) {
      _pendingAppOpen = false;
      return;
    }
    if (_lastAppOpenShown != null &&
        DateTime.now().difference(_lastAppOpenShown!) < _minAppOpenInterval) {
      _pendingAppOpen = false;
      return;
    }
    if (_appOpenAd == null) {
      _loadAppOpen();
      return;
    }

    _pendingAppOpen = false;
    _isShowingAppOpen = true;
    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _appOpenAd = null;
        _isShowingAppOpen = false;
        _lastAppOpenShown = DateTime.now();
        _loadAppOpen();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _appOpenAd = null;
        _isShowingAppOpen = false;
        _loadAppOpen();
      },
    );
    _appOpenAd!.show();
  }

  void setAdsEnabled(bool enabled) {
    if (_adsEnabled == enabled) return;
    _adsEnabled = enabled;
    if (!enabled) {
      _interstitialAd?.dispose();
      _interstitialAd = null;
      _appOpenAd?.dispose();
      _appOpenAd = null;
      _pendingAppOpen = false;
      _isShowingAppOpen = false;
      _isShowingInterstitial = false;
      return;
    }
    _loadInterstitial();
    _loadAppOpen();
  }
}
