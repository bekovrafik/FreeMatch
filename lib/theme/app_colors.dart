import 'package:flutter/material.dart';

class AppColors {
  // Primary
  static const Color primary = Colors.amber; // Amber-500
  static const Color primaryDark = Color(0xFFD97706); // Amber-600
  static const Color primaryLight = Color(0xFFFCD34D); // Amber-300

  // Backgrounds
  static const Color scaffoldBackground = Color(0xFF020617); // Slate-950
  static const Color surface = Color(0xFF0F172A); // Slate-900
  static const Color card = Color(0xFF1E293B); // Slate-800
  static const Color cardBorder = Color(0xFF334155); // Slate-700

  // Text
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFF94A3B8); // Slate-400
  static const Color textMuted = Color(0xFF64748B); // Slate-500

  // Status
  static const Color error = Color(0xFFEF4444); // Red-500
  static const Color success = Color(0xFF22C55E); // Green-500
  static const Color warning = Color(0xFFEAB308); // Yellow-500

  // Gradients
  static const LinearGradient premiumGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
