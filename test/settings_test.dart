import 'package:neprosto/editor/desk_text_field.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neprosto/editor/controller.dart';
import 'package:neprosto/editor/desktop.dart';
import 'package:neprosto/editor/hotkeys.dart';
import 'package:neprosto/editor/model.dart';
import 'package:neprosto/editor/project_tab_bar.dart';
import 'package:neprosto/editor/project_tabs.dart';
import 'package:neprosto/editor/scene.dart';
import 'package:neprosto/main.dart';

Future<void> openProjectSettings(WidgetTester t) async {
  const item = 'Настройки проекта…';
  final native = !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;
  if (native) {
    t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('neprosto/popup'),
      (call) async {
        if (call.method != 'choose') return null;
        final items = call.arguments['items'] as List;
        expect(items, contains(item));
        return items.indexOf(item);
      },
    );
  }
  await t.tap(
    find.descendant(
      of: find.byType(ProjectTabBar),
      matching: find.byIcon(CupertinoIcons.chevron_down),
    ),
  );
  await t.pumpAndSettle();
  if (!native) {
    await t.tap(find.text(item));
    await t.pumpAndSettle();
  }
}

void main() {
  test('A saved Q binding takes precedence over the new width shortcut', () {
    final keys = EditorHotkeys()
        .assign(Command.measure, Command.stretchWidth.standard)
        .assign(Command.add, (
          key: LogicalKeyboardKey.keyK,
          primary: false,
          shift: false,
          alt: false,
        ));
    final restored = EditorHotkeys.decode(keys.encode());
    expect(restored.commandFor(Command.stretchWidth.standard), Command.measure);
    expect(
      restored.commandFor(Command.stretchHeight.standard),
      Command.stretchHeight,
    );
    expect(restored[Command.add], keys[Command.add]);
    expect(
      restored.conflict(Command.stretchHeight, Command.stretchHeight.standard),
      isNull,
    );
  });

  testWidgets('Record, cancel, apply and reset custom drawing shortcuts', (
    t,
  ) async {
    await t.binding.setSurfaceSize(const Size(1200, 780));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final e = Editor(Project.bench());
    await t.pumpWidget(NeprostoApp(editor: e));
    await t.pumpAndSettle();
    Future<void> keyboard() async {
      await t.tap(find.byTooltip('Настройки'));
      await t.pumpAndSettle();
      await t.tap(find.text('Горячие клавиши'));
      await t.pumpAndSettle();
    }

    Future<void> record(Command cmd, LogicalKeyboardKey key) async {
      final control = find.byKey(ValueKey('shortcut-${cmd.name}'));
      await t.ensureVisible(control);
      await t.pumpAndSettle();
      await t.tap(control);
      await t.sendKeyEvent(key);
      await t.pumpAndSettle();
    }

    await keyboard();
    await record(Command.add, LogicalKeyboardKey.keyM);
    expect(find.textContaining('Уже назначено'), findsOneWidget);
    expect(e.tool, Tool.select);
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await t.pumpAndSettle();
    await record(Command.add, LogicalKeyboardKey.keyK);
    await t.tap(find.text('Отмена'));
    await t.pumpAndSettle();
    expect(e.hotkeys[Command.add], Command.add.standard);
    await keyboard();
    await record(Command.add, LogicalKeyboardKey.keyK);
    await record(Command.dimensions, LogicalKeyboardKey.keyL);
    await t.tap(find.text('Готово'));
    await t.pumpAndSettle();
    expect(find.byTooltip('Новая деталь · K'), findsOneWidget);
    expect(EditorHotkeys.decode(e.hotkeys.encode())[Command.add].label, 'K');
    await t.sendKeyEvent(LogicalKeyboardKey.keyW);
    await t.sendKeyEvent(LogicalKeyboardKey.keyB);
    expect(e.tool, Tool.select);
    await t.sendKeyEvent(LogicalKeyboardKey.keyK);
    expect(e.tool, Tool.beam);
    await t.sendKeyDownEvent(LogicalKeyboardKey.keyL);
    expect(e.dimensionsVisible, false);
    await t.sendKeyUpEvent(LogicalKeyboardKey.keyL);
    expect(e.dimensionsVisible, true);
    await keyboard();
    await t.tap(find.text('Сбросить сочетания'));
    await t.pumpAndSettle();
    await t.tap(find.text('Готово'));
    await t.pumpAndSettle();
    expect(e.hotkeys.customized, false);
  });

  testWidgets('macOS only binds Quit when Command-Q is free', (t) async {
    await t.binding.setSurfaceSize(const Size(1200, 780));
    addTearDown(() => t.binding.setSurfaceSize(null));
    const channel = MethodChannel('neprosto/popup');
    final messenger = t.binding.defaultBinaryMessenger;
    final quitBindings = <bool>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'editorShortcuts') {
        quitBindings.add(call.arguments['quit'] as bool);
      }
      return null;
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
    final defaults = EditorHotkeys();
    final remapped = defaults.assign(Command.stretchHeight, (
      key: LogicalKeyboardKey.keyK,
      primary: true,
      shift: false,
      alt: false,
    ));
    for (final keys in [
      defaults,
      remapped,
      remapped.assign(Command.measure, Command.stretchHeight.standard),
    ]) {
      final e = Editor(Project.bench())..hotkeys = keys;
      await t.pumpWidget(NeprostoApp(key: UniqueKey(), editor: e));
      await t.pumpAndSettle();
    }
    expect(quitBindings, [false, true, false]);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets(
    'Editing settings apply or cancel global units and keep each unit’s step',
    (t) async {
      await t.binding.setSurfaceSize(const Size(1200, 780));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final project = Project.bench().copy(unit: LengthUnit.centimeter);
      final editor = Editor(project);
      await t.pumpWidget(NeprostoApp(editor: editor));
      await t.pumpAndSettle();

      final field = find.descendant(
        of: find.byKey(const ValueKey('input-step')),
        matching: find.byType(DeskTextField),
      );
      String stepText() => t.widget<DeskTextField>(field).controller!.text;
      Future<void> tap(String label) async {
        await t.tap(find.text(label));
        await t.pumpAndSettle();
      }

      await tap('Шаг 1 см');
      expect(
        t
            .widget<DeskSegments<LengthUnit>>(
              find.byType(DeskSegments<LengthUnit>),
            )
            .value,
        LengthUnit.centimeter,
      );
      expect(find.text('1/16″'), findsNothing);
      await tap('Дюймы');
      expect(stepText(), '1/16');
      expect(
        t.getBottomLeft(find.text('Шаг редактирования')).dy,
        lessThan(t.getTopLeft(find.text('1/100″')).dy),
      );
      await tap('1/32″');
      expect(stepText(), '1/32');
      await tap('Шаг редактирования');
      expect(find.byType(DeskSwitch), findsNothing);
      expect(stepText(), '1/32');
      await tap('1/16″');
      expect(stepText(), '1/16');
      await tap('1/100″');
      expect(stepText(), '1/100');
      await tap('1°');
      await tap('Отмена');
      expect(editor.step.anglePrecision.increment, .1);
      expect(editor.project, same(project));
      expect(editor.step.value(LengthUnit.inch), 1 / 16);

      await tap('Шаг 1 см');
      await tap('Миллиметры');
      await tap('0.1 мм');
      expect(stepText(), '0.1');
      await t.enterText(field, '5');
      await tap('Дюймы');
      await tap('1/8″');
      await tap('Миллиметры');
      expect(stepText(), '5');
      await tap('Дюймы');
      expect(stepText(), '1/8');
      await tap('0.01°');
      await tap('Сохранение');
      final minutes = find.descendant(
        of: find.byType(DeskDialog),
        matching: find.byType(EditableText),
      );
      await t.enterText(minutes, '5+2 *2');
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.pump();
      expect(t.widget<EditableText>(minutes).controller.text, '14');
      await t.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await t.pump();
      expect(t.widget<EditableText>(minutes).controller.text, '13');
      await tap('Готово');
      expect(editor.step.anglePrecision.increment, .01);
      expect(find.byTooltip('Единицы измерения · Дюймы'), findsNothing);
      expect(find.text('Шаг 1/8″'), findsOneWidget);
      expect(editor.step.value(LengthUnit.millimeter), 5);
      expect(editor.displayUnit, LengthUnit.inch);
      expect(editor.canUndo, isFalse);
      expect(editor.project.beams.first.size, project.beams.first.size);
      editor.undo();
      expect(editor.project, same(project));
      editor.select(1);
      editor.setTool(Tool.rotate);
      await t.pumpAndSettle();
      final angle = find.byKey(const Key('angle'));
      await t.enterText(angle, '5+2 *2');
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.pumpAndSettle();
      expect(
        find.descendant(of: angle, matching: find.text('14')),
        findsOneWidget,
      );
      await t.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await t.pumpAndSettle();
      expect(editor.angle, closeTo(13.99, 1e-10));
    },
    variant: TargetPlatformVariant({
      TargetPlatform.macOS,
      TargetPlatform.windows,
    }),
  );

  testWidgets('Workspace boundaries use project units and undo as one edit', (
    t,
  ) async {
    await t.binding.setSurfaceSize(const Size(1100, 650));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final bench = Project.bench();
    final p = bench.copy(
      unit: LengthUnit.centimeter,
      beams: [
        ...bench.beams,
        bench.beams.first.copy(id: bench.nextId, origin: Vector3(2000, 0, 0)),
      ],
    );
    final e = Editor(p)..select(1);
    await t.pumpWidget(NeprostoApp(editor: e));
    await t.pumpAndSettle();
    await openProjectSettings(t);
    final width = find.descendant(
      of: find.byKey(const ValueKey('workspace-0')),
      matching: find.byType(DeskTextField),
    );
    expect(t.widget<DeskTextField>(width).controller!.text, isEmpty);
    Finder action(String label) => find.descendant(
      of: find.byType(DeskDialog),
      matching: find.text(label),
    );
    final name = find.byKey(const ValueKey('project-settings-name'));
    await t.enterText(name, 'Черновик');
    await t.enterText(width, '0');
    await t.pumpAndSettle();
    await t.tap(action('Применить'));
    await t.pumpAndSettle();
    expect(find.text('Габариты проекта'), findsOneWidget);
    expect(e.project, same(p));
    await t.enterText(width, '4*50');
    await t.pumpAndSettle();
    await t.tap(action('Отмена'));
    await t.pumpAndSettle();
    expect(e.project, same(p));
    await openProjectSettings(t);
    await t.enterText(name, ' Шкаф ');
    expect(t.widget<DeskTextField>(width).controller!.text, isEmpty);
    await t.enterText(width, '4*50');
    final depth = find.descendant(
      of: find.byKey(const ValueKey('workspace-1')),
      matching: find.byType(DeskTextField),
    );
    await t.enterText(depth, '50');
    await t.pumpAndSettle();
    expect(
      t
          .widget<DeskButton>(
            find.ancestor(
              of: action('Применить'),
              matching: find.byType(DeskButton),
            ),
          )
          .onPressed,
      isNull,
    );
    await t.enterText(
      find.descendant(
        of: find.byKey(const ValueKey('workspace-2')),
        matching: find.byType(DeskTextField),
      ),
      '45',
    );
    await t.pumpAndSettle();
    await t.tap(action('Применить'));
    await t.pumpAndSettle();
    expect(e.project.workspaceSize, Vector3(2000, 500, 450));
    expect(e.project.name, 'Шкаф');
    expect(e.project.beams, p.beams);
    expect(e.single?.id, 1);
    expect(
      Project.decode(e.project.encode()).workspaceSize,
      e.project.workspaceSize,
    );
    expect(
      e.project.copy(name: 'Копия').workspaceSize,
      e.project.workspaceSize,
    );
    e.undo();
    expect(e.project, same(p));
    e.redo();
    expect(e.project.workspaceSize?.x, 2000);
    final empty = Project(
      'Помещение',
      [],
    ).withWorkspace(e.project.workspaceSize);
    const size = Size(900, 540);
    for (final view in ViewAngle.values) {
      final camera = Camera()
        ..view(view)
        ..fit(empty, size);
      for (final point in empty.workspaceCorners) {
        expect(
          (Offset.zero & size).contains(camera.project(point, size)),
          true,
        );
      }
    }
  });

  testWidgets(
    'Resizing products applies all project axes as one undoable edit',
    (t) async {
      await t.binding.setSurfaceSize(const Size(1100, 700));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final board = Project.bench().beams.first.withSizeLock(1, true);
      final original = Project(
        'Проект',
        [board],
        [],
        LengthUnit.centimeter,
      ).withWorkspace(Vector3(2000, 1000, 500));
      final e = Editor(original);
      await t.pumpWidget(NeprostoApp(editor: e));
      await t.pumpAndSettle();
      await openProjectSettings(t);
      final toggle = find.descendant(
        of: find.byType(DeskDialog),
        matching: find.byType(DeskSwitch),
      );
      expect(t.widget<DeskSwitch>(toggle).value, isFalse);
      await t.tap(find.text('Изменить размеры изделий'));
      await t.pumpAndSettle();
      expect(t.widget<DeskSwitch>(toggle).value, isTrue);
      Future<void> enter(int axis, String value) async {
        await t.enterText(
          find.descendant(
            of: find.byKey(ValueKey('workspace-$axis')),
            matching: find.byType(DeskTextField),
          ),
          value,
        );
        await t.pump();
      }

      final apply = find.descendant(
        of: find.byType(DeskDialog),
        matching: find.text('Применить'),
      );
      await enter(0, '300');
      await enter(1, '50');
      await t.tap(apply);
      await t.pumpAndSettle();
      expect(
        find.text('Весь габарит занят фиксированными размерами'),
        findsOneWidget,
      );
      expect(e.project, same(original));
      expect(e.canUndo, isFalse);

      await enter(1, '100');
      await enter(2, '100');
      await t.tap(apply);
      await t.pumpAndSettle();
      expect(find.byType(DeskDialog), findsNothing);
      final resized = e.project;
      expect(resized.workspaceSize, Vector3(3000, 1000, 1000));
      expect(
        resized.beams.single.size,
        Vector3(1800, board.size.y, board.size.z * 2),
      );
      expect(resized.beams.single.locked(1), isTrue);
      e.undo();
      expect(e.project, same(original));
      expect(e.canUndo, isFalse);
      e.redo();
      expect(e.project, same(resized));
    },
  );

  testWidgets(
    'An empty tab can set and clear its own project boundaries',
    (t) async {
      await t.binding.setSurfaceSize(const Size(1200, 700));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final original = Editor(
        Project.bench().withWorkspace(Vector3(900, 800, 700)),
      );
      final tabs = ProjectTabs(original)..create();
      final empty = tabs.value.editor;
      expect(empty.project.workspaceSize, Vector3(3000, 3000, 2500));
      await t.pumpWidget(NeprostoApp.withTabs(tabs));
      await t.pumpAndSettle();
      await openProjectSettings(t);
      final name = find.byKey(const ValueKey('project-settings-name'));
      await t.enterText(name, ' ');
      await t.pumpAndSettle();
      final apply = find.ancestor(
        of: find.text('Применить'),
        matching: find.byType(DeskButton),
      );
      expect(t.widget<DeskButton>(apply).onPressed, isNull);
      await t.enterText(name, 'Мастерская');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pumpAndSettle();
      expect(empty.project.name, 'Мастерская');
      expect(find.text('Мастерская'), findsOneWidget);
      expect(empty.project.workspaceSize, Vector3(3000, 3000, 2500));
      expect(Project.decode(empty.project.encode()).name, 'Мастерская');
      await openProjectSettings(t);
      await t.tap(find.text('Применить'));
      await t.pumpAndSettle();
      expect(empty.project.workspaceSize, Vector3(3000, 3000, 2500));
      await openProjectSettings(t);
      await t.tap(find.text('Убрать границы'));
      await t.pumpAndSettle();
      expect(empty.project.workspaceSize, isNull);
      expect(Project.decode(empty.project.encode()).workspaceSize, isNull);
      await openProjectSettings(t);
      for (var i = 0; i < 3; i++) {
        final field = find.descendant(
          of: find.byKey(ValueKey('workspace-$i')),
          matching: find.byType(DeskTextField),
        );
        expect(t.widget<DeskTextField>(field).controller!.text, isEmpty);
      }
      final unbounded = empty.project;
      await t.tap(apply);
      await t.pumpAndSettle();
      expect(empty.project, same(unbounded));
      expect(original.project.workspaceSize, Vector3(900, 800, 700));
      expect(original.canUndo, isFalse);
    },
    variant: TargetPlatformVariant({
      TargetPlatform.macOS,
      TargetPlatform.windows,
    }),
  );
}
