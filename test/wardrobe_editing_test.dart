import 'dart:math' as math;

import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoIcons;
import 'package:excel/excel.dart' show Excel;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:neprosto/editor/controller.dart';
import 'package:neprosto/editor/desktop.dart';
import 'package:neprosto/editor/part_type_picker.dart';
import 'package:neprosto/editor/part_finish.dart';
import 'package:neprosto/editor/model.dart';
import 'package:neprosto/editor/step.dart';
import 'package:neprosto/editor/project_templates.dart';
import 'package:neprosto/editor/parts_workbook.dart';
import 'package:neprosto/editor/scene.dart';
import 'package:neprosto/main.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

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
  test('Hinge edge and outside face survive selecting a new type, arbitrary angles and reopening', () {
    for (final verticalLength in [true, false]) {
      for (final fromRear in [false, true]) {
        final upright = panel.copy(
          along: axis(verticalLength ? 2 : 0),
          across: axis(verticalLength ? 0 : 2),
        );
        final viewer = axis(1) * (fromRear ? 1.0 : -1.0);
        for (final hinge in DoorHinge.values) {
          for (final degrees in [42.5, 90.0, 115.0, 180.0]) {
            final closed = upright.withDoorHinge(
              hinge,
              towardEye: viewer,
              screenUp: axis(2),
              angle: degrees,
            );
            final open = Beam.fromJson(closed.swingDoor(1).toJson());
            final stationary = [
              for (var i = 0; i < 8; i++)
                if (open.corner(i).distanceTo(closed.corner(i)) < 1e-7)
                  closed.corner(i),
            ];
            expect(stationary, hasLength(2));
            final bounds = Bounds3.points(closed.corners);
            for (final p in stationary) {
              final expected = switch (hinge) {
                DoorHinge.top => bounds.high.z,
                DoorHinge.bottom => bounds.low.z,
                DoorHinge.left => fromRear ? bounds.high.x : bounds.low.x,
                DoorHinge.right => fromRear ? bounds.low.x : bounds.high.x,
              };
              expect(hinge.onSide ? p.x : p.z, closeTo(expected, 1e-8));
              expect(
                p.y,
                closeTo(fromRear ? bounds.high.y : bounds.low.y, 1e-8),
              );
            }
            expect(
              open.up.dot(closed.up),
              closeTo(math.cos(degrees * math.pi / 180), 1e-8),
            );
            final ordinary = open.withDoorHinge(
              null,
              towardEye: viewer,
              screenUp: axis(2),
            );
            expect(ordinary.hinge, isNull);
            expect(ordinary.doorOpen, isFalse);
            for (var i = 0; i < 8; i++) {
              expect(
                ordinary.corner(i).distanceTo(upright.corner(i)),
                lessThan(1e-7),
              );
            }
            expect(ordinary.name, panel.name);
          }
        }
      }
    }
  });

  test('BAZIS worksheet keeps millimetres, individual materials, names and positions in a grouped row', () {
    final a = panel.copy(
      finish: FinishPreset.oakBoard.finish,
      startCut: (y: 12, z: 0),
    );
    final b = a.copy(
      id: 2,
      name: 'Полка',
      finish: FinishPreset.whiteBoard.finish,
    );
    final excel = Excel.decodeBytes(
      encodeBazisCutList([
        StockRow([a, b]),
      ]),
    );
    expect(excel.tables.keys, ['Панели']);
    final rows = excel['Панели'].rows;
    expect(rows, hasLength(3));
    expect(rows.first.map((v) => v!.value.toString()), [
      'Позиция',
      'Наименование',
      'Материал',
      'Толщина',
      'Длина',
      'Ширина',
      'Кол-во',
    ]);
    expect(rows[1][0]!.value.toString(), '1');
    expect(rows[2][1]!.value.toString(), 'Полка');
    expect(rows[1][2]!.value.toString(), isNot(rows[2][2]!.value.toString()));
    expect(double.parse(rows[1][4]!.value.toString()), 406);
    expect(rows[2][6]!.value.toString(), '1');
  });

  testWidgets(
    'Edit door settings under the name and show a leading icon only for doors',
    (t) async {
      await t.binding.setSurfaceSize(const Size(1320, 900));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final e = Editor(Project('Проект', [panel]))..select(panel.id);
      await t.pumpWidget(NeprostoApp(editor: e));
      await t.pumpAndSettle();

      Future<void> editName() async {
        final action = find.byTooltip('Переименовать деталь');
        final title = find.descendant(
          of: action,
          matching: find.text(panel.name),
        );
        final pencil = find.descendant(
          of: action,
          matching: find.byIcon(CupertinoIcons.pencil),
        );
        expect(
          t.getRect(pencil).left - t.getRect(title).right,
          closeTo(controlGap, .1),
        );
        expect(t.getCenter(pencil).dy, closeTo(t.getCenter(title).dy, .1));
        await t.tap(title);
        await t.pumpAndSettle();
        expect(find.text('Название детали'), findsOneWidget);
        expect(
          t.getTopLeft(find.byType(PartTypePicker)).dy,
          greaterThan(
            t.getBottomLeft(find.byKey(const ValueKey('rename-field'))).dy,
          ),
        );
      }

      Future<void> choose(String label) async {
        final button = find.descendant(
          of: find.byType(PartTypePicker),
          matching: find.text(label),
        );
        await t.tap(button);
        await t.pumpAndSettle();
      }

      expect(find.byType(PartTypePicker), findsNothing);
      expect(find.byType(DoorIcon), findsNothing);
      await editName();
      final diagram = find.byKey(const ValueKey('hinge-diagram'));
      expect(diagram, findsNothing);
      await choose('Дверца');
      expect(find.text('Петли слева'), findsOneWidget);
      final face = t.getRect(diagram);
      for (final (point, label) in [
        (face.centerRight - const Offset(16, 0), 'Петли справа'),
        (face.bottomCenter - const Offset(0, 16), 'Петли снизу'),
        (face.centerLeft + const Offset(16, 0), 'Петли слева'),
        (face.topCenter + const Offset(0, 16), 'Петли сверху'),
      ]) {
        await t.tapAt(point);
        await t.pumpAndSettle();
        expect(find.text(label), findsOneWidget);
      }
      await choose('Обычная деталь');
      expect(diagram, findsNothing);
      await choose('Дверца');
      expect(find.text('Петли сверху'), findsOneWidget);
      final field = find.descendant(
        of: find.byKey(const ValueKey('dialog-door-angle')),
        matching: find.byType(EditableText),
      );
      await t.enterText(field, '181');
      await t.pump();
      final done = find.widgetWithText(DeskButton, 'Готово');
      expect(t.widget<DeskButton>(done).onPressed, isNull);
      await t.enterText(field, '115');
      await t.pump();
      expect(e.single!.hinge, isNull);
      await t.tap(done);
      await t.pumpAndSettle();
      expect(e.single!.hinge, DoorHinge.top);
      expect(e.single!.openingAngle, 115);
      expect(find.byType(PartTypePicker), findsNothing);
      expect(find.text('Угол открывания'), findsNothing);
      final icons = find.byType(DoorIcon);
      expect(icons, findsWidgets);
      for (final element in icons.evaluate()) {
        final icon = find.byWidget(element.widget);
        expect(
          find.descendant(
            of: icon,
            matching: find.byIcon(PhosphorIconsRegular.door),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(of: icon, matching: find.byType(RotatedBox)),
          findsNothing,
        );
        final row = find.ancestor(of: icon, matching: find.byType(Row)).first;
        final name = find
            .descendant(of: row, matching: find.text(panel.name))
            .first;
        expect(
          t.getTopRight(icon).dx,
          lessThanOrEqualTo(t.getTopLeft(name).dx),
        );
      }
      await t.tap(find.text('Открыть дверцу'));
      await t.pumpAndSettle();
      expect(e.single!.doorOpen, isTrue);
      await editName();
      expect(find.text('Петли сверху'), findsOneWidget);
      await choose('Обычная деталь');
      await t.tap(find.text('Отмена'));
      await t.pumpAndSettle();
      expect(e.single!.hinge, DoorHinge.top);
      await editName();
      await choose('Обычная деталь');
      await t.tap(done);
      await t.pumpAndSettle();
      expect(e.single!.hinge, isNull);
      expect(e.single!.doorOpen, isFalse);
      expect(find.byType(DoorIcon), findsNothing);
      expect(find.text('Открыть дверцу'), findsNothing);
      e.undo();
      expect(e.single!.doorOpen, isTrue);
    },
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
    'Double click edits properties; buttons swing the door and edit its drill layout',
    (t) async {
      await t.binding.setSurfaceSize(const Size(1320, 900));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final e = Editor(wardrobe.copy(unit: LengthUnit.centimeter))
        ..step = EditStep(values: {LengthUnit.centimeter: .1});
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
      expect(e.single!.doorOpen, isFalse);
      expect(find.byKey(const ValueKey('part-dialog-name')), findsOneWidget);
      expect(find.byType(PartTypePicker), findsNothing);
      Future<void> tap(String text) async {
        final target = find.text(text).last;
        await t.ensureVisible(target);
        await t.tap(target);
        await t.pumpAndSettle();
      }

      final x = find.descendant(
        of: find.byKey(const ValueKey('dialog-position-0')),
        matching: find.byType(EditableText),
      );
      expect(
        t.widget<EditableText>(x).controller.text,
        e.lengthInput.format(door.origin.x),
      );
      await t.enterText(x, '1,2');
      await tap('Применить');
      expect(e.single!.origin, Vector3(12, door.origin.y, door.origin.z));
      expect(e.single!.hinge, door.hinge);
      e.undo();
      await t.pumpAndSettle();
      expect(e.single, same(door));
      await tap('Открыть дверцу');
      expect(e.single!.doorOpen, isTrue);
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
      expect(find.text('Вперёд · К вам'), findsOneWidget);
      await tap('Под петлю Ø35 мм');
      expect(
        t.widget<Text>(find.byKey(const ValueKey('hole-view-face'))).data,
        'Сторона Б',
      );
      expect(find.text('Вперёд · От вас'), findsOneWidget);
      await t.tap(find.text('Сторона А').hitTestable());
      await t.pump();
      await t.pump(const Duration(milliseconds: 70));
      expect(t.hasRunningAnimations, isTrue);
      await t.pumpAndSettle();
      await tap('Сторона Б');
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
      await tap('Под петлю Ø35 мм');
      await tap('Сторона А');
      final diagram = t.getRect(find.byKey(const ValueKey('hole-diagram')));
      await t.tapAt(diagram.center + const Offset(8, 20));
      await t.pumpAndSettle();
      await tap('Применить');
      final saved = e.single!;
      expect(saved.holes, hasLength(3));
      expect(saved.holes.last.back, isFalse);
      expect(saved.holes.last.x, isNot(120));
      expect(saved.holes.take(2), [
        door.holes.single,
        const PanelHole(120, 22, 35, depth: 12, back: true),
      ]);
      await tap('Отверстия');
      await t.tap(find.byTooltip('Удалить').hitTestable().last);
      await t.pumpAndSettle();
      await tap('Отмена');
      expect(e.single, same(saved));
      await tap('Отверстия');
      await t.tap(find.byTooltip('Удалить').hitTestable().last);
      await t.pumpAndSettle();
      await tap('Применить');
      expect(e.single!.holes, saved.holes.skip(1));
      e.undo();
      expect(e.single, same(saved));
    },
  );
}
