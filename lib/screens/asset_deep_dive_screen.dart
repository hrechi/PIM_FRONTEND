import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../models/asset_item.dart';
import '../providers/asset_provider.dart';
import '../services/api_service.dart';
import '../utils/asset_image_utils.dart';
import '../widgets/custom_button.dart';
import 'mechanic_chat_screen.dart';

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
  Map<String, dynamic>? _insightsResult;
  Map<String, dynamic>? _predictiveResult;
  late String _status;

  @override
  void initState() {
    super.initState();
    _status = widget.asset.status;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  ImageProvider? _assetImageProvider() {
    return resolveAssetImageProvider(
      widget.asset.imageUrl,
      mediaBaseUrl: ApiService.mediaBaseUrl,
    );
  }

  Color _statusColor() {
    switch (_status) {
      case 'IN_USE':
        return const Color(0xFFE3A77B);
      case 'MAINTENANCE':
        return const Color(0xFFE57373);
      default:
        return const Color(0xFF61C06F);
    }
  }

  String _statusLabel() {
    switch (_status) {
      case 'IN_USE':
        return 'In use';
      case 'MAINTENANCE':
        return 'Maintenance';
      default:
        return 'Available';
    }
  }

  Widget _detailChip(String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: (color ?? Colors.white).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          color: color ?? Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _detailTile(String label, String value, {IconData? icon}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white70, size: 18),
            const SizedBox(height: 10),
          ],
          Text(
            value,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _setStatus(String status) async {
    setState(() => _status = status);
    await context.read<AssetProvider>().updateAsset(
      assetId: widget.asset.id,
      status: status,
    );
  }

  void _showQrCode() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Asset QR Code',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: QrImageView(
                    data: widget.asset.serialNumber.isNotEmpty
                        ? widget.asset.serialNumber
                        : widget.asset.id,
                    version: QrVersions.auto,
                    size: 220,
                    backgroundColor: Colors.white,
                    eyeStyle: const QrEyeStyle(
                      eyeShape: QrEyeShape.square,
                      color: Colors.black,
                    ),
                    dataModuleStyle: const QrDataModuleStyle(
                      dataModuleShape: QrDataModuleShape.square,
                      color: Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  widget.asset.name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'Serial: ${widget.asset.serialNumber}',
                  style: GoogleFonts.poppins(fontSize: 12),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
        provider.fetchAssetInsights(widget.asset.id),
        provider.fetchPredictiveMaintenance(widget.asset.id),
      ]);

      if (!mounted) return;
      setState(() {
        _historyResult = results[0];
        _diagnosticsResult = results[1];
        _insightsResult = results[2];
        _predictiveResult = results[3];
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
    final history =
        (_historyResult?['history'] as List?)
            ?.map((item) => Map<String, dynamic>.from(item as Map))
            .toList() ??
        [];
    final aggregates = Map<String, dynamic>.from(
      (_historyResult?['aggregates'] as Map?) ?? const {},
    );
    final diagnostics = Map<String, dynamic>.from(
      (_diagnosticsResult?['diagnostics'] as Map?) ?? const {},
    );
    final dynamicReport =
        (_diagnosticsResult?['dynamicReport']?.toString() ??
            diagnostics['technicalBulletin']?.toString()) ??
        'AI report unavailable.';

    return Scaffold(
      backgroundColor: const Color(0xFF08140E),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 330,
            pinned: true,
            backgroundColor: const Color(0xFF08140E),
            surfaceTintColor: Colors.transparent,
            title: Text(
              widget.asset.name,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'asset-image-${widget.asset.id}',
                    child: _assetImageProvider() == null
                        ? _assetFallback()
                        : Image(
                            image: _assetImageProvider()!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _assetFallback(),
                          ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          const Color(0xFF08140E).withValues(alpha: 0.94),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 18,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _detailChip(widget.asset.brand),
                            _detailChip(widget.asset.category),
                            _detailChip(_statusLabel(), color: _statusColor()),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.asset.model != null &&
                                  widget.asset.model!.isNotEmpty
                              ? '${widget.asset.model}${widget.asset.modelYear != null ? ' • ${widget.asset.modelYear}' : ''}'
                              : 'Asset details',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.asset.serialNumber.isNotEmpty
                              ? 'Serial ${widget.asset.serialNumber}'
                              : 'Serial not set',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 24, bottom: 24),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  if (_error != null) _errorCard(_error!),
                  if (!_isLoading && _error == null) ...[
                    _glassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.asset.name,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.asset.brand,
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _detailChip(
                                'Status: ${_statusLabel()}',
                                color: _statusColor(),
                              ),
                              _detailChip('Category: ${widget.asset.category}'),
                              if (widget.asset.fieldName != null)
                                _detailChip('Field: ${widget.asset.fieldName}'),
                              if (widget.asset.assignedToName != null)
                                _detailChip(
                                  'Assigned: ${widget.asset.assignedToName}',
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _detailTile(
                                  'Model',
                                  widget.asset.model ?? 'Not set',
                                  icon: Icons.precision_manufacturing_rounded,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _detailTile(
                                  'Mileage',
                                  widget.asset.mileage != null
                                      ? '${widget.asset.mileage!.toStringAsFixed(0)} km'
                                      : 'Not set',
                                  icon: Icons.route_rounded,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _detailTile(
                                  'Operating hours',
                                  widget.asset.operatingHours != null
                                      ? '${widget.asset.operatingHours!.toStringAsFixed(0)} h'
                                      : 'Not set',
                                  icon: Icons.schedule_rounded,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _detailTile(
                                  'Last service',
                                  widget.asset.lastServiceDate != null
                                      ? DateFormat(
                                          'dd MMM yyyy',
                                        ).format(widget.asset.lastServiceDate!)
                                      : 'Not set',
                                  icon: Icons.handyman_rounded,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: CustomButton(
                                  text: 'QR Code',
                                  onPressed: _showQrCode,
                                  backgroundColor: const Color(0xFF2F8ED1),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: CustomButton(
                                  text: _status == 'IN_USE'
                                      ? 'Mark Available'
                                      : 'Mark In Use',
                                  onPressed: () => _setStatus(
                                    _status == 'IN_USE'
                                        ? 'AVAILABLE'
                                        : 'IN_USE',
                                  ),
                                  backgroundColor: _status == 'IN_USE'
                                      ? const Color(0xFF61C06F)
                                      : const Color(0xFFE3A77B),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: CustomButton(
                              text: '🔧 Ask about this machine',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MechanicChatScreen(
                                      assetId: widget.asset.id,
                                      assetBrand: widget.asset.brand,
                                      assetModel: widget.asset.model,
                                      assetCategory: widget.asset.category,
                                    ),
                                  ),
                                );
                              },
                              backgroundColor: const Color(0xFF2F8ED1),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _predictiveMaintenanceCard(_predictiveResult),
                    const SizedBox(height: 14),
                    _machineInsightsCard(_insightsResult),
                    const SizedBox(height: 14),
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF163024), Color(0xFF07120D)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.precision_manufacturing_rounded,
          color: Color(0xFF9EE6B7),
          size: 80,
        ),
      ),
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
              _chip(
                'Risk',
                '${diagnostics['riskPercentage'] ?? diagnostics['failureProbability'] ?? 'N/A'}%',
              ),
              _chip(
                'Critical',
                diagnostics['criticalComponent']?.toString() ?? 'N/A',
              ),
              _chip(
                'Pro Tip',
                diagnostics['maintenanceProTip']?.toString() ?? 'N/A',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _machineInsightsCard(Map<String, dynamic>? insights) {
    final riskLevel = (insights?['riskLevel']?.toString() ?? 'LOW')
        .toUpperCase();
    final warnings =
        (insights?['warnings'] as List?)
            ?.map((item) => item.toString())
            .where((item) => item.trim().isNotEmpty)
            .toList() ??
        const [];
    final recommendations =
        (insights?['recommendations'] as List?)
            ?.map((item) => item.toString())
            .where((item) => item.trim().isNotEmpty)
            .toList() ??
        const [];

    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Machine Insights',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _detailChip(
            'Risk level: $riskLevel',
            color: _riskLevelColor(riskLevel),
          ),
          const SizedBox(height: 12),
          if (warnings.isEmpty && recommendations.isEmpty)
            Text(
              'No machine insights yet. The asset has not shown enough usage patterns to flag risk.',
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.78),
                fontSize: 13,
                height: 1.45,
              ),
            )
          else ...[
            if (warnings.isNotEmpty) ...[
              Text(
                'Warnings',
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ...warnings.map(
                (warning) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _bulletRow(
                    warning,
                    icon: Icons.warning_amber_rounded,
                    color: const Color(0xFFE3A77B),
                  ),
                ),
              ),
            ],
            if (recommendations.isNotEmpty) ...[
              if (warnings.isNotEmpty) const SizedBox(height: 10),
              Text(
                'Recommendations',
                style: GoogleFonts.poppins(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ...recommendations.map(
                (recommendation) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _bulletRow(
                    recommendation,
                    icon: Icons.lightbulb_outline_rounded,
                    color: const Color(0xFF9EE6B7),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _predictiveMaintenanceCard(Map<String, dynamic>? predictive) {
    final riskLevel = (predictive?['riskLevel']?.toString() ?? 'LOW')
        .toUpperCase();
    final canUse = predictive?['canUse'] != false;
    final predictions =
        (predictive?['predictions'] as List?)
            ?.map((item) => item.toString())
            .where((item) => item.trim().isNotEmpty)
            .toList() ??
        const [];
    final actions =
        (predictive?['recommendedActions'] as List?)
            ?.map((item) => item.toString())
            .where((item) => item.trim().isNotEmpty)
            .toList() ??
        const [];

    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Predicted Maintenance',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _detailChip(
            'Risk level: $riskLevel',
            color: _riskLevelColor(riskLevel),
          ),
          const SizedBox(height: 12),
          if (!canUse)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFC83E4D).withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFC83E4D).withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                '⚠ Machine requires maintenance before use',
                style: GoogleFonts.poppins(
                  color: const Color(0xFFFFC7CF),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (predictions.isNotEmpty) ...[
            if (!canUse) const SizedBox(height: 12),
            Text(
              'Predictions',
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ...predictions.map(
              (prediction) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _bulletRow(
                  prediction,
                  icon: Icons.trending_up_rounded,
                  color: const Color(0xFFE3A77B),
                ),
              ),
            ),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Recommended actions',
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ...actions.map(
              (action) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _bulletRow(
                  action,
                  icon: Icons.build_circle_outlined,
                  color: const Color(0xFF9EE6B7),
                ),
              ),
            ),
          ],
          if (predictions.isEmpty && actions.isEmpty)
            Text(
              'No maintenance predictions at the moment.',
              style: GoogleFonts.poppins(
                color: Colors.white.withValues(alpha: 0.78),
                fontSize: 13,
                height: 1.45,
              ),
            ),
        ],
      ),
    );
  }

  Widget _bulletRow(
    String text, {
    required IconData icon,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 12,
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }

  Color _riskLevelColor(String riskLevel) {
    switch (riskLevel.toUpperCase()) {
      case 'HIGH':
        return const Color(0xFFC83E4D);
      case 'MEDIUM':
        return const Color(0xFFE3A77B);
      default:
        return const Color(0xFF61C06F);
    }
  }

  Widget _metricsCard(Map<String, dynamic> aggregates) {
    return _glassCard(
      child: Row(
        children: [
          Expanded(
            child: _metric(
              'Lifetime Hours',
              '${aggregates['totalLifetimeHours'] ?? 0}',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _metric(
              'Avg Session',
              '${aggregates['averageSessionLength'] ?? 0} h',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _metric('Sessions', '${aggregates['sessionCount'] ?? 0}'),
          ),
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
    final completed = history
        .where((item) => item['endTime'] != null)
        .toList()
        .reversed
        .toList();
    final points = <FlSpot>[];
    for (var i = 0; i < completed.length; i++) {
      points.add(
        FlSpot(
          i.toDouble(),
          ((completed[i]['durationHours'] as num?)?.toDouble() ?? 0.0),
        ),
      );
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
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.white.withValues(alpha: 0.08),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
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
            style: GoogleFonts.poppins(
              color: Colors.white.withValues(alpha: 0.78),
            ),
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
        style: GoogleFonts.poppins(color: Colors.white, fontSize: 11),
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
