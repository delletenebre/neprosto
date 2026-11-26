part of 'viewport.dart';

/// A jig projected on the centreline of a stock edge. The datum stays fixed
/// while the pointer travels along the edge, including in perspective views.
class _ConnectionPlacement {
  _ConnectionPlacement(
    this.scene,
    this.part,
    this.base,
    this.offset,
    this.pattern,
    this.ruler,
  );
  final Scene scene;
  final Beam part;
  final ConnectionBase base;
  final double offset;
  final ConnectionPattern pattern;
  final ConnectionRuler ruler;
  bool get usesRuler => pattern.kind != ConnectionKind.pocket;
  double get length => base.edge.length(part.size);
  late final layout = pattern.layout(
    part,
    base.edge,
    base.fromEnd,
    offset,
    ruler.pitch,
  );
  late final issue = pattern.issue(part, layout);

  static Vector3 point(Beam b, PanelEdge edge, double fraction) {
    final fixed = edge.atMax ? 1.0 : 0.0;
    return b.pointAt(
      Vector3(
        edge.alongWidth ? fixed : fraction,
        edge.alongWidth ? fraction : fixed,
        .5,
      ),
    );
  }

  Offset at(double distance) => scene.camera.project(
    point(
      part,
      base.edge,
      base.fromEnd ? 1 - distance / length : distance / length,
    ),
    scene.size,
  );

  static _ConnectionPlacement? pick(
    Scene scene,
    Editor editor,
    Offset? pointer, {
    bool forClick = false,
  }) {
    final locked = editor.connectionBase;
    final hit = pointer == null ? null : scene.hit(pointer);
    final part = locked != null
        ? editor.project.byId[locked.partId]
        : hit?.beam ??
              (pointer == null
                  ? null
                  : scene.edgeAt(pointer, surface: null)?.face.beam);
    if (part == null || part.hidden) return null;
    final cam = scene.camera;
    var nearest = double.infinity;
    _ConnectionPlacement? best;
    final options = locked != null
        ? [locked.edge]
        : hit != null && hit.face < 4 && hit.isOuterFace
        ? [PanelEdge.values[hit.face]]
        : PanelEdge.values;
    for (final edge in options) {
      final start = point(part, edge, 0), end = point(part, edge, 1);
      final a = cam.project(start, scene.size),
          b = cam.project(end, scene.size),
          line = b - a;
      if (line.distanceSquared < 4) continue;
      final pos = pointer ?? a;
      final cursor = pos - a;
      final t =
          ((cursor.dx * line.dx + cursor.dy * line.dy) / line.distanceSquared)
              .clamp(0.0, 1.0);
      final gap = (pos - (a + line * t)).distance;
      if (gap >= nearest ||
          (forClick &&
              locked != null &&
              (hit == null ? gap > 32 : hit.beam.id != part.id))) {
        continue;
      }
      final f0 = cam.projectionFactor(start), f1 = cam.projectionFactor(end);
      final along = t * f0 / (t * f0 + (1 - t) * f1);
      final far = locked?.fromEnd ?? (along > .5);
      final length = edge.length(part.size);
      final distance = (far ? 1 - along : along) * length;
      final offset = editor.connectionPattern.kind == ConnectionKind.pocket
          ? (pointer == null ? length / 2 : distance)
          : locked == null || pointer == null
          ? editor.connectionRuler.first
          : editor.connectionRuler.snap(distance);
      nearest = gap;
      best = _ConnectionPlacement(
        scene,
        part,
        (partId: part.id, edge: edge, fromEnd: far),
        offset,
        editor.connectionPattern,
        editor.connectionRuler,
      );
    }
    return best;
  }
}

class _ConnectionScalePainter extends CustomPainter {
  _ConnectionScalePainter(this.view, this.colors, this.textStyle);
  final TextStyle textStyle;
  final _ConnectionPlacement view;
  final EditorPalette colors;
  @override
  void paint(Canvas canvas, Size size) {
    final a = view.at(0), b = view.at(view.length);
    final line = b - a;
    if (line.distance < 2) return;
    final normal = Offset(-line.dy, line.dx) / line.distance;
    final pen = Paint()
      ..color = colors.accent
      ..strokeWidth = 2;
    final outline = Paint()
      ..color = colors.accent.withValues(alpha: .40)
      ..strokeWidth = 1.3;
    for (final edge in PanelEdge.values) {
      final axis = [
        for (final t in [0.0, 1.0])
          view.scene.camera.project(
            _ConnectionPlacement.point(view.part, edge, t),
            size,
          ),
      ];
      canvas.drawLine(axis.first, axis.last, outline);
    }
    canvas.drawLine(a, b, pen);
    if (view.usesRuler) {
      final stride = math.max(
        1,
        (8 * view.length / (line.distance * view.ruler.pitch)).ceil(),
      );
      final count = ((view.length - view.ruler.first) / view.ruler.pitch)
          .floor();
      // Bound rendering work when a zoomed edge extends far beyond the viewport.
      final drawStride = math.max(stride, (count / 2000).ceil());
      for (var n = 0; n <= count; n += drawStride) {
        final at = view.at(view.ruler.first + n * view.ruler.pitch);
        canvas.drawLine(at - normal * 3, at + normal * 3, pen);
      }
    }
    canvas.drawCircle(a, 5, Paint()..color = colors.field);
    canvas.drawCircle(a, 5, pen..style = PaintingStyle.stroke);
    pen.style = PaintingStyle.fill;
    final labelBounds = <Rect>[];
    void mark(Offset center, String value) {
      final label = TextPainter(
        text: TextSpan(
          text: value,
          style: textStyle.copyWith(
            fontSize: 12,
            color: colors.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final rect = Rect.fromCenter(
        center: center - normal * 15,
        width: label.width + 6,
        height: label.height + 2,
      );
      if (!labelBounds.any((r) => r.overlaps(rect))) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(3)),
          Paint()..color = colors.field,
        );
        label.paint(canvas, rect.topLeft + const Offset(3, 1));
        labelBounds.add(rect);
      }
      label.dispose();
    }

    mark(a, '0');
    final color = view.issue == null ? colors.accent : colors.danger;
    Offset stock(Vector3 p) => view.scene.camera.project(
      view.part.origin +
          view.part.along * p.x +
          view.part.across * p.y +
          view.part.up * p.z,
      size,
    );
    final geometry = Paint()
      ..color = color.withValues(alpha: .8)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke;
    for (final hole in view.layout.faces) {
      final drill = hole.drills(view.part.size).first;
      final points = [
        for (var n = 0; n < 36; n++)
          stock(
            drill.entry +
                Vector3(
                      math.cos(n * math.pi / 18),
                      math.sin(n * math.pi / 18),
                      0,
                    ) *
                    hole.diameter *
                    .5,
          ),
      ];
      canvas.drawPath(Path()..addPolygon(points, true), geometry);
    }
    for (final drill in [
      for (final h in view.layout.faces) ...h.drills(view.part.size).skip(1),
      for (final h in view.layout.edges) ...h.drills(view.part.size),
    ]) {
      canvas.drawLine(stock(drill.entry), stock(drill.stop), geometry);
    }
    for (final (index, item) in view.pattern.stations.indexed) {
      final c = view.at(view.offset + index * view.ruler.pitch);
      final r = item == ConnectionKind.dowel ? 4.0 : 6.0;
      canvas.drawCircle(c, r, Paint()..color = colors.field);
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      canvas.drawCircle(c, 1.4, Paint()..color = color);
      mark(
        c,
        view.scene.input.unit.format(view.offset + index * view.ruler.pitch),
      );
    }
  }

  @override
  bool shouldRepaint(_ConnectionScalePainter old) => true;
}
