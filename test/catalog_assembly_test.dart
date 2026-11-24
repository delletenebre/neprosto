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
  test('Thirty different source plans cover all difficulty levels', () {
    final plans = FurnitureTemplate.values
        .where((t) => t.source != null)
        .toList();
    expect(plans, hasLength(30));
    expect(plans.map((p) => p.source).toSet(), hasLength(30));
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
      final mm = t.build(LengthUnit.millimeter),
          inches = t.build(LengthUnit.inch);
      expect(inches.beams, hasLength(mm.beams.length));
      for (final b in mm.beams) {
        for (var i = 0; i < 8; i++) {
          expect(
            b.corner(i).distanceTo(inches.byId[b.id]!.corner(i)),
            lessThan(1e-6),
          );
        }
      }
    }
  });

  // A reference cut (finished dimensions) per design detects lost pieces
  // and dimension/axis swaps that an overall bounding box cannot catch.
  test('Each adapted plan retains its characteristic cuts', () {
    const checks = <FurnitureTemplate, (int, double, double, double)>{
      FurnitureTemplate.laptopTray: (1, 362, 286, 19),
      FurnitureTemplate.bagShelf: (1, 457, 140, 19),
      FurnitureTemplate.pantryShelf: (8, 686, 25, 13),
      FurnitureTemplate.diningTable: (5, 1828.8, 139.7, 38.1),
      FurnitureTemplate.consoleTable: (2, 1612.9, 304.8, 19.05),
      FurnitureTemplate.bathTray: (2, 234.95, 38.1, 19.05),
      FurnitureTemplate.machineStand: (4, 882, 90, 40),
      FurnitureTemplate.trestleBench: (1, 1295, 235, 38),
      FurnitureTemplate.windowBox: (19, 160, 30, 20),
      FurnitureTemplate.birdhouse: (
        2,
        147,
        147,
        20,
      ), // Trapezoidal gable panels.
      FurnitureTemplate.candleShelf: (1, 230, 140, 20),
      FurnitureTemplate.stool: (1, 400, 300, 18),
      FurnitureTemplate.blanketLadder: (5, 450, 40, 40),
      FurnitureTemplate.headphoneStand: (1, 273, 65, 20),
      FurnitureTemplate.gardenBench: (
        5,
        1680,
        90,
        40,
      ), // five full-length seat boards, plus back boards
      FurnitureTemplate.plantPanel: (7, 1000, 140, 40),
      FurnitureTemplate.picnicTable: (9, 800, 90, 40),
      FurnitureTemplate.toyChest: (6, 840, 90, 20),
      FurnitureTemplate.standingPlanter: (4, 340, 40, 20),
      FurnitureTemplate.shutters: (45, 270, 90, 20),
      FurnitureTemplate.lantern: (4, 900, 90, 20),
      FurnitureTemplate.workbench: (12, 1524, 101.6, 38.1),
      FurnitureTemplate.toolTote: (2, 267, 140, 19),
      FurnitureTemplate.mirrorFrame: (4, 410, 38, 19),
      FurnitureTemplate.hexShelf: (
        6,
        178,
        184,
        38,
      ), // Length on the inside edge of the mitre.
      FurnitureTemplate.bookcase: (16, 900, 90, 20),
      FurnitureTemplate.coffeeTable: (4, 382, 40, 40),
      FurnitureTemplate.wallShelf: (5, 254, 90, 40),
      FurnitureTemplate.shoeBench: (1, 1000, 312, 18),
      FurnitureTemplate.trivet: (14, 156, 12, 7),
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
        if (t == FurnitureTemplate.gardenBench &&
            b.name == editorStrings.benchBack) {
          return false;
        }
        final cutLength = t == FurnitureTemplate.hexShelf
            ? [
                for (final k in [0, 2, 4, 6])
                  b.corner(k).distanceTo(b.corner(k + 1)),
              ].reduce(math.min)
            : b.size.x;
        return near(cutLength, length) &&
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
          case FurnitureTemplate.shutters:
            expect(sizes, [19, 19, 19]);
            for (final leaf in groups) {
              expect(
                leaf.where(
                  (id) => p.byId[id]!.name == editorStrings.doorPanelInfill,
                ),
                hasLength(15),
              );
            }
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
