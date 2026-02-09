import 'package:flutter/material.dart';
import '../../../theme/color_palette.dart';
import '../../../theme/text_styles.dart';
import '../models/soil_measurement.dart';
import 'status_badge.dart';

/// Tile widget for displaying soil measurement in a list
/// Shows summary information with tap and swipe actions
class MeasurementTile extends StatelessWidget {
  final SoilMeasurement measurement;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool showActions;

  const MeasurementTile({
    super.key,
    required this.measurement,
    this.onTap,
    this.onDelete,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColorPalette.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: measurement.isHealthy
              ? AppColorPalette.success.withOpacity(0.3)
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: ID and Date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // ID with icon
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColorPalette.mistyBlue.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.location_on,
                            size: 18,
                            color: AppColorPalette.mistyBlue,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          measurement.idMesure,
                          style: AppTextStyles.bodyLarge().copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    // Health status badge
                    StatusBadge.health(
                      isHealthy: measurement.isHealthy,
                      compact: true,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Metrics Row
                Row(
                  children: [
                    // pH
                    Expanded(
                      child: _MetricItem(
                        icon: Icons.science,
                        label: 'pH',
                        value: measurement.ph.toStringAsFixed(1),
                        color: _getPhColor(measurement.ph),
                      ),
                    ),

                    // Divider
                    Container(
                      width: 1,
                      height: 40,
                      color: AppColorPalette.softSlate.withOpacity(0.2),
                    ),

                    // Moisture
                    Expanded(
                      child: _MetricItem(
                        icon: Icons.water_drop,
                        label: 'Moisture',
                        value: '${measurement.soilMoisture.toStringAsFixed(0)}%',
                        color: _getMoistureColor(measurement.soilMoisture),
                      ),
                    ),

                    // Divider
                    Container(
                      width: 1,
                      height: 40,
                      color: AppColorPalette.softSlate.withOpacity(0.2),
                    ),

                    // Temperature
                    Expanded(
                      child: _MetricItem(
                        icon: Icons.thermostat,
                        label: 'Temp',
                        value: '${measurement.temperature.toStringAsFixed(0)}°C',
                        color: AppColorPalette.warning,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Status Badges
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusBadge.ph(
                      status: measurement.phStatus,
                      compact: true,
                    ),
                    StatusBadge.moisture(
                      status: measurement.moistureStatus,
                      compact: true,
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Date
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: AppColorPalette.softSlate,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      measurement.formattedDateTime,
                      style: AppTextStyles.caption(
                        color: AppColorPalette.softSlate,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Wrap with dismissible for swipe to delete
    if (showActions && onDelete != null) {
      return Dismissible(
        key: Key(measurement.idMesure),
        direction: DismissDirection.endToStart,
        background: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColorPalette.alertError,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(
            Icons.delete,
            color: AppColorPalette.white,
            size: 32,
          ),
        ),
        confirmDismiss: (direction) async {
          return await showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Confirm Delete'),
                content: Text(
                  'Are you sure you want to delete measurement ${measurement.idMesure}?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColorPalette.alertError,
                    ),
                    child: const Text('Delete'),
                  ),
                ],
              );
            },
          );
        },
        onDismissed: (direction) {
          onDelete?.call();
        },
        child: content,
      );
    }

    return content;
  }

  Color _getPhColor(double ph) {
    if (ph < 6.0) return AppColorPalette.alertError;
    if (ph > 7.5) return AppColorPalette.warning;
    return AppColorPalette.success;
  }

  Color _getMoistureColor(double moisture) {
    if (moisture < 30) return AppColorPalette.alertError;
    if (moisture > 80) return AppColorPalette.info;
    return AppColorPalette.success;
  }
}

/// Internal metric item widget
class _MetricItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: color,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.caption(
            color: AppColorPalette.softSlate,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.bodySmall().copyWith(
            fontWeight: FontWeight.bold,
            color: AppColorPalette.charcoalGreen,
          ),
        ),
      ],
    );
  }
}
