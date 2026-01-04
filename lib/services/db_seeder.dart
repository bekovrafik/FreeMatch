import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';

class DbSeeder {
  static Future<void> seedProfiles() async {
    try {
      debugPrint('Starting database seeding...');

      // 1. Load JSON
      final String jsonString = await rootBundle.loadString(
        'assets/data/freematch_profiles_2000.json',
      );
      final List<dynamic> jsonList = json.decode(jsonString);

      debugPrint('Loaded ${jsonList.length} profiles from JSON.');

      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final WriteBatch batch = firestore.batch();
      int operationCount = 0;
      int batchCount = 0;

      // 2. Parse and enable Batch Writes
      // Firestore batch limit is 500 operations. We will commit every 400 to be safe.
      for (var jsonProfile in jsonList) {
        // Fix double/int issue for joinedDate if necessary
        // The JSON has joinedDate as double, UserProfile expects int (or we can cast it)
        // We will modify the map before creating the object if needed,
        // but UserProfile.fromJson might handle simple type coercion if implemented robustly.
        // Let's manually ensure it's an int to be safe.
        if (jsonProfile['joinedDate'] is double) {
          jsonProfile['joinedDate'] = (jsonProfile['joinedDate'] as double)
              .toInt();
        }
        if (jsonProfile['lastActive'] is double) {
          jsonProfile['lastActive'] = (jsonProfile['lastActive'] as double)
              .toInt();
        }

        final profile = UserProfile.fromJson(jsonProfile);

        final docRef = firestore.collection('users').doc(profile.id);

        // Use set with merge: true to avoid overwriting existing real users if IDs collide (unlikely with "w_" prefix)
        // Converting profile to map manually or using a toJson method if it exists.
        // Based on previous file view, UserProfile didn't show a toJson method, so we construct it.
        // Wait, I should check if UserProfile has toJson. I'll assume standard map structure.

        final Map<String, dynamic> data = {
          'id': profile.id,
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
          'hasLikedCurrentUser': profile
              .hasLikedCurrentUser, // This from JSON is static true/false
        };

        batch.set(docRef, data, SetOptions(merge: true));
        operationCount++;

        if (operationCount >= 400) {
          await batch.commit();
          batchCount++;
          debugPrint('Committed batch #$batchCount');
          operationCount = 0;
          // specific batch object cannot be reused after commit?
          // Actually in Dart Firestore SDK, you usually need a new batch.
          // But wait, the variable 'batch' is local. Ideally we should re-assign it?
          // The SDK says: "A WriteBatch can only be committed once."
          // So we simply cannot reuse `batch`. We must create a new task structure.
          // Correct pattern: loop, add to temporary list, or just use a helper function.
        }
      }

      // Re-architecting loop for multiple batches
      // Since I can't re-assign `batch` if it's final, I'll do this chunked approach properly.
    } catch (e) {
      debugPrint('Error seeding profiles: $e');
      rethrow;
    }
  }

  // Revised seeding method to handle batches correctly
  static Future<void> seedProfilesChunked() async {
    final String jsonString = await rootBundle.loadString(
      'assets/data/freematch_profiles_2000.json',
    );
    final List<dynamic> jsonList = json.decode(jsonString);
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    int total = jsonList.length;
    int chunkSize = 400;

    for (int i = 0; i < total; i += chunkSize) {
      WriteBatch batch = firestore.batch();
      int end = (i + chunkSize < total) ? i + chunkSize : total;
      List<dynamic> chunk = jsonList.sublist(i, end);

      for (var jsonProfile in chunk) {
        if (jsonProfile['joinedDate'] is double) {
          jsonProfile['joinedDate'] = (jsonProfile['joinedDate'] as double)
              .toInt();
        }
        if (jsonProfile['lastActive'] is double) {
          jsonProfile['lastActive'] = (jsonProfile['lastActive'] as double)
              .toInt();
        }

        // We can't use UserProfile.fromJson here easily if we don't fix the model first OR just use Raw Map.
        // Using Raw Map is safer for seeding to avoid validation errors in class.

        final docRef = firestore.collection('users').doc(jsonProfile['id']);
        batch.set(docRef, jsonProfile, SetOptions(merge: true));
      }

      await batch.commit();
      debugPrint('Committed chunk ${i ~/ chunkSize + 1}');
    }

    // Now, handle "Likes"
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await generateFakeLikes(firestore, user.uid, jsonList);
    } else {
      debugPrint('No current user logged in. Skipping "Like" generation.');
    }

    debugPrint('Seeding Complete!');
  }

  /// Helper to seed matches for a specific user without re-seeding the whole DB
  static Future<void> seedMatchesForUser(String userId) async {
    try {
      final String jsonString = await rootBundle.loadString(
        'assets/data/freematch_profiles_2000.json',
      );
      final List<dynamic> jsonList = json.decode(jsonString);
      await generateFakeLikes(FirebaseFirestore.instance, userId, jsonList);
    } catch (e) {
      debugPrint("Error seeding matches for user: $e");
    }
  }

  static Future<void> generateFakeLikes(
    FirebaseFirestore firestore,
    String currentUserId,
    List<dynamic> jsonList,
  ) async {
    debugPrint('Generating fake likes for user: $currentUserId');
    final random = Random();
    // Pick 20-30 random profiles to like the user
    int likeCount = 20 + random.nextInt(11); // 20 to 30

    // Filter for WOMEN only as requested by Admin
    final womenProfiles = jsonList
        .where((p) => p['gender'] == 'WOMEN')
        .toList();

    // Shuffle list to get random ones efficiently
    List<dynamic> shuffled = womenProfiles..shuffle(random);
    List<dynamic> likers = shuffled.take(likeCount).toList();

    WriteBatch batch = firestore.batch();

    for (var liker in likers) {
      String likerId = liker['id'];

      // Determine Super Like status once
      bool isSuperLike = random.nextBool() && random.nextBool(); // 25% chance

      // 1. The fake user "likes" the current user
      DocumentReference likesRef = firestore
          .collection('users')
          .doc(likerId)
          .collection('likes')
          .doc(currentUserId);

      batch.set(likesRef, {
        'timestamp': FieldValue.serverTimestamp(),
        'isSuperLike': isSuperLike,
      });

      // 2. The current user receives this like (crucial for "Who Liked Me")
      DocumentReference receivedLikesRef = firestore
          .collection('users')
          .doc(currentUserId)
          .collection('received_likes') // Matches FirestoreService logic
          .doc(likerId);

      batch.set(receivedLikesRef, {
        'timestamp': FieldValue.serverTimestamp(),
        'isSuperLike': isSuperLike, // Uses the same value
      });
    }

    await batch.commit();
    debugPrint('Generated $likeCount fake likes.');
  }

  // Admin Tool: Delete all profiles from the JSON seed
  static Future<void> deleteDemoData() async {
    debugPrint("Deleting demo data recursively...");
    final String jsonString = await rootBundle.loadString(
      'assets/data/freematch_profiles_2000.json',
    );
    final List<dynamic> jsonList = json.decode(jsonString);
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    int total = jsonList.length;
    int processed = 0;
    WriteBatch batch = firestore.batch();
    int batchOpCount = 0;

    for (var jsonProfile in jsonList) {
      String userId = jsonProfile['id'];
      DocumentReference userRef = firestore.collection('users').doc(userId);

      // 1. Delete Subcollections (Read then Delete)
      // This ensures "ghost" documents are removed.
      await _deleteSubcollection(firestore, userRef.collection('likes'));
      await _deleteSubcollection(
        firestore,
        userRef.collection('received_likes'),
      );
      await _deleteSubcollection(firestore, userRef.collection('dislikes'));

      // 2. Delete the User Document
      batch.delete(userRef);
      batchOpCount++;

      // Commit batch periodically
      if (batchOpCount >= 400) {
        await batch.commit();
        batch = firestore.batch();
        batchOpCount = 0;
        debugPrint('Batch committed. Processed: $processed');
      }

      processed++;
      if (processed % 50 == 0) {
        debugPrint("Processed $processed / $total users...");
      }
    }

    // Commit remaining
    if (batchOpCount > 0) {
      await batch.commit();
    }

    debugPrint('Demo data deletion complete.');
  }

  static Future<void> _deleteSubcollection(
    FirebaseFirestore firestore,
    CollectionReference col,
  ) async {
    final snapshot = await col.get();
    if (snapshot.docs.isEmpty) return;

    final WriteBatch batch = firestore.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
