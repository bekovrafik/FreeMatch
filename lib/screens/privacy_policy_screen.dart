import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF020617),
      appBar: AppBar(
        title: const Text(
          "Privacy Policy",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0F172A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader("Privacy Policy"),
            const SizedBox(height: 8),
            _buildText("Last updated: January 2025"),
            _buildDivider(),

            _buildSectionTitle("1. Introduction"),
            _buildText(
              "FreeMatch ('the App') is operated by PillLens, Inc. ('Company', 'we', 'us', or 'our'). "
              "We differ from other dating apps by offering a completely free matching experience supported by non-intrusive advertising. "
              "This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you visit our mobile application.",
            ),

            _buildSectionTitle("2. Information We Collect"),
            _buildSubTitle("A. Personal Data"),
            _buildText(
              "We collect information that identifies you personally, including:\n"
              "• Name and Email Address (via Firebase Authentication)\n"
              "• Date of Birth and Gender (for age verification and matching)\n"
              "• Profile Information (Bios, Interests, Job Title)",
            ),
            _buildSubTitle("B. Media & Biometrics"),
            _buildText(
              "• **Photos:** We access your camera and photo library to allow you to upload profile pictures and send images in chat.\n"
              "• **Audio/Voice:** We access your microphone to enable 'Voice Intros' and voice messaging features.",
            ),
            _buildSubTitle("C. Location Data"),
            _buildText(
              "We collect your device's precise location (GPS) to find potential matches near you ("
              "e.g., 'Users within 50km'). You can disable location services in your device settings, though this will limit matching functionality.",
            ),

            _buildSectionTitle("3. How We Use Your Information"),
            _buildText(
              "We use collected data to:\n"
              "• Create and manage your account.\n"
              "• Facilitate matching with other users based on location and preferences.\n"
              "• Enable communication (chat, voice, image sharing) between matched users.\n"
              "• Serve personalized advertisements via Google AdMob.\n"
              "• Enforce our Terms of Service and prevent abuse (blocking/reporting).",
            ),

            _buildSectionTitle("4. Disclosure of Your Information"),
            _buildText(
              "We may share information with:\n"
              "• **Service Providers:** We use Google Firebase (for hosting, database, authentication) and RevenueCat (for potential future subscriptions).\n"
              "• **Advertisers:** We use Google AdMob to display ads. These third parties may access data like your device ID or IP address to serve relevant checks.",
            ),

            _buildSectionTitle("5. Security of Your Information"),
            _buildText(
              "We use administrative, technical, and physical security measures (including Firebase Security Rules and encrypted storage) "
              "to help protect your personal information. However, no electronic transmission is 100% secure.",
            ),

            _buildSectionTitle("6. Deletion of Account & Data"),
            _buildText(
              "Reference to **Google Play Data Safety & Apple App Store Guidelines**:\n"
              "You have the right to delete your account at any time. Doing so will permanently remove your profile, matches, messages, and uploaded media from our servers.\n\n"
              "**To delete your account:**\n"
              "Go to Settings > Delete Account > Confirm.",
            ),

            _buildSectionTitle("7. Children's Privacy"),
            _buildText(
              "FreeMatch is strictly for users aged 18 and older. We do not knowingly solicit information from or market to children under the age of 18.",
            ),

            _buildSectionTitle("8. Contact Us"),
            _buildText(
              "If you have questions or comments about this Privacy Policy, please contact PillLens, Inc support at:\n"
              "• Email: support@pilllens.com",
            ),

            const SizedBox(height: 40),
            Center(
              child: Text(
                "© 2025 PillLens, Inc. All rights reserved.",
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.amber, // Highlight color
        ),
      ),
    );
  }

  Widget _buildSubTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.white70,
        ),
      ),
    );
  }

  Widget _buildText(String text) {
    return Text(
      text,
      style: TextStyle(color: Colors.blueGrey[100], fontSize: 14, height: 1.6),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 20),
      child: Divider(color: Colors.white24),
    );
  }
}
