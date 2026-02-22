import 'package:flutter/material.dart';
import '../../theme/color_palette.dart';
import '../../theme/text_styles.dart';

/// Reusable badge widget for displaying status information
/// Used for pH status, moisture status, etc.
class StatusBadge extends StatelessWidget {
  final String label;
  final StatusBadgeType type;
  final IconData? icon;
  final bool compact;

  const StatusBadge({
    super.key,
    required this.label,
    required this.type,
    this.icon,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final bgColor = color.withOpacity(0.15);

    return Container(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
          : const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: compact ? 12 : 14,
              color: color,
            ),
            SizedBox(width: compact ? 4 : 6),
          ],
          Text(
            label,
            style: (compact ? AppTextStyles.caption() : AppTextStyles.bodySmall()).copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor() {
    switch (type) {
      case StatusBadgeType.acidic:
        return AppColorPalette.alertError;
      case StatusBadgeType.neutral:
        return AppColorPalette.success;
      case StatusBadgeType.alkaline:
        return AppColorPalette.warning;
      case StatusBadgeType.dry:
        return AppColorPalette.alertError;
      case StatusBadgeType.optimal:
        return AppColorPalette.success;
      case StatusBadgeType.wet:
        return AppColorPalette.info;
      case StatusBadgeType.healthy:
        return AppColorPalette.success;
      case StatusBadgeType.warning:
        return AppColorPalette.warning;
      case StatusBadgeType.critical:
        return AppColorPalette.alertError;
      case StatusBadgeType.info:
        return AppColorPalette.info;
    }
  }

  /// Factory for pH status badges
  factory StatusBadge.ph({
    required String status,
    bool compact = false,
  }) {
    StatusBadgeType type;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'acidic':
        type = StatusBadgeType.acidic;
        icon = Icons.water_drop;
        break;
      case 'alkaline':
        type = StatusBadgeType.alkaline;
        icon = Icons.science;
        break;
      default:
        type = StatusBadgeType.neutral;
        icon = Icons.check_circle;
    }

    return StatusBadge(
      label: status,
      type: type,
      icon: icon,
      compact: compact,
    );
  }

  /// Factory for moisture status badges
  factory StatusBadge.moisture({
    required String status,
    bool compact = false,
  }) {
    StatusBadgeType type;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'dry':
        type = StatusBadgeType.dry;
        icon = Icons.water_drop_outlined;
        break;
      case 'wet':
        type = StatusBadgeType.wet;
        icon = Icons.water;
        break;
      default:
        type = StatusBadgeType.optimal;
        icon = Icons.check_circle;
    }

    return StatusBadge(
      label: status,
      type: type,
      icon: icon,
      compact: compact,
    );
  }

  /// Factory for health status badges
  factory StatusBadge.health({
    required bool isHealthy,
    bool compact = false,
  }) {
    return StatusBadge(
      label: isHealthy ? 'Healthy' : 'Warning',
      type: isHealthy ? StatusBadgeType.healthy : StatusBadgeType.warning,
      icon: isHealthy ? Icons.check_circle : Icons.warning,
      compact: compact,
    );
  }
}

/// Status badge types
enum StatusBadgeType {
  acidic,
  neutral,
  alkaline,
  dry,
  optimal,
  wet,
  healthy,
  warning,
  critical,
  info,
}
