import 'package:flutter/material.dart';
import '../../../theme/color_palette.dart';
import '../../../theme/text_styles.dart';
import '../../../utils/responsive.dart';
import '../models/soil_measurement.dart';
import '../widgets/status_badge.dart';
import '../widgets/soil_metric_card.dart';
import 'soil_measurement_form_screen.dart';

/// Screen displaying detailed information about a soil measurement
/// Route: /soil/:id
class SoilMeasurementDetailsScreen extends StatefulWidget {
  final SoilMeasurement measurement;

  const SoilMeasurementDetailsScreen({
    super.key,
    required this.measurement,
  });

  @override
  State<SoilMeasurementDetailsScreen> createState() =>
      _SoilMeasurementDetailsScreenState();
}

class _SoilMeasurementDetailsScreenState
    extends State<SoilMeasurementDetailsScreen> {
  late SoilMeasurement measurement;

  @override
  void initState() {
    super.initState();
    measurement = widget.measurement;
  }

  /// Navigate to edit screen
  Future<void> _editMeasurement() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SoilMeasurementFormScreen(
          measurement: measurement,
        ),
      ),
    );

    // Reload if measurement was edited
    if (result == true && mounted) {
      // In production, reload from API
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Measurement updated'),
        ),
      );
    }
  }

  /// Delete measurement
  Future<void> _deleteMeasurement() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Measurement'),
        content: Text(
          'Are you sure you want to delete measurement ${measurement.idMesure}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: AppColorPalette.alertError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // In production, delete from API
      Navigator.pop(context, 'deleted');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Measurement ${measurement.idMesure} deleted'),
          backgroundColor: AppColorPalette.alertError,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorPalette.wheatWarmClay,
      appBar: AppBar(
        title: Text(
          measurement.idMesure,
          style: AppTextStyles.h3(),
        ),
        actions: [
          // Edit button
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editMeasurement,
            tooltip: 'Edit',
          ),
          // Delete button
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteMeasurement,
            color: AppColorPalette.alertError,
            tooltip: 'Delete',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Responsive.constrainedContent(
        context: context,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(Responsive.cardPadding(context)),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card - Overall Status
            _buildHeaderCard(),

            const SizedBox(height: 16),

            // Status Badges Section
            _buildStatusBadges(),

            const SizedBox(height: 24),

            // Metrics Grid
            _buildMetricsGrid(),

            const SizedBox(height: 24),

            // Nutrients Section
            _buildNutrientsSection(),

            const SizedBox(height: 24),

            // Location Section
            _buildLocationSection(),

            const SizedBox(height: 24),

            // Metadata Section
            _buildMetadataSection(),

            const SizedBox(height: 80),
          ],
        ),
      ),
    ));
    
  }

  /// Build header card with overall status
  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: measurement.isHealthy
            ? AppColorPalette.successGradient
            : AppColorPalette.alertGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColorPalette.charcoalGreen.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                measurement.isHealthy ? Icons.check_circle : Icons.warning,
                color: AppColorPalette.white,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      measurement.isHealthy
                          ? 'Healthy Soil'
                          : 'Requires Attention',
                      style: AppTextStyles.h3(
                        color: AppColorPalette.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Health Score: ${measurement.healthScore.toStringAsFixed(0)}%',
                      style: AppTextStyles.bodyMedium(
                        color: AppColorPalette.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: AppColorPalette.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: measurement.healthScore / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColorPalette.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build status badges
  Widget _buildStatusBadges() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status Indicators',
          style: AppTextStyles.h4(),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            StatusBadge.ph(status: measurement.phStatus),
            StatusBadge.moisture(status: measurement.moistureStatus),
            StatusBadge.health(isHealthy: measurement.isHealthy),
          ],
        ),
      ],
    );
  }

  /// Build metrics grid
  Widget _buildMetricsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Measurements',
          style: AppTextStyles.h4(),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: Responsive.gridColumns(
            context,
            mobile: 1,
            tablet: 2,
            desktop: 2,
          ),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: Responsive.value(
            context,
            mobile: 2.5,
            tablet: 1.8,
            desktop: 2.0,
          ),
          children: [
            SoilMetricCard.ph(
              value: measurement.ph,
              status: measurement.phStatus,
              compact: true,
            ),
            SoilMetricCard.moisture(
              value: measurement.soilMoisture,
              status: measurement.moistureStatus,
              compact: true,
            ),
            SoilMetricCard.sunlight(
              value: measurement.sunlight,
              compact: true,
            ),
            SoilMetricCard.temperature(
              value: measurement.temperature,
              compact: true,
            ),
          ],
        ),
      ],
    );
  }

  /// Build nutrients section
  Widget _buildNutrientsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColorPalette.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColorPalette.softSlate.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColorPalette.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.grass,
                  size: 20,
                  color: AppColorPalette.success,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Nutrients (N-P-K)',
                style: AppTextStyles.h4(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...measurement.nutrients.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getNutrientName(entry.key),
                    style: AppTextStyles.bodyMedium(),
                  ),
                  Text(
                    '${entry.value.toStringAsFixed(1)}%',
                    style: AppTextStyles.bodyMedium().copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColorPalette.success,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// Build location section
  Widget _buildLocationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColorPalette.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColorPalette.softSlate.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColorPalette.info.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.location_on,
                  size: 20,
                  color: AppColorPalette.info,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Location',
                style: AppTextStyles.h4(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _LocationRow(
            label: 'Latitude',
            value: measurement.latitude.toStringAsFixed(6),
          ),
          const SizedBox(height: 8),
          _LocationRow(
            label: 'Longitude',
            value: measurement.longitude.toStringAsFixed(6),
          ),
        ],
      ),
    );
  }

  /// Build metadata section
  Widget _buildMetadataSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColorPalette.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColorPalette.softSlate.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColorPalette.softSlate.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.info_outline,
                  size: 20,
                  color: AppColorPalette.softSlate,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Measurement Info',
                style: AppTextStyles.h4(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _MetadataRow(
            label: 'Measurement ID',
            value: measurement.idMesure,
          ),
          const SizedBox(height: 8),
          _MetadataRow(
            label: 'Date & Time',
            value: measurement.formattedDateTime,
          ),
        ],
      ),
    );
  }

  String _getNutrientName(String code) {
    switch (code) {
      case 'N':
        return 'Nitrogen';
      case 'P':
        return 'Phosphorus';
      case 'K':
        return 'Potassium';
      default:
        return code;
    }
  }
}

/// Location row widget
class _LocationRow extends StatelessWidget {
  final String label;
  final String value;

  const _LocationRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium(
            color: AppColorPalette.softSlate,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium().copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Metadata row widget
class _MetadataRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetadataRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium(
            color: AppColorPalette.softSlate,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium().copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}
