import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'local_db_service.dart';
import '../models/local/local_message.dart';

final chatServiceProvider = Provider((ref) {
  final localDB = ref.watch(localDBServiceProvider);
  return ChatService(localDB);
});

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LocalDBService _localDb;

  ChatService(this._localDb);

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

  // --- HYBRID SYNC IMPLEMENTATION ---

  // --- HYBRID SYNC IMPLEMENTATION ---

  // _localDb is now injected via constructor

  Future<void> initLocalDb() async {
    // Ideally called at app startup
    try {
      await _localDb.init();
    } catch (e) {
      // Handle if already initialized
    }
  }

  /// 1. Send Message: Optimistic Local Update + Cloud Write
  Future<void> sendMessage(
    String chatId,
    String senderId,
    String text, {
    String type = 'TEXT',
    String? mediaUrl,
  }) async {
    final timestamp = DateTime.now();

    // A. Create Local Message (Optimistic)
    // Use a temp ID until we get Firestore ID.
    // However, Hive keys need to be consistent.
    // Strategy: We won't save to local DB *immediately* unless we really want offline-first sending.
    // For MVP "Smart Cache": Write to Firestore, wait for response, THEN save to Local.
    // This avoids "Pending/Error" state complexity for now.
    // The UI will likely see the update via the Stream instantly if we return local stream.
    // BETTER: Write to local with isSynced=false, then update.

    // For simplicity in this iteration (Cost Reduction focus):
    // 1. Write to Firestore.
    // 2. On success, Write to Local DB.

    final docRef = await _firestore
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

    // 3. Save to Local DB (so we don't need to fetch it back)
    final localMsg = LocalMessage(
      firestoreId: docRef.id,
      chatId: chatId,
      senderId: senderId,
      text: text,
      type: type,
      mediaUrl: mediaUrl,
      timestamp: timestamp,
      isSynced: true,
    );
    await _localDb.saveMessage(localMsg);

    // 4. Update Chat Metadata
    await _firestore.collection('chats').doc(chatId).update({
      'lastMessage': type == 'TEXT' ? text : 'Sent a $type',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });
  }

  /// 2. Get Messages: Local Stream + Background Sync
  /// Returns a Stream of Local Messages.
  Stream<List<LocalMessage>> getMessages(String chatId) async* {
    // Ensure DB is ready (lazy init if needed, or rely on main)
    // await initLocalDb();

    // A. Emit Local Data immediately
    // Hive Watch? Hive doesn't have a built-in query stream like Firestore easily without "watch()".
    // Box.watch() emits events for the whole box.
    // We can filter on the fly.

    yield _localDb.getMessages(chatId);

    // B. Trigger Sync in Background
    _syncMessages(chatId);

    // C. Watch for Local DB changes (e.g. when Sync finishes or new msg sent)
    await for (final _ in _localDb.box.watch()) {
      // This event stream captures ANY change in the box.
      // Optimization: Check if event.key relates to this chat if possible?
      // Since we filter anyway, just re-emit.
      yield _localDb.getMessages(chatId);
    }
  }

  /// 3. Sync Logic: Fetch only NEW messages from Firestore
  Future<void> _syncMessages(String chatId) async {
    final lastTime = _localDb.getLastMessageTimestamp(chatId);

    Query query = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false); // Oldest to Newest for sync

    if (lastTime != null) {
      // Add buffer (e.g. 1ms) to avoid duplicates, or use >
      final lastDate = DateTime.fromMillisecondsSinceEpoch(lastTime);
      query = query.where(
        'timestamp',
        isGreaterThan: Timestamp.fromDate(lastDate),
      );
    }

    final snapshot = await query.get();

    if (snapshot.docs.isNotEmpty) {
      debugPrint("Syncing ${snapshot.docs.length} new messages for $chatId");
      final newMessages = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        // Handle timestamp safely (can be null for rapid local writes if we read pending, but here it's from server)
        final ts =
            (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

        return LocalMessage(
          firestoreId: doc.id,
          chatId: chatId,
          senderId: data['senderId'] ?? '',
          text: data['text'] ?? '',
          type: data['type'] ?? 'TEXT',
          mediaUrl: data['mediaUrl'],
          timestamp: ts,
          isSynced: true,
        );
      }).toList();

      await _localDb.saveMessages(newMessages);
    } else {
      debugPrint("Chat $chatId is up to date.");
    }
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

  // Unmatch: Delete chat and remove like records (Transactional)
  Future<void> unmatchUser(
    String chatId,
    String currentUserId,
    String otherUserId,
  ) async {
    final chatRef = _firestore.collection('chats').doc(chatId);

    final myLikeRef = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('likes')
        .doc(otherUserId);

    final otherLikeRef = _firestore
        .collection('users')
        .doc(otherUserId)
        .collection('likes')
        .doc(currentUserId);

    final myReceivedRef = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('received_likes')
        .doc(otherUserId);

    final otherReceivedRef = _firestore
        .collection('users')
        .doc(otherUserId)
        .collection('received_likes')
        .doc(currentUserId);

    await _firestore.runTransaction((transaction) async {
      // We can just delete. If doc doesn't exist, delete is ignored/safe in transaction?
      // standard Firestore transaction requires read before write IF we depend on data.
      // But for pure deletes, we can just execute.
      // However, Dart SDK `transaction.delete` does not return a Future, it just queues.

      transaction.delete(chatRef);
      transaction.delete(myLikeRef);
      transaction.delete(otherLikeRef);
      transaction.delete(myReceivedRef);
      transaction.delete(otherReceivedRef);
    });
  }

  // Report User (Firestore Write)
  Future<void> reportUser({
    required String reporterId,
    required String reportedId,
    required String reason,
    String? chatId,
  }) async {
    await _firestore.collection('reports').add({
      'reporterId': reporterId,
      'reportedId': reportedId,
      'reason': reason,
      'chatId': chatId,
      'timestamp': FieldValue.serverTimestamp(),
      'status': 'PENDING', // Admin can review and change to RESOLVED/BANNED
    });
  }

  // Block User (Transactional)
  Future<void> blockUser(
    String chatId,
    String currentUserId,
    String otherUserId,
  ) async {
    final blockRef = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('blocked_users')
        .doc(otherUserId);

    // Reuse refs from unmatch logic
    final chatRef = _firestore.collection('chats').doc(chatId);
    final myLikeRef = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('likes')
        .doc(otherUserId);
    final otherLikeRef = _firestore
        .collection('users')
        .doc(otherUserId)
        .collection('likes')
        .doc(currentUserId);
    final myReceivedRef = _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('received_likes')
        .doc(otherUserId);
    final otherReceivedRef = _firestore
        .collection('users')
        .doc(otherUserId)
        .collection('received_likes')
        .doc(currentUserId);

    await _firestore.runTransaction((transaction) async {
      // 1. Unmatch logic
      if (chatId.isNotEmpty) {
        transaction.delete(chatRef);
      }
      transaction.delete(myLikeRef);
      transaction.delete(otherLikeRef);
      transaction.delete(myReceivedRef);
      transaction.delete(otherReceivedRef);

      // 2. Block Logic
      transaction.set(blockRef, {'timestamp': FieldValue.serverTimestamp()});
    });
  }

  // --- PREMIUM FEATURES (Typing Indicators) ---

  // Update Typing Status
  Future<void> updateTypingStatus(
    String chatId,
    String userId,
    bool isTyping,
  ) async {
    // Debounce/Throttle should be handled in UI/Controller
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('typing')
        .doc(userId)
        .set({'isTyping': isTyping, 'timestamp': FieldValue.serverTimestamp()});
  }

  // Listen to other user's typing status
  Stream<bool> listenToTypingStatus(String chatId, String otherUserId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('typing')
        .doc(otherUserId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return false;
          final data = snapshot.data();
          if (data == null) return false;

          final isTyping = data['isTyping'] as bool? ?? false;
          final timestamp = data['timestamp'] as Timestamp?;

          // Auto-expire after 10 seconds if client crash/disconnect
          if (isTyping && timestamp != null) {
            final diff = DateTime.now().difference(timestamp.toDate());
            if (diff.inSeconds > 10) return false;
          }

          return isTyping;
        });
  }

  // --- PREMIUM FEATURES (Read Receipts) ---

  // Mark Chat Read
  Future<void> markChatRead(String chatId, String userId) async {
    await _firestore.collection('chats').doc(chatId).update({
      'participantsData.$userId.lastRead': FieldValue.serverTimestamp(),
    });
  }

  // Get Other User's Last Read Time
  Stream<DateTime?> getOtherUserLastRead(String chatId, String otherUserId) {
    return _firestore.collection('chats').doc(chatId).snapshots().map((
      snapshot,
    ) {
      final data = snapshot.data();
      if (data == null) return null;

      final pData = data['participantsData'] as Map<String, dynamic>?;
      if (pData == null) return null;

      final userData = pData[otherUserId] as Map<String, dynamic>?;
      if (userData == null) return null;

      final ts = userData['lastRead'] as Timestamp?;
      return ts?.toDate();
    });
  }

  // Fetch Blocked Users
  Stream<List<Map<String, dynamic>>> getBlockedUsers(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('blocked_users')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final List<Map<String, dynamic>> blocked = [];
          for (var doc in snapshot.docs) {
            final profileDoc = await _firestore
                .collection('users')
                .doc(doc.id)
                .get();
            if (profileDoc.exists) {
              final data = profileDoc.data()!;
              blocked.add({
                'id': doc.id,
                'name': data['name'] ?? 'Unknown',
                'image': (data['imageUrls'] as List?)?.firstOrNull ?? '',
              });
            }
          }
          return blocked;
        });
  }

  // Unblock User
  Future<void> unblockUser(String currentUserId, String targetUserId) async {
    await _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('blocked_users')
        .doc(targetUserId)
        .delete();
  }
}
