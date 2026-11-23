import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neprosto/editor/controller.dart';
import 'package:neprosto/editor/hotkeys.dart';
import 'package:neprosto/editor/model.dart';
import 'package:neprosto/editor/scene.dart';
import 'package:neprosto/main.dart';

void main() {
  testWidgets('Record, cancel, apply and reset custom drawing shortcuts', (
    t,
  ) async {
    await t.binding.setSurfaceSize(const Size(1200, 780));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final e = Editor(Project.bench());
    await t.pumpWidget(NeprostoApp(editor: e));
    await t.pumpAndSettle();
    Future<void> keyboard() async {
      await t.tap(find.byTooltip('Настройки'));
      await t.pumpAndSettle();
      await t.tap(find.text('Горячие клавиши'));
      await t.pumpAndSettle();
    }

    Future<void> record(Command cmd, LogicalKeyboardKey key) async {
      final control = find.byKey(ValueKey('shortcut-${cmd.name}'));
      await t.ensureVisible(control);
      await t.pumpAndSettle();
      await t.tap(control);
      await t.sendKeyEvent(key);
      await t.pumpAndSettle();
    }

    await keyboard();
    await record(Command.add, LogicalKeyboardKey.keyM);
    expect(find.textContaining('Уже назначено'), findsOneWidget);
    expect(e.tool, Tool.select);
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await t.pumpAndSettle();
    await record(Command.add, LogicalKeyboardKey.keyK);
    await t.tap(find.text('Отмена'));
    await t.pumpAndSettle();
    expect(e.hotkeys[Command.add], Command.add.standard);
    await keyboard();
    await record(Command.add, LogicalKeyboardKey.keyK);
    await record(Command.dimensions, LogicalKeyboardKey.keyL);
    await t.tap(find.text('Готово'));
    await t.pumpAndSettle();
    expect(find.byTooltip('Новая деталь · K'), findsOneWidget);
    expect(EditorHotkeys.decode(e.hotkeys.encode())[Command.add].label, 'K');
    await t.sendKeyEvent(LogicalKeyboardKey.keyQ);
    await t.sendKeyEvent(LogicalKeyboardKey.keyB);
    expect(e.tool, Tool.select);
    await t.sendKeyEvent(LogicalKeyboardKey.keyK);
    expect(e.tool, Tool.beam);
    await t.sendKeyDownEvent(LogicalKeyboardKey.keyL);
    expect(e.dimensionsVisible, false);
    await t.sendKeyUpEvent(LogicalKeyboardKey.keyL);
    expect(e.dimensionsVisible, true);
    await keyboard();
    await t.tap(find.text('Сбросить сочетания'));
    await t.pumpAndSettle();
    await t.tap(find.text('Готово'));
    await t.pumpAndSettle();
    expect(e.hotkeys.customized, false);
  });

  testWidgets('Workspace boundaries use project units and undo as one edit', (
    t,
  ) async {
    await t.binding.setSurfaceSize(const Size(1100, 650));
    addTearDown(() => t.binding.setSurfaceSize(null));
    final p = Project.bench().copy(unit: LengthUnit.centimeter);
    final e = Editor(p);
    await t.pumpWidget(NeprostoApp(editor: e));
    await t.pumpAndSettle();
    await t.tap(find.byTooltip('Настройки'));
    await t.pumpAndSettle();
    await t.tap(find.text('Пространство'));
    await t.pumpAndSettle();
    await t.tap(find.byType(CupertinoSwitch).last);
    await t.pumpAndSettle();
    final width = find.descendant(
      of: find.byKey(const ValueKey('workspace-0')),
      matching: find.byType(CupertinoTextField),
    );
    await t.enterText(width, '4*50');
    await t.pumpAndSettle();
    await t.tap(find.text('Готово'));
    await t.pumpAndSettle();
    expect(e.project.workspaceSize, Vector3(2000, 3000, 2500));
    expect(e.project.beams, p.beams);
    expect(
      Project.decode(e.project.encode()).workspaceSize,
      e.project.workspaceSize,
    );
    expect(
      e.project.copy(name: 'Копия').workspaceSize,
      e.project.workspaceSize,
    );
    e.undo();
    expect(e.project, same(p));
    e.redo();
    expect(e.project.workspaceSize?.x, 2000);
    final empty = Project(
      'Помещение',
      [],
    ).withWorkspace(e.project.workspaceSize);
    const size = Size(900, 540);
    for (final view in ViewAngle.values) {
      final camera = Camera()
        ..view(view)
        ..fit(empty, size);
      for (final point in empty.workspaceCorners) {
        expect(
          (Offset.zero & size).contains(camera.project(point, size)),
          true,
        );
      }
    }
  });
}
