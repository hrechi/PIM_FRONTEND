import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../services/robot_api_service.dart';
import '../services/robot_service.dart';
import '../services/robot_voice_controller.dart';
import '../services/lidar_map_builder.dart';
import '../theme/color_palette.dart';
import '../theme/text_styles.dart';
import '../widgets/camera_view.dart';
import '../widgets/drive_button.dart';
import '../widgets/robot/lidar_map_panel.dart';
import '../widgets/robot/lidar_radar_panel.dart';
import 'lidar_field_mapping_screen.dart';

class ControlRoomScreen extends StatefulWidget {
  const ControlRoomScreen({super.key});

  @override
  State<ControlRoomScreen> createState() => _ControlRoomScreenState();
}

class _ControlRoomScreenState extends State<ControlRoomScreen> {
  static const double _joystickRadius = 54;
  static const double _maxSpeed = 3.2;
  static const double _floatingPreviewThreshold = 220;
  // Twist limits — kept conservative so an over-eager finger can't slam the
  // JetBot into a wall. Tune per-robot if needed.
  static const double _maxLinearMs = 0.35;
  static const double _maxAngularRad = 1.5;
  static const Duration _joystickPublishPeriod = Duration(milliseconds: 50);

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _robotViewAnchorKey = GlobalKey();
  final GlobalKey _scrollViewportKey = GlobalKey();

  bool _showFloatingPreview = false;
  bool _previewDockingDisabled = false;

  // ── Robot wiring ────────────────────────────────────────────
  final RobotApiService _robotApi = RobotApiService();
  RobotService? _robot;
  RobotDescriptor? _activeRobot;
  StreamSubscription<RobotConnectionState>? _robotStateSub;
  StreamSubscription<RobotTelemetry>? _telemetrySub;
  StreamSubscription<RobotSafetyEvent>? _safetySub;
  Timer? _joyTicker;
  DateTime _lastJoyAuditAt = DateTime.fromMillisecondsSinceEpoch(0);
  String? _robotError;
  bool _loadingRobots = true;
  bool _exploring = false;
  bool _savingMap = false;

  bool _isConnected = false;
  // -1 means "unknown" — we'll render an em-dash until /voltage publishes.
  double _batteryLevel = -1;
  int _signalStrength = 0;
  double _speed = 0;
  double _heading = 0;
  String _direction = 'Idle';
  Offset _joystickOffset = Offset.zero;
  String _lastDirectionLog = 'Idle';

  final List<_ControlEvent> _events = <_ControlEvent>[
    _ControlEvent(
      message: 'Control Room preview initialized',
      color: AppColorPalette.info,
      timestamp: DateTime.now(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    _bootstrapRobot();
  }

  /// Pulls the robot registry from NestJS, connects to the first robot's
  /// rosbridge, and wires the connection-state stream to UI flags.
  Future<void> _bootstrapRobot() async {
    try {
      final robots = await _robotApi.listRobots();
      if (!mounted) return;
      if (robots.isEmpty) {
        setState(() {
          _loadingRobots = false;
          _robotError = 'No robots registered for this account.';
        });
        return;
      }
      final robot = robots.first;
      final svc = RobotService(
        robotIp: robot.ip,
        rosbridgePort: robot.rosbridgePort,
      );
      _robotStateSub = svc.connectionState.listen((state) {
        if (!mounted) return;
        final connected = state == RobotConnectionState.connected;
        setState(() {
          _isConnected = connected;
          if (!connected) {
            _speed = 0;
            _signalStrength = 0;
            _direction = 'Disconnected';
            _joystickOffset = Offset.zero;
          } else {
            _direction = 'Idle';
          }
        });
        if (!connected) {
          _joyTicker?.cancel();
          _joyTicker = null;
        }
        _appendEvent(
          connected
              ? 'Robot link connected (${robot.name})'
              : 'Robot link ${state.name}',
          connected ? AppColorPalette.success : AppColorPalette.warning,
        );
      });
      _telemetrySub = svc.telemetryStream.listen((t) {
        if (!mounted) return;
        setState(() {
          _batteryLevel = t.batteryPercent ?? _batteryLevel;
          _signalStrength = t.signalPercent;
          // Only let odom drive the speed gauge when the joystick is centred —
          // otherwise the operator sees command intent, not robot reality, on
          // the gauge. This keeps it responsive while still showing real m/s
          // when idle.
          if (_joystickOffset.distance < 4) {
            _speed = t.linearSpeed.abs();
            _heading = t.headingDeg;
          }
        });
      });
      _safetySub = svc.safetyStream.listen((evt) {
        if (!mounted) return;
        if (evt.tripped) {
          final cm = ((evt.distanceMeters ?? 0) * 100).round();
          _appendEvent(
            'Auto-stop: obstacle ${cm}cm',
            AppColorPalette.alertError,
          );
        } else {
          _appendEvent('Safety latch cleared', AppColorPalette.success);
        }
      });
      await svc.connect();
      if (!mounted) {
        await svc.dispose();
        return;
      }
      setState(() {
        _activeRobot = robot;
        _robot = svc;
        _loadingRobots = false;
        _robotError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingRobots = false;
        _robotError = 'Failed to load robots: $e';
      });
    }
  }

  @override
  void dispose() {
    _joyTicker?.cancel();
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _robotStateSub?.cancel();
    _telemetrySub?.cancel();
    _safetySub?.cancel();
    // Fire-and-forget; we can't await in dispose, but RobotService.dispose()
    // is internally idempotent and sends a final stop().
    _robot?.dispose();
    _robotApi.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;

    final shouldShow =
        _scrollController.offset > _floatingPreviewThreshold &&
        !_previewDockingDisabled;

    if (shouldShow != _showFloatingPreview && mounted) {
      setState(() {
        _showFloatingPreview = shouldShow;
      });
    }
  }

  Future<void> _closeFloatingPreview() async {
    if (!_scrollController.hasClients) return;

    setState(() {
      _previewDockingDisabled = true;
      _showFloatingPreview = false;
    });

    await _scrollToRobotView();

    if (!mounted) return;
    setState(() {
      _previewDockingDisabled = false;
    });
  }

  Future<void> _scrollToRobotView() async {
    if (!_scrollController.hasClients) return;

    final target = _resolveRobotViewOffset().clamp(
      0.0,
      _scrollController.position.maxScrollExtent,
    );

    await _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  double _resolveRobotViewOffset() {
    final robotContext = _robotViewAnchorKey.currentContext;
    final viewportContext = _scrollViewportKey.currentContext;

    if (robotContext == null || viewportContext == null) {
      return 0;
    }

    final robotBox = robotContext.findRenderObject();
    final viewportBox = viewportContext.findRenderObject();

    if (robotBox is! RenderBox || viewportBox is! RenderBox) {
      return 0;
    }

    final robotY = robotBox.localToGlobal(Offset.zero).dy;
    final viewportY = viewportBox.localToGlobal(Offset.zero).dy;
    final delta = robotY - viewportY;

    return _scrollController.offset + delta - 12;
  }

  Future<void> _toggleConnection() async {
    final svc = _robot;
    if (svc == null) {
      // Not bootstrapped yet — try again.
      await _bootstrapRobot();
      return;
    }
    if (svc.isConnected) {
      _joyTicker?.cancel();
      _joyTicker = null;
      await svc.dispose();
      // After explicit disconnect we tear down the service and let the user
      // re-bootstrap to reconnect.
      _robotStateSub?.cancel();
      _robotStateSub = null;
      _telemetrySub?.cancel();
      _telemetrySub = null;
      if (!mounted) return;
      setState(() {
        _robot = null;
        _isConnected = false;
        _signalStrength = 0;
        _speed = 0;
      });
    } else {
      await svc.connect();
    }
  }

  Future<void> _emergencyStop() async {
    _joyTicker?.cancel();
    _joyTicker = null;
    final robot = _robot;
    // Triple-tap stop in case a single Twist gets dropped on a flaky link.
    for (var i = 0; i < 3; i++) {
      await robot?.stop();
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    if (_activeRobot != null) {
      _robotApi.logCommand(
        robotId: _activeRobot!.id,
        command: RobotCommand.stop,
        linear: 0,
        angular: 0,
      );
    }
    if (!mounted) return;
    setState(() {
      _speed = 0;
      _joystickOffset = Offset.zero;
      _direction = 'Emergency stop';
      _appendEvent('Emergency stop executed', AppColorPalette.alertError);
    });
  }

  RobotCommand _commandFor(double linear, double angular) {
    if (linear > 0) return RobotCommand.forward;
    if (linear < 0) return RobotCommand.backward;
    if (angular > 0) return RobotCommand.left;
    if (angular < 0) return RobotCommand.right;
    return RobotCommand.stop;
  }

  void _onDriveCommandSent(double linear, double angular) {
    final robot = _activeRobot;
    if (robot == null) return;
    _robotApi.logCommand(
      robotId: robot.id,
      command: _commandFor(linear, angular),
      linear: linear,
      angular: angular,
    );
  }

  void _onJoystickPanUpdate(DragUpdateDetails details) {
    if (!_isConnected) return;

    setState(() {
      final next = Offset(
        _joystickOffset.dx + details.delta.dx,
        _joystickOffset.dy + details.delta.dy,
      );
      _joystickOffset = _clampOffset(next, _joystickRadius);

      final normalized = _joystickOffset.distance / _joystickRadius;
      _speed = (_maxSpeed * normalized).clamp(0, _maxSpeed);

      if (_joystickOffset.distance < 8) {
        _direction = 'Idle';
      } else {
        final radians = math.atan2(_joystickOffset.dy, _joystickOffset.dx);
        final degrees = (radians * 180 / math.pi + 360) % 360;
        _heading = degrees;
        _direction = _directionFromHeading(_heading);

        if (_direction != _lastDirectionLog) {
          _appendEvent('Joystick: $_direction', AppColorPalette.info);
          _lastDirectionLog = _direction;
        }
      }
    });

    // Kick off the periodic publisher the first time the stick moves. The
    // ticker reads the current `_joystickOffset` on every tick so we don't
    // need to push deltas through it.
    _joyTicker ??= Timer.periodic(_joystickPublishPeriod, (_) {
      _publishJoystick();
    });
    // Also publish immediately for responsiveness on the very first event.
    _publishJoystick();
  }

  void _publishJoystick() {
    final robot = _robot;
    if (robot == null || !_isConnected) return;

    // Map the joystick offset to a Twist:
    //  - up on screen (negative dy) → forward (+linear.x)
    //  - right on screen (positive dx) → clockwise turn (-angular.z)
    final nx = (_joystickOffset.dx / _joystickRadius).clamp(-1.0, 1.0);
    final ny = (-_joystickOffset.dy / _joystickRadius).clamp(-1.0, 1.0);
    final linear = ny * _maxLinearMs;
    final angular = -nx * _maxAngularRad;

    robot.drive(linear: linear, angular: angular);

    // Throttle the audit-log + REST round-trip to ~4 Hz so we don't spam the
    // backend at 20 Hz while the stick is held.
    final now = DateTime.now();
    if (now.difference(_lastJoyAuditAt).inMilliseconds >= 250 &&
        _activeRobot != null) {
      _lastJoyAuditAt = now;
      _robotApi.logCommand(
        robotId: _activeRobot!.id,
        command: _commandFor(linear, angular),
        linear: linear,
        angular: angular,
      );
    }
  }

  void _onJoystickPanEnd(DragEndDetails details) {
    _joyTicker?.cancel();
    _joyTicker = null;
    _robot?.stop();
    if (_activeRobot != null) {
      _robotApi.logCommand(
        robotId: _activeRobot!.id,
        command: RobotCommand.stop,
        linear: 0,
        angular: 0,
      );
    }
    if (!_isConnected) return;

    setState(() {
      _joystickOffset = Offset.zero;
      _speed = 0;
      _direction = 'Idle';
      _appendEvent('Joystick released', AppColorPalette.softSlate);
      _lastDirectionLog = 'Idle';
    });
  }

  Offset _clampOffset(Offset value, double maxRadius) {
    if (value.distance <= maxRadius) {
      return value;
    }

    final angle = math.atan2(value.dy, value.dx);
    return Offset(math.cos(angle) * maxRadius, math.sin(angle) * maxRadius);
  }

  String _directionFromHeading(double heading) {
    if (heading >= 337.5 || heading < 22.5) return 'East';
    if (heading >= 22.5 && heading < 67.5) return 'South-East';
    if (heading >= 67.5 && heading < 112.5) return 'South';
    if (heading >= 112.5 && heading < 157.5) return 'South-West';
    if (heading >= 157.5 && heading < 202.5) return 'West';
    if (heading >= 202.5 && heading < 247.5) return 'North-West';
    if (heading >= 247.5 && heading < 292.5) return 'North';
    return 'North-East';
  }

  void _appendEvent(String message, Color color) {
    _events.insert(
      0,
      _ControlEvent(message: message, color: color, timestamp: DateTime.now()),
    );

    if (_events.length > 12) {
      _events.removeRange(12, _events.length);
    }
  }

  /// Toggle the autonomous explore loop driven by `RobotVoiceController`.
  Future<void> _toggleExplore() async {
    final ctrl = RobotVoiceController.instance;
    if (_exploring) {
      await ctrl.stopExplore();
      if (!mounted) return;
      setState(() => _exploring = false);
      _appendEvent('Auto-explore stopped', AppColorPalette.softSlate);
    } else {
      // RobotVoiceController.startExplore() will lazily auto-connect via the
      // API and bind to the first registered robot.
      final ok = await ctrl.startExplore();
      if (!mounted) return;
      setState(() => _exploring = ok);
      _appendEvent(
        ok ? 'Auto-explore started' : 'Auto-explore failed to start',
        ok ? AppColorPalette.success : AppColorPalette.alertError,
      );
    }
  }

  /// Persist a snapshot of the live occupancy map to the backend.
  Future<void> _saveMapSnapshot(LidarMapBuilder builder) async {
    if (_savingMap) return;
    final robot = _activeRobot;
    if (robot == null) {
      _appendEvent('Cannot save map: no robot bound', AppColorPalette.warning);
      return;
    }
    setState(() => _savingMap = true);
    try {
      final pixels = builder.toGreyscalePixels();
      final cols = builder.cols;
      final rows = builder.rows;
      final res = builder.resolutionMeters;
      // Encode RGBA pixels as a PNG via dart:ui.
      final completer = Completer<Uint8List>();
      ui.decodeImageFromPixels(pixels, cols, rows, ui.PixelFormat.rgba8888, (
        img,
      ) async {
        final byteData = await img.toByteData(
          format: ui.ImageByteFormat.png,
        );
        completer.complete(byteData!.buffer.asUint8List());
      });
      final png = await completer.future;
      final meta = await _robotApi.saveMap(
        robotId: robot.id,
        pngBytes: png,
        resolutionMeters: res,
        cols: cols,
        rows: rows,
        label: 'Snapshot ${DateTime.now().toIso8601String()}',
      );
      if (!mounted) return;
      _appendEvent('Map saved: ${meta['id']}', AppColorPalette.success);
    } catch (e) {
      if (!mounted) return;
      _appendEvent('Map save failed: $e', AppColorPalette.alertError);
    } finally {
      if (mounted) setState(() => _savingMap = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorPalette.wheatWarmClay,
      appBar: AppBar(
        title: Text(
          'Control Room',
          style: AppTextStyles.h3(color: AppColorPalette.charcoalGreen),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              key: _scrollViewportKey,
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(),
                  const SizedBox(height: 14),
                  _buildAdaptiveControlArea(),
                  const SizedBox(height: 14),
                  if (_robot != null) ...[
                    LidarRadarPanel(
                      scanStream: _robot!.scanStream,
                      lastScan: _robot!.lastScan,
                    ),
                    const SizedBox(height: 14),
                    LidarMapPanel(
                      scanStream: _robot!.scanStream,
                      telemetryStream: _robot!.telemetryStream,
                      onSnapshot: _saveMapSnapshot,
                    ),
                    const SizedBox(height: 14),
                  ],
                  _buildQuickCommands(),
                  const SizedBox(height: 14),
                  _buildTelemetryGrid(),
                  const SizedBox(height: 14),
                  _buildEventFeed(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            if (_showFloatingPreview) _buildFloatingPreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingPreview() {
    final width = math.min(MediaQuery.of(context).size.width * 0.48, 210.0);

    return Positioned(
      right: 14,
      bottom: 18,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: width,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.22),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Live Preview',
                    style: AppTextStyles.caption(
                      color: AppColorPalette.charcoalGreen,
                    ).copyWith(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: _closeFloatingPreview,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColorPalette.lightGrey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.close_rounded, size: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              AspectRatio(
                aspectRatio: 16 / 9,
                child: _buildLivePreviewCanvas(compact: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    final statusColor = _isConnected
        ? AppColorPalette.success
        : AppColorPalette.warning;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColorPalette.robotTechGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Preview Mode',
                  style: AppTextStyles.buttonSmall(color: Colors.white),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _isConnected ? 'Connected' : 'Disconnected',
                style: AppTextStyles.bodySmall(color: Colors.white),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _toggleConnection,
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                icon: Icon(
                  _isConnected ? Icons.link_off_rounded : Icons.link_rounded,
                ),
                label: Text(_isConnected ? 'Disconnect' : 'Reconnect'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Robot Control Station',
            style: AppTextStyles.h3(color: Colors.white),
          ),
          const SizedBox(height: 6),
          Text(
            'Control movement, monitor robot view, and validate command flow before ROS integration.',
            style: AppTextStyles.bodySmall(
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdaptiveControlArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  key: _robotViewAnchorKey,
                  child: _buildRobotViewCard(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: _buildJoystickCard()),
            ],
          );
        }

        return Column(
          children: [
            Container(key: _robotViewAnchorKey, child: _buildRobotViewCard()),
            const SizedBox(height: 12),
            _buildJoystickCard(),
          ],
        );
      },
    );
  }

  Widget _buildRobotViewCard() {
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
              Text(
                'Robot View',
                style: AppTextStyles.h4(color: AppColorPalette.charcoalGreen),
              ),
              const Spacer(),
              Text(
                'Simulated Feed',
                style: AppTextStyles.caption(color: AppColorPalette.softSlate),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AspectRatio(aspectRatio: 16 / 9, child: _buildLivePreviewCanvas()),
        ],
      ),
    );
  }

  Widget _buildLivePreviewCanvas({bool compact = false}) {
    final robot = _activeRobot;
    if (robot == null) {
      return Container(
        decoration: BoxDecoration(
          color: AppColorPalette.charcoalGreen,
          borderRadius: BorderRadius.circular(compact ? 10 : 14),
        ),
        alignment: Alignment.center,
        child: _loadingRobots
            ? const CircularProgressIndicator(strokeWidth: 2)
            : Padding(
                padding: EdgeInsets.all(compact ? 6 : 12),
                child: Text(
                  _robotError ?? 'No robot selected',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.caption(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),
      );
    }

    return CameraView(
      robotIp: robot.ip,
      videoPort: robot.videoPort,
      videoTopic: robot.videoTopic,
      isLive: _isConnected,
    );
  }

  Widget _buildJoystickCard() {
    final knobColor = _isConnected
        ? AppColorPalette.fieldFreshStart
        : AppColorPalette.mediumGrey;

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
              Text(
                'Joystick Control',
                style: AppTextStyles.h4(color: AppColorPalette.charcoalGreen),
              ),
              const Spacer(),
              Text(
                _isConnected ? 'Active' : 'Offline',
                style: AppTextStyles.caption(
                  color: _isConnected
                      ? AppColorPalette.success
                      : AppColorPalette.alertError,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Center(
            child: SizedBox(
              width: _joystickRadius * 2 + 24,
              height: _joystickRadius * 2 + 24,
              child: GestureDetector(
                onPanUpdate: _onJoystickPanUpdate,
                onPanEnd: _onJoystickPanEnd,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: _joystickRadius * 2,
                      height: _joystickRadius * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColorPalette.lightGrey,
                          width: 4,
                        ),
                        color: AppColorPalette.wheatWarmClay,
                      ),
                    ),
                    Transform.translate(
                      offset: _joystickOffset,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: knobColor,
                          boxShadow: [
                            BoxShadow(
                              color: knobColor.withValues(alpha: 0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.open_with_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Drag the joystick to simulate heading and speed control.',
            style: AppTextStyles.bodySmall(color: AppColorPalette.softSlate),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickCommands() {
    final robot = _robot;
    final canDrive = robot != null && _isConnected;

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
              Text(
                'Hold to Drive',
                style: AppTextStyles.h4(color: AppColorPalette.charcoalGreen),
              ),
              const SizedBox(width: 8),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: canDrive
                      ? AppColorPalette.success
                      : AppColorPalette.alertError,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                canDrive ? 'Online' : 'Offline',
                style: AppTextStyles.caption(
                  color: canDrive
                      ? AppColorPalette.success
                      : AppColorPalette.alertError,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!canDrive)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                _robotError ??
                    'Waiting for rosbridge connection to ${_activeRobot?.ip ?? 'robot'}…',
                style: AppTextStyles.bodySmall(
                  color: AppColorPalette.softSlate,
                ),
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                DriveButton(
                  robot: robot,
                  linear: 0.25,
                  angular: 0,
                  icon: Icons.keyboard_arrow_up_rounded,
                  label: 'Forward',
                  color: AppColorPalette.fieldFreshStart,
                  onCommandSent: _onDriveCommandSent,
                ),
                DriveButton(
                  robot: robot,
                  linear: -0.25,
                  angular: 0,
                  icon: Icons.keyboard_arrow_down_rounded,
                  label: 'Reverse',
                  color: AppColorPalette.fieldFreshStart,
                  onCommandSent: _onDriveCommandSent,
                ),
                DriveButton(
                  robot: robot,
                  linear: 0,
                  angular: 1.2,
                  icon: Icons.keyboard_arrow_left_rounded,
                  label: 'Left',
                  color: AppColorPalette.mistyBlue,
                  onCommandSent: _onDriveCommandSent,
                ),
                DriveButton(
                  robot: robot,
                  linear: 0,
                  angular: -1.2,
                  icon: Icons.keyboard_arrow_right_rounded,
                  label: 'Right',
                  color: AppColorPalette.mistyBlue,
                  onCommandSent: _onDriveCommandSent,
                ),
              ],
            ),
          const SizedBox(height: 16),
          _ActionButtonsBar(
            canDrive: canDrive,
            exploring: _exploring,
            onEmergencyStop: _emergencyStop,
            onToggleExplore: _toggleExplore,
            onOpenFieldMapping: () async {
              final result = await Navigator.of(context).push<
                  List<List<double>>>(
                MaterialPageRoute(
                  builder: (_) => const LidarFieldMappingScreen(),
                ),
              );
              if (!mounted) return;
              if (result != null && result.isNotEmpty) {
                _appendEvent(
                  'Captured perimeter: ${result.length} vertices',
                  AppColorPalette.success,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryGrid() {
    final cards = <_MetricData>[
      _MetricData(
        label: 'Battery',
        value: _batteryLevel < 0
            ? '—'
            : '${_batteryLevel.toStringAsFixed(1)} %',
        icon: Icons.battery_full_rounded,
        color: _batteryLevel < 0
            ? AppColorPalette.softSlate
            : (_batteryLevel > 35
                  ? AppColorPalette.success
                  : AppColorPalette.warning),
      ),
      _MetricData(
        label: 'Signal',
        value: '$_signalStrength %',
        icon: Icons.network_cell_rounded,
        color: _signalStrength > 40
            ? AppColorPalette.info
            : AppColorPalette.warning,
      ),
      _MetricData(
        label: 'Speed',
        value: '${_speed.toStringAsFixed(2)} m/s',
        icon: Icons.speed_rounded,
        color: AppColorPalette.fieldFreshStart,
      ),
      _MetricData(
        label: 'Heading',
        value: '${_heading.toStringAsFixed(0)}°',
        icon: Icons.explore_rounded,
        color: AppColorPalette.robotTechEnd,
      ),
      _MetricData(
        label: 'Direction',
        value: _direction,
        icon: Icons.navigation_rounded,
        color: AppColorPalette.mistyBlue,
      ),
    ];

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
              Text(
                'Telemetry',
                style: AppTextStyles.h4(color: AppColorPalette.charcoalGreen),
              ),
              const Spacer(),
              Text(
                _isConnected ? 'Live' : 'Offline',
                style: AppTextStyles.caption(color: AppColorPalette.softSlate),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 10.0;
              final width = constraints.maxWidth;
              final crossAxisCount = width >= 900
                  ? 5
                  : width >= 720
                  ? 4
                  : width >= 520
                  ? 3
                  : 2;

              final itemWidth =
                  (width - ((crossAxisCount - 1) * spacing)) / crossAxisCount;
              final isCompact = itemWidth < 170;
              final itemHeight = isCompact ? 118.0 : 126.0;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: cards.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: spacing,
                  crossAxisSpacing: spacing,
                  childAspectRatio: itemWidth / itemHeight,
                ),
                itemBuilder: (context, index) {
                  return _buildTelemetryCard(cards[index], compact: isCompact);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryCard(_MetricData metric, {bool compact = false}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColorPalette.wheatWarmClay,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: metric.color.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(compact ? 6 : 8),
            decoration: BoxDecoration(
              color: metric.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              metric.icon,
              color: metric.color,
              size: compact ? 18 : 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            metric.label,
            style: AppTextStyles.caption(
              color: AppColorPalette.softSlate,
            ).copyWith(fontSize: compact ? 11 : 12),
          ),
          const SizedBox(height: 4),
          Text(
            metric.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                (compact
                        ? AppTextStyles.bodyMedium(
                            color: AppColorPalette.charcoalGreen,
                          )
                        : AppTextStyles.bodyLarge(
                            color: AppColorPalette.charcoalGreen,
                          ))
                    .copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildEventFeed() {
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
          Text(
            'Recent Activity',
            style: AppTextStyles.h4(color: AppColorPalette.charcoalGreen),
          ),
          const SizedBox(height: 10),
          if (_events.isEmpty)
            Text(
              'No activity yet.',
              style: AppTextStyles.bodySmall(color: AppColorPalette.softSlate),
            )
          else
            ..._events.map(
              (event) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: event.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.message,
                            style: AppTextStyles.bodyMedium(
                              color: AppColorPalette.charcoalGreen,
                            ),
                          ),
                          Text(
                            '${event.timestamp.hour.toString().padLeft(2, '0')}:${event.timestamp.minute.toString().padLeft(2, '0')}:${event.timestamp.second.toString().padLeft(2, '0')}',
                            style: AppTextStyles.caption(
                              color: AppColorPalette.softSlate,
                            ),
                          ),
                        ],
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
}

class _MetricData {
  const _MetricData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _ControlEvent {
  const _ControlEvent({
    required this.message,
    required this.color,
    required this.timestamp,
  });

  final String message;
  final Color color;
  final DateTime timestamp;
}

/// Compact, professionally-styled action bar for the Control Room.
///
/// * Emergency Stop is always visible and visually dominant (red, full-width
///   on phones, primary on tablets).
/// * Auto-Explore + Field Mapping are grouped together as the "autonomy"
///   actions and only appear when the robot can drive.
/// * On narrow screens the buttons stack into a single column; on wider
///   screens they sit side-by-side in a balanced row.
class _ActionButtonsBar extends StatelessWidget {
  const _ActionButtonsBar({
    required this.canDrive,
    required this.exploring,
    required this.onEmergencyStop,
    required this.onToggleExplore,
    required this.onOpenFieldMapping,
  });

  final bool canDrive;
  final bool exploring;
  final VoidCallback onEmergencyStop;
  final VoidCallback onToggleExplore;
  final VoidCallback onOpenFieldMapping;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 520;

        final stopButton = _ActionPillButton(
          icon: Icons.stop_circle_rounded,
          label: 'Emergency Stop',
          background: AppColorPalette.alertError,
          foreground: Colors.white,
          onPressed: onEmergencyStop,
        );

        final exploreButton = _ActionPillButton(
          icon: exploring ? Icons.stop_rounded : Icons.explore_rounded,
          label: exploring ? 'Stop Auto-Explore' : 'Auto-Explore',
          background: exploring
              ? AppColorPalette.warning
              : AppColorPalette.fieldFreshStart,
          foreground: Colors.white,
          onPressed: onToggleExplore,
        );

        final mapButton = _ActionPillButton(
          icon: Icons.crop_free_rounded,
          label: 'Field Mapping',
          background: Colors.white,
          foreground: AppColorPalette.charcoalGreen,
          borderColor: AppColorPalette.charcoalGreen.withValues(alpha: 0.25),
          onPressed: onOpenFieldMapping,
        );

        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              stopButton,
              if (canDrive) ...[
                const SizedBox(height: 10),
                exploreButton,
                const SizedBox(height: 10),
                mapButton,
              ],
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: stopButton),
            if (canDrive) ...[
              const SizedBox(width: 12),
              Expanded(child: exploreButton),
              const SizedBox(width: 12),
              Expanded(child: mapButton),
            ],
          ],
        );
      },
    );
  }
}

/// Pill-shaped action button used in the Control Room action bar.
class _ActionPillButton extends StatelessWidget {
  const _ActionPillButton({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    required this.onPressed,
    this.borderColor,
  });

  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final Color? borderColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: borderColor != null
                ? BorderSide(color: borderColor!, width: 1.2)
                : BorderSide.none,
          ),
          textStyle: AppTextStyles.bodyMedium(
            color: foreground,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: foreground),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
