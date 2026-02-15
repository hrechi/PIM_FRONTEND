import 'package:flutter/material.dart';

// ── Server Configuration ─────────────────────────────────────
// Change this IP to your PC's local WiFi IP when testing on a
// physical device. Run `ipconfig` (Windows) or `ifconfig` (Mac/Linux)
// and use the IPv4 address from your WiFi adapter.
import 'dart:io'; // Import this at the top

class AppConfig {
  static String get serverHost {
    // Android Emulator needs 10.0.2.2 to reach the host
    if (Platform.isAndroid) {
      return '10.0.2.2';
    }
    // iOS Simulator uses localhost
    return 'localhost';
  }

  static const int serverPort = 3000;
}
class AppColors {
  // ── Primary Surface Colors ─────────────────────────────────
  static const Color sageTint = Color(0xFFF1F8F5);
  static const Color mistyBlue = Color(0xFF309448);
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
