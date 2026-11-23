import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum Command {
  add(
    'Новая деталь',
    'Инструменты',
    LogicalKeyboardKey.keyQ,
    alias: LogicalKeyboardKey.keyB,
  ),
  select('Выбор деталей', 'Инструменты', LogicalKeyboardKey.keyV),
  move('Переместить по опорам', 'Инструменты', LogicalKeyboardKey.keyM),
  rotate('Повернуть деталь', 'Инструменты', LogicalKeyboardKey.keyR),
  measure('Измерить расстояние', 'Инструменты', LogicalKeyboardKey.keyD),
  fit('Вписать в окно', 'Вид', LogicalKeyboardKey.keyF),
  dimensions('Показать / скрыть размеры', 'Вид', LogicalKeyboardKey.tab),
  undo(
    'Отменить действие',
    'Редактирование',
    LogicalKeyboardKey.keyZ,
    primary: true,
  ),
  redo(
    'Повторить действие',
    'Редактирование',
    LogicalKeyboardKey.keyZ,
    primary: true,
    shift: true,
  ),
  selectAll(
    'Выбрать все детали',
    'Редактирование',
    LogicalKeyboardKey.keyA,
    primary: true,
  ),
  duplicate(
    'Дублировать',
    'Редактирование',
    LogicalKeyboardKey.keyD,
    primary: true,
  ),
  delete(
    'Удалить',
    'Редактирование',
    LogicalKeyboardKey.backspace,
    alias: LogicalKeyboardKey.delete,
  ),
  group(
    'Сгруппировать',
    'Редактирование',
    LogicalKeyboardKey.keyG,
    primary: true,
  ),
  ungroup(
    'Разгруппировать',
    'Редактирование',
    LogicalKeyboardKey.keyG,
    primary: true,
    shift: true,
  ),
  left('Влево', 'Сдвиг', LogicalKeyboardKey.arrowLeft),
  right('Вправо', 'Сдвиг', LogicalKeyboardKey.arrowRight),
  up('Вверх', 'Сдвиг', LogicalKeyboardKey.arrowUp),
  down('Вниз', 'Сдвиг', LogicalKeyboardKey.arrowDown),
  stopLeft(
    'До упора влево',
    'Сдвиг',
    LogicalKeyboardKey.arrowLeft,
    shift: true,
  ),
  stopRight(
    'До упора вправо',
    'Сдвиг',
    LogicalKeyboardKey.arrowRight,
    shift: true,
  ),
  stopUp('До упора вверх', 'Сдвиг', LogicalKeyboardKey.arrowUp, shift: true),
  stopDown('До упора вниз', 'Сдвиг', LogicalKeyboardKey.arrowDown, shift: true),
  newProject('Новый проект', 'Проект', LogicalKeyboardKey.keyN, primary: true),
  open('Открыть проект', 'Проект', LogicalKeyboardKey.keyO, primary: true),
  save('Сохранить проект', 'Проект', LogicalKeyboardKey.keyS, primary: true),
  settings('Настройки', 'Проект', LogicalKeyboardKey.comma, primary: true);

  const Command(
    this.label,
    this.category,
    this.key, {
    this.primary = false,
    this.shift = false,
    this.alias,
  });
  final String label, category;
  final LogicalKeyboardKey key;
  final LogicalKeyboardKey? alias;
  final bool primary, shift;
  Chord get standard => (key: key, primary: primary, shift: shift, alt: false);
}

typedef Chord = ({LogicalKeyboardKey key, bool primary, bool shift, bool alt});

final _special = {
  LogicalKeyboardKey.tab: 'Tab',
  LogicalKeyboardKey.backspace: '⌫',
  LogicalKeyboardKey.delete: 'Del',
  LogicalKeyboardKey.arrowLeft: '←',
  LogicalKeyboardKey.arrowRight: '→',
  LogicalKeyboardKey.arrowUp: '↑',
  LogicalKeyboardKey.arrowDown: '↓',
};

bool _supported(LogicalKeyboardKey key) =>
    _special.containsKey(key) ||
    key.keyId >= LogicalKeyboardKey.f1.keyId &&
        key.keyId <= LogicalKeyboardKey.f12.keyId ||
    key.keyId >= 0x21 && key.keyId <= 0x7e;

Chord? chordFor(KeyEvent event) {
  var key = event.logicalKey;
  final letter =
      event.physicalKey.usbHidUsage - PhysicalKeyboardKey.keyA.usbHidUsage;
  if (letter >= 0 && letter < 26) {
    key = LogicalKeyboardKey(LogicalKeyboardKey.keyA.keyId + letter);
  }
  if (!_supported(key)) return null;
  final kb = HardwareKeyboard.instance;
  return (
    key: key,
    primary: kb.isMetaPressed || kb.isControlPressed,
    shift: kb.isShiftPressed,
    alt: kb.isAltPressed,
  );
}

extension ChordLabel on Chord {
  String get label {
    final mac = defaultTargetPlatform == TargetPlatform.macOS;
    return [
      if (shift) mac ? '⇧' : 'Shift',
      if (alt) mac ? '⌥' : 'Alt',
      if (primary) mac ? '⌘' : 'Ctrl',
      _special[key] ?? key.keyLabel.toUpperCase(),
    ].join(mac ? '' : '+');
  }

  bool get reserved =>
      primary &&
      {
        LogicalKeyboardKey.keyQ,
        LogicalKeyboardKey.keyW,
        LogicalKeyboardKey.keyH,
        LogicalKeyboardKey.keyM,
        LogicalKeyboardKey.keyX,
        LogicalKeyboardKey.keyC,
        LogicalKeyboardKey.keyV,
        LogicalKeyboardKey.tab,
        LogicalKeyboardKey.backspace,
        LogicalKeyboardKey.delete,
      }.contains(key);
}

class EditorHotkeys {
  EditorHotkeys([Map<Command, Chord> changes = const {}])
    : _changes = Map.unmodifiable(changes);
  final Map<Command, Chord> _changes;
  bool get customized => _changes.isNotEmpty;
  Chord operator [](Command command) => _changes[command] ?? command.standard;

  Command? commandFor(Chord chord) {
    for (final command in Command.values) {
      if (this[command] == chord ||
          (!_changes.containsKey(command) &&
              command.alias == chord.key &&
              !chord.primary &&
              !chord.alt &&
              !chord.shift)) {
        return command;
      }
    }
    return null;
  }

  EditorHotkeys assign(Command command, Chord chord) {
    final next = {..._changes, command: chord};
    if (chord == command.standard) next.remove(command);
    return EditorHotkeys(next);
  }

  String? conflict(Command command, Chord chord) {
    if (chord.reserved) return 'Это системное сочетание. Выберите другое.';
    final keys = [
      chord,
      if (chord == command.standard && command.alias != null)
        (key: command.alias!, primary: false, shift: false, alt: false),
    ];
    for (final key in keys) {
      final other = commandFor(key);
      if (other != null && other != command) {
        return 'Уже назначено для «${other.label}»';
      }
    }
    return null;
  }

  String encode() => jsonEncode({
    for (final entry in _changes.entries)
      entry.key.name: [
        entry.value.key.keyId,
        entry.value.primary,
        entry.value.shift,
        entry.value.alt,
      ],
  });

  factory EditorHotkeys.decode(String source) {
    try {
      final data = jsonDecode(source) as Map;
      final map = <Command, Chord>{};
      for (final command in Command.values) {
        if (data[command.name] case [
          int id,
          bool primary,
          bool shift,
          bool alt,
        ]) {
          final chord = (
            key: LogicalKeyboardKey(id),
            primary: primary,
            shift: shift,
            alt: alt,
          );
          if (_supported(chord.key) &&
              !chord.reserved &&
              chord != command.standard) {
            map[command] = chord;
          }
        }
      }
      final result = EditorHotkeys(map);
      for (final command in Command.values) {
        if (result.commandFor(result[command]) != command ||
            result.conflict(command, result[command]) != null) {
          return EditorHotkeys();
        }
      }
      return result;
    } on FormatException {
      return EditorHotkeys();
    } on TypeError {
      return EditorHotkeys();
    }
  }
}
