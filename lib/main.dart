import 'editor/desktop.dart';

import 'package:cupertino_ui/cupertino_ui.dart' as cu;

import 'dart:async';
import 'dart:ui' show ViewFocusEvent, ViewFocusState;

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'editor/controller.dart';
import 'editor/hotkeys.dart';
import 'editor/settings.dart';
import 'editor/controls.dart';
import 'editor/drawing.dart';
import 'editor/inspector.dart';
import 'editor/model.dart';
import 'editor/parts_panel.dart';
import 'editor/parts_list.dart';
import 'editor/scene.dart';
import 'editor/step.dart';
import 'editor/storage.dart';
import 'editor/viewport.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Project project = Project.bench();
  final prefs = SharedPreferencesAsync();
  String? issue;
  var restored = false;
  try {
    final draft = await prefs.getString('drawing-v1');
    if (draft != null) {
      project = Project.decode(draft);
      restored = true;
    }
  } catch (_) {
    issue = 'Не удалось открыть локальный черновик';
  }
  final editor = Editor(project);
  try {
    editor.snapByDefault = await prefs.getBool('move-snap-default') ?? true;
    editor.dimensionsByDefault =
        await prefs.getBool('dimensions-by-default') ?? true;
    final bindings = await prefs.getString('hotkeys-v1');
    if (bindings != null) editor.hotkeys = EditorHotkeys.decode(bindings);
    final data = await prefs.getString('edit-step-v1');
    if (data != null) editor.step = EditStep.decode(data);
  } catch (_) {
    /* Keep default input increments for an unreadable preference. */
  }
  runApp(
    NeprostoApp(
      editor: editor,
      preferences: prefs,
      initialMessage: issue,
      restored: restored,
    ),
  );
}

class NeprostoApp extends StatelessWidget {
  final Editor editor;
  final SharedPreferencesAsync? preferences;
  final String? initialMessage;
  final bool restored;
  const NeprostoApp({
    super.key,
    required this.editor,
    this.preferences,
    this.initialMessage,
    this.restored = false,
  });
  @override
  Widget build(BuildContext context) => cu.CupertinoApp(
    title: 'neprosto',
    builder: (_, child) => ListenableBuilder(
      listenable: editor,
      child: child,
      builder: (_, child) => Units(
        editor.project.unit,
        editor.step.enabled
            ? editor.step.millimeters(editor.project.unit)
            : null,
        child: child!,
      ),
    ),
    debugShowCheckedModeBanner: false,
    localizationsDelegates: const [DefaultMaterialLocalizations.delegate],
    theme: const cu.CupertinoThemeData(
      brightness: Brightness.light,
      primaryColor: Color(0xff0876e8),
      scaffoldBackgroundColor: Color(0xfff7f7f9),
      textTheme: cu.CupertinoTextThemeData(
        textStyle: TextStyle(
          fontFamily: '.AppleSystemUIFont',
          fontSize: 13,
          color: ink,
        ),
      ),
    ),
    home: Workspace(editor, preferences, initialMessage, restored),
  );
}

class Workspace extends StatefulWidget {
  const Workspace(
    this.editor,
    this.preferences,
    this.initialMessage,
    this.restored, {
    super.key,
  });
  final Editor editor;
  final SharedPreferencesAsync? preferences;
  final String? initialMessage;
  final bool restored;
  @override
  State<Workspace> createState() => _WorkspaceState();
}

class _WorkspaceState extends State<Workspace> with WidgetsBindingObserver {
  Editor get e => widget.editor;
  bool partsVisible = true, fileBusy = false;
  static const menu = MethodChannel('neprosto/editor');
  Future<void> writes = Future.value();
  Project? saved;
  @override
  void initState() {
    super.initState();
    saved = widget.restored ? null : e.project;
    e.onDocumentChange = cache;
    if (widget.initialMessage != null) e.message = widget.initialMessage!;
    syncNativeKeys();
    HardwareKeyboard.instance.addHandler(keyEvent);
    FocusManager.instance.addEarlyKeyEventHandler(dimensionTab);
    WidgetsBinding.instance.addObserver(this);
    menu.setMethodCallHandler((call) async {
      if (call.method == 'settings' &&
          ModalRoute.of(context)?.isCurrent == true) {
        await editSettings();
        return;
      }
      if (!{'undo', 'redo', 'selectAll'}.contains(call.method)) return;
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

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    FocusManager.instance.removeEarlyKeyEventHandler(dimensionTab);
    HardwareKeyboard.instance.removeHandler(keyEvent);
    menu.setMethodCallHandler(null);

    e.onDocumentChange = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) e.holdDimensionTab(false);
  }

  @override
  void didChangeViewFocus(ViewFocusEvent event) {
    if (event.state == ViewFocusState.unfocused) e.holdDimensionTab(false);
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
    if (!editingText && event.logicalKey == LogicalKeyboardKey.escape) {
      e.setTool(Tool.select);
      return KeyEventResult.handled;
    }
    final chord = chordFor(event);
    if (chord == null) return KeyEventResult.ignored;
    final command = e.hotkeys.commandFor(chord);
    if (command == null ||
        (editingText && !(command == Command.save && chord.primary))) {
      return KeyEventResult.ignored;
    }
    if (command == Command.dimensions) heldDimensionKey = event.physicalKey;
    return dispatch(command) ? KeyEventResult.handled : KeyEventResult.ignored;
  }

  void cache(Project project) {
    if (widget.preferences == null) return;
    final data = project.encode();
    writes = writes
        .then((_) => widget.preferences!.setString('drawing-v1', data))
        .catchError((Object error) {
          if (mounted) {
            e.message = 'Не удалось записать черновик';
            e.refresh();
          }
        });
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
      case Command.delete:
        e.delete();
      case Command.open:
        unawaited(file('open'));
      case Command.save:
        unawaited(file('save'));
      case Command.newProject:
        unawaited(file('new'));
      case Command.selectAll:
        e.selection = e.project.byId.keys.toSet();
        e.refresh();
      case Command.fit:
        e.fitRequested = true;
        e.refresh();
      case Command.dimensions:
        e.holdDimensionTab(true);
      case Command.select:
        e.setTool(Tool.select);
      case Command.add:
        e.setTool(Tool.beam);
      case Command.measure:
        e.setTool(Tool.measure);
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

  Future<String?> nameDialog(String title, String value) async {
    var result = value;
    return cu.showCupertinoDialog<String>(
      context: context,
      builder: (ctx) => DeskDialog(
        title: Text(title),
        content: SizedBox(
          width: 320,
          child: cu.CupertinoTextFormFieldRow(
            padding: EdgeInsets.zero,
            initialValue: value,
            autofocus: true,
            onChanged: (v) => result = v,
            onFieldSubmitted: (v) {
              if (v.trim().isNotEmpty) Navigator.pop(ctx, v.trim());
            },
          ),
        ),
        actions: [
          DeskButton(
            plain: true,
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Отмена'),
          ),
          DeskButton(
            primary: true,
            onPressed: () {
              if (result.trim().isNotEmpty) Navigator.pop(ctx, result.trim());
            },
            child: const Text('Готово'),
          ),
        ],
      ),
    );
  }

  Future<void> renamePart(Beam part) async {
    final name = await nameDialog('Название детали', part.name);
    if (name != null && name != part.name && e.project.byId[part.id] == part) {
      e.commit(e.project.edit({part.id}, (b) => b.copy(name: name)));
    }
  }

  Future<void> showPartsList() async {
    FocusManager.instance.primaryFocus?.unfocus();
    FocusManager.instance.applyFocusChangesIfNeeded();
    await cu.showCupertinoDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => PartsList(e, rename: renamePart),
    );
  }

  Future<bool> replaceAllowed() async {
    if (identical(e.project, saved)) return true;
    final answer = await cu.showCupertinoDialog<int>(
      context: context,
      builder: (ctx) => DeskDialog(
        title: const Text('Сохранить текущий проект?'),
        content: Text(e.project.name),
        actions: [
          DeskButton(
            plain: true,
            onPressed: () => Navigator.pop(ctx, 0),
            child: const Text('Отмена'),
          ),
          DeskButton(
            plain: true,
            onPressed: () => Navigator.pop(ctx, 1),
            child: const Text('Продолжить без сохранения'),
          ),
          DeskButton(
            primary: true,
            onPressed: () => Navigator.pop(ctx, 2),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    if (answer == 2) return save();
    return answer == 1;
  }

  Future<void> saveSnapDefault(bool value) async {
    e.snapByDefault = value;
    e.refresh();
    try {
      await widget.preferences?.setBool('move-snap-default', value);
    } catch (_) {
      e.message = 'Не удалось сохранить режим привязки';
      e.refresh();
    }
  }

  bool settingsOpen = false;

  Future<void> syncNativeKeys() async {
    if (defaultTargetPlatform != TargetPlatform.macOS || kIsWeb) return;
    try {
      await const MethodChannel('neprosto/popup')
          .invokeMethod<void>('editorShortcuts', {
            for (final command in [
              Command.undo,
              Command.redo,
              Command.settings,
              Command.selectAll,
            ])
              command.name: e.hotkeys[command] == command.standard,
          });
    } on MissingPluginException {
      // Widget tests and older running native hosts use Flutter shortcuts.
    }
  }

  Future<void> editSettings([
    SettingsPage initial = SettingsPage.editing,
  ]) async {
    if (settingsOpen) return;
    settingsOpen = true;
    e.holdDimensionTab(false);
    try {
      final result = await cu.showCupertinoDialog<SettingsResult>(
        context: context,
        builder: (_) => EditorSettings(e, initial),
      );
      if (result == null || !mounted) return;
      e.hotkeys = result.hotkeys;
      e.step = result.step;
      e.dimensionsByDefault = result.dimensions;
      e.snapByDefault = result.snap;
      if (e.project.workspaceSize != result.workspace) {
        e.commit(e.project.withWorkspace(result.workspace));
      } else {
        e.refresh();
      }
      await syncNativeKeys();
      final prefs = widget.preferences;
      if (prefs != null) {
        await Future.wait([
          prefs.setString('hotkeys-v1', result.hotkeys.encode()),
          prefs.setString('edit-step-v1', result.step.encode()),
          prefs.setBool('dimensions-by-default', result.dimensions),
          prefs.setBool('move-snap-default', result.snap),
        ]);
      }
    } catch (_) {
      e.message = 'Не удалось сохранить настройки';
      e.refresh();
    } finally {
      settingsOpen = false;
    }
  }

  Future<bool> save() async {
    final current = e.project, ok = await saveProject(current);
    if (ok) {
      saved = current;
      e.message = 'Проект сохранён';
      e.refresh();
    }
    return ok;
  }

  Future<void> file(String action) async {
    if (fileBusy) return;
    fileBusy = true;
    try {
      FocusManager.instance.primaryFocus?.unfocus();
      FocusManager.instance.applyFocusChangesIfNeeded();
      if (action == 'workspace') {
        await editSettings(SettingsPage.workspace);
        return;
      }
      if (action == 'save') {
        await save();
        return;
      }
      if (action == 'rename') {
        final value = await nameDialog('Название проекта', e.project.name);
        if (value != null) e.commit(e.project.copy(name: value));
        return;
      }
      if (!await replaceAllowed() || !mounted) return;
      Project? next;
      if (action == 'open') {
        next = await openProject();
      }
      if (action == 'new') {
        final value = await nameDialog('Новый проект', 'Без названия');
        if (value != null) next = Project(value, []);
      }
      if (action == 'demo') next = Project.bench();
      if (next != null) {
        saved = next;
        e.load(next);
      }
    } catch (error) {
      e.message = action == 'open'
          ? 'Не удалось открыть файл проекта'
          : 'Не удалось сохранить проект';
      e.refresh();
    } finally {
      fileBusy = false;
    }
  }

  String get hint {
    if (e.message.isNotEmpty) return e.message;
    return switch (e.tool) {
      Tool.select => switch (e.selection.length) {
        0 =>
          'Чтобы добавить деталь, нажмите «Новая деталь» или ${e.hotkeys[Command.add].label}',
        1 => 'ПКМ — действия с деталью · Маркер — растянуть',
        _ =>
          'Правый щелчок по выделению — действия со всеми выбранными деталями',
      },
      Tool.move =>
        e.first == null
            ? 'Укажите исходную опору на перемещаемой детали'
            : 'Укажите опору назначения',
      Tool.beam =>
        e.first == null
            ? 'Укажите начальную точку детали'
            : 'Укажите конец детали',
      Tool.measure =>
        e.first == null
            ? 'Укажите первую точку размера'
            : 'Укажите вторую точку размера',
      Tool.align =>
        e.referenceId == null
            ? 'Щёлкните по опорной детали'
            : 'Выберите край, центр или введите отступ',
      Tool.gap =>
        e.firstShelf == null
            ? 'Выберите первую полку'
            : 'Выберите вторую полку',
      Tool.face => 'Выберите грань для рабочей плоскости',
      Tool.rotate => 'Нажмите стрелку для поворота на 90° или введите угол',
    };
  }

  Widget header() => Container(
    height: 47,
    padding: const EdgeInsets.symmetric(horizontal: 15),
    decoration: const BoxDecoration(
      color: Colors.white,
      border: Border(bottom: BorderSide(color: line)),
    ),
    child: Row(
      children: [
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
        Flexible(
          child: Align(
            alignment: Alignment.centerLeft,
            child: DeskMenu<String>(
              title: 'Проект',
              change: file,
              items: [
                ('new', 'Новый проект…'),
                ('open', 'Открыть проект…'),
                ('save', 'Сохранить проект…'),
                ('rename', 'Переименовать…'),
                ('demo', 'Открыть пример скамьи'),
                ('workspace', 'Размеры рабочего пространства…'),
              ],
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(cu.CupertinoIcons.folder, size: 16, color: muted),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      e.project.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const Icon(
                    cu.CupertinoIcons.chevron_down,
                    size: 16,
                    color: muted,
                  ),
                ],
              ),
            ),
          ),
        ),
        iconAction(
          cu.CupertinoIcons.arrow_uturn_left,
          'Отменить',
          e.canUndo ? e.undo : null,
        ),
        iconAction(
          cu.CupertinoIcons.arrow_uturn_right,
          'Повторить',
          e.canRedo ? e.redo : null,
        ),
        const SizedBox(width: 8),
        DeskButton(
          onPressed: showPartsList,
          icon: const Icon(cu.CupertinoIcons.list_bullet, size: 16),
          label: const Text('Список деталей'),
        ),
        const SizedBox(width: 8),
        DeskButton(
          onPressed: () => file('save'),
          icon: const Icon(cu.CupertinoIcons.square_arrow_down, size: 16),
          label: const Text('Сохранить'),
        ),
        const SizedBox(width: 8),
        iconAction(cu.CupertinoIcons.gear_alt, 'Настройки', editSettings),
      ],
    ),
  );
  void zoom(double factor) {
    e.camera.scale = (e.camera.scale * factor).clamp(.005, 100);
    e.camera.pan *= factor;
    e.refresh();
  }

  Widget viewport() => Column(
    children: [
      Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 7),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: line)),
        ),
        child: Row(
          children: [
            iconAction(
              cu.CupertinoIcons.sidebar_left,
              'Дерево деталей',
              () => setState(() => partsVisible = !partsVisible),
              size: 17,
            ),
            const SizedBox(width: 3),
            MenuChoice<String>(
              label: 'Рабочая плоскость · ${e.plane.name}',
              items: const [
                ('XY', 'XY · сверху'),
                ('XZ', 'XZ · спереди'),
                ('YZ', 'YZ · сбоку'),
                ('face', 'Выбрать грань…'),
              ],
              change: (v) {
                if (v == 'face') {
                  e.setTool(Tool.face);
                } else {
                  e.setPlane(
                    v == 'XY'
                        ? WorkPlane.xy()
                        : v == 'XZ'
                        ? WorkPlane.xz()
                        : WorkPlane.yz(),
                  );
                }
              },
            ),
            const Spacer(),
            iconAction(cu.CupertinoIcons.minus, 'Отдалить', () => zoom(.8)),
            iconAction(cu.CupertinoIcons.plus, 'Приблизить', () => zoom(1.25)),
            iconAction(
              cu.CupertinoIcons.viewfinder,
              'Вписать в окно · ${e.hotkeys[Command.fit].label}',
              () {
                e.fitRequested = true;
                e.refresh();
              },
            ),
          ],
        ),
      ),
      Expanded(
        child: Stack(
          children: [
            Positioned.fill(child: DrawingViewport(e)),
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: line),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x10000000),
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    for (final (tool, icon, title) in [
                      (
                        Tool.select,
                        cu.CupertinoIcons.location_north,
                        'Выбрать · ${e.hotkeys[Command.select].label}',
                      ),
                      (
                        Tool.move,
                        cu.CupertinoIcons.move,
                        'Переместить по опорам · ${e.hotkeys[Command.move].label}',
                      ),
                      (
                        Tool.rotate,
                        cu.CupertinoIcons.arrow_clockwise,
                        'Поворот · ${e.hotkeys[Command.rotate].label}',
                      ),
                      (
                        Tool.measure,
                        Icons.straighten,
                        'Измерить · ${e.hotkeys[Command.measure].label}',
                      ),
                      (
                        Tool.face,
                        cu.CupertinoIcons.layers,
                        'Плоскость по грани',
                      ),
                    ])
                      iconAction(
                        icon,
                        title,
                        tool == Tool.rotate && e.selection.isEmpty
                            ? null
                            : () => e.setTool(tool),
                        active: e.tool == tool,
                      ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 14,
              bottom: 13,
              child: IgnorePointer(
                child: CustomPaint(
                  size: const Size(62, 51),
                  painter: AxesPainter(e.camera),
                ),
              ),
            ),
          ],
        ),
      ),
      Container(
        key: const ValueKey('view-tabs'),
        width: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xfff2f2f5),
          border: Border(top: BorderSide(color: line, width: .7)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final view in ViewAngle.values)
                Semantics(
                  selected: view == e.activeView,
                  child: DeskButton(
                    plain: true,
                    active: view == e.activeView,
                    onPressed: () => e.setView(view),
                    child: Text(view.label),
                  ),
                ),
            ],
          ),
        ),
      ),
      Container(
        height: 37,
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: line)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 9),
        child: Row(
          children: [
            iconAction(
              cu.CupertinoIcons.scope,
              e.tool == Tool.measure
                  ? 'Привязка линейки без Ctrl / ⌘'
                  : 'Привязка по опорам',
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
              label:
                  'Опора · ${(e.tool == Tool.measure ? e.snapByDefault : e.snap) ? e.snapMode.label : 'выкл.'}',
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
            const Spacer(),
            DeskButton(
              plain: true,
              onPressed: editSettings,
              child: Text(
                e.step.enabled
                    ? 'Шаг · ${e.project.unit.format(e.step.millimeters(e.project.unit))}'
                    : 'Шаг выкл.',
                style: const TextStyle(fontSize: 11),
              ),
            ),
            MenuChoice<LengthUnit>(
              label: e.project.unit.symbol,
              items: [for (final unit in LengthUnit.values) (unit, unit.title)],
              change: (unit) {
                FocusManager.instance.primaryFocus?.unfocus();
                e.commit(e.project.copy(unit: unit));
              },
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    ],
  );
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: e,
    builder: (context, _) => cu.CupertinoPageScaffold(
      child: Column(
        children: [
          header(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) {
                final compact = box.maxWidth < 1050;
                return Row(
                  children: [
                    if (partsVisible && box.maxWidth >= 780) ...[
                      SizedBox(
                        width: compact ? 173 : 214,
                        child: PartsPanel(e),
                      ),
                      const VerticalDivider(width: 1),
                    ],
                    Expanded(child: viewport()),
                    const VerticalDivider(width: 1),
                    SizedBox(
                      width: compact ? 210 : 247,
                      child: Inspector(
                        e,
                        rename: () {
                          final part = e.single;
                          if (part != null) renamePart(part);
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Container(
            height: 30,
            color: const Color(0xfff0f0f3),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const Icon(
                  cu.CupertinoIcons.info_circle,
                  size: 14,
                  color: muted,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    hint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: ink),
                  ),
                ),
                if (e.overlaps.isNotEmpty)
                  Text(
                    'Пересечения · ${e.overlaps.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xffa0442e),
                    ),
                  ),
                const SizedBox(width: 12),
                Text(
                  'Деталей · ${e.project.beams.length}',
                  style: mono.copyWith(fontSize: 10, color: muted),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class AxesPainter extends CustomPainter {
  final Camera camera;
  AxesPainter(this.camera);
  @override
  void paint(Canvas c, Size s) {
    const o = Offset(24, 28);
    for (var i = 0; i < 3; i++) {
      final dir = Offset(camera.right[i], -camera.up[i]) * 19, p = o + dir;
      final color = [
        const Color(0xffac6957),
        const Color(0xff6b8a56),
        const Color(0xff557f9b),
      ][i];
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
