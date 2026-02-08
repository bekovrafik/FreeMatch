import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../providers/user_provider.dart';
// import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/card_stack.dart';
import '../widgets/discovery_settings_modal.dart';
import '../widgets/daily_reward_modal.dart';
import '../widgets/custom_bottom_nav.dart';
import '../providers/home_provider.dart';
import '../theme/app_colors.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // 1. Trigger Startup Logic via Provider
    _initStartup();
  }

  Future<void> _initStartup() async {
    // Save Token
    ref.read(homeProvider.notifier).initHome(context);

    // Update User Location for Distance Calculation
    _updateUserLocation();

    // Watch for Daily Reward (Hybrid Approach: Provider fetches, UI shows)
    try {
      final rewardState = await ref.read(dailyRewardCheckProvider.future);
      if (rewardState['showReward'] == true && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black.withValues(alpha: 0.8),
          builder: (context) => DailyRewardModal(
            streak: rewardState['streak'] as int,
            onClose: () => Navigator.pop(context),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error checking reward: $e");
    }
  }

  Future<void> _updateUserLocation() async {
    try {
      // Simple permission check and update
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        final position = await Geolocator.getCurrentPosition();
        final user = ref.read(authServiceProvider).currentUser;
        if (user != null) {
          await ref.read(firestoreServiceProvider).updateUserFields(user.uid, {
            'latitude': position.latitude,
            'longitude': position.longitude,
          });
          debugPrint(
            "DEBUG: User location updated: ${position.latitude}, ${position.longitude}",
          );
        }
      }
    } catch (e) {
      debugPrint("Error updating user location: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // 2. Watch State
    final selectedIndex = ref.watch(homeProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF020617), // Slate-950
      floatingActionButton: null,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('assets/images/free.png', height: 32, width: 32),
            const SizedBox(width: 8),
            Text(
              'FreeMatch',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: AppColors.warning, size: 16),
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
        index: selectedIndex,
        children: [
          const Center(child: CardStack()), // Feed
          const ChatScreen(),
          const ProfileScreen(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: selectedIndex,
        onItemTapped: (idx) => ref.read(homeProvider.notifier).setIndex(idx),
      ),
    );
  }
}
