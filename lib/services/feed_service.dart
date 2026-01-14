import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/card_item.dart';
import '../models/user_profile.dart';
// import '../constants/mock_data.dart'; // Removed
import '../providers/user_provider.dart';
import 'gravity_service.dart';
import 'firestore_service.dart';
import 'auth_service.dart';

class FeedService {
  final Ref ref;
  final GravityService _gravityService = GravityService();
  final List<UserProfile> _activeProfiles = [];

  FeedService(this.ref);

  // Initialize with real data
  Future<void> initializeFeed() async {
    final user = ref.read(authServiceProvider).currentUser;
    final firestore = ref.read(firestoreServiceProvider);

    // Get filter settings
    final userState = ref.read(userProvider);
    final prefs = userState.preferences;

    if (user != null) {
      _activeProfiles.clear(); // Clear existing profiles to prevent duplicates

      // DEBUG: List ALL users in DB to verify existence
      try {
        final allDocs = await firestore.getAllUsersDebug();
        print('DEBUG: TOTAL USERS IN DB: ${allDocs.length}');
        for (var d in allDocs) {
          print(
            'DEBUG: User: ${d['name']} (${d['gender']}, ${d['age']}y) ID: ${d['id']}',
          );
        }
      } catch (e) {
        print('DEBUG: Failed to list users: $e');
      }

      print(
        'DEBUG: Filters - Gender: ${prefs.gender}, Age: ${prefs.ageRange}, Location: ${prefs.location}, Dist: ${prefs.distance}',
      );

      var profiles = await firestore.fetchProfiles(
        currentUserId: user.uid,
        gender: prefs.gender,
        minAge: prefs.ageRange[0],
        maxAge: prefs.ageRange[1],
      );

      print(
        'DEBUG: Fetched ${profiles.length} profiles: ${profiles.map((p) => p.name).join(', ')}',
      );

      // AUTO-SEED: If no profiles found, generate demo data
      // if (profiles.isEmpty) {
      //   await firestore.seedDemoProfiles(
      //     gender: prefs.gender,
      //     location: prefs.location,
      //   );
      //   // Re-fetch after seeding
      //   profiles = await firestore.fetchProfiles(
      //     currentUserId: user.uid,
      //     gender: prefs.gender,
      //     minAge: prefs.ageRange[0],
      //     maxAge: prefs.ageRange[1],
      //   );
      // }

      if (profiles.isNotEmpty) {
        final filteredProfiles = profiles.where((profile) {
          // 0. Safety Check: Never show current user
          if (profile.id == user.uid) return false;

          // 3. Distance Filter (Naive check against profile.distance)
          if (profile.distance > prefs.distance) {
            return false;
          }

          // Location String Filter (City Name etc.)
          if (prefs.location.isNotEmpty) {
            if (!profile.location.toLowerCase().contains(
              prefs.location.toLowerCase(),
            )) {
              return false;
            }
          }

          // 4. Interest Filter
          if (prefs.interests.isNotEmpty) {
            final hasInterest = profile.interests.any(
              (i) => prefs.interests.contains(i),
            );
            if (!hasInterest) {
              return false;
            }
          }

          // 5. Looking For Filter
          if (prefs.lookingFor.isNotEmpty) {
            // If user hasn't specified 'lookingFor' in their profile,
            // we might default to showing them, or hiding.
            // Let's hide if they don't match strict filter.
            if (profile.lookingFor == null ||
                !prefs.lookingFor.contains(profile.lookingFor)) {
              return false;
            }
          }

          return true;
        }).toList();

        _activeProfiles.addAll(_gravityService.sortProfiles(filteredProfiles));
        return;
      }
    }

    // Fallback to mock data if no user or empty DB (Also filtered)
    // removed mock profiles
    // final filteredMock = MOCK_PROFILES.where((profile) {
    //  ...
    // }).toList();

    // _activeProfiles.addAll(_gravityService.sortProfiles(filteredMock));
    // Do nothing if real profiles not found
  }

  /// FSA Rule: Profile - Profile - Profile - Ad (P-P-P-A)
  CardItem getCardAtIndex(int index) {
    if (_activeProfiles.isEmpty) {
      return CardItem(
        type: CardType.empty,
        data: null,
        uniqueId: 'empty-$index',
      );
    }

    const int patternLength = 4;
    final int positionInPattern = index % patternLength; // 0, 1, 2, 3

    // Indices 0, 1, 2 are Profiles. Index 3 is Ad.
    if (positionInPattern < 3) {
      // It's a Profile
      final int cycleIndex = (index / patternLength).floor();
      final int profileIndex =
          (cycleIndex * 3 + positionInPattern) % _activeProfiles.length;
      final profile = _activeProfiles[profileIndex];

      return CardItem(
        type: CardType.profile,
        data: profile,
        uniqueId: 'profile-$index-${profile.id}',
      );
    } else {
      // It's an Ad
      // Return generic Ad Placeholder
      // We don't need data, the AdCard will handle loading the ad
      return CardItem(type: CardType.ad, data: null, uniqueId: 'ad-$index');
    }
  }
}
