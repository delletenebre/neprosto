import '../l10n/strings.dart';
import 'palette.dart';
import 'desk_text_field.dart';

import 'dart:math' as math;

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/services.dart';

import 'assembly.dart';
import 'controls.dart';
import 'desktop.dart';
import 'finish_picker.dart';
import 'model.dart';
import 'step.dart';
import 'part_type_picker.dart';
import 'controller.dart';
import 'edge_banding_dialog.dart';
import 'stock_axis.dart';

part 'group_size_dialog.dart';

Future<void> showPartProperties(
  BuildContext context,
  Editor editor,
  Offset position, {
  DialogSource? source,
}) async {
  final parts = editor.selected;
  if (parts.isEmpty) return;
  final group = editor.selectedGroup;
  if (group != null) {
    final initial = editor.project;
    final result = await _editGroupSize(
      context,
      editor,
      initial,
      group,
      position,
      source,
    );
    if (context.mounted &&
        result != null &&
        identical(editor.project, initial)) {
      editor.commit(result);
    }
    return;
  }
  final result = await _editParts(
    context,
    editor,
    parts,
    position,
    source: source,
  );
  if (!context.mounted) return;
  editor.hoveredSize = editor.focusedSize = null;
  if (result == null ||
      parts.any((part) => editor.project.byId[part.id] != part)) {
    editor.refresh();
    return;
  }
  final changes = <int, Beam>{};
  for (final (i, part) in parts.indexed) {
    final next = result[i];
    if (next.name != part.name ||
        next.size != part.size ||
        next.finish != part.finish ||
        next.banding != part.banding ||
        next.locks != part.locks) {
      changes[part.id] = next.copy(origin: part.origin);
    }
  }
  var project = editor.project;
  if (changes.isNotEmpty) {
    project = project.edit(changes.keys.toSet(), (b) => changes[b.id]!);
  }
  if (parts.length == 1 && result.single.origin != parts.single.origin) {
    project = project.move(
      {parts.single.id},
      result.single.origin - parts.single.origin,
      withinWorkspace: editor.movementSnapping,
    );
  }
  if (identical(project, editor.project)) {
    editor.refresh();
  } else {
    editor.commit(project);
  }
}

Future<Beam?> editPartSize(
  BuildContext context,
  Editor editor,
  Beam part,
  Offset globalPoint, {
  bool creating = false,
  DialogSource? source,
}) async {
  final result = await _editParts(
    context,
    editor,
    [part],
    globalPoint,
    creating: creating,
    source: source,
  );
  return result?.single;
}

Future<List<Beam>?> _editParts(
  BuildContext context,
  Editor editor,
  List<Beam> parts,
  Offset globalPoint, {
  bool creating = false,
  DialogSource? source,
}) {
  final multiple = parts.length > 1;
  var drafts = parts.toList();
  final door = creating ? DoorSettingsDraft(parts.single) : null;
  final editedOffsets = <int, double>{};
  final validPosition = [true, true, true];
  T? common<T>(T Function(Beam) read) {
    final first = read(drafts.first);
    return drafts.every((b) => read(b) == first) ? first : null;
  }

  final initialSizes = [
    for (final axis in StockAxis.values) common((b) => b.size[axis.index]),
  ];
  final sizes = initialSizes.toList();
  void setSize(int axis, double? value) {
    sizes[axis] = value;
    for (final (i, draft) in drafts.indexed) {
      drafts[i] = draft.copy(
        size: draft.size.clone()..[axis] = value ?? parts[i].size[axis],
      );
    }
  }

  bool locked(int i) => drafts.any((b) => b.locked(i));
  final firstEditable = StockAxis.values.indexWhere((a) => !locked(a.index));
  final valid = [true, true, true];
  return _showSizeDialog<List<Beam>>(context, globalPoint, source, (
    ctx,
    update,
  ) {
    final offsets = creating || multiple
        ? null
        : editor.project.offsetsOf(Bounds3.points(drafts.single.corners));
    bool validSize(int i) =>
        valid[i] && drafts.every((b) => b.size[i] >= b.minimumSize(i));
    bool ready() =>
        (multiple || drafts.single.name.trim().isNotEmpty) &&
        (door?.valid ?? true) &&
        validPosition.every((ok) => ok) &&
        StockAxis.values.every((axis) => validSize(axis.index));
    void apply() {
      if (ready()) {
        if (!multiple) {
          final draft = drafts.single;
          final origin = draft.origin.clone();
          if (editedOffsets.isNotEmpty) {
            final current = editor.project.offsetsOf(
              Bounds3.points(draft.corners),
            );
            for (final entry in editedOffsets.entries) {
              origin.add(
                offsetDirection(entry.key) * (entry.value - current[entry.key]),
              );
            }
          }
          final part = draft.copy(name: draft.name.trim(), origin: origin);
          drafts[0] = !creating || door == null
              ? part
              : editor.configureDoor(part, door.hinge, angle: door.angle);
        }
        Navigator.pop(ctx, drafts);
      }
    }

    return DeskDialog(
      compact: true,
      title: multiple
          ? Text(context.strings.selectedParts(parts.length))
          : DeskTextField(
              key: const ValueKey('part-dialog-name'),
              initialValue: parts.single.name,
              placeholder: context.strings.partName,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.colors.ink,
              ),
              onChanged: (v) =>
                  update(() => drafts[0] = drafts.single.copy(name: v)),
              onSubmitted: (_) => apply(),
            ),
      content: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (i, axis) in StockAxis.values.indexed)
              StockSizeRow(
                editor,
                axis,
                FocusTraversalOrder(
                  order: NumericFocusOrder(i.toDouble()),
                  child: ValueBox(
                    sizes[i],
                    (v) => update(() => setSize(i, v)),
                    onCleared: multiple
                        ? () => update(() => setSize(i, null))
                        : null,
                    placeholder: initialSizes[i] == null
                        ? context.strings.mixedValues
                        : multiple
                        ? editor.lengthInput.format(initialSizes[i]!)
                        : null,
                    key: ValueKey('dialog-size-$i'),
                    live: true,
                    enabled: !locked(i),
                    autofocus: i == firstEditable,
                    onValidityChanged: (ok) {
                      if (valid[i] != ok) update(() => valid[i] = ok);
                    },
                    onSubmitted: apply,
                  ),
                ),
                fieldWidth: 104,
                trailing: sizeLockButton(
                  axis,
                  locked(i),
                  validSize(i)
                      ? () => update(() {
                          final lock = !locked(i);
                          drafts = [
                            for (final b in drafts) b.withSizeLock(i, lock),
                          ];
                        })
                      : null,
                ),
              ),
            if (door != null) ...[
              const SizedBox(height: 8),
              PartTypePicker(door, refresh: () => update(() {}), submit: apply),
            ],
            if (offsets != null) ...[
              const SizedBox(height: 8),
              sectionTitle(context.strings.partOffsets),
              for (var i = 0; i < 3; i++)
                PartOffsetRow(
                  i,
                  FocusTraversalOrder(
                    order: NumericFocusOrder((3 + i).toDouble()),
                    child: ValueBox(
                      editedOffsets[i] ?? offsets[i],
                      (v) => update(() => editedOffsets[i] = v),
                      key: ValueKey('dialog-position-$i'),
                      signed: true,
                      live: true,
                      onValidityChanged: (ok) {
                        if (validPosition[i] != ok) {
                          update(() => validPosition[i] = ok);
                        }
                      },
                      onSubmitted: apply,
                    ),
                  ),
                  fieldWidth: 104,
                ),
            ],
            const SizedBox(height: 8),
            Row(
              spacing: controlGap,
              children: [
                Text(context.strings.partFinish),
                Expanded(
                  child: PartFinishButton(common((b) => b.finish), (finish) {
                    update(
                      () => drafts = [
                        for (final b in drafts) b.copy(finish: finish),
                      ],
                    );
                  }),
                ),
              ],
            ),
            if (!multiple && drafts.single.supportsEdgeBanding) ...[
              const SizedBox(height: controlGap),
              EdgeBandingButton(drafts.single, editor.displayUnit, () async {
                final banding = await editEdgeBanding(
                  ctx,
                  drafts.single,
                  editor.displayUnit,
                );
                if (ctx.mounted && banding != null) {
                  update(
                    () => drafts[0] = drafts.single.copy(banding: banding),
                  );
                }
              }),
            ],
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
          onPressed: ready() ? apply : null,
          child: Text(
            creating
                ? context.strings.choosePartPosition
                : context.strings.apply,
          ),
        ),
      ],
    );
  });
}

Future<T?> _showSizeDialog<T>(
  BuildContext context,
  Offset globalPoint,
  DialogSource? source,
  StatefulWidgetBuilder builder,
) {
  final overlay =
      Navigator.of(
            context,
            rootNavigator: true,
          ).overlay!.context.findRenderObject()!
          as RenderBox;
  final origin = overlay.globalToLocal(globalPoint);
  return showDeskDialog<T>(
    source: source,
    useSafeArea: false,
    context: context,
    barrierDismissible: true,
    barrierLabel: context.strings.closePartDimensions,
    barrierColor: const Color(0x18000000),
    builder: (ctx) => CustomSingleChildLayout(
      delegate: _PartDialogLayout(origin),
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              Navigator.pop(ctx),
        },
        child: StatefulBuilder(builder: builder),
      ),
    ),
  );
}

class _PartDialogLayout extends SingleChildLayoutDelegate {
  final Offset origin;
  _PartDialogLayout(this.origin);

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final width = math.min(302.0, math.max(0.0, constraints.maxWidth - 24));
    return BoxConstraints(
      minWidth: width,
      maxWidth: width,
      maxHeight: math.max(0.0, constraints.maxHeight - 24),
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    const gap = 12.0;
    final x = origin.dx + gap + childSize.width <= size.width - gap
        ? origin.dx + gap
        : origin.dx - gap - childSize.width;
    return Offset(
      x.clamp(gap, math.max(gap, size.width - childSize.width - gap)),
      (origin.dy - childSize.height * .45).clamp(
        gap,
        math.max(gap, size.height - childSize.height - gap),
      ),
    );
  }

  @override
  bool shouldRelayout(_PartDialogLayout old) => old.origin != origin;
}

Future<double?> editDimensionLabel(
  BuildContext context,
  Beam part,
  StockAxis axis,
  Rect labelBounds,
) {
  final overlay =
      Navigator.of(
            context,
            rootNavigator: true,
          ).overlay!.context.findRenderObject()!
          as RenderBox;
  final source = DialogSource.of(context, labelBounds)!;
  final center = overlay.globalToLocal(source.bounds.center);
  var value = part.size[axis.index], valid = true;
  return showDeskDialog<double>(
    source: source,
    useSafeArea: false,
    context: context,
    barrierDismissible: false,
    barrierColor: const Color(0x00000000),
    builder: (ctx) {
      void apply() {
        if (valid && value >= part.minimumSize(axis.index)) {
          Navigator.pop(ctx, value);
        }
      }

      return LayoutBuilder(
        builder: (_, box) {
          final width = math.min(124.0, box.maxWidth);
          return Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: apply,
                ),
              ),
              Positioned(
                left: (center.dx - width / 2).clamp(
                  0.0,
                  math.max(0.0, box.maxWidth - width),
                ),
                top: (center.dy - 15.5).clamp(
                  0.0,
                  math.max(0.0, box.maxHeight - 31),
                ),
                width: width,
                child: CallbackShortcuts(
                  bindings: {
                    const SingleActivator(LogicalKeyboardKey.escape): () =>
                        Navigator.pop(ctx),
                    const SingleActivator(LogicalKeyboardKey.tab): apply,
                    const SingleActivator(LogicalKeyboardKey.tab, shift: true):
                        apply,
                  },
                  child: Semantics(
                    key: DeskDialogRoute.surfaceKey(ctx),
                    label: axis.label,
                    child: ValueBox(
                      part.size[axis.index],
                      (v) => value = v,
                      key: const ValueKey('canvas-size-input'),
                      autofocus: true,
                      live: true,
                      onSubmitted: apply,
                      onValidityChanged: (v) => valid = v,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
