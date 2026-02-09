import 'package:flutter/material.dart';
import '../theme/color_palette.dart';
import '../theme/text_styles.dart';

/// Reusable chip widget for displaying status information
/// Provides color-coded visual feedback with icon support
class StatusChip extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final double? iconSize;
  final EdgeInsetsGeometry? padding;
  final StatusType? statusType;

  const StatusChip({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.iconSize,
    this.padding,
    this.statusType,
  });

  @override
  Widget build(BuildContext context) {
    // Determine colors based on status type if provided
    Color bgColor = backgroundColor ?? _getBackgroundColor();
    Color txtColor = textColor ?? _getTextColor();

    return Container(
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: 12.0,
            vertical: 6.0,
          ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: iconSize ?? 14.0,
              color: txtColor,
            ),
            const SizedBox(width: 4.0),
          ],
          Text(
            label,
            style: AppTextStyles.bodySmall(color: txtColor).copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Get background color based on status type
  Color _getBackgroundColor() {
    if (statusType == null) return AppColorPalette.lightGrey;

    switch (statusType!) {
      case StatusType.success:
        return AppColorPalette.success.withOpacity(0.15);
      case StatusType.warning:
        return AppColorPalette.warning.withOpacity(0.15);
      case StatusType.error:
        return AppColorPalette.alertError.withOpacity(0.15);
      case StatusType.info:
        return AppColorPalette.info.withOpacity(0.15);
      case StatusType.healthy:
        return AppColorPalette.healthGlow.withOpacity(0.15);
      case StatusType.neutral:
        return AppColorPalette.lightGrey;
    }
  }

  /// Get text color based on status type
  Color _getTextColor() {
    if (statusType == null) return AppColorPalette.charcoalGreen;

    switch (statusType!) {
      case StatusType.success:
        return AppColorPalette.success;
      case StatusType.warning:
        return AppColorPalette.warning;
      case StatusType.error:
        return AppColorPalette.alertError;
      case StatusType.info:
        return AppColorPalette.info;
      case StatusType.healthy:
        return const Color(0xFF6B8E00); // Darker shade of health glow for readability
      case StatusType.neutral:
        return AppColorPalette.charcoalGreen;
    }
  }

  /// Factory constructor for success status
  factory StatusChip.success({
    required String label,
    IconData? icon,
  }) {
    return StatusChip(
      label: label,
      statusType: StatusType.success,
      icon: icon ?? Icons.check_circle,
    );
  }

  /// Factory constructor for warning status
  factory StatusChip.warning({
    required String label,
    IconData? icon,
  }) {
    return StatusChip(
      label: label,
      statusType: StatusType.warning,
      icon: icon ?? Icons.warning,
    );
  }

  /// Factory constructor for error status
  factory StatusChip.error({
    required String label,
    IconData? icon,
  }) {
    return StatusChip(
      label: label,
      statusType: StatusType.error,
      icon: icon ?? Icons.error,
    );
  }

  /// Factory constructor for info status
  factory StatusChip.info({
    required String label,
    IconData? icon,
  }) {
    return StatusChip(
      label: label,
      statusType: StatusType.info,
      icon: icon ?? Icons.info,
    );
  }

  /// Factory constructor for healthy status
  factory StatusChip.healthy({
    required String label,
    IconData? icon,
  }) {
    return StatusChip(
      label: label,
      statusType: StatusType.healthy,
      icon: icon ?? Icons.favorite,
    );
  }
}

/// Enum for different status types
enum StatusType {
  success,
  warning,
  error,
  info,
  healthy,
  neutral,
}
