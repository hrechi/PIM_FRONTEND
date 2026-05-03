typedef VoicePageActionExecutor = Future<VoicePageActionResult> Function(
  String transcript,
);

class VoicePageActionResult {
  const VoicePageActionResult({
    required this.handled,
    this.message = '',
  });

  const VoicePageActionResult.notHandled()
      : handled = false,
        message = '';

  final bool handled;
  final String message;
}

class VoicePageActionRegistry {
  static String? _activePageKey;
  static VoicePageActionExecutor? _executor;

  static String? get activePageKey => _activePageKey;
  static bool get hasActiveHandler => _executor != null;

  static void register({
    required String pageKey,
    required VoicePageActionExecutor executor,
  }) {
    _activePageKey = pageKey;
    _executor = executor;
  }

  static void unregister(String pageKey) {
    if (_activePageKey != pageKey) {
      return;
    }

    _activePageKey = null;
    _executor = null;
  }

  static Future<VoicePageActionResult> dispatch(String transcript) async {
    final executor = _executor;
    if (executor == null) {
      return const VoicePageActionResult.notHandled();
    }

    return executor(transcript);
  }
}
