class ChatMessage {
  final String id;
  final String text;
  final String timestamp;
  final bool isMe;
  final String type; // 'TEXT', 'GIFT', 'GIF', 'IMAGE'
  final String? mediaUrl;
  bool liked;

  ChatMessage({
    required this.id,
    required this.text,
    required this.timestamp,
    required this.isMe,
    this.type = 'TEXT',
    this.mediaUrl,
    this.liked = false,
  });
}
