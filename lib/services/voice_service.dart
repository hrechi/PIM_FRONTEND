import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

class VoiceService {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();

  bool _initialized = false;
  bool _isSpeechAvailable = false;
  String _latestTranscript = '';
  final List<String> _speechLocales = <String>[];
  final Set<String> _ttsLanguages = <String>{};

  bool get isListening => _speechToText.isListening;

  List<String> get speechLocales => List<String>.unmodifiable(_speechLocales);

  String _normalizeLocale(String locale) {
    return locale.trim().toLowerCase().replaceAll('_', '-');
  }

  List<String> _fallbackLocales(String locale) {
    final normalized = locale.trim();
    if (normalized.isEmpty) {
      return const <String>[];
    }

    final canonical = _normalizeLocale(normalized);
    if (canonical == 'ar-tn') {
      return const <String>['ar-TN', 'ar-SA', 'ar'];
    }
    if (canonical == 'ar-sa') {
      return const <String>['ar-SA', 'ar-TN', 'ar'];
    }
    if (canonical == 'fr-fr') {
      return const <String>['fr-FR', 'fr'];
    }
    if (canonical == 'en-us') {
      return const <String>['en-US', 'en'];
    }

    final parts = normalized.split('-');
    if (parts.length >= 2) {
      return <String>[normalized, parts.first];
    }

    return <String>[normalized];
  }

  String? _pickLocaleMatch(Iterable<String> source, String candidate) {
    final normalizedCandidate = _normalizeLocale(candidate);

    for (final value in source) {
      if (_normalizeLocale(value) == normalizedCandidate) {
        return value;
      }
    }

    for (final value in source) {
      final normalizedValue = _normalizeLocale(value);
      if (normalizedValue.startsWith('$normalizedCandidate-')) {
        return value;
      }
    }

    return null;
  }

  String? resolveSpeechLocale(String? preferredLocale) {
    if (preferredLocale == null || preferredLocale.trim().isEmpty) {
      return null;
    }

    for (final candidate in _fallbackLocales(preferredLocale)) {
      final match = _pickLocaleMatch(_speechLocales, candidate);
      if (match != null) {
        return match;
      }
    }

    return null;
  }

  Future<bool> _startListeningAttempt({
    required void Function(String transcript, bool isFinal) onResult,
    void Function(double level)? onSoundLevelChange,
    String? localeId,
  }) async {
    final dynamic started = await _speechToText.listen(
      onResult: (SpeechRecognitionResult result) {
        _latestTranscript = result.recognizedWords.trim();
        onResult(_latestTranscript, result.finalResult);
      },
      onSoundLevelChange: onSoundLevelChange,
      listenFor: const Duration(minutes: 2),
      pauseFor: const Duration(seconds: 30),
      listenOptions: SpeechListenOptions(
        partialResults: true,
        cancelOnError: false,
        listenMode: ListenMode.dictation,
      ),
      localeId: localeId,
    );

    if (started is bool) {
      return started;
    }

    return true;
  }

  Future<String?> _setTtsLanguageWithFallback(String preferredLocale) async {
    for (final candidate in _fallbackLocales(preferredLocale)) {
      final preferredMatch = _pickLocaleMatch(_ttsLanguages, candidate);
      final target = preferredMatch ?? candidate;

      try {
        final dynamic available =
            await _flutterTts.isLanguageAvailable(target);
        final bool isAvailable =
            available is bool ? available : available is int ? available == 1 : true;

        if (!isAvailable) {
          continue;
        }

        await _flutterTts.setLanguage(target);
        return target;
      } catch (_) {
        // Ignore unsupported language candidate and try next fallback.
      }
    }

    return null;
  }

  Future<void> initialize({
    void Function(String status)? onStatus,
    void Function(String error)? onError,
  }) async {
    if (_initialized) return;

    _isSpeechAvailable = await _speechToText.initialize(
      onStatus: (status) {
        if (onStatus != null) {
          onStatus(status);
        }
      },
      onError: (SpeechRecognitionError error) {
        if (onError != null) {
          onError(error.errorMsg);
        }
      },
    );

    final locales = await _speechToText.locales();
    _speechLocales
      ..clear()
      ..addAll(locales.map((locale) => locale.localeId));

    final dynamic ttsLanguages = await _flutterTts.getLanguages;
    _ttsLanguages.clear();
    if (ttsLanguages is List) {
      _ttsLanguages.addAll(ttsLanguages.map((item) => item.toString()));
    }

    await _setTtsLanguageWithFallback('en-US');
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.48);
    await _flutterTts.awaitSpeakCompletion(true);

    _initialized = true;
  }

  Future<String?> startListening({
    required void Function(String transcript, bool isFinal) onResult,
    void Function(double level)? onSoundLevelChange,
    String? localeId,
  }) async {
    if (!_initialized) {
      throw Exception('Voice service is not initialized.');
    }

    if (!_isSpeechAvailable) {
      throw Exception(
        'Speech recognition is not available on this device.',
      );
    }

    _latestTranscript = '';
    if (localeId != null && localeId.trim().isNotEmpty) {
      final localeCandidates = <String>[];

      for (final fallback in _fallbackLocales(localeId)) {
        final resolved = resolveSpeechLocale(fallback);
        if (resolved == null) {
          continue;
        }

        final exists = localeCandidates.any(
          (value) => _normalizeLocale(value) == _normalizeLocale(resolved),
        );
        if (!exists) {
          localeCandidates.add(resolved);
        }
      }

      if (localeCandidates.isEmpty) {
        final isArabicRequested = _normalizeLocale(localeId).startsWith('ar');
        if (isArabicRequested) {
          throw Exception(
            'Arabic speech recognition is not available on this device. Enable or download Arabic language in speech settings, then try again.',
          );
        }

        throw Exception(
          'Speech recognition locale $localeId is not available on this device.',
        );
      }

      for (final candidate in localeCandidates) {
        try {
          final started = await _startListeningAttempt(
            onResult: onResult,
            onSoundLevelChange: onSoundLevelChange,
            localeId: candidate,
          );

          if (started) {
            return candidate;
          }
        } catch (_) {
          // Try next candidate from the same requested language.
        }
      }

      throw Exception(
        'Unable to start speech recognition for $localeId. Please verify speech language installation and permissions.',
      );
    }

    final startedDefault = await _startListeningAttempt(
      onResult: onResult,
      onSoundLevelChange: onSoundLevelChange,
      localeId: null,
    );

    if (!startedDefault) {
      throw Exception('Speech recognition could not start with available locales.');
    }

    return null;
  }

  Future<String> stopListening() async {
    if (_speechToText.isListening) {
      await _speechToText.stop();
    }
    return _latestTranscript.trim();
  }

  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
  }

  Future<void> speak(
    String text, {
    String? languageCode,
  }) async {
    if (!_initialized) {
      throw Exception('Voice service is not initialized.');
    }

    if (languageCode != null && languageCode.trim().isNotEmpty) {
      await _setTtsLanguageWithFallback(languageCode);
    }

    await _flutterTts.stop();
    await _flutterTts.speak(text);
  }

  Future<void> dispose() async {
    await _speechToText.cancel();
    await _flutterTts.stop();
  }
}
