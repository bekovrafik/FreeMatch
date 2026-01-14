import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

      // 1. Fetch "received_likes" for current user to identify who liked them
      final receivedLikesSnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('received_likes')
          .get();

      // Map of ID -> isSuperLike
      final Map<String, bool> likedStatus = {};
      for (var doc in receivedLikesSnapshot.docs) {
        likedStatus[doc.id] = doc.data()['isSuperLike'] == true;
      }

      return snapshot.docs
          .where((doc) => doc.id != currentUserId) // Filter out self locally
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final userId = doc.id;
            final didLikeMe = likedStatus.containsKey(userId);
            final wasSuper = likedStatus[userId] == true;

            return UserProfile.fromJson({
              ...data,
              'id': userId,
              'hasLikedCurrentUser': didLikeMe,
              'isSuperLike': wasSuper, // Pass this context to the profile
            });
          })
          .toList();
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
  Future<void> recordSwipe(
    String currentUserId,
    String targetUserId,
    bool isLike, {
    bool isSuperLike = false,
  }) async {
    try {
      final collection = isLike ? 'likes' : 'dislikes';

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

      // No client-side match check.
    } catch (e) {
      debugPrint('Error recording swipe: $e');
    }
  }

  // Fetch users who have liked the current user (but not yet matched/swiped?)
  Stream<List<UserProfile>> getWhoLikedMe(String currentUserId) {
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('received_likes')
        .orderBy('timestamp', descending: true)
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

    for (var i = 0; i < demoUsers.length; i++) {
      final user = demoUsers[i];
      final docRef = _firestore.collection('users').doc();
      final now = DateTime.now().millisecondsSinceEpoch;

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
        'distance': (i + 1) * 2.5, // 2.5km increments
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
      print(
        "DEBUG: User ${data['name']} Age Type: ${data['age'].runtimeType} Value: ${data['age']}",
      );
      return {...data, 'id': d.id};
    }).toList();
  }
}
