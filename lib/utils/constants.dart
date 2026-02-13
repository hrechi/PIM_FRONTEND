import 'package:flutter/material.dart';

// ── Server Configuration ─────────────────────────────────────
// Change this IP to your PC's local WiFi IP when testing on a
// physical device. Run `ipconfig` (Windows) or `ifconfig` (Mac/Linux)
// and use the IPv4 address from your WiFi adapter.
class AppConfig {
  static const String serverHost = '192.168.1.102'; // your PC's WiFi IP
  static const int    serverPort = 3000;
}

class AppColors {
  // Light Theme Colors
  static const Color mistyBlue = Color(0xFF6B9BD1);
  static const Color fieldFreshStart = Color(0xFF4CAF7E);
  static const Color wheatWarmClay = Color(0xFFF5E6D3);
  static const Color sageTint = Color(0xFFF8FAF5);
  static const Color primaryText = Color(0xFF2C3E50);
  static const Color secondaryText = Color(0xFF7F8C8D);
  static const Color error = Color(0xFFE74C3C);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkMistyBlue = Color(0xFF5A8BC5);
  static const Color darkFieldFreshStart = Color(0xFF3D9C6B);
  static const Color darkTextPrimary = Color(0xFFE1E1E1);
  static const Color darkTextSecondary = Color(0xFFB0B0B0);
  static const Color darkError = Color(0xFFCF6679);

  // Status Colors (work for both themes)
  static const Color success = Color(0xFF4CAF7E);
  static const Color info = Color(0xFF2196F3);
  static const Color warning = Color(0xFFFFA726);
  static const Color alertError = Color(0xFFE74C3C);
  static const Color healthGlow = Color(0xFF2E7D32);

  static const Color healthOptimal = Color(0xFF4CAF7E);
  static const Color healthWarning = Color(0xFFFFA726);
  static const Color healthCritical = Color(0xFFE74C3C);

  // Animal Type Colors
  static const Color cowColor = Color(0xFF8D6E63);
  static const Color sheepColor = Color(0xFFECEFF1);
  static const Color horseColor = Color(0xFF6D4C41);
  static const Color goatColor = Color(0xFFBCAAA4);
  static const Color birdColor = Color(0xFF90CAF9);
  static const Color otherColor = Color(0xFF9E9E9E);

  // Gradients
  static const LinearGradient fieldFreshGradient = LinearGradient(
    colors: [Color(0xFF4CAF7E), Color(0xFF2E7D32)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    colors: [Color(0xFF2ECC71), Color(0xFF27AE60)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Gradient for cards
  static const LinearGradient cardGradientLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFF8F9FA)],
  );

  static const LinearGradient cardGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2A2A2A), Color(0xFF1E1E1E)],
  );
}

class AppConstants {
  static const String appName = 'Fieldly PIM';
  
  // Animal Types
  static const List<String> animalTypes = [
    'COW',
    'SHEEP',
    'HORSE',
    'GOAT',
    'BIRD',
    'OTHER',
  ];

  // Health Status
  static const List<String> healthStatuses = [
    'OPTIMAL',
    'WARNING',
    'CRITICAL',
  ];

  // Activity Levels
  static const List<String> activityLevels = [
    'LOW',
    'MODERATE',
    'HIGH',
  ];

  // Sex
  static const List<String> sexOptions = [
    'MALE',
    'FEMALE',
  ];
}

