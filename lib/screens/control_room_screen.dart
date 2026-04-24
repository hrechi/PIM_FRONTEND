import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/color_palette.dart';
import '../theme/text_styles.dart';

class ControlRoomScreen extends StatefulWidget {
  const ControlRoomScreen({super.key});

  @override
  State<ControlRoomScreen> createState() => _ControlRoomScreenState();
}

class _ControlRoomScreenState extends State<ControlRoomScreen> {
  static const double _joystickRadius = 54;
  static const double _maxSpeed = 3.2;
  static const double _floatingPreviewThreshold = 220;

  Timer? _mockTimer;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _robotViewAnchorKey = GlobalKey();
  final GlobalKey _scrollViewportKey = GlobalKey();

  bool _showFloatingPreview = false;
  bool _previewDockingDisabled = false;

  bool _isConnected = true;
  double _batteryLevel = 88;
  int _signalStrength = 91;
  double _speed = 0;
  double _heading = 0;
  String _direction = 'Idle';
  Offset _joystickOffset = Offset.zero;
  String _lastDirectionLog = 'Idle';

  int _frameIndex = 0;
  DateTime _lastHeartbeat = DateTime.now();

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
    _mockTimer = Timer.periodic(const Duration(milliseconds: 900), (_) {
      if (!mounted) return;
      setState(() {
        _frameIndex++;
        _lastHeartbeat = DateTime.now();

        if (_isConnected) {
          _batteryLevel = (_batteryLevel - 0.08).clamp(10, 100);
          _signalStrength = 65 + (_frameIndex % 30);
        } else {
          _signalStrength = 0;
          _speed = 0;
        }
      });
    });
  }

  @override
  void dispose() {
    _mockTimer?.cancel();
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
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

  void _toggleConnection() {
    setState(() {
      _isConnected = !_isConnected;
      if (!_isConnected) {
        _speed = 0;
        _direction = 'Disconnected';
        _joystickOffset = Offset.zero;
      } else {
        _direction = 'Idle';
      }
      _appendEvent(
        _isConnected
            ? 'Robot link connected (mock)'
            : 'Robot link disconnected (mock)',
        _isConnected ? AppColorPalette.success : AppColorPalette.warning,
      );
    });
  }

  void _emergencyStop() {
    setState(() {
      _speed = 0;
      _joystickOffset = Offset.zero;
      _direction = 'Emergency stop';
      _appendEvent('Emergency stop executed', AppColorPalette.alertError);
    });
  }

  void _sendQuickCommand(String command) {
    if (!_isConnected) return;

    setState(() {
      switch (command) {
        case 'Forward':
          _speed = 1.8;
          _heading = 0;
          _direction = 'Forward';
          break;
        case 'Backward':
          _speed = 1.2;
          _heading = 180;
          _direction = 'Backward';
          break;
        case 'Left':
          _speed = 1;
          _heading = 270;
          _direction = 'Turning Left';
          break;
        case 'Right':
          _speed = 1;
          _heading = 90;
          _direction = 'Turning Right';
          break;
        case 'Hold':
          _speed = 0;
          _direction = 'Stationary';
          break;
      }

      _appendEvent('Command: $command', AppColorPalette.fieldFreshStart);
    });
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
        return;
      }

      final radians = math.atan2(_joystickOffset.dy, _joystickOffset.dx);
      final degrees = (radians * 180 / math.pi + 360) % 360;
      _heading = degrees;
      _direction = _directionFromHeading(_heading);

      if (_direction != _lastDirectionLog) {
        _appendEvent('Joystick: $_direction', AppColorPalette.info);
        _lastDirectionLog = _direction;
      }
    });
  }

  void _onJoystickPanEnd(DragEndDetails details) {
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
    final wave = (math.sin(_frameIndex / 3) + 1) / 2;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 10 : 14),
        gradient: LinearGradient(
          colors: [
            Color.lerp(
              AppColorPalette.robotTechStart,
              AppColorPalette.robotTechEnd,
              wave,
            )!,
            Color.lerp(
              AppColorPalette.charcoalGreen,
              AppColorPalette.darkGrey,
              1 - wave,
            )!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: EdgeInsets.all(compact ? 6 : 10),
              child: Text(
                'FRAME ${_frameIndex.toString().padLeft(4, '0')}',
                style: AppTextStyles.caption(
                  color: Colors.white.withValues(alpha: 0.9),
                ).copyWith(fontSize: compact ? 10 : 12),
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Icon(
              _isConnected
                  ? Icons.center_focus_strong_rounded
                  : Icons.videocam_off_rounded,
              size: compact ? 34 : 56,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: EdgeInsets.all(compact ? 6 : 10),
              child: Text(
                _isConnected
                    ? 'Heartbeat: ${_lastHeartbeat.hour.toString().padLeft(2, '0')}:${_lastHeartbeat.minute.toString().padLeft(2, '0')}:${_lastHeartbeat.second.toString().padLeft(2, '0')}'
                    : 'No signal',
                style: AppTextStyles.caption(
                  color: Colors.white.withValues(alpha: 0.9),
                ).copyWith(fontSize: compact ? 9 : 12),
              ),
            ),
          ),
        ],
      ),
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
    final commands = <_QuickCommand>[
      _QuickCommand('Forward', Icons.keyboard_arrow_up_rounded),
      _QuickCommand('Left', Icons.keyboard_arrow_left_rounded),
      _QuickCommand('Hold', Icons.pause_circle_outline_rounded),
      _QuickCommand('Right', Icons.keyboard_arrow_right_rounded),
      _QuickCommand('Backward', Icons.keyboard_arrow_down_rounded),
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
          Text(
            'Quick Commands',
            style: AppTextStyles.h4(color: AppColorPalette.charcoalGreen),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in commands)
                ElevatedButton.icon(
                  onPressed: _isConnected
                      ? () => _sendQuickCommand(item.label)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColorPalette.mistyBlue,
                    disabledBackgroundColor: AppColorPalette.lightGrey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(item.icon, size: 18),
                  label: Text(item.label),
                ),
              ElevatedButton.icon(
                onPressed: _emergencyStop,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColorPalette.alertError,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.stop_circle_rounded, size: 18),
                label: const Text('Emergency Stop'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryGrid() {
    final cards = <_MetricData>[
      _MetricData(
        label: 'Battery',
        value: '${_batteryLevel.toStringAsFixed(1)} %',
        icon: Icons.battery_full_rounded,
        color: _batteryLevel > 35
            ? AppColorPalette.success
            : AppColorPalette.warning,
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
                'Mock data',
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

class _QuickCommand {
  const _QuickCommand(this.label, this.icon);

  final String label;
  final IconData icon;
}
