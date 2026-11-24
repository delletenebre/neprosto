import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../l10n/strings.dart';
import 'arithmetic.dart';
import 'controller.dart';
import 'desk_text_field.dart';
import 'desktop.dart';
import 'drawing.dart';
import 'joint.dart';
import 'model.dart';
import 'palette.dart';
import 'scene.dart';

Future<void> showEndCuts(
  BuildContext context,
  Editor editor,
  Beam part, {
  bool? end,
}) async {
  final result = await showDeskDialog<Beam>(
    context: context,
    builder: (_) => _EndCutDialog(
      part,
      editor.camera,
      editor.project.unit,
      end ??
          (part.startCut == (y: 0.0, z: 0.0) &&
              part.endCut != (y: 0.0, z: 0.0)),
    ),
  );
  if (result == null ||
      !context.mounted ||
      editor.project.byId[part.id] != part ||
      (part.startCut == result.startCut && part.endCut == result.endCut)) {
    return;
  }
  editor.commit(editor.project.edit({part.id}, (_) => result));
}

class _EndCutDialog extends StatefulWidget {
  const _EndCutDialog(this.part, this.camera, this.unit, this.initialEnd);
  final Beam part;
  final Camera camera;
  final LengthUnit unit;
  final bool initialEnd;
  @override
  State<_EndCutDialog> createState() => _EndCutDialogState();
}

// An untouched field retains the exact plane from a template or saved file.
class _MarkField {
  _MarkField(this.originalOffset, this.span) {
    final angle = markingAngle(originalOffset, span);
    final rounded = mm(angle);
    initialText =
        (angle != 0 && rounded == '0') || double.parse(rounded).abs() == 90
        ? angle.toString()
        : rounded;
    text = TextEditingController(text: initialText);
  }
  final double originalOffset, span;
  late final String initialText;
  late final TextEditingController text;

  double get offset {
    final value = text.text.trim().replaceAll(',', '.').replaceAll('−', '-');
    if (value == initialText) return originalOffset;
    final degrees = calculate(value);
    return degrees == null ? 0 : markingOffset(degrees, span) ?? 0;
  }
}

class _EndCutDialogState extends State<_EndCutDialog> {
  late bool end = widget.initialEnd;
  late final fields = [
    for (final cut in [widget.part.startCut, widget.part.endCut])
      (
        width: _MarkField(cut.y, widget.part.size.y),
        thickness: _MarkField(cut.z, widget.part.size.z),
      ),
  ];

  @override
  void dispose() {
    for (final f in fields) {
      f.width.text.dispose();
      f.thickness.text.dispose();
    }
    super.dispose();
  }

  Widget marking(_MarkField f, String label) {
    final colors = context.colors, offset = f.offset;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.paper,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 5),
            Semantics(
              label: label,
              child: DeskTextField(
                key: ObjectKey(f),
                controller: f.text,
                placeholder: '0',
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                  decimal: true,
                ),
                onChanged: (_) => setState(() {}),
                suffix: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text('°'),
                ),
              ),
            ),
            SizedBox(
              height: 78,
              child: CustomPaint(
                painter: _MarkDiagram(
                  offset / f.span,
                  end,
                  colors,
                  DefaultTextStyle.of(context).style,
                ),
              ),
            ),
            Text(
              context.strings.angleToLongEdge(
                mm(90 - markingAngle(offset, f.span).abs()),
              ),
              style: TextStyle(fontSize: 12, color: colors.muted),
            ),
            Text(
              context.strings.cutOffsetReadout(
                '${widget.unit.format(offset)} ${widget.unit.symbol}',
              ),
              style: TextStyle(fontSize: 12, color: colors.muted),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.strings, colors = context.colors;
    final current = fields[end ? 1 : 0];
    final cuts = [
      for (final f in fields) (y: f.width.offset, z: f.thickness.offset),
    ];
    final draft = widget.part.copy(startCut: cuts.first, endCut: cuts.last);
    final part = draft.size.x >= draft.minimumLength ? draft : null;
    return DeskDialog(
      title: Text(strings.endCutsTitle),
      maxWidth: 540,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          Text(widget.part.name, style: TextStyle(color: colors.muted)),
          DeskSegments<bool>(end, {
            false: strings.start,
            true: strings.endPoint,
          }, (value) => setState(() => end = value)),
          SizedBox(
            height: 92,
            child: part == null
                ? Center(
                    child: Text(
                      strings.cutsIntersect,
                      style: TextStyle(color: colors.danger),
                    ),
                  )
                : LayoutBuilder(
                    builder: (_, box) {
                      final camera = widget.camera.copy()
                        ..fitPoints(part.corners, box.biggest);
                      camera.scale *= 1.15;
                      return CustomPaint(
                        painter: DrawingPainter(
                          colors: colors,
                          scene: Scene(
                            Project('', [part]),
                            camera,
                            box.biggest,
                          ),
                          selection: {},
                          dimensions: false,
                        ),
                        foregroundPainter: EndFaceOutline(
                          part,
                          end,
                          camera,
                          colors.danger,
                        ),
                      );
                    },
                  ),
          ),
          LayoutBuilder(
            builder: (_, box) {
              final face = marking(current.width, strings.faceMarkAngle);
              final edge = marking(current.thickness, strings.edgeMarkAngle);
              return box.maxWidth < 320
                  ? Column(
                      spacing: 8,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [face, edge],
                    )
                  : Row(
                      spacing: 8,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: face),
                        Expanded(child: edge),
                      ],
                    );
            },
          ),
          Text(
            strings.cutDiagramKey,
            style: TextStyle(fontSize: 12, color: colors.muted),
          ),
          if (part != null)
            Builder(
              builder: (_) {
                final saw = sawAngles(part, end);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 3,
                  children: [
                    Text(
                      strings.flatSawSettings,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      strings.sawSettingValues(
                        _direction(saw.miter),
                        _direction(saw.bevel),
                      ),
                    ),
                    Text(
                      strings.sawDirections,
                      style: TextStyle(fontSize: 12, color: colors.muted),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
      leadingAction: DeskButton(
        onPressed: () => setState(() {
          current.width.text.text = '0';
          current.thickness.text.text = '0';
        }),
        child: Text(strings.resetEndCut),
      ),
      actions: [
        DeskButton(
          plain: true,
          onPressed: () => Navigator.pop(context),
          child: Text(strings.cancel),
        ),
        DeskButton(
          primary: true,
          onPressed: part == null ? null : () => Navigator.pop(context, part),
          child: Text(strings.apply),
        ),
      ],
    );
  }

  String _direction(double angle) {
    final value = mm(angle.abs());
    if (value == '0') return value;
    return '${angle > 0 ? '→' : '←'} $value';
  }
}

/// Both elevations use the same local length axis, increasing to the right.
/// Shrink both axes equally on steep cuts so the drawn angle remains true.
class _MarkDiagram extends CustomPainter {
  const _MarkDiagram(this.slope, this.end, this.colors, this.labelStyle);
  final double slope;
  final bool end;
  final EditorPalette colors;
  final TextStyle labelStyle;

  @override
  void paint(Canvas canvas, Size size) {
    final midX = size.width * (end ? .62 : .38);
    final midY = size.height / 2;
    final half = math.min(midY - 11, size.width * .27 / slope.abs());
    final top = Offset(midX + half * slope, midY - half);
    final bottom = Offset(midX - half * slope, midY + half);
    final board = Rect.fromLTRB(0, top.dy, size.width, bottom.dy);
    final keep = end ? board.left : board.right;
    final waste = end ? board.right : board.left;
    Path side(double x) => Path()
      ..addPolygon([
        top,
        Offset(x, top.dy),
        Offset(x, bottom.dy),
        bottom,
      ], true);
    canvas.drawPath(
      side(keep),
      Paint()..color = colors.diagramColor(const Color(0xffdfbd91)),
    );
    canvas.save();
    canvas.clipPath(side(waste));
    for (double x = board.left - board.height; x < board.right; x += 6) {
      canvas.drawLine(
        Offset(x, bottom.dy),
        Offset(x + board.height, top.dy),
        Paint()..color = colors.line,
      );
    }
    canvas.restore();
    final pen = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = colors.muted;
    canvas.drawRect(board, pen);
    for (double y = 3; y < size.height - 3; y += 6) {
      canvas.drawLine(Offset(midX, y), Offset(midX, y + 3), pen);
    }
    pen
      ..strokeWidth = 2.5
      ..color = colors.danger;
    canvas.drawLine(top, bottom, pen);
    final sweep = math.atan(slope);
    if (sweep.abs() > .001) {
      final radius = math.min(21.0, (top - Offset(midX, midY)).distance * .8);
      canvas.drawArc(
        Rect.fromCircle(center: Offset(midX, midY), radius: radius),
        -math.pi / 2,
        sweep,
        false,
        pen..strokeWidth = 1.5,
      );
    }
    final label = TextPainter(
      text: TextSpan(
        text: '${mm(sweep.abs() * 180 / math.pi)}°',
        style: labelStyle.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colors.danger,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final labelX = slope < 0 ? midX - label.width - 7 : midX + 7;
    final at = Offset(
      labelX.clamp(2.0, math.max(2.0, size.width - label.width - 2)),
      midY - label.height / 2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        (at & label.size).inflate(2),
        const Radius.circular(3),
      ),
      Paint()..color = colors.paper,
    );
    label.paint(canvas, at);
    label.dispose();
  }

  @override
  bool shouldRepaint(_MarkDiagram old) =>
      old.end != end ||
      old.slope != slope ||
      old.colors != colors ||
      old.labelStyle != labelStyle;
}
