import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:neprosto/editor/controller.dart';
import 'package:neprosto/editor/hole_dialog.dart';
import 'package:neprosto/editor/model.dart';

void main() {
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
      expect(t.getRect(diagram).bottom, lessThan(t.getRect(offsets).top));
      expect(t.getSize(diagram).width, greaterThan(300));
      await t.tapAt(t.getCenter(diagram));
      await t.pumpAndSettle();
      expect(value('hole-horizontal'), '298.5');
      expect(value('hole-vertical'), '1094.5');

      await t.tap(find.text('Применить'));
      await t.pumpAndSettle();
      final hole = editor.project.beams.single.holes.single;
      expect(hole.back, isTrue);
      expect(hole.centerX(door.size), 1094.5);
      expect(hole.centerY(door.size), 298.5);
    },
    variant: TargetPlatformVariant({
      TargetPlatform.macOS,
      TargetPlatform.windows,
    }),
  );
}
