import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../models/animal.dart';
import '../../services/animal_health_service.dart';
import '../../utils/constants.dart';

class WeightTrackingScreen extends StatefulWidget {
  final Animal animal;
  const WeightTrackingScreen({super.key, required this.animal});

  @override
  State<WeightTrackingScreen> createState() => _WeightTrackingScreenState();
}

class _WeightTrackingScreenState extends State<WeightTrackingScreen> {
  static const _kGreen = Color(0xFF309448);
  static const _kOrange = Color(0xFFE65100);
  static const _kBg = Color(0xFFF8FAFC);
  static const _kDark = Color(0xFF0F172A);
  static const _kMid = Color(0xFF475569);

  bool _isLoading = true;
  String? _error;
  WeightHistory? _history;
  int _selectedDays = 90;

  final _dateFormat = DateFormat('dd/MM');
  final _fullDateFormat = DateFormat('dd MMM yyyy');
  final _nf = NumberFormat('#,##0.0');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final h = await WeightService.getHistory(
        widget.animal.id,
        days: _selectedDays,
      );
      setState(() => _history = h);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showAddDialog() async {
    final controller = TextEditingController();
    final byController = TextEditingController();
    DateTime selectedDate = DateTime.now();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add Weight Record',
              style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Weight (kg)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Symbols.scale),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: byController,
                decoration: InputDecoration(
                  labelText: 'Measured by (optional)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  prefixIcon: const Icon(Symbols.person),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (d != null) setS(() => selectedDate = d);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Symbols.calendar_today,
                          size: 20, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(
                        _fullDateFormat.format(selectedDate),
                        style: const TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    final raw = controller.text.trim();
    final kg = double.tryParse(raw.replaceAll(',', '.'));
    if (kg == null || kg <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid weight')),
        );
      }
      return;
    }

    try {
      await WeightService.addRecord(
        widget.animal.id,
        weightKg: kg,
        measuredBy:
            byController.text.trim().isEmpty ? null : byController.text.trim(),
        // Utilise midi (12:00) pour éviter les problèmes de timezone UTC
        measuredDate: DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          12, 0, 0,
        ),
      );
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Weight record added'),
              backgroundColor: _kGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteRecord(String recordId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Record'),
        content: const Text('Remove this weight measurement?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await WeightService.deleteRecord(recordId);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: _kDark),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weight Tracking',
              style: const TextStyle(
                  color: _kDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 17),
            ),
            Text(
              widget.animal.name,
              style: const TextStyle(color: _kMid, fontSize: 13),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Symbols.add_circle, color: _kGreen),
            tooltip: 'Add measurement',
            onPressed: _showAddDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_history!.weightLossAlert != null)
                          _buildAlert(_history!.weightLossAlert!),
                        const SizedBox(height: 12),
                        _buildStatsRow(),
                        const SizedBox(height: 16),
                        _buildPeriodSelector(),
                        const SizedBox(height: 16),
                        _buildChart(),
                        const SizedBox(height: 24),
                        _buildRecordsList(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Symbols.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Symbols.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(backgroundColor: _kGreen,
                  foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlert(WeightLossAlert alert) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kOrange.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Symbols.warning, color: _kOrange, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              alert.message,
              style: const TextStyle(
                  color: _kOrange, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final s = _history!.stats;
    final trend = s.trendKgPerWeek;
    final trendColor = trend == null
        ? _kMid
        : trend > 0
            ? _kGreen
            : Colors.red;
    final trendIcon = trend == null
        ? Symbols.trending_flat
        : trend > 0
            ? Symbols.trending_up
            : Symbols.trending_down;

    return Row(
      children: [
        _statCard('Current', '${_nf.format(s.latestKg ?? widget.animal.weight ?? 0)} kg',
            Symbols.scale, _kGreen),
        const SizedBox(width: 10),
        _statCard('Min', s.minKg != null ? '${_nf.format(s.minKg!)} kg' : '--',
            Symbols.arrow_downward, Colors.blue),
        const SizedBox(width: 10),
        _statCard('Max', s.maxKg != null ? '${_nf.format(s.maxKg!)} kg' : '--',
            Symbols.arrow_upward, Colors.purple),
        const SizedBox(width: 10),
        _statCard(
          'Trend',
          trend != null
              ? '${trend > 0 ? '+' : ''}${_nf.format(trend)} kg/w'
              : '--',
          trendIcon,
          trendColor,
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
                textAlign: TextAlign.center),
            Text(label,
                style: const TextStyle(color: _kMid, fontSize: 10),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    const periods = [30, 60, 90, 180, 365];
    const labels = ['30d', '60d', '90d', '6m', '1y'];
    return Row(
      children: List.generate(periods.length, (i) {
        final selected = _selectedDays == periods[i];
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () {
              if (!selected) {
                setState(() => _selectedDays = periods[i]);
                _load();
              }
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: selected ? _kGreen : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: selected ? _kGreen : Colors.grey.shade300),
                boxShadow: selected
                    ? [
                        BoxShadow(
                            color: _kGreen.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2))
                      ]
                    : [],
              ),
              child: Text(
                labels[i],
                style: TextStyle(
                  color: selected ? Colors.white : _kMid,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildChart() {
    final records = _history!.records;
    if (records.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Symbols.show_chart, size: 40, color: Color(0xFFCBD5E1)),
              SizedBox(height: 8),
              Text('No data for this period',
                  style: TextStyle(color: Color(0xFF94A3B8))),
            ],
          ),
        ),
      );
    }

    final weights = records.map((r) => r.weightKg).toList();
    final minW = weights.reduce((a, b) => a < b ? a : b);
    final maxW = weights.reduce((a, b) => a > b ? a : b);
    final range = (maxW - minW).clamp(1.0, double.infinity);

    return Container(
      height: 200,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Weight Evolution',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: _kDark)),
          const SizedBox(height: 8),
          Expanded(
            child: CustomPaint(
              painter: _WeightChartPainter(
                records: records,
                minW: minW,
                maxW: maxW,
                range: range,
                lineColor: _kGreen,
                dateFormat: _dateFormat,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordsList() {
    final records = List.of(_history!.records.reversed);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Measurements',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: _kDark)),
            Text('${records.length} records',
                style: const TextStyle(color: _kMid, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 10),
        if (records.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('No measurements yet. Tap + to add one.',
                  style: TextStyle(color: Color(0xFF94A3B8))),
            ),
          )
        else
          ...records.asMap().entries.map((entry) {
            final i = entry.key;
            final r = entry.value;
            final prev = i < records.length - 1 ? records[i + 1] : null;
            final diff =
                prev != null ? r.weightKg - prev.weightKg : null;
            return _recordTile(r, diff);
          }),
      ],
    );
  }

  Widget _recordTile(WeightRecord r, double? diff) {
    Color diffColor = _kMid;
    String diffText = '';
    IconData diffIcon = Symbols.trending_flat;

    if (diff != null) {
      diffColor = diff > 0 ? _kGreen : diff < 0 ? Colors.red : _kMid;
      diffIcon = diff > 0
          ? Symbols.trending_up
          : diff < 0
              ? Symbols.trending_down
              : Symbols.trending_flat;
      diffText =
          '${diff > 0 ? '+' : ''}${_nf.format(diff)} kg';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 1))
        ],
      ),
      child: Row(
        children: [
          // ── Icône ──
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _kGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Symbols.scale, color: _kGreen, size: 20),
          ),
          const SizedBox(width: 12),
          // ── Texte (flexible) ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_nf.format(r.weightKg)} kg',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: _kDark),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _fullDateFormat.format(r.date) +
                      (r.measuredBy != null ? ' · ${r.measuredBy}' : ''),
                  style: const TextStyle(color: _kMid, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
          // ── Diff + delete (taille fixe) ──
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (diff != null) ...[
                const SizedBox(width: 6),
                Icon(diffIcon, color: diffColor, size: 14),
                const SizedBox(width: 2),
                Text(
                  diffText,
                  style: TextStyle(
                      color: diffColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ],
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => _deleteRecord(r.id),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Symbols.delete_outline,
                      color: Colors.red, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Custom chart painter ──────────────────────────────────────────────────────

class _WeightChartPainter extends CustomPainter {
  final List<WeightRecord> records;
  final double minW;
  final double maxW;
  final double range;
  final Color lineColor;
  final DateFormat dateFormat;

  _WeightChartPainter({
    required this.records,
    required this.minW,
    required this.maxW,
    required this.range,
    required this.lineColor,
    required this.dateFormat,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (records.isEmpty) return;

    final chartH = size.height - 20; // leave room for date labels
    final chartW = size.width;

    // Grid lines
    final gridPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = chartH * (1 - i / 4);
      canvas.drawLine(Offset(0, y), Offset(chartW, y), gridPaint);
    }

    // Compute points
    final points = <Offset>[];
    for (int i = 0; i < records.length; i++) {
      final x = records.length == 1
          ? chartW / 2
          : chartW * i / (records.length - 1);
      final y = chartH * (1 - (records[i].weightKg - minW) / range);
      points.add(Offset(x, y));
    }

    // Fill area under curve
    final fillPath = Path()..moveTo(points.first.dx, chartH);
    for (final p in points) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(points.last.dx, chartH);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [lineColor.withOpacity(0.25), lineColor.withOpacity(0.02)],
      ).createShader(Rect.fromLTWH(0, 0, chartW, chartH));
    canvas.drawPath(fillPath, fillPaint);

    // Line
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Dots
    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    final dotBorder = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (final p in points) {
      canvas.drawCircle(p, 5, dotBorder);
      canvas.drawCircle(p, 3.5, dotPaint);
    }

    // Date labels (show max 5 evenly spaced)
    final labelPaint = TextPainter(textDirection: ui.TextDirection.ltr);
    final step = (records.length / 5).ceil().clamp(1, records.length);
    for (int i = 0; i < records.length; i += step) {
      final label = dateFormat.format(records[i].date);
      labelPaint.text = TextSpan(
        text: label,
        style: TextStyle(
            color: Colors.grey.shade500, fontSize: 9),
      );
      labelPaint.layout();
      final x = (records.length == 1
              ? chartW / 2
              : chartW * i / (records.length - 1)) -
          labelPaint.width / 2;
      labelPaint.paint(canvas, Offset(x, chartH + 4));
    }
  }

  @override
  bool shouldRepaint(_WeightChartPainter old) =>
      old.records != records || old.minW != minW || old.maxW != maxW;
}
