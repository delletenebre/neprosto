import 'package:material_ui/material_ui.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart'
    show PhosphorIconsRegular;

import 'scene.dart';

class ViewAngleIcon extends StatelessWidget {
  const ViewAngleIcon(this.angle, {required this.color, super.key});

  final ViewAngle angle;
  final Color color;

  @override
  Widget build(BuildContext context) => switch (angle) {
    ViewAngle.perspective => Icon(
      PhosphorIconsRegular.perspective,
      size: 16,
      color: color,
    ),
    ViewAngle.iso => Icon(PhosphorIconsRegular.cube, size: 16, color: color),
    _ => CustomPaint(
      size: const Size.square(19),
      painter: _CubeFaceIcon(angle, color),
    ),
  };
}

class _CubeFaceIcon extends CustomPainter {
  const _CubeFaceIcon(this.angle, this.color);
  final ViewAngle angle;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    if (angle == ViewAngle.left) {
      canvas.translate(24, 0);
      canvas.scale(-1, 1);
    } else if (angle == ViewAngle.bottom) {
      canvas.translate(0, 24);
      canvas.scale(1, -1);
    }

    const front = Rect.fromLTWH(2, 8, 14, 14);
    const back = Rect.fromLTWH(8, 2, 14, 14);
    final top = Path()
      ..addPolygon([
        front.topLeft,
        back.topLeft,
        back.topRight,
        front.topRight,
      ], true);
    final right = Path()
      ..addPolygon([
        front.topRight,
        back.topRight,
        back.bottomRight,
        front.bottomRight,
      ], true);
    final face = switch (angle) {
      ViewAngle.top || ViewAngle.bottom => top,
      ViewAngle.left || ViewAngle.right => right,
      ViewAngle.back => Path()..addRect(back),
      _ => Path()..addRect(front),
    };
    canvas.drawPath(face, Paint()..color = color.withValues(alpha: .42));
    final edge = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 1.45;
    canvas.drawRect(front, edge);
    canvas.drawPath(top, edge);
    canvas.drawPath(right, edge);
    if (angle == ViewAngle.back) {
      // Show the two hidden edges of the selected rear face through the cube.
      final hidden = Path();
      for (var offset = 0.0; offset < back.width; offset += 4) {
        hidden.moveTo(back.left, back.bottom - offset);
        hidden.relativeLineTo(0, -2);
        hidden.moveTo(back.left + offset, back.bottom);
        hidden.relativeLineTo(2, 0);
      }
      canvas.drawPath(hidden, edge);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CubeFaceIcon old) =>
      old.angle != angle || old.color != color;
}
