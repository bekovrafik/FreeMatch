import 'package:flutter_riverpod/flutter_riverpod.dart';

// Tracks the set of profile IDs that have been unlocked (via Ad watch) in the current session.
final unlockedProfilesProvider =
    NotifierProvider<UnlockedProfilesNotifier, Set<String>>(
      UnlockedProfilesNotifier.new,
    );

class UnlockedProfilesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void unlock(String profileId) {
    state = {...state, profileId};
  }
}
