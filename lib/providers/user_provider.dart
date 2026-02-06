import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart'; // For UserProfile
import '../services/auth_service.dart'; // For authStateProvider
import '../services/firestore_service.dart'; // For firestoreServiceProvider

import '../models/discovery_preferences.dart';

class UserState {
  final int superLikes;
  final int streak;
  final String lastLoginDate;
  final bool isVerified;
  final DiscoveryPreferences preferences;

  const UserState({
    this.superLikes = 5,
    this.streak = 1,
    this.lastLoginDate = '',
    this.isVerified = false,
    this.preferences = const DiscoveryPreferences(),
  });

  UserState copyWith({
    int? superLikes,
    int? streak,
    String? lastLoginDate,
    bool? isVerified,
    DiscoveryPreferences? preferences,
  }) {
    return UserState(
      superLikes: superLikes ?? this.superLikes,
      streak: streak ?? this.streak,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
      isVerified: isVerified ?? this.isVerified,
      preferences: preferences ?? this.preferences,
    );
  }
}

class UserNotifier extends Notifier<UserState> {
  @override
  UserState build() {
    // Listen to profile stream to keep local state in sync
    final profileAsync = ref.watch(currentUserProfileProvider);

    return profileAsync.maybeWhen(
      data: (profile) {
        if (profile != null) {
          // Sync preferences from profile using a fresh UserState as base
          const initialState = UserState();
          return initialState.copyWith(
            preferences: profile.toDiscoveryPreferences(
              initialState.preferences,
            ),
            isVerified: profile.isVerified,
          );
        }
        return const UserState();
      },
      orElse: () => const UserState(),
    );
  }

  void decrementSuperLike() {
    if (state.superLikes > 0) {
      state = state.copyWith(superLikes: state.superLikes - 1);
    }
  }

  void incrementSuperLike() {
    state = state.copyWith(superLikes: state.superLikes + 1);
  }

  Future<void> updatePreferences(DiscoveryPreferences newPrefs) async {
    // 1. Optimistic Update
    state = state.copyWith(preferences: newPrefs);

    // 2. Persist to Firestore
    final user = ref.read(authServiceProvider).currentUser;
    if (user != null) {
      // Create a temporary profile dummy to use the mapping logic or just map manually
      // We'll update specific fields
      final updates = {
        'distance': newPrefs.distance,
        'location': newPrefs.location,
        'interests': newPrefs.interests,
        'lookingFor': newPrefs.gender, // Mapping 'Show me' -> 'lookingFor'
        // ageRange is usually local-only or needs specific fields in UserProfile if we want to save it
        // For now, we are NOT saving ageRange to profile as UserProfile doesn't have minAge/maxAge fields.
        // If we want to persist ageRange, we need to add 'minAge'/'maxAge' to UserProfile or a 'settings' sub-collection.
        // Given the UserProfile definition, we'll skip ageRange persistence for now or add it to 'discoverySettings' map if schema allowed.
        // Let's assume we update what we can.
      };

      await ref
          .read(firestoreServiceProvider)
          .updateUserFields(user.uid, updates);
    }
  }

  void setVerified(bool isVerified) {
    state = state.copyWith(isVerified: isVerified);
  }
}

final userProvider = NotifierProvider<UserNotifier, UserState>(
  UserNotifier.new,
);

final currentUserProfileProvider = StreamProvider<UserProfile?>((ref) {
  final authState = ref.watch(authStateProvider);

  return authState.when(
    data: (user) {
      if (user != null) {
        return ref.read(firestoreServiceProvider).userProfileStream(user.uid);
      }
      return Stream.value(null);
    },
    loading: () => Stream.value(null),
    error: (error, stack) => Stream.value(null),
  );
});
