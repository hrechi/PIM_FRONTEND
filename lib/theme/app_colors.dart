import 'package:flutter/material.dart';
import '../utils/constants.dart';

class FieldlyColors {
  FieldlyColors._();

  static const Color primary = AppColors.mistyBlue;
  static const Color darkGreen = AppColors.sageGreen;
  static const Color background = AppColors.wheatWarmClay;
  static const Color textPrimary = AppColors.primaryText;
  static const Color textSecondary = AppColors.secondaryText;

  static const Color healthy = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color critical = Color(0xFFE53935);
  static const Color unknown = Color(0xFF9E9E9E);

  static Color healthStatus(String? status) {
    switch ((status ?? '').toUpperCase()) {
      case 'HEALTHY':
      case 'OPTIMAL':
      case 'OK':
        return healthy;
      case 'WARNING':
        return warning;
      case 'CRITICAL':
        return critical;
      default:
        return unknown;
    }
  }
}
