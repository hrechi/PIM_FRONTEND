import 'package:flutter/material.dart';

/// Centralized color palette for Fieldly application
/// All colors are defined here to maintain consistency across the app
class AppColorPalette {
  // Private constructor to prevent instantiation
  AppColorPalette._();

  // ============================================
  // PRIMARY SURFACE COLORS
  // ============================================
  
  static const Color sageTint = Color(0xFFF128F5);
  static const Color mistyBlue = Color(0xFF309448);
  static const Color wheatWarmClay = Color(0xFFFAF7F2);

  // ============================================
  // HIGH-IMPACT GRADIENT COLORS
  // ============================================
  
  // Field Fresh Gradient: #2ECC71 → #27AE60 → #3498DB
  static const Color fieldFreshStart = Color(0xFF2ECC71);
  static const Color fieldFreshMid = Color(0xFF27AE60);
  static const Color fieldFreshEnd = Color(0xFF3498DB);
  
  static const LinearGradient fieldFreshGradient = LinearGradient(
    colors: [fieldFreshStart, fieldFreshMid, fieldFreshEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Emerald Green
  static const Color emeraldGreen = Color(0xFF3498DB);

  // Health Glow
  static const Color healthGlow = Color(0xFFAFFE00);

  // Robot Tech Gradient: #1ABC9C → #00D2FF
  static const Color robotTechStart = Color(0xFF1ABC9C);
  static const Color robotTechEnd = Color(0xFF00D2FF);
  
  static const LinearGradient robotTechGradient = LinearGradient(
    colors: [robotTechStart, robotTechEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ============================================
  // FUNCTIONAL STATUS & ACTION COLORS
  // ============================================
  
  static const Color success = Color(0xFF1DB954);
  static const Color alertError = Color(0xFFFF4B2B);
  static const Color info = Color(0xFF00F260);
  static const Color warning = Color(0xFF729944);

  // ============================================
  // TYPOGRAPHY COLORS
  // ============================================
  
  static const Color charcoalGreen = Color(0xFF2C3E50);
  static const Color softSlate = Color(0xFF7F8C8D);

  // ============================================
  // ADDITIONAL NEUTRAL COLORS
  // ============================================
  
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color lightGrey = Color(0xFFECF0F1);
  static const Color mediumGrey = Color(0xFFBDC3C7);
  static const Color darkGrey = Color(0xFF34495E);

  // ============================================
  // GRADIENT HELPERS
  // ============================================
  
  /// Creates a custom linear gradient with the given colors
  static LinearGradient customGradient({
    required List<Color> colors,
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
  }) {
    return LinearGradient(
      colors: colors,
      begin: begin,
      end: end,
    );
  }

  /// Success gradient for positive actions
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF1DB954), Color(0xFF2ECC71)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Alert gradient for warning states
  static const LinearGradient alertGradient = LinearGradient(
    colors: [Color(0xFFFF4B2B), Color(0xFFFF6B6B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
