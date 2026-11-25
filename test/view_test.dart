import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
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
import 'package:neprosto/editor/viewport_footer.dart';
import 'package:neprosto/editor/work_plane_picker.dart';
import 'package:neprosto/main.dart';

import 'viewport_test_helpers.dart';

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
    'Cube and view buttons select fixed views that pan and 3D views that orbit',
    (t) async {
      await t.binding.setSurfaceSize(const Size(1440, 800));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final e = Editor(Project.bench());
      await t.pumpWidget(NeprostoApp(editor: e));
      await t.pumpAndSettle();
      Finder displayed(String label) => find.descendant(
        of: find.byType(ViewportFooter),
        matching: find.text(label),
      );
      expect(displayed(ViewAngle.perspective.label), findsOneWidget);
      expect(displayed(ViewAngle.iso.label), findsNothing);
      expect(find.byTooltip(ViewAngle.iso.label), findsOneWidget);
      for (final angle in ViewAngle.values.where(
        (v) => v.projectionPlane != null,
      )) {
        expect(find.byTooltip(angle.label), findsOneWidget);
        expect(displayed(angle.label), findsNothing);
      }
      expect(e.camera.perspective, isTrue);
      final axes = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is AxesPainter,
      );
      expect(axes, findsOneWidget);
      void expectOffsetAxes() {
        final orientation = Camera()
          ..yaw = e.camera.yaw
          ..pitch = e.camera.pitch
          ..scale = 19;
        final painter = t.widget<CustomPaint>(axes).painter! as AxesPainter;
        final pattern = paints;
        const origin = Offset(24, 28);
        for (final (i, direction) in [axis(0), -axis(1), axis(2)].indexed) {
          pattern.line(
            p1: origin,
            p2: origin + orientation.project(direction, Size.zero),
            color: painter.colors.axisColor(i),
          );
        }
        expect(axes, pattern);
      }

      expectOffsetAxes();
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
      // The center of +Z projects vertically above the cube origin.
      final top =
          t.getCenter(cube) + Offset(e.camera.right.z, -e.camera.up.z) * 24;
      await t.tapAt(top);
      await t.pumpAndSettle();
      expect(e.activeView, ViewAngle.top);
      expect(displayed(ViewAngle.top.label), findsOneWidget);
      expect(displayed(ViewAngle.perspective.label), findsNothing);
      expect(find.text('Сверху · XY'), findsNothing);
      e.camera.scale = .7;
      final origin = canvasBounds.center;
      const delta = Offset(30, -60);
      Future<void> rightDrag() async {
        final mouse = await t.startGesture(
          origin,
          kind: PointerDeviceKind.mouse,
          buttons: kSecondaryMouseButton,
        );
        await mouse.moveBy(delta);
        await mouse.up();
        await t.pumpAndSettle();
      }

      for (final view in const [
        ViewAngle.top,
        ViewAngle.front,
        ViewAngle.right,
        ViewAngle.back,
        ViewAngle.left,
        ViewAngle.bottom,
      ]) {
        await selectViewportView(t, view);
        final pan = e.camera.pan;
        await rightDrag();
        expect(e.camera.pan - pan, delta);
        final pad = await t.createGesture(kind: PointerDeviceKind.trackpad);
        await t.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
        await pad.panZoomStart(origin);
        await pad.panZoomUpdate(origin, pan: delta);
        await pad.panZoomEnd();
        await t.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
        await t.pumpAndSettle();
        expect(e.camera.pan - pan, delta * 2);
        expect(displayed(view.label), findsOneWidget);
        expect(e.camera.yaw, view.yaw);
        expect(e.camera.pitch, view.pitch);
        expectOffsetAxes();
      }
      for (final view in [ViewAngle.iso, ViewAngle.perspective]) {
        await selectViewportView(t, view);
        await rightDrag();
        expect(e.camera.yaw, isNot(view.yaw));
        expect(e.camera.perspective, view == ViewAngle.perspective);
        expect(e.activeView, isNull);
        expectOffsetAxes();
        expect(displayed(view.label), findsOneWidget);
        expect(find.byTooltip('Свободный вид · ${view.label}'), findsOneWidget);
        await selectViewportView(t, view);
        expect(e.camera.yaw, view.yaw);
        expect(e.camera.pitch, view.pitch);
      }
      await selectViewportView(t, ViewAngle.top);
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
      expect(find.text('XZ · Задняя'), findsOneWidget);
      for (final plane in GridPlane.values) {
        final row = find.byKey(ValueKey('grid-${plane.name}'));
        final icon = find.descendant(
          of: row,
          matching: find.byType(GridPlaneIcon),
        );
        expect(t.widget<GridPlaneIcon>(icon).plane, plane);
        if (plane != GridPlane.yz) {
          final floor = plane == GridPlane.xy;
          expect(
            icon,
            paints..path(
              color: EditorPalette.highlight,
              includes: [floor ? const Offset(17, 28) : const Offset(8, 15)],
              excludes: [floor ? const Offset(17, 10) : const Offset(26, 20)],
            ),
          );
        }
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

  testWidgets('Hover reuses the grid while pan and project resize repaint it', (
    t,
  ) async {
    await t.binding.setSurfaceSize(const Size(1260, 800));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final e = Editor(Project.bench().withWorkspace(Vector3(600, 400, 300)))
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

    final pannedGrid = picture(grid);
    final resized = Vector3(800, 500, 350);
    e.commit(e.project.withWorkspace(resized));
    await t.pump();
    expect(
      (t.widget<CustomPaint>(grid).painter! as GridPainter)
          .project
          .workspaceSize,
      resized,
    );
    expect(picture(grid), isNot(same(pannedGrid)));
  });

  const size = Size(240, 180);
  Future<List<int>> gridPixels(
    Camera cam, {
    WorkPlane? plane,
    Project? project,
    GridVisibility grid = const GridVisibility(),
    EditorPalette colors = EditorPalette.light,
  }) async {
    final recorder = ui.PictureRecorder();
    GridPainter(
      camera: cam,
      project: project ?? Project('', []),
      plane: plane ?? WorkPlane.xy(),
      visibility: grid,
      colors: colors,
    ).paint(Canvas(recorder), size);
    final picture = recorder.endRecording();
    final image = await picture.toImage(240, 180);
    final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    final result = [
      for (var i = 0; i < data.lengthInBytes; i += 4) data.getUint32(i),
    ];
    image.dispose();
    picture.dispose();
    return result;
  }

  test(
    'An unbounded grid covers the viewport and fades at grazing angles',
    () async {
      final cam = Camera()..scale = .1;
      final floor = await gridPixels(cam);
      expect(floor.toSet().length, greaterThan(1));
      expect(floor.take(240 * 30).toSet().length, greaterThan(1));
      const hidden = GridVisibility(automatic: false, planes: {});
      final empty = (await gridPixels(cam, grid: hidden)).toSet();
      expect(empty, hasLength(1));
      cam.pitch = .005;
      expect((await gridPixels(cam)).toSet(), empty);
      final walls = hidden.toggle(GridPlane.xz).toggle(GridPlane.yz);
      expect(
        (await gridPixels(cam, grid: walls)).toSet().length,
        greaterThan(1),
      );
      expect(GridVisibility.decode(walls.encode()).planes, walls.planes);
    },
  );

  test('Grid lines follow their world axis in both themes', () async {
    for (final colors in EditorPalette.values) {
      for (final (plane, horizontal, vertical) in [
        (WorkPlane.xy(), 0, 1),
        (WorkPlane.xz(), 0, 2),
        (WorkPlane.yz(), 1, 2),
      ]) {
        final camera = Camera()
          ..facePlane(plane)
          ..scale = .4
          ..pan = const Offset(.5, .5);
        final pixels = await gridPixels(camera, plane: plane, colors: colors);
        for (final (x, y, axis) in [
          (128, 90, horizontal),
          (120, 97, vertical),
        ]) {
          final pixel = pixels[y * 240 + x];
          final expected = Color.lerp(
            colors.paper,
            colors.axisColor(axis),
            .5,
          )!.toARGB32();
          for (final shift in [16, 8, 0]) {
            expect(
              (pixel >> (shift + 8)) & 255,
              closeTo((expected >> shift) & 255, 2),
            );
          }
        }
      }
    }
  });

  test(
    'Project bounds clip each grid, including an oblique part face',
    () async {
      final room = Vector3(375, 265, 185);
      final project = Project('', []).withWorkspace(room);
      final center = room * .5;
      final u = Vector3(1, 1, 0).normalized();
      final v = Vector3(-1, 1, 2).normalized();
      final face = WorkPlane('Грань', center, u, v);
      final paper = (await gridPixels(
        Camera(),
        grid: const GridVisibility(automatic: false, planes: {}),
      )).first;
      for (final perspective in [false, true]) {
        for (final axes in [...GridPlane.values, null]) {
          final plane = axes == GridPlane.xz
              ? WorkPlane.xz().through(Vector3(0, room.y, 0))
              : axes?.plane ?? face;
          final cam = Camera()
            ..scale = .4
            ..target = center
            ..facePlane(plane)
            ..perspective = perspective;
          final grid = axes == null
              ? const GridVisibility()
              : GridVisibility(automatic: false, planes: {axes});
          final pixels = await gridPixels(
            cam,
            plane: plane,
            project: project,
            grid: grid,
          );
          var drawn = 0;
          for (var i = 0; i < pixels.length; i++) {
            if (pixels[i] == paper) continue;
            final at = Offset(i % 240 + .5, i ~/ 240 + .5);
            final point = cam.onPlane(at, size, plane)!;
            // Allow a pixel of antialiasing at the boundary.
            for (var axis = 0; axis < 3; axis++) {
              expect(point[axis], inInclusiveRange(-3, room[axis] + 3));
            }
            drawn++;
          }
          expect(drawn, greaterThan(100));
        }
      }

      final above = WorkPlane.xy().through(Vector3(0, 0, room.z + 1));
      final cam = Camera()..facePlane(above);
      expect((await gridPixels(cam, plane: above, project: project)).toSet(), {
        paper,
      });
    },
  );

  test(
    'The XZ axis grid follows the rear of the workspace or assembly',
    () async {
      final assembly = Project.bench();
      final cam = Camera()..scale = .28;
      const grid = GridVisibility(automatic: false, planes: {GridPlane.xz});
      for (final (project, rearY) in [
        (assembly.withWorkspace(Vector3(380, 250, 180)), 250.0),
        (assembly.withWorkspace(Vector3(380, 400, 180)), 400.0),
        (assembly, assembly.partBounds!.high.y),
      ]) {
        cam.target = Vector3(190, rearY * .5, 90);
        final rear = WorkPlane.xz().through(Vector3(0, rearY, 0));
        final manual = await gridPixels(cam, project: project, grid: grid);
        expect(manual, await gridPixels(cam, project: project, plane: rear));
        expect(
          manual,
          isNot(
            equals(
              await gridPixels(cam, project: project, plane: WorkPlane.xz()),
            ),
          ),
        );
      }
    },
  );
}
