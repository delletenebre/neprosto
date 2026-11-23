import 'dart:math' as math;

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

import 'controller.dart';
import 'controls.dart';
import 'desktop.dart';
import 'drawing.dart';
import 'hotkeys.dart';
import 'model.dart';
import 'step.dart';

enum SettingsPage {
  editing('Редактирование', CupertinoIcons.slider_horizontal_3),
  drawing('Чертёж', CupertinoIcons.square_on_square),
  workspace('Пространство', CupertinoIcons.cube_box),
  keyboard('Горячие клавиши', CupertinoIcons.keyboard);

  const SettingsPage(this.title, this.icon);
  final String title;
  final IconData icon;
}

typedef SettingsResult = ({
  EditStep step,
  bool snap,
  bool dimensions,
  EditorHotkeys hotkeys,
  Vector3? workspace,
});

class EditorSettings extends StatefulWidget {
  const EditorSettings(this.editor, this.initial, {super.key});
  final Editor editor;
  final SettingsPage initial;
  @override
  State<EditorSettings> createState() => _EditorSettingsState();
}

class _EditorSettingsState extends State<EditorSettings> {
  late SettingsPage page = widget.initial;
  late final unit = widget.editor.project.unit;
  late bool snap = widget.editor.snapByDefault,
      show = widget.editor.dimensionsByDefault;
  late bool stepped = widget.editor.step.enabled;
  late double increment = widget.editor.step.millimeters(unit);
  late EditorHotkeys keys = widget.editor.hotkeys;
  late bool bounded = widget.editor.project.workspaceSize != null;
  late final room =
      widget.editor.project.workspaceSize?.clone() ?? Vector3(3000, 3000, 2500);
  final invalid = <String>{};
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
        setState(
          () => error =
              'Выберите букву, цифру, стрелку или функциональную клавишу',
        );
      }
    }
    return KeyEventResult.handled;
  }

  void setPage(SettingsPage value) {
    FocusManager.instance.primaryFocus?.unfocus();
    if (scroll.hasClients) scroll.jumpTo(0);
    setState(() {
      invalid.clear();
      page = value;
      recording = null;
      error = null;
    });
  }

  Widget caption(String text) => Text(
    text,
    style: const TextStyle(color: muted, fontSize: 12, height: 1.35),
  );
  Widget heading(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: ink,
      ),
    ),
  );

  Widget card(List<Widget> children) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
    decoration: BoxDecoration(
      color: CupertinoColors.white,
      border: Border.all(color: line, width: .7),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );

  Widget field(
    String id,
    double value,
    ValueChanged<double> onChange,
    double width,
  ) => SizedBox(
    width: width,
    child: ValueBox(
      value,
      onChange,
      key: ValueKey(id),
      live: true,
      onValidityChanged: (valid) {
        if (invalid.contains(id) == valid) {
          setState(() => valid ? invalid.remove(id) : invalid.add(id));
        }
      },
    ),
  );

  List<Widget> editing() => [
    heading('Перемещение и линейка'),
    card([
      const Text('Режим без нажатых клавиш'),
      const SizedBox(height: 9),
      DeskSegments(snap, const {
        false: 'Свободно',
        true: 'С привязкой',
      }, (v) => setState(() => snap = v)),
      const SizedBox(height: 7),
      caption(
        snap
            ? 'Удерживайте Ctrl или ⌘ для свободного движения.'
            : 'Удерживайте Ctrl или ⌘ для привязки.',
      ),
    ]),
    const SizedBox(height: 18),
    heading('Перемещение и растягивание'),
    card([
      Row(
        children: [
          const Expanded(child: Text('Двигать и растягивать с шагом')),
          if (stepped) ...[
            field(
              'input-step',
              increment,
              (n) => setState(() => increment = n),
              78,
            ),
            const SizedBox(width: 9),
          ],
          DeskSwitch(
            value: stepped,
            onChanged: (v) => setState(() {
              stepped = v;
              invalid.remove('input-step');
            }),
          ),
        ],
      ),
      const SizedBox(height: 8),
      caption(
        stepped
            ? 'Стрелка сдвигает деталь на ${unit.format(increment)} ${unit.symbol}. При растягивании длина меняется шагами, например ${[20, 21, 22].map((n) => unit.format(increment * n)).join(' → ')} ${unit.symbol}.'
            : 'При перетаскивании положение и длина меняются плавно.',
      ),
    ]),
  ];

  List<Widget> drawing() {
    final held = keys[Command.dimensions].label;
    return [
      heading('Размеры на чертеже'),
      card([
        DeskSegments(show, {
          true: 'Всегда видны',
          false: 'Только с $held',
        }, (v) => setState(() => show = v)),
        const SizedBox(height: 9),
        caption(
          'Удерживайте $held, чтобы ${show ? 'скрыть' : 'показать'} размеры.',
        ),
      ]),
    ];
  }

  List<Widget> workspace() => [
    heading('Рабочее пространство проекта'),
    card([
      Row(
        children: [
          const Expanded(child: Text('Задать границы')),
          DeskSwitch(
            value: bounded,
            onChanged: (v) => setState(() {
              bounded = v;
              invalid.removeWhere((id) => id.startsWith('workspace-'));
            }),
          ),
        ],
      ),
      if (bounded)
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(['Ширина · X', 'Глубина · Y', 'Высота · Z'][i]),
                ),
                field(
                  'workspace-$i',
                  room[i],
                  (n) => setState(() => room[i] = n),
                  100,
                ),
              ],
            ),
          ),
    ]),
    const SizedBox(height: 8),
    caption(
      'Границы отсчитываются от начала координат. Размеры и положение деталей сохраняются.',
    ),
  ];

  List<Widget> keyboard() => [
    caption('Нажмите на сочетание и введите новое. Esc отменяет ввод.'),
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
                  children: [
                    Expanded(child: Text(command.label)),
                    Semantics(
                      label: 'Сменить сочетание для «${command.label}»',
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
                                ? 'Нажмите клавиши…'
                                : keys[command].label,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (recording == command && error != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      error!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.systemRed,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ]),
    ],
  ];

  void apply() {
    final result = (
      step: widget.editor.step.change(unit, increment / unit.factor, stepped),
      snap: snap,
      dimensions: show,
      hotkeys: keys,
      workspace: bounded ? room : null,
    );
    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) => DeskDialog(
    maxWidth: 650,
    title: const Text('Настройки'),
    content: SizedBox(
      height: math.min(
        355,
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
                            color: page == tab ? accent : muted,
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
            color: line,
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          Expanded(
            child: CupertinoScrollbar(
              controller: scroll,
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.only(right: 6),
                children: switch (page) {
                  SettingsPage.editing => editing(),
                  SettingsPage.drawing => drawing(),
                  SettingsPage.keyboard => keyboard(),
                  SettingsPage.workspace => workspace(),
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
          child: const Text('Сбросить сочетания'),
        ),
      DeskButton(
        plain: true,
        onPressed: () => Navigator.pop(context),
        child: const Text('Отмена'),
      ),
      DeskButton(
        primary: true,
        onPressed: recording == null && invalid.isEmpty ? apply : null,
        child: const Text('Готово'),
      ),
    ],
  );
}
