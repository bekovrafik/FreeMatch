import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/user_profile.dart';
import '../screens/public_profile_screen.dart';

class ProfileCard extends StatefulWidget {
  final UserProfile profile;

  const ProfileCard({super.key, required this.profile});

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  int _photoIndex = 0;

  void _nextPhoto() {
    setState(() {
      if (widget.profile.imageUrls.isNotEmpty) {
        if (_photoIndex < widget.profile.imageUrls.length - 1) {
          _photoIndex++;
        } else {
          _photoIndex = 0;
        }
      }
    });
  }

  void _prevPhoto() {
    setState(() {
      if (widget.profile.imageUrls.isNotEmpty) {
        if (_photoIndex > 0) {
          _photoIndex--;
        } else {
          _photoIndex = widget.profile.imageUrls.length - 1;
        }
      }
    });
  }

  void _openDetails() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PublicProfileScreen(profile: widget.profile),
        fullscreenDialog: true,
      ),
    );
  }

  // Audio State
  late final AudioPlayer _audioPlayer; // Use late final
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initAudio();
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

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black, // Fallback
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Background Image
            CachedNetworkImage(
              imageUrl: widget.profile.imageUrls.isNotEmpty
                  ? widget.profile.imageUrls[_photoIndex]
                  : '',
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: Colors.grey[900]),
              errorWidget: (context, url, error) =>
                  Container(color: Colors.grey[900]),
            ),

            // 2. Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.8),
                  ],
                  stops: const [0.5, 0.7, 1.0],
                ),
              ),
            ),

            // 3. Story Progress Bars (Top)
            if (widget.profile.imageUrls.length > 1)
              Positioned(
                top: 12,
                left: 8,
                right: 8,
                child: Row(
                  children: widget.profile.imageUrls.asMap().entries.map((
                    entry,
                  ) {
                    final idx = entry.key;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: idx == _photoIndex
                                ? 1.0
                                : (idx < _photoIndex ? 1.0 : 0.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

            // 3.5. Tap Zones (Photo Navigation - Below Content)
            Positioned.fill(
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _prevPhoto,
                      behavior: HitTestBehavior.translucent,
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: _nextPhoto,
                      behavior: HitTestBehavior.translucent,
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                ],
              ),
            ),

            // 4. Content (Clickable to open details)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: _openDetails,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                widget.profile.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (widget.profile.isVerified)
                                const Icon(
                                  Icons.verified,
                                  color: Colors.blue,
                                  size: 28,
                                ),
                              const SizedBox(width: 10),
                              Text(
                                '${widget.profile.age}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.work_outline,
                                color: Colors.amber,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  widget.profile.profession.isNotEmpty
                                      ? widget.profile.profession
                                      : "FreeMatch Member",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                color: Colors.amber,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  '${widget.profile.distance.toStringAsFixed(0)} km away (${widget.profile.location})',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (widget.profile.bio.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              widget.profile.bio,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Voice Intro (Separate GestureDetector)
                    if (widget.profile.voiceIntro != null &&
                        widget.profile.voiceIntro!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _toggleAudio,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: _isPlaying
                                ? Colors.amber.withValues(alpha: 0.9)
                                : Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: _isPlaying ? Colors.black : Colors.white,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _isPlaying
                                      ? "Playing Intro..."
                                      : "Play Voice Intro",
                                  style: TextStyle(
                                    color: _isPlaying
                                        ? Colors.black
                                        : Colors.white54,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),

            // 5. Info Button (Top Right)
            Positioned(
              top: 30, // Below status bars
              right: 16,
              child: GestureDetector(
                onTap: _openDetails,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white12),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),

            // Priority Badge
            if (widget.profile.hasLikedCurrentUser)
              Positioned(
                top: 30,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'LIKES YOU',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
