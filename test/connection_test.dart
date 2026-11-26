import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:neprosto/editor/controller.dart';
import 'package:neprosto/editor/hole_dialog.dart';
import 'package:neprosto/editor/model.dart';
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
      await t.tap(find.byKey(const ValueKey('hole-row-edge-0')));
      await t.pumpAndSettle();
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
    },
  );
}
