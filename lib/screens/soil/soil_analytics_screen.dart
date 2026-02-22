import 'package:flutter/material.dart';
import '../../theme/color_palette.dart';
import '../../theme/text_styles.dart';
import '../../utils/responsive.dart';
import '../../services/soil_repository.dart';
import '../../services/soil_api_service.dart';
import '../../models/soil_measurement.dart';
import '../../models/ai_prediction.dart';
import '../../widgets/soil/ai_prediction_card.dart';
import '../../widgets/soil/chart_container.dart';


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
  bool _loadingPrediction = false;
  AiPrediction? _prediction;
  String? _predictionError;
  final SoilRepository _repository = SoilRepository();
  final SoilApiService _apiService = SoilApiService();

  @override
  void initState() {
    super.initState();
    _loadHistoricalData();
  }

  /// Load historical data for charts
  Future<void> _loadHistoricalData() async {
    setState(() => isLoading = true);

    try {
      // Fetch ALL measurements (use high limit to get all data)
      final response = await _repository.getMeasurements(
        page: 1,
        limit: 1000, // High limit to get all measurements
        sortBy: 'createdAt',
        order: 'ASC', // Oldest first for charts
      );
      
      if (!mounted) return;
      
      setState(() {
        historicalData = response.data;
        isLoading = false;
      });

      // Load AI prediction for the latest measurement
      if (historicalData.isNotEmpty) {
        _loadLatestPrediction();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        historicalData = [];
        isLoading = false;
      });
    }
  }

  /// Load AI prediction for the latest measurement
  Future<void> _loadLatestPrediction() async {
    if (historicalData.isEmpty) return;

    setState(() {
      _loadingPrediction = true;
      _predictionError = null;
    });

    try {
      // Get the latest measurement (last in the sorted list)
      final latestMeasurement = historicalData.last;
      final prediction = await _apiService.getPrediction(latestMeasurement.id);
      
      if (mounted) {
        setState(() {
          _prediction = prediction;
          _loadingPrediction = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _predictionError = e.toString();
          _loadingPrediction = false;
        });
      }
    }
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
            if (!isLoading && historicalData.isNotEmpty)
              Text(
                '${historicalData.length} measurements',
                style: AppTextStyles.caption(
                  color: AppColorPalette.softSlate,
                ),
              ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : historicalData.isEmpty
              ? _buildEmptyState()
              : historicalData.length < 3
                  ? _buildInsufficientDataState()
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
                    subtitle: _getDateRangeSubtitle(),
                    height: Responsive.chartHeight(context),
                    chart: _PhChart(data: historicalData),
                    legend: ChartLegend(
                      items: [
                        ChartLegendItem(
                          color: AppColorPalette.mistyBlue,
                          label: 'pH Level',
                        ),
                        ChartLegendItem(
                          color: AppColorPalette.success.withValues(alpha: 0.2),
                          label: 'Optimal Range (6-7.5)',
                        ),
                      ],
                    ),
                  ),

                  // Soil Moisture Evolution Chart
                  ChartContainer(
                    title: 'Soil Moisture Evolution',
                    subtitle: _getDateRangeSubtitle(),
                    height: Responsive.chartHeight(context),
                    chart: _MoistureChart(data: historicalData),
                    legend: ChartLegend(
                      items: [
                        ChartLegendItem(
                          color: AppColorPalette.info,
                          label: 'Moisture %',
                        ),
                        ChartLegendItem(
                          color: AppColorPalette.success.withValues(alpha: 0.2),
                          label: 'Optimal Range (30-80%)',
                        ),
                      ],
                    ),
                  ),

                  // Sunlight Evolution Chart
                  ChartContainer(
                    title: 'Sunlight Exposure',
                    subtitle: _getDateRangeSubtitle(),
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

  /// Build empty state when no measurements
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.show_chart,
              size: 80,
              color: AppColorPalette.softSlate.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Measurements Yet',
              style: AppTextStyles.h3(),
            ),
            const SizedBox(height: 8),
            Text(
              'Add soil measurements to see analytics and trends',
              style: AppTextStyles.bodyMedium(
                color: AppColorPalette.softSlate,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build insufficient data state when too few measurements
  Widget _buildInsufficientDataState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.data_usage,
              size: 80,
              color: AppColorPalette.info.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Insufficient Data',
              style: AppTextStyles.h3(),
            ),
            const SizedBox(height: 8),
            Text(
              'Add at least ${3 - historicalData.length} more measurement${3 - historicalData.length > 1 ? 's' : ''} to view trends',
              style: AppTextStyles.bodyMedium(
                color: AppColorPalette.softSlate,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Current measurements: ${historicalData.length}',
              style: AppTextStyles.caption(
                color: AppColorPalette.softSlate,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get date range subtitle for charts
  String _getDateRangeSubtitle() {
    if (historicalData.isEmpty) return '';
    if (historicalData.length == 1) return 'Single measurement';
    
    final oldest = historicalData.first.createdAt;
    final newest = historicalData.last.createdAt;
    final daysDiff = newest.difference(oldest).inDays;
    
    if (daysDiff == 0) return 'Same day';
    if (daysDiff == 1) return 'Last 2 days';
    if (daysDiff < 7) return 'Last $daysDiff days';
    if (daysDiff < 14) return 'Last week';
    if (daysDiff < 30) return 'Last ${(daysDiff / 7).round()} weeks';
    if (daysDiff < 60) return 'Last month';
    return 'Last ${(daysDiff / 30).round()} months';
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Loading state
          if (_loadingPrediction)
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: AppColorPalette.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      color: AppColorPalette.charcoalGreen,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading AI prediction...',
                      style: AppTextStyles.bodyMedium(
                        color: AppColorPalette.softSlate,
                      ),
                    ),
                  ],
                ),
              ),
            )
          // Error state
          else if (_predictionError != null)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColorPalette.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColorPalette.alertError,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'AI Service Unavailable',
                    style: AppTextStyles.h4(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Unable to load AI prediction. Make sure the AI service is running.',
                    style: AppTextStyles.caption(
                      color: AppColorPalette.softSlate,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadLatestPrediction,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColorPalette.charcoalGreen,
                    ),
                  ),
                ],
              ),
            )
          // Success state - show prediction card
          else if (_prediction != null)
            AiPredictionCard(
              prediction: _prediction!,
              onRefresh: _loadLatestPrediction,
            )
          // Initial/empty state
          else
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColorPalette.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.psychology,
                    size: 48,
                    color: AppColorPalette.charcoalGreen,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No AI Prediction Available',
                    style: AppTextStyles.h4(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add more measurements to get AI predictions',
                    style: AppTextStyles.caption(
                      color: AppColorPalette.softSlate,
                    ),
                    textAlign: TextAlign.center,
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
          color: color.withValues(alpha: 0.3),
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
    if (data.isEmpty) {
      return const Center(child: Text('No data'));
    }
    
    // Use fixed range for pH (standard soil pH range)
    return CustomPaint(
      size: Size.infinite,
      painter: _LineChartPainter(
        data: data.map((m) => m.ph).toList(),
        color: AppColorPalette.mistyBlue,
        minValue: 4.5,
        maxValue: 9.0,
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
    if (data.isEmpty) {
      return const Center(child: Text('No data'));
    }
    
    // Use 0-100% range for moisture (percentage)
    return CustomPaint(
      size: Size.infinite,
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
    // Calculate dynamic min/max from actual data
    final sunlightValues = data.map((m) => m.sunlight).toList();
    
    if (sunlightValues.isEmpty) {
      return const Center(child: Text('No data'));
    }
    
    double minSunlight = sunlightValues.reduce((a, b) => a < b ? a : b);
    double maxSunlight = sunlightValues.reduce((a, b) => a > b ? a : b);
    
    // Add padding to min/max for better visualization
    // If all values are the same, create a range around that value
    if (minSunlight == maxSunlight) {
      minSunlight = (minSunlight * 0.8).clamp(0, double.infinity);
      maxSunlight = minSunlight + (minSunlight > 0 ? minSunlight * 0.4 : 100);
    } else {
      final range = maxSunlight - minSunlight;
      minSunlight = (minSunlight - range * 0.1).clamp(0, double.infinity);
      maxSunlight = maxSunlight + range * 0.1;
    }
    
    return CustomPaint(
      size: Size.infinite,
      painter: _LineChartPainter(
        data: sunlightValues,
        color: AppColorPalette.warning,
        minValue: minSunlight,
        maxValue: maxSunlight,
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
    if (size.width <= 0 || size.height <= 0) return;

    // Add padding to avoid clipping at edges
    const padding = 10.0;
    final chartWidth = size.width - (2 * padding);
    final chartHeight = size.height - (2 * padding);

    // Draw optimal range background
    if (optimalMin != null && optimalMax != null) {
      final optimalPaint = Paint()
        ..color = AppColorPalette.success.withValues(alpha: 0.1)
        ..style = PaintingStyle.fill;

      final minY = chartHeight * (1 - (optimalMin! - minValue) / (maxValue - minValue)) + padding;
      final maxY = chartHeight * (1 - (optimalMax! - minValue) / (maxValue - minValue)) + padding;

      canvas.drawRect(
        Rect.fromLTRB(padding, maxY, size.width - padding, minY),
        optimalPaint,
      );
    }

    // Draw grid lines
    final gridPaint = Paint()
      ..color = AppColorPalette.softSlate.withValues(alpha: 0.2)
      ..strokeWidth = 1;

    for (int i = 0; i <= 4; i++) {
      final y = (chartHeight * i / 4) + padding;
      canvas.drawLine(
        Offset(padding, y),
        Offset(size.width - padding, y),
        gridPaint,
      );
    }

    // Draw line chart
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    
    // Calculate step - handle single data point case
    final stepX = data.length > 1 
        ? chartWidth / (data.length - 1)
        : chartWidth / 2; // Center single point

    for (int i = 0; i < data.length; i++) {
      final x = data.length > 1 
          ? (i * stepX) + padding
          : (chartWidth / 2) + padding; // Center single point
          
      final normalizedValue = (data[i] - minValue) / (maxValue - minValue);
      // Clamp normalized value between 0 and 1
      final clampedValue = normalizedValue.clamp(0.0, 1.0);
      final y = (chartHeight * (1 - clampedValue)) + padding;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      // Draw data points
      canvas.drawCircle(
        Offset(x, y),
        6,
        Paint()..color = color,
      );
      canvas.drawCircle(
        Offset(x, y),
        3,
        Paint()..color = AppColorPalette.white,
      );
    }

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
