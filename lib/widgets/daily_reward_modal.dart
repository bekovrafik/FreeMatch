import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/streak_service.dart';
import '../providers/user_provider.dart';

class DailyRewardModal extends ConsumerStatefulWidget {
  final int streak;
  final VoidCallback onClose;

  const DailyRewardModal({
    super.key,
    required this.streak,
    required this.onClose,
  });

  @override
  ConsumerState<DailyRewardModal> createState() => _DailyRewardModalState();
}

class _DailyRewardModalState extends ConsumerState<DailyRewardModal>
    with SingleTickerProviderStateMixin {
  bool _claimed = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleClaim() async {
    setState(() {
      _claimed = true;
    });

    // Update backend/storage
    await StreakService().claimReward();

    // Reward Logic: Add 1 Super Like
    ref.read(userProvider.notifier).incrementSuperLike();

    // Close after delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      widget.onClose();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine current day index (0-6)
    // Streak starts at 1. Day 1 = index 0.
    final currentDayIndex = (widget.streak - 1) % 7;

    return Center(
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A), // Slate-900
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF334155)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 20),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Header Icon (Gift)
                Positioned(
                  top: -60,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF0F172A),
                          width: 6,
                        ),
                      ),
                      child: const Icon(
                        Icons.card_giftcard,
                        size: 32,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),

                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 24),
                    const Text(
                      "Daily Streak 🔥",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.streak > 1
                          ? "You're on a ${widget.streak} day streak! Keep it up!"
                          : "Come back every day to earn rewards!",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 24),

                    // Row 1: Days 1-4
                    Row(
                      children: [
                        _buildDayItem(0, currentDayIndex),
                        const SizedBox(width: 8),
                        _buildDayItem(1, currentDayIndex),
                        const SizedBox(width: 8),
                        _buildDayItem(2, currentDayIndex),
                        const SizedBox(width: 8),
                        _buildDayItem(3, currentDayIndex),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Row 2: Days 5-6 + Day 7 (Wide)
                    Row(
                      children: [
                        _buildDayItem(4, currentDayIndex),
                        const SizedBox(width: 8),
                        _buildDayItem(5, currentDayIndex),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: _buildDayItem(
                            6,
                            currentDayIndex,
                            isWide: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Claim Button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _claimed ? null : _handleClaim,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _claimed
                              ? Colors.green
                              : Colors
                                    .transparent, // Gradient hack below for unclaimed
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: _claimed
                                ? null
                                : const LinearGradient(
                                    colors: [Colors.amber, Colors.deepOrange],
                                  ),
                            borderRadius: BorderRadius.circular(16),
                            color: _claimed ? Colors.green : null,
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_claimed)
                                  const Icon(
                                    Icons.check,
                                    color: Colors.black,
                                    size: 20,
                                  ),
                                SizedBox(width: _claimed ? 8 : 0),
                                Text(
                                  _claimed ? "Claimed!" : "Claim Reward",
                                  style: TextStyle(
                                    color: _claimed
                                        ? Colors.black
                                        : Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Miss a day and your streak resets. Day 7 unlocks Premium!",
                      style: TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                  ],
                ),

                // Close Button
                Positioned(
                  top: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: widget.onClose,
                    child: const Icon(Icons.close, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayItem(int index, int currentDayIndex, {bool isWide = false}) {
    final isCompleted = index < currentDayIndex;
    final isCurrent = index == currentDayIndex;
    final isPremium = index == 6; // Day 7

    return Expanded(
      flex: isWide ? 2 : 1,
      child: AspectRatio(
        aspectRatio: isWide ? 2.0 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: isCurrent
                ? Colors.amber.withValues(alpha: 0.1)
                : (isCompleted
                      ? Colors.green.withValues(alpha: 0.2)
                      : const Color(0xFF1E293B)),
            border: Border.all(
              color: isCurrent
                  ? Colors.amber
                  : (isCompleted ? Colors.green : const Color(0xFF334155)),
              width: isCurrent ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: isCurrent
                ? [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.1),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isPremium ? Icons.workspace_premium : Icons.star,
                      size: isPremium ? 24 : 18,
                      color: isCurrent
                          ? Colors.amber
                          : (isCompleted
                                ? Colors.green
                                : (isPremium
                                      ? Colors.grey[400]
                                      : Colors.grey[600])),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isPremium ? "Premium" : "1 Super\nLike",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isCurrent
                            ? Colors.amber
                            : (isCompleted ? Colors.green : Colors.grey[500]),
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              if (isCompleted)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 10,
                      color: Colors.black,
                    ),
                  ),
                ),
              if (isCurrent)
                Positioned(
                  bottom: -6,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 2,
                        horizontal: 8,
                      ),
                      child: const Text(
                        "TODAY",
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
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
  }
}
