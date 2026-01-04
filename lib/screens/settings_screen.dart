import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../widgets/discovery_settings_modal.dart';
import 'privacy_policy_screen.dart';
import 'blocked_users_screen.dart';
import 'contact_support_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _logout(BuildContext context, WidgetRef ref) async {
    await AuthService(FirebaseAuth.instance).signOut();
    if (context.mounted) {
      // Navigate to root (which redirects to AuthScreen via AuthState change)
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  void _deleteAccount(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          "Delete Account?",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Are you sure you want to delete your account? This action is irreversible and all your data (matches, messages) will be lost.",
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog

              final currentUser = ref.read(authServiceProvider).currentUser;
              if (currentUser == null) return;

              try {
                // 1. Delete Firestore Data
                await ref
                    .read(firestoreServiceProvider)
                    .deleteUserData(currentUser.uid);

                // 2. Delete Auth Account
                await ref.read(authServiceProvider).deleteAccount();

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Account deleted successfully."),
                    ),
                  );
                  // Nav to root is handled by authStateChanges stream usually,
                  // but we can force pop just in case.
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              } catch (e) {
                if (context.mounted) {
                  // Handle requires-recent-login
                  if (e.toString().contains('requires-recent-login')) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Security: Please log out and log in again to delete account.",
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error deleting account: $e")),
                    );
                  }
                }
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        title: const Text("Settings", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0F172A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          _buildSectionHeader("DISCOVERY"),
          _buildListTile(
            context,
            icon: Icons.tune,
            title: "Discovery Settings",
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const DiscoverySettingsModal(),
              );
            },
          ),

          const Divider(color: Color(0xFF1E293B)),
          _buildSectionHeader("COMMUNITY"),
          _buildListTile(
            context,
            icon: Icons.block,
            title: "Blocked Users",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BlockedUsersScreen()),
            ),
          ),

          const Divider(color: Color(0xFF1E293B)),
          _buildSectionHeader("LEGAL & SUPPORT"),
          _buildListTile(
            context,
            icon: Icons.privacy_tip_outlined,
            title: "Privacy Policy",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
            ),
          ),
          _buildListTile(
            context,
            icon: Icons.mail_outline,
            title: "Contact Support",
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ContactSupportScreen()),
            ),
          ),

          const Divider(color: Color(0xFF1E293B)),
          const SizedBox(height: 40),

          _buildListTile(
            context,
            icon: Icons.logout,
            title: "Logout",
            color: Colors.white,
            onTap: () => _logout(context, ref),
          ),
          _buildListTile(
            context,
            icon: Icons.delete_forever,
            title: "Delete Account",
            color: Colors.red, // Danger
            onTap: () => _deleteAccount(context, ref),
          ),

          const SizedBox(height: 40),
          const SizedBox(height: 40),

          const SizedBox(height: 40),
          const Center(
            child: Text(
              "Version 1.0.0 (Build 2025)",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.blueGrey[400],
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
