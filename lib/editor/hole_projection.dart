part of 'hole_dialog.dart';

class _PlanDimension {
  const _PlanDimension(
    this.horizontal,
    this.after,
    this.from,
    this.target,
    this.value,
  );

  factory _PlanDimension.offset(
    Rect face,
    Offset target,
    bool horizontal,
    bool fromMax,
    double value, {
    bool after = false,
  }) {
    final origin = horizontal
        ? (fromMax ? face.right : face.left)
        : (fromMax ? face.bottom : face.top);
    return _PlanDimension(horizontal, after, origin, target, value);
  }
  final bool horizontal, after;
  final double from, value;
  final Offset target;
}

/// Dimension lines occupy the four margins, leaving the holes selectable.
class _PlanDimensions extends CustomPainter {
  _PlanDimensions(BuildContext context, this.face, this.lines, this.unit)
    : colors = context.colors,
      style = DefaultTextStyle.of(context).style.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: context.colors.ink,
      ),
      scaler = MediaQuery.textScalerOf(context),
      direction = Directionality.of(context);
  final Rect face;
  final List<_PlanDimension> lines;
  final LengthUnit unit;
  final EditorPalette colors;
  final TextStyle style;
  final TextScaler scaler;
  final TextDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    final pen = Paint()
      ..color = colors.accent
      ..strokeWidth = 1;
    final guide = Paint()
      ..color = colors.muted.withValues(alpha: .45)
      ..strokeWidth = .7;
    for (final d in lines) {
      final h = d.horizontal, sign = d.after ? 1.0 : -1.0;
      final edge = h
          ? (d.after ? face.bottom : face.top)
          : (d.after ? face.right : face.left);
      final line = edge + sign * 7;
      final end = h ? d.target.dx : d.target.dy;
      Offset point(double along, double across) =>
          h ? Offset(along, across) : Offset(across, along);
      canvas.drawLine(
        point(d.from, edge),
        point(d.from, line + sign * 2),
        guide,
      );
      canvas.drawLine(d.target, point(end, line + sign * 2), guide);
      canvas.drawLine(point(d.from, line), point(end, line), pen);
      for (final x in [d.from, end]) {
        final p = point(x, line);
        canvas.drawLine(p.translate(-2, 2), p.translate(2, -2), pen);
      }
      final label = TextPainter(
        text: TextSpan(
          text: '${unit.format(d.value)} ${unit.symbol}',
          style: style,
        ),
        textScaler: scaler,
        textDirection: direction,
        maxLines: 1,
      )..layout();
      final available = h ? size.width : size.height;
      final factor = math.min(1.0, available / (label.width + 4));
      final half = label.width * factor / 2;
      final middle = ((d.from + end) / 2).clamp(half, available - half);
      final at = point(middle, line + sign * (3 + label.height * factor / 2));
      canvas.save();
      canvas.translate(at.dx, at.dy);
      if (!h) canvas.rotate(-math.pi / 2);
      canvas.scale(factor);
      label.paint(canvas, Offset(-label.width / 2, -label.height / 2));
      canvas.restore();
      label.dispose();
    }
  }

  @override
  bool shouldRepaint(_PlanDimensions old) => true;
}

class _EdgeBoreCaption extends StatelessWidget {
  const _EdgeBoreCaption({
    required this.unit,
    required this.bolt,
    required this.inset,
  });
  final LengthUnit unit;
  final BoltBore bolt;
  final double? inset;
  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    String length(double? n) =>
        n == null ? '—' : '${unit.format(n)} ${unit.symbol}';
    return Text(
      '${s.boltBoreOption} · Ø${length(bolt.diameter)} · ${s.boltBoreDepth} ${length(inset)} · ${s.boltFaceOffset} ${length(bolt.faceOffset)}',
      style: TextStyle(color: context.colors.muted, fontSize: 12),
    );
  }
}

class _BoreRowPlan extends StatelessWidget {
  const _BoreRowPlan({
    required this.side,
    required this.edge,
    required this.panelSize,
    required this.center,
    required this.diameter,
    required this.start,
    required this.end,
    required this.count,
    required this.blind,
    required this.bolt,
    required this.unit,
  });
  final DoorHinge side;
  final PanelEdge edge;
  final Vector3 panelSize;
  final double? center, diameter, start, end;
  final int? count;
  final bool blind;
  final BoltBore? bolt;
  final LengthUnit unit;

  @override
  Widget build(BuildContext context) {
    final vertical = side.onSide;
    final far = side == DoorHinge.right || side == DoorHinge.bottom;
    final length = edge.length(panelSize), width = edge.width(panelSize);
    final inset = center, bit = diameter, first = start, last = end, n = count;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: context.colors.paper,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 158 + 2 * MediaQuery.textScalerOf(context).scale(11),
            child: LayoutBuilder(
              builder: (context, box) {
                final margin = MediaQuery.textScalerOf(context).scale(12) + 16;
                final w = vertical ? width : length,
                    h = vertical ? length : width;
                final scale = math.min(
                  math.max(1.0, box.maxWidth - margin * 2) / w,
                  math.max(1.0, box.maxHeight - margin * 2) / h,
                );
                final face = Rect.fromCenter(
                  center: box.biggest.center(Offset.zero),
                  width: w * scale,
                  height: h * scale,
                );
                final marks = <_HoleMark>[], lines = <_PlanDimension>[];
                if (bit != null &&
                    bit > 0 &&
                    inset != null &&
                    inset >= bit / 2 &&
                    inset + bit / 2 <= width &&
                    first != null &&
                    n != null &&
                    n >= 1 &&
                    (n == 1 || last != null) &&
                    n <= length / bit + 1) {
                  final pitch = n == 1
                      ? 0.0
                      : (length - first - last!) / (n - 1);
                  final cross = far ? width - inset : inset;
                  // Sub-pixel holes in a dense row share the same screen pixel.
                  final stride = n > 1 && pitch > 0
                      ? math.max(1, (1 / (scale * pitch)).floor())
                      : 1;
                  if (first >= bit / 2 &&
                      first <= length - bit / 2 &&
                      (n == 1 || (last! >= bit / 2 && pitch >= bit))) {
                    for (var i = 0; i < n; i = math.min(i + stride, n - 1)) {
                      final along = first + pitch * i;
                      final c =
                          face.topLeft +
                          (vertical
                                  ? Offset(cross, along)
                                  : Offset(along, cross)) *
                              scale;
                      final entry = vertical
                          ? Offset(far ? face.right : face.left, c.dy)
                          : Offset(c.dx, far ? face.bottom : face.top);
                      marks.add((
                        index: i,
                        center: c,
                        boltEntry: bolt == null ? null : entry,
                        radius: bit * scale / 2,
                        selected: i == 0,
                        blind: blind,
                        invalid: false,
                      ));
                      if (i == n - 1) break;
                    }
                    final c = marks.first.center;
                    final delta = (far ? 1 : -1) * bit * scale / 2;
                    lines.addAll([
                      _PlanDimension.offset(face, c, vertical, far, inset),
                      _PlanDimension.offset(
                        face,
                        c.translate(vertical ? delta : 0, vertical ? 0 : delta),
                        vertical,
                        far,
                        inset - bit / 2,
                        after: true,
                      ),
                      _PlanDimension.offset(face, c, !vertical, false, first),
                      if (n > 1)
                        _PlanDimension.offset(
                          face,
                          marks.last.center,
                          !vertical,
                          true,
                          last!,
                          after: true,
                        ),
                    ]);
                  }
                }
                return CustomPaint(
                  key: const ValueKey('cup-measurement-diagram'),
                  painter: _HoleDiagram(face, 0, 1, context.colors, marks),
                  foregroundPainter: _PlanDimensions(
                    context,
                    face,
                    lines,
                    unit,
                  ),
                );
              },
            ),
          ),
          if (bolt case final shaft?)
            _EdgeBoreCaption(unit: unit, bolt: shaft, inset: inset),
        ],
      ),
    );
  }
}
