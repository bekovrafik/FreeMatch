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
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          "Delete Account?",
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Action irreversible. Enter password to confirm:",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context); // Close dialog

              final password = passwordController.text;
              if (password.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Password required")),
                );
                return;
              }

              final currentUser = ref.read(authServiceProvider).currentUser;
              if (currentUser == null) return;

              try {
                // 1. Delete Firestore Data
                await ref
                    .read(firestoreServiceProvider)
                    .deleteUserData(currentUser.uid);

                // 2. Delete Auth Account
                await ref.read(authServiceProvider).deleteAccount(password);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Account deleted successfully."),
                    ),
                  );
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text("Error: $e")));
                }
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      body: SafeArea(
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back Button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8), // Touch target
                      alignment: Alignment.centerLeft,
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Settings",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
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
