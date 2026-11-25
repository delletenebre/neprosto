import 'dart:math' as math;

import 'package:intl/intl.dart' show NumberFormat;
import 'package:material_ui/material_ui.dart';

import '../l10n/strings.dart';
import 'arithmetic.dart';
import 'controller.dart';
import 'controls.dart';
import 'desk_text_field.dart';
import 'desktop.dart';
import 'drawing.dart';
import 'joint.dart';
import 'model.dart';
import 'palette.dart';
import 'scene.dart';
import 'step.dart';
import 'saw_preview.dart';

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
      editor.step.anglePrecision,
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
  const _EndCutDialog(
    this.part,
    this.camera,
    this.input,
    this.precision,
    this.initialEnd,
  );
  final Beam part;
  final Camera camera;
  final LengthInput input;
  final AnglePrecision precision;
  final bool initialEnd;
  @override
  State<_EndCutDialog> createState() => _EndCutDialogState();
}

// An untouched field retains the exact plane from a template or saved file.
class _MarkField {
  _MarkField(this.originalOffset, this.span, this.precision) {
    final angle = markingAngle(originalOffset, span);
    final rounded = precision.format(angle);
    final initialText =
        (angle != 0 && rounded == '0') || double.parse(rounded).abs() == 90
        ? angle.toString()
        : rounded;
    text = TextEditingController(text: initialText);
  }
  final double originalOffset, span;
  final AnglePrecision precision;
  late final TextEditingController text;
  bool edited = false;

  double? get degrees {
    final value = calculate(text.text);
    return value == null ? null : precision.round(value);
  }

  double get offset =>
      edited ? markingOffset(degrees ?? 0, span) ?? 0 : originalOffset;

  void normalize() {
    final value = degrees;
    if (edited && value != null && markingOffset(value, span) != null) {
      setAngle(value);
    }
  }

  void step(int direction) {
    final next = precision.round(
      (degrees ?? 0) + direction * precision.increment,
    );
    if (markingOffset(next, span) != null) setAngle(next);
  }

  void setAngle(double angle) {
    edited = true;
    final value = precision.format(angle);
    text.value = TextEditingValue(
      text: value,
      selection: TextSelection(baseOffset: 0, extentOffset: value.length),
    );
  }
}

class _EndCutDialogState extends State<_EndCutDialog> {
  late bool end = widget.initialEnd;
  SawType sawType = SawType.miter;
  bool tableCutaway = true;
  late final fields = [
    for (final cut in [widget.part.startCut, widget.part.endCut])
      (
        width: _MarkField(cut.y, widget.part.size.y, widget.precision),
        thickness: _MarkField(cut.z, widget.part.size.z, widget.precision),
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
    final distance =
        '${widget.input.format(offset)} ${widget.input.unit.symbol}';
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
                onChanged: (_) => setState(() => f.edited = true),
                onStep: (direction) => setState(() => f.step(direction)),
                onSubmitted: (_) => setState(f.normalize),
                suffix: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Text('°'),
                ),
              ),
            ),
            SizedBox(
              height: 112,
              child: Semantics(
                image: true,
                label: context.strings.cutOffsetReadout(distance),
                child: CustomPaint(
                  painter: _MarkDiagram(
                    offset / f.span,
                    end,
                    colors,
                    DefaultTextStyle.of(context).style,
                    context.strings.start,
                    widget.precision,
                    distance,
                  ),
                ),
              ),
            ),
            Text(
              context.strings.angleToLongEdge(
                widget.precision.format(
                  90 - markingAngle(offset, f.span).abs(),
                ),
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
            DeskSegments<SawType>(sawType, {
              SawType.miter: strings.mitreSaw,
              SawType.handheld: strings.handheldSaw,
              SawType.table: strings.tableSaw,
            }, (value) => setState(() => sawType = value)),
            Text(
              strings.sawStockPosition,
              style: TextStyle(fontSize: 12, color: colors.muted),
            ),
            _diagramPair(
              _SawSetting(
                tool: sawType,
                blade: false,
                angle: saw.miter,
                tableCutaway: tableCutaway,
              ),
              _SawSetting(
                tool: sawType,
                blade: true,
                angle: saw.bevel,
                tableCutaway: tableCutaway,
                changeView: (cutaway) => setState(() => tableCutaway = cutaway),
              ),
            ),
          ],
        ],
      ),
      leadingAction: DeskButton(
        onPressed: () => setState(() {
          current.width.setAngle(0);
          current.thickness.setAngle(0);
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
    this.precision,
    this.distance,
  );
  final double slope;
  final AnglePrecision precision;
  final bool end;
  final EditorPalette colors;
  final TextStyle labelStyle;
  final String startLabel, distance;

  void _drawOffset(Canvas canvas, Size size, Offset top, Offset bottom) {
    final left = math.min(top.dx, bottom.dx),
        right = math.max(top.dx, bottom.dx);
    final y = top.dy - 10;
    final pen = Paint()
      ..color = colors.muted
      ..strokeWidth = .85;
    canvas.drawLine(Offset(left - 3, y), Offset(right + 3, y), pen);
    for (final x in {left, right}) {
      canvas.drawLine(Offset(x, top.dy - 2), Offset(x, y - 3), pen);
      canvas.drawLine(Offset(x - 2, y + 2), Offset(x + 2, y - 2), pen);
    }
    final label = TextPainter(
      text: TextSpan(
        text: distance,
        style: labelStyle.copyWith(fontSize: 11, color: colors.ink),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: size.width);
    final double x = ((left + right - label.width) / 2).clamp(
      2.0,
      math.max(2.0, size.width - label.width - 2),
    );
    label.paint(canvas, Offset(x, y - label.height - 3));
    label.dispose();
  }

  @override
  void paint(Canvas canvas, Size size) {
    const topInset = 34.0, bottomInset = 24.0;
    final midY = (size.height + topInset - bottomInset) / 2;
    final edgeInset = math.min(24.0, size.width * .12);
    final half = math.min(
      midY - topInset,
      (size.width - 2 * edgeInset) * .33 / slope.abs(),
    );
    final run = 2 * half * slope;
    final edgeX = end ? size.width - edgeInset : edgeInset;
    final stockEdge = edgeX + (end ? 1 : -1) * edgeInset * .6;
    final topAtEdge = end ? slope > 0 : slope < 0;
    final top = Offset(topAtEdge ? edgeX : edgeX + run, midY - half);
    final bottom = Offset(topAtEdge ? edgeX - run : edgeX, midY + half);
    final corner = topAtEdge ? top : bottom;
    final keep = end ? 3.0 : size.width - 3;
    final wood = Path()
      ..addPolygon([
        top,
        Offset(keep, top.dy),
        Offset(keep, bottom.dy),
        bottom,
      ], true);
    canvas.drawPath(
      wood,
      Paint()..color = colors.diagramColor(const Color(0xffdfbd91)),
    );
    final pen = Paint()..color = colors.line;
    final waste = Path()
      ..addPolygon([
        Offset(stockEdge, top.dy),
        top,
        bottom,
        Offset(stockEdge, bottom.dy),
      ], true);
    canvas.save();
    canvas.clipPath(waste);
    final hatch = waste.getBounds();
    for (var x = hatch.left - hatch.height; x < hatch.right; x += 6) {
      canvas.drawLine(
        Offset(x, bottom.dy),
        Offset(x + hatch.height, top.dy),
        pen,
      );
    }
    canvas.restore();
    pen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = colors.muted;
    canvas.drawPath(
      Path()
        ..moveTo(stockEdge, top.dy)
        ..lineTo(keep, top.dy)
        ..lineTo(keep, bottom.dy)
        ..lineTo(stockEdge, bottom.dy),
      pen,
    );
    for (double y = top.dy - 2; y < bottom.dy + 6; y += 6) {
      canvas.drawLine(Offset(edgeX, y), Offset(edgeX, y + 3), pen);
    }
    pen
      ..strokeWidth = 2.5
      ..color = colors.danger;
    canvas.drawLine(top, bottom, pen);
    final sweep = math.atan(slope);
    if (sweep.abs() > .001) {
      final radius = math.min(21.0, 2 * half * .8);
      canvas.drawArc(
        Rect.fromCircle(center: corner, radius: radius),
        topAtEdge ? math.pi / 2 : -math.pi / 2,
        sweep,
        false,
        pen..strokeWidth = 1.5,
      );
    }
    final label = TextPainter(
      text: TextSpan(
        text: '${precision.format(sweep.abs() * 180 / math.pi)}°',
        style: labelStyle.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colors.danger,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    // A wide offcut has room for the reading next to the reference edge.
    final room = 2 * half - label.height - 5;
    final inWaste = room >= 21 && room * slope.abs() >= label.width + 9;
    final labelEdge = inWaste
        ? edgeX
        : (end ? math.min(top.dx, bottom.dx) : math.max(top.dx, bottom.dx));
    final labelX = end ? labelEdge - label.width - 6 : labelEdge + 6;
    final at = Offset(
      labelX.clamp(2.0, math.max(2.0, size.width - label.width - 2)),
      inWaste
          ? (topAtEdge ? bottom.dy - label.height - 3 : top.dy + 3)
          : midY - label.height / 2,
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
    _drawOffset(canvas, size, top, bottom);
    _drawStart(
      canvas,
      size,
      end ? Offset(keep, bottom.dy) : bottom,
      startLabel,
      labelStyle,
      colors,
      offscreen: end,
      labelToRight: end || bottom.dx < 56,
    );
  }

  @override
  bool shouldRepaint(_MarkDiagram old) =>
      old.end != end ||
      old.slope != slope ||
      old.precision != precision ||
      old.distance != distance ||
      old.colors != colors ||
      old.startLabel != startLabel ||
      old.labelStyle != labelStyle;
}
