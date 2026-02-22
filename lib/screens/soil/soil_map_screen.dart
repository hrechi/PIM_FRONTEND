import 'package:flutter/material.dart';
import '../../theme/color_palette.dart';
import '../../theme/text_styles.dart';
import '../../utils/responsive.dart';
import '../../models/soil_measurement.dart';
import '../../widgets/soil/status_badge.dart';
import 'soil_measurement_details_screen.dart';

/// Screen displaying soil measurements on a map
/// Route: /soil/map
class SoilMapScreen extends StatefulWidget {
  final List<SoilMeasurement> measurements;

  const SoilMapScreen({
    super.key,
    required this.measurements,
  });

  @override
  State<SoilMapScreen> createState() => _SoilMapScreenState();
}

class _SoilMapScreenState extends State<SoilMapScreen> {
  SoilMeasurement? selectedMeasurement;

  /// Show measurement details in bottom sheet
  void _showMeasurementDetails(SoilMeasurement measurement) {
    setState(() {
      selectedMeasurement = measurement;
    });

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _MeasurementBottomSheet(
        measurement: measurement,
        onViewDetails: () {
          Navigator.pop(context); // Close bottom sheet
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SoilMeasurementDetailsScreen(
                measurement: measurement,
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorPalette.wheatWarmClay,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Soil Map',
              style: AppTextStyles.h3(),
            ),
            Text(
              '${widget.measurements.length} measurements',
              style: AppTextStyles.caption(
                color: AppColorPalette.softSlate,
              ),
            ),
          ],
        ),
        actions: [
          // Legend button
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showLegend(),
            tooltip: 'Legend',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Responsive.constrainedContent(
        context: context,
        child: Stack(
          children: [
          // Map placeholder with markers
          _buildMapView(),

          // Filter chips at top
          Positioned(
            top: Responsive.spacing(context, mobile: 12, tablet: 16, desktop: 20),
            left: 0,
            right: 0,
            child: _buildFilterChips(),
          ),
        ],
      ),
     ) );
  }

  /// Build map view with measurement markers
  Widget _buildMapView() {
    return Container(
      color: AppColorPalette.lightGrey,
      child: Stack(
        children: [
          // Map background pattern
          CustomPaint(
            size: Size.infinite,
            painter: _MapBackgroundPainter(),
          ),

          // Center text
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.map,
                  size: 64,
                  color: AppColorPalette.softSlate.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'Interactive Map View',
                  style: AppTextStyles.h4(
                    color: AppColorPalette.softSlate,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap markers to view details',
                  style: AppTextStyles.bodySmall(
                    color: AppColorPalette.softSlate,
                  ),
                ),
              ],
            ),
          ),

          // Measurement markers
          ...widget.measurements.asMap().entries.map((entry) {
            final index = entry.key;
            final measurement = entry.value;

            // Calculate position (mock positioning based on index and lat/lng)
            final screenWidth = MediaQuery.of(context).size.width;
            final screenHeight = MediaQuery.of(context).size.height;

            // Simple positioning algorithm for demo
            final x = (screenWidth * 0.2) +
                ((index % 4) * screenWidth * 0.2) +
                ((measurement.longitude + 122.4194) * 1000).abs() % 50;
            final y = (screenHeight * 0.2) +
                ((index ~/ 4) * screenHeight * 0.15) +
                ((measurement.latitude - 37.7749) * 1000).abs() % 50;

            return Positioned(
              left: x.clamp(20.0, screenWidth - 60),
              top: y.clamp(100.0, screenHeight - 200),
              child: _MapMarker(
                measurement: measurement,
                onTap: () => _showMeasurementDetails(measurement),
                isSelected: selectedMeasurement?.id == measurement.id,
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// Build filter chips
  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _MapFilterChip(
              icon: Icons.check_circle,
              label: 'Healthy',
              count: widget.measurements.where((m) => m.isHealthy).length,
              color: AppColorPalette.success,
            ),
            const SizedBox(width: 8),
            _MapFilterChip(
              icon: Icons.warning,
              label: 'Warning',
              count: widget.measurements.where((m) => !m.isHealthy).length,
              color: AppColorPalette.alertError,
            ),
          ],
        ),
      ),
    );
  }

  /// Show map legend
  void _showLegend() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Map Legend'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LegendItem(
              color: AppColorPalette.success,
              label: 'Healthy soil conditions',
            ),
            const SizedBox(height: 12),
            _LegendItem(
              color: AppColorPalette.warning,
              label: 'Moderate issues detected',
            ),
            const SizedBox(height: 12),
            _LegendItem(
              color: AppColorPalette.alertError,
              label: 'Critical issues detected',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Map marker widget
class _MapMarker extends StatelessWidget {
  final SoilMeasurement measurement;
  final VoidCallback onTap;
  final bool isSelected;

  const _MapMarker({
    required this.measurement,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = measurement.isHealthy
        ? AppColorPalette.success
        : measurement.healthScore > 50
            ? AppColorPalette.warning
            : AppColorPalette.alertError;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isSelected ? 50 : 40,
        height: isSelected ? 50 : 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Pulse animation when selected
            if (isSelected)
              Container(
                decoration: BoxDecoration(
                  color: color.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ),
            // Main marker
            Container(
              width: isSelected ? 36 : 28,
              height: isSelected ? 36 : 28,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColorPalette.white,
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.location_on,
                size: isSelected ? 20 : 16,
                color: AppColorPalette.white,
              ),
            ),
            // ID label
            if (isSelected)
              Positioned(
                bottom: -20,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColorPalette.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColorPalette.charcoalGreen.withOpacity(0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Text(
                    measurement.id.split('-').last,
                    style: AppTextStyles.caption().copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for measurement details
class _MeasurementBottomSheet extends StatelessWidget {
  final SoilMeasurement measurement;
  final VoidCallback onViewDetails;

  const _MeasurementBottomSheet({
    required this.measurement,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColorPalette.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColorPalette.charcoalGreen.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ID: ...${measurement.id.split('-').last}',
                      style: AppTextStyles.h3(),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      measurement.formattedDateTime,
                      style: AppTextStyles.caption(
                        color: AppColorPalette.softSlate,
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge.health(
                isHealthy: measurement.isHealthy,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Quick metrics
          Row(
            children: [
              Expanded(
                child: _QuickMetric(
                  icon: Icons.science,
                  label: 'pH',
                  value: measurement.ph.toStringAsFixed(1),
                  color: measurement.phStatusEnum == PhStatus.neutral
                      ? AppColorPalette.success
                      : AppColorPalette.alertError,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickMetric(
                  icon: Icons.water_drop,
                  label: 'Moisture',
                  value: '${measurement.soilMoisture.toStringAsFixed(0)}%',
                  color: measurement.moistureStatusEnum == MoistureStatus.optimal
                      ? AppColorPalette.success
                      : AppColorPalette.alertError,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickMetric(
                  icon: Icons.thermostat,
                  label: 'Temp',
                  value: '${measurement.temperature.toStringAsFixed(0)}°C',
                  color: AppColorPalette.warning,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Status badges
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

          const SizedBox(height: 20),

          // View details button
          ElevatedButton(
            onPressed: onViewDetails,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              backgroundColor: AppColorPalette.mistyBlue,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.remove_red_eye),
                const SizedBox(width: 8),
                Text(
                  'View Full Details',
                  style: AppTextStyles.buttonMedium(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick metric widget for bottom sheet
class _QuickMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _QuickMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.bodyMedium().copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption(
              color: AppColorPalette.softSlate,
            ),
          ),
        ],
      ),
    );
  }
}

/// Map filter chip
class _MapFilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;

  const _MapFilterChip({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColorPalette.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColorPalette.charcoalGreen.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.bodySmall().copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              count.toString(),
              style: AppTextStyles.caption().copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Legend item
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColorPalette.white,
              width: 2,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodyMedium(),
          ),
        ),
      ],
    );
  }
}

/// Map background painter
class _MapBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColorPalette.softSlate.withOpacity(0.1)
      ..strokeWidth = 1;

    // Draw grid
    const gridSize = 50.0;
    for (double i = 0; i < size.width; i += gridSize) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        paint,
      );
    }
    for (double i = 0; i < size.height; i += gridSize) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
