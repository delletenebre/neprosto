import '../l10n/strings.dart';
import 'palette.dart';
import 'desk_text_field.dart';

import 'dart:math' as math;

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

import 'controller.dart';
import 'arithmetic.dart';
import 'controls.dart';
import 'desktop.dart';
import 'hotkeys.dart';
import 'model.dart';
import 'platform_ui.dart';

import 'package:material_ui/material_ui.dart' as m;

import 'grid_controls.dart';
import 'grid_visibility.dart';
import 'step.dart';

enum SettingsPage {
  editing(CupertinoIcons.slider_horizontal_3),
  appearance(CupertinoIcons.paintbrush),
  drawing(CupertinoIcons.square_on_square),
  saving(CupertinoIcons.square_arrow_down),
  keyboard(CupertinoIcons.keyboard);

  const SettingsPage(this.icon);

  final IconData icon;
  String get title => switch (this) {
    SettingsPage.editing => editorStrings.editing,
    SettingsPage.appearance => editorStrings.appearance,
    SettingsPage.drawing => editorStrings.drawing,
    SettingsPage.saving => editorStrings.saving,
    SettingsPage.keyboard => editorStrings.keyboardShortcuts,
  };
}

typedef SettingsResult = ({
  EditorPalette? palette,
  Locale locale,
  LengthUnit unit,
  EditStep step,
  bool snap,
  bool dimensions,
  bool showHiddenOutlines,
  EditorHotkeys hotkeys,
  GridVisibility grid,
  bool autosave,
  int autosaveMinutes,
});

class EditorSettings extends StatefulWidget {
  const EditorSettings(
    this.editor, {
    this.palette,
    this.locale = const Locale('ru'),
    required this.onPreview,
    required this.autosave,
    required this.autosaveMinutes,
    super.key,
  });
  final Editor editor;
  final EditorPalette? palette;
  final Locale locale;
  final void Function(EditorPalette?, Locale) onPreview;
  final bool autosave;
  final int autosaveMinutes;
  @override
  State<EditorSettings> createState() => _EditorSettingsState();
}

class _EditorSettingsState extends State<EditorSettings> {
  late EditorPalette? palette = widget.palette;
  late Locale locale = widget.locale;
  SettingsPage page = SettingsPage.editing;
  late LengthUnit unit = widget.editor.displayUnit;
  late bool snap = widget.editor.snapByDefault,
      show = widget.editor.dimensionsByDefault;
  late EditStep step = widget.editor.step;
  late GridVisibility grid = widget.editor.gridVisibility;
  late bool showHiddenOutlines = widget.editor.showHiddenOutlines;
  late EditorHotkeys keys = widget.editor.hotkeys;
  late bool autosave = widget.autosave;
  late final minutes = TextEditingController(
    text: widget.autosaveMinutes.toString(),
  );
  int? get interval {
    final value = calculate(minutes.text);
    if (value == null || value != value.truncateToDouble()) return null;
    final integer = value.toInt();
    return integer == value ? integer : null;
  }

  bool stepValid = true;
  Command? _recording;
  Command? get recording => _recording;
  set recording(Command? command) {
    if ((_recording == null) != (command == null)) {
      setNativeCapture(command != null);
    }
    _recording = command;
  }

  Future<void> setNativeCapture(bool active) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.macOS) return;
    try {
      await const MethodChannel('neprosto/popup')
          .invokeMethod<void>('captureShortcut', active);
    } on MissingPluginException {
      // Flutter alone handles recording on hosts without an AppKit menu.
    }
  }

  String? error;
  final scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addEarlyKeyEventHandler(capture);
  }

  @override
  void dispose() {
    FocusManager.instance.removeEarlyKeyEventHandler(capture);
    recording = null;
    scroll.dispose();
    minutes.dispose();
    super.dispose();
  }

  KeyEventResult capture(KeyEvent event) {
    final command = recording;
    if (command == null || ModalRoute.of(context)?.isCurrent != true) {
      return KeyEventResult.ignored;
    }
    if (event is KeyDownEvent && !event.synthesized) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        setState(() {
          recording = null;
          error = null;
        });
      } else if (chordFor(event) case final chord?) {
        setState(() {
          error = keys.conflict(command, chord);
          if (error == null) {
            keys = keys.assign(command, chord);
            recording = null;
          }
        });
      } else if (!{
        LogicalKeyboardKey.control,
        LogicalKeyboardKey.meta,
        LogicalKeyboardKey.shift,
        LogicalKeyboardKey.alt,
      }.contains(
        LogicalKeyboardKey.collapseSynonyms({event.logicalKey}).first,
      )) {
        setState(() => error = context.strings.shortcutKeyHint);
      }
    }
    return KeyEventResult.handled;
  }

  void setPage(SettingsPage value) {
    FocusManager.instance.primaryFocus?.unfocus();
    if (scroll.hasClients) scroll.jumpTo(0);
    setState(() {
      stepValid = true;
      page = value;
      recording = null;
      error = null;
    });
  }

  Widget caption(String text) => Text(
    text,
    style: TextStyle(color: context.colors.muted, fontSize: 12, height: 1.35),
  );
  Widget heading(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: context.colors.ink,
      ),
    ),
  );

  Widget card(List<Widget> children) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
    decoration: BoxDecoration(
      color: context.colors.field,
      border: Border.all(color: context.colors.line, width: .7),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );

  Widget stepField(LengthUnit fieldUnit) => Units(
    (unit: fieldUnit, increment: null),
    key: ValueKey(fieldUnit),
    child: SizedBox(
      width: 78,
      child: ValueBox(
        step.millimeters(fieldUnit),
        (mm) => setState(() {
          step = step.change(fieldUnit, mm / fieldUnit.factor);
        }),
        key: const ValueKey('input-step'),
        formatValue: fieldUnit.formatStep,
        live: true,
        onValidityChanged: (valid) {
          if (valid != stepValid) setState(() => stepValid = valid);
        },
      ),
    ),
  );

  Widget stepPresets(List<double> values) => DeskSegmentedControl<double>(
    value: values.contains(step.value(unit)) ? step.value(unit) : null,
    children: {
      for (final value in values)
        value: Text(
          unit == LengthUnit.inch
              ? '${unit.formatStep(value * unit.factor)}${unit.symbol}'
              : '${unit.format(value * unit.factor)} ${unit.symbol}',
        ),
    },
    change: (value) {
      FocusManager.instance.primaryFocus?.unfocus();
      setState(() {
        step = step.change(unit, value);
        stepValid = true;
      });
    },
  );

  List<Widget> editing() => [
    heading(context.strings.measurementUnits),
    DeskSegments(
      unit,
      {for (final choice in LengthUnit.values) choice: choice.title},
      (next) => setState(() {
        unit = next;
        stepValid = true;
      }),
    ),
    const SizedBox(height: 18),
    heading(context.strings.precision),
    card([
      Row(
        children: [
          Expanded(child: Text(context.strings.editingIncrement)),
          stepField(unit),
        ],
      ),
      const SizedBox(height: 8),
      stepPresets(const [1, .1, .01]),
      if (unit == LengthUnit.inch) ...[
        const SizedBox(height: 6),
        stepPresets(const [1 / 8, 1 / 16, 1 / 32]),
      ],
      const SizedBox(height: 12),
      Text(context.strings.anglePrecision),
      const SizedBox(height: 8),
      DeskSegments(step.anglePrecision, {
        for (final p in AnglePrecision.values) p: '${mm(p.increment)}°',
      }, (p) => setState(() => step = step.withAnglePrecision(p))),
    ]),
    const SizedBox(height: 18),
    heading(context.strings.movementAndRuler),
    card([
      Text(context.strings.modeWithoutModifierKeys),
      const SizedBox(height: 9),
      DeskSegments(snap, {
        false: context.strings.free,
        true: context.strings.snapping,
      }, (v) => setState(() => snap = v)),
      const SizedBox(height: 7),
      caption(
        snap
            ? context.strings.freeMovementHint(primaryModifierLabel)
            : context.strings.holdToSnap(primaryModifierLabel),
      ),
    ]),
  ];

  List<Widget> drawing() {
    final held = keys[Command.dimensions].label;
    return [
      heading(context.strings.dimensionsOnDrawing),
      card([
        DeskSegments(show, {
          true: context.strings.alwaysVisible,
          false: context.strings.onlyWith(held),
        }, (v) => setState(() => show = v)),
        const SizedBox(height: 9),
        caption(
          context.strings.holdDimensionModifier(
            held,
            show ? context.strings.hide : context.strings.show,
          ),
        ),
      ]),
      const SizedBox(height: 16),
      heading(context.strings.hiddenParts),
      card([
        DeskSegments(showHiddenOutlines, {
          false: context.strings.hideCompletely,
          true: context.strings.showOutlines,
        }, (v) => setState(() => showHiddenOutlines = v)),
      ]),
      const SizedBox(height: 16),
      heading(context.strings.gridVisibility),
      card([GridControls(grid, (next) => setState(() => grid = next))]),
    ];
  }

  List<Widget> saving() => [
    heading(context.strings.autosave),
    card([
      Row(
        children: [
          Expanded(child: Text(context.strings.saveProjectsAutomatically)),
          DeskSwitch(
            value: autosave,
            onChanged: (value) => setState(() => autosave = value),
          ),
        ],
      ),
      if (autosave) ...[
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: Text(context.strings.intervalMin)),
            SizedBox(
              width: 70,
              child: DeskTextField(
                controller: minutes,
                onStep: (direction) {
                  final next = (interval ?? 0) + direction;
                  if (next > 0) setState(() => minutes.text = next.toString());
                },
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) {
                  final value = interval;
                  if (value != null && value > 0) {
                    setState(() => minutes.text = value.toString());
                  }
                },
              ),
            ),
          ],
        ),
        if ((interval ?? 0) < 1) ...[
          const SizedBox(height: controlGap),
          caption(context.strings.positiveIntegerHint),
        ],
      ],
    ]),
    if (autosave) ...[
      const SizedBox(height: 8),
      caption(
        kIsWeb
            ? context.strings.browserDraftsHint
            : context.strings.autosaveFilesHint,
      ),
    ],
  ];

  List<Widget> keyboard() => [
    caption(context.strings.recordShortcutHint),
    for (final group in Command.values.map((c) => c.category).toSet()) ...[
      const SizedBox(height: 14),
      heading(group),
      card([
        for (final command in Command.values.where((c) => c.category == group))
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Column(
              children: [
                Row(
                  spacing: controlGap,
                  children: [
                    Expanded(child: Text(command.label)),
                    Semantics(
                      label: context.strings.changeShortcutFor(command.label),
                      child: DeskButton(
                        key: ValueKey('shortcut-${command.name}'),
                        active: recording == command,
                        onPressed: () => setState(() {
                          recording = command;
                          error = null;
                        }),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minWidth: 42),
                          child: Text(
                            recording == command
                                ? context.strings.pressKeys
                                : keys.commandFor(keys[command]) == command
                                ? keys[command].label
                                : context.strings.assign,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (recording == command && error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: controlGap),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        error!,
                        style: TextStyle(
                          fontSize: 12,
                          color: context.colors.danger,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ]),
    ],
  ];

  void preview(EditorPalette? nextPalette, Locale nextLocale) {
    setState(() {
      palette = nextPalette;
      locale = nextLocale;
    });
    widget.onPreview(nextPalette, nextLocale);
  }

  void apply() {
    final result = (
      unit: unit,
      step: step,
      snap: snap,
      dimensions: show,
      showHiddenOutlines: showHiddenOutlines,
      palette:
          palette ?? (page == SettingsPage.appearance ? context.colors : null),
      locale: locale,
      hotkeys: keys,
      grid: grid,
      autosave: autosave,
      autosaveMinutes: (interval ?? 0) > 0 ? interval! : widget.autosaveMinutes,
    );
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) => DeskDialog(
    maxWidth: 650,
    title: Text(context.strings.settings),
    content: SizedBox(
      height: math.min(
        425,
        math.max(180, MediaQuery.sizeOf(context).height - 165),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 166,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final tab in SettingsPage.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: DeskButton(
                      plain: true,
                      active: page == tab,
                      onPressed: () => setPage(tab),
                      child: Row(
                        children: [
                          Icon(
                            tab.icon,
                            color: page == tab
                                ? context.colors.accent
                                : context.colors.muted,
                            size: 17,
                          ),
                          const SizedBox(width: 8),
                          Flexible(child: Text(tab.title)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            width: .7,
            color: context.colors.line,
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          Expanded(
            child: m.Scrollbar(
              controller: scroll,
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.only(right: 6),
                children: switch (page) {
                  SettingsPage.appearance => [
                    heading(context.strings.theme),
                    DeskSegments(palette ?? context.colors, {
                      EditorPalette.light: context.strings.light,
                      EditorPalette.dark: context.strings.dark,
                    }, (v) => preview(v, locale)),
                    const SizedBox(height: 18),
                    heading(context.strings.language),
                    DeskSegments(locale, {
                      const Locale('ru'): 'Русский',
                      const Locale('en'): 'English',
                      const Locale('ky'): 'Кыргызча',
                    }, (v) => preview(palette, v)),
                  ],
                  SettingsPage.editing => editing(),
                  SettingsPage.drawing => drawing(),
                  SettingsPage.saving => saving(),
                  SettingsPage.keyboard => keyboard(),
                },
              ),
            ),
          ),
        ],
      ),
    ),
    actions: [
      if (page == SettingsPage.keyboard)
        DeskButton(
          plain: true,
          onPressed: keys.customized
              ? () => setState(() {
                  keys = EditorHotkeys();
                  recording = null;
                  error = null;
                })
              : null,
          child: Text(context.strings.resetShortcuts),
        ),
      DeskButton(
        plain: true,
        onPressed: () => Navigator.pop(context),
        child: Text(context.strings.cancel),
      ),
      DeskButton(
        primary: true,
        onPressed:
            recording == null && stepValid && (!autosave || (interval ?? 0) > 0)
            ? apply
            : null,
        child: Text(context.strings.done),
      ),
    ],
  );
}
