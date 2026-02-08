import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/local/local_message.dart';

final localDBServiceProvider = Provider<LocalDBService>((ref) {
  throw UnimplementedError(
    'localDBServiceProvider must be overridden in main.dart',
  );
});

class LocalDBService {
  static const String messageBoxName = 'messages';
  Box<LocalMessage>? _messageBox;

  Future<void> init() async {
    try {
      print("DEBUG: LocalDBService init started");
      await Hive.initFlutter();
      Hive.registerAdapter(LocalMessageAdapter());
      _messageBox = await Hive.openBox<LocalMessage>(messageBoxName);
      print(
        "DEBUG: LocalDBService init completed. Box is open: ${_messageBox?.isOpen}",
      );
    } catch (e) {
      print("DEBUG: LocalDBService init failed: $e");
      rethrow;
    }
  }

  Box<LocalMessage> get box {
    if (_messageBox == null) {
      throw Exception('Hive not initialized. Call init() first.');
    }
    return _messageBox!;
  }

  /// Save a single message
  Future<void> saveMessage(LocalMessage message) async {
    // We use firestoreId as the key if available to prevent duplicates
    // OR composite key chatId_timestamp
    // For simplicity, let's use firestoreId as key if it's reliable.
    // If firestoreId is empty (pending), we use a temp ID or let Hive auto-increment?
    // Let's use firestoreId. If it's a pending local message, we give it a temp UUID.
    await box.put(message.firestoreId, message);
  }

  /// Save multiple messages (batch sync)
  Future<void> saveMessages(List<LocalMessage> messages) async {
    final Map<String, LocalMessage> entries = {
      for (var m in messages) m.firestoreId: m,
    };
    await box.putAll(entries);
  }

  /// Get messages for a specific chat
  /// Note: Hive is a key-value store. Filtering is O(N) unless we use indices.
  /// For < 10k messages total, O(N) is usually fine in Dart (~5-10ms).
  /// Optimization: Store specific lists of IDs per Chat in another box if needed.
  List<LocalMessage> getMessages(String chatId) {
    if (_messageBox == null) return [];

    final all = _messageBox!.values.where((m) => m.chatId == chatId).toList();
    // Sort by timestamp descending (newest first) or ascending depending on UI needs
    // Typically chat UI wants reverse: newest at bottom (index 0 for reverse list)
    // Firestore queries usually give newest first?
    all.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return all;
  }

  /// Get last sync timestamp for a chat to minimize Firestore reads
  int? getLastMessageTimestamp(String chatId) {
    if (_messageBox == null) return null;

    // This is inefficient (O(N)), but safe for MVP.
    // Optimization: Maintain a separate 'Metadata' box {chatId: lastTimestamp}
    final messages = _messageBox!.values.where((m) => m.chatId == chatId);
    if (messages.isEmpty) return null;

    final lastMsg = messages.reduce(
      (a, b) => a.timestamp.compareTo(b.timestamp) > 0 ? a : b,
    );
    return lastMsg.timestamp.millisecondsSinceEpoch;
  }

  Future<void> clearChat(String chatId) async {
    final keys = _messageBox!.values
        .where((m) => m.chatId == chatId)
        .map((m) => m.key)
        .toList();
    await _messageBox!.deleteAll(keys);
  }
}
