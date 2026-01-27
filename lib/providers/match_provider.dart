import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/admob_service.dart';
import '../providers/unlocked_profiles_provider.dart';

class MatchState {
  final bool isLoadingAd;
  final String? error;

  MatchState({this.isLoadingAd = false, this.error});

  MatchState copyWith({bool? isLoadingAd, String? error}) {
    return MatchState(
      isLoadingAd: isLoadingAd ?? this.isLoadingAd,
      error: error,
    );
  }
}

final matchProvider = NotifierProvider<MatchNotifier, MatchState>(() {
  return MatchNotifier();
});

class MatchNotifier extends Notifier<MatchState> {
  @override
  MatchState build() {
    return MatchState();
  }

  void showAdToUnlock(BuildContext context, String profileId) {
    if (state.isLoadingAd) return;

    state = state.copyWith(isLoadingAd: true);

    ref
        .read(admobServiceProvider)
        .loadRewardedInterstitialAd(
          onAdLoaded: (ad) {
            // Keep loading true until shown/earned?
            // Or set false now?
            // If we set false now, the overlay disappears.
            // Let's set false after show.

            ad.show(
              onUserEarnedReward: (adWithoutView, reward) {
                ref.read(unlockedProfilesProvider.notifier).unlock(profileId);
              },
            );
            // We can't easily track when ad closes unless we wrap the callback.
            // RewardedInterstitialAd doesn't have "onAdClosed".
            // Usage usually:
            // load -> callback -> show.
            // FullScreenContentCallback can track dismiss.

            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                state = state.copyWith(isLoadingAd: false);
                ad.dispose();
              },
              onAdFailedToShowFullScreenContent: (ad, err) {
                state = state.copyWith(
                  isLoadingAd: false,
                  error: err.toString(),
                );
                ad.dispose();
              },
            );
          },
          onAdFailedToLoad: (error) {
            state = state.copyWith(isLoadingAd: false, error: error.toString());
            debugPrint('Ad failed to load: $error');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Failed to load ad. Please try again."),
              ),
            );
          },
        );
  }
}
