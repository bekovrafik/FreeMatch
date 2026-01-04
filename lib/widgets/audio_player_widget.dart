import 'package:flutter/material.dart';

class AudioPlayerWidget extends StatelessWidget {
  final int duration;
  final String color;

  const AudioPlayerWidget({
    super.key,
    required this.duration,
    this.color = 'bg-white/10',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.play_arrow, color: Colors.white, size: 20),
          const SizedBox(width: 4),
          Text(
            "0:${duration.toString().padLeft(2, '0')}",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
