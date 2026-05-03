import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:roslibdart/roslibdart.dart';

/// Connection state of the underlying rosbridge WebSocket.
enum RobotConnectionState { disconnected, connecting, connected }

/// Snapshot of the latest telemetry pulled off rosbridge.
@immutable
class RobotTelemetry {
  const RobotTelemetry({
    this.batteryVolts,
    this.batteryPercent,
    this.linearSpeed = 0,
    this.angularSpeed = 0,
    this.headingDeg = 0,
    this.signalPercent = 0,
    this.lastOdomAt,
    this.lastBatteryAt,
  });

  /// Raw battery voltage from `/voltage` (jetbot_pro). Null until a packet
  /// arrives.
  final double? batteryVolts;

  /// Battery percentage derived from [batteryVolts] using the LiPo curve.
  final double? batteryPercent;

  /// Latest forward velocity (m/s) from `/odom.twist.twist.linear.x`.
  final double linearSpeed;

  /// Latest yaw rate (rad/s) from `/odom.twist.twist.angular.z`.
  final double angularSpeed;

  /// Robot yaw in degrees [0..360) derived from the odom quaternion.
  final double headingDeg;

  /// Heuristic 0..100 link health based on freshness of the last odom packet.
  final int signalPercent;

  final DateTime? lastOdomAt;
  final DateTime? lastBatteryAt;

  RobotTelemetry copyWith({
    double? batteryVolts,
    double? batteryPercent,
    double? linearSpeed,
    double? angularSpeed,
    double? headingDeg,
    int? signalPercent,
    DateTime? lastOdomAt,
    DateTime? lastBatteryAt,
  }) {
    return RobotTelemetry(
      batteryVolts: batteryVolts ?? this.batteryVolts,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      linearSpeed: linearSpeed ?? this.linearSpeed,
      angularSpeed: angularSpeed ?? this.angularSpeed,
      headingDeg: headingDeg ?? this.headingDeg,
      signalPercent: signalPercent ?? this.signalPercent,
      lastOdomAt: lastOdomAt ?? this.lastOdomAt,
      lastBatteryAt: lastBatteryAt ?? this.lastBatteryAt,
    );
  }
}

/// Thin wrapper around `roslibdart` that:
///  - opens a WebSocket to a robot's rosbridge server
///  - advertises and publishes `geometry_msgs/Twist` on `/cmd_vel`
///  - subscribes to `/odom` and `/voltage` for live telemetry
///  - exposes connection-state + telemetry streams the UI can listen to
///  - auto-reconnects with a small backoff while [_keepAlive] is true
///
/// Designed to be created once per Control Room screen and disposed cleanly
/// when the screen is left.
class RobotService {
  RobotService({
    required this.robotIp,
    this.rosbridgePort = 9090,
    this.cmdVelTopic = '/cmd_vel',
    this.odomTopic = '/odom',
    this.voltageTopic = '/voltage',
    this.batteryStateTopic = '/battery_state',
    this.batteryFullVolts = 12.6,
    this.batteryEmptyVolts = 9.5,
  });

  final String robotIp;
  final int rosbridgePort;
  final String cmdVelTopic;
  final String odomTopic;
  final String voltageTopic;
  final String batteryStateTopic;
  final double batteryFullVolts;
  final double batteryEmptyVolts;

  Ros? _ros;
  Topic? _cmdVel;
  Topic? _odom;
  Topic? _voltage;
  Topic? _batteryState;
  Timer? _signalTimer;
  bool _loggedFirstOdom = false;
  bool _loggedFirstBattery = false;

  bool _keepAlive = false;
  bool _disposed = false;
  Timer? _reconnectTimer;

  final StreamController<RobotConnectionState> _stateCtrl =
      StreamController<RobotConnectionState>.broadcast();
  final StreamController<RobotTelemetry> _telemetryCtrl =
      StreamController<RobotTelemetry>.broadcast();
  RobotConnectionState _state = RobotConnectionState.disconnected;
  RobotTelemetry _telemetry = const RobotTelemetry();

  /// Live stream of connection state changes.
  Stream<RobotConnectionState> get connectionState => _stateCtrl.stream;

  /// Live telemetry stream (battery, odom-derived speed/heading, signal).
  Stream<RobotTelemetry> get telemetryStream => _telemetryCtrl.stream;

  /// Last known telemetry snapshot.
  RobotTelemetry get currentTelemetry => _telemetry;

  /// Last known connection state (synchronous access for initial UI build).
  RobotConnectionState get currentState => _state;

  bool get isConnected => _state == RobotConnectionState.connected;

  String get _wsUrl => 'ws://$robotIp:$rosbridgePort';

  /// Open the WebSocket and advertise `/cmd_vel`. Safe to call multiple times.
  Future<void> connect() async {
    if (_disposed) return;
    _keepAlive = true;
    if (_state == RobotConnectionState.connecting ||
        _state == RobotConnectionState.connected) {
      return;
    }

    _emit(RobotConnectionState.connecting);

    try {
      final ros = Ros(url: _wsUrl);
      // `connect()` returns void in roslibdart; status is reported via
      // ros.statusStream. We register the status listener BEFORE connecting
      // so we don't miss the first transition.
      ros.statusStream.listen(
        _onRosStatus,
        onError: (Object _) => _handleDrop(),
      );
      ros.connect();

      final cmdVel = Topic(
        ros: ros,
        name: cmdVelTopic,
        type: 'geometry_msgs/Twist',
        reconnectOnClose: true,
        queueLength: 1,
        queueSize: 1,
      );
      await cmdVel.advertise();

      // Telemetry subscriptions. We don't await `subscribe` results because
      // any failure here will surface through the rosbridge status stream
      // and we'd rather have a working /cmd_vel than abort the whole session.
      final odom = Topic(
        ros: ros,
        name: odomTopic,
        type: 'nav_msgs/Odometry',
        reconnectOnClose: true,
        queueLength: 1,
        queueSize: 1,
        throttleRate: 100, // ms — 10 Hz is plenty for UI gauges
      );
      unawaited(odom.subscribe(_handleOdom));

      final voltage = Topic(
        ros: ros,
        name: voltageTopic,
        type: 'std_msgs/Float32',
        reconnectOnClose: true,
        queueLength: 1,
        queueSize: 1,
        throttleRate: 500,
      );
      unawaited(voltage.subscribe(_handleVoltage));

      // Some JetBot variants publish battery as sensor_msgs/BatteryState on
      // /battery_state instead of (or in addition to) /voltage. Subscribing to
      // both means we surface whichever the robot actually exposes.
      final batteryState = Topic(
        ros: ros,
        name: batteryStateTopic,
        type: 'sensor_msgs/BatteryState',
        reconnectOnClose: true,
        queueLength: 1,
        queueSize: 1,
        throttleRate: 500,
      );
      unawaited(batteryState.subscribe(_handleBatteryState));

      _ros = ros;
      _cmdVel = cmdVel;
      _odom = odom;
      _voltage = voltage;
      _batteryState = batteryState;
      _startSignalTimer();
      _emit(RobotConnectionState.connected);
    } catch (e, st) {
      debugPrint('[RobotService] connect failed: $e\n$st');
      _handleDrop();
    }
  }

  // ── Telemetry handlers ─────────────────────────────────────────────────

  Future<void> _handleOdom(Map<String, dynamic> msg) async {
    if (!_loggedFirstOdom) {
      _loggedFirstOdom = true;
      debugPrint('[RobotService] first /odom packet received');
    }
    try {
      final twist = (msg['twist'] as Map?)?['twist'] as Map?;
      final linear = (twist?['linear'] as Map?)?['x'];
      final angular = (twist?['angular'] as Map?)?['z'];
      final orientation =
          ((msg['pose'] as Map?)?['pose'] as Map?)?['orientation'] as Map?;

      double? yawDeg;
      if (orientation != null) {
        final qx = (orientation['x'] as num?)?.toDouble() ?? 0;
        final qy = (orientation['y'] as num?)?.toDouble() ?? 0;
        final qz = (orientation['z'] as num?)?.toDouble() ?? 0;
        final qw = (orientation['w'] as num?)?.toDouble() ?? 1;
        // Yaw extraction from quaternion (Z axis).
        final siny = 2 * (qw * qz + qx * qy);
        final cosy = 1 - 2 * (qy * qy + qz * qz);
        final yaw = math.atan2(siny, cosy);
        yawDeg = (yaw * 180 / math.pi + 360) % 360;
      }

      _telemetry = _telemetry.copyWith(
        linearSpeed: (linear as num?)?.toDouble() ?? _telemetry.linearSpeed,
        angularSpeed:
            (angular as num?)?.toDouble() ?? _telemetry.angularSpeed,
        headingDeg: yawDeg ?? _telemetry.headingDeg,
        lastOdomAt: DateTime.now(),
      );
      _emitTelemetry();
    } catch (e) {
      debugPrint('[RobotService] odom parse failed: $e');
    }
  }

  Future<void> _handleVoltage(Map<String, dynamic> msg) async {
    try {
      final raw = msg['data'];
      final volts = (raw as num?)?.toDouble();
      if (volts == null) return;
      if (!_loggedFirstBattery) {
        _loggedFirstBattery = true;
        debugPrint(
          '[RobotService] first $voltageTopic packet: ${volts.toStringAsFixed(2)} V',
        );
      }
      _applyBatteryVolts(volts);
    } catch (e) {
      debugPrint('[RobotService] voltage parse failed: $e');
    }
  }

  /// Handle `sensor_msgs/BatteryState` — used as a fallback for JetBots that
  /// don't publish a plain `/voltage`. We prefer the message's `percentage`
  /// field when valid; otherwise fall back to deriving % from `voltage`.
  Future<void> _handleBatteryState(Map<String, dynamic> msg) async {
    try {
      final volts = (msg['voltage'] as num?)?.toDouble();
      final percentageRaw = (msg['percentage'] as num?)?.toDouble();
      if (!_loggedFirstBattery && (volts != null || percentageRaw != null)) {
        _loggedFirstBattery = true;
        debugPrint(
          '[RobotService] first $batteryStateTopic packet: '
          'volts=$volts, percentage=$percentageRaw',
        );
      }

      double? pct;
      if (percentageRaw != null && percentageRaw.isFinite && percentageRaw > 0) {
        // sensor_msgs/BatteryState specifies percentage in 0..1.
        pct = (percentageRaw * 100).clamp(0.0, 100.0);
      }

      if (volts != null && volts.isFinite && volts > 0) {
        if (pct != null) {
          _telemetry = _telemetry.copyWith(
            batteryVolts: volts,
            batteryPercent: pct,
            lastBatteryAt: DateTime.now(),
          );
          _emitTelemetry();
        } else {
          _applyBatteryVolts(volts);
        }
      } else if (pct != null) {
        _telemetry = _telemetry.copyWith(
          batteryPercent: pct,
          lastBatteryAt: DateTime.now(),
        );
        _emitTelemetry();
      }
    } catch (e) {
      debugPrint('[RobotService] battery_state parse failed: $e');
    }
  }

  void _applyBatteryVolts(double volts) {
    final span = (batteryFullVolts - batteryEmptyVolts).abs();
    final pct = span <= 0
        ? 0.0
        : ((volts - batteryEmptyVolts) / span * 100).clamp(0.0, 100.0);
    _telemetry = _telemetry.copyWith(
      batteryVolts: volts,
      batteryPercent: pct,
      lastBatteryAt: DateTime.now(),
    );
    _emitTelemetry();
  }

  void _startSignalTimer() {
    _signalTimer?.cancel();
    _signalTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final last = _telemetry.lastOdomAt;
      int signal;
      if (!isConnected) {
        signal = 0;
      } else if (last == null) {
        // Connected but no odom yet — give partial credit while waiting.
        signal = 40;
      } else {
        final ageMs = DateTime.now().difference(last).inMilliseconds;
        if (ageMs < 500) {
          signal = 100;
        } else if (ageMs > 5000) {
          signal = 0;
        } else {
          // Linear ramp 500ms → 100, 5000ms → 0.
          signal = (100 - ((ageMs - 500) / 4500.0 * 100)).round().clamp(0, 100);
        }
      }
      if (signal != _telemetry.signalPercent) {
        _telemetry = _telemetry.copyWith(signalPercent: signal);
        _emitTelemetry();
      }
    });
  }

  void _emitTelemetry() {
    if (!_telemetryCtrl.isClosed) _telemetryCtrl.add(_telemetry);
  }

  void _onRosStatus(Status status) {
    switch (status) {
      case Status.connected:
        _emit(RobotConnectionState.connected);
        break;
      case Status.closed:
      case Status.errored:
        _handleDrop();
        break;
      case Status.connecting:
        _emit(RobotConnectionState.connecting);
        break;
      case Status.none:
        break;
    }
  }

  void _handleDrop() {
    _emit(RobotConnectionState.disconnected);
    _cmdVel = null;
    _odom = null;
    _voltage = null;
    _batteryState = null;
    _ros = null;
    _signalTimer?.cancel();
    _signalTimer = null;
    _loggedFirstOdom = false;
    _loggedFirstBattery = false;
    // Zero out the live readings so the UI doesn't keep showing stale data.
    _telemetry = _telemetry.copyWith(
      linearSpeed: 0,
      angularSpeed: 0,
      signalPercent: 0,
    );
    _emitTelemetry();
    if (!_keepAlive || _disposed) return;
    // Backoff lightly to avoid hammering the robot if it's offline.
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 2), () {
      if (_keepAlive && !_disposed) connect();
    });
  }

  void _emit(RobotConnectionState s) {
    if (_state == s) return;
    _state = s;
    if (!_stateCtrl.isClosed) _stateCtrl.add(s);
  }

  /// Publish a single Twist message. Silently no-ops if not connected — the
  /// caller (a 20 Hz timer) will retry on the next tick once the link is back.
  Future<void> drive({
    required double linear,
    required double angular,
  }) async {
    final topic = _cmdVel;
    if (topic == null || !isConnected) return;
    final msg = <String, dynamic>{
      'linear': {'x': linear, 'y': 0.0, 'z': 0.0},
      'angular': {'x': 0.0, 'y': 0.0, 'z': angular},
    };
    try {
      await topic.publish(msg);
    } catch (e) {
      debugPrint('[RobotService] publish failed: $e');
      _handleDrop();
    }
  }

  /// Send a zero-velocity Twist to halt the robot.
  Future<void> stop() => drive(linear: 0, angular: 0);

  /// Tear down the connection and stop auto-reconnecting.
  Future<void> dispose() async {
    _disposed = true;
    _keepAlive = false;
    _reconnectTimer?.cancel();
    _signalTimer?.cancel();
    try {
      // Best-effort stop before closing the link.
      await stop();
      await _odom?.unsubscribe();
      await _voltage?.unsubscribe();
      await _batteryState?.unsubscribe();
      await _cmdVel?.unadvertise();
      await _ros?.close();
    } catch (e) {
      debugPrint('[RobotService] dispose error: $e');
    }
    _cmdVel = null;
    _odom = null;
    _voltage = null;
    _batteryState = null;
    _ros = null;
    if (!_stateCtrl.isClosed) {
      await _stateCtrl.close();
    }
    if (!_telemetryCtrl.isClosed) {
      await _telemetryCtrl.close();
    }
  }
}
