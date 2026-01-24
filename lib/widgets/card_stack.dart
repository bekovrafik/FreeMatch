import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_provider.dart';
import '../models/card_item.dart';
import '../models/user_profile.dart';
import '../widgets/match_overlay.dart';
import '../providers/feed_provider.dart';
import 'profile_card.dart';
import 'native_ad_card.dart';

import 'empty_state_card.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import '../screens/chat_detail_screen.dart';
import '../services/firestore_service.dart';

class CardStack extends ConsumerStatefulWidget {
  const CardStack({super.key});

  @override
  ConsumerState<CardStack> createState() => _CardStackState();
}

class _CardStackState extends ConsumerState<CardStack>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _rotateAnimation;

  Offset _dragOffset = Offset.zero;
  double _dragAngle = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(_animationController);
    _rotateAnimation = Tween<double>(
      begin: 0,
      end: 0,
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _runSpringBack() {
    _slideAnimation = Tween<Offset>(begin: _dragOffset, end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.elasticOut,
          ),
        );

    _rotateAnimation = Tween<double>(begin: _dragAngle, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward(from: 0).then((_) {
      if (mounted) {
        setState(() {
          _dragOffset = Offset.zero;
          _dragAngle = 0;
        });
      }
    });
  }

  void _triggerSwipe(Offset direction, {bool isSuperLike = false}) {
    // If animating, don't interrupt unless it's spring back (which clears itself)
    // Actually we can interrupt

    final endOffset = isSuperLike
        ? Offset(0, -MediaQuery.of(context).size.height) // Fly up off screen
        : Offset(
            direction.dx > 0
                ? MediaQuery.of(context).size.width * 1.5
                : -MediaQuery.of(context).size.width * 1.5,
            0,
          );

    _slideAnimation = Tween<Offset>(begin: _dragOffset, end: endOffset).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    final endAngle = isSuperLike ? 0.0 : (direction.dx > 0 ? 0.2 : -0.2);

    _rotateAnimation = Tween<double>(begin: _dragAngle, end: endAngle).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward(from: 0).then((_) {
      if (!mounted) return;

      // Logic after animation
      final notifier = ref.read(feedProvider.notifier);

      if (isSuperLike) {
        final userState = ref.read(userProvider);
        if (userState.superLikes <= 0) {
          // Reset if failed
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("No Super Likes left!")));
          _dragOffset = Offset.zero;
          _dragAngle = 0;
          _animationController.reset();
          setState(() {});
          return;
        }
        ref.read(userProvider.notifier).decrementSuperLike();
        HapticFeedback.heavyImpact();

        // MATCH LOGIC FOR SUPER LIKE
        final topCard = ref.read(feedProvider).value?.firstOrNull;
        if (topCard != null && topCard.type == CardType.profile) {
          final profile = topCard.data as UserProfile;
          final currentUser = ref.read(authServiceProvider).currentUser;

          if (currentUser != null) {
            final firestoreService = ref.read(firestoreServiceProvider);
            firestoreService
                .recordSwipe(
                  currentUser.uid,
                  profile.id,
                  true,
                  isSuperLike: true,
                )
                .then((_) {
                  // OPTIMISTIC MATCH (Super Like)
                  // Cloud function creates match, but we can verify client side
                  // or just wait. For now, just show overlay if verified.
                  if (profile.hasLikedCurrentUser) {
                    if (mounted) _showMatchOverlay(profile);
                  }
                });
          }
        }
        notifier.popCard();
      } else {
        // Like
        HapticFeedback.mediumImpact();
        // Match Logic Match (Parity)
        final topCard = ref.read(feedProvider).value?.firstOrNull;
        if (topCard != null) {
          // --- PROFILE SWIPE ---
          if (topCard.type == CardType.profile) {
            final profile = topCard.data as UserProfile;
            final currentUser = ref.read(authServiceProvider).currentUser;

            if (currentUser != null) {
              if (direction.dx > 0) {
                // LIKE
                final firestoreService = ref.read(firestoreServiceProvider);
                debugPrint("Recording swipe for profile: ${profile.id}");
                firestoreService
                    .recordSwipe(currentUser.uid, profile.id, true)
                    .then((_) {
                      // SERVER-SIDE MATCHING ARCHITECTURE
                      // We do NOT create the chat here. The Cloud Function does.
                      // We only show the UI overlay if we know they verified us (Optimistic).

                      if (profile.hasLikedCurrentUser) {
                        debugPrint("Optimistic Match! Showing overlay...");
                        if (mounted) {
                          _showMatchOverlay(profile);
                        }
                      }
                    });
              } else {
                // NOPE
                ref
                    .read(firestoreServiceProvider)
                    .recordSwipe(currentUser.uid, profile.id, false);
                HapticFeedback.lightImpact();
              }
            }
            notifier.popCard();
          }
          // --- AD SWIPE ---
          else if (topCard.type == CardType.ad) {
            if (direction.dx > 0) {
              // SWIPE RIGHT -> Open Link
              final ad = topCard.data as AdContent;
              launchUrl(
                Uri.parse(ad.linkUrl),
                mode: LaunchMode.externalApplication,
              );
            }
            // SWIPE LEFT -> Dismiss (Do nothing else)
            notifier.popCard();
          }
        }
      }

      // Reset
      if (mounted) {
        _dragOffset = Offset.zero;
        _dragAngle = 0;
        _animationController.reset();
        setState(() {}); // specific rebuild
      }
    });
  }

  void _showMatchOverlay(UserProfile profile) async {
    final currentUserAuth = ref.read(authServiceProvider).currentUser;
    if (currentUserAuth == null) return;

    // Fetch full profile for image
    final currentProfile = await ref
        .read(firestoreServiceProvider)
        .getUserProfile(currentUserAuth.uid);

    if (currentProfile == null || !mounted) return;

    showDialog(
      context: context,
      useSafeArea: false,
      barrierDismissible: false,
      builder: (dialogContext) => MatchOverlay(
        matchedProfile: profile,
        currentProfile: currentProfile,
        onKeepSwiping: () => Navigator.of(dialogContext).pop(),
        onSendMessage: () async {
          Navigator.of(dialogContext).pop();

          try {
            final chatId = await ref
                .read(chatServiceProvider)
                .createChat(currentUserAuth.uid, profile.id);

            if (mounted) {
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(
                  builder: (context) => ChatDetailScreen(
                    match: {
                      'id': profile.id,
                      'name': profile.name,
                      'image': profile.imageUrls.isNotEmpty
                          ? profile.imageUrls.first
                          : '',
                      'chatId': chatId,
                    },
                  ),
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Error creating chat: $e")),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feedState = ref.watch(feedProvider);
    final notifier = ref.read(feedProvider.notifier);

    return feedState.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: Colors.amber)),
      error: (e, s) => Center(
        child: Text("Error: $e", style: const TextStyle(color: Colors.red)),
      ),
      data: (cards) {
        // Check if list is empty OR if the top card is our "empty placeholder"
        // FeedService returns CardType.empty when no profiles are available
        if (cards.isEmpty || cards.first.type == CardType.empty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: EmptyStateCard()),
          );
        }

        final topCard = cards[0];
        final nextCard = cards.length > 1 ? cards[1] : null;

        return LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              alignment: Alignment.center,
              children: [
                // Next Card
                if (nextCard != null)
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Transform.scale(
                        scale: 0.95,
                        child: _buildCardView(nextCard),
                      ),
                    ),
                  ),

                // Top Card (Gesture Controlled)
                GestureDetector(
                  onPanStart: (details) {
                    _animationController.stop();
                  },
                  onPanUpdate: (details) {
                    setState(() {
                      _dragOffset += details.delta;
                      _dragAngle = _dragOffset.dx * 0.001; // Sensitivity
                    });
                  },
                  onPanEnd: (details) {
                    final velocity = details.velocity.pixelsPerSecond;

                    if (_dragOffset.dx.abs() > 100 || velocity.dx.abs() > 500) {
                      // Swipe Out
                      final isRight = _dragOffset.dx > 0;
                      final isSuperLike =
                          _dragOffset.dy < -200 && velocity.dy < -500;

                      if (isSuperLike) {
                        _triggerSwipe(Offset.zero, isSuperLike: true);
                      } else {
                        _triggerSwipe(Offset(isRight ? 2 : -2, 0));
                      }
                    } else {
                      // Spring Back
                      _runSpringBack();
                    }
                  },
                  child: AnimatedBuilder(
                    animation: _animationController,
                    builder: (context, child) {
                      final offset = _animationController.isAnimating
                          ? _slideAnimation.value
                          : _dragOffset;
                      final angle = _animationController.isAnimating
                          ? _rotateAnimation.value
                          : _dragAngle;

                      return Transform.translate(
                        offset: offset,
                        child: Transform.rotate(
                          angle: angle,
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Stack(
                              children: [
                                _buildCardView(topCard),

                                // LIKE Stamp
                                if (offset.dx > 0)
                                  Positioned(
                                    top: 40,
                                    left: 40,
                                    child: Opacity(
                                      opacity: (offset.dx / 150).clamp(
                                        0.0,
                                        1.0,
                                      ),
                                      child: Transform.rotate(
                                        angle: -0.5,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.green,
                                              width: 4,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          child: const Text(
                                            "LIKE",
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontSize: 32,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                // NOPE Stamp
                                if (offset.dx < 0)
                                  Positioned(
                                    top: 40,
                                    right: 40,
                                    child: Opacity(
                                      opacity: (-offset.dx / 150).clamp(
                                        0.0,
                                        1.0,
                                      ),
                                      child: Transform.rotate(
                                        angle: 0.5,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.red,
                                              width: 4,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                          child: const Text(
                                            "NOPE",
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontSize: 32,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                // SUPER LIKE Stamp
                                if (offset.dy < 0 &&
                                    offset.dy.abs() > offset.dx.abs())
                                  Positioned(
                                    bottom: 100,
                                    left: 0,
                                    right: 0,
                                    child: Center(
                                      child: Opacity(
                                        opacity: (-offset.dy / 200).clamp(
                                          0.0,
                                          1.0,
                                        ),
                                        child: const Text(
                                          "SUPER LIKE",
                                          style: TextStyle(
                                            color: Colors.blue,
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black,
                                                blurRadius: 10,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // FABs
                Positioned(
                  bottom: 30,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Rewind
                      _buildFab(
                        onTap: () {
                          if (notifier.canRewind) {
                            HapticFeedback.mediumImpact();
                            notifier.rewind();
                          }
                        },
                        icon: Icons.refresh,
                        color: Colors.amber,
                        isSmall: true,
                        disabled: !notifier.canRewind,
                      ),
                      const SizedBox(width: 20),

                      // NOPE
                      _buildFab(
                        onTap: () => _triggerSwipe(const Offset(-1, 0)),
                        icon: Icons.close,
                        color: Colors.red,
                        size: 64,
                        iconSize: 32,
                      ),
                      const SizedBox(width: 24),

                      // LIKE
                      InkWell(
                        onTap: () => _triggerSwipe(const Offset(1, 0)),
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Colors.cyan, Colors.blue],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.withValues(alpha: 0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),

                      // SUPER LIKE
                      _buildFab(
                        onTap: () =>
                            _triggerSwipe(Offset.zero, isSuperLike: true),
                        icon: Icons.star,
                        color: Colors.purple,
                        isSmall: true,
                        isOutlined: true,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCardView(CardItem item) {
    if (item.type == CardType.profile) {
      return ProfileCard(profile: item.data as UserProfile);
    } else if (item.type == CardType.ad) {
      return NativeAdCard(cardItem: item);
    } else {
      return Container(color: Colors.transparent);
    }
  }

  Widget _buildFab({
    required VoidCallback onTap,
    required IconData icon,
    required Color color,
    double size = 50,
    double iconSize = 24,
    bool isSmall = false,
    bool isOutlined = false,
    bool disabled = false,
  }) {
    if (isSmall) size = 50;

    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF1E293B),
          border: isOutlined
              ? Border.all(color: color.withValues(alpha: 0.5), width: 2)
              : Border.all(color: Colors.transparent),
          boxShadow: [
            if (!disabled)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
          ],
        ),
        child: Icon(
          icon,
          color: disabled ? Colors.grey : color,
          size: iconSize,
        ),
      ),
    );
  }
}
