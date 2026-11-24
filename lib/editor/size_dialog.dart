import '../l10n/strings.dart';
import 'palette.dart';
import 'desk_text_field.dart';

import 'dart:math' as math;

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/services.dart';

import 'controls.dart';
import 'desktop.dart';
import 'finish_picker.dart';
import 'model.dart';
import 'part_type_picker.dart';
import 'controller.dart';
import 'stock_axis.dart';

Future<void> showPartProperties(
  BuildContext context,
  Editor editor,
  Offset position,
) async {
  final parts = editor.selected;
  if (parts.isEmpty) return;
  final result = await _editParts(context, editor, parts, position);
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
        next.hinge != part.hinge ||
        next.openingAngle != part.openingAngle ||
        next.locks != part.locks) {
      changes[part.id] = next;
    }
  }
  if (changes.isEmpty) {
    editor.refresh();
  } else {
    editor.commit(
      editor.project.edit(changes.keys.toSet(), (b) => changes[b.id]!),
    );
  }
}

Future<Beam?> editPartSize(
  BuildContext context,
  Editor editor,
  Beam part,
  Offset globalPoint, {
  bool creating = false,
}) async {
  final result = await _editParts(
    context,
    editor,
    [part],
    globalPoint,
    creating: creating,
  );
  return result?.single;
}

Future<List<Beam>?> _editParts(
  BuildContext context,
  Editor editor,
  List<Beam> parts,
  Offset globalPoint, {
  bool creating = false,
}) {
  final overlay =
      Navigator.of(
            context,
            rootNavigator: true,
          ).overlay!.context.findRenderObject()!
          as RenderBox;
  final origin = overlay.globalToLocal(globalPoint);
  final multiple = parts.length > 1;
  var drafts = parts.toList();
  final door = DoorSettingsDraft(parts.first);
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
  final reduceMotion = MediaQuery.disableAnimationsOf(context);
  return showGeneralDialog<List<Beam>>(
    context: context,
    barrierDismissible: true,
    barrierLabel: context.strings.closePartDimensions,
    barrierColor: const Color(0x18000000),
    transitionDuration: reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 230),
    transitionBuilder: (_, animation, secondary, child) => child,
    pageBuilder: (ctx, animation, _) => AnimatedBuilder(
      animation: animation,
      child: StatefulBuilder(
        builder: (_, update) {
          bool validSize(int i) =>
              valid[i] && drafts.every((b) => b.size[i] >= b.minimumSize(i));
          bool ready() =>
              (multiple ||
                  (drafts.single.name.trim().isNotEmpty && door.valid)) &&
              StockAxis.values.every((axis) => validSize(axis.index));
          void apply() {
            if (ready()) {
              if (!multiple) {
                final part = drafts.single.copy(
                  name: drafts.single.name.trim(),
                );
                drafts[0] = editor.configureDoor(
                  part,
                  door.hinge,
                  angle: door.angle,
                );
              }
              Navigator.pop(ctx, drafts);
            }
          }

          return CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.escape): () =>
                  Navigator.pop(ctx),
            },
            child: DeskDialog(
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
                                ? editor.project.unit.format(initialSizes[i]!)
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
                                    for (final b in drafts)
                                      b.withSizeLock(i, lock),
                                  ];
                                })
                              : null,
                        ),
                      ),
                    if (!multiple) ...[
                      const SizedBox(height: 8),
                      PartTypePicker(
                        door,
                        refresh: () => update(() {}),
                        submit: apply,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      spacing: controlGap,
                      children: [
                        Text(context.strings.partFinish),
                        Expanded(
                          child: PartFinishButton(common((b) => b.finish), (
                            finish,
                          ) {
                            update(
                              () => drafts = [
                                for (final b in drafts) b.copy(finish: finish),
                              ],
                            );
                          }),
                        ),
                      ],
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
                  onPressed: ready() ? apply : null,
                  child: Text(
                    creating
                        ? context.strings.choosePartPosition
                        : context.strings.apply,
                  ),
                ),
              ],
            ),
          );
        },
      ),
      builder: (_, child) {
        final t = Curves.easeOutCubic.transform(animation.value);
        return CustomSingleChildLayout(
          delegate: _PartDialogLayout(origin, t),
          child: Transform.scale(
            scale: .22 + .78 * t,
            child: Opacity(opacity: animation.value, child: child),
          ),
        );
      },
    ),
  );
}

class _PartDialogLayout extends SingleChildLayoutDelegate {
  final Offset origin;
  final double progress;
  _PartDialogLayout(this.origin, this.progress);

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
    final target = Offset(
      x.clamp(gap, math.max(gap, size.width - childSize.width - gap)),
      (origin.dy - childSize.height * .45).clamp(
        gap,
        math.max(gap, size.height - childSize.height - gap),
      ),
    );
    return Offset.lerp(
      origin - childSize.center(Offset.zero),
      target,
      progress,
    )!;
  }

  @override
  bool shouldRelayout(_PartDialogLayout old) =>
      old.origin != origin || old.progress != progress;
}

Future<double?> editDimensionLabel(
  BuildContext context,
  Beam part,
  StockAxis axis,
  Offset globalCenter,
) {
  final overlay =
      Navigator.of(
            context,
            rootNavigator: true,
          ).overlay!.context.findRenderObject()!
          as RenderBox;
  final center = overlay.globalToLocal(globalCenter);
  var value = part.size[axis.index], valid = true;
  return showGeneralDialog<double>(
    context: context,
    barrierDismissible: false,
    barrierColor: const Color(0x00000000),
    transitionDuration: Duration.zero,
    pageBuilder: (ctx, _, _) {
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
