import 'dart:async';

import 'package:flutter/material.dart';

import '../services/robot_service.dart';

/// Hold-to-drive control.
///
/// Pattern (the comment is here because the timer dance isn't obvious):
///  1. `onPointerDown` starts a periodic 50 ms timer (≈ 20 Hz). Each tick
///     re-publishes the same Twist on `/cmd_vel`. Re-publishing matters
///     because rosbridge / robots typically apply a watchdog that halts the
///     wheels if no command arrives within ~100–500 ms.
///  2. `onPointerUp` / `onPointerCancel` cancels the timer and immediately
///     sends a zero Twist via `RobotService.stop()` so the robot halts the
///     instant the operator lifts their finger — even if a tick was about
///     to fire.
///  3. We also fire one immediate `drive()` on press so there's no perceived
///     latency before the first tick.
class DriveButton extends StatefulWidget {
  const DriveButton({
    super.key,
    required this.robot,
    required this.linear,
    required this.angular,
    required this.icon,
    this.label,
    this.onCommandSent,
    this.size = 72,
    this.color,
    this.disabledColor,
    this.tickInterval = const Duration(milliseconds: 50),
  });

  final RobotService robot;
  final double linear;
  final double angular;
  final IconData icon;
  final String? label;

  /// Optional callback invoked once per press (not per tick) — useful for
  /// audit logging without spamming the backend at 20 Hz.
  final void Function(double linear, double angular)? onCommandSent;

  final double size;
  final Color? color;
  final Color? disabledColor;
  final Duration tickInterval;

  @override
  State<DriveButton> createState() => _DriveButtonState();
}

class _DriveButtonState extends State<DriveButton> {
  Timer? _ticker;
  bool _pressed = false;

  void _start() {
    if (_pressed) return;
    _pressed = true;
    if (mounted) setState(() {});

    // Immediate publish for snappy response.
    widget.robot.drive(linear: widget.linear, angular: widget.angular);
    widget.onCommandSent?.call(widget.linear, widget.angular);

    _ticker?.cancel();
    _ticker = Timer.periodic(widget.tickInterval, (_) {
      widget.robot.drive(linear: widget.linear, angular: widget.angular);
    });
  }

  void _stop() {
    if (!_pressed) return;
    _pressed = false;
    _ticker?.cancel();
    _ticker = null;
    widget.robot.stop();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ticker?.cancel();
    // Defensive stop: if the widget is torn down mid-press, halt the robot.
    if (_pressed) {
      widget.robot.stop();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = widget.color ?? theme.colorScheme.primary;
    final idleColor = widget.disabledColor ?? activeColor.withValues(alpha: 0.85);
    final bg = _pressed ? activeColor : idleColor;

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => _start(),
      onPointerUp: (_) => _stop(),
      onPointerCancel: (_) => _stop(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(widget.size * 0.22),
          boxShadow: _pressed
              ? null
              : [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, color: Colors.white, size: widget.size * 0.5),
            if (widget.label != null) ...[
              const SizedBox(height: 2),
              Text(
                widget.label!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
