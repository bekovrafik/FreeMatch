import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_provider.dart';
// import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/card_stack.dart';
import '../widgets/discovery_settings_modal.dart';
import '../widgets/daily_reward_modal.dart';
import '../services/streak_service.dart';
import '../services/auth_service.dart'; // For logout in previous logic
import '../services/notification_service.dart';
import '../services/firestore_service.dart';
import '../widgets/custom_bottom_nav.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkDailyReward();
    // Save FCM Token
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveFcmToken();
    });
  }

  Future<void> _saveFcmToken() async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user != null) {
      final token = await ref.read(notificationServiceProvider).getToken();
      if (token != null) {
        await ref
            .read(firestoreServiceProvider)
            .saveDeviceToken(user.uid, token);
        debugPrint("FCM Token Saved: $token");
      }
    }
  }

  Future<void> _checkDailyReward() async {
    // Artificial delay for startup
    await Future.delayed(const Duration(seconds: 1));

    // Check service
    final result = await StreakService().checkDailyStreak();
    // { streak: int, showReward: bool, hasClaimedToday: bool }

    if (result['showReward'] == true && mounted) {
      final streak = result['streak'] as int;

      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.8),
        builder: (context) => DailyRewardModal(
          streak: streak,
          onClose: () => Navigator.pop(context),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/free.png', height: 32, width: 32),
            const SizedBox(width: 8),
            const Text(
              'FreeMatch',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 24,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B), // Slate-800
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Consumer(
                  builder: (context, ref, _) {
                    final superLikes = ref.watch(userProvider).superLikes;
                    return Text(
                      '$superLikes',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const DiscoverySettingsModal(),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          const Center(child: CardStack()), // Feed
          const ChatScreen(),
          const ProfileScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: (idx) => setState(() => _selectedIndex = idx),
      ),
    );
  }
}
