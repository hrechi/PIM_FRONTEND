import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/global_voice_controller.dart';
import '../providers/voice_access_mode_provider.dart';

class GlobalVoiceFab extends StatefulWidget {
  const GlobalVoiceFab({super.key});

  @override
  State<GlobalVoiceFab> createState() => _GlobalVoiceFabState();
}

class _GlobalVoiceFabState extends State<GlobalVoiceFab> {
  static const double _fabSize = 62;
  static const double _horizontalMargin = 12;
  static const double _topMargin = 12;
  static const double _bottomMargin = 20;

  Offset? _position;
  Offset? _dragStartGlobal;
  Offset? _positionAtDragStart;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    return Consumer3<AuthProvider, VoiceAccessModeProvider, GlobalVoiceController>(
      builder: (context, auth, accessMode, voice, _) {
        if (!auth.isAuthenticated || !accessMode.isEnabled) {
          _position = null;
          return const SizedBox.shrink();
        }

        return SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableSize = Size(
                constraints.maxWidth,
                constraints.maxHeight,
              );

              _position ??= Offset(
                _horizontalMargin,
                (availableSize.height - _fabSize - _bottomMargin)
                    .clamp(_topMargin, availableSize.height),
              );

              final clampedPosition = _clampPosition(_position!, availableSize);
              _position = clampedPosition;

              final icon = _iconForState(voice.state);
              final color = _colorForState(voice.state);
              final isLoading = voice.state == GlobalVoiceState.processing;
              final isListening = voice.state == GlobalVoiceState.listening;
              final transcript = voice.liveTranscript.trim();

              return Stack(
                children: [
                  Positioned(
                    left: clampedPosition.dx,
                    top: clampedPosition.dy,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isListening)
                          Container(
                            constraints: const BoxConstraints(maxWidth: 220),
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFF1F6FEB).withValues(alpha: 0.28),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Text(
                              transcript.isEmpty ? 'Listening...' : transcript,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        GestureDetector(
                          onLongPressStart: (details) {
                            _isDragging = true;
                            _dragStartGlobal = details.globalPosition;
                            _positionAtDragStart = _position;
                          },
                          onLongPressMoveUpdate: (details) {
                            if (!_isDragging ||
                                _dragStartGlobal == null ||
                                _positionAtDragStart == null) {
                              return;
                            }

                            final delta = details.globalPosition - _dragStartGlobal!;
                            final nextPosition = _positionAtDragStart! + delta;
                            setState(() {
                              _position = _clampPosition(nextPosition, availableSize);
                            });
                          },
                          onLongPressEnd: (_) {
                            _isDragging = false;
                            _dragStartGlobal = null;
                            _positionAtDragStart = null;
                          },
                          child: SizedBox(
                            width: _fabSize,
                            height: _fabSize,
                            child: FloatingActionButton(
                              heroTag: 'global_voice_fab',
                              backgroundColor: color,
                              onPressed: isLoading ? null : voice.onMicPressed,
                              child: isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Icon(icon, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Offset _clampPosition(Offset position, Size size) {
    final maxX = (size.width - _fabSize - _horizontalMargin)
        .clamp(_horizontalMargin, size.width);
    final maxY = (size.height - _fabSize - _bottomMargin)
        .clamp(_topMargin, size.height);

    return Offset(
      position.dx.clamp(_horizontalMargin, maxX).toDouble(),
      position.dy.clamp(_topMargin, maxY).toDouble(),
    );
  }

  IconData _iconForState(GlobalVoiceState state) {
    switch (state) {
      case GlobalVoiceState.listening:
        return Icons.stop_rounded;
      case GlobalVoiceState.processing:
        return Icons.sync_rounded;
      case GlobalVoiceState.speaking:
        return Icons.volume_up_rounded;
      case GlobalVoiceState.error:
        return Icons.error_outline_rounded;
      case GlobalVoiceState.idle:
        return Icons.mic_rounded;
    }
  }

  Color _colorForState(GlobalVoiceState state) {
    switch (state) {
      case GlobalVoiceState.listening:
        return const Color(0xFF2EC4B6);
      case GlobalVoiceState.processing:
        return const Color(0xFF4D96FF);
      case GlobalVoiceState.speaking:
        return const Color(0xFF6BCB77);
      case GlobalVoiceState.error:
        return const Color(0xFFE53935);
      case GlobalVoiceState.idle:
        return const Color(0xFF1F6FEB);
    }
  }
}
