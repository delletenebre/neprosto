import 'editor/native_appearance.dart';

import 'package:flutter_localizations/flutter_localizations.dart'
    show GlobalWidgetsLocalizations;

import 'editor/palette.dart';
import 'l10n/app_localizations.dart';
import 'l10n/strings.dart';
import 'editor/desk_text_field.dart';
import 'editor/desktop.dart';
import 'editor/platform_ui.dart';

import 'package:cupertino_ui/cupertino_ui.dart' as cu;

import 'dart:async';
import 'dart:convert';
import 'dart:ui' show AppExitResponse, ViewFocusEvent, ViewFocusState;

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:material_ui/material_ui.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart'
    show PhosphorIconsRegular;
import 'package:shared_preferences/shared_preferences.dart';

import 'editor/controller.dart';
import 'editor/hotkeys.dart';
import 'editor/grid_controls.dart';
import 'editor/grid_visibility.dart';
import 'editor/settings.dart';
import 'editor/controls.dart';
import 'editor/drawing.dart';
import 'editor/inspector.dart';
import 'editor/model.dart';
import 'editor/parts_panel.dart';
import 'editor/part_type_picker.dart';
import 'editor/parts_list.dart';
import 'editor/project_settings.dart';
import 'editor/project_picker.dart';
import 'editor/template_picker.dart';
import 'editor/project_tabs.dart';
import 'editor/project_tab_bar.dart';
import 'editor/scene.dart';
import 'editor/step.dart';
import 'editor/storage.dart';
import 'editor/viewport.dart';
import 'editor/work_plane_picker.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = SharedPreferencesAsync();
  var language = const Locale('ru');
  EditorPalette? palette;
  try {
    final code = await prefs.getString('interface-language');
    language =
        editorLocales
            .where((locale) => locale.languageCode == code)
            .firstOrNull ??
        language;
    final saved = await prefs.getString('interface-theme');
    palette = EditorPalette.values
        .where((value) => value.name == saved)
        .firstOrNull;
  } catch (_) {
    // An unavailable preference store must not prevent the editor from opening.
  }
  editorStrings = lookupAppLocalizations(language);
  var tabs = ProjectTabs(Editor(Project.bench()));
  String? issue;
  var autosave = true, minutes = 5;
  try {
    final session = await prefs.getString(ProjectTabs.storageKey);
    if (session != null) {
      tabs = ProjectTabs.decode(session);
    } else if (await prefs.getString('drawing-v1') case final draft?) {
      tabs = ProjectTabs(Editor(Project.decode(draft)), dirty: true);
    }
  } catch (_) {
    issue = editorStrings.draftOpenError;
  }
  try {
    tabs.restoreRecent(await prefs.getString(ProjectTabs.recentKey));
  } catch (_) {
    tabs.restoreRecent(null);
  }
  final editor = tabs.value.editor;
  try {
    autosave = await prefs.getBool('autosave-enabled') ?? true;
    final interval = await prefs.getInt('autosave-minutes');
    if (interval != null && interval > 0) minutes = interval;
    editor.snapByDefault = await prefs.getBool('move-snap-default') ?? true;
    editor.dimensionsByDefault =
        await prefs.getBool('dimensions-by-default') ?? true;
    editor.showHiddenOutlines =
        await prefs.getBool('show-hidden-outlines') ?? false;
    editor.gridVisibility = GridVisibility.decode(
      await prefs.getInt('grid-planes-v1'),
    );
    final bindings = await prefs.getString('hotkeys-v1');
    if (bindings != null) editor.hotkeys = EditorHotkeys.decode(bindings);
    final data = await prefs.getString('edit-step-v1');
    if (data != null) editor.step = EditStep.decode(data);
  } catch (_) {
    /* Keep default input increments for an unreadable preference. */
  }
  runApp(
    NeprostoApp.withTabs(
      tabs,
      preferences: prefs,
      initialMessage: issue,
      initialLocale: language,
      initialPalette: palette,
      autosave: autosave,
      autosaveMinutes: minutes,
    ),
  );
}

class NeprostoApp extends StatefulWidget {
  final Locale initialLocale;
  final EditorPalette? initialPalette;
  final ProjectTabs tabs;
  final SharedPreferencesAsync? preferences;
  final String? initialMessage;
  final bool autosave;
  final int autosaveMinutes;
  NeprostoApp({
    Key? key,
    required Editor editor,
    SharedPreferencesAsync? preferences,
    String? initialMessage,
    bool restored = false,
  }) : this.withTabs(
         ProjectTabs(editor, dirty: restored),
         key: key,
         preferences: preferences,
         initialMessage: initialMessage,
       );
  const NeprostoApp.withTabs(
    this.tabs, {
    super.key,
    this.preferences,
    this.initialMessage,
    this.initialLocale = const Locale('ru'),
    this.initialPalette,
    this.autosave = true,
    this.autosaveMinutes = 5,
  });
  @override
  State<NeprostoApp> createState() => _NeprostoAppState();
}

class _NeprostoAppState extends State<NeprostoApp> {
  late Locale locale = widget.initialLocale;
  late EditorPalette? overridePalette = widget.initialPalette;

  @override
  void initState() {
    super.initState();
    editorStrings = lookupAppLocalizations(locale);
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<ProjectTab>(
    valueListenable: widget.tabs,
    builder: (context, tab, _) {
      final editor = tab.editor;
      final palette =
          overridePalette ??
          (MediaQuery.platformBrightnessOf(context) == Brightness.dark
              ? EditorPalette.dark
              : EditorPalette.light);
      final material = palette.materialTheme(
        macControls
            ? '.AppleSystemUIFont'
            : defaultTargetPlatform == TargetPlatform.windows
            ? 'Segoe UI'
            : null,
      );
      const delegates = [
        AppLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        cu.GlobalCupertinoLocalizations.delegate,
      ];
      final home = Workspace(
        widget.tabs,
        widget.preferences,
        widget.initialMessage,
        widget.autosave,
        widget.autosaveMinutes,
        palette: palette,
        followSystemTheme: overridePalette == null,
        locale: locale,
        onAppearance: (next, language) {
          if (next == overridePalette && language == locale) return;
          setState(() {
            overridePalette = next;
            if (language != locale) {
              locale = language;
              editorStrings = lookupAppLocalizations(language);
            }
          });
        },
      );
      Widget withUnits(BuildContext context, Widget? child) =>
          ListenableBuilder(
            listenable: editor,
            child: child,
            builder: (_, child) => Units(
              editor.lengthInput,
              anglePrecision: editor.step.anglePrecision,
              child: child!,
            ),
          );
      if (!appleControls) {
        return MaterialApp(
          title: 'neprosto',
          debugShowCheckedModeBanner: false,
          locale: locale,
          supportedLocales: editorLocales,
          localizationsDelegates: delegates,
          theme: material,
          builder: (context, child) => Material(
            type: MaterialType.transparency,
            child: withUnits(context, child),
          ),
          home: home,
        );
      }
      return cu.CupertinoApp(
        title: 'neprosto',
        locale: locale,
        supportedLocales: editorLocales,
        builder: (context, child) => Theme(
          data: material,
          child: Material(
            type: MaterialType.transparency,
            textStyle: cu.CupertinoTheme.of(context).textTheme.textStyle,
            child: withUnits(context, child),
          ),
        ),
        debugShowCheckedModeBanner: false,
        localizationsDelegates: delegates,
        theme: cu.CupertinoThemeData(
          brightness: palette.brightness,
          primaryColor: palette.accent,
          scaffoldBackgroundColor: palette.panel,
          textTheme: cu.CupertinoTextThemeData(
            textStyle: TextStyle(
              fontFamily: '.AppleSystemUIFont',
              fontSize: 13,
              color: palette.ink,
            ),
          ),
        ),
        home: home,
      );
    },
  );
}

class Workspace extends StatefulWidget {
  final EditorPalette palette;
  final bool followSystemTheme;
  final Locale locale;
  final void Function(EditorPalette?, Locale) onAppearance;
  const Workspace(
    this.tabs,
    this.preferences,
    this.initialMessage,
    this.autosave,
    this.autosaveMinutes, {
    required this.palette,
    required this.followSystemTheme,
    required this.locale,
    required this.onAppearance,
    super.key,
  });
  final ProjectTabs tabs;
  final SharedPreferencesAsync? preferences;
  final String? initialMessage;
  final bool autosave;
  final int autosaveMinutes;
  @override
  State<Workspace> createState() => _WorkspaceState();
}

class _WorkspaceState extends State<Workspace> with WidgetsBindingObserver {
  ProjectTabs get tabs => widget.tabs;
  ProjectTab get active => tabs.value;
  Editor get e => active.editor;
  GlobalKey<DrawingViewportState> get viewportKey =>
      GlobalObjectKey<DrawingViewportState>(e);
  bool partsVisible = true, inspectorVisible = true, fileBusy = false;
  bool? hasWindowToolbar;
  Object? lastToolbarState;
  static const menu = MethodChannel('neprosto/editor');
  Future<void> writes = Future.value();
  List<RecentProject>? cachedRecent;
  bool retryDraft = false;
  late bool autosave = widget.autosave;
  late int autosaveMinutes = widget.autosaveMinutes;
  Timer? autosaveTimer;
  Future<void>? autosaving;
  @override
  void initState() {
    super.initState();
    scheduleAutosave();
    if (widget.initialMessage != null) e.message = widget.initialMessage!;
    syncNativeKeys();
    unawaited(syncAppearance());
    HardwareKeyboard.instance.addHandler(keyEvent);
    FocusManager.instance.addEarlyKeyEventHandler(dimensionTab);
    WidgetsBinding.instance.addObserver(this);
    menu.setMethodCallHandler((call) async {
      if (!{'undo', 'redo', 'selectAll'}.contains(call.method)) {
        if (ModalRoute.isCurrentOf(context) != true || fileBusy) return;
        switch (call.method) {
          case 'new' ||
              'open' ||
              'save' ||
              'saveAs' ||
              'rename' ||
              'close' ||
              'projectSettings':
            await file(call.method);
          case 'settings':
            await editSettings();
          case 'partsList':
            await showPartsList();
          case 'partsSidebar':
            toggleParts();
          case 'inspector':
            toggleInspector();
          case 'zoomIn':
            zoom(1.25);
          case 'zoomOut':
            zoom(.8);
          case 'fit':
            dispatch(Command.fit);
        }
        return;
      }
      final focus = FocusManager.instance.primaryFocus?.context;
      if (focus?.findAncestorWidgetOfExactType<EditableText>() != null) {
        Actions.maybeInvoke(focus!, switch (call.method) {
          'undo' => const UndoTextIntent(SelectionChangedCause.keyboard),
          'redo' => const RedoTextIntent(SelectionChangedCause.keyboard),
          _ => const SelectAllTextIntent(SelectionChangedCause.keyboard),
        });
      } else if (ModalRoute.of(context)?.isCurrent == true) {
        dispatch(Command.values.byName(call.method));
      }
    });
  }

  Future<void> syncAppearance() => updateNativeAppearance(
    widget.followSystemTheme ? null : widget.palette,
    editorStrings,
  );

  void toggleParts() => setState(() => partsVisible = !partsVisible);
  void toggleInspector() =>
      setState(() => inspectorVisible = !inspectorVisible);

  Future<void> syncDocumentToolbar() async {
    if (!macControls || kIsWeb || hasWindowToolbar == false) return;
    final state = (
      active.committed.name,
      active.dirty,
      partsVisible,
      inspectorVisible,
      widget.locale,
    );
    if (lastToolbarState == state) return;
    lastToolbarState = state;
    final s = context.strings;
    bool installed;
    try {
      installed =
          await const MethodChannel(
            'neprosto/popup',
          ).invokeMethod<bool>('documentToolbar', {
            'title': active.committed.name,
            'edited': active.dirty,
            'labels': {'partsSidebar': s.partsTree, 'inspector': s.properties},
            'panels': {
              'partsSidebar': partsVisible,
              'inspector': inspectorVisible,
            },
          }) ==
          true;
    } on MissingPluginException {
      installed = false;
    }
    if (mounted && installed != hasWindowToolbar) {
      setState(() => hasWindowToolbar = installed);
    }
  }

  bool? workspaceMenuEnabled;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (macControls && !kIsWeb) {
      final enabled = ModalRoute.isCurrentOf(context) == true;
      if (enabled != workspaceMenuEnabled) {
        workspaceMenuEnabled = enabled;
        unawaited(syncMenuAvailability(enabled));
      }
    }
  }

  Future<void> syncMenuAvailability(bool enabled) async {
    try {
      await const MethodChannel('neprosto/popup')
          .invokeMethod<void>('workspaceMenuEnabled', enabled);
    } on MissingPluginException {
      // The Flutter test host has no menu bar.
    }
  }

  @override
  void didUpdateWidget(Workspace oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.followSystemTheme != oldWidget.followSystemTheme ||
        widget.palette != oldWidget.palette ||
        widget.locale != oldWidget.locale) {
      unawaited(syncAppearance());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    FocusManager.instance.removeEarlyKeyEventHandler(dimensionTab);
    HardwareKeyboard.instance.removeHandler(keyEvent);
    menu.setMethodCallHandler(null);

    autosaveTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) e.releaseModifiers();
  }

  @override
  Future<AppExitResponse> didRequestAppExit() async {
    if (autosaving case final pending?) await pending;
    if (mounted &&
        autosave &&
        (retryDraft || tabs.items.any((tab) => tab.draft != tab.committed))) {
      for (final tab in tabs.items) {
        tab.draft = tab.committed;
      }
      cache();
    }
    await writes;
    return AppExitResponse.exit;
  }

  @override
  void didChangeViewFocus(ViewFocusEvent event) {
    if (event.state == ViewFocusState.unfocused) e.releaseModifiers();
  }

  bool get editingText =>
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<EditableText>() !=
      null;

  PhysicalKeyboardKey? heldDimensionKey;

  // Release a held shortcut even when focus has since moved into a field or dialog.
  bool keyEvent(KeyEvent event) {
    if (event is! KeyUpEvent || event.physicalKey != heldDimensionKey) {
      return false;
    }
    heldDimensionKey = null;
    e.holdDimensionTab(false);
    return true;
  }

  KeyEventResult dimensionTab(KeyEvent event) {
    if (heldDimensionKey == event.physicalKey && e.dimensionTabHeld) {
      return KeyEventResult.handled;
    }
    if (event is! KeyDownEvent ||
        event.synthesized ||
        ModalRoute.of(context)?.isCurrent != true) {
      return KeyEventResult.ignored;
    }
    if ((!editingText || e.tool == Tool.align) &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      e.setTool(
        e.tool == Tool.measure || e.tool == Tool.gap ? Tool.ruler : Tool.select,
      );
      return KeyEventResult.handled;
    }
    if (e.canApplyRotation &&
        !editingText &&
        const [
          SingleActivator(LogicalKeyboardKey.enter),
          SingleActivator(LogicalKeyboardKey.numpadEnter),
        ].any((key) => key.accepts(event, HardwareKeyboard.instance))) {
      e.applyRotation();
      return KeyEventResult.handled;
    }
    final chord = chordFor(event);
    if (chord == null) return KeyEventResult.ignored;
    final command = e.hotkeys.commandFor(chord);
    if (command == null ||
        (editingText &&
            !(chord.primary &&
                (command == Command.save ||
                    command == Command.saveAs ||
                    command == Command.closeTab)))) {
      return KeyEventResult.ignored;
    }
    if (command == Command.dimensions) heldDimensionKey = event.physicalKey;
    return dispatch(command) ? KeyEventResult.handled : KeyEventResult.ignored;
  }

  void cache() {
    final prefs = widget.preferences;
    if (prefs == null) return;
    final data = tabs.encode();
    final recent = tabs.recent;
    writes = writes.then((_) async {
      try {
        await prefs.setString(ProjectTabs.storageKey, data);
        if (recent.isNotEmpty && !identical(cachedRecent, recent)) {
          await prefs.setString(ProjectTabs.recentKey, jsonEncode(recent));
          cachedRecent = recent;
        }
        retryDraft = false;
      } catch (_) {
        retryDraft = true;
        if (mounted) {
          e.message = editorStrings.draftSaveError;
          e.refresh();
        }
      }
    });
  }

  void scheduleAutosave() {
    autosaveTimer?.cancel();
    if (!autosave) return;
    var lastSaveTick = 0;
    autosaveTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (timer.tick - lastSaveTick < autosaveMinutes ||
          fileBusy ||
          autosaving != null) {
        return;
      }
      lastSaveTick = timer.tick;
      autosaving = autosaveTabs().whenComplete(() => autosaving = null);
    });
  }

  Future<void> autosaveTabs() async {
    var changed = false;
    for (final tab in tabs.items.toList()) {
      if (!mounted || !autosave) break;
      final project = tab.committed;
      if (tab.draft != project) {
        tab.draft = project;
        changed = true;
      }
      final file = tab.file;
      if (file == null || !tab.dirty) continue;
      try {
        final output = await writeProject(project, file);
        tab.file = output;
        tabs.refreshRecentFile(file, output, project.name);
        tab.saved = project;
        changed = true;
      } catch (_) {
        tab.editor.message = editorStrings.updateProjectError;
      }
      tab.editor.refresh();
    }
    if (mounted && (changed || retryDraft)) {
      cache();
      setState(() {});
    }
  }

  bool dispatch(Command command) {
    switch (command) {
      case Command.settings:
        unawaited(editSettings());
      case Command.undo:
        e.undo();
      case Command.redo:
        e.redo();
      case Command.group:
        e.group();
      case Command.ungroup:
        e.ungroup();
      case Command.duplicate:
        e.duplicate();
      case Command.stretchWidth || Command.stretchHeight:
        if (e.tool != Tool.select || e.single == null) return false;
        e.stretchBetweenSupports(height: command == Command.stretchHeight);
      case Command.delete:
        e.delete();
      case Command.open:
        unawaited(file('open'));
      case Command.save:
        unawaited(file('save'));
      case Command.saveAs:
        unawaited(file('saveAs'));
      case Command.closeTab:
        unawaited(file('close'));
      case Command.newProject:
        unawaited(file('new'));
      case Command.selectAll:
        e.selectAll();
      case Command.hideSelected:
        e.setPartsHidden(e.selection, true);
      case Command.fit:
        e.fitRequested = true;
        e.refresh();
      case Command.dimensions:
        e.holdDimensionTab(true);
      case Command.select:
        e.setTool(Tool.select);
      case Command.add:
        e.setTool(e.rulerActive ? Tool.measure : Tool.beam);
      case Command.addWithDimensions:
        unawaited(viewportKey.currentState?.addWithDimensions());
      case Command.measure:
        openRuler();
      case Command.move:
        e.setTool(Tool.move);
      case Command.rotate:
        if (e.selection.isEmpty) return false;
        e.setTool(Tool.rotate);
      case Command.left ||
          Command.right ||
          Command.up ||
          Command.down ||
          Command.stopLeft ||
          Command.stopRight ||
          Command.stopUp ||
          Command.stopDown:
        if (e.tool != Tool.select || e.selection.isEmpty) return false;
        final horizontal = {
          Command.left,
          Command.right,
          Command.stopLeft,
          Command.stopRight,
        }.contains(command);
        final positive = {
          Command.right,
          Command.up,
          Command.stopRight,
          Command.stopUp,
        }.contains(command);
        final untilStop = {
          Command.stopLeft,
          Command.stopRight,
          Command.stopUp,
          Command.stopDown,
        }.contains(command);
        e.shift(horizontal ? 0 : 1, positive ? 1 : -1, untilStop: untilStop);
    }
    return true;
  }

  Future<String?> nameDialog(
    String title,
    String value, {
    DoorSettingsDraft? door,
    DialogSource? source,
  }) {
    var result = value;
    return showDeskDialog<String>(
      source: source,
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (_, update) {
          final ready = result.trim().isNotEmpty && (door?.valid ?? true);
          void submit() {
            if (result.trim().isNotEmpty && (door?.valid ?? true)) {
              Navigator.pop(ctx, result.trim());
            }
          }

          return DeskDialog(
            title: Text(title),
            content: SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 12,
                children: [
                  DeskTextField(
                    key: const ValueKey('rename-field'),
                    initialValue: value,
                    autofocus: true,
                    onChanged: (v) => update(() => result = v),
                    onSubmitted: (_) => submit(),
                  ),
                  if (door != null)
                    PartTypePicker(
                      door,
                      refresh: () => update(() {}),
                      submit: submit,
                    ),
                ],
              ),
            ),
            actions: [
              DeskButton(
                plain: true,
                onPressed: () => Navigator.pop(ctx),
                child: Text(context.strings.cancel),
              ),
              DeskButton(
                primary: true,
                onPressed: ready ? submit : null,
                child: Text(context.strings.done),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> renamePart(Beam part) async {
    final editor = e;
    final door = DoorSettingsDraft(part);
    final name = await nameDialog(
      context.strings.partName,
      part.name,
      door: door,
    );
    if (name == null || !mounted || editor.project.byId[part.id] != part) {
      return;
    }
    if (name == part.name &&
        door.hinge == part.hinge &&
        (door.hinge == null || door.angle == part.openingAngle)) {
      return;
    }
    final named = name == part.name ? part : part.copy(name: name);
    final updated = editor.configureDoor(named, door.hinge, angle: door.angle);
    editor.commit(editor.project.edit({part.id}, (_) => updated));
  }

  Future<void> showPartsList() async {
    FocusManager.instance.primaryFocus?.unfocus();
    FocusManager.instance.applyFocusChangesIfNeeded();
    await showDeskDialog<void>(
      source:
          DialogSource.current ??
          DialogSource.of(partsListButton.currentContext),
      context: context,
      barrierDismissible: true,
      builder: (_) => PartsList(e),
    );
  }

  Future<bool> closeAllowed(ProjectTab tab, DialogSource? source) async {
    if (!tab.dirty) return true;
    final answer = await showDeskDialog<int>(
      source: source,
      context: context,
      builder: (ctx) => DeskDialog(
        maxWidth: 352,
        title: Row(
          children: [
            Icon(
              cu.CupertinoIcons.doc_text,
              size: 22,
              color: context.colors.accent,
            ),
            SizedBox(width: 9),
            Expanded(child: Text(context.strings.saveChanges)),
          ],
        ),
        content: Text(
          context.strings.discardChangesWarning(tab.committed.name),
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: context.colors.muted,
          ),
        ),
        actions: [
          DeskButton(
            plain: true,
            onPressed: () => Navigator.pop(ctx, 1),
            child: Text(context.strings.discardChanges),
          ),
          DeskButton(
            onPressed: () => Navigator.pop(ctx, 0),
            child: Text(context.strings.cancel),
          ),
          DeskButton(
            primary: true,
            onPressed: () => Navigator.pop(ctx, 2),
            child: Text(context.strings.save),
          ),
        ],
      ),
    );
    if (answer == 2) return await save(tab) && !tab.dirty;
    return answer == 1;
  }

  Future<void> saveSnapDefault(bool value) async {
    e.snapByDefault = value;
    e.refresh();
    try {
      await widget.preferences?.setBool('move-snap-default', value);
    } catch (_) {
      e.message = editorStrings.snapSaveError;
      e.refresh();
    }
  }

  bool settingsOpen = false;
  bool gridControlsOpen = false;
  final settingsButton = GlobalKey();
  final newProjectButton = GlobalKey();
  final partsListButton = GlobalKey();
  final gridButton = GlobalKey();
  Future<void> gridWrites = Future.value();

  Future<void> saveGrid(GridVisibility value) {
    final prefs = widget.preferences;
    if (prefs == null) return Future.value();
    gridWrites = gridWrites
        .then((_) => prefs.setInt('grid-planes-v1', value.encode()))
        .catchError((Object _) {
          if (mounted) {
            e.message = editorStrings.gridSaveError;
            e.refresh();
          }
        });
    return gridWrites;
  }

  Future<void> showGridControls() async {
    if (gridControlsOpen) return;
    final source = DialogSource.of(gridButton.currentContext)!;
    final overlay =
        Navigator.of(
              context,
              rootNavigator: true,
            ).overlay!.context.findRenderObject()!
            as RenderBox;
    setState(() => gridControlsOpen = true);
    try {
      await showDeskDialog<void>(
        source: source,
        useSafeArea: false,
        context: context,
        barrierDismissible: true,
        barrierLabel: context.strings.closeGridSettings,
        barrierColor: Colors.transparent,
        builder: (ctx) => LayoutBuilder(
          builder: (_, box) {
            final anchor = overlay.globalToLocal(source.bounds.bottomRight);
            return Stack(
              children: [
                Positioned(
                  right: (box.maxWidth - anchor.dx).clamp(
                    0.0,
                    (box.maxWidth - 265).clamp(0.0, box.maxWidth),
                  ),
                  top: anchor.dy + 5,
                  child: IntrinsicWidth(
                    child: Container(
                      key: DeskDialogRoute.surfaceKey(ctx),
                      constraints: const BoxConstraints(minWidth: 265),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.colors.panel,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: context.colors.line,
                          width: .8,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x28000000),
                            offset: Offset(0, 4),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                      child: ListenableBuilder(
                        listenable: e,
                        builder: (_, _) =>
                            GridControls(e.gridVisibility, (next) {
                              e.gridVisibility = next;
                              e.refresh();
                              unawaited(saveGrid(next));
                            }),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );
    } finally {
      if (mounted) setState(() => gridControlsOpen = false);
    }
  }

  Future<void> syncNativeKeys() async {
    if (defaultTargetPlatform != TargetPlatform.macOS || kIsWeb) return;
    try {
      await const MethodChannel('neprosto/popup').invokeMethod<void>(
        'editorShortcuts',
        {
          'quit': e.hotkeys.commandFor(Command.stretchHeight.standard) == null,
          for (final command in [
            Command.newProject,
            Command.open,
            Command.save,
            Command.saveAs,
            Command.closeTab,
            Command.undo,
            Command.redo,
            Command.settings,
            Command.selectAll,
          ])
            command.name: e.hotkeys[command] == command.standard,
        },
      );
    } on MissingPluginException {
      // Widget tests and older running native hosts use Flutter shortcuts.
    }
  }

  Future<void> editSettings() async {
    if (settingsOpen) return;
    settingsOpen = true;
    e.releaseModifiers();
    final originalPalette = widget.followSystemTheme ? null : widget.palette;
    final originalLocale = widget.locale;
    try {
      final result = await showDeskDialog<SettingsResult>(
        source:
            DialogSource.current ??
            DialogSource.of(settingsButton.currentContext),
        context: context,
        builder: (_) => EditorSettings(
          e,
          palette: originalPalette,
          locale: originalLocale,
          onPreview: widget.onAppearance,
          autosave: autosave,
          autosaveMinutes: autosaveMinutes,
        ),
      );
      if (!mounted) return;
      if (result == null) {
        widget.onAppearance(originalPalette, originalLocale);
        return;
      }
      final theme = result.palette;
      final languageChanged = result.locale != originalLocale;
      widget.onAppearance(theme, result.locale);
      if (languageChanged) {
        for (final tab in tabs.items) {
          tab.editor.message = '';
        }
      }
      if (autosave != result.autosave ||
          autosaveMinutes != result.autosaveMinutes) {
        autosave = result.autosave;
        autosaveMinutes = result.autosaveMinutes;
        scheduleAutosave();
      }
      e.hotkeys = result.hotkeys;
      e.step = result.step;
      e.gridVisibility = result.grid;
      e.dimensionsByDefault = result.dimensions;
      e.showHiddenOutlines = result.showHiddenOutlines;
      e.snapByDefault = result.snap;
      if (e.project.unit != result.unit) {
        e.commit(e.project.copy(unit: result.unit));
      } else {
        e.refresh();
      }
      final prefs = widget.preferences;
      if (prefs != null) {
        await Future.wait([
          if (theme != null && theme != originalPalette)
            prefs.setString('interface-theme', theme.name),
          if (languageChanged)
            prefs.setString('interface-language', result.locale.languageCode),
          prefs.setBool('autosave-enabled', autosave),
          prefs.setInt('autosave-minutes', autosaveMinutes),
          saveGrid(result.grid),
          prefs.setString('hotkeys-v1', result.hotkeys.encode()),
          prefs.setString('edit-step-v1', result.step.encode()),
          prefs.setBool('dimensions-by-default', result.dimensions),
          prefs.setBool('show-hidden-outlines', result.showHiddenOutlines),
          prefs.setBool('move-snap-default', result.snap),
        ]);
      }
      await syncNativeKeys();
    } catch (_) {
      e.message = editorStrings.settingsSaveError;
      e.refresh();
    } finally {
      settingsOpen = false;
    }
  }

  Future<bool> save(ProjectTab tab, {bool saveAs = false}) async {
    final current = tab.committed;
    final target = !saveAs && tab.file != null
        ? tab.file!
        : await chooseProjectFile(current);
    if (target == null) return false;
    final owner = tabs.forDocument(target.path);
    if (owner != null && owner != tab) {
      e.message = editorStrings.fileAlreadyOpen;
      e.refresh();
      return false;
    }
    final output = await writeProject(current, target);
    if (!kIsWeb) {
      tab.file = output;
      tab.recentId = null;
    }
    tabs.remember(tabs.savedDocument(tab, current), previousId: target.path);
    tab.saved = tab.draft = current;
    tab.editor.message = editorStrings.projectSaved;
    tab.editor.refresh();
    cache();
    return true;
  }

  void focusTab(ProjectTab tab) {
    if (fileBusy || tab == active) return;
    FocusManager.instance.primaryFocus?.unfocus();
    FocusManager.instance.applyFocusChangesIfNeeded();
    tabs.select(tab);
    cache();
  }

  Future<void> file(String action, {ProjectTab? tab}) async {
    if (fileBusy) return;
    fileBusy = true;
    try {
      FocusManager.instance.primaryFocus?.unfocus();
      FocusManager.instance.applyFocusChangesIfNeeded();
      if (autosaving case final pending?) await pending;
      if (!mounted) return;
      final source =
          DialogSource.current ??
          DialogSource.of(
            action == 'new' || action == 'addTab'
                ? newProjectButton.currentContext
                : GlobalObjectKey(tab ?? active).currentContext,
          );
      RecentProject? recent;
      if (action == 'addTab') {
        final choice = await chooseProjectForTab(
          context,
          tabs.recent,
          source: source,
        );
        if (!mounted || choice == null) return;
        action = choice.action;
        recent = choice.recent;
      }
      if (action == 'projectSettings') {
        await showProjectSettings(context, e, source: source);
        return;
      }
      if (action == 'save' || action == 'saveAs') {
        await save(active, saveAs: action == 'saveAs');
        return;
      }
      if (action == 'rename') {
        final document = tab ?? active;
        final value = await nameDialog(
          context.strings.projectName,
          document.committed.name,
          source: source,
        );
        if (value != null && mounted && tabs.items.contains(document)) {
          document.editor.commit(document.editor.project.copy(name: value));
          if (document != active) setState(() {});
        }
        return;
      }
      switch (action) {
        case 'close':
          final closing = tab ?? active;
          if (!await closeAllowed(closing, source) || !mounted) return;
          tabs.close(closing);
        case 'open':
          final input = await openProject();
          if (!mounted || input == null) return;
          tabs.openDocument(input.project, source: input.file);
        case 'recent':
          final entry = recent!;
          final existing = tabs.forDocument(entry.id);
          if (existing != null) {
            tabs.select(existing);
            tabs.remember(entry);
          } else if (entry.file case final file?) {
            final input = await readProjectFile(file);
            if (!mounted) return;
            tabs.openDocument(
              input.project,
              source: input.file,
              recentId: entry.id,
            );
          } else {
            tabs.openDocument(entry.snapshot!, recentId: entry.id);
          }
        case 'new':
          final choice = await chooseProjectTemplate(
            context,
            e.project.unit,
            source: source,
          );
          if (!mounted || choice == null) return;
          tabs.create(template: choice.template, unit: choice.unit);
        default:
          return;
      }
      cache();
    } catch (error) {
      if (!mounted) return;
      e.message = action == 'open' || action == 'recent'
          ? context.strings.openProjectError
          : context.strings.saveProjectError;
      e.refresh();
    } finally {
      fileBusy = false;
    }
  }

  void openRuler() {
    if (!partsVisible) setState(() => partsVisible = true);
    e.setTool(Tool.ruler);
  }

  String get hint {
    if (e.pickingAlignmentSupport) return context.strings.clickTheReferencePart;
    if (e.partToPlace != null) return context.strings.placePartHint;
    if (e.tool == Tool.beam && e.first != null) {
      final kb = HardwareKeyboard.instance;
      if (kb.isMetaPressed || kb.isControlPressed) {
        final mode = kb.isShiftPressed
            ? context.strings.straightUpAlongZ
            : context.strings.tiltInAVerticalPlane;
        return e.camera.up.z.abs() < .20
            ? context.strings.heightGesture(mode)
            : context.strings.placeEndHint(mode);
      }
      final prefix = e.message.isEmpty
          ? context.strings.setTheEndOfThePart
          : e.message;
      return context.strings.liftHint(prefix, primaryModifierLabel);
    }
    if (e.message.isNotEmpty) return e.message;
    return switch (e.tool) {
      Tool.select => switch (e.selection.length) {
        0 => context.strings.addPartHint(e.hotkeys[Command.add].label),
        1 => context.strings.moveResizeHint,
        _ => context.strings.multiSelectionMenuHint,
      },
      Tool.move =>
        e.first == null
            ? context.strings.setTheSourceAnchorOnThePart
            : context.strings.setTheDestinationAnchor,
      Tool.beam =>
        e.first == null
            ? context.strings.setTheStartOfThePart
            : context.strings.setTheEndOfThePart,
      Tool.ruler => context.strings.selectDimensionHint(
        e.hotkeys[Command.add].label,
      ),
      Tool.measure =>
        e.first == null
            ? context.strings.setTheFirstDimensionPoint
            : context.strings.setTheSecondDimensionPoint,
      Tool.align =>
        e.first == null
            ? context.strings.chooseAlignmentHint
            : e.selection.contains(e.first!.beam)
            ? context.strings.setTheDestinationAnchor
            : context.strings.chooseMovingAnchor,
      Tool.gap =>
        e.firstShelf == null
            ? context.strings.selectTheFirstShelf
            : context.strings.selectTheSecondShelf,
      Tool.face => context.strings.selectWorkPlaneFace,
      Tool.rotate => context.strings.rotationInputHint,
    };
  }

  Widget header() => Container(
    height: macControls ? (hasWindowToolbar == true ? 31 : 35) : 47,
    padding: EdgeInsets.symmetric(horizontal: macControls ? 0 : 15),
    decoration: BoxDecoration(
      color: context.colors.chrome,
      border: Border(bottom: BorderSide(color: context.colors.line)),
    ),
    child: Row(
      children: [
        if (!macControls) ...[
          const Mark(),
          const SizedBox(width: 8),
          const Text(
            'neprosto',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.1,
            ),
          ),
          const SizedBox(width: 17),
          const SizedBox(height: 22, child: VerticalDivider()),
          const SizedBox(width: 8),
        ],
        if (macControls && hasWindowToolbar != true)
          iconAction(
            cu.CupertinoIcons.sidebar_left,
            context.strings.partsTree,
            toggleParts,
          ),
        Expanded(
          child: ProjectTabBar(
            newProjectButton: newProjectButton,
            tabs: tabs.items,
            active: active,
            select: focusTab,
            addTab: () => file('addTab'),
            close: (tab) => file('close', tab: tab),
            menuItems: [
              if (!macControls || kIsWeb) ...[
                ('new', context.strings.newProject),
                ('open', context.strings.openProjectMenu),
              ],
              ('save', context.strings.saveProject),
              ('saveAs', context.strings.saveAs),
              ('rename', context.strings.rename),
              ('projectSettings', context.strings.projectSettingsMenu),
              if ((!macControls || kIsWeb) &&
                  (!partsVisible || MediaQuery.sizeOf(context).width < 780))
                ('partsList', context.strings.partsList),
              ('close', context.strings.closeTab),
            ],
            onMenuAction: (action, tab) => action == 'partsList'
                ? showPartsList()
                : file(action, tab: tab),
          ),
        ),
        if (macControls && hasWindowToolbar != true)
          iconAction(
            cu.CupertinoIcons.sidebar_right,
            context.strings.properties,
            toggleInspector,
          ),
      ],
    ),
  );
  void zoom(double factor) {
    e.camera.scale = (e.camera.scale * factor).clamp(.005, 100);
    e.camera.pan *= factor;
    e.refresh();
  }

  List<Widget> drawingTools() => [
    for (final (tool, icon, title) in [
      (
        Tool.select,
        cu.CupertinoIcons.location_north,
        context.strings.selectShortcut(e.hotkeys[Command.select].label),
      ),
      (
        Tool.move,
        cu.CupertinoIcons.move,
        context.strings.anchorShortcut(e.hotkeys[Command.move].label),
      ),
      (
        Tool.rotate,
        cu.CupertinoIcons.arrow_clockwise,
        context.strings.rotateShortcut(e.hotkeys[Command.rotate].label),
      ),
      (
        Tool.ruler,
        Icons.straighten,
        context.strings.measureShortcut(e.hotkeys[Command.measure].label),
      ),
    ])
      iconAction(
        icon,
        title,
        tool == Tool.rotate && e.selection.isEmpty
            ? null
            : tool == Tool.ruler
            ? openRuler
            : () => e.setTool(tool),
        active: tool == Tool.ruler ? e.rulerActive : e.tool == tool,
      ),
    if (e.project.hasHiddenParts)
      iconAction(
        cu.CupertinoIcons.eye,
        context.strings.showAllParts,
        e.showAllHiddenParts,
      ),
  ];

  Widget viewportToolbar() {
    Widget group(List<Widget> controls, {double spacing = 2}) => Wrap(
      spacing: spacing,
      runSpacing: toolbarGap,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: controls,
    );

    Widget afterDivider(Widget controls) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 16, child: VerticalDivider(width: 15)),
        Flexible(child: controls),
      ],
    );

    final documentActions = group([
      iconAction(
        cu.CupertinoIcons.arrow_uturn_left,
        context.strings.undo,
        e.canUndo ? e.undo : null,
      ),
      iconAction(
        cu.CupertinoIcons.arrow_uturn_right,
        context.strings.redo,
        e.canRedo ? e.redo : null,
      ),
      iconAction(
        PhosphorIconsRegular.floppyDisk,
        context.strings.save,
        () => file('save'),
      ),
    ]);
    final planeAndGrid = Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 2,
      children: [
        Flexible(child: WorkPlanePicker(e)),
        DeskIcon(
          cu.CupertinoIcons.grid,
          context.strings.gridVisibility,
          showGridControls,
          key: gridButton,
          size: 18,
          background: gridControlsOpen ? context.colors.pale : null,
        ),
      ],
    );
    final zoomControls = group([
      iconAction(
        cu.CupertinoIcons.minus,
        context.strings.zoomOut,
        () => zoom(.8),
      ),
      iconAction(
        cu.CupertinoIcons.plus,
        context.strings.zoomIn,
        () => zoom(1.25),
      ),
      iconAction(
        cu.CupertinoIcons.viewfinder,
        context.strings.fitShortcut(e.hotkeys[Command.fit].label),
        () {
          e.fitRequested = true;
          e.refresh();
        },
      ),
    ]);

    final settings = afterDivider(
      DeskIcon(
        cu.CupertinoIcons.gear_alt,
        context.strings.settings,
        editSettings,
        key: settingsButton,
        size: 18,
      ),
    );

    return Container(
      key: const ValueKey('drawing-toolbar'),
      constraints: BoxConstraints(minHeight: macControls ? 35 : 44),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: context.colors.panel,
        border: Border(bottom: BorderSide(color: context.colors.line)),
      ),
      child: LayoutBuilder(
        builder: (context, box) => Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          spacing: 12,
          children: [
            Expanded(
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: toolbarGap,
                children: [
                  group([
                    if (!macControls)
                      iconAction(
                        cu.CupertinoIcons.sidebar_left,
                        context.strings.partsTree,
                        toggleParts,
                      ),
                    documentActions,
                    if (macControls) afterDivider(group(drawingTools())),
                  ], spacing: macControls ? 0 : 12),
                  planeAndGrid,
                ],
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: box.maxWidth / 2),
              child: Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [zoomControls, settings],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget viewport() => Column(
    children: [
      viewportToolbar(),
      Expanded(
        child: Stack(
          children: [
            Positioned.fill(child: DrawingViewport(e, key: viewportKey)),
            if (!macControls)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: context.colors.panel,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: context.colors.line),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x10000000),
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(spacing: toolbarGap, children: drawingTools()),
                ),
              ),
            Positioned(
              left: 14,
              bottom: 13,
              child: IgnorePointer(
                child: CustomPaint(
                  size: const Size(62, 51),
                  painter: AxesPainter(e.camera, context.colors),
                ),
              ),
            ),
          ],
        ),
      ),
      Container(
        key: const ValueKey('view-tabs'),
        width: double.infinity,
        decoration: BoxDecoration(
          color: context.colors.chrome,
          border: Border(
            top: BorderSide(color: context.colors.line, width: .7),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: toolbarGap,
            children: [
              for (final view in ViewAngle.values)
                Semantics(
                  selected: view == e.selectedView,
                  value: view == e.selectedView && e.activeView == null
                      ? context.strings.freeView
                      : null,
                  child: DeskButton(
                    plain: true,
                    primary: view == e.activeView,
                    active: view == e.selectedView,
                    onPressed: () => e.setView(view),
                    child: Text(view.label),
                  ),
                ),
            ],
          ),
        ),
      ),
      if (!macControls) draftingControls(),
    ],
  );
  Widget draftingControls() => Container(
    height: macControls ? 30 : 37,
    decoration: BoxDecoration(
      color: macControls ? context.colors.chrome : context.colors.panel,
      border: macControls
          ? null
          : Border(top: BorderSide(color: context.colors.line)),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 9),
    child: Row(
      spacing: toolbarGap,
      children: [
        iconAction(
          cu.CupertinoIcons.scope,
          e.tool == Tool.measure
              ? context.strings.rulerSnapModifier(primaryModifierLabel)
              : context.strings.snapToAnchors,
          () {
            if (e.tool == Tool.measure) {
              saveSnapDefault(!e.snapByDefault);
            } else {
              e.snap = !e.snap;
            }
            e.hover = null;
            e.refresh();
          },
          active: e.tool == Tool.measure ? e.snapByDefault : e.snap,
          size: 15,
        ),
        MenuChoice<SnapMode>(
          selected: (e.tool == Tool.measure ? e.snapByDefault : e.snap)
              ? e.snapMode
              : null,
          label: context.strings.anchorLabel(
            (e.tool == Tool.measure ? e.snapByDefault : e.snap)
                ? e.snapMode.label
                : context.strings.off,
          ),
          items: [for (final m in SnapMode.values) (m, m.label)],
          change: (m) {
            if (e.tool == Tool.measure) {
              saveSnapDefault(true);
            } else {
              e.snap = true;
            }
            e.snapMode = m;
            e.hover = null;
            e.refresh();
          },
        ),
        if (!macControls) const Spacer(),
        DeskButton(
          plain: true,
          onPressed: editSettings,
          child: Text(
            context.strings.step(e.step.label(e.project.unit)),
            style: const TextStyle(fontSize: 11),
          ),
        ),
        MenuChoice<LengthUnit>(
          selected: e.project.unit,
          label: e.project.unit.symbol,
          items: [for (final unit in LengthUnit.values) (unit, unit.title)],
          change: (unit) {
            FocusManager.instance.primaryFocus?.unfocus();
            e.commit(e.project.copy(unit: unit));
          },
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: e,
    builder: (context, _) {
      unawaited(syncDocumentToolbar());
      final workspace = Column(
        children: [
          header(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) {
                final compact = box.maxWidth < 1050;
                final parts = PartsPanel(
                  e,
                  showPartsList: showPartsList,
                  partsListButton: partsListButton,
                  centerOn: (points) {
                    final viewport = viewportKey.currentState;
                    if (viewport == null) return;
                    e.camera.fitPoints(points, viewport.size);
                    e.fitRequested = false;
                    e.refresh();
                  },
                );
                return Row(
                  key: ObjectKey(e),
                  children: [
                    if (partsVisible && box.maxWidth >= 780) ...[
                      SizedBox(
                        width: macControls
                            ? (compact ? 185 : 224)
                            : (compact ? 173 : 214),
                        child: parts,
                      ),
                      const VerticalDivider(width: 1),
                    ],
                    Expanded(child: viewport()),
                    if (!macControls ||
                        inspectorVisible ||
                        (box.maxWidth < 780 && e.rulerActive)) ...[
                      const VerticalDivider(width: 1),
                      SizedBox(
                        width: compact ? 210 : 247,
                        child: box.maxWidth < 780 && e.rulerActive
                            ? parts
                            : Inspector(
                                e,
                                rename: () {
                                  final part = e.single;
                                  if (part != null) renamePart(part);
                                },
                              ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
          Container(
            height: 30,
            color: context.colors.chrome,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Icon(
                  cu.CupertinoIcons.info_circle,
                  size: 14,
                  color: context.colors.muted,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: context.colors.ink),
                  ),
                ),
                if (e.overlaps.isNotEmpty)
                  Text(
                    context.strings.intersectionsLabel(e.overlaps.length),
                    style: TextStyle(
                      fontSize: 11,
                      color: context.colors.danger,
                    ),
                  ),
                if (macControls) draftingControls(),
                const SizedBox(width: 12),
                Text(
                  context.strings.partCount(e.project.beams.length),
                  style: mono.copyWith(
                    fontSize: 10,
                    color: context.colors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
      return appleControls
          ? cu.CupertinoPageScaffold(child: workspace)
          : Scaffold(body: workspace);
    },
  );
}

class AxesPainter extends CustomPainter {
  final Camera camera;
  final EditorPalette colors;
  AxesPainter(this.camera, this.colors);
  @override
  void paint(Canvas c, Size s) {
    const o = Offset(24, 28);
    for (var i = 0; i < 3; i++) {
      final dir = Offset(camera.right[i], -camera.up[i]) * 19, p = o + dir;
      final color = colors.axisColor(i);
      c.drawLine(
        o,
        p,
        Paint()
          ..color = color
          ..strokeWidth = 1.6,
      );
      final t = TextPainter(
        text: TextSpan(
          text: 'XYZ'[i],
          style: mono.copyWith(color: color, fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      t.paint(c, p + Offset(dir.dx * .18 - 2, dir.dy * .18 - 6));
    }
  }

  @override
  bool shouldRepaint(AxesPainter old) => true;
}
