import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final chatServiceProvider = Provider((ref) => ChatService());

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create or Get existing Chat
  Future<String> createChat(
    String currentUserId,
    String otherUserId, {
    Map<String, dynamic>? otherUserData, // {name, image}
    Map<String, dynamic>? currentUserData, // {name, image}
  }) async {
    // Check if chat exists (naive approach: query by participants)
    final query = await _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .get();

    for (var doc in query.docs) {
      final participants = List<String>.from(doc['participants']);
      if (participants.contains(otherUserId)) {
        return doc.id;
      }
    }

    // Fetch missing data if needed
    Map<String, dynamic> finalCurrentUserData = currentUserData ?? {};
    if (currentUserData == null) {
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        finalCurrentUserData = {
          'name': data['name'] ?? '',
          'image': (data['imageUrls'] as List?)?.firstOrNull ?? '',
        };
      }
    }

    Map<String, dynamic> finalOtherUserData = otherUserData ?? {};
    if (otherUserData == null) {
      final userDoc = await _firestore
          .collection('users')
          .doc(otherUserId)
          .get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        finalOtherUserData = {
          'name': data['name'] ?? '',
          'image': (data['imageUrls'] as List?)?.firstOrNull ?? '',
        };
      }
    }

    // Create new chat
    final docRef = await _firestore.collection('chats').add({
      'participants': [currentUserId, otherUserId],
      'participantsData': {
        currentUserId: finalCurrentUserData,
        otherUserId: finalOtherUserData,
      },
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  Future<void> sendMessage(
    String chatId,
    String senderId,
    String text, {
    String type = 'TEXT',
    String? mediaUrl,
  }) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
          'senderId': senderId,
          'text': text,
          'timestamp': FieldValue.serverTimestamp(),
          'type': type,
          'mediaUrl': mediaUrl,
        });

    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': type == 'TEXT' ? text : 'Sent a $type',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Fetch chats for the current user
  Stream<QuerySnapshot> getUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots();
  }

  // Get match count
  Future<int> getMatchCount(String userId) async {
    final snapshot = await _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  // Unmatch: Delete chat and remove like records
  Future<void> unmatchUser(
    String chatId,
    String currentUserId,
    String otherUserId,
  ) async {
    // 1. Delete Chat
    await _firestore.collection('chats').doc(chatId).delete();

    // 2. Remove Match (Likes) - specific path depends on FirestoreService recordSwipe
    // We remove the 'like' from currentUser -> otherUser
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('likes')
        .doc(otherUserId)
        .delete();

    // Remove the 'like' from otherUser -> currentUser (mutual)
    await _firestore
        .collection('users')
        .doc(otherUserId)
        .collection('likes')
        .doc(currentUserId)
        .delete();

    // Also remove from received_likes to be thorough
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('received_likes')
        .doc(otherUserId)
        .delete();
    await _firestore
        .collection('users')
        .doc(otherUserId)
        .collection('received_likes')
        .doc(currentUserId)
        .delete();
  }

  // Block User
  Future<void> blockUser(
    String chatId,
    String currentUserId,
    String otherUserId,
  ) async {
    // 1. Unmatch (Clean up chat and likes)
    await unmatchUser(chatId, currentUserId, otherUserId);

    // 2. Add to Blocked
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('blocked_users')
        .doc(otherUserId)
        .set({'timestamp': FieldValue.serverTimestamp()});
  }
}
