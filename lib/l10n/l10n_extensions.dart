import 'package:flutter/material.dart';
import 'app_localizations.dart';

/// Shorthand extension — use `context.l10n.signIn` anywhere in the widget tree.
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
