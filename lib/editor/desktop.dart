import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart' show Tooltip;

/// Compact macOS controls with the same keyboard focus and press feedback on web.
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
    final foreground = onPressed == null
        ? CupertinoColors.inactiveGray
        : primary
        ? CupertinoColors.white
        : const Color(0xff252529);
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: onPressed == null && (!plain || primary || active)
            ? const Color(0xffe6e6e6)
            : primary
            ? const Color(0xff0875e8)
            : active
            ? const Color(0xffdeebfb)
            : plain
            ? const Color(0x00000000)
            : const Color(0xfffafafa),
        borderRadius: BorderRadius.circular(6),
        border: plain || primary
            ? null
            : Border.all(color: const Color(0xffc9c9ce), width: .7),
      ),
      child: CupertinoButton(
        sizeStyle: CupertinoButtonSize.small,
        onPressed: onPressed,
        minimumSize: const Size(24, 26),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        foregroundColor: foreground,
        child: IconTheme.merge(
          data: IconThemeData(color: foreground, size: 15),
          child: DefaultTextStyle(
            style: TextStyle(
              fontFamily: '.AppleSystemUIFont',
              fontSize: 12.5,
              color: foreground,
              fontWeight: FontWeight.w500,
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}

class DeskDialog extends StatelessWidget {
  final Widget title, content;
  final List<Widget> actions;
  final bool compact;
  final double maxWidth;
  const DeskDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
    this.compact = false,
    this.maxWidth = 500,
  });
  @override
  Widget build(BuildContext context) => Center(
    widthFactor: compact ? 1 : null,
    heightFactor: compact ? 1 : null,
    child: Padding(
      padding: EdgeInsets.all(compact ? 0 : 18),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xfff6f6f8),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: const Color(0xffcdced2), width: .75),
            boxShadow: const [
              BoxShadow(
                color: Color(0x37000000),
                blurRadius: 28,
                offset: Offset(0, 11),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DefaultTextStyle(
                  style: const TextStyle(
                    fontFamily: '.AppleSystemUIFont',
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.label,
                  ),
                  child: title,
                ),
                const SizedBox(height: 13),
                Flexible(child: SingleChildScrollView(child: content)),
                const SizedBox(height: 17),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 7,
                  runSpacing: 5,
                  children: actions,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class DeskSegments<T extends Object> extends StatelessWidget {
  final T value;
  final Map<T, String> choices;
  final ValueChanged<T> change;
  const DeskSegments(this.value, this.choices, this.change, {super.key});
  @override
  Widget build(BuildContext context) => CupertinoSlidingSegmentedControl<T>(
    groupValue: value,
    children: {
      for (final e in choices.entries)
        e.key: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
          child: Text(
            e.value,
            style: const TextStyle(
              fontFamily: '.AppleSystemUIFont',
              fontSize: 12,
              color: CupertinoColors.label,
            ),
          ),
        ),
    },
    onValueChanged: (v) {
      if (v != null) change(v);
    },
  );
}

class DeskSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const DeskSwitch({super.key, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 38,
    height: 26,
    child: FittedBox(
      fit: BoxFit.contain,
      child: CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: CupertinoColors.activeBlue,
      ),
    ),
  );
}

class DeskIcon extends StatelessWidget {
  final IconData icon;
  final String tip;
  final VoidCallback? action;
  final bool active;
  final double size;
  const DeskIcon(
    this.icon,
    this.tip,
    this.action, {
    super.key,
    this.active = false,
    this.size = 17,
  });
  @override
  Widget build(BuildContext context) => Tooltip(
    message: tip,
    waitDuration: const Duration(milliseconds: 380),
    child: Semantics(
      label: tip,
      button: true,
      enabled: action != null,
      child: CupertinoButton(
        sizeStyle: CupertinoButtonSize.small,
        onPressed: action,
        color: active && action != null ? const Color(0xffdbe9fa) : null,
        minimumSize: const Size(29, 28),
        padding: const EdgeInsets.all(4),
        borderRadius: BorderRadius.circular(5),
        child: Icon(
          icon,
          size: size,
          color: action == null
              ? const Color(0xffbabac0)
              : active
              ? CupertinoColors.activeBlue
              : const Color(0xff46464b),
        ),
      ),
    ),
  );
}

class DeskMenu<T> extends StatelessWidget {
  const DeskMenu({
    super.key,
    required this.title,
    required this.items,
    required this.change,
    required this.child,
  });
  final String title;
  final List<(T, String)> items;
  final ValueChanged<T> change;
  final Widget child;
  Future<void> open(BuildContext context) async {
    final box = context.findRenderObject()! as RenderBox;
    final index = await showDeskPopup(
      context,
      box.localToGlobal(Offset(0, box.size.height + 2)),
      title: title,
      anchorHeight: box.size.height + 2,
      rows: [for (final item in items) DeskPopupRow(item.$2)],
    );
    if (context.mounted && index != null) change(items[index].$1);
  }

  @override
  Widget build(BuildContext context) => Tooltip(
    message: title,
    child: CupertinoButton(
      onPressed: () => open(context),
      sizeStyle: CupertinoButtonSize.small,
      padding: EdgeInsets.zero,
      minimumSize: const Size(18, 24),
      child: DefaultTextStyle(
        style: const TextStyle(
          fontFamily: '.AppleSystemUIFont',
          fontSize: 13,
          color: CupertinoColors.label,
        ),
        child: child,
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
    this.breakBefore = false,
  });
  final String label, symbol, keyHint;
  final IconData? icon;
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
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS) {
    try {
      final index = await const MethodChannel('neprosto/popup')
          .invokeMethod<int>(showTitle ? 'contextMenu' : 'choose', {
            'items': [for (final row in rows) row.label],
            if (showTitle) 'heading': title,
            'symbols': [for (final row in rows) row.symbol],
            'shortcuts': [for (final row in rows) row.keyHint],
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
                  color: const Color(0xfffbfbfc),
                  border: Border.all(color: const Color(0xffc9c9cf), width: .7),
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
                              style: const TextStyle(
                                color: CupertinoColors.secondaryLabel,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    for (final (i, row) in rows.indexed) ...[
                      if (row.breakBefore)
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 5,
                          ),
                          child: SizedBox(
                            height: 1,
                            child: ColoredBox(color: Color(0xffdfdfe4)),
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
    final color = hover ? CupertinoColors.white : CupertinoColors.label;
    return MouseRegion(
      onEnter: (_) => setState(() => hover = true),
      onExit: (_) => setState(() => hover = false),
      child: SizedBox(
        height: 32,
        child: CupertinoButton(
          sizeStyle: CupertinoButtonSize.small,
          color: hover ? CupertinoColors.activeBlue : null,
          borderRadius: BorderRadius.circular(5),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: Size.zero,
          onPressed: widget.choose,
          child: Row(
            children: [
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
                    color: hover ? color : CupertinoColors.secondaryLabel,
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
