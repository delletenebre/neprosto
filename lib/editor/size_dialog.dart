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
import 'controller.dart';
import 'stock_axis.dart';

Future<void> showPartProperties(
  BuildContext context,
  Editor editor,
  Beam part,
  Offset position,
) async {
  final result = await editPartSize(context, editor, part, position);
  if (!context.mounted) return;
  editor.hoveredSize = editor.focusedSize = null;
  editor.refresh();
  if (result == null ||
      editor.project.byId[part.id] != part ||
      (result.name == part.name &&
          result.size == part.size &&
          result.finish == part.finish &&
          result.locks == part.locks)) {
    return;
  }
  editor.commit(editor.project.edit({part.id}, (_) => result));
}

Future<Beam?> editPartSize(
  BuildContext context,
  Editor editor,
  Beam part,
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
  var draft = part;
  final firstEditable = StockAxis.values.indexWhere(
    (a) => !part.locked(a.index),
  );
  final valid = [true, true, true];
  final reduceMotion = MediaQuery.disableAnimationsOf(context);
  return showGeneralDialog<Beam>(
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
              valid[i] && draft.size[i] >= draft.minimumSize(i);
          bool ready() =>
              draft.name.trim().isNotEmpty &&
              StockAxis.values.every((axis) => validSize(axis.index));
          void apply() {
            if (ready()) {
              Navigator.pop(ctx, draft.copy(name: draft.name.trim()));
            }
          }

          return CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.escape): () =>
                  Navigator.pop(ctx),
            },
            child: DeskDialog(
              compact: true,
              title: DeskTextField(
                key: const ValueKey('part-dialog-name'),
                initialValue: part.name,
                placeholder: context.strings.partName,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.colors.ink,
                ),
                onChanged: (v) => update(() => draft = draft.copy(name: v)),
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
                            draft.size[i],
                            (v) => update(
                              () => draft = draft.copy(
                                size: draft.size.clone()..[i] = v,
                              ),
                            ),
                            key: ValueKey('dialog-size-$i'),
                            live: true,
                            enabled: !draft.locked(i),
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
                          draft.locked(i),
                          validSize(i)
                              ? () => update(
                                  () => draft = draft.withSizeLock(
                                    i,
                                    !draft.locked(i),
                                  ),
                                )
                              : null,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      spacing: controlGap,
                      children: [
                        Text(context.strings.partFinish),
                        Expanded(
                          child: PartFinishButton(draft.finish, (finish) {
                            update(() => draft = draft.copy(finish: finish));
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
