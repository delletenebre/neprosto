import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

extension EditorLanguageContext on BuildContext {
  AppLocalizations get strings =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ??
      editorStrings;
}

// The editor has one UI language, including commands and exports without a widget context.
AppLocalizations editorStrings = lookupAppLocalizations(const Locale('ru'));
final editorLanguages = {
  const Locale('ru'): (name: 'Русский', flag: '🇷🇺'),
  const Locale('en'): (name: 'English', flag: '🇬🇧'),
  const Locale('ky'): (name: 'Кыргызча', flag: '🇰🇬'),
};
final editorLocales = editorLanguages.keys;
