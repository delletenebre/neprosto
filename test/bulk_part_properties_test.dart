import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:neprosto/editor/controller.dart';
import 'package:neprosto/editor/desk_text_field.dart';
import 'package:neprosto/editor/desktop.dart';
import 'package:neprosto/editor/finish_picker.dart';
import 'package:neprosto/editor/model.dart';
import 'package:neprosto/editor/part_finish.dart';
import 'package:neprosto/editor/parts_panel.dart';
import 'package:neprosto/editor/scene.dart';
import 'package:neprosto/main.dart';

void main() {
  final dialog = find.byType(DeskDialog);
  Finder input(int axis) => find.descendant(
    of: find.byKey(ValueKey('dialog-size-$axis')),
    matching: find.byType(DeskTextField),
  );
  Future<void> doubleClick(WidgetTester t, Offset at) async {
    await t.tapAt(at, kind: PointerDeviceKind.mouse);
    await t.pump(kDoubleTapMinTime);
    await t.tapAt(at, kind: PointerDeviceKind.mouse);
    await t.pumpAndSettle();
  }

  Future<void> mount(WidgetTester t, Editor e) async {
    await t.binding.setSurfaceSize(const Size(1350, 840));
    addTearDown(() => t.binding.setSurfaceSize(null));
    await t.pumpWidget(NeprostoApp(editor: e));
    await t.pumpAndSettle();
  }

  testWidgets(
    'Canvas double-click edits parts selected in the tree in one undo',
    (t) async {
      final project = Project.bench().edit(
        {2},
        (b) => b.copy(
          size: Vector3(800, 65, 36),
          locks: 1,
          finish: FinishPreset.plywood.finish,
          rabbets: const {RabbetEdge.topLeft: (width: 15, depth: 8)},
        ),
      );
      final e = Editor(project)..setView(ViewAngle.top);
      await mount(t, e);
      Finder row(int id) => find.descendant(
        of: find.byType(PartsPanel),
        matching: find.text(project.byId[id]!.name),
      );
      await t.tap(row(1), kind: PointerDeviceKind.mouse);
      await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await t.tap(row(2), kind: PointerDeviceKind.mouse);
      await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await t.pumpAndSettle();
      final drawing = find.byKey(const Key('drawing'));
      final board = project.byId[2]!.pointAt(Vector3(.4, .5, 1));
      await doubleClick(
        t,
        t.getTopLeft(drawing) + e.camera.project(board, t.getSize(drawing)),
      );
      expect(e.selection, {1, 2});
      expect(
        find.descendant(of: dialog, matching: find.text('Выбрано деталей · 2')),
        findsOneWidget,
      );
      expect(t.widget<DeskTextField>(input(0)).enabled, isFalse);
      expect(t.widget<DeskTextField>(input(1)).placeholder, 'Разные');
      expect(t.widget<DeskTextField>(input(2)).controller!.text, '36');
      final finish = find.descendant(
        of: dialog,
        matching: find.byType(PartFinishButton),
      );
      expect(t.widget<PartFinishButton>(finish).finish, isNull);
      await t.enterText(input(1), '12');
      await t.pump();
      final apply = find.ancestor(
        of: find.text('Применить'),
        matching: find.byType(DeskButton),
      );
      expect(t.widget<DeskButton>(apply).onPressed, isNull);
      await t.enterText(input(1), '');
      await t.enterText(input(2), '9*2');
      await t.tap(finish);
      await t.pumpAndSettle();
      await t.tap(find.text('ЛДСП · дуб'));
      await t.tap(find.text('Применить').hitTestable());
      await t.pumpAndSettle();
      expect(e.project, same(project));
      await t.tap(apply);
      await t.pumpAndSettle();
      for (final b in e.selected) {
        final original = project.byId[b.id]!;
        expect(b.size, Vector3(original.size.x, original.size.y, 18));
        expect(b.name, original.name);
        expect(b.origin, original.origin);
        expect(b.locks, original.locks);
        expect(b.rabbets, original.rabbets);
        expect(b.finish, FinishPreset.oakBoard.finish);
      }
      expect(e.selection, {1, 2});
      expect(e.project.byId[3], same(project.byId[3]));
      final edited = e.project;
      e.undo();
      expect(e.project, same(project));
      expect(e.canUndo, isFalse);
      e.redo();
      expect(e.project, same(edited));
    },
  );

  testWidgets(
    'Canvas double-click keeps the selection and stages edits until applied',
    (t) async {
      final project = Project.bench().edit(
        {2},
        (b) => b.copy(
          size: Vector3(800, 65, 12),
          finish: FinishPreset.plywood.finish,
        ),
      );
      final e = Editor(project)..setView(ViewAngle.top);
      await mount(t, e);
      final drawing = find.byKey(const Key('drawing'));
      Offset board(int id) =>
          t.getTopLeft(drawing) +
          e.camera.project(
            project.byId[id]!.pointAt(Vector3(.4, .5, 1)),
            t.getSize(drawing),
          );
      await t.tapAt(board(1));
      await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await t.tapAt(board(2));
      await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await t.pump(kDoubleTapMinTime);
      await doubleClick(t, board(2));
      expect(e.selection, {1, 2});
      await t.enterText(input(0), '600');
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
      expect(e.project, same(project));
      await doubleClick(t, board(2));
      await t.tap(find.text('Применить'));
      await t.pumpAndSettle();
      expect(e.canUndo, isFalse);
      await doubleClick(t, board(2));
      await t.enterText(input(1), '84');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pumpAndSettle();
      expect(dialog, findsNothing);
      expect(e.project.byId[1], same(project.byId[1]));
      expect(e.project.byId[2]!.size, Vector3(800, 84, 12));
      expect(e.project.byId[2]!.finish, FinishPreset.plywood.finish);
      expect(e.selection, {1, 2});
    },
  );
}
