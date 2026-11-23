import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import 'drawing.dart';
import 'desktop.dart';

import 'package:cupertino_ui/cupertino_ui.dart' as cu;

import 'arithmetic.dart';
import 'model.dart';
import 'controller.dart';
import 'stock_axis.dart';

class StockSizeRow extends StatelessWidget {
  const StockSizeRow(
    this.editor,
    this.axis,
    this.field, {
    this.trailing,
    this.fieldWidth = 92,
    super.key,
  });
  final Editor editor;
  final StockAxis axis;
  final Widget field;
  final Widget? trailing;
  final double fieldWidth;
  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => editor.markSize(axis.index, true),
    onExit: (_) => editor.markSize(axis.index, false),
    child: Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (v) => editor.markSize(axis.index, v, focus: true),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: axis.color.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                axis.letter,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: axis.color,
                ),
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                axis.label,
                style: const TextStyle(fontSize: 12, color: ink),
              ),
            ),
            SizedBox(width: fieldWidth, child: field),
            ?trailing,
          ],
        ),
      ),
    ),
  );
}

Widget iconAction(
  IconData icon,
  String tip,
  VoidCallback? action, {
  bool active = false,
  double size = 18,
}) => DeskIcon(icon, tip, action, active: active, size: size);

Widget sectionTitle(String label, {Widget? trailing}) => Row(
  children: [
    Expanded(
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
      ),
    ),
    ?trailing,
  ],
);

class Units extends InheritedWidget {
  const Units(this.unit, this.step, {super.key, required super.child});
  final double? step;
  final LengthUnit unit;
  static LengthUnit of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<Units>()?.unit ??
      LengthUnit.millimeter;
  @override
  bool updateShouldNotify(Units old) => old.unit != unit || old.step != step;
}

class ValueBox extends StatefulWidget {
  const ValueBox(
    this.value,
    this.changed, {
    super.key,
    this.unit,
    this.signed = false,
    this.live = false,
    this.autofocus = false,
    this.onSubmitted,
    this.onValidityChanged,
  });
  final double value;
  final String? unit;
  final bool signed, live, autofocus;
  final VoidCallback? onSubmitted;
  final ValueChanged<bool>? onValidityChanged;
  final ValueChanged<double> changed;
  @override
  State<ValueBox> createState() => _ValueBoxState();
}

class _ValueBoxState extends State<ValueBox> {
  final text = TextEditingController();
  LengthUnit units = LengthUnit.millimeter;
  String format(double n) => widget.unit == null ? units.format(n) : mm(n);
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = context.dependOnInheritedWidgetOfExactType<Units>();
    final next = scope?.unit ?? LengthUnit.millimeter;
    increment = widget.unit == null ? scope?.step : 1;
    if (text.text.isEmpty || next != units) {
      units = next;
      text.text = format(widget.value);
    }
  }

  final focus = FocusNode();
  double? increment;
  KeyEventResult arrow(FocusNode node, KeyEvent ev) {
    if (ev is KeyUpEvent || increment == null) return KeyEventResult.ignored;
    final dir = ev.logicalKey == LogicalKeyboardKey.arrowUp
        ? 1
        : ev.logicalKey == LogicalKeyboardKey.arrowDown
        ? -1
        : 0;
    if (dir == 0) return KeyEventResult.ignored;
    final n = (parse(text.text) ?? widget.value) + dir * increment!;
    if (widget.signed || n > 0) {
      text.text = format(n);
      text.selection = TextSelection(
        baseOffset: 0,
        extentOffset: text.text.length,
      );
      widget.changed(n);
    }
    return KeyEventResult.handled;
  }

  @override
  void initState() {
    super.initState();
    focus.addListener(_focus);
    focus.onKeyEvent = arrow;
  }

  void _focus() {
    if (mounted) setState(() {});
    if (focus.hasFocus) {
      text.selection = TextSelection(
        baseOffset: 0,
        extentOffset: text.text.length,
      );
    } else {
      _commit();
    }
  }

  double? parse(String s) {
    final result = calculate(s);
    final n = result == null
        ? null
        : result * (widget.unit == null ? units.factor : 1);
    return n != null && n.isFinite && n.abs() <= 1e8 && (widget.signed || n > 0)
        ? n
        : null;
  }

  void _commit() {
    if (text.text == format(widget.value)) return;
    final n = parse(text.text);
    if (n == null && widget.onValidityChanged != null) return;
    if (n != null && n != widget.value) widget.changed(n);
    if (mounted) text.text = format(n ?? widget.value);
    // A constraint may reject an edit. Re-read the actual model value.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !focus.hasFocus) text.text = format(widget.value);
    });
  }

  @override
  void didUpdateWidget(ValueBox old) {
    super.didUpdateWidget(old);
    if (widget.value != old.value &&
        (!focus.hasFocus || parse(text.text) != widget.value)) {
      text.text = format(widget.value);
    }
  }

  @override
  void dispose() {
    focus.removeListener(_focus);
    focus.dispose();
    text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 31,
    child: cu.CupertinoTextField(
      controller: text,
      focusNode: focus,
      autofocus: widget.autofocus,
      style: mono.copyWith(fontSize: 12, color: ink),
      textAlign: TextAlign.right,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) {
        if (widget.onSubmitted != null) {
          if (parse(text.text) != null) widget.onSubmitted!();
        } else {
          focus.unfocus();
        }
      },
      onChanged: widget.live
          ? (s) {
              final n = parse(s);
              if (n != null) widget.changed(n);
              widget.onValidityChanged?.call(n != null);
            }
          : null,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      suffix: Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Text(
          widget.unit ?? units.symbol,
          style: const TextStyle(fontSize: 10, color: muted),
        ),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: focus.hasFocus ? accent : line,
          width: focus.hasFocus ? 1.5 : .8,
        ),
      ),
    ),
  );
}

class Mark extends StatelessWidget {
  const Mark({super.key});
  @override
  Widget build(BuildContext context) => Container(
    width: 32,
    height: 32,
    decoration: BoxDecoration(
      color: accent,
      borderRadius: BorderRadius.circular(8),
    ),
    child: CustomPaint(painter: _MarkPainter()),
  );
}

class _MarkPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()
      ..color = const Color(0xfff1f6e8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7
      ..strokeJoin = StrokeJoin.round;
    for (var i = 0; i < 2; i++) {
      final y = 9.0 + i * 8;
      c.drawPath(
        Path()
          ..moveTo(6, y + 2)
          ..lineTo(20, y - 3)
          ..lineTo(26, y)
          ..lineTo(12, y + 5)
          ..close(),
        p,
      );
      c.drawPath(
        Path()
          ..moveTo(6, y + 2)
          ..lineTo(6, y + 5)
          ..lineTo(12, y + 8)
          ..lineTo(26, y + 3)
          ..lineTo(26, y),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(_MarkPainter old) => false;
}

class MenuChoice<T> extends StatelessWidget {
  const MenuChoice({
    super.key,
    required this.label,
    required this.items,
    required this.change,
    this.icon,
  });
  final String label;
  final List<(T, String)> items;
  final ValueChanged<T> change;
  final IconData? icon;
  @override
  Widget build(BuildContext context) => DeskMenu<T>(
    title: label,
    change: change,
    items: items,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: muted),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          const Icon(cu.CupertinoIcons.chevron_down, size: 15, color: muted),
        ],
      ),
    ),
  );
}
