import 'package:flutter/material.dart';
import '../../theme/color_palette.dart';
import '../../theme/text_styles.dart';
import '../../models/soil_measurement.dart';
import '../../models/field_model.dart';
import '../../services/field_service.dart';
import 'status_badge.dart';

/// Tile widget for displaying soil measurement in a list
/// Shows summary information with tap and swipe actions
class MeasurementTile extends StatefulWidget {
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
  State<MeasurementTile> createState() => _MeasurementTileState();
}

class _MeasurementTileState extends State<MeasurementTile> {
  final FieldService _fieldService = FieldService();
  FieldModel? _field;
  bool _isLoadingField = false;

  @override
  void initState() {
    super.initState();
    if (widget.measurement.fieldId != null) {
      _loadField();
    }
  }

  Future<void> _loadField() async {
    setState(() => _isLoadingField = true);
    try {
      final fields = await _fieldService.getFields();
      final field = fields.firstWhere(
        (f) => f.id == widget.measurement.fieldId,
        orElse: () => throw Exception('Field not found'),
      );
      if (mounted) {
        setState(() {
          _field = field;
          _isLoadingField = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingField = false);
      }
    }
  }

  String get _displayName {
    if (widget.measurement.fieldId != null && _field != null) {
      return _field!.name;
    }
    return widget.measurement.shortLocation;
  }

  @override
  Widget build(BuildContext context) {
    Widget content = Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColorPalette.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.measurement.isHealthy
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
          onTap: widget.onTap,
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
                    // Location/Field with icon
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: widget.measurement.fieldId != null
                                  ? AppColorPalette.fieldFreshStart.withOpacity(0.15)
                                  : AppColorPalette.mistyBlue.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              widget.measurement.fieldId != null
                                  ? Icons.landscape
                                  : Icons.location_on,
                              size: 18,
                              color: widget.measurement.fieldId != null
                                  ? AppColorPalette.fieldFreshStart
                                  : AppColorPalette.mistyBlue,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _isLoadingField
                                ? Text(
                                    'Loading...',
                                    style: AppTextStyles.bodyMedium().copyWith(
                                      color: AppColorPalette.softSlate,
                                    ),
                                  )
                                : Text(
                                    _displayName,
                                    style: AppTextStyles.bodyLarge().copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                          ),
                        ],
                      ),
                    ),

                    // Health status badge
                    StatusBadge.health(
                      isHealthy: widget.measurement.isHealthy,
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
                        value: widget.measurement.ph.toStringAsFixed(1),
                        color: _getPhColor(widget.measurement.ph),
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
                        value: '${widget.measurement.soilMoisture.toStringAsFixed(0)}%',
                        color: _getMoistureColor(widget.measurement.soilMoisture),
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
                        value: '${widget.measurement.temperature.toStringAsFixed(0)}°C',
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
                      status: widget.measurement.phStatus,
                      compact: true,
                    ),
                    StatusBadge.moisture(
                      status: widget.measurement.moistureStatus,
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
                      widget.measurement.formattedDateTime,
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
    if (widget.showActions && widget.onDelete != null) {
      return Dismissible(
        key: Key(widget.measurement.id),
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
                  'Are you sure you want to delete measurement at ${_displayName}?',
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
          widget.onDelete?.call();
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
