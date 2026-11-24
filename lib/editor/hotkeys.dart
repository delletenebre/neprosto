import '../l10n/strings.dart';

import 'dart:convert';

import 'platform_ui.dart';

import 'package:flutter/services.dart';

enum Command {
  add(LogicalKeyboardKey.keyW, alias: LogicalKeyboardKey.keyB),
  addWithDimensions(LogicalKeyboardKey.keyW, shift: true),
  select(LogicalKeyboardKey.keyV),
  move(LogicalKeyboardKey.keyM),
  rotate(LogicalKeyboardKey.keyR),
  measure(LogicalKeyboardKey.keyD),
  fit(LogicalKeyboardKey.keyF),
  dimensions(LogicalKeyboardKey.tab),
  undo(LogicalKeyboardKey.keyZ, primary: true),
  redo(LogicalKeyboardKey.keyZ, primary: true, shift: true),
  selectAll(LogicalKeyboardKey.keyA, primary: true),
  hideSelected(LogicalKeyboardKey.keyH),
  duplicate(LogicalKeyboardKey.keyD, primary: true),
  stretchWidth(LogicalKeyboardKey.keyQ),
  stretchHeight(LogicalKeyboardKey.keyQ, primary: true),
  delete(LogicalKeyboardKey.backspace, alias: LogicalKeyboardKey.delete),
  group(LogicalKeyboardKey.keyG, primary: true),
  ungroup(LogicalKeyboardKey.keyG, primary: true, shift: true),
  left(LogicalKeyboardKey.arrowLeft),
  right(LogicalKeyboardKey.arrowRight),
  up(LogicalKeyboardKey.arrowUp),
  down(LogicalKeyboardKey.arrowDown),
  stopLeft(LogicalKeyboardKey.arrowLeft, shift: true),
  stopRight(LogicalKeyboardKey.arrowRight, shift: true),
  stopUp(LogicalKeyboardKey.arrowUp, shift: true),
  stopDown(LogicalKeyboardKey.arrowDown, shift: true),
  newProject(LogicalKeyboardKey.keyN, primary: true),
  open(LogicalKeyboardKey.keyO, primary: true),
  closeTab(LogicalKeyboardKey.keyW, primary: true),
  save(LogicalKeyboardKey.keyS, primary: true),
  saveAs(LogicalKeyboardKey.keyS, primary: true, shift: true),
  settings(LogicalKeyboardKey.comma, primary: true);

  const Command(
    this.key, {
    this.primary = false,
    this.shift = false,
    this.alias,
  });

  final LogicalKeyboardKey key;
  final LogicalKeyboardKey? alias;
  final bool primary, shift;
  Chord get standard => (key: key, primary: primary, shift: shift, alt: false);
  String get label => switch (this) {
    Command.add => editorStrings.newPart,
    Command.addWithDimensions => editorStrings.newPartWithDimensions,
    Command.select => editorStrings.selectParts,
    Command.move => editorStrings.placeAgainstReference,
    Command.rotate => editorStrings.rotatePart,
    Command.measure => editorStrings.measureDistance,
    Command.fit => editorStrings.fitToWindow,
    Command.dimensions => editorStrings.showHideDimensions,
    Command.undo => editorStrings.undoAction,
    Command.redo => editorStrings.redoAction,
    Command.selectAll => editorStrings.selectAllParts,
    Command.hideSelected => editorStrings.hideSelectedParts,
    Command.duplicate => editorStrings.duplicate,
    Command.stretchWidth => editorStrings.stretchToWidth,
    Command.stretchHeight => editorStrings.stretchToHeight,
    Command.delete => editorStrings.delete,
    Command.group => editorStrings.groupLabel,
    Command.ungroup => editorStrings.ungroup,
    Command.left => editorStrings.left,
    Command.right => editorStrings.right,
    Command.up => editorStrings.up,
    Command.down => editorStrings.down,
    Command.stopLeft => editorStrings.leftToNextStop,
    Command.stopRight => editorStrings.rightToNextStop,
    Command.stopUp => editorStrings.upToNextStop,
    Command.stopDown => editorStrings.downToNextStop,
    Command.newProject => editorStrings.newProject,
    Command.open => editorStrings.openProject,
    Command.closeTab => editorStrings.closeTab,
    Command.save => editorStrings.saveProject,
    Command.saveAs => editorStrings.saveAs,
    Command.settings => editorStrings.settings,
  };

  String get category => switch (this) {
    Command.add ||
    Command.addWithDimensions ||
    Command.select ||
    Command.move ||
    Command.rotate ||
    Command.measure => editorStrings.tools,
    Command.fit || Command.dimensions => editorStrings.view,
    Command.undo ||
    Command.redo ||
    Command.selectAll ||
    Command.hideSelected ||
    Command.duplicate ||
    Command.stretchWidth ||
    Command.stretchHeight ||
    Command.delete ||
    Command.group ||
    Command.ungroup => editorStrings.editing,
    Command.left ||
    Command.right ||
    Command.up ||
    Command.down ||
    Command.stopLeft ||
    Command.stopRight ||
    Command.stopUp ||
    Command.stopDown => editorStrings.nudge,
    Command.newProject ||
    Command.open ||
    Command.closeTab ||
    Command.save ||
    Command.saveAs ||
    Command.settings => editorStrings.project,
  };
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
    final mac = appleControls;
    return [
      if (shift) mac ? '⇧' : 'Shift',
      if (alt) mac ? '⌥' : 'Alt',
      if (primary) primaryModifierLabel,
      if (!mac && key == LogicalKeyboardKey.backspace)
        'Backspace'
      else
        _special[key] ?? key.keyLabel.toUpperCase(),
    ].join(mac ? '' : '+');
  }

  bool get reserved =>
      primary &&
      this != Command.stretchHeight.standard &&
      {
        LogicalKeyboardKey.keyQ,
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
    for (final entry in _changes.entries) {
      if (entry.value == chord) return entry.key;
    }
    for (final command in Command.values) {
      if (_changes.containsKey(command)) continue;
      if (command.standard == chord ||
          (command.alias == chord.key &&
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
    if (chord.reserved) return editorStrings.reservedShortcut;
    final keys = [
      chord,
      if (chord == command.standard && command.alias != null)
        (key: command.alias!, primary: false, shift: false, alt: false),
    ];
    for (final key in keys) {
      final other = commandFor(key);
      if (other != null && other != command) {
        return editorStrings.alreadyAssignedTo(other.label);
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
        // A saved shortcut can predate a newly introduced default.
        if (!map.containsKey(command) && map.containsValue(command.standard)) {
          continue;
        }
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
