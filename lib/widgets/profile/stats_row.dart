import 'package:flutter/material.dart';

class ProfileStatsRow extends StatelessWidget {
  final int matchCount;
  final int likeCount;
  final double completion;

  const ProfileStatsRow({
    super.key,
    this.matchCount = 0,
    this.likeCount = 0,
    this.completion = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildStatCard("${(completion * 100).toInt()}%", "COMPLETE"),
          const SizedBox(width: 12),
          _buildStatCard("$matchCount", "MATCHES", highlight: true),
          const SizedBox(width: 12),
          _buildStatCard("$likeCount", "LIKES", isHeart: true),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String value,
    String label, {
    bool highlight = false,
    bool isHeart = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF111827), // Dark navy
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: isHeart
                        ? Colors.pink
                        : (highlight ? Colors.amber : Colors.white),
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                if (isHeart)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.favorite, size: 16, color: Colors.pink),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
