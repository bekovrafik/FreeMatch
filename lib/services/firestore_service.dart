import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart'; // Add Geolocator
import 'dart:math' as math; // For Mock Location Generation
import '../models/user_profile.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService(FirebaseFirestore.instance);
});

class FirestoreService {
  final FirebaseFirestore _firestore;

  FirestoreService(this._firestore);

  // Fetch profiles with server-side filtering and pagination
  Future<List<UserProfile>> fetchProfiles({
    required String currentUserId,
    String? gender,
    double? minAge,
    double? maxAge,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      Query query = _firestore.collection('users');

      // Server-side filtering
      if (gender != null && gender != 'EVERYONE') {
        query = query.where('gender', isEqualTo: gender.toUpperCase());
      }

      if (minAge != null) {
        query = query.where('age', isGreaterThanOrEqualTo: minAge);
      }

      if (maxAge != null) {
        query = query.where('age', isLessThanOrEqualTo: maxAge);
      }

      // Pagination
      query = query.limit(limit);
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      if (snapshot.docs.isEmpty) return [];

      final profileDocs = snapshot.docs
          .where((doc) => doc.id != currentUserId)
          .toList();
      if (profileDocs.isEmpty) return [];

      // 0. Get Current User Location for Distance Calculation
      double? myLat;
      double? myLng;
      try {
        final userDoc = await _firestore
            .collection('users')
            .doc(currentUserId)
            .get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          if (userData != null) {
            myLat = (userData['latitude'] as num?)?.toDouble();
            myLng = (userData['longitude'] as num?)?.toDouble();
          }
        }
      } catch (e) {
        debugPrint('Error fetching current user location: $e');
      }

      // 2. Optimized: Check "Like Status" ONLY for the fetched profiles (Max 20 reads)
      // Instead of reading ALL received_likes (Potential 1000+ reads)
      final profileIds = profileDocs.map((doc) => doc.id).toList();
      final Map<String, bool> likedStatus = {};

      // Firestore 'whereIn' is limited to 10 values. We must chunk.
      // Or we can just do parallel get()s since 20 is small.
      // Parallel get() is mostly cleaner and robust for Document ID checks.
      // Cost: 20 reads per page load. Much reuse/caching potential.

      // Let's use Future.wait for parallel reads
      final checkLikesFutures = profileIds.map(
        (id) => _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('received_likes')
            .doc(id)
            .get(),
      );

      final likeSnapshots = await Future.wait(checkLikesFutures);

      for (var doc in likeSnapshots) {
        if (doc.exists) {
          likedStatus[doc.id] = doc.data()?['isSuperLike'] == true;
        }
      }

      return profileDocs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        final userId = doc.id;
        final didLikeMe = likedStatus.containsKey(userId);
        final wasSuper = likedStatus[userId] == true;

        // Dynamic Distance Calculation
        double calculatedDist = (data['distance'] as num?)?.toDouble() ?? 0.0;
        if (myLat != null && myLng != null) {
          final double? uLat = (data['latitude'] as num?)?.toDouble();
          final double? uLng = (data['longitude'] as num?)?.toDouble();
          if (uLat != null && uLng != null) {
            // Returns meters, convert to km
            calculatedDist =
                Geolocator.distanceBetween(myLat, myLng, uLat, uLng) / 1000.0;
          }
        }

        return UserProfile.fromJson({
          ...data,
          'id': userId,
          'distance': calculatedDist,
          'hasLikedCurrentUser': didLikeMe,
          'isSuperLike': wasSuper, // Pass this context to the profile
        });
      }).toList();
    } catch (e) {
      debugPrint("Error fetching profiles: $e");
      return [];
    }
  }

  // Fetch a single user profile by ID
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserProfile.fromJson({...doc.data()!, 'id': doc.id});
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Stream<UserProfile?> userProfileStream(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserProfile.fromJson({...doc.data()!, 'id': doc.id});
      }
      return null;
    });
  }

  // Update specific fields of a user profile
  Future<void> updateUserFields(
    String userId,
    Map<String, dynamic> data,
  ) async {
    await _firestore.collection('users').doc(userId).update(data);
  }

  // Create or Update a new user profile document
  Future<void> saveUserProfile(UserProfile profile) async {
    await _firestore.collection('users').doc(profile.id).set({
      'name': profile.name,
      'age': profile.age,
      'bio': profile.bio,
      'imageUrls': profile.imageUrls,
      'location': profile.location,
      'profession': profile.profession,
      'gender': profile.gender,
      'distance': profile.distance,
      'latitude': profile.latitude,
      'longitude': profile.longitude,
      'interests': profile.interests,
      'isVerified': profile.isVerified,
      'lastActive': profile.lastActive,
      'joinedDate': profile.joinedDate,
      'popularityScore': profile.popularityScore,
      'voiceIntro': profile.voiceIntro,
      'voiceIntroTitle': profile.voiceIntroTitle,
      'status': profile.status,
      'orientation': profile.orientation,
      'drinks': profile.drinks,
      'height': profile.height,
      'religion': profile.religion,
      'sign': profile.sign,
      'smokes': profile.smokes,
      'speaks': profile.speaks,
      'bodyType': profile.bodyType,
      'lookingFor': profile.lookingFor,
    }, SetOptions(merge: true));
  }

  // Record a Swipe (Like or Dislike)
  // Matching is now handled server-side by Cloud Functions
  // Record a Swipe (Like or Dislike)
  // Matching is now handled server-side by Cloud Functions
  // BUT: We want to clean up the "Who Likes Me" list locally/immediately for UX.
  Future<void> recordSwipe(
    String currentUserId,
    String targetUserId,
    bool isLike, {
    bool isSuperLike = false,
  }) async {
    try {
      final collection = isLike ? 'likes' : 'dislikes';
      debugPrint(
        'DEBUG: recordSwipe from $currentUserId to $targetUserId ($collection)',
      );

      // 1. Record the swipe (Atomic Write Trigger)
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection(collection)
          .doc(targetUserId)
          .set({
            'timestamp': FieldValue.serverTimestamp(),
            'isSuperLike': isSuperLike,
          });

      // 2. [UX FIX] Remove from "received_likes" so they disappear from "Who Likes Me"
      // This makes the list act like an Inbox.
      debugPrint(
        'DEBUG: Attempting to delete $targetUserId from received_likes of $currentUserId',
      );
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('received_likes')
          .doc(targetUserId)
          .delete();
      debugPrint('DEBUG: Deletion successful or doc did not exist.');
    } catch (e) {
      debugPrint('DEBUG ERROR recording swipe/cleanup: $e');
    }
  }

  // Fetch users who have liked the current user (but not yet matched/swiped?)
  Stream<List<UserProfile>> getWhoLikedMe(String currentUserId) {
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('received_likes')
        .orderBy('timestamp', descending: true)
        .limit(20) // Performance Limit
        .snapshots()
        .asyncMap((snapshot) async {
          final userIds = snapshot.docs.map((doc) => doc.id).toList();
          if (userIds.isEmpty) return [];

          // Fetch user profiles (chunked if > 10, but simplistic for now)
          // Firestore 'in' query limit is 10. We'll do individual fetches for robustness here
          List<UserProfile> profiles = [];
          for (var id in userIds) {
            final profile = await getUserProfile(id);
            if (profile != null) {
              // Check if they super liked? (It's in the doc data)
              final isSuperLike =
                  snapshot.docs
                      .firstWhere((d) => d.id == id)
                      .data()['isSuperLike'] ??
                  false;
              // We could attach 'isSuperLike' to the profile wrapper or handle it differently
              // Return profile with Super Like status
              profiles.add(profile.copyWith(isSuperLike: isSuperLike));
            }
          }
          return profiles;
        });
  }

  // Get total likes count
  Future<int> getLikesCount(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('received_likes')
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  Future<void> deleteUserData(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
    } catch (e) {
      // Handle error or log
    }
  }

  Future<void> saveDeviceToken(String userId, String token) async {
    await _firestore.collection('users').doc(userId).set({
      'fcmToken': token,
    }, SetOptions(merge: true));
  }

  Future<void> seedDemoProfiles({String? gender, String? location}) async {
    final targetGender = gender ?? 'WOMEN';
    final targetLocation = location ?? 'New York, USA';

    // Basic pool of names/images for demo (could be expanded)
    final List<Map<String, dynamic>> women = [
      {
        'name': 'Sophia',
        'age': 24,
        'bio':
            'Coffee lover ☕ | Travel enthusiast ✈️ | Always looking for the next adventure!',
        'imageUrls': [
          'https://images.unsplash.com/photo-1524504388940-b1c1722653e1',
          'https://images.unsplash.com/photo-1517841905240-472988babdf9',
        ],
        'profession': 'Graphic Designer',
        'interests': ['Art', 'Travel', 'Coffee', 'Photography'],
      },
      {
        'name': 'Emma',
        'age': 26,
        'bio': 'Yoga instructor 🧘‍♀️. Love nature and hiking on weekends.',
        'imageUrls': [
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330',
          'https://images.unsplash.com/photo-1534528741775-53994a69daeb',
        ],
        'profession': 'Yoga Instructor',
        'interests': ['Yoga', 'Nature', 'Hiking', 'Health'],
      },
      {
        'name': 'Olivia',
        'age': 23,
        'bio':
            'Tech geek 💻 by day, gamer 🎮 by night. Looking for someone to co-op with.',
        'imageUrls': [
          'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e',
          'https://images.unsplash.com/photo-1502823403499-6ccfcf4fb453',
        ],
        'profession': 'Software Engineer',
        'interests': ['Gaming', 'Tech', 'Movies', 'Anime'],
      },
      {
        'name': 'Ava',
        'age': 25,
        'bio':
            'Foodie 🍕. I know the best pizza spots in town. Swipe right if you love cheese!',
        'imageUrls': [
          'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df',
          'https://images.unsplash.com/photo-1544005313-94ddf0286df2',
        ],
        'profession': 'Chef',
        'interests': ['Foodie', 'Cooking', 'Music', 'Wine'],
      },
      {
        'name': 'Isabella',
        'age': 27,
        'bio':
            'Artist 🎨. Painting my way through life. Let’s visit an art gallery?',
        'imageUrls': [
          'https://images.unsplash.com/photo-1524250502761-1ac6f2e30d43',
          'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2',
        ],
        'profession': 'Artist',
        'interests': ['Art', 'Museums', 'Reading', 'Culture'],
      },
    ];

    final List<Map<String, dynamic>> men = [
      {
        'name': 'Liam',
        'age': 25,
        'bio': 'Musician 🎸. Let me play you a song.',
        'imageUrls': [
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e',
          'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d',
        ],
        'profession': 'Musician',
        'interests': ['Music', 'Guitar', 'Concerts', 'Vinyl'],
      },
      {
        'name': 'Noah',
        'age': 28,
        'bio': 'Entrepreneur. Building the next big thing. 🚀',
        'imageUrls': [
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d',
          'https://images.unsplash.com/photo-1480455624313-e29b44bbfde1',
        ],
        'profession': 'Founder',
        'interests': ['Business', 'Tech', 'Startups', 'Travel'],
      },
      {
        'name': 'William',
        'age': 26,
        'bio': 'Chef 👨‍🍳. I make the best pasta in town.',
        'imageUrls': [
          'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7',
          'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce',
        ],
        'profession': 'Chef',
        'interests': ['Food', 'Cooking', 'Wine', 'Dining'],
      },
      {
        'name': 'James',
        'age': 29,
        'bio': 'Photographer 📷. Capturing moments.',
        'imageUrls': [
          'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6',
          'https://images.unsplash.com/photo-1522075469751-3a3694c2d637',
        ],
        'profession': 'Photographer',
        'interests': ['Photography', 'Art', 'Travel', 'Adventure'],
      },
      {
        'name': 'Benjamin',
        'age': 27,
        'bio': 'Fitness enthusiast. Join me for a run? 🏃‍♂️',
        'imageUrls': [
          'https://images.unsplash.com/photo-1463453091185-61582044d556',
          'https://images.unsplash.com/photo-1480429370139-e0132c086e2a',
        ],
        'profession': 'Personal Trainer',
        'interests': ['Running', 'Gym', 'Health', 'Sports'],
      },
    ];

    List<Map<String, dynamic>> demoUsers = [];

    if (targetGender == 'WOMEN') {
      demoUsers = women;
    } else if (targetGender == 'MEN') {
      demoUsers = men;
    } else {
      // Everyone - mix
      demoUsers = [...women, ...men];
      demoUsers.shuffle(); // Randomize mix
    }

    final batch = _firestore.batch();

    // Center point (e.g., New York City)
    const double centerLat = 40.7128;
    const double centerLng = -74.0060;
    final random = math.Random();

    for (var i = 0; i < demoUsers.length; i++) {
      final user = demoUsers[i];
      final docRef = _firestore.collection('users').doc();
      final now = DateTime.now().millisecondsSinceEpoch;

      // Random offset within ~10km
      // 1 degree lat ~= 111km. 10km ~= 0.09 degrees
      final latOffset = (random.nextDouble() - 0.5) * 0.18;
      final lngOffset = (random.nextDouble() - 0.5) * 0.18;

      batch.set(docRef, {
        'id': docRef.id,
        'name': user['name'],
        'age': user['age'],
        'bio': user['bio'],
        'imageUrls': user['imageUrls'],
        'location': targetLocation, // Use dynamic location
        'profession': user['profession'],
        'gender': targetGender == 'EVERYONE'
            ? (i < women.length ? 'WOMEN' : 'MEN')
            : targetGender,
        'distance': (i + 1) * 2.5, // Static fallback
        'latitude': centerLat + latOffset,
        'longitude': centerLng + lngOffset,
        'interests': user['interests'],
        'isVerified': true,
        'dob': DateTime.now()
            .subtract(Duration(days: (user['age'] as int) * 365))
            .millisecondsSinceEpoch,
        'lastActive': now,
        'joinedDate': now,
        'popularityScore': 80 + i,
      });
    }

    await batch.commit();
    debugPrint("DEBUG: Seeded ${demoUsers.length} profiles with Geolocation.");
  }

  Future<void> purgeAllUsers() async {
    try {
      final snapshot = await _firestore.collection('users').get();
      final batch = _firestore.batch();
      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      debugPrint("DEBUG: PURGED ALL USERS");
    } catch (e) {
      debugPrint("DEBUG: Failed to purge users: $e");
    }
  }

  Future<List<Map<String, dynamic>>> getAllUsersDebug() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs.map((d) {
      final data = d.data();
      debugPrint(
        "DEBUG: User ${data['name']} Age Type: ${data['age'].runtimeType} Value: ${data['age']}",
      );
      return {...data, 'id': d.id};
    }).toList();
  }
}
