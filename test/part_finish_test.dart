import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:neprosto/editor/controller.dart';
import 'package:neprosto/editor/desktop.dart';
import 'package:neprosto/editor/edge_banding_dialog.dart';
import 'package:neprosto/editor/finish_picker.dart';
import 'package:neprosto/editor/model.dart';
import 'package:neprosto/editor/part_finish.dart';
import 'package:neprosto/editor/scene.dart';
import 'package:neprosto/main.dart';

void main() {
  test('Legacy projects use wood and custom finishes survive duplication and saving', () {
    final beam = Project.bench().beams.first;
    final legacy = beam.toJson()..remove('finish');
    expect(Beam.fromJson(legacy).finish, woodFinish);
    const finish = (texture: PartTexture.brushedMetal, rgb: 0x224466);
    final editor = Editor(Project('Sample', [beam.copy(finish: finish)]))
      ..select(beam.id)
      ..duplicate();
    expect(Project.decode(editor.project.encode()).beams.map((b) => b.finish), [
      finish,
      finish,
    ]);
    for (final invalid in [
      {'texture': 'unknown', 'rgb': 0},
      {'texture': 'wood', 'rgb': -1},
      {'texture': 'wood', 'rgb': 0x1000000},
    ]) {
      expect(
        () => Beam.fromJson({...legacy, 'finish': invalid}),
        throwsFormatException,
      );
    }
  });

  testWidgets('Double-click part properties stage material until applied', (
    t,
  ) async {
    await t.binding.setSurfaceSize(const Size(1350, 840));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final editor = Editor(Project.bench())..setView(ViewAngle.top);
    await t.pumpWidget(NeprostoApp(editor: editor));
    await t.pumpAndSettle();
    final drawing = find.byKey(const Key('drawing'));
    final at =
        t.getTopLeft(drawing) +
        editor.camera.project(Vector3(240, 40, 450), t.getSize(drawing));
    final dialog = find.byType(DeskDialog);
    Future<void> tap(Finder finder) async {
      await t.tap(finder);
      await t.pumpAndSettle();
    }

    Future<void> stageBoard() async {
      await t.tapAt(at);
      await t.pump(const Duration(milliseconds: 90));
      await t.tapAt(at);
      await t.pumpAndSettle();
      await tap(
        find.descendant(of: dialog, matching: find.byType(PartFinishButton)),
      );
      await tap(
        find
            .descendant(
              of: find.byType(DeskSegments<PartMaterial>),
              matching: find.text('ДПМ'),
            )
            .hitTestable(),
      );
      await tap(find.text('Применить').hitTestable());
      expect(editor.single!.finish, woodFinish);
    }

    await stageBoard();
    await tap(find.text('Отмена').hitTestable());
    expect(editor.canUndo, isFalse);
    await stageBoard();
    await tap(find.text('Применить').hitTestable());
    expect(editor.single!.finish, FinishPreset.whiteBoard.finish);
    expect(find.byType(EdgeBandingButton), findsOneWidget);
    editor.undo();
    await t.pumpAndSettle();
    expect(find.byType(EdgeBandingButton), findsNothing);
    expect(editor.single!.finish, woodFinish);
  });

  testWidgets(
    'Material and custom color apply as one part edit',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final editor = Editor(Project.bench())..select(1);
      await tester.pumpWidget(NeprostoApp(editor: editor));
      await tester.pumpAndSettle();
      final button = find.byType(PartFinishButton);
      final dialog = find.byType(DeskDialog);
      Finder inside(Finder finder) =>
          find.descendant(of: dialog, matching: finder);
      Future<void> tap(Finder finder) async {
        await tester.tap(finder);
        await tester.pumpAndSettle();
      }

      expect(find.byType(EdgeBandingButton), findsNothing);
      await tester.ensureVisible(button);
      await tap(button);
      final input = inside(find.byType(EditableText));
      expect(inside(find.text('Готовые образцы')), findsNothing);
      expect(inside(find.byType(DropdownButton<FinishPreset>)), findsNothing);
      final materials = inside(find.byType(DeskSegments<PartMaterial>));
      PartMaterial selected() =>
          tester.widget<DeskSegments<PartMaterial>>(materials).value;
      Finder segment(String label) => find
          .descendant(of: materials, matching: find.text(label))
          .hitTestable();
      for (final label in ['ДПМ', 'Дерево', 'Металл']) {
        expect(segment(label), findsOneWidget);
      }
      expect(selected(), PartMaterial.wood);
      await tap(segment('ДПМ'));
      expect(selected(), PartMaterial.panel);
      expect(tester.widget<EditableText>(input).controller.text, '#F4F2EC');
      await tap(find.byTooltip('Дуб · #B39474'));
      expect(tester.widget<EditableText>(input).controller.text, '#B39474');
      expect(selected(), PartMaterial.panel);
      await tap(segment('Металл'));
      await tap(segment('ДПМ'));
      expect(tester.widget<EditableText>(input).controller.text, '#B39474');
      await tap(inside(find.text('Отмена')));
      expect(editor.canUndo, isFalse);
      await tap(button);
      await tap(segment('Металл'));
      expect(tester.widget<EditableText>(input).controller.text, '#B0B8C1');
      expect(selected(), PartMaterial.metal);
      await tester.enterText(input, '22xx');
      await tester.pump();
      final apply = inside(find.text('Применить'));
      expect(
        tester
            .widget<DeskButton>(
              find.ancestor(of: apply, matching: find.byType(DeskButton)),
            )
            .onPressed,
        isNull,
      );
      await tester.enterText(input, '#225599');
      await tester.pump();
      await tap(apply);
      const custom = (texture: PartTexture.brushedMetal, rgb: 0x225599);
      expect(editor.single!.finish, custom);
      expect(find.byType(EdgeBandingButton), findsNothing);
      expect(editor.project.byId[2]!.finish, woodFinish);
      editor.undo();
      expect(editor.single!.finish, woodFinish);
      editor.redo();
      expect(editor.single!.finish, custom);
    },
    variant: TargetPlatformVariant({
      TargetPlatform.macOS,
      TargetPlatform.windows,
    }),
  );
}
