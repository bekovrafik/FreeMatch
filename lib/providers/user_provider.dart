import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart'; // For UserProfile
import '../services/auth_service.dart'; // For authStateProvider
import '../services/firestore_service.dart'; // For firestoreServiceProvider

class DiscoveryPreferences {
  final List<double> ageRange; // [min, max]
  final double distance;
  final String gender; // 'MEN', 'WOMEN', 'EVERYONE'
  final String location;
  final List<String> interests;
  final List<String> lookingFor;

  const DiscoveryPreferences({
    this.ageRange = const [18, 35],
    this.distance = 50,
    this.gender = 'EVERYONE',
    this.location = '',
    this.interests = const [],
    this.lookingFor = const [],
  });

  DiscoveryPreferences copyWith({
    List<double>? ageRange,
    double? distance,
    String? gender,
    String? location,
    List<String>? interests,
    List<String>? lookingFor,
  }) {
    return DiscoveryPreferences(
      ageRange: ageRange ?? this.ageRange,
      distance: distance ?? this.distance,
      gender: gender ?? this.gender,
      location: location ?? this.location,
      interests: interests ?? this.interests,
      lookingFor: lookingFor ?? this.lookingFor,
    );
  }
}

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
    return const UserState();
  }

  void decrementSuperLike() {
    if (state.superLikes > 0) {
      state = state.copyWith(superLikes: state.superLikes - 1);
    }
  }

  void incrementSuperLike() {
    state = state.copyWith(superLikes: state.superLikes + 1);
  }

  void updatePreferences(DiscoveryPreferences newPrefs) {
    state = state.copyWith(preferences: newPrefs);
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
