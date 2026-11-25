import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import 'palette.dart';

Future<void> updateNativeAppearance(
  EditorPalette? palette,
  AppLocalizations strings,
) async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.macOS) return;
  try {
    await const MethodChannel(
      'neprosto/popup',
    ).invokeMethod<void>('appearance', {
      'theme': palette?.name ?? 'system',
      'menu': {
        'np.aboutNeprosto': strings.aboutNeprosto,
        'np.settingsMenu': strings.settingsMenu,
        'np.services': strings.services,
        'np.hideNeprosto': strings.hideNeprosto,
        'np.hideOthers': strings.hideOthers,
        'np.showAll': strings.showAll,
        'np.quitNeprosto': strings.quitNeprosto,
        'np.file': strings.fileMenu,
        'np.new': '${strings.newProject}…',
        'np.open': strings.openProjectMenu,
        'np.close': strings.closeTab,
        'np.save': strings.save,
        'np.saveAs': strings.saveAs,
        'np.rename': strings.rename,
        'np.projectSettings': strings.projectSettingsMenu,
        'np.zoomIn': strings.zoomIn,
        'np.zoomOut': strings.zoomOut,
        'np.fit': strings.fitToWindow,
        'np.partsSidebar': strings.partsTree,
        'np.inspector': strings.properties,
        'np.partsList': strings.partsList,
        'np.edit': strings.edit,
        'np.undo': strings.undo,
        'np.redo': strings.redo,
        'np.cut': strings.cut,
        'np.copy': strings.copy,
        'np.paste': strings.paste,
        'np.pasteAndMatchStyle': strings.pasteAndMatchStyle,
        'np.delete': strings.delete,
        'np.selectAll': strings.selectAll,
        'np.find': strings.find,
        'np.findMenu': strings.findMenu,
        'np.findAndReplace': strings.findAndReplace,
        'np.findNext': strings.findNext,
        'np.findPrevious': strings.findPrevious,
        'np.useSelectionForFind': strings.useSelectionForFind,
        'np.jumpToSelection': strings.jumpToSelection,
        'np.spellingAndGrammar': strings.spellingAndGrammar,
        'np.showSpellingAndGrammar': strings.showSpellingAndGrammar,
        'np.checkDocumentNow': strings.checkDocumentNow,
        'np.checkSpellingWhileTyping': strings.checkSpellingWhileTyping,
        'np.checkGrammarWithSpelling': strings.checkGrammarWithSpelling,
        'np.correctSpellingAutomatically': strings.correctSpellingAutomatically,
        'np.substitutions': strings.substitutions,
        'np.showSubstitutions': strings.showSubstitutions,
        'np.smartCopyPaste': strings.smartCopyPaste,
        'np.smartQuotes': strings.smartQuotes,
        'np.smartDashes': strings.smartDashes,
        'np.smartLinks': strings.smartLinks,
        'np.dataDetectors': strings.dataDetectors,
        'np.textReplacement': strings.textReplacement,
        'np.transformations': strings.transformations,
        'np.makeUpperCase': strings.makeUpperCase,
        'np.makeLowerCase': strings.makeLowerCase,
        'np.capitalize': strings.capitalize,
        'np.speech': strings.speech,
        'np.startSpeaking': strings.startSpeaking,
        'np.stopSpeaking': strings.stopSpeaking,
        'np.view': strings.view,
        'np.enterFullScreen': strings.enterFullScreen,
        'np.window': strings.window,
        'np.minimize': strings.minimize,
        'np.zoomLabel': strings.zoomLabel,
        'np.bringAllToFront': strings.bringAllToFront,
        'np.help': strings.help,
      },
    });
  } on MissingPluginException {
    // The Flutter test host has no AppKit window.
  }
}
