import 'package:flutter/foundation.dart';

import '../services/voice_access_mode_service.dart';

class VoiceAccessModeProvider with ChangeNotifier {
  bool _isEnabled = false;
  bool _isLoaded = false;

  bool get isEnabled => _isEnabled;
  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    final enabled = await VoiceAccessModeService.isFullAccessEnabled();
    _isEnabled = enabled;
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setEnabled(bool enabled) async {
    if (_isEnabled == enabled) {
      if (!_isLoaded) {
        _isLoaded = true;
        notifyListeners();
      }
      return;
    }

    _isEnabled = enabled;
    _isLoaded = true;
    notifyListeners();
    await VoiceAccessModeService.setFullAccessEnabled(enabled);
  }
}
