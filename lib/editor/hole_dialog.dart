import 'dart:math' as math;

import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoIcons;
import 'package:flutter/foundation.dart'
    show listEquals, mapEquals, precisionErrorTolerance;
import 'package:flutter/gestures.dart'
    show
        DragStartBehavior,
        GestureBinding,
        PointerDeviceKind,
        PointerScrollEvent,
        kSecondaryMouseButton,
        kMiddleMouseButton;
import 'package:flutter/services.dart'
    show HardwareKeyboard, KeyEvent, KeyDownEvent, LogicalKeyboardKey;
import 'package:material_ui/material_ui.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart'
    show PhosphorIconsRegular;

import '../l10n/strings.dart';
import 'controls.dart';
import 'controller.dart';
import 'desk_text_field.dart';
import 'step.dart';
import 'drawing.dart';
import 'grid_plane_icon.dart';
import 'hotkeys.dart';
import 'viewport_footer.dart';
import 'view_cube.dart';
import 'scene.dart';
import 'desktop.dart';
import 'model.dart';
import 'palette.dart';
import 'platform_ui.dart';

part 'edge_boring_dialog.dart';
part 'hole_projection.dart';
part 'edge_hole_editor.dart';
part 'drill_view.dart';
part 'hole_navigation.dart';
part 'hole_history.dart';
part 'drill_settings.dart';

typedef _HoleEdits = ({
  List<PanelHole> faces,
  List<EdgeHole> edges,
  DrillGroups groups,
});

Future<void> showPanelHoles(
  BuildContext context,
  Editor editor,
  Beam part,
) async {
  final holes = await showDeskDialog<_HoleEdits>(
    context: context,
    builder: (_) => _HoleDialog(part, editor),
  );
  if (holes != null &&
      context.mounted &&
      identical(editor.project.byId[part.id], part) &&
      (!listEquals(holes.faces, part.holes) ||
          !listEquals(holes.edges, part.edgeHoles) ||
          !mapEquals(holes.groups.members, part.drillGroups.members))) {
    editor.commit(
      editor.project.edit(
        {part.id},
        (b) => b.copy(
          holes: holes.faces,
          edgeHoles: holes.edges,
          drillGroups: holes.groups,
        ),
      ),
    );
  }
}

class _HoleDepth extends LengthEditingController {
  _HoleDepth(super.input, super.value, this.thickness);
  final double thickness;
  bool get blind => text.trim().isNotEmpty;
  bool finish() => _finishHoleDepth(this, thickness);
}

bool _finishHoleDepth(LengthEditingController field, double span) {
  final z = field.millimeters;
  if (field.text.isEmpty || (z != null && z > 0 && z < span)) return false;
  field.setMillimeters(null);
  return true;
}

Widget _depthField(_HoleDepth depth, String key, VoidCallback changed) =>
    Builder(
      builder: (context) => DraftLengthField(
        depth,
        changed,
        key: ValueKey(key),
        placeholder: context.strings.throughHole,
        onBlur: () {
          if (depth.finish()) changed();
        },
      ),
    );

class _HoleDraft {
  _HoleDraft(this.original, LengthInput projectInput, this.size)
    : input = original.boringEdge == null
          ? projectInput
          : (unit: projectInput.unit, increment: null),
      name = original.name,
      datum = original.datum,
      anchorFace = original.anchorFace,
      fromEnd = original.fromEnd,
      fromFar = original.fromFarEdge,
      back = original.back;
  final PanelHole original;
  final Vector3 size;
  late final bolt = _BoltBoreDraft(
    (unit: input.unit, increment: null),
    size.z,
    original.boltBore,
  );
  bool get hasBolt => bolt.enabled;
  double? get sectionDepth => blind ? depth.millimeters : size.z;
  late PanelEdge edge =
      original.boringEdge ??
      PanelEdge.values.reduce(
        (a, b) => a.centerInset(original, size) <= b.centerInset(original, size)
            ? a
            : b,
      );
  bool edgeChosen = false;
  bool keepRim = false;
  double? edgeOffset(double? value) {
    if (value == null) return null;
    final fromMax = edge.alongWidth ? fromEnd : fromFar;
    return edge.atMax == fromMax ? value : edge.width(size) - value;
  }

  LengthEditingController get acrossEdge => edge.alongWidth ? x : y;
  late final hardwareInput = (unit: input.unit, increment: null);
  late final center = LengthEditingController(
    hardwareInput,
    edgeOffset(acrossEdge.millimeters),
  );
  late final rim = LengthEditingController(
    hardwareInput,
    (center.millimeters ?? 0) - original.diameter / 2,
  );

  void syncFromPosition() {
    keepRim = false;
    center.setMillimeters(edgeOffset(acrossEdge.millimeters));
    syncRim();
    updatePreview();
  }

  void syncRim() {
    final c = center.millimeters, bit = diameter.millimeters;
    rim.setMillimeters(
      c != null && bit != null && bit > 0 ? c - bit / 2 : null,
    );
  }

  void editOffsets({required bool fromRim}) {
    keepRim = fromRim;
    if (fromRim) {
      final r = rim.millimeters, bit = diameter.millimeters;
      center.setMillimeters(
        r != null && bit != null && bit > 0 ? r + bit / 2 : null,
      );
    } else {
      syncRim();
    }
    acrossEdge.setMillimeters(edgeOffset(center.millimeters));
    updatePreview();
  }

  final LengthInput input;
  String name;
  DrillDatum? datum;
  int? anchorFace;
  Offset get point => Offset(
    fromEnd ? size.x - previewX : previewX,
    fromFar ? size.y - previewY : previewY,
  );

  void moveTo(Offset p) {
    x.setMillimeters(fromEnd ? size.x - p.dx : p.dx);
    y.setMillimeters(fromFar ? size.y - p.dy : p.dy);
    syncFromPosition();
  }

  bool fromEnd, fromFar, back;
  bool get blind => depth.blind;
  late final x = LengthEditingController(input, original.x),
      y = LengthEditingController(input, original.y),
      diameter = LengthEditingController(input, original.diameter),
      depth = _HoleDepth(hardwareInput, original.depth, size.z);
  // Keep a drawable footprint while a field contains an unfinished expression.
  late double previewX = x.millimeters ?? original.x,
      previewY = y.millimeters ?? original.y,
      previewDiameter = original.diameter;

  void updatePreview() {
    previewX = x.millimeters ?? previewX;
    previewY = y.millimeters ?? previewY;
    final value = diameter.millimeters;
    if (value != null && value > 0) previewDiameter = value;
  }

  void setReference({
    required bool end,
    required bool far,
    required Vector3 size,
  }) {
    if (end != fromEnd) {
      final value = x.millimeters;
      previewX = size.x - (value ?? previewX);
      if (value != null) {
        x.setMillimeters(previewX);
      }
      fromEnd = end;
    }
    if (far != fromFar) {
      final value = y.millimeters;
      previewY = size.y - (value ?? previewY);
      if (value != null) {
        y.setMillimeters(previewY);
      }
      fromFar = far;
    }
  }

  PanelHole? get hole {
    final a = x.millimeters,
        b = y.millimeters,
        d = diameter.millimeters,
        z = depth.millimeters;
    if (a == null ||
        b == null ||
        d == null ||
        (blind && z == null) ||
        (hasBolt && bolt.value == null)) {
      return null;
    }
    return PanelHole(
      a,
      b,
      d,
      name: name,
      datum: datum,
      anchorFace: anchorFace,
      boringEdge: original.boringEdge != null || edgeChosen || hasBolt
          ? edge
          : null,
      boltBore: hasBolt ? bolt.value : null,
      depth: blind ? z : null,
      back: (blind || hasBolt || datum != null) && back,
      fromEnd: fromEnd,
      fromFarEdge: fromFar,
    );
  }

  void dispose() {
    bolt.dispose();
    for (final c in [x, y, diameter, depth, center, rim]) {
      c.dispose();
    }
  }
}

enum _HoleMode { faces, spatial }

class _HoleDialog extends StatefulWidget {
  _HoleDialog(this.part, this.editor) : input = editor.lengthInput;
  final Beam part;
  final Editor editor;
  final LengthInput input;
  @override
  State<_HoleDialog> createState() => _HoleDialogState();
}

class _HoleDialogState extends State<_HoleDialog> {
  final past = <_HoleSnapshot>[], future = <_HoleSnapshot>[];
  late _HoleSnapshot lastEdit = _HoleSnapshot(this);
  Object? lastSequence, dragSequence;
  int historyRevision = 0;

  void endSequence() => lastSequence = null;

  void changeWork(VoidCallback change, {Object? sequence, bool field = false}) {
    // Text controllers already contain the new value when onChanged runs.
    final before = field ? lastEdit : _HoleSnapshot(this);
    setState(change);
    final after = lastEdit = _HoleSnapshot(this);
    if (before.sameWork(after)) return;
    if (sequence == null ||
        !identical(sequence, lastSequence) ||
        past.isEmpty) {
      past.add(before);
      if (past.length > 100) past.removeAt(0);
    } else if (past.last.sameWork(after)) {
      past.removeLast();
      sequence = null;
    }
    lastSequence = sequence;
    future.clear();
  }

  void stepHistory({required bool redo}) {
    final from = redo ? future : past;
    if (from.isEmpty) return;
    (redo ? past : future).add(_HoleSnapshot(this));
    final target = from.removeLast();
    final retired = drafts.toList();
    setState(() {
      lastSequence = dragSequence = null;
      dragOffset = guides = null;
      pickingBoringEdge = false;
      nameBeforeEditing = null;
      drafts.clear();
      for (final face in target.faces) {
        drafts.add(
          _HoleDraft(face.original, widget.input, size)..restore(face),
        );
      }
      edges
        ..clear()
        ..addAll(target.edges);
      groups = target.groups;
      datums
        ..clear()
        ..addAll(target.datums);
      if (benchPose != target.pose) drillFace = null;
      benchPose = target.pose;
      edgeSelection = target.edge;
      selected = target.selected;
      extraSelection
        ..clear()
        ..addAll(target.extra);
      viewBack = target.back;
      historyRevision++;
      lastEdit = target;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final draft in retired) {
        draft.dispose();
      }
    });
  }

  late final drafts = [
    for (final h in widget.part.holes) _HoleDraft(h, widget.input, size),
  ];
  final listScroll = ScrollController();
  final nameInput = TextEditingController();
  String? nameBeforeEditing;
  int selected = 0;
  final extraSelection = <HoleRef>{};
  HoleRef? get primaryRow =>
      edgeSelection ?? (current == null ? null : (HoleKind.face, selected));
  bool pickingBoringEdge = false;
  bool showFaceDimensions = false;
  bool faceMagnet = true;
  Offset? dragOffset;
  ({double? x, double? y})? guides;
  bool get pickingAnchor =>
      (HardwareKeyboard.instance.isMetaPressed ||
          HardwareKeyboard.instance.isControlPressed) &&
      !HardwareKeyboard.instance.isShiftPressed;

  bool follows(int index, int ancestor) {
    final seen = <int>{};
    int? next = index;
    while (next != null &&
        next >= 0 &&
        next < drafts.length &&
        seen.add(next)) {
      if (next == ancestor) return true;
      next = drafts[next].anchorFace;
    }
    return false;
  }

  void setCorner(_HoleDraft root, bool end, bool far) {
    final index = drafts.indexOf(root);
    for (final (i, d) in drafts.indexed) {
      if (follows(i, index)) d.setReference(end: end, far: far, size: size);
    }
  }

  DrillDatum? anchorPoint(_HoleDraft d) {
    final index = d.anchorFace;
    if (index != null && index >= 0 && index < drafts.length) {
      final p = drafts[index].point;
      return (u: p.dx, v: p.dy);
    }
    return d.datum;
  }

  void setAnchor(int? host, Offset point, {int? child}) {
    final index = child ?? selected;
    if (index < 0 ||
        index >= drafts.length ||
        (host != null && follows(host, index))) {
      return;
    }
    final d = drafts[index];
    if (host != null) {
      final ref = drafts[host];
      setCorner(d, ref.fromEnd, ref.fromFar);
      point = ref.point;
    }
    d.anchorFace = host;
    d.datum = (u: point.dx, v: point.dy);
    if (!d.blind && !d.hasBolt) d.back = viewBack;
  }

  void removeFaceAnchor(int removed) {
    for (final d in drafts) {
      final ref = d.anchorFace;
      if (ref == removed) {
        d.anchorFace = null;
        d.datum = null;
      } else if (ref != null && ref > removed) {
        d.anchorFace = ref - 1;
      }
    }
  }

  void updatePosition(_HoleDraft d, VoidCallback change) {
    final before = d.point;
    change();
    final delta = d.point - before;
    if (delta == Offset.zero) return;
    final root = drafts.indexOf(d);
    for (final (i, child) in drafts.indexed) {
      if (i != root && follows(i, root)) child.moveTo(child.point + delta);
    }
    for (final child in drafts) {
      final parent = child.anchorFace;
      if (parent != null && parent >= 0 && parent < drafts.length) {
        final point = drafts[parent].point;
        child.datum = (u: point.dx, v: point.dy);
      }
    }
  }

  late final edges = [...widget.part.edgeHoles];
  late DrillGroups groups = widget.part.drillGroups;
  late HoleRef? edgeSelection = drafts.isEmpty && edges.isNotEmpty
      ? (HoleKind.edge, 0)
      : null;
  List<HoleRef> get rows => [
    for (var i = 0; i < drafts.length; i++) (HoleKind.face, i),
    for (var i = 0; i < drafts.length; i++)
      if (drafts[i].hasBolt) (HoleKind.shaft, i),
    for (var i = 0; i < edges.length; i++) (HoleKind.edge, i),
  ];
  _HoleMode mode = _HoleMode.faces;
  int? drillFace;
  Beam? benchPose;
  final datums = <int, Offset>{};
  late final jig = _DrillSettings(
    widget.input.unit,
    widget.editor.connectionRuler,
    datums,
  );
  final faceCamera = Camera()..scale = 1;
  late bool viewBack =
      current != null &&
          (current!.blind || current!.hasBolt || current!.datum != null)
      ? current!.back
      : !upright;
  bool get flipped => viewBack == upright;
  void selectHole(int index, {bool followFace = true}) {
    current?.depth.finish();
    extraSelection.clear();
    nameBeforeEditing = null;
    selected = index;
    edgeSelection = null;
    if (current case final d?
        when followFace && (d.blind || d.hasBolt || d.datum != null)) {
      viewBack = d.back;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || selected < 0 || !listScroll.hasClients) return;
      final position = listScroll.position;
      final top = rowHeight * displayRows.indexOf((HoleKind.face, selected));
      final bottom = top + rowHeight;
      if (top < position.pixels) {
        listScroll.jumpTo(top);
      } else if (bottom > position.pixels + position.viewportDimension) {
        listScroll.jumpTo(
          math.min(
            position.maxScrollExtent,
            bottom - position.viewportDimension,
          ),
        );
      }
    });
  }

  void showFace(bool back) {
    if (viewBack == back) return;
    current?.depth.finish();
    viewBack = back;
    guides = null;
    if (current == null || (current!.blind && current!.back != back)) {
      selectHole(
        drafts.indexWhere((d) => !d.blind || d.back == back),
        followFace: false,
      );
    }
  }

  double get rowHeight => 18 + MediaQuery.textScalerOf(context).scale(14) * 3;

  _HoleDraft? get current =>
      selected < 0 ? null : drafts.elementAtOrNull(selected);
  Vector3 get size => widget.part.size;
  // Show an installed upright in portrait, with its stock length vertical.
  bool get upright =>
      widget.part.along.z.abs() > .01 &&
      widget.part.along.z.abs() > widget.part.across.z.abs();

  @override
  void initState() {
    super.initState();
    lastEdit = _HoleSnapshot(this);
    FocusManager.instance.addListener(endSequence);
    HardwareKeyboard.instance.addHandler(groupShortcut);
  }

  bool groupShortcut(KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.synthesized ||
        ModalRoute.of(context)?.isCurrent != true ||
        FocusManager.instance.primaryFocus?.context
                ?.findAncestorWidgetOfExactType<EditableText>() !=
            null) {
      return false;
    }
    final chord = chordFor(event);
    final command = chord == null
        ? null
        : widget.editor.hotkeys.commandFor(chord);
    if (command == Command.undo || command == Command.redo) {
      stepHistory(redo: command == Command.redo);
      return true;
    }
    if (mode != _HoleMode.faces ||
        (command != Command.group && command != Command.ungroup)) {
      return false;
    }
    final selected = {?primaryRow, ...extraSelection};
    final ungroup = command == Command.ungroup;
    if (ungroup
        ? !selected.any(groups.members.containsKey)
        : selected.length < 2) {
      return false;
    }
    changeWork(() => groupSelection(selected, ungroup: ungroup));
    return true;
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(groupShortcut);
    FocusManager.instance.removeListener(endSequence);
    jig.dispose();
    listScroll.dispose();
    nameInput.dispose();
    for (final draft in drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  void add() {
    final previous = current?.hole;
    final diameter =
        previous?.diameter ?? math.min(5.0, math.min(size.x, size.y) / 2);
    final depth = previous?.depth;
    final back = depth != null && viewBack;
    final lineAlongWidth = size.y > size.x;
    final length = lineAlongWidth ? size.y : size.x;
    final inset = (lineAlongWidth ? size.x : size.y) / 2;
    final occupied = <double>[];
    for (final draft in drafts) {
      final h = draft.hole;
      if (h == null || (depth != null && h.depth != null && h.back != back)) {
        continue;
      }
      final across = lineAlongWidth ? h.centerX(size) : h.centerY(size);
      if ((across - inset).abs() < (h.diameter + diameter) / 2) {
        occupied.add(lineAlongWidth ? h.centerY(size) : h.centerX(size));
      }
    }
    var position = length / 2;
    if (occupied.isNotEmpty) {
      occupied.sort();
      final stops = [0.0, ...occupied, length];
      var largest = 0.0;
      for (var i = 1; i < stops.length; i++) {
        final gap = stops[i] - stops[i - 1];
        if (gap > largest) {
          largest = gap;
          position = (stops[i] + stops[i - 1]) / 2;
        }
      }
    }
    final h = PanelHole(
      widget.input.round(lineAlongWidth ? inset : position),
      widget.input.round(lineAlongWidth ? position : inset),
      diameter,
      depth: depth,
      back: back,
    );
    drafts.add(_HoleDraft(h, widget.input, size));
    selectHole(drafts.length - 1);
  }

  String? fieldError(_HoleDraft d, LengthEditingController field) {
    final value = field.millimeters;
    final s = context.strings;
    String length(double mm) =>
        '${widget.input.unit.format(mm)} ${widget.input.unit.symbol}';
    if (field == d.depth) {
      return value == null || value <= 0 || value >= size.z
          ? s.holeDepthRange(length(size.z))
          : null;
    }
    final maxDiameter = math.min(size.x, size.y);
    if (field == d.diameter) {
      return value == null || value <= 0 || value > maxDiameter
          ? s.holeDiameterRange(length(maxDiameter))
          : null;
    }
    final span = field == d.x ? size.x : size.y;
    final edge = d.edge;
    final alongBolt = d.hasBolt && (field == d.y) == edge.alongWidth;
    final diameter = math.max(
      d.diameter.millimeters ?? 0.0,
      alongBolt ? d.bolt.diameter.millimeters ?? 0.0 : 0.0,
    );
    final radius = diameter > 0 && diameter <= maxDiameter ? diameter / 2 : 0.0;
    return value == null || value < radius || value + radius > span
        ? s.holeOffsetRange(length(radius), length(span - radius))
        : null;
  }

  Widget labeled(String label, Widget child, {String? error}) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    spacing: 5,
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: error == null
                    ? context.colors.muted
                    : context.colors.danger,
              ),
            ),
          ),
          if (error != null)
            Tooltip(
              message: error,
              child: Icon(
                Icons.warning_amber_rounded,
                size: 15,
                color: context.colors.danger,
              ),
            ),
        ],
      ),
      ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 32),
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            border: error == null
                ? null
                : Border.all(color: context.colors.danger),
            borderRadius: BorderRadius.circular(5),
          ),
          child: child,
        ),
      ),
    ],
  );

  Widget number(String label, String key, LengthEditingController controller) =>
      labeled(
        label,
        error: fieldError(current!, controller),
        Semantics(
          label: label,
          child: DraftLengthField(
            controller,
            () => changeWork(
              () => updatePosition(current!, current!.syncFromPosition),
              sequence: controller,
              field: true,
            ),
            key: ValueKey(key),
          ),
        ),
      );

  ({bool right, bool top}) origin(_HoleDraft d, bool mirror) => (
    right: (upright ? d.fromFar : d.fromEnd) != mirror,
    top: upright ? d.fromEnd : d.fromFar,
  );

  Widget offsets(_HoleDraft d) {
    final s = context.strings;
    final corner = origin(d, flipped);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Tooltip(
          message: s.pickHoleAnchor(primaryModifierLabel),
          child: Text(
            s.holeReferenceCorner,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        Row(
          spacing: 10,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _CornerPicker(
              right: corner.right,
              top: corner.top,
              onChanged: (right, top) {
                final horizontalFar = right != flipped;
                changeWork(() {
                  d.anchorFace = null;
                  d.datum = null;
                  setCorner(
                    d,
                    upright ? top : horizontalFar,
                    upright ? horizontalFar : top,
                  );
                });
              },
            ),
            Expanded(
              child: number(
                corner.right ? s.fromRight : s.fromLeft,
                'hole-horizontal',
                upright ? d.y : d.x,
              ),
            ),
            Expanded(
              child: number(
                corner.top ? s.fromTop : s.fromBottom,
                'hole-vertical',
                upright ? d.x : d.y,
              ),
            ),
          ],
        ),
        if (anchorPoint(d) case final datum?)
          Row(
            children: [
              Expanded(
                child: Text(
                  '${d.anchorFace == null ? s.pointAnchor : s.anchoredFaceHole(d.anchorFace! + 1)} · Δ ${widget.input.unit.format(d.point.dx - datum.u)} / ${length(d.point.dy - datum.v)}',
                  style: TextStyle(fontSize: 12, color: context.colors.muted),
                ),
              ),
              DeskIcon(
                Icons.link_off,
                s.detachHoleAnchor,
                () => changeWork(() {
                  d.anchorFace = null;
                  d.datum = null;
                }),
              ),
            ],
          ),
      ],
    );
  }

  Widget diagram(
    double angle,
    Set<int> invalid, {
    ValueChanged<DoorHinge>? pickEdge,
  }) {
    final s = context.strings;
    final part = widget.part;
    final horizontalAxis = upright ? part.across : part.along;
    final verticalAxis = upright ? part.along : part.across;
    final normal = horizontalAxis.cross(verticalAxis);
    final cosine = math.cos(angle), sine = math.sin(angle);
    final right = horizontalAxis * cosine + normal * sine;
    final eye = right.cross(verticalAxis);
    final back = (cosine < 0) == upright;
    final settled = (angle - (flipped ? math.pi : 0)).abs() < 1e-7;
    Widget direction(String label, Vector3 world, int axisIndex) {
      final offset = Offset(world.dot(right), -world.dot(verticalAxis));
      final axial = offset.distance < .08;
      final toward = world.dot(eye) >= 0;
      final color = context.colors.axisColor(axisIndex);
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.rotate(
            angle: axial ? 0 : offset.direction + math.pi / 2,
            child: Icon(
              axial
                  ? (toward ? Icons.adjust : Icons.cancel_outlined)
                  : Icons.arrow_upward,
              size: 14,
              color: color,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            axial
                ? '$label · ${toward ? s.towardViewer : s.awayFromViewer}'
                : label,
            style: TextStyle(fontSize: 11, color: context.colors.muted),
          ),
        ],
      );
    }

    final canvas = LayoutBuilder(
      builder: (context, box) {
        final width = upright ? size.y : size.x,
            height = upright ? size.x : size.y;
        final labelHeight = MediaQuery.textScalerOf(context).scale(12) + 5;
        // Reserve space on both sides so flipping never shifts the board.
        final margin = labelHeight + 12;
        final scale =
            (pickEdge == null ? faceCamera.scale : 1.0) *
            math.min(
              math.max(1.0, box.maxWidth - 2 * margin) /
                  math.sqrt(width * width + size.z * size.z),
              math.max(1.0, box.maxHeight - 2 * margin) / height,
            );
        final rect = Rect.fromCenter(
          center: box.biggest.center(
            pickEdge == null ? faceCamera.pan : Offset.zero,
          ),
          width: width * scale,
          height: height * scale,
        );
        final faceShift = (cosine >= 0 ? 1 : -1) * size.z * scale * sine / 2;
        final faceRect = Rect.fromCenter(
          center: rect.center + Offset(faceShift, 0),
          width: rect.width * cosine.abs(),
          height: rect.height,
        );
        Offset project(Offset p) => Offset(
          faceRect.center.dx +
              ((upright ? p.dy : p.dx) - width / 2) * scale * cosine,
          rect.bottom - (upright ? p.dx : p.dy) * scale,
        );
        Offset center(_HoleDraft d) => project(
          Offset(d.point.dx.clamp(0.0, size.x), d.point.dy.clamp(0.0, size.y)),
        );

        Offset? boltEntry(_HoleDraft draft) {
          if (!draft.hasBolt) return null;
          final edge = draft.edge;
          final c = center(draft);
          if (edge.alongWidth == upright) {
            return Offset(c.dx, edge.atMax ? faceRect.top : faceRect.bottom);
          }
          final right = edge.atMax != (cosine < 0);
          return Offset(right ? faceRect.right : faceRect.left, c.dy);
        }

        final marks = <_HoleMark>[
          for (final (i, d) in drafts.indexed)
            if (!d.blind || d.back == back)
              (
                index: i,
                center: center(d),
                boltEntry: boltEntry(d),
                radius: math.min(
                  d.previewDiameter * scale / 2,
                  box.biggest.shortestSide / 2,
                ),
                selected: i == selected,
                blind: d.blind,
                invalid: invalid.contains(i),
              ),
        ];
        final painter = _HoleDiagram(
          faceRect,
          faceShift * 2,
          cosine.abs(),
          context.colors,
          marks,
        );
        final lines = <_PlanDimension>[];
        final d = current;
        if (pickEdge == null &&
            showFaceDimensions &&
            settled &&
            d != null &&
            (!d.blind || d.back == back) &&
            d.hole?.fits(size) == true) {
          final corner = origin(d, cosine < 0);
          final c = center(d);
          if (anchorPoint(d) case final datum?) {
            final origin = project(Offset(datum.u, datum.v));
            lines.add(
              _PlanDimension(
                true,
                !corner.top,
                origin.dx,
                c,
                ((c.dx - origin.dx) / (scale * cosine)).abs(),
              ),
            );
            lines.add(
              _PlanDimension(
                false,
                corner.right,
                origin.dy,
                c,
                ((c.dy - origin.dy) / scale).abs(),
              ),
            );
          } else {
            lines.add(
              _PlanDimension.offset(
                faceRect,
                c,
                true,
                corner.right,
                upright ? d.previewY : d.previewX,
                after: !corner.top,
              ),
            );
            lines.add(
              _PlanDimension.offset(
                faceRect,
                c,
                false,
                !corner.top,
                upright ? d.previewX : d.previewY,
                after: corner.right,
              ),
            );
          }
        }
        Offset stockAt(Offset at) {
          // Global-to-local pointer conversion can shift an exact centre click
          // by a fraction of a pixel and round a half-step the other way.
          double coordinate(double pixels, double pixelsPerMm, double extent) {
            if (pixels.abs() < precisionErrorTolerance) return extent / 2;
            return (extent / 2 + pixels / pixelsPerMm).clamp(0.0, extent);
          }

          final delta = at - faceRect.center;
          final horizontal = coordinate(delta.dx, scale * cosine, width);
          final vertical = coordinate(-delta.dy, scale, height);
          final x = upright ? vertical : horizontal,
              y = upright ? horizontal : vertical;
          return Offset(x, y);
        }

        void place(Offset at, {bool dragging = false}) {
          if (current == null) add();
          final d = current!;
          final p =
              stockAt(at) +
              (dragging ? dragOffset ?? Offset.zero : Offset.zero);
          double? snapX, snapY;
          if (dragging && faceMagnet) {
            final radius = d.previewDiameter / 2;
            double? snap(double value, double extent, bool horizontal) {
              double? best;
              var distance = 7 / scale;
              void offer(double target) {
                final diff = (target - value).abs();
                if (target >= radius &&
                    target <= extent - radius &&
                    diff < distance) {
                  distance = diff;
                  best = target;
                }
              }

              offer(extent / 2);
              for (final m in marks) {
                if (follows(m.index, selected)) continue;
                final other = drafts[m.index];
                final c = horizontal ? other.point.dx : other.point.dy;
                offer(c);
                offer(extent - c);
                // Equal clearance between the bore rims and opposite stock edges.
                final nearSide = c <= extent / 2;
                final radiusDifference = other.previewDiameter / 2 - radius;
                offer(
                  extent -
                      c +
                      (nearSide ? radiusDifference : -radiusDifference),
                );
              }
              return best;
            }

            snapX = snap(p.dx, size.x, true);
            snapY = snap(p.dy, size.y, false);
            guides = (x: snapX, y: snapY);
          }
          final x =
              snapX ??
              (d.fromEnd
                  ? size.x - widget.input.round(size.x - p.dx)
                  : widget.input.round(p.dx));
          final y =
              snapY ??
              (d.fromFar
                  ? size.y - widget.input.round(size.y - p.dy)
                  : widget.input.round(p.dy));
          updatePosition(d, () => d.moveTo(Offset(x, y)));
        }

        Widget guide(bool vertical, Offset p) => Positioned.fromRect(
          rect: vertical
              ? Rect.fromLTWH(p.dx - .5, faceRect.top, 1, faceRect.height)
              : Rect.fromLTWH(faceRect.left, p.dy - .5, faceRect.width, 1),
          child: IgnorePointer(
            child: ColoredBox(
              key: ValueKey(vertical ? 'snap-guide-v' : 'snap-guide-h'),
              color: context.colors.accent.withValues(alpha: .7),
            ),
          ),
        );

        final drawing = Stack(
          fit: StackFit.expand,
          children: [
            if (pickEdge != null)
              CustomPaint(painter: painter)
            else
              GestureDetector(
                key: const ValueKey('hole-diagram'),
                supportedDevices: const {
                  PointerDeviceKind.mouse,
                  PointerDeviceKind.touch,
                  PointerDeviceKind.stylus,
                  PointerDeviceKind.invertedStylus,
                },
                dragStartBehavior: DragStartBehavior.down,
                onTapUp: (event) {
                  if (!settled) return;
                  final i = painter.holeAt(event.localPosition);
                  if (i == null && !faceRect.contains(event.localPosition)) {
                    return;
                  }
                  changeWork(() {
                    if (pickingAnchor) {
                      setAnchor(i, stockAt(event.localPosition));
                    } else if (i == null) {
                      place(event.localPosition);
                    } else {
                      selectHole(i, followFace: false);
                    }
                  });
                },
                onPanStart: (event) {
                  if (pickingAnchor || !settled) return;
                  final i = painter.holeAt(event.localPosition);
                  dragSequence = Object();
                  dragOffset = i != null
                      ? drafts[i].point - stockAt(event.localPosition)
                      : faceRect.contains(event.localPosition)
                      ? Offset.zero
                      : null;
                  if (i != null) {
                    changeWork(() => selectHole(i, followFace: false));
                  }
                },
                onPanUpdate: (event) {
                  if (dragOffset != null &&
                      !pickingAnchor &&
                      settled &&
                      faceRect.contains(event.localPosition)) {
                    changeWork(
                      () => place(event.localPosition, dragging: true),
                      sequence: dragSequence,
                    );
                  } else if (guides != null) {
                    setState(() => guides = null);
                  }
                },
                onPanEnd: (_) {
                  dragOffset = null;
                  if (guides != null) setState(() => guides = null);
                },
                onPanCancel: () {
                  dragOffset = null;
                  if (guides != null) setState(() => guides = null);
                },
                child: CustomPaint(
                  painter: painter,
                  foregroundPainter: lines.isEmpty
                      ? null
                      : _PlanDimensions(
                          context,
                          faceRect,
                          lines,
                          widget.input.unit,
                        ),
                ),
              ),
            if (pickEdge == null && settled && guides?.x != null)
              guide(!upright, project(Offset(guides!.x!, 0))),
            if (pickEdge == null && settled && guides?.y != null)
              guide(upright, project(Offset(0, guides!.y!))),
            if (pickEdge == null && settled && widget.editor.showHoleNumbers)
              ...holeNumbers(marks, faceRect, box.biggest),
            if (pickEdge != null)
              Positioned(
                left: 4,
                right: 4,
                bottom: box.maxHeight - faceRect.top + 7,
                child: IgnorePointer(
                  child: Center(
                    child: Text(
                      back ? s.faceB : s.faceA,
                      key: const ValueKey('hole-view-face'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.colors.ink,
                      ),
                    ),
                  ),
                ),
              ),
            if (pickEdge != null)
              for (final side in DoorHinge.values)
                _boringEdgeTarget(faceRect, side, pickEdge),
          ],
        );
        if (pickEdge != null) return drawing;
        return _HoleNavigation(
          pan: (delta) => setState(() => faceCamera.pan += delta),
          zoom: (factor, focus) =>
              setState(() => faceCamera.zoom(factor, focus, box.biggest)),
          child: drawing,
        );
      },
    );
    return Column(
      children: [
        Expanded(child: canvas),
        Padding(
          padding: const EdgeInsets.only(bottom: 5),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            children: [
              direction(s.up, axis(2), 2),
              direction(s.forwardDirection, -axis(1), 1),
            ],
          ),
        ),
      ],
    );
  }

  Iterable<Widget> holeNumbers(
    List<_HoleMark> marks,
    Rect face,
    Size viewport,
  ) sync* {
    const fontSize = 10.0;
    final scaledFont = MediaQuery.textScalerOf(context).scale(fontSize);
    final occupied = [
      for (final m in marks)
        Rect.fromCircle(center: m.center, radius: math.max(6.0, m.radius)),
    ];
    for (final mark in marks) {
      if (!(Offset.zero & viewport).contains(mark.center)) continue;
      final number = '${mark.index + 1}';
      final height = scaledFont + 3;
      final width = math.max(height, number.length * scaledFont * .7 + 4);
      final gap = math.max(6.0, mark.radius) + 1;
      // Prefer a free spot on the panel, close to the hole. Near an edge or
      // in a row of closely spaced holes, try the other sides first.
      late Rect label;
      var bestScore = double.infinity;
      for (final side in const [
        Alignment.centerRight,
        Alignment.centerLeft,
        Alignment.topCenter,
        Alignment.bottomCenter,
        Alignment.topRight,
        Alignment.bottomLeft,
        Alignment.topLeft,
        Alignment.bottomRight,
      ]) {
        final x = mark.center.dx + side.x * (gap + width / 2) - width / 2;
        final y = mark.center.dy + side.y * (gap + height / 2) - height / 2;
        final candidate = Rect.fromLTWH(
          x.clamp(0.0, math.max(0.0, viewport.width - width)),
          y.clamp(0.0, math.max(0.0, viewport.height - height)),
          width,
          height,
        );
        var score = face.intersect(candidate) == candidate ? 0.0 : 1.0;
        for (final obstacle in occupied) {
          final overlap = candidate.intersect(obstacle);
          if (!overlap.isEmpty) score += overlap.width * overlap.height;
        }
        if (score < bestScore) {
          bestScore = score;
          label = candidate;
          if (score == 0) break;
        }
      }
      occupied.add(label.inflate(1));
      yield Positioned.fromRect(
        rect: label,
        child: Semantics(
          selected: mark.selected,
          child: DeskControl(
            key: ValueKey('hole-number-${mark.index + 1}'),
            outlined: true,
            borderRadius: BorderRadius.circular(3),
            background: mark.selected
                ? EditorPalette.highlight
                : context.colors.field,
            onPressed: () => changeWork(
              () => pickingAnchor
                  ? setAnchor(mark.index, drafts[mark.index].point)
                  : selectHole(mark.index, followFace: false),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                number,
                maxLines: 1,
                semanticsLabel: context.strings.holeSelection(
                  mark.index + 1,
                  drafts.length,
                ),
                style: TextStyle(
                  fontSize: fontSize,
                  height: 1,
                  fontWeight: FontWeight.w600,
                  color: mark.selected
                      ? EditorPalette.onHighlight
                      : context.colors.ink,
                ),
              ),
            ),
          ),
        ),
      );
    }
  }

  Widget preview(double height, Set<int> invalid) {
    final s = context.strings;
    void toggleNumbers(bool value) =>
        setState(() => widget.editor.showHoleNumbers = value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        Container(
          height: height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: context.colors.paper,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.colors.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 5, 8, 0),
                child: Row(
                  spacing: 2,
                  children: [
                    DeskSegmentedControl<bool>(
                      key: const ValueKey('hole-view-face'),
                      value: viewBack,
                      children: {
                        for (final back in [false, true])
                          back: Tooltip(
                            message: _drillSideLabel(widget.part, back ? 5 : 4),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              child: Text(
                                back ? s.faceMarkB : s.faceMarkA,
                                key: ValueKey('hole-view-${back ? 'b' : 'a'}'),
                              ),
                            ),
                          ),
                      },
                      change: (back) => changeWork(() => showFace(back)),
                    ),
                    const Spacer(),
                    DeskIcon(
                      PhosphorIconsRegular.magnet,
                      s.faceMagnet,
                      () => setState(() => faceMagnet = !faceMagnet),
                      key: const ValueKey('face-magnet'),
                      active: faceMagnet,
                    ),
                    DeskIcon(
                      Icons.straighten,
                      showFaceDimensions ? s.hideDimensions : s.showDimensions,
                      () => setState(
                        () => showFaceDimensions = !showFaceDimensions,
                      ),
                      active: showFaceDimensions,
                    ),
                    DeskIcon(
                      Icons.tag,
                      s.showHoleNumbers,
                      () => toggleNumbers(!widget.editor.showHoleNumbers),
                      key: const ValueKey('hole-show-numbers'),
                      active: widget.editor.showHoleNumbers,
                    ),
                    DeskIcon(
                      Icons.fit_screen_outlined,
                      s.fitToWindow,
                      () => setState(() {
                        faceCamera.scale = 1;
                        faceCamera.pan = Offset.zero;
                      }),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: MediaQuery.disableAnimationsOf(context)
                    ? diagram(flipped ? math.pi : 0, invalid)
                    : TweenAnimationBuilder<double>(
                        tween: Tween(end: flipped ? math.pi : 0.0),
                        duration: const Duration(milliseconds: 320),
                        curve: Curves.easeInOut,
                        builder: (_, angle, _) => diagram(angle, invalid),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void startRename(_HoleDraft draft) {
    nameInput.value = TextEditingValue(
      text: draft.name,
      selection: TextSelection(baseOffset: 0, extentOffset: draft.name.length),
    );
    setState(() => nameBeforeEditing = draft.name);
  }

  Widget inlineName(_HoleDraft draft) => Focus(
    canRequestFocus: false,
    onFocusChange: (focused) {
      if (!focused &&
          mounted &&
          current == draft &&
          nameBeforeEditing != null) {
        setState(() => nameBeforeEditing = null);
      }
    },
    child: CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () => changeWork(() {
          draft.name = nameBeforeEditing!;
          nameBeforeEditing = null;
        }, sequence: nameInput),
      },
      child: Semantics(
        key: const ValueKey('hole-name'),
        label: context.strings.holeName,
        child: DeskTextField(
          controller: nameInput,
          autofocus: true,
          onChanged: (value) => changeWork(
            () => draft.name = value.trim(),
            field: true,
            sequence: nameInput,
          ),
          onSubmitted: (_) => setState(() => nameBeforeEditing = null),
        ),
      ),
    ),
  );

  List<HoleRef> get displayRows {
    final all = rows, byGroup = <int, List<HoleRef>>{};
    for (final ref in all) {
      if (groups.members[ref] case final id?) (byGroup[id] ??= []).add(ref);
    }
    return [
      for (final ref in all)
        if (groups.members[ref] case final id?) ...?byGroup.remove(id) else ref,
    ];
  }

  PanelEdge edgeFor(HoleRef ref) =>
      ref.$1 == HoleKind.edge ? edges[ref.$2].edge : drafts[ref.$2].edge;
  String length(double value) =>
      '${widget.input.unit.format(value)} ${widget.input.unit.symbol}';
  String refLabel(HoleRef ref) {
    if (ref.$1 == HoleKind.edge) return edges[ref.$2].kind.label;
    final d = drafts[ref.$2];
    if (ref.$1 == HoleKind.shaft) return context.strings.boltBoreOption;
    return d.name.isEmpty ? 'Ø${length(d.previewDiameter)}' : d.name;
  }

  void selectRow(HoleRef ref, {bool toggle = false}) {
    if (toggle && primaryRow != null) {
      if (ref != primaryRow) {
        if (!extraSelection.remove(ref)) extraSelection.add(ref);
        return;
      }
      if (extraSelection.isEmpty) return;
      final remaining = extraSelection.toList();
      selectRow(remaining.first);
      extraSelection.addAll(remaining.skip(1));
      return;
    }
    if (ref.$1 == HoleKind.face) {
      selectHole(ref.$2);
    } else {
      selectEdgeHole(ref);
    }
  }

  void showShaft(int index) {
    final d = drafts[index];
    if (!d.hasBolt) {
      d.bolt.enabled = true;
      if (!d.blind) d.back = viewBack;
      groups = groups.assign([
        (HoleKind.face, index),
        (HoleKind.shaft, index),
      ], join: groups.members[(HoleKind.face, index)]);
    }
    selectEdgeHole((HoleKind.shaft, index));
  }

  void groupSelection(Set<HoleRef> selection, {bool ungroup = false}) {
    final members = ungroup && selection.length == 1
        ? groups.members.keys.where(
            (ref) => groups.members[ref] == groups.members[selection.single],
          )
        : selection;
    groups = groups.assign(members, ungroup: ungroup);
  }

  Future<void> rowMenu(HoleRef ref, Offset at, {bool additive = false}) async {
    if (ref != primaryRow && !extraSelection.contains(ref)) {
      changeWork(() => selectRow(ref, toggle: additive));
    }
    final first = primaryRow!;
    final selection = {first, ...extraSelection};
    final s = context.strings;
    final menu = <({String label, IconData icon, VoidCallback run})>[
      if (selection.length > 1)
        (
          label: s.groupLabel,
          icon: Icons.workspaces_outline,
          run: () => groupSelection(selection),
        ),
      if (selection.any(groups.members.containsKey))
        (
          label: s.ungroup,
          icon: Icons.workspaces_outline,
          run: () => groupSelection(selection, ungroup: true),
        ),
      if (first.$1 == HoleKind.face &&
          extraSelection.isNotEmpty &&
          extraSelection.every(
            (r) => r.$1 == HoleKind.face && !follows(first.$2, r.$2),
          ))
        (
          label: s.linkToHole(first.$2 + 1),
          icon: Icons.link,
          run: () {
            for (final item in extraSelection) {
              setAnchor(first.$2, drafts[first.$2].point, child: item.$2);
            }
          },
        ),
      if (selection.length == 1 && ref.$1 == HoleKind.face) ...[
        (
          label: drafts[ref.$2].hasBolt ? s.boltBoreOption : s.addLinkedShaft,
          icon: Icons.link,
          run: () => showShaft(ref.$2),
        ),
        if (drafts[ref.$2].datum != null)
          (
            label: s.detachHoleAnchor,
            icon: Icons.link_off,
            run: () {
              drafts[ref.$2].anchorFace = null;
              drafts[ref.$2].datum = null;
            },
          ),
      ],
      if (selection.length == 1 && ref.$1 == HoleKind.shaft)
        (
          label: s.linkedFaceHole(ref.$2 + 1),
          icon: Icons.link,
          run: () => selectHole(ref.$2),
        ),
      if (selection.length == 1)
        (
          label: s.delete,
          icon: CupertinoIcons.trash,
          run: () => deleteRow(ref),
        ),
    ];
    final index = await showDeskPopup(
      context,
      at,
      title: s.panelHoles,
      rows: [
        for (final item in menu)
          DeskPopupRow(
            item.label,
            icon: item.icon,
            keyHint: item.label == s.groupLabel
                ? widget.editor.hotkeys[Command.group].label
                : item.label == s.ungroup
                ? widget.editor.hotkeys[Command.ungroup].label
                : '',
          ),
      ],
    );
    if (mounted && index != null) changeWork(menu[index].run);
  }

  void deleteRow(HoleRef ref) {
    if (ref.$1 != HoleKind.face) {
      removeEdgeHole(ref);
      return;
    }
    final i = ref.$2;
    groups = groups.remove(ref);
    removeFaceAnchor(i);
    drafts.removeAt(i).dispose();
    if (drafts.isEmpty && edges.isNotEmpty) {
      selectEdgeHole((HoleKind.edge, 0));
    } else {
      selectHole(math.min(i, drafts.length - 1));
    }
  }

  void selectEdgeHole(HoleRef ref) {
    current?.depth.finish();
    extraSelection.clear();
    edgeSelection = ref;
    nameBeforeEditing = null;
  }

  Future<void> editStandalone(PanelEdge side, [int? index]) async {
    final part = widget.part.copy(
      holes: [for (final d in drafts) ?d.hole],
      edgeHoles: [
        for (final (i, h) in edges.indexed)
          if (i != index) h,
      ],
    );
    final result = await showDeskDialog<EdgeHole>(
      context: context,
      builder: (_) => _EditEdgeHole(
        part,
        widget.input.unit,
        index != null
            ? edges[index]
            : (
                edge: side,
                kind: EdgeHoleKind.plain,
                datum: null,
                fromEnd: false,
                back: false,
                offset: side.length(size) / 2,
                height: size.z / 2,
                diameter: math.min(8.0, size.z / 2),
                depth: math.min(20.0, side.width(size) / 2),
              ),
      ),
    );
    if (!mounted || result == null) return;
    changeWork(() {
      if (index == null) {
        edges.add(result);
      } else {
        edges[index] = result;
      }
      selectEdgeHole((HoleKind.edge, index ?? edges.length - 1));
    });
  }

  void removeEdgeHole(HoleRef ref) {
    groups = groups.remove(ref);
    if (ref.$1 == HoleKind.shaft) {
      drafts[ref.$2].bolt.enabled = false;
      selectHole(ref.$2);
    } else {
      edges.removeAt(ref.$2);
      if (edges.isNotEmpty) {
        selectEdgeHole((HoleKind.edge, math.min(ref.$2, edges.length - 1)));
      } else {
        selectHole(drafts.isEmpty ? -1 : 0);
      }
    }
  }

  ({
    double along,
    double z,
    double diameter,
    double? depth,
    bool far,
    Offset zero,
  })
  edgeGeometry(HoleRef ref) {
    final side = edgeFor(ref);
    if (ref.$1 == HoleKind.edge) {
      final h = edges[ref.$2];
      return (
        along: h.position(size),
        z: h.kind == EdgeHoleKind.pocket && h.back
            ? size.z - h.height
            : h.height,
        diameter: h.diameter,
        depth: h.depth,
        far: h.fromEnd,
        zero: h.datum == null
            ? Offset(h.fromEnd ? side.length(size) : 0, h.back ? size.z : 0)
            : Offset(h.datum!.u, h.datum!.v),
      );
    }
    final d = drafts[ref.$2], far = side.alongWidth ? d.fromFar : d.fromEnd;
    final raw = side.alongWidth ? d.previewY : d.previewX;
    final z = d.bolt.offset.millimeters ?? size.z / 2;
    return (
      along: far ? side.length(size) - raw : raw,
      z: d.back ? size.z - z : z,
      diameter: d.bolt.diameter.millimeters ?? 0,
      depth: d.center.millimeters,
      far: far,
      zero: Offset(far ? side.length(size) : 0, d.back ? size.z : 0),
    );
  }

  Widget edgePreview(HoleRef ref, double height) {
    final side = edgeFor(ref), span = side.length(size), g = edgeGeometry(ref);
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: context.colors.paper,
        border: Border.all(color: context.colors.line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Text('2D · ${_drillSideLabel(widget.part, side.faceIndex)}'),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (ctx, box) {
                final scale = math.min(
                  (box.maxWidth - 40).clamp(1, double.infinity) / span,
                  (box.maxHeight - 60).clamp(1, double.infinity) / size.z,
                );
                final face = Rect.fromCenter(
                  center: box.biggest.center(Offset.zero),
                  width: span * scale,
                  height: size.z * scale,
                );
                Offset pos(double u, double v) =>
                    Offset(face.left + u * scale, face.bottom - v * scale);
                final visible = rows
                    .where(
                      (r) =>
                          r.$1 != HoleKind.face &&
                          (edgeFor(r) == side ||
                              (r.$1 == HoleKind.edge &&
                                  edges[r.$2].kind != EdgeHoleKind.pocket &&
                                  edges[r.$2].depth == null &&
                                  edgeFor(r).alongWidth == side.alongWidth)),
                    )
                    .toList();
                final marks = <_HoleMark>[
                  for (final (i, r) in visible.indexed)
                    (
                      index: i,
                      center: pos(edgeGeometry(r).along, edgeGeometry(r).z),
                      boltEntry: null,
                      radius: edgeGeometry(r).diameter * scale / 2,
                      selected: r == ref,
                      blind: edgeGeometry(r).depth != null,
                      invalid: false,
                    ),
                ];
                final painter = _HoleDiagram(face, 0, 1, context.colors, marks);
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (e) {
                        if (painter.holeAt(e.localPosition) case final i?) {
                          changeWork(() => selectEdgeHole(visible[i]));
                        }
                      },
                      child: CustomPaint(painter: painter),
                    ),
                    _DatumMarker(pos(g.zero.dx, g.zero.dy), box.biggest),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget edgeInspector(HoleRef ref) {
    final s = context.strings, g = edgeGeometry(ref), side = edgeFor(ref);
    final at = g.far ? side.length(size) - g.along : g.along;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: [
        Text(
          refLabel(ref),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        Text(
          '${_drillSideLabel(widget.part, side.faceIndex)} · ${s.offset} ${length(at)}',
        ),
        Text(
          '${s.boltBoreDepth} · ${g.depth == null ? s.throughHole : length(g.depth!)}',
        ),
        if (ref.$1 == HoleKind.edge) ...[
          Text('Ø${length(g.diameter)} · ${s.boltFaceOffset} ${length(g.z)}'),
          DeskButton(
            onPressed: () => editStandalone(side, ref.$2),
            child: Text(s.edit),
          ),
        ] else ...[
          Row(
            spacing: 8,
            children: [
              Expanded(
                child: labeled(
                  s.holeDiameter,
                  DraftLengthField(
                    drafts[ref.$2].bolt.diameter,
                    () => changeWork(
                      () {},
                      sequence: drafts[ref.$2].bolt.diameter,
                      field: true,
                    ),
                    key: const ValueKey('cup-bolt-diameter'),
                  ),
                ),
              ),
              Expanded(
                child: labeled(
                  '${s.boltFaceOffset} · ${drafts[ref.$2].back ? s.faceB : s.faceA}',
                  DraftLengthField(
                    drafts[ref.$2].bolt.offset,
                    () => changeWork(
                      () {},
                      sequence: drafts[ref.$2].bolt.offset,
                      field: true,
                    ),
                    key: const ValueKey('cup-bolt-offset'),
                  ),
                ),
              ),
            ],
          ),
          if (drafts[ref.$2].bolt.value?.fitsSection(
                size.z,
                drafts[ref.$2].sectionDepth,
              ) !=
              true)
            Text(
              s.boltBoreInvalid,
              style: TextStyle(color: context.colors.danger),
            ),
          DeskButton(
            plain: true,
            icon: const Icon(Icons.link, size: 16),
            label: Text(s.linkedFaceHole(ref.$2 + 1)),
            onPressed: () => changeWork(() => selectHole(ref.$2)),
          ),
        ],
      ],
    );
  }

  Widget holeList(
    Set<int> invalid,
    Set<int> boltCollisions, {
    required bool compact,
  }) {
    final s = context.strings, colors = context.colors;
    final ordered = displayRows, all = rows;
    final detailStyle = TextStyle(
      fontSize: 11,
      height: 1.15,
      color: colors.muted,
    );
    final list = ordered.isEmpty
        ? Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(s.noPanelHoles, textAlign: TextAlign.center),
            ),
          )
        : ListView.builder(
            controller: listScroll,
            padding: EdgeInsets.zero,
            itemExtent: rowHeight,
            itemCount: ordered.length,
            itemBuilder: (context, row) {
              final ref = ordered[row], i = ref.$2, group = groups.members[ref];
              final draft = ref.$1 == HoleKind.face ? drafts[i] : null;
              final active = ref == primaryRow;
              final marked = active || extraSelection.contains(ref);
              final solo = active && extraSelection.isEmpty;
              final editing =
                  solo && draft != null && nameBeforeEditing != null;
              final title = '№ ${all.indexOf(ref) + 1} · ${refLabel(ref)}';
              final String details;
              if (draft != null) {
                final type = draft.blind
                    ? '${s.blindHole} · ${draft.back ? s.faceB : s.faceA}'
                    : s.throughHole;
                final bit = draft.diameter.millimeters;
                details = draft.name.isEmpty && !editing
                    ? type
                    : 'Ø${bit == null ? '—' : length(bit)} · $type';
              } else {
                details =
                    'Ø${length(edgeGeometry(ref).diameter)} · ${_drillSideLabel(widget.part, edgeFor(ref).faceIndex)}';
              }
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 1),
                child: Listener(
                  onPointerDown: (e) {
                    if (e.buttons == kSecondaryMouseButton) {
                      rowMenu(ref, e.position);
                    }
                  },
                  child: GestureDetector(
                    onLongPressStart: (e) =>
                        rowMenu(ref, e.globalPosition, additive: true),
                    child: DeskListRow(
                      key: ValueKey('hole-row-${ref.$1.name}-$i'),
                      selected: marked,
                      onPressed: () => changeWork(
                        () => selectRow(ref, toggle: pickingAnchor),
                      ),
                      padding: const EdgeInsets.fromLTRB(8, 2, 4, 2),
                      builder: (_) => Row(
                        spacing: toolbarGap,
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minHeight: 22,
                                  ),
                                  child: Row(
                                    spacing: 5,
                                    children: [
                                      if (draft != null && invalid.contains(i))
                                        Tooltip(
                                          message: [
                                            for (final field in [
                                              draft.diameter,
                                              draft.x,
                                              draft.y,
                                              if (draft.blind) draft.depth,
                                            ])
                                              ?fieldError(draft, field),
                                            if (draft.hasBolt &&
                                                draft.bolt.value?.fitsSection(
                                                      size.z,
                                                      draft.sectionDepth,
                                                    ) !=
                                                    true)
                                              s.boltBoreInvalid,
                                            if (boltCollisions.contains(i))
                                              s.boreCollision,
                                          ].join('\n'),
                                          child: Icon(
                                            Icons.warning_amber_rounded,
                                            size: 16,
                                            color: colors.danger,
                                          ),
                                        ),
                                      if (editing) ...[
                                        Text('№ ${i + 1}'),
                                        Expanded(child: inlineName(draft)),
                                      ] else ...[
                                        Flexible(
                                          child: Text(
                                            title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        if (solo && draft != null)
                                          SizedBox.square(
                                            dimension: 22,
                                            child: DeskInlineIcon(
                                              icon: PhosphorIconsRegular
                                                  .pencilSimple,
                                              label: s.rename,
                                              onPressed: () =>
                                                  startRename(draft),
                                            ),
                                          ),
                                      ],
                                    ],
                                  ),
                                ),
                                Text(
                                  details,
                                  maxLines: group != null || editing ? 1 : 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: detailStyle,
                                ),
                                if (group != null && !editing)
                                  Text(
                                    s.numberedGroup(group),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: detailStyle,
                                  ),
                              ],
                            ),
                          ),
                          if (solo)
                            DeskIcon(
                              CupertinoIcons.trash,
                              s.delete,
                              () => changeWork(() => deleteRow(ref)),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        Text(
          '${s.panelHoles} (${all.length})',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        if (compact)
          SizedBox(height: rowHeight * ordered.length.clamp(1, 3), child: list)
        else
          Expanded(child: list),
      ],
    );
  }

  Widget _boringEdgeTarget(
    Rect face,
    DoorHinge side,
    ValueChanged<DoorHinge> pick,
  ) {
    final vertical = side.onSide;
    final center = switch (side) {
      DoorHinge.left => face.centerLeft,
      DoorHinge.right => face.centerRight,
      DoorHinge.top => face.topCenter,
      DoorHinge.bottom => face.bottomCenter,
    };
    final extent = math.max(12.0, (vertical ? face.height : face.width) - 22);
    final handle = math.min(40.0, extent);
    return Positioned.fromRect(
      rect: Rect.fromCenter(
        center: center,
        width: vertical ? 24 : extent,
        height: vertical ? extent : 24,
      ),
      child: Tooltip(
        message: _edgeLabel(context, side),
        child: DeskControl(
          key: ValueKey('cup-edge-${side.name}'),
          onPressed: () => pick(side),
          child: Container(
            width: vertical ? 4 : handle,
            height: vertical ? handle : 4,
            decoration: BoxDecoration(
              color: context.colors.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }

  bool get boringBack =>
      widget.part.hinge == null ? viewBack : !widget.part.doorMount.frontAtMax;

  Widget pickBoringEdge() {
    final s = context.strings;
    void cancel() => setState(() => pickingBoringEdge = false);
    return PopScope<_HoleEdits>(
      canPop: false,
      onPopInvokedWithResult: (popped, _) {
        if (!popped) cancel();
      },
      child: DeskDialog(
        maxWidth: 540,
        title: Text(s.chooseBoringEdge),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.part.name),
            SizedBox(
              height: 300,
              child: diagram(
                boringBack == upright ? math.pi : 0,
                const {},
                pickEdge: addBoreRow,
              ),
            ),
          ],
        ),
        actions: [
          DeskButton(plain: true, onPressed: cancel, child: Text(s.cancel)),
        ],
      ),
    );
  }

  PanelEdge stockEdge(DoorHinge side, bool back) {
    final mirrored = back == upright;
    final alongWidth = side.onSide != upright;
    final atMax = side.onSide
        ? (side == DoorHinge.right) != mirrored
        : side == DoorHinge.top;
    return alongWidth
        ? (atMax ? PanelEdge.end : PanelEdge.start)
        : (atMax ? PanelEdge.far : PanelEdge.near);
  }

  Future<void> addBoreRow(DoorHinge side) async {
    final part = widget.part;
    final back = boringBack;
    final mirrored = back == upright;
    final edge = stockEdge(side, back);
    final holes = await showDeskDialog<List<PanelHole>>(
      context: context,
      builder: (_) => _EdgeBoringDialog(
        part: part,
        unit: widget.input.unit,
        side: side,
        edge: edge,
        back: back,
        firstAtMax: side.onSide || mirrored,
        existing: [for (final d in drafts) ?d.hole],
        edgeHoles: edges,
      ),
    );
    if (holes == null || !mounted) return;
    changeWork(() {
      pickingBoringEdge = false;
      final first = drafts.length;
      groups = groups.assign(
        layoutRefs((faces: holes, edges: const []), first, edges.length),
      );
      drafts.addAll(holes.map((h) => _HoleDraft(h, widget.input, size)));
      selectHole(first);
    });
  }

  Widget addButtons() => Wrap(
    spacing: 6,
    runSpacing: 4,
    children: [
      DeskButton(
        onPressed: () => changeWork(add),
        icon: const Icon(Icons.add),
        label: Text(context.strings.addHole),
      ),
      DeskMenu<PanelEdge>(
        title: context.strings.addEdgeBore,
        items: [
          for (final e in PanelEdge.values)
            (e, _drillSideLabel(widget.part, e.faceIndex)),
        ],
        change: (side) => editStandalone(side),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Text(context.strings.addEdgeBore),
        ),
      ),
      DeskButton(
        plain: true,
        onPressed: () => setState(() => pickingBoringEdge = true),
        icon: const Icon(Icons.add),
        label: Text(context.strings.edgeBoringCommand),
      ),
    ],
  );

  Widget properties(_HoleDraft d, {required bool boltCollision}) {
    final s = context.strings;
    Widget field(String key, LengthEditingController c, VoidCallback edit) =>
        DraftLengthField(
          c,
          () => changeWork(
            () => updatePosition(d, edit),
            sequence: c,
            field: true,
          ),
          key: ValueKey(key),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: 12,
      children: [
        _BoringMeasurements(
          unit: d.input.unit,
          diameter: d.diameter.millimeters,
          centerDistance: d.center.millimeters,
          rim: d.rim.millimeters,
          depth: d.depth.millimeters,
          bolt: d.bolt,
          reference: _EdgeReferencePicker(
            selected: DoorHinge.values.firstWhere(
              (side) => stockEdge(side, viewBack) == d.edge,
            ),
            onChanged: (side) => changeWork(() {
              d.edge = stockEdge(side, viewBack);
              d.edgeChosen = true;
              d.syncFromPosition();
            }),
          ),
          diameterField: field(
            'hole-diameter',
            d.diameter,
            () => d.editOffsets(fromRim: d.keepRim),
          ),
          centerField: field(
            'hole-center',
            d.center,
            () => d.editOffsets(fromRim: false),
          ),
          rimField: field(
            'hole-rim',
            d.rim,
            () => d.editOffsets(fromRim: true),
          ),
          depthField: _depthField(
            d.depth,
            'hole-depth',
            () => changeWork(
              () {
                if (identical(d, current) && d.blind) d.back = viewBack;
              },
              sequence: d.depth,
              field: true,
            ),
          ),
          finishDepth: () {
            if (d.depth.finish()) {
              changeWork(() {}, sequence: d.depth, field: true);
            }
          },
          faceField: labeled(
            d.hasBolt && !d.blind ? s.boltReferenceFace : s.drillingFace,
            DeskSegments(d.back, {
              false: s.faceA,
              true: s.faceB,
            }, (v) => changeWork(() => viewBack = d.back = v)),
          ),
          belowDimensions: offsets(d),
          errors: {
            s.holeDiameter: fieldError(d, d.diameter),
            if (d.blind) s.rabbetDepth: fieldError(d, d.depth),
          },
          linkedAction: Align(
            alignment: Alignment.centerLeft,
            child: DeskButton(
              key: const ValueKey('face-linked-shaft'),
              plain: true,
              icon: Icon(d.hasBolt ? Icons.link : Icons.add, size: 16),
              label: Text(d.hasBolt ? s.boltBoreOption : s.addLinkedShaft),
              onPressed: () => changeWork(() => showShaft(drafts.indexOf(d))),
            ),
          ),
          onChanged: () => setState(() {}),
        ),
        if (d.hasBolt &&
            d.bolt.value?.fitsSection(size.z, d.sectionDepth) != true)
          Text(
            s.boltBoreInvalid,
            style: TextStyle(color: context.colors.danger, fontSize: 12),
          ),
        if (boltCollision)
          Text(
            s.boreCollision,
            style: TextStyle(color: context.colors.danger, fontSize: 12),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => Actions(
    actions: {
      DialogHistoryIntent: CallbackAction<DialogHistoryIntent>(
        onInvoke: (intent) {
          if (ModalRoute.of(context)?.isCurrent == true) {
            stepHistory(redo: intent.redo);
          }
          return null;
        },
      ),
    },
    child: FocusScope(
      autofocus: true,
      child: LayoutBuilder(
        builder: (_, constraints) => dialog(constraints.maxWidth),
      ),
    ),
  );

  Widget dialog(double windowWidth) {
    if (pickingBoringEdge) return pickBoringEdge();
    final s = context.strings, unit = widget.input.unit;
    final invalid = {
      for (final (i, d) in drafts.indexed)
        if (d.hole?.fits(size) != true) i,
    };
    final boltCollisions = <int>{};
    if (drafts.any((d) => d.hasBolt)) {
      final drills = [
        for (final d in drafts) d.hole?.drills(size).toList() ?? <PanelDrill>[],
      ];
      for (final (i, group) in drills.indexed) {
        if (group.length < 2 || invalid.contains(i)) continue;
        for (final (j, other) in drills.indexed) {
          if (j != i &&
              !invalid.contains(j) &&
              other.any(group.last.intersects)) {
            boltCollisions.addAll([i, j]);
          }
        }
      }
    }
    if (edges.isNotEmpty) {
      final edgeDrills = edges.expand((h) => h.drills(size)).toList();
      for (final (i, d) in drafts.indexed) {
        if (d.hole
                ?.drills(size)
                .any((drill) => edgeDrills.any(drill.intersects)) ==
            true) {
          boltCollisions.add(i);
        }
      }
    }
    invalid.addAll(boltCollisions);
    final footerAdds = windowWidth >= 680;
    return DeskDialog(
      maxWidth: mode == _HoleMode.faces ? 1240 : 1030,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(s.panelHoles),
          Text(
            '${widget.part.name}  ·  ${[size.x, size.y, size.z].map(widget.input.format).join(' × ')} ${unit.symbol}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.normal,
              color: context.colors.muted,
            ),
          ),
        ],
      ),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: 14,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: DeskSegments(
              mode,
              {_HoleMode.faces: '2D', _HoleMode.spatial: s.drillMode},
              (value) => changeWork(() {
                current?.depth.finish();
                if (mode != value) {
                  drillFace = null;
                  extraSelection.clear();
                }
                mode = value;
              }),
            ),
          ),
          if (mode != _HoleMode.faces)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 10,
              children: [
                _DrillControls(
                  jig,
                  drillFace == null ? double.infinity : size[drillFace! ~/ 2],
                  () => setState(() {}),
                ),
                _DrillView(
                  hotkeys: widget.editor.hotkeys,
                  part: widget.part.copy(
                    origin: benchPose?.origin,
                    along: benchPose?.along,
                    across: benchPose?.across,
                    hidden: false,
                    holes: [for (final d in drafts) ?d.hole],
                    edgeHoles: edges,
                  ),
                  unit: unit,
                  viewBack: viewBack,
                  edge: edgeSelection == null
                      ? current?.edge ?? PanelEdge.near
                      : edgeFor(edgeSelection!),
                  far:
                      edgeSelection?.$1 == HoleKind.edge &&
                      edges[edgeSelection!.$2].fromEnd,
                  jig: jig,
                  selectView: (face) => setState(() => drillFace = face),
                  historyRevision: historyRevision,
                  changeDatum: (change) => changeWork(change),
                  orient: (part, sequence) => changeWork(() {
                    benchPose = part;
                    drillFace = null;
                  }, sequence: sequence),
                  place: (layout) => changeWork(() {
                    edges.addAll(layout.edges);
                    for (final hole in layout.faces) {
                      drafts.add(_HoleDraft(hole, widget.input, size));
                      selectHole(drafts.length - 1);
                    }
                    if (layout.edges.isNotEmpty) {
                      edgeSelection = (HoleKind.edge, edges.length - 1);
                    }
                  }),
                ),
              ],
            )
          else
            LayoutBuilder(
              builder: (context, box) {
                final d = current;
                final wide = box.maxWidth >= 850;
                final listWidth = wide
                    ? (box.maxWidth * .20).clamp(176.0, 224.0)
                    : 178.0;
                final inspectorWidth = (box.maxWidth * .32).clamp(308.0, 390.0);
                const gap = 16.0;
                final previewWidth =
                    box.maxWidth -
                    (footerAdds ? listWidth + gap : 0) -
                    (wide && rows.isNotEmpty ? inspectorWidth + gap : 0);
                final screenHeight =
                    MediaQuery.sizeOf(context).height -
                    MediaQuery.viewInsetsOf(context).vertical;
                final heightLimit = wide
                    ? (screenHeight - 205).clamp(270.0, 780.0)
                    : (screenHeight * .55).clamp(245.0, 510.0);
                final ratio = upright ? size.x / size.y : size.y / size.x;
                // Include the side controls, dimension margins and direction legend.
                final previewHeight = math.min(
                  heightLimit,
                  math.max(255.0, 110 + (previewWidth - 58) * ratio),
                );
                final ref = edgeSelection;
                final partPreview = ref == null
                    ? preview(previewHeight, invalid)
                    : edgePreview(ref, previewHeight);
                final form = ref != null
                    ? edgeInspector(ref)
                    : d == null
                    ? null
                    : properties(
                        d,
                        boltCollision: boltCollisions.contains(selected),
                      );
                if (!footerAdds) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 14,
                    children: [
                      holeList(invalid, boltCollisions, compact: true),
                      addButtons(),
                      partPreview,
                      ?form,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: gap,
                  children: [
                    SizedBox(
                      width: listWidth,
                      height: math.max(342.0, previewHeight),
                      child: holeList(invalid, boltCollisions, compact: false),
                    ),
                    if (wide) ...[
                      Expanded(child: partPreview),
                      if (rows.isNotEmpty)
                        SizedBox(
                          width: inspectorWidth,
                          child: form ?? const SizedBox.shrink(),
                        ),
                    ] else
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: 14,
                          children: [partPreview, ?form],
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
      leadingAction: footerAdds && mode == _HoleMode.faces
          ? addButtons()
          : null,
      actions: [
        DeskButton(
          plain: true,
          onPressed: () => Navigator.pop(context),
          child: Text(s.cancel),
        ),
        DeskButton(
          primary: true,
          onPressed: invalid.isNotEmpty
              ? null
              : () => Navigator.pop(context, (
                  faces: [for (final d in drafts) d.hole!],
                  edges: edges,
                  groups: groups,
                )),
          child: Text(s.apply),
        ),
      ],
    );
  }
}

class _CornerPicker extends StatelessWidget {
  const _CornerPicker({
    required this.right,
    required this.top,
    required this.onChanged,
  });
  final bool right, top;
  final void Function(bool right, bool top) onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors, s = context.strings;
    Widget corner(bool fromRight, bool fromTop) {
      final selected = right == fromRight && top == fromTop;
      final label =
          '${fromRight ? s.fromRight : s.fromLeft} · ${fromTop ? s.fromTop : s.fromBottom}';
      final diameter = selected ? 12.0 : 7.0;
      return Positioned(
        left: fromRight ? 34 : 0,
        top: fromTop ? 0 : 26,
        width: 34,
        height: 26,
        child: Tooltip(
          message: label,
          child: Semantics(
            selected: selected,
            child: DeskControl(
              key: ValueKey('hole-origin-$fromRight-$fromTop'),
              onPressed: () => onChanged(fromRight, fromTop),
              child: Container(
                width: diameter,
                height: diameter,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? EditorPalette.highlight : colors.field,
                  border: Border.all(
                    color: selected ? colors.accent : colors.muted,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return _ReferenceDiagram([
      for (final fromTop in [true, false])
        for (final fromRight in [false, true]) corner(fromRight, fromTop),
    ]);
  }
}

class _EdgeReferencePicker extends StatelessWidget {
  const _EdgeReferencePicker({required this.selected, required this.onChanged});
  final DoorHinge selected;
  final ValueChanged<DoorHinge> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Widget handle(DoorHinge side) {
      final active = side == selected;
      const panel = _ReferenceDiagram.panel;
      final center = switch (side) {
        DoorHinge.left => panel.centerLeft,
        DoorHinge.right => panel.centerRight,
        DoorHinge.top => panel.topCenter,
        DoorHinge.bottom => panel.bottomCenter,
      };
      final label = _edgeLabel(context, side);
      return Positioned.fromRect(
        rect: Rect.fromCenter(
          center: center,
          width: side.onSide ? 22 : 24,
          height: side.onSide ? 24 : 22,
        ),
        child: Tooltip(
          message: label,
          child: Semantics(
            label: label,
            selected: active,
            child: DeskControl(
              key: ValueKey('hole-reference-${side.name}'),
              padding: EdgeInsets.zero,
              onPressed: () => onChanged(side),
              child: Container(
                width: side.onSide ? 6 : 19,
                height: side.onSide ? 16 : 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: active ? EditorPalette.highlight : colors.field,
                  border: Border.all(
                    color: active ? colors.accent : colors.muted,
                    width: active ? 1.5 : 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return _ReferenceDiagram([
      for (final side in DoorHinge.values) handle(side),
    ]);
  }
}

class _ReferenceDiagram extends StatelessWidget {
  const _ReferenceDiagram(this.handles);
  final List<Widget> handles;
  static const panel = Rect.fromLTWH(17, 13, 34, 26);

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 68,
    height: 52,
    child: Stack(
      children: [
        Positioned.fromRect(
          rect: panel,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: context.colors.chrome,
              border: Border.all(color: context.colors.muted),
            ),
          ),
        ),
        ...handles,
      ],
    ),
  );
}

typedef _HoleMark = ({
  int index,
  Offset center,
  Offset? boltEntry,
  double radius,
  bool selected,
  bool blind,
  bool invalid,
});

class _HoleDiagram extends CustomPainter {
  _HoleDiagram(this.rect, this.shift, this.cosine, this.colors, this.marks);
  final double shift, cosine;
  final Rect rect;
  final EditorPalette colors;
  final List<_HoleMark> marks;

  int? holeAt(Offset at) {
    int? nearest;
    var closest = double.infinity;
    for (final mark in marks.reversed) {
      final distance = (mark.center - at).distance;
      if (distance <= math.max(6.0, mark.radius) && distance < closest) {
        nearest = mark.index;
        closest = distance;
      }
    }
    return nearest;
  }

  @override
  bool hitTest(Offset position) =>
      rect.contains(position) || holeAt(position) != null;

  @override
  void paint(Canvas canvas, Size size) {
    if (shift.abs() > .01) {
      final edge = shift > 0 ? rect.left : rect.right;
      canvas.drawRect(
        Rect.fromLTRB(
          math.min(edge, edge - shift),
          rect.top,
          math.max(edge, edge - shift),
          rect.bottom,
        ),
        Paint()..color = colors.muted,
      );
    }
    canvas.drawRect(rect, Paint()..color = colors.chrome);
    final pen = Paint()
      ..style = PaintingStyle.stroke
      ..color = colors.muted;
    canvas.drawRect(rect, pen);
    for (final m in marks) {
      final c = m.center;
      pen.color = m.invalid
          ? colors.danger
          : m.selected
          ? colors.accent
          : colors.muted;
      if (m.boltEntry case final entry?) {
        final length = (c - entry).distance;
        if (length > 0) {
          final direction = (c - entry) / length;
          for (var x = 0.0; x < length; x += 5) {
            canvas.drawLine(
              entry + direction * x,
              entry + direction * math.min(x + 3, length),
              pen,
            );
          }
        }
      }
      final r = math.max(2.0, m.radius);
      final oval = Rect.fromCenter(
        center: c,
        width: 2 * r * cosine,
        height: 2 * r,
      );
      canvas.drawOval(
        oval,
        Paint()
          ..color = m.invalid
              ? colors.danger.withValues(alpha: .14)
              : m.blind && m.selected
              ? EditorPalette.highlight
              : m.blind
              ? colors.muted
              : colors.paper,
      );
      pen.strokeWidth = m.selected ? 2 : 1;
      canvas.drawOval(oval, pen);
      if (m.selected && cosine > .3) {
        canvas.drawCircle(c, 1.5, Paint()..color = pen.color);
      }
      pen.strokeWidth = 1;
    }
  }

  @override
  bool shouldRepaint(_HoleDiagram old) => true;
}
