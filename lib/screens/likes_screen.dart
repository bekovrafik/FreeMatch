import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../services/admob_service.dart';
import '../providers/unlocked_profiles_provider.dart';
import 'public_profile_screen.dart';

class LikesScreen extends ConsumerStatefulWidget {
  const LikesScreen({super.key});

  @override
  ConsumerState<LikesScreen> createState() => _LikesScreenState();
}

class _LikesScreenState extends ConsumerState<LikesScreen> {
  // Local state removed in favor of provider
  bool _isLoadingAd = false;

  void _handleProfileTap(UserProfile profile, bool isUnlocked) {
    if (isUnlocked) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PublicProfileScreen(
            profile: profile.copyWith(hasLikedCurrentUser: true),
          ),
        ),
      );
    } else {
      _showAd(profile.id);
    }
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
                // Update Global Provider
                ref.read(unlockedProfilesProvider.notifier).unlock(profileId);
              },
            );
          },
          onAdFailedToLoad: (error) {
            setState(() => _isLoadingAd = false);
            debugPrint('Ad failed to load: $error');
            // Optional: Show fallback or error message
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
      appBar: AppBar(
        title: const Text(
          "Who Liked You",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0F172A), // Slate-900
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: currentUser == null
          ? const Center(
              child: Text(
                "Please login to see likes",
                style: TextStyle(color: Colors.white),
              ),
            )
          : Stack(
              children: [
                StreamBuilder<List<UserProfile>>(
                  stream: ref
                      .watch(firestoreServiceProvider)
                      .getWhoLikedMe(currentUser.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final likes = snapshot.data ?? [];

                    if (likes.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.favorite_border,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              "No likes yet",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Keep swiping to find your match!",
                              style: TextStyle(color: Colors.grey[400]),
                            ),
                          ],
                        ),
                      );
                    }

                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: likes.length,
                      itemBuilder: (context, index) {
                        final profile = likes[index];
                        final isUnlocked = unlockedProfiles.contains(
                          profile.id,
                        );

                        return GestureDetector(
                          onTap: () => _handleProfileTap(profile, isUnlocked),
                          child: Stack(
                            children: [
                              // Blurred Content
                              ImageFiltered(
                                imageFilter: ImageFilter.blur(
                                  sigmaX: isUnlocked ? 0 : 10,
                                  sigmaY: isUnlocked ? 0 : 10,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E293B),
                                    borderRadius: BorderRadius.circular(16),
                                    border: profile.isSuperLike
                                        ? Border.all(
                                            color: Colors.blueAccent,
                                            width: 3,
                                          )
                                        : null,
                                    image: profile.imageUrls.isNotEmpty
                                        ? DecorationImage(
                                            image: CachedNetworkImageProvider(
                                              profile.imageUrls.first,
                                            ),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Colors.transparent,
                                          Colors.black.withValues(alpha: 0.8),
                                        ],
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "${profile.name}, ${profile.age}",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        if (profile.profession.isNotEmpty)
                                          Text(
                                            profile.profession,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // Lock Overlay
                              if (!isUnlocked)
                                Center(
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.6,
                                      ),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white54),
                                    ),
                                    child: const Icon(
                                      Icons.lock,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                ),

                              // Super Like Star
                              if (profile.isSuperLike)
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.blueAccent,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.star,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
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
}
