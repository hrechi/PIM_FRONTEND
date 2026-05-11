import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../l10n/l10n_extensions.dart';
import '../l10n/locale_constants.dart';
import '../providers/locale_provider.dart';

/// A bottom sheet language picker.
/// Call [LanguageSelector.show] from any screen.
class LanguageSelector {
  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _LanguageSelectorSheet(),
    );
  }
}

class _LanguageSelectorSheet extends StatelessWidget {
  const _LanguageSelectorSheet();

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final l10n = context.l10n;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              l10n.selectLanguage,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 20),

            // Language options
            ...kSupportedLocales.map((locale) {
              final code = locale.languageCode;
              final isSelected =
                  localeProvider.locale.languageCode == code;
              final flag = kLocaleFlags[code] ?? '';
              final name = kLocaleDisplayNames[code] ?? code;

              return _LanguageTile(
                flag: flag,
                name: name,
                isSelected: isSelected,
                onTap: () {
                  localeProvider.setLocaleByCode(code);
                  Navigator.of(context).pop();
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.flag,
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  final String flag;
  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF309448);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFFE8F5E9)
            : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? green : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Text(flag, style: const TextStyle(fontSize: 28)),
        title: Text(
          name,
          style: TextStyle(
            fontSize: 16,
            fontWeight:
                isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? green : const Color(0xFF1A1A1A),
          ),
        ),
        trailing: isSelected
            ? const Icon(Icons.check_circle_rounded,
                color: green, size: 22)
            : null,
      ),
    );
  }
}

/// Inline language selector widget (for settings screens).
class LanguageSelectorTile extends StatelessWidget {
  const LanguageSelectorTile({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final l10n = context.l10n;
    final currentCode = localeProvider.locale.languageCode;
    final flag = kLocaleFlags[currentCode] ?? '';
    final name = kLocaleDisplayNames[currentCode] ?? currentCode;

    return ListTile(
      leading: const Icon(Icons.language_rounded),
      title: Text(l10n.language),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(flag, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 6),
          Text(
            name,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF757575),
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, color: Color(0xFF757575)),
        ],
      ),
      onTap: () => LanguageSelector.show(context),
    );
  }
}
