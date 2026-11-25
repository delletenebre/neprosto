import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:neprosto/editor/model.dart';
import 'package:neprosto/editor/project_templates.dart';
import 'package:neprosto/l10n/strings.dart';

// The editor's clearance ruler clips opposing face polygons. Only contact
// across an area counts: meeting at a single corner cannot attach a rail.
List<Set<int>> assemblies(Project p) {
  final remaining = p.byId.keys.toSet();
  final boxes = {for (final b in p.beams) b.id: Bounds3.points(b.corners)};
  bool touches(int i, int j) {
    final a = boxes[i]!, b = boxes[j]!;
    for (var dim = 0; dim < 3; dim++) {
      if (math.max(a.low[dim], b.low[dim]) >
          math.min(a.high[dim], b.high[dim]) + 1e-6) {
        return false;
      }
    }
    final gap = shelfClearance(p.byId[i]!, p.byId[j]!);
    return gap != null && gap.length(p) < 1e-5;
  }

  final components = <Set<int>>[];
  while (remaining.isNotEmpty) {
    final queue = [remaining.first];
    remaining.remove(queue.first);
    for (var i = 0; i < queue.length; i++) {
      final next = remaining.where((j) => touches(queue[i], j)).toList();
      queue.addAll(next);
      remaining.removeAll(next);
    }
    components.add(queue.toSet());
  }
  return components;
}

void main() {
  test('Each category lists its examples with distinct assembly notes', () {
    final plans = FurnitureTemplate.values
        .where((t) => t.source != null)
        .toList();
    for (final category in TemplateCategory.values) {
      final templates = FurnitureTemplate.values.where(
        (t) => t.category == category,
      );
      expect(
        templates.length,
        switch (category) {
          TemplateCategory.garden => equals(9),
          TemplateCategory.bathroom => equals(2),
          _ => inInclusiveRange(3, 4),
        },
      );
      expect(
        templates.map((t) => t.assemblyNote).toSet(),
        hasLength(templates.length),
      );
      expect(templates.every((t) => t.assemblyNote.isNotEmpty), isTrue);
    }
    expect(plans.map((p) => p.source).toSet(), hasLength(plans.length));
    expect(
      plans.map((p) => p.difficulty).toSet(),
      PlanDifficulty.values.toSet(),
    );
    for (final t in plans) {
      final uri = Uri.parse(t.source!);
      expect(uri.scheme, 'https');
      expect([
        'pochertezhu.ru',
        'saw-man.ru',
        'novamett.ru',
      ], contains(uri.host));
    }
  });

  test('Every template has native dimensions in both systems', () {
    for (final t in FurnitureTemplate.values) {
      final metric = t.build(LengthUnit.millimeter);
      expect(
        t.build(LengthUnit.centimeter).beams.map((b) => b.toJson()),
        metric.beams.map((b) => b.toJson()),
        reason: t.name,
      );
      for (final u in [LengthUnit.millimeter, LengthUnit.inch]) {
        final p = u == LengthUnit.inch ? t.build(u) : metric;
        final bounds = p.partBounds!,
            size = (bounds.high - bounds.low) / u.factor;
        for (final extent in size.storage) {
          expect(
            extent,
            closeTo(extent.round(), 1e-6),
            reason: '${t.name} ${u.name} extent',
          );
        }
        for (final b in p.beams) {
          final squareCut =
              !b.bevelled &&
              [
                b.along,
                b.across,
              ].every((axis) => axis.storage.any((v) => v.abs() > 1 - 1e-8));
          for (final length in [if (squareCut) b.size.x, b.size.y, b.size.z]) {
            final ticks = u == LengthUnit.inch
                ? length / u.factor * 16
                : length;
            expect(
              ticks,
              closeTo(ticks.round(), 1e-6),
              reason: '${t.name} ${u.name}: ${b.name}',
            );
          }
        }
      }
    }
  });

  for (final unit in [LengthUnit.millimeter, LengthUnit.inch]) {
    test(
      'The duct clears both panels, the chase and the storage bays in ${unit.name}',
      () {
        final p = FurnitureTemplate.hoodCabinet.build(unit);
        final ports = p.beams
            .where(
              (b) => b.holes.any((h) => h.name == editorStrings.ductOpening),
            )
            .toList();
        expect(ports.map((b) => b.name).toSet(), {
          editorStrings.bottomPanel,
          editorStrings.topPanel,
        });
        Vector3 center(Beam b) {
          final hole = b.holes.single;
          expect(hole.fits(b.size), isTrue);
          expect(hole.depth, isNull);
          return b.origin +
              b.along * hole.centerX(b.size) +
              b.across * hole.centerY(b.size);
        }

        final lower = center(ports.first), upper = center(ports.last);
        expect(upper.x, closeTo(lower.x, 1e-6));
        expect(upper.y, closeTo(lower.y, 1e-6));
        final diameter = unit == LengthUnit.inch ? 6.25 * 25.4 : 160;
        for (final b in ports) {
          expect(b.holes.single.diameter, closeTo(diameter, 1e-6));
        }
        for (final b in p.beams.where((b) => !ports.contains(b))) {
          final bounds = Bounds3.points(b.corners);
          final dx = lower.x - lower.x.clamp(bounds.low.x, bounds.high.x);
          final dy = lower.y - lower.y.clamp(bounds.low.y, bounds.high.y);
          expect(
            dx * dx + dy * dy,
            greaterThan(diameter * diameter / 4),
            reason: b.name,
          );
        }
        expect(
          p.beams.where((b) => b.name == editorStrings.chaseSide),
          hasLength(2),
        );
        expect(
          p.beams.where((b) => b.name == editorStrings.chaseCover),
          hasLength(1),
        );
        expect(
          p.beams.where((b) => b.name == editorStrings.shelfPart),
          hasLength(2),
        );
        final doors = p.beams.where((b) => b.hinge != null);
        expect(doors.map((b) => b.hinge).toSet(), {
          DoorHinge.left,
          DoorHinge.right,
        });
        for (final door in doors) {
          expect(door.holes, hasLength(2));
          expect(
            door.holes.every(
              (hole) => hole.back && hole.depth != null && hole.fits(door.size),
            ),
            isTrue,
          );
        }
      },
    );

    test(
      'The rim mitres meet and the toy chest has solid timber at the lid hinge in ${unit.name}',
      () {
        final bed = FurnitureTemplate.raisedBed.build(unit);
        final rim = bed.beams
            .where((b) => b.name == editorStrings.bedRim)
            .toList();
        expect(rim, hasLength(4));
        for (final (i, b) in rim.indexed) {
          expect(b.startCut.y, b.size.y);
          expect(b.endCut.y, -b.size.y);
          final next = rim[(i + 1) % 4];
          for (final k in faceCorners[1]) {
            expect(
              faceCorners[0].any(
                (j) => b.corner(k).distanceTo(next.corner(j)) < 1e-6,
              ),
              isTrue,
            );
          }
        }
        final p = FurnitureTemplate.toyChest.build(unit);
        final back = p.partBounds!.high.y;
        final lid = p.beams.lastWhere(
          (b) => b.group != null && b.name == editorStrings.topPanel,
        );
        final rail = p.beams.lastWhere(
          (b) => b.group == null && b.name == editorStrings.frontPanel,
        );
        final lidBounds = Bounds3.points(lid.corners),
            railBounds = Bounds3.points(rail.corners);
        expect(lidBounds.high.y, closeTo(back, 1e-6));
        expect(railBounds.high.y, closeTo(back, 1e-6));
        expect(railBounds.high.z, closeTo(lidBounds.low.z, 1e-6));
        expect(railBounds.low.x, greaterThanOrEqualTo(lidBounds.low.x));
        expect(railBounds.high.x, lessThanOrEqualTo(lidBounds.high.x));
      },
    );
  }

  // A reference cut (finished dimensions) per design detects lost pieces
  // and dimension/axis swaps that an overall bounding box cannot catch.
  test('Each adapted plan retains its characteristic cuts', () {
    const checks = <FurnitureTemplate, (int, double, double, double)>{
      FurnitureTemplate.pantryShelf: (8, 686, 25, 13),
      FurnitureTemplate.diningTable: (5, 1800, 140, 40),
      FurnitureTemplate.consoleTable: (2, 1614, 300, 18),
      FurnitureTemplate.machineStand: (4, 882, 90, 40),
      FurnitureTemplate.birdhouse: (
        2,
        147,
        147,
        20,
      ), // Trapezoidal gable panels.
      FurnitureTemplate.blanketLadder: (5, 450, 40, 40),
      FurnitureTemplate.picnicTable: (9, 800, 90, 40),
      FurnitureTemplate.toyChest: (6, 840, 90, 20),
      FurnitureTemplate.workbench: (12, 1500, 100, 38),
      FurnitureTemplate.mirrorFrame: (4, 410, 38, 19),
      FurnitureTemplate.bookcase: (16, 900, 90, 20),
      FurnitureTemplate.coffeeTable: (4, 382, 40, 40),
      FurnitureTemplate.wallShelf: (5, 254, 90, 40),
      FurnitureTemplate.shoeBench: (1, 1000, 312, 18),
    };
    expect(
      checks.keys.toSet(),
      FurnitureTemplate.values.where((t) => t.source != null).toSet(),
    );
    for (final entry in checks.entries) {
      final t = entry.key, p = t.build(LengthUnit.millimeter);
      final (count, length, width, thickness) = entry.value;
      bool near(double a, double b) => (a - b).abs() < 1e-6;
      final matches = p.beams.where((b) {
        if (t == FurnitureTemplate.birdhouse) {
          return b.name == editorStrings.sidePanel &&
              b.bevelled &&
              near(Bounds3.points(b.corners).high.z, length) &&
              near(b.size.y, width) &&
              near(b.size.z, thickness);
        }
        return near(b.size.x, length) &&
            near(b.size.y, width) &&
            near(b.size.z, thickness);
      });
      expect(matches, hasLength(count), reason: t.name);
    }
  });

  for (final t in FurnitureTemplate.values) {
    for (final u in [LengthUnit.millimeter, LengthUnit.inch]) {
      test('${t.name} in ${u.name} has connected assemblies', () {
        final p = t.build(u);
        final groups = assemblies(p);
        final sizes = groups.map((g) => g.length).toList()..sort();
        // Hinges and drawer slides are purchased hardware, excluded from the
        // cutting list. Check each moving wooden assembly independently.
        switch (t) {
          case FurnitureTemplate.signatureCabinet:
            expect(sizes, [1, p.beams.length - 1]);
            final door = groups.singleWhere((g) => g.length == 1).single;
            expect(p.byId[door]!.bore, isNotNull);
          case FurnitureTemplate.bedroomWardrobe:
            expect(sizes, [1, 1, 1, p.beams.length - 3]);
            final doors =
                groups
                    .where((g) => g.length == 1)
                    .map((g) => p.byId[g.single]!)
                    .toList()
                  ..sort((a, b) => a.origin.x.compareTo(b.origin.x));
            expect(doors.map((b) => b.name), [
              editorStrings.leftHingedDoor,
              editorStrings.rightHingedDoor,
              editorStrings.rightHingedDoor,
            ]);
            for (final (index, door) in doors.indexed) {
              final bounds = Bounds3.points(door.corners);
              expect(bounds.low.y, closeTo(0, 1e-6));
              expect(door.size, doors.first.size);
              final pull = door.bore!;
              final center = door.pointAt(Vector3(pull.u, pull.v, 0));
              expect(center.x > bounds.center.x, index == 0);
              if (index > 0) {
                final previous = Bounds3.points(doors[index - 1].corners);
                expect(bounds.low.x, greaterThan(previous.high.x));
              }
            }
          case FurnitureTemplate.drawerChest:
            expect(sizes, [5, 5, 5, 5, 5]);
            final drawers = groups.where(
              (g) =>
                  g.any((id) => p.byId[id]!.name == editorStrings.drawerFront),
            );
            expect(drawers, hasLength(4));
            for (final drawer in drawers) {
              expect(
                drawer.where(
                  (id) => p.byId[id]!.name == editorStrings.sidePanel,
                ),
                hasLength(2),
              );
            }
          case FurnitureTemplate.hoodCabinet:
            expect(sizes, [1, 1, p.beams.length - 2]);
          default:
            expect(
              groups,
              hasLength(1),
              reason: groups
                  .map(
                    (ids) => ids.map((i) => '$i ${p.byId[i]!.name}').join(', '),
                  )
                  .join(' / '),
            );
        }
      });
    }
  }
}
