import '../l10n/strings.dart';
import 'palette.dart';

import 'dart:math' as math;
import 'dart:ui' as ui show Gradient;

import 'package:material_ui/material_ui.dart';

import 'model.dart';
import 'step.dart';
import 'finish_painter.dart';
import 'part_finish.dart';
import 'move_snap.dart';
import 'stock_axis.dart';
import 'positioning.dart';
import 'scene.dart';
import 'contact.dart';

const alignmentColors = {
  StockAlignment.front: Color(0xff087d63),
  StockAlignment.middle: Color(0xff1b74cd),
  StockAlignment.back: Color(0xff8355b5),
  StockAlignment.offset: Color(0xffa96313),
};
const supportColor = Color(0xff963456);
const mono = TextStyle(
  fontFamily: 'monospace',
  fontSize: 11,
  fontFeatures: [FontFeature.tabularFigures()],
);

class EndFaceOutline extends CustomPainter {
  final Beam beam;
  final bool end;
  final Camera camera;
  final Color color;
  EndFaceOutline(this.beam, this.end, this.camera, this.color);
  @override
  void paint(Canvas c, Size s) {
    final points = beam.rabbets.isNotEmpty
        ? [
            for (final p in beam.sectionOutline)
              camera.project(beam.pointAt(p..x = end ? 1 : 0), s),
          ]
        : [
            for (final point in beam.sectionOutline)
              camera.project(
                beam.pointAt(Vector3(end ? 1 : 0, point.y, point.z)),
                s,
              ),
          ];
    final path = Path()..addPolygon(points, true);
    final pen = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = color;
    c.drawPath(path, pen);
    final bounds = path.getBounds();
    if (bounds.longestSide < 12) {
      c.drawCircle(bounds.center, 6, pen..strokeWidth = 1.5);
    }
  }

  @override
  bool shouldRepaint(EndFaceOutline old) => true;
}

class DrawingPainter extends CustomPainter {
  final stockLabels = <StockAxis, Rect>{};
  final _dimensionLines =
      <Dimension, ({Offset start, Offset end, Rect label})>{};
  final Dimension? selectedDimension;

  Dimension? dimensionAt(Offset position) {
    Dimension? closest;
    var best = 7.0 * 7.0;
    for (final entry in _dimensionLines.entries) {
      final line = entry.value;
      final distance = line.label.inflate(2).contains(position)
          ? 0.0
          : segmentDistanceSquared(position, line.start, line.end);
      if (distance <= best) {
        best = distance;
        closest = entry.key;
      }
    }
    return closest;
  }

  final Scene scene;
  final Iterable<Beam> hiddenOutlines;
  final Set<int> selection;
  final int? referenceId;
  final Beam? alignmentSupport;
  final Dimension? gapPreview;
  final Anchor? hover, first;
  final Beam? preview;
  final EditorPalette colors;
  final Color previewColor;
  final SceneFace? activeFace;
  final RulerTarget? rulerTarget;
  final bool showRise, dimensions, dimensionsVisible;
  final bool showAllStockSizes;
  final Set<int> overlaps;
  final Set<int> moveHighlight;
  final int? resizePart;
  final ResizeEdge? activeEdge;
  final Offset? edgePointer;
  final Project? original;
  final List<MoveGuide> moveGuides;
  final Vector3? rotationPivot;
  final int rotationAxis;
  final int? highlightedSize;
  final ({int axis, Vector3 origin})? positionGuide;
  final bool localRotation;
  final List<Vector3>? rotationBasis;
  final double angle;
  DrawingPainter({
    required this.scene,
    this.hiddenOutlines = const [],
    required this.selection,
    this.selectedDimension,
    this.referenceId,
    this.alignmentSupport,
    this.gapPreview,
    this.hover,
    this.first,
    this.preview,
    this.colors = EditorPalette.light,
    Color? previewColor,
    this.activeFace,
    this.rulerTarget,
    this.showRise = false,
    required this.dimensions,
    this.dimensionsVisible = true,
    this.showAllStockSizes = false,
    this.overlaps = const {},
    this.moveHighlight = const {},
    this.resizePart,
    this.activeEdge,
    this.edgePointer,
    this.original,
    this.rotationAxis = 2,
    this.rotationPivot,
    this.highlightedSize,
    this.positionGuide,
    this.localRotation = false,
    this.rotationBasis,
    this.moveGuides = const [],
    this.angle = 0,
  }) : previewColor = previewColor ?? colors.accent;
  Offset project(Vector3 p) => scene.camera.project(p, scene.size);
  @override
  void paint(Canvas c, Size s) {
    stockLabels.clear();
    _dimensionLines.clear();
    c.save();
    c.clipRect(Offset.zero & s);
    _workspace(c);
    if (rulerTarget?.face == null) _rulerGuide(c);
    if (original != null) {
      final pen = Paint()
        ..color = const Color(0xff87958a)
        ..strokeWidth = 1;
      for (final b in original!.beams.where((b) => selection.contains(b.id))) {
        _partOutline(c, b, pen);
      }
    }
    for (final f in scene.faces) {
      final clip = f.paintClip;
      if (clip != null) {
        c.save();
        c.clipPath(clip);
      }
      _face(c, f);
      if (f == rulerTarget?.face) {
        _highlightFace(c, f);
        _rulerGuide(c);
      }
      if (clip != null) c.restore();
    }
    if (hiddenOutlines.isNotEmpty) {
      final pen = Paint()
        ..color = colors.muted.withValues(alpha: .48)
        ..strokeWidth = 1;
      for (final b in hiddenOutlines) {
        _partOutline(c, b, pen);
      }
    }
    if ((original != null || rotationPivot != null) && selection.isNotEmpty) {
      _rotation(c);
    }
    if (activeFace case final face?) {
      _highlightFace(c, face);
    }
    if (preview case final b?) {
      final ghost = Scene(Project('', [b]), scene.camera, s);
      for (final f in ghost.faces) {
        c.drawPath(
          f.path,
          Paint()..color = previewColor.withValues(alpha: .27),
        );
        c.drawPath(
          f.path,
          Paint()
            ..color = previewColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4,
        );
      }
    }
    if (dimensionsVisible && dimensions && scene.project.beams.isNotEmpty) {
      final selected = scene.project.beams
          .where((b) => selection.contains(b.id))
          .toList();
      List<Vector3> points;
      if (selected.length == 1) {
        points = selected.single.corners;
      } else {
        final bounds = Bounds3.points(
          (selected.isEmpty ? scene.project.beams : selected).expand(
            (b) => b.corners,
          ),
        );
        points = List.generate(
          8,
          (i) => Vector3(
            (i & 1) == 0 ? bounds.low.x : bounds.high.x,
            (i & 2) == 0 ? bounds.low.y : bounds.high.y,
            (i & 4) == 0 ? bounds.low.z : bounds.high.z,
          ),
        );
      }
      _dimensions(c, points, part: selected.singleOrNull);
    }
    for (final d in [
      if (dimensionsVisible && original == null) ...scene.project.dimensions,
      if (dimensionsVisible) ?gapPreview,
    ]) {
      final g = d.geometry(scene.project);
      if (g == null) continue;
      final selected = d == selectedDimension;
      final line = _ruler(
        c,
        g.from,
        g.to,
        -17,
        colors.accent,
        selected: selected,
        showDepth: true,
      );
      if (line != null && d != gapPreview) _dimensionLines[d] = line;
      if (selected) {
        if (d.a.beam != null) _marker(c, project(g.from));
        if (d.b.beam != null) _marker(c, project(g.to));
      }
    }
    for (final g in moveGuides) {
      final paint = Paint()
        ..color = colors.accent
        ..strokeWidth = 1.4;
      final start = project(g.line.$1), end = project(g.line.$2);
      if (g.reference case final ref?) {
        for (final (a, b) in [
          (start, end),
          (project(ref.$1), project(ref.$2)),
        ]) {
          final d = b - a;
          if (d.distance < .01) continue;
          final tick = Offset(-d.dy, d.dx) * (4 / d.distance);
          c.drawLine(a, b, paint);
          c.drawLine(a - tick, a + tick, paint);
          c.drawLine(b - tick, b + tick, paint);
        }
        if (!dimensionsVisible) continue;
        final unit = scene.input.unit;
        _label(
          c,
          (start + end) / 2 + const Offset(0, -15),
          editorStrings.gap(scene.input.format(g.gap!), unit.symbol),
          colors.accent,
          filled: true,
        );
      } else {
        final d = end - start;
        if (d.distance < 1) continue;
        final step = d / d.distance;
        for (var i = -6.0; i < d.distance + 6; i += 8) {
          c.drawLine(start + step * i, start + step * (i + 4), paint);
        }
      }
    }
    if (alignmentSupport case final support?) _drawSupport(c, s, support);
    if (first case final a?) {
      if (showRise && hover != null) {
        final start = a.resolve(scene.project),
            end = hover!.resolve(scene.project);
        final top = project(Vector3(start.x, start.y, end.z));
        final base = project(start), tip = project(end);
        final pen = Paint()
          ..color = colors.accent.withValues(alpha: .75)
          ..strokeWidth = 1.2;
        c.drawLine(base, top, pen);
        c.drawLine(top, tip, pen);
        if (dimensionsVisible) {
          final unit = scene.input.unit;
          _label(
            c,
            top + const Offset(0, -24),
            'Z +${scene.input.format(end.z - start.z)} ${unit.symbol}',
            colors.accent,
          );
        }
      }
      _marker(c, project(a.resolve(scene.project)));
      if (hover case final b? when dimensionsVisible) {
        _ruler(
          c,
          a.resolve(scene.project),
          b.resolve(scene.project),
          -12,
          colors.accent,
        );
      }
    }
    if (hover case final a?) {
      final screen = project(a.resolve(scene.project));
      if (a.attached) {
        _marker(c, screen);
        _label(
          c,
          screen + const Offset(0, -24),
          a.displayLabel,
          colors.accent,
          filled: true,
        );
      } else {
        c.drawCircle(screen, 3, Paint()..color = colors.accent);
      }
    }
    if (activeEdge case final edge? when edgePointer != null) {
      final part = scene.project.byId[edge.face.beam.id]!;
      final unit = scene.input.unit;
      _label(
        c,
        edgePointer! + const Offset(0, -24),
        '${StockAxis.values[edge.axis].label} · ${scene.input.format(part.size[edge.axis])} ${unit.symbol}',
        colors.accent,
        filled: true,
      );
    }
    if (positionGuide case final guide?) {
      _drawPositionAxis(c, guide.axis, guide.origin);
    }
    c.restore();
  }

  void _highlightFace(Canvas c, SceneFace face) {
    c.drawPath(
      face.path,
      Paint()..color = colors.accent.withValues(alpha: .22),
    );
    c.drawPath(
      face.path,
      Paint()
        ..color = colors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawPositionAxis(Canvas c, int dim, Vector3 origin) {
    final center = project(origin);
    final forward = offsetDirection(dim);
    final direction = project(origin + forward) - center;
    final color = colors.axisColor(dim);
    final pen = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    Offset label;
    if (direction.distance <
        .01 * scene.camera.scale * scene.camera.projectionFactor(origin)) {
      // The axis points toward or away from the viewer in this projection.
      c.drawCircle(center, 7, Paint()..color = colors.paper);
      c.drawCircle(center, 6, pen..style = PaintingStyle.stroke);
      if (scene.camera.towardEye(origin).dot(forward) > 0) {
        c.drawCircle(center, 2, pen..style = PaintingStyle.fill);
      } else {
        c.drawLine(
          center - const Offset(3, 3),
          center + const Offset(3, 3),
          pen,
        );
        c.drawLine(
          center - const Offset(3, -3),
          center + const Offset(3, -3),
          pen,
        );
      }
      label = center + const Offset(0, -19);
    } else {
      final unit = direction / direction.distance;
      final normal = Offset(-unit.dy, unit.dx);
      final tip = center + unit * 64;
      final path = Path()
        ..moveTo(center.dx - unit.dx * 48, center.dy - unit.dy * 48)
        ..lineTo(tip.dx, tip.dy);
      for (final side in [-1, 1]) {
        final wing = tip - unit * 8 + normal * (side * 4);
        path
          ..moveTo(tip.dx, tip.dy)
          ..lineTo(wing.dx, wing.dy);
      }
      pen.style = PaintingStyle.stroke;
      c.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = colors.paper,
      );
      c.drawPath(path, pen);
      c.drawCircle(center, 3.5, pen..style = PaintingStyle.fill);
      label = tip + unit * 13;
    }
    _label(c, label, 'XYZ'[dim], color);
  }

  void _drawSupport(Canvas c, Size size, Beam support) {
    final faces = scene.faces.where((f) => f.beam.id == support.id);
    if (faces.isEmpty || size.width < 40 || size.height < 26) return;
    final outline = faces
        .map((f) => f.path)
        .reduce((a, b) => Path.combine(PathOperation.union, a, b));
    final bounds = outline.getBounds().intersect(Offset.zero & size);
    if (bounds.isEmpty) return;
    // Paint above the rest of the assembly so a rail cannot hide its support.
    c.drawPath(
      outline,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 4
        ..color = Colors.white,
    );
    c.drawPath(
      outline,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 2
        ..color = supportColor,
    );
    final slice = Path.combine(
      PathOperation.intersect,
      outline,
      Path()..addRect(
        Rect.fromLTRB(
          bounds.left,
          bounds.center.dy - .5,
          bounds.right,
          bounds.center.dy + .5,
        ),
      ),
    );
    final cross = slice.getBounds();
    if (cross.isEmpty) return;
    final caption = TextPainter(
      text: TextSpan(
        text: editorStrings.anchorLabel(support.name),
        style: mono.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: math.min(250.0, size.width - 20));
    final width = caption.width + 12, height = caption.height + 6;
    final right =
        cross.right + 12 + width < size.width ||
        size.width - cross.right > cross.left;
    final tip = right ? cross.centerRight : cross.centerLeft;
    final x = right ? tip.dx + 12 : tip.dx - width - 12;
    final rect = Rect.fromLTWH(
      x.clamp(3.0, size.width - width - 3),
      (tip.dy - height - 5).clamp(3.0, math.max(3.0, size.height - height - 3)),
      width,
      height,
    );
    final pen = Paint()
      ..color = supportColor
      ..strokeWidth = 1.5;
    c.drawLine(tip, right ? rect.centerLeft : rect.centerRight, pen);
    c.drawCircle(tip, 2.5, pen);
    c.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), pen);
    caption.paint(c, rect.topLeft + const Offset(6, 3));
    caption.dispose();
  }

  void _rotation(Canvas c) {
    final pivot =
        rotationPivot ??
        Bounds3.points(
          original!.beams
              .where((b) => selection.contains(b.id))
              .expand((b) => b.corners),
        ).center;
    final dial = RotationDial.project(
      scene.camera,
      scene.size,
      pivot,
      rotationBasis![rotationAxis],
    );
    final color = const [
      Color(0xffb74e43),
      Color(0xff31815d),
      Color(0xff376cb3),
    ][rotationAxis];
    final path = Path()..addPolygon(dial.ring, true);
    c.drawPath(path, Paint()..color = color.withValues(alpha: .065));
    c.drawPath(
      path,
      Paint()
        ..color = colors.panel.withValues(alpha: .85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    c.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: .70)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    if ((dial.axisEnd - dial.center).distance > 14) {
      c.drawLine(
        dial.center,
        dial.axisEnd,
        Paint()
          ..color = color
          ..strokeWidth = 1.5,
      );
    }
    for (final a in dial.arrows) {
      c.drawPath(
        Path()..addPolygon(a.path, false),
        Paint()
          ..color = color
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke,
      );
      final tangent = a.tip - a.path[a.path.length - 4];
      if (tangent.distance > .01) {
        final d = tangent / tangent.distance, side = Offset(-d.dy, d.dx);
        c.drawPath(
          Path()..addPolygon([
            a.tip + d * 3,
            a.tip - d * 8 + side * 4.5,
            a.tip - d * 8 - side * 4.5,
          ], true),
          Paint()..color = color,
        );
      }
      _label(c, a.label, a.sign > 0 ? '+90°' : '−90°', color, filled: true);
    }
    c.drawCircle(dial.center, 4, Paint()..color = Colors.white);
    c.drawCircle(dial.center, 2.5, Paint()..color = color);
    _label(
      c,
      dial.axisEnd + const Offset(0, -10),
      localRotation
          ? StockAxis.values[rotationAxis].label
          : editorStrings.axis('XYZ'[rotationAxis]),
      color,
    );
  }

  void _rulerGuide(Canvas c) {
    if (rulerTarget?.guide case final guide?) {
      c.drawLine(
        project(guide.$1),
        project(guide.$2),
        Paint()
          ..color = colors.accent
          ..strokeWidth = 3.5,
      );
    }
  }

  void _workspace(Canvas c) {
    final corners = scene.project.workspaceCorners;
    if (corners.isEmpty) return;
    final tint = Color.lerp(colors.paper, colors.muted, .45)!;
    final clear = tint.withValues(alpha: 0);
    final dashed = Paint()
      ..strokeWidth = 1
      ..shader = ui.Gradient.linear(
        Offset.zero,
        const Offset(9, 0),
        [tint, tint, clear, clear],
        const [0, .44, .44, 1],
        TileMode.repeated,
      );
    final corner = Paint()
      ..strokeWidth = 1.2
      ..color = Color.lerp(colors.paper, colors.muted, .65)!;
    forEachBoxEdge(corners, (a, b) {
      final clipped = scene.camera.clipLine(a, b);
      if (clipped == null) return;
      final start = project(clipped.$1);
      final edge = project(clipped.$2) - start;
      final length = edge.distance;
      if (length < 1) return;
      final tick = math.min(7.0, length * .2);
      c.save();
      c.translate(start.dx, start.dy);
      c.rotate(edge.direction);
      c.drawLine(Offset.zero, Offset(length, 0), dashed);
      if (identical(a, clipped.$1)) {
        c.drawLine(Offset.zero, Offset(tick, 0), corner);
      }
      if (identical(b, clipped.$2)) {
        c.drawLine(Offset(length - tick, 0), Offset(length, 0), corner);
      }
      c.restore();
    });
  }

  void _partOutline(Canvas c, Beam b, Paint pen) {
    void line(Vector3 a, Vector3 b) {
      if (scene.camera.clipLine(a, b) case (final from, final to)) {
        c.drawLine(project(from), project(to), pen);
      }
    }

    if (b.rabbets.isEmpty) {
      forEachBoxEdge(b.corners, line);
      return;
    }
    final section = b.sectionOutline;
    final start = section.map(b.pointAt).toList();
    final end = [for (final p in section) b.pointAt(p.clone()..x = 1)];
    for (var i = 0; i < section.length; i++) {
      final j = (i + 1) % section.length;
      line(start[i], start[j]);
      line(end[i], end[j]);
      line(start[i], end[i]);
    }
  }

  void _face(Canvas c, SceneFace f) {
    final selected = selection.contains(f.beam.id);
    final movable = moveHighlight.contains(f.beam.id);
    final reference = f.beam.id == referenceId;
    final light = Vector3(-.38, -.48, .79).normalized();
    final finish = f.beam.finish;
    final core = panelCoreColor(finish.texture);
    final cutSurface = f.face < 4 || !f.isOuterFace;
    final base = (cutSurface ? core : null) ?? finishColor(finish);
    final shade = f.normal.dot(light) * .24 - .12;
    Color lit(Color base) {
      var fill = Color.lerp(
        base,
        shade < 0 ? Colors.black : Colors.white,
        shade.abs(),
      )!;
      if (overlaps.contains(f.beam.id)) {
        fill = Color.lerp(fill, const Color(0xffda7657), .53)!;
      }
      if (reference) fill = Color.lerp(fill, const Color(0xff80b6ce), .70)!;
      if (f.beam.id == alignmentSupport?.id) {
        fill = Color.lerp(fill, supportColor, .38)!;
      }
      if (selected) fill = Color.lerp(fill, EditorPalette.highlight, .22)!;
      if (selected && highlightedSize == f.face ~/ 2) {
        fill = Color.lerp(fill, StockAxis.values[highlightedSize!].color, .33)!;
      }
      if (original != null && !selected) {
        fill = Color.lerp(fill, colors.paper, .58)!;
      }
      return fill;
    }

    final fill = lit(base);
    c.drawPath(f.path, Paint()..color = fill);
    final clipTexture = f.boreRim != null || f.points.length != 4;
    if (clipTexture) {
      c.save();
      c.clipPath(f.path);
    }
    final points = f.points.length == 4
        ? f.points
        : [for (final i in faceCorners[f.face]) project(f.beam.corner(i))];
    // Faces 0, 3 and 4 wind across the grain first (see faceCorners).
    final acrossFirst = f.face == 0 || f.face == 3 || f.face == 4;
    if (finish.texture == PartTexture.plywood && f.face < 4) {
      // Alternating veneer layers run parallel to the broad faces of the sheet.
      final corners = faceCorners[f.face];
      final bottom = corners.where((index) => index & 4 == 0).toList();
      final pen = Paint()
        ..color = const Color(0x665d422c)
        ..strokeWidth = .7;
      Offset layer(int corner, double fraction) => Offset.lerp(
        points[corners.indexOf(corner)],
        points[corners.indexOf(corner | 4)],
        fraction,
      )!;
      for (final fraction in [.25, .5, .75]) {
        c.drawLine(
          layer(bottom.first, fraction),
          layer(bottom.last, fraction),
          pen,
        );
      }
    } else {
      paintFinishTexture(
        c,
        finish.texture,
        fill,
        points[0],
        points[acrossFirst ? 3 : 1],
        points[2],
        points[acrossFirst ? 1 : 3],
        seed: f.beam.id,
        cutSurface: cutSurface,
      );
    }
    final band = f.beam.banding;
    if (band.edges.isNotEmpty) {
      final paint = Paint()..color = lit(Color(0xff000000 | band.rgb));
      for (final strip in f.bandingPolygons) {
        c.drawPath(
          Path()..addPolygon(strip.map(project).toList(), true),
          paint,
        );
      }
    }
    if (clipTexture) c.restore();
    if (f.boreRim != null || f.boreFloor != null) {
      final boreColor = core == null ? fill : lit(core);
      if (f.boreFloor case final floor?) {
        c.drawPath(
          floor,
          Paint()..color = Color.lerp(boreColor, Colors.black, .32)!,
        );
      }
      if (f.boreRim case final rim?) {
        c.drawPath(
          rim,
          Paint()..color = Color.lerp(boreColor, Colors.black, .65)!,
        );
      }
    }
    c.drawPath(
      f.path,
      Paint()
        ..color = selected || movable
            ? colors.accent
            : Color.lerp(base, Colors.black, .42)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = movable
            ? 2.4
            : selected
            ? 1.65
            : .8
        ..strokeJoin = StrokeJoin.round,
    );
    if (f.beam.id == resizePart) {
      for (var i = 0; i < f.points.length; i++) {
        final edge = ResizeEdge(f, i);
        if (!edge.canResize(scene.camera)) continue;
        final active =
            activeEdge?.face.face == f.face &&
            activeEdge?.index == i &&
            activeEdge?.start == edge.start;
        final midpoint = (edge.start + edge.end) / 2;
        // On a shared edge, each face offers a different resize direction.
        // Put its marker just inside the face that owns that gesture.
        final inward = f.points.length == 4
            ? (points[(i + 2) % 4] + points[(i + 3) % 4]) / 2 - midpoint
            : f.bounds.center - midpoint;
        final inset = inward * math.min(.2, 3 / math.max(1, inward.distance));
        final center = midpoint + inset;
        final line = edge.end - edge.start;
        final half = line * math.min(.5, 6 / line.distance);
        final start = active ? edge.start : center - half;
        final end = active ? edge.end : center + half;
        final pen = Paint()..strokeCap = StrokeCap.round;
        c.drawLine(
          start,
          end,
          pen
            ..color = colors.paper
            ..strokeWidth = 5,
        );
        c.drawLine(
          start,
          end,
          pen
            ..color = colors.diagramColor(StockAxis.values[edge.axis].color)
            ..strokeWidth = 3,
        );
      }
    }
  }

  void _dimensions(Canvas c, List<Vector3> corners, {Beam? part}) {
    final center = corners.map(project).reduce((a, b) => a + b) / 8;
    final used = <Rect>[];
    Offset place(Offset preferred, String text) {
      final width = text.length * 7.8 + 10;
      var candidate = preferred;
      for (final dy in [0.0, -18.0, 18.0, -36.0, 36.0]) {
        candidate = Offset(
          preferred.dx.clamp(
            width / 2 + 2,
            math.max(width / 2 + 2, scene.size.width - width / 2 - 2),
          ),
          (preferred.dy + dy).clamp(
            10.0,
            math.max(10.0, scene.size.height - 10),
          ),
        );
        final rect = Rect.fromCenter(
          center: candidate,
          width: width,
          height: 17,
        );
        if (!used.any(rect.overlaps)) {
          used.add(rect);
          break;
        }
      }
      return candidate;
    }

    for (final axis in StockAxis.values) {
      final k = axis.index, bit = 1 << k;
      final active = part != null && k == highlightedSize;
      if (!showAllStockSizes &&
          part != null &&
          highlightedSize != null &&
          !active) {
        continue;
      }
      final color = part == null
          ? colors.muted
          : colors.diagramColor(axis.color);
      final label = part == null
          ? null
          : '${active ? axis.label : axis.letter} ${scene.input.format(part.size[k])}';
      var best = -1.0, start = 0, side = 1.0;
      for (var i = 0; i < 8; i++) {
        if (i & bit != 0) continue;
        final a = project(corners[i]),
            b = project(corners[i | bit]),
            dir = b - a;
        if (dir.distance < (part == null ? 19 : 1.5)) continue;
        final n = Offset(-dir.dy, dir.dx) / dir.distance,
            delta = (a + b) / 2 - center;
        final score = n.dx * delta.dx + n.dy * delta.dy;
        if (score.abs() > best) {
          best = score.abs();
          start = i;
          side = score.sign;
        }
      }
      if (best >= 0) {
        var from = corners[start], to = corners[start | bit];
        if (part != null && part.bevelled) {
          // Stock dimensions refer to the nominal section and centreline length.
          final dir = [part.along, part.across, part.up][k];
          final middle = k == 0
              ? part.pointAt(Vector3.all(.5))
              : (from + to) * .5;
          from = middle - dir * (part.size[k] / 2);
          to = middle + dir * (part.size[k] / 2);
        }
        if (active) {
          c.drawLine(
            project(from),
            project(to),
            Paint()
              ..color = color
              ..strokeWidth = 3,
          );
        }
        final line = _ruler(
          c,
          from,
          to,
          side == 0 ? 20 : side * 22,
          color,
          label: label,
          place: part == null ? null : place,
        );
        if (part != null && line != null) stockLabels[axis] = line.label;
      } else if (part != null && label != null) {
        final p = project(faceCenter(part, k, true));
        final title = active ? editorStrings.depthDirection(label) : '⊙ $label';
        final badge = place(p + const Offset(28, -19), title);
        final pen = Paint()
          ..color = color
          ..strokeWidth = 1.2;
        c.drawLine(p, badge, pen);
        c.drawCircle(p, 3, pen..style = PaintingStyle.stroke);
        stockLabels[axis] = _label(c, badge, title, color);
      }
    }
  }

  ({Offset start, Offset end, Rect label})? _ruler(
    Canvas c,
    Vector3 from,
    Vector3 to,
    double gap,
    Color color, {
    String? label,
    bool selected = false,
    bool showDepth = false,
    Offset Function(Offset, String)? place,
  }) {
    final a = project(from), b = project(to), dir = b - a;
    final text = label ?? scene.input.format(from.distanceTo(to));
    if (dir.distance < 1) {
      if (!showDepth) return null;
      final badge = a + const Offset(0, -17);
      c.drawLine(a, badge, Paint()..color = color);
      return (
        start: a,
        end: badge,
        label: _label(c, badge, text, color, filled: selected),
      );
    }
    final unit = dir / dir.distance, n = Offset(-unit.dy, unit.dx);
    final a1 = a + n * gap, b1 = b + n * gap;
    final pen = Paint()
      ..color = color.withValues(alpha: .78)
      ..strokeWidth = selected ? 2.2 : .9;
    c.drawLine(a + n * (gap.sign * 3), a1 + n * (gap.sign * 4), pen);
    c.drawLine(b + n * (gap.sign * 3), b1 + n * (gap.sign * 4), pen);
    c.drawLine(a1, b1, pen);
    for (final p in [a1, b1]) {
      c.drawLine(p - n * 2.5 - unit * 2, p + n * 2.5 + unit * 2, pen);
    }
    final mid = (a1 + b1) / 2, badge = place?.call(mid, text) ?? mid;
    if ((badge - mid).distance > 1) c.drawLine(mid, badge, pen);
    return (
      start: a1,
      end: b1,
      label: _label(c, badge, text, color, filled: selected),
    );
  }

  Rect _label(
    Canvas c,
    Offset center,
    String value,
    Color color, {
    bool filled = false,
  }) {
    final text = TextPainter(
      text: TextSpan(
        text: value,
        style: mono.copyWith(
          color: filled
              ? (colors.isDark ? EditorPalette.onHighlight : Colors.white)
              : color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final rect = Rect.fromCenter(
      center: center,
      width: text.width + 9,
      height: text.height + 3,
    );
    c.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(3)),
      Paint()..color = filled ? colors.accent : colors.paper,
    );
    text.paint(c, center - Offset(text.width / 2, text.height / 2));
    return rect;
  }

  void _marker(Canvas c, Offset p) {
    c.drawCircle(p, 6, Paint()..color = colors.paper);
    c.drawCircle(
      p,
      5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = colors.accent,
    );
    c.drawCircle(p, 1.7, Paint()..color = colors.accent);
  }

  @override
  bool shouldRepaint(covariant DrawingPainter old) => true;
}
