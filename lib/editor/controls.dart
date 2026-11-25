import '../l10n/strings.dart';
import 'palette.dart';
import 'platform_ui.dart';
import 'desk_text_field.dart';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'drawing.dart';
import 'desktop.dart';

import 'package:cupertino_ui/cupertino_ui.dart' as cu;

import 'arithmetic.dart';
import 'model.dart';
import 'controller.dart';
import 'stock_axis.dart';
import 'step.dart';

const double inspectorFieldWidth = 92;

class StockSizeRow extends StatelessWidget {
  const StockSizeRow(
    this.editor,
    this.axis,
    this.field, {
    this.trailing,
    this.fieldWidth = inspectorFieldWidth,
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
                color: context.colors
                    .diagramColor(axis.color)
                    .withValues(alpha: .10),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                axis.letter,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: context.colors.diagramColor(axis.color),
                ),
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                axis.label,
                style: TextStyle(fontSize: 12, color: context.colors.ink),
              ),
            ),
            SizedBox(width: fieldWidth, child: field),
            if (trailing != null) const SizedBox(width: 6),
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

Widget sizeLockButton(StockAxis axis, bool locked, VoidCallback? toggle) =>
    dimensionLockButton(axis.label, locked, toggle);

Widget dimensionLockButton(String label, bool locked, VoidCallback? toggle) =>
    iconAction(
      locked ? cu.CupertinoIcons.lock : cu.CupertinoIcons.lock_open,
      editorStrings.resizeLockHint(
        locked ? editorStrings.unlock : editorStrings.lock,
        label,
      ),
      toggle,
      active: locked,
      size: 15,
    );

Widget sectionTitle(String label, {Widget? trailing}) => Row(
  children: [
    Expanded(
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    ),
    ?trailing,
  ],
);

class Units extends InheritedWidget {
  const Units(this.input, {super.key, required super.child});
  final LengthInput input;
  static LengthInput of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<Units>()?.input ??
      (unit: LengthUnit.millimeter, increment: null);
  @override
  bool updateShouldNotify(Units old) => old.input != input;
}

/// Keeps untouched geometry exact while its text is shown at editing precision.
class LengthEditingController extends TextEditingController {
  LengthEditingController(this.input, double? value)
    : _original = value,
      super(text: value == null ? '' : input.format(value));

  final LengthInput input;
  double? _original;
  double? get millimeters => _original ?? input.parse(text);
  void edited() => _original = null;

  void setMillimeters(double? mm) {
    _original = mm;
    text = mm == null ? '' : input.format(mm);
  }
}

class DraftLengthField extends StatefulWidget {
  const DraftLengthField(this.controller, this.changed, {super.key});
  final LengthEditingController controller;
  final VoidCallback changed;
  @override
  State<DraftLengthField> createState() => _DraftLengthFieldState();
}

class _DraftLengthFieldState extends State<DraftLengthField> {
  final focus = FocusNode();

  @override
  void initState() {
    super.initState();
    focus.addListener(normalize);
    focus.onKeyEvent = (_, event) {
      final field = widget.controller;
      final step = field.input.stepMm, value = field.millimeters;
      if (event is KeyUpEvent || step == null || value == null) {
        return KeyEventResult.ignored;
      }
      final key = event.logicalKey;
      if (key != LogicalKeyboardKey.arrowUp &&
          key != LogicalKeyboardKey.arrowDown) {
        return KeyEventResult.ignored;
      }
      field.setMillimeters(
        field.input.round(
          value + (key == LogicalKeyboardKey.arrowUp ? step : -step),
        ),
      );
      widget.changed();
      return KeyEventResult.handled;
    };
  }

  void normalize() {
    final field = widget.controller;
    if (focus.hasFocus) return;
    if (field.millimeters case final mm?) {
      field.setMillimeters(mm);
    }
  }

  @override
  void dispose() {
    focus.removeListener(normalize);
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DeskTextField(
    controller: widget.controller,
    focusNode: focus,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    onChanged: (_) {
      widget.controller.edited();
      widget.changed();
    },
    onSubmitted: (_) => focus.unfocus(),
    suffix: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: Text(
        widget.controller.input.unit.symbol,
        style: TextStyle(fontSize: 12, color: context.colors.muted),
      ),
    ),
  );
}

class ValueBox extends StatefulWidget {
  const ValueBox(
    this.value,
    this.changed, {
    super.key,
    this.unit,
    this.formatValue,
    this.signed = false,
    this.live = false,
    this.autofocus = false,
    this.enabled = true,
    this.onSubmitted,
    this.onValidityChanged,
    this.onFocusChanged,
    this.onCleared,
    this.placeholder,
  });
  final double? value;
  final String? unit, placeholder;
  final String Function(double)? formatValue;
  final bool signed, live, autofocus, enabled;
  final VoidCallback? onSubmitted, onCleared;
  final ValueChanged<bool>? onValidityChanged;
  final ValueChanged<bool>? onFocusChanged;
  final ValueChanged<double> changed;
  @override
  State<ValueBox> createState() => _ValueBoxState();
}

class _ValueBoxState extends State<ValueBox> {
  final text = TextEditingController();
  LengthInput input = (unit: LengthUnit.millimeter, increment: null);
  bool edited = false;
  String format(double? n) {
    if (n == null) return '';
    if (widget.formatValue case final formatter?) return formatter(n);
    return widget.unit == null ? input.format(n) : mm(n);
  }

  bool get cleared => widget.onCleared != null && text.text.trim().isEmpty;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = Units.of(context);
    if (text.text.isEmpty || next != input) {
      input = next;
      edited = false;
      text.text = format(widget.value);
    }
  }

  final focus = FocusNode();
  KeyEventResult arrow(FocusNode node, KeyEvent ev) {
    final increment = widget.unit == null ? input.stepMm : 1.0;
    if (!widget.enabled || ev is KeyUpEvent || increment == null) {
      return KeyEventResult.ignored;
    }
    final dir = ev.logicalKey == LogicalKeyboardKey.arrowUp
        ? 1
        : ev.logicalKey == LogicalKeyboardKey.arrowDown
        ? -1
        : 0;
    if (dir == 0) return KeyEventResult.ignored;
    final base = parse(text.text) ?? widget.value;
    if (base == null) return KeyEventResult.ignored;
    final sum = base + dir * increment;
    final n = widget.unit == null ? input.round(sum) : sum;
    if (widget.signed || n > 0) {
      text.text = format(n);
      text.selection = TextSelection(
        baseOffset: 0,
        extentOffset: text.text.length,
      );
      widget.changed(n);
      widget.onValidityChanged?.call(true);
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
    widget.onFocusChanged?.call(focus.hasFocus);
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
    final n = widget.unit == null ? input.parse(s) : calculate(s);
    return n != null && n.isFinite && n.abs() <= 1e8 && (widget.signed || n > 0)
        ? n
        : null;
  }

  void _commit() {
    if (!edited && text.text == format(widget.value)) return;
    edited = false;
    if (!widget.enabled) {
      text.text = format(widget.value);
      return;
    }
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
    height: macControls ? 27 : 31,
    child: DeskTextField(
      controller: text,
      focusNode: focus,
      autofocus: widget.autofocus,
      enabled: widget.enabled,
      placeholder: widget.placeholder,
      style: mono.copyWith(
        fontSize: 12,
        color: widget.enabled ? context.colors.ink : context.colors.muted,
      ),
      textAlign: TextAlign.right,
      onSubmitted: (_) {
        if (widget.onSubmitted != null) {
          if (cleared || parse(text.text) != null) widget.onSubmitted!();
        } else {
          focus.unfocus();
        }
      },
      onChanged: (s) {
        edited = true;
        if (!widget.live) return;
        final n = parse(s);
        if (cleared) {
          widget.onCleared!();
        } else if (n != null) {
          widget.changed(n);
        }
        widget.onValidityChanged?.call(cleared || n != null);
      },
      suffix: Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Text(
          widget.unit ?? input.unit.symbol,
          style: TextStyle(
            fontSize: 10,
            color: widget.enabled
                ? context.colors.muted
                : context.colors.disabled,
          ),
        ),
      ),
      cupertinoDecoration: BoxDecoration(
        color: widget.enabled ? context.colors.field : context.colors.chrome,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: focus.hasFocus ? context.colors.accent : context.colors.line,
          width: focus.hasFocus ? 1.5 : .8,
        ),
      ),
    ),
  );
}

class Mark extends StatelessWidget {
  const Mark({super.key});
  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    'assets/mark.svg',
    width: 32,
    height: 32,
    excludeFromSemantics: true,
  );
}

class MenuChoice<T> extends StatelessWidget {
  const MenuChoice({
    super.key,
    required this.label,
    required this.items,
    required this.change,
    this.icon,
    this.compactLabel,
    this.selected,
  });
  final String label;
  final String? compactLabel;
  final List<(T, String)> items;
  final ValueChanged<T> change;
  final IconData? icon;
  final T? selected;
  @override
  Widget build(BuildContext context) => DeskMenu<T>(
    title: label,
    selected: selected,
    change: change,
    items: items,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: controlGap,
        children: [
          if (icon != null) Icon(icon, size: 16, color: context.colors.muted),
          Flexible(
            child: Text(
              compactLabel ?? label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          Icon(
            cu.CupertinoIcons.chevron_down,
            size: 15,
            color: context.colors.muted,
          ),
        ],
      ),
    ),
  );
}
