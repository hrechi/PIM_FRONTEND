import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../l10n/locale_constants.dart';

const String _kLocaleKey = 'app_locale';

/// Manages the current app locale and persists the user's choice.
///
/// Usage:
///   context.read<LocaleProvider>().setLocale(const Locale('fr'));
///   context.watch<LocaleProvider>().locale
class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('fr'); // Default: French (primary market)

  Locale get locale => _locale;

  String get languageCode => _locale.languageCode;

  bool get isRtl => kRtlLocales.contains(_locale.languageCode);

  /// Load persisted locale from SharedPreferences.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kLocaleKey);
    if (saved != null &&
        kSupportedLocales.any((l) => l.languageCode == saved)) {
      _locale = Locale(saved);
      notifyListeners();
    }
  }

  /// Change the app locale and persist the choice.
  Future<void> setLocale(Locale locale) async {
    if (!kSupportedLocales.any((l) => l.languageCode == locale.languageCode)) {
      return;
    }
    if (_locale == locale) return;

    _locale = locale;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kLocaleKey, locale.languageCode);
  }

  /// Convenience method to set locale by language code string.
  Future<void> setLocaleByCode(String code) async {
    await setLocale(Locale(code));
  }
}
