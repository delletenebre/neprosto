import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neprosto/editor/controller.dart';
import 'package:neprosto/editor/model.dart';
import 'package:neprosto/editor/move_snap.dart';
import 'package:neprosto/editor/scene.dart';
import 'package:neprosto/main.dart';

void main() {
  final room = Vector3(200, 180, 160);
  final board = Beam(
    1,
    'Полка',
    Vector3(30, 40, 20),
    Vector3(80, 40, 16),
    axis(0),
    axis(1),
  );

  test(
    'Rotated selection meets two walls together and stays in the work plane',
    () {
      final other = board.copy(id: 2, origin: Vector3(70, 60, 30));
      final project = Project('', [
        board,
        other,
      ]).withWorkspace(room).rotate({1, 2}, axis(2), 28);
      final bounds = project.partBounds!;
      final camera = Camera()
        ..view(ViewAngle.top)
        ..scale = 2;
      final raw = Vector3(room.x - bounds.high.x - 2, -bounds.low.y + 2, 0);
      final snap = MoveSnap(project, {
        1,
        2,
      }, WorkPlane.xy()).apply(raw, raw, camera);
      expect(snap.guides, hasLength(2));
      expect(bounds.high.x + snap.delta.x, closeTo(room.x, 1e-7));
      expect(bounds.low.y + snap.delta.y, closeTo(0, 1e-7));
      expect(snap.delta.z, closeTo(0, 1e-7));

      final slope = WorkPlane(
        '',
        Vector3.zero(),
        Vector3(1, 0, 1).normalized(),
        axis(1),
      );
      final travel = room.z - bounds.high.z;
      final diagonal = Vector3(travel - 2, 0, travel - 2);
      final tallRoom = project.withWorkspace(Vector3(500, 180, room.z));
      camera.facePlane(slope);
      final up = MoveSnap(tallRoom, {
        1,
        2,
      }, slope).apply(diagonal, diagonal, camera);
      expect(up.delta.dot(slope.normal), closeTo(0, 1e-7));
      expect(bounds.high.z + up.delta.z, closeTo(room.z, 1e-7));
    },
  );

  testWidgets('Place a part by its corner on a workspace boundary', (t) async {
    await t.binding.setSurfaceSize(const Size(1360, 840));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final project = Project('', [board]).withWorkspace(room);
    final e = Editor(project)
      ..setView(ViewAngle.top)
      ..select(board.id)
      ..setTool(Tool.move)
      ..fitRequested = false;
    e.camera
      ..target = room * .5
      ..scale = 1;
    await t.pumpWidget(NeprostoApp(editor: e));
    await t.pumpAndSettle();
    final canvas = find.byKey(const Key('drawing'));
    Offset at(Vector3 world) =>
        t.getTopLeft(canvas) + e.camera.project(world, t.getSize(canvas));
    await t.tapAt(at(board.corner(7)));
    await t.pump();
    expect(e.first?.beam, board.id);
    await t.tapAt(at(Vector3(room.x - 4, 120, board.corner(7).z)));
    await t.pump();
    expect(e.single!.corner(7), Vector3(room.x, 120, board.corner(7).z));
    e.undo();
    expect(e.project, same(project));
    await t.pump(kDoubleTapTimeout);
  });

  for (final positive in [false, true]) {
    testWidgets(
      'Resize the ${positive ? "right" : "left"} end to a wall, release and undo',
      (t) async {
        await t.binding.setSurfaceSize(const Size(1360, 840));
        addTearDown(() => t.binding.setSurfaceSize(null));
        final project = Project('', [board]).withWorkspace(room);
        final e = Editor(project)
          ..setView(ViewAngle.top)
          ..select(board.id)
          ..fitRequested = false;
        e.camera
          ..target = room * .5
          ..scale = 1;
        await t.pumpWidget(NeprostoApp(editor: e));
        await t.pumpAndSettle();
        final canvas = find.byKey(const Key('drawing'));
        final edge = board.pointAt(Vector3(positive ? 1 : 0, .5, 1));
        final start =
            t.getTopLeft(canvas) + e.camera.project(edge, t.getSize(canvas));
        final wall = positive ? room.x : 0.0, sign = positive ? 1.0 : -1.0;
        final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
        await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await mouse.addPointer(location: start);
        await mouse.down(start);
        Future<void> drag(double x) async {
          await mouse.moveTo(start + Offset(x - edge.x, 0));
          await t.pump();
        }

        double end() => positive ? e.single!.corner(1).x : e.single!.origin.x;
        await drag(wall - sign * 4);
        expect(end(), wall);
        await drag(wall - sign * 8);
        expect(end(), wall);
        await drag(wall - sign * 12);
        expect(end(), wall - sign * 12);
        await drag(wall + sign * 20);
        expect(end(), wall);
        await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await t.pump();
        expect(end(), wall + sign * 20);
        await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await t.pump();
        expect(end(), wall);
        expect(
          positive ? e.single!.origin : e.single!.corner(1),
          positive ? board.origin : board.corner(1),
        );
        await mouse.up();
        await mouse.removePointer();
        await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        e.undo();
        expect(e.project, same(project));
        await t.pump(kDoubleTapTimeout);
      },
    );
  }
}
