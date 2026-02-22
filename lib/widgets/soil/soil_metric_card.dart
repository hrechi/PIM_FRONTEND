import 'package:flutter/material.dart';
import '../../theme/color_palette.dart';
import '../../theme/text_styles.dart';

/// Reusable card widget for displaying soil metrics
/// Shows a metric with icon, label, value, and optional trend
class SoilMetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool compact;

  const SoilMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor,
    this.backgroundColor,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? AppColorPalette.white;
    final iconClr = iconColor ?? AppColorPalette.mistyBlue;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: compact
            ? const EdgeInsets.all(12)
            : const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColorPalette.softSlate.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColorPalette.charcoalGreen.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconClr.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    size: compact ? 20 : 24,
                    color: iconClr,
                  ),
                ),
                const SizedBox(width: 12),

                // Label and Value
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: compact
                            ? AppTextStyles.caption()
                            : AppTextStyles.bodySmall(
                                color: AppColorPalette.softSlate,
                              ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: compact
                            ? AppTextStyles.bodyMedium().copyWith(
                                fontWeight: FontWeight.bold,
                              )
                            : AppTextStyles.h4(),
                      ),
                    ],
                  ),
                ),

                // Trailing widget (optional)
                if (trailing != null) trailing!,
              ],
            ),

            // Subtitle (optional)
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: AppTextStyles.caption(
                  color: AppColorPalette.softSlate,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Factory for pH metric
  factory SoilMetricCard.ph({
    required double value,
    required String status,
    bool compact = false,
    VoidCallback? onTap,
  }) {
    Color iconColor;
    if (status == 'Acidic') {
      iconColor = AppColorPalette.alertError;
    } else if (status == 'Alkaline') {
      iconColor = AppColorPalette.warning;
    } else {
      iconColor = AppColorPalette.success;
    }

    return SoilMetricCard(
      label: 'pH Level',
      value: value.toStringAsFixed(1),
      icon: Icons.science,
      iconColor: iconColor,
      subtitle: status,
      compact: compact,
      onTap: onTap,
    );
  }

  /// Factory for moisture metric
  factory SoilMetricCard.moisture({
    required double value,
    required String status,
    bool compact = false,
    VoidCallback? onTap,
  }) {
    Color iconColor;
    if (status == 'Dry') {
      iconColor = AppColorPalette.alertError;
    } else if (status == 'Wet') {
      iconColor = AppColorPalette.info;
    } else {
      iconColor = AppColorPalette.success;
    }

    return SoilMetricCard(
      label: 'Soil Moisture',
      value: '${value.toStringAsFixed(0)}%',
      icon: Icons.water_drop,
      iconColor: iconColor,
      subtitle: status,
      compact: compact,
      onTap: onTap,
    );
  }

  /// Factory for sunlight metric
  factory SoilMetricCard.sunlight({
    required double value,
    bool compact = false,
    VoidCallback? onTap,
  }) {
    return SoilMetricCard(
      label: 'Sunlight',
      value: '${value.toStringAsFixed(0)} lux',
      icon: Icons.wb_sunny,
      iconColor: AppColorPalette.warning,
      compact: compact,
      onTap: onTap,
    );
  }

  /// Factory for temperature metric
  factory SoilMetricCard.temperature({
    required double value,
    bool compact = false,
    VoidCallback? onTap,
  }) {
    return SoilMetricCard(
      label: 'Temperature',
      value: '${value.toStringAsFixed(1)}°C',
      icon: Icons.thermostat,
      iconColor: AppColorPalette.alertError,
      compact: compact,
      onTap: onTap,
    );
  }

  /// Factory for nutrients metric
  factory SoilMetricCard.nutrients({
    required String value,
    bool compact = false,
    VoidCallback? onTap,
  }) {
    return SoilMetricCard(
      label: 'Nutrients (N-P-K)',
      value: value,
      icon: Icons.grass,
      iconColor: AppColorPalette.success,
      compact: compact,
      onTap: onTap,
    );
  }
}
