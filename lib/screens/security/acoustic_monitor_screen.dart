import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../theme/color_palette.dart';
import '../../theme/text_styles.dart';
import '../../utils/constants.dart';

// ─────────────────────────────────────────────────────────────
//  Acoustic Monitor – Command Center Screen
// ─────────────────────────────────────────────────────────────

class AcousticMonitorScreen extends StatefulWidget {
  const AcousticMonitorScreen({super.key});

  @override
  State<AcousticMonitorScreen> createState() => _AcousticMonitorScreenState();
}

class _AcousticMonitorScreenState extends State<AcousticMonitorScreen>
    with SingleTickerProviderStateMixin {
  // ── SSE / polling state ───────────────────────────────────
  Timer? _pollTimer;
  double _db = 0;
  double _dominantFreq = 0;
  String _status = 'calm'; // calm | suspicious | alert
  String? _category;
  List<double> _waveform = List.filled(64, 0);
  List<Map<String, dynamic>> _alerts = [];
  bool _connected = false;

  // ── Animation ─────────────────────────────────────────────
  late AnimationController _pulseController;

  // ── Audio server config ───────────────────────────────────
  String get _audioHost => AppConfig.serverHost;
  int get _audioPort => 5051;
  String get _baseUrl => 'http://$_audioHost:$_audioPort';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _startPolling();
    _fetchAlerts();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  // ── Data fetching ─────────────────────────────────────────

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(milliseconds: 150), (_) async {
      try {
        final resp = await http
            .get(Uri.parse('$_baseUrl/audio_status'))
            .timeout(const Duration(seconds: 2));
        if (resp.statusCode == 200) {
          final data = json.decode(resp.body);
          if (!mounted) return;
          setState(() {
            _db = (data['db'] as num?)?.toDouble() ?? 0;
            _dominantFreq = (data['dominant_freq'] as num?)?.toDouble() ?? 0;
            _status = data['status'] ?? 'calm';
            _category = data['category'];
            _connected = true;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _connected = false);
      }

      // Also poll waveform
      try {
        final resp = await http
            .get(Uri.parse('$_baseUrl/audio_stream'))
            .timeout(const Duration(seconds: 2));
        if (resp.statusCode == 200) {
          // SSE returns "data: {...}\n\n" — grab the JSON
          final lines = resp.body.split('\n');
          for (final line in lines) {
            if (line.startsWith('data: ')) {
              final jsonStr = line.substring(6);
              final data = json.decode(jsonStr);
              if (data['waveform'] != null && mounted) {
                setState(() {
                  _waveform = (data['waveform'] as List)
                      .map((e) => (e as num).toDouble())
                      .toList();
                });
              }
              break;
            }
          }
        }
      } catch (_) {}
    });
  }

  Future<void> _fetchAlerts() async {
    try {
      final resp = await http
          .get(Uri.parse('$_baseUrl/audio_alerts'))
          .timeout(const Duration(seconds: 3));
      if (resp.statusCode == 200 && mounted) {
        setState(() {
          _alerts = List<Map<String, dynamic>>.from(json.decode(resp.body));
        });
      }
    } catch (_) {}
  }

  // ── Color helpers ─────────────────────────────────────────

  Color get _statusColor {
    switch (_status) {
      case 'alert':
        return AppColorPalette.alertError;
      case 'suspicious':
        return Colors.orange.shade600;
      default:
        return AppColorPalette.success;
    }
  }

  Color _alertColor(String status) {
    switch (status) {
      case 'alert':
        return AppColorPalette.alertError;
      case 'suspicious':
        return Colors.orange.shade600;
      default:
        return AppColorPalette.success;
    }
  }

  IconData _alertIcon(String? category) {
    if (category == null) return Icons.graphic_eq;
    if (category.contains('Engine')) return Icons.directions_car;
    if (category.contains('Glass') || category.contains('Impact')) {
      return Icons.broken_image;
    }
    return Icons.volume_up;
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'alert':
        return 'THREAT';
      case 'suspicious':
        return 'SUSPECT';
      default:
        return 'CLEAR';
    }
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorPalette.wheatWarmClay,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) => Icon(
                Icons.hearing,
                color: _statusColor.withValues(
                  alpha: 0.5 + _pulseController.value * 0.5,
                ),
                size: 22,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Acoustic Monitor',
              style: AppTextStyles.h3(color: AppColorPalette.charcoalGreen),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppColorPalette.charcoalGreen,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColorPalette.lightGrey),
        ),
        actions: [
          // Connection indicator
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _connected
                        ? AppColorPalette.success
                        : AppColorPalette.alertError,
                    boxShadow: [
                      BoxShadow(
                        color:
                            (_connected
                                    ? AppColorPalette.success
                                    : AppColorPalette.alertError)
                                .withValues(alpha: 0.6),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _connected ? 'LIVE' : 'OFFLINE',
                  style: AppTextStyles.overline(
                    color: _connected
                        ? AppColorPalette.success
                        : AppColorPalette.alertError,
                  ),
                ),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchAlerts),
        ],
      ),
      body: _connected ? _buildMonitorBody() : _buildOfflineBody(),
    );
  }

  // ── Offline state ─────────────────────────────────────────

  Widget _buildOfflineBody() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColorPalette.alertError.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.hearing_disabled,
                size: 56,
                color: AppColorPalette.alertError.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Acoustic Engine Offline',
              style: AppTextStyles.h3(color: AppColorPalette.charcoalGreen),
            ),
            const SizedBox(height: 12),
            Text(
              'Make sure the engine is running on your server',
              style: AppTextStyles.bodySmall(color: AppColorPalette.softSlate),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Listening on $_baseUrl',
              style: AppTextStyles.caption(color: AppColorPalette.mediumGrey),
            ),
          ],
        ),
      ),
    );
  }

  // ── Main monitor body ─────────────────────────────────────

  Widget _buildMonitorBody() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        // ── Status banner ──
        _buildStatusBanner(),
        const SizedBox(height: 16),

        // ── Waveform visualizer ──
        _buildWaveformCard(),
        const SizedBox(height: 16),

        // ── Gauges row ──
        Row(
          children: [
            Expanded(child: _buildDbGauge()),
            const SizedBox(width: 12),
            Expanded(child: _buildFreqGauge()),
          ],
        ),
        const SizedBox(height: 20),

        // ── Alert history header ──
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Row(
            children: [
              Icon(Icons.notifications_active, size: 18, color: AppColorPalette.softSlate),
              const SizedBox(width: 8),
              Text(
                'Alert History',
                style: AppTextStyles.h4(color: AppColorPalette.charcoalGreen),
              ),
              const Spacer(),
              Text(
                '${_alerts.length} events',
                style: AppTextStyles.caption(color: AppColorPalette.softSlate),
              ),
            ],
          ),
        ),

        // ── Alert list ──
        if (_alerts.isEmpty)
          _buildEmptyAlerts()
        else
          ..._alerts.take(20).map(_buildAlertTile),
      ],
    );
  }

  // ── Status Banner ─────────────────────────────────────────

  Widget _buildStatusBanner() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _statusColor.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (_, __) => Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _statusColor,
                boxShadow: _status != 'calm'
                    ? [
                        BoxShadow(
                          color: _statusColor.withValues(
                            alpha: _pulseController.value * 0.8,
                          ),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : [],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _statusLabel(_status),
                style: AppTextStyles.buttonSmall(color: _statusColor),
              ),
              if (_category != null)
                Text(
                  _category!,
                  style: AppTextStyles.caption(color: AppColorPalette.softSlate),
                ),
            ],
          ),
          const Spacer(),
          Text(
            '${_db.toStringAsFixed(1)} dB',
            style: AppTextStyles.h3(color: _statusColor),
          ),
        ],
      ),
    );
  }

  // ── Waveform Card ─────────────────────────────────────────

  Widget _buildWaveformCard() {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: CustomPaint(
          painter: _WaveformPainter(
            waveform: _waveform,
            color: _statusColor,
            progress: _pulseController.value,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }

  // ── dB Gauge ──────────────────────────────────────────────

  Widget _buildDbGauge() {
    final maxDb = 120.0;
    final fraction = (_db / maxDb).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: fraction,
                    strokeWidth: 8,
                    backgroundColor: AppColorPalette.lightGrey,
                    valueColor: AlwaysStoppedAnimation<Color>(_statusColor),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _db.toStringAsFixed(0),
                      style: AppTextStyles.displaySmall(color: AppColorPalette.charcoalGreen),
                    ),
                    Text(
                      'dB',
                      style: AppTextStyles.overline(color: AppColorPalette.softSlate),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Noise Level',
            style: AppTextStyles.caption(color: AppColorPalette.softSlate),
          ),
        ],
      ),
    );
  }

  // ── Frequency Gauge ───────────────────────────────────────

  Widget _buildFreqGauge() {
    String freqLabel;
    Color freqColor;
    if (_dominantFreq < 500) {
      freqLabel = 'LOW';
      freqColor = Colors.orange.shade700;
    } else if (_dominantFreq > 2000) {
      freqLabel = 'HIGH';
      freqColor = AppColorPalette.alertError;
    } else {
      freqLabel = 'MID';
      freqColor = AppColorPalette.success;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: (_dominantFreq / 5000).clamp(0.0, 1.0),
                    strokeWidth: 8,
                    backgroundColor: AppColorPalette.lightGrey,
                    valueColor: AlwaysStoppedAnimation<Color>(freqColor),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _dominantFreq > 1000
                          ? '${(_dominantFreq / 1000).toStringAsFixed(1)}k'
                          : _dominantFreq.toStringAsFixed(0),
                      style: AppTextStyles.displaySmall(color: AppColorPalette.charcoalGreen),
                    ),
                    Text(
                      'Hz · $freqLabel',
                      style: AppTextStyles.overline(color: freqColor),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Dominant Freq',
            style: AppTextStyles.caption(color: AppColorPalette.softSlate),
          ),
        ],
      ),
    );
  }

  // ── Empty alerts ──────────────────────────────────────────

  Widget _buildEmptyAlerts() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 40,
            color: AppColorPalette.success.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text('All Clear', style: AppTextStyles.h4(color: AppColorPalette.charcoalGreen)),
          const SizedBox(height: 4),
          Text(
            'No acoustic threats detected.',
            style: AppTextStyles.bodySmall(color: AppColorPalette.softSlate),
          ),
        ],
      ),
    );
  }

  // ── Alert Tile ────────────────────────────────────────────

  Widget _buildAlertTile(Map<String, dynamic> alert) {
    final status = alert['status'] ?? 'calm';
    final color = _alertColor(status);
    final category = alert['category'] ?? 'Unknown';
    final db = (alert['db'] as num?)?.toDouble() ?? 0;
    final freq = (alert['freq'] as num?)?.toDouble() ?? 0;
    final ts = alert['timestamp'] ?? '';

    String timeLabel = '';
    try {
      final dt = DateTime.parse(ts).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) {
        timeLabel = 'Just now';
      } else if (diff.inMinutes < 60) {
        timeLabel = '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        timeLabel = '${diff.inHours}h ago';
      } else {
        timeLabel = '${diff.inDays}d ago';
      }
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColorPalette.lightGrey),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_alertIcon(category), size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category, style: AppTextStyles.label(color: AppColorPalette.charcoalGreen)),
                const SizedBox(height: 2),
                Text(
                  '${db.toStringAsFixed(1)} dB · ${freq.toStringAsFixed(0)} Hz',
                  style: AppTextStyles.caption(color: AppColorPalette.softSlate),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: AppTextStyles.overline(color: color),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                timeLabel,
                style: AppTextStyles.caption(color: AppColorPalette.mediumGrey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Waveform CustomPainter
// ─────────────────────────────────────────────────────────────

class _WaveformPainter extends CustomPainter {
  final List<double> waveform;
  final Color color;
  final double progress;

  _WaveformPainter({
    required this.waveform,
    required this.color,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (waveform.isEmpty) return;

    final midY = size.height / 2;
    final barWidth = size.width / waveform.length;

    // Background grid lines
    final gridPaint = Paint()
      ..color = AppColorPalette.mediumGrey.withValues(alpha: 0.15)
      ..strokeWidth = 1;
    for (int i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Center line
    final centerPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), centerPaint);

    // Normalize waveform
    final maxVal = waveform.fold<double>(1, (m, v) => max(m, v.abs()));

    // Waveform bars
    for (int i = 0; i < waveform.length; i++) {
      final normalized = (waveform[i] / maxVal).clamp(-1.0, 1.0);
      final barHeight = normalized * (size.height * 0.4);

      final x = i * barWidth + barWidth / 2;

      // Glow effect
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.15 + 0.1 * progress)
        ..strokeWidth = barWidth * 0.6
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawLine(
        Offset(x, midY - barHeight),
        Offset(x, midY + barHeight),
        glowPaint,
      );

      // Solid bar
      final barPaint = Paint()
        ..color = color.withValues(alpha: 0.6 + 0.4 * (normalized.abs()))
        ..strokeWidth = barWidth * 0.4
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(x, midY - barHeight),
        Offset(x, midY + barHeight),
        barPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) => true;
}
