import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/user_profile.dart';
// Assume existing or create simple one if needed
import '../widgets/custom_toast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

import '../widgets/profile/personal_details_section.dart';

class PublicProfileScreen extends ConsumerStatefulWidget {
  final UserProfile profile;

  const PublicProfileScreen({super.key, required this.profile});

  @override
  ConsumerState<PublicProfileScreen> createState() =>
      _PublicProfileScreenState();
}

class _PublicProfileScreenState extends ConsumerState<PublicProfileScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _showSafetyMenu = false;

  // Audio State
  late final AudioPlayer _audioPlayer;
  bool _isPlaying = false;

  // Personal Details Controllers (View Mode)
  late TextEditingController _heightController;
  late TextEditingController _speaksController;

  @override
  void initState() {
    super.initState();
    _initAudio();
    _heightController = TextEditingController(
      text: widget.profile.height ?? "",
    );
    _speaksController = TextEditingController(
      text: widget.profile.speaks?.join(", ") ?? "",
    );
  }

  void _initAudio() {
    _audioPlayer = AudioPlayer();
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _scrollController.dispose();
    _heightController.dispose();
    _speaksController.dispose();
    super.dispose();
  }

  Future<void> _toggleAudio() async {
    final url = widget.profile.voiceIntro;
    if (url == null || url.isEmpty) return;

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        if (mounted) setState(() => _isPlaying = false);
      } else {
        await _audioPlayer.play(UrlSource(url));
        if (mounted) setState(() => _isPlaying = true);
      }
    } catch (e) {
      debugPrint("Error toggling audio: $e");
    }
  }

  void _handleReport() {
    // Mock Report
    CustomToast.show(context, "User reported.", isError: true);
    Navigator.pop(context);
    // Ideally pop again to close profile if needed, or just stay
  }

  void _handleBlock() {
    // Mock Block
    CustomToast.show(context, "User blocked.", isError: true);
    Navigator.pop(context);
    Navigator.pop(context); // Close chat/profile
  }

  Future<void> _handleMatch() async {
    final currentUser = ref.read(authServiceProvider).currentUser;
    if (currentUser == null) return;

    try {
      // 1. Record Swipe (Like) - Server handles matching
      final firestoreService = ref.read(firestoreServiceProvider);
      await firestoreService.recordSwipe(
        currentUser.uid,
        widget.profile.id,
        true,
      );

      // 2. Optimistic UI Check
      if (widget.profile.hasLikedCurrentUser) {
        if (mounted) {
          CustomToast.show(context, "It's a Match! Check your chats soon.");
          Navigator.pop(context); // Close profile
        }
      } else {
        if (mounted) {
          CustomToast.show(context, "Liked!", isError: false);
          Navigator.pop(context);
        }
      }
    } catch (e) {
      debugPrint("Error matching: $e");
      if (mounted) CustomToast.show(context, "Error matching", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Parity with React ProfileDetailView
    return Scaffold(
      backgroundColor: const Color(0xFF020617), // Slate-950
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // 1. Hero Image App Bar
              SliverAppBar(
                expandedHeight: MediaQuery.of(context).size.height * 0.45,
                backgroundColor: const Color(0xFF020617),
                pinned: true,
                leading: IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down, size: 32),
                  onPressed: () => Navigator.pop(context),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                    foregroundColor: Colors.white,
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: widget.profile.imageUrls.isNotEmpty
                            ? widget.profile.imageUrls.first
                            : '',
                        fit: BoxFit.cover,
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.transparent,
                              Color(0xFF020617),
                            ],
                            stops: [0.0, 0.6, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Details Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name & Age
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            widget.profile.name,
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (widget.profile.isVerified)
                            const Icon(
                              Icons.verified,
                              color: Colors.blue,
                              size: 32,
                            ),
                          const SizedBox(width: 12),
                          Text(
                            "${widget.profile.age}",
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Profession & Location Cards
                      _buildInfoCard(
                        Icons.work,
                        widget.profile.profession,
                        Colors.amber,
                      ),
                      const SizedBox(height: 8),
                      _buildInfoCard(
                        Icons.location_on,
                        widget.profile.location,
                        Colors.amber,
                      ),

                      const SizedBox(height: 32),

                      // Bio
                      const Row(
                        children: [
                          Icon(Icons.format_quote, color: Colors.grey),
                          SizedBox(width: 8),
                          Text(
                            "About Me",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.profile.bio.isNotEmpty
                            ? widget.profile.bio
                            : "No bio available.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[300],
                          height: 1.6,
                          fontWeight: FontWeight.w300,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Voice Intro
                      if (widget.profile.voiceIntro != null &&
                          widget.profile.voiceIntro!.isNotEmpty) ...[
                        const Row(
                          children: [
                            Icon(Icons.mic, color: Colors.grey),
                            SizedBox(width: 8),
                            Text(
                              "Voice Intro",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: _toggleAudio,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _isPlaying
                                    ? Colors.amber
                                    : Colors.white10,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: _isPlaying
                                      ? Colors.amber
                                      : Colors.grey[800],
                                  child: Icon(
                                    _isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    color: _isPlaying
                                        ? Colors.black
                                        : Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    widget.profile.voiceIntroTitle ??
                                        "My Voice Intro",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],

                      // Personal Details
                      PersonalDetailsSection(
                        isEditing: false,
                        status: widget.profile.status,
                        orientation: widget.profile.orientation,
                        drinks: widget.profile.drinks,
                        smokes: widget.profile.smokes,
                        bodyType: widget.profile.bodyType,
                        sign: widget.profile.sign,
                        religion: widget.profile.religion,
                        lookingFor: widget.profile.lookingFor,
                        heightController: _heightController,
                        speaksController: _speaksController,
                        onStatusChanged: (_) {}, // Dummy
                        onOrientationChanged: (_) {},
                        onDrinksChanged: (_) {},
                        onSmokesChanged: (_) {},
                        onBodyTypeChanged: (_) {},
                        onSignChanged: (_) {},
                        onReligionChanged: (_) {},
                        onLookingForChanged: (_) {},
                      ),
                      const SizedBox(height: 32),

                      // Interests
                      if (widget.profile.interests.isNotEmpty) ...[
                        const Text(
                          "INTERESTS",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.profile.interests
                              .map(
                                (tag) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E293B),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    tag,
                                    style: TextStyle(
                                      color: Colors.grey[300],
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 32),
                      ],

                      // Gallery Grid
                      if (widget.profile.imageUrls.length > 1) ...[
                        const Text(
                          "MORE PHOTOS",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GridView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 0.8,
                              ),
                          itemCount: widget.profile.imageUrls.length - 1,
                          itemBuilder: (context, index) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: CachedNetworkImage(
                                imageUrl: widget.profile.imageUrls[index + 1],
                                fit: BoxFit.cover,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 32),
                      ],

                      // Safety Actions
                      Center(
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _showSafetyMenu = !_showSafetyMenu;
                            });
                          },
                          icon: const Icon(
                            Icons.shield_outlined,
                            size: 16,
                            color: Colors.grey,
                          ),
                          label: const Text(
                            "Report or Block",
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                      if (_showSafetyMenu)
                        Container(
                          margin: const EdgeInsets.only(top: 16, bottom: 40),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey[800]!),
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(
                                  Icons.report,
                                  color: Colors.red,
                                ),
                                title: const Text(
                                  "Report User",
                                  style: TextStyle(color: Colors.red),
                                ),
                                onTap: _handleReport,
                              ),
                              const Divider(height: 1, color: Colors.white10),
                              ListTile(
                                leading: const Icon(
                                  Icons.block,
                                  color: Colors.white,
                                ),
                                title: const Text(
                                  "Block User",
                                  style: TextStyle(color: Colors.white),
                                ),
                                onTap: _handleBlock,
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 100), // Bottom padding
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Sticky Bottom Button
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: widget.profile.hasLikedCurrentUser
                ? Row(
                    children: [
                      // Pass Button
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            final currentUser = ref
                                .read(authServiceProvider)
                                .currentUser;
                            if (currentUser != null) {
                              await ref
                                  .read(firestoreServiceProvider)
                                  .recordSwipe(
                                    currentUser.uid,
                                    widget.profile.id,
                                    false, // Dislike/Pass
                                  );
                              if (context.mounted) {
                                CustomToast.show(context, "Passed");
                                Navigator.pop(context);
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF334155,
                            ), // Slate-700
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 5,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.red,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Match Button
                      Expanded(
                        flex: 3,
                        child: ElevatedButton(
                          onPressed: _handleMatch,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEA580C), // Orange
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 10,
                            shadowColor: const Color(
                              0xFFEA580C,
                            ).withValues(alpha: 0.5),
                          ),
                          child: Text(
                            "Match with ${widget.profile.name.split(' ')[0]}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.grey[700]!),
                      ),
                      elevation: 10,
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
    );
  }

  Widget _buildInfoCard(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
