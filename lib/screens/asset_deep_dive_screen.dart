import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/asset_item.dart';
import '../providers/asset_provider.dart';

class AssetDeepDiveScreen extends StatefulWidget {
  const AssetDeepDiveScreen({super.key, required this.asset});

  final AssetItem asset;

  @override
  State<AssetDeepDiveScreen> createState() => _AssetDeepDiveScreenState();
}

class _AssetDeepDiveScreenState extends State<AssetDeepDiveScreen> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _historyResult;
  Map<String, dynamic>? _diagnosticsResult;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final provider = context.read<AssetProvider>();
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        provider.fetchAssetHistory(widget.asset.id),
        provider.fetchAssetDiagnostics(widget.asset.id),
      ]);

      if (!mounted) return;
      setState(() {
        _historyResult = results[0];
        _diagnosticsResult = results[1];
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Unable to load deep-dive data for this asset.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = (_historyResult?['history'] as List?)
            ?.map((item) => Map<String, dynamic>.from(item as Map))
            .toList() ??
        [];
    final aggregates = Map<String, dynamic>.from(
      (_historyResult?['aggregates'] as Map?) ?? const {},
    );
    final diagnostics = Map<String, dynamic>.from(
      (_diagnosticsResult?['diagnostics'] as Map?) ?? const {},
    );
    final dynamicReport = (_diagnosticsResult?['dynamicReport']?.toString() ??
            diagnostics['technicalBulletin']?.toString()) ??
        'AI report unavailable.';

    return Scaffold(
      backgroundColor: const Color(0xFF08140E),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: const Color(0xFF08140E),
            title: Text(
              widget.asset.name,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.asset.imageUrl != null && widget.asset.imageUrl!.isNotEmpty)
                    Image.network(
                      widget.asset.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _assetFallback(),
                    )
                  else
                    _assetFallback(),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          const Color(0xFF08140E).withValues(alpha: 0.95),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isLoading) const Center(child: CircularProgressIndicator()),
                  if (_error != null) _errorCard(_error!),
                  if (!_isLoading && _error == null) ...[
                    _aiInsightCard(dynamicReport, diagnostics),
                    const SizedBox(height: 14),
                    _metricsCard(aggregates),
                    const SizedBox(height: 14),
                    _usageLineChart(history),
                    const SizedBox(height: 14),
                    _sectionTitle('History Timeline'),
                    const SizedBox(height: 10),
                    ..._historyTimeline(history),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _assetFallback() {
    return Container(
      color: const Color(0xFF123021),
      child: const Icon(Icons.precision_manufacturing_rounded, color: Color(0xFF9EE6B7), size: 72),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _aiInsightCard(String report, Map<String, dynamic> diagnostics) {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dynamic AI Report',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            report,
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip('Risk', '${diagnostics['riskPercentage'] ?? diagnostics['failureProbability'] ?? 'N/A'}%'),
              _chip('Critical', diagnostics['criticalComponent']?.toString() ?? 'N/A'),
              _chip('Pro Tip', diagnostics['maintenanceProTip']?.toString() ?? 'N/A'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricsCard(Map<String, dynamic> aggregates) {
    return _glassCard(
      child: Row(
        children: [
          Expanded(child: _metric('Lifetime Hours', '${aggregates['totalLifetimeHours'] ?? 0}')),
          const SizedBox(width: 10),
          Expanded(child: _metric('Avg Session', '${aggregates['averageSessionLength'] ?? 0} h')),
          const SizedBox(width: 10),
          Expanded(child: _metric('Sessions', '${aggregates['sessionCount'] ?? 0}')),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _usageLineChart(List<Map<String, dynamic>> history) {
    final completed = history.where((item) => item['endTime'] != null).toList().reversed.toList();
    final points = <FlSpot>[];
    for (var i = 0; i < completed.length; i++) {
      points.add(FlSpot(i.toDouble(), ((completed[i]['durationHours'] as num?)?.toDouble() ?? 0.0)));
    }

    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Usage vs Time',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 210,
            child: LineChart(
              LineChartData(
                minY: 0,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: Colors.white.withValues(alpha: 0.08), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '#${value.toInt() + 1}',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: points,
                    isCurved: true,
                    barWidth: 3,
                    color: const Color(0xFF9EE6B7),
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF9EE6B7).withValues(alpha: 0.26),
                          const Color(0xFF9EE6B7).withValues(alpha: 0.02),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _historyTimeline(List<Map<String, dynamic>> history) {
    if (history.isEmpty) {
      return [
        _glassCard(
          child: Text(
            'No usage sessions yet for this asset.',
            style: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.78)),
          ),
        ),
      ];
    }

    return history.map((entry) {
      final task = (entry['taskType']?.toString() ?? '').toLowerCase();
      final notes = (entry['notes']?.toString() ?? '').toLowerCase();
      final duration = (entry['durationHours'] as num?)?.toDouble() ?? 0;

      IconData icon = Icons.pause_circle_outline_rounded;
      Color color = const Color(0xFF8FA99A);
      if (task.contains('maintenance') || notes.contains('maintenance')) {
        icon = Icons.build_circle_outlined;
        color = const Color(0xFFE3A77B);
      } else if (duration > 0) {
        icon = Icons.play_circle_fill_rounded;
        color = const Color(0xFF61C06F);
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _glassCard(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry['farmerName'] ?? 'Farmer'} • ${duration.toStringAsFixed(2)} h',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry['notes']?.toString().isNotEmpty == true
                          ? entry['notes'].toString()
                          : 'No notes for this session.',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _chip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$label: $value',
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _errorCard(String message) {
    return _glassCard(
      child: Text(
        message,
        style: GoogleFonts.poppins(
          color: const Color(0xFFE3A77B),
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF102218).withValues(alpha: 0.72),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            borderRadius: BorderRadius.circular(22),
          ),
          child: child,
        ),
      ),
    );
  }
}
