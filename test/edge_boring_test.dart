import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:neprosto/editor/controller.dart';
import 'package:neprosto/editor/desktop.dart';
import 'package:neprosto/editor/hole_dialog.dart';
import 'package:neprosto/editor/model.dart';
import 'package:neprosto/editor/parts_workbook.dart';
import 'package:neprosto/editor/scene.dart';

extension on WidgetTester {
  Future<void> mountHoles(Editor editor) async {
    await binding.setSurfaceSize(const Size(1100, 800));
    addTearDown(() => binding.setSurfaceSize(null));
    await pumpWidget(
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
  }

  Future<void> tapAndSettle(Finder target) async {
    await ensureVisible(target);
    await tap(target);
    await pumpAndSettle();
  }

  Future<void> pressText(String label) => tapAndSettle(find.text(label).last);
  Future<void> selectEdge(String side) async {
    await pressText('Присадка по кромке…');
    await tapAndSettle(find.byKey(ValueKey('cup-edge-$side')));
    expect(field('depth'), findsNothing);
    await pressText('Параметры сверления');
  }

  Finder field(String name) => find.descendant(
    of: find.byKey(ValueKey('cup-$name')),
    matching: find.byType(EditableText),
  );

  String value(String name) =>
      widget<EditableText>(field(name)).controller.text;

  Future<void> edit(String name, String text) async {
    await enterText(field(name), text);
    await pump();
  }

  bool get canAdd =>
      widget<DeskButton>(find.widgetWithText(DeskButton, 'Добавить отверстия'))
          .onPressed !=
      null;
}

void main() {
  testWidgets(
    'All four edges follow the visible inside face and keep exact drilling references',
    (t) async {
      final door = Beam(
        1,
        'Дверца',
        Vector3.zero(),
        Vector3(1000, 460, 18),
        axis(2),
        axis(0),
        hinge: DoorHinge.left,
      );
      final editor = Editor(Project('', [door]));
      await t.mountHoles(editor);

      for (final (side, edge) in [
        ('left', PanelEdge.far),
        ('right', PanelEdge.near),
        ('top', PanelEdge.end),
        ('bottom', PanelEdge.start),
      ]) {
        await t.pressText('Открыть');
        await t.selectEdge(side);
        expect(t.value('first'), '100');
        expect(t.value('last'), '100');
        expect(t.value('count'), edge.alongWidth ? '2' : '3');
        expect(t.value('center'), '22.5');
        expect(t.value('rim'), '5');
        expect(
          find.byKey(const ValueKey('cup-measurement-diagram')),
          findsOneWidget,
        );
        final plan = t.getRect(
          find.byKey(const ValueKey('cup-measurement-diagram')),
        );
        expect(find.byKey(const ValueKey('cup-depth-diagram')), findsNothing);
        expect(t.getRect(t.field('rim')).top, t.getRect(t.field('center')).top);
        expect(t.getRect(t.field('depth')).bottom, lessThan(plan.top));
        expect(t.value('diameter'), '35');
        await t.edit('diameter', '15');
        expect(t.value('rim'), '5');
        expect(t.value('center'), '12.5');
        await t.edit('center', '34');
        await t.edit('diameter', '16');
        expect(t.value('center'), '34');
        expect(t.value('rim'), '26');
        await t.edit('diameter', '0');
        expect(t.canAdd, isFalse);
        await t.edit('diameter', '15');
        await t.edit('center', '25.25');
        expect(t.value('rim'), '17.75');
        expect(t.canAdd, isTrue);
        await t.edit('center', '1+');
        expect(t.value('rim'), '');
        expect(t.canAdd, isFalse);
        await t.edit('rim', '4.5');
        expect(t.value('center'), '12');
        expect(t.value('depth'), '13');
        await t.edit('depth', '18');
        expect(t.canAdd, isFalse);
        await t.edit('depth', '12.5');
        await t.edit('last', '130');
        await t.edit('count', '3');
        expect(t.field('bolt-offset'), findsNothing);
        await t.pressText('Торцевое отверстие');
        expect(t.value('bolt-diameter'), '8');
        expect(t.value('bolt-offset'), '9');
        await t.edit('bolt-offset', '13');
        expect(t.canAdd, isFalse);
        await t.edit('bolt-offset', '8');
        await t.edit('bolt-diameter', '7');
        await t.pressText('Добавить отверстия');
        expect(editor.project.beams.single.holes, isEmpty);
        await t.pressText('Применить');

        final saved = editor.project.beams.single;
        final holes = saved.holes;
        expect(holes, hasLength(3));
        final span = edge.length(door.size);
        final step = (span - 100 - 130) / 2;
        for (final (i, h) in holes.indexed) {
          expect(h.boringEdge, edge);
          expect(h.back, isTrue);
          expect(h.depth, 12.5);
          expect(h.diameter, 15);
          expect(edge.centerInset(h, door.size), 12);
          final rod = h.drills(door.size).last;
          expect(rod.diameter, 7);
          expect(rod.depth, 12);
          expect(rod.face, edge.faceIndex);
          expect(rod.entry[rod.axis], edge.atMax ? door.size[rod.axis] : 0);
          expect(
            rod.stop,
            Vector3(h.centerX(door.size), h.centerY(door.size), 10),
          );
          final along = edge.alongWidth
              ? h.centerY(door.size)
              : h.centerX(door.size);
          expect(along, closeTo(span - 100 - i * step, 1e-8));
        }
        expect(Beam.fromJson(saved.toJson()).holes, holes);
        editor.undo();
        expect(editor.project.beams.single, same(door));
      }
    },
    variant: TargetPlatformVariant({
      TargetPlatform.macOS,
      TargetPlatform.windows,
    }),
  );

  testWidgets(
    'A bolt checks the entire drilling path and stays editable with its cam',
    (t) async {
      final board = Beam(
        1,
        'Полка',
        Vector3.zero(),
        Vector3(500, 300, 18),
        axis(0),
        axis(1),
        holes: const [PanelHole(100, 8, 5, fromFarEdge: true)],
      );
      final editor = Editor(Project('', [board]));
      const option = 'Торцевое отверстие';
      await t.mountHoles(editor);
      await t.pressText('Открыть');
      await t.selectEdge('top');
      await t.edit('diameter', '15');
      await t.edit('center', '34');
      expect(t.canAdd, isTrue);
      await t.pressText(option);
      expect(t.canAdd, isFalse);
      expect(find.textContaining('пересекает существующее'), findsOneWidget);
      await t.pressText(option);
      expect(t.canAdd, isTrue);
      await t.pressText(option);
      await t.edit('first', '120');
      await t.pressText('Добавить отверстия');
      await t.tapAndSettle(find.byKey(const ValueKey('face-linked-shaft')));
      await t.edit('bolt-offset', '');
      expect(t.field('bolt-offset'), findsOneWidget);
      expect(
        t
            .widget<DeskButton>(find.widgetWithText(DeskButton, 'Применить'))
            .onPressed,
        isNull,
      );
      await t.edit('bolt-offset', '7');
      await t.pressText('Применить');
      final saved = editor.project.beams.single;
      expect(saved.drillingCount, 5);
      expect(saved.holes[1].boltBore, (diameter: 8.0, faceOffset: 7.0));
      expect(saved.holes[2].boltBore, (diameter: 8.0, faceOffset: 9.0));
      expect(Beam.fromJson(saved.toJson()).holes, saved.holes);
      editor.undo();
      expect(editor.project.beams.single, same(board));
    },
  );

  testWidgets(
    'Depth commits on blur and a through hole keeps its edge drilling',
    (t) async {
      final board = Beam(
        1,
        'Полка',
        Vector3.zero(),
        Vector3(500, 300, 18),
        axis(0),
        axis(1),
        holes: const [PanelHole(35, 110, 15)],
      );
      final editor = Editor(Project('', [board]));
      Finder field(String key) => find.descendant(
        of: find.byKey(ValueKey('hole-$key')),
        matching: find.byType(EditableText),
      );
      String value(String key) =>
          t.widget<EditableText>(field(key)).controller.text;
      Future<void> edit(String key, String text) async {
        await t.enterText(field(key), text);
        await t.pump();
      }

      await t.mountHoles(editor);
      await t.pressText('Открыть');
      expect(field('depth'), findsNothing);
      await t.pressText('Параметры сверления');
      expect(value('depth'), isEmpty);
      await t.tapAndSettle(find.byKey(const ValueKey('face-linked-shaft')));
      await t.edit('bolt-offset', '7');
      await t.pressText('К отверстию № 1');
      await t.pressText('Параметры сверления');
      for (final raw in ['0', '-2', '18', '19', '2+', '']) {
        await edit('depth', raw);
        await t.tapAndSettle(field('center'));
        expect(value('depth'), isEmpty);
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('hole-depth')),
            matching: find.text('Сквозное'),
          ),
          findsOneWidget,
        );
      }
      await edit('depth', '4+8');
      await t.tapAndSettle(field('rim'));
      expect(value('depth'), '12');
      await edit('rim', '17.5');
      expect(value('center'), '25');
      await edit('diameter', '20');
      expect(value('rim'), '17.5');
      expect(value('center'), '27.5');
      await edit('center', '34');
      expect(value('rim'), '24');
      await edit('depth', '0');
      await t.pressText('Параметры сверления');
      expect(field('depth'), findsNothing);
      await t.pressText('Применить');
      final saved = editor.project.beams.single;
      final h = saved.holes.single;
      expect(h.depth, isNull);
      expect(h.boringEdge, PanelEdge.start);
      expect(h.x, 34);
      expect(h.diameter, 20);
      expect(h.boltBore, (diameter: 8.0, faceOffset: 7.0));
      expect(h.fits(saved.size), isTrue);
      expect(h.drills(saved.size).first.through, isTrue);
      expect(h.drills(saved.size).last.depth, 34);
      expect(Beam.fromJson(saved.toJson()).holes, saved.holes);
      await t.pressText('Открыть');
      await t.pressText('Параметры сверления');
      expect(value('depth'), isEmpty);
      await t.tapAndSettle(find.byKey(const ValueKey('face-linked-shaft')));
      expect(t.value('bolt-offset'), '7');
    },
  );

  testWidgets(
    'An edge row accepts a through bore after an oversized depth loses focus',
    (t) async {
      final board = Beam(
        1,
        'Полка',
        Vector3.zero(),
        Vector3(500, 300, 18),
        axis(0),
        axis(1),
      );
      final editor = Editor(Project('', [board]));
      await t.mountHoles(editor);
      await t.pressText('Открыть');
      await t.selectEdge('top');
      await t.pressText('Торцевое отверстие');
      await t.edit('depth', '30');
      await t.tapAndSettle(t.field('center'));
      expect(t.value('depth'), isEmpty);
      expect(t.canAdd, isTrue);
      await t.pressText('Добавить отверстия');
      await t.pressText('Применить');
      final saved = editor.project.beams.single;
      expect(saved.drillingCount, 4);
      for (final h in saved.holes) {
        expect(h.depth, isNull);
        expect(h.boltBore, isNotNull);
        expect(h.fits(saved.size), isTrue);
      }
    },
  );

  test('The bolt meets the cam on either face and opens on the selected stock edge', () {
    final size = Vector3(320, 240, 18);
    const viewport = Size(640, 480);
    for (final back in [true, false]) {
      for (final edge in PanelEdge.values) {
        final camHole = PanelHole(
          34,
          34,
          15,
          depth: 12.5,
          back: back,
          fromEnd: edge == PanelEdge.end,
          fromFarEdge: edge == PanelEdge.far,
          boringEdge: edge,
          boltBore: (diameter: 8, faceOffset: 7),
        );
        final part = Beam(
          1,
          'Полка',
          Vector3.zero(),
          size,
          axis(0),
          axis(1),
          holes: [camHole],
        );
        final drills = camHole.drills(size).toList();
        expect(drills, hasLength(2));
        expect(drills.first.intersects(drills.last), isTrue);
        expect(drills.last.depth, 34);
        expect(drills.last.stop.z, back ? 11 : 7);
        final doc = Project('', [part]);
        final camera = Camera()
          ..view(switch (edge) {
            PanelEdge.start => ViewAngle.left,
            PanelEdge.end => ViewAngle.right,
            PanelEdge.near => ViewAngle.front,
            PanelEdge.far => ViewAngle.back,
          })
          ..fit(doc, viewport);
        final scene = Scene(doc, camera, viewport);
        final entry = camera.project(drills.last.entry, viewport);
        final face = scene.hit(entry)!;
        expect(face.face, edge.faceIndex);
        expect(face.boreFloor!.contains(entry), isTrue);
        final list = stockHoles(part, LengthUnit.millimeter).split('\n');
        expect(list, hasLength(2));
        expect(list.last, contains('Торцевое отверстие Ø8'));
        expect(list.last, contains('Глубина 34'));
      }
    }
  });

  testWidgets(
    'Inch defaults, manual count, collisions and cancellation use the same draft',
    (t) async {
      const inch = 25.4;
      final part = Beam(
        1,
        'Фасад',
        Vector3.zero(),
        Vector3(750, 400, 18),
        axis(0),
        axis(1),
        holes: const [
          PanelHole(4 * inch, 22.5, 5, fromFarEdge: true),
          PanelHole(5 * inch, 22.5, 5, fromFarEdge: true, depth: 5.5),
        ],
      );
      final editor = Editor(Project('', [part], [], LengthUnit.inch));
      await t.mountHoles(editor);
      await t.pressText('Открыть');
      await t.pressText('Присадка по кромке…');
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
      expect(find.text('Отверстия (2)'), findsOneWidget);
      await t.selectEdge('top');
      expect(t.value('first'), '4');
      expect(t.value('last'), '4');
      expect(t.value('count'), '2');
      expect(t.canAdd, isFalse);
      expect(find.textContaining('пересекает существующее'), findsOneWidget);
      await t.edit('first', '5');
      expect(t.canAdd, isFalse);
      await t.edit('depth', '.45');
      expect(t.canAdd, isTrue);
      await t.edit('count', '999');
      expect(t.canAdd, isFalse);
      await t.edit('count', '3');
      await t.edit('rim', '-.1');
      expect(t.canAdd, isFalse);
      await t.pressText('Отмена');
      expect(find.text('Нажмите на кромку детали'), findsOneWidget);
      await t.tapAndSettle(find.byKey(const ValueKey('cup-edge-top')));
      await t.pressText('Параметры сверления');
      await t.edit('first', '5');
      expect(t.canAdd, isFalse);
      await t.edit('depth', '.45');
      await t.edit('count', '3');
      await t.pressText('Добавить отверстия');
      await t.pressText('Применить');
      final holes = editor.project.beams.single.holes;
      expect(holes, hasLength(5));
      expect(holes.take(2), part.holes);
      for (final (i, h) in holes.skip(2).indexed) {
        expect(h.depth, closeTo(.45 * inch, 1e-8));
        expect(h.centerY(part.size), 377.5);
        expect(
          h.centerX(part.size),
          closeTo(5 * inch + i * (750 - 9 * inch) / 2, 1e-8),
        );
      }
    },
  );
}
