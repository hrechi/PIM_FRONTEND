import 'package:flutter/material.dart';
import '../theme/color_palette.dart';
import '../theme/text_styles.dart';
import '../models/animal.dart';
import 'status_chip.dart';

/// Reusable card widget for displaying live health metrics
/// Optimized for horizontal scrolling in a ListView
class MetricCard extends StatelessWidget {
  final Animal animal;
  final VoidCallback? onTap;
  final double width;

  const MetricCard({
    super.key,
    required this.animal,
    this.onTap,
    this.width = 170.0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        margin: const EdgeInsets.only(right: 12.0),
        decoration: BoxDecoration(
          color: AppColorPalette.white,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(
            color: animal.isHealthy
                ? AppColorPalette.healthGlow.withOpacity(0.3)
                : AppColorPalette.alertError.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColorPalette.charcoalGreen.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Animal Image Placeholder
            Container(
              height: 110,
              decoration: BoxDecoration(
                color: AppColorPalette.lightGrey,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14.0),
                  topRight: Radius.circular(14.0),
                ),
                gradient: LinearGradient(
                  colors: [
                    AppColorPalette.mistyBlue.withOpacity(0.3),
                    AppColorPalette.emeraldGreen.withOpacity(0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Icon(
                  _getAnimalIcon(animal.type),
                  size: 48,
                  color: AppColorPalette.white,
                ),
              ),
            ),

            // Animal Info
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Animal ID
                  Text(
                    animal.id,
                    style: AppTextStyles.bodyMedium().copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2.0),

                  // Animal Type
                  Text(
                    animal.type,
                    style: AppTextStyles.caption(
                      color: AppColorPalette.softSlate,
                    ),
                  ),
                  const SizedBox(height: 8.0),

                  // Temperature Metric
                  _MetricRow(
                    icon: Icons.thermostat,
                    label: 'Temp',
                    value: animal.formattedTemperature,
                    isWarning: animal.temperature > 39.0,
                  ),
                  const SizedBox(height: 6.0),

                  // Heart Rate Metric
                  _MetricRow(
                    icon: Icons.favorite,
                    label: 'Heart',
                    value: animal.formattedHeartRate,
                    isWarning: false,
                  ),
                  const SizedBox(height: 8.0),

                  // Status Chip
                  animal.isHealthy
                      ? StatusChip.healthy(
                          label: 'Healthy',
                          icon: Icons.check_circle_outline,
                        )
                      : StatusChip.warning(
                          label: 'Attention',
                          icon: Icons.warning_amber,
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get appropriate icon for animal type
  IconData _getAnimalIcon(String type) {
    switch (type.toLowerCase()) {
      case 'cow':
        return Icons.agriculture; // Closest to a cow
      case 'sheep':
        return Icons.pets;
      case 'goat':
        return Icons.pets;
      case 'chicken':
        return Icons.egg;
      default:
        return Icons.pets;
    }
  }
}

/// Internal widget for displaying metric rows
class _MetricRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isWarning;

  const _MetricRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: isWarning
              ? AppColorPalette.alertError
              : AppColorPalette.softSlate,
        ),
        const SizedBox(width: 6.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.caption(
                  color: AppColorPalette.softSlate,
                ),
              ),
              Text(
                value,
                style: AppTextStyles.bodySmall(
                  color: isWarning
                      ? AppColorPalette.alertError
                      : AppColorPalette.charcoalGreen,
                ).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
