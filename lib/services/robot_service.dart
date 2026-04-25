import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:roslibdart/roslibdart.dart';

/// Connection state of the underlying rosbridge WebSocket.
enum RobotConnectionState { disconnected, connecting, connected }

/// Thin wrapper around `roslibdart` that:
///  - opens a WebSocket to a robot's rosbridge server
///  - advertises and publishes `geometry_msgs/Twist` on `/cmd_vel`
///  - exposes a connection-state stream the UI can listen to
///  - auto-reconnects with a small backoff while [_keepAlive] is true
///
/// Designed to be created once per Control Room screen and disposed cleanly
/// when the screen is left.
class RobotService {
  RobotService({
    required this.robotIp,
    this.rosbridgePort = 9090,
    this.cmdVelTopic = '/cmd_vel',
  });

  final String robotIp;
  final int rosbridgePort;
  final String cmdVelTopic;

  Ros? _ros;
  Topic? _cmdVel;

  bool _keepAlive = false;
  bool _disposed = false;
  Timer? _reconnectTimer;

  final StreamController<RobotConnectionState> _stateCtrl =
      StreamController<RobotConnectionState>.broadcast();
  RobotConnectionState _state = RobotConnectionState.disconnected;

  /// Live stream of connection state changes.
  Stream<RobotConnectionState> get connectionState => _stateCtrl.stream;

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

      _ros = ros;
      _cmdVel = cmdVel;
      _emit(RobotConnectionState.connected);
    } catch (e, st) {
      debugPrint('[RobotService] connect failed: $e\n$st');
      _handleDrop();
    }
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
    _ros = null;
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
    try {
      // Best-effort stop before closing the link.
      await stop();
      await _cmdVel?.unadvertise();
      await _ros?.close();
    } catch (e) {
      debugPrint('[RobotService] dispose error: $e');
    }
    _cmdVel = null;
    _ros = null;
    if (!_stateCtrl.isClosed) {
      await _stateCtrl.close();
    }
  }
}
