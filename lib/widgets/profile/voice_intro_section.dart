import 'package:flutter/material.dart';

class VoiceIntroSection extends StatelessWidget {
  final bool isRecording;
  final bool isPlaying;
  final String? recordPath;
  final String? voiceTitle;
  final VoidCallback onTapMic;
  final VoidCallback onDelete;

  const VoiceIntroSection({
    super.key,
    required this.isRecording,
    required this.isPlaying,
    required this.recordPath,
    required this.voiceTitle,
    required this.onTapMic,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("VOICE INTRO"),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF111827),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1F2937)),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: onTapMic,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isRecording
                          ? Colors.red.withValues(alpha: 0.2)
                          : const Color(0xFF1F2937),
                      shape: BoxShape.circle,
                      border: isRecording
                          ? Border.all(color: Colors.red)
                          : null,
                    ),
                    child: Icon(
                      isRecording
                          ? Icons.stop
                          : (recordPath != null
                                ? (isPlaying ? Icons.pause : Icons.play_arrow)
                                : Icons.mic),
                      color: isRecording
                          ? Colors.red
                          : (recordPath != null ? Colors.amber : Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isRecording
                            ? "Recording (Tap to Stop)..."
                            : (recordPath != null
                                  ? (voiceTitle ?? "My Voice Intro")
                                  : "Tap mic to record intro"),
                        style: TextStyle(
                          color: isRecording ? Colors.red : Colors.white,
                          fontSize: 16,
                          fontWeight: recordPath != null
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      if (recordPath != null)
                        const Padding(
                          padding: EdgeInsets.only(top: 4.0),
                          child: Text(
                            "Tap play to listen",
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
                if (recordPath != null && !isRecording)
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.grey,
          fontWeight: FontWeight.bold,
          fontSize: 13,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
