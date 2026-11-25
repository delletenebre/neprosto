import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoIcons;
import 'package:material_ui/material_ui.dart';

import '../l10n/strings.dart';
import 'controller.dart';
import 'grid_visibility.dart';
import 'palette.dart';

class WorkPlanePicker extends StatelessWidget {
  const WorkPlanePicker(this.editor, {super.key});

  final Editor editor;

  @override
  Widget build(BuildContext context) {
    final s = context.strings, colors = context.colors;
    final current = GridPlane.values
        .where((plane) => plane.axes == editor.plane.name)
        .firstOrNull;
    final title = editor.plane.displayName;
    final label = s.workPlaneLabel(title);
    final canPickFace = editor.project.visibleGeometry.beams.isNotEmpty;

    Widget icon(GridPlane? plane, double size) => plane == null
        ? Icon(CupertinoIcons.scope, size: size, color: colors.muted)
        : CustomPaint(
            size: Size.square(size),
            painter: _PlaneDiagram(plane, colors),
          );

    PopupMenuItem<void> option({
      GridPlane? plane,
      required String title,
      required String hint,
      required VoidCallback choose,
      bool enabled = true,
    }) => PopupMenuItem<void>(
      enabled: enabled,
      onTap: choose,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Semantics(
        selected: current == plane,
        child: Row(
          spacing: 10,
          children: [
            icon(plane, 32),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: enabled ? colors.ink : colors.muted,
                    ),
                  ),
                  Text(
                    hint,
                    style: TextStyle(fontSize: 12, color: colors.muted),
                  ),
                ],
              ),
            ),
            if (plane != null)
              Text(
                plane.axes,
                style: TextStyle(fontSize: 11, color: colors.muted),
              ),
            SizedBox(
              width: 16,
              child: current == plane
                  ? Icon(
                      CupertinoIcons.check_mark,
                      size: 16,
                      color: colors.accent,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );

    return Material(
      color: colors.field,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: colors.line, width: .8),
      ),
      child: PopupMenuButton<void>(
        tooltip: label,
        position: PopupMenuPosition.under,
        offset: const Offset(0, 3),
        constraints: const BoxConstraints.tightFor(width: 312),
        borderRadius: BorderRadius.circular(6),
        color: colors.field,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: colors.line, width: .8),
        ),
        itemBuilder: (_) => [
          PopupMenuItem<void>(
            enabled: false,
            height: 32,
            child: Text(
              s.workPlanePurpose,
              style: TextStyle(fontSize: 12, color: colors.muted),
            ),
          ),
          for (final plane in GridPlane.values)
            option(
              plane: plane,
              title: plane.plane.displayName,
              hint: switch (plane) {
                GridPlane.xy => s.horizontalPlaneExample,
                GridPlane.xz => s.frontPlaneExample,
                GridPlane.yz => s.sidePlaneExample,
              },
              choose: () => editor.setPlane(plane.plane),
            ),
          const PopupMenuDivider(height: 9),
          option(
            title: s.partFacePlane,
            hint: canPickFace ? s.selectWorkPlaneFace : s.workPlaneNeedsPart,
            enabled: canPickFace,
            choose: () => editor.setTool(Tool.face),
          ),
        ],
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4.5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 5,
            children: [
              icon(current, 19),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colors.ink,
                  ),
                ),
              ),
              Icon(CupertinoIcons.chevron_down, size: 11, color: colors.muted),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaneDiagram extends CustomPainter {
  const _PlaneDiagram(this.plane, this.colors);
  final GridPlane plane;
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
    for (final entry in faces.entries) {
      final path = Path()..addPolygon(entry.value, true);
      canvas.drawPath(
        path,
        Paint()
          ..color = entry.key == plane ? EditorPalette.highlight : colors.panel,
      );
      canvas.drawPath(path, outline);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PlaneDiagram old) =>
      old.plane != plane || old.colors != colors;
}
