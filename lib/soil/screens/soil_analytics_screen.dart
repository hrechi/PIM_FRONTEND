import 'package:flutter/material.dart';
import 'dart:math';
import '../../../theme/color_palette.dart';
import '../../../theme/text_styles.dart';
import '../../../utils/responsive.dart';
import '../models/soil_measurement.dart';
import '../widgets/chart_container.dart';

/// Screen displaying soil analytics and AI predictions
/// Route: /soil/analytics
class SoilAnalyticsScreen extends StatefulWidget {
  const SoilAnalyticsScreen({super.key});

  @override
  State<SoilAnalyticsScreen> createState() => _SoilAnalyticsScreenState();
}

class _SoilAnalyticsScreenState extends State<SoilAnalyticsScreen> {
  List<SoilMeasurement> historicalData = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadHistoricalData();
  }

  /// Load historical data for charts
  Future<void> _loadHistoricalData() async {
    setState(() => isLoading = true);

    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 500));

    setState(() {
      historicalData = SoilMeasurement.getHistoricalData();
      isLoading = false;
    });
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
              'Soil Analytics',
              style: AppTextStyles.h3(),
            ),
            Text(
              '13-week analysis',
              style: AppTextStyles.caption(
                color: AppColorPalette.softSlate,
              ),
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Responsive.constrainedContent(
              context: context,
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  vertical: Responsive.verticalPadding(context),
                ),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary Cards
                  _buildSummaryCards(),

                  const SizedBox(height: 24),

                  // pH Evolution Chart
                  ChartContainer(
                    title: 'pH Level Evolution',
                    subtitle: 'Last 13 weeks',
                    height: Responsive.chartHeight(context),
                    chart: _PhChart(data: historicalData),
                    legend: ChartLegend(
                      items: [
                        ChartLegendItem(
                          color: AppColorPalette.mistyBlue,
                          label: 'pH Level',
                        ),
                        ChartLegendItem(
                          color: AppColorPalette.success.withOpacity(0.2),
                          label: 'Optimal Range (6-7.5)',
                        ),
                      ],
                    ),
                  ),

                  // Soil Moisture Evolution Chart
                  ChartContainer(
                    title: 'Soil Moisture Evolution',
                    subtitle: 'Last 13 weeks',
                    height: Responsive.chartHeight(context),
                    chart: _MoistureChart(data: historicalData),
                    legend: ChartLegend(
                      items: [
                        ChartLegendItem(
                          color: AppColorPalette.info,
                          label: 'Moisture %',
                        ),
                        ChartLegendItem(
                          color: AppColorPalette.success.withOpacity(0.2),
                          label: 'Optimal Range (30-80%)',
                        ),
                      ],
                    ),
                  ),

                  // Sunlight Evolution Chart
                  ChartContainer(
                    title: 'Sunlight Exposure',
                    subtitle: 'Last 13 weeks',
                    height: Responsive.chartHeight(context),
                    chart: _SunlightChart(data: historicalData),
                    legend: ChartLegend(
                      items: [
                        ChartLegendItem(
                          color: AppColorPalette.warning,
                          label: 'Sunlight (lux)',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // AI Prediction Section
                  _buildAIPredictionSection(),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
    );
  }

  /// Build summary cards
  Widget _buildSummaryCards() {
    if (historicalData.isEmpty) return const SizedBox();

    final latestMeasurement = historicalData.last;
    final avgPh = historicalData.map((m) => m.ph).reduce((a, b) => a + b) /
        historicalData.length;
    final avgMoisture = historicalData
            .map((m) => m.soilMoisture)
            .reduce((a, b) => a + b) /
        historicalData.length;

    final cards = [
      _SummaryCard(
        icon: Icons.science,
        label: 'Avg pH',
        value: avgPh.toStringAsFixed(1),
        color: AppColorPalette.mistyBlue,
      ),
      _SummaryCard(
        icon: Icons.water_drop,
        label: 'Avg Moisture',
        value: '${avgMoisture.toStringAsFixed(0)}%',
        color: AppColorPalette.info,
      ),
      _SummaryCard(
        icon: Icons.thermostat,
        label: 'Latest Temp',
        value: '${latestMeasurement.temperature.toStringAsFixed(0)}°C',
        color: AppColorPalette.alertError,
      ),
    ];

    // Display cards in a row on all screen sizes
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Responsive.horizontalPadding(context)),
      child: Row(
        children: [
          Expanded(child: cards[0]),
          SizedBox(width: Responsive.spacing(context, mobile: 8, tablet: 12, desktop: 16)),
          Expanded(child: cards[1]),
          SizedBox(width: Responsive.spacing(context, mobile: 8, tablet: 12, desktop: 16)),
          Expanded(child: cards[2]),
        ],
      ),
    );
  }

  /// Build AI prediction section
  Widget _buildAIPredictionSection() {
    // Mock AI prediction
    final random = Random();
    final wiltingRisk = 15 + random.nextDouble() * 60; // 15-75%
    final riskLevel = wiltingRisk < 30
        ? 'Low'
        : wiltingRisk < 60
            ? 'Medium'
            : 'High';
    final riskColor = wiltingRisk < 30
        ? AppColorPalette.success
        : wiltingRisk < 60
            ? AppColorPalette.warning
            : AppColorPalette.alertError;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColorPalette.sageTint.withOpacity(0.1),
            AppColorPalette.mistyBlue.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColorPalette.mistyBlue.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColorPalette.mistyBlue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.psychology,
                  size: 28,
                  color: AppColorPalette.mistyBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Prediction',
                      style: AppTextStyles.h3(),
                    ),
                    Text(
                      'Machine learning analysis',
                      style: AppTextStyles.caption(
                        color: AppColorPalette.softSlate,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColorPalette.mistyBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'BETA',
                  style: AppTextStyles.caption(
                    color: AppColorPalette.white,
                  ).copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Prediction Title
          Text(
            'Wilting Point Prediction',
            style: AppTextStyles.h4(),
          ),
          const SizedBox(height: 12),

          // Risk Percentage
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${wiltingRisk.toStringAsFixed(0)}%',
                style: AppTextStyles.displayMedium(
                  color: riskColor,
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: riskColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: riskColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        riskLevel == 'Low'
                            ? Icons.check_circle
                            : riskLevel == 'Medium'
                                ? Icons.warning
                                : Icons.error,
                        size: 16,
                        color: riskColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$riskLevel Risk',
                        style: AppTextStyles.bodySmall(
                          color: riskColor,
                        ).copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Progress bar
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: AppColorPalette.lightGrey,
              borderRadius: BorderRadius.circular(6),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: wiltingRisk / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: riskColor,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            'Based on current soil moisture trends, temperature patterns, and historical data, the AI model predicts a $riskLevel risk of reaching the wilting point in the next 7 days.',
            style: AppTextStyles.bodySmall(
              color: AppColorPalette.softSlate,
            ),
          ),

          const SizedBox(height: 16),

          // Recommendation
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColorPalette.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColorPalette.info.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 20,
                  color: AppColorPalette.info,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    riskLevel == 'Low'
                        ? 'Soil conditions are optimal. Continue monitoring.'
                        : riskLevel == 'Medium'
                            ? 'Consider irrigation within 2-3 days.'
                            : 'Immediate irrigation recommended.',
                    style: AppTextStyles.bodySmall(
                      color: AppColorPalette.charcoalGreen,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Summary card widget
class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({
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
        color: AppColorPalette.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 24,
            color: color,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.h4(
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption(
              color: AppColorPalette.softSlate,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Placeholder pH chart widget
class _PhChart extends StatelessWidget {
  final List<SoilMeasurement> data;

  const _PhChart({required this.data});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LineChartPainter(
        data: data.map((m) => m.ph).toList(),
        color: AppColorPalette.mistyBlue,
        minValue: 5.0,
        maxValue: 8.5,
        optimalMin: 6.0,
        optimalMax: 7.5,
      ),
    );
  }
}

/// Placeholder moisture chart widget
class _MoistureChart extends StatelessWidget {
  final List<SoilMeasurement> data;

  const _MoistureChart({required this.data});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LineChartPainter(
        data: data.map((m) => m.soilMoisture).toList(),
        color: AppColorPalette.info,
        minValue: 0,
        maxValue: 100,
        optimalMin: 30,
        optimalMax: 80,
      ),
    );
  }
}

/// Placeholder sunlight chart widget
class _SunlightChart extends StatelessWidget {
  final List<SoilMeasurement> data;

  const _SunlightChart({required this.data});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LineChartPainter(
        data: data.map((m) => m.sunlight).toList(),
        color: AppColorPalette.warning,
        minValue: 2000,
        maxValue: 8000,
      ),
    );
  }
}

/// Simple line chart painter
class _LineChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final double minValue;
  final double maxValue;
  final double? optimalMin;
  final double? optimalMax;

  _LineChartPainter({
    required this.data,
    required this.color,
    required this.minValue,
    required this.maxValue,
    this.optimalMin,
    this.optimalMax,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    // Draw optimal range background
    if (optimalMin != null && optimalMax != null) {
      final optimalPaint = Paint()
        ..color = AppColorPalette.success.withOpacity(0.1)
        ..style = PaintingStyle.fill;

      final minY = size.height * (1 - (optimalMin! - minValue) / (maxValue - minValue));
      final maxY = size.height * (1 - (optimalMax! - minValue) / (maxValue - minValue));

      canvas.drawRect(
        Rect.fromLTRB(0, maxY, size.width, minY),
        optimalPaint,
      );
    }

    // Draw grid lines
    final gridPaint = Paint()
      ..color = AppColorPalette.softSlate.withOpacity(0.2)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    // Draw line chart
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    final stepX = size.width / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final normalizedValue = (data[i] - minValue) / (maxValue - minValue);
      final y = size.height * (1 - normalizedValue);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      // Draw data points
      canvas.drawCircle(
        Offset(x, y),
        4,
        Paint()..color = color,
      );
      canvas.drawCircle(
        Offset(x, y),
        2,
        Paint()..color = AppColorPalette.white,
      );
    }

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
