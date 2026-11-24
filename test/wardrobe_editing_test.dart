import 'package:excel/excel.dart' show Excel;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:neprosto/editor/controller.dart';
import 'package:neprosto/editor/desktop.dart';
import 'package:neprosto/editor/model.dart';
import 'package:neprosto/editor/project_templates.dart';
import 'package:neprosto/editor/parts_workbook.dart';
import 'package:neprosto/editor/scene.dart';
import 'package:neprosto/main.dart';

void main() {
  final wardrobe = FurnitureTemplate.bedroomWardrobe.build(
    LengthUnit.millimeter,
  );
  final doors = wardrobe.beams.where((b) => b.hinge != null).toList();

  test(
    'Each wardrobe leaf swings out on its own hinge and reopens from disk',
    () {
      expect(doors.length, 3);
      final e = Editor(wardrobe);
      for (final door in doors) {
        final before = e.project;
        final hinge = door.hinge == DoorHinge.left ? 0 : 2;
        e.toggleDoor(door.id);
        final opened = e.project.byId[door.id]!;
        final halfway = door.swingDoor(.5);
        expect(
          halfway.corner(hinge).distanceTo(door.corner(hinge)),
          lessThan(1e-8),
        );
        expect(halfway.across.dot(door.across), closeTo(.70710678, 1e-6));
        for (final other in before.beams.where((b) => b.id != door.id)) {
          expect(e.project.byId[other.id], same(other));
        }
        for (final end in [hinge, hinge | 1]) {
          expect(
            opened.corner(end).distanceTo(door.corner(end)),
            lessThan(1e-8),
          );
        }
        expect(opened.corner(hinge ^ 2).y, lessThan(-door.size.y + 1e-7));
        expect(opened.across.dot(door.across).abs(), lessThan(1e-8));
      }
      expect(e.overlaps, isEmpty);
      final loaded = Editor(Project.decode(e.project.encode()));
      for (final door in doors) {
        expect(loaded.project.byId[door.id]!.doorOpen, isTrue);
        loaded.toggleDoor(door.id);
        final closed = loaded.project.byId[door.id]!;
        expect(closed.origin.distanceTo(door.origin), lessThan(1e-8));
        expect(closed.across, door.across);
        expect(closed.holes, door.holes);
      }
      loaded.undo();
      expect(loaded.project.byId[doors.last.id]!.doorOpen, isTrue);
    },
  );

  test('Legacy wardrobe door and finger pull are editable after reopening', () {
    final b = doors.first;
    final old = b.toJson()
      ..remove('holes')
      ..remove('hinge');
    old['bore'] = [.45, .75, 32];
    final loaded = Beam.fromJson(old);
    expect(loaded.hinge, DoorHinge.left);
    expect(loaded.holes.single.x, closeTo(.45 * b.size.x, 1e-6));
    expect(loaded.holes.single.y, closeTo(.75 * b.size.y, 1e-6));
    expect(loaded.copy(holes: []).holes, isEmpty);
    expect(Beam.fromJson({...old, 'name': 'Panel'}).hinge, isNull);
  });

  final panel = Beam(
    1,
    'Фасад',
    Vector3.zero(),
    Vector3(400, 200, 18),
    axis(0),
    axis(1),
  );
  test('All through holes reveal the interior and blind holes have a floor on the drilled face', () {
    final part = panel.copy(
      holes: const [
        PanelHole(40, 25, 20),
        PanelHole(40, 25, 20, fromEnd: true),
        PanelHole(80, 40, 35, depth: 12, back: true, fromFarEdge: true),
      ],
    );
    expect(Beam.fromJson(part.toJson()).holes, part.holes);
    const size = Size(640, 480);
    final doc = Project('', [part]);
    for (final view in [ViewAngle.top, ViewAngle.bottom]) {
      final cam = Camera()
        ..view(view)
        ..fit(doc, size);
      final scene = Scene(doc, cam, size);
      Offset at(double x, double y) => cam.project(Vector3(x, y, 0), size);
      expect(scene.hit(at(40, 25)), isNull);
      expect(scene.hit(at(360, 25)), isNull);
      final face = scene.hit(at(80, 160))!;
      expect(
        face.boreFloor?.contains(at(80, 160)) ?? false,
        view == ViewAngle.top,
      );
    }
    final book = Excel.decodeBytes(
      encodePartsWorkbook(LengthUnit.centimeter, [
        StockRow([part]),
      ]),
    );
    for (final sheet in book.tables.values) {
      expect(sheet.rows.first.last!.value.toString(), 'Отверстия (см)');
      final drillList = sheet.rows[1].last!.value.toString().split('\n');
      expect(drillList, hasLength(3));
      expect(drillList.last, contains('Ø3.5'));
      expect(drillList.last, contains('Глубина 1.2'));
    }
    final resized = part.copy(size: Vector3(450, 250, 18));
    expect(resized.holes[1].centerX(resized.size), 410);
    expect(resized.holes[2].centerY(resized.size), 210);
  });

  testWidgets(
    'Open a leaf in 3D, close it from properties and edit its drill layout',
    (t) async {
      await t.binding.setSurfaceSize(const Size(1320, 900));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final e = Editor(wardrobe.copy(unit: LengthUnit.centimeter));
      await t.pumpWidget(NeprostoApp(editor: e));
      await t.pumpAndSettle();
      e.setView(ViewAngle.front);
      await t.pumpAndSettle();
      final drawing = find.byKey(const Key('drawing')), door = doors.first;
      final at =
          t.getTopLeft(drawing) +
          e.camera.project(
            door.pointAt(Vector3(.5, .5, 0)),
            t.getSize(drawing),
          );
      await t.tapAt(at);
      await t.pump(const Duration(milliseconds: 60));
      await t.tapAt(at);
      await t.pumpAndSettle();
      expect(e.single!.doorOpen, isTrue);
      Future<void> tap(String text) async {
        final target = find.text(text).last;
        await t.ensureVisible(target);
        await t.tap(target);
        await t.pumpAndSettle();
      }

      await tap('Закрыть дверцу');
      expect(e.single!.doorOpen, isFalse);
      Future<void> input(String key, String text) async {
        await t.enterText(
          find.descendant(
            of: find.byKey(ValueKey(key)),
            matching: find.byType(EditableText),
          ),
          text,
        );
        await t.pump();
      }

      await tap('Отверстия');
      await tap('Под петлю Ø35 мм');
      await input('hole-horizontal', '2,2');
      await input('hole-vertical', '10+2');
      await input('hole-depth', '2');
      expect(
        t
            .widget<DeskButton>(
              find.widgetWithText(DeskButton, 'Применить').last,
            )
            .onPressed,
        isNull,
      );
      await input('hole-depth', '1,2');
      await tap('Применить');
      final saved = e.single!;
      expect(saved.holes, [
        door.holes.single,
        const PanelHole(120, 22, 35, depth: 12, back: true),
      ]);
      await tap('Отверстия');
      await tap('Удалить');
      await tap('Отмена');
      expect(e.single, same(saved));
      await tap('Отверстия');
      await tap('Удалить');
      await tap('Применить');
      expect(e.single!.holes, [saved.holes.last]);
      e.undo();
      expect(e.single, same(saved));
    },
  );
}
