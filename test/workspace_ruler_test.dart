import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neprosto/editor/controller.dart';
import 'package:neprosto/editor/drawing.dart';
import 'package:neprosto/editor/model.dart';
import 'package:neprosto/editor/scene.dart';
import 'package:neprosto/main.dart';

void main() {
  const viewport = Size(900, 600);
  final room = Vector3(600, 320, 240);
  final empty = Project('', []).withWorkspace(room);

  test('Perspective ruler follows all twelve drawn workspace edges', () {
    final camera = Camera()..view(ViewAngle.perspective);
    camera.fit(empty, viewport);
    final scene = Scene(empty, camera, viewport);
    final corners = empty.workspaceCorners;
    for (var i = 0; i < corners.length; i++) {
      for (final bit in [1, 2, 4]) {
        if (i & bit != 0) continue;
        final a = corners[i], b = corners[i | bit];
        final point = a + (b - a) * .32;
        final pos = camera.project(point, viewport);
        final edge = camera.project(b, viewport) - camera.project(a, viewport);
        final cursor = pos + Offset(-edge.dy, edge.dx) / edge.distance * 2;
        final target = scene.rulerTarget(cursor, sticky: true)!;
        expect(target.anchor.point.distanceTo(point), lessThan(1e-6));
        expect(target.anchor.onWorkspace, isTrue);
        expect(target.guide, (a, b));
        expect(scene.rulerTarget(cursor, sticky: false), isNull);
      }
    }
  });

  test('Workspace corners, midpoints and free edge points respect the selected snap mode', () {
    final camera = Camera()..view(ViewAngle.front);
    camera.fit(empty, viewport);
    final scene = Scene(empty, camera, viewport);
    RulerTarget? aim(Vector3 p, SnapMode mode) => scene.rulerTarget(
      camera.project(p, viewport) + const Offset(2, 1),
      sticky: true,
      mode: mode,
    );
    final corner = Vector3(room.x, 0, room.z);
    final mid = Vector3(room.x, 0, room.z / 2);
    expect(aim(corner, SnapMode.corner)!.anchor.point, corner);
    expect(aim(mid, SnapMode.edge)!.anchor.point, mid);
    expect(aim(mid, SnapMode.corner), isNull);
    expect(aim(corner, SnapMode.edge), isNull);
    expect(aim(mid, SnapMode.surface), isNull);
    expect(aim(Vector3(120, 0, 80), SnapMode.auto), isNull);
    expect(
      Scene(
        Project('', []),
        camera,
        viewport,
      ).rulerTarget(camera.project(corner, viewport), sticky: true),
      isNull,
    );

    final span = Dimension(
      aim(mid, SnapMode.edge)!.anchor,
      aim(corner, SnapMode.corner)!.anchor,
    );
    final saved = Project.decode(empty.copy(dimensions: [span]).encode());
    final resized = saved.withWorkspace(room * 2);
    final measured = resized.dimensions.single;
    expect(measured.locked, isTrue);
    expect(measured.a.resolve(resized), mid * 2);
    expect(measured.b.resolve(resized), corner * 2);
    final unbounded = resized.withWorkspace(null);
    expect(unbounded.dimensions.single.b.resolve(unbounded), corner * 2);
  });

  testWidgets(
    'Measure from a board to the bottom workspace boundary in front view',
    (t) async {
      await t.binding.setSurfaceSize(const Size(1360, 840));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final board = Beam(
        1,
        'Полка',
        Vector3(80, 70, 120),
        Vector3(400, 50, 18),
        axis(0),
        axis(1),
      );
      final editor = Editor(Project('', [board]).withWorkspace(room))
        ..setView(ViewAngle.front)
        ..setTool(Tool.measure)
        ..fitRequested = false;
      editor.camera
        ..target = room * .5
        ..scale = 1;
      await t.pumpWidget(NeprostoApp(editor: editor));
      await t.pumpAndSettle();
      final canvas = find.byKey(const Key('drawing'));
      Offset at(double z) =>
          t.getTopLeft(canvas) +
          editor.camera.project(Vector3(160, 70, z), t.getSize(canvas));
      final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: at(121));
      await mouse.down(at(121));
      await mouse.up();
      await t.pump();
      expect(editor.first!.beam, board.id);
      await mouse.moveTo(at(4));
      await t.pump();
      DrawingPainter painter() =>
          t.widget<CustomPaint>(canvas).painter! as DrawingPainter;
      expect(painter().rulerTarget!.guide, isNotNull);
      expect(editor.hover!.point, Vector3(160, 70, 0));
      await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await t.pump();
      expect(painter().rulerTarget, isNull);
      expect(editor.hover!.point.z, 4);
      await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await t.pump();
      await mouse.down(at(4));
      await mouse.up();
      await t.pump();
      final dimension = editor.project.dimensions.single;
      expect(dimension.b.onWorkspace, isTrue);
      expect(dimension.length(editor.project), 120);
      editor.setTool(Tool.measure);
      await t.pump(kDoubleTapTimeout);
      await mouse.down(at(4));
      await mouse.up();
      await t.pump();
      await mouse.moveTo(at(121));
      await t.pump();
      expect(painter().first!.point, Vector3(160, 70, 0));
      await mouse.down(at(121));
      await mouse.up();
      await t.pump();
      final reverse = editor.project.dimensions.last;
      expect(reverse.a.onWorkspace, isTrue);
      expect(reverse.b.beam, board.id);
      expect(reverse.length(editor.project), 120);
      await mouse.removePointer();
    },
  );
}
