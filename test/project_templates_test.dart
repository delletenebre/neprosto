import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart' show TargetPlatform;
import 'package:flutter_test/flutter_test.dart';
import 'package:neprosto/editor/contact.dart';
import 'package:neprosto/editor/controller.dart';
import 'package:neprosto/editor/model.dart';
import 'package:neprosto/editor/part_finish.dart';
import 'package:neprosto/editor/parts_workbook.dart' show blankLength;
import 'package:neprosto/editor/project_tabs.dart';
import 'package:neprosto/editor/project_templates.dart';
import 'package:neprosto/editor/scene.dart';
import 'package:neprosto/editor/template_stock.dart';
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
          expect(project.overlaps, isEmpty);
          expect(Project.decode(project.encode()).toJson(), project.toJson());
          final placed = <int>{};
          for (final blank in templateStock(project)) {
            final previous = <Rect>[];
            for (final MapEntry(key: id, value: cut) in blank.cuts.entries) {
              final part = project.byId[id]!;
              expect(placed.add(id), isTrue);
              expect(part.finish.texture, template.material.finish.texture);
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

  test(
    'Bench slats share a retail board and small parts fit a project panel',
    () {
      final bench = FurnitureTemplate.gardenBench.build(LengthUnit.millimeter);
      final slats = bench.beams.take(4);
      final used = templateStock(
        bench,
      ).where((blank) => slats.any((slat) => blank.cuts.containsKey(slat.id)));
      expect(used, hasLength(2));
      for (final board in used) {
        expect(board.size.width, 3000);
        expect(board.cuts.length, 2);
        expect(board.requiredSize.width, 1490 * 2 + 3);
      }
      final shelf = FurnitureTemplate.wallShelf.build(LengthUnit.millimeter);
      expect(templateStock(shelf).single.size, const Size(760, 760));
    },
  );

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

      final newButton = find.byTooltip('Новый проект');
      await tap(newButton);
      expect(find.text('Фирменная тумба neprosto'), findsWidgets);
      await tap(find.text('Сад и дача'));
      await tap(find.text('Дюймы'));

      expect(find.textContaining('47.5 × 18 × 33.5 ″'), findsOneWidget);
      expect(find.text('Материалы для покупки'), findsOneWidget);
      await tap(find.text('Схема раскроя'));
      expect(find.text('Схема раскроя · Садовая скамья'), findsOneWidget);
      expect(find.textContaining('#1  Планка сиденья 1'), findsOneWidget);
      await tap(find.text('Закрыть'));
      await tap(find.text('Создать проект'));
      final created = tabs.value;
      expect(created.committed.name, 'Садовая скамья');
      expect(created.committed.unit, LengthUnit.inch);
      expect(created.committed.beams, isNotEmpty);
      expect(created.dirty, isTrue);
      expect(created.editor.canUndo, isFalse);
      expect(tabs.items.first, same(original));
      await tap(newButton);
      await tap(find.text('Отмена'));
      expect(tabs.value, same(created));
      expect(tabs.items, hasLength(2));
      await tap(newButton);
      await tap(find.text('Пустой проект'));
      expect(tabs.value.committed.unit, LengthUnit.inch);
      expect(tabs.value.committed.beams, isEmpty);
    },
    variant: TargetPlatformVariant({
      TargetPlatform.macOS,
      TargetPlatform.windows,
    }),
  );
}
