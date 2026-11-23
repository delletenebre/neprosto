import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:neprosto/editor/arithmetic.dart';
import 'package:neprosto/editor/assembly.dart';
import 'package:neprosto/editor/contact.dart';
import 'package:neprosto/editor/controller.dart';
import 'package:neprosto/editor/joint.dart';
import 'package:neprosto/editor/model.dart';
import 'package:neprosto/editor/move_snap.dart';
import 'package:neprosto/editor/step.dart';
import 'package:neprosto/editor/positioning.dart';
import 'package:neprosto/editor/scene.dart';

import 'dart:ui' show Size;

Beam bar(
  int id,
  double x,
  double y,
  double z,
  double length, {
  double width = 30,
  double height = 40,
}) => Beam(
  id,
  'Брусок $id',
  Vector3(x, y, z),
  Vector3(length, width, height),
  axis(0),
  axis(1),
);
void near(Vector3 a, Vector3 b) => expect(a.distanceTo(b), lessThan(1e-6));

void main() {
  test(
    'Dragging aligns stock ends and matches the clear space between slats',
    () {
      final parts = [
        bar(1, 0, 0, 0, 300),
        bar(2, 0, 38.25, 0, 300, width: 40),
        bar(3, 21, 160, 0, 300),
        bar(4, 0, 80, 90, 300),
      ];
      final cam = Camera()
        ..view(ViewAngle.top)
        ..scale = 1;
      final project = Project('Столешница', parts);
      final m = MoveSnap(project, {3}, WorkPlane.xy());
      final raw = Vector3(-19.8, -72, 0);
      final matched = m.apply(raw, raw, cam);
      near(matched.delta, Vector3(-21, -73.5, 0));
      expect(
        matched.guides.map((g) => g.gap).nonNulls.single,
        closeTo(8.25, 1e-7),
      );
      // A group moves rigidly as one footprint.
      final assembly = project.copy(beams: [...parts, bar(5, 21, 200, 0, 300)]);
      final group = MoveSnap(assembly, {
        3,
        5,
      }, WorkPlane.xy()).apply(raw, raw, cam);
      near(group.delta, matched.delta);
      // Between two neighbours the gaps can be equalised even without a third reference.
      final middle = Project('Полки', [
        parts[0],
        bar(2, 0, 110, 0, 300),
        parts[2],
      ]);
      final between = Vector3(-21, -103.75, 0);
      final centered = MoveSnap(middle, {
        3,
      }, WorkPlane.xy()).apply(between, between, cam);
      near(centered.delta, Vector3(-21, -105, 0));
      expect(
        centered.guides.map((g) => g.gap).nonNulls.single,
        closeTo(25, 1e-7),
      );
      final rotated = project.rotate(project.byId.keys.toSet(), axis(2), 30);
      final offset = turn(raw, axis(2), math.pi / 6);
      final rotatedSnap = MoveSnap(rotated, {
        3,
      }, WorkPlane.xy()).apply(offset, offset, cam);
      near(rotatedSnap.delta, turn(matched.delta, axis(2), math.pi / 6));
    },
  );

  test(
    'Independent locks preserve 30×40 stock and rail contacts while resizing',
    () {
      final leg = Beam(
        1,
        'Стойка',
        Vector3.zero(),
        Vector3(400, 30, 40),
        axis(2),
        axis(0),
        locks: 6,
      );
      final p = Project('Рама', [
        leg,
        leg.copy(id: 2, origin: Vector3(970, 0, 0)),
        bar(3, 30, 0, 360, 940),
      ]);
      final r = resizeAssembly(p, {1, 2, 3}, axis(0), 1200);
      expect(r.error, isNull);
      final next = r.project;
      expect(next.byId[2]!.origin.x, 1170);
      expect(next.byId[2]!.size, leg.size);
      expect(next.byId[3]!.size.x, 1140);
      expect(next.byId[3]!.corner(1).x, next.byId[2]!.origin.x);
      expect(resizeAssembly(p, {1, 2, 3}, axis(0), 59).error, isNotNull);
      expect(bar(4, 0, 0, 0, 400).locks, 0);
    },
  );
  test(
    'A dragged end hits the first obstruction and ignores touching sides',
    () {
      final a = bar(1, 0, 0, 0, 100),
          side = bar(2, 80, 30, 0, 70),
          stop = bar(3, 220, 0, 0, 30);
      final contact = firstContact(a, 0, true, [
        side,
        stop,
        bar(4, 175, 0, 0, 5),
      ])!;
      expect(contact.travel, 75);
      expect(contact.obstacle, 4);
      final grown = resizeEnd(a, 0, true, 120, stop: contact);
      expect(grown.size.x, 175);
      expect(intersects(grown, bar(4, 175, 0, 0, 5)), false);
      final back = firstContact(a, 0, false, [bar(5, -100, 0, 0, 70)])!;
      near(resizeEnd(a, 0, false, 45, stop: back).corner(1), a.corner(1));
      expect(back.travel, 30);
      expect(firstContact(a, 0, true, [side]), null);
      expect(firstContact(a, 0, true, [bar(6, 100, 0, 0, 30)])!.travel, 0);
    },
  );
  test('Rotated stock has exact contact and volume overlap detection', () {
    final p = Project('Рама', [bar(1, 0, 0, 0, 100), bar(2, 180, 0, 0, 40)]);
    final turned = p.rotate({1, 2}, axis(2), 31);
    final a = turned.byId[1]!, b = turned.byId[2]!;
    final contact = firstContact(a, 0, true, [b])!;
    expect(contact.travel, closeTo(80, 1e-6));
    expect(intersects(resizeEnd(a, 0, true, 80), b), false);
    expect(intersects(resizeEnd(a, 0, true, 80.01), b), true);
  });
  test('Magnetic end alignment needs dwell, holds briefly and releases', () {
    final a = bar(1, 0, 0, 0, 100),
        b = bar(2, 0, 35, 0, 137.25),
        far = bar(3, 0, 1000, 0, 138);
    final targets = alignedEnds(a, 0, true, [b, far], 80);
    expect(targets.any((t) => t.id == 3), false);
    final magnet = EndMagnet();
    expect(magnet.update(36, targets, 5, Duration.zero), null);
    expect(
      magnet.update(38, targets, 5, const Duration(milliseconds: 179)),
      null,
    );
    expect(
      magnet.update(38, targets, 5, const Duration(milliseconds: 180))!.travel,
      37.25,
    );
    expect(
      magnet.update(44, targets, 5, const Duration(milliseconds: 200)),
      isNotNull,
    );
    expect(
      magnet.update(50, targets, 5, const Duration(milliseconds: 210)),
      null,
    );
  });
  test('Face placement rotates a group rigidly and mates opposite normals', () {
    final a = bar(1, 0, 0, 0, 100), b = bar(2, 300, 40, 30, 200);
    final p = Project('', [a, a.copy(id: 3, origin: Vector3(0, 50, 0)), b]);
    final from = Anchor(
      faceCenter(a, 0, true),
      1,
      0,
      Vector3(1, .5, .5),
      'Плоскость',
      1,
    );
    final to = Anchor(
      faceCenter(b, 2, true),
      2,
      0,
      Vector3(.5, .5, 1),
      'Плоскость',
      5,
    );
    final moved = mate(p, {1, 3}, from, to);
    near(from.resolve(moved), to.resolve(moved));
    near(moved.byId[1]!.along, -b.up);
    expect(
      moved.byId[1]!.origin.distanceTo(moved.byId[3]!.origin),
      closeTo(50, 1e-6),
    );
  });
  test(
    'Miter faces coincide and 30° deflection gives a 15° cut and edge lengths',
    () {
      for (final bend in [true, false]) {
        for (final endA in [true, false]) {
          for (final endB in [true, false]) {
            for (final flip in [true, false]) {
              final j = makeJoint(
                bar(1, 0, 0, 0, 500),
                bar(2, 580, 120, 90, 430),
                firstEnd: endA,
                secondEnd: endB,
                inside: 150,
                bendThroughWidth: bend,
                flip: flip,
              );
              expect(j.saw, closeTo(15, 1e-6));
              expect(endAngle(j.fixed, endA), closeTo(15, 1e-6));
              final end1 = j.fixed.corners.indexed
                  .where((n) => n.$1.isOdd == endA)
                  .map((n) => n.$2);
              final end2 = j.moving.corners.indexed
                  .where((n) => n.$1.isOdd == endB)
                  .map((n) => n.$2);
              for (final v in end1) {
                expect(end2.any((x) => x.distanceTo(v) < 1e-6), true);
              }
              expect(intersects(j.fixed, j.moving), false);
              final lengths = edgeLengths(j.fixed)..sort();
              expect(
                lengths.last - lengths.first,
                closeTo((bend ? 30 : 40) * math.tan(math.pi / 12), 1e-6),
              );
            }
          }
        }
      }
      expect(
        makeJoint(
          bar(1, 0, 0, 0, 500),
          bar(2, 0, 0, 0, 500),
          firstEnd: true,
          secondEnd: false,
          inside: 30,
          bendThroughWidth: true,
          flip: false,
        ).saw,
        75,
      );
    },
  );
  test(
    'Groups, dependent dimensions, cuts and units survive a project round trip',
    () {
      final j = makeJoint(
        bar(1, 0, 0, 0, 500),
        bar(2, 350, 0, 0, 310),
        firstEnd: true,
        secondEnd: false,
        inside: 90,
        bendThroughWidth: true,
        flip: false,
      );
      final a = j.fixed.copy(group: 2, locks: 6), b = j.moving.copy(group: 2);
      final d = Dimension(Anchor(a.corner(2), 1, 2), Anchor(b.corner(7), 2, 7));
      final p = Project('Стеллаж', [a, b], [d], LengthUnit.inch);
      final copy = Project.decode(p.encode());
      expect(copy.encode(), p.encode());
      expect(copy.assembly(1), {1, 2});
      expect(copy.dimensions.single.length(copy), closeTo(d.length(p), 1e-7));
      expect(copy.remove({1}).dimensions, isEmpty);
      expect(copy.remove({1}).beams.single.group, null);
      final editor = Editor(copy)..select(1);
      editor.duplicate();
      expect(editor.project.beams, hasLength(4));
      editor.undo();
      expect(editor.project.beams, hasLength(2));
      editor.redo();
      expect(editor.project.beams, hasLength(4));
    },
  );
  test(
    'Arithmetic, project units, configurable increments and no-step mode',
    () {
      expect(calculate('4*10+12'), 52);
      expect(calculate(' (12,5 + 3.5) / 2 '), 8);
      expect(calculate('2*-(-4+1)'), 6);
      for (final input in ['1/0', '2(3)', '9+', '1+alert(1)', '(((((']) {
        expect(calculate(input), isNull);
      }
      expect(LengthUnit.inch.format(12.7), '0.5');
      expect(LengthUnit.centimeter.format(1200), '120');
      final steps = EditStep().change(LengthUnit.centimeter, .25, true);
      expect(steps.round(123.53, LengthUnit.millimeter), 124);
      expect(steps.round(123.53, LengthUnit.centimeter), 122.5);
      final off = EditStep.decode(
        steps.change(LengthUnit.millimeter, .5, false).encode(),
      );
      expect(off.round(123.53, LengthUnit.millimeter), 123.53);
      expect(off.value(LengthUnit.centimeter), .25);
    },
  );
  test(
    'Apron sits flush, centred or at an exact reveal relative to a bench post',
    () {
      final p = Project.bench(),
          rail = p.byId[9]!,
          post = adjacentSupport(p, rail)!;
      expect(post.id, 5);
      final placement = StockPlacement(rail, post, false);
      expect(placement.placed(StockAlignment.front, 0).origin.y, 25);
      expect(placement.placed(StockAlignment.middle, 0).origin.y, 40);
      expect(placement.placed(StockAlignment.back, 0).origin.y, 55);
      expect(placement.placed(StockAlignment.offset, 7.25).origin.y, 32.25);
      expect(
        placement.placed(StockAlignment.offset, 7.25).origin.x,
        rail.origin.x,
      );
    },
  );
  test(
    'Directional stop moves the whole selection to its nearest obstruction',
    () {
      final p = Project('', [
        bar(1, 0, 0, 0, 100),
        bar(2, 25, 40, 0, 100),
        bar(3, 150, 40, 0, 50),
        bar(4, 300, 0, 0, 50),
      ]);
      final c = travelToStop(p, {1, 2}, axis(0))!;
      expect(c.travel, 25);
      expect(c.obstacle, 3);
      final moved = p.move({1, 2}, axis(0) * c.travel);
      expect(travelToStop(moved, {1, 2}, axis(0))!.travel, 0);
      expect(travelToStop(moved, {1, 2}, -axis(0)), null);
      expect(travelToStop(moved, {1, 2}, axis(2)), null);
    },
  );
  test('Shelf clearance tracks facing surfaces through lateral shifts, edits, rotation and reload', () {
    final a = bar(1, 0, 0, 0, 800, width: 280, height: 18),
        b = bar(2, 120, 50, 310, 600, width: 170, height: 25);
    final d = shelfClearance(a, b)!;
    final p = Project('Полки', [a, b], [d]);
    expect(d.length(p), closeTo(292, 1e-7));
    final moved = p.move({2}, Vector3(100, 0, 30));
    expect(d.length(moved), closeTo(322, 1e-7));
    final exact = moved.setDistance(d, 250);
    expect(d.length(exact), closeTo(250, 1e-7));
    expect(exact.byId[2]!.origin.x, moved.byId[2]!.origin.x);
    final rotated = Project.decode(exact.rotate({1, 2}, axis(1), 31).encode());
    expect(rotated.dimensions.single.length(rotated), closeTo(250, 1e-6));
    expect(d.geometry(p.move({2}, Vector3(1000, 0, 0))), null);
  });
  test('Rotation dial only offers the active plane and both directions wrap to zero', () {
    final e = Editor(Project.bench())
      ..select(5)
      ..setTool(Tool.rotate);
    for (var i = 0; i < 3; i++) {
      e.chooseRotationAxis(i);
      final dial = RotationDial.project(
        e.camera,
        const Size(800, 600),
        e.single!.pointAt(Vector3.all(.5)),
        e.rotationBasis[i],
      );
      expect(dial.arrows.map((a) => a.sign), [-1, 1]);
      expect(dial.hit(dial.arrows.first.label), -1);
      expect(dial.hit(dial.arrows.last.label), 1);
      expect(
        (dial.arrows.first.label - dial.arrows.last.label).distance,
        greaterThan(170),
      );
    }
    e.setAngle(-90);
    expect(e.angle, 270);
    e.setAngle(e.angle + 90);
    expect(e.angle, 0);
    e.setAngle(90);
    e.setAngle(e.angle - 90);
    expect(e.angle, 0);
  });
}
