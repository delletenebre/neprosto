import 'dart:math' as math;

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/services.dart';

import 'controls.dart';
import 'desktop.dart';
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
      (result.name == part.name && result.size == part.size)) {
    return;
  }
  editor.commit(
    editor.project.edit({
      part.id,
    }, (b) => b.copy(name: result.name, size: result.size)),
  );
}

Future<({String name, Vector3 size})?> editPartSize(
  BuildContext context,
  Editor editor,
  Beam part,
  Offset globalPoint,
) {
  final overlay =
      Navigator.of(
            context,
            rootNavigator: true,
          ).overlay!.context.findRenderObject()!
          as RenderBox;
  final origin = overlay.globalToLocal(globalPoint);
  final size = part.size.clone();
  var name = part.name;
  final valid = [true, true, true];
  final reduceMotion = MediaQuery.disableAnimationsOf(context);
  return showGeneralDialog<({String name, Vector3 size})>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Закрыть размеры детали',
    barrierColor: const Color(0x18000000),
    transitionDuration: reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 230),
    transitionBuilder: (_, animation, secondary, child) => child,
    pageBuilder: (ctx, animation, _) => AnimatedBuilder(
      animation: animation,
      child: StatefulBuilder(
        builder: (_, update) {
          final ready =
              name.trim().isNotEmpty &&
              valid.every((v) => v) &&
              size.x >= part.minimumLength;
          void apply() {
            if (name.trim().isNotEmpty &&
                valid.every((v) => v) &&
                size.x >= part.minimumLength) {
              Navigator.pop(ctx, (name: name.trim(), size: size));
            }
          }

          return CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.escape): () =>
                  Navigator.pop(ctx),
            },
            child: DeskDialog(
              compact: true,
              title: CupertinoTextFormFieldRow(
                key: const ValueKey('part-dialog-name'),
                initialValue: part.name,
                padding: EdgeInsets.zero,
                placeholder: 'Название детали',
                prefix: const Icon(CupertinoIcons.pencil, size: 16),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.label,
                ),
                onChanged: (v) => update(() => name = v),
                onFieldSubmitted: (_) => apply(),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final (i, axis) in StockAxis.values.indexed)
                    StockSizeRow(
                      editor,
                      axis,
                      ValueBox(
                        size[i],
                        (v) => update(() => size[i] = v),
                        key: ValueKey('dialog-size-$i'),
                        live: true,
                        autofocus: i == 0,
                        onValidityChanged: (ok) {
                          if (valid[i] != ok) update(() => valid[i] = ok);
                        },
                        onSubmitted: apply,
                      ),
                      fieldWidth: 122,
                    ),
                ],
              ),
              actions: [
                DeskButton(
                  plain: true,
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Отмена'),
                ),
                DeskButton(
                  primary: true,
                  onPressed: ready ? apply : null,
                  child: const Text('Применить'),
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
        if (valid &&
            (axis != StockAxis.length || value >= part.minimumLength)) {
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
