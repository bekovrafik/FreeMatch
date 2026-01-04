import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';
import '../widgets/custom_toast.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';

import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/storage_service.dart';
import '../screens/public_profile_screen.dart';
import '../models/user_profile.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart'; // Unused

// --- Constants (Parity with React) ---
const List<String> emojis = [
  '😀',
  '😂',
  '😍',
  '🥺',
  '😎',
  '🔥',
  '❤️',
  '🍆',
  '🍑',
  '🍻',
  '👋',
  '👀',
  '😭',
  '🥳',
  '🥰',
  '🤪',
  '🤩',
  '😡',
  '😱',
  '🤢',
  '🤮',
  '🤧',
  '😵',
  '👍',
  '👎',
];

const List<Map<String, String>> gifts = [
  {
    'url': 'https://cdn-icons-png.flaticon.com/512/2935/2935413.png',
    'name': 'Coffee',
  },
  {
    'url': 'https://cdn-icons-png.flaticon.com/512/1404/1404945.png',
    'name': 'Pizza',
  },
  {
    'url': 'https://cdn-icons-png.flaticon.com/512/742/742751.png',
    'name': 'Rose',
  },
  {
    'url': 'https://cdn-icons-png.flaticon.com/512/4710/4710922.png',
    'name': 'Teddy',
  },
  {
    'url': 'https://cdn-icons-png.flaticon.com/512/1139/1139982.png',
    'name': 'Party',
  },
  {
    'url': 'https://cdn-icons-png.flaticon.com/512/3112/3112946.png',
    'name': 'Trophy',
  },
  {
    'url': 'https://cdn-icons-png.flaticon.com/512/938/938063.png',
    'name': 'Ice Cream',
  },
  {
    'url': 'https://cdn-icons-png.flaticon.com/512/869/869869.png',
    'name': 'Sun',
  },
  {
    'url': 'https://cdn-icons-png.flaticon.com/512/1076/1076928.png',
    'name': 'Ring',
  },
];

const List<Map<String, dynamic>> mockGifs = [
  {
    'id': 'g1',
    'url': 'https://media.giphy.com/media/l0HlHFRbmaZtBRhXG/giphy.gif',
    'tags': ['happy', 'dance', 'excited'],
  },
  {
    'id': 'g2',
    'url': 'https://media.giphy.com/media/26BRv0ThflsHCqDrG/giphy.gif',
    'tags': ['hello', 'hi', 'wave'],
  },
  {
    'id': 'g3',
    'url': 'https://media.giphy.com/media/l2JdZO8X4Q2X3y7Di/giphy.gif',
    'tags': ['love', 'heart', 'romance'],
  },
  {
    'id': 'g4',
    'url': 'https://media.giphy.com/media/3o7TKoWXm3okO1kgHC/giphy.gif',
    'tags': ['funny', 'laugh', 'lol'],
  },
  {
    'id': 'g5',
    'url': 'https://media.giphy.com/media/xT5LMB2WiOdjpB7K4o/giphy.gif',
    'tags': ['yes', 'agree', 'nod'],
  },
];

class ChatDetailScreen extends ConsumerStatefulWidget {
  final Map<String, String> match;

  const ChatDetailScreen({super.key, required this.match});

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  // Audio State
  late AudioRecorder _audioRecorder;
  late AudioPlayer _audioPlayer;
  bool _isRecording = false;
  // String? _recordPath; // Unused
  String? _playingUrl;
  bool _isPlaying = false;

  bool _showEmoji = false;
  bool _showGift = false;
  bool _showGif = false;
  String _gifSearch = '';

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _audioPlayer = AudioPlayer();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _playingUrl = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSend(String text, {String type = 'TEXT', String? mediaUrl}) {
    if ((text.isEmpty && mediaUrl == null) || widget.match['chatId'] == null) {
      return;
    }

    final currentUser = ref.read(authServiceProvider).currentUser;
    if (currentUser == null) return;

    ref
        .read(chatServiceProvider)
        .sendMessage(
          widget.match['chatId']!,
          currentUser.uid,
          text,
          type: type,
          mediaUrl: mediaUrl,
        );
    // Note: No need to setState locally as StreamBuilder handles updates
    _textController.clear();
    _closePickers();
    // Scroll to bottom (actually top since reverse: true)
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // --- Audio Recording Methods ---

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path =
            '${dir.path}/chat_audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc),
          path: path,
        );

        setState(() {
          _isRecording = true;
          // _recordPath = path;
        });
      }
    } catch (e) {
      debugPrint("Error starting record: $e");
    }
  }

  Future<void> _stopAndSendRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        // _recordPath = path;
      });

      if (path != null) {
        final file = File(path);
        if (await file.exists()) {
          if (!mounted) return;
          CustomToast.show(context, "Sending audio...");
          final url = await ref
              .read(storageServiceProvider)
              .uploadChatVoice(file, widget.match['chatId']!);
          if (!mounted) return;
          _handleSend("Sent a voice message", type: 'AUDIO', mediaUrl: url);
        }
      }
    } catch (e) {
      debugPrint("Error stopping record: $e");
    }
  }

  // Future<void> _cancelRecording() async {
  //   await _audioRecorder.stop();
  //   setState(() {
  //     _isRecording = false;
  //     // _recordPath = null;
  //   });
  // }

  Future<void> _playAudio(String url) async {
    if (_playingUrl == url && _isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(UrlSource(url));
      setState(() {
        _playingUrl = url;
      });
    }
  }

  void _closePickers() {
    setState(() {
      _showEmoji = false;
      _showGift = false;
      _showGif = false;
    });
  }

  void _showActionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_off, color: Colors.white),
              title: const Text(
                "Unmatch",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () async {
                final navigator = Navigator.of(context); // Capture navigator
                navigator.pop(); // Close menu

                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF1E293B),
                    title: const Text(
                      "Unmatch?",
                      style: TextStyle(color: Colors.white),
                    ),
                    content: const Text(
                      "Are you sure? This conversation will be deleted.",
                      style: TextStyle(color: Colors.grey),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          "Unmatch",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm != true) return;
                if (!context.mounted) return;

                final currentUser = ref.read(authServiceProvider).currentUser;
                if (currentUser != null) {
                  navigator.pop(); // Close chat using captured navigator

                  await ref
                      .read(chatServiceProvider)
                      .unmatchUser(
                        widget.match['chatId']!,
                        currentUser.uid,
                        widget.match['id'] ?? '',
                      );

                  if (context.mounted) {
                    CustomToast.show(context, "Unmatched.");
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.white),
              title: const Text(
                "Block",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () async {
                final navigator = Navigator.of(context); // Capture navigator
                navigator.pop(); // Close menu

                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF1E293B),
                    title: const Text(
                      "Unmatch?",
                      style: TextStyle(color: Colors.white),
                    ),
                    content: const Text(
                      "Are you sure? This conversation will be deleted.",
                      style: TextStyle(color: Colors.grey),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          "Unmatch",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm != true) return;
                if (!context.mounted) return;

                final currentUser = ref.read(authServiceProvider).currentUser;
                if (currentUser != null) {
                  navigator.pop(); // Close chat using captured navigator

                  await ref
                      .read(chatServiceProvider)
                      .unmatchUser(
                        widget.match['chatId']!,
                        currentUser.uid,
                        widget.match['id'] ?? '',
                      );

                  if (context.mounted) {
                    CustomToast.show(context, "Unmatched.");
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.white),
              title: const Text(
                "Block",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () async {
                final navigator = Navigator.of(context); // Capture navigator
                navigator.pop(); // Close menu

                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: const Color(0xFF1E293B),
                    title: const Text(
                      "Block User?",
                      style: TextStyle(color: Colors.white),
                    ),
                    content: const Text(
                      "They will be unmatched and won't be able to see your profile.",
                      style: TextStyle(color: Colors.grey),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          "Block",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm != true) return;
                if (!context.mounted) return;

                final currentUser = ref.read(authServiceProvider).currentUser;
                if (currentUser != null) {
                  navigator.pop(); // Close chat using captured navigator

                  await ref
                      .read(chatServiceProvider)
                      .blockUser(
                        widget.match['chatId']!,
                        currentUser.uid,
                        widget.match['id'] ?? '',
                      );

                  if (context.mounted) {
                    CustomToast.show(context, "Blocked user.", isError: true);
                  }
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.report, color: Colors.red),
              title: const Text(
                "Report",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                CustomToast.show(context, "Reported user.", isError: true);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 70,
      );
      if (image == null) return;

      if (!mounted) return;
      CustomToast.show(context, "Uploading image...");

      final url = await ref
          .read(storageServiceProvider)
          .uploadChatImage(File(image.path), widget.match['chatId']!);

      _handleSend("Sent an image", type: 'IMAGE', mediaUrl: url);
    } catch (e) {
      if (mounted) {
        CustomToast.show(context, "Failed to upload image", isError: true);
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text(
                'Camera',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.purple),
              title: const Text(
                'Gallery',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617), // Slate-950
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A), // Slate-900
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onTap: () {
            // Reconstruct a UserProfile object from the map
            // Note: In a real app, you should pass UserProfile directly to ChatDetailScreen
            final profile = UserProfile(
              id: widget.match['id'] ?? '',
              name: widget.match['name'] ?? 'Unknown',
              age: 24, // Fallback/Fetch needed
              bio: "Hey there! I'm using FreeMatch.", // Fallback/Fetch needed
              profession: "FreeMatch User", // Fallback/Fetch needed
              imageUrls: [
                if (widget.match['image'] != null &&
                    widget.match['image']!.isNotEmpty)
                  widget.match['image']!,
              ],
              interests: [],
              location: "Nearby",
              gender: "Female",
              distance: 5,
              lastActive: DateTime.now().millisecondsSinceEpoch,
              joinedDate: DateTime.now().millisecondsSinceEpoch,
            );

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PublicProfileScreen(profile: profile),
              ),
            );
          },
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: CachedNetworkImageProvider(
                  widget.match['image'] ?? '',
                ),
                radius: 18,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.match['name'] ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "Active now",
                    style: TextStyle(color: Colors.green, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.grey),
            onPressed: _showActionsMenu,
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: ref
                  .watch(chatServiceProvider)
                  .getMessages(widget.match['chatId']!),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "No messages yet",
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }
                final messages = docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final currentUser = ref.read(authServiceProvider).currentUser;
                  final isMe = data['senderId'] == currentUser?.uid;

                  return ChatMessage(
                    id: doc.id,
                    text: data['text'] ?? '',
                    timestamp:
                        "Just now", // Format timestamp properly in real app
                    isMe: isMe,
                    type: data['type'] ?? 'TEXT',
                    mediaUrl: data['mediaUrl'],
                  );
                }).toList();

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  reverse: true, // Messages come newest first from Query
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return _buildMessageBubble(messages[index]);
                  },
                );
              },
            ),
          ),

          // Pickers Area
          if (_showEmoji) _buildEmojiPicker(),
          if (_showGift) _buildGiftPicker(),
          if (_showGif) _buildGifPicker(),

          // Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            color: const Color(0xFF0F172A),
            child: SafeArea(
              // Handle bottom notch
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    color: Colors.cyan,
                    onPressed: _showImageSourceDialog,
                  ),
                  IconButton(
                    icon: const Icon(Icons.emoji_emotions_outlined),
                    color: _showEmoji ? Colors.amber : Colors.grey,
                    onPressed: () {
                      _closePickers();
                      setState(() => _showEmoji = !_showEmoji);
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.gif_box_outlined,
                    ), // Using available icon, lucide had Clapperboard
                    color: _showGif ? Colors.blue : Colors.grey,
                    onPressed: () {
                      _closePickers();
                      setState(() => _showGif = !_showGif);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.card_giftcard),
                    color: _showGift ? Colors.pink : Colors.grey,
                    onPressed: () {
                      _closePickers();
                      setState(() => _showGift = !_showGift);
                    },
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        controller: _textController,
                        onTap: _closePickers,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: "Type a message...",
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        onSubmitted: (val) => _handleSend(val),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // MIC OR SEND BUTTON
                  if (_isRecording)
                    GestureDetector(
                      onLongPressUp:
                          _stopAndSendRecording, // Support hold patterns if desired later
                      onTap: _stopAndSendRecording,
                      child: Container(
                        padding: const EdgeInsets.all(12), // Bigger
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.stop,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    )
                  else if (_textController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () => _handleSend(_textController.text),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Colors.amber,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.send,
                          color: Colors.black,
                          size: 20,
                        ),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: _startRecording,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.mic,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isMe = msg.isMe;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              backgroundImage: CachedNetworkImageProvider(
                widget.match['image'] ?? '',
              ),
              radius: 12,
            ),
            const SizedBox(width: 8),
          ],

          Flexible(
            child: GestureDetector(
              onDoubleTap: () {
                setState(() {
                  msg.liked = !msg.liked;
                });
              },
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  // Content
                  if (msg.type == 'TEXT')
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isMe
                            ? Colors.amber[700]
                            : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: isMe
                              ? const Radius.circular(16)
                              : Radius.zero,
                          bottomRight: isMe
                              ? Radius.zero
                              : const Radius.circular(16),
                        ),
                      ),
                      child: Text(
                        msg.text,
                        style: const TextStyle(color: Colors.white),
                      ),
                    )
                  else if (msg.type == 'GIFT')
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        children: [
                          CachedNetworkImage(
                            imageUrl: msg.mediaUrl!,
                            width: 80,
                            height: 80,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            msg.text,
                            style: const TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (msg.type == 'GIF' || msg.type == 'IMAGE')
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: msg.mediaUrl!,
                        width: 200,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 200,
                          height: 200,
                          color: Colors.grey[900],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ),
                    ),

                  if (msg.type == 'AUDIO')
                    Container(
                      width: 200,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isMe
                            ? Colors.amber[700]
                            : const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => _playAudio(msg.mediaUrl!),
                            child: CircleAvatar(
                              backgroundColor: Colors.white,
                              radius: 18,
                              child: Icon(
                                (_playingUrl == msg.mediaUrl && _isPlaying)
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Timestamp & Like
                  if (msg.liked)
                    const Padding(
                      padding: EdgeInsets.only(top: 4.0),
                      child: Icon(Icons.favorite, size: 14, color: Colors.red),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      msg.timestamp,
                      style: TextStyle(color: Colors.grey[600], fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper for Audio Bubble (Extracted or Inline)
  // Assuming this replaces or appends for specific types
  // The original _buildMessageBubble handles 'TEXT', 'GIFT', 'GIF', 'IMAGE'.
  // We need to inject 'AUDIO' logic inside the first `children` list of the Column.

  Widget _buildEmojiPicker() {
    return Container(
      height: 250,
      color: const Color(0xFF0F172A),
      child: GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 7,
        ),
        itemCount: emojis.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              _textController.text += emojis[index];
            },
            child: Center(
              child: Text(emojis[index], style: const TextStyle(fontSize: 24)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGiftPicker() {
    return Container(
      height: 250,
      color: const Color(0xFF0F172A),
      child: GridView.builder(
        padding: const EdgeInsets.all(10),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: gifts.length,
        itemBuilder: (context, index) {
          final gift = gifts[index];
          return GestureDetector(
            onTap: () =>
                _handleSend(gift['name']!, type: 'GIFT', mediaUrl: gift['url']),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CachedNetworkImage(
                    imageUrl: gift['url']!,
                    height: 40,
                    width: 40,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    gift['name']!,
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGifPicker() {
    // Filter logic
    final gifs = _gifSearch.isEmpty
        ? mockGifs
        : mockGifs
              .where(
                (g) =>
                    (g['tags'] as List<String>?)?.contains(_gifSearch) ?? false,
              )
              .toList();

    return Container(
      height: 250,
      color: const Color(0xFF0F172A),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (val) => setState(() => _gifSearch = val),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search GIPHY...",
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
              ),
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.5,
              ),
              itemCount: gifs.length,
              itemBuilder: (context, index) {
                final gif = gifs[index];
                return GestureDetector(
                  onTap: () =>
                      _handleSend('', type: 'GIF', mediaUrl: gif['url']),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: gif['url']!,
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
