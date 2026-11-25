import 'dart:ui' show Tristate;

import 'package:excel/excel.dart' show Excel;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:neprosto/editor/contact.dart';
import 'package:neprosto/editor/controller.dart';
import 'package:neprosto/editor/desktop.dart';
import 'package:neprosto/editor/model.dart';
import 'package:neprosto/editor/parts_workbook.dart';
import 'package:neprosto/editor/scene.dart';
import 'package:neprosto/editor/step.dart';
import 'package:neprosto/l10n/strings.dart';
import 'package:neprosto/main.dart';

void main() {
  final blank = Beam(
    1,
    'Полка',
    Vector3.zero(),
    Vector3(120, 40, 20),
    axis(0),
    axis(1),
  );
  final part = blank.copy(rabbets: {RabbetEdge.topLeft: (width: 12, depth: 8)});

  testWidgets(
    'Inspector machining badges count the operations on the selected part',
    (t) async {
      await t.binding.setSurfaceSize(const Size(1320, 880));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final editor = Editor(Project('', [blank]))..select(blank.id);
      await t.pumpWidget(NeprostoApp(editor: editor));
      await t.pumpAndSettle();

      void checkCounts(int ends, int rabbets, int holes) {
        for (final (title, count) in [
          (editorStrings.endCutsTitle, ends),
          (editorStrings.rabbetTitle, rabbets),
          (editorStrings.panelHoles, holes),
        ]) {
          final button = find.widgetWithText(DeskButton, title);
          expect(button, findsOneWidget);
          final badge = find.descendant(
            of: button,
            matching: find.byType(Badge),
          );
          if (count == 0) {
            expect(badge, findsNothing);
          } else {
            expect(
              find.descendant(of: badge, matching: find.text('$count')),
              findsOneWidget,
            );
          }
        }
        expect(find.text(editorStrings.endMarkings), findsNothing);
      }

      checkCounts(0, 0, 0);
      editor.commit(
        editor.project.edit(
          {blank.id},
          (b) => b.copy(
            startCut: (y: 5, z: -3),
            rabbets: const {
              RabbetEdge.topLeft: (width: 5, depth: 2),
              RabbetEdge.bottomRight: (width: 6, depth: 3),
            },
            holes: const [
              PanelHole(20, 20, 3),
              PanelHole(40, 20, 3),
              PanelHole(60, 20, 3),
            ],
          ),
        ),
      );
      await t.pump();
      checkCounts(1, 2, 3);
      editor.commit(
        editor.project.edit({blank.id}, (b) => b.copy(endCut: (y: 0, z: -4))),
      );
      await t.pump();
      checkCounts(2, 2, 3);
      editor.undo();
      await t.pump();
      checkCounts(1, 2, 3);
      editor.undo();
      await t.pump();
      checkCounts(0, 0, 0);
    },
  );

  test('Cut profile drives picking, snaps, clearance and contact', () {
    final stock = Project('', [part]);
    final cam = Camera()
      ..view(ViewAngle.right)
      ..scale = 4;
    const size = Size(400, 300);
    final end = Scene(stock, cam, size);
    Offset at(double y, double z) => cam.project(Vector3(120, y, z), size);
    expect(end.hit(at(6, 15)), isNull);
    expect(end.hit(at(6, 5))?.face, 1);
    expect(
      end.snap(at(12, 12), mode: SnapMode.corner, radius: 1)?.local,
      Vector3(1, .3, .6),
    );
    expect(end.snap(at(0, 20), mode: SnapMode.corner, radius: 1), isNull);
    cam.view(ViewAngle.top);
    final floor = Scene(
      stock,
      cam,
      size,
    ).hit(cam.project(Vector3(60, 6, 12), size))!;
    expect(floor.world.every((p) => p.z == 12), isTrue);
    final insert = blank.copy(
      id: 2,
      size: Vector3(100, 10, 8),
      origin: Vector3(0, 0, 15),
    );
    expect(intersects(part, insert), isFalse);
    expect(intersects(part, insert.copy(origin: Vector3(1, 1, 11))), isTrue);
    expect(firstContact(insert, 2, false, [part])!.travel, closeTo(3, 1e-8));
    final project = Project('', [part, insert]);
    expect(travelToStop(project, {2}, -axis(2))!.travel, closeTo(3, 1e-8));
    expect(shelfClearance(insert, part)!.length(project), closeTo(3, 1e-8));
  });

  test('All four cuts survive mitres, resize, save and workbook export', () {
    final cuts = {
      for (final edge in RabbetEdge.values) edge: (width: 12.0, depth: 4.0),
    };
    final board = part.copy(
      rabbets: cuts,
      startCut: (y: 12, z: -5),
      endCut: (y: -6, z: 4),
    );
    expect(board.sectionOutline, hasLength(12));
    expect(board.profileFaces.length, 14);
    expect(board.cutsFit, isTrue);
    final restored = Project.decode(Project('', [board]).encode()).beams.single;
    expect(restored.rabbets, cuts);
    expect(restored.startCut, board.startCut);
    for (final strip in restored.solidStrips()) {
      for (var i = 0; i < 8; i++) {
        expect(
          board.localAt(strip.corner(i)).x,
          closeTo((i & 1).toDouble(), 1e-10),
        );
      }
    }
    final resized = resizeEnd(board, 1, true, -1000);
    expect(resized.size.y, greaterThan(24));
    expect(resized.cutsFit, isTrue);
    expect(board.copy(size: Vector3(120, 24, 20)).cutsFit, isFalse);
    expect(board.copy(size: Vector3(120, 40, 8)).cutsFit, isFalse);
    expect(Beam.fromJson(blank.toJson()).rabbets, isEmpty);
    expect(
      () => Beam.fromJson({
        ...blank.toJson(),
        'rabbets': {
          'topLeft': [12, 20],
        },
      }),
      throwsFormatException,
    );
    expect(
      () => Beam.fromJson({
        ...blank.toJson(),
        'rabbets': {
          'unknown': [1, 1],
        },
      }),
      throwsFormatException,
    );
    final book = Excel.decodeBytes(
      encodePartsWorkbook(LengthUnit.centimeter, [
        StockRow([board]),
      ]),
    );
    for (final sheet in book.tables.values) {
      expect(sheet.rows[0].last!.value.toString(), 'Выборка фальца');
      expect(
        sheet.rows[1].last!.value.toString(),
        contains('Верхнее левое · 1.2 × 0.4 см'),
      );
    }
  });

  testWidgets(
    'Edit multiple rabbets in project units, cancel, apply, undo and remove',
    (t) async {
      await t.binding.setSurfaceSize(const Size(1320, 880));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final shelf = blank.copy(size: Vector3(1200, 600, 20));
      final e = Editor(Project('', [shelf], [], LengthUnit.centimeter))
        ..step = EditStep(values: {LengthUnit.centimeter: .1})
        ..select(shelf.id, individual: true);
      await t.pumpWidget(NeprostoApp(editor: e));
      await t.pumpAndSettle();
      final dialog = find.byType(DeskDialog);
      final fields = find.descendant(
        of: dialog,
        matching: find.byType(EditableText),
      );
      Future<void> open() async {
        final button = find.text('Выборка фальца');
        await t.ensureVisible(button);
        await t.tap(button.hitTestable());
        await t.pumpAndSettle();
      }

      Future<void> action(String label) async {
        await t.tap(
          find.descendant(of: dialog, matching: find.text(label)).hitTestable(),
        );
        await t.pumpAndSettle();
      }

      Future<void> enter(int i, String text) async {
        await t.enterText(fields.at(i), text);
        await t.pump();
      }

      bool getEnabled() =>
          t
              .widget<DeskButton>(
                find.widgetWithText(DeskButton, 'Применить').last,
              )
              .onPressed !=
          null;

      await open();
      final diagram = t.getRect(find.byKey(const ValueKey('rabbet-section')));
      expect(diagram.height, lessThanOrEqualTo(56));
      for (final edge in RabbetEdge.values) {
        final marker = find.bySemanticsLabel(edge.label);
        expect(find.text(edge.label), findsNothing);
        final bounds = t.getRect(marker);
        expect(bounds.center.dx > diagram.center.dx, edge.right);
        expect(bounds.center.dy < diagram.center.dy, edge.top);
        await t.tap(marker);
        await t.pumpAndSettle();
        expect(
          t.getSemantics(marker).flagsCollection.isSelected,
          Tristate.isTrue,
        );
      }
      await enter(0, '1,2');
      expect(getEnabled(), isFalse);
      await enter(1, '2');
      expect(getEnabled(), isFalse);
      await enter(1, '0,8');
      expect(getEnabled(), isTrue);
      await action('Отмена');
      expect(e.single, same(shelf));
      await open();
      await enter(0, '1,2');
      await enter(1, '0,8');
      await t.tapAt(Offset.lerp(diagram.center, diagram.bottomRight, .5)!);
      await t.pumpAndSettle();
      await enter(0, '1/2');
      await enter(1, '0,5');
      await action('Применить');
      expect(e.single!.rabbets, {
        RabbetEdge.topLeft: (width: 12, depth: 8),
        RabbetEdge.bottomRight: (width: 5, depth: 5),
      });
      e.undo();
      expect(e.single, same(shelf));
      e.redo();
      await t.pumpAndSettle();
      await open();
      await t.tap(find.bySemanticsLabel('Верхнее левое'));
      await t.pumpAndSettle();
      await action('Убрать фальц');
      await action('Применить');
      expect(e.single!.rabbets.keys, [RabbetEdge.bottomRight]);
    },
    variant: TargetPlatformVariant({
      TargetPlatform.macOS,
      TargetPlatform.windows,
    }),
  );
}
