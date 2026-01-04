import 'dart:io';
import 'package:flutter/foundation.dart';

class AdConstants {
  static String get nativeAdUnitId {
    if (Platform.isAndroid) {
      return kReleaseMode
          ? 'ca-app-pub-7841436065695087/4770853551' // Production
          : 'ca-app-pub-3940256099942544/2247696110'; // Test ID
    } else if (Platform.isIOS) {
      return kReleaseMode
          ? 'ca-app-pub-7841436065695087/1059911084' // Production
          : 'ca-app-pub-3940256099942544/3986624511'; // Test ID
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static String get rewardedInterstitialAdUnitId {
    if (Platform.isAndroid) {
      return 'ca-app-pub-7841436065695087/6044692180'; // Provided Real ID
    } else if (Platform.isIOS) {
      return 'ca-app-pub-7841436065695087/4785265616'; // Provided Real ID
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }

  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return kReleaseMode
          ? 'ca-app-pub-7841436065695087/4770853551' // Production (Using same ID as Native for now)
          : 'ca-app-pub-3940256099942544/6300978111'; // Test Banner ID
    } else if (Platform.isIOS) {
      return kReleaseMode
          ? 'ca-app-pub-7841436065695087/1059911084' // Production (Using same ID as Native for now)
          : 'ca-app-pub-3940256099942544/2934735716'; // Test Banner ID
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
}
