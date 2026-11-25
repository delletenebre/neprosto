part of 'end_cut_dialog.dart';

enum _SawType { miter, handheld, table }

class _SawSetting extends StatelessWidget {
  const _SawSetting({
    required this.tool,
    required this.blade,
    required this.angle,
  });

  final _SawType tool;
  final bool blade;
  final double angle;

  @override
  Widget build(BuildContext context) {
    final s = context.strings, colors = context.colors;
    // Handheld travel points away from the operator, opposite the miter handle.
    final reading = !blade && tool == _SawType.handheld ? -angle : angle;
    final rounded = (angle.abs() * 100).round() / 100;
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
            height: 106,
            child: CustomPaint(
              painter: !blade && tool != _SawType.miter
                  ? _SawPlan(tool, reading, colors)
                  : _SawDial(
                      tool: tool,
                      blade: blade,
                      reading: reading,
                      colors: colors,
                      labelStyle: DefaultTextStyle.of(context).style,
                    ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (blade) ...[
                Icon(Icons.visibility_outlined, size: 13, color: colors.muted),
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
    final radius = math.min(size.height - 33, mid - 16);
    if (radius <= 0) return;
    // In plan the handle points toward the operator. In front elevation the
    // blade points upward. In both views a right setting is on the right.
    final vertical = blade ? -1.0 : 1.0;
    final pivot = Offset(mid, blade ? size.height - 13 : 13);
    Offset direction(double degrees) {
      final radians = degrees * math.pi / 180;
      return Offset(math.sin(radians), vertical * math.cos(radians));
    }

    final limit = math.max(blade ? 45 : 60, (reading.abs() / 15).ceil() * 15);
    final span = limit * math.pi / 180;
    canvas.drawArc(
      Rect.fromCircle(center: pivot, radius: radius),
      vertical * math.pi / 2 - span,
      2 * span,
      false,
      Paint()
        ..color = colors.chrome
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10,
    );
    final tick = Paint();
    for (var degree = -limit; degree <= limit; degree++) {
      final major = degree % 15 == 0;
      final fifth = degree % 5 == 0;
      final ray = direction(degree.toDouble());
      final tickLength = major
          ? 10.0
          : fifth
          ? 7.0
          : 3.0;
      final inner = pivot + ray * (radius - 5);
      tick
        ..color = fifth ? colors.ink : colors.muted
        ..strokeWidth = major ? 1.6 : .8;
      canvas.drawLine(inner, inner + ray * tickLength, tick);
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
        pivot + ray * (radius + 13) - text.size.center(Offset.zero),
      );
      text.dispose();
    }

    // The fence sits behind the miter pivot. The blade stands on the bed.
    final ray = direction(reading);
    final hub = pivot + ray * ((radius - 7) / 2);
    final bedY = switch ((blade, tool)) {
      (true, _SawType.handheld) => pivot.dy - 6,
      (true, _SawType.table) => hub.dy - 3,
      _ => pivot.dy - 4 * vertical,
    };
    final bedWidth = radius * .78;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(mid, bedY),
          width: bedWidth * 2,
          height: 3,
        ),
        const Radius.circular(1.5),
      ),
      Paint()..color = colors.muted,
    );
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(
          mid,
          bedY + (blade && tool == _SawType.handheld ? 4 : 4 * vertical),
        ),
        width: bedWidth * 1.65,
        height: 5,
      ),
      Paint()..color = colors.diagramColor(const Color(0xffdfbd91)),
    );

    final pen = Paint()..color = colors.danger;
    if (blade) {
      // On the table saw the arbor is under the table and only the upper
      // portion of the blade projects above the workpiece.
      canvas.save();
      if (tool == _SawType.table) {
        canvas.clipRect(Rect.fromLTRB(0, 0, size.width, bedY - 1));
      }
      _drawBlade(canvas, size, pivot, radius);
      canvas.restore();
      if (tool == _SawType.handheld) {
        canvas.drawLine(
          Offset(mid - bedWidth * .66, bedY),
          Offset(mid + bedWidth * .66, bedY),
          Paint()
            ..color = colors.muted
            ..strokeWidth = 3,
        );
      }
    } else {
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

  void _drawBlade(Canvas canvas, Size size, Offset pivot, double dialRadius) {
    final radius = (dialRadius - 7) / 2;
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, 0, size.width, pivot.dy + 2));
    canvas.translate(pivot.dx, pivot.dy);
    canvas.rotate(reading * math.pi / 180);
    canvas.translate(0, -radius);
    // An oblique view reveals the teeth and hub while the long axis shows the tilt.
    canvas.scale(.54, 1);
    const pitch = 2 * math.pi / 24;
    final teeth = Path()
      ..addPolygon([
        for (var i = 0; i < 24; i++) ...[
          Offset.fromDirection(i * pitch - math.pi / 2, radius),
          Offset.fromDirection((i + .38) * pitch - math.pi / 2, radius * .87),
        ],
      ], true);
    canvas.drawPath(
      teeth,
      Paint()..color = colors.diagramColor(const Color(0xffaab6c3)),
    );
    final outline = Paint()
      ..color = colors.muted
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    canvas.drawPath(teeth, outline);
    canvas.drawCircle(Offset.zero, radius * .79, outline);
    canvas.drawLine(
      Offset(0, -radius * .2),
      Offset(0, -radius * .92),
      Paint()
        ..color = colors.danger
        ..strokeWidth = 3,
    );
    canvas.drawCircle(Offset.zero, radius * .22, Paint()..color = colors.paper);
    canvas.drawCircle(Offset.zero, radius * .22, outline);
    canvas.drawCircle(Offset.zero, radius * .085, Paint()..color = colors.ink);
    if (tool == _SawType.handheld) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: radius * .97),
        -math.pi,
        math.pi * .88,
        false,
        Paint()
          ..color = colors.muted
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * .16,
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
  const _SawPlan(this.tool, this.angle, this.colors);
  final _SawType tool;
  final double angle;
  final EditorPalette colors;

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
      final table = RRect.fromRectAndRadius(
        Rect.fromLTRB(-halfWidth - 7, -41, halfWidth + 7, 41),
        const Radius.circular(5),
      );
      canvas.drawRRect(table, Paint()..color = colors.chrome);
      final length = math.min(
        halfWidth,
        30 / math.max(.01, math.sin(radians).abs()),
      );
      final knobX = -length * .55;
      const knobY = 9.0;
      final slotX = knobX * math.cos(radians) - knobY * math.sin(radians);
      canvas.drawLine(
        Offset(slotX, -40),
        Offset(slotX, 40),
        Paint()
          ..color = colors.line
          ..strokeWidth = 3,
      );
      // The blade stays in its slot. The gauge turns the board's right end
      // toward the operator for a positive miter-handle reading.
      canvas.save();
      canvas.rotate(radians);
      final knob = Offset(knobX, knobY);
      canvas.drawArc(
        Rect.fromCircle(center: knob, radius: 10),
        0,
        math.pi,
        true,
        Paint()..color = colors.line,
      );
      canvas.drawRect(Rect.fromLTRB(-length, -12, length, 4), wood);
      canvas.drawRRect(
        RRect.fromLTRBR(-length, 4, length, 8, const Radius.circular(1)),
        metal,
      );
      canvas.drawCircle(knob, 3, metal);
      canvas.restore();
      canvas.drawLine(
        const Offset(0, -24),
        const Offset(0, 11),
        line..strokeWidth = 3,
      );
      _drawSight(canvas, const Offset(0, 36), const Offset(0, -1), colors);
    }
  }

  @override
  bool shouldRepaint(_SawPlan old) =>
      old.tool != tool || old.angle != angle || old.colors != colors;
}
