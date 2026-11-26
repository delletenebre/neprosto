import '../l10n/strings.dart';

import 'package:flutter/foundation.dart' show setEquals;
import 'package:cupertino_ui/cupertino_ui.dart';

import 'hotkeys.dart';

import 'controller.dart';
import 'connection_picker.dart';
import 'edge_banding_dialog.dart';
import 'desktop.dart';
import 'end_cut_dialog.dart';
import 'rabbet_dialog.dart';
import 'hole_dialog.dart';
import 'joint_dialog.dart';
import 'name_dialog.dart';
import 'scene.dart';
import 'size_dialog.dart';

Future<void> showDrawingMenu(
  BuildContext context,
  Editor editor,
  Offset position, {
  int? partId,
  DialogSource? source,
  WorkPlane? facePlane,
  bool? end,
  VoidCallback? addHere,
}) async {
  FocusManager.instance.primaryFocus?.unfocus();
  FocusManager.instance.applyFocusChangesIfNeeded();
  final clicked = editor.project.byId[partId];
  if (clicked != null &&
      !clicked.hidden &&
      !editor.selection.contains(partId)) {
    editor.setTool(Tool.select);
    editor.select(partId);
  }
  final part = editor.single;
  final group = editor.selectedGroup;
  final groupDoor = editor.project.groupDoors[group];
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
    heading = context.strings.drawing;
    if (editor.canAddConnection) {
      add(
        context.strings.addConnection,
        CupertinoIcons.link,
        'link',
        () => chooseConnection(context, editor),
      );
    }
    if (addHere != null) {
      add(context.strings.newPartHere, CupertinoIcons.plus, 'plus', addHere);
    }
    add(
      context.strings.measureDistance,
      CupertinoIcons.resize,
      'ruler',
      () => editor.setTool(Tool.ruler),
      key: editor.hotkeys[Command.measure].label,
    );
    if (doc.visibleGeometry.beams.isNotEmpty) {
      add(
        context.strings.selectAllParts,
        CupertinoIcons.square_stack,
        'square.dashed',
        editor.selectAll,
        key: editor.hotkeys[Command.selectAll].label,
        divider: true,
      );
      add(
        context.strings.fitToWindow,
        CupertinoIcons.viewfinder,
        'viewfinder',
        () {
          editor.fitRequested = true;
          editor.refresh();
        },
        key: editor.hotkeys[Command.fit].label,
      );
    }
    if (doc.hasHiddenParts) {
      add(
        context.strings.showAllParts,
        CupertinoIcons.eye,
        'eye',
        editor.showAllHiddenParts,
      );
    }
  } else if (clicked != null && clicked.hidden) {
    heading = clicked.name;
    add(
      context.strings.showPart,
      CupertinoIcons.eye,
      'eye',
      () => editor.setPartsHidden({clicked.id}, false),
    );
  } else {
    heading = group == null
        ? part?.name ?? context.strings.selectedParts(ids.length)
        : doc.groupName(group);
    if (facePlane != null) {
      add(
        context.strings.buildInThisPlane,
        CupertinoIcons.layers,
        'square.2.layers.3d',
        () => editor.setPlane(facePlane),
      );
    }
    if (editor.canGroup) {
      add(
        context.strings.groupLabel,
        CupertinoIcons.square_stack,
        'square.3.layers.3d',
        editor.group,
        key: editor.hotkeys[Command.group].label,
      );
    }
    if (editor.canUngroup) {
      add(
        context.strings.ungroup,
        CupertinoIcons.rectangle_on_rectangle_angled,
        'rectangle.on.rectangle.angled',
        editor.ungroup,
        key: editor.hotkeys[Command.ungroup].label,
      );
    }
    if (group != null && groupDoor != null) {
      add(
        groupDoor.isOpen ? context.strings.closeDoor : context.strings.openDoor,
        CupertinoIcons.arrow_turn_up_right,
        'arrow.turn.up.right',
        () => editor.toggleGroupDoor(group),
      );
    } else if (group == null && part != null && part.hinge != null) {
      add(
        part.doorOpen ? context.strings.closeDoor : context.strings.openDoor,
        CupertinoIcons.arrow_turn_up_right,
        'arrow.turn.up.right',
        () => editor.toggleDoor(part.id),
      );
    }
    if (group != null || part != null) {
      add(
        context.strings.nameAndDimensions,
        CupertinoIcons.pencil,
        'pencil.and.ruler',
        () => showPartProperties(context, editor, position),
      );
      add(
        '${context.strings.properties}…',
        CupertinoIcons.slider_horizontal_3,
        'slider.horizontal.3',
        () => showSelectionProperties(context, editor),
      );
    }
    if (group == null && part != null) {
      add(
        context.strings.endCutsTitle,
        CupertinoIcons.triangle,
        'triangle',
        () => showEndCuts(context, editor, part, end: end),
      );
      add(
        context.strings.rabbetTitle,
        CupertinoIcons.crop,
        'crop',
        () => showRabbets(context, editor, part),
      );
      add(
        context.strings.addConnection,
        CupertinoIcons.link,
        'link',
        () => chooseConnection(context, editor),
      );
      add(
        context.strings.panelHoles,
        CupertinoIcons.circle,
        'circle',
        () => showPanelHoles(context, editor, part),
      );
      if (part.supportsEdgeBanding) {
        add(
          context.strings.edgeBanding,
          CupertinoIcons.rectangle,
          'rectangle',
          () => showEdgeBanding(context, editor, part),
        );
      }
      if (doc.visibleGeometry.beams.length > 1) {
        add(
          context.strings.alignToReference,
          CupertinoIcons.scope,
          'scope',
          () => editor.beginAlignment(pickReference: true),
        );
      }
    }
    if (ids.length == 2 && editor.canAddConnection) {
      add(
        context.strings.addConnection,
        CupertinoIcons.link,
        'link',
        () => chooseConnection(context, editor),
      );
    }
    add(
      context.strings.placeAgainstReference,
      CupertinoIcons.move,
      'arrow.up.and.down.and.arrow.left.and.right',
      () => editor.setTool(Tool.move),
      key: editor.hotkeys[Command.move].label,
      divider: rows.isNotEmpty,
    );
    add(
      context.strings.rotateMenu,
      CupertinoIcons.arrow_clockwise,
      'arrow.clockwise',
      () => editor.setTool(Tool.rotate),
      key: editor.hotkeys[Command.rotate].label,
    );
    if (editor.selectedJoint != null) {
      add(
        context.strings.miterJointMenu,
        CupertinoIcons.triangle,
        'triangle',
        () => showPartJoint(context, editor),
      );
    }
    final hideKey = editor.hotkeys[Command.hideSelected];
    add(
      ids.length == 1
          ? context.strings.hidePart
          : context.strings.hideSelectedParts,
      CupertinoIcons.eye_slash,
      'eye.slash',
      () => editor.setPartsHidden(ids, true),
      key: editor.hotkeys.commandFor(hideKey) == Command.hideSelected
          ? hideKey.label
          : '',
      divider: true,
    );
    add(
      context.strings.duplicate,
      CupertinoIcons.doc_on_doc,
      'doc.on.doc',
      editor.duplicate,
      key: editor.hotkeys[Command.duplicate].label,
      divider: true,
    );
    add(
      context.strings.delete,
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
    source: source,
  );
  if (index == null ||
      !context.mounted ||
      !identical(editor.project, doc) ||
      !setEquals(ids, editor.selection)) {
    return;
  }
  editor.setTool(Tool.select);
  DialogSource.invoke(source, actions[index]);
}
