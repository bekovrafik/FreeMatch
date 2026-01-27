import 'dart:io';
import 'package:flutter/foundation.dart';

class AdConstants {
  static String get nativeAdUnitId {
    if (Platform.isAndroid) {
      return kReleaseMode
          ? 'ca-app-pub-7841436065695087/7106444683' // Production
          : 'ca-app-pub-3940256099942544/2247696110'; // Test ID
    } else if (Platform.isIOS) {
      return kReleaseMode
          ? 'ca-app-pub-7841436065695087/1059911084' // Production
          : 'ca-app-pub-3940256099942544/3986624511'; // Test ID
    } else if (!kReleaseMode) {
      return 'ca-app-pub-3940256099942544/9257395921'; // Fallback Test ID
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static String get rewardedInterstitialAdUnitId {
    if (Platform.isAndroid) {
      return kReleaseMode
          ? 'ca-app-pub-7841436065695087/6044692180' // Production
          : 'ca-app-pub-3940256099942544/5354046379'; // Test ID
    } else if (Platform.isIOS) {
      return kReleaseMode
          ? 'ca-app-pub-7841436065695087/4785265616' // Production
          : 'ca-app-pub-3940256099942544/6978759866'; // Test ID
    } else if (!kReleaseMode) {
      return 'ca-app-pub-3940256099942544/9257395921'; // Fallback Test ID
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static String get appOpenAdUnitId {
    if (Platform.isAndroid) {
      return kReleaseMode
          ? 'ca-app-pub-7841436065695087/6322525174' // Production
          : 'ca-app-pub-3940256099942544/9257395921'; // Test ID
    } else if (Platform.isIOS) {
      return kReleaseMode
          ? 'ca-app-pub-7841436065695087/4734111336' // Production
          : 'ca-app-pub-3940256099942544/5575463023'; // Test ID
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
}
