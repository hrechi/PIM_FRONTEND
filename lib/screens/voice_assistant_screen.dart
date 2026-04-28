import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/voice_access_mode_provider.dart';
import '../services/chat_service.dart';
import '../services/robot_voice_controller.dart';
import '../services/voice_navigation_service.dart';
import '../services/voice_service.dart';
import '../utils/constants.dart';

class VoiceAssistantScreen extends StatefulWidget {
  const VoiceAssistantScreen({
    super.key,
    this.conversationId,
  });

  final String? conversationId;

  @override
  State<VoiceAssistantScreen> createState() => _VoiceAssistantScreenState();
}

enum VoiceUiState {
  idle,
  listening,
  processing,
  speaking,
  error,
}

enum VoiceLanguageMode {
  auto,
  arTN,
  frFR,
  enUS,
}

class _VoiceAssistantScreenState extends State<VoiceAssistantScreen>
    with TickerProviderStateMixin {
  final VoiceService _voiceService = VoiceService();

  late final AnimationController _pulseController;
  late final AnimationController _spinController;

  String? _conversationId;
  VoiceUiState _state = VoiceUiState.idle;
  String _transcript = '';
  String _assistantReply = '';
  String _statusText = 'Tap the bubble to start listening';
  bool _showStillThinking = false;
  bool _isInitializing = true;
  double _soundLevel = 0;
  bool _manualStopRequested = false;
  bool _isRestartingListening = false;
  VoiceLanguageMode _languageMode = VoiceLanguageMode.auto;
  String? _activeListeningLocale;
  String _activeReplyLanguage = 'en-US';
  bool _isFullAccessEnabled = false;

  Timer? _thinkingTimer;

  static const Map<VoiceLanguageMode, String> _languageCodeByMode = {
    VoiceLanguageMode.auto: 'auto',
    VoiceLanguageMode.arTN: 'ar-TN',
    VoiceLanguageMode.frFR: 'fr-FR',
    VoiceLanguageMode.enUS: 'en-US',
  };

  @override
  void initState() {
    super.initState();
    _conversationId = widget.conversationId;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _loadFullAccessMode();
    _initializeVoice();
  }

  Future<void> _loadFullAccessMode() async {
    final accessMode = context.read<VoiceAccessModeProvider>();
    if (!accessMode.isLoaded) {
      await accessMode.load();
    }

    final enabled = accessMode.isEnabled;
    if (!mounted) return;

    setState(() {
      _isFullAccessEnabled = enabled;
      if (_state == VoiceUiState.idle) {
        _statusText = _idleStatusText();
      }
    });
  }

  Future<void> _initializeVoice() async {
    try {
      await _voiceService.initialize(
        onStatus: (status) {
          if (!mounted) return;
          if (status == 'notListening' && _state == VoiceUiState.listening) {
            if (_manualStopRequested) {
              _manualStopRequested = false;
              return;
            }

            _resumeListeningAfterSilence();
          }
        },
        onError: (error) {
          if (!mounted) return;

          if (
            _state == VoiceUiState.listening &&
            _isRecoverableListeningError(error)
          ) {
            setState(() {
              _statusText = _listeningStatusText();
            });
            _resumeListeningAfterSilence();
            return;
          }

          setState(() {
            _state = VoiceUiState.error;
            _statusText = error;
          });
          _pulseController.stop();
          _spinController.stop();
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = VoiceUiState.error;
        _statusText = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  Future<void> _onBubblePressed() async {
    if (_isInitializing || _state == VoiceUiState.processing) {
      return;
    }

    if (_state == VoiceUiState.speaking) {
      await _voiceService.stopSpeaking();
      if (!mounted) return;
      setState(() {
        _state = VoiceUiState.idle;
        _statusText = _idleStatusText();
      });
      return;
    }

    if (_state == VoiceUiState.listening) {
      await _stopAndProcess();
      return;
    }

    await _startListening();
  }

  Future<void> _startListening() async {
    try {
      await _voiceService.stopSpeaking();
      _manualStopRequested = false;
      final selectedMode = _languageMode;
      final preferredLocale = _languageCodeByMode[selectedMode] ?? 'en-US';
      final localeForListening =
          selectedMode == VoiceLanguageMode.auto ? null : preferredLocale;

      _activeListeningLocale = localeForListening;

      await _startSpeechCapture(
        clearTranscript: true,
        localeId: localeForListening,
      );

      if (!mounted) return;
      setState(() {
        _state = VoiceUiState.listening;
        _statusText = _listeningStatusText();
        _assistantReply = '';
        _showStillThinking = false;
        _soundLevel = 0;
      });
      _spinController.stop();
      _pulseController.repeat(reverse: true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = VoiceUiState.error;
        _statusText = e.toString();
      });
    }
  }

  Future<void> _startSpeechCapture({
    bool clearTranscript = false,
    String? localeId,
  }) async {
    final usedLocale = await _voiceService.startListening(
      onResult: (transcript, _) {
        if (!mounted) return;
        setState(() {
          _transcript = transcript;
        });
      },
      onSoundLevelChange: (level) {
        if (!mounted) return;
        setState(() {
          _soundLevel = _normalizeSoundLevel(level);
        });
      },
      localeId: localeId,
    );

    _activeListeningLocale = usedLocale ?? localeId ?? _activeListeningLocale;

    if (!mounted) return;
    if (clearTranscript) {
      setState(() {
        _transcript = '';
      });
    }
  }

  Future<void> _resumeListeningAfterSilence() async {
    if (_isRestartingListening || _state != VoiceUiState.listening) {
      return;
    }

    _isRestartingListening = true;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 220));
      if (!mounted || _state != VoiceUiState.listening || _manualStopRequested) {
        return;
      }

      await _startSpeechCapture(localeId: _activeListeningLocale);
      if (!mounted) return;
      setState(() {
        _statusText = _listeningStatusText();
      });
      _pulseController.repeat(reverse: true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _statusText = _listeningStatusText();
      });

      // Keep trying silently so listening feels continuous.
      Future<void>.delayed(const Duration(milliseconds: 450), () {
        if (!mounted || _state != VoiceUiState.listening || _manualStopRequested) {
          return;
        }
        _resumeListeningAfterSilence();
      });
    } finally {
      _isRestartingListening = false;
    }
  }

  bool _isRecoverableListeningError(String error) {
    final normalized = error.toLowerCase();

    return normalized.contains('timeout') ||
        normalized.contains('error_speech_timeout') ||
        normalized.contains('error_no_match') ||
        normalized.contains('no match') ||
        normalized.contains('speech timeout') ||
        normalized.contains('no speech input');
  }

  String _languageLabel(VoiceLanguageMode mode) {
    switch (mode) {
      case VoiceLanguageMode.auto:
        return 'Auto';
      case VoiceLanguageMode.arTN:
        return 'Arabic (TN)';
      case VoiceLanguageMode.frFR:
        return 'French';
      case VoiceLanguageMode.enUS:
        return 'English';
    }
  }

  String _detectLanguageFromTranscript(String transcript) {
    final text = transcript.trim();
    if (text.isEmpty) {
      return 'en-US';
    }

    if (RegExp(r'[\u0600-\u06FF]').hasMatch(text)) {
      return 'ar-TN';
    }

    final arabiziHints = RegExp(
      r'\b(chnowa|chnoua|barsha|barcha|mouch|msh|ya3ni|inshallah|inchallah|salam|marhba|labes|behi|3lech|3la|3lik|3andi|3andek|allah)\b',
      caseSensitive: false,
    );
    final arabiziToken = RegExp(r'\b[a-z]{2,}[2356789][a-z0-9]*\b', caseSensitive: false);
    if (arabiziHints.hasMatch(text) || arabiziToken.hasMatch(text)) {
      return 'ar-TN';
    }

    final frenchHints = RegExp(
      r"[éèêëàâîïôùûüçœ]|\b(merci|bonjour|salut|aujourd'hui|demain|champ|ferme|mission|irrigation)\b",
      caseSensitive: false,
    );
    if (frenchHints.hasMatch(text)) {
      return 'fr-FR';
    }

    return 'en-US';
  }

  bool _hasArabicScript(String text) {
    return RegExp(r'[\u0600-\u06FF]').hasMatch(text);
  }

  String _normalizeLanguageCode(String code) {
    final normalized = code.trim().toLowerCase().replaceAll('_', '-');
    if (normalized == 'ar-tn') return 'ar-TN';
    if (normalized == 'ar-sa') return 'ar-SA';
    if (normalized == 'fr-fr') return 'fr-FR';
    if (normalized == 'en-us') return 'en-US';
    if (normalized.startsWith('ar')) return 'ar-TN';
    if (normalized.startsWith('fr')) return 'fr-FR';
    if (normalized.startsWith('en')) return 'en-US';
    return 'en-US';
  }

  String _resolveRequestedLanguageCode(String transcript) {
    final selectedMode = _languageMode;

    if (selectedMode == VoiceLanguageMode.auto) {
      final detected = _detectLanguageFromTranscript(transcript);
      return _normalizeLanguageCode(detected);
    }

    final configured = _languageCodeByMode[selectedMode] ?? 'en-US';
    return _normalizeLanguageCode(configured);
  }

  String _listeningStatusText() {
    final selectedMode = _languageMode;
    final modeHint = _isFullAccessEnabled ? ' Full access is ON.' : '';
    if (selectedMode == VoiceLanguageMode.auto) {
      return 'Listening (auto detect)... tap again when you are done$modeHint';
    }

    return 'Listening in ${_languageLabel(selectedMode)}... tap again when you are done$modeHint';
  }

  String _idleStatusText() {
    if (_isFullAccessEnabled) {
      return 'Full access mode is ON. Say "open" followed by a page name.';
    }

    return 'Tap the bubble to start listening';
  }

  Future<void> _setFullAccessEnabled(bool enabled) async {
    await context.read<VoiceAccessModeProvider>().setEnabled(enabled);
    if (!mounted) return;

    setState(() {
      _isFullAccessEnabled = enabled;
    });
  }

  Future<void> _speakLocalFeedback({
    required String message,
    required String transcript,
  }) async {
    final requestedLanguageCode = _resolveRequestedLanguageCode(transcript);

    if (!mounted) return;
    setState(() {
      _assistantReply = message;
      _activeReplyLanguage = requestedLanguageCode;
      _state = VoiceUiState.speaking;
      _statusText = 'Speaking response...';
      _showStillThinking = false;
      _soundLevel = 0;
    });

    await _voiceService.speak(
      message,
      languageCode: requestedLanguageCode,
    );

    if (!mounted) return;
    setState(() {
      _state = VoiceUiState.idle;
      _statusText = _idleStatusText();
      _soundLevel = 0;
    });
  }

  Future<bool> _handleLocalVoiceCommand(String transcript) async {
    final command = VoiceNavigationService.parse(transcript);
    switch (command.type) {
      case VoiceCommandType.none:
        return false;
      case VoiceCommandType.activateFullAccess:
        await _setFullAccessEnabled(true);
        await _speakLocalFeedback(
          message:
              'Full access mode enabled. You can now say open followed by any page name.',
          transcript: transcript,
        );
        return true;
      case VoiceCommandType.deactivateFullAccess:
        await _setFullAccessEnabled(false);
        await _speakLocalFeedback(
          message: 'Full access mode disabled.',
          transcript: transcript,
        );
        return true;
      case VoiceCommandType.navigate:
        if (!_isFullAccessEnabled) {
          await _speakLocalFeedback(
            message:
                'Full access mode is currently off. Say give me full access first.',
            transcript: transcript,
          );
          return true;
        }

        final page = command.page;
        if (page == null) {
          return true;
        }

        final label = VoiceNavigationService.labelForPage(page);
        VoiceNavigationService.navigateToPage(context, page);
        await _speakLocalFeedback(
          message: 'Opening $label.',
          transcript: transcript,
        );
        return true;
      case VoiceCommandType.unknownNavigate:
        if (!_isFullAccessEnabled) {
          await _speakLocalFeedback(
            message:
                'I heard a navigation request, but full access mode is off. Say give me full access first.',
            transcript: transcript,
          );
          return true;
        }

        final suggestions = command.suggestions;
        final suggestionText = suggestions.isEmpty
            ? ''
            : ' Try: ${suggestions.join(', ')}.';
        await _speakLocalFeedback(
          message:
              'I could not find that page in the app.$suggestionText',
          transcript: transcript,
        );
        return true;
      case VoiceCommandType.robotCommand:
        return _handleRobotVoiceCommand(command, transcript);
    }
  }

  Future<bool> _handleRobotVoiceCommand(
    VoiceCommandResult command,
    String transcript,
  ) async {
    if (!_isFullAccessEnabled) {
      await _speakLocalFeedback(
        message:
            'I heard a robot command, but full access mode is off. Say give me full access first.',
        transcript: transcript,
      );
      return true;
    }

    final action = command.robotAction;
    if (action == null) return true;

    final controller = RobotVoiceController.instance;

    // Stop is highest-priority and must work even if we never connected.
    if (action == RobotVoiceAction.stop) {
      final ok = await controller.emergencyStop();
      await _speakLocalFeedback(
        message: ok
            ? 'Emergency stop sent.'
            : 'No robot is connected, but I tried to send a stop anyway.',
        transcript: transcript,
      );
      return true;
    }

    final connected = await controller.ensureConnected();
    if (!connected) {
      await _speakLocalFeedback(
        message:
            'I cannot reach the robot right now. Please check that it is online and try again.',
        transcript: transcript,
      );
      return true;
    }

    bool dispatched = false;
    String spoken = '';
    switch (action) {
      case RobotVoiceAction.forward:
        dispatched = await controller.moveForward();
        spoken = 'Moving forward.';
        break;
      case RobotVoiceAction.backward:
        dispatched = await controller.moveBackward();
        spoken = 'Moving backward.';
        break;
      case RobotVoiceAction.left:
        dispatched = await controller.turnLeft();
        spoken = 'Turning left.';
        break;
      case RobotVoiceAction.right:
        dispatched = await controller.turnRight();
        spoken = 'Turning right.';
        break;
      case RobotVoiceAction.distance:
        final meters = command.distanceMeters ?? 0;
        dispatched = await controller.driveDistance(meters: meters);
        final cm = (meters.abs() * 100).round();
        final dir = meters >= 0 ? 'forward' : 'backward';
        spoken = 'Driving $dir for $cm centimeters.';
        break;
      case RobotVoiceAction.stop:
        // handled above
        break;
    }

    await _speakLocalFeedback(
      message: dispatched
          ? spoken
          : 'The robot did not accept the command. Please try again.',
      transcript: transcript,
    );
    return true;
  }

  Future<void> _discardListening() async {
    _manualStopRequested = true;
    await _voiceService.stopListening();
    _pulseController.stop();

    if (!mounted) return;
    setState(() {
      _state = VoiceUiState.idle;
      _transcript = '';
      _statusText = 'Recording discarded. Tap the bubble to listen again.';
      _soundLevel = 0;
      _showStillThinking = false;
    });
  }

  Future<void> _stopAndProcess() async {
    _manualStopRequested = true;
    final stoppedTranscript = await _voiceService.stopListening();
    _pulseController.stop();

    if (!mounted) return;

    final transcript = stoppedTranscript.trim().isNotEmpty
        ? stoppedTranscript.trim()
        : _transcript.trim();

    if (transcript.isEmpty) {
      setState(() {
        _state = VoiceUiState.idle;
        _statusText = 'No speech detected. Tap and try again.';
        _soundLevel = 0;
      });
      return;
    }

    if (_languageMode == VoiceLanguageMode.arTN &&
        !_hasArabicScript(transcript)) {
      setState(() {
        _state = VoiceUiState.error;
        _statusText =
            'Arabic transcription is not coming as Arabic script. Please enable/download Arabic speech recognition on your device and try again.';
        _soundLevel = 0;
      });
      return;
    }

    if (await _handleLocalVoiceCommand(transcript)) {
      return;
    }

    setState(() {
      _transcript = transcript;
      _state = VoiceUiState.processing;
      _statusText = 'Processing your request...';
      _showStillThinking = false;
      _soundLevel = 0;
    });

    _spinController.repeat();
    _thinkingTimer?.cancel();
    _thinkingTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      if (_state == VoiceUiState.processing) {
        setState(() {
          _showStillThinking = true;
        });
      }
    });

    try {
      final requestedLanguageCode = _resolveRequestedLanguageCode(transcript);

      final result = await ChatService.sendVoiceMessage(
        transcript,
        conversationId: _conversationId,
        languageCode: requestedLanguageCode,
      );

      final reply = (result['reply'] as String?)?.trim() ?? '';
      final nextConversationId = result['conversationId'] as String?;
      final returnedLanguageCode =
          (result['languageCode'] as String?)?.trim() ?? '';
      final replyLanguage = _normalizeLanguageCode(
        returnedLanguageCode.isNotEmpty
            ? returnedLanguageCode
            : requestedLanguageCode,
      );

      if (!mounted) return;

      setState(() {
        if (nextConversationId != null && nextConversationId.isNotEmpty) {
          _conversationId = nextConversationId;
        }
        _assistantReply = reply;
        _activeReplyLanguage = replyLanguage;
        _state = VoiceUiState.speaking;
        _statusText = 'Speaking response...';
        _showStillThinking = false;
        _soundLevel = 0;
      });

      await _voiceService.speak(
        reply,
        languageCode: replyLanguage,
      );

      if (!mounted) return;
      setState(() {
        _state = VoiceUiState.idle;
        _statusText = _idleStatusText();
        _soundLevel = 0;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = VoiceUiState.error;
        _statusText = 'Voice request failed: $e';
        _showStillThinking = false;
        _soundLevel = 0;
      });
    } finally {
      _thinkingTimer?.cancel();
      _spinController.stop();
    }
  }

  @override
  void dispose() {
    _thinkingTimer?.cancel();
    _pulseController.dispose();
    _spinController.dispose();
    _voiceService.dispose();
    super.dispose();
  }

  Color _bubbleColor() {
    switch (_state) {
      case VoiceUiState.listening:
        return const Color(0xFF2EC4B6);
      case VoiceUiState.processing:
        return const Color(0xFF4D96FF);
      case VoiceUiState.speaking:
        return const Color(0xFF6BCB77);
      case VoiceUiState.error:
        return AppColors.error;
      case VoiceUiState.idle:
        return AppColors.mistBlue;
    }
  }

  IconData _bubbleIcon() {
    switch (_state) {
      case VoiceUiState.listening:
        return Icons.graphic_eq_rounded;
      case VoiceUiState.processing:
        return Icons.sync_rounded;
      case VoiceUiState.speaking:
        return Icons.volume_up_rounded;
      case VoiceUiState.error:
        return Icons.error_outline_rounded;
      case VoiceUiState.idle:
        return Icons.mic_rounded;
    }
  }

  double _normalizeSoundLevel(double rawLevel) {
    if (rawLevel.isNaN || rawLevel.isInfinite || rawLevel <= 0) {
      return 0;
    }

    double normalized;
    if (rawLevel <= 1) {
      normalized = rawLevel;
    } else if (rawLevel <= 50) {
      normalized = rawLevel / 50;
    } else {
      normalized = 1;
    }

    return normalized.clamp(0.0, 1.0);
  }

  Widget _buildVoiceBubble() {
    return GestureDetector(
      onTap: _onBubblePressed,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _pulseController,
          _spinController,
        ]),
        builder: (context, child) {
          final pulse = _state == VoiceUiState.listening
              ? _pulseController.value
              : 0;
          final listeningBoost =
              _state == VoiceUiState.listening ? _soundLevel * 0.25 : 0;
          final coreScale = 1 + (pulse * 0.08) + listeningBoost;
          final ring1Scale = 1 + (pulse * 0.25) + (_soundLevel * 0.35);
          final ring2Scale = 1 + (pulse * 0.4) + (_soundLevel * 0.5);
          final rotation = _spinController.value * math.pi * 2;
          final bubbleColor = _bubbleColor();

          return SizedBox(
            width: 260,
            height: 260,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Transform.scale(
                  scale: ring2Scale,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: bubbleColor.withValues(
                        alpha: _state == VoiceUiState.listening ? 0.12 : 0.07,
                      ),
                    ),
                  ),
                ),
                Transform.scale(
                  scale: ring1Scale,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: bubbleColor.withValues(
                        alpha: _state == VoiceUiState.listening ? 0.2 : 0.1,
                      ),
                    ),
                  ),
                ),
                Transform.scale(
                  scale: coreScale,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          bubbleColor.withValues(alpha: 0.95),
                          bubbleColor.withValues(alpha: 0.65),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: bubbleColor.withValues(alpha: 0.35),
                          blurRadius: 30,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Transform.rotate(
                        angle:
                            _state == VoiceUiState.processing ? rotation : 0,
                        child: Icon(
                          _bubbleIcon(),
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTranscriptCard() {
    final displayText = _transcript.trim().isEmpty
        ? 'Your words will appear here...'
        : _transcript;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.mistBlue.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You said',
            style: TextStyle(
              color: Colors.black54,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            displayText,
            style: TextStyle(
              color: _transcript.trim().isEmpty
                  ? Colors.black45
                  : Colors.black87,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _displayLanguageCode(String code) {
    final normalized = _normalizeLanguageCode(code);
    if (normalized == 'ar-TN') return 'Arabic (TN)';
    if (normalized == 'ar-SA') return 'Arabic';
    if (normalized == 'fr-FR') return 'French';
    return 'English';
  }

  Widget _buildLanguageModeChip(VoiceLanguageMode mode) {
    final isSelected = _languageMode == mode;
    final isBusy =
        _state == VoiceUiState.listening || _state == VoiceUiState.processing;

    return ChoiceChip(
      label: Text(_languageLabel(mode)),
      selected: isSelected,
      onSelected: isBusy
          ? null
          : (selected) {
              if (!selected) return;
              setState(() {
                _languageMode = mode;
                _activeReplyLanguage =
                    mode == VoiceLanguageMode.auto
                        ? _activeReplyLanguage
                        : (_languageCodeByMode[mode] ?? 'en-US');
                _statusText = mode == VoiceLanguageMode.auto
                    ? 'Auto language detection enabled. Tap the bubble to start listening.'
                    : 'Language set to ${_languageLabel(mode)}. Tap the bubble to start listening.';
              });
            },
    );
  }

  Widget _buildLanguageSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Voice language',
          style: TextStyle(
            color: Colors.black54,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: VoiceLanguageMode.values
              .map(_buildLanguageModeChip)
              .toList(growable: false),
        ),
        const SizedBox(height: 6),
        Text(
          'Reply voice: ${_displayLanguageCode(_activeReplyLanguage)}',
          style: TextStyle(
            color: Colors.black45,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFullAccessModeCard() {
    final enabled = _isFullAccessEnabled;
    final bg = enabled
        ? const Color(0xFFDFF5E6)
        : const Color(0xFFFFF4DA);
    final border = enabled
        ? const Color(0xFF3E8E5B)
        : const Color(0xFFB5852E);
    final textColor = enabled
        ? const Color(0xFF1E5D39)
        : const Color(0xFF7A5717);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border.withValues(alpha: 0.7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                enabled ? Icons.lock_open_rounded : Icons.lock_outline_rounded,
                color: textColor,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                enabled ? 'Full Access: ON' : 'Full Access: OFF',
                style: TextStyle(
                  color: textColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Enable with: "give me full access"\nDisable with: "disable full access" or "exit full access mode"',
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F3FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Voice Assistant',
          style: TextStyle(color: Colors.black87),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _conversationId),
            child: const Text('Done'),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final double bubbleAreaHeight = math.max(
              240.0,
              constraints.maxHeight * 0.38,
            );

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  children: [
                    SizedBox(
                      height: bubbleAreaHeight,
                      child: Center(
                        child: _buildVoiceBubble(),
                      ),
                    ),
                    _buildTranscriptCard(),
                    const SizedBox(height: 12),
                    _buildLanguageSelector(),
                    const SizedBox(height: 12),
                    _buildFullAccessModeCard(),
                    const SizedBox(height: 14),
                    Text(
                      _statusText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: _state == VoiceUiState.error
                            ? AppColors.error
                            : Colors.black54,
                      ),
                    ),
                    if (_showStillThinking) ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Still thinking...',
                        style: TextStyle(
                          color: Colors.black54,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    if (_assistantReply.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        constraints: BoxConstraints(
                          maxHeight: math.max(130.0, constraints.maxHeight * 0.28),
                        ),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            _assistantReply,
                            style: const TextStyle(color: Colors.black87),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    if (_isInitializing)
                      const CircularProgressIndicator()
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_state == VoiceUiState.listening)
                            IconButton(
                              tooltip: 'Discard recording',
                              onPressed: _discardListening,
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.redAccent,
                              ),
                            ),
                          OutlinedButton.icon(
                            onPressed: _onBubblePressed,
                            icon: Icon(
                              _state == VoiceUiState.listening
                                  ? Icons.stop_circle_outlined
                                  : Icons.mic_rounded,
                            ),
                            label: Text(
                              _state == VoiceUiState.listening
                                  ? 'Stop and send'
                                  : 'Start listening',
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
