import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/widgets.dart' show ListView, Scrollable;
import 'package:flutter/foundation.dart' show TargetPlatform;
import 'package:flutter_test/flutter_test.dart';
import 'package:neprosto/editor/contact.dart';
import 'package:neprosto/editor/controller.dart';
import 'package:neprosto/editor/desktop.dart' show DeskDialog;
import 'package:neprosto/editor/model.dart';
import 'package:neprosto/editor/part_finish.dart';
import 'package:neprosto/editor/parts_workbook.dart' show blankLength;
import 'package:neprosto/editor/project_tabs.dart';
import 'package:neprosto/editor/project_templates.dart';
import 'package:neprosto/editor/scene.dart';
import 'package:neprosto/editor/template_stock.dart';
import 'package:neprosto/l10n/strings.dart';
import 'package:neprosto/main.dart';

void main() {
  for (final template in FurnitureTemplate.values) {
    for (final unit in [LengthUnit.millimeter, LengthUnit.inch]) {
      test(
        '${template.name} in ${unit.name} assembles and fits purchased stock',
        () {
          final project = template.build(unit), kerf = templateKerf(unit);
          final bounds = project.partBounds!;
          final advertised = unit == LengthUnit.inch
              ? template.imperial
              : template.metric;
          final size =
              Vector3(advertised.$1, advertised.$2, advertised.$3) *
              unit.factor;
          expect(bounds.low.length, closeTo(0, .00001));
          expect((bounds.high - size).length, closeTo(0, .00001));
          expect(
            project.beams.map((b) => b.finish.texture),
            contains(template.material.finish.texture),
          );
          expect(
            project.overlaps.map((id) => '$id ${project.byId[id]!.name}'),
            isEmpty,
          );
          expect(Project.decode(project.encode()).toJson(), project.toJson());
          final placed = <int>{};
          for (final blank in templateStock(project)) {
            final previous = <Rect>[];
            for (final MapEntry(key: id, value: cut) in blank.cuts.entries) {
              final part = project.byId[id]!;
              expect(placed.add(id), isTrue);
              expect(
                part.finish.texture,
                project.byId[blank.cuts.keys.first]!.finish.texture,
              );
              expect(blank.thickness, part.size.z);
              expect(cut.left, greaterThanOrEqualTo(0));
              expect(cut.top, greaterThanOrEqualTo(0));
              expect(cut.right, lessThanOrEqualTo(blank.size.width + .00001));
              expect(cut.bottom, lessThanOrEqualTo(blank.size.height + .00001));
              final quarterTurn =
                  (cut.width - blankLength(part)).abs() > .00001;
              if (quarterTurn) {
                expect([
                  PartTexture.mdf,
                  PartTexture.laminate,
                ], contains(part.finish.texture));
              }
              expect(
                cut.width,
                closeTo(quarterTurn ? part.size.y : blankLength(part), .00001),
              );
              expect(
                cut.height,
                closeTo(quarterTurn ? blankLength(part) : part.size.y, .00001),
              );
              for (final other in previous) {
                final dx = math.max(
                  cut.left - other.right,
                  other.left - cut.right,
                );
                final dy = math.max(
                  cut.top - other.bottom,
                  other.top - cut.bottom,
                );
                expect(math.max(dx, dy), greaterThanOrEqualTo(kerf - .00001));
              }
              previous.add(cut);
            }
          }
          expect(placed, project.byId.keys.toSet());
        },
      );
    }
  }

  for (final unit in [LengthUnit.millimeter, LengthUnit.inch]) {
    test(
      'Gazebo ring supports the open gable roof and keeps the entrance clear in ${unit.name}',
      () {
        final doc = FurnitureTemplate.gazebo.build(unit),
            bounds = doc.partBounds!;
        final ring = doc.beams.where(
          (b) => b.name == editorStrings.gazeboRingBeam,
        );
        final roofParts = {
          editorStrings.roofRafter,
          editorStrings.roofTie,
          editorStrings.roofBatten,
        };
        expect(
          doc.beams.where((b) => b.name == editorStrings.roofBoard),
          isEmpty,
        );
        expect(ring, hasLength(4));
        final plate = Bounds3.points(ring.first.corners).high.z;
        final underside = Bounds3.points(ring.first.corners).low.z;
        final posts = doc.beams
            .where((b) => b.name == editorStrings.uprightPost)
            .map((p) => Bounds3.points(p.corners))
            .where((p) => (p.high.z - underside).abs() < 1e-6)
            .toList();
        expect(posts, hasLength(4));
        bool spans(double a0, double a1, double b0, double b1) =>
            math.min(a1, b1) - math.max(a0, b0) > 1e-6;
        for (final beam in doc.beams) {
          final b = Bounds3.points(beam.corners);
          if (ring.contains(beam)) {
            expect(b.high.z, closeTo(plate, 1e-6));
            expect(b.low.z, closeTo(underside, 1e-6));
            expect(
              posts.where(
                (p) =>
                    spans(p.low.x, p.high.x, b.low.x, b.high.x) &&
                    spans(p.low.y, p.high.y, b.low.y, b.high.y),
              ),
              hasLength(2),
            );
          } else if (roofParts.contains(beam.name)) {
            expect(b.low.z, greaterThanOrEqualTo(plate - 1e-6));
          } else {
            expect(b.high.z, lessThanOrEqualTo(underside + 1e-6));
          }
        }
        final frontPosts = posts.where((p) => p.low.y.abs() < 1e-6).toList()
          ..sort((a, b) => a.low.x.compareTo(b.low.x));
        expect(frontPosts, hasLength(2));
        for (final beam in doc.beams.where(
          (b) => !ring.contains(b) && !roofParts.contains(b.name),
        )) {
          final b = Bounds3.points(beam.corners);
          expect(
            spans(b.low.y, b.high.y, 0, frontPosts.first.high.y) &&
                spans(
                  b.low.x,
                  b.high.x,
                  frontPosts.first.high.x,
                  frontPosts.last.low.x,
                ),
            isFalse,
          );
        }
        final ties = doc.beams.where((b) => b.name == editorStrings.roofTie);
        final rafters = doc.beams.where(
          (b) => b.name == editorStrings.roofRafter,
        );
        final battens = doc.beams.where(
          (b) => b.name == editorStrings.roofBatten,
        );
        expect(ties, hasLength(5));
        expect(rafters, hasLength(10));
        expect(battens, hasLength(8));
        for (final tie in ties) {
          final t = Bounds3.points(tie.corners);
          expect(t.low.z, closeTo(plate, 1e-6));
          final pair = rafters
              .where(
                (r) =>
                    (r.pointAt(Vector3(0, .5, .5)).y - t.center.y).abs() < 1e-6,
              )
              .toList();
          expect(pair, hasLength(2));
          for (final r in pair) {
            for (final k in faceCorners[0]) {
              final heel = r.corner(k);
              expect(heel.z, closeTo(t.high.z, 1e-6));
              expect(heel.x, inInclusiveRange(t.low.x - 1e-6, t.high.x + 1e-6));
              expect(heel.y, inInclusiveRange(t.low.y - 1e-6, t.high.y + 1e-6));
            }
          }
          for (final k in faceCorners[1]) {
            expect(
              faceCorners[1].any(
                (j) =>
                    pair.first.corner(k).distanceTo(pair.last.corner(j)) < 1e-6,
              ),
              isTrue,
            );
          }
          for (final batten in battens) {
            final supported = pair.any(
              (r) => [0.0, 1.0].every((edge) {
                final p = r.localAt(
                  batten.pointAt(Vector3(t.center.y / bounds.high.y, edge, 0)),
                );
                return p.x >= -1e-6 &&
                    p.x <= 1 + 1e-6 &&
                    (p.z - .5).abs() < 1e-6 &&
                    math.min(p.y.abs(), (1 - p.y).abs()) < 1e-6;
              }),
            );
            expect(
              supported,
              isTrue,
              reason: 'batten ${batten.id}, tie ${tie.id}',
            );
          }
        }
        expect(
          doc.beams.where((b) => b.name == editorStrings.benchBack),
          isNotEmpty,
        );
        expect(
          doc.beams.where((b) => b.name == editorStrings.seatSlat(1)),
          hasLength(1),
        );
      },
    );

    test(
      'Sawhorse feet, cap, aprons and ties have bearing faces in ${unit.name}',
      () {
        final project = FurnitureTemplate.sawhorse.build(unit);
        final strings = editorStrings;
        Beam named(String name) =>
            project.beams.singleWhere((b) => b.name == name);
        final cap = named(strings.topPanel);
        const tolerance = 1e-7;
        final inside = inInclusiveRange(-tolerance, 1 + tolerance);
        for (var i = 0; i < 4; i++) {
          final leg = named(strings.leg(i + 1));
          final apron = named(strings.sideRail(i % 2 + 1));
          final tie = named(strings.crossRail(i ~/ 2 + 1));
          for (final k in faceCorners[0]) {
            expect(leg.corner(k).z, closeTo(0, tolerance));
          }
          for (final k in faceCorners[1]) {
            final contact = cap.localAt(leg.corner(k));
            expect(contact.z, closeTo(0, tolerance));
            expect(contact.x, inside);
            expect(contact.y, inside);
          }
          // A rectangular patch of each leg's outer face meets its apron.
          for (final height in [.87, .96]) {
            for (final width in [.1, .9]) {
              final p = apron.localAt(leg.pointAt(Vector3(height, width, 1)));
              expect(p.z, closeTo(0, tolerance));
              expect(p.x, inside);
              expect(p.y, inside);
            }
          }
          final joint = leg.localAt(
            tie.pointAt(Vector3(i.isEven ? .05 : .95, .5, i < 2 ? 1 : 0)),
          );
          expect(joint.x, inside);
          expect(joint.z, inside);
          expect(
            math.min(joint.y.abs(), (1 - joint.y).abs()),
            lessThan(tolerance),
          );
        }
      },
    );

    test(
      'Each planter wall course covers two inside corner posts in ${unit.name}',
      () {
        for (final template in [
          FurnitureTemplate.raisedBed,
          FurnitureTemplate.trellisPlanter,
        ]) {
          final project = template.build(unit);
          final extent = project.partBounds!.high;
          final walls = project.beams.where(
            (b) => b.name == editorStrings.planterWall,
          );
          final posts = project.beams
              .where((b) => b.name == editorStrings.uprightPost)
              .map((p) => Bounds3.points(p.corners))
              .toList();
          expect(walls, isNotEmpty);
          for (final wall in walls) {
            final bounds = Bounds3.points(wall.corners);
            final along = wall.along.x.abs() > .5 ? 0 : 1, across = 1 - along;
            final near = bounds.center[across] < extent[across] / 2;
            final face = near ? bounds.high[across] : bounds.low[across];
            for (final end in [false, true]) {
              final matches = posts.where((post) {
                final postFace = near ? post.low[across] : post.high[across];
                final cornerEdge = end
                    ? extent[along] - post.high[along]
                    : post.low[along];
                return (cornerEdge - wall.size.z).abs() < 1e-6 &&
                    (face - postFace).abs() < 1e-6 &&
                    bounds.low[along] <= post.low[along] + 1e-6 &&
                    bounds.high[along] >= post.high[along] - 1e-6 &&
                    bounds.low.z >= post.low.z - 1e-6 &&
                    bounds.high.z <= post.high.z + 1e-6;
              });
              expect(
                matches,
                hasLength(1),
                reason: '${template.name}, board ${wall.id}',
              );
            }
          }
        }
      },
    );
  }

  test('The four shelf decks pack on retail boards and floating shelf skins on plywood', () {
    final rack = FurnitureTemplate.bookcase.build(LengthUnit.millimeter);
    final planks = rack.beams.where((p) => p.name == editorStrings.shelfPart);
    final boards = templateStock(rack)
        .where((blank) => planks.any((p) => blank.cuts.containsKey(p.id)));
    expect(planks, hasLength(16));
    expect(boards.expand((b) => b.cuts.keys), hasLength(16));
    expect(boards.any((b) => b.cuts.length > 1), isTrue);
    final shelf = FurnitureTemplate.wallShelf.build(LengthUnit.millimeter);
    final skins = templateStock(shelf).where((b) => b.thickness == 6);
    expect(skins, hasLength(1));
    expect(skins.single.cuts, hasLength(5));
  });

  test('Signature cabinet retains its colours and drilled finger pull when reopened', () {
    final p = Project.decode(
      FurnitureTemplate.signatureCabinet.build(LengthUnit.millimeter).encode(),
    );
    final door = p.beams.singleWhere((part) => part.bore != null);
    final bore = door.bore!;
    expect(bore.diameter, 32);
    expect(
      p.beams.map((part) => part.finish.rgb).toSet(),
      containsAll([0xc3dcf1, 0x42577a, 0xe4f187]),
    );
    const viewport = Size(800, 600);
    final camera = Camera()
      ..view(ViewAngle.front)
      ..fit(p, viewport);
    final scene = Scene(p, camera, viewport);
    final centre = door.pointAt(Vector3(bore.u, bore.v, 1));
    expect(
      scene.hit(camera.project(centre, viewport))?.beam.finish.rgb,
      0x42577a,
    );
    expect(
      scene
          .hit(camera.project(centre - door.along * bore.diameter, viewport))
          ?.beam
          .id,
      door.id,
    );
  });

  testWidgets(
    'Create an inch template, reopen the picker, cancel or start blank',
    (t) async {
      await t.binding.setSurfaceSize(const Size(1080, 760));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final tabs = ProjectTabs(Editor(Project.bench()));
      final original = tabs.value;
      await t.pumpWidget(NeprostoApp.withTabs(tabs));
      await t.pumpAndSettle();
      Future<void> tap(Finder f) async {
        await t.ensureVisible(f);
        await t.tap(f);
        await t.pumpAndSettle();
      }

      Future<void> chooseTemplate() async {
        await tap(find.byTooltip('Новая вкладка'));
        await tap(find.text('Создать проект'));
      }

      await chooseTemplate();
      expect(find.text('Фирменная тумба neprosto'), findsWidgets);
      await tap(find.text('Табуреты и скамьи'));
      expect(
        find.descendant(
          of: find.byType(DeskDialog),
          matching: find.text('Деталей · 12'),
        ),
        findsOneWidget,
      );
      expect(find.text('1200 × 360 × 450 мм'), findsOneWidget);
      await t.scrollUntilVisible(
        find.text('Сад и дача'),
        100,
        scrollable: find
            .descendant(
              of: find.byType(ListView).last,
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tap(find.text('Сад и дача'));
      await tap(find.text('Дюймы'));

      expect(
        find.textContaining('66.14173 × 27.55906 × 37.00787 ″'),
        findsOneWidget,
      );
      expect(find.text(editorStrings.planSource), findsNothing);
      expect(find.text(editorStrings.planAdaptation), findsNothing);
      expect(find.text(editorStrings.stockShopping), findsNothing);
      expect(find.text(editorStrings.cuttingLayout), findsNothing);
      await tap(find.text('Создать проект'));
      final created = tabs.value;
      expect(created.committed.name, 'Садовая скамья с подлокотниками');
      expect(created.committed.unit, LengthUnit.inch);
      expect(created.committed.beams, isNotEmpty);
      expect(
        (created.committed.workspaceSize! - Vector3(1680, 700, 940)).length,
        closeTo(0, .00001),
      );
      expect(created.dirty, isTrue);
      expect(created.editor.canUndo, isFalse);
      expect(tabs.items.first, same(original));
      await chooseTemplate();
      await tap(find.text('Отмена'));
      expect(tabs.value, same(created));
      expect(tabs.items, hasLength(2));
      await chooseTemplate();
      await tap(find.text('Пустой проект'));
      expect(tabs.value.committed.unit, LengthUnit.inch);
      expect(tabs.value.committed.beams, isEmpty);
      expect(tabs.value.committed.workspaceSize, Vector3(3000, 3000, 2500));
    },
    variant: TargetPlatformVariant({
      TargetPlatform.macOS,
      TargetPlatform.windows,
    }),
  );
}
