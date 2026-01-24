import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:giphy_get/giphy_get.dart';
import '../models/chat_message.dart';
import '../widgets/custom_toast.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/storage_service.dart';
import '../screens/public_profile_screen.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:permission_handler/permission_handler.dart'; // Unused

// --- Constants (Parity with React) ---

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

  Future<void> _showGifPicker() async {
    // Public Beta Key - User should replace with their own if needed
    const apiKey = 'Phix89D55M26';

    final GiphyGif? gif = await GiphyGet.getGif(
      context: context,
      apiKey: apiKey,
      lang: GiphyLanguage.english,
      randomID: "freematch_user", // Should be unique user ID in prod
      tabColor: Colors.pink,
      modal: false, // Full screen
      showEmojis: false,
    );

    if (gif != null && mounted) {
      // Use fixed_width for better performance/size in chat
      final url = gif.images?.fixedWidth.url ?? gif.images?.original?.url;
      if (url != null) {
        _handleSend("Sent a GIF", type: 'GIF', mediaUrl: url);
      }
    }
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
          onTap: () async {
            // Fetch real profile from Firestore to ensure we have all details
            final profileId = widget.match['id'];
            if (profileId != null) {
              final userProfile = await ref
                  .read(firestoreServiceProvider)
                  .getUserProfile(profileId);

              if (userProfile != null && context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PublicProfileScreen(profile: userProfile),
                  ),
                );
              }
            }
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
                    icon: const Icon(Icons.gif_box_outlined),
                    color: Colors.pink,
                    onPressed: _showGifPicker,
                  ),

                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextField(
                        controller: _textController,

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
                    Builder(
                      builder: (context) {
                        // Check if text is only emojis
                        final isEmojiOnly = RegExp(
                          r'^(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])+$',
                        ).hasMatch(msg.text.replaceAll(' ', ''));

                        return Container(
                          padding: isEmojiOnly
                              ? EdgeInsets.zero
                              : const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                          decoration: isEmojiOnly
                              ? null
                              : BoxDecoration(
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
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: isEmojiOnly ? 40 : 14,
                            ),
                          ),
                        );
                      },
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
                        errorWidget: (context, url, error) => Container(
                          width: 200,
                          height: 200,
                          color: Colors.grey[900],
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image, color: Colors.grey),
                              SizedBox(height: 8),
                              Text(
                                "Failed to load",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                              ),
                            ],
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
}
