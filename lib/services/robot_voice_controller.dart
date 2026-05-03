import 'dart:async';

import 'package:flutter/foundation.dart';

import 'robot_api_service.dart';
import 'robot_service.dart';

/// App-wide singleton that lets the voice assistant (or any other surface
/// outside the Control Room screen) drive the robot.
///
/// Holds its own [RobotService] connection so that voice commands work even
/// when the Control Room screen isn't currently mounted. Connections are
/// lazy: the first command call triggers `listRobots` + `connect`. After
/// that, subsequent commands re-use the open WebSocket.
class RobotVoiceController {
  RobotVoiceController._();
  static final RobotVoiceController instance = RobotVoiceController._();

  // Conservative defaults that match the Control Room joystick limits.
  static const double _quickLinear = 0.22; // m/s
  static const double _quickAngular = 1.1; // rad/s
  static const Duration _quickPulse = Duration(milliseconds: 1500);
  static const Duration _quickTurnPulse = Duration(milliseconds: 900);
  static const double _distanceSpeed = 0.20; // m/s for "advance X cm" commands
  static const Duration _maxDistanceDuration = Duration(seconds: 12);
  static const double _publishHz = 20;

  final RobotApiService _api = RobotApiService();
  RobotService? _svc;
  RobotDescriptor? _robot;
  Timer? _pulseTicker;
  Timer? _pulseTimeout;

  RobotDescriptor? get activeRobot => _robot;
  bool get isConnected => _svc?.isConnected ?? false;

  /// Bring up (or reuse) a connection. Returns `true` once the rosbridge
  /// link is established. Returns `false` if no robot is registered or the
  /// connection couldn't be opened within [timeout].
  Future<bool> ensureConnected({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (_svc?.isConnected ?? false) return true;

    if (_svc == null) {
      try {
        final robots = await _api.listRobots();
        if (robots.isEmpty) return false;
        _robot = robots.first;
        _svc = RobotService(
          robotIp: _robot!.ip,
          rosbridgePort: _robot!.rosbridgePort,
        );
      } catch (e) {
        debugPrint('[RobotVoiceController] listRobots failed: $e');
        return false;
      }
    }

    final svc = _svc!;
    if (!svc.isConnected) {
      try {
        await svc.connect();
      } catch (e) {
        debugPrint('[RobotVoiceController] connect failed: $e');
      }
      // connect() returns once the WS is open OR fails silently; poll briefly.
      final deadline = DateTime.now().add(timeout);
      while (!svc.isConnected && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }
    return svc.isConnected;
  }

  Future<bool> moveForward({Duration? duration}) =>
      _drivePulse(linear: _quickLinear, angular: 0, duration: duration ?? _quickPulse);

  Future<bool> moveBackward({Duration? duration}) =>
      _drivePulse(linear: -_quickLinear, angular: 0, duration: duration ?? _quickPulse);

  Future<bool> turnLeft({Duration? duration}) => _drivePulse(
        linear: 0,
        angular: _quickAngular,
        duration: duration ?? _quickTurnPulse,
      );

  Future<bool> turnRight({Duration? duration}) => _drivePulse(
        linear: 0,
        angular: -_quickAngular,
        duration: duration ?? _quickTurnPulse,
      );

  /// Drive forward (positive `meters`) or backward (negative) for the given
  /// straight-line distance. Uses closed-loop integration of `/odom` linear
  /// velocity feedback so the robot actually travels close to the requested
  /// distance regardless of the open-loop speed estimate. Falls back to a
  /// duration-based pulse if no odom packets arrive within the first second.
  Future<bool> driveDistance({required double meters}) async {
    if (meters == 0) return emergencyStop();

    final ok = await ensureConnected();
    if (!ok) return false;
    final svc = _svc!;

    final magnitude = meters.abs();
    final linear = meters > 0 ? _distanceSpeed : -_distanceSpeed;
    // Hard safety cap derived from speed; never run forever even if odom is
    // dead or wrong.
    final fallbackSecs = (magnitude / _distanceSpeed).clamp(
      0.2,
      _maxDistanceDuration.inMilliseconds / 1000.0,
    );
    // Allow ~50% extra time for acceleration / friction before the safety
    // timeout cuts in. Still capped by [_maxDistanceDuration].
    final maxSecs = (fallbackSecs * 1.5).clamp(
      0.5,
      _maxDistanceDuration.inMilliseconds / 1000.0,
    );
    final maxDuration = Duration(milliseconds: (maxSecs * 1000).round());

    _cancelPulse();

    // Start the publish loop so the robot actually moves.
    final periodMs = (1000 / _publishHz).round();
    _pulseTicker = Timer.periodic(Duration(milliseconds: periodMs), (_) {
      svc.drive(linear: linear, angular: 0);
    });
    unawaited(svc.drive(linear: linear, angular: 0));

    final completer = Completer<bool>();
    final stopwatch = Stopwatch()..start();
    var integrated = 0.0; // m (always positive — magnitude travelled)
    DateTime lastSampleAt = DateTime.now();
    var sawOdom = false;
    StreamSubscription<RobotTelemetry>? sub;

    void finish(bool result) {
      if (completer.isCompleted) return;
      sub?.cancel();
      _cancelPulse();
      try {
        svc.stop();
      } catch (_) {}
      completer.complete(result);
    }

    sub = svc.telemetryStream.listen((tele) {
      // Only count packets that carry a fresh /odom timestamp.
      final ts = tele.lastOdomAt;
      if (ts == null) return;
      sawOdom = true;
      final now = DateTime.now();
      final dt = now.difference(lastSampleAt).inMilliseconds / 1000.0;
      lastSampleAt = now;
      if (dt <= 0 || dt > 1.0) {
        // Skip suspicious deltas (first sample, long gaps).
        return;
      }
      integrated += tele.linearSpeed.abs() * dt;
      if (integrated >= magnitude) {
        debugPrint(
          '[RobotVoiceController] driveDistance reached '
          '${integrated.toStringAsFixed(3)} m / target '
          '${magnitude.toStringAsFixed(3)} m in '
          '${stopwatch.elapsedMilliseconds} ms',
        );
        finish(true);
      }
    });

    // Safety timeout: stop regardless of integration. If odom never arrived,
    // this also acts as the open-loop fallback.
    _pulseTimeout = Timer(maxDuration, () {
      debugPrint(
        '[RobotVoiceController] driveDistance timeout '
        '(${stopwatch.elapsedMilliseconds} ms, sawOdom=$sawOdom, '
        'integrated=${integrated.toStringAsFixed(3)} m / '
        'target ${magnitude.toStringAsFixed(3)} m)',
      );
      finish(true);
    });

    return completer.future;
  }

  /// Hard stop — cancels any in-flight pulse and triple-publishes a zero
  /// Twist (matching the Control Room emergency stop behaviour).
  Future<bool> emergencyStop() async {
    _cancelPulse();
    final svc = _svc;
    if (svc == null) return false;
    if (!svc.isConnected) {
      // Try to bring the link back up so the stop actually lands.
      await ensureConnected(timeout: const Duration(seconds: 2));
    }
    for (var i = 0; i < 3; i++) {
      try {
        await svc.stop();
      } catch (_) {}
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    return svc.isConnected;
  }

  /// Publish a fixed Twist at 20 Hz for [duration], then send a stop. Cancels
  /// any previously-running pulse first so commands don't queue up.
  Future<bool> _drivePulse({
    required double linear,
    required double angular,
    required Duration duration,
  }) async {
    final ok = await ensureConnected();
    if (!ok) return false;
    final svc = _svc!;

    _cancelPulse();
    _pulseTicker = Timer.periodic(
      Duration(milliseconds: (1000 / _publishHz).round()),
      (_) {
        // Fire-and-forget; RobotService swallows errors and reconnects.
        svc.drive(linear: linear, angular: angular);
      },
    );
    // Publish the first frame immediately for snappier response.
    unawaited(svc.drive(linear: linear, angular: angular));

    _pulseTimeout = Timer(duration, () {
      _cancelPulse();
      svc.stop();
    });
    return true;
  }

  void _cancelPulse() {
    _pulseTicker?.cancel();
    _pulseTicker = null;
    _pulseTimeout?.cancel();
    _pulseTimeout = null;
  }

  /// Tear down the underlying connection. Called only when the user logs out
  /// or the app exits — voice commands should keep the link warm otherwise.
  Future<void> shutdown() async {
    _cancelPulse();
    final svc = _svc;
    _svc = null;
    _robot = null;
    if (svc != null) {
      try {
        await svc.dispose();
      } catch (_) {}
    }
  }
}
