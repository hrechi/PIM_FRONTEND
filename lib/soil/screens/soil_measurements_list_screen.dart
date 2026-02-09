import 'package:flutter/material.dart';
import '../../../theme/color_palette.dart';
import '../../../theme/text_styles.dart';
import '../../../utils/responsive.dart';
import '../models/soil_measurement.dart';
import '../widgets/measurement_tile.dart';
import 'soil_measurement_form_screen.dart';
import 'soil_measurement_details_screen.dart';
import 'soil_analytics_screen.dart';
import 'soil_map_screen.dart';

/// Screen displaying list of all soil measurements
/// Route: /soil
class SoilMeasurementsListScreen extends StatefulWidget {
  const SoilMeasurementsListScreen({super.key});

  @override
  State<SoilMeasurementsListScreen> createState() =>
      _SoilMeasurementsListScreenState();
}

class _SoilMeasurementsListScreenState
    extends State<SoilMeasurementsListScreen> {
  List<SoilMeasurement> measurements = [];
  bool isLoading = false;
  String filterStatus = 'All'; // All, Healthy, Warning

  @override
  void initState() {
    super.initState();
    _loadMeasurements();
  }

  /// Load measurements (mock data for now)
  Future<void> _loadMeasurements() async {
    setState(() => isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      measurements = SoilMeasurement.getMockData();
      isLoading = false;
    });
  }

  /// Filter measurements based on health status
  List<SoilMeasurement> get filteredMeasurements {
    if (filterStatus == 'All') return measurements;
    if (filterStatus == 'Healthy') {
      return measurements.where((m) => m.isHealthy).toList();
    }
    return measurements.where((m) => !m.isHealthy).toList();
  }

  /// Navigate to add measurement screen
  Future<void> _navigateToAddMeasurement() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SoilMeasurementFormScreen(),
      ),
    );

    // Reload if measurement was added
    if (result == true) {
      _loadMeasurements();
    }
  }

  /// Navigate to details screen
  void _navigateToDetails(SoilMeasurement measurement) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SoilMeasurementDetailsScreen(
          measurement: measurement,
        ),
      ),
    );
  }

  /// Delete measurement
  void _deleteMeasurement(SoilMeasurement measurement) {
    setState(() {
      measurements.removeWhere((m) => m.idMesure == measurement.idMesure);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Measurement ${measurement.idMesure} deleted'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            setState(() {
              measurements.add(measurement);
              measurements.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = filteredMeasurements;

    return Scaffold(
      backgroundColor: AppColorPalette.wheatWarmClay,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Soil Measurements',
              style: AppTextStyles.h3(),
            ),
            Text(
              '${measurements.length} total measurements',
              style: AppTextStyles.caption(
                color: AppColorPalette.softSlate,
              ),
            ),
          ],
        ),
        actions: [
          // Analytics button
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SoilAnalyticsScreen(),
                ),
              );
            },
            tooltip: 'View Analytics',
          ),
          // Map button
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SoilMapScreen(
                    measurements: measurements,
                  ),
                ),
              );
            },
            tooltip: 'View Map',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Responsive.constrainedContent(
        context: context,
        child: Column(
          children: [
            // Filter chips
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.horizontalPadding(context),
                vertical: 12,
              ),
              child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    count: measurements.length,
                    isSelected: filterStatus == 'All',
                    onTap: () => setState(() => filterStatus = 'All'),
                  ),
                  SizedBox(width: Responsive.spacing(context)),
                  _FilterChip(
                    label: 'Healthy',
                    count: measurements.where((m) => m.isHealthy).length,
                    isSelected: filterStatus == 'Healthy',
                    onTap: () => setState(() => filterStatus = 'Healthy'),
                    color: AppColorPalette.success,
                  ),
                  SizedBox(width: Responsive.spacing(context)),
                  _FilterChip(
                    label: 'Warning',
                    count: measurements.where((m) => !m.isHealthy).length,
                    isSelected: filterStatus == 'Warning',
                    onTap: () => setState(() => filterStatus = 'Warning'),
                    color: AppColorPalette.alertError,
                  ),
                ],
              ),
            ),
          ),

          // Measurements list
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : filtered.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadMeasurements,
                        child: ListView.builder(
                          padding: EdgeInsets.only(
                            bottom: 80,
                            left: Responsive.horizontalPadding(context),
                            right: Responsive.horizontalPadding(context),
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final measurement = filtered[index];
                            return MeasurementTile(
                              measurement: measurement,
                              onTap: () => _navigateToDetails(measurement),
                              onDelete: () => _deleteMeasurement(measurement),
                            );
                          },
                        ),
                      ),
          ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddMeasurement,
        icon: const Icon(Icons.add),
        label: const Text('Add Measurement'),
        backgroundColor: AppColorPalette.mistyBlue,
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.grass,
            size: 80,
            color: AppColorPalette.softSlate.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            filterStatus == 'All'
                ? 'No measurements yet'
                : 'No $filterStatus measurements',
            style: AppTextStyles.h4(
              color: AppColorPalette.softSlate,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            filterStatus == 'All'
                ? 'Tap the button below to add your first measurement'
                : 'Try changing the filter',
            style: AppTextStyles.bodyMedium(
              color: AppColorPalette.softSlate,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Filter chip widget
class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColorPalette.mistyBlue;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? chipColor
              : AppColorPalette.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? chipColor
                : AppColorPalette.softSlate.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.bodySmall().copyWith(
                color: isSelected
                    ? AppColorPalette.white
                    : AppColorPalette.charcoalGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColorPalette.white.withOpacity(0.3)
                    : chipColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: AppTextStyles.caption().copyWith(
                  color: isSelected
                      ? AppColorPalette.white
                      : chipColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
