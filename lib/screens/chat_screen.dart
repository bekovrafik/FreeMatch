import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import 'chat_detail_screen.dart';
import 'likes_screen.dart';
import '../providers/unlocked_profiles_provider.dart';
import '../services/admob_service.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  bool _isLoadingAd = false;

  void _openChat(BuildContext context, Map<String, dynamic> match) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ChatDetailScreen(match: Map<String, String>.from(match)),
      ),
    );
  }

  void _showAd(String profileId) {
    if (_isLoadingAd) return;
    setState(() => _isLoadingAd = true);

    ref
        .read(admobServiceProvider)
        .loadRewardedInterstitialAd(
          onAdLoaded: (ad) {
            setState(() => _isLoadingAd = false);
            ad.show(
              onUserEarnedReward: (adWithoutView, reward) {
                ref.read(unlockedProfilesProvider.notifier).unlock(profileId);
              },
            );
          },
          onAdFailedToLoad: (error) {
            setState(() => _isLoadingAd = false);
            debugPrint('Ad failed to load: $error');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Failed to load ad. Please try again."),
              ),
            );
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authServiceProvider).currentUser;
    final unlockedProfiles = ref.watch(unlockedProfilesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF020617), // Slate-950
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Header & Search
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Matches",
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        decoration: InputDecoration(
                          hintText: "Search matches...",
                          hintStyle: TextStyle(color: Colors.grey[600]),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey[600],
                          ),
                          filled: true,
                          fillColor: const Color(0xFF1E293B), // Slate-800
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),

              // Likes You Row
              if (currentUser != null)
                StreamBuilder<List<UserProfile>>(
                  stream: ref
                      .watch(firestoreServiceProvider)
                      .getWhoLikedMe(currentUser.uid),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      debugPrint("Error loading likes: ${snapshot.error}");
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            "Error loading likes: ${snapshot.error}",
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const SliverToBoxAdapter(child: SizedBox.shrink());
                    }

                    final likes = snapshot.data ?? [];

                    if (likes.isEmpty) {
                      return const SliverToBoxAdapter(child: SizedBox.shrink());
                    }

                    return SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "LIKES YOU (${likes.length})",
                                  style: TextStyle(
                                    color: Colors.pink[400],
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                    fontSize: 12,
                                  ),
                                ),
                                if (likes.isNotEmpty)
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const LikesScreen(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      "SEE ALL",
                                      style: TextStyle(
                                        color: Colors.blue[400],
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 110,
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              scrollDirection: Axis.horizontal,
                              itemCount: likes.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(width: 12),
                              itemBuilder: (context, index) {
                                final profile = likes[index];
                                final isUnlocked = unlockedProfiles.contains(
                                  profile.id,
                                );

                                return GestureDetector(
                                  onTap: () {
                                    if (isUnlocked) {
                                      // Show minimal profile details
                                      showDialog(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          contentPadding: EdgeInsets.zero,
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              if (profile.imageUrls.isNotEmpty)
                                                Image.network(
                                                  profile.imageUrls.first,
                                                  height: 200,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                ),
                                              Padding(
                                                padding: const EdgeInsets.all(
                                                  16.0,
                                                ),
                                                child: Text(
                                                  "${profile.name}, ${profile.age}",
                                                  style: const TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 16.0,
                                                    ),
                                                child: Text(
                                                  "Swipe right on them in the feed to match!",
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 16),
                                            ],
                                          ),
                                        ),
                                      );
                                    } else {
                                      _showAd(profile.id);
                                    }
                                  },
                                  child: Stack(
                                    children: [
                                      ImageFiltered(
                                        imageFilter: ImageFilter.blur(
                                          sigmaX: isUnlocked ? 0 : 10,
                                          sigmaY: isUnlocked ? 0 : 10,
                                        ),
                                        child: Column(
                                          children: [
                                            Container(
                                              width: 70,
                                              height: 70,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: Colors.pink,
                                                  width: 2,
                                                ),
                                                image: DecorationImage(
                                                  image:
                                                      CachedNetworkImageProvider(
                                                        profile
                                                                .imageUrls
                                                                .isNotEmpty
                                                            ? profile
                                                                  .imageUrls
                                                                  .first
                                                            : '',
                                                      ),
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              profile.name,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (!isUnlocked)
                                        Positioned.fill(
                                          child: Center(
                                            child: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withValues(
                                                  alpha: 0.6,
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.lock,
                                                color: Colors.white,
                                                size: 20,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Messages List (Real Data)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    "MESSAGES",
                    style: TextStyle(
                      color: Colors.blueGrey[400],
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),

              if (currentUser == null)
                const SliverToBoxAdapter(
                  child: Center(child: Text("Please sign in to view chats")),
                )
              else
                StreamBuilder<QuerySnapshot>(
                  stream: ref
                      .watch(chatServiceProvider)
                      .getUserChats(currentUser.uid),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return SliverToBoxAdapter(
                        child: Center(child: Text('Error: ${snapshot.error}')),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SliverToBoxAdapter(
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final docs = snapshot.data?.docs ?? [];

                    if (docs.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  "No chats yet. Start swiping!",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final chatId = docs[index].id;
                        final participants = List<String>.from(
                          data['participants'],
                        );

                        // Identify Other User
                        final otherUserId = participants.firstWhere(
                          (id) => id != currentUser.uid,
                          orElse: () =>
                              currentUser.uid, // Should not happen ideally
                        );

                        // Extract Cached Data
                        final participantsData =
                            data['participantsData'] as Map<String, dynamic>? ??
                            {};
                        final otherUserData =
                            participantsData[otherUserId]
                                as Map<String, dynamic>? ??
                            {};

                        final otherName = otherUserData['name'] ?? 'User';
                        final otherImage = otherUserData['image'] ?? '';
                        final lastMessage = data['lastMessage'] ?? '';

                        // Timestamp formatting
                        String timeDisplay = '';
                        if (data['lastMessageTime'] != null) {
                          final ts = (data['lastMessageTime'] as Timestamp)
                              .toDate();
                          final diff = DateTime.now().difference(ts);
                          if (diff.inMinutes < 60) {
                            timeDisplay = '${diff.inMinutes}m ago';
                          } else if (diff.inHours < 24) {
                            timeDisplay = '${diff.inHours}h ago';
                          } else {
                            timeDisplay = '${diff.inDays}d ago';
                          }
                        }

                        if (otherName == 'User' || otherName.isEmpty) {
                          // Fallback: Fetch profile directly
                          return FutureBuilder<UserProfile?>(
                            future: ref
                                .read(firestoreServiceProvider)
                                .getUserProfile(otherUserId),
                            builder: (context, userSnapshot) {
                              final user = userSnapshot.data;
                              final fallbackName = user?.name ?? 'User';
                              final fallbackImage =
                                  (user?.imageUrls.isNotEmpty ?? false)
                                  ? user!.imageUrls.first
                                  : '';

                              return _buildChatTile(
                                context,
                                chatId,
                                otherUserId,
                                fallbackName,
                                fallbackImage,
                                lastMessage,
                                timeDisplay,
                              );
                            },
                          );
                        }

                        return _buildChatTile(
                          context,
                          chatId,
                          otherUserId,
                          otherName,
                          otherImage,
                          lastMessage,
                          timeDisplay,
                        );
                      }, childCount: docs.length),
                    );
                  },
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
          if (_isLoadingAd)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.amber),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChatTile(
    BuildContext context,
    String chatId,
    String otherUserId,
    String name,
    String image,
    dynamic lastMessage,
    String timeDisplay,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        radius: 28,
        backgroundImage: image.isNotEmpty
            ? CachedNetworkImageProvider(image)
            : null,
        backgroundColor: Colors.amber,
        child: image.isEmpty
            ? Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              )
            : null,
      ),
      title: Text(
        name,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        lastMessage.toString().isNotEmpty
            ? lastMessage.toString()
            : "New Match! Say Hello 👋",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: lastMessage.toString().isNotEmpty
              ? Colors.grey[500]
              : Colors.pinkAccent,
          fontWeight: lastMessage.toString().isNotEmpty
              ? FontWeight.normal
              : FontWeight.bold,
        ),
      ),
      trailing: Text(
        timeDisplay,
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
      onTap: () {
        _openChat(context, {
          'id': otherUserId,
          'name': name,
          'image': image,
          'chatId': chatId,
        });
      },
    );
  }
}
