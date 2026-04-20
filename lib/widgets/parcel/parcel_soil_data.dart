import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/soil_measurement.dart';
import '../../theme/color_palette.dart';
import '../../theme/text_styles.dart';
import '../soil/status_badge.dart';

/// Widget displaying soil data for a parcel
/// Shows latest metrics, status badges, and 13-week trend chart
class ParcelSoilDataWidget extends StatelessWidget {
  final String parcelId;
  final String parcelName;
  final List<SoilMeasurement> measurements; // Sorted by createdAt DESC
  final VoidCallback onAddMeasurement;
  final bool isLoading;

  const ParcelSoilDataWidget({
    super.key,
    required this.parcelId,
    required this.parcelName,
    required this.measurements,
    required this.onAddMeasurement,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _loadingState();
    }

    if (measurements.isEmpty) {
      return _emptyState(context);
    }

    final latest = measurements.first;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Latest Metrics Cards ──
            _buildLatestMetricsRow(latest),
            const SizedBox(height: 20),

            // ── Status Badges ──
            _buildStatusBadgesRow(latest),
            const SizedBox(height: 24),

            // ── Trend Chart (13 weeks) ──
            if (measurements.isNotEmpty)
              _buildTrendChartCard(context, measurements),
            const SizedBox(height: 16),

            // ── Last Update Info ──
            Center(
              child: Text(
                'Last measured: ${DateFormat.yMMMd().format(latest.createdAt)}',
                style: AppTextStyles.bodySmall().copyWith(
                  color: AppColorPalette.softSlate,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build empty state widget
  Widget _emptyState(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 40, 20, 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColorPalette.fieldFreshStart.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                '🧪',
                style: TextStyle(fontSize: 40),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No soil measurements yet',
            style: AppTextStyles.bodyLarge().copyWith(
              fontWeight: FontWeight.w600,
              color: AppColorPalette.charcoalGreen,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Add a soil measurement to track health and trends',
            style: AppTextStyles.bodySmall().copyWith(
              color: AppColorPalette.softSlate,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onAddMeasurement,
            icon: const Icon(Icons.add),
            label: const Text('Add Measurement'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorPalette.fieldFreshStart,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build loading state
  Widget _loadingState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColorPalette.fieldFreshStart,
        ),
      ),
    );
  }

  /// Build latest metrics display
  Widget _buildLatestMetricsRow(SoilMeasurement latest) {
    return Row(
      children: [
        _metricCard(
          icon: Icons.science,
          label: 'pH',
          value: latest.ph.toStringAsFixed(1),
          unit: '',
          color: AppColorPalette.info,
        ),
        const SizedBox(width: 12),
        _metricCard(
          icon: Icons.water_drop,
          label: 'Moisture',
          value: latest.soilMoisture.toStringAsFixed(0),
          unit: '%',
          color: AppColorPalette.fieldFreshStart,
        ),
        const SizedBox(width: 12),
        _metricCard(
          icon: Icons.thermostat,
          label: 'Temp',
          value: latest.temperature.toStringAsFixed(0),
          unit: '°C',
          color: AppColorPalette.alertError,
        ),
      ],
    );
  }

  /// Build a metric card
  Widget _metricCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColorPalette.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: color.withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColorPalette.charcoalGreen.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Icon(icon, size: 18, color: color),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: AppTextStyles.caption().copyWith(
                color: AppColorPalette.softSlate,
              ),
            ),
            const SizedBox(height: 4),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: AppTextStyles.bodyLarge().copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  TextSpan(
                    text: unit,
                    style: AppTextStyles.bodySmall().copyWith(
                      color: AppColorPalette.softSlate,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build status badges row
  Widget _buildStatusBadgesRow(SoilMeasurement latest) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // pH Status
        StatusBadge.ph(
          status: latest.phStatus,
          compact: false,
        ),

        // Moisture Status
        StatusBadge.moisture(
          status: latest.moistureStatus,
          compact: false,
        ),

        // Overall Health
        StatusBadge.health(
          isHealthy: latest.isHealthy,
          compact: false,
        ),
      ],
    );
  }

  /// Build trend chart for 13 weeks
  Widget _buildTrendChartCard(
    BuildContext context,
    List<SoilMeasurement> measurements,
  ) {
    // Group measurements by week (last 13 weeks)
    final now = DateTime.now();
    final thirteenWeeksAgo = now.subtract(const Duration(days: 91)); // 13 weeks
    final recentMeasurements = measurements
        .where((m) => m.createdAt.isAfter(thirteenWeeksAgo))
        .toList();

    if (recentMeasurements.isEmpty) {
      return Center(
        child: Text(
          'Not enough data for trend chart',
          style: AppTextStyles.bodySmall().copyWith(
            color: AppColorPalette.softSlate,
          ),
        ),
      );
    }

    // Prepare data for charting (aggregate by week)
    final weeklyData = _aggregateDataByWeek(recentMeasurements, 13);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColorPalette.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColorPalette.charcoalGreen.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '13-Week Trend',
            style: AppTextStyles.bodyLarge().copyWith(
              fontWeight: FontWeight.bold,
              color: AppColorPalette.charcoalGreen,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 240,
            child: LineChart(
              _buildLineChartData(weeklyData),
            ),
          ),
          const SizedBox(height: 12),
          // Legend
          Wrap(
            spacing: 16,
            children: [
              _legendItem('Moisture %', AppColorPalette.fieldFreshStart),
              _legendItem('pH', AppColorPalette.warning),
              _legendItem('Temp °C', AppColorPalette.alertError),
            ],
          ),
        ],
      ),
    );
  }

  /// Aggregate measurements by week
  List<Map<String, dynamic>> _aggregateDataByWeek(
    List<SoilMeasurement> measurements,
    int weeks,
  ) {
    final now = DateTime.now();
    final weeklyMap = <int, List<SoilMeasurement>>{};

    // Group by week number
    for (final measurement in measurements) {
      final weeksDiff =
          ((now.millisecondsSinceEpoch - measurement.createdAt.millisecondsSinceEpoch) /
                  (1000 * 60 * 60 * 24 * 7))
              .ceil();
      if (weeksDiff >= 0 && weeksDiff <= weeks) {
        weeklyMap.putIfAbsent(weeksDiff, () => []).add(measurement);
      }
    }

    // Calculate averages for each week
    final data = <Map<String, dynamic>>[];
    for (int i = 0; i < weeks; i++) {
      final weekMeasurements = weeklyMap[i] ?? [];
      if (weekMeasurements.isNotEmpty) {
        final avgMoisture =
            weekMeasurements.map((m) => m.soilMoisture).reduce((a, b) => a + b) /
                weekMeasurements.length;
        final avgPh = weekMeasurements.map((m) => m.ph).reduce((a, b) => a + b) /
            weekMeasurements.length;
        final avgTemp =
            weekMeasurements.map((m) => m.temperature).reduce((a, b) => a + b) /
                weekMeasurements.length;

        data.add({
          'week': i,
          'moisture': avgMoisture,
          'ph': avgPh,
          'temperature': avgTemp,
        });
      }
    }

    return data.reversed.toList(); // Reverse to show oldest to newest
  }

  /// Build line chart data with 3 lines
  LineChartData _buildLineChartData(List<Map<String, dynamic>> weeklyData) {
    if (weeklyData.isEmpty) {
      return LineChartData(
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
      );
    }

    // Prepare spots for each metric
    final moistureSpots = _createSpots(weeklyData, 'moisture', 100);
    final phSpots = _createSpots(weeklyData, 'ph', 14);
    final tempSpots = _createSpots(weeklyData, 'temperature', 50);

    return LineChartData(
      minY: 0,
      maxY: 100,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (_) => FlLine(
          color: AppColorPalette.softSlate.withOpacity(0.1),
          strokeWidth: 1,
        ),
      ),
      borderData: FlBorderData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (v, _) => Text(
              v.toInt().toString(),
              style: AppTextStyles.caption().copyWith(
                color: AppColorPalette.softSlate,
              ),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 24,
            getTitlesWidget: (v, _) => Text(
              'W${v.toInt()}',
              style: AppTextStyles.caption().copyWith(
                color: AppColorPalette.softSlate,
                fontSize: 9,
              ),
            ),
          ),
        ),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      lineBarsData: [
        // Moisture line (green)
        LineChartBarData(
          spots: moistureSpots,
          isCurved: true,
          color: AppColorPalette.fieldFreshStart,
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: AppColorPalette.fieldFreshStart.withOpacity(0.1),
          ),
        ),
        // pH line (orange)
        LineChartBarData(
          spots: phSpots,
          isCurved: true,
          color: AppColorPalette.warning,
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
        // Temperature line (red)
        LineChartBarData(
          spots: tempSpots,
          isCurved: true,
          color: AppColorPalette.alertError,
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => AppColorPalette.charcoalGreen,
          tooltipPadding: const EdgeInsets.all(8),
          tooltipBorder: BorderSide(
            color: AppColorPalette.charcoalGreen.withOpacity(0.2),
          ),
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              String label = '';
              switch (spot.barIndex) {
                case 0:
                  label = 'Moist: ${spot.y.toStringAsFixed(0)}%';
                  break;
                case 1:
                  label = 'pH: ${spot.y.toStringAsFixed(1)}';
                  break;
                case 2:
                  label = 'Temp: ${spot.y.toStringAsFixed(0)}°C';
                  break;
              }
              return LineTooltipItem(
                label,
                TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  /// Create spots from weekly data for a specific metric
  List<FlSpot> _createSpots(
    List<Map<String, dynamic>> weeklyData,
    String metric,
    double maxValue,
  ) {
    return weeklyData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      final value = (data[metric] as num).toDouble();
      // Normalize to 0-100 scale
      final normalized = (value / maxValue) * 100;
      return FlSpot(index.toDouble(), normalized.clamp(0, 100));
    }).toList();
  }

  /// Build legend item
  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.caption().copyWith(
            color: AppColorPalette.charcoalGreen,
          ),
        ),
      ],
    );
  }
}
