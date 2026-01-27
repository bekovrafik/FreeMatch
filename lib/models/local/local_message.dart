import 'package:hive/hive.dart';

part 'local_message.g.dart';

@HiveType(typeId: 0)
class LocalMessage extends HiveObject {
  @HiveField(0)
  final String firestoreId;

  @HiveField(1)
  final String chatId; // Indexable

  @HiveField(2)
  final String senderId;

  @HiveField(3)
  final String text;

  @HiveField(4)
  final String type; // 'text', 'image', 'voice'

  @HiveField(5)
  final String? mediaUrl;

  @HiveField(6)
  final DateTime timestamp;

  @HiveField(7)
  bool isSynced;

  LocalMessage({
    required this.firestoreId,
    required this.chatId,
    required this.senderId,
    required this.text,
    required this.type,
    this.mediaUrl,
    required this.timestamp,
    this.isSynced = true,
  });

  // Helper to map from map (if needed during migration)
  // or factory constructors if mapping from Firestore snapshots
}
