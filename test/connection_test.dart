import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:neprosto/editor/controller.dart';
import 'package:neprosto/editor/desktop.dart';
import 'package:neprosto/editor/hole_dialog.dart';
import 'package:neprosto/editor/model.dart';
import 'package:neprosto/editor/part_finish.dart';
import 'package:neprosto/editor/parts_workbook.dart';
import 'package:neprosto/editor/scene.dart';
import 'package:neprosto/main.dart';

void main() {
  final board = Beam(
    1,
    'Полка',
    Vector3.zero(),
    Vector3(360, 210, 19),
    axis(0),
    axis(1),
  );
  const ruler = ConnectionRuler();

  test('Wood rows follow the overlap and Pocket Hole has its own spacing', () {
    final a = board.copy(size: Vector3(720, 140, 19));
    final b = board.copy(
      id: 2,
      origin: Vector3(80, 140, 0),
      size: Vector3(450, 140, 19),
    );
    final contact = connectionContacts([a, b]).first;
    const dowel = ConnectionPattern(ConnectionKind.dowel);
    final layout = contact.plan(dowel, ruler)!;
    final first = layout.layouts[1]!.edges;
    final second = layout.layouts[2]!.edges;
    expect(first, hasLength(greaterThan(2)));
    expect(first.every((h) => h.diameter == 10), isTrue);
    for (final (i, hole) in first.indexed) {
      expect(hole.offset, inExclusiveRange(80, 530));
      expect(hole.offset, closeTo(second[i].offset + 80, 1e-6));
    }
    const pocket = ConnectionPattern(ConnectionKind.pocket);
    final pockets = contact.plan(pocket, ruler)!;
    expect(pockets.layouts[2]!.edges, isEmpty);
    expect(pockets.stations.first.$2, closeTo(105.4, 1e-6));
    expect(pockets.stations.last.$2, closeTo(504.6, 1e-6));
    expect(
      contact
          .plan(pocket, const ConnectionRuler(first: 10, pitch: 80))!
          .stations,
      pockets.stations,
    );
    expect(
      contact.plan(const ConnectionPattern(ConnectionKind.woodScrew), ruler),
      isNull,
    );
    expect(
      connectionContacts([a, b.copy(origin: Vector3(80, 140.1, 0))]),
      isEmpty,
    );
    expect(
      connectionContacts([a, b.copy(origin: Vector3(720, 140, 0))]),
      isEmpty,
    );
  });

  test(
    'Cabinet and wood options follow the stock at a rotated edge-to-face joint',
    () {
      final side = board.copy(
        id: 2,
        origin: Vector3(0, 229, 0),
        size: Vector3(360, 90, 19),
        along: axis(0),
        across: axis(2),
      );
      final parts = Project('', [
        board.copy(finish: FinishPreset.whiteBoard.finish),
        side.copy(finish: FinishPreset.oakBoard.finish),
      ]).rotate({1, 2}, axis(0), 31).beams;
      final contact = connectionContacts(parts)
          .firstWhere((c) => c.part.id == 1);
      const confirmat = ConnectionPattern(
        ConnectionKind.confirmat,
        dowels: 2,
        side: DowelSide.both,
      );
      final fasteners = contact.plan(confirmat, ruler)!;
      expect(fasteners.stations.map((s) => s.$2), [37, 69, 101]);
      final pilot = fasteners.layouts[1]!.edges[1];
      final clearance = fasteners.layouts[2]!.faces[1];
      expect(pilot.kind, EdgeHoleKind.confirmat);
      expect(clearance.x, closeTo(pilot.offset, 1e-6));
      expect(clearance.diameter, 7);
      expect(clearance.depth, isNull);
      expect(
        contact.plan(const ConnectionPattern(ConnectionKind.pocket), ruler),
        isNull,
      );
      expect(
        contact.plan(const ConnectionPattern(ConnectionKind.woodScrew), ruler),
        isNull,
      );

      final wood = connectionContacts([board, side]).first;
      final screws = wood.plan(
        const ConnectionPattern(ConnectionKind.woodScrew),
        ruler,
      )!;
      final woodPilot = screws.layouts[1]!.edges.first;
      expect(woodPilot.kind, EdgeHoleKind.woodScrew);
      expect(screws.layouts[2]!.faces.first.diameter, 4.5);
      final drilled = withDrillLayout(board, screws.layouts[1]!);
      expect(Beam.fromJson(drilled.toJson()).edgeHoles, drilled.edgeHoles);
    },
  );

  testWidgets(
    'A touching pair previews and applies both sets of holes in one edit',
    (t) async {
      await t.binding.setSurfaceSize(const Size(790, 740));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final mate = board.copy(id: 2, origin: Vector3(0, 211, 0));
      final editor = Editor(Project('Стол', [board, mate]))
        ..select(1)
        ..select(2, multi: true);
      await t.pumpWidget(NeprostoApp(editor: editor));
      await t.pumpAndSettle();
      final button = find.widgetWithText(DeskButton, 'Добавить соединение');
      expect(t.widget<DeskButton>(button).onPressed, isNull);
      expect(
        find.byTooltip('Выберите две детали, которые соприкасаются гранями'),
        findsOneWidget,
      );

      editor.commit(editor.project.move({2}, Vector3(0, -1, 0)));
      final touching = editor.project;
      await t.pumpAndSettle();
      expect(t.widget<DeskButton>(button).onPressed, isNotNull);
      await t.tap(button);
      await t.pumpAndSettle();
      final preview = find.byKey(const ValueKey('paired-connection-preview'));
      expect(preview, findsOneWidget);
      expect(find.byKey(const ValueKey('connection-confirmat')), findsNothing);
      await t.tap(find.byKey(const ValueKey('connection-pocket')));
      await t.pumpAndSettle();
      expect(preview, findsOneWidget);
      expect(editor.project, same(touching));
      await t.tap(find.byKey(const ValueKey('connection-dowel')));
      await t.pumpAndSettle();
      await t.tap(find.widgetWithText(DeskButton, 'Применить'));
      await t.pumpAndSettle();
      for (final old in touching.beams) {
        final next = editor.project.byId[old.id]!;
        expect(next.origin, old.origin);
        expect(next.edgeHoles, isNotEmpty);
      }
      editor.undo();
      expect(editor.project, same(touching));
    },
  );

  test('All templates use a single datum, survive storage and reject overlapping placements', () {
    for (final kind in ConnectionKind.values) {
      for (final count
          in (kind == ConnectionKind.dowel
              ? [1, 2, 3]
              : kind == ConnectionKind.pocket
              ? [0]
              : [0, 1, 2])) {
        for (final side in DowelSide.values) {
          for (final edge in PanelEdge.values) {
            for (final far in [false, true]) {
              final pattern = ConnectionPattern(
                kind,
                dowels: count,
                side: side,
                back: far,
              );
              final layout = pattern.layout(board, edge, far, 37, 32);
              expect(
                pattern.issue(board, layout),
                isNull,
                reason: '$kind/$count/$side/$edge/$far',
              );
              final parts = board.copy(
                holes: layout.faces,
                edgeHoles: layout.edges,
              );
              final stored = Beam.fromJson(parts.toJson());
              expect(stored.edgeHoles, layout.edges);
              expect(stored.holes, layout.faces);
              expect(pattern.issue(stored, layout), isNotNull);
              final centers =
                  [
                      for (final h in layout.edges) h.position(board.size),
                      for (final h in layout.faces)
                        h.drills(board.size).last.entry[edge.alongWidth
                            ? 1
                            : 0],
                    ].map((d) => far ? edge.length(board.size) - d : d).toList()
                    ..sort();
              expect(centers, [
                for (final (i, _) in pattern.stations.indexed) 37 + i * 32,
              ]);
              final stock = stockHoles(stored, LengthUnit.millimeter);
              if (kind == ConnectionKind.pocket) {
                final bores = stored.edgeHoles.single
                    .drills(board.size)
                    .toList();
                expect(bores.first.entry.z, far ? 19 : 0);
                expect(bores.first.stop, bores.last.entry);
                expect(bores.last.diameter, lessThan(bores.first.diameter));
                expect(stock, contains('15°'));
              }
            }
          }
        }
      }
    }
    const p = ConnectionPattern(
      ConnectionKind.confirmat,
      dowels: 2,
      side: DowelSide.both,
    );
    expect(p.stations, [
      ConnectionKind.dowel,
      ConnectionKind.confirmat,
      ConnectionKind.dowel,
    ]);
    expect(
      p.issue(board, p.layout(board, PanelEdge.near, false, 330, 32)),
      isNotNull,
    );
    const maxi = ConnectionPattern(ConnectionKind.maxifix);
    final thin = board.copy(size: Vector3(360, 210, 18));
    expect(
      maxi.issue(thin, maxi.layout(thin, PanelEdge.near, false, 37, 32)),
      isNotNull,
    );
    expect(ruler.snap(52), 37);
    expect(ruler.snap(54), 69);
    expect(ConnectionRuler.restore(40, 25).snap(66), 65);
  });

  testWidgets(
    'Pick a template, a physical edge and a datum, cancel or commit a snapped group',
    (t) async {
      await t.binding.setSurfaceSize(const Size(1340, 840));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final project = Project('Шкаф', [board]);
      final editor = Editor(project)
        ..setView(ViewAngle.top)
        ..fitRequested = false;
      editor.camera
        ..target = board.size * .5
        ..scale = 1.4;
      await t.pumpWidget(NeprostoApp(editor: editor));
      await t.pumpAndSettle();
      final drawing = find.byKey(const Key('drawing'));
      Offset at(double x) =>
          t.getTopLeft(drawing) +
          editor.camera.project(
            Vector3(x, 1.0, board.size.z),
            t.getSize(drawing),
          );
      Future<void> tap(Finder f) async {
        await t.ensureVisible(f);
        await t.tap(f);
        await t.pumpAndSettle();
      }

      await tap(find.text('Добавить соединение'));
      await tap(find.byKey(const Key('connection-confirmat')));
      await tap(find.text('2').last);
      await tap(find.text('Разместить на схеме'));
      expect(editor.tool, Tool.connection);
      await t.tapAt(at(347));
      await t.pump();
      expect(editor.connectionBase, (
        partId: 1,
        edge: PanelEdge.near,
        fromEnd: true,
      ));
      expect(editor.project, same(project));
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pump();
      expect(editor.connectionBase, isNull);
      expect(editor.project, same(project));
      await tap(find.text('Добавить соединение'));
      await tap(find.text('Разместить на схеме'));
      await t.tapAt(at(347));
      await t.pump();
      await t.tapAt(at(360 - 70));
      await t.pumpAndSettle();
      final holes = editor.project.byId[1]!.edgeHoles;
      expect(holes.map((h) => h.offset), [69, 101, 133]);
      expect(holes.map((h) => h.kind), [
        EdgeHoleKind.dowel,
        EdgeHoleKind.confirmat,
        EdgeHoleKind.dowel,
      ]);
      expect(holes.every((h) => h.fromEnd), isTrue);
      expect(editor.project.byId[1]!.holes, isEmpty);
      editor.undo();
      expect(editor.project, same(project));
      editor.redo();
      expect(editor.project.byId[1]!.edgeHoles, holes);
    },
  );

  testWidgets(
    'Drawing settings change the first mark and pitch used by the tool',
    (t) async {
      await t.binding.setSurfaceSize(const Size(1280, 820));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final editor = Editor(Project('', [board]));
      await t.pumpWidget(NeprostoApp(editor: editor));
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('Настройки'));
      await t.pumpAndSettle();
      await t.tap(find.text('Чертёж').last);
      await t.pumpAndSettle();
      for (final (key, value) in [
        ('connection-first', '42'),
        ('connection-pitch', '24'),
      ]) {
        await t.enterText(
          find.descendant(
            of: find.byKey(ValueKey(key)),
            matching: find.byType(EditableText),
          ),
          value,
        );
        await t.pump();
      }
      await t.tap(find.text('Готово'));
      await t.pumpAndSettle();
      expect(editor.connectionRuler.snap(64), 66);
      await t.tap(find.text('Добавить соединение'));
      await t.pumpAndSettle();
      await t.tap(find.text('3').last);
      await t.pumpAndSettle();
      for (final v in ['42 мм', '66 мм', '90 мм']) {
        expect(find.text(v), findsWidgets);
      }
    },
  );

  testWidgets(
    'Edge inspection edits a standalone bore and follows the linked cam back to its face',
    (t) async {
      const pattern = ConnectionPattern(ConnectionKind.minifix, dowels: 1);
      final layout = pattern.layout(board, PanelEdge.near, false, 37, 32);
      final part = board.copy(holes: layout.faces, edgeHoles: layout.edges);
      final editor = Editor(Project('', [part]));
      await t.binding.setSurfaceSize(const Size(1080, 800));
      addTearDown(() => t.binding.setSurfaceSize(null));
      await t.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  showPanelHoles(context, editor, editor.project.beams.single),
              child: const Text('Open'),
            ),
          ),
        ),
      );
      Future<void> press(String label) async {
        final f = find.text(label).last;
        await t.ensureVisible(f);
        await t.tap(f);
        await t.pumpAndSettle();
      }

      await press('Open');
      final edge = find.byKey(const ValueKey('hole-row-edge-0'));
      final trash = find.descendant(
        of: edge,
        matching: find.byTooltip('Удалить'),
      );
      expect(trash, findsNothing);
      await t.tap(edge);
      await t.pumpAndSettle();
      expect(t.getCenter(trash).dy, t.getCenter(edge).dy);
      await press('Правка');
      await t.pumpAndSettle();
      await t.enterText(find.byType(EditableText).first, '75');
      await t.pump();
      await press('Применить');
      expect(editor.project.beams.single, same(part));
      await t.tap(find.byKey(const ValueKey('hole-row-shaft-0')));
      await t.pumpAndSettle();
      await press('К отверстию № 1');
      await t.pumpAndSettle();
      expect(find.text('Параметры сверления'), findsOneWidget);
      await press('Применить');
      expect(editor.project.beams.single.edgeHoles.single.offset, 75);
      expect(editor.project.beams.single.holes, layout.faces);

      await t.binding.setSurfaceSize(const Size(620, 800));
      await press('Open');
      await t.ensureVisible(edge);
      await t.tap(edge);
      await t.pumpAndSettle();
      expect(trash.hitTestable(), findsOneWidget);
      expect(t.getCenter(trash).dy, t.getCenter(edge).dy);
      expect(t.getRect(trash).right, lessThan(t.getRect(edge).right));
      final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer();
      await mouse.moveTo(t.getCenter(trash));
      await t.pump(const Duration(milliseconds: 400));
      await t.pumpAndSettle();
      expect(find.text('Удалить'), findsOneWidget);
      await mouse.removePointer();
      await t.tap(trash);
      await t.pumpAndSettle();
      expect(edge, findsNothing);
      await press('Применить');
      expect(editor.project.beams.single.edgeHoles, isEmpty);
      expect(editor.project.beams.single.holes, layout.faces);
    },
  );
}
