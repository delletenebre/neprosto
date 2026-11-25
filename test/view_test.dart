import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart' show PictureLayer, RenderParagraph;
import 'package:flutter_test/flutter_test.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:neprosto/editor/controller.dart';
import 'package:neprosto/editor/desktop.dart';
import 'package:neprosto/editor/grid_painter.dart';
import 'package:neprosto/editor/palette.dart';
import 'package:neprosto/editor/grid_plane_icon.dart';
import 'package:neprosto/editor/grid_visibility.dart';
import 'package:neprosto/editor/model.dart';
import 'package:neprosto/editor/scene.dart';
import 'package:neprosto/editor/view_cube.dart';
import 'package:neprosto/editor/work_plane_picker.dart';
import 'package:neprosto/main.dart';

void main() {
  test(
    'Orbit keeps the picked point under the pointer in both projections',
    () {
      const viewport = Size(960, 600);
      final point = Vector3(280, 110, 690);
      for (final perspective in [false, true]) {
        final cam = Camera()
          ..perspective = perspective
          ..target = Vector3(30, 100, 160)
          ..pan = const Offset(70, -45);
        final original = cam.project(point, viewport);
        for (final delta in [
          const Offset(50, -33),
          const Offset(-40, 8),
          const Offset(70, 40),
        ]) {
          cam.orbit(delta, point);
          expect(
            (cam.project(point, viewport) - original).distance,
            lessThan(1e-7),
          );
        }
      }
    },
  );

  testWidgets(
    'Orbit and cube faces select the correct view without replacing presets',
    (t) async {
      await t.binding.setSurfaceSize(const Size(1260, 800));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final e = Editor(Project.bench());
      await t.pumpWidget(NeprostoApp(editor: e));
      await t.pumpAndSettle();
      DeskButton tab(ViewAngle view) => t.widget<DeskButton>(
        find.ancestor(
          of: find.text(view.label),
          matching: find.byType(DeskButton),
        ),
      );
      expect(tab(ViewAngle.iso).primary, isTrue);
      final axes = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is AxesPainter,
      );
      expect(axes, findsOneWidget);
      final canvasBounds = t.getRect(find.byKey(const Key('drawing')));
      final axesBounds = t.getRect(axes);
      expect(axesBounds.left - canvasBounds.left, closeTo(14, .01));
      expect(canvasBounds.bottom - axesBounds.bottom, closeTo(13, .01));
      final cube = find
          .descendant(
            of: find.byType(ViewCube),
            matching: find.byType(CustomPaint),
          )
          .first;
      // The center of +Z projects vertically above the cube origin in the initial axonometric view.
      final top =
          t.getCenter(cube) + Offset(e.camera.right.z, -e.camera.up.z) * 24;
      await t.tapAt(top);
      await t.pumpAndSettle();
      expect(e.activeView, ViewAngle.top);
      expect(tab(ViewAngle.top).primary, isTrue);
      expect(tab(ViewAngle.iso).active, isFalse);
      expect(find.text('Сверху · XY'), findsNothing);
      e.camera.scale = .7;
      final canvas = find.byKey(const Key('drawing'));
      final origin =
          t.getTopLeft(canvas) +
          e.camera.project(
            e.project.beams.first.pointAt(Vector3.all(.5)),
            t.getSize(canvas),
          );
      final mouse = await t.startGesture(
        origin,
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await mouse.moveBy(const Offset(30, -60));
      await mouse.up();
      await t.pumpAndSettle();
      expect(e.activeView, isNull);
      expect(tab(ViewAngle.top).active, isTrue);
      expect(tab(ViewAngle.top).primary, isFalse);
      expect(tab(ViewAngle.iso).active, isFalse);
      expect(find.text('Свободный вид · Ортография'), findsNothing);
      await t.tap(find.text('Сверху'));
      await t.pumpAndSettle();
      expect(tab(ViewAngle.top).primary, isTrue);
      expect(e.camera.pitch, ViewAngle.top.pitch);
      expect(e.camera.scale, .7);
      await t.tap(find.text('Аксонометрия'));
      await t.pumpAndSettle();
      expect(e.camera.pitch, ViewAngle.iso.pitch);
      expect(e.camera.yaw, ViewAngle.iso.yaw);
      await t.tap(find.text('Сверху'));
      await t.pumpAndSettle();
      expect(e.camera.pitch, ViewAngle.top.pitch);
      expect(e.camera.scale, .7);
    },
  );

  testWidgets('Cube fades only when its silhouette covers a visible part', (
    t,
  ) async {
    await t.binding.setSurfaceSize(const Size(1260, 800));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final part = Beam(
      1,
      'A',
      Vector3.all(-1),
      Vector3.all(2),
      axis(0),
      axis(1),
    );
    final e = Editor(Project('', [part]))..fitRequested = false;
    e.camera.scale = 1;
    await t.pumpWidget(NeprostoApp(editor: e));
    await t.pumpAndSettle();
    final cube = find.descendant(
      of: find.byType(ViewCube),
      matching: find.byType(CustomPaint),
    );
    final drawing = find.byKey(const Key('drawing'));
    final center = t.getCenter(cube);
    Future<void> panPartTo(Offset offsetFromCube) async {
      e.camera.pan = center - t.getCenter(drawing) + offsetFromCube;
      e.refresh();
      await t.pump();
    }

    const leftFace = Color(0xffd7e7f2);
    final opaque = paints..path(color: leftFace);
    final translucent = paints..path(color: leftFace.withValues(alpha: .45));
    // Inside the bounding rectangle, beyond the upper right sloping edge.
    await panPartTo(const Offset(30, -32));
    expect(cube, opaque);
    // The part touches only the right side of the cube.
    await panPartTo(const Offset(31, 0));
    expect(cube, translucent);
    e.commit(e.project.edit({part.id}, (b) => b.copy(hidden: true)));
    await t.pump();
    expect(cube, opaque);
    e.undo();
    await t.pump();
    expect(cube, translucent);
    await t.tapAt(center + Offset(0, -e.camera.up.z * 24));
    await t.pumpAndSettle();
    expect(e.activeView, ViewAngle.top);
  });

  testWidgets(
    'Grid button changes visible planes without changing the drawing plane',
    (t) async {
      await t.binding.setSurfaceSize(const Size(1260, 800));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final e = Editor(Project.bench())..setView(ViewAngle.front);
      await t.pumpWidget(NeprostoApp(editor: e));
      await t.pumpAndSettle();
      final gridButton = find.byTooltip('Видимость сетки');
      Color? buttonBackground() => t
          .widget<DeskControl>(
            find.descendant(of: gridButton, matching: find.byType(DeskControl)),
          )
          .background;
      expect(buttonBackground(), isNull);
      await t.tap(gridButton);
      await t.pumpAndSettle();
      for (final label in ['Рабочая плоскость', 'По осям']) {
        final text = t.renderObject<RenderParagraph>(find.text(label));
        expect(
          text.size.width + .01,
          greaterThanOrEqualTo(text.getMaxIntrinsicWidth(double.infinity)),
          reason: label,
        );
      }
      expect(buttonBackground(), EditorPalette.light.pale);
      await t.tap(find.text('По осям'));
      await t.pumpAndSettle();
      for (final plane in GridPlane.values) {
        final row = find.byKey(ValueKey('grid-${plane.name}'));
        final icon = find.descendant(
          of: row,
          matching: find.byType(GridPlaneIcon),
        );
        expect(t.widget<GridPlaneIcon>(icon).plane, plane);
      }
      await t.tap(find.byKey(const ValueKey('grid-xy')));
      await t.pumpAndSettle();
      expect(e.gridVisibility.planes, isEmpty);
      await t.tap(find.byKey(const ValueKey('grid-yz')));
      await t.pumpAndSettle();
      expect(e.gridVisibility.planes, {GridPlane.yz});
      expect(e.plane.name, 'XZ');
      expect(e.activeView, ViewAngle.front);
      await t.tapAt(const Offset(10, 10));
      await t.pumpAndSettle();
      expect(buttonBackground(), isNull);
      expect(find.byKey(const ValueKey('grid-yz')), findsNothing);
      await t.tap(find.byTooltip('Видимость сетки'));
      await t.pumpAndSettle();
      await t.tap(find.text('Рабочая плоскость'));
      await t.pumpAndSettle();
      expect(e.gridVisibility.automatic, isTrue);
      expect(e.gridVisibility.planes, {GridPlane.yz});
    },
    variant: TargetPlatformVariant({
      TargetPlatform.macOS,
      TargetPlatform.windows,
    }),
  );

  testWidgets(
    'Work plane examples select the matching plane or a face in the drawing',
    (t) async {
      await t.binding.setSurfaceSize(const Size(1260, 800));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final e = Editor(Project.bench());
      await t.pumpWidget(NeprostoApp(editor: e));
      await t.pumpAndSettle();
      final picker = find.byType(WorkPlanePicker);
      Future<void> open() async {
        await t.tap(picker);
        await t.pumpAndSettle();
      }

      for (final (example, title, axes) in [
        ('Как дверца шкафа', 'Фронтальная', 'XZ'),
        ('Как боковина шкафа', 'Боковая', 'YZ'),
        ('Как полка или столешница', 'Горизонтальная', 'XY'),
      ]) {
        await open();
        expect(find.text(axes), findsOneWidget);
        await t.tap(find.text(example));
        await t.pumpAndSettle();
        expect(e.plane.name, axes);
        expect(
          find.descendant(of: picker, matching: find.textContaining(title)),
          findsOneWidget,
        );
      }

      await open();
      await t.tap(find.text('По грани детали'));
      await t.pumpAndSettle();
      expect(e.tool, Tool.face);
      expect(e.plane.name, 'XY');
      final drawing = find.byKey(const Key('drawing'));
      final part = e.project.beams.first;
      final point = e.camera.project(
        part.pointAt(Vector3.all(.5)),
        t.getSize(drawing),
      );
      await t.tapAt(t.getTopLeft(drawing) + point);
      await t.pumpAndSettle();
      expect(e.tool, Tool.select);
      expect(e.plane.name, 'Грань');
      expect(
        find.descendant(
          of: picker,
          matching: find.textContaining('По грани детали'),
        ),
        findsOneWidget,
      );

      e.setPartsHidden(e.project.byId.keys.toSet(), true);
      await t.pumpAndSettle();
      await open();
      final unavailable = find.text('Нужна видимая деталь на чертеже');
      expect(unavailable, findsOneWidget);
      await t.tap(unavailable);
      await t.pumpAndSettle();
      expect(unavailable, findsOneWidget);
      expect(e.tool, Tool.select);
    },
    variant: TargetPlatformVariant({
      TargetPlatform.macOS,
      TargetPlatform.windows,
    }),
  );

  testWidgets('Hover reuses the grid picture and panning updates it', (
    t,
  ) async {
    await t.binding.setSurfaceSize(const Size(1260, 800));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final e = Editor(Project.bench())
      ..gridVisibility = const GridVisibility(
        automatic: false,
        planes: {GridPlane.xy, GridPlane.xz, GridPlane.yz},
      );
    await t.pumpWidget(NeprostoApp(editor: e));
    await t.pumpAndSettle();
    final grid = find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is GridPainter,
    );
    ui.Picture picture(Finder finder) =>
        t.layerListOf(finder).whereType<PictureLayer>().single.picture!;
    final drawing = find.byKey(const Key('drawing'));
    final initialGrid = picture(grid), initialDrawing = picture(drawing);
    final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer();
    addTearDown(mouse.removePointer);
    await mouse.moveTo(t.getCenter(drawing));
    await t.pump();
    expect(picture(drawing), isNot(same(initialDrawing)));
    expect(picture(grid), same(initialGrid));

    await t.sendEventToBinding(
      PointerScrollEvent(
        position: t.getCenter(drawing),
        scrollDelta: const Offset(40, 10),
      ),
    );
    await t.pump();
    expect(picture(grid), isNot(same(initialGrid)));
  });

  test('Each grid covers the viewport and fades at grazing angles', () async {
    const size = Size(240, 180);
    final cam = Camera()..scale = .1;
    Future<List<int>> pixels([
      GridVisibility grid = const GridVisibility(),
    ]) async {
      final recorder = ui.PictureRecorder();
      GridPainter(
        camera: cam,
        plane: WorkPlane.xy(),
        visibility: grid,
        paper: EditorPalette.light.paper,
      ).paint(Canvas(recorder), size);
      final picture = recorder.endRecording();
      final image = await picture.toImage(240, 180);
      final data = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      final result = [
        for (var i = 0; i < data.lengthInBytes; i += 4) data.getUint32(i),
      ];
      image.dispose();
      picture.dispose();
      return result;
    }

    final floor = await pixels();
    expect(floor.toSet().length, greaterThan(1));
    expect(floor.take(240 * 30).toSet().length, greaterThan(1));
    const hidden = GridVisibility(automatic: false, planes: {});
    final empty = (await pixels(hidden)).toSet();
    expect(empty, hasLength(1));
    cam.pitch = .005;
    expect((await pixels()).toSet(), empty);
    final walls = hidden.toggle(GridPlane.xz).toggle(GridPlane.yz);
    expect((await pixels(walls)).toSet().length, greaterThan(1));
    expect(GridVisibility.decode(walls.encode()).planes, walls.planes);
  });
}
