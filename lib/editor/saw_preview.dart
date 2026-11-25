import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'model.dart' show Vector3;
import 'palette.dart';

enum SawType { miter, handheld, table }

/// The plan shows rotation about the table normal. The blade view shows bevel
/// about the cut line, with the observer behind the direction of travel.
class SawPreview extends CustomPainter {
  const SawPreview({
    required this.tool,
    required this.bladeView,
    required this.angle,
    required this.angleLabel,
    required this.cutaway,
    required this.colors,
    required this.labelStyle,
    required this.feedLabel,
  });

  static const wood = Color(0xffd9b783), fence = Color(0xff52788b);
  final SawType tool;
  final bool bladeView;
  final String feedLabel;

  final double angle;
  final String angleLabel;
  final bool cutaway;
  final EditorPalette colors;
  final TextStyle labelStyle;

  Vector3 get bladeEye =>
      (tool != SawType.table
              ? Vector3(-.76, -1, .52)
              : cutaway
              ? Vector3(.97, -.86, .36)
              : Vector3(-.58, -1, .60))
          .normalized();

  @override
  void paint(Canvas canvas, Size size) {
    final showScale = bladeView || tool == SawType.miter;
    final height = size.height - (showScale ? 25 : 0);
    final scene = _SawScene(canvas, this);
    final tableBlade = bladeView && tool == SawType.table;
    final sceneHeight = tableBlade
        ? 66.0
        : bladeView
        ? 82.0
        : 96.0;
    final scale = math.min((size.width - 8) / 127, height / sceneHeight);
    if (scale <= 0) return;
    canvas.save();
    canvas.translate(
      size.width / 2,
      height *
          (tableBlade
              ? (cutaway ? .46 : .52)
              : bladeView
              ? .66
              : .48),
    );
    canvas.scale(scale);
    scene.draw();
    canvas.restore();
    if (!showScale) return;

    final limit = math.max(bladeView ? 45 : 60, (angle.abs() / 15).ceil() * 15);
    final half = math.min(size.width * .40, 90.0);
    double x(double degrees) => size.width / 2 + degrees / limit * half;
    final tick = Paint()..strokeWidth = .9;
    final y = height + 8;
    final dx = x(angle);
    final active = TextPainter(
      text: TextSpan(
        text: angleLabel,
        style: labelStyle.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: colors.danger,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);
    final double left = (dx - active.width / 2).clamp(
      0.0,
      size.width - active.width,
    );
    final activeBounds = Offset(left, y + 1) & active.size;
    for (int d = -limit; d <= limit; d += 5) {
      final major = d % 15 == 0;
      final dx = x(d.toDouble());
      tick.color = major ? colors.muted : colors.line;
      canvas.drawLine(Offset(dx, y - (major ? 5 : 2)), Offset(dx, y), tick);
      if (d != 0 && d.abs() != limit) continue;
      final label = TextPainter(
        text: TextSpan(
          text: '${d.abs()}°',
          style: labelStyle.copyWith(fontSize: 9, color: colors.muted),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final at = Offset(dx - label.width / 2, y + 1);
      if (!(at & label.size).overlaps(activeBounds.inflate(3))) {
        label.paint(canvas, at);
      }
      label.dispose();
    }
    canvas.drawPath(
      Path()..addPolygon([
        Offset(dx, y),
        Offset(dx - 3, y - 8),
        Offset(dx + 3, y - 8),
      ], true),
      Paint()..color = colors.danger,
    );
    active.paint(canvas, activeBounds.topLeft);
    active.dispose();
  }

  @override
  bool shouldRepaint(SawPreview old) =>
      old.tool != tool ||
      old.bladeView != bladeView ||
      old.feedLabel != feedLabel ||
      old.angle != angle ||
      old.angleLabel != angleLabel ||
      old.cutaway != cutaway ||
      old.colors != colors ||
      old.labelStyle != labelStyle;
}

typedef _Face = ({List<Vector3> points, Color color});

/// Splits a polygon at the blade plane (or the tabletop in the infeed view).
List<Vector3> _clip(List<Vector3> points, double Function(Vector3) distance) {
  final result = <Vector3>[];
  var a = points.last, da = distance(a);
  for (final b in points) {
    final db = distance(b);
    if ((da < 0) != (db < 0)) result.add(a + (b - a) * (da / (da - db)));
    if (db >= 0) result.add(b);
    a = b;
    da = db;
  }
  return result;
}

class _SawScene {
  _SawScene(this.canvas, this.view);
  final Canvas canvas;
  final SawPreview view;
  static const deck = Color(0xffd3dadc),
      edge = Color(0xff80919b),
      cabinet = Color(0xff526571);
  static const woodEdge = Color(0xffae865b);
  bool get cutaway =>
      view.tool == SawType.table && view.bladeView && view.cutaway;
  late final eye = view.bladeView
      ? view.bladeEye
      : Vector3(-.25, -.55, 1).normalized();
  // Keep the front edge horizontal in the plan while exposing the thickness.
  late final right = view.bladeView
      ? Vector3(-eye.y, eye.x, 0).normalized()
      : Vector3(0, eye.z, -eye.y).cross(eye).normalized();
  late final vertical = eye.cross(right);
  late final radians = view.angle * math.pi / 180;
  late final bevel = view.bladeView ? radians : 0.0;
  late final yaw = view.bladeView || view.tool == SawType.table
      ? 0.0
      : view.tool == SawType.miter
      ? radians
      : -radians;
  late final feed = Vector3(-math.sin(yaw), math.cos(yaw), 0);
  late final across = Vector3(math.cos(yaw), math.sin(yaw), 0);
  late final tilt = across * math.sin(bevel) + Vector3(0, 0, math.cos(bevel));
  late final normal = across * math.cos(bevel) - Vector3(0, 0, math.sin(bevel));
  late final bladeScale = switch (view.tool) {
    SawType.table => 1.0,
    SawType.miter => .84,
    SawType.handheld => .67,
  };
  late final pivot = switch (view.tool) {
    SawType.table => Vector3.zero(),
    SawType.miter => Vector3(0, 0, 5),
    SawType.handheld =>
      feed * (view.bladeView ? -11.0 : -8.0) + Vector3(0, 0, 1.5),
  };
  late final hubHeight = switch (view.tool) {
    SawType.table => -10.0,
    SawType.miter => 18.0,
    SawType.handheld => 12.0,
  };
  late final near = normal.dot(eye) >= 0 ? 1.0 : -1.0;
  final furniture = <_Face>[];

  Offset project(Vector3 p) => Offset(right.dot(p), -vertical.dot(p));
  Path face(List<Vector3> points) =>
      Path()..addPolygon(points.map(project).toList(), true);

  void box(
    double x0,
    double x1,
    double y0,
    double y1,
    double z0,
    double z1,
    Color top,
    Color edge,
  ) {
    final a = Vector3(x0, y0, z1), b = Vector3(x1, y0, z1);
    final c = Vector3(x1, y1, z1), d = Vector3(x0, y1, z1);
    final down = Vector3(0, 0, z0 - z1);
    final (l, r) = eye.x > 0 ? (b, c) : (d, a);
    furniture.addAll([
      (
        points: [l, r, r + down, l + down],
        color: Color.lerp(edge, Colors.black, .12)!,
      ),
      (points: [a, b, b + down, a + down], color: edge),
      (points: [a, b, c, d], color: top),
    ]);
  }

  static Offset rotate(Offset p, double angle) => Offset(
    p.dx * math.cos(angle) - p.dy * math.sin(angle),
    p.dx * math.sin(angle) + p.dy * math.cos(angle),
  );

  void prism(
    List<Offset> outline,
    double low,
    double high,
    Color top,
    Color side, {
    double rotation = 0,
    Offset center = Offset.zero,
  }) {
    final rim = [for (final local in outline) center + rotate(local, rotation)];
    Vector3 at(Offset p, double z) => Vector3(p.dx, p.dy, z);
    for (var i = 0; i < rim.length; i++) {
      final a = rim[i], b = rim[(i + 1) % rim.length], d = b - a;
      if (d.dy * eye.x - d.dx * eye.y <= 0) continue;
      final shade = .12 * d.dy.abs() / d.distance;
      furniture.add((
        points: [at(a, low), at(b, low), at(b, high), at(a, high)],
        color: Color.lerp(side, Colors.black, shade)!,
      ));
    }
    furniture.add((points: [for (final p in rim) at(p, high)], color: top));
  }

  void plate(
    Rect bounds,
    double low,
    double high,
    Color top,
    Color side, {
    double rotation = 0,
    Offset center = Offset.zero,
  }) => prism(
    [bounds.topLeft, bounds.topRight, bounds.bottomRight, bounds.bottomLeft],
    low,
    high,
    top,
    side,
    rotation: rotation,
    center: center,
  );

  void timber(
    Rect bounds,
    double low,
    double high, {
    double rotation = 0,
    Offset center = Offset.zero,
  }) {
    plate(
      bounds,
      low,
      high,
      SawPreview.wood,
      woodEdge,
      rotation: rotation,
      center: center,
    );
    for (final (start, end, row) in [
      (.03, .49, .35),
      (.30, .78, .68),
      (.69, .96, .33),
    ]) {
      final y = bounds.top + bounds.height * row;
      final left = bounds.left + bounds.width * start,
          right = bounds.left + bounds.width * end;
      final grain = [
        Offset(left, y),
        Offset((left + right) * .5, y + .15),
        Offset(right, y - .24),
        Offset((left + right) * .5, y + .52),
      ];
      furniture.add((
        points: grain.map((local) {
          final point = center + rotate(local, rotation);
          return Vector3(point.dx, point.dy, high + .01);
        }).toList(),
        color: const Color(0xffc8a371),
      ));
    }
  }

  void miterBase() {
    prism(
      const [
        Offset(-52, -13),
        Offset(-37, -19),
        Offset(37, -19),
        Offset(52, -13),
        Offset(52, 18),
        Offset(45, 23),
        Offset(-45, 23),
        Offset(-52, 18),
      ],
      -8,
      -3,
      deck,
      cabinet,
    );
    prism(circle(30, 72), -5, 0, deck, edge);
    // The locking handle, throat plate and pointer turn as a single assembly.
    prism(
      const [Offset(-3, -40), Offset(3, -40), Offset(6, -25), Offset(-6, -25)],
      -4,
      -.2,
      edge,
      cabinet,
      rotation: yaw,
    );
    plate(
      const Rect.fromLTRB(-3.8, -46, 3.8, -37),
      -4,
      0,
      cabinet,
      cabinet,
      rotation: yaw,
    );
    plate(
      const Rect.fromLTRB(-2.8, -29, 2.8, 23),
      -.2,
      .1,
      edge,
      edge,
      rotation: yaw,
    );
    if (!view.bladeView) {
      final ticks = const Color(0xff81919b);
      for (var d = -75; d <= 75; d += 5) {
        final a = d * math.pi / 180;
        plate(
          Rect.fromLTRB(-.23, -29, .23, d % 15 == 0 ? -26.0 : -27.5),
          .11,
          .12,
          ticks,
          ticks,
          rotation: a,
        );
      }
      prism(
        const [Offset(-1.8, -33), Offset(1.8, -33), Offset(0, -29.2)],
        0,
        .22,
        view.colors.danger,
        edge,
        rotation: yaw,
      );
    }
    if (view.bladeView) {
      box(-7, 7, 20, 28, 0, 11, deck, cabinet);
    }
    for (final (l, r) in [(-52.0, -4.0), (4.0, 52.0)]) {
      box(l, r, 11, 13, 0, 11, deck, edge);
    }
    timber(const Rect.fromLTRB(-55, -9, 55, 11), 0, 5);
    if (!view.bladeView) {
      final travel = math.min(
        55 / math.max(.0001, feed.x.abs()),
        (feed.y > 0 ? 11 : 9) / math.max(.0001, feed.y.abs()),
      );
      final front = math.min(
        55 / math.max(.0001, feed.x.abs()),
        9 / math.max(.0001, feed.y.abs()),
      );
      plate(
        Rect.fromLTRB(-.60, -front, .60, travel),
        5,
        5.05,
        view.colors.danger,
        view.colors.danger,
        rotation: yaw,
      );
    }
  }

  void handBase() {
    // Leave a visible stretch of the cut line ahead of the shoe in elevation.
    final board = view.bladeView
        ? const Rect.fromLTRB(-52, -38, 52, 37)
        : const Rect.fromLTRB(-52, -26, 52, 26);
    timber(board, -5, 0);
    // The shoe stays flat on the board while the blade and guard tilt together.
    final center = Offset(pivot.x, pivot.y);
    const length = 24.0;
    for (final (l, r) in [(-7.0, -1.6), (1.6, 15.0)]) {
      plate(
        Rect.fromLTRB(l, -length, r, length),
        0,
        1.6,
        deck,
        edge,
        rotation: yaw,
        center: center,
      );
    }
    for (final y in [-length, length - 2]) {
      plate(
        Rect.fromLTRB(-1.6, y, 1.6, y + 2),
        0,
        1.6,
        deck,
        edge,
        rotation: yaw,
        center: center,
      );
    }
    if (!view.bladeView) {
      final run = math.min(
        52 / math.max(.0001, feed.x.abs()),
        26 / math.max(.0001, feed.y.abs()),
      );
      plate(
        Rect.fromLTRB(-.48, -run, .48, run),
        .02,
        .03,
        view.colors.danger,
        view.colors.danger,
        rotation: yaw,
      );
    }
  }

  static const _stockCenter = Offset(0, -20);
  static const _fenceFace = 8.0, _halfStockWidth = 6.0;
  static const _slotOffset = _fenceFace + _halfStockWidth;
  double get _slotSide => radians < 0 ? 1 : -1;

  // The stock midpoint stays on the blade and the trailing long edge rests
  // against the fence. Intersect that fence position with the chosen slot.
  Offset get _gaugePivot {
    final travel =
        _slotOffset * math.cos(radians) / (1 + math.sin(radians).abs());
    return Offset(_slotSide * _slotOffset, _stockCenter.dy - travel);
  }

  void tableGauge() {
    final pivot = _gaugePivot;
    final yaw = -radians;
    const gauge = SawPreview.fence;
    box(
      pivot.dx - .7,
      pivot.dx + .7,
      pivot.dy - 3,
      pivot.dy + 12,
      .1,
      .3,
      edge,
      cabinet,
    );
    prism(
      [
        const Offset(-7.5, 5.5),
        for (var i = 0; i <= 24; i++)
          Offset.fromDirection(math.pi + i * math.pi / 24, 7.5),
        const Offset(7.5, 5.5),
      ],
      .3,
      2.1,
      gauge,
      cabinet,
      center: pivot,
      rotation: yaw,
    );

    final board = Rect.fromLTRB(-34, -_halfStockWidth, 34, _halfStockWidth);
    timber(board, 0, 4.7, center: _stockCenter, rotation: yaw);
    // Mark only the part of the blade path that falls on the top of the stock.
    final top = [
      for (final local in [
        board.topLeft,
        board.topRight,
        board.bottomRight,
        board.bottomLeft,
      ])
        _stockCenter + rotate(local, yaw),
    ];
    final stripe = _clip([
      for (final p in top) Vector3(p.dx, p.dy, 4.72),
    ], (p) => p.x + .55);
    furniture.add((
      points: _clip(stripe, (p) => .55 - p.x),
      color: EditorPalette.light.danger,
    ));

    // The short end faces the blade. Its whole sweep clears the teeth.
    final left = _slotSide > 0 ? -9.0 : -18.0;
    final right = _slotSide > 0 ? 18.0 : 9.0;
    plate(
      Rect.fromLTRB(left, 5, right, _fenceFace),
      .3,
      6.2,
      gauge,
      cabinet,
      center: pivot,
      rotation: yaw,
    );
    prism(
      circle(2, 24),
      2.1,
      3.4,
      cabinet,
      edge,
      center: pivot + rotate(const Offset(0, -3), yaw),
    );
  }

  void arrow(Offset a, Offset b, Color color) {
    final direction = (b - a) / (b - a).distance,
        side = Offset(-direction.dy, direction.dx);
    final tail = b - direction * 4;
    canvas.drawLine(
      a,
      tail,
      Paint()
        ..color = color
        ..strokeWidth = 1.5,
    );
    canvas.drawPath(
      Path()..addPolygon([b, tail + side * 2, tail - side * 2], true),
      Paint()..color = color,
    );
  }

  void planMarks() {
    final ink = Paint()
      ..color = view.colors.muted
      ..strokeWidth = .85;

    if (view.tool == SawType.miter) {
      for (var y = -35.0; y < -10; y += 4) {
        canvas.drawLine(
          project(Vector3(0, y, .3)),
          project(Vector3(0, y + 2, .3)),
          ink,
        );
      }
    } else if (view.tool == SawType.handheld) {
      final length = math.min(
        52 / math.max(.0001, feed.x.abs()),
        26 / math.max(.0001, feed.y.abs()),
      );
      arrow(
        project(feed * math.max(11, length - 9) + Vector3(0, 0, .2)),
        project(feed * length + Vector3(0, 0, .2)),
        view.colors.danger,
      );
    } else {
      if (view.angle.abs() > 2) {
        Offset reference(double length, double angle) {
          final point =
              _gaugePivot + Offset.fromDirection(angle, length * _slotSide);
          return project(Vector3(point.dx, point.dy, 6.3));
        }

        for (double d = 5; d < 15; d += 4) {
          canvas.drawLine(reference(d, 0), reference(d + 2, 0), ink);
        }
        final arc = Path()
          ..addPolygon([
            for (var i = 0; i <= 20; i++) reference(11, -radians * i / 20),
          ], false);
        canvas.drawPath(
          arc,
          Paint()
            ..color = SawPreview.fence
            ..style = PaintingStyle.stroke
            ..strokeWidth = .65,
        );
      }
    }
    final camera = view.bladeEye;
    final position = rotate(Offset(camera.x, camera.y), yaw);
    final observer = view.tool == SawType.table
        ? project(Vector3(position.dx * 55, -40, 0))
        : project(Vector3(position.dx * 59, position.dy * 50, 0));
    canvas.save();
    canvas.translate(observer.dx, observer.dy);
    canvas.scale(.70);
    _drawSight(canvas, Offset.zero, -observer / observer.distance, view.colors);
    canvas.restore();
  }

  void tableFeedMark() {
    // Both blade views show the same feed direction on the tabletop. Put
    // the arrow on the visible side of the blade and inside the cutaway.
    final x = view.bladeView ? (eye.x > 0 ? 31.0 : -31.0) : -_slotSide * 40;
    final start = Vector3(x, view.bladeView ? (cutaway ? 2 : -17) : -6, .4);
    final a = project(start), b = project(start + feed * 22);
    arrow(a, b, SawPreview.fence);
    final label = TextPainter(
      text: TextSpan(
        text: view.feedLabel,
        style: view.labelStyle.copyWith(
          fontSize: 6.3,
          color: view.colors.ink,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final at = a + Offset(-label.width / 2, 1);
    if (view.bladeView) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          (at & label.size).inflate(.7),
          const Radius.circular(1.8),
        ),
        Paint()..color = view.colors.paper,
      );
    }
    label.paint(canvas, at);
    label.dispose();
  }

  /// All castings use the blade's local frame. The guard and handle move
  /// with the arbor, while the shoe, fence and workpiece stay on the table.
  void toolHead({required bool nearSide}) {
    final hand = view.tool == SawType.handheld;
    final cap = const Color(0xff849da9), ridge = const Color(0xffb3c3ca);
    const grip = Color(0xff435761), side = Color(0xff647d8a);
    // Intervals here use the physical arbor axis. Extrusions below are
    // ordered from the far side of the saw toward this particular observer.
    void shell(
      List<Offset> outline,
      double lo,
      double hi,
      Color paint, {
      Color wall = side,
    }) {
      final a = lo * near, b = hi * near;
      extrusion(
        outline,
        math.min(a, b),
        math.max(a, b),
        paint,
        wallColor: wall,
      );
    }

    List<Offset> arc(double r, double first, double last, int count) => [
      for (var i = 0; i <= count; i++)
        Offset.fromDirection(first + (last - first) * i / count, r),
    ];
    if (!nearSide) {
      if (near < 0) {
        shell(circle(10, 40), 4, 18, side);
        shell(circle(8.5, 40), 18, 19, grip);
      }
      if (!hand) {
        shell(
          const [
            Offset(3, 3),
            Offset(17, 8),
            Offset(36, -4),
            Offset(39, -19),
            Offset(32, -22),
            Offset(28, -10),
            Offset(10, -2),
          ],
          -2,
          5,
          side,
        );
      }
      final handle = hand
          ? const [
              Offset(-27, 4),
              Offset(-32, 11),
              Offset(-27, 28),
              Offset(-16, 39),
              Offset(4, 39),
              Offset(11, 31),
              Offset(5, 26),
              Offset(0, 32),
              Offset(-13, 32),
              Offset(-21, 24),
              Offset(-25, 12),
              Offset(-20, 8),
            ]
          : const [
              Offset(-12, 27),
              Offset(-39, 30),
              Offset(-47, 25),
              Offset(-48, 12),
              Offset(-42, 8),
              Offset(-21, 11),
              Offset(-20, 15),
              Offset(-39, 15),
              Offset(-42, 18),
              Offset(-37, 23),
              Offset(-14, 20),
            ];
      shell(handle, -2.4, 3.6, grip, wall: side);
      return;
    }

    final guard = [
      ...arc(29.5, -.08, math.pi + .08, 50),
      const Offset(-24, -2),
      const Offset(-16, 4),
      const Offset(-5, 8),
      const Offset(6, 8),
      const Offset(18, 4),
      const Offset(25, -2),
    ];
    // Only the upper half of the blade is covered by this housing.
    extrusion(guard, -3.2, 3.2, cap, wallColor: side);
    extrusion(
      [
        ...arc(27, .28, math.pi - .28, 38),
        ...arc(25.7, math.pi - .28, .28, 38),
      ],
      3.2,
      3.65,
      ridge,
      wallColor: cap,
    );
    if (near > 0) {
      shell(circle(10, 40), 4, 18, side);
      shell(circle(8.5, 40), 18, 19, grip);
    }
  }

  void tableBase() {
    final front = cutaway
        ? 0.0
        : view.bladeView
        ? -32.0
        : -39.0;
    if (cutaway) {
      box(-46, 46, 27, 29, -23, -3, cabinet, cabinet);
      for (final x in [-45.0, 43.0]) {
        box(x, x + 2, 1, 28, -23, -3, cabinet, cabinet);
      }
    } else {
      box(-48, 48, -28, 28, -15, -3, cabinet, cabinet);
    }
    for (final (left, right) in [(-53.0, -4.2), (4.2, 53.0)]) {
      box(left, right, front, 32, -3, 0, deck, edge);
    }
    box(-4.2, 4.2, 27, 32, -3, 0, deck, edge);
    if (!cutaway) box(-4.2, 4.2, front, -27, -3, 0, deck, edge);
    for (final (l, r) in [(-4.2, -2.1), (2.1, 4.2)]) {
      box(
        l,
        r,
        math.max(front, -27),
        27,
        -1,
        .04,
        const Color(0xffb4c0c5),
        edge,
      );
    }
    for (final x in [-_slotOffset, _slotOffset]) {
      box(x - .85, x + .85, front, 32, .04, .07, const Color(0xff98a7ae), edge);
    }
  }

  void draw() {
    switch (view.tool) {
      case SawType.table:
        tableBase();
        if (!view.bladeView) tableGauge();
      case SawType.miter:
        miterBase();
      case SawType.handheld:
        handBase();
    }
    for (final f in furniture) {
      canvas.drawPath(face(f.points), Paint()..color = f.color);
    }
    if (view.tool == SawType.handheld && view.bladeView) {
      final besideShoe = across * -22;
      arrow(
        project(besideShoe + feed * 9),
        project(besideShoe + feed * 32),
        EditorPalette.light.danger,
      );
    }
    if (view.tool != SawType.miter || view.bladeView) blade();

    // The table can hide the lower blade. On portable and miter saws the
    // head sits above the stock, and is clipped at its upper surface.
    if (view.tool == SawType.table) {
      for (final f in furniture) {
        final points = _clip(f.points, (p) => normal.dot(p - pivot) * near);
        if (points.length >= 3) {
          canvas.drawPath(face(points), Paint()..color = f.color);
        }
      }
    }
    if (!view.bladeView) planMarks();
    if (view.tool == SawType.table) tableFeedMark();
  }

  // Profile coordinates are measured along the feed and up the blade face.
  Vector3 bladePoint(Offset p, double axial) =>
      pivot +
      tilt * (p.dy * bladeScale + hubHeight) +
      feed * (p.dx * bladeScale) +
      normal * (axial * bladeScale);

  static List<Offset> circle(double radius, int count) => [
    for (var i = 0; i < count; i++)
      Offset.fromDirection(i * 2 * math.pi / count, radius),
  ];
  static final teeth = [
    for (var i = 0; i < 42; i++)
      for (final (phase, radius) in [
        (0.0, 25.4),
        (.33, 26.0),
        (.48, 28.0),
        (.68, 28.0),
        (.8, 25.4),
      ])
        Offset.fromDirection(2 * math.pi * (i + phase) / 42, radius),
  ];

  void extrusion(
    List<Offset> outline,
    double back,
    double front,
    Color color, {
    bool steel = false,
    Color wallColor = const Color(0xff657782),
  }) {
    List<Vector3> visible(List<Vector3> points) => cutaway
        ? points
        : _clip(points, (p) => p.z - (view.tool == SawType.miter ? 5.0 : 0.0));
    final farPoints = [for (final p in outline) bladePoint(p, back * near)];
    final nearPoints = [for (final p in outline) bladePoint(p, front * near)];
    final walls = Path();
    for (var i = 0; i < outline.length; i++) {
      final j = (i + 1) % outline.length;
      final points = visible([
        farPoints[i],
        farPoints[j],
        nearPoints[j],
        nearPoints[i],
      ]);
      if (points.length >= 3) {
        final vertices = points.map(project).toList();
        // Matching winding keeps the edge solid even when seen edge-on.
        final ab = vertices[1] - vertices[0], ac = vertices.last - vertices[0];
        walls.addPolygon(
          ab.dx * ac.dy < ab.dy * ac.dx ? vertices.reversed.toList() : vertices,
          true,
        );
      }
    }
    canvas.drawPath(walls, Paint()..color = wallColor);
    final points = visible(nearPoints);
    if (points.length < 3) return;
    final path = face(points);
    final paint = Paint()..color = color;
    if (steel) {
      final hub = project(bladePoint(Offset.zero, front * near));
      paint.shader = const SweepGradient(
        colors: [
          Color(0xffa2afb7),
          Color(0xffdde4e6),
          Color(0xff93a4af),
          Color(0xffd4dde1),
          Color(0xffa2afb7),
        ],
        transform: GradientRotation(.5),
      ).createShader(Rect.fromCircle(center: hub, radius: 28));
    }
    canvas.drawPath(path, paint);
    if (steel) {
      canvas.save();
      canvas.clipPath(path);
      final ring = face([
        for (final p in circle(21, 80)) bladePoint(p, front * near),
      ]);
      canvas.drawPath(
        ring,
        Paint()
          ..color = const Color(0xff9aa9b1)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .30,
      );
      canvas.restore();
    }
  }

  void blade() {
    const darkSteel = Color(0xff657782);
    if (view.tool != SawType.table) toolHead(nearSide: false);
    final shaft = circle(1.9, 24), bolt = circle(3, 6), flange = circle(5, 40);
    const pin = Color(0xff7d8e97),
        hex = Color(0xffbdc8cc),
        washer = Color(0xff929fa7);
    extrusion(shaft, -6.8, -2.1, pin);
    extrusion(bolt, -2.1, -1.15, hex);
    extrusion(flange, -1.15, -.55, washer);
    extrusion(teeth, -.55, .55, darkSteel, steel: true);
    extrusion(flange, .55, 1.15, washer);
    extrusion(bolt, 1.15, 2.1, hex);
    extrusion(shaft, 2.1, 6.8, pin);
    if (view.tool != SawType.table) toolHead(nearSide: true);
  }
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
