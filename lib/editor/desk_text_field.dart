import '../l10n/strings.dart';
import 'palette.dart';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart' as m;

import 'platform_ui.dart';

class DeskTextField extends StatelessWidget {
  const DeskTextField({
    super.key,
    this.controller,
    this.initialValue,
    this.placeholder,
    this.focusNode,
    this.autofocus = false,
    this.enabled = true,
    this.textAlign = TextAlign.start,
    this.style,
    this.onChanged,
    this.onStep,
    this.onSubmitted,
    this.keyboardType,
    this.inputFormatters,
    this.suffix,
    this.cupertinoDecoration,
  });

  final TextEditingController? controller;
  final String? initialValue, placeholder;
  final FocusNode? focusNode;
  final bool autofocus, enabled;
  final TextAlign textAlign;
  final TextStyle? style;
  final ValueChanged<String>? onChanged, onSubmitted;
  final ValueChanged<int>? onStep;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffix;
  final BoxDecoration? cupertinoDecoration;

  @override
  Widget build(BuildContext context) {
    final field = _field(context);
    final step = onStep;
    if (!enabled || step == null) return field;
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (_, event) {
        if (event is KeyUpEvent) return KeyEventResult.ignored;
        if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          step(1);
        } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          step(-1);
        } else if ((event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.numpadEnter) &&
            onSubmitted != null &&
            controller != null) {
          if (event is KeyDownEvent) onSubmitted!(controller!.text);
        } else {
          return KeyEventResult.ignored;
        }
        return KeyEventResult.handled;
      },
      child: field,
    );
  }

  Widget _field(BuildContext context) {
    const padding = EdgeInsets.symmetric(horizontal: 6, vertical: 4);
    if (!appleControls) {
      return m.TextFormField(
        initialValue: initialValue,
        controller: controller,
        focusNode: focusNode,
        autofocus: autofocus,
        enabled: enabled,
        style: style ?? const TextStyle(fontSize: 13),
        textAlign: textAlign,
        textInputAction: TextInputAction.done,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        onEditingComplete: onStep == null ? null : () {},
        onFieldSubmitted: onSubmitted,
        decoration: m.InputDecoration(
          hintText: placeholder,
          fillColor: enabled ? null : context.colors.chrome,
          isDense: true,
          contentPadding: padding,
          border: const m.OutlineInputBorder(),
          suffixIcon: suffix,
          suffixIconConstraints: const BoxConstraints(),
        ),
      );
    }
    final decoration =
        cupertinoDecoration ??
        BoxDecoration(
          color: context.colors.field,
          border: Border.fromBorderSide(BorderSide(color: context.colors.line)),
          borderRadius: BorderRadius.circular(5),
        );
    if (initialValue != null) {
      return CupertinoTextFormFieldRow(
        initialValue: initialValue,
        padding: EdgeInsets.zero,
        decoration: decoration,
        textInputAction: TextInputAction.done,
        placeholder: placeholder,
        autofocus: autofocus,
        style: style,
        onChanged: onChanged,
        onFieldSubmitted: onSubmitted,
      );
    }
    return CupertinoTextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      enabled: enabled,
      style: style,
      textAlign: textAlign,
      textInputAction: TextInputAction.done,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      onEditingComplete: onStep == null ? null : () {},
      onSubmitted: onSubmitted,
      padding: padding,
      suffix: suffix,
      decoration: decoration,
    );
  }
}

class DeskSearchField extends StatefulWidget {
  const DeskSearchField({
    super.key,
    required this.placeholder,
    required this.onChanged,
  });
  final String placeholder;
  final ValueChanged<String> onChanged;

  @override
  State<DeskSearchField> createState() => _DeskSearchFieldState();
}

class _DeskSearchFieldState extends State<DeskSearchField> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (appleControls) {
      return CupertinoSearchTextField(
        backgroundColor: context.colors.chrome,
        style: macControls
            ? TextStyle(fontSize: 13, color: context.colors.ink)
            : null,
        controller: controller,
        placeholder: widget.placeholder,
        onChanged: widget.onChanged,
      );
    }
    return m.TextField(
      controller: controller,
      style: const TextStyle(fontSize: 13),
      onChanged: widget.onChanged,
      decoration: m.InputDecoration(
        isDense: true,
        hintText: widget.placeholder,
        prefixIcon: const Icon(m.Icons.search, size: 16),
        prefixIconConstraints: const BoxConstraints(minWidth: 26),
        suffixIconConstraints: const BoxConstraints(minWidth: 24),
        contentPadding: const EdgeInsets.symmetric(vertical: 6),
        border: const m.OutlineInputBorder(),
        suffixIcon: ValueListenableBuilder(
          valueListenable: controller,
          builder: (_, value, _) => value.text.isEmpty
              ? const SizedBox.shrink()
              : m.IconButton(
                  tooltip: context.strings.clearSearch,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 28,
                  ),
                  padding: EdgeInsets.zero,
                  icon: const Icon(m.Icons.close, size: 15),
                  onPressed: () {
                    controller.clear();
                    widget.onChanged('');
                  },
                ),
        ),
      ),
    );
  }
}
