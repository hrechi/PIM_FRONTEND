import 'package:flutter/material.dart';

// ── Server Configuration ─────────────────────────────────────
// Change this IP to your PC's local WiFi IP when testing on a
// physical device. Run `ipconfig` (Windows) or `ifconfig` (Mac/Linux)
// and use the IPv4 address from your WiFi adapter.
class AppConfig {
  static const String serverHost = '192.168.1.12'; // your PC's WiFi IP
  static const int    serverPort = 3000;
}

class AppColors {
  // ── Primary Surface Colors ─────────────────────────────────
  static const Color sageTint = Color(0xFFF1F8F5);
  static const Color sageGreen = Color(0xFF2D5016);  // For UI elements
  static const Color mistBlue = Color(0xFF309448);
  static const Color mistyBlue = Color(0xFF309448);
  static const Color wheat = Color(0xFFD4A574);
  static const Color wheatWarmClay = Color(0xFFFAF7F2);

  // ── High-Impact Gradients ──────────────────────────────────
  static const Color fieldFreshStart = Color(0xFF2ECC71);
  static const Color fieldFreshEnd = Color(0xFF3498DB);
  static const Color emeraldGreen = Color(0xFF3498DB);
  static const Color robotTechNavy = Color(0xFF1AAC21);
  static const Color robotTechEnd = Color(0xFF00D22F);

  // ── Health Glow ────────────────────────────────────────────
  static const Color healthGlow = Color(0xFFAFF000);

  // ── Functional Status & Action Colors ──────────────────────
  static const Color success = Color(0xFF1DB954);
  static const Color error = Color(0xFFFF4B2B);
  static const Color info = Color(0xFF00F260);
  static const Color warning = Color(0xFF729944);

  // ── Text Colors ────────────────────────────────────────────
  static const Color primaryText = Color(0xFF2C3E2D);      // Charcoal Green
  static const Color secondaryText = Color(0xFF7F8C8D);    // Soft Slate

  // ── Accent / Alias Colors ─────────────────────────────────
  static const Color primaryGreen = Color(0xFF2ECC71);
  static const Color backgroundNeutral = Color(0xFFF5F7FA);

  // ── Dark Theme Colors ─────────────────────────────────────
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkMistyBlue = Color(0xFF4CAF6A);
  static const Color darkFieldFreshStart = Color(0xFF3DDC84);
  static const Color darkError = Color(0xFFCF6679);
  static const Color darkTextPrimary = Color(0xFFE0E0E0);
  static const Color darkTextSecondary = Color(0xFF9E9E9E);

  // ── Gradient Definitions ───────────────────────────────────
  static const LinearGradient fieldFreshGradient = LinearGradient(
    colors: [fieldFreshStart, fieldFreshEnd],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    colors: [Color(0xFF2ECC71), Color(0xFF3498DB)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient robotTechGradient = LinearGradient(
    colors: [robotTechNavy, robotTechEnd],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

class AppConstants {
  static const List<String> animalTypes = ['cow', 'horse', 'sheep', 'dog'];
}
