import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:neprosto/editor/controller.dart';
import 'package:neprosto/editor/desktop.dart';
import 'package:neprosto/editor/drawing.dart';
import 'package:neprosto/editor/edge_banding_dialog.dart';
import 'package:neprosto/editor/model.dart';
import 'package:neprosto/editor/part_finish.dart';
import 'package:neprosto/editor/parts_workbook.dart';
import 'package:neprosto/editor/scene.dart';
import 'package:neprosto/main.dart';

Beam shelf() => Beam(
  1,
  'Полка',
  Vector3.zero(),
  Vector3(262, 332, 18),
  axis(0),
  axis(1),
  finish: FinishPreset.whiteBoard.finish,
);

void main() {
  test(
    'Selected stock edges and exact tape sizes survive copying and saving',
    () {
      final original = shelf();
      final legacy = original.toJson();
      expect(legacy.containsKey('edgeBanding'), isFalse);
      expect(Beam.fromJson(legacy).banding.edges, isEmpty);
      final band = EdgeBanding(
        edges: {PanelEdge.near, PanelEdge.end},
        rgb: 0x224466,
        thickness: .45,
        width: 22,
      );
      final editor = Editor(Project('Шкаф', [original.copy(banding: band)]))
        ..select(1)
        ..duplicate();
      final loaded = Project.decode(editor.project.encode());
      expect(loaded.beams.map((b) => b.banding), [band, band]);
      expect(
        stockBanding(loaded.beams.first, LengthUnit.millimeter),
        '0.45 × 22 мм · #224466 · Д+, Ш−',
      );
      for (final change in [
        {'width': 0},
        {'thickness': -1},
        {'rgb': 0x1000000},
        {
          'edges': ['up'],
        },
      ]) {
        expect(
          () => Beam.fromJson({
            ...legacy,
            'edgeBanding': {...band.toJson(), ...change},
          }),
          throwsFormatException,
        );
      }
    },
  );

  test('Only panel stock uses tape and a material change preserves the independent tape color', () {
    final tape = EdgeBanding(
      edges: {PanelEdge.near},
      rgb: 0x181818,
      thickness: 1,
    );
    final panel = shelf().copy(banding: tape);
    expect(panel.material, PartMaterial.panel);
    final redPanel = panel.copy(
      finish: (texture: PartTexture.laminate, rgb: 0xee2222),
    );
    expect(redPanel.banding.rgb, 0x181818);
    for (final preset in [
      FinishPreset.wood,
      FinishPreset.aluminum,
      FinishPreset.graphiteSteel,
    ]) {
      final b = redPanel.copy(finish: preset.finish);
      expect(b.banding.edges, isEmpty);
      expect(stockBanding(b, LengthUnit.millimeter), isEmpty);
      final loaded = Beam.fromJson(b.toJson()).copy(name: 'Деталь');
      expect(loaded.material, preset.finish.texture.material);
      expect(loaded.banding.edges, isEmpty);
      expect(loaded.copy(finish: FinishPreset.oakBoard.finish).banding, tape);
    }
  });

  test('Viewport paints the two panel faces, four raw edges and the chosen tape independently', () async {
    Future<int> pixel(Beam b, ViewAngle view) async {
      const size = Size(80, 80);
      final camera = Camera()
        ..view(view)
        ..target = b.pointAt(Vector3.all(.5))
        ..scale = 2;
      final recorder = ui.PictureRecorder();
      DrawingPainter(
        scene: Scene(Project('Test', [b]), camera, size),
        selection: {},
        dimensions: false,
      ).paint(Canvas(recorder), size);
      final picture = recorder.endRecording();
      final image = await picture.toImage(80, 80);
      final pixels = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      final rgba = pixels.getUint32((40 * 80 + 40) * 4);
      image.dispose();
      picture.dispose();
      return rgba;
    }

    for (final preset in [
      FinishPreset.whiteBoard,
      FinishPreset.oakBoard,
      FinishPreset.plywood,
      FinishPreset.mdf,
    ]) {
      final panel = shelf().copy(finish: preset.finish);
      final recolored = panel.copy(
        finish: (texture: panel.finish.texture, rgb: 0x00ff00),
      );
      for (final view in [
        ViewAngle.left,
        ViewAngle.right,
        ViewAngle.front,
        ViewAngle.back,
      ]) {
        expect(
          await pixel(panel, view),
          await pixel(recolored, view),
          reason: '${preset.name} ${view.name}',
        );
      }
      for (final view in [ViewAngle.top, ViewAngle.bottom]) {
        expect(await pixel(panel, view), isNot(await pixel(recolored, view)));
      }
    }
    final part = shelf();
    final blue = EdgeBanding(
      edges: {PanelEdge.near},
      rgb: 0x0000ff,
      thickness: .8,
    );
    final banded = part.copy(banding: blue);
    expect(
      await pixel(banded, ViewAngle.back),
      await pixel(part, ViewAngle.back),
    );
    final front = await pixel(banded, ViewAngle.front);
    expect((front >> 8) & 255, greaterThan(front >> 24));
    expect(front, isNot(await pixel(part, ViewAngle.front)));
    for (final preset in [FinishPreset.wood, FinishPreset.aluminum]) {
      expect(
        await pixel(banded.copy(finish: preset.finish), ViewAngle.front),
        await pixel(part.copy(finish: preset.finish), ViewAngle.front),
      );
    }
  });

  test(
    'The same local edge follows the panel and covers its specified width',
    () {
      final part = shelf();
      expect(part.bandingEdgeLabel(part.bandingLayout.bottom), 'Передний край');
      final door = part.copy(along: axis(2), across: -axis(0));
      expect(door.bandingLayout.top, PanelEdge.end);
      expect(door.bandingEdgeLabel(door.bandingLayout.right), 'Правый');
      List<List<Vector3>> strips(ViewAngle view, double? width) {
        final b = part.copy(
          banding: EdgeBanding(
            edges: {PanelEdge.near},
            rgb: 1,
            thickness: .8,
            width: width,
          ),
        );
        return Scene(
          Project('Test', [b]),
          Camera()..view(view),
          const Size(300, 300),
        ).faces.single.bandingPolygons.toList();
      }

      final top = Bounds3.points(strips(ViewAngle.top, null).single);
      expect(top.low.y, 0);
      expect(top.high.y, closeTo(.8, 1e-8));
      final front = Bounds3.points(strips(ViewAngle.front, null).single);
      expect(front.high.z - front.low.z, 18);
      final narrow = Bounds3.points(strips(ViewAngle.front, 10).single);
      expect([narrow.low.z, narrow.high.z], [4, 14]);
      expect(strips(ViewAngle.top, 10), isEmpty);
      expect(strips(ViewAngle.back, null), isEmpty);
    },
  );

  testWidgets(
    'An open door keeps its edge labels; its properties dialog stages the edit',
    (t) async {
      await t.binding.setSurfaceSize(const Size(1280, 820));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final door = shelf()
          .copy(along: axis(2), across: axis(0))
          .withDoorHinge(DoorHinge.left, towardEye: -axis(1), screenUp: axis(2))
          .swingDoor(1);
      final editor = Editor(Project('Шкаф', [door]))..select(1);
      await t.pumpWidget(NeprostoApp(editor: editor));
      await t.pumpAndSettle();

      Future<void> tap(Finder finder) async {
        await t.ensureVisible(finder);
        await t.tap(finder);
        await t.pumpAndSettle();
      }

      for (final save in [false, true]) {
        await tap(find.byTooltip('Свойства детали'));
        await tap(
          find.descendant(
            of: find.byType(DeskDialog),
            matching: find.byType(EdgeBandingButton),
          ),
        );
        await tap(find.text('Правый').hitTestable());
        await tap(find.text('Применить').hitTestable());
        expect(editor.single!.banding.edges, isEmpty);
        await tap(find.text(save ? 'Готово' : 'Отмена').hitTestable());
        expect(editor.canUndo, save);
      }
      expect(editor.single!.banding.edges, {PanelEdge.far});
      expect(editor.single!.doorOpen, isTrue);
      expect(editor.single!.banding.width, isNull);
    },
  );

  testWidgets(
    'Set two shelf edges, validate, cancel, remove and undo',
    (t) async {
      await t.binding.setSurfaceSize(const Size(1280, 820));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final editor = Editor(
        Project('Шкаф', [
          shelf(),
          shelf().copy(id: 2, origin: Vector3(0, 0, 40)),
        ]),
      )..select(1);
      await t.pumpWidget(NeprostoApp(editor: editor));
      await t.pumpAndSettle();

      Future<void> tap(Finder finder) async {
        await t.ensureVisible(finder);
        await t.tap(finder);
        await t.pumpAndSettle();
      }

      final button = find.byType(EdgeBandingButton);
      final fields = find.descendant(
        of: find.byType(DeskDialog),
        matching: find.byType(EditableText),
      );
      final apply = find.widgetWithText(DeskButton, 'Применить');
      await tap(button);
      expect(find.text('Цвет кромки'), findsOneWidget);
      final all = find.widgetWithText(DeskButton, 'Весь периметр');
      final clear = find.widgetWithText(DeskButton, 'Снять все');
      expect(t.widget<DeskButton>(clear).onPressed, isNull);
      await tap(all);
      expect(t.widget<DeskButton>(all).onPressed, isNull);
      await tap(clear);
      expect(t.widget<DeskButton>(clear).onPressed, isNull);
      final panel = t.getRect(find.byKey(const ValueKey('band-panel')));
      await t.tapAt(Offset(panel.left + 4, panel.bottom));
      await t.pumpAndSettle();
      await t.tapAt(Offset(panel.right, panel.top + 14));
      await t.pumpAndSettle();
      final auto = find.byKey(const ValueKey('band-auto-width'));
      expect(t.widget<Checkbox>(auto).value, isTrue);
      expect(t.widget<EditableText>(fields.at(1)).controller.text, '18');
      await tap(auto);
      await t.enterText(fields.at(0), '0,8');
      await t.enterText(fields.at(1), '22');
      await tap(auto);
      expect(t.widget<EditableText>(fields.at(1)).controller.text, '18');
      await tap(auto);
      expect(t.widget<EditableText>(fields.at(1)).controller.text, '22');
      await t.enterText(fields.at(2), 'xxx');
      await t.pump();
      expect(t.widget<DeskButton>(apply).onPressed, isNull);
      await t.enterText(fields.at(2), '#334455');
      await t.pump();
      await tap(apply);
      final band = editor.single!.banding;
      expect(band.edges, {PanelEdge.near, PanelEdge.end});
      expect(band.rgb, 0x334455);
      expect(band.thickness, .8);
      expect(band.width, 22);
      expect(editor.project.byId[2]!.banding.edges, isEmpty);
      await tap(button);
      await t.enterText(fields.first, '0');
      await t.pump();
      expect(t.widget<DeskButton>(apply).onPressed, isNull);
      await tap(find.text('Отмена'));
      expect(editor.single!.banding, band);
      await tap(button);
      expect(t.widget<Checkbox>(auto).value, isFalse);
      await tap(auto);
      await tap(apply);
      expect(editor.single!.banding.width, isNull);
      expect(editor.single!.banding.edges, band.edges);
      editor.undo();
      await t.pumpAndSettle();
      await tap(button);
      await tap(clear);
      await tap(apply);
      expect(editor.single!.banding, const EdgeBanding.none());
      editor.undo();
      expect(editor.single!.banding, band);
      editor.redo();
      expect(editor.single!.banding.edges, isEmpty);
    },
    variant: TargetPlatformVariant({
      TargetPlatform.macOS,
      TargetPlatform.windows,
    }),
  );
}
