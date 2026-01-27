// import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import '../constants/ad_constants.dart';

final admobServiceProvider = Provider((ref) => AdMobService());

class AdMobService {
  Future<void> initialize() async {
    await MobileAds.instance.initialize();
  }

  NativeAd createNativeAd({
    required Function(Ad) onAdLoaded,
    required Function(Ad, LoadAdError) onAdFailedToLoad,
  }) {
    return NativeAd(
      adUnitId: AdConstants.nativeAdUnitId,
      factoryId:
          'listTile', // Must match Android factory ID if using custom templates
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailedToLoad,
      ),
    );
  }

  void loadRewardedInterstitialAd({
    required Function(RewardedInterstitialAd) onAdLoaded,
    required Function(LoadAdError) onAdFailedToLoad,
  }) {
    RewardedInterstitialAd.load(
      adUnitId: AdConstants.rewardedInterstitialAdUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: onAdLoaded,
        onAdFailedToLoad: onAdFailedToLoad,
      ),
    );
  }
}

class AppOpenAdManager {
  String adUnitId = AdConstants.appOpenAdUnitId;
  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;
  DateTime? _appOpenLoadTime;

  /// Load an AppOpenAd.
  void loadAd() {
    AppOpenAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('AppOpenAd loaded');
          _appOpenAd = ad;
          _appOpenLoadTime = DateTime.now();
        },
        onAdFailedToLoad: (error) {
          debugPrint('AppOpenAd failed to load: $error');
        },
      ),
    );
  }

  /// Whether an ad is available to be shown.
  bool get isAdAvailable {
    return _appOpenAd != null;
  }

  /// Check if ad is expired (4 hours)
  bool get _isAdExpired {
    return _appOpenLoadTime != null &&
        DateTime.now().difference(_appOpenLoadTime!) > const Duration(hours: 4);
  }

  /// Shows the ad, if one exists and is not already being shown.
  /// If the ad is already being shown or is expired, this method invokes
  /// [onAdDismissed] immediately.
  void showAdIfAvailable() {
    if (!isAdAvailable || _isShowingAd) {
      debugPrint('Tried to show ad before available or while showing.');
      loadAd();
      return;
    }

    if (_isAdExpired) {
      debugPrint('Ad expired. Reloading.');
      _appOpenAd = null;
      loadAd();
      return;
    }

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
        debugPrint('$ad onAdShowedFullScreenContent');
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('$ad onAdFailedToShowFullScreenContent: $error');
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('$ad onAdDismissedFullScreenContent');
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAd();
      },
    );

    _appOpenAd!.show();
  }
}

final appOpenAdManagerProvider = Provider((ref) => AppOpenAdManager());
