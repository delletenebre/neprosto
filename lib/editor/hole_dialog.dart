import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:material_ui/material_ui.dart';

import '../l10n/strings.dart';
import 'arithmetic.dart';
import 'controller.dart';
import 'desk_text_field.dart';
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
    builder: (_) => _HoleDialog(part, editor.project.unit),
  );
  if (holes != null &&
      context.mounted &&
      identical(editor.project.byId[part.id], part) &&
      !listEquals(holes, part.holes)) {
    editor.commit(editor.project.edit({part.id}, (b) => b.copy(holes: holes)));
  }
}

class _HoleDraft {
  _HoleDraft(this.original, this.unit)
    : fromEnd = original.fromEnd,
      fromFar = original.fromFarEdge,
      blind = original.depth != null,
      back = original.back;
  final PanelHole original;
  final LengthUnit unit;
  bool fromEnd, fromFar, blind, back;
  TextEditingController field(double n) =>
      TextEditingController(text: unit.format(n));
  late final x = field(original.x),
      y = field(original.y),
      diameter = field(original.diameter),
      depth = field(original.depth ?? 12);
  double? read(TextEditingController field, double initial) {
    if (field.text == unit.format(initial)) return initial;
    final n = calculate(field.text);
    return n == null ? null : n * unit.factor;
  }

  late double referenceX = original.x, referenceY = original.y;

  void setReference({
    required bool end,
    required bool far,
    required Vector3 size,
  }) {
    if (end != fromEnd) {
      final value = read(x, referenceX);
      if (value != null) {
        referenceX = size.x - value;
        x.text = unit.format(referenceX);
      }
      fromEnd = end;
    }
    if (far != fromFar) {
      final value = read(y, referenceY);
      if (value != null) {
        referenceY = size.y - value;
        y.text = unit.format(referenceY);
      }
      fromFar = far;
    }
  }

  PanelHole? get hole {
    final a = read(x, referenceX),
        b = read(y, referenceY),
        d = read(diameter, original.diameter),
        z = read(depth, original.depth ?? 12);
    if (a == null || b == null || d == null || (blind && z == null)) {
      return null;
    }
    return PanelHole(
      a,
      b,
      d,
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
  const _HoleDialog(this.part, this.unit);
  final Beam part;
  final LengthUnit unit;
  @override
  State<_HoleDialog> createState() => _HoleDialogState();
}

class _HoleDialogState extends State<_HoleDialog> {
  late final drafts = [
    for (final h in widget.part.holes) _HoleDraft(h, widget.unit),
  ];
  int selected = 0;
  late bool viewBack = current?.blind == true ? current!.back : !upright;
  bool get flipped => viewBack == upright;
  void selectHole(int index) {
    selected = index;
    if (current?.blind == true) viewBack = current!.back;
  }

  _HoleDraft? get current => drafts.elementAtOrNull(selected);
  Vector3 get size => widget.part.size;
  // Show an installed upright in portrait, with its stock length vertical.
  bool get upright =>
      widget.part.along.z.abs() > .01 &&
      widget.part.along.z.abs() > widget.part.across.z.abs();

  @override
  void dispose() {
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
      lineAlongWidth ? inset : position,
      lineAlongWidth ? position : inset,
      diameter,
      fromEnd: lineAlongWidth && far,
      fromFarEdge: !lineAlongWidth && far,
      depth: depth,
      back: back,
    );
    drafts.add(_HoleDraft(h, widget.unit));
    selectHole(drafts.length - 1);
  }

  Widget labeled(String label, Widget child) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    spacing: 5,
    children: [
      Text(label, style: TextStyle(fontSize: 12, color: context.colors.muted)),
      child,
    ],
  );

  Widget number(String label, String key, TextEditingController controller) =>
      labeled(
        label,
        Semantics(
          label: label,
          child: DeskTextField(
            key: ValueKey(key),
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            suffix: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 7),
              child: Text(
                widget.unit.symbol,
                style: TextStyle(fontSize: 12, color: context.colors.muted),
              ),
            ),
            onChanged: (_) => setState(() {}),
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

  Widget diagram(double angle) {
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
        Offset center(PanelHole h) {
          final x = h.centerX(size), y = h.centerY(size);
          return Offset(
            faceRect.center.dx +
                ((upright ? y : x) - width / 2) * scale * cosine,
            rect.bottom - (upright ? x : y) * scale,
          );
        }

        final marks = [for (final d in drafts) d.hole];
        int? hit(Offset at) {
          for (var i = marks.length - 1; i >= 0; i--) {
            final h = marks[i];
            if (h != null &&
                (h.depth == null || h.back == back) &&
                (center(h) - at).distance <=
                    math.max(6, h.diameter * scale / 2)) {
              return i;
            }
          }
          return null;
        }

        void place(Offset at) {
          if (current == null) add();
          final d = current!;
          final horizontal =
              ((at.dx - faceRect.center.dx) / (scale * cosine) + width / 2)
                  .clamp(0.0, width);
          final vertical = ((rect.bottom - at.dy) / scale).clamp(0.0, height);
          final x = upright ? vertical : horizontal,
              y = upright ? horizontal : vertical;
          d.x.text = widget.unit.format(d.fromEnd ? size.x - x : x);
          d.y.text = widget.unit.format(d.fromFar ? size.y - y : y);
        }

        return Stack(
          fit: StackFit.expand,
          children: [
            GestureDetector(
              key: const ValueKey('hole-diagram'),
              behavior: HitTestBehavior.opaque,
              onTapUp: (event) {
                if (!settled || !faceRect.contains(event.localPosition)) {
                  return;
                }
                final i = hit(event.localPosition);
                setState(() {
                  if (i == null) {
                    place(event.localPosition);
                  } else {
                    selectHole(i);
                  }
                });
              },
              onPanStart: (event) {
                if (!settled || !faceRect.contains(event.localPosition)) {
                  return;
                }
                setState(() {
                  selectHole(hit(event.localPosition) ?? selected);
                });
              },
              onPanUpdate: (event) {
                if (settled && faceRect.contains(event.localPosition)) {
                  setState(() => place(event.localPosition));
                }
              },
              child: CustomPaint(
                painter: _HoleDiagram(
                  faceRect,
                  faceShift * 2,
                  cosine.abs(),
                  context.colors,
                  current == null ? null : origin(current!, cosine < 0),
                  [
                    for (final (i, h) in marks.indexed)
                      if (h != null &&
                          h.fits(size) &&
                          (h.depth == null || h.back == back))
                        (
                          center: center(h),
                          radius: h.diameter * scale / 2,
                          selected: i == selected,
                          blind: h.depth != null,
                        ),
                  ],
                ),
              ),
            ),
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

  Widget preview(double height) {
    final s = context.strings;
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
          child: MediaQuery.disableAnimationsOf(context)
              ? diagram(flipped ? math.pi : 0)
              : TweenAnimationBuilder<double>(
                  tween: Tween(end: flipped ? math.pi : 0.0),
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeInOut,
                  builder: (_, angle, _) => diagram(angle),
                ),
        ),
        Text(
          s.holeDiagramHelp,
          style: TextStyle(fontSize: 12, color: context.colors.muted),
        ),
      ],
    );
  }

  Widget properties(int invalid) {
    final s = context.strings, d = current;
    final separator = Divider(height: 1, color: context.colors.line);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: 14,
      children: [
        if (d != null) ...[
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: DeskMenu<int>(
                    title: s.holeSelection(selected + 1, drafts.length),
                    selected: selected,
                    items: [
                      for (var i = 0; i < drafts.length; i++)
                        (
                          i,
                          '№ ${i + 1} · Ø${drafts[i].diameter.text} ${widget.unit.symbol} · ${drafts[i].blind ? (drafts[i].back ? s.faceB : s.faceA) : s.throughHole}',
                        ),
                    ],
                    change: (v) => setState(() => selectHole(v)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 4,
                      children: [
                        Flexible(
                          child: Text(
                            s.holeSelection(selected + 1, drafts.length),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        const Icon(Icons.expand_more, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
              DeskIcon(
                Icons.delete_outline,
                s.delete,
                () => setState(() {
                  drafts.removeAt(selected).dispose();
                  selectHole(
                    math.max(0, math.min(selected, drafts.length - 1)),
                  );
                }),
              ),
            ],
          ),
          separator,
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
          if (invalid >= 0)
            Text(
              '№ ${invalid + 1} · ${s.invalidHole}',
              style: TextStyle(color: context.colors.danger),
            ),
          separator,
        ] else
          Text(
            s.noPanelHoles,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            DeskButton(
              onPressed: () => setState(() => add()),
              icon: const Icon(Icons.add),
              label: Text(s.addHole),
            ),
            DeskButton(
              onPressed: () => setState(() => add(cup: true)),
              icon: const Icon(Icons.add),
              label: Text(s.cupHole),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings, unit = widget.unit;
    final invalid = drafts.indexWhere((d) => d.hole?.fits(size) != true);
    return DeskDialog(
      maxWidth: 790,
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
                '${[size.x, size.y, size.z].map(unit.format).join(' × ')} ${unit.symbol}',
                style: TextStyle(fontSize: 12, color: context.colors.muted),
              ),
            ],
          ),
          LayoutBuilder(
            builder: (context, box) {
              if (box.maxWidth < 630) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 14,
                  children: [preview(upright ? 245 : 210), properties(invalid)],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 20,
                children: [
                  Expanded(flex: 5, child: preview(342)),
                  Expanded(flex: 6, child: properties(invalid)),
                ],
              );
            },
          ),
        ],
      ),
      actions: [
        DeskButton(
          plain: true,
          onPressed: () => Navigator.pop(context),
          child: Text(s.cancel),
        ),
        DeskButton(
          primary: true,
          onPressed: invalid >= 0
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
          for (final y in [true, false])
            for (final x in [false, true])
              Positioned(
                left: x ? 34 : 0,
                top: y ? 0 : 26,
                width: 34,
                height: 26,
                child: Tooltip(
                  message:
                      '${x ? s.fromRight : s.fromLeft} · ${y ? s.fromTop : s.fromBottom}',
                  child: Semantics(
                    selected: right == x && top == y,
                    label:
                        '${x ? s.fromRight : s.fromLeft} · ${y ? s.fromTop : s.fromBottom}',
                    child: DeskControl(
                      key: ValueKey('hole-origin-$x-$y'),
                      onPressed: () => onChanged(x, y),
                      child: Container(
                        width: right == x && top == y ? 12 : 7,
                        height: right == x && top == y ? 12 : 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: right == x && top == y
                              ? EditorPalette.highlight
                              : colors.field,
                          border: Border.all(
                            color: right == x && top == y
                                ? colors.accent
                                : colors.muted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

typedef _HoleMark = ({Offset center, double radius, bool selected, bool blind});

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
      pen.color = m.selected ? colors.accent : colors.muted;
      final r = math.max(2.0, m.radius);
      final oval = Rect.fromCenter(
        center: c,
        width: 2 * r * cosine,
        height: 2 * r,
      );
      canvas.drawOval(
        oval,
        Paint()..color = m.blind ? colors.muted : colors.paper,
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
