import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../l10n/strings.dart';
import 'contact.dart';
import 'controller.dart';
import 'controls.dart';
import 'desktop.dart';
import 'drawing.dart';
import 'joint.dart';
import 'model.dart';
import 'palette.dart';
import 'scene.dart';
import 'step.dart';

Future<void> showPartJoint(BuildContext context, Editor editor) async {
  if (editor.selection.length != 2) return;
  final pair = editor.selection.map((id) => editor.project.byId[id]!).toList();
  final result = await showDeskDialog<List<JointCut>>(
    context: context,
    builder: (_) => JointDialog(pair[0], pair[1]),
  );
  if (result == null ||
      !context.mounted ||
      pair.any((b) => editor.project.byId[b.id] != b)) {
    return;
  }
  final changes = {for (final cut in result) cut.part.id: cut.part};
  editor.commit(
    editor.project.edit(changes.keys.toSet(), (b) => changes[b.id]!),
  );
}

class JointDialog extends StatefulWidget {
  final Beam a, b;
  const JointDialog(this.a, this.b, {super.key});

  @override
  State<JointDialog> createState() => _JointDialogState();
}

class _JointDialogState extends State<JointDialog> {
  late final List<JointCut>? ends;
  late final List<FaceJoint> faces;
  FaceJoint? face;
  bool byFace = false;

  @override
  void initState() {
    super.initState();
    ends = endJointOption(widget.a, widget.b);
    faces = faceJointOptions(widget.a, widget.b);
    face = faces.firstOrNull;
    byFace = ends == null && face != null;
  }

  String partLabel(Beam part) => widget.a.name != widget.b.name
      ? part.name
      : '${part.id == widget.a.id ? 1 : 2} · ${part.name}';

  String faceLabel(int face) {
    final s = context.strings;
    return switch (face) {
      2 => s.frontEdge,
      3 => s.backEdge,
      4 => s.jointBottomFace,
      _ => s.jointTopFace,
    };
  }

  Widget _partRow(Beam part, String detail, {Widget? trailing}) => Row(
    spacing: controlGap,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: part.name,
              child: Text(
                partLabel(part),
                style: const TextStyle(fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              detail,
              style: TextStyle(fontSize: 11, color: context.colors.muted),
            ),
          ],
        ),
      ),
      ?trailing,
    ],
  );

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final colors = context.colors;
    final input = Units.of(context);
    final angle = Units.angleOf(context);
    final option = byFace ? face : null;
    final cuts = option == null ? ends : [option.cut];
    final inside = ends != null && !byFace
        ? jointInsideAngle(
            ends!.first.part,
            ends!.first.end,
            ends!.last.part,
            ends!.last.end,
          )
        : null;
    return DeskDialog(
      title: Text(s.miterJoint),
      maxWidth: 520,
      content: SizedBox(
        width: 488,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: controlGap,
          children: [
            if (cuts == null)
              Text(
                intersects(widget.a, widget.b)
                    ? s.jointNoAvailableCut
                    : s.jointNeedsOverlap,
              )
            else ...[
              if (ends != null && faces.isNotEmpty)
                DeskSegments(byFace, {
                  false: s.jointEndToEnd,
                  true: s.jointEndToFace,
                }, (value) => setState(() => byFace = value))
              else
                Text(
                  byFace ? s.jointEndToFace : s.jointEndToEnd,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              _JointDrawing(cuts: cuts, support: option?.support),
              Wrap(
                spacing: 14,
                runSpacing: controlGap,
                children: [
                  _legend(s.jointCutLine, colors.accent),
                  _legend(s.jointOffcut, colors.danger),
                  if (inside != null)
                    Text(
                      '${s.insideAngle} · ${angle.format(inside)}°',
                      style: TextStyle(fontSize: 11, color: colors.muted),
                    ),
                ],
              ),
              if (option != null)
                _partRow(
                  option.support,
                  '${s.referencePart} · ${faceLabel(option.face)}',
                  trailing: faces.length < 2
                      ? null
                      : Flexible(
                          child: MenuChoice<int>(
                            selected: faces.indexOf(option),
                            label: s.jointChooseFace,
                            items: [
                              for (final (index, other) in faces.indexed)
                                (
                                  index,
                                  '${partLabel(other.support)} · ${faceLabel(other.face)}',
                                ),
                            ],
                            change: (index) =>
                                setState(() => face = faces[index]),
                          ),
                        ),
                ),
              Text(
                s.shortAndLongEdgeLengths(input.unit.symbol),
                style: TextStyle(fontSize: 12, color: colors.muted),
              ),
              for (final cut in cuts)
                Builder(
                  builder: (_) {
                    final lengths = edgeLengths(cut.part)..sort();
                    final saw = sawAngles(cut.part, cut.end);
                    final blade = angle.format(saw.bevel);
                    return _partRow(
                      cut.part,
                      [
                        cut.end ? s.endCut : s.startCut,
                        '${s.sawTableRotation} ${angle.format(saw.miter)}°',
                        if (blade != '0') '${s.sawBladeTilt} $blade°',
                      ].join(' · '),
                      trailing: Text(
                        '${input.format(lengths.first)} / ${input.format(lengths.last)}',
                        style: mono,
                      ),
                    );
                  },
                ),
            ],
          ],
        ),
      ),
      actions: [
        DeskButton(
          plain: true,
          onPressed: () => Navigator.pop(context),
          child: Text(s.cancel),
        ),
        DeskButton(
          primary: true,
          onPressed: cuts == null ? null : () => Navigator.pop(context, cuts),
          child: Text(s.jointApplyCut),
        ),
      ],
    );
  }

  Widget _legend(String label, Color color) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: 5,
    children: [
      SizedBox(width: 12, height: 3, child: ColoredBox(color: color)),
      Text(label, style: TextStyle(fontSize: 11, color: context.colors.muted)),
    ],
  );
}

class _JointDrawing extends StatelessWidget {
  const _JointDrawing({required this.cuts, required this.support});

  final List<JointCut> cuts;
  final Beam? support;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 185,
    child: ClipRect(
      child: LayoutBuilder(
        builder: (_, box) {
          final parts = [for (final cut in cuts) cut.part, ?support];
          final first = cuts.first;
          final a = first.part, b = parts.last;
          final cross = a.along.cross(b.along);
          final normal = cross.length2 > 1e-8 ? cross.normalized() : a.up;
          final center = faceCenter(a, 0, first.end);
          final camera = Camera()
            ..facePlane(WorkPlane('', center, a.along, normal.cross(a.along)))
            ..orbitAroundAxis(a.along, .34, center);
          final size = box.biggest;
          final span = parts
              .map((b) => math.max(b.size.y, b.size.z))
              .reduce(math.max);
          final detail = [
            for (final cut in cuts) ...[
              for (final i in faceCorners[cut.end ? 1 : 0]) cut.part.corner(i),
              faceCenter(cut.part, 0, cut.end) +
                  cut.part.along *
                      (cut.end ? -1.0 : 1.0) *
                      math.min(cut.part.size.x, span * 1.8),
              faceCenter(cut.part, 0, cut.end) -
                  cut.part.along *
                      (cut.end ? -1.0 : 1.0) *
                      math.min(jointOffcutDepth(cut), span * 1.3),
            ],
            if (support != null) ...[
              center - support!.along * span,
              center + support!.along * span,
            ],
          ];
          camera.fitPoints(detail, size);
          final scene = Scene(Project('', parts), camera, size);
          return ColoredBox(
            color: context.colors.paper,
            child: CustomPaint(
              painter: DrawingPainter(
                colors: context.colors,
                scene: scene,
                selection: {},
                dimensions: false,
              ),
              foregroundPainter: _JointMarks(cuts, camera, context.colors),
            ),
          );
        },
      ),
    ),
  );
}

class _JointMarks extends CustomPainter {
  _JointMarks(this.cuts, this.camera, this.colors);

  final List<JointCut> cuts;
  final Camera camera;
  final EditorPalette colors;

  @override
  void paint(Canvas canvas, Size size) {
    for (final cut in cuts) {
      if (jointOffcutDepth(cut) > 1e-6) {
        final normal = cut.part.faceNormal(cut.end ? 1 : 0);
        final at = faceCenter(cut.part, 0, cut.end);
        final scene = Scene(Project('', [cut.stock]), camera, size);
        var silhouette = Path();
        for (final face in scene.faces) {
          final polygon = clipPolygon(face.world, (p) => (p - at).dot(normal));
          if (polygon.length < 3) continue;
          silhouette = Path.combine(
            PathOperation.union,
            silhouette,
            Path()..addPolygon([
              for (final p in polygon) camera.project(p, size),
            ], true),
          );
        }
        canvas.drawPath(
          silhouette,
          Paint()..color = colors.danger.withValues(alpha: .24),
        );
        canvas.drawPath(
          silhouette,
          Paint()
            ..color = colors.danger
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.3,
        );
      }
    }
    for (final cut in cuts) {
      EndFaceOutline(
        cut.part,
        cut.end,
        camera,
        colors.accent,
      ).paint(canvas, size);
    }
  }

  @override
  bool shouldRepaint(_JointMarks old) => true;
}
