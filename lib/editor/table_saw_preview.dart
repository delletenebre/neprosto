import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'model.dart' show Vector3;
import 'palette.dart';

/// Orthographic view of the blade, with the bevel measured from vertical.
class TableSawPreview extends CustomPainter {
  const TableSawPreview(this.angle, this.cutaway, this.colors, this.labelStyle);

  final double angle;
  final bool cutaway;
  final EditorPalette colors;
  final TextStyle labelStyle;

  static Vector3 viewpoint(bool cutaway) =>
      (cutaway ? Vector3(.97, -.86, .36) : Vector3(-.58, -1, .60)).normalized();

  @override
  void paint(Canvas canvas, Size size) {
    final height = size.height - 25;
    final scale = math.min((size.width - 8) / 127, height / 66);
    if (scale <= 0) return;
    canvas.save();
    canvas.translate(size.width / 2, height * (cutaway ? .46 : .52));
    canvas.scale(scale);
    _TableScene(canvas, angle, cutaway).draw();
    canvas.restore();

    final limit = math.max(45, (angle.abs() / 15).ceil() * 15);
    final half = math.min(size.width * .40, 90.0);
    double x(double degrees) => size.width / 2 + degrees / limit * half;
    final tick = Paint()..strokeWidth = .9;
    final y = height + 8;
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
      label.paint(canvas, Offset(dx - label.width / 2, y + 1));
      label.dispose();
    }
    final dx = x(angle);
    canvas.drawPath(
      Path()..addPolygon([
        Offset(dx, y),
        Offset(dx - 3, y - 8),
        Offset(dx + 3, y - 8),
      ], true),
      Paint()..color = colors.danger,
    );
  }

  @override
  bool shouldRepaint(TableSawPreview old) =>
      old.angle != angle ||
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

class _TableScene {
  _TableScene(this.canvas, double degrees, this.cutaway)
    : radians = degrees * math.pi / 180;
  final Canvas canvas;
  final double radians;
  final bool cutaway;
  late final eye = TableSawPreview.viewpoint(cutaway);
  late final right = Vector3(-eye.y, eye.x, 0).normalized();
  late final vertical = eye.cross(right);
  late final tilt = Vector3(math.sin(radians), 0, math.cos(radians));
  late final normal = Vector3(tilt.z, 0, -tilt.x);
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

  void draw() {
    const deck = Color(0xffd3dadc), edge = Color(0xff80919b);
    const cabinet = Color(0xff526571);
    final front = cutaway ? 0.0 : -32.0;
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
    if (!cutaway) box(-4.2, 4.2, -32, -27, -3, 0, deck, edge);
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
    for (final x in [-36.0, 36.0]) {
      box(x, x + .65, front, 32, .04, .07, const Color(0xff98a7ae), edge);
    }

    // Split the tabletop and stand at the blade. Both halves retain their
    // depth order, including when the observer sees the other blade face.
    void drawFurniture(double side) {
      for (final f in furniture) {
        final points = _clip(f.points, (p) => normal.dot(p) * near * side);
        if (points.length >= 3)
          canvas.drawPath(face(points), Paint()..color = f.color);
      }
    }

    drawFurniture(-1);
    blade();
    drawFurniture(1);
  }

  // In blade coordinates x is along the feed, y points toward the teeth at
  // the top and the arbor is ten units below the tabletop.
  Vector3 bladePoint(Offset p, double axial) =>
      tilt * (p.dy - 10) + Vector3(0, p.dx, 0) + normal * axial;

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

  void blade() {
    const darkSteel = Color(0xff657782);
    void cylinder(
      List<Offset> outline,
      double back,
      double front,
      Color color, {
      bool steel = false,
    }) {
      List<Vector3> visible(List<Vector3> points) =>
          cutaway ? points : _clip(points, (p) => p.z);
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
          final ab = vertices[1] - vertices[0],
              ac = vertices.last - vertices[0];
          walls.addPolygon(
            ab.dx * ac.dy < ab.dy * ac.dx
                ? vertices.reversed.toList()
                : vertices,
            true,
          );
        }
      }
      canvas.drawPath(walls, Paint()..color = darkSteel);
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

    final shaft = circle(1.9, 24), bolt = circle(3, 6), flange = circle(5, 40);
    const pin = Color(0xff7d8e97),
        hex = Color(0xffbdc8cc),
        washer = Color(0xff929fa7);
    cylinder(shaft, -6.8, -2.1, pin);
    cylinder(bolt, -2.1, -1.15, hex);
    cylinder(flange, -1.15, -.55, washer);
    cylinder(teeth, -.55, .55, darkSteel, steel: true);
    cylinder(flange, .55, 1.15, washer);
    cylinder(bolt, 1.15, 2.1, hex);
    cylinder(shaft, 2.1, 6.8, pin);
  }
}
