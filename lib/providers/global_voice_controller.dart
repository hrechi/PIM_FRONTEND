import 'dart:async';

import 'package:flutter/material.dart';

import '../main.dart';
import '../services/chat_service.dart';
import '../services/robot_voice_controller.dart';
import '../services/voice_navigation_service.dart';
import '../services/voice_page_action_registry.dart';
import '../services/voice_service.dart';
import 'voice_access_mode_provider.dart';

enum GlobalVoiceState {
  idle,
  listening,
  processing,
  speaking,
  error,
}

class GlobalVoiceController with ChangeNotifier {
  GlobalVoiceController({
    required VoiceAccessModeProvider accessModeProvider,
  }) : _accessModeProvider = accessModeProvider {
    _initialize();
  }

  final VoiceService _voiceService = VoiceService();
  final VoiceAccessModeProvider _accessModeProvider;

  GlobalVoiceState _state = GlobalVoiceState.idle;
  String _lastTranscript = '';
  String _lastError = '';
  bool _isReady = false;
  String? _conversationId;
  bool _manualStopRequested = false;
  bool _isRestartingListening = false;
  String? _activeListeningLocale;

  GlobalVoiceState get state => _state;
  String get lastTranscript => _lastTranscript;
  String get liveTranscript => _lastTranscript;
  String get lastError => _lastError;
  bool get isReady => _isReady;
  bool get isListening => _state == GlobalVoiceState.listening;
  bool get isBusy =>
      _state == GlobalVoiceState.processing || _state == GlobalVoiceState.speaking;

  Future<void> _initialize() async {
    try {
      await _voiceService.initialize(
        onStatus: (status) {
          if (status == 'notListening' && _state == GlobalVoiceState.listening) {
            if (_manualStopRequested) {
              _manualStopRequested = false;
              return;
            }

            _resumeListeningAfterSilence();
          }
        },
        onError: (error) {
          if (_state == GlobalVoiceState.listening &&
              _isRecoverableListeningError(error)) {
            _resumeListeningAfterSilence();
            return;
          }

          _lastError = error;
          _state = GlobalVoiceState.error;
          notifyListeners();
        },
      );
      _isReady = true;
      _state = GlobalVoiceState.idle;
      notifyListeners();
    } catch (e) {
      _lastError = e.toString();
      _state = GlobalVoiceState.error;
      notifyListeners();
    }
  }

  Future<void> onMicPressed() async {
    if (!_accessModeProvider.isEnabled) {
      return;
    }

    if (!_isReady) {
      return;
    }

    if (_state == GlobalVoiceState.processing) {
      return;
    }

    if (_state == GlobalVoiceState.speaking) {
      await _voiceService.stopSpeaking();
      _state = GlobalVoiceState.idle;
      notifyListeners();
      return;
    }

    if (isListening) {
      await _stopAndProcess();
      return;
    }

    await _startListening();
  }

  Future<void> _startListening() async {
    try {
      _lastError = '';
      _lastTranscript = '';
      _manualStopRequested = false;
      _state = GlobalVoiceState.listening;
      notifyListeners();

      await _voiceService.stopSpeaking();
      await _startSpeechCapture(
        clearTranscript: true,
        localeId: null,
      );
    } catch (e) {
      _lastError = e.toString();
      _state = GlobalVoiceState.error;
      notifyListeners();
    }
  }

  Future<void> _startSpeechCapture({
    bool clearTranscript = false,
    String? localeId,
  }) async {
    final usedLocale = await _voiceService.startListening(
      onResult: (transcript, _) {
        _lastTranscript = transcript;
        notifyListeners();
      },
      localeId: localeId,
    );

    _activeListeningLocale = usedLocale ?? localeId ?? _activeListeningLocale;

    if (clearTranscript) {
      _lastTranscript = '';
      notifyListeners();
    }
  }

  Future<void> _resumeListeningAfterSilence() async {
    if (_isRestartingListening || _state != GlobalVoiceState.listening) {
      return;
    }

    _isRestartingListening = true;
    try {
      await Future<void>.delayed(const Duration(milliseconds: 220));
      if (_state != GlobalVoiceState.listening || _manualStopRequested) {
        return;
      }

      await _startSpeechCapture(localeId: _activeListeningLocale);
    } catch (_) {
      // Keep trying silently so listening feels continuous like voice chat page.
      Future<void>.delayed(const Duration(milliseconds: 450), () {
        if (_state != GlobalVoiceState.listening || _manualStopRequested) {
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

  Future<void> _stopAndProcess() async {
    _manualStopRequested = true;
    final stoppedTranscript = await _voiceService.stopListening();
    final transcript = stoppedTranscript.trim().isNotEmpty
      ? stoppedTranscript.trim()
      : _lastTranscript.trim();

    if (transcript.isEmpty) {
      _state = GlobalVoiceState.idle;
      notifyListeners();
      await _speak('I did not catch that. Please try again.', transcript: '');
      return;
    }

    _lastTranscript = transcript;
    _state = GlobalVoiceState.processing;
    notifyListeners();

    try {
      final localCommand = VoiceNavigationService.parse(transcript);

      if (localCommand.type == VoiceCommandType.deactivateFullAccess) {
        await _accessModeProvider.setEnabled(false);
        await _speak('Full access mode disabled.', transcript: transcript);
        return;
      }

      if (localCommand.type == VoiceCommandType.activateFullAccess) {
        await _accessModeProvider.setEnabled(true);
        await _speak('Full access mode is already enabled.', transcript: transcript);
        return;
      }

      // Robot motion / emergency-stop commands. Mirrors voice_assistant_screen
      // so the floating mic responds to "forward", "stop", "turn left",
      // "advance for 30 cm", etc., exactly like the Hold-to-Drive buttons.
      if (localCommand.type == VoiceCommandType.robotCommand) {
        await _handleRobotVoiceCommand(localCommand, transcript);
        return;
      }

      if (VoicePageActionRegistry.hasActiveHandler) {
        final result = await VoicePageActionRegistry.dispatch(transcript);
        if (result.handled) {
          if (result.message.isNotEmpty) {
            await _speak(result.message, transcript: transcript);
          }
          _state = GlobalVoiceState.idle;
          notifyListeners();
          return;
        }
      }

      if (localCommand.type == VoiceCommandType.navigate &&
          localCommand.page != null) {
        final navState = navigatorKey.currentState;
        if (navState != null) {
          VoiceNavigationService.navigateToPageWithNavigator(
            navState,
            localCommand.page!,
          );
        }
        await _speak(
          'Opening ${VoiceNavigationService.labelForPage(localCommand.page!)}.',
          transcript: transcript,
        );
        return;
      }

      if (localCommand.type == VoiceCommandType.unknownNavigate) {
        final suggestionText = localCommand.suggestions.isEmpty
            ? ''
            : ' Try ${localCommand.suggestions.join(', ')}.';
        await _speak(
          'I could not find that page.$suggestionText',
          transcript: transcript,
        );
        return;
      }

      final requestedLanguageCode = _resolveRequestedLanguageCode(transcript);
      final result = await ChatService.sendVoiceMessage(
        transcript,
        conversationId: _conversationId,
        languageCode: requestedLanguageCode,
      );

      final reply = (result['reply'] as String?)?.trim() ?? '';
      final nextConversationId = result['conversationId'] as String?;
      if (nextConversationId != null && nextConversationId.isNotEmpty) {
        _conversationId = nextConversationId;
      }

      final returnedLanguageCode =
          (result['languageCode'] as String?)?.trim() ?? requestedLanguageCode;

      await _speak(
        reply.isEmpty ? 'Done.' : reply,
        transcript: transcript,
        forcedLanguageCode: returnedLanguageCode,
      );
    } catch (e) {
      _lastError = e.toString();
      _state = GlobalVoiceState.error;
      notifyListeners();
      await _speak('I could not complete that request.', transcript: transcript);
    }
  }

  Future<void> _handleRobotVoiceCommand(
    VoiceCommandResult command,
    String transcript,
  ) async {
    final action = command.robotAction;
    if (action == null) {
      _state = GlobalVoiceState.idle;
      notifyListeners();
      return;
    }

    final controller = RobotVoiceController.instance;

    // Stop is highest priority and must work even if we never connected to a
    // robot — try to publish a zero-Twist anyway.
    if (action == RobotVoiceAction.stop) {
      final ok = await controller.emergencyStop();
      await _speak(
        ok
            ? 'Emergency stop sent.'
            : 'No robot is connected, but I tried to send a stop anyway.',
        transcript: transcript,
      );
      return;
    }

    final connected = await controller.ensureConnected();
    if (!connected) {
      await _speak(
        'No robot is connected. Open the Control Room and connect first.',
        transcript: transcript,
      );
      return;
    }

    bool ok = false;
    String successMessage = 'Done.';
    switch (action) {
      case RobotVoiceAction.forward:
        ok = await controller.moveForward();
        successMessage = 'Moving forward.';
        break;
      case RobotVoiceAction.backward:
        ok = await controller.moveBackward();
        successMessage = 'Moving backward.';
        break;
      case RobotVoiceAction.left:
        ok = await controller.turnLeft();
        successMessage = 'Turning left.';
        break;
      case RobotVoiceAction.right:
        ok = await controller.turnRight();
        successMessage = 'Turning right.';
        break;
      case RobotVoiceAction.distance:
        final meters = command.distanceMeters ?? 0;
        ok = await controller.driveDistance(meters: meters);
        final cm = (meters.abs() * 100).round();
        final dir = meters >= 0 ? 'forward' : 'backward';
        successMessage = 'Driving $dir for $cm centimeters.';
        break;
      case RobotVoiceAction.explore:
        ok = await controller.startExplore();
        successMessage =
            'Starting autonomous exploration. Say stop to cancel.';
        break;
      case RobotVoiceAction.stop:
        // handled above
        return;
    }

    await _speak(
      ok ? successMessage : 'I could not send the command to the robot.',
      transcript: transcript,
    );
  }

  Future<void> _speak(
    String message, {
    required String transcript,
    String? forcedLanguageCode,
  }) async {
    _state = GlobalVoiceState.speaking;
    notifyListeners();

    final languageCode = forcedLanguageCode ?? _resolveRequestedLanguageCode(transcript);

    await _voiceService.speak(
      message,
      languageCode: languageCode,
    );

    _state = GlobalVoiceState.idle;
    notifyListeners();
  }

  String _normalizeLanguageCode(String code) {
    final normalized = code.trim().toLowerCase().replaceAll('_', '-');
    if (normalized == 'ar-tn') return 'ar-TN';
    if (normalized == 'fr-fr') return 'fr-FR';
    if (normalized.startsWith('ar')) return 'ar-TN';
    if (normalized.startsWith('fr')) return 'fr-FR';
    return 'en-US';
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
    final arabiziToken = RegExp(
      r'\b[a-z]{2,}[2356789][a-z0-9]*\b',
      caseSensitive: false,
    );
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

  String _resolveRequestedLanguageCode(String transcript) {
    return _normalizeLanguageCode(_detectLanguageFromTranscript(transcript));
  }

  Future<void> disposeController() async {
    await _voiceService.dispose();
  }

  @override
  void dispose() {
    _voiceService.dispose();
    super.dispose();
  }
}
