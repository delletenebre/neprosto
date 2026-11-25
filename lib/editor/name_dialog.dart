import 'package:flutter/widgets.dart';

import '../l10n/strings.dart';
import 'controller.dart';
import 'desk_text_field.dart';
import 'desktop.dart';
import 'model.dart';
import 'part_type_picker.dart';

Future<String?> showNameDialog(
  BuildContext context,
  String title,
  String value, {
  DoorSettingsDraft? door,
  bool group = false,
  DialogSource? source,
}) {
  var result = value;
  return showDeskDialog<String>(
    source: source,
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (_, update) {
        final ready = result.trim().isNotEmpty && (door?.valid ?? true);
        void submit() {
          if (result.trim().isNotEmpty && (door?.valid ?? true)) {
            Navigator.pop(ctx, result.trim());
          }
        }

        return DeskDialog(
          title: Text(title),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 12,
              children: [
                DeskTextField(
                  key: const ValueKey('rename-field'),
                  initialValue: value,
                  autofocus: true,
                  onChanged: (v) => update(() => result = v),
                  onSubmitted: (_) => submit(),
                ),
                if (door != null)
                  PartTypePicker(
                    door,
                    group: group,
                    refresh: () => update(() {}),
                    submit: submit,
                  ),
              ],
            ),
          ),
          actions: [
            DeskButton(
              plain: true,
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.strings.cancel),
            ),
            DeskButton(
              primary: true,
              onPressed: ready ? submit : null,
              child: Text(context.strings.done),
            ),
          ],
        );
      },
    ),
  );
}

Future<void> _editPartProperties(
  BuildContext context,
  Editor editor,
  Beam part,
) async {
  final door = DoorSettingsDraft(part);
  final name = await showNameDialog(
    context,
    context.strings.partName,
    part.name,
    door: door,
  );
  if (name == null ||
      !context.mounted ||
      editor.project.byId[part.id] != part) {
    return;
  }
  if (name == part.name &&
      door.hinge == part.hinge &&
      (door.hinge == null || door.angle == part.openingAngle)) {
    return;
  }
  final named = name == part.name ? part : part.copy(name: name);
  final updated = editor.configureDoor(named, door.hinge, angle: door.angle);
  editor.commit(editor.project.edit({part.id}, (_) => updated));
}

Future<void> showSelectionProperties(
  BuildContext context,
  Editor editor,
) async {
  final group = editor.selectedGroup;
  if (group == null) {
    final part = editor.single;
    if (part != null) await _editPartProperties(context, editor, part);
    return;
  }
  final project = editor.project;
  final door = DoorSettingsDraft.group(project.groupDoors[group]);
  final name = await showNameDialog(
    context,
    context.strings.groupName,
    project.groupName(group),
    door: door,
    group: true,
  );
  if (name == null || !context.mounted || !identical(editor.project, project)) {
    return;
  }
  editor.commit(
    editor.configureGroupDoor(
      project.withGroupName(group, name),
      group,
      door.hinge,
      door.angle,
    ),
  );
}
