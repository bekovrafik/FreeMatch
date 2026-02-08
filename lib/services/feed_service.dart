import 'package:flutter/foundation.dart';
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
        debugPrint('DEBUG: TOTAL USERS IN DB: ${allDocs.length}');
        for (var d in allDocs) {
          debugPrint(
            'DEBUG: User: ${d['name']} (${d['gender']}, ${d['age']}y) ID: ${d['id']}',
          );
        }
      } catch (e) {
        debugPrint('DEBUG: Failed to list users: $e');
      }

      debugPrint(
        'DEBUG: Filters - Gender: ${prefs.gender}, Age: ${prefs.ageRange}, Location: ${prefs.location}, Dist: ${prefs.distance}',
      );

      var profiles = await firestore.fetchProfiles(
        currentUserId: user.uid,
        gender: prefs.gender,
        minAge: prefs.ageRange[0],
        maxAge: prefs.ageRange[1],
      );

      debugPrint(
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
        // 1. Initial filter with Location and Distance
        List<UserProfile> filteredProfiles = profiles.where((profile) {
          // 0. Safety Check: Never show current user
          if (profile.id == user.uid) return false;

          // Distance Filter
          if (profile.distance > prefs.distance) {
            return false;
          }

          // Location String Filter
          if (prefs.location.isNotEmpty) {
            if (!profile.location.toLowerCase().contains(
              prefs.location.toLowerCase(),
            )) {
              return false;
            }
          }

          // Interest Filter
          if (prefs.interests.isNotEmpty) {
            final hasInterest = profile.interests.any(
              (i) => prefs.interests.contains(i),
            );
            if (!hasInterest) {
              return false;
            }
          }

          // Looking For Filter
          if (prefs.lookingFor.isNotEmpty) {
            if (profile.lookingFor == null ||
                !prefs.lookingFor.contains(profile.lookingFor)) {
              return false;
            }
          }

          return true;
        }).toList();

        // 2. WORLDWIDE FALLBACK: If no profiles in location, try ignoring Location and Distance
        if (filteredProfiles.isEmpty &&
            (prefs.location.isNotEmpty || prefs.distance < 100)) {
          debugPrint(
            'DEBUG: No local profiles found. Falling back to Worldwide.',
          );
          filteredProfiles = profiles.where((profile) {
            if (profile.id == user.uid) return false;

            // Still apply Interest and Looking For filters if they exist
            if (prefs.interests.isNotEmpty) {
              final hasInterest = profile.interests.any(
                (i) => prefs.interests.contains(i),
              );
              if (!hasInterest) return false;
            }

            if (prefs.lookingFor.isNotEmpty) {
              if (profile.lookingFor == null ||
                  !prefs.lookingFor.contains(profile.lookingFor)) {
                return false;
              }
            }

            return true;
          }).toList();
        }

        // 3. ULTIMATE FALLBACK: If Strict Fallback is empty, show ANYONE matching Age/Gender (ignoring interests/lookingFor)
        if (filteredProfiles.isEmpty) {
          debugPrint(
            'DEBUG: Worldwide fallback empty. Trying ULTIMATE FALLBACK (Ignoring Interests/LookingFor).',
          );
          filteredProfiles = profiles.where((profile) {
            if (profile.id == user.uid) return false;
            return true;
          }).toList();
        }

        if (filteredProfiles.isNotEmpty) {
          _activeProfiles.addAll(
            _gravityService.sortProfiles(filteredProfiles),
          );
        }
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

    // Pure Profile Feed (No Ads in Swipe Stack)
    final int profileIndex = index % _activeProfiles.length;
    final profile = _activeProfiles[profileIndex];

    return CardItem(
      type: CardType.profile,
      data: profile,
      uniqueId: 'profile-$index-${profile.id}',
    );
  }
}
