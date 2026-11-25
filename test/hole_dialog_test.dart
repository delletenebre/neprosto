import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:neprosto/editor/controller.dart';
import 'package:neprosto/editor/desktop.dart';
import 'package:neprosto/editor/hole_dialog.dart';
import 'package:neprosto/editor/model.dart';
import 'package:neprosto/editor/palette.dart';
import 'package:neprosto/editor/step.dart';

void main() {
  testWidgets(
    'Invalid holes remain selectable and each row shows its own warning',
    (t) async {
      final board = Beam(
        1,
        'Планка',
        Vector3.zero(),
        Vector3(600, 160, 12),
        axis(0),
        axis(1),
        holes: const [
          PanelHole(300, 80, 5),
          PanelHole(90, 80, 35, depth: 8, back: true),
        ],
      );
      final editor = Editor(Project('', [board]));
      await t.binding.setSurfaceSize(const Size(1100, 800));
      addTearDown(() => t.binding.setSurfaceSize(null));
      await t.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showPanelHoles(context, editor, board),
              child: const Text('Открыть'),
            ),
          ),
        ),
      );
      Future<void> tap(Finder finder) async {
        await t.tap(finder);
        await t.pumpAndSettle();
      }

      Future<void> edit(String field, String text) async {
        await t.enterText(
          find.descendant(
            of: find.byKey(ValueKey('hole-$field')),
            matching: find.byType(EditableText),
          ),
          text,
        );
        await t.pumpAndSettle();
      }

      Finder number(int i) => find.byKey(ValueKey('hole-number-$i'));
      final warnings = find.descendant(
        of: find.byType(ListView),
        matching: find.byIcon(Icons.warning_amber_rounded),
      );
      final apply = find.widgetWithText(DeskButton, 'Применить');
      final diagram = find.byKey(const ValueKey('hole-diagram'));

      await tap(find.text('Открыть'));
      await tap(number(2));
      final originalPosition = t.getCenter(number(2));
      await edit('depth', '12');
      expect(t.getCenter(number(2)), originalPosition);
      expect(t.widget<Icon>(warnings).color, EditorPalette.light.danger);
      expect(t.widget<DeskButton>(apply).onPressed, isNull);
      await edit('depth', '');
      expect(t.getCenter(number(2)), originalPosition);
      await edit('horizontal', '150');
      final editedPosition = t.getCenter(number(2));
      expect(editedPosition, isNot(originalPosition));
      await edit('horizontal', '2+');
      await edit('diameter', '');
      expect(t.getCenter(number(2)), editedPosition);
      await edit('horizontal', '9000');
      expect(t.getRect(diagram).contains(t.getCenter(number(2))), isTrue);
      await tap(number(1));
      await edit('diameter', '0');
      expect(warnings, findsNWidgets(2));
      expect(number(1), findsOneWidget);
      await tap(number(2));
      await tap(find.text('Показать номера на схеме'));
      await tap(diagram); // Pick the invalid first hole at the panel centre.
      expect(find.byKey(const ValueKey('hole-depth')), findsNothing);
      await edit('diameter', '5');
      expect(warnings, findsOneWidget);
      expect(t.widget<DeskButton>(apply).onPressed, isNull);
      await tap(find.text('Показать номера на схеме'));
      await tap(number(2));
      await edit('horizontal', '150');
      await edit('diameter', '35');
      await edit('depth', '10');
      expect(warnings, findsNothing);
      await tap(apply);
      expect(editor.project.beams.single.holes, [
        board.holes.first,
        const PanelHole(150, 80, 35, depth: 10, back: true),
      ]);
    },
  );

  testWidgets('Hole list follows additions, row clicks and diagram picks', (
    t,
  ) async {
    final board = Beam(
      1,
      'Панель',
      Vector3.zero(),
      Vector3(800, 300, 18),
      axis(0),
      axis(1),
    );
    final editor = Editor(Project('', [board]));
    await t.binding.setSurfaceSize(const Size(1100, 800));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () =>
                showPanelHoles(context, editor, editor.project.beams.single),
            child: const Text('Открыть'),
          ),
        ),
      ),
    );
    Future<void> tap(Finder finder) async {
      await t.tap(finder);
      await t.pumpAndSettle();
    }

    await tap(find.text('Открыть'));
    expect(find.text('Отверстия (0)'), findsOneWidget);
    expect(find.text('На детали пока нет отверстий'), findsOneWidget);
    final add = find.text('Добавить отверстие');
    final diagram = find.byKey(const ValueKey('hole-diagram'));
    Finder number(int i) => find.byKey(ValueKey('hole-number-$i'));
    final name = find.descendant(
      of: find.byKey(const ValueKey('hole-name')),
      matching: find.byType(EditableText),
    );
    final listHeading = find.text('Отверстия (1)');
    await tap(add);
    expect(t.getRect(listHeading).right, lessThan(t.getRect(diagram).left));
    expect(t.getRect(add).top, greaterThan(t.getRect(diagram).bottom));
    expect(t.getCenter(add).dx, lessThan(t.getRect(diagram).left));

    await tap(find.text('Под петлю Ø35 мм'));
    final first = find.text('№ 1 · Ø5 мм');
    final second = find.text('№ 2 · Ø35 мм');
    expect(first.hitTestable(), findsOneWidget);
    expect(second.hitTestable(), findsOneWidget);
    expect(find.text('Отверстие 2 из 2'), findsNothing);
    expect(t.getRect(number(1)).overlaps(t.getRect(number(2))), isFalse);
    final toggle = find.text('Показать номера на схеме');
    final centre = t.getCenter(diagram);
    expect(t.getRect(toggle).bottom, lessThanOrEqualTo(t.getRect(diagram).top));
    await tap(toggle);
    expect(number(1), findsNothing);
    expect(number(2), findsNothing);
    expect(t.getCenter(diagram), centre);
    expect(second.hitTestable(), findsOneWidget);
    expect(find.byKey(const ValueKey('hole-depth')), findsOneWidget);
    await tap(toggle);
    expect(number(1), findsOneWidget);
    expect(number(2), findsOneWidget);
    await t.enterText(name, 'Петля');
    await t.pumpAndSettle();
    expect(find.text('№ 2 · Петля'), findsOneWidget);
    expect(find.text('Ø35 мм · Глухое · Сторона Б'), findsOneWidget);
    await tap(first);
    expect(find.byKey(const ValueKey('hole-depth')), findsNothing);
    await tap(number(2));
    expect(t.widget<EditableText>(name).controller.text, 'Петля');
    expect(find.byKey(const ValueKey('hole-depth')), findsOneWidget);
    await tap(add);
    await tap(find.text('Сторона А').hitTestable());
    expect(number(2), findsNothing);
    expect(number(3), findsOneWidget);
    await tap(first);

    for (var i = 0; i < 8; i++) {
      await tap(add);
    }
    expect(find.text('№ 11 · Ø5 мм').hitTestable(), findsOneWidget);
    expect(first.hitTestable(), findsNothing);
    // The first through hole was added at the centre of the panel.
    await tap(diagram);
    expect(first.hitTestable(), findsOneWidget);
    final trash = find.descendant(
      of: find.byType(ListView),
      matching: find.byTooltip('Удалить'),
    );
    expect(t.getCenter(trash).dy, closeTo(t.getRect(first).center.dy, 16));
    await tap(trash);
    expect(number(11), findsNothing);
    expect(number(2), findsNothing); // The opposite-face hole is now second.
    expect(number(1), findsOneWidget);
    expect(find.text('№ 1 · Петля').hitTestable(), findsOneWidget);
    await tap(find.text('Применить'));
    expect(editor.project.beams.single.holes, hasLength(10));
    final saved = editor.project.beams.single;
    expect(saved.holes.first.diameter, 35);
    expect(Beam.fromJson(saved.toJson()).holes.first.name, 'Петля');
    await tap(find.text('Открыть'));
    await tap(toggle);
    await t.enterText(name, 'Шкант');
    await tap(find.text('Отмена'));
    expect(editor.project.beams.single, same(saved));
    await tap(find.text('Открыть'));
    expect(number(1), findsNothing);
    await tap(toggle);
    expect(number(1), findsOneWidget);
    await t.enterText(name, 'Верхняя петля');
    await tap(find.text('Применить'));
    expect(editor.project.beams.single.holes.first.name, 'Верхняя петля');
    editor.undo();
    expect(editor.project.beams.single, same(saved));
  });

  testWidgets(
    'Inch precision applies to picked offsets, typed expressions and arrows',
    (t) async {
      const inch = 25.4;
      final board = Beam(
        1,
        'Panel',
        Vector3.zero(),
        Vector3(10.346 * inch, 4.578 * inch, 16),
        axis(0),
        axis(1),
        holes: const [PanelHole(20.321, 21.432, 5.135)],
      );
      final editor = Editor(Project('', [board], [], LengthUnit.inch))
        ..step = EditStep(values: {LengthUnit.inch: .01});
      await t.binding.setSurfaceSize(const Size(1100, 800));
      addTearDown(() => t.binding.setSurfaceSize(null));
      await t.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  showPanelHoles(context, editor, editor.project.beams.single),
              child: const Text('Открыть'),
            ),
          ),
        ),
      );
      Future<void> tap(String text) async {
        await t.tap(find.text(text));
        await t.pumpAndSettle();
      }

      Finder field(String key) => find.descendant(
        of: find.byKey(ValueKey(key)),
        matching: find.byType(EditableText),
      );
      String value(String key) =>
          t.widget<EditableText>(field(key)).controller.text;

      await tap('Открыть');
      expect(value('hole-diameter'), '0.2');
      await tap('Применить');
      expect(editor.project.beams.single, same(board));
      await tap('Открыть');
      await t.tap(find.byKey(const ValueKey('hole-diagram')));
      await t.pumpAndSettle();
      expect(value('hole-horizontal'), '5.17');
      expect(value('hole-vertical'), '2.29');
      await t.enterText(field('hole-vertical'), '1,234 + 0.002');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pumpAndSettle();
      expect(value('hole-vertical'), '1.24');
      await t.tap(field('hole-vertical'));
      await t.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await t.pumpAndSettle();
      expect(value('hole-vertical'), '1.25');
      await tap('Применить');
      final hole = editor.project.beams.single.holes.single;
      expect(hole.x, closeTo(5.17 * inch, 1e-9));
      expect(hole.y, closeTo(1.25 * inch, 1e-9));
      expect(hole.diameter, 5.135);
    },
  );

  testWidgets(
    'The door and its hit area stay centred and corner choices follow the visible face',
    (t) async {
      final door = Beam(
        1,
        'Дверца',
        Vector3.zero(),
        Vector3(2189, 597, 16),
        axis(2),
        -axis(1),
        holes: const [PanelHole(120, 22, 35, depth: 12)],
      );
      final editor = Editor(Project('', [door]));
      await t.binding.setSurfaceSize(const Size(1100, 800));
      addTearDown(() => t.binding.setSurfaceSize(null));
      await t.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => showPanelHoles(context, editor, door),
              child: const Text('Открыть'),
            ),
          ),
        ),
      );
      await t.tap(find.text('Открыть'));
      await t.pumpAndSettle();

      final diagram = find.byKey(const ValueKey('hole-diagram'));
      final face = find.byKey(const ValueKey('hole-view-face'));
      final offsets = find.text('Отступы от угла');
      String value(String key) => t
          .widget<EditableText>(
            find.descendant(
              of: find.byKey(ValueKey(key)),
              matching: find.byType(EditableText),
            ),
          )
          .controller
          .text;
      Future<void> corner(bool right, bool top) async {
        final choice = find.byKey(ValueKey('hole-origin-$right-$top'));
        await t.ensureVisible(choice);
        await t.tap(choice);
        await t.pumpAndSettle();
      }

      expect(t.getRect(diagram).right, lessThan(t.getRect(offsets).left));
      expect(t.getCenter(face).dx, closeTo(t.getCenter(diagram).dx, 1));
      expect(
        t.getCenter(find.text('Вверх')).dx,
        lessThan(t.getCenter(diagram).dx),
      );
      expect(
        t.getCenter(find.text('Вперёд')).dy,
        greaterThan(t.getCenter(diagram).dy),
      );

      await corner(true, true);
      expect(value('hole-horizontal'), '575');
      expect(value('hole-vertical'), '2069');
      await t.tap(find.text('Сторона Б'));
      await t.pumpAndSettle();
      expect(find.text('От левого края'), findsOneWidget);
      expect(value('hole-horizontal'), '575');
      await corner(true, false);
      expect(value('hole-horizontal'), '22');
      expect(value('hole-vertical'), '120');

      await t.binding.setSurfaceSize(const Size(420, 790));
      await t.pumpAndSettle();
      final listEntry = find.text('№ 1 · Ø35 мм');
      final addHole = find.text('Добавить отверстие');
      expect(t.getRect(listEntry).bottom, lessThan(t.getRect(addHole).top));
      expect(t.getRect(addHole).bottom, lessThan(t.getRect(diagram).top));
      expect(t.getRect(diagram).bottom, lessThan(t.getRect(offsets).top));
      expect(t.getSize(diagram).width, greaterThan(300));
      await t.tapAt(t.getCenter(diagram));
      await t.pumpAndSettle();
      expect(value('hole-horizontal'), '299');
      expect(value('hole-vertical'), '1095');

      await t.tap(find.text('Применить'));
      await t.pumpAndSettle();
      final hole = editor.project.beams.single.holes.single;
      expect(hole.back, isTrue);
      expect(hole.centerX(door.size), 1095);
      expect(hole.centerY(door.size), 299);
    },
    variant: TargetPlatformVariant({
      TargetPlatform.macOS,
      TargetPlatform.windows,
    }),
  );
}
