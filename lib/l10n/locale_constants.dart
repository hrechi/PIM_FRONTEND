import 'package:flutter/material.dart';

/// Supported locales for the app.
const List<Locale> kSupportedLocales = [
  Locale('fr'),
  Locale('en'),
  Locale('ar'),
];

/// RTL language codes.
const Set<String> kRtlLocales = {'ar'};

/// Emoji flags per language code.
const Map<String, String> kLocaleFlags = {
  'fr': '🇫🇷',
  'en': '🇬🇧',
  'ar': '🇸🇦',
};

/// Display names per language code.
const Map<String, String> kLocaleDisplayNames = {
  'fr': 'Français',
  'en': 'English',
  'ar': 'العربية',
};
