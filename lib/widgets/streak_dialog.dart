import 'package:flutter/material.dart';

class StreakDialog extends StatelessWidget {
  final int streakDays;
  final VoidCallback onClaim;

  const StreakDialog({
    super.key,
    required this.streakDays,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final isDay7 = streakDays % 7 == 0;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A), // Slate-900
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.amber, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.2),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.local_fire_department,
              color: Colors.amber,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              '$streakDays Day Streak!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isDay7
                  ? 'You reached day 7! Premium Sticker Unlocked!'
                  : 'Keep it up! +1 Super Like added.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onClaim,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 12,
                ),
              ),
              child: const Text('CLAIM REWARD'),
            ),
          ],
        ),
      ),
    );
  }
}
