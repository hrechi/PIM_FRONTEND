import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../services/lidar_map_builder.dart';
import '../../services/robot_service.dart';
import '../../theme/color_palette.dart';
import '../../theme/text_styles.dart';

/// Renders the live occupancy grid produced by [LidarMapBuilder]. The widget
/// owns the builder and continuously feeds it from the robot's scan + odom
/// streams while mounted.
class LidarMapPanel extends StatefulWidget {
  const LidarMapPanel({
    super.key,
    required this.scanStream,
    required this.telemetryStream,
    this.builder,
    this.height = 320,
    this.onSnapshot,
  });

  final Stream<RobotLaserScan> scanStream;
  final Stream<RobotTelemetry> telemetryStream;

  /// Optional shared builder. If null, this widget creates its own (cleared
  /// on dispose).
  final LidarMapBuilder? builder;
  final double height;

  /// Called when the user taps "Save". Receives a freshly-rendered PNG and
  /// the raw int8 grid snapshot.
  final Future<void> Function(LidarMapBuilder builder)? onSnapshot;

  @override
  State<LidarMapPanel> createState() => _LidarMapPanelState();
}

class _LidarMapPanelState extends State<LidarMapPanel> {
  late LidarMapBuilder _builder;
  StreamSubscription<RobotLaserScan>? _scanSub;
  StreamSubscription<RobotTelemetry>? _teleSub;
  Timer? _repaintTimer;
  ui.Image? _image;
  int _renderedAt = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _builder = widget.builder ?? LidarMapBuilder();
    _teleSub = widget.telemetryStream.listen(_builder.setPoseFromTelemetry);
    _scanSub = widget.scanStream.listen(_builder.integrateScan);
    _repaintTimer = Timer.periodic(const Duration(milliseconds: 750), (_) {
      if (_builder.updateCount == _renderedAt) return;
      _renderedAt = _builder.updateCount;
      _renderImage();
    });
  }

  @override
  void dispose() {
    _scanSub?.cancel();
    _teleSub?.cancel();
    _repaintTimer?.cancel();
    _image?.dispose();
    super.dispose();
  }

  Future<void> _renderImage() async {
    final pixels = _builder.toGreyscalePixels();
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels,
      _builder.cols,
      _builder.rows,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    final img = await completer.future;
    if (!mounted) {
      img.dispose();
      return;
    }
    setState(() {
      _image?.dispose();
      _image = img;
    });
  }

  Future<void> _handleSave() async {
    final cb = widget.onSnapshot;
    if (cb == null) return;
    setState(() => _saving = true);
    try {
      await cb(_builder);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _handleClear() {
    _builder.reset();
    setState(() {
      _renderedAt = 0;
      _image?.dispose();
      _image = null;
    });
  }

  @override
  Widget build(BuildContext context) {
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
              Text('Live Map',
                  style: AppTextStyles.h4(color: AppColorPalette.charcoalGreen)),
              const SizedBox(width: 8),
              Text(
                '${_builder.updateCount} scans',
                style:
                    AppTextStyles.caption(color: AppColorPalette.softSlate),
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Reset map',
                onPressed: _handleClear,
                icon: const Icon(Icons.refresh_rounded),
              ),
              if (widget.onSnapshot != null)
                IconButton(
                  tooltip: 'Save snapshot',
                  onPressed: _saving ? null : _handleSave,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (widget.height.isInfinite)
            Expanded(child: _buildMapArea())
          else
            SizedBox(height: widget.height, child: _buildMapArea()),
        ],
      ),
    );
  }

  Widget _buildMapArea() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        color: AppColorPalette.charcoalGreen,
        child: _image == null
            ? Center(
                child: Text(
                  'Drive around to build a map',
                  style: AppTextStyles.bodySmall(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              )
            : InteractiveViewer(
                minScale: 0.5,
                maxScale: 6,
                child: SizedBox.expand(
                  child: CustomPaint(
                    painter: _MapPainter(
                      image: _image!,
                      poseCellX: _builder.cols ~/ 2 +
                          (_builder.poseX / _builder.resolutionMeters)
                              .round(),
                      poseCellY: _builder.rows ~/ 2 -
                          (_builder.poseY / _builder.resolutionMeters)
                              .round(),
                      yaw: _builder.poseYaw,
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter({
    required this.image,
    required this.poseCellX,
    required this.poseCellY,
    required this.yaw,
  });

  final ui.Image image;
  final int poseCellX;
  final int poseCellY;
  final double yaw;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    final src = Rect.fromLTWH(
        0, 0, image.width.toDouble(), image.height.toDouble());
    // Fit-contain.
    final scale = math.min(
      size.width / image.width,
      size.height / image.height,
    );
    final dw = image.width * scale;
    final dh = image.height * scale;
    final dst = Rect.fromLTWH(
        (size.width - dw) / 2, (size.height - dh) / 2, dw, dh);
    canvas.drawImageRect(image, src, dst, Paint());

    // Robot marker.
    final px = dst.left + poseCellX * scale;
    final py = dst.top + poseCellY * scale;
    canvas.save();
    canvas.translate(px, py);
    canvas.rotate(-yaw); // screen y-axis flipped
    final p = Paint()..color = AppColorPalette.fieldFreshStart;
    final tri = Path()
      ..moveTo(0, -8)
      ..lineTo(-6, 6)
      ..lineTo(6, 6)
      ..close();
    canvas.drawPath(tri, p);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) =>
      old.image != image ||
      old.poseCellX != poseCellX ||
      old.poseCellY != poseCellY ||
      old.yaw != yaw;
}
