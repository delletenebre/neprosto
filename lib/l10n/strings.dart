import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

extension EditorLanguageContext on BuildContext {
  AppLocalizations get strings =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ??
      editorStrings;
}

// The editor has one UI language, including commands and exports without a widget context.
AppLocalizations editorStrings = lookupAppLocalizations(const Locale('ru'));
const editorLocales = [Locale('ru'), Locale('en'), Locale('ky')];
