import 'dart:convert';

import 'package:cupertino_ui/cupertino_ui.dart' as cu;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show Locale, Localizations;
import 'package:flutter_test/flutter_test.dart';
import 'package:neprosto/editor/controller.dart';
import 'package:neprosto/editor/settings.dart';
import 'package:neprosto/editor/palette.dart';
import 'package:neprosto/editor/parts_list.dart';
import 'package:neprosto/l10n/app_localizations.dart';
import 'package:neprosto/l10n/strings.dart';
import 'package:neprosto/editor/model.dart';
import 'package:neprosto/editor/project_tab_bar.dart';
import 'package:neprosto/editor/project_tabs.dart';
import 'package:neprosto/editor/storage.dart';
import 'package:neprosto/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Preferences extends Fake implements SharedPreferencesAsync {
  final values = <String, Object>{};
  @override
  Future<void> setString(String key, String value) async => values[key] = value;
  @override
  Future<void> setInt(String key, int value) async => values[key] = value;
  @override
  Future<void> setBool(String key, bool value) async => values[key] = value;
}

void main() {
  testWidgets('The plus button opens files and reopens recent projects', (
    t,
  ) async {
    await t.binding.setSurfaceSize(const Size(960, 700));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final messenger = t.binding.defaultBinaryMessenger;
    const picker = MethodChannel('plugins.flutter.io/file_selector');
    const files = MethodChannel('neprosto/project-files');
    const path = '/projects/shelf.neprosto';
    var name = 'Полка';
    var reads = 0;
    List<String>? paths;
    messenger.setMockMethodCallHandler(picker, (call) async {
      expect(call.method, 'openFile');
      return paths;
    });
    messenger.setMockMethodCallHandler(files, (call) async {
      expect(call.method, 'read');
      expect(call.arguments['path'], path);
      if (reads++ > 0) expect(call.arguments['bookmark'], 'scope');
      if (name.isEmpty) throw PlatformException(code: 'missing');
      return {
        'path': path,
        'bookmark': 'scope',
        'bytes': utf8.encode(Project(name, []).encode()),
      };
    });
    addTearDown(() => messenger.setMockMethodCallHandler(picker, null));
    addTearDown(() => messenger.setMockMethodCallHandler(files, null));
    final prefs = _Preferences();
    final tabs = ProjectTabs(Editor(Project.bench()));
    final original = tabs.value;
    await t.pumpWidget(NeprostoApp.withTabs(tabs, preferences: prefs));
    await t.pumpAndSettle();
    Future<void> tap(Finder finder) async {
      await t.tap(finder);
      await t.pumpAndSettle();
    }

    final plus = find.byTooltip('Новая вкладка');
    await tap(plus);
    expect(find.text('Пока нет недавних проектов'), findsOneWidget);
    expect(find.text('Создать проект'), findsOneWidget);
    await tap(find.text('Открыть проект…'));
    expect(tabs.value, same(original));
    expect(original.editor.message, isNot(editorStrings.openProjectError));
    paths = [path];
    await tap(plus);
    await tap(find.text('Открыть проект…'));
    final opened = tabs.value;
    expect(opened.file!.path, path);
    expect(reads, 1);
    opened.editor.commit(opened.committed.copy(name: 'Правки'));
    tabs.select(original);
    await t.pumpAndSettle();
    await tap(plus);
    await tap(find.text(path));
    expect(tabs.value, same(opened));
    expect(tabs.value.committed.name, 'Правки');
    expect(tabs.items, hasLength(2));
    expect(reads, 1);
    tabs.close(opened);
    await t.pumpAndSettle();
    name = 'Полка с диска';
    await tap(plus);
    await tap(find.text(path));
    expect(tabs.value.committed.name, name);
    expect(reads, 2);
    expect(tabs.recent, hasLength(1));
    final restored = ProjectTabs.decode(tabs.encode())
      ..restoreRecent(prefs.values[ProjectTabs.recentKey] as String);
    expect(restored.recent.single.name, name);
    expect(restored.recent.single.file!.bookmark, 'scope');
    tabs.close(tabs.value);
    await t.pumpAndSettle();
    name = '';
    await tap(plus);
    await tap(find.text(path));
    expect(tabs.items.single, same(original));
    expect(original.editor.message, editorStrings.openProjectError);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  test(
    'Browser copies survive closing and preserve the last saved version',
    () {
      final tabs = ProjectTabs(Editor(Project.bench()));
      final imported = Project('Полка', []);
      tabs.openDocument(imported);
      final id = tabs.recent.single.id;
      tabs.value.editor.commit(imported.copy(name: 'Несохранённая правка'));
      final restored = ProjectTabs.decode(tabs.encode())
        ..restoreRecent(jsonEncode(tabs.recent));
      expect(restored.forDocument(id), same(restored.value));
      restored.close(restored.value);
      restored.openDocument(restored.recent.single.snapshot!, recentId: id);
      expect(restored.value.committed.name, 'Полка');
      expect(restored.value.file, isNull);
      expect(restored.recent.single.id, id);
    },
  );

  testWidgets(
    'Web language menu switches the open workspace and saves the selection',
    (t) async {
      await t.binding.setSurfaceSize(const Size(880, 600));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final originalStrings = editorStrings;
      addTearDown(() => editorStrings = originalStrings);
      final prefs = _Preferences();
      final editor = Editor(Project.bench())..select(1);
      final project = editor.project;
      await t.pumpWidget(NeprostoApp(editor: editor, preferences: prefs));
      await t.pumpAndSettle();
      Finder menu() => find.byTooltip(editorStrings.language);
      if (!kIsWeb) {
        expect(menu(), findsNothing);
        return;
      }
      final settings = t.getRect(find.byTooltip(editorStrings.settings));
      final button = t.getRect(menu());
      expect(button.center.dy, closeTo(settings.center.dy, 1));
      expect(settings.left - button.right, inInclusiveRange(0, 4));
      const languages = [
        ('en', '🇬🇧', 'English'),
        ('ky', '🇰🇬', 'Кыргызча'),
        ('ru', '🇷🇺', 'Русский'),
      ];
      expect(find.text('🇷🇺 RU'), findsOneWidget);
      for (final (code, flag, name) in languages) {
        await t.tap(menu());
        await t.pumpAndSettle();
        for (final (_, flag, name) in languages) {
          expect(find.text('$flag $name'), findsOneWidget);
        }
        await t.tap(find.text('$flag $name'));
        await t.pumpAndSettle();
        final page = t.element(find.byType(Workspace));
        expect(Localizations.localeOf(page), Locale(code));
        expect(
          find.byTooltip(lookupAppLocalizations(Locale(code)).settings),
          findsOneWidget,
        );
        expect(find.text('$flag ${code.toUpperCase()}'), findsOneWidget);
        expect(prefs.values, {'interface-language': code});
        expect(editor.project, same(project));
        expect(editor.selection, {1});
      }
    },
    variant: TargetPlatformVariant({
      TargetPlatform.macOS,
      TargetPlatform.windows,
    }),
  );

  testWidgets(
    'All three languages and both themes work on an open project',
    (t) async {
      await t.binding.setSurfaceSize(const Size(880, 600));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final initialStrings = editorStrings;
      addTearDown(() => editorStrings = initialStrings);
      const popup = MethodChannel('neprosto/popup');
      final messenger = t.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(popup, (_) async => null);
      addTearDown(() => messenger.setMockMethodCallHandler(popup, null));
      final editor = Editor(Project.bench().copy(name: 'Стол / Table'))
        ..select(1);
      final tabs = ProjectTabs(editor);
      final prefs = _Preferences();
      await t.pumpWidget(NeprostoApp.withTabs(tabs, preferences: prefs));
      await t.pumpAndSettle();
      var strings = lookupAppLocalizations(const Locale('ru'));
      for (final (code, language) in [
        ('ru', 'Русский'),
        ('en', 'English'),
        ('ky', 'Кыргызча'),
      ]) {
        for (final dark in [false, true]) {
          await t.tap(find.byTooltip(strings.settings));
          await t.pumpAndSettle();
          await t.tap(find.text(strings.appearance));
          await t.pumpAndSettle();
          final saved = Map.of(prefs.values);
          await t.tap(find.text(language));
          await t.pumpAndSettle();
          strings = lookupAppLocalizations(Locale(code));
          expect(find.text(strings.theme), findsOneWidget);
          await t.tap(find.text(dark ? strings.dark : strings.light));
          await t.pumpAndSettle();
          expect(t.element(find.byType(EditorSettings)).colors.isDark, dark);
          final page = t.element(find.byType(Workspace));
          expect(Localizations.localeOf(page).languageCode, code);
          expect(page.colors.isDark, dark);
          expect(prefs.values, saved);
          await t.tap(find.text(strings.done));
          await t.pumpAndSettle();

          expect(Localizations.localeOf(page).languageCode, code);
          expect(page.colors.isDark, dark);
          expect(prefs.values['interface-theme'], dark ? 'dark' : 'light');
          if (code != 'ru') expect(prefs.values['interface-language'], code);
          expect(editor.project.name, 'Стол / Table');
          expect(editor.selection, {1});
          await t.tap(find.text(strings.partsList));
          await t.pumpAndSettle();
          expect(find.byType(PartsList), findsOneWidget);
          expect(find.text(strings.close), findsOneWidget);
          expect(find.text(strings.exportToExcel), findsOneWidget);
          if (dark) {
            await t.tap(find.text(strings.close));
          } else {
            await t.sendKeyEvent(LogicalKeyboardKey.escape);
          }
          await t.pumpAndSettle();
          expect(find.byType(PartsList), findsNothing);
          expect(t.takeException(), isNull);
        }
      }
    },
    variant: TargetPlatformVariant({
      TargetPlatform.macOS,
      TargetPlatform.windows,
    }),
  );

  testWidgets(
    'Cancelling appearance previews restores the locale and system theme',
    (t) async {
      await t.binding.setSurfaceSize(const Size(880, 600));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final prefs = _Preferences();
      final editor = Editor(Project.bench())..message = 'Проект сохранён';
      await t.pumpWidget(NeprostoApp(editor: editor, preferences: prefs));
      await t.pumpAndSettle();

      await t.tap(find.byTooltip('Настройки'));
      await t.pumpAndSettle();
      await t.tap(find.text('Оформление'));
      await t.pumpAndSettle();
      await t.tap(find.text('Тёмная'));
      await t.pumpAndSettle();
      await t.tap(find.text('English'));
      await t.pumpAndSettle();
      final en = lookupAppLocalizations(const Locale('en'));
      await t.tap(find.text(en.editing));
      await t.pumpAndSettle();
      expect(t.element(find.byType(EditorSettings)).colors, EditorPalette.dark);
      await t.tap(find.text(en.cancel));
      await t.pumpAndSettle();

      final page = t.element(find.byType(Workspace));
      expect(Localizations.localeOf(page), const Locale('ru'));
      expect(
        t.widget<Workspace>(find.byType(Workspace)).followSystemTheme,
        isTrue,
      );
      expect(page.colors, EditorPalette.light);
      expect(editor.message, 'Проект сохранён');
      expect(prefs.values, isEmpty);
    },
    variant: TargetPlatformVariant({
      TargetPlatform.macOS,
      TargetPlatform.windows,
    }),
  );

  testWidgets(
    'Switch tabs with independent selections and history, then cancel or discard on close',
    (t) async {
      await t.binding.setSurfaceSize(const Size(960, 700));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final editor = Editor(Project.bench())..select(1);
      final tabs = ProjectTabs(editor);
      await t.pumpWidget(NeprostoApp.withTabs(tabs));
      await t.pumpAndSettle();
      editor.commit(editor.project.copy(name: 'Скамья садовая'));
      await t.pump();
      await t.tap(find.byTooltip('Новая вкладка'));
      await t.pumpAndSettle();
      await t.tap(find.text('Создать проект'));
      await t.pumpAndSettle();
      await t.tap(find.text('Пустой проект'));
      await t.pumpAndSettle();
      expect(tabs.items.length, 2);
      expect(tabs.value.editor.canUndo, false);
      expect(tabs.value.editor.project.beams, isEmpty);
      final other = tabs.value;
      other.editor.commit(other.committed.copy(name: 'Стол'));
      await t.pump();
      Future<void> selectTab(String name) async {
        final label = find.descendant(
          of: find.byType(ProjectTabBar),
          matching: find.text(name),
        );
        await t.ensureVisible(label);
        await t.pumpAndSettle();
        await t.tap(label);
        await t.pumpAndSettle();
      }

      await selectTab('Скамья садовая');
      expect(tabs.value.editor, same(editor));
      expect(editor.single?.id, 1);
      editor.undo();
      await t.pumpAndSettle();
      expect(tabs.value.committed.name, 'Скамья');
      expect(other.committed.name, 'Стол');
      await selectTab('Стол');
      Future<void> closeFromMenu() async {
        await t.tap(
          find.descendant(
            of: find.byType(ProjectTabBar),
            matching: find.text(tabs.value.committed.name),
          ),
        );
        await t.pumpAndSettle();
        await t.tap(find.text('Закрыть вкладку'));
        await t.pumpAndSettle();
      }

      await closeFromMenu();
      expect(find.text('Сохранить изменения?'), findsOneWidget);
      await t.tap(find.text('Отмена'));
      await t.pumpAndSettle();
      expect(tabs.value, same(other));
      await closeFromMenu();
      await t.tap(find.text('Не сохранять'));
      await t.pumpAndSettle();
      expect(tabs.items.single.editor, same(editor));
      await closeFromMenu();
      expect(tabs.items.single.committed.name, 'Без названия');
    },
  );

  testWidgets(
    'Autosave checkpoints all tabs at the selected interval and stops when switched off',
    (t) async {
      await t.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final prefs = _Preferences();
      final tabs = ProjectTabs(Editor(Project.bench()));
      final linked = tabs.value..file = const ProjectFile('/tmp/test.neprosto');
      final fileWrites = <String>[];
      final messenger = t.binding.defaultBinaryMessenger;
      const popup = MethodChannel('neprosto/popup');
      messenger.setMockMethodCallHandler(popup, (_) async => null);
      addTearDown(() => messenger.setMockMethodCallHandler(popup, null));
      const files = MethodChannel('neprosto/project-files');
      messenger.setMockMethodCallHandler(files, (call) async {
        expect(call.method, 'write');
        final data = call.arguments['bytes'] as Uint8List;
        fileWrites.add(Project.decode(utf8.decode(data)).name);
        return {'path': linked.file!.path, 'bookmark': 'test'};
      });
      addTearDown(() => messenger.setMockMethodCallHandler(files, null));
      await t.pumpWidget(NeprostoApp.withTabs(tabs, preferences: prefs));
      await t.pumpAndSettle();
      linked.editor.commit(linked.committed.copy(name: 'Первый'));
      await t.tap(find.byTooltip('Новая вкладка'));
      await t.pumpAndSettle();
      await t.tap(find.text('Создать проект'));
      await t.pumpAndSettle();
      await t.tap(find.text('Пустой проект'));
      await t.pumpAndSettle();
      final draft = tabs.value;
      draft.editor.commit(draft.committed.copy(name: 'Второй'));
      await t.pump(const Duration(minutes: 4));
      expect(fileWrites, isEmpty);
      await t.pump(const Duration(minutes: 1));
      await t.pumpAndSettle();
      expect(fileWrites, ['Первый']);
      final restored = ProjectTabs.decode(
        prefs.values[ProjectTabs.storageKey] as String,
      );
      expect(restored.value.committed.name, 'Второй');
      expect(restored.value.dirty, true);
      expect(restored.items.first.dirty, false);
      expect(restored.items.first.file!.bookmark, 'test');

      Future<void> settings() async {
        await t.tap(find.byTooltip('Настройки'));
        await t.pumpAndSettle();
        await t.tap(find.text('Сохранение'));
        await t.pumpAndSettle();
      }

      await settings();
      final interval = find.byType(cu.CupertinoTextField).last;
      expect(t.widget<cu.CupertinoTextField>(interval).controller!.text, '5');
      await t.enterText(interval, '2');
      await t.pumpAndSettle();
      await t.tap(find.text('Готово'));
      await t.pumpAndSettle();
      expect(
        prefs.values['autosave-minutes'],
        2,
        reason:
            'status: ${draft.editor.message}, settings open: ${find.text('Готово').evaluate().isNotEmpty}',
      );
      linked.editor.commit(linked.committed.copy(name: 'Ещё правка'));
      await t.pump(const Duration(minutes: 1));
      expect(fileWrites, hasLength(1));
      await t.pump(const Duration(minutes: 1));
      await t.pumpAndSettle();
      expect(fileWrites.last, 'Ещё правка');
      await settings();
      await t.tap(find.byType(cu.CupertinoSwitch).last);
      await t.pumpAndSettle();
      await t.tap(find.text('Готово'));
      await t.pumpAndSettle();
      expect(prefs.values['autosave-enabled'], false);
      draft.editor.commit(draft.committed.copy(name: 'Только вручную'));
      linked.editor.commit(linked.committed.copy(name: 'Не записывать'));
      await t.pump(const Duration(minutes: 10));
      expect(fileWrites, hasLength(2));
      expect(draft.draft.name, 'Второй');
      expect(linked.dirty, true);
      final linkedTab = find.descendant(
        of: find.byType(ProjectTabBar),
        matching: find.text('Не записывать'),
      );
      await t.ensureVisible(linkedTab);
      await t.pumpAndSettle();
      await t.tap(linkedTab);
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('Сохранить'));
      await t.pumpAndSettle();
      expect(fileWrites.last, 'Не записывать');
      expect(linked.dirty, false);
      final history = ProjectTabs.decode(tabs.encode())
        ..restoreRecent(prefs.values[ProjectTabs.recentKey] as String);
      expect(history.recent.single.name, 'Не записывать');
      expect(history.recent.single.file!.path, linked.file!.path);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets(
    'AppKit receives a single extension filter and a clean suggested stem',
    (t) async {
      const channel = MethodChannel('plugins.flutter.io/file_selector');
      final messenger = t.binding.defaultBinaryMessenger;
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.arguments['suggestedName'], 'Скамья 1.2');
        expect(call.arguments['acceptedTypeGroups'].single['extensions'], [
          'neprosto',
        ]);
        return null;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      for (final suffix in ['', '.neprosto', '.NEPROSTO.neprosto']) {
        expect(
          await chooseProjectFile(Project('Скамья 1.2$suffix', [])),
          isNull,
        );
      }
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );
}
