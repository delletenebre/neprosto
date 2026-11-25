import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neprosto/editor/controller.dart';
import 'package:neprosto/editor/desktop.dart';
import 'package:neprosto/editor/inspector.dart';
import 'package:neprosto/editor/model.dart';
import 'package:neprosto/editor/project_templates.dart';
import 'package:neprosto/main.dart';

void main() {
  final chest = FurnitureTemplate.toyChest.build(LengthUnit.millimeter);
  final group = chest.groupDoors.keys.single;
  final lid = chest.beams.where((b) => b.group == group).toList();
  final bounds = Bounds3.points(lid.expand((b) => b.corners));

  test('The lid and its underside rails lift together about the rear edge', () {
    expect(chest.groupNames[group], 'Крышка');
    expect(lid, hasLength(12));
    final editor = Editor(chest.withDefaultWorkspace())..select(lid.last.id);
    expect(editor.selectedGroup, group);
    final pivot = Vector3(0, bounds.high.y, bounds.high.z);
    editor.toggleGroupDoor(group);
    for (final t in [.5, 1.0]) {
      final pose = t == 1 ? editor.project : editor.doorSwing!.frame(t);
      for (final b in chest.beams) {
        if (b.group != group) {
          expect(pose.byId[b.id], same(b));
          continue;
        }
        for (var i = 0; i < 8; i++) {
          final p = b.corner(i);
          final expected = pivot + turn(p - pivot, axis(0), -t * math.pi / 2);
          expect(
            pose.byId[b.id]!.corner(i).distanceTo(expected),
            lessThan(1e-7),
          );
        }
      }
    }
    final reopened = Editor(Project.decode(editor.project.encode()));
    expect(reopened.project.groupDoors[group]!.isOpen, isTrue);
    reopened.toggleGroupDoor(group);
    for (final original in lid) {
      final closed = reopened.project.byId[original.id]!;
      for (var i = 0; i < 8; i++) {
        expect(closed.corner(i).distanceTo(original.corner(i)), lessThan(1e-7));
      }
    }
    reopened.undo();
    expect(reopened.project.groupDoors[group]!.isOpen, isTrue);
  });

  test(
    'A rotated duplicate keeps a separate working hinge and hidden members',
    () {
      final editor = Editor(chest)..setPartsHidden({lid.first.id}, true);
      editor.select(lid.last.id);
      editor.duplicate();
      final copy = editor.selectedGroup!;
      expect(copy, isNot(group));
      final members = editor.project.assembly(editor.selection.first);
      expect(members, hasLength(lid.length));
      final rotated = editor.project.rotate(
        members,
        Vector3(1, 1, 0).normalized(),
        33,
      );
      editor.commit(rotated);
      final door = rotated.groupDoors[copy]!;
      final member = rotated.byId[members.first]!;
      editor.toggleGroupDoor(copy);
      expect(editor.project.groupDoors[group]!.isOpen, isFalse);
      expect(editor.project.groupDoors[copy]!.isOpen, isTrue);
      for (final b in lid) {
        expect(editor.project.byId[b.id], same(rotated.byId[b.id]));
      }
      expect(editor.project.byId[member.id]!.origin, isNot(member.origin));
      editor.commit(
        editor.configureGroupDoor(editor.project, copy, DoorHinge.right, 115),
      );
      expect(editor.project.groupDoors[copy]!.isOpen, isTrue);
      editor.toggleGroupDoor(copy);
      for (final id in members) {
        for (var i = 0; i < 8; i++) {
          expect(
            editor.project.byId[id]!
                .corner(i)
                .distanceTo(rotated.byId[id]!.corner(i)),
            lessThan(1e-7),
          );
        }
      }
      expect(
        editor.project.groupDoors[copy]!.top.distanceTo(door.top),
        lessThan(1e-7),
      );
      editor.ungroup();
      expect(editor.project.groupDoors.keys, [group]);
    },
  );

  testWidgets(
    'Group dimensions move the whole frame and stretch its free rail',
    (t) async {
      await t.binding.setSurfaceSize(const Size(1320, 900));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final post = Beam(
        1,
        'Стойка',
        Vector3.zero(),
        Vector3(400, 30, 40),
        axis(2),
        axis(0),
        locks: 6,
        group: 2,
      );
      final rail = Beam(
        3,
        'Царга',
        Vector3(30, 0, 360),
        Vector3(940, 40, 40),
        axis(0),
        axis(1),
        locks: 6,
        group: 2,
      );
      final other = post.copy(
        id: 4,
        ungroup: true,
        origin: Vector3(2000, 0, 0),
      );
      final project = Project('Рама', [
        post,
        post.copy(id: 2, hidden: true, origin: Vector3(970, 0, 0)),
        rail,
        other,
      ]);
      final editor = Editor(project)..select(post.id);
      await t.pumpWidget(NeprostoApp(editor: editor));
      await t.pumpAndSettle();
      Future<void> open() async {
        await t.tap(
          find.descendant(
            of: find.byType(Inspector),
            matching: find.text('Группа 2'),
          ),
        );
        await t.pumpAndSettle();
      }

      Finder field(String key) => find.descendant(
        of: find.byKey(ValueKey(key)),
        matching: find.byType(EditableText),
      );
      final apply = find.widgetWithText(DeskButton, 'Применить');
      await open();
      expect(
        t.widget<EditableText>(field('group-extent-0')).controller.text,
        '1000',
      );
      await t.enterText(field('group-extent-0'), '1200');
      await t.enterText(field('group-extent-1'), '20');
      await t.pump();
      expect(t.widget<DeskButton>(apply).onPressed, isNull);
      await t.tap(find.text('Отмена'));
      await t.pumpAndSettle();
      expect(editor.project, same(project));
      await open();
      await t.enterText(field('group-extent-0'), '1200');
      await t.enterText(field('dialog-position-0'), '50');
      await t.enterText(field('group-dialog-name'), 'Каркас');
      await t.tap(apply);
      await t.pumpAndSettle();
      final result = editor.project;
      expect(result.groupNames[2], 'Каркас');
      expect(result.byId[1]!.origin.x, 50);
      expect(result.byId[2]!.origin.x, 1220);
      expect(result.byId[2]!.size, post.size);
      expect(result.byId[2]!.hidden, isTrue);
      expect(result.byId[3]!.size.x, 1140);
      expect(result.byId[3]!.origin.x, 80);
      expect(result.byId[3]!.corner(1).x, result.byId[2]!.origin.x);
      expect(result.byId[4], same(other));
      editor.undo();
      expect(editor.project, same(project));
      expect(editor.canUndo, isFalse);
    },
  );

  testWidgets(
    'Group properties apply a hinge and the inspector opens the assembly',
    (t) async {
      await t.binding.setSurfaceSize(const Size(1320, 900));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final loose = Project('Ящик', lid.map((b) => b.copy(ungroup: true)));
      final editor = Editor(loose)
        ..selectAll()
        ..group();
      final id = editor.selectedGroup!;
      await t.pumpWidget(NeprostoApp(editor: editor));
      await t.pumpAndSettle();
      Future<void> tap(Finder control) async {
        await t.tap(control);
        await t.pumpAndSettle();
      }

      final before = editor.project;
      final title = find.descendant(
        of: find.byType(Inspector),
        matching: find.text('Группа $id'),
      );
      final nameField = find.byKey(const ValueKey('rename-field'));
      await tap(title);
      expect(find.byKey(const ValueKey('group-extent-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('dialog-position-0')), findsOneWidget);
      expect(find.text('Тип группы'), findsNothing);
      await tap(find.text('Отмена'));
      final properties = find.byTooltip('Свойства группы');
      await tap(properties);
      expect(find.text('Название группы'), findsOneWidget);
      expect(find.text('Элемент'), findsOneWidget);
      final input = find.descendant(
        of: nameField,
        matching: find.byType(EditableText),
      );
      expect(t.widget<EditableText>(input).controller.text, 'Группа $id');
      expect(t.widget<EditableText>(input).focusNode.hasFocus, isTrue);
      await t.enterText(nameField, 'Черновик');
      await tap(find.text('Дверца'));
      await tap(find.text('Отмена'));
      expect(editor.project, same(before));
      await tap(properties);
      await t.enterText(nameField, '   ');
      await t.pump();
      final done = find.ancestor(
        of: find.text('Готово'),
        matching: find.byType(DeskButton),
      );
      expect(t.widget<DeskButton>(done).onPressed, isNull);
      await t.enterText(nameField, '  Крышка ящика  ');
      await tap(find.text('Дверца'));
      final diagram = t.getRect(find.byKey(const ValueKey('hinge-diagram')));
      await t.tapAt(diagram.topCenter + const Offset(0, 16));
      await t.pumpAndSettle();
      await tap(done);
      expect(editor.project.groupNames[id], 'Крышка ящика');
      expect(editor.project.groupDoors[id]?.hinge, DoorHinge.top);
      expect(
        Project.decode(editor.project.encode()).groupNames[id],
        'Крышка ящика',
      );
      final renamed = editor.project;
      editor.undo();
      expect(editor.project, same(before));
      editor.redo();
      await t.pumpAndSettle();
      expect(editor.project, same(renamed));
      await tap(find.text('Открыть дверцу'));
      expect(editor.project.groupDoors[id]?.isOpen, isTrue);
      await tap(find.text('Закрыть дверцу'));
      expect(editor.project.groupDoors[id]?.isOpen, isFalse);
      final header = find.byKey(ValueKey('group-header-$id'));
      await t.tap(
        header,
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await t.pumpAndSettle();
      await tap(find.text('Название и размеры…'));
      final fullName = find.byKey(const ValueKey('group-dialog-name'));
      await t.enterText(fullName, 'Верхняя крышка');
      await tap(find.text('Применить'));
      expect(editor.project.groupNames[id], 'Верхняя крышка');
      expect(editor.project.groupDoors[id]?.hinge, DoorHinge.top);
      expect(t.takeException(), isNull);
    },
  );
}
