import 'dart:math' as math;

import 'package:flutter/foundation.dart'
    show listEquals, precisionErrorTolerance;
import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:material_ui/material_ui.dart';

import '../l10n/strings.dart';
import 'controls.dart';
import 'controller.dart';
import 'desk_text_field.dart';
import 'step.dart';
import 'desktop.dart';
import 'model.dart';
import 'palette.dart';

Future<void> showPanelHoles(
  BuildContext context,
  Editor editor,
  Beam part,
) async {
  final holes = await showDeskDialog<List<PanelHole>>(
    context: context,
    builder: (_) => _HoleDialog(part, editor),
  );
  if (holes != null &&
      context.mounted &&
      identical(editor.project.byId[part.id], part) &&
      !listEquals(holes, part.holes)) {
    editor.commit(editor.project.edit({part.id}, (b) => b.copy(holes: holes)));
  }
}

class _HoleDraft {
  _HoleDraft(this.original, this.input)
    : name = original.name,
      fromEnd = original.fromEnd,
      fromFar = original.fromFarEdge,
      blind = original.depth != null,
      back = original.back;
  final PanelHole original;
  final LengthInput input;
  String name;
  bool fromEnd, fromFar, blind, back;
  late final x = LengthEditingController(input, original.x),
      y = LengthEditingController(input, original.y),
      diameter = LengthEditingController(input, original.diameter),
      depth = LengthEditingController(input, original.depth ?? 12);
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
    if (a == null || b == null || d == null || (blind && z == null)) {
      return null;
    }
    return PanelHole(
      a,
      b,
      d,
      name: name,
      depth: blind ? z : null,
      back: blind && back,
      fromEnd: fromEnd,
      fromFarEdge: fromFar,
    );
  }

  void dispose() {
    for (final c in [x, y, diameter, depth]) {
      c.dispose();
    }
  }
}

class _HoleDialog extends StatefulWidget {
  _HoleDialog(this.part, this.editor) : input = editor.lengthInput;
  final Beam part;
  final Editor editor;
  final LengthInput input;
  @override
  State<_HoleDialog> createState() => _HoleDialogState();
}

class _HoleDialogState extends State<_HoleDialog> {
  late final drafts = [
    for (final h in widget.part.holes) _HoleDraft(h, widget.input),
  ];
  final listScroll = ScrollController();
  int selected = 0;
  late bool viewBack = current?.blind == true ? current!.back : !upright;
  bool get flipped => viewBack == upright;
  void selectHole(int index) {
    selected = index;
    if (current?.blind == true) viewBack = current!.back;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !listScroll.hasClients) return;
      final position = listScroll.position;
      final top = rowHeight * selected;
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

  double get rowHeight => 14 + MediaQuery.textScalerOf(context).scale(14) * 3;

  _HoleDraft? get current => drafts.elementAtOrNull(selected);
  Vector3 get size => widget.part.size;
  // Show an installed upright in portrait, with its stock length vertical.
  bool get upright =>
      widget.part.along.z.abs() > .01 &&
      widget.part.along.z.abs() > widget.part.across.z.abs();

  @override
  void dispose() {
    listScroll.dispose();
    for (final draft in drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  void add({bool cup = false}) {
    final part = widget.part;
    final previous = current?.hole;
    final diameter = cup
        ? 35.0
        : previous?.diameter ?? math.min(5.0, math.min(size.x, size.y) / 2);
    final depth = cup ? 12.0 : previous?.depth;
    final back =
        depth != null &&
        (cup && part.hinge != null
            ? !part.doorMount.frontAtMax
            : cup
            ? true
            : viewBack);
    // Space successive holes along the same drilling line. A hinge cup is
    // inset from the hinged edge, including on lift-up and drop-down fronts.
    final lineAlongWidth = cup && part.hinge != null
        ? part.hingeAcross
        : size.y > size.x;
    final length = lineAlongWidth ? size.y : size.x;
    final width = lineAlongWidth ? size.x : size.y;
    final far = cup && part.hinge != null && part.hingeAtMax;
    final inset = cup ? math.min(22.0, width / 2) : width / 2;
    final line = far ? width - inset : inset;
    final occupied = <double>[];
    for (final draft in drafts) {
      final h = draft.hole;
      if (h == null || (depth != null && h.depth != null && h.back != back)) {
        continue;
      }
      final across = lineAlongWidth ? h.centerX(size) : h.centerY(size);
      if ((across - line).abs() < (h.diameter + diameter) / 2) {
        occupied.add(lineAlongWidth ? h.centerY(size) : h.centerX(size));
      }
    }
    final margin = math.min(100.0, length / 2);
    var position = cup ? margin : length / 2;
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
      if (cup &&
          occupied.length == 1 &&
          (occupied.first - (length - margin)).abs() >= diameter) {
        position = length - margin;
      }
    }
    final h = PanelHole(
      widget.input.round(lineAlongWidth ? inset : position),
      widget.input.round(lineAlongWidth ? position : inset),
      diameter,
      fromEnd: lineAlongWidth && far,
      fromFarEdge: !lineAlongWidth && far,
      depth: depth,
      back: back,
    );
    drafts.add(_HoleDraft(h, widget.input));
    selectHole(drafts.length - 1);
  }

  Widget labeled(String label, Widget child) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    spacing: 5,
    children: [
      Text(label, style: TextStyle(fontSize: 12, color: context.colors.muted)),
      ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 32),
        child: child,
      ),
    ],
  );

  Widget number(String label, String key, LengthEditingController controller) =>
      labeled(
        label,
        Semantics(
          label: label,
          child: DraftLengthField(
            controller,
            () => setState(current!.updatePreview),
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
        Text(
          s.holeReferenceCorner,
          style: const TextStyle(fontWeight: FontWeight.w600),
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
                setState(
                  () => d.setReference(
                    end: upright ? top : horizontalFar,
                    far: upright ? horizontalFar : top,
                    size: size,
                  ),
                );
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
      ],
    );
  }

  Widget diagram(double angle, Set<int> invalid) {
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
    final sideLabels = <Widget>[], bottomLabels = <Widget>[];
    void direction(String label, Vector3 world, int axisIndex) {
      final offset = Offset(world.dot(right), -world.dot(verticalAxis));
      final axial = offset.distance < .08;
      final vertical = !axial && offset.dy.abs() > offset.dx.abs();
      final toward = world.dot(eye) >= 0;
      final color = context.colors.axisColor(axisIndex);
      final indicator = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.rotate(
            angle: axial
                ? 0
                : offset.direction + math.pi / 2 + (vertical ? math.pi / 2 : 0),
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
      if (vertical) {
        sideLabels.add(RotatedBox(quarterTurns: 3, child: indicator));
      } else {
        bottomLabels.add(indicator);
      }
    }

    direction(s.up, axis(2), 2);
    direction(s.forwardDirection, -axis(1), 1);
    return LayoutBuilder(
      builder: (context, box) {
        final width = upright ? size.y : size.x,
            height = upright ? size.x : size.y;
        final labelHeight = MediaQuery.textScalerOf(context).scale(12) + 5;
        // Reserve space on both sides so flipping never shifts the board.
        final marginX = labelHeight + 12;
        final marginY = labelHeight * 2 + 12;
        final scale = math.min(
          math.max(1.0, box.maxWidth - 2 * marginX) /
              math.sqrt(width * width + size.z * size.z),
          math.max(1.0, box.maxHeight - 2 * marginY) / height,
        );
        final rect = Rect.fromCenter(
          center: box.biggest.center(Offset.zero),
          width: width * scale,
          height: height * scale,
        );
        final faceShift = (cosine >= 0 ? 1 : -1) * size.z * scale * sine / 2;
        final faceRect = Rect.fromCenter(
          center: rect.center + Offset(faceShift, 0),
          width: rect.width * cosine.abs(),
          height: rect.height,
        );
        Offset center(_HoleDraft draft) {
          // Pin an off-panel centre to its edge so it can still be picked.
          final x = (draft.fromEnd ? size.x - draft.previewX : draft.previewX)
              .clamp(0.0, size.x);
          final y = (draft.fromFar ? size.y - draft.previewY : draft.previewY)
              .clamp(0.0, size.y);
          return Offset(
            faceRect.center.dx +
                ((upright ? y : x) - width / 2) * scale * cosine,
            rect.bottom - (upright ? x : y) * scale,
          );
        }

        final marks = <_HoleMark>[
          for (final (i, d) in drafts.indexed)
            if (!d.blind || d.back == back)
              (
                index: i,
                center: center(d),
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
          current == null ? null : origin(current!, cosine < 0),
          marks,
        );

        void place(Offset at) {
          if (current == null) add();
          final d = current!;
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
          d.x.setMillimeters(widget.input.round(d.fromEnd ? size.x - x : x));
          d.y.setMillimeters(widget.input.round(d.fromFar ? size.y - y : y));
          d.updatePreview();
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              key: const ValueKey('hole-diagram'),
              dragStartBehavior: DragStartBehavior.down,
              onTapUp: (event) {
                if (!settled) return;
                final i = painter.holeAt(event.localPosition);
                if (i == null && !faceRect.contains(event.localPosition)) {
                  return;
                }
                setState(() {
                  if (i == null) {
                    place(event.localPosition);
                  } else {
                    selectHole(i);
                  }
                });
              },
              onPanStart: (event) {
                if (!settled) return;
                final i = painter.holeAt(event.localPosition);
                if (i != null) setState(() => selectHole(i));
              },
              onPanUpdate: (event) {
                if (settled && faceRect.contains(event.localPosition)) {
                  setState(() => place(event.localPosition));
                }
              },
              child: CustomPaint(painter: painter),
            ),
            if (settled && widget.editor.showHoleNumbers)
              ...holeNumbers(marks, faceRect, box.biggest),
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
            for (final (i, label) in sideLabels.indexed)
              Positioned(
                left: i == 0 ? null : faceRect.right + 5,
                right: i == 0 ? box.maxWidth - faceRect.left + 5 : null,
                top: 4,
                bottom: 4,
                child: IgnorePointer(child: Center(child: label)),
              ),
            Positioned(
              top: faceRect.bottom + 5,
              left: 4,
              right: 4,
              child: IgnorePointer(child: Column(children: bottomLabels)),
            ),
          ],
        );
      },
    );
  }

  Iterable<Widget> holeNumbers(
    List<_HoleMark> marks,
    Rect face,
    Size viewport,
  ) sync* {
    final fontSize = MediaQuery.textScalerOf(context).scale(11);
    final occupied = [
      for (final m in marks)
        Rect.fromCircle(center: m.center, radius: math.max(6.0, m.radius)),
    ];
    for (final mark in marks) {
      final number = '${mark.index + 1}';
      final height = fontSize + 7;
      final width = math.max(height, number.length * fontSize * .75 + 8);
      final gap = math.max(6.0, mark.radius) + 2;
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
      occupied.add(label.inflate(2));
      yield Positioned.fromRect(
        rect: label,
        child: Semantics(
          selected: mark.selected,
          child: DeskControl(
            key: ValueKey('hole-number-${mark.index + 1}'),
            outlined: true,
            background: mark.selected
                ? EditorPalette.highlight
                : context.colors.field,
            onPressed: () => setState(() => selectHole(mark.index)),
            child: Text(
              number,
              semanticsLabel: context.strings.holeSelection(
                mark.index + 1,
                drafts.length,
              ),
              style: TextStyle(
                fontSize: 11,
                height: 1,
                fontWeight: FontWeight.w600,
                color: mark.selected
                    ? EditorPalette.onHighlight
                    : context.colors.ink,
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
                child: MergeSemantics(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => toggleNumbers(!widget.editor.showHoleNumbers),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 6,
                      children: [
                        DeskSwitch(
                          value: widget.editor.showHoleNumbers,
                          onChanged: toggleNumbers,
                        ),
                        Flexible(
                          child: Text(
                            s.showHoleNumbers,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
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
        Text(
          s.holeDiagramHelp,
          style: TextStyle(fontSize: 12, color: context.colors.muted),
        ),
      ],
    );
  }

  Widget holeList(Set<int> invalid, {required bool compact}) {
    final s = context.strings, colors = context.colors;
    final list = Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.field,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.line),
      ),
      child: drafts.isEmpty
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
              itemCount: drafts.length,
              itemBuilder: (context, i) {
                final draft = drafts[i];
                final diameter = draft.diameter.millimeters;
                final dimension = diameter == null
                    ? '—'
                    : '${widget.input.format(diameter)} ${widget.input.unit.symbol}';
                final type = draft.blind
                    ? '${s.blindHole} · ${draft.back ? s.faceB : s.faceA}'
                    : s.throughHole;
                final active = i == selected;
                final title = draft.name.isEmpty ? 'Ø$dimension' : draft.name;
                final details = draft.name.isEmpty
                    ? type
                    : 'Ø$dimension · $type';
                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: active ? context.selectionFill : null,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Semantics(
                          selected: active,
                          child: DeskControl(
                            onPressed: () => setState(() => selectHole(i)),
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    spacing: 5,
                                    children: [
                                      if (invalid.contains(i))
                                        Tooltip(
                                          message: s.invalidHole,
                                          child: Icon(
                                            Icons.warning_amber_rounded,
                                            size: 16,
                                            color: colors.danger,
                                          ),
                                        ),
                                      Flexible(
                                        child: Text(
                                          '№ ${i + 1} · $title',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    details,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      height: 1.15,
                                      color: colors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (active)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Center(
                            child: DeskIcon(
                              Icons.delete_outline,
                              s.delete,
                              () => setState(() {
                                drafts.removeAt(i).dispose();
                                selectHole(
                                  math.max(0, math.min(i, drafts.length - 1)),
                                );
                              }),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        Text(
          '${s.panelHoles} (${drafts.length})',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        if (compact)
          SizedBox(
            height: rowHeight * drafts.length.clamp(1, 3) + 10,
            child: list,
          )
        else
          Expanded(child: list),
      ],
    );
  }

  Widget addButtons() => Wrap(
    spacing: 6,
    runSpacing: 4,
    children: [
      DeskButton(
        onPressed: () => setState(() => add()),
        icon: const Icon(Icons.add),
        label: Text(context.strings.addHole),
      ),
      DeskButton(
        plain: true,
        onPressed: () => setState(() => add(cup: true)),
        icon: const Icon(Icons.add),
        label: Text(context.strings.cupHole),
      ),
    ],
  );

  Widget properties(_HoleDraft d, int? invalid) {
    final s = context.strings;
    final separator = Divider(height: 1, color: context.colors.line);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: 14,
      children: [
        offsets(d),
        separator,
        Row(
          spacing: 12,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              flex: 3,
              child: labeled(
                s.drillingType,
                DeskSegments(
                  d.blind,
                  {false: s.throughHole, true: s.blindHole},
                  (v) => setState(() {
                    d.blind = v;
                    if (v) d.back = viewBack;
                  }),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: number(s.holeDiameter, 'hole-diameter', d.diameter),
            ),
          ],
        ),
        if (d.blind)
          Row(
            spacing: 12,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                flex: 3,
                child: labeled(
                  s.drillingFace,
                  DeskSegments(d.back, {
                    false: s.faceA,
                    true: s.faceB,
                  }, (v) => setState(() => viewBack = d.back = v)),
                ),
              ),
              Expanded(
                flex: 2,
                child: number(s.rabbetDepth, 'hole-depth', d.depth),
              ),
            ],
          ),
        if (invalid != null)
          Text(
            '№ ${invalid + 1} · ${s.invalidHole}',
            style: TextStyle(color: context.colors.danger),
          ),
        labeled(
          s.holeName,
          Semantics(
            key: const ValueKey('hole-name'),
            label: s.holeName,
            child: DeskTextField(
              key: ObjectKey(d),
              initialValue: d.name,
              placeholder: '№ ${selected + 1}',
              onChanged: (value) => setState(() => d.name = value.trim()),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (_, constraints) => dialog(constraints.maxWidth));

  Widget dialog(double windowWidth) {
    final s = context.strings, unit = widget.input.unit;
    final invalid = {
      for (final (i, d) in drafts.indexed)
        if (d.hole?.fits(size) != true) i,
    };
    final footerAdds = windowWidth >= 680;
    return DeskDialog(
      maxWidth: 1030,
      title: Text(s.panelHoles),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: 14,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 3,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                widget.part.name,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                '${[size.x, size.y, size.z].map(widget.input.format).join(' × ')} ${unit.symbol}',
                style: TextStyle(fontSize: 12, color: context.colors.muted),
              ),
            ],
          ),
          LayoutBuilder(
            builder: (context, box) {
              final d = current;
              final wide = box.maxWidth >= 850;
              final partPreview = preview(
                wide
                    ? 342
                    : upright
                    ? 245
                    : 210,
                invalid,
              );
              final form = d == null
                  ? null
                  : properties(
                      d,
                      invalid.contains(selected)
                          ? selected
                          : invalid.firstOrNull,
                    );
              if (!footerAdds) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 14,
                  children: [
                    holeList(invalid, compact: true),
                    addButtons(),
                    partPreview,
                    ?form,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 16,
                children: [
                  SizedBox(
                    width: wide ? 240 : 190,
                    height: 342,
                    child: holeList(invalid, compact: false),
                  ),
                  if (wide) ...[
                    Expanded(flex: 5, child: partPreview),
                    if (form != null) Expanded(flex: 6, child: form),
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
      leadingAction: footerAdds ? addButtons() : null,
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
              : () => Navigator.pop(context, [for (final d in drafts) d.hole!]),
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

    return SizedBox(
      width: 68,
      height: 52,
      child: Stack(
        children: [
          Positioned.fromRect(
            rect: const Rect.fromLTWH(17, 13, 34, 26),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.chrome,
                border: Border.all(color: colors.muted),
              ),
            ),
          ),
          for (final fromTop in [true, false])
            for (final fromRight in [false, true]) corner(fromRight, fromTop),
        ],
      ),
    );
  }
}

typedef _HoleMark = ({
  int index,
  Offset center,
  double radius,
  bool selected,
  bool blind,
  bool invalid,
});

class _HoleDiagram extends CustomPainter {
  _HoleDiagram(
    this.rect,
    this.shift,
    this.cosine,
    this.colors,
    this.origin,
    this.marks,
  );
  final double shift, cosine;
  final Rect rect;
  final EditorPalette colors;
  final ({bool right, bool top})? origin;
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
      if (m.selected && origin != null) {
        final x = origin!.right ? rect.right : rect.left;
        final y = origin!.top ? rect.top : rect.bottom;
        final guide = Paint()..color = colors.accent.withValues(alpha: .48);
        canvas.drawLine(Offset(x, c.dy), c, guide);
        canvas.drawLine(Offset(c.dx, y), c, guide);
        canvas.drawCircle(Offset(x, c.dy), 1.8, guide);
        canvas.drawCircle(Offset(c.dx, y), 1.8, guide);
      }
      pen.color = m.invalid
          ? colors.danger
          : m.selected
          ? colors.accent
          : colors.muted;
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
              : m.blind
              ? colors.muted
              : colors.paper,
      );
      canvas.drawOval(oval, pen);
      if (m.selected) {
        canvas.drawLine(c - const Offset(7, 0), c + const Offset(7, 0), pen);
        canvas.drawLine(c - const Offset(0, 7), c + const Offset(0, 7), pen);
      }
    }
  }

  @override
  bool shouldRepaint(_HoleDiagram old) => true;
}
