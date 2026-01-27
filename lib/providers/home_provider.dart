import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/streak_service.dart';
import '../services/notification_service.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../services/admob_service.dart';

// State to hold both index and swipe info?
// Or separate? Let's keep HomeNotifier for index, and a separate SwipeNotifier?
// Actually, HomeNotifier is fine to expand or we can make a specific SwipeLimiter.
// Let's make a separate provider for Swipe Limits to keep things clean.

class SwipeLimitState {
  final int swipesLeft;
  final bool isLoading;

  SwipeLimitState({required this.swipesLeft, this.isLoading = false});
}

final swipeLimitProvider =
    NotifierProvider<SwipeLimitNotifier, SwipeLimitState>(() {
      return SwipeLimitNotifier();
    });

class SwipeLimitNotifier extends Notifier<SwipeLimitState> {
  static const int kDailyFreeSwipes = 25;
  static const int kAdRewardSwipes = 25;
  late SharedPreferences _prefs;

  @override
  SwipeLimitState build() {
    // Load initial state async, but for now return default.
    // We'll initialize in a method or use FutureProvider, but we want sync access for UI blocking.
    // Best pattern: Load in init, start with 0 or 25?
    // Let's start with 0 and load fast. Or assume 25.
    _loadSwipes();
    return SwipeLimitState(swipesLeft: 25);
  }

  Future<void> _loadSwipes() async {
    _prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD
    final lastReset = _prefs.getString('last_swipe_reset_date');

    if (lastReset != today) {
      // New Day: Reset
      await _prefs.setString('last_swipe_reset_date', today);
      await _prefs.setInt('daily_swipes_left', kDailyFreeSwipes);
      state = SwipeLimitState(swipesLeft: kDailyFreeSwipes);
    } else {
      // Same Day: Load
      final left = _prefs.getInt('daily_swipes_left') ?? kDailyFreeSwipes;
      state = SwipeLimitState(swipesLeft: left);
    }
  }

  Future<void> decrementSwipe() async {
    if (state.swipesLeft > 0) {
      final newCount = state.swipesLeft - 1;
      state = SwipeLimitState(swipesLeft: newCount);
      await _prefs.setInt('daily_swipes_left', newCount);
    }
  }

  bool get canSwipe => state.swipesLeft > 0;

  Future<void> watchAdForSwipes(BuildContext context) async {
    state = SwipeLimitState(swipesLeft: state.swipesLeft, isLoading: true);

    ref
        .read(admobServiceProvider)
        .loadRewardedInterstitialAd(
          onAdLoaded: (ad) {
            ad.show(
              onUserEarnedReward: (adWithoutView, reward) async {
                // Grant Swipes
                final newCount = state.swipesLeft + kAdRewardSwipes;
                state = SwipeLimitState(swipesLeft: newCount);
                // Verify prefs are init
                await _prefs.setInt('daily_swipes_left', newCount);
              },
            );
            state = SwipeLimitState(
              swipesLeft: state.swipesLeft,
              isLoading: false,
            );
          },
          onAdFailedToLoad: (err) {
            state = SwipeLimitState(
              swipesLeft: state.swipesLeft,
              isLoading: false,
            );
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text("Failed to load ad: $err")));
          },
        );
  }
}

final homeProvider = NotifierProvider<HomeNotifier, int>(() {
  return HomeNotifier();
});

class HomeNotifier extends Notifier<int> {
  @override
  int build() {
    return 0; // Initial state
  }

  void setIndex(int index) {
    state = index;
  }

  Future<void> initHome(BuildContext? context) async {
    _saveFcmToken();
    // Daily Reward check
    await Future.delayed(const Duration(seconds: 1));
    final result = await StreakService().checkDailyStreak();
    if (result['showReward'] == true && context != null && context.mounted) {
      // UI handling usually happens in HomeScreen via future provider
    }
  }

  Future<void> _saveFcmToken() async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user != null) {
      final token = await ref.read(notificationServiceProvider).getToken();
      if (token != null) {
        await ref
            .read(firestoreServiceProvider)
            .saveDeviceToken(user.uid, token);
      }
    }
  }
}

// Separate provider for the specific task of checking reward async
final dailyRewardCheckProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  await Future.delayed(const Duration(seconds: 1));
  return await StreakService().checkDailyStreak();
});
