import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../services/robot_service.dart';
import '../../theme/color_palette.dart';
import '../../theme/text_styles.dart';

/// Polar lidar visualisation. Robot sits at the centre, beams are plotted as
/// dots whose colour encodes proximity. The forward-cone safety zone is
/// shaded green when clear, red when an obstacle is inside the safety
/// distance.
class LidarRadarPanel extends StatefulWidget {
  const LidarRadarPanel({
    super.key,
    required this.scanStream,
    required this.lastScan,
    this.maxRange = 6.0,
    this.safetyConeRad = math.pi / 6,
    this.safetyDistance = 0.30,
  });

  final Stream<RobotLaserScan> scanStream;
  final RobotLaserScan? lastScan;
  final double maxRange; // metres shown by the outermost ring
  final double safetyConeRad;
  final double safetyDistance;

  @override
  State<LidarRadarPanel> createState() => _LidarRadarPanelState();
}

class _LidarRadarPanelState extends State<LidarRadarPanel> {
  StreamSubscription<RobotLaserScan>? _sub;
  RobotLaserScan? _scan;

  @override
  void initState() {
    super.initState();
    _scan = widget.lastScan;
    _sub = widget.scanStream.listen((s) {
      if (!mounted) return;
      setState(() => _scan = s);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scan = _scan;
    final closest = scan?.minRangeInCone(widget.safetyConeRad);
    final tripped = closest != null && closest < widget.safetyDistance;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Lidar Radar',
                  style: AppTextStyles.h4(color: AppColorPalette.charcoalGreen)),
              const SizedBox(width: 8),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scan == null
                      ? AppColorPalette.mediumGrey
                      : (tripped
                          ? AppColorPalette.alertError
                          : AppColorPalette.success),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                scan == null
                    ? 'Waiting for /scan'
                    : (tripped
                        ? 'Obstacle ${(closest! * 100).round()} cm'
                        : 'Clear'),
                style: AppTextStyles.caption(
                  color: scan == null
                      ? AppColorPalette.softSlate
                      : (tripped
                          ? AppColorPalette.alertError
                          : AppColorPalette.success),
                ),
              ),
              const Spacer(),
              if (scan != null)
                Text('${scan.beamCount} beams',
                    style: AppTextStyles.caption(
                        color: AppColorPalette.softSlate)),
            ],
          ),
          const SizedBox(height: 10),
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                color: AppColorPalette.charcoalGreen,
                child: CustomPaint(
                  painter: _RadarPainter(
                    scan: scan,
                    maxRange: widget.maxRange,
                    safetyConeRad: widget.safetyConeRad,
                    safetyDistance: widget.safetyDistance,
                    tripped: tripped,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({
    required this.scan,
    required this.maxRange,
    required this.safetyConeRad,
    required this.safetyDistance,
    required this.tripped,
  });

  final RobotLaserScan? scan;
  final double maxRange;
  final double safetyConeRad;
  final double safetyDistance;
  final bool tripped;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 4;
    final pxPerMeter = radius / maxRange;

    // Range rings.
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.18);
    for (var i = 1; i <= 4; i++) {
      canvas.drawCircle(centre, radius * i / 4, ringPaint);
    }
    // Cross-hairs.
    canvas.drawLine(Offset(centre.dx, centre.dy - radius),
        Offset(centre.dx, centre.dy + radius), ringPaint);
    canvas.drawLine(Offset(centre.dx - radius, centre.dy),
        Offset(centre.dx + radius, centre.dy), ringPaint);

    // Forward cone shading. The robot's "forward" is +X (angle 0). On screen
    // we draw it pointing UP, so apply a -pi/2 rotation.
    final conePath = Path()
      ..moveTo(centre.dx, centre.dy)
      ..arcTo(
        Rect.fromCircle(center: centre, radius: radius),
        -math.pi / 2 - safetyConeRad,
        safetyConeRad * 2,
        false,
      )
      ..close();
    final conePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = (tripped
              ? AppColorPalette.alertError
              : AppColorPalette.success)
          .withValues(alpha: 0.18);
    canvas.drawPath(conePath, conePaint);

    // Safety distance arc.
    final safetyPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = (tripped
              ? AppColorPalette.alertError
              : AppColorPalette.success)
          .withValues(alpha: 0.55);
    final safetyR = (safetyDistance * pxPerMeter).clamp(2.0, radius);
    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: safetyR),
      -math.pi / 2 - safetyConeRad,
      safetyConeRad * 2,
      false,
      safetyPaint,
    );

    // Beam dots.
    final s = scan;
    if (s != null) {
      final dotPaint = Paint()..style = PaintingStyle.fill;
      for (var i = 0; i < s.ranges.length; i++) {
        final r = s.ranges[i];
        if (!r.isFinite || r < s.rangeMin || r > s.rangeMax) continue;
        final clipped = math.min(r, maxRange);
        final angle = s.angleMin + i * s.angleIncrement;
        // Robot frame: x=forward, y=left (REP-103). Map to screen so forward
        // points UP and left is to the LEFT.
        final screenAngle = angle - math.pi / 2;
        final px = centre.dx + clipped * pxPerMeter * math.cos(screenAngle);
        final py = centre.dy + clipped * pxPerMeter * math.sin(screenAngle);
        // Colour: green near safety distance threshold, yellow mid, white far.
        final t = (clipped / maxRange).clamp(0.0, 1.0);
        Color c;
        if (clipped < safetyDistance) {
          c = AppColorPalette.alertError;
        } else if (t < 0.33) {
          c = AppColorPalette.warning;
        } else {
          c = Colors.white.withValues(alpha: 0.85);
        }
        dotPaint.color = c;
        canvas.drawCircle(Offset(px, py), 1.6, dotPaint);
      }
    }

    // Robot triangle (pointing up).
    final robotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColorPalette.fieldFreshStart;
    final tri = Path()
      ..moveTo(centre.dx, centre.dy - 8)
      ..lineTo(centre.dx - 6, centre.dy + 6)
      ..lineTo(centre.dx + 6, centre.dy + 6)
      ..close();
    canvas.drawPath(tri, robotPaint);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter old) =>
      old.scan != scan || old.tripped != tripped;
}
