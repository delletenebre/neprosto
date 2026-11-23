import 'package:flutter/foundation.dart' show setEquals;
import 'package:cupertino_ui/cupertino_ui.dart';

import 'hotkeys.dart';

import 'controller.dart';
import 'desktop.dart';
import 'joint_dialog.dart';
import 'size_dialog.dart';

Future<void> showDrawingMenu(
  BuildContext context,
  Editor editor,
  Offset position, {
  int? partId,
  VoidCallback? addHere,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  FocusManager.instance.applyFocusChangesIfNeeded();
  if (partId != null && !editor.selection.contains(partId)) {
    editor.setTool(Tool.select);
    editor.select(partId);
  }
  final part = editor.single;
  final doc = editor.project;
  final ids = {...editor.selection};
  final rows = <DeskPopupRow>[];
  final actions = <VoidCallback>[];
  void add(
    String label,
    IconData icon,
    String symbol,
    VoidCallback action, {
    String key = '',
    bool divider = false,
  }) {
    rows.add(
      DeskPopupRow(
        label,
        icon: icon,
        symbol: symbol,
        keyHint: key,
        breakBefore: divider,
      ),
    );
    actions.add(action);
  }

  final String heading;
  if (partId == null) {
    heading = 'Чертёж';
    if (addHere != null) {
      add('Новая деталь здесь', CupertinoIcons.plus, 'plus', addHere);
    }
    add(
      'Измерить расстояние',
      CupertinoIcons.resize,
      'ruler',
      () => editor.setTool(Tool.measure),
      key: editor.hotkeys[Command.measure].label,
    );
    if (doc.beams.isNotEmpty) {
      add(
        'Выбрать все детали',
        CupertinoIcons.square_stack,
        'square.dashed',
        () {
          editor.selection = doc.byId.keys.toSet();
          editor.refresh();
        },
        key: editor.hotkeys[Command.selectAll].label,
        divider: true,
      );
      add('Вписать в окно', CupertinoIcons.viewfinder, 'viewfinder', () {
        editor.fitRequested = true;
        editor.refresh();
      }, key: editor.hotkeys[Command.fit].label);
    }
  } else {
    heading = part?.name ?? 'Выбрано деталей · ${ids.length}';
    if (editor.canGroup) {
      add(
        'Сгруппировать',
        CupertinoIcons.square_stack,
        'square.3.layers.3d',
        editor.group,
        key: editor.hotkeys[Command.group].label,
      );
    }
    if (editor.canUngroup) {
      add(
        'Разгруппировать',
        CupertinoIcons.rectangle_on_rectangle_angled,
        'rectangle.on.rectangle.angled',
        editor.ungroup,
        key: editor.hotkeys[Command.ungroup].label,
      );
    }
    if (part != null) {
      add(
        'Название и размеры…',
        CupertinoIcons.pencil,
        'pencil.and.ruler',
        () => showPartProperties(context, editor, part, position),
      );
      if (doc.beams.length > 1) {
        add(
          'Выровнять по опоре…',
          CupertinoIcons.scope,
          'scope',
          editor.beginAlignment,
        );
      }
    }
    add(
      'Переместить по точкам…',
      CupertinoIcons.move,
      'arrow.up.and.down.and.arrow.left.and.right',
      () => editor.setTool(Tool.move),
      key: editor.hotkeys[Command.move].label,
      divider: rows.isNotEmpty,
    );
    add(
      'Повернуть…',
      CupertinoIcons.arrow_clockwise,
      'arrow.clockwise',
      () => editor.setTool(Tool.rotate),
      key: editor.hotkeys[Command.rotate].label,
    );
    if (ids.length == 2) {
      add(
        'Угловой стык…',
        CupertinoIcons.triangle,
        'triangle',
        () => showPartJoint(context, editor),
      );
    }
    add(
      'Дублировать',
      CupertinoIcons.doc_on_doc,
      'doc.on.doc',
      editor.duplicate,
      key: editor.hotkeys[Command.duplicate].label,
      divider: true,
    );
    add(
      'Удалить',
      CupertinoIcons.trash,
      'trash',
      editor.delete,
      key: editor.hotkeys[Command.delete].label,
    );
  }
  // Paint a newly selected part before AppKit starts tracking the menu.
  await WidgetsBinding.instance.endOfFrame;
  if (!context.mounted) return;
  final index = await showDeskPopup(
    context,
    position,
    title: heading,
    rows: rows,
    showTitle: true,
  );
  if (index == null ||
      !context.mounted ||
      !identical(editor.project, doc) ||
      !setEquals(ids, editor.selection)) {
    return;
  }
  editor.setTool(Tool.select);
  actions[index]();
}
