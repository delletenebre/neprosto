import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/widgets.dart' show ListView, Scrollable;
import 'package:flutter/foundation.dart' show TargetPlatform;
import 'package:flutter_test/flutter_test.dart';
import 'package:neprosto/editor/contact.dart';
import 'package:neprosto/editor/controller.dart';
import 'package:neprosto/editor/desktop.dart' show DeskDialog;
import 'package:neprosto/editor/drawing.dart';
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
        for (final template in [FurnitureTemplate.raisedBed]) {
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

  test('The far picnic seat draws and picks in front of its support from either end', () async {
    const size = Size(800, 600);
    final project = FurnitureTemplate.picnicTable.build(LengthUnit.millimeter);
    final seats =
        project.beams
            .where(
              (b) =>
                  b.name == editorStrings.seatSlat(1) ||
                  b.name == editorStrings.seatSlat(2),
            )
            .toList()
          ..sort((a, b) => a.origin.y.compareTo(b.origin.y));

    Future<int> pixel(Scene scene, Offset at) async {
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder)
        ..translate(-at.dx.floorToDouble(), -at.dy.floorToDouble());
      DrawingPainter(
        scene: scene,
        selection: const {},
        dimensions: false,
        dimensionsVisible: false,
      ).paint(canvas, size);
      final picture = recorder.endRecording();
      final image = await picture.toImage(1, 1);
      final data = await image.toByteData();
      image.dispose();
      picture.dispose();
      return data!.getUint32(0);
    }

    for (final reverse in [false, true]) {
      final camera = Camera();
      if (reverse) camera.yaw += math.pi;
      camera.fit(project, size);
      final scene = Scene(project, camera, size);
      final seat = seats[reverse ? 1 : 2];
      final local = reverse ? Vector3(.98, .2, 1) : Vector3(.02, .65, 1);
      final point = camera.project(seat.pointAt(local), size);
      expect(scene.hit(point)?.beam.id, seat.id);
      final isolated = Scene(Project('', [seat]), camera, size);
      expect(await pixel(scene, point), await pixel(isolated, point));
    }
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
      expect(find.text(editorStrings.templateHoodCabinet), findsWidgets);
      expect(find.text(editorStrings.assembleHoodCabinet), findsOneWidget);
      Future<void> openGarden() async {
        final category = find.text(editorStrings.categoryGarden);
        await t.scrollUntilVisible(
          category,
          100,
          scrollable: find
              .descendant(
                of: find.byType(ListView).last,
                matching: find.byType(Scrollable),
              )
              .first,
        );
        await tap(category);
      }

      await openGarden();
      await tap(find.text(editorStrings.bench).last);
      expect(
        find.descendant(
          of: find.byType(DeskDialog),
          matching: find.text('Деталей · 12'),
        ),
        findsOneWidget,
      );
      expect(find.text('1200 × 360 × 450 мм'), findsOneWidget);
      expect(find.text('Миллиметры'), findsNothing);
      expect(find.text('Дюймы'), findsNothing);
      await tap(find.text('Отмена'));
      await tap(find.text('Шаг 1 мм'));
      await tap(find.text('Дюймы'));
      await tap(find.text('Готово'));
      await chooseTemplate();
      await openGarden();
      expect(find.textContaining('59 × 29 × 22 ″'), findsOneWidget);
      expect(find.text(editorStrings.planSource), findsNothing);
      expect(find.text(editorStrings.planAdaptation), findsNothing);
      expect(find.text(editorStrings.stockShopping), findsNothing);
      expect(find.text(editorStrings.cuttingLayout), findsNothing);
      await tap(find.text('Создать проект'));
      final created = tabs.value;
      expect(created.committed.name, editorStrings.templateRaisedBed);
      expect(created.committed.unit, LengthUnit.inch);
      expect(created.committed.beams, isNotEmpty);
      expect(
        (created.committed.workspaceSize! - Vector3(59, 29, 22) * 25.4).length,
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
      tabs.select(original);
      await t.pumpAndSettle();
      expect(original.editor.displayUnit, LengthUnit.inch);
      expect(original.committed.unit, LengthUnit.millimeter);
      expect(original.dirty, isFalse);
      expect(find.text('Шаг 1/16″'), findsOneWidget);
    },
    variant: TargetPlatformVariant({
      TargetPlatform.macOS,
      TargetPlatform.windows,
    }),
  );
}
