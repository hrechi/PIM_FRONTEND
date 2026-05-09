import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:roslibdart/roslibdart.dart';

/// Connection state of the underlying rosbridge WebSocket.
enum RobotConnectionState { disconnected, connecting, connected }

/// Single 360° (or partial-arc) laser scan from `sensor_msgs/LaserScan`.
@immutable
class RobotLaserScan {
  const RobotLaserScan({
    required this.ranges,
    required this.angleMin,
    required this.angleMax,
    required this.angleIncrement,
    required this.rangeMin,
    required this.rangeMax,
    required this.timestamp,
  });

  /// Distances in metres. NaN/Inf means "no return". Length matches the
  /// number of beams the sensor reported.
  final List<double> ranges;
  final double angleMin; // rad
  final double angleMax; // rad
  final double angleIncrement; // rad per beam
  final double rangeMin; // m
  final double rangeMax; // m
  final DateTime timestamp;

  int get beamCount => ranges.length;

  /// Smallest valid range inside the forward cone of half-width [coneRad].
  /// Returns null if no beam in the cone is valid (between rangeMin/Max).
  double? minRangeInCone(double coneRad) {
    double? best;
    for (var i = 0; i < ranges.length; i++) {
      final angle = angleMin + i * angleIncrement;
      // Normalise to (-pi, pi].
      final a = math.atan2(math.sin(angle), math.cos(angle));
      if (a.abs() > coneRad) continue;
      final r = ranges[i];
      if (!r.isFinite) continue;
      if (r < rangeMin || r > rangeMax) continue;
      if (best == null || r < best) best = r;
    }
    return best;
  }
}

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
    this.scanTopic = '/scan',
    this.batteryFullVolts = 12.6,
    this.batteryEmptyVolts = 9.5,
    this.safetyStopDistance = 0.30,
    this.safetyConeRad = math.pi / 6, // ±30°
  });

  final String robotIp;
  final int rosbridgePort;
  final String cmdVelTopic;
  final String odomTopic;
  final String voltageTopic;
  final String batteryStateTopic;
  final String scanTopic;
  final double batteryFullVolts;
  final double batteryEmptyVolts;

  /// Trigger an automatic stop when any beam in the forward cone is closer
  /// than this many metres for [_safetyStopRequiredHits] consecutive scans.
  final double safetyStopDistance;
  final double safetyConeRad;
  static const int _safetyStopRequiredHits = 2;

  Ros? _ros;
  Topic? _cmdVel;
  Topic? _odom;
  Topic? _voltage;
  Topic? _batteryState;
  Topic? _scan;
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
  final StreamController<RobotLaserScan> _scanCtrl =
      StreamController<RobotLaserScan>.broadcast();
  final StreamController<RobotSafetyEvent> _safetyCtrl =
      StreamController<RobotSafetyEvent>.broadcast();
  RobotConnectionState _state = RobotConnectionState.disconnected;
  RobotTelemetry _telemetry = const RobotTelemetry();
  RobotLaserScan? _lastScan;
  int _safetyHitStreak = 0;
  double _lastCommandedLinear = 0;
  double _lastCommandedAngular = 0;
  bool _safetyTripped = false;
  bool _loggedFirstScan = false;

  /// Live stream of connection state changes.
  Stream<RobotConnectionState> get connectionState => _stateCtrl.stream;

  /// Live telemetry stream (battery, odom-derived speed/heading, signal).
  Stream<RobotTelemetry> get telemetryStream => _telemetryCtrl.stream;

  /// Live `sensor_msgs/LaserScan` stream.
  Stream<RobotLaserScan> get scanStream => _scanCtrl.stream;

  /// Fires when the forward-cone safety monitor stops the robot.
  Stream<RobotSafetyEvent> get safetyStream => _safetyCtrl.stream;

  /// Most recent scan (null until the first packet arrives).
  RobotLaserScan? get lastScan => _lastScan;

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

      final scan = Topic(
        ros: ros,
        name: scanTopic,
        type: 'sensor_msgs/LaserScan',
        reconnectOnClose: true,
        queueLength: 1,
        queueSize: 1,
        throttleRate: 100, // 10 Hz is plenty for radar UI + safety.
      );
      unawaited(scan.subscribe(_handleScan));

      _ros = ros;
      _cmdVel = cmdVel;
      _odom = odom;
      _voltage = voltage;
      _batteryState = batteryState;
      _scan = scan;
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
    _scan = null;
    _ros = null;
    _safetyHitStreak = 0;
    _safetyTripped = false;
    _loggedFirstScan = false;
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
    // Block forward motion while the safety monitor has tripped. Reverse and
    // pure-rotation commands are still allowed so the operator can back away.
    if (_safetyTripped && linear > 0) {
      _lastCommandedLinear = 0;
      _lastCommandedAngular = angular;
      try {
        await topic.publish(<String, dynamic>{
          'linear': {'x': 0.0, 'y': 0.0, 'z': 0.0},
          'angular': {'x': 0.0, 'y': 0.0, 'z': angular},
        });
      } catch (_) {}
      return;
    }
    _lastCommandedLinear = linear;
    _lastCommandedAngular = angular;
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
  Future<void> stop() {
    _lastCommandedLinear = 0;
    _lastCommandedAngular = 0;
    return drive(linear: 0, angular: 0);
  }

  /// Manually clear the safety latch — operator confirms the path is clear.
  void clearSafetyLatch() {
    if (_safetyTripped) {
      _safetyTripped = false;
      _safetyHitStreak = 0;
      if (!_safetyCtrl.isClosed) {
        _safetyCtrl.add(const RobotSafetyEvent.cleared());
      }
    }
  }

  Future<void> _handleScan(Map<String, dynamic> msg) async {
    if (!_loggedFirstScan) {
      _loggedFirstScan = true;
      debugPrint('[RobotService] first $scanTopic packet received');
    }
    try {
      final rangesRaw = msg['ranges'] as List?;
      if (rangesRaw == null) return;
      final ranges = List<double>.generate(rangesRaw.length, (i) {
        final v = rangesRaw[i];
        if (v is num) return v.toDouble();
        return double.nan;
      }, growable: false);
      final scan = RobotLaserScan(
        ranges: ranges,
        angleMin: (msg['angle_min'] as num?)?.toDouble() ?? -math.pi,
        angleMax: (msg['angle_max'] as num?)?.toDouble() ?? math.pi,
        angleIncrement:
            (msg['angle_increment'] as num?)?.toDouble() ??
                (2 * math.pi / ranges.length),
        rangeMin: (msg['range_min'] as num?)?.toDouble() ?? 0.05,
        rangeMax: (msg['range_max'] as num?)?.toDouble() ?? 12.0,
        timestamp: DateTime.now(),
      );
      _lastScan = scan;
      if (!_scanCtrl.isClosed) _scanCtrl.add(scan);
      _evaluateSafety(scan);
    } catch (e) {
      debugPrint('[RobotService] scan parse failed: $e');
    }
  }

  void _evaluateSafety(RobotLaserScan scan) {
    // Only intervene when the operator is requesting forward motion.
    if (_lastCommandedLinear <= 0.02) {
      _safetyHitStreak = 0;
      return;
    }
    final closest = scan.minRangeInCone(safetyConeRad);
    if (closest == null) return;
    if (closest < safetyStopDistance) {
      _safetyHitStreak += 1;
      if (_safetyHitStreak >= _safetyStopRequiredHits && !_safetyTripped) {
        _safetyTripped = true;
        debugPrint(
          '[RobotService] safety stop: obstacle ${(closest * 100).round()}cm',
        );
        // Triple-publish a zero Twist to be sure it lands.
        final topic = _cmdVel;
        if (topic != null) {
          final stopMsg = <String, dynamic>{
            'linear': {'x': 0.0, 'y': 0.0, 'z': 0.0},
            'angular': {'x': 0.0, 'y': 0.0, 'z': 0.0},
          };
          for (var i = 0; i < 3; i++) {
            unawaited(topic.publish(stopMsg).catchError((_) {}));
          }
        }
        _lastCommandedLinear = 0;
        if (!_safetyCtrl.isClosed) {
          _safetyCtrl.add(RobotSafetyEvent.tripped(distanceMeters: closest));
        }
      }
    } else {
      _safetyHitStreak = 0;
    }
  }

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
      await _scan?.unsubscribe();
      await _cmdVel?.unadvertise();
      await _ros?.close();
    } catch (e) {
      debugPrint('[RobotService] dispose error: $e');
    }
    _cmdVel = null;
    _odom = null;
    _voltage = null;
    _batteryState = null;
    _scan = null;
    _ros = null;
    if (!_stateCtrl.isClosed) {
      await _stateCtrl.close();
    }
    if (!_telemetryCtrl.isClosed) {
      await _telemetryCtrl.close();
    }
    if (!_scanCtrl.isClosed) {
      await _scanCtrl.close();
    }
    if (!_safetyCtrl.isClosed) {
      await _safetyCtrl.close();
    }
  }
}

/// Notification emitted when the forward-cone safety monitor trips/clears.
@immutable
class RobotSafetyEvent {
  const RobotSafetyEvent.tripped({required this.distanceMeters})
      : tripped = true;
  const RobotSafetyEvent.cleared()
      : tripped = false,
        distanceMeters = null;

  final bool tripped;
  final double? distanceMeters;
}
