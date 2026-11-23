import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'model.dart';
import 'move_snap.dart';
import 'stock_axis.dart';
import 'positioning.dart';
import 'scene.dart';
import 'contact.dart';

const ink = Color(0xff242428),
    muted = Color(0xff67676d),
    accent = Color(0xff176cc0),
    pale = Color(0xffe2edfc),
    line = Color(0xffd5d5d9),
    paper = Color(0xfffafaf6);
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

class DrawingPainter extends CustomPainter {
  final stockLabels = <StockAxis, Rect>{};
  final Scene scene;
  final Set<int> selection;
  final int? referenceId;
  final Beam? alignmentSupport;
  final Dimension? gapPreview;
  final WorkPlane plane;
  final Anchor? hover, first;
  final Beam? preview;
  final Color previewColor;
  final SceneFace? activeFace;
  final bool grid, dimensions, dimensionsVisible;
  final double gridStep;
  final Set<int> overlaps;
  final int? handleAxis;
  final Project? original;
  final (Vector3, Vector3)? guide;
  final List<MoveGuide> moveGuides;
  final int rotationAxis;
  final int? highlightedSize;
  final bool localRotation;
  final List<Vector3>? rotationBasis;
  final double angle;
  DrawingPainter({
    required this.scene,
    required this.selection,
    this.referenceId,
    this.alignmentSupport,
    this.gapPreview,
    required this.plane,
    this.hover,
    this.first,
    this.preview,
    this.previewColor = accent,
    this.activeFace,
    required this.grid,
    required this.dimensions,
    this.dimensionsVisible = true,
    required this.gridStep,
    this.overlaps = const {},
    this.handleAxis,
    this.original,
    this.rotationAxis = 2,
    this.highlightedSize,
    this.localRotation = false,
    this.rotationBasis,
    this.guide,
    this.moveGuides = const [],
    this.angle = 0,
  });
  Offset project(Vector3 p) => scene.camera.project(p, scene.size);
  @override
  void paint(Canvas c, Size s) {
    stockLabels.clear();
    c.save();
    c.clipRect(Offset.zero & s);
    c.drawRect(Offset.zero & s, Paint()..color = paper);
    if (grid) _grid(c, s);
    _workspace(c);
    if (original != null) {
      for (final b in original!.beams.where((b) => selection.contains(b.id))) {
        final corners = b.corners;
        for (var i = 0; i < 8; i++) {
          for (final bit in [1, 2, 4]) {
            if ((i & bit) == 0) {
              c.drawLine(
                project(corners[i]),
                project(corners[i | bit]),
                Paint()
                  ..color = const Color(0xff87958a)
                  ..strokeWidth = 1,
              );
            }
          }
        }
      }
    }
    for (final f in scene.faces) {
      _face(c, f);
    }
    if (original != null && selection.isNotEmpty) _rotation(c);
    if (activeFace case final face?) {
      c.drawPath(face.path, Paint()..color = accent.withValues(alpha: .22));
      c.drawPath(
        face.path,
        Paint()
          ..color = accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
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
      _ruler(c, g.from, g.to, -17, accent);
      if (d.clearance) {
        _marker(c, project(g.from));
        _marker(c, project(g.to));
      }
    }
    if (handleAxis != null && selection.length == 1) {
      final b = scene.project.byId[selection.first];
      if (b != null) {
        for (final positive in [false, true]) {
          final at = project(faceCenter(b, handleAxis!, positive));
          c.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: at, width: 10, height: 10),
              const Radius.circular(2),
            ),
            Paint()..color = Colors.white,
          );
          c.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: at, width: 10, height: 10),
              const Radius.circular(2),
            ),
            Paint()
              ..color = accent
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
        }
      }
    }
    if (guide != null) {
      final (a, b) = guide!;
      final start = project(a), end = project(b), delta = end - start;
      if (delta.distance > 1) {
        final d = delta / delta.distance;
        for (double i = -15; i < delta.distance + 15; i += 8) {
          c.drawLine(
            start + d * i,
            start + d * (i + 4),
            Paint()
              ..color = accent
              ..strokeWidth = 1.5,
          );
        }
      }
      _marker(c, end);
      _label(
        c,
        start + const Offset(0, -15),
        'Совпадение',
        accent,
        filled: true,
      );
    }
    for (final g in moveGuides) {
      final paint = Paint()
        ..color = accent
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
        final unit = scene.project.unit;
        _label(
          c,
          (start + end) / 2 + const Offset(0, -15),
          'Зазор ${unit.format(g.gap!)} ${unit.symbol}',
          accent,
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
    if (first case final a?) {
      _marker(c, project(a.resolve(scene.project)));
      if (hover case final b? when dimensionsVisible) {
        _ruler(
          c,
          a.resolve(scene.project),
          b.resolve(scene.project),
          -12,
          accent,
        );
      }
    }
    if (hover case final a?) {
      final screen = project(a.resolve(scene.project));
      if (a.beam != null) {
        _marker(c, screen);
        _label(c, screen + const Offset(0, -24), a.label, accent, filled: true);
      } else {
        c.drawCircle(screen, 3, Paint()..color = accent);
      }
    }
    if (alignmentSupport case final support?) _drawSupport(c, s, support);
    c.restore();
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
        text: 'Опора · ${support.name}',
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
    final pivot = Bounds3.points(
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
        ..color = Colors.white.withValues(alpha: .85)
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
          : 'Ось ${'XYZ'[rotationAxis]}',
      color,
    );
  }

  void _worldLine(Canvas c, Vector3 a, Vector3 b, Paint pen) {
    final camera = scene.camera;
    if (camera.perspective) {
      final limit = camera.eyeDistance * .95;
      final da = (a - camera.target).dot(camera.eye),
          db = (b - camera.target).dot(camera.eye);
      if (da > limit && db > limit) return;
      if (da > limit || db > limit) {
        final cut = a + (b - a) * ((limit - da) / (db - da));
        if (da > limit) {
          a = cut;
        } else {
          b = cut;
        }
      }
    }
    c.drawLine(project(a), project(b), pen);
  }

  void _workspace(Canvas c) {
    final corners = scene.project.workspaceCorners;
    if (corners.isEmpty) return;
    final pen = Paint()
      ..strokeWidth = 1.2
      ..color = const Color(0xff95a6b4);
    for (var i = 0; i < corners.length; i++) {
      for (final bit in [1, 2, 4]) {
        if (i & bit == 0) _worldLine(c, corners[i], corners[i | bit], pen);
      }
    }
  }

  void _grid(Canvas c, Size s) {
    final camera = scene.camera;
    if (camera.eye.dot(plane.normal).abs() < .025) return;
    final across = <Vector3>[];
    if (camera.perspective) {
      final center = camera.target - plane.origin, r = camera.eyeDistance * 3;
      for (final sign in [-1.0, 1.0]) {
        across.add(center + (plane.u + plane.v) * (sign * r));
      }
    } else {
      across.addAll(
        [
          Offset.zero,
          Offset(s.width, 0),
          s.bottomRight(Offset.zero),
          Offset(0, s.height),
        ].map((p) => camera.onPlane(p, s, plane)! - plane.origin),
      );
    }
    var step = gridStep;
    while (step * camera.scale < 18) {
      step *= 2;
    }
    double minU = double.infinity, maxU = -minU, minV = minU, maxV = -minU;
    for (final a in across) {
      minU = math.min(minU, a.dot(plane.u));
      maxU = math.max(maxU, a.dot(plane.u));
      minV = math.min(minV, a.dot(plane.v));
      maxV = math.max(maxV, a.dot(plane.v));
    }
    while ((maxU - minU + maxV - minV) / step > 240) {
      step *= 2;
    }
    Vector3 pt(double u, double v) => plane.origin + plane.u * u + plane.v * v;
    Paint paint(int i) => Paint()
      ..color = i == 0
          ? const Color(0xffc3cbbb)
          : i % 5 == 0
          ? const Color(0xffdce1d5)
          : const Color(0xffe9ece3)
      ..strokeWidth = i == 0 ? 1 : .7;
    for (var i = (minU / step).floor(); i <= (maxU / step).ceil(); i++) {
      _worldLine(c, pt(i * step, minV), pt(i * step, maxV), paint(i));
    }
    for (var i = (minV / step).floor(); i <= (maxV / step).ceil(); i++) {
      _worldLine(c, pt(minU, i * step), pt(maxU, i * step), paint(i));
    }
  }

  void _face(Canvas c, SceneFace f) {
    final selected = selection.contains(f.beam.id);
    final reference = f.beam.id == referenceId;
    final light = Vector3(-.38, -.48, .79).normalized();
    final shade = (f.normal.dot(light) * .22 + .57 + (f.beam.id % 4) * .018)
        .clamp(0.0, 1.0);
    var fill = Color.lerp(
      const Color(0xff986d45),
      const Color(0xfff2d8ae),
      shade,
    )!;
    if (f.face <= 1) fill = Color.lerp(fill, const Color(0xffac8059), .25)!;
    if (overlaps.contains(f.beam.id)) {
      fill = Color.lerp(fill, const Color(0xffda7657), .53)!;
    }
    if (reference) fill = Color.lerp(fill, const Color(0xff80b6ce), .70)!;
    if (f.beam.id == alignmentSupport?.id) {
      fill = Color.lerp(fill, supportColor, .38)!;
    }
    if (selected) fill = Color.lerp(fill, const Color(0xffb8c79a), .44)!;
    if (selected && highlightedSize == f.face ~/ 2) {
      fill = Color.lerp(fill, StockAxis.values[highlightedSize!].color, .33)!;
    }
    if (original != null && !selected) fill = Color.lerp(fill, paper, .58)!;
    c.drawPath(f.path, Paint()..color = fill);
    // Fine longitudinal fibres follow the part even when the assembly rotates.
    c.save();
    c.clipPath(f.path);
    final grain = Paint()
      ..color = const Color(0xff81582e).withValues(alpha: .22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = .65;
    final points = f.points;
    final longEdge = f.world[1] - f.world[0];
    final reverse = f.face > 1 && longEdge.dot(f.beam.along).abs() < .01;
    final a = points[0],
        b = points[reverse ? 3 : 1],
        d = points[reverse ? 1 : 3];
    final u = b - a, v = d - a;
    final count = (v.distance / 5).clamp(2, 24).toInt();
    for (var i = 1; i <= count; i++) {
      final seed = math.sin(i * 12.31 + f.beam.id * 7.1),
          t = (i + seed * .31) / (count + 1);
      final begin = a + v * t, end = begin + u;
      final wave = v * (math.sin(i * 2.1 + f.beam.id) * .045);
      final path = Path()
        ..moveTo(begin.dx, begin.dy)
        ..cubicTo(
          begin.dx + u.dx * .30 + wave.dx,
          begin.dy + u.dy * .30 + wave.dy,
          end.dx - u.dx * .28 - wave.dx,
          end.dy - u.dy * .28 - wave.dy,
          end.dx,
          end.dy,
        );
      c.drawPath(path, grain);
    }
    c.restore();
    c.drawPath(
      f.path,
      Paint()
        ..color = selected ? accent : const Color(0xff836e53)
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 1.65 : .8
        ..strokeJoin = StrokeJoin.round,
    );
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
      if (part != null && highlightedSize != null && !active) continue;
      final color = part == null ? const Color(0xff63735d) : axis.color;
      final label = part == null
          ? null
          : '${active ? axis.label : axis.letter} ${scene.project.unit.format(part.size[k])}';
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
        final rect = _ruler(
          c,
          from,
          to,
          side == 0 ? 20 : side * 22,
          color,
          label: label,
          place: part == null ? null : place,
        );
        if (part != null && rect != null) stockLabels[axis] = rect;
      } else if (part != null && label != null) {
        final p = project(faceCenter(part, k, true));
        final title = active ? '$label · в глубину' : '⊙ $label';
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

  Rect? _ruler(
    Canvas c,
    Vector3 from,
    Vector3 to,
    double gap,
    Color color, {
    String? label,
    Offset Function(Offset, String)? place,
  }) {
    final a = project(from), b = project(to), dir = b - a;
    if (dir.distance < 1) return null;
    final unit = dir / dir.distance, n = Offset(-unit.dy, unit.dx);
    final a1 = a + n * gap, b1 = b + n * gap;
    final pen = Paint()
      ..color = color.withValues(alpha: .78)
      ..strokeWidth = .9;
    c.drawLine(a + n * (gap.sign * 3), a1 + n * (gap.sign * 4), pen);
    c.drawLine(b + n * (gap.sign * 3), b1 + n * (gap.sign * 4), pen);
    c.drawLine(a1, b1, pen);
    for (final p in [a1, b1]) {
      c.drawLine(p - n * 2.5 - unit * 2, p + n * 2.5 + unit * 2, pen);
    }
    final text = label ?? scene.project.unit.format(from.distanceTo(to));
    final mid = (a1 + b1) / 2, badge = place?.call(mid, text) ?? mid;
    if ((badge - mid).distance > 1) c.drawLine(mid, badge, pen);
    return _label(c, badge, text, color);
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
          color: filled ? Colors.white : color,
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
      Paint()..color = filled ? accent : paper,
    );
    text.paint(c, center - Offset(text.width / 2, text.height / 2));
    return rect;
  }

  void _marker(Canvas c, Offset p) {
    c.drawCircle(p, 6, Paint()..color = Colors.white);
    c.drawCircle(
      p,
      5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = accent,
    );
    c.drawCircle(p, 1.7, Paint()..color = accent);
  }

  @override
  bool shouldRepaint(covariant DrawingPainter old) => true;
}
