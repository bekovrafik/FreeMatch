import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/user_profile.dart'; // Ensure UserProfile is available
import 'package:cached_network_image/cached_network_image.dart';

// HARDCODED Current User Image for Demo (Matching React const CURRENT_USER)
const String _kCurrentUserImage =
    "https://images.unsplash.com/photo-1599566150163-29194dcaad36?ixlib=rb-1.2.1&auto=format&fit=crop&w=500&q=80";

class MatchOverlay extends StatefulWidget {
  final UserProfile matchedProfile;
  final VoidCallback onKeepSwiping;
  final VoidCallback onSendMessage;

  const MatchOverlay({
    super.key,
    required this.matchedProfile,
    required this.onKeepSwiping,
    required this.onSendMessage,
  });

  @override
  State<MatchOverlay> createState() => _MatchOverlayState();
}

class _MatchOverlayState extends State<MatchOverlay>
    with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late Animation<double> _scaleAnim;
  late Animation<double> _rotateAnim;

  late AnimationController _imagesController;
  late Animation<Offset> _leftImageAnim;
  late Animation<Offset> _rightImageAnim;
  late Animation<double> _heartScaleAnim;

  @override
  void initState() {
    super.initState();

    // 1. Text Entrance
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.elasticOut,
    );
    _rotateAnim = Tween<double>(begin: -0.1, end: 0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );

    // 2. Images Entrance
    _imagesController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _leftImageAnim =
        Tween<Offset>(
          begin: const Offset(-1, 0),
          end: const Offset(-0.2, 0),
        ).animate(
          CurvedAnimation(
            parent: _imagesController,
            curve: const Interval(0.2, 0.7, curve: Curves.elasticOut),
          ),
        );

    _rightImageAnim =
        Tween<Offset>(
          begin: const Offset(1, 0),
          end: const Offset(0.2, 0),
        ).animate(
          CurvedAnimation(
            parent: _imagesController,
            curve: const Interval(0.4, 0.9, curve: Curves.elasticOut),
          ),
        );

    _heartScaleAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _imagesController,
        curve: const Interval(0.6, 1.0, curve: Curves.elasticOut),
      ),
    );

    // Sequence
    _entranceController.forward().then((_) => _imagesController.forward());
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _imagesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.9), // Backdrop
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // "IT'S A MATCH" Text
              ScaleTransition(
                scale: _scaleAnim,
                child: RotationTransition(
                  turns: _rotateAnim,
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Color(0xFFFBBF24), Color(0xFFDB2777)],
                    ).createShader(bounds),
                    child: const Text(
                      "IT'S A\nMATCH!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        height: 0.9,
                        letterSpacing: -2,
                        fontStyle: FontStyle.italic,
                        color:
                            Colors.white, // Text color required by ShaderMask
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 48),

              // Images Area
              SizedBox(
                height: 250,
                width: double.infinity,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Me (Left)
                    SlideTransition(
                      position: _leftImageAnim,
                      child: Transform.rotate(
                        angle: -10 * math.pi / 180,
                        child: _buildProfileImage(
                          _kCurrentUserImage,
                          Colors.pink,
                        ),
                      ),
                    ),

                    // Match (Right)
                    SlideTransition(
                      position: _rightImageAnim,
                      child: Transform.rotate(
                        angle: 10 * math.pi / 180,
                        child: _buildProfileImage(
                          widget.matchedProfile.imageUrls.first,
                          Colors.amber,
                        ),
                      ),
                    ),

                    // Heart Icon
                    ScaleTransition(
                      scale: _heartScaleAnim,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black26, blurRadius: 10),
                          ],
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.pink,
                          size: 32,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              Text.rich(
                TextSpan(
                  text: "You and ",
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                  children: [
                    TextSpan(
                      text: widget.matchedProfile.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                    const TextSpan(text: " like each other."),
                  ],
                ),
              ),

              const SizedBox(height: 48),

              // Buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: widget.onSendMessage,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.pink, Colors.amber],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(
                                  Icons.chat_bubble_outline,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  "Send a Message",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: widget.onKeepSwiping,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF334155)),
                          backgroundColor: const Color(0xFF1E293B),
                          foregroundColor: const Color(0xFFCBD5E1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          "Keep Swiping",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage(String url, Color borderColor) {
    return Container(
      width: 160,
      height: 220,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 4),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.5),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
        image: DecorationImage(
          image: CachedNetworkImageProvider(url),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
