import 'package:shared_preferences/shared_preferences.dart';

class VoiceAccessModeService {
  static const String _fullAccessKey = 'voice_full_access_mode_enabled';

  static Future<bool> isFullAccessEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_fullAccessKey) ?? false;
  }

  static Future<void> setFullAccessEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_fullAccessKey, enabled);
  }
}
