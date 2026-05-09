# Internationalisation (i18n) — Fieldly

## Langues supportées

| Code | Langue    | Drapeau | Direction |
|------|-----------|---------|-----------|
| `fr` | Français  | 🇫🇷     | LTR       |
| `en` | English   | 🇬🇧     | LTR       |
| `ar` | العربية   | 🇹🇳     | **RTL**   |

La langue par défaut est le **Français** (marché principal : Maghreb).

---

## Architecture

```
lib/l10n/
├── app_en.arb              ← Traductions anglaises
├── app_fr.arb              ← Traductions françaises  
├── app_ar.arb              ← Traductions arabes (RTL)
├── app_localizations.dart  ← Classe principale + delegate
├── l10n_extensions.dart    ← Extension context.l10n
└── README.md               ← Ce fichier

lib/providers/
└── locale_provider.dart    ← Gestion de la locale + persistance

lib/widgets/
└── language_selector.dart  ← Bottom sheet + tile de sélection
```

---

## Utilisation dans un écran

### 1. Importer l'extension

```dart
import '../l10n/l10n_extensions.dart';
```

### 2. Accéder aux traductions

```dart
// Dans un widget build()
Text(context.l10n.signIn)
Text(context.l10n.welcomeBack)
Text(context.l10n.timeBasedGreeting) // "Bonjour" / "Bonsoir" selon l'heure

// Avec paramètres
Text(context.l10n.currentlyUsedBy('Ahmed'))
Text(context.l10n.cannotDeletePublished('published'))
```

### 3. Changer la langue programmatiquement

```dart
context.read<LocaleProvider>().setLocaleByCode('ar'); // Arabe
context.read<LocaleProvider>().setLocaleByCode('fr'); // Français
context.read<LocaleProvider>().setLocaleByCode('en'); // Anglais
```

### 4. Afficher le sélecteur de langue

```dart
// Bottom sheet
LanguageSelector.show(context);

// Tile dans une liste de paramètres
const LanguageSelectorTile()
```

---

## Ajouter une nouvelle clé de traduction

1. Ajouter la clé dans `app_en.arb` :
```json
"myNewKey": "My new text"
```

2. Ajouter dans `app_fr.arb` :
```json
"myNewKey": "Mon nouveau texte"
```

3. Ajouter dans `app_ar.arb` :
```json
"myNewKey": "نصي الجديد"
```

4. Ajouter le getter dans `app_localizations.dart` :
```dart
String get myNewKey => _t('myNewKey');
```

---

## Support RTL (Arabe)

Le RTL est géré automatiquement dans `main.dart` via `Directionality`.
Quand la locale est `ar`, toute l'interface bascule en RTL.

Pour les cas spéciaux :
```dart
// Vérifier si RTL
if (context.l10n.isRtl) { ... }

// Forcer une direction
Directionality(
  textDirection: TextDirection.ltr,
  child: MyWidget(),
)
```

---

## Écrans traduits ✅

- `signin_screen.dart`
- `signup_screen.dart`
- `home_screen.dart` (greeting dynamique + bouton langue)
- `farmer_home_screen_v2.dart`
- `profile_screen.dart` (avec LanguageSelectorTile)
- `community_feed_screen.dart`
- `notification_center_screen.dart`
- `asset_list_screen.dart`
- `catalogue/catalogue_list_screen.dart`
- `catalogue/catalogue_export_screen.dart`
- `widgets/app_drawer.dart` (navigation complète)

## Écrans à traduire 🔲

Pattern à suivre pour chaque écran :
1. Ajouter `import '../l10n/l10n_extensions.dart';`
2. Remplacer les `Text('...')` hardcodés par `Text(context.l10n.xxx)`
3. Remplacer les `const Text('...')` → supprimer `const` + utiliser l10n
