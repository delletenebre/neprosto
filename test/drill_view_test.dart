import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:neprosto/editor/controller.dart';
import 'package:neprosto/editor/drawing.dart';
import 'package:neprosto/editor/scene.dart';
import 'package:neprosto/editor/hole_dialog.dart';
import 'package:neprosto/editor/model.dart';
import 'package:neprosto/editor/part_finish.dart';
import 'package:neprosto/main.dart';

final canvas = find.byKey(const ValueKey('drill-canvas'));
final zero = find.byKey(const ValueKey('drill-zero-point'));

extension on WidgetTester {
  Future<Editor> openPart(Beam part) async {
    final editor = Editor(Project('', [part]));
    await binding.setSurfaceSize(const Size(1100, 800));
    addTearDown(() => binding.setSurfaceSize(null));
    await pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () =>
                showPanelHoles(context, editor, editor.project.beams.single),
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tapSettled(find.text('Open'));
    return editor;
  }

  Future<void> tapSettled(Finder finder) async {
    await ensureVisible(finder);
    await tap(finder);
    await pumpAndSettle();
  }

  DrawingPainter get drawing => widgetList<CustomPaint>(
    find.descendant(of: canvas, matching: find.byType(CustomPaint)),
  ).map((p) => p.painter).whereType<DrawingPainter>().single;

  Offset screen(double x, double y, double z) {
    final scene = drawing.scene;
    final b = scene.project.beams.single;
    final p = b.origin + b.along * x + b.across * y + b.up * z;
    return getTopLeft(canvas) + scene.camera.project(p, scene.size);
  }

  Future<void> wheel(
    Offset position,
    Offset delta, [
    LogicalKeyboardKey? modifier,
  ]) async {
    if (modifier != null) await sendKeyDownEvent(modifier);
    await sendEventToBinding(
      PointerScrollEvent(position: position, scrollDelta: delta),
    );
    await pump();
    if (modifier != null) await sendKeyUpEvent(modifier);
  }

  Future<void> side(String label) async {
    await tapSettled(find.byTooltip(label));
  }

  Future<void> history({bool redo = false}) async {
    await sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    if (redo) await sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await sendKeyEvent(LogicalKeyboardKey.keyZ);
    if (redo) await sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await pumpAndSettle();
  }
}

void main() {
  final panel = Beam(
    1,
    'ЛДСП',
    Vector3.zero(),
    Vector3(400, 200, 18),
    axis(0),
    axis(1),
    finish: FinishPreset.whiteBoard.finish,
  );
  testWidgets(
    'Native Mac undo targets the hole dialog, then the project after Apply',
    (t) async {
      final editor = Editor(Project('Test', []));
      final initial = Project('Test', [panel]);
      editor.commit(initial);
      await t.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => t.binding.setSurfaceSize(null));
      await t.pumpWidget(NeprostoApp(editor: editor));
      await t.pumpAndSettle();
      showPanelHoles(
        t.element(find.byKey(const Key('drawing'))),
        editor,
        panel,
      );
      await t.pumpAndSettle();
      Future<void> native(String action) async {
        const menu = MethodChannel('neprosto/editor');
        await t.binding.defaultBinaryMessenger.handlePlatformMessage(
          menu.name,
          menu.codec.encodeMethodCall(MethodCall(action)),
          null,
        );
        await t.pumpAndSettle();
      }

      await native('undo');
      expect(editor.project, same(initial));
      await t.tapSettled(find.text('Добавить отверстие'));
      await native('undo');
      expect(find.text('Отверстия (0)'), findsOneWidget);
      await native('redo');
      expect(find.text('Отверстия (1)'), findsOneWidget);
      final x = find.descendant(
        of: find.byKey(const ValueKey('hole-horizontal')),
        matching: find.byType(EditableText),
      );
      final original = t.widget<EditableText>(x).controller.text;
      await t.tap(x);
      await t.pump(const Duration(milliseconds: 600));
      await t.enterText(x, '1');
      await t.enterText(x, '125');
      await t.pump(const Duration(milliseconds: 600));
      await native('undo');
      expect(t.widget<EditableText>(x).controller.text, isNot('125'));
      expect(find.text('Отверстия (1)'), findsOneWidget);
      await native('redo');
      expect(t.widget<EditableText>(x).controller.text, '125');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pumpAndSettle();
      await native('undo');
      expect(t.widget<EditableText>(x).controller.text, original);
      await native('redo');
      expect(t.widget<EditableText>(x).controller.text, '125');
      await t.tapSettled(find.text('Применить'));
      expect(editor.project.beams.single.holes.single.x, 125);
      await native('undo');
      expect(editor.project, same(initial));
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets(
    'Spatial bores, datum and linked shaft share undo history across views',
    (t) async {
      final editor = await t.openPart(panel);
      await t.tapSettled(find.text('3D'));
      await t.side('Сверху');
      await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await t.tapAt(t.screen(200, 100, 18));
      await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await t.pumpAndSettle();
      final datum = t.getCenter(zero);
      await t.tapAt(t.screen(232, 100, 18));
      await t.pumpAndSettle();
      expect(t.drawing.scene.project.beams.single.holes, hasLength(1));
      await t.side('Спереди');
      await t.tapAt(t.screen(70, 0, 9));
      await t.pumpAndSettle();
      expect(t.drawing.scene.project.beams.single.edgeHoles, hasLength(1));
      await t.tapSettled(find.text('2D'));
      await t.history();
      expect(find.text('Отверстия (1)'), findsOneWidget);
      await t.history();
      expect(find.text('Отверстия (0)'), findsOneWidget);
      await t.tapSettled(find.text('3D'));
      await t.side('Сверху');
      await t.history();
      expect((t.getCenter(zero) - datum).distance, greaterThan(10));
      await t.history(redo: true);
      expect((t.getCenter(zero) - datum).distance, lessThan(1));
      await t.history(redo: true);
      await t.tapSettled(find.text('2D'));
      await t.tapSettled(find.byKey(const ValueKey('face-linked-shaft')));
      expect(find.byKey(const ValueKey('hole-row-shaft-0')), findsOneWidget);
      await t.history(redo: true);
      expect(find.text('Отверстия (2)'), findsOneWidget);
      await t.history();
      expect(find.byKey(const ValueKey('hole-row-shaft-0')), findsNothing);
      await t.history(redo: true);
      await t.tapSettled(find.byKey(const ValueKey('hole-row-face-0')));
      await t.tapSettled(find.byTooltip('Удалить'));
      expect(find.text('Отверстия (0)'), findsOneWidget);
      await t.history();
      expect(find.text('Отверстия (2)'), findsOneWidget);
      await t.tapSettled(find.text('Применить'));
      expect(editor.project.beams.single.holes.single.boltBore, isNotNull);
      expect(editor.project.beams.single.edgeHoles, isEmpty);
    },
  );
  testWidgets(
    'Rotation planes slide out of the same stationary toggle and reverse on R',
    (t) async {
      await t.openPart(panel);
      await t.tapSettled(find.text('3D'));
      final button = find.byKey(const ValueKey('drill-rotation'));
      final closeIcon = find.descendant(
        of: button,
        matching: find.byIcon(Icons.close),
      );
      final morph = find.descendant(
        of: button,
        matching: find.byKey(const ValueKey('rotation-glyph-transition')),
      );
      final initialIcon = t
          .widget<Icon>(
            find.descendant(of: button, matching: find.byType(Icon)),
          )
          .icon!;
      final xy = find.text('XY'), xz = find.text('XZ'), yz = find.text('YZ');
      for (final width in [1100.0, 620.0, 400.0]) {
        await t.binding.setSurfaceSize(Size(width, 800));
        await t.pumpAndSettle();
        await t.ensureVisible(button);
        await t.pumpAndSettle();
        final anchor = t.getCenter(button);
        final hiddenX = t.getCenter(yz).dx;
        expect(yz.hitTestable(), findsNothing);
        await t.tap(button);
        await t.pump();
        await t.pump(const Duration(milliseconds: 105));
        final openingX = t.getCenter(yz).dx;
        expect(closeIcon, findsNothing);
        final openingGlyph = t.widget<CustomPaint>(morph).painter!;
        expect(
          find.descendant(of: button, matching: find.byTooltip('Закрыть')),
          findsOneWidget,
        );
        expect(openingX, greaterThan(hiddenX));
        expect(t.getCenter(button), anchor);
        await t.sendKeyEvent(LogicalKeyboardKey.keyR);
        await t.pump();
        expect(
          t.widget<CustomPaint>(morph).painter!.shouldRepaint(openingGlyph),
          isFalse,
        );
        await t.pump(const Duration(milliseconds: 75));
        expect(
          t.widget<CustomPaint>(morph).painter!.shouldRepaint(openingGlyph),
          isTrue,
        );
        expect(closeIcon, findsNothing);
        expect(t.getCenter(yz).dx, lessThan(openingX));
        await t.sendKeyEvent(LogicalKeyboardKey.keyR);
        await t.pumpAndSettle();
        expect(t.getCenter(button), anchor);
        expect(t.getCenter(yz).dx, greaterThan(openingX));
        expect(closeIcon, findsOneWidget);
        expect(morph, findsNothing);
        for (final (plane, index) in [(xy, 2), (xz, 1), (yz, 0)]) {
          expect(plane.hitTestable(), findsOneWidget);
          expect(t.getCenter(plane).dy, closeTo(anchor.dy, 2));
          expect(t.getCenter(plane).dx, greaterThan(anchor.dx));
          await t.tap(plane);
          await t.pumpAndSettle();
          expect(t.drawing.rotationAxis, index);
        }
        await t.tap(button);
        await t.pumpAndSettle();
        expect(t.getCenter(button), anchor);
        expect(t.getCenter(yz).dx, closeTo(hiddenX, .01));
        expect(
          find.descendant(of: button, matching: find.byIcon(initialIcon)),
          findsOneWidget,
        );
        expect(xy.hitTestable(), findsNothing);
        expect(morph, findsNothing);
        expect(t.takeException(), isNull);
      }
      t.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
      await t.pumpAndSettle();
      await t.sendKeyEvent(LogicalKeyboardKey.keyR);
      await t.pump();
      expect(xy.hitTestable(), findsOneWidget);
      expect(closeIcon, findsOneWidget);
      expect(morph, findsNothing);
      await t.sendKeyEvent(LogicalKeyboardKey.keyR);
      await t.pump();
      expect(yz.hitTestable(), findsNothing);
    },
    variant: TargetPlatformVariant({
      TargetPlatform.macOS,
      TargetPlatform.windows,
    }),
  );

  testWidgets('The separate 3D view buttons animate between panel edges', (
    t,
  ) async {
    await t.openPart(panel);
    await t.tapSettled(find.text('3D'));
    await t.tap(find.byKey(const ValueKey(ViewAngle.front)));
    await t.pump();
    final start = t.drawing.scene.camera.eye;
    await t.pump(const Duration(milliseconds: 200));
    final middle = t.drawing.scene.camera.eye;
    await t.pumpAndSettle();
    final end = t.drawing.scene.camera.eye;
    expect(start.distanceTo(middle), greaterThan(.05));
    expect(end.distanceTo(middle), greaterThan(.05));
    expect(t.drawing.scene.faces.single.face, PanelEdge.near.faceIndex);
    await t.tapSettled(find.byKey(const ValueKey(ViewAngle.right)));
    expect(t.drawing.activeFace?.face, PanelEdge.end.faceIndex);
    expect(t.drawing.scene.camera.eye.distanceTo(end), greaterThan(.3));
  });

  testWidgets(
    'Picking a timber side, shifting the datum and placing a sensor uses real millimetres',
    (t) async {
      final beam = Beam(
        1,
        'Брусок',
        Vector3(20, 40, 60),
        Vector3(400, 40, 40),
        axis(0),
        axis(2),
      );
      final editor = await t.openPart(beam);
      // The installed lower face is the long stock edge at y = 0.
      await t.tapSettled(find.text('3D'));
      await t.side('Снизу');
      expect(t.drawing.scene.faces.single.face, PanelEdge.near.faceIndex);
      final mid = t.screen(200, 0, 20);
      await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await t.tapAt(mid + const Offset(1, 0));
      await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await t.pump();
      expect(t.drawing.scene.project.beams.single.edgeHoles, isEmpty);
      expect((t.getCenter(zero) - mid).distance, lessThan(.1));
      final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer();
      addTearDown(mouse.removePointer);
      final badge = find.byKey(const ValueKey('drill-datum'));
      expect(badge, findsNothing);
      await mouse.moveTo(t.getCenter(zero));
      await t.pump();
      expect(badge, findsOneWidget);
      expect(find.byKey(const ValueKey('drill-distance')), findsNothing);
      await mouse.moveTo(t.screen(232.7, 0, 20));
      await t.pump();
      expect(badge, findsNothing);
      expect(find.textContaining('Δ 32 мм'), findsOneWidget);
      await t.tapAt(t.screen(232.7, 0, 20));
      await t.pump();
      await mouse.moveTo(t.screen(264.4, 0, 20));
      await t.pump();
      expect(find.textContaining('Δ 64 мм'), findsOneWidget);
      await t.tapAt(t.screen(264.4, 0, 20));
      await t.pump();
      await t.tapAt(t.screen(264.4, 0, 20));
      await t.pump();
      expect(t.drawing.scene.project.beams.single.edgeHoles.length, 2);
      await mouse.moveTo(t.getCenter(zero));
      await t.pump();
      await mouse.down(t.getCenter(zero));
      await mouse.up();
      await t.pumpAndSettle();
      expect(editor.project.beams.single, same(beam));
      await t.tapSettled(find.text('Применить'));
      final saved = editor.project.beams.single;
      expect(saved.edgeHoles.map((h) => h.offset), [232, 264, 200]);
      expect(
        saved.edgeHoles.every(
          (h) =>
              h.kind == EdgeHoleKind.openingSensor &&
              h.edge == PanelEdge.near &&
              h.height == 20 &&
              h.diameter == 10 &&
              h.datum == (u: 200.0, v: 20.0),
        ),
        isTrue,
      );
      expect(Beam.fromJson(saved.toJson()).edgeHoles, saved.edgeHoles);
      await t.tapSettled(find.text('Open'));
      await t.tapSettled(find.byKey(const ValueKey('hole-row-edge-0')));
      await t.tapSettled(find.text('Правка'));
      expect(find.text('Δ 32 / 0 мм'), findsOneWidget);
    },
  );

  testWidgets(
    'Face views flip independently of the drilling side and share pan and zoom',
    (t) async {
      final part = panel.copy(
        holes: const [PanelHole(60, 40, 10, depth: 12, datum: (u: 40, v: 30))],
      );
      final editor = await t.openPart(part);
      final diagram = find.byKey(const ValueKey('hole-diagram'));
      final faceA = find.byKey(const ValueKey('hole-view-a'));
      final faceB = find.byKey(const ValueKey('hole-view-b'));
      final label = find.byKey(const ValueKey('hole-number-1'));
      expect(label, findsOneWidget);
      expect(zero, findsNothing);
      final ink = find.descendant(
        of: diagram,
        matching: find.byType(CustomPaint),
      );
      expect(t.widget<CustomPaint>(ink).foregroundPainter, isNull);
      await t.tapSettled(find.byTooltip('Показать размеры'));
      expect(t.widget<CustomPaint>(ink).foregroundPainter, isNotNull);
      expect(zero, findsNothing);
      await t.tapSettled(find.byTooltip('Скрыть размеры'));
      final original = t.getCenter(label);
      final focus = t.getCenter(diagram);
      await t.wheel(focus, const Offset(0, -90), LogicalKeyboardKey.metaLeft);
      expect(
        (t.getCenter(label) - focus).distance,
        greaterThan((original - focus).distance),
      );
      final zoomed = t.getCenter(label);
      await t.wheel(focus, const Offset(7, 12));
      expect(
        (t.getCenter(label) - zoomed - const Offset(-7, -12)).distance,
        lessThan(.01),
      );
      await t.tapSettled(find.byTooltip('Вписать в окно'));
      expect((t.getCenter(label) - original).distance, lessThan(.01));
      await t.tap(faceB);
      await t.pump();
      await t.pump(const Duration(milliseconds: 95));
      expect(t.hasRunningAnimations, isTrue);
      expect(label, findsNothing);
      await t.tap(faceA);
      await t.pumpAndSettle();
      expect(label, findsOneWidget);
      await t.tapSettled(faceB);
      expect(label, findsNothing);
      expect(canvas, findsNothing);
      await t.tapSettled(find.text('Применить'));
      expect(editor.project.beams.single, same(part));
    },
  );

  testWidgets(
    'Picking a drawing edge measures from the visible side of either face',
    (t) async {
      final door = Beam(
        1,
        'Дверца',
        Vector3.zero(),
        Vector3(716, 396, 18),
        axis(2),
        axis(0),
        holes: const [PanelHole(90, 22, 35)],
      );
      final editor = await t.openPart(door);
      Finder field(String name) => find.descendant(
        of: find.byKey(ValueKey('hole-$name')),
        matching: find.byType(EditableText),
      );
      String value(String name) =>
          t.widget<EditableText>(field(name)).controller.text;
      Future<void> choose(String side) =>
          t.tapSettled(find.byKey(ValueKey('hole-reference-$side')));
      for (final (side, center) in [
        ('left', '22'),
        ('right', '374'),
        ('top', '626'),
        ('bottom', '90'),
      ]) {
        await choose(side);
        expect(value('center'), center);
      }
      await choose('left');
      await t.tapSettled(find.byKey(const ValueKey('hole-view-b')));
      expect(value('center'), '22');
      await choose('left');
      expect(value('center'), '374');
      await t.enterText(field('rim'), '8.5');
      await t.pump();
      expect(value('center'), '26');
      await t.tapSettled(find.text('Применить'));
      final hole = editor.project.beams.single.holes.single;
      expect(hole.boringEdge, PanelEdge.far);
      expect((hole.centerX(door.size), hole.centerY(door.size)), (90, 370));
    },
  );

  testWidgets(
    'Right drag orbits at the picked point; wheel pans and modifier-wheel zooms there',
    (t) async {
      await t.openPart(panel);
      await t.tapSettled(find.text('3D'));
      await t.side('Сверху');
      final anchor = t.screen(130, 90, 18);
      final initial = t.drawing.scene.camera;
      final primary = await t.startGesture(
        anchor,
        kind: PointerDeviceKind.mouse,
      );
      await primary.moveBy(const Offset(72, -36));
      await primary.up();
      await t.pumpAndSettle();
      expect(t.drawing.scene.camera.eye, initial.eye);
      expect(t.drawing.scene.project.beams.single.holes, isEmpty);
      final right = await t.startGesture(
        anchor,
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await right.moveBy(const Offset(72, -36));
      await right.up();
      await t.pumpAndSettle();
      expect(
        t.drawing.scene.camera.eye.distanceTo(initial.eye),
        greaterThan(.1),
      );
      expect((t.screen(130, 90, 18) - anchor).distance, lessThan(.01));
      final scale = t.drawing.scene.camera.scale;
      await t.wheel(anchor, const Offset(0, -90), LogicalKeyboardKey.metaLeft);
      expect(t.drawing.scene.camera.scale, closeTo(scale * 1.3703, .001));
      expect((t.screen(130, 90, 18) - anchor).distance, lessThan(.01));
      final zoomed = t.drawing.scene.camera.scale;
      await t.wheel(anchor, const Offset(11, 17));
      expect(t.drawing.scene.camera.scale, zoomed);
      expect(
        (t.screen(130, 90, 18) - anchor + const Offset(11, 17)).distance,
        lessThan(.01),
      );
      expect(t.drawing.scene.project.beams.single.holes, isEmpty);
    },
  );

  testWidgets(
    'The drilling bench turns the stock on its side around a pinned point and drills the new top',
    (t) async {
      final editor = await t.openPart(panel);
      await t.tapSettled(find.text('3D'));
      await t.side('Сверху');
      final pin = t.screen(130, 90, 18);
      await t.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await t.tapAt(pin);
      await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await t.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await t.pumpAndSettle();
      final initial = t.drawing.scene.camera.eye;
      await t.sendKeyEvent(LogicalKeyboardKey.keyR);
      await t.pumpAndSettle();
      await t.sendKeyEvent(LogicalKeyboardKey.keyX);
      await t.pumpAndSettle();
      final pinnedBeforeTurn = t.screen(130, 90, 18);
      final dial = RotationDial.project(
        t.drawing.scene.camera,
        t.drawing.scene.size,
        Vector3(130, 90, 18),
        axis(0),
      );
      await t.tapAt(t.getTopLeft(canvas) + dial.arrows.last.label);
      await t.pumpAndSettle();
      final part = t.drawing.scene.project.beams.single;
      expect(part.up.dot(-axis(1)), closeTo(1, .00001));
      expect(part.across.dot(axis(2)), closeTo(1, .00001));
      expect(t.drawing.scene.camera.eye, initial);
      expect(
        (t.screen(130, 90, 18) - pinnedBeforeTurn).distance,
        lessThan(.05),
      );
      await t.sendKeyEvent(LogicalKeyboardKey.keyR);
      await t.pumpAndSettle();
      await t.side('Сверху');
      await t.tapAt(t.screen(100, 200, 9));
      await t.pumpAndSettle();
      final edge = t.drawing.scene.project.beams.single.edgeHoles.single;
      expect(edge.edge, PanelEdge.far);
      await t.tapSettled(find.text('2D'));
      await t.tapSettled(find.text('3D'));
      expect(
        t.drawing.scene.project.beams.single.up.dot(-axis(1)),
        closeTo(1, .00001),
      );
      await t.tapSettled(find.text('Применить'));
      expect(editor.project.beams.single.edgeHoles.single, edge);
      expect(editor.project.beams.single.along, panel.along);
      expect(editor.project.beams.single.across, panel.across);
    },
  );

  testWidgets(
    'The edge context menu lays the picked face down and keeps drill coordinates',
    (t) async {
      final editor = await t.openPart(panel);
      await t.tapSettled(find.text('3D'));
      await t.side('Спереди');
      await t.tapAt(t.screen(200, 0, 9), buttons: kSecondaryMouseButton);
      await t.pumpAndSettle();
      await t.tapSettled(find.text('Положить этой гранью вниз'));
      final part = t.drawing.scene.project.beams.single;
      expect(
        part.faceNormal(PanelEdge.near.faceIndex).dot(-axis(2)),
        closeTo(1, .00001),
      );
      expect(part.holes, isEmpty);
      await t.history();
      expect(t.drawing.scene.project.beams.single.up, panel.up);
      await t.history(redo: true);
      expect(t.drawing.scene.project.beams.single.up, part.up);
      await t.tapSettled(find.text('Отмена'));
      expect(editor.project.beams.single, same(panel));
    },
  );

  testWidgets(
    'Dragging on a flipped upright panel snaps each axis in stock coordinates',
    (t) async {
      final board = Beam(
        1,
        'Дверца',
        Vector3.zero(),
        Vector3(316, 200, 18),
        axis(2),
        axis(0),
        holes: const [PanelHole(112, 106, 12), PanelHole(70, 50, 6)],
      );
      final editor = await t.openPart(board);
      await t.tapSettled(find.byKey(const ValueKey('hole-view-b')));
      final diagram = find.byKey(const ValueKey('hole-diagram'));
      Finder label(int n) => find.byKey(ValueKey('hole-number-$n'));
      await t.wheel(
        t.getCenter(diagram),
        const Offset(0, -40),
        LogicalKeyboardKey.metaLeft,
      );
      final scale = (t.getCenter(label(2)).dy - t.getCenter(label(1)).dy) / 42;
      final middle = t.getCenter(diagram);
      Offset screen(double x, double y) =>
          middle + Offset((100 - y) * scale, (158 - x) * scale);
      Future<void> move(Offset from, Offset to, {required bool snaps}) async {
        final g = await t.startGesture(from, kind: PointerDeviceKind.mouse);
        await g.moveBy(Offset(0, -12));
        await t.pump();
        await g.moveTo(to);
        await t.pump();
        for (final axis in ['v', 'h']) {
          expect(
            find.byKey(ValueKey('snap-guide-$axis')),
            snaps ? findsOneWidget : findsNothing,
          );
        }
        await g.up();
        await t.pumpAndSettle();
        expect(find.byKey(const ValueKey('snap-guide-v')), findsNothing);
      }

      Future<void> check(String h, String v) async {
        for (final (key, value) in [('horizontal', h), ('vertical', v)]) {
          final field = find.descendant(
            of: find.byKey(ValueKey('hole-$key')),
            matching: find.byType(EditableText),
          );
          expect(t.widget<EditableText>(field).controller.text, value);
        }
      }

      await move(screen(112, 106), screen(72, 151), snaps: true);
      await check('150', '70');
      await t.history();
      await check('106', '112');
      await t.history(redo: true);
      await check('150', '70');
      // Preserve clearance to the rim with different bit diameters.
      await move(screen(70, 150), screen(72, 146.5), snaps: true);
      await check('147', '70');
      await move(screen(70, 147), screen(156, 102), snaps: true);
      await check('100', '158');
      await t.tapSettled(find.byKey(const ValueKey('face-magnet')));
      await move(screen(158, 100), screen(72, 148), snaps: false);
      await t.tapSettled(find.text('Применить'));
      final h = editor.project.beams.single.holes.first;
      expect((h.x, h.y), (72, 148));
    },
  );

  testWidgets(
    'Manual groups and live hole anchors persist and update after deletion',
    (t) async {
      final part = panel.copy(
        holes: const [
          PanelHole(60, 40, 8),
          PanelHole(115, 80, 8),
          PanelHole(180, 120, 8),
        ],
      );
      final editor = await t.openPart(part);
      Finder key(String v) => find.byKey(ValueKey(v));
      Future<void> pick(int i) => t.tapSettled(key('hole-number-$i'));
      Future<void> anchor(int i) async {
        await t.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
        await pick(i);
        await t.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      }

      await pick(3);
      await anchor(2);
      await pick(2);
      await anchor(1);
      await pick(1);
      await anchor(3); // Reject a dependency cycle.
      await t.enterText(
        find.descendant(
          of: key('hole-horizontal'),
          matching: find.byType(EditableText),
        ),
        '70',
      );
      await t.pumpAndSettle();
      await t.tapSettled(key('hole-row-face-1'));
      await t.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await t.tapSettled(key('hole-row-face-2'));
      await t.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      final native = defaultTargetPlatform == TargetPlatform.macOS;
      if (native) {
        const channel = MethodChannel('neprosto/popup');
        final messenger = t.binding.defaultBinaryMessenger;
        messenger.setMockMethodCallHandler(channel, (call) async {
          final items = call.arguments['items'] as List;
          expect(items, contains('Сгруппировать'));
          return items.indexOf('Сгруппировать');
        });
        addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      }
      await t.tap(key('hole-row-face-2'), buttons: kSecondaryMouseButton);
      await t.pumpAndSettle();
      if (!native) await t.tapSettled(find.text('Сгруппировать'));
      final groupLabels = find.text('Группа 1');
      expect(groupLabels, findsNWidgets(2));
      await t.history();
      expect(groupLabels, findsNothing);
      await t.history(redo: true);
      expect(groupLabels, findsNWidgets(2));
      await t.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await t.sendKeyEvent(LogicalKeyboardKey.keyG);
      await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await t.pumpAndSettle();
      expect(groupLabels, findsNothing);
      await t.sendKeyEvent(LogicalKeyboardKey.keyG);
      await t.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await t.pumpAndSettle();
      expect(groupLabels, findsNWidgets(2));
      await t.tapSettled(find.text('Применить'));
      final saved = editor.project.beams.single;
      expect(saved.holes.map((h) => h.x), [70, 125, 190]);
      expect(saved.holes.map((h) => h.anchorFace), [null, 0, 1]);
      expect(saved.holes.last.datum, (u: 125.0, v: 80.0));
      final stored = Beam.fromJson(saved.toJson());
      expect(stored.holes, saved.holes);
      expect(stored.drillGroups.members, {
        (HoleKind.face, 1): 1,
        (HoleKind.face, 2): 1,
      });
      await t.tapSettled(find.text('Open'));
      await t.tapSettled(find.byTooltip('Удалить'));
      await t.tapSettled(find.text('Применить'));
      final after = editor.project.beams.single;
      expect(after.holes.map((h) => h.anchorFace), [null, 0]);
      expect(after.drillGroups.members, {
        (HoleKind.face, 0): 1,
        (HoleKind.face, 1): 1,
      });
      editor.undo();
      expect(editor.project.beams.single, same(saved));
    },
    variant: TargetPlatformVariant({
      TargetPlatform.macOS,
      TargetPlatform.windows,
    }),
  );

  testWidgets(
    'Spatial drilling starts with the configured ruler and normalizes through depths on blur',
    (t) async {
      final editor = await t.openPart(panel);
      editor.connectionRuler = const ConnectionRuler(first: 24, pitch: 12);
      await t.tapSettled(find.text('3D'));
      await t.side('Сверху');
      expect(find.text('24 + 12 мм'), findsOneWidget);
      Finder field(String key) => find.descendant(
        of: find.byKey(ValueKey(key)),
        matching: find.byType(EditableText),
      );
      final depth = field('drill-depth');
      for (final value in ['0', '18', '30', '-1', '2+']) {
        await t.enterText(depth, value);
        await t.tapSettled(field('drill-diameter'));
        expect(t.widget<EditableText>(depth).controller.text, isEmpty);
      }
      await t.tapAt(t.screen(25, 38, 18));
      await t.pumpAndSettle();
      final hole = t.drawing.scene.project.beams.single.holes.single;
      expect((hole.x, hole.y, hole.depth), (24, 36, null));
    },
  );

  testWidgets(
    'Face drilling uses the 37+32 grid, editable pitch, free placement and shared cancel',
    (t) async {
      final editor = await t.openPart(panel);
      await t.tapSettled(find.text('3D'));
      await t.side('Сверху');
      expect(t.drawing.scene.faces.single.face, 5);
      await t.tapAt(t.screen(39, 68, 18));
      await t.pump();
      var h = t.drawing.scene.project.beams.single.holes.single;
      expect((h.x, h.y, h.diameter, h.depth, h.back), (37, 69, 10, 12, true));
      await t.tapSettled(find.byKey(const ValueKey('drill-ruler')));
      final pitch = find.descendant(
        of: find.byKey(const ValueKey('drill-pitch')),
        matching: find.byType(EditableText),
      );
      await t.enterText(pitch, '20');
      await t.pump();
      await t.tapAt(t.screen(77, 116, 18));
      await t.pump();
      h = t.drawing.scene.project.beams.single.holes.last;
      expect((h.x, h.y), (77, 117));
      await t.tapSettled(find.byKey(const ValueKey('drill-magnet')));
      await t.tapAt(t.screen(199, 99, 18));
      await t.pump();
      h = t.drawing.scene.project.beams.single.holes.last;
      expect(h.x, closeTo(199, .001));
      expect(h.y, closeTo(99, .001));
      final count = t.drawing.scene.project.beams.single.holes.length;
      final eye = t.drawing.scene.camera.eye;
      final right = await t.startGesture(
        t.getCenter(canvas),
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await right.moveBy(const Offset(80, -50));
      await right.up();
      await t.pumpAndSettle();
      expect(t.drawing.scene.camera.eye.distanceTo(eye), greaterThan(.1));
      expect(t.drawing.scene.project.beams.single.holes.length, count);
      await t.tapSettled(find.text('2D'));
      expect(find.text('Отверстия (3)'), findsOneWidget);
      expect(zero, findsNothing);
      await t.tapSettled(find.text('Отмена'));
      expect(editor.project.beams.single, same(panel));
    },
  );
}
