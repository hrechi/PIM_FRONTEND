import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';

import '../../services/robot_api_service.dart';
import '../../theme/color_palette.dart';
import '../../widgets/camera_view.dart';

/// Result returned by [RobotCaptureScreen] via `Navigator.pop`.
///
/// [file] is either a JPEG screenshot or a `.zip` of recorded JPEG frames
/// (which the backend assembles into an MP4). [isVideo] tells the form
/// which it is so it can label/preview correctly.
class RobotCaptureResult {
  const RobotCaptureResult({required this.file, required this.isVideo});
  final File file;
  final bool isVideo;
}

/// Live preview of the robot camera with two actions:
///   * a Screenshot button that grabs one JPEG frame, and
///   * a Record toggle that streams JPEG frames into a `.zip` ready to be
///     turned into an MP4 by the backend.
///
/// On success the screen pops with a [RobotCaptureResult]. On cancel /
/// back-navigation it returns `null`.
class RobotCaptureScreen extends StatefulWidget {
  const RobotCaptureScreen({
    super.key,
    required this.robot,
    this.maxRecordingDuration = const Duration(seconds: 60),
  });

  final RobotDescriptor robot;
  final Duration maxRecordingDuration;

  @override
  State<RobotCaptureScreen> createState() => _RobotCaptureScreenState();
}

class _RobotCaptureScreenState extends State<RobotCaptureScreen> {
  final GlobalKey _previewKey = GlobalKey();

  bool _isCapturing = false;
  bool _isRecording = false;
  Timer? _recordTimer;
  Timer? _hudTimer;
  final Stopwatch _watch = Stopwatch();
  final List<Uint8List> _frames = <Uint8List>[];
  final List<int> _timestampsMs = <int>[];
  int _recordedFrames = 0;
  int _elapsedMs = 0;

  static const Duration _frameInterval = Duration(milliseconds: 200); // 5 fps

  @override
  void dispose() {
    _recordTimer?.cancel();
    _hudTimer?.cancel();
    super.dispose();
  }

  /// Grab the current pixels of the live preview widget as a PNG.
  /// Works because the `Mjpeg` widget is rendered into a normal
  /// RepaintBoundary, so we just rasterize it.
  Future<Uint8List> _grabPng({double pixelRatio = 1.0}) async {
    final ctx = _previewKey.currentContext;
    if (ctx == null) {
      throw StateError('Preview not mounted');
    }
    final boundary =
        ctx.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      throw StateError('Preview boundary missing');
    }
    // Wait one frame if Flutter is still painting the first image.
    if (boundary.debugNeedsPaint) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
    try {
      final byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw StateError('Failed to encode preview frame as PNG');
      }
      return byteData.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  Future<void> _takeScreenshot() async {
    if (_isCapturing || _isRecording) return;
    setState(() => _isCapturing = true);
    try {
      final png = await _grabPng(pixelRatio: 2.0);
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}${Platform.pathSeparator}'
        'robot_${widget.robot.id}_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(png, flush: true);
      if (!mounted) return;
      Navigator.of(context).pop(
        RobotCaptureResult(file: file, isVideo: false),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Screenshot failed: $e'),
          backgroundColor: AppColorPalette.alertError,
        ),
      );
      setState(() => _isCapturing = false);
    }
  }

  void _startRecording() {
    if (_isCapturing || _isRecording) return;
    _frames.clear();
    _timestampsMs.clear();
    _watch
      ..reset()
      ..start();
    setState(() {
      _isRecording = true;
      _recordedFrames = 0;
      _elapsedMs = 0;
    });
    _hudTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted) return;
      setState(() => _elapsedMs = _watch.elapsedMilliseconds);
    });
    _recordTimer = Timer.periodic(_frameInterval, (_) async {
      if (!_isRecording) return;
      // Hard stop on max duration.
      if (_watch.elapsedMilliseconds >=
          widget.maxRecordingDuration.inMilliseconds) {
        await _stopRecording(autoFinalize: true);
        return;
      }
      try {
        final png = await _grabPng();
        if (!_isRecording) return;
        _frames.add(png);
        _timestampsMs.add(_watch.elapsedMilliseconds);
        if (mounted) {
          setState(() => _recordedFrames = _frames.length);
        }
      } catch (_) {
        // Skip transient capture errors; the next tick will retry.
      }
    });
  }

  Future<void> _stopRecording({bool autoFinalize = false}) async {
    if (!_isRecording) return;
    _recordTimer?.cancel();
    _hudTimer?.cancel();
    _watch.stop();
    setState(() => _isCapturing = true);
    try {
      if (_frames.isEmpty) {
        throw StateError('No frames were captured from the preview.');
      }
      final file = await _buildZip();
      if (!mounted) return;
      Navigator.of(context).pop(
        RobotCaptureResult(file: file, isVideo: true),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            autoFinalize
                ? 'Recording ended: $e'
                : 'Failed to finalize recording: $e',
          ),
          backgroundColor: AppColorPalette.alertError,
        ),
      );
      setState(() {
        _isRecording = false;
        _isCapturing = false;
      });
    }
  }

  Future<File> _buildZip() async {
    final archive = Archive();
    for (var i = 0; i < _frames.length; i++) {
      final name = 'frame_${i.toString().padLeft(5, '0')}.png';
      archive.addFile(
        ArchiveFile(name, _frames[i].length, _frames[i]),
      );
    }
    final manifest = <String, Object>{
      'robotId': widget.robot.id,
      'frameCount': _frames.length,
      'durationMs': _timestampsMs.isNotEmpty ? _timestampsMs.last : 0,
      'timestampsMs': _timestampsMs,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'frameExt': 'png',
    };
    final manifestBytes =
        Uint8List.fromList(utf8.encode(jsonEncode(manifest)));
    archive.addFile(
      ArchiveFile('manifest.json', manifestBytes.length, manifestBytes),
    );
    final zipped = ZipEncoder().encode(archive);
    if (zipped == null) {
      throw StateError('Failed to encode zip');
    }
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}${Platform.pathSeparator}'
      'robot_${widget.robot.id}_${DateTime.now().millisecondsSinceEpoch}.zip',
    );
    await file.writeAsBytes(zipped, flush: true);
    return file;
  }

  String _formatElapsed(int ms) {
    final s = (ms ~/ 1000);
    final mm = (s ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    final cs = ((ms % 1000) ~/ 100).toString();
    return '$mm:$ss.$cs';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text('Robot — ${widget.robot.name}'),
      ),
      body: Stack(
        children: [
          // Live MJPEG preview wrapped in a RepaintBoundary so we can
          // rasterize the displayed frame for screenshots / recording.
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black,
              child: Center(
                child: RepaintBoundary(
                  key: _previewKey,
                  child: CameraView(
                    robotIp: widget.robot.ip,
                    videoPort: widget.robot.videoPort,
                    videoTopic: widget.robot.videoTopic,
                  ),
                ),
              ),
            ),
          ),
          // Recording HUD.
          if (_isRecording)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _RecDot(),
                        const SizedBox(width: 8),
                        Text(
                          'REC ${_formatElapsed(_elapsedMs)}'
                          ' • $_recordedFrames frames',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          // Bottom action bar.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ActionButton(
                      icon: Icons.photo_camera,
                      label: 'Screenshot',
                      enabled: !_isCapturing && !_isRecording,
                      color: AppColorPalette.robotTechStart,
                      onPressed: _takeScreenshot,
                    ),
                    _ActionButton(
                      icon: _isRecording ? Icons.stop : Icons.fiber_manual_record,
                      label: _isRecording ? 'Stop' : 'Record',
                      enabled: !_isCapturing,
                      color: _isRecording
                          ? AppColorPalette.alertError
                          : AppColorPalette.success,
                      onPressed: _isRecording
                          ? () => _stopRecording()
                          : _startRecording,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isCapturing && !_isRecording)
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.black54,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}

class _RecDot extends StatefulWidget {
  const _RecDot();
  @override
  State<_RecDot> createState() => _RecDotState();
}

class _RecDotState extends State<_RecDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: Container(
        width: 12,
        height: 12,
        decoration: const BoxDecoration(
          color: Colors.redAccent,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.enabled,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
