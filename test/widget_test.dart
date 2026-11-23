import 'package:cupertino_ui/cupertino_ui.dart' as cu;
import 'package:neprosto/editor/desktop.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:neprosto/main.dart';
import 'package:neprosto/editor/controller.dart';
import 'package:neprosto/editor/model.dart';
import 'package:neprosto/editor/scene.dart';
import 'package:neprosto/editor/drawing.dart';
import 'package:neprosto/editor/stock_axis.dart';
import 'package:neprosto/editor/parts_list.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart'
    show PhosphorIconsRegular;

void main() {
  testWidgets('Command double click edits the actual stock label in place', (
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
    final before = e.project;
    for (final (mod, key) in [
      (LogicalKeyboardKey.metaLeft, LogicalKeyboardKey.enter),
      (LogicalKeyboardKey.controlLeft, LogicalKeyboardKey.escape),
    ]) {
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
      final field = find.descendant(
        of: find.byKey(const Key('canvas-size-input')),
        matching: find.byType(cu.CupertinoTextField),
      );
      expect(field, findsOneWidget);
      expect((t.getCenter(field) - pointer).distance, lessThan(1));
      await t.enterText(field, '4*10+12');
      await t.pump();
      if (key == LogicalKeyboardKey.enter) {
        await t.testTextInput.receiveAction(TextInputAction.done);
        await t.pumpAndSettle();
        expect(e.single!.size.z, 52);
        e.undo();
        await t.pumpAndSettle();
      } else {
        await t.sendKeyEvent(key);
        await t.pumpAndSettle();
      }
      expect(field, findsNothing);
      expect(e.project, same(before));
      expect(e.single!.id, 1);
    }
  });

  testWidgets(
    'Parts list groups equal blanks, separates cuts and renames individual parts',
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
      expect(inside('620'), findsOneWidget);
      expect(inside('2'), findsOneWidget);
      await t.tap(inside('Полка'));
      await t.pumpAndSettle();
      await t.tap(inside('Полка 2'));
      await t.pumpAndSettle();
      final rename = find.byType(cu.CupertinoTextFormFieldRow);
      await t.enterText(
        find.descendant(of: rename, matching: find.byType(EditableText)),
        'Верхняя полка',
      );
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pumpAndSettle();
      expect(inside('Верхняя полка'), findsOneWidget);
      final loaded = Project.decode(e.project.encode());
      expect(loaded.byId[2]!.name, 'Верхняя полка');
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
        of: find.byType(cu.CupertinoSearchTextField),
        matching: find.byType(EditableText),
      );
      await t.enterText(search, 'Верхняя');
      await t.pumpAndSettle();
      expect(find.textContaining('Найдено 1 из 3'), findsOneWidget);
      await t.enterText(search, 'Несуществующая');
      await t.pumpAndSettle();
      final exportButton = find.ancestor(
        of: inside('Экспорт в Excel'),
        matching: find.byType(DeskButton),
      );
      expect(t.widget<DeskButton>(exportButton).onPressed, isNull);
    },
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
            .alignmentSupport,
        isNull,
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
      await t.tap(find.text('На чертеже'));
      await t.tap(find.text('Ножка 1').first);
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('align-front')));
      await t.pumpAndSettle();
      await t.tap(find.text('Применить'));
      await t.pumpAndSettle();
      expect(e.project.byId[9]!.origin.y, 25);
      e.undo();
      expect(e.project, same(original));
    },
  );

  testWidgets(
    'The reference and moving part are explicit and offsets are previewed before applying',
    (t) async {
      await t.binding.setSurfaceSize(const Size(1320, 850));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final e = Editor(Project.bench())..select(9);
      await t.pumpWidget(NeprostoApp(editor: e));
      await t.pumpAndSettle();
      final before = e.project;
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
      expect(find.text('Отступ от переднего края опоры'), findsOneWidget);
      expect(e.displayed, same(before));
      expect(e.canUndo, isFalse);
      final field = find.descendant(
        of: find.byKey(const Key('placement-offset')),
        matching: find.byType(cu.CupertinoTextField),
      );
      await t.enterText(field, '-25/2');
      await t.pumpAndSettle();
      expect(e.manualOffset, -12.5);
      expect(e.project, same(before));
      final expected = e.displayed.byId[9]!.origin;
      await t.enterText(field, '8/0');
      await t.pumpAndSettle();
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
      expect(e.suggestedPlacement?.reference.id, 6);
      await t.tap(find.byTooltip('Выбрать перемещаемую деталь'));
      await t.pumpAndSettle();
      await t.tap(find.text('Ножка 1').last);
      await t.pumpAndSettle();
      expect(e.single?.id, 5);
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
      expect(e.selection, {1, 2, 3, 4});
      expect(e.canUndo, false);
      expect(find.text('Сгруппировать'), findsOneWidget);
      await t.tap(find.text('Сгруппировать'));
      await t.pumpAndSettle();
      expect(e.project.assembly(3), {1, 2, 3, 4});
      await rightClick(t.getCenter(find.text('Планка сиденья 2').first));
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
        matching: find.byType(cu.CupertinoTextField),
      );
      await open();
      expect(e.highlightedSize, 0);
      expect(
        t.getRect(find.byType(DeskDialog)).left,
        closeTo(at.dx + 12, .001),
      );
      await t.enterText(input(0), '100+47');
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.pump();
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
      await t.enterText(input(1), '4*10+12');
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
    await t.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await t.pump();
    expect(e.hover?.beam, isNull);
    expect(e.hover!.point.x, closeTo(3, 1e-5));
    await mouse.down(near);
    await mouse.up();
    await t.pump();
    expect(e.first?.beam, isNull);
    await t.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    final next = at(Vector3(198, 2, 20));
    await mouse.moveTo(next);
    await mouse.down(next);
    await mouse.up();
    await t.pumpAndSettle();
    expect(e.project.dimensions.single.a.beam, isNull);
    expect(e.project.dimensions.single.b.beam, 1);
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
        matching: find.byType(cu.CupertinoTextField),
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
    'A drawing dimension evaluates arithmetic on enter and undo restores it',
    (t) async {
      await t.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final editor = Editor(Project.bench());
      await t.pumpWidget(NeprostoApp(editor: editor));
      await t.pumpAndSettle();
      final field = find.descendant(
        of: find.byKey(const ValueKey('extent-0')),
        matching: find.byType(cu.CupertinoTextField),
      );
      await t.enterText(field, '4*10+12');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pumpAndSettle();
      expect(t.widget<cu.CupertinoTextField>(field).controller!.text, '52');
      final bounds = Bounds3.points(
        editor.project.beams.expand((b) => b.corners),
      );
      expect(bounds.high.x - bounds.low.x, closeTo(52, .000001));
      editor.undo();
      await t.pumpAndSettle();
      expect(t.widget<cu.CupertinoTextField>(field).controller!.text, '1200');
      await t.tap(find.text('Планка сиденья 1'));
      await t.pumpAndSettle();
      final width = find.descendant(
        of: find.byKey(const ValueKey('size-1-1')),
        matching: find.byType(cu.CupertinoTextField),
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
    Color buttonFill() =>
        (t
                    .widget<DecoratedBox>(
                      find
                          .descendant(
                            of: apply,
                            matching: find.byType(DecoratedBox),
                          )
                          .first,
                    )
                    .decoration
                as BoxDecoration)
            .color!;
    final disabled = buttonFill();
    expect(disabled.r, disabled.g);
    expect(disabled.g, disabled.b);
    await t.tap(find.text('+90°'));
    await t.pumpAndSettle();
    expect(buttonFill(), isNot(disabled));
    expect(editor.single!.along.distanceTo(original.along), 0);
    expect(
      editor.displayed.beams.single.along.distanceTo(original.along),
      greaterThan(1),
    );
    await t.tap(find.text('Применить'));
    await t.pumpAndSettle();
    expect(editor.single!.along.distanceTo(original.along), greaterThan(1));
    editor.undo();
    await t.pumpAndSettle();
    expect(editor.single, original);
  });
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
        matching: find.byType(cu.CupertinoTextField),
      );
      await t.enterText(width, '1/2');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pumpAndSettle();
      expect(e.single!.size.y, closeTo(12.7, 1e-9));
      expect(t.widget<cu.CupertinoTextField>(width).controller!.text, '0.5');
      await t.tap(find.text('Шаг · 0.0625'));
      await t.pumpAndSettle();
      final step = find.descendant(
        of: find.byType(DeskDialog),
        matching: find.byType(cu.CupertinoTextField),
      );
      await t.enterText(step, '1/4');
      await t.tap(find.text('Готово'));
      await t.pumpAndSettle();
      expect(e.step.value(LengthUnit.inch), .25);
      await t.tap(width);
      await t.pump();
      await t.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await t.pumpAndSettle();
      expect(e.single!.size.y, closeTo(19.05, 1e-8));
      await t.tap(find.text('Шаг · 0.25'));
      await t.pumpAndSettle();
      await t.tap(find.byType(cu.CupertinoSwitch).last);
      await t.pumpAndSettle();
      await t.tap(find.text('Готово'));
      await t.pumpAndSettle();
      expect(e.step.enabled, false);
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
    'Q starts a new part and Tab temporarily inverts the configured dimension visibility',
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
      await t.sendKeyEvent(LogicalKeyboardKey.keyQ);
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
      await t.sendKeyEvent(LogicalKeyboardKey.keyQ);
      expect(e.tool, Tool.select);
      await t.sendKeyDownEvent(LogicalKeyboardKey.tab);
      await t.pump();
      expect(e.dimensionTabHeld, false);
      await t.sendKeyUpEvent(LogicalKeyboardKey.tab);
      expect(t.widget<EditableText>(field).focusNode.hasFocus, false);
    },
  );
}
