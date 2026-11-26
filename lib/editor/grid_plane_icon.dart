import 'package:material_ui/material_ui.dart';

import 'grid_visibility.dart';
import 'desktop.dart';
import 'palette.dart';

class GridPlaneIcon extends StatelessWidget {
  const GridPlaneIcon(
    this.plane, {
    required this.size,
    this.axisGrid = false,
    super.key,
  });

  final GridPlane plane;
  final double size;
  final bool axisGrid;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: _PlaneDiagram(plane, axisGrid, context.colors),
  );
}

class RotationPlanePicker extends StatelessWidget {
  const RotationPlanePicker(this.axis, this.onChanged, {super.key});
  final int axis;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => DeskSegmentedControl<int>(
    value: axis,
    change: onChanged,
    children: {
      for (final (i, p) in [
        (2, GridPlane.xy),
        (1, GridPlane.xz),
        (0, GridPlane.yz),
      ])
        i: Tooltip(
          message: '${p.axes} · ${p.label}',
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: 4,
                children: [
                  GridPlaneIcon(p, size: 21),
                  Text(p.axes, style: const TextStyle(fontSize: 11)),
                ],
              ),
            ),
          ),
        ),
    },
  );
}

class _PlaneDiagram extends CustomPainter {
  const _PlaneDiagram(this.plane, this.axisGrid, this.colors);
  final GridPlane plane;
  final bool axisGrid;
  final EditorPalette colors;

  // All three views use the same cabinet, with its wider front facing right.
  static const faces = {
    GridPlane.xy: [Offset(2, 9), Offset(22, 4), Offset(32, 10), Offset(12, 15)],
    GridPlane.xz: [
      Offset(12, 15),
      Offset(32, 10),
      Offset(32, 28),
      Offset(12, 33),
    ],
    GridPlane.yz: [Offset(2, 9), Offset(12, 15), Offset(12, 33), Offset(2, 27)],
  };

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 35, size.height / 35);
    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 1.2
      ..color = colors.muted;
    final offset = axisGrid
        ? switch (plane) {
            GridPlane.xy => const Offset(0, 18),
            GridPlane.xz => const Offset(-10, -6),
            GridPlane.yz => Offset.zero,
          }
        : Offset.zero;
    if (offset != Offset.zero) {
      final face = (Path()..addPolygon(faces[plane]!, true)).shift(offset);
      canvas.drawPath(face, Paint()..color = EditorPalette.highlight);
      canvas.drawPath(face, outline);
    }
    for (final entry in faces.entries) {
      final path = Path()..addPolygon(entry.value, true);
      if (offset == Offset.zero) {
        canvas.drawPath(
          path,
          Paint()
            ..color = entry.key == plane
                ? EditorPalette.highlight
                : colors.panel,
        );
      }
      canvas.drawPath(path, outline);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PlaneDiagram old) =>
      old.plane != plane || old.axisGrid != axisGrid || old.colors != colors;
}
