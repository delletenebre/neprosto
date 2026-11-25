import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:neprosto/editor/controller.dart';
import 'package:neprosto/editor/desktop.dart';
import 'package:neprosto/editor/joint.dart';
import 'package:neprosto/editor/model.dart';
import 'package:neprosto/editor/parts_workbook.dart';
import 'package:neprosto/editor/project_templates.dart';
import 'package:neprosto/editor/scene.dart';
import 'package:neprosto/editor/step.dart';
import 'package:neprosto/editor/table_saw_preview.dart';
import 'package:neprosto/main.dart';

void main() {
  test('Compound markings and saw settings describe the same cut plane', () {
    final part = Project.bench().beams.first.copy(
      size: Vector3(300, 40, 20),
      endCut: (y: markingOffset(45, 40)!, z: markingOffset(-45, 20)!),
    );
    final saw = sawAngles(part, true);
    expect(saw.miter, closeTo(-45, 1e-10));
    expect(saw.bevel, closeTo(-35.26438968, 1e-8));
    final m = saw.miter * math.pi / 180, b = saw.bevel * math.pi / 180;
    final normal =
        (part.along * math.cos(m) + part.across * math.sin(m)) * math.cos(b) -
        part.up * math.sin(b);
    expect(normal.distanceTo(part.faceNormal(1)), lessThan(1e-10));
    expect(stockCut(part, true), '45° +Ш · 45° −Т');
    for (final v in [90.0, -90.0, 100.0, double.nan, double.infinity]) {
      expect(markingOffset(v, 20), isNull);
    }
    expect(markingOffset(89.999999, 1000), isNull);
  });

  testWidgets('The end face context menu makes a new cut on a square beam', (
    t,
  ) async {
    await t.binding.setSurfaceSize(const Size(1320, 880));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final beam = Beam(
      1,
      'Брус',
      Vector3.zero(),
      Vector3(250, 80, 40),
      axis(0),
      axis(1),
    );
    final editor = Editor(Project('Торцы', [beam]))
      ..step = EditStep(anglePrecision: AnglePrecision.hundredth)
      ..setView(ViewAngle.right);
    await t.pumpWidget(NeprostoApp(editor: editor));
    await t.pumpAndSettle();
    final drawing = find.byKey(const Key('drawing'));
    final point = editor.camera.project(
      beam.pointAt(Vector3(1, .5, .5)),
      t.getSize(drawing),
    );
    final gesture = await t.startGesture(
      t.getTopLeft(drawing) + point,
      kind: PointerDeviceKind.mouse,
      buttons: kSecondaryMouseButton,
    );
    await gesture.up();
    await t.pumpAndSettle();
    await t.tap(
      find.descendant(
        of: find.byType(PopupMenuItem<int>),
        matching: find.text('Торцевые срезы'),
      ),
    );
    await t.pumpAndSettle();
    final dialog = find.byType(DeskDialog);
    Finder readout(String text) =>
        find.descendant(of: dialog, matching: find.text(text));
    expect(readout('Поворот стола'), findsOneWidget);
    expect(readout('Наклон диска'), findsOneWidget);
    expect(readout('0°'), findsNWidgets(2));
    expect(
      t
          .widget<DeskSegments<bool>>(
            find.descendant(
              of: dialog,
              matching: find.byType(DeskSegments<bool>),
            ),
          )
          .value,
      isTrue,
    );
    await t.enterText(
      find.descendant(of: dialog, matching: find.byType(EditableText)).first,
      '-45',
    );
    await t.pump();
    expect(readout('45° вправо'), findsOneWidget);
    expect(readout('0°'), findsOneWidget);
    final tilt = find
        .descendant(of: dialog, matching: find.byType(EditableText))
        .last;
    await t.enterText(tilt, '45');
    await t.pump();
    expect(readout('35,26° вправо'), findsOneWidget);
    final width = find
        .descendant(of: dialog, matching: find.byType(EditableText))
        .first;
    await t.enterText(width, '45');
    await t.enterText(tilt, '-45');
    await t.pump();
    expect(readout('45° влево'), findsOneWidget);
    expect(readout('35,26° влево'), findsOneWidget);
    for (final (tool, title, setup, view) in [
      (
        'Ручная циркулярная',
        'Линия пропила',
        '45° вправо',
        'Сзади пилы по ходу реза',
      ),
      (
        'Пильный стол',
        'Поперечный упор',
        '45° · правый край от себя',
        'В разрезе',
      ),
      (
        'Торцовочная пила',
        'Поворот стола',
        '45° влево',
        'От рукоятки вдоль реза',
      ),
    ]) {
      await t.tap(readout(tool));
      await t.pumpAndSettle();
      expect(readout(title), findsOneWidget);
      expect(readout(setup), findsOneWidget);
      expect(readout(view), findsOneWidget);
      if (tool == 'Пильный стол') {
        expect(readout('Диск'), findsOneWidget);
        expect(readout('Упор'), findsOneWidget);
        expect(readout('Сверху · передний край внизу'), findsOneWidget);
      }
      expect(readout('35,26° влево'), findsOneWidget);
      expect(editor.canUndo, isFalse);
    }
    await t.enterText(width, '65');
    await t.pump();
    expect(readout('65° влево'), findsOneWidget);
    expect(readout('Угол за пределами показанной шкалы'), findsNothing);
    await t.enterText(width, '0');
    await t.tap(readout('Пильный стол'));
    await t.pumpAndSettle();
    final disc = find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is TableSawPreview,
    );
    TableSawPreview preview() =>
        t.widget<CustomPaint>(disc).painter! as TableSawPreview;
    expect(preview().cutaway, isTrue);
    for (final angle in [45.28, -45.28, 0.0, -66.8014]) {
      await t.enterText(tilt, angle.toString());
      await t.pump();
      expect(
        preview().angle,
        closeTo(editor.step.anglePrecision.round(angle), 1e-8),
      );
      expect(readout('Угол за пределами показанной шкалы'), findsNothing);
    }
    final previousAngle = preview().angle;
    await t.tap(readout('Со стороны подачи'));
    await t.pumpAndSettle();
    expect(preview().cutaway, isFalse);
    expect(preview().angle, previousAngle);
    await t.enterText(width, '-45');
    await t.enterText(tilt, '0');
    await t.pump();
    await t.tap(find.descendant(of: dialog, matching: find.text('Применить')));
    await t.pumpAndSettle();
    expect(editor.single!.startCut, beam.startCut);
    expect(editor.single!.endCut.y, closeTo(-80, 1e-10));
    expect(editor.single!.endCut.z, 0);
  }, variant: TargetPlatformVariant.only(TargetPlatform.windows));

  testWidgets(
    'Edit both cuts of the template rail, cancel, apply and undo',
    (t) async {
      await t.binding.setSurfaceSize(const Size(1320, 880));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final project = FurnitureTemplate.porch.build(LengthUnit.inch);
      final rail = project.beams.firstWhere(
        (b) => b.name.startsWith('Поручень') && b.bevelled,
      );
      final editor = Editor(project)..select(rail.id, individual: true);
      await t.pumpWidget(NeprostoApp(editor: editor));
      await t.pumpAndSettle();
      final dialog = find.byType(DeskDialog);
      Finder inside(Finder f) => find.descendant(of: dialog, matching: f);
      final inputs = inside(find.byType(EditableText));
      Future<void> tap(Finder f) async {
        await t.tap(f.hitTestable());
        await t.pumpAndSettle();
      }

      Future<void> open() async {
        final button = find.text('Торцевые срезы');
        await t.ensureVisible(button);
        await tap(button);
      }

      Future<void> enter(int i, String value) async {
        await t.enterText(inputs.at(i), value);
        await t.pump();
      }

      Future<void> action(String label) => tap(inside(find.text(label)));
      String field(int i) =>
          t.widget<EditableText>(inputs.at(i)).controller.text;
      bool canApply() =>
          t
              .widget<DeskButton>(
                inside(find.widgetWithText(DeskButton, 'Применить')),
              )
              .onPressed !=
          null;

      await open();
      final originalThickness = field(1);
      expect(double.parse(originalThickness).abs(), greaterThan(0));
      expect(inside(find.textContaining('″')), findsNWidgets(2));
      await action('Применить');
      expect(editor.canUndo, isFalse);
      await open();
      for (final (formula, result) in [
        ('(5+2)*2', '14'),
        ('5+2*2', '9'),
        ('5+2 *2', '14'),
        ('5 + 2 * 2', '9'),
        ('5+ 2*2', '9'),
      ]) {
        await enter(0, formula);
        await t.sendKeyEvent(LogicalKeyboardKey.enter);
        await t.pump();
        expect(field(0), result);
      }
      await t.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await t.pump();
      expect(field(0), '9.1');
      await enter(1, '0');
      await t.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await t.pump();
      expect(field(1), '-0.1');
      await enter(0, '15,5');
      await action('Конец');
      expect(field(0), '0');
      await action('Прямой торец');
      expect(field(1), '0');
      await action('Начало');
      expect(field(0), '15,5');
      await action('Отмена');
      expect(editor.single, same(rail));
      expect(editor.canUndo, isFalse);

      await open();
      for (final invalid in ['', '-', 'ошибка', '1/0', '-90', '95']) {
        await enter(0, invalid);
        expect(canApply(), isTrue);
        expect(inside(find.text('Смещение 0 ″')), findsOneWidget);
        expect(field(1), originalThickness);
      }
      await enter(0, '89.9');
      expect(inside(find.textContaining('Срезы пересекаются')), findsOneWidget);
      expect(canApply(), isFalse);
      await enter(0, '31/2');
      expect(canApply(), isTrue);
      await action('Конец');
      await enter(1, '');
      expect(inside(find.text('Смещение 0 ″')), findsNWidgets(2));
      await enter(0, '45+');
      expect(canApply(), isTrue);
      await action('Применить');
      final edited = editor.single!;
      expect(
        markingAngle(edited.startCut.y, edited.size.y),
        closeTo(15.5, 1e-10),
      );
      expect(edited.startCut.z, rail.startCut.z);
      expect(edited.endCut, (y: 0, z: 0));
      expect(
        Project.decode(editor.project.encode()).byId[rail.id]!.startCut,
        edited.startCut,
      );
      editor.undo();
      expect(editor.single, same(rail));
      expect(editor.canUndo, isFalse);
      editor.redo();
      expect(editor.single, same(edited));
    },
    variant: TargetPlatformVariant({
      TargetPlatform.macOS,
      TargetPlatform.windows,
    }),
  );
}
