part of 'end_cut_dialog.dart';

enum _SawType { miter, handheld, table }

const _stockTint = Color(0xffd6aa75);
const _fenceTint = Color(0xff426c85);

class _SawSetting extends StatelessWidget {
  const _SawSetting({
    required this.tool,
    required this.blade,
    required this.angle,
    required this.tableCutaway,
    this.changeView,
  });

  final _SawType tool;
  final bool blade;
  final double angle;
  final bool tableCutaway;
  final ValueChanged<bool>? changeView;

  @override
  Widget build(BuildContext context) {
    final s = context.strings, colors = context.colors;
    // Handheld travel points away from the operator, opposite the miter handle.
    final reading = !blade && tool == _SawType.handheld ? -angle : angle;
    final rounded = Units.angleOf(context).round(angle.abs());
    final degrees = NumberFormat('0.##', s.localeName).format(rounded);
    final value = switch ((rounded, blade, tool)) {
      (0, _, _) => '0°',
      (_, false, _SawType.table) =>
        reading > 0 ? s.sawFenceNear(degrees) : s.sawFenceFar(degrees),
      _ => reading < 0 ? s.sawAngleLeft(degrees) : s.sawAngleRight(degrees),
    };
    final (title, view) = switch ((blade, tool)) {
      (false, _SawType.miter) => (s.sawTableRotation, s.sawMiterPlan),
      (false, _SawType.handheld) => (s.sawCutLine, s.sawHandPlan),
      (false, _SawType.table) => (s.sawCrosscutFence, s.sawTablePlan),
      (true, _SawType.miter) => (s.sawBladeTilt, s.sawMiterSight),
      (true, _SawType.handheld) => (s.sawBladeTilt, s.sawHandSight),
      (true, _SawType.table) => (s.sawBladeTilt, s.sawTableSight),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.paper,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 2,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          SizedBox(
            height: 150,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: CustomPaint(
                    painter: blade && tool == _SawType.table
                        ? TableSawPreview(
                            reading,
                            tableCutaway,
                            colors,
                            DefaultTextStyle.of(context).style,
                          )
                        : !blade && tool != _SawType.miter
                        ? _SawPlan(
                            tool,
                            reading,
                            colors,
                            s.sawFeed,
                            tableCutaway,
                            DefaultTextStyle.of(context).style,
                          )
                        : _SawDial(
                            tool: tool,
                            blade: blade,
                            reading: reading,
                            colors: colors,
                            labelStyle: DefaultTextStyle.of(context).style,
                          ),
                  ),
                ),
                if (!blade && tool == _SawType.table)
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 9,
                    children: [
                      for (final (label, color) in [
                        (s.part, colors.diagramColor(_stockTint)),
                        (s.sawFenceKey, colors.diagramColor(_fenceTint)),
                        (s.sawBladeKey, colors.danger),
                      ])
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: const SizedBox(width: 10, height: 5),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              label,
                              style: TextStyle(fontSize: 10, color: colors.ink),
                            ),
                          ],
                        ),
                    ],
                  ),
              ],
            ),
          ),
          if (blade && tool == _SawType.table)
            DeskSegments<bool>(tableCutaway, {
              true: s.sawTableSight,
              false: s.sawFeedView,
            }, changeView!)
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (blade) ...[
                  Icon(
                    Icons.visibility_outlined,
                    size: 13,
                    color: colors.muted,
                  ),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    view,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: colors.muted),
                  ),
                ),
              ],
            ),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colors.ink,
            ),
          ),
        ],
      ),
    );
  }
}

class _SawDial extends CustomPainter {
  const _SawDial({
    required this.tool,
    required this.blade,
    required this.reading,
    required this.colors,
    required this.labelStyle,
  });
  final _SawType tool;
  final bool blade;
  final double reading;
  final EditorPalette colors;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.width / 2;
    final radius = math.min(math.min(size.height * .56, 86.0), mid - 17);
    if (radius <= 0) return;
    // In plan the handle points toward the operator. In front elevation the
    // blade points upward. In both views a right setting is on the right.
    final vertical = blade ? -1.0 : 1.0;
    final pivot = Offset(mid, blade ? size.height * .69 : size.height * .17);
    Offset direction(double degrees) {
      final radians = degrees * math.pi / 180;
      return Offset(math.sin(radians), vertical * math.cos(radians));
    }

    final limit = math.max(blade ? 45 : 60, (reading.abs() / 15).ceil() * 15);
    final span = limit * math.pi / 180;
    final scale = Rect.fromCircle(center: pivot, radius: radius);
    canvas.drawArc(
      scale,
      vertical * math.pi / 2 - span,
      2 * span,
      false,
      Paint()
        ..color = colors.line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    final tick = Paint();
    for (var degree = -limit; degree <= limit; degree++) {
      final major = degree % 15 == 0;
      final fifth = degree % 5 == 0;
      final ray = direction(degree.toDouble());
      final length = major
          ? 7.0
          : fifth
          ? 4.5
          : 2.0;
      tick
        ..color = major
            ? colors.ink
            : fifth
            ? colors.muted
            : colors.line
        ..strokeWidth = major ? 1.2 : .8;
      canvas.drawLine(
        pivot + ray * (radius - length),
        pivot + ray * radius,
        tick,
      );
      if (!major) continue;
      final text = TextPainter(
        text: TextSpan(
          text: '${degree.abs()}',
          style: labelStyle.copyWith(
            fontSize: 10,
            fontWeight: degree == 0 ? FontWeight.w700 : FontWeight.w500,
            color: colors.ink,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(
        canvas,
        pivot + ray * (radius + 10) - text.size.center(Offset.zero),
      );
      text.dispose();
    }

    final ray = direction(reading);
    final pen = Paint()..color = colors.danger;
    if (blade) {
      _drawBladeView(canvas, size, pivot, radius, ray);
    } else {
      final fenceWidth = radius * .8;
      canvas.drawRRect(
        RRect.fromLTRBR(
          mid - fenceWidth,
          pivot.dy - 6,
          mid + fenceWidth,
          pivot.dy - 3,
          const Radius.circular(1.5),
        ),
        Paint()..color = colors.muted,
      );
      canvas.drawRect(
        Rect.fromLTRB(
          mid - fenceWidth * .82,
          pivot.dy - 3,
          mid + fenceWidth * .82,
          pivot.dy + 2,
        ),
        Paint()..color = colors.diagramColor(_stockTint),
      );
      final cross = Offset(-ray.dy, ray.dx);
      final tip = pivot + ray * (radius - 4);
      final base = tip - ray * 9;
      canvas.drawLine(pivot, base, pen..strokeWidth = 2);
      canvas.drawPath(
        Path()..addPolygon([tip, base + cross * 3.7, base - cross * 3.7], true),
        pen,
      );
      canvas.drawCircle(pivot, 3.5, pen);
      canvas.drawCircle(pivot, 1.4, Paint()..color = colors.paper);
      _drawSight(
        canvas,
        pivot + ray * (radius * .54) + cross * 10,
        -ray,
        colors,
      );
    }
    canvas.drawLine(
      pivot + ray * (radius - 5),
      pivot + ray * (radius + 4),
      pen..strokeWidth = 2,
    );
  }

  // Oblique front view. Width and height stay true for the bevel scale.
  // Length along the cut recedes slightly to the left and up.
  static const _cutDepth = Offset(-.21, -.09);

  void _drawBladeView(
    Canvas canvas,
    Size size,
    Offset pivot,
    double dialRadius,
    Offset ray,
  ) {
    final radius = dialRadius * .40;
    final hubDistance = radius * .72;
    final hub = pivot + ray * hubDistance;
    final bed = Rect.fromCenter(
      center: pivot + const Offset(0, 2),
      width: math.min(size.width - 14, dialRadius * 1.85),
      height: 6,
    );
    final stockY = tool == _SawType.handheld ? bed.bottom : bed.top - 7;
    final stock = Rect.fromLTWH(bed.left + 8, stockY, bed.width - 16, 7);
    final metal = colors.diagramColor(const Color(0xff586671));
    if (reading.abs() > 1) {
      final zero = Paint()
        ..color = colors.line
        ..strokeWidth = 1;
      for (double d = 6; d < dialRadius - 10; d += 7) {
        canvas.drawLine(pivot - Offset(0, d), pivot - Offset(0, d + 3), zero);
      }
    }
    _drawSlottedPlate(
      canvas,
      stock,
      25,
      colors.diagramColor(_stockTint),
      pivot,
      ray,
    );
    _drawSlottedPlate(canvas, bed, 34, metal, pivot, ray);
    canvas.save();
    canvas.translate(hub.dx, hub.dy);
    final bevel = reading * math.pi / 180;
    canvas.rotate(bevel);
    // Express the fixed depth axis in the rotating blade's coordinates.
    final depth = Offset(
      _cutDepth.dx * math.cos(bevel) + _cutDepth.dy * math.sin(bevel),
      -_cutDepth.dx * math.sin(bevel) + _cutDepth.dy * math.cos(bevel),
    );
    _drawDisc(canvas, radius, depth);
    canvas.restore();
    // The front lip is nearer to the viewer than the blade and its arbor.
    _drawSlottedPlate(canvas, bed, 34, metal, pivot, ray, frontOnly: true);
    final tip = hubDistance + radius;
    final guide = Paint()
      ..color = colors.danger
      ..strokeWidth = 1;
    for (double d = tip + 3; d < dialRadius - 7; d += 5) {
      canvas.drawLine(pivot + ray * d, pivot + ray * (d + 2), guide);
    }
    final side = Offset(-ray.dy, ray.dx);
    final index = pivot + ray * (dialRadius - 1);
    final base = index - ray * 6;
    canvas.drawPath(
      Path()..addPolygon([index, base + side * 2.8, base - side * 2.8], true),
      guide,
    );
  }

  void _drawSlottedPlate(
    Canvas canvas,
    Rect section,
    double halfDepth,
    Color color,
    Offset pivot,
    Offset ray, {
    bool frontOnly = false,
  }) {
    final back = _cutDepth * halfDepth;
    // Intersect the same blade plane with both heights of the cross-section.
    double cut(double y, double side) =>
        (pivot.dx + ((y - pivot.dy) * ray.dx - side * 1.8) / ray.dy)
            .clamp(section.left, section.right)
            .toDouble();
    for (final (left, right, lowerLeft, lowerRight) in [
      (
        section.left,
        cut(section.top, -1),
        section.left,
        cut(section.bottom, -1),
      ),
      (
        cut(section.top, 1),
        section.right,
        cut(section.bottom, 1),
        section.right,
      ),
    ]) {
      final a = Offset(left, section.top), b = Offset(right, section.top);
      if (!frontOnly) {
        canvas.drawPath(
          Path()..addPolygon([a - back, b - back, b + back, a + back], true),
          Paint()..color = Color.lerp(color, colors.paper, .25)!,
        );
      }
      canvas.drawPath(
        Path()..addPolygon([
          a - back,
          b - back,
          Offset(lowerRight, section.bottom) - back,
          Offset(lowerLeft, section.bottom) - back,
        ], true),
        Paint()..color = color,
      );
    }
  }

  void _drawDisc(Canvas canvas, double radius, Offset depth) {
    const pitch = 2 * math.pi / 28;
    final teeth = [
      for (var i = 0; i < 28; i++) ...[
        Offset.fromDirection(i * pitch, radius),
        Offset.fromDirection((i + .18) * pitch, radius),
        Offset.fromDirection((i + .50) * pitch, radius * .936),
      ],
    ];
    final edge = [for (final p in teeth) depth * p.dx + Offset(0, p.dy)];
    const halfKerf = 1.2;
    const across = Offset(halfKerf, 0);
    final walls = Path();
    for (var i = 0; i < edge.length; i++) {
      final a = edge[i], b = edge[(i + 1) % edge.length];
      // Consistent winding keeps overlapping teeth solid even exactly edge-on.
      final side = a.dy <= b.dy ? across : -across;
      walls.addPolygon([a - side, b - side, b + side, a + side], true);
    }
    canvas.drawPath(walls, Paint()..color = const Color(0xff627580));
    final near = depth.dx <= 0 ? 1.0 : -1.0;
    canvas.drawLine(
      Offset(-near * radius * .13, 0),
      Offset(near * radius * .16, 0),
      Paint()
        ..color = const Color(0xff697b85)
        ..strokeWidth = radius * .12
        ..strokeCap = StrokeCap.round,
    );
    if (depth.dx.abs() < 1e-6) return;
    canvas.save();
    canvas.translate(near * halfKerf, 0);
    final projection = Matrix4.identity()
      ..setEntry(0, 0, depth.dx)
      ..setEntry(1, 0, depth.dy);
    canvas.transform(projection.storage);
    final rim = Path()..addPolygon(teeth, true);
    final face = Rect.fromCircle(center: Offset.zero, radius: radius);
    canvas.drawPath(
      rim,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xffe7edef),
            Color(0xffa0b1ba),
            Color(0xffe7edef),
            Color(0xff91a4af),
          ],
          stops: [0, .38, .6, 1],
        ).createShader(face),
    );
    canvas.drawPath(
      rim,
      Paint()
        ..color = const Color(0xff6e818b)
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8,
    );
    final machining = Paint()
      ..color = const Color(0xff8c9da5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .6;
    canvas.drawCircle(Offset.zero, radius * .84, machining);
    for (var i = 0; i < 3; i++) {
      final a = i * 2 * math.pi / 3 + .35;
      final slot = Path()
        ..moveTo(radius * .72 * math.cos(a), radius * .72 * math.sin(a))
        ..quadraticBezierTo(
          radius * .57 * math.cos(a + .12),
          radius * .57 * math.sin(a + .12),
          radius * .52 * math.cos(a + .28),
          radius * .52 * math.sin(a + .28),
        );
      canvas.drawPath(
        slot,
        Paint()
          ..color = const Color(0xff7a8d97)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.25
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.drawCircle(
      Offset.zero,
      radius * .16,
      Paint()..color = const Color(0xff7a8c96),
    );
    canvas.drawCircle(
      Offset.zero,
      radius * .12,
      Paint()..color = const Color(0xffdbe2e5),
    );
    canvas.drawCircle(
      Offset.zero,
      radius * .065,
      Paint()..color = const Color(0xff475963),
    );
    if (tool == _SawType.handheld) {
      // A raised guard follows the teeth without painting over the disc face.
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: radius * 1.045),
        -math.pi * 1.04,
        math.pi * .92,
        false,
        Paint()
          ..color = colors.diagramColor(_fenceTint)
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * .13
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SawDial old) =>
      old.blade != blade ||
      old.tool != tool ||
      old.reading != reading ||
      old.colors != colors ||
      old.labelStyle != labelStyle;
}

/// The eye in each plan locates the observer for the adjacent blade view.
void _drawSight(
  Canvas canvas,
  Offset eye,
  Offset direction,
  EditorPalette colors,
) {
  final side = Offset(-direction.dy, direction.dx);
  final ink = Paint()..color = colors.ink;
  final edge = Path()
    ..moveTo(eye.dx - 6, eye.dy)
    ..quadraticBezierTo(eye.dx, eye.dy - 7, eye.dx + 6, eye.dy)
    ..quadraticBezierTo(eye.dx, eye.dy + 7, eye.dx - 6, eye.dy)
    ..close();
  canvas.drawPath(edge, Paint()..color = colors.paper);
  canvas.drawPath(
    edge,
    Paint()
      ..color = colors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1,
  );
  canvas.drawCircle(eye, 1.7, ink);
  final tip = eye + direction * 14;
  final base = eye + direction * 8;
  canvas.drawPath(
    Path()..addPolygon([tip, base + side * 2.6, base - side * 2.6], true),
    ink,
  );
}

class _SawPlan extends CustomPainter {
  const _SawPlan(
    this.tool,
    this.angle,
    this.colors,
    this.feed,
    this.tableCutaway,
    this.labelStyle,
  );
  final _SawType tool;
  final double angle;
  final EditorPalette colors;
  final String feed;
  final bool tableCutaway;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.center(Offset.zero);
    final halfWidth = math.min(78.0, mid.dx - 21);
    if (halfWidth <= 0) return;
    final wood = Paint()..color = colors.diagramColor(const Color(0xffdfbd91));
    final metal = Paint()..color = colors.muted;
    final line = Paint()
      ..color = colors.danger
      ..strokeWidth = 2;
    final radians = angle * math.pi / 180;
    canvas.translate(mid.dx, mid.dy);
    if (tool == _SawType.handheld) {
      final board = Rect.fromLTRB(-halfWidth, -23, halfWidth, 23);
      canvas.drawRect(board, wood);
      final direction = Offset(math.sin(radians), -math.cos(radians));
      final reach = math.min(
        halfWidth / direction.dx.abs(),
        23 / direction.dy.abs(),
      );
      final far = direction * reach, near = -far;
      for (double y = -23; y < 23; y += 6) {
        canvas.drawLine(
          Offset(0, y),
          Offset(0, y + 3),
          Paint()..color = colors.muted,
        );
      }
      canvas.drawLine(near, far, line);
      canvas.save();
      canvas.rotate(radians);
      // The shoe and guard travel with the cut line, on top of the board.
      final shoe = RRect.fromLTRBR(-13, 1, 6, 25, const Radius.circular(2));
      canvas.drawRRect(shoe, Paint()..color = colors.chrome);
      canvas.drawRRect(
        shoe,
        Paint()
          ..color = colors.muted
          ..style = PaintingStyle.stroke,
      );
      canvas.drawRRect(
        RRect.fromLTRBR(-8, 6, -3, 20, const Radius.circular(2)),
        metal,
      );
      canvas.drawLine(const Offset(0, 1), const Offset(0, 23), line);
      canvas.drawPath(
        Path()..addPolygon(const [
          Offset(0, -10),
          Offset(-3, -4),
          Offset(3, -4),
        ], true),
        line,
      );
      canvas.restore();
      _drawSight(canvas, near - direction * 16, direction, colors);
    } else {
      _drawTable(canvas, size, radians);
    }
  }

  void _drawTable(Canvas canvas, Size size, double radians) {
    final w = math.min(size.width - 4, 229.0);
    final h = math.min(size.height - 18, 112.0);
    if (w < 40 || h < 30) return;
    final table = Rect.fromCenter(
      center: const Offset(0, -3),
      width: w,
      height: h,
    );
    final top = RRect.fromRectAndRadius(table, const Radius.circular(6));
    canvas.drawRRect(
      top.shift(const Offset(0, 2)),
      Paint()..color = colors.line,
    );
    canvas.drawRRect(top, Paint()..color = colors.chrome);
    canvas.drawRRect(
      top,
      Paint()
        ..color = colors.line
        ..style = PaintingStyle.stroke
        ..strokeWidth = .8,
    );
    final cutX = -w * .045;
    canvas.translate(cutX, -5);
    final length = math.min(
      w * .36,
      (h * .42 - 8) / math.max(.01, math.sin(radians).abs()),
    );
    const knobY = 7.0;
    final knobX = -length * .62;
    final slotX = knobX * math.cos(radians) - knobY * math.sin(radians);
    final guide = colors.diagramColor(_fenceTint);
    final rail = Paint()
      ..color = colors.line
      ..strokeWidth = 2.5;
    canvas.drawLine(
      Offset(slotX, table.top + 6),
      Offset(slotX, table.bottom + 4),
      rail,
    );
    final insert = RRect.fromLTRBR(
      -5,
      -h * .38,
      5,
      4,
      const Radius.circular(5),
    );
    canvas.drawRRect(insert, Paint()..color = colors.paper);
    canvas.drawRRect(
      insert,
      Paint()
        ..color = colors.line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.save();
    canvas.rotate(radians);
    final knob = Offset(knobX, knobY);
    canvas.drawArc(
      Rect.fromCircle(center: knob, radius: 12),
      0,
      math.pi,
      true,
      Paint()..color = guide.withValues(alpha: .4),
    );
    final board = Rect.fromLTRB(-length, -18, length, 4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(board, const Radius.circular(1.5)),
      Paint()..color = colors.diagramColor(_stockTint),
    );
    final grain = Paint()
      ..color = const Color(0xff8d602c).withValues(alpha: .32)
      ..strokeWidth = .8;
    for (final y in [-12.0, -4.0]) {
      final mark = Path()
        ..moveTo(-length + 3, y)
        ..cubicTo(-length * .35, y + 2, length * .2, y - 2, length - 3, y);
      canvas.drawPath(mark, grain..style = PaintingStyle.stroke);
    }
    canvas.drawRRect(
      RRect.fromLTRBR(-length - 3, 4, length + 3, 10, const Radius.circular(2)),
      Paint()..color = guide,
    );
    canvas.drawCircle(knob, 3.5, Paint()..color = guide);
    canvas.drawCircle(knob, 1.3, Paint()..color = colors.paper);
    canvas.drawCircle(Offset(length, 7), 2, Paint()..color = colors.paper);
    canvas.restore();

    if (angle.abs() >= 2) {
      final center = Offset(
        slotX,
        knobX * math.sin(radians) + knobY * math.cos(radians),
      );
      final arcRadius = length * .54;
      final reference = Paint()
        ..color = colors.muted
        ..strokeWidth = 1;
      for (double d = 4; d < arcRadius + 12; d += 6) {
        canvas.drawLine(
          center + Offset(d, 0),
          center + Offset(d + 3, 0),
          reference,
        );
      }
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: arcRadius),
        0,
        radians,
        false,
        Paint()
          ..color = guide
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
      final zero = TextPainter(
        text: TextSpan(
          text: '0°',
          style: labelStyle.copyWith(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: colors.ink,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final at = center + Offset(arcRadius + 15, -zero.height / 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          (at & zero.size).inflate(1),
          const Radius.circular(2),
        ),
        Paint()..color = colors.chrome,
      );
      zero.paint(canvas, at);
      zero.dispose();
    }

    // The tabletop insert and blade stay fixed as the gauge rotates.
    final blade = RRect.fromLTRBR(
      -1.7,
      -h * .32,
      1.7,
      -2,
      const Radius.circular(1.2),
    );
    canvas.drawRRect(blade, Paint()..color = colors.danger);
    final feedX = table.right - cutX - 20;
    final feedPen = Paint()
      ..color = guide
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(feedX, 6), Offset(feedX, -16), feedPen);
    canvas.drawPath(
      Path()..addPolygon([
        Offset(feedX, -21),
        Offset(feedX - 4, -13),
        Offset(feedX + 4, -13),
      ], true),
      feedPen,
    );
    final label = TextPainter(
      text: TextSpan(
        text: feed,
        style: labelStyle.copyWith(
          fontSize: 9,
          color: guide,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, Offset(feedX - label.width / 2, 9));
    label.dispose();
    final eye = TableSawPreview.viewpoint(tableCutaway);
    final sight = Offset(-eye.x, eye.y);
    _drawSight(
      canvas,
      Offset(eye.x * w * .48 - cutX, table.bottom + 8),
      sight / sight.distance,
      colors,
    );
  }

  @override
  bool shouldRepaint(_SawPlan old) =>
      old.tool != tool ||
      old.angle != angle ||
      old.colors != colors ||
      old.feed != feed ||
      old.tableCutaway != tableCutaway ||
      old.labelStyle != labelStyle;
}
