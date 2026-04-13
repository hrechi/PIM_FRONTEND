import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/harvest_analytics_model.dart';
import '../services/analytics_service.dart';

class HarvestAnalyticsScreen extends StatefulWidget {
  const HarvestAnalyticsScreen({super.key});

  @override
  State<HarvestAnalyticsScreen> createState() => _HarvestAnalyticsScreenState();
}

class _HarvestAnalyticsScreenState extends State<HarvestAnalyticsScreen> {
  // ── State ───────────────────────────────────────────────
  bool _loading = true;
  String? _error;

  YieldSummary? _summary;
  int _touchedBarIndex = -1;

  // ── Colour palette ──────────────────────────────────────
  static const Color _green1 = Color(0xFF2E7D32);
  static const Color _green2 = Color(0xFF66BB6A);
  static const Color _green3 = Color(0xFFA5D6A7);
  static const Color _amber = Color(0xFFFFA726);
  static const Color _bg = Color(0xFFF1F8E9);
  static const Color _cardBg = Colors.white;
  static const Color _textDark = Color(0xFF1B5E20);
  static const Color _textLight = Color(0xFF757575);

  // ── Lifecycle ────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final summary = await AnalyticsService.getYieldSummary();
      if (mounted) {
        setState(() {
          _summary = summary;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  // ── Build ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: _green1),
            )
          : _error != null
              ? _buildError()
              : _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: _green1,
      foregroundColor: Colors.white,
      title: Text(
        'Harvest Analytics',
        style: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Refresh',
          onPressed: _loadData,
        ),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              'Failed to load analytics',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              style: GoogleFonts.inter(color: _textLight, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: _green1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    final s = _summary!;
    return RefreshIndicator(
      color: _green1,
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        children: [
          // ── Summary Cards ────────────────────────────────
          _sectionTitle('📊 Farm Overview'),
          const SizedBox(height: 12),
          _buildSummaryRow(s),
          const SizedBox(height: 8),
          _buildBestParcelCard(s),

          const SizedBox(height: 28),

          // ── Line Chart ────────────────────────────────────
          _sectionTitle('📈 Yield Trend (Last 12 Months)'),
          const SizedBox(height: 12),
          _buildLineChartCard(s.recentTrend),

          const SizedBox(height: 28),

          // ── Bar Chart ─────────────────────────────────────
          if (s.recentTrend.isNotEmpty) ...[
            _sectionTitle('📦 Monthly Harvest Comparison'),
            const SizedBox(height: 12),
            _buildBarChartCard(s.recentTrend),
          ],

          const SizedBox(height: 28),

          // ── Stats Row ─────────────────────────────────────
          _sectionTitle('🌾 Quick Stats'),
          const SizedBox(height: 12),
          _buildStatsRow(s),
        ],
      ),
    );
  }

  // ── Section Title ────────────────────────────────────────
  Widget _sectionTitle(String text) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: _textDark,
          letterSpacing: 0.3,
        ),
      );

  // ── Summary Cards Row ────────────────────────────────────
  Widget _buildSummaryRow(YieldSummary s) {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            icon: Icons.agriculture_rounded,
            label: 'Total Yield',
            value: '${s.totalYield.toStringAsFixed(1)} t',
            color: _green1,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryCard(
            icon: Icons.trending_up_rounded,
            label: 'Avg Yield/ha',
            value: '${s.avgYieldPerHectare.toStringAsFixed(2)} t/ha',
            color: _green2,
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 12, color: _textLight),
          ),
        ],
      ),
    );
  }

  // ── Best Parcel Card ─────────────────────────────────────
  Widget _buildBestParcelCard(YieldSummary s) {
    if (s.bestParcel == null) {
      return _emptyStateCard('No harvest data recorded yet.');
    }
    final bp = s.bestParcel!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF388E3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _green1.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.emoji_events_rounded,
                color: Colors.amber, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Best Performing Parcel',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  bp.location,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${bp.totalYield.toStringAsFixed(1)} tonnes total',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.white70),
        ],
      ),
    );
  }

  // ── Line Chart ───────────────────────────────────────────
  Widget _buildLineChartCard(List<MonthlyTrend> trend) {
    if (trend.isEmpty) {
      return _emptyStateCard('No trend data available yet.');
    }

    final maxY = trend
        .map((t) => t.totalYield)
        .reduce((a, b) => a > b ? a : b);
    final spots = trend.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.totalYield);
    }).toList();

    return _chartCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY * 1.25,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.grey.shade200,
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
                        v.toStringAsFixed(0),
                        style: GoogleFonts.inter(
                            fontSize: 10, color: _textLight),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      interval: 1,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= trend.length) {
                          return const SizedBox.shrink();
                        }
                        // Show short month label e.g. "Jan"
                        final parts = trend[idx].month.split('-');
                        final monthNum =
                            parts.length == 2 ? int.tryParse(parts[1]) : null;
                        final labels = [
                          '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                        ];
                        final label = monthNum != null &&
                                monthNum >= 1 &&
                                monthNum <= 12
                            ? labels[monthNum]
                            : parts.last;
                        return Text(
                          label,
                          style: GoogleFonts.inter(
                              fontSize: 9, color: _textLight),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: _green1,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (_, __, ___, ____) =>
                          FlDotCirclePainter(
                        radius: 4,
                        color: _green1,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          _green1.withValues(alpha: 0.25),
                          _green1.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => _green1,
                    getTooltipItems: (spots) => spots
                        .map((s) => LineTooltipItem(
                              '${s.y.toStringAsFixed(1)} t',
                              GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 3,
                decoration: BoxDecoration(
                  color: _green1,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Total Yield (tonnes)',
                style: GoogleFonts.inter(fontSize: 11, color: _textLight),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Bar Chart ────────────────────────────────────────────
  Widget _buildBarChartCard(List<MonthlyTrend> trend) {
    if (trend.isEmpty) return const SizedBox.shrink();

    final maxY = trend
        .map((t) => t.totalYield)
        .reduce((a, b) => a > b ? a : b);

    final barGroups = trend.asMap().entries.map((e) {
      final isTouched = e.key == _touchedBarIndex;
      return BarChartGroupData(
        x: e.key,
        barRods: [
          BarChartRodData(
            toY: e.value.totalYield,
            color: isTouched ? _amber : _green2,
            width: isTouched ? 18 : 14,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(6),
            ),
          ),
        ],
      );
    }).toList();

    return _chartCard(
      child: SizedBox(
        height: 210,
        child: BarChart(
          BarChartData(
            maxY: maxY * 1.3,
            barTouchData: BarTouchData(
              touchCallback: (_, response) {
                setState(() {
                  _touchedBarIndex =
                      response?.spot?.touchedBarGroupIndex ?? -1;
                });
              },
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => _green1,
                getTooltipItem: (group, _, rod, __) {
                  final month = trend[group.x.toInt()].month;
                  return BarTooltipItem(
                    '$month\n${rod.toY.toStringAsFixed(1)} t',
                    GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (v, _) => Text(
                    v.toStringAsFixed(0),
                    style:
                        GoogleFonts.inter(fontSize: 10, color: _textLight),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  getTitlesWidget: (v, _) {
                    final idx = v.toInt();
                    if (idx < 0 || idx >= trend.length) {
                      return const SizedBox.shrink();
                    }
                    final parts = trend[idx].month.split('-');
                    final monthNum =
                        parts.length == 2 ? int.tryParse(parts[1]) : null;
                    final labels = [
                      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                    ];
                    final label = monthNum != null &&
                            monthNum >= 1 &&
                            monthNum <= 12
                        ? labels[monthNum]
                        : parts.last;
                    return Text(
                      label,
                      style: GoogleFonts.inter(
                          fontSize: 9, color: _textLight),
                    );
                  },
                ),
              ),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (_) => FlLine(
                color: Colors.grey.shade200,
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: barGroups,
          ),
        ),
      ),
    );
  }

  // ── Stats Row ────────────────────────────────────────────
  Widget _buildStatsRow(YieldSummary s) {
    return Row(
      children: [
        Expanded(
          child: _statTile(
            label: 'Total Harvests',
            value: '${s.totalHarvests}',
            icon: Icons.check_circle_outline_rounded,
            color: _green1,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _statTile(
            label: 'Parcels Tracked',
            value: '${s.parcelCount}',
            icon: Icons.grid_view_rounded,
            color: _amber,
          ),
        ),
      ],
    );
  }

  Widget _statTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _textDark,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.inter(
                    fontSize: 11, color: _textLight),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────
  Widget _chartCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _emptyStateCard(String message) {
    return _chartCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.bar_chart_rounded,
                  size: 48, color: _green3),
              const SizedBox(height: 12),
              Text(
                message,
                style: GoogleFonts.inter(
                  color: _textLight,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
