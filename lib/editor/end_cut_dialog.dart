import 'dart:math' as math;

import 'package:intl/intl.dart' show NumberFormat;
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
import 'step.dart';

part 'saw_settings.dart';

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
      editor.lengthInput,
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
  const _EndCutDialog(this.part, this.camera, this.input, this.initialEnd);
  final Beam part;
  final Camera camera;
  final LengthInput input;
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
  _SawType sawType = _SawType.miter;
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
              height: 94,
              child: CustomPaint(
                painter: _MarkDiagram(
                  offset / f.span,
                  end,
                  colors,
                  DefaultTextStyle.of(context).style,
                  context.strings.start,
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
                '${widget.input.format(offset)} ${widget.input.unit.symbol}',
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
    final saw = part == null ? null : sawAngles(part, end);
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
                        foregroundPainter: _PreviewEndOutline(
                          part,
                          end,
                          camera,
                          colors,
                          strings.start,
                          DefaultTextStyle.of(context).style,
                        ),
                      );
                    },
                  ),
          ),
          _diagramPair(
            marking(current.width, strings.faceMarkAngle),
            marking(current.thickness, strings.edgeMarkAngle),
          ),
          if (saw != null) ...[
            const Divider(height: 1),
            DeskSegments<_SawType>(sawType, {
              _SawType.miter: strings.mitreSaw,
              _SawType.handheld: strings.handheldSaw,
              _SawType.table: strings.tableSaw,
            }, (value) => setState(() => sawType = value)),
            Text(
              strings.sawStockPosition,
              style: TextStyle(fontSize: 12, color: colors.muted),
            ),
            _diagramPair(
              _SawSetting(tool: sawType, blade: false, angle: saw.miter),
              _SawSetting(tool: sawType, blade: true, angle: saw.bevel),
            ),
          ],
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
}

Widget _diagramPair(Widget first, Widget second) => LayoutBuilder(
  builder: (_, box) => box.maxWidth < 320
      ? Column(
          spacing: 8,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [first, second],
        )
      : Row(
          spacing: 8,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            Expanded(child: second),
          ],
        ),
);

class _PreviewEndOutline extends EndFaceOutline {
  _PreviewEndOutline(
    Beam part,
    bool end,
    Camera camera,
    this.colors,
    this.startLabel,
    this.style,
  ) : super(part, end, camera, colors.danger);
  final EditorPalette colors;
  final String startLabel;
  final TextStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    super.paint(canvas, size);
    final start = camera.project(beam.pointAt(Vector3(0, .5, .5)), size);
    _drawStart(
      canvas,
      size,
      start,
      startLabel,
      style,
      colors,
      labelToRight: start.dx > size.width / 2,
    );
  }
}

void _drawStart(
  Canvas canvas,
  Size size,
  Offset anchor,
  String text,
  TextStyle style,
  EditorPalette colors, {
  bool offscreen = false,
  bool labelToRight = false,
}) {
  final label = TextPainter(
    text: TextSpan(
      text: text,
      style: style.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: colors.ink,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: size.width);
  final labelX = labelToRight ? anchor.dx + 14 : anchor.dx - 14 - label.width;
  final double left = labelX.clamp(
    0.0,
    math.max(0.0, size.width - label.width),
  );
  final at = Offset(left, size.height - label.height);
  final box = at & label.size;
  final pen = Paint()
    ..color = colors.muted
    ..strokeWidth = 1.2;
  final elbow = anchor + Offset(labelToRight ? 7 : -7, 0);
  canvas.drawLine(anchor, elbow, pen);
  canvas.drawLine(
    elbow,
    Offset(labelToRight ? box.left : box.right, box.center.dy),
    pen,
  );
  if (offscreen) {
    canvas.drawLine(anchor, anchor + const Offset(4, -3), pen);
    canvas.drawLine(anchor, anchor + const Offset(4, 3), pen);
  } else {
    canvas.drawCircle(anchor, 3.5, Paint()..color = colors.paper);
    canvas.drawCircle(anchor, 2.3, Paint()..color = colors.ink);
  }
  canvas.drawRRect(
    RRect.fromRectAndRadius(box.inflate(1), const Radius.circular(2)),
    Paint()..color = colors.paper,
  );
  label.paint(canvas, at);
  label.dispose();
}

/// Both elevations use the same local length axis, increasing to the right.
/// Shrink both axes equally on steep cuts so the drawn angle remains true.
class _MarkDiagram extends CustomPainter {
  const _MarkDiagram(
    this.slope,
    this.end,
    this.colors,
    this.labelStyle,
    this.startLabel,
  );
  final double slope;
  final bool end;
  final EditorPalette colors;
  final TextStyle labelStyle;
  final String startLabel;

  @override
  void paint(Canvas canvas, Size size) {
    final midX = size.width * (end ? .62 : .38);
    final diagramHeight = size.height - 18;
    final midY = diagramHeight / 2;
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
    for (double y = 3; y < diagramHeight - 3; y += 6) {
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
    _drawStart(
      canvas,
      size,
      end ? Offset(1, board.bottom) : bottom,
      startLabel,
      labelStyle,
      colors,
      offscreen: end,
      labelToRight: end,
    );
  }

  @override
  bool shouldRepaint(_MarkDiagram old) =>
      old.end != end ||
      old.slope != slope ||
      old.colors != colors ||
      old.startLabel != startLabel ||
      old.labelStyle != labelStyle;
}
