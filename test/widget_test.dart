import 'package:neprosto/editor/desk_text_field.dart';
import 'package:cupertino_ui/cupertino_ui.dart' as cu;
import 'package:neprosto/editor/desktop.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:neprosto/main.dart';
import 'package:neprosto/editor/controller.dart';
import 'package:neprosto/editor/inspector.dart';
import 'package:neprosto/editor/hotkeys.dart';
import 'package:neprosto/editor/model.dart';
import 'package:neprosto/editor/scene.dart';
import 'package:neprosto/editor/drawing.dart';
import 'package:neprosto/editor/stock_axis.dart';
import 'package:neprosto/editor/parts_list.dart';
import 'package:neprosto/editor/parts_panel.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart'
    show PhosphorIconsRegular;

void main() {
  testWidgets(
    'Double-click centers a hidden row only when outlines are shown',
    (t) async {
      await t.binding.setSurfaceSize(const Size(1200, 780));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final project = Project.bench().edit({2}, (b) => b.copy(hidden: true));
      final editor = Editor(project)..select(1);
      await t.pumpWidget(NeprostoApp(editor: editor));
      await t.pumpAndSettle();

      final row = find.descendant(
        of: find.byType(PartsPanel),
        matching: find.text(project.byId[2]!.name),
      );
      final size = t.getSize(find.byKey(const Key('drawing')));
      final middle = project.byId[2]!.pointAt(Vector3.all(.5));
      final before = editor.camera.project(middle, size);
      expect(before, isNot(size.center(Offset.zero)));
      for (final outlines in [false, true]) {
        editor.showHiddenOutlines = outlines;
        editor.refresh();
        await t.pumpAndSettle();
        await t.tap(row, kind: PointerDeviceKind.mouse);
        await t.pump(kDoubleTapMinTime);
        await t.tap(row, kind: PointerDeviceKind.mouse);
        await t.pumpAndSettle();
        final expected = outlines ? size.center(Offset.zero) : before;
        expect(
          (editor.camera.project(middle, size) - expected).distance,
          lessThan(.001),
        );
        expect(editor.selection, {1});
        expect(editor.project, same(project));
        expect(find.byType(DeskDialog), findsNothing);
      }
    },
  );

  testWidgets(
    'Only user groups can be renamed and collapse by group ID',
    (t) async {
      await t.binding.setSurfaceSize(const Size(1200, 780));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final project = Project.bench().edit({1, 2}, (b) => b.copy(group: 1));
      final editor = Editor(Project.decode(project.encode()));
      await t.pumpWidget(NeprostoApp(editor: editor));
      await t.pumpAndSettle();
      final group = find.byKey(const ValueKey('group-header-1'));
      final ungrouped = find.byKey(const ValueKey('group-header-null'));
      final rename = find.byTooltip('Переименовать группу');
      expect(rename, findsNothing);
      expect(find.descendant(of: ungrouped, matching: rename), findsNothing);
      final title = find.text('Группа 1');
      final arrow = find.descendant(
        of: group,
        matching: find.byIcon(cu.CupertinoIcons.chevron_down),
      );
      expect(t.getRect(title).left - t.getRect(arrow).right, greaterThan(4));
      await t.tap(title);
      await t.pumpAndSettle();
      final firstPart = find.text(project.byId[1]!.name);
      expect(firstPart, findsNothing);
      final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer();
      addTearDown(mouse.removePointer);
      await mouse.moveTo(t.getCenter(title));
      await t.pumpAndSettle();
      final pencil = find.descendant(of: group, matching: rename);
      expect(t.getCenter(pencil).dx, greaterThan(t.getRect(title).right));
      await mouse.moveTo(t.getCenter(pencil));
      await t.tap(pencil);
      await t.pumpAndSettle();
      final input = find.descendant(
        of: group,
        matching: find.byType(EditableText),
      );
      expect(find.byType(DeskDialog), findsNothing);
      expect(t.widget<EditableText>(input).focusNode.hasFocus, isTrue);
      await t.enterText(input, 'Черновик');
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
      expect(input, findsNothing);
      expect(editor.canUndo, isFalse);
      await mouse.moveTo(t.getCenter(title));
      await t.pumpAndSettle();
      await t.tap(pencil);
      await t.pumpAndSettle();
      await t.enterText(input, '  Детали изделия  ');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pumpAndSettle();
      expect(find.text('Детали изделия'), findsNWidgets(2));
      expect(firstPart, findsNothing);
      expect(Project.decode(editor.project.encode()).groupNames, {
        1: 'Детали изделия',
      });
      await t.tap(
        find.descendant(of: group, matching: find.text('Детали изделия')),
      );
      await t.pumpAndSettle();
      expect(firstPart, findsOneWidget);
      editor.undo();
      await t.pumpAndSettle();
      expect(title, findsOneWidget);
      expect(find.text('Детали изделия'), findsOneWidget);
    },
    variant: TargetPlatformVariant({
      TargetPlatform.macOS,
      TargetPlatform.windows,
    }),
  );

  testWidgets('A collapsed group can reveal or hide its members in one edit', (
    t,
  ) async {
    await t.binding.setSurfaceSize(const Size(1200, 780));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final project = Project.bench()
        .edit({1, 2}, (b) => b.copy(group: 1, hidden: b.id == 1))
        .edit({3, 4}, (b) => b.copy(group: 2, hidden: true));
    final editor = Editor(project);
    await t.pumpWidget(NeprostoApp(editor: editor));
    await t.pumpAndSettle();
    final header = find.byKey(const ValueKey('group-header-1'));
    Finder action(String tip) => find
        .descendant(of: header, matching: find.byTooltip(tip))
        .hitTestable();
    final show = action('Показать все детали группы');
    final hide = action('Скрыть все детали группы');
    final title = find.descendant(of: header, matching: find.text('Группа 1'));
    final count = find.descendant(of: header, matching: find.text('2'));
    final titleOrigin = t.getTopLeft(title);
    final countBounds = t.getRect(count);
    final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer();
    addTearDown(mouse.removePointer);
    final defaultHeader = find.byKey(const ValueKey('group-header-null'));
    final defaultHide = find
        .descendant(
          of: defaultHeader,
          matching: find.byTooltip('Скрыть все детали группы'),
        )
        .hitTestable();
    expect(defaultHide, findsNothing);
    await mouse.moveTo(t.getCenter(defaultHeader));
    await t.pumpAndSettle();
    expect(defaultHide, findsOneWidget);
    await mouse.moveTo(Offset.zero);
    await t.pumpAndSettle();
    expect(defaultHide, findsNothing);
    expect(
      t.getRect(header).right - t.getRect(count).right,
      greaterThanOrEqualTo(12),
    );
    await t.tap(title);
    await t.pumpAndSettle();
    Set<int> hidden() => {
      for (final b in editor.project.beams)
        if (b.hidden) b.id,
    };
    expect(show, findsNothing);
    await mouse.moveTo(t.getCenter(title));
    await t.pumpAndSettle();
    expect(show, findsOneWidget);
    expect(t.getTopLeft(title), titleOrigin);
    expect(t.getRect(count), countBounds);
    await t.tap(show);
    await t.pumpAndSettle();
    expect(hidden(), {3, 4});
    await mouse.moveTo(Offset.zero);
    await t.pumpAndSettle();
    expect(hide, findsNothing);
    editor.undo();
    await t.pumpAndSettle();
    expect(editor.project, same(project));
    editor.redo();
    await t.pumpAndSettle();

    await mouse.moveTo(t.getCenter(title));
    await t.pumpAndSettle();
    expect(
      find.descendant(
        of: hide,
        matching: find.byIcon(PhosphorIconsRegular.eyeSlash),
      ),
      findsOneWidget,
    );
    await t.tap(hide);
    await t.pumpAndSettle();
    expect(
      find.descendant(of: show, matching: find.byIcon(cu.CupertinoIcons.eye)),
      findsOneWidget,
    );
    await mouse.moveTo(Offset.zero);
    await t.pumpAndSettle();
    expect(hidden(), {1, 2, 3, 4});
    expect(show, findsNothing);
    await mouse.moveTo(t.getCenter(title));
    await t.pumpAndSettle();
    expect(show, findsOneWidget);
    await t.tap(show);
    await t.pumpAndSettle();
    expect(hidden(), {3, 4});
    expect(find.text(project.byId[1]!.name), findsNothing);
  });

  testWidgets('H hides the selection and the toolbar restores it', (t) async {
    await t.binding.setSurfaceSize(const Size(1200, 780));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final e = Editor(Project.bench());
    await t.pumpWidget(NeprostoApp(editor: e));
    await t.pumpAndSettle();
    final showAll = find.byTooltip('Показать все скрытые детали');
    expect(showAll, findsNothing);

    final original = e.project;
    e.select(1);
    e.select(2, multi: true);
    await t.sendKeyEvent(LogicalKeyboardKey.keyH);
    await t.pumpAndSettle();
    final hidden = e.project;
    expect(
      {
        for (final b in hidden.beams)
          if (b.hidden) b.id,
      },
      {1, 2},
    );
    expect(e.selection, isEmpty);
    await t.sendKeyEvent(LogicalKeyboardKey.keyH);
    expect(e.project, same(hidden));
    await t.tap(showAll);
    await t.pumpAndSettle();
    expect(e.project.beams.where((b) => b.hidden), isEmpty);
    expect(showAll, findsNothing);

    e.undo();
    await t.pumpAndSettle();
    expect(e.project, same(hidden));
    expect(showAll, findsOneWidget);
    e.undo();
    expect(e.project, same(original));
  });

  testWidgets('Hidden parts can be outlined and restored from the parts tree', (
    t,
  ) async {
    await t.binding.setSurfaceSize(const Size(1200, 780));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final part = Project.bench().beams.first;
    final e = Editor(Project('Шкаф', [part]))..select(part.id);
    await t.pumpWidget(NeprostoApp(editor: e));
    await t.pumpAndSettle();
    final tree = find.byType(PartsPanel);
    expect(
      find.descendant(of: tree, matching: find.text('Список деталей')),
      findsOneWidget,
    );
    DrawingPainter painter() =>
        t.widget<CustomPaint>(find.byKey(const Key('drawing'))).painter!
            as DrawingPainter;
    final hide = find.byTooltip('Скрыть деталь').hitTestable();
    final show = find.byTooltip('Показать деталь').hitTestable();
    final name = find.descendant(of: tree, matching: find.text(part.name));
    final namePosition = t.getRect(name);
    final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer();
    addTearDown(mouse.removePointer);
    expect(hide, findsNothing);
    await mouse.moveTo(namePosition.center);
    await t.pumpAndSettle();
    expect(
      find.descendant(
        of: hide,
        matching: find.byIcon(PhosphorIconsRegular.eyeSlash),
      ),
      findsOneWidget,
    );
    expect(t.getRect(name), namePosition);
    await mouse.moveTo(Offset.zero);
    await t.pumpAndSettle();
    expect(hide, findsNothing);
    await mouse.moveTo(namePosition.center);
    await t.pumpAndSettle();
    final eyePosition = t.getCenter(hide);
    await mouse.moveTo(eyePosition);
    await mouse.down(eyePosition);
    await mouse.up();
    await t.pumpAndSettle();
    expect(
      find.descendant(of: show, matching: find.byIcon(cu.CupertinoIcons.eye)),
      findsOneWidget,
    );
    await mouse.moveTo(Offset.zero);
    await t.pumpAndSettle();
    expect(
      find.descendant(
        of: show,
        matching: find.byIcon(PhosphorIconsRegular.eyeClosed),
      ),
      findsOneWidget,
    );
    expect(e.selection, isEmpty);
    expect(painter().scene.faces, isEmpty);
    expect(painter().hiddenOutlines, isEmpty);
    expect(Project.decode(e.project.encode()).beams.single.hidden, isTrue);
    await t.tap(find.byTooltip('Настройки'));
    await t.pumpAndSettle();
    await t.tap(find.text('Чертёж').last);
    await t.pumpAndSettle();
    await t.tap(find.text('Показать контуры'));
    await t.tap(find.text('Готово'));
    await t.pumpAndSettle();
    expect(painter().hiddenOutlines.single.id, part.id);
    final scene = painter().scene;
    final corner = e.camera.project(part.corner(0), scene.size);
    expect(scene.hit(corner), isNull);
    expect(scene.snap(corner), isNull);
    await t.tap(show);
    await t.pumpAndSettle();
    expect(hide, findsNothing);
    expect(painter().scene.faces, isNotEmpty);
    expect(painter().hiddenOutlines, isEmpty);
  });

  testWidgets('Shift+W previews a dimensioned part until a click places it', (
    t,
  ) async {
    await t.binding.setSurfaceSize(const Size(1200, 780));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final e = Editor(Project('Шкаф', [], [], LengthUnit.centimeter));
    e.setView(ViewAngle.front);
    final original = e.project;
    await t.pumpWidget(NeprostoApp(editor: e));
    await t.pumpAndSettle();
    final drawing = find.byKey(const Key('drawing'));
    final pointer = t.getCenter(drawing) + const Offset(62, 43);
    final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer();
    addTearDown(mouse.removePointer);
    await mouse.moveTo(pointer);
    await t.pump();
    Vector3 position(Offset point) => e.plane.quantize(
      e.camera.onPlane(
        point - t.getTopLeft(drawing),
        t.getSize(drawing),
        e.plane,
      )!,
      e.step.millimeters(e.project.unit),
    );
    Beam? preview() =>
        (t.widget<CustomPaint>(drawing).painter! as DrawingPainter).preview;
    Future<void> open() async {
      await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await t.sendKeyEvent(LogicalKeyboardKey.keyW);
      await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await t.pumpAndSettle();
      expect(find.text('Выбрать место'), findsOneWidget);
    }

    await open();
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await t.pumpAndSettle();
    expect(e.project, same(original));
    expect(e.canUndo, isFalse);
    await open();
    await t.tap(find.text('Выбрать место'));
    await t.pumpAndSettle();
    await mouse.moveTo(pointer + const Offset(20, 10));
    await t.pump();
    expect(preview(), isNotNull);
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await t.pumpAndSettle();
    expect(preview(), isNull);
    expect(e.tool, Tool.select);
    expect(e.project, same(original));
    expect(e.canUndo, isFalse);
    await open();
    for (final (i, value) in ['45+5', '7', '2'].indexed) {
      await t.enterText(
        find.descendant(
          of: find.byKey(ValueKey('dialog-size-$i')),
          matching: find.byType(EditableText),
        ),
        value,
      );
    }
    await t.testTextInput.receiveAction(TextInputAction.done);
    await t.pumpAndSettle();
    expect(e.project, same(original));
    await mouse.moveTo(pointer);
    await t.pump();
    expect(preview()!.origin, position(pointer));
    expect(preview()!.size, Vector3(500, 70, 20));
    await mouse.moveTo(t.getCenter(find.text('Список деталей')));
    await t.pump();
    expect(preview(), isNull);
    final destination = pointer + const Offset(-105, 60);
    await mouse.moveTo(destination);
    await t.pump();
    expect(preview()!.origin, position(destination));
    expect(e.project, same(original));
    expect(e.canUndo, isFalse);
    await mouse.down(destination);
    await mouse.up();
    await t.pumpAndSettle();
    expect(preview(), isNull);
    expect(e.project.beams, hasLength(1));
    expect(e.single!.size, Vector3(500, 70, 20));
    expect(e.single!.origin, position(destination));
    expect(e.single!.across, e.plane.v);
    e.undo();
    expect(e.project, same(original));
  });

  testWidgets('Q and Command-Q fit one part between the nearest supports', (
    t,
  ) async {
    await t.binding.setSurfaceSize(const Size(1300, 820));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final part = Beam(
      1,
      'Стойка',
      Vector3(40, 0, 20),
      Vector3(30, 15, 10),
      axis(2),
      axis(0),
    );
    final project = Project('Рама', [
      part,
      part.copy(id: 2, origin: Vector3(0, 0, 20)),
      part.copy(id: 3, origin: Vector3(90, 0, 20)),
      part.copy(id: 4, origin: Vector3(110, 0, 20)),
      part.copy(id: 5, origin: Vector3(40, 0, -40)),
      part.copy(id: 6, origin: Vector3(40, 0, 80)),
    ]);
    final e = Editor(project)..select(1);
    await t.pumpWidget(NeprostoApp(editor: e));
    await t.pumpAndSettle();
    await t.sendKeyEvent(LogicalKeyboardKey.keyQ);
    final widened = e.project;
    expect(e.single!.origin, Vector3(15, 0, 20));
    expect(e.single!.size, Vector3(30, 75, 10));
    await t.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.keyQ);
    expect(e.single!.origin, Vector3(15, 0, -10));
    expect(e.single!.size, Vector3(90, 75, 10));
    expect(e.project.beams.skip(1), project.beams.skip(1));
    await t.sendKeyEvent(LogicalKeyboardKey.keyQ);
    await t.sendKeyEvent(LogicalKeyboardKey.keyZ);
    expect(e.project, same(widened));
    await t.sendKeyEvent(LogicalKeyboardKey.keyZ);
    expect(e.project, same(project));
    await t.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
  });

  testWidgets('The inspector and on-canvas editor respect dimension locks', (
    t,
  ) async {
    await t.binding.setSurfaceSize(const Size(1320, 820));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final e = Editor(Project.bench())
      ..select(1)
      ..setView(ViewAngle.top);
    await t.pumpWidget(NeprostoApp(editor: e));
    await t.pumpAndSettle();
    final drawing = find.byKey(const Key('drawing'));
    Future<Offset> doubleClickLabel(LogicalKeyboardKey mod) async {
      final painter = t.widget<CustomPaint>(drawing).painter! as DrawingPainter;
      final pointer =
          t.getTopLeft(drawing) +
          painter.stockLabels[StockAxis.thickness]!.center;
      await t.sendKeyDownEvent(mod);
      await t.tapAt(pointer);
      await t.pump(const Duration(milliseconds: 90));
      await t.tapAt(pointer);
      await t.sendKeyUpEvent(mod);
      await t.pumpAndSettle();
      return pointer;
    }

    final field = find.descendant(
      of: find.byKey(const Key('canvas-size-input')),
      matching: find.byType(DeskTextField),
    );
    final thickness = find.descendant(
      of: find.byKey(const Key('size-1-2')),
      matching: find.byType(DeskTextField),
    );
    final lock = find.byTooltip('Блокировать размер · Толщина');
    await t.ensureVisible(lock);
    await t.tap(lock);
    await t.pumpAndSettle();
    expect(t.widget<DeskTextField>(thickness).enabled, isFalse);
    await t.tap(thickness);
    await t.pumpAndSettle();
    expect(t.widget<DeskTextField>(thickness).focusNode!.hasFocus, isFalse);
    await doubleClickLabel(LogicalKeyboardKey.metaLeft);
    expect(field, findsNothing);
    expect(e.message, 'Размер заблокирован');

    await t.tap(find.byTooltip('Разблокировать размер · Толщина'));
    await t.pumpAndSettle();
    expect(t.widget<DeskTextField>(thickness).enabled, isTrue);
    await t.enterText(thickness, '44');
    await t.testTextInput.receiveAction(TextInputAction.done);
    await t.pumpAndSettle();
    expect(e.single!.size.z, 44);
    final unlocked = e.project;
    for (final (mod, key) in [
      (LogicalKeyboardKey.metaLeft, LogicalKeyboardKey.enter),
      (LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.escape),
    ]) {
      final pointer = await doubleClickLabel(mod);
      expect(field, findsOneWidget);
      expect((t.getCenter(field) - pointer).distance, lessThan(1));
      await t.enterText(field, '4*10+12');
      await t.pump();
      if (key == LogicalKeyboardKey.enter) {
        await t.testTextInput.receiveAction(TextInputAction.done);
        await t.pumpAndSettle();
        expect(t.widget<DeskTextField>(field).controller!.text, '52');
        await t.sendKeyEvent(LogicalKeyboardKey.enter);
        await t.pumpAndSettle();
        expect(e.single!.size.z, 52);
        e.undo();
        await t.pumpAndSettle();
      } else {
        await t.sendKeyEvent(key);
        await t.pumpAndSettle();
      }
      expect(field, findsNothing);
      expect(e.project, same(unlocked));
      expect(e.single!.id, 1);
    }
  });

  testWidgets(
    'Parts list shows exact names, stock dimensions and quantities in flat rows',
    (t) async {
      await t.binding.setSurfaceSize(const Size(1320, 820));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final beam = Beam(
        1,
        'Полка 1',
        Vector3.zero(),
        Vector3(600, 80, 15),
        axis(0),
        axis(1),
      );
      final e = Editor(
        Project('Шкаф', [
          beam,
          beam.copy(id: 2, name: 'Полка 2', origin: Vector3(0, 0, 100)),
          beam.copy(id: 4, holes: [PanelHole(40, 20, 6)]),
          beam.copy(id: 5, size: Vector3(720, 80, 15)),
          beam.copy(
            id: 3,
            name: 'Скос',
            startCut: (y: 40, z: 0),
            origin: Vector3(0, 0, 200),
          ),
        ]),
      );
      await t.pumpWidget(NeprostoApp(editor: e));
      await t.pumpAndSettle();
      await t.tap(find.text('Список деталей'));
      await t.pumpAndSettle();
      Finder inside(String text) => find.descendant(
        of: find.byType(PartsList),
        matching: find.text(text),
      );
      Finder partRow(String name, String length) => find.ancestor(
        of: inside(name),
        matching: find.ancestor(of: inside(length), matching: find.byType(Row)),
      );
      final repeated = partRow('Полка 1', '600');
      expect(inside('Полка 1'), findsNWidgets(2));
      expect(partRow('Полка 1', '720'), findsOneWidget);
      expect(partRow('Полка 2', '600'), findsOneWidget);
      expect(partRow('Скос', '620'), findsOneWidget);
      expect(
        find.descendant(of: repeated, matching: find.text('2')),
        findsOneWidget,
      );
      expect(
        find.ancestor(of: inside('Полка 1'), matching: find.byType(DeskButton)),
        findsNothing,
      );
      const channel = MethodChannel('plugins.flutter.io/file_selector');
      final messenger = t.binding.defaultBinaryMessenger;
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return null;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      await t.tap(inside('Экспорт в Excel'));
      await t.pumpAndSettle();
      expect(
        calls.single.arguments['suggestedName'],
        'Шкаф — список деталей.xlsx',
      );
      expect(inside('Файл Excel сохранён'), findsNothing);
      final search = find.descendant(
        of: find.byType(DeskSearchField),
        matching: find.byType(EditableText),
      );
      await t.enterText(search, 'Полка 1');
      await t.pumpAndSettle();
      expect(find.textContaining('Найдено 3 из 5'), findsOneWidget);
      expect(inside('Полка 2'), findsNothing);
      await t.enterText(search, 'Несуществующая');
      await t.pumpAndSettle();
      final exportButton = find.ancestor(
        of: inside('Экспорт в Excel'),
        matching: find.byType(DeskButton),
      );
      expect(t.widget<DeskButton>(exportButton).onPressed, isNull);
    },
  );

  for (final snap in [true, false]) {
    testWidgets('Place by anchor moves between drawing points (snap $snap)', (
      t,
    ) async {
      await t.binding.setSurfaceSize(const Size(1320, 950));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final part = Beam(
        1,
        'Полка',
        Vector3(0, 0, 40),
        Vector3(220, 100, 30),
        axis(0),
        axis(1),
      );
      final support = part.copy(
        id: 2,
        name: 'Опора',
        origin: Vector3(340, 140, 100),
      );
      final project = Project('Стенд', [part, support]);
      final e = Editor(project)
        ..setView(ViewAngle.top)
        ..select(part.id)
        ..snap = snap
        ..snapMode = snap ? SnapMode.auto : SnapMode.surface;
      await t.pumpWidget(NeprostoApp(editor: e));
      await t.pumpAndSettle();
      final inspector = find.byType(Inspector);
      final button = find.text('Поставить по опоре');
      await t.scrollUntilVisible(
        button.hitTestable(),
        200,
        scrollable: find
            .descendant(of: inspector, matching: find.byType(Scrollable))
            .first,
      );
      await t.tap(button);
      await t.pumpAndSettle();
      expect(e.tool, Tool.move);
      expect(
        find.descendant(of: inspector, matching: find.byType(EditableText)),
        findsNothing,
      );
      expect(
        find.descendant(of: inspector, matching: find.text('Повернуть')),
        findsNothing,
      );
      Finder step(int number) => find.descendant(
        of: inspector,
        matching: find.textContaining('$number из 2.'),
      );
      expect(step(1), findsOneWidget);
      final drawing = find.byKey(const Key('drawing'));
      Offset screen(Vector3 point) =>
          t.getTopLeft(drawing) + e.camera.project(point, t.getSize(drawing));
      final from = part.pointAt(Vector3(.26, .33, 1));
      final to = snap
          ? support.corner(7)
          : support.pointAt(Vector3(.32, .27, 1));
      final destination =
          screen(to) + (snap ? const Offset(-2, 2) : Offset.zero);
      await t.tapAt(screen(support.pointAt(Vector3.all(.5))));
      expect(e.first, isNull);
      await t.tapAt(screen(from));
      await t.pumpAndSettle();
      expect(e.first?.beam, part.id);
      expect(step(2), findsOneWidget);
      expect(e.project, same(project));
      expect(e.canUndo, isFalse);
      final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer();
      await mouse.moveTo(destination);
      await t.pump();
      final roundedFrom = Vector3(57, 33, 70);
      final roundedTo = snap ? to : Vector3(410, 167, 130);
      final expected = part.origin + (roundedTo - roundedFrom);
      expect(e.preview!.origin.distanceTo(expected), lessThan(.0001));
      await mouse.removePointer();
      await t.tapAt(destination);
      await t.pumpAndSettle();
      expect(e.tool, Tool.select);
      expect(
        find.descendant(of: inspector, matching: find.text('Размеры детали')),
        findsOneWidget,
      );
      expect(e.single!.origin.distanceTo(expected), lessThan(.0001));
      expect(e.project.byId[2], same(support));
      e.undo();
      expect(e.project, same(project));
    });
  }

  testWidgets(
    'Anchor placement shows its assigned key and Esc restores the inspector',
    (t) async {
      await t.binding.setSurfaceSize(const Size(900, 650));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final e = Editor(Project.bench());
      await t.pumpWidget(NeprostoApp(editor: e));
      await t.pumpAndSettle();
      await t.sendKeyEvent(LogicalKeyboardKey.keyM);
      await t.pumpAndSettle();
      final inspector = find.byType(Inspector);
      Finder inside(String text) =>
          find.descendant(of: inspector, matching: find.text(text));
      expect(inside('Поставить по опоре'), findsOneWidget);
      expect(inside('Работа с чертежом'), findsNothing);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
      expect(e.tool, Tool.select);
      e.hotkeys = e.hotkeys.assign(Command.move, (
        key: LogicalKeyboardKey.keyK,
        primary: false,
        shift: false,
        alt: false,
      ));
      e.select(1);
      await t.pumpAndSettle();
      await t.scrollUntilVisible(
        inside('Поставить по опоре').hitTestable(),
        180,
        scrollable: find
            .descendant(of: inspector, matching: find.byType(Scrollable))
            .first,
      );
      expect(inside('K'), findsOneWidget);
      await t.sendKeyEvent(LogicalKeyboardKey.keyK);
      await t.pumpAndSettle();
      expect(inside('Отмена').hitTestable(), findsOneWidget);
      expect(inside(e.single!.name), findsOneWidget);
      await t.tap(inside('Отмена'));
      await t.pumpAndSettle();
      expect(e.tool, Tool.select);
      expect(e.canUndo, isFalse);
    },
  );

  testWidgets('Position fields show the project axis at the edited origin', (
    t,
  ) async {
    await t.binding.setSurfaceSize(const Size(1320, 900));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final project = Project.bench().rotate({9}, axis(2), 30);
    final e = Editor(project)
      ..select(9)
      ..setView(ViewAngle.top);
    await t.pumpWidget(NeprostoApp(editor: e));
    await t.pumpAndSettle();
    final drawing = find.byKey(const Key('drawing'));
    DrawingPainter painter() =>
        t.widget<CustomPaint>(drawing).painter! as DrawingPainter;
    Finder field(int dim) => find.byKey(ValueKey('position-$dim'));
    expect(painter().positionGuide, isNull);
    await t.ensureVisible(field(0));
    await t.tap(field(0));
    await t.pumpAndSettle();
    final origin = e.single!.origin;
    for (var dim = 0; dim < 3; dim++) {
      if (dim > 0) {
        await t.sendKeyEvent(LogicalKeyboardKey.tab);
        await t.pumpAndSettle();
      }
      expect(painter().positionGuide, (axis: dim, origin: origin));
      final center = painter().project(origin);
      expect(
        t.renderObject(drawing),
        paints..something(
          (method, args) =>
              method == #drawCircle &&
              ((args[0] as Offset) - center).distance < .001 &&
              args[1] == (dim == 2 ? 6 : 3.5) &&
              (args[2] as Paint).color.toARGB32() ==
                  painter().colors.axisColor(dim).toARGB32(),
        ),
      );
    }
    await t.testTextInput.receiveAction(TextInputAction.done);
    await t.pumpAndSettle();
    expect(painter().positionGuide, isNull);
    expect(e.canUndo, isFalse);
    e.select(5, multi: true);
    await t.pumpAndSettle();
    await t.ensureVisible(field(1));
    await t.tap(field(1));
    await t.pumpAndSettle();
    final low = Bounds3.points(e.selected.expand((b) => b.corners)).low;
    expect(painter().positionGuide, (axis: 1, origin: low));
    await t.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await t.pumpAndSettle();
    final moved = painter().positionGuide!;
    expect(moved.axis, 1);
    final expected = low.clone()..y = low.y.roundToDouble() + 1;
    expect(moved.origin.distanceTo(expected), lessThan(.001));
  });

  testWidgets(
    'Align to reference joins a corner and an edge midpoint in either order',
    (t) async {
      await t.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final part = Beam(
        1,
        'Полка',
        Vector3.zero(),
        Vector3(100, 36, 16),
        axis(0),
        axis(1),
      );
      final support = part.copy(
        id: 2,
        name: 'Опора',
        origin: Vector3(150, 60, 30),
      );
      final project = Project('Стенд', [part, support]);
      final e = Editor(project)
        ..select(1)
        ..setView(ViewAngle.top)
        ..fitRequested = false;
      e.camera.target = Vector3(125, 50, 0);
      e.camera.scale = 2;
      await t.pumpWidget(NeprostoApp(editor: e));
      await t.pumpAndSettle();
      final drawing = find.byKey(const Key('drawing'));
      DrawingPainter painter() =>
          t.widget<CustomPaint>(drawing).painter! as DrawingPainter;
      Offset screen(Vector3 p) => t.getTopLeft(drawing) + painter().project(p);
      final corner = part.corner(7),
          middle = support.pointAt(Vector3(.5, 0, 1));
      final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer();
      Future<void> hoverAnchor(Vector3 at, String label) async {
        await mouse.moveTo(screen(at) + const Offset(1, 1));
        await t.pump();
        final paint = painter();
        expect(paint.hover?.displayLabel, label);
        expect(paint.hover!.point.distanceTo(at), lessThan(.001));
        expect(
          t.renderObject(drawing),
          paints..something(
            (method, args) =>
                method == #drawCircle &&
                args[1] == 5 &&
                ((args[0] as Offset) - paint.project(at)).distance < .001,
          ),
        );
      }

      for (final supportFirst in [false, true]) {
        await t.tap(find.text('Выровнять по опоре…'));
        await t.pumpAndSettle();
        if (supportFirst) {
          await t.tap(find.text('На чертеже'));
          await t.pumpAndSettle();
        }
        final a = supportFirst ? middle : corner,
            b = supportFirst ? corner : middle;
        await hoverAnchor(a, supportFirst ? 'Середина ребра' : 'Угол');
        await t.tapAt(screen(a));
        await t.pump();
        expect(e.first?.point, a);
        expect(e.project, same(project));
        await t.tapAt(screen(Vector3(-18, -18, 0)));
        expect(e.first?.point, a);
        expect(e.canUndo, isFalse);
        await hoverAnchor(b, supportFirst ? 'Угол' : 'Середина ребра');
        expect(painter().alignmentSupport?.id, support.id);
        expect(painter().preview!.corner(7).distanceTo(middle), lessThan(.001));
        await t.tapAt(screen(b));
        await t.pumpAndSettle();
        expect(e.tool, Tool.select);
        expect(e.single!.corner(7).distanceTo(middle), lessThan(.001));
        expect(e.project.byId[2], same(support));
        e.undo();
        await t.pumpAndSettle();
        expect(e.project, same(project));
        expect(e.canUndo, isFalse);
      }
      await mouse.removePointer();
    },
  );

  testWidgets(
    'Holding the alignment modifier temporarily picks a support on the drawing',
    (t) async {
      await t.binding.setSurfaceSize(const Size(1100, 760));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final project = Project.bench();
      final e = Editor(project)
        ..setView(ViewAngle.top)
        ..select(9)
        ..beginAlignment();
      await t.pumpWidget(NeprostoApp(editor: e));
      await t.pumpAndSettle();
      final modifier = defaultTargetPlatform == TargetPlatform.macOS
          ? LogicalKeyboardKey.metaLeft
          : LogicalKeyboardKey.controlLeft;
      final drawing = find.byKey(const Key('drawing'));
      Offset board(int id) =>
          t.getTopLeft(drawing) +
          e.camera.project(
            project.byId[id]!.pointAt(Vector3(.5, .5, 1)),
            t.getSize(drawing),
          );
      final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer();
      addTearDown(mouse.removePointer);
      await mouse.moveTo(t.getCenter(find.text('На чертеже')));
      await t.pumpAndSettle();
      await t.sendKeyDownEvent(modifier);
      await mouse.moveTo(board(2));
      await t.pumpAndSettle();
      expect(e.alignmentSupport?.id, 2);
      await t.tapAt(board(2));
      await t.sendKeyUpEvent(modifier);
      await t.pumpAndSettle();
      expect(e.referenceId, 2);
      expect(e.single?.id, 9);
      final field = find.byKey(const Key('placement-offset'));
      await t.enterText(field, '27');
      await t.pumpAndSettle();
      await mouse.moveTo(board(3));
      await t.sendKeyDownEvent(modifier);
      await t.pumpAndSettle();
      expect(e.alignmentSupport?.id, 3);
      expect(e.previewPlacement, isNull);
      await t.sendKeyUpEvent(modifier);
      await t.pumpAndSettle();
      expect(e.alignmentSupport?.id, 2);
      expect(e.previewPlacement, isNotNull);
      expect(e.manualOffset, 27);
      expect(e.project, same(project));
      expect(e.canUndo, isFalse);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
      expect(e.tool, Tool.select);
      expect(e.displayed, same(project));
      expect(find.text('На чертеже'), findsNothing);
    },
    variant: TargetPlatformVariant({
      TargetPlatform.macOS,
      TargetPlatform.windows,
    }),
  );

  testWidgets(
    'Aligning to a support waits for a reference, a placement and confirmation',
    (t) async {
      await t.binding.setSurfaceSize(const Size(1320, 850));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final e = Editor(Project.bench())..select(9);
      await t.pumpWidget(NeprostoApp(editor: e));
      await t.pumpAndSettle();
      final original = e.project;
      final drawing = find.byKey(const Key('drawing'));
      expect(find.text('Выравнивание'), findsNothing);
      expect(find.text('Перемещаемая деталь'), findsNothing);
      expect(find.text('Размеры детали'), findsOneWidget);
      final positionField = find.byKey(const Key('position-0'));
      final positionRect = t.getRect(positionField.hitTestable());
      await t.tap(find.text('Выровнять по опоре…'));
      await t.pumpAndSettle();
      expect(e.tool, Tool.align);
      expect(find.text('Выравнивание'), findsOneWidget);
      expect(find.text('Размеры детали'), findsOneWidget);
      expect(t.getRect(positionField), positionRect);
      expect(
        positionRect.top,
        greaterThan(t.getRect(find.text('Применить')).bottom),
      );
      expect(positionField.hitTestable(), findsNothing);
      final positionInput = find.descendant(
        of: positionField,
        matching: find.byType(EditableText),
      );
      expect(
        t.widget<EditableText>(positionInput).focusNode.canRequestFocus,
        isFalse,
      );
      final pickButton = find.ancestor(
        of: find.text('На чертеже'),
        matching: find.byType(DeskButton),
      );
      expect(
        find.descendant(of: pickButton, matching: find.byType(Text)),
        findsOneWidget,
      );
      final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      final colors = <Color>{};
      for (final option in ['front', 'middle', 'back']) {
        await mouse.moveTo(t.getCenter(find.byKey(ValueKey('align-$option'))));
        await t.pumpAndSettle();
        final painter =
            t.widget<CustomPaint>(drawing).painter! as DrawingPainter;
        expect(painter.preview, isNotNull);
        expect(painter.alignmentSupport?.id, 5);
        colors.add(painter.previewColor);
        expect(painter.scene.project, same(original));
        expect(e.canUndo, false);
      }
      expect(colors, hasLength(3));
      await mouse.moveTo(Offset.zero);
      await mouse.removePointer();
      await t.pumpAndSettle();
      expect(
        (t.widget<CustomPaint>(drawing).painter! as DrawingPainter).preview,
        isNull,
      );
      expect(
        (t.widget<CustomPaint>(drawing).painter! as DrawingPainter)
            .alignmentSupport
            ?.id,
        5,
      );
      await t.tap(find.text('На чертеже'));
      await t.pumpAndSettle();
      expect(e.referenceId, isNull);
      expect(e.displayed, same(original));
      expect(e.canUndo, false);
      await t.tap(find.text('Ножка 1').first);
      await t.pumpAndSettle();
      expect(e.referenceId, 5);
      expect(e.displayed, same(original));
      expect(e.canUndo, false);
      await t.tap(find.byKey(const ValueKey('align-front')));
      await t.pumpAndSettle();
      expect(e.project, same(original));
      expect(e.displayed.byId[9]!.origin.y, 25);
      expect(e.canUndo, false);
      await t.tap(find.text('Отмена'));
      await t.pumpAndSettle();
      expect(e.displayed, same(original));
      expect(e.tool, Tool.select);
      expect(e.alignmentSupport, isNull);
      await t.tap(find.text('Выровнять по опоре…'));
      await t.pumpAndSettle();
      await t.tap(find.text('На чертеже'));
      await t.tap(find.text('Ножка 1').first);
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('align-front')));
      await t.pumpAndSettle();
      await t.tap(find.text('Применить'));
      await t.pumpAndSettle();
      expect(e.project.byId[9]!.origin.y, 25);
      expect(e.tool, Tool.select);
      expect(find.text('Выравнивание'), findsNothing);
      e.undo();
      expect(e.project, same(original));
    },
  );

  testWidgets(
    'Closing the compact alignment panel discards the preview and returns to part properties',
    (t) async {
      await t.binding.setSurfaceSize(const Size(980, 350));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final original = Project.bench();
      final e = Editor(original)..select(9);
      await t.pumpWidget(NeprostoApp(editor: e));
      await t.pumpAndSettle();
      await t.tap(find.text('Выровнять по опоре…'));
      await t.pumpAndSettle();
      final close = find.descendant(
        of: find.byType(Inspector),
        matching: find.byTooltip('Закрыть'),
      );
      final apply = find.text('Применить');
      final closePosition = t.getCenter(close);
      expect(
        closePosition.dx,
        greaterThan(t.getRect(find.text('Выравнивание')).right),
      );
      final applyPosition = t.getCenter(apply);
      final offset = find.byKey(const Key('placement-offset'));
      await t.ensureVisible(offset);
      await t.enterText(offset, '27');
      await t.pumpAndSettle();
      expect(e.displayed.byId[9]!.origin, isNot(original.byId[9]!.origin));
      expect(t.getCenter(close.hitTestable()), closePosition);
      expect(t.getCenter(apply.hitTestable()), applyPosition);
      await t.tap(close);
      await t.pumpAndSettle();
      expect(find.text('Выравнивание'), findsNothing);
      expect(find.text('Выровнять по опоре…'), findsOneWidget);
      expect(e.tool, Tool.select);
      expect(e.single?.id, 9);
      expect(e.displayed, same(original));
      expect(e.canUndo, isFalse);
    },
  );

  testWidgets(
    'Alignment previews offsets and moves only the selected part',
    (t) async {
      await t.binding.setSurfaceSize(const Size(1320, 850));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final e = Editor(Project.bench())..select(9);
      await t.pumpWidget(NeprostoApp(editor: e));
      await t.pumpAndSettle();
      final before = e.project;
      await t.tap(find.text('Выровнять по опоре…'));
      await t.pumpAndSettle();
      expect(find.text('Перемещаемая деталь'), findsNothing);
      expect(find.byTooltip('Выбрать перемещаемую деталь'), findsNothing);
      await t.tap(find.byTooltip('Выбрать опорную деталь из списка'));
      await t.pumpAndSettle();
      await t.tap(find.text('Ножка 2').last);
      await t.pumpAndSettle();
      expect(e.single?.id, 9);
      expect(e.referenceId, 6);
      expect(e.project, same(before));
      final width = find.text('По ширине'), thickness = find.text('По толщине');
      expect(width, findsOneWidget);
      await t.tap(thickness);
      await t.pumpAndSettle();
      expect(e.alignThickness, isTrue);
      expect(find.text('Отступ от нижнего края опоры'), findsOneWidget);
      expect(find.byIcon(PhosphorIconsRegular.alignBottom), findsOneWidget);
      expect(find.byIcon(PhosphorIconsRegular.alignTop), findsOneWidget);
      final slide = await t.startGesture(
        t.getCenter(thickness),
        kind: PointerDeviceKind.mouse,
      );
      await slide.moveBy(const Offset(-24, 0));
      await t.pump();
      await slide.moveTo(t.getCenter(width));
      await slide.up();
      await t.pumpAndSettle();
      expect(e.alignThickness, isFalse);
      expect(e.referenceId, 6);
      final offsetLabel = find.text('Отступ от переднего края опоры');
      final offsetBox = find.byKey(const Key('placement-offset'));
      expect(t.getSize(offsetBox).width, 92);
      expect(
        t.getRect(offsetBox).left - t.getRect(offsetLabel).right,
        greaterThanOrEqualTo(6),
      );
      expect(find.text('0 — заподлицо, минус — выступ'), findsNothing);
      expect(e.displayed, same(before));
      expect(e.canUndo, isFalse);
      final field = find.descendant(
        of: find.byKey(const Key('placement-offset')),
        matching: find.byType(DeskTextField),
      );
      await t.enterText(field, '-25/2');
      await t.pumpAndSettle();
      expect(e.manualOffset, -13);
      expect(e.project, same(before));
      final expected = e.displayed.byId[9]!.origin;
      await t.enterText(field, '8/0');
      await t.pumpAndSettle();
      expect(find.text('Проверьте выражение'), findsOneWidget);
      expect(
        t
            .widget<DeskButton>(
              find.ancestor(
                of: find.text('Применить'),
                matching: find.byType(DeskButton),
              ),
            )
            .onPressed,
        isNull,
      );
      await t.enterText(field, '-25/2');
      await t.pump();
      await t.tap(find.text('Применить'));
      await t.pumpAndSettle();
      expect(e.single!.origin, expected);
      expect(e.single!.id, 9);
      for (final part in before.beams.where((part) => part.id != 9)) {
        expect(e.project.byId[part.id]!.origin, part.origin);
      }
      expect(e.suggestedPlacement?.reference.id, 6);
      await t.tap(find.text('Ножка 1').first);
      await t.pumpAndSettle();
      expect(e.single?.id, 5);
      await t.tap(find.text('Выровнять по опоре…'));
      await t.pumpAndSettle();
      // A post's width is along X, so its controls show left and right edges.
      await t.tap(find.text('По ширине'));
      await t.pumpAndSettle();
      expect(find.byIcon(PhosphorIconsRegular.alignLeft), findsOneWidget);
      expect(
        find.byIcon(PhosphorIconsRegular.alignCenterHorizontal),
        findsOneWidget,
      );
      expect(find.byIcon(PhosphorIconsRegular.alignRight), findsOneWidget);
      e.undo();
      expect(e.project, same(before));
    },
  );

  testWidgets(
    'Right click acts on selected boards together and right drag still orbits',
    (t) async {
      await t.binding.setSurfaceSize(const Size(1320, 850));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final e = Editor(Project.bench())..setView(ViewAngle.top);
      await t.pumpWidget(NeprostoApp(editor: e));
      await t.pumpAndSettle();
      final drawing = find.byKey(const Key('drawing'));
      Offset board(int id) =>
          t.getTopLeft(drawing) +
          e.camera.project(
            e.project.byId[id]!.pointAt(Vector3.all(.5)),
            t.getSize(drawing),
          );
      Future<void> rightClick(Offset position) async {
        final g = await t.startGesture(
          position,
          kind: PointerDeviceKind.mouse,
          buttons: kSecondaryMouseButton,
        );
        await g.up();
        await t.pumpAndSettle();
      }

      final original = e.project;
      await t.tapAt(board(1));
      await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      for (final id in [2, 3, 4]) {
        await t.tapAt(board(id));
        await t.pump();
      }
      await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await rightClick(board(3));
      final buildInPlane = find.text('Строить в этой плоскости');
      await t.tap(buildInPlane);
      await t.pumpAndSettle();
      final clickedBoard = e.project.byId[3]!;
      expect(e.plane.normal, clickedBoard.up);
      expect(e.plane.origin.z, clickedBoard.pointAt(Vector3.all(1)).z);
      expect(e.selection, {1, 2, 3, 4});
      expect(e.canUndo, false);
      await rightClick(board(3));
      expect(find.text('Сгруппировать'), findsOneWidget);
      await t.tap(find.text('Сгруппировать'));
      await t.pumpAndSettle();
      expect(e.project.assembly(3), {1, 2, 3, 4});
      await rightClick(t.getCenter(find.text('Планка сиденья 2').first));
      expect(buildInPlane, findsNothing);
      expect(find.text('Сгруппировать'), findsNothing);
      await t.tap(find.text('Разгруппировать'));
      await t.pumpAndSettle();
      expect(e.selected.every((b) => b.group == null), isTrue);
      e.undo();
      e.undo();
      expect(e.project, same(original));
      await t.pumpAndSettle();
      final other = t.getCenter(find.text('Ножка 1').first);
      await rightClick(other);
      expect(e.selection, {5});
      expect(find.text('Название и размеры…'), findsOneWidget);
      await t.tap(find.text('Дублировать'));
      await t.pumpAndSettle();
      expect(e.project.beams, hasLength(original.beams.length + 1));
      final at = board(2);
      final yaw = e.camera.yaw;
      final drag = await t.startGesture(
        at,
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await drag.moveBy(const Offset(45, 15));
      await drag.up();
      await t.pumpAndSettle();
      expect(e.camera.yaw, isNot(yaw));
      expect(find.text('Дублировать'), findsNothing);
      final empty = t.getBottomRight(drawing) - const Offset(10, 10);
      await rightClick(empty);
      expect(buildInPlane, findsNothing);
      await t.tap(find.text('Новая деталь здесь'));
      await t.pumpAndSettle();
      expect(e.project.beams, hasLength(original.beams.length + 2));
    },
  );

  testWidgets(
    'Double clicking wood opens a local size editor with cancel and atomic apply',
    (t) async {
      await t.binding.setSurfaceSize(const Size(1350, 840));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final e = Editor(Project.bench())..setView(ViewAngle.top);
      await t.pumpWidget(NeprostoApp(editor: e));
      await t.pumpAndSettle();
      final d = find.byKey(const Key('drawing')), before = e.project;
      final at =
          t.getTopLeft(d) +
          e.camera.project(Vector3(240, 40, 450), t.getSize(d));
      Future<void> open() async {
        await t.tapAt(at);
        await t.pump(const Duration(milliseconds: 90));
        await t.tapAt(at);
        await t.pumpAndSettle();
        expect(find.byType(DeskDialog), findsOneWidget);
      }

      Finder input(int i) => find.descendant(
        of: find.byKey(ValueKey('dialog-size-$i')),
        matching: find.byType(DeskTextField),
      );
      Finder lock(StockAxis axis, {bool locked = false}) => find.descendant(
        of: find.byType(DeskDialog),
        matching: find.byTooltip(
          '${locked ? 'Разблокировать' : 'Блокировать'} размер · ${axis.label}',
        ),
      );
      await open();
      expect(e.highlightedSize, 0);
      expect(
        find.descendant(
          of: find.byType(DeskDialog),
          matching: find.byIcon(cu.CupertinoIcons.pencil),
        ),
        findsNothing,
      );
      await t.tap(lock(StockAxis.thickness));
      await t.pumpAndSettle();
      expect(t.widget<DeskTextField>(input(2)).enabled, false);
      expect(
        t.getRect(find.byType(DeskDialog)).left,
        closeTo(at.dx + 12, .001),
      );
      await t.enterText(input(0), '100+47');
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.pump();
      expect(e.focusedSize, 1);
      await t.enterText(input(1), '1/0');
      await t.pump();
      expect(e.focusedSize, 1);
      final apply = find.ancestor(
        of: find.descendant(
          of: find.byType(DeskDialog),
          matching: find.text('Применить'),
        ),
        matching: find.byType(DeskButton),
      );
      expect(t.widget<DeskButton>(apply).onPressed, isNull);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
      expect(find.byType(DeskDialog), findsNothing);
      expect(e.project, same(before));
      await open();
      expect(t.widget<DeskTextField>(input(2)).enabled, true);
      await t.enterText(input(1), '4*10+12');
      await t.tap(lock(StockAxis.width));
      await t.pumpAndSettle();
      await t.enterText(
        find.descendant(
          of: find.byKey(const Key('part-dialog-name')),
          matching: find.byType(EditableText),
        ),
        'Сиденье',
      );
      await t.enterText(input(2), '12');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pumpAndSettle();
      expect(find.byType(DeskDialog), findsNothing);
      expect(e.single!.size, Vector3(1200, 52, 12));
      expect(e.single!.name, 'Сиденье');
      expect(e.single!.locks, 1 << StockAxis.width.index);
      final edited = e.project;
      await open();
      expect(t.widget<DeskTextField>(input(1)).enabled, false);
      await t.tap(lock(StockAxis.width, locked: true));
      await t.pumpAndSettle();
      expect(t.widget<DeskTextField>(input(1)).enabled, true);
      await t.tap(apply);
      await t.pumpAndSettle();
      expect(e.single!.locks, 0);
      expect(e.single!.size, Vector3(1200, 52, 12));
      e.undo();
      expect(e.project, same(edited));
      e.undo();
      expect(e.project, same(before));
    },
  );

  testWidgets('B draws from the reference face using its section and depth', (
    t,
  ) async {
    await t.binding.setSurfaceSize(const Size(1340, 840));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final board = Beam(
      1,
      'Планка',
      Vector3(0, 0, 100),
      Vector3(240, 84, 12),
      axis(0),
      axis(1),
    );
    final e = Editor(Project('Стол', [board]))..setView(ViewAngle.top);
    await t.pumpWidget(NeprostoApp(editor: e));
    await t.pumpAndSettle();
    final d = find.byKey(const Key('drawing'));
    Offset at(Vector3 point) =>
        t.getTopLeft(d) + e.camera.project(point, t.getSize(d));
    for (final view in [ViewAngle.top, ViewAngle.iso, ViewAngle.front]) {
      e.setView(view);
      await t.pumpAndSettle();
      await t.sendKeyEvent(LogicalKeyboardKey.keyB);
      await t.pump();
      final start = view == ViewAngle.front
          ? Vector3(170, 0, 105)
          : Vector3(170, 56, 112);
      final end = start + Vector3(78, 0, 0);
      await t.tapAt(at(start));
      await t.pump();
      expect(e.sketch!.reference?.id, 1);
      await t.tapAt(at(end));
      await t.pumpAndSettle();
      final made = e.single!;
      expect(made.size.y, 84);
      expect(made.size.z, 12);
      if (view == ViewAngle.front) {
        expect(made.origin.y, closeTo(0, 1e-5));
        expect(made.across.dot(axis(1)), closeTo(1, 1e-5));
      } else {
        expect(made.origin.z, closeTo(100, 1e-5));
        expect(made.up.dot(axis(2)), closeTo(1, 1e-5));
      }
      e.undo();
      await t.pump();
    }
  });

  testWidgets('Shift targets the visible side of a thin rotated part', (
    t,
  ) async {
    await t.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final part = Beam(
      1,
      'Полка',
      Vector3.zero(),
      Vector3(120, 40, 12),
      Vector3(.8, .6, 0),
      Vector3(-.6, .8, 0),
    );
    final original = Project('Шкаф', [part]);
    final e = Editor(original)
      ..setView(ViewAngle.perspective)
      ..fitRequested = false;
    e.camera.scale = 2;
    await t.pumpWidget(NeprostoApp(editor: e));
    await t.pumpAndSettle();
    final drawing = find.byKey(const Key('drawing'));
    DrawingPainter painter() =>
        t.widget<CustomPaint>(drawing).painter! as DrawingPainter;
    Offset at(Vector3 world) =>
        t.getTopLeft(drawing) + e.camera.project(world, t.getSize(drawing));
    final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer();
    await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    // The top and side of the board share this long edge.
    final top = at(part.pointAt(Vector3(.64, .03, 1)));
    await mouse.moveTo(top);
    await t.pump();
    expect(painter().activeEdge?.axis, 1);
    expect(painter().activeEdge?.positive, false);
    final side = part.pointAt(Vector3(.64, 0, .85));
    await mouse.moveTo(at(side));
    await t.pump();
    expect(painter().activeEdge?.axis, 2);
    await mouse.down(at(side));
    await mouse.moveTo(at(side + part.up * 15));
    await t.pump();
    expect(e.single!.size, Vector3(120, 40, 27));
    await mouse.cancel();
    await t.pump();
    expect(e.project, same(original));
    expect(e.canUndo, false);

    final start = part.pointAt(Vector3(.01, .55, 1));
    await mouse.moveTo(at(start));
    await t.pump();
    expect(painter().activeEdge?.axis, 0);
    await mouse.down(at(start));
    await mouse.moveTo(at(start - part.along * 18));
    await mouse.up();
    await t.pump();
    expect(e.single!.size, Vector3(138, 40, 12));
    expect(e.single!.corner(7).distanceTo(part.corner(7)), lessThan(.001));
    e.undo();
    final locked = original.edit({1}, (b) => b.withSizeLock(2, true));
    e.commit(locked);
    await t.pump();
    await mouse.moveTo(at(side));
    await t.pump();
    expect(painter().activeEdge, isNull);
    await mouse.down(at(side));
    await mouse.moveTo(at(side + part.up * 15));
    await mouse.up();
    expect(e.project, same(locked));
    await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await mouse.removePointer();
    await t.pump(kDoubleTapTimeout);
  });

  testWidgets(
    'Ruler previews and attaches both ends on edges and face centerlines',
    (t) async {
      await t.binding.setSurfaceSize(const Size(1360, 840));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final beam = Beam(
        1,
        'Планка',
        Vector3.zero(),
        Vector3(1000, 80, 12),
        axis(0),
        axis(1),
      );
      final editor = Editor(Project('Размеры', [beam]))
        ..setView(ViewAngle.front)
        ..setTool(Tool.measure)
        ..fitRequested = false;
      editor.camera
        ..target = Vector3(500, 0, 6)
        ..scale = 1;
      await t.pumpWidget(NeprostoApp(editor: editor));
      await t.pumpAndSettle();
      final canvas = find.byKey(const Key('drawing'));
      Offset at(double x, double z) =>
          t.getTopLeft(canvas) +
          editor.camera.project(Vector3(x, 0, z), t.getSize(canvas));
      final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: at(340, 18));
      RulerTarget target() =>
          (t.widget<CustomPaint>(canvas).painter! as DrawingPainter)
              .rulerTarget!;
      Future<void> aim(double x, double z) async {
        await mouse.moveTo(at(x, z));
        await t.pump();
      }

      Future<void> click(double x, double z) async {
        await mouse.down(at(x, z));
        await mouse.up();
        await t.pump();
      }

      for (final (z, snapped, label) in [
        (1.0, 0.0, 'Нижнее ребро'),
        (11.0, 12.0, 'Верхнее ребро'),
        (5.0, 6.0, 'Средняя линия грани'),
      ]) {
        await aim(350, z);
        final preview = target();
        expect(preview.face?.face, 2);
        expect(preview.anchor.displayLabel, label);
        expect(preview.anchor.point, Vector3(350, 0, snapped));
        expect(preview.guide!.$1.z, snapped);
        expect(preview.guide!.$2.z, snapped);
      }
      await t.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await t.pump();
      expect(target().guide, isNull);
      expect(target().anchor.point, Vector3(350, 0, 5));
      await t.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await t.pump();
      expect(target().anchor.point.z, 6);
      await click(350, 5);
      await aim(650, 11);
      await click(650, 11);
      final dimension = editor.project.dimensions.single;
      final taller = editor.project.edit({
        1,
      }, (part) => part.copy(size: Vector3(1000, 80, 20)));
      expect(dimension.a.resolve(taller), Vector3(350, 0, 10));
      expect(dimension.b.resolve(taller), Vector3(650, 0, 20));

      await t.tap(find.text('Шаг · 1'));
      await t.pumpAndSettle();
      await t.tap(find.text('Свободно'));
      await t.tap(find.text('Готово'));
      await t.pumpAndSettle();
      expect(editor.snapByDefault, isFalse);
      editor.setTool(Tool.measure);
      await t.pump();
      await aim(450, 5);
      expect(target().anchor.point.z, 5);
      await t.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await t.pump();
      expect(target().anchor.point.z, 6);
      await t.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await mouse.removePointer();
    },
  );

  testWidgets('Movement and ruler invert immediately with either modifier', (
    t,
  ) async {
    await t.binding.setSurfaceSize(const Size(1360, 840));
    addTearDown(() => t.binding.setSurfaceSize(null));
    Beam slat(int id, double y) => Beam(
      id,
      'Планка $id',
      Vector3(0, y, 0),
      Vector3(200, 30, 20),
      axis(0),
      axis(1),
    );
    final p = Project('Тест', [slat(1, 0), slat(2, 38), slat(3, 130)]);
    final e = Editor(p)
      ..setView(ViewAngle.top)
      ..select(3);
    e.fitRequested = false;
    e.camera.scale = 1;
    await t.pumpWidget(NeprostoApp(editor: e));
    await t.pumpAndSettle();
    final drawing = find.byKey(const Key('drawing'));
    Offset at(Vector3 p) =>
        t.getTopLeft(drawing) + e.camera.project(p, t.getSize(drawing));
    for (final sticky in [true, false]) {
      e.snapByDefault = sticky;
      for (final mod in [
        LogicalKeyboardKey.controlLeft,
        LogicalKeyboardKey.metaLeft,
      ]) {
        if (!sticky) await t.sendKeyDownEvent(mod);
        final g = await t.startGesture(
          at(Vector3(60, 145, 20)),
          kind: PointerDeviceKind.mouse,
        );
        await g.moveBy(const Offset(0, 53));
        await t.pump();
        expect(e.single!.origin.y, 76);
        if (sticky) {
          await t.sendKeyDownEvent(mod);
        } else {
          await t.sendKeyUpEvent(mod);
        }
        await t.pump();
        expect(e.single!.origin.y, 77);
        if (sticky) {
          await t.sendKeyUpEvent(mod);
        } else {
          await t.sendKeyDownEvent(mod);
        }
        await t.pump();
        expect(e.single!.origin.y, 76);
        await g.up();
        await g.removePointer();
        if (!sticky) await t.sendKeyUpEvent(mod);
        e.undo();
        await t.pump();
        expect(e.project, same(p));
      }
    }
    await t.tap(find.text('Шаг · 1'));
    await t.pumpAndSettle();
    await t.tap(find.text('С привязкой'));
    await t.tap(find.text('Готово'));
    await t.pumpAndSettle();
    expect(e.snapByDefault, true);
    e.setTool(Tool.measure);
    await t.pump();
    final near = at(Vector3(3, 3, 20));
    final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: near + const Offset(1, 1));
    await mouse.moveTo(near);
    await t.pump();
    expect(e.hover?.beam, 1);
    expect(e.hover!.point.x, closeTo(0, 1e-5));
    await t.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await t.pump();
    expect(e.hover?.beam, 1);
    expect(e.hover!.point.x, closeTo(3, 1e-5));
    await mouse.down(near);
    await mouse.up();
    await t.pump();
    expect(e.first?.beam, 1);
    await t.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    final next = at(Vector3(198, 2, 20));
    await mouse.moveTo(next);
    await mouse.down(next);
    await mouse.up();
    await t.pumpAndSettle();
    final measured = e.project.dimensions.single;
    expect(measured.a.beam, 1);
    expect(measured.b.beam, 1);
    expect(measured.a.resolve(e.project).x, closeTo(3, 1e-5));
    final shifted = e.project.move({1}, axis(0) * 25);
    expect(measured.a.resolve(shifted).x, closeTo(28, 1e-5));
    expect(measured.b.resolve(shifted).x, closeTo(225, 1e-5));
    await mouse.removePointer();
  });

  testWidgets(
    'Empty-space double click leaves the project untouched and the context menu inserts a part in the current projection',
    (t) async {
      await t.binding.setSurfaceSize(const Size(1360, 840));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final e = Editor(Project('Тест', []));
      await t.pumpWidget(NeprostoApp(editor: e));
      await t.pumpAndSettle();
      final drawing = find.byKey(const Key('drawing'));
      final tabs = find.byKey(const ValueKey('view-tabs'));
      for (final v in ViewAngle.values) {
        await t.tap(find.descendant(of: tabs, matching: find.text(v.label)));
        await t.pumpAndSettle();
        expect(e.activeView, v);
      }
      await t.tap(find.text('Спереди'));
      await t.pumpAndSettle();
      final pointer = t.getCenter(drawing) + const Offset(15, 12);
      final origin = e.camera.onPlane(
        pointer - t.getTopLeft(drawing),
        t.getSize(drawing),
        e.plane,
      )!;
      await t.tapAt(pointer);
      await t.pump(const Duration(milliseconds: 90));
      await t.tapAt(pointer);
      await t.pumpAndSettle();
      expect(e.project.beams, isEmpty);
      expect(e.canUndo, isFalse);
      expect(find.byType(DeskDialog), findsNothing);
      final rightClick = await t.startGesture(
        pointer,
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await rightClick.up();
      await t.pumpAndSettle();
      await t.tap(find.text('Новая деталь здесь'));
      await t.pumpAndSettle();
      expect(e.project.beams, hasLength(1));
      expect(e.single!.name, 'Деталь 1');
      expect(
        e.single!.origin.distanceTo(e.plane.quantize(origin, 1)),
        lessThan(1e-6),
      );
      expect(e.single!.size, Vector3(300, 30, 40));
      final part = e.single!;
      final width = find.descendant(
        of: find.byKey(ValueKey('size-${part.id}-1')),
        matching: find.byType(DeskTextField),
      );
      await t.tap(width);
      await t.pump();
      await t.sendKeyEvent(LogicalKeyboardKey.backspace);
      expect(e.project.beams, hasLength(1));
      await t.tap(find.text(part.name).first);
      await t.pumpAndSettle();
      for (final key in [
        LogicalKeyboardKey.backspace,
        LogicalKeyboardKey.delete,
      ]) {
        e.select(part.id);
        await t.pump();
        await t.sendKeyEvent(key);
        await t.pumpAndSettle();
        expect(e.project.beams, isEmpty);
        e.undo();
        await t.pumpAndSettle();
        expect(e.project.beams.single.id, part.id);
      }
      e.camera.scale = 1.7;
      await t.tap(find.text('Перспектива'));
      await t.pumpAndSettle();
      expect(e.camera.perspective, true);
      final size = t.getSize(drawing), at = Vector3(80, 20, 0);
      final screen = e.camera.project(at, size);
      expect(
        e.camera.onPlane(screen, size, WorkPlane.xy())!.distanceTo(at),
        lessThan(1e-6),
      );
      await t.tap(find.text('Спереди'));
      await t.pumpAndSettle();
      expect(e.camera.scale, 1.7);
    },
  );

  testWidgets(
    'Selected assembly dimensions evaluate arithmetic and support undo',
    (t) async {
      await t.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final editor = Editor(Project.bench());
      await t.pumpWidget(NeprostoApp(editor: editor));
      await t.pumpAndSettle();
      expect(find.text('Габариты сборки'), findsNothing);
      editor.selection = editor.project.byId.keys.toSet();
      editor.refresh();
      await t.pumpAndSettle();
      final field = find.descendant(
        of: find.byKey(const ValueKey('extent-0')),
        matching: find.byType(DeskTextField),
      );
      await t.enterText(field, '4*10+12');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pumpAndSettle();
      expect(t.widget<DeskTextField>(field).controller!.text, '52');
      final bounds = Bounds3.points(
        editor.project.beams.expand((b) => b.corners),
      );
      expect(bounds.high.x - bounds.low.x, closeTo(52, .000001));
      editor.undo();
      await t.pumpAndSettle();
      expect(t.widget<DeskTextField>(field).controller!.text, '1200');
      await t.tap(find.text('Планка сиденья 1'));
      await t.pump(kDoubleTapTimeout);
      await t.pumpAndSettle();
      final width = find.descendant(
        of: find.byKey(const ValueKey('size-1-1')),
        matching: find.byType(DeskTextField),
      );
      await t.enterText(width, '(60+20)/2');
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.pumpAndSettle();
      expect(editor.single!.size.y, 40);
      await t.enterText(width, '1/0');
      await t.tapAt(const Offset(10, 4));
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.pumpAndSettle();
      expect(editor.single!.size.y, 40);
    },
  );
  testWidgets('Dial and inspector animate the group around the chosen axis', (
    t,
  ) async {
    await t.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final project = Project.bench().edit({5, 9}, (b) => b.copy(group: 1));
    final editor = Editor(project)
      ..select(9)
      ..setTool(Tool.rotate)
      ..chooseRotationAxis(1);
    await t.pumpWidget(NeprostoApp(editor: editor));
    await t.pumpAndSettle();

    final drawing = find.byKey(const Key('drawing'));
    Project frame() =>
        (t.widget<CustomPaint>(drawing).painter! as DrawingPainter)
            .scene
            .project;
    final pivot = Bounds3.points(editor.selected.expand((b) => b.corners))
        .center;
    final dial = RotationDial.project(
      editor.camera,
      t.getSize(drawing),
      pivot,
      axis(1),
    );
    await t.tapAt(t.getTopLeft(drawing) + dial.arrows.first.label);
    await t.pump();
    await t.pump(const Duration(milliseconds: 130));
    final halfway = project.rotate({5, 9}, axis(1), -45);
    for (final id in [5, 9]) {
      expect(
        frame().byId[id]!.origin.distanceTo(halfway.byId[id]!.origin),
        lessThan(1),
      );
    }
    expect(frame().byId[1], same(project.byId[1]));
    expect(editor.project, same(project));
    expect(editor.angle, 270);

    final midTurn = frame().byId[9]!.origin;
    await t.tap(find.text('+90°'));
    await t.pump();
    expect(frame().byId[9]!.origin.distanceTo(midTurn), lessThan(.001));
    await t.pumpAndSettle();
    expect(frame().byId[9]!.origin, project.byId[9]!.origin);
    expect(editor.canUndo, isFalse);

    await t.tap(find.text('+90°'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 60));
    await t.tap(find.text('Применить'));
    await t.pumpAndSettle();
    final expected = project.rotate({5, 9}, axis(1), 90);
    expect(editor.project.byId[9]!.origin, expected.byId[9]!.origin);
    editor.undo();
    expect(editor.project, same(project));
  });

  testWidgets('Create a beam and preview rotation before applying', (t) async {
    await t.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final editor = Editor(Project('Тест', []));
    await t.pumpWidget(NeprostoApp(editor: editor));
    await t.pumpAndSettle();
    await t.tap(find.text('Новая деталь'));
    await t.pumpAndSettle();
    final center = t.getCenter(find.byKey(const Key('drawing')));
    await t.tapAt(center);
    await t.pump();
    await t.tapAt(center + const Offset(180, -40));
    await t.pumpAndSettle();
    expect(editor.project.beams, hasLength(1));
    final original = editor.single!;
    expect(original.name, 'Деталь 1');
    await t.tap(find.byTooltip('Поворот · R'));
    await t.pumpAndSettle();
    final apply = find.ancestor(
      of: find.text('Применить'),
      matching: find.byType(DeskButton),
    );
    Color buttonFill() => t
        .widget<DeskControl>(
          find.descendant(of: apply, matching: find.byType(DeskControl)),
        )
        .background!;
    final disabled = buttonFill();
    expect(t.widget<DeskButton>(apply).onPressed, isNull);
    expect(disabled.a, 1);
    Rect buttonRect(String label) => t.getRect(
      find.ancestor(of: find.text(label), matching: find.byType(DeskButton)),
    );
    final minus = buttonRect('−90°'), plus = buttonRect('+90°');
    final angle = t.getRect(find.byKey(const Key('angle')));
    expect(t.getCenter(find.text('Угол')).dy, angle.center.dy);
    expect(minus.center.dy, angle.center.dy);
    expect(plus.center.dy, angle.center.dy);
    expect(minus.left - angle.right, greaterThanOrEqualTo(6));
    expect(plus.left - minus.right, greaterThanOrEqualTo(6));
    expect(t.getRect(apply).top - plus.bottom, greaterThanOrEqualTo(6));
    expect(
      buttonRect('Отмена').top - t.getRect(apply).bottom,
      greaterThanOrEqualTo(6),
    );
    await t.tap(find.text('+90°'));
    await t.pumpAndSettle();
    expect(buttonFill(), isNot(disabled));
    expect(editor.single!.along.distanceTo(original.along), 0);
    expect(
      editor.displayed.beams.single.along.distanceTo(original.along),
      greaterThan(1),
    );
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await t.pumpAndSettle();
    expect(editor.tool, Tool.select);
    expect(editor.single!.along.distanceTo(original.along), greaterThan(1));
    editor.undo();
    await t.pumpAndSettle();
    expect(editor.single, original);
  });
  testWidgets(
    'Enter confirms stepped and typed rotations in a narrow inspector',
    (t) async {
      await t.binding.setSurfaceSize(const Size(1000, 800));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final project = Project.bench();
      final editor = Editor(project)
        ..select(1)
        ..setTool(Tool.rotate);
      await t.pumpWidget(NeprostoApp(editor: editor));
      await t.pumpAndSettle();
      final field = find.byKey(const Key('angle'));
      final angleY = t.getCenter(field).dy;
      expect(t.getCenter(find.text('−90°')).dy, angleY);
      expect(t.getCenter(find.text('+90°')).dy, angleY);

      await t.tap(find.text('−90°'));
      await t.pumpAndSettle();
      expect(editor.angle, 270);
      final stepped = editor.displayed.byId[1]!;
      await t.sendKeyEvent(LogicalKeyboardKey.numpadEnter);
      await t.pumpAndSettle();
      expect(editor.tool, Tool.select);
      expect(editor.single!.along, stepped.along);
      editor.undo();
      expect(editor.project, same(project));

      editor.setTool(Tool.rotate);
      await t.pumpAndSettle();
      await t.enterText(field, '30+15');
      await t.pump();
      expect(editor.angle, 45);
      final typed = editor.displayed.byId[1]!;
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pumpAndSettle();
      expect(
        find.descendant(of: field, matching: find.text('45')),
        findsOneWidget,
      );
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.pumpAndSettle();
      expect(editor.tool, Tool.select);
      expect(editor.single!.along, typed.along);
      editor.undo();
      expect(editor.project, same(project));
    },
  );
  testWidgets(
    'Units, settings, typed expressions and arrow increments use the displayed unit',
    (t) async {
      await t.binding.setSurfaceSize(const Size(1280, 820));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final e = Editor(Project.bench())..select(1);
      await t.pumpWidget(NeprostoApp(editor: e));
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('мм'));
      await t.pumpAndSettle();
      await t.tap(find.text('Дюймы'));
      await t.pumpAndSettle();
      expect(e.project.unit, LengthUnit.inch);
      expect(e.single!.size.x, 1200);
      final width = find.descendant(
        of: find.byKey(const ValueKey('size-1-1')),
        matching: find.byType(DeskTextField),
      );
      await t.enterText(width, '1/2');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pumpAndSettle();
      expect(e.single!.size.y, closeTo(12.7, 1e-9));
      expect(t.widget<DeskTextField>(width).controller!.text, '0.5');
      await t.tap(find.text('Шаг · 1/16″'));
      await t.pumpAndSettle();
      final step = find.descendant(
        of: find.byType(DeskDialog),
        matching: find.byType(DeskTextField),
      );
      await t.enterText(step, '0.25');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pumpAndSettle();
      expect(t.widget<DeskTextField>(step).controller!.text, '1/4');
      await t.tap(find.text('Готово'));
      await t.pumpAndSettle();
      expect(e.step.value(LengthUnit.inch), .25);
      await t.ensureVisible(width);
      await t.pumpAndSettle();
      await t.tap(width);
      await t.pump();
      await t.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await t.pumpAndSettle();
      expect(e.single!.size.y, closeTo(19.05, 1e-8));
      await t.tap(find.text('Шаг · 1/4″'));
      await t.pumpAndSettle();
      expect(find.byType(DeskSwitch), findsNothing);
      await t.tap(find.text('Готово'));
      await t.pumpAndSettle();
      expect(e.lengthInput.increment, .25);
    },
  );
  testWidgets('Control and Command both undo, redo and zoom at the pointer', (
    t,
  ) async {
    await t.binding.setSurfaceSize(const Size(1300, 820));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final e = Editor(Project.bench())..select(1);
    await t.pumpWidget(NeprostoApp(editor: e));
    await t.pumpAndSettle();
    final drawing = find.byKey(const Key('drawing')),
        pos = t.getCenter(drawing) + const Offset(44, 13);
    for (final mod in [
      LogicalKeyboardKey.controlLeft,
      LogicalKeyboardKey.metaLeft,
    ]) {
      final previous = e.project;
      await t.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await t.pump();
      final changed = e.project;
      expect(identical(changed, previous), false);
      await t.sendKeyDownEvent(mod);
      await t.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await t.pump();
      expect(e.project, same(previous));
      await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await t.sendKeyEvent(LogicalKeyboardKey.keyZ);
      await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      expect(e.project, same(changed));
      final scale = e.camera.scale;
      final local = pos - t.getTopLeft(drawing),
          size = t.getSize(drawing),
          point = e.camera.rayOrigin(local, size);
      await t.sendEventToBinding(
        PointerScrollEvent(position: pos, scrollDelta: const Offset(0, -30)),
      );
      await t.pump();
      expect(e.camera.scale, greaterThan(scale));
      expect((e.camera.project(point, size) - local).distance, lessThan(1e-6));
      await t.sendKeyUpEvent(mod);
    }
  });

  testWidgets(
    'Opening the dimensions tab shows saved lines for picking and naming',
    (t) async {
      await t.binding.setSurfaceSize(const Size(1260, 800));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final d = Dimension(
        Anchor(Vector3(-90, 0, 0)),
        Anchor(Vector3(90, 0, 0)),
      );
      final p = Project('Чертёж', [], [d]);
      final e = Editor(p)
        ..setView(ViewAngle.top)
        ..dimensionsByDefault = false
        ..fitRequested = false;
      e.camera.scale = 1;
      await t.pumpWidget(NeprostoApp(editor: e));
      await t.pumpAndSettle();
      final drawing = find.byKey(const Key('drawing'));
      DrawingPainter painter() =>
          t.widget<CustomPaint>(drawing).painter! as DrawingPainter;
      final center = t.getCenter(drawing);
      final badge =
          t.getSize(drawing).center(Offset.zero) - const Offset(0, 17);
      expect(painter().dimensionAt(badge), isNull);
      await t.tap(find.text('Размеры  1'));
      await t.pumpAndSettle();
      expect(e.tool, Tool.ruler);
      expect(painter().dimensionAt(badge), same(d));
      expect(painter().selectedDimension, isNull);
      await t.tapAt(center + const Offset(-62, -17));
      await t.pumpAndSettle();
      expect(painter().selectedDimension, same(d));
      final row = find.byKey(ObjectKey(d));
      expect(t.widget<Semantics>(row).properties.selected, isTrue);
      await t.tapAt(center + const Offset(0, 42));
      await t.pump();
      expect(e.selectedDimension, isNull);
      expect(e.project, same(p));
      await t.tap(find.text('Размер 1'));
      await t.pump();
      expect(painter().selectedDimension, same(d));
      await t.tapAt(center + const Offset(0, 42));
      await t.pump();
      expect(e.selectedDimension, isNull);
      final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer();
      addTearDown(mouse.removePointer);
      await mouse.moveTo(t.getCenter(find.text('Размер 1')));
      await t.pumpAndSettle();
      await t.tap(
        find.descendant(
          of: find.byTooltip('Центрировать'),
          matching: find.byIcon(PhosphorIconsRegular.crosshair),
        ),
      );
      await t.pumpAndSettle();
      expect(painter().selectedDimension, same(d));
      expect(e.camera.scale, greaterThan(1));
      expect(e.activeView, ViewAngle.top);
      expect(
        (e.camera.project(d.a.point, t.getSize(drawing)) +
                e.camera.project(d.b.point, t.getSize(drawing))) /
            2,
        t.getSize(drawing).center(Offset.zero),
      );
      final rename = find.byTooltip('Переименовать размер');
      final remove = find.byTooltip('Удалить размер');
      expect(remove, findsOneWidget);
      await t.tap(rename);
      await t.pumpAndSettle();
      final input = find.descendant(
        of: row,
        matching: find.byWidgetPredicate(
          (w) => w is EditableText && w.autofocus,
        ),
      );
      expect(remove, findsNothing);
      await t.enterText(input, 'Черновик');
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
      expect(find.text('Размер 1'), findsOneWidget);
      expect(remove, findsOneWidget);
      await t.tap(rename);
      await t.pumpAndSettle();
      expect(remove, findsNothing);
      await t.enterText(input, '  Глубина сиденья  ');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pumpAndSettle();
      expect(find.text('Глубина сиденья'), findsOneWidget);
      expect(remove, findsOneWidget);
      expect(e.selectedDimension, same(e.project.dimensions.single));
      final restored = Project.decode(e.project.encode()).dimensions.single;
      expect(restored.name, 'Глубина сиденья');
      expect(restored.length(p), d.length(p));
      await t.sendKeyEvent(LogicalKeyboardKey.backspace);
      await t.pumpAndSettle();
      expect(e.project.dimensions, isEmpty);
      e.undo();
      await t.pumpAndSettle();
      expect(find.text('Глубина сиденья'), findsOneWidget);
      e.undo();
      await t.pumpAndSettle();
      expect(find.text('Размер 1'), findsOneWidget);

      await t.sendKeyEvent(LogicalKeyboardKey.keyW);
      await t.pumpAndSettle();
      expect(e.tool, Tool.measure);
      final start = center + const Offset(60, 40);
      await t.tapAt(start);
      await t.pump();
      expect(e.first, isNotNull);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pump();
      expect(e.tool, Tool.ruler);
      expect(e.project, same(p));
      await t.tap(find.text('Новый размер'));
      await t.pumpAndSettle();
      await t.tapAt(start);
      await t.tapAt(start + const Offset(105, 15));
      await t.pumpAndSettle();
      expect(e.project.dimensions, hasLength(2));
      expect(e.tool, Tool.ruler);
      expect(painter().selectedDimension, same(e.project.dimensions.last));
      await t.tap(find.text('Детали  0'));
      await t.pumpAndSettle();
      expect(e.tool, Tool.select);
      expect(painter().dimensionAt(badge), isNull);
    },
  );

  testWidgets(
    'A bound measurement follows both parts until its length is edited',
    (t) async {
      await t.binding.setSurfaceSize(const Size(1260, 800));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final first = Beam(
        1,
        'Полка',
        Vector3(-100, -10, 0),
        Vector3(30, 20, 10),
        axis(0),
        axis(1),
      );
      final second = first.copy(id: 2, origin: Vector3(60, -10, 0));
      final a = Anchor(first.corner(5), 1, 5),
          b = Anchor(second.corner(4), 2, 4);
      final legacy = Project('Тест', [first, second]).toJson()
        ..['dimensions'] = [
          [a.toJson(), b.toJson()],
          [
            Anchor(first.corner(7), 1, 7).toJson(),
            Anchor(second.corner(6), 2, 6).toJson(),
          ],
        ];
      final e = Editor(Project.fromJson(legacy))
        ..setView(ViewAngle.top)
        ..setTool(Tool.ruler)
        ..fitRequested = false;
      e.camera.scale = 1;
      await t.pumpWidget(NeprostoApp(editor: e));
      await t.pumpAndSettle();
      Dimension measured() => e.project.dimensions.first;
      final row = find.byKey(ObjectKey(measured()));
      Finder field() =>
          find.descendant(of: row, matching: find.byType(DeskTextField));
      final drawing = find.byKey(const Key('drawing'));
      PaintPattern markerAt(Vector3 world) {
        final point = e.camera.project(world, t.getSize(drawing));
        return paints..something(
          (method, args) =>
              method == #drawCircle && args[0] == point && args[1] == 5,
        );
      }

      final unlock = find.byTooltip('Разблокировать размер · Размер 1');
      final lock = find.byTooltip('Блокировать размер · Размер 1');
      expect(t.widget<DeskTextField>(field()).enabled, isFalse);
      expect(drawing, paintsExactlyCountTimes(#drawCircle, 0));
      await t.tap(find.text('Размер 2'));
      await t.pumpAndSettle();
      expect(drawing, markerAt(first.corner(7)));
      expect(drawing, isNot(markerAt(a.resolve(e.project))));
      await t.tap(find.text('Размер 1'));
      await t.pumpAndSettle();
      expect(drawing, isNot(markerAt(first.corner(7))));
      expect(drawing, markerAt(a.resolve(e.project)));
      expect(drawing, markerAt(b.resolve(e.project)));
      e.commit(e.project.move({2}, axis(0) * 10));
      await t.pumpAndSettle();
      expect(t.widget<DeskTextField>(field()).controller!.text, '140');
      expect(drawing, markerAt(b.resolve(e.project)));
      await t.tap(unlock);
      await t.pumpAndSettle();
      expect(t.widget<DeskTextField>(field()).enabled, isTrue);
      expect(measured().b.beam, 2);
      final before = e.project;
      await t.enterText(field(), '83');
      await t.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await t.pump();
      await t.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await t.pump();
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pumpAndSettle();
      expect(e.project.beams, orderedEquals(before.beams));
      expect(measured().length(e.project), 85);
      expect(measured().a.beam, 1);
      expect(measured().b.beam, isNull);
      expect(drawing, markerAt(a.resolve(e.project)));
      expect(drawing, isNot(markerAt(measured().b.point)));
      expect(drawing, isNot(markerAt(b.resolve(e.project))));
      await t.tap(lock);
      await t.pumpAndSettle();
      final reopened = Project.decode(e.project.encode());
      expect(reopened.dimensions.first.locked, isTrue);
      expect(
        reopened.dimensions.first.length(reopened.move({2}, axis(0) * 20)),
        85,
      );
      expect(t.widget<DeskTextField>(field()).enabled, isFalse);
      await t.tapAt(t.getCenter(drawing) + const Offset(0, 100));
      await t.pumpAndSettle();
      expect(drawing, paintsExactlyCountTimes(#drawCircle, 0));
      e.undo();
      e.undo();
      e.undo();
      expect(e.project, same(before));
      expect(measured().b.beam, 2);
    },
  );

  testWidgets('The part row selects and centers one member of a group', (
    t,
  ) async {
    await t.binding.setSurfaceSize(const Size(1260, 800));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final project = Project.bench().edit({1, 5}, (b) => b.copy(group: 1));
    final e = Editor(project)..selectAll();
    await t.pumpWidget(NeprostoApp(editor: e));
    await t.pumpAndSettle();
    final part = e.project.byId[5]!;
    final row = find.byKey(ValueKey(part.id));
    final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer();
    addTearDown(mouse.removePointer);
    await mouse.moveTo(t.getCenter(row));
    await t.pumpAndSettle();
    final scale = e.camera.scale;
    expect(
      find.descendant(
        of: row,
        matching: find.byIcon(PhosphorIconsRegular.crosshair),
      ),
      findsNothing,
    );
    await t.tap(row, kind: PointerDeviceKind.mouse);
    await t.pump(kDoubleTapMinTime);
    expect(e.selection, {1, 5});
    expect(e.camera.scale, scale);
    await t.tap(row, kind: PointerDeviceKind.mouse);
    await t.pumpAndSettle();
    expect(e.selection, {part.id});
    expect(find.byType(DeskDialog), findsNothing);
    final size = t.getSize(find.byKey(const Key('drawing')));
    final middle = e.camera.project(part.pointAt(Vector3.all(.5)), size);
    expect((middle - size.center(Offset.zero)).distance, lessThan(.001));
    expect(e.activeView, ViewAngle.iso);
    expect(e.camera.scale, greaterThan(scale));
    expect(e.canUndo, isFalse);
    await t.tap(find.byIcon(Icons.straighten).first);
    await t.pumpAndSettle();
    expect(find.text('Новый размер'), findsOneWidget);
    expect(e.tool, Tool.ruler);
  });

  testWidgets('The ruler keeps all part dimensions visible in both modes', (
    t,
  ) async {
    await t.binding.setSurfaceSize(const Size(1300, 820));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final e = Editor(Project.bench())..select(1);
    await t.pumpWidget(NeprostoApp(editor: e));
    await t.pumpAndSettle();
    final drawing = find.byKey(const Key('drawing'));
    Iterable<StockAxis> labels() =>
        (t.widget<CustomPaint>(drawing).painter! as DrawingPainter)
            .stockLabels
            .keys;
    final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer();
    addTearDown(mouse.removePointer);
    for (final byDefault in [false, true]) {
      e.dimensionsByDefault = byDefault;
      await t.sendKeyEvent(LogicalKeyboardKey.keyD);
      await t.pumpAndSettle();
      expect(labels(), unorderedEquals(StockAxis.values));
      await t.sendKeyDownEvent(LogicalKeyboardKey.tab);
      await t.pump();
      expect(labels(), unorderedEquals(StockAxis.values));
      await t.tap(find.text('Новый размер'));
      await t.pumpAndSettle();
      await t.tap(find.text('Просвет'));
      await t.pumpAndSettle();
      expect(e.tool, Tool.gap);
      expect(labels(), unorderedEquals(StockAxis.values));
      await t.sendKeyUpEvent(LogicalKeyboardKey.tab);
      final width = find.byKey(const ValueKey('size-1-1'));
      await mouse.moveTo(t.getCenter(width));
      await t.pumpAndSettle();
      expect(e.highlightedSize, StockAxis.width.index);
      expect(labels(), unorderedEquals(StockAxis.values));
      await mouse.moveTo(Offset.zero);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
      expect(e.tool, Tool.ruler);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
      expect(labels().isNotEmpty, byDefault);
    }
  });

  testWidgets(
    'W starts a new part and Tab temporarily inverts the configured dimension visibility',
    (t) async {
      await t.binding.setSurfaceSize(const Size(1300, 820));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final e = Editor(Project.bench())..select(1);
      final before = e.project;
      await t.pumpWidget(NeprostoApp(editor: e));
      await t.pumpAndSettle();
      final drawing = find.byKey(const Key('drawing'));
      DrawingPainter painter() =>
          t.widget<CustomPaint>(drawing).painter! as DrawingPainter;
      await t.sendKeyEvent(LogicalKeyboardKey.keyW);
      expect(e.tool, Tool.beam);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
      for (final byDefault in [true, false]) {
        if (!byDefault) {
          await t.tap(find.text('Шаг · 1'));
          await t.pumpAndSettle();
          await t.tap(find.text('Чертёж').last);
          await t.pumpAndSettle();
          await t.tap(find.text('Только с Tab'));
          await t.pumpAndSettle();
          await t.tap(find.text('Готово'));
          await t.pumpAndSettle();
        }
        expect(painter().stockLabels.isNotEmpty, byDefault);
        await t.sendKeyDownEvent(LogicalKeyboardKey.tab);
        await t.pumpAndSettle();
        expect(painter().stockLabels.isNotEmpty, !byDefault);
        await t.sendKeyRepeatEvent(LogicalKeyboardKey.tab);
        await t.pump();
        expect(e.dimensionsVisible, !byDefault);
        await t.sendKeyUpEvent(LogicalKeyboardKey.tab);
        await t.pumpAndSettle();
        expect(painter().stockLabels.isNotEmpty, byDefault);
      }
      expect(e.project, same(before));
      expect(e.canUndo, false);
      final field = find.descendant(
        of: find.byKey(const ValueKey('size-1-0')),
        matching: find.byType(EditableText),
      );
      await t.tap(field);
      await t.pump();
      await t.sendKeyEvent(LogicalKeyboardKey.keyW);
      expect(e.tool, Tool.select);
      await t.sendKeyDownEvent(LogicalKeyboardKey.tab);
      await t.pump();
      expect(e.dimensionTabHeld, false);
      await t.sendKeyUpEvent(LogicalKeyboardKey.tab);
      expect(t.widget<EditableText>(field).focusNode.hasFocus, false);
    },
  );
}
