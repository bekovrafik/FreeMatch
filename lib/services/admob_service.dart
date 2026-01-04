// import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
