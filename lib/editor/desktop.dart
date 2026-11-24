import 'palette.dart';

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart' show Tooltip;
import 'package:material_ui/material_ui.dart' as m;

import 'platform_ui.dart';

const double controlGap = 6;
const double toolbarGap = 4;

class DeskControl extends StatelessWidget {
  const DeskControl({
    super.key,
    required this.onPressed,
    required this.child,
    this.padding = EdgeInsets.zero,
    this.minimumSize = Size.zero,
    this.foreground,
    this.background,
    this.borderRadius,
    this.outlined = false,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Size minimumSize;
  final Color? foreground, background;
  final BorderRadius? borderRadius;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(appleControls ? 6 : 4);
    final shape = RoundedRectangleBorder(
      borderRadius: radius,
      side: outlined
          ? BorderSide(color: context.colors.line, width: .8)
          : BorderSide.none,
    );
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return DecoratedBox(
        decoration: ShapeDecoration(shape: shape),
        child: CupertinoButton(
          sizeStyle: CupertinoButtonSize.small,
          onPressed: onPressed,
          minimumSize: minimumSize,
          padding: padding,
          color: background,
          borderRadius: radius,
          foregroundColor: foreground,
          child: child,
        ),
      );
    }
    final style = m.TextButton.styleFrom(
      foregroundColor: foreground ?? context.colors.ink,
      backgroundColor: background,
      disabledBackgroundColor: background,
      shape: shape,
      minimumSize: minimumSize,
      padding: padding,
      tapTargetSize: m.MaterialTapTargetSize.shrinkWrap,
      visualDensity: m.VisualDensity.standard,
      textStyle: TextStyle(
        fontFamily: DefaultTextStyle.of(context).style.fontFamily,
        fontSize: 12.5,
        letterSpacing: 0,
        fontWeight: macControls ? FontWeight.w400 : FontWeight.w500,
      ),
    );
    final mac = macControls;
    final focusColor = context.colors.accent;
    return m.TextButton(
      onPressed: onPressed,
      style: mac
          ? style.copyWith(
              animationDuration: Duration.zero,
              splashFactory: m.NoSplash.splashFactory,
              overlayColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.pressed)) {
                  return context.colors.ink.withValues(alpha: .14);
                }
                if (states.contains(WidgetState.hovered)) {
                  return context.colors.ink.withValues(alpha: .06);
                }
                return const Color(0x00000000);
              }),
              side: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.focused)
                    ? BorderSide(
                        color: focusColor,
                        width: 2,
                        strokeAlign: BorderSide.strokeAlignOutside,
                      )
                    : shape.side,
              ),
            )
          : style,
      child: child,
    );
  }
}

class DeskButton extends StatelessWidget {
  const DeskButton({
    super.key,
    required this.onPressed,
    this.child,
    this.label,
    this.icon,
    this.primary = false,
    this.plain = false,
    this.active = false,
  });
  final VoidCallback? onPressed;
  final Widget? child, label, icon;
  final bool primary, plain, active;
  @override
  Widget build(BuildContext context) {
    final dialogAction =
        macControls &&
        context.findAncestorWidgetOfExactType<_DialogActions>() != null;
    final flat = plain && !dialogAction;
    final foreground = onPressed == null
        ? context.colors.disabled
        : primary
        ? EditorPalette.onHighlight
        : context.colors.ink;
    final content =
        child ??
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ?icon,
            if (icon != null) const SizedBox(width: 5),
            Flexible(child: label!),
          ],
        );
    return DeskControl(
      onPressed: onPressed,
      background: onPressed == null && (!flat || primary || active)
          ? context.colors.chrome
          : primary
          ? EditorPalette.highlight
          : active
          ? context.selectionFill
          : flat
          ? null
          : context.colors.field,
      outlined: !flat && !primary,
      minimumSize: dialogAction
          ? const Size(70, 24)
          : Size(24, macControls ? 24 : 26),
      padding: EdgeInsets.symmetric(
        horizontal: dialogAction ? 12 : 8,
        vertical: macControls ? 3 : 4,
      ),
      foreground: foreground,
      child: IconTheme.merge(
        data: IconThemeData(color: foreground, size: 15),
        child: DefaultTextStyle.merge(
          style: TextStyle(
            fontSize: 12.5,
            color: foreground,
            fontWeight: macControls ? FontWeight.w400 : FontWeight.w500,
            letterSpacing: 0,
          ),
          child: content,
        ),
      ),
    );
  }
}

Future<T?> showDeskDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = false,
}) => macControls
    ? showGeneralDialog<T>(
        context: context,
        barrierDismissible: barrierDismissible,
        barrierLabel: CupertinoLocalizations.of(context)
            .modalBarrierDismissLabel,
        barrierColor: const Color(0x26000000),
        transitionDuration: const Duration(milliseconds: 140),
        pageBuilder: (context, _, _) => SafeArea(child: builder(context)),
      )
    : appleControls
    ? showCupertinoDialog<T>(
        context: context,
        builder: builder,
        barrierDismissible: barrierDismissible,
      )
    : m.showDialog<T>(
        context: context,
        builder: builder,
        barrierDismissible: barrierDismissible,
      );

class DeskDialog extends StatelessWidget {
  final Widget title, content;
  final List<Widget> actions;
  final bool compact;
  final bool insetContent;
  final Widget? leadingAction;
  final double maxWidth;
  const DeskDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
    this.compact = false,
    this.insetContent = true,
    this.leadingAction,
    this.maxWidth = 500,
  });
  @override
  Widget build(BuildContext context) {
    final primary = actions
        .whereType<DeskButton>()
        .where((b) => b.primary)
        .firstOrNull;
    final buttons =
        defaultTargetPlatform == TargetPlatform.windows && primary != null
        ? [primary, ...actions.where((action) => action != primary)]
        : actions;
    final divided = macControls && !compact;
    final padding = EdgeInsets.all(appleControls ? 20 : 18);
    final separator = SizedBox(
      height: .7,
      child: ColoredBox(color: context.colors.line),
    );
    final body = Padding(
      padding: divided ? EdgeInsets.zero : padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: divided
                ? const EdgeInsets.symmetric(horizontal: 18, vertical: 12)
                : EdgeInsets.zero,
            child: DefaultTextStyle.merge(
              style: TextStyle(
                fontSize: divided ? 15 : 17,
                fontWeight: FontWeight.w600,
                color: context.colors.ink,
              ),
              child: title,
            ),
          ),
          if (divided) separator else const SizedBox(height: 13),
          Flexible(
            child: SingleChildScrollView(
              padding: divided && insetContent
                  ? const EdgeInsets.all(16)
                  : EdgeInsets.zero,
              child: content,
            ),
          ),
          if (divided) separator else const SizedBox(height: 17),
          Padding(
            padding: divided
                ? const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
                : EdgeInsets.zero,
            child: _DialogActions(buttons, leadingAction),
          ),
        ],
      ),
    );
    final inset = EdgeInsets.all(compact ? 0 : 18);
    final constraints = BoxConstraints(maxWidth: maxWidth);
    final dialog = appleControls
        ? Center(
            widthFactor: compact ? 1 : null,
            heightFactor: compact ? 1 : null,
            child: Padding(
              padding: inset,
              child: Container(
                constraints: constraints,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: context.colors.panel,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: context.colors.line, width: .75),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x37000000),
                      blurRadius: 28,
                      offset: Offset(0, 11),
                    ),
                  ],
                ),
                child: body,
              ),
            ),
          )
        : compact
        ? m.Material(
            color: m.Theme.of(context).colorScheme.surface,
            elevation: 6,
            borderRadius: BorderRadius.circular(8),
            child: body,
          )
        : m.Dialog(
            insetPadding: inset,
            constraints: constraints,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            child: body,
          );
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.maybePop(context),
        if (appleControls)
          const SingleActivator(LogicalKeyboardKey.period, meta: true): () =>
              Navigator.maybePop(context),
      },
      child: FocusScope(
        autofocus: true,
        onKeyEvent: (scope, event) {
          if (scope.hasPrimaryFocus &&
              event is KeyDownEvent &&
              (event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.numpadEnter) &&
              primary?.onPressed != null &&
              HardwareKeyboard.instance.logicalKeysPressed.length == 1) {
            primary!.onPressed!();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: dialog,
      ),
    );
  }
}

class _DialogActions extends StatelessWidget {
  const _DialogActions(this.buttons, this.leading);
  final List<Widget> buttons;
  final Widget? leading;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (leading != null && constraints.maxWidth >= 520) {
        return Row(
          children: [
            leading!,
            const Spacer(),
            ...buttons.expand((b) => [const SizedBox(width: 7), b]),
          ],
        );
      }
      return OverflowBar(
        alignment: MainAxisAlignment.end,
        spacing: 7,
        overflowSpacing: 5,
        overflowAlignment: OverflowBarAlignment.end,
        overflowDirection: appleControls
            ? VerticalDirection.up
            : VerticalDirection.down,
        children: [?leading, ...buttons],
      );
    },
  );
}

class DeskSegments<T extends Object> extends StatelessWidget {
  final T value;
  final Map<T, String> choices;
  final ValueChanged<T> change;
  const DeskSegments(this.value, this.choices, this.change, {super.key});
  @override
  Widget build(BuildContext context) => DeskSegmentedControl<T>(
    value: value,
    children: {
      for (final e in choices.entries)
        e.key: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
          child: Text(
            e.value,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ),
    },
    change: change,
  );
}

class DeskSegmentedControl<T extends Object> extends StatelessWidget {
  const DeskSegmentedControl({
    super.key,
    required this.value,
    required this.children,
    required this.change,
  });
  final T? value;
  final Map<T, Widget> children;
  final ValueChanged<T> change;

  @override
  Widget build(BuildContext context) {
    if (appleControls) {
      return CupertinoSlidingSegmentedControl<T>(
        groupValue: value,
        backgroundColor: context.colors.chrome,
        thumbColor: EditorPalette.highlight,
        children: {
          for (final entry in children.entries)
            entry.key: DefaultTextStyle.merge(
              style: TextStyle(
                color: entry.key == value
                    ? EditorPalette.onHighlight
                    : context.colors.ink,
              ),
              child: entry.value,
            ),
        },
        onValueChanged: (next) {
          if (next != null) change(next);
        },
      );
    }
    return GestureDetector(
      onHorizontalDragEnd: (drag) {
        final size = context.size!;
        if (!(Offset.zero & size).contains(drag.localPosition)) return;
        final index = (drag.localPosition.dx * children.length / size.width)
            .floor();
        final rtl = Directionality.of(context) == TextDirection.rtl;
        final next = children.keys.elementAt(
          rtl ? children.length - 1 - index : index,
        );
        if (next != value) change(next);
      },
      child: m.SegmentedButton<T>(
        segments: [
          for (final e in children.entries)
            m.ButtonSegment(value: e.key, label: e.value),
        ],
        selected: {?value},
        emptySelectionAllowed: value == null,
        showSelectedIcon: false,
        onSelectionChanged: (values) {
          if (values.isNotEmpty) change(values.single);
        },
        style: m.SegmentedButton.styleFrom(
          selectedBackgroundColor: EditorPalette.highlight,
          selectedForegroundColor: EditorPalette.onHighlight,
          minimumSize: const Size(0, 28),
          padding: const EdgeInsets.symmetric(horizontal: 3),
          tapTargetSize: m.MaterialTapTargetSize.shrinkWrap,
          visualDensity: m.VisualDensity.standard,
          textStyle: const TextStyle(fontSize: 12, letterSpacing: 0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        ),
      ),
    );
  }
}

class DeskSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const DeskSwitch({super.key, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: macControls ? 32 : 38,
    height: macControls ? 22 : 26,
    child: FittedBox(
      fit: BoxFit.contain,
      child: !appleControls
          ? m.Switch(value: value, onChanged: onChanged)
          : CupertinoSwitch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: EditorPalette.highlight,
              thumbColor: value ? EditorPalette.onHighlight : null,
            ),
    ),
  );
}

class DeskIcon extends StatelessWidget {
  final IconData icon;
  final String tip;
  final VoidCallback? action;
  final bool active;
  final Color? foreground, background;
  final BorderRadius? borderRadius;
  final double size;
  const DeskIcon(
    this.icon,
    this.tip,
    this.action, {
    super.key,
    this.active = false,
    this.foreground,
    this.background,
    this.borderRadius,
    this.size = 17,
  });
  @override
  Widget build(BuildContext context) => Tooltip(
    message: tip,
    waitDuration: const Duration(milliseconds: 380),
    child: DeskControl(
      onPressed: action,
      borderRadius: borderRadius,
      background: active && action != null
          ? (macControls ? context.selectionFill : EditorPalette.highlight)
          : background,
      minimumSize: const Size(29, 28),
      padding: const EdgeInsets.all(4),
      child: Icon(
        icon,
        semanticLabel: tip,
        size: size,
        color: action == null
            ? context.colors.disabled
            : active
            ? (macControls ? context.colors.ink : EditorPalette.onHighlight)
            : foreground ?? context.colors.muted,
      ),
    ),
  );
}

class DeskMenu<T> extends StatelessWidget {
  const DeskMenu({
    super.key,
    required this.title,
    required this.items,
    this.selected,
    this.borderRadius,
    this.dividers = const {},
    required this.change,
    required this.child,
  });
  final String title;
  final List<(T, String)> items;
  final T? selected;
  final BorderRadius? borderRadius;
  final Set<T> dividers;
  final ValueChanged<T> change;
  final Widget child;
  Future<void> open(BuildContext context) async {
    final box = context.findRenderObject()! as RenderBox;
    final index = await showDeskPopup(
      context,
      box.localToGlobal(Offset(0, box.size.height + 2)),
      title: title,
      anchorHeight: box.size.height + 2,
      rows: [
        for (final item in items)
          DeskPopupRow(
            item.$2,
            checked: selected == null ? null : selected == item.$1,
            breakBefore: dividers.contains(item.$1),
          ),
      ],
    );
    if (context.mounted && index != null) change(items[index].$1);
  }

  @override
  Widget build(BuildContext context) => Tooltip(
    message: title,
    child: DeskControl(
      onPressed: () => open(context),
      borderRadius: borderRadius,
      padding: EdgeInsets.zero,
      minimumSize: const Size(18, 24),
      child: DefaultTextStyle(
        style: DefaultTextStyle.of(context).style
            .copyWith(fontSize: 13, color: context.colors.ink),
        child: Semantics(label: title, excludeSemantics: true, child: child),
      ),
    ),
  );
}

class DeskPopupRow {
  const DeskPopupRow(
    this.label, {
    this.icon,
    this.symbol = '',
    this.keyHint = '',
    this.checked,
    this.breakBefore = false,
  });
  final String label, symbol, keyHint;
  final IconData? icon;
  final bool? checked;
  final bool breakBefore;
}

Future<int?> showDeskPopup(
  BuildContext context,
  Offset at, {
  required String title,
  required List<DeskPopupRow> rows,
  bool showTitle = false,
  double anchorHeight = 0,
}) async {
  if (!appleControls) {
    final overlay =
        Navigator.of(context).overlay!.context.findRenderObject()! as RenderBox;
    final point = overlay.globalToLocal(at);
    return m.showMenu<int>(
      context: context,
      semanticLabel: title,
      position: RelativeRect.fromSize(point & Size.zero, overlay.size),
      constraints: const BoxConstraints(maxWidth: 320),
      items: [
        if (showTitle)
          m.PopupMenuItem<int>(enabled: false, height: 28, child: Text(title)),
        for (final (index, row) in rows.indexed) ...[
          if (row.breakBefore) const m.PopupMenuDivider(),
          m.PopupMenuItem<int>(
            value: index,
            height: 36,
            child: Row(
              children: [
                if (row.checked != null)
                  SizedBox(
                    width: 22,
                    child: row.checked!
                        ? const Icon(m.Icons.check, size: 15)
                        : null,
                  ),
                if (row.icon != null) ...[
                  Icon(row.icon, size: 16),
                  const SizedBox(width: 8),
                ],
                Flexible(child: Text(row.label)),
                if (row.keyHint.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Text(row.keyHint, style: const TextStyle(fontSize: 12)),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS) {
    try {
      final index = await const MethodChannel('neprosto/popup')
          .invokeMethod<int>(showTitle ? 'contextMenu' : 'choose', {
            'items': [for (final row in rows) row.label],
            if (showTitle) 'heading': title,
            'symbols': [for (final row in rows) row.symbol],
            'shortcuts': [for (final row in rows) row.keyHint],
            'checked': [
              for (final (i, row) in rows.indexed)
                if (row.checked == true) i,
            ],
            'dividers': [
              for (final (i, row) in rows.indexed)
                if (row.breakBefore) i,
            ],
            'x': at.dx,
            'y': at.dy,
          });
      return index != null && index >= 0 && index < rows.length ? index : null;
    } on MissingPluginException {
      // Embedders without the AppKit bridge use the Flutter menu.
    }
  }
  if (!context.mounted) return null;
  return showGeneralDialog<int>(
    context: context,
    barrierLabel: title,
    barrierDismissible: true,
    barrierColor: const Color(0x00000000),
    transitionDuration: Duration.zero,
    pageBuilder: (ctx, _, _) => LayoutBuilder(
      builder: (_, box) {
        final width = math.min(showTitle ? 275.0 : 242.0, box.maxWidth);
        final height = math.min(
          box.maxHeight * .85,
          rows.length * 32.0 +
              12 +
              (showTitle ? 27 : 0) +
              rows.where((r) => r.breakBefore).length * 9,
        );
        final top =
            (at.dy + height <= box.maxHeight
                    ? at.dy
                    : at.dy - anchorHeight - height)
                .clamp(0.0, box.maxHeight - height);
        return Stack(
          children: [
            Positioned(
              left: at.dx.clamp(0.0, box.maxWidth - width),
              top: top,
              width: width,
              height: height,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: context.colors.panel,
                  border: Border.all(color: context.colors.line, width: .7),
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 18,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: ListView(
                  padding: const EdgeInsets.all(5),
                  children: [
                    if (showTitle)
                      SizedBox(
                        height: 27,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: context.colors.muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    for (final (i, row) in rows.indexed) ...[
                      if (row.breakBefore)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 5,
                          ),
                          child: SizedBox(
                            height: 1,
                            child: ColoredBox(color: context.colors.line),
                          ),
                        ),
                      _PopupButton(row, () => Navigator.pop(ctx, i)),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class _PopupButton extends StatefulWidget {
  const _PopupButton(this.row, this.choose);
  final DeskPopupRow row;
  final VoidCallback choose;
  @override
  State<_PopupButton> createState() => _PopupButtonState();
}

class _PopupButtonState extends State<_PopupButton> {
  bool hover = false;
  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final color = hover ? EditorPalette.onHighlight : context.colors.ink;
    return MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: SizedBox(
        height: 32,
        child: DeskControl(
          background: hover ? EditorPalette.highlight : null,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: Size.zero,
          onPressed: widget.choose,
          child: Row(
            children: [
              if (row.checked != null)
                SizedBox(
                  width: 22,
                  child: row.checked!
                      ? Icon(CupertinoIcons.check_mark, size: 13, color: color)
                      : null,
                ),
              if (row.icon != null) ...[
                Icon(row.icon, size: 16, color: color),
                const SizedBox(width: 9),
              ],
              Expanded(
                child: Text(
                  row.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 13, color: color),
                ),
              ),
              if (row.keyHint.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  row.keyHint,
                  style: TextStyle(
                    fontSize: 12,
                    color: hover ? color : context.colors.muted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
