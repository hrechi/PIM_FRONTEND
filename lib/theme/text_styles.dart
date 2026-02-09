import 'package:flutter/material.dart';
import 'color_palette.dart';

/// Centralized text styles for Fieldly application
/// Provides consistent typography across the app with support for multiple font families
class AppTextStyles {
  // Private constructor to prevent instantiation
  AppTextStyles._();

  // ============================================
  // FONT FAMILIES
  // ============================================
  
  static const String fontFamilyInter = 'Inter';
  static const String fontFamilyPlusJakartaSans = 'Plus Jakarta Sans';
  static const String fontFamilySatoshi = 'Satoshi';

  // Default font family (can be switched for theming)
  static const String defaultFontFamily = fontFamilyInter;

  // ============================================
  // HEADING STYLES
  // ============================================
  
  /// Large heading - used for main screen titles
  static TextStyle h1({Color? color, String? fontFamily}) => TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: color ?? AppColorPalette.charcoalGreen,
        fontFamily: fontFamily ?? defaultFontFamily,
        letterSpacing: -0.5,
      );

  /// Medium heading - used for section titles
  static TextStyle h2({Color? color, String? fontFamily}) => TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: color ?? AppColorPalette.charcoalGreen,
        fontFamily: fontFamily ?? defaultFontFamily,
        letterSpacing: -0.3,
      );

  /// Small heading - used for card titles
  static TextStyle h3({Color? color, String? fontFamily}) => TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: color ?? AppColorPalette.charcoalGreen,
        fontFamily: fontFamily ?? defaultFontFamily,
        letterSpacing: -0.2,
      );

  /// Extra small heading - used for subsection titles
  static TextStyle h4({Color? color, String? fontFamily}) => TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color ?? AppColorPalette.charcoalGreen,
        fontFamily: fontFamily ?? defaultFontFamily,
      );

  // ============================================
  // BODY TEXT STYLES
  // ============================================
  
  /// Large body text
  static TextStyle bodyLarge({Color? color, String? fontFamily}) => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: color ?? AppColorPalette.charcoalGreen,
        fontFamily: fontFamily ?? defaultFontFamily,
        height: 1.5,
      );

  /// Regular body text
  static TextStyle bodyMedium({Color? color, String? fontFamily}) => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: color ?? AppColorPalette.charcoalGreen,
        fontFamily: fontFamily ?? defaultFontFamily,
        height: 1.5,
      );

  /// Small body text
  static TextStyle bodySmall({Color? color, String? fontFamily}) => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: color ?? AppColorPalette.softSlate,
        fontFamily: fontFamily ?? defaultFontFamily,
        height: 1.5,
      );

  // ============================================
  // BUTTON TEXT STYLES
  // ============================================
  
  /// Primary button text
  static TextStyle buttonLarge({Color? color, String? fontFamily}) => TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color ?? AppColorPalette.white,
        fontFamily: fontFamily ?? defaultFontFamily,
        letterSpacing: 0.5,
      );

  /// Secondary button text
  static TextStyle buttonMedium({Color? color, String? fontFamily}) => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color ?? AppColorPalette.white,
        fontFamily: fontFamily ?? defaultFontFamily,
        letterSpacing: 0.3,
      );

  /// Small button text
  static TextStyle buttonSmall({Color? color, String? fontFamily}) => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color ?? AppColorPalette.white,
        fontFamily: fontFamily ?? defaultFontFamily,
        letterSpacing: 0.3,
      );

  // ============================================
  // LABEL & CAPTION STYLES
  // ============================================
  
  /// Label text for form fields
  static TextStyle label({Color? color, String? fontFamily}) => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color ?? AppColorPalette.softSlate,
        fontFamily: fontFamily ?? defaultFontFamily,
      );

  /// Caption text for descriptions
  static TextStyle caption({Color? color, String? fontFamily}) => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: color ?? AppColorPalette.softSlate,
        fontFamily: fontFamily ?? defaultFontFamily,
      );

  /// Overline text for labels
  static TextStyle overline({Color? color, String? fontFamily}) => TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: color ?? AppColorPalette.softSlate,
        fontFamily: fontFamily ?? defaultFontFamily,
        letterSpacing: 1.0,
      );

  // ============================================
  // SPECIAL PURPOSE STYLES
  // ============================================
  
  /// Display text for large metrics/numbers
  static TextStyle displayLarge({Color? color, String? fontFamily}) => TextStyle(
        fontSize: 48,
        fontWeight: FontWeight.bold,
        color: color ?? AppColorPalette.charcoalGreen,
        fontFamily: fontFamily ?? defaultFontFamily,
        letterSpacing: -1.0,
      );

  /// Medium display text for metrics
  static TextStyle displayMedium({Color? color, String? fontFamily}) => TextStyle(
        fontSize: 36,
        fontWeight: FontWeight.bold,
        color: color ?? AppColorPalette.charcoalGreen,
        fontFamily: fontFamily ?? defaultFontFamily,
        letterSpacing: -0.8,
      );

  /// Small display text
  static TextStyle displaySmall({Color? color, String? fontFamily}) => TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: color ?? AppColorPalette.charcoalGreen,
        fontFamily: fontFamily ?? defaultFontFamily,
        letterSpacing: -0.5,
      );
}
