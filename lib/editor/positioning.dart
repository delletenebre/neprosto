import '../l10n/strings.dart';

import 'dart:math' as math;

import 'model.dart';

enum StockAlignment {
  front,
  middle,
  back,
  offset;

  String get label => switch (this) {
    StockAlignment.front => editorStrings.frontEdge,
    StockAlignment.middle => editorStrings.center,
    StockAlignment.back => editorStrings.backEdge,
    StockAlignment.offset => editorStrings.offset,
  };
}

({double lo, double hi}) span(Beam b, Vector3 n) {
  final v = b.corners.map((p) => p.dot(n));
  return (lo: v.reduce(math.min), hi: v.reduce(math.max));
}

class StockPlacement {
  final Beam part, reference;
  final Vector3 direction;
  bool get alongThickness => direction.dot(part.up).abs() > .99999;
  final double near, far, width, current;
  StockPlacement._(
    this.part,
    this.reference,
    this.direction,
    this.near,
    this.far,
    this.width,
    this.current,
  );
  factory StockPlacement(Beam part, Beam reference, bool alongThickness) {
    var normal = alongThickness ? part.up : part.across;
    var dominant = 0;
    for (var i = 1; i < 3; i++) {
      if (normal[i].abs() > normal[dominant].abs()) dominant = i;
    }
    if (normal[dominant] < 0) normal = -normal;
    final a = span(part, normal), b = span(reference, normal);
    return StockPlacement._(
      part,
      reference,
      normal,
      b.lo,
      b.hi,
      a.hi - a.lo,
      a.lo - b.lo,
    );
  }
  double offset(StockAlignment alignment, double manual) => switch (alignment) {
    StockAlignment.front => 0,
    StockAlignment.middle => (far - near - width) / 2,
    StockAlignment.back => far - near - width,
    StockAlignment.offset => manual,
  };
  Beam placed(StockAlignment alignment, double manual) => part.copy(
    origin: part.origin + direction * (offset(alignment, manual) - current),
  );
}

Beam? adjacentSupport(Project p, Beam rail) {
  final length = span(rail, rail.along);
  final frame = [rail.across, rail.up];
  final cross = frame.map((n) => span(rail, n)).toList();
  double best = double.infinity;
  Beam? nearest;
  for (final b in p.beams) {
    if (b.id == rail.id) continue;
    final end = span(b, rail.along);
    final endGap = math.min(
      (end.hi - length.lo).abs(),
      (end.lo - length.hi).abs(),
    );
    var score = endGap * endGap;
    for (var i = 0; i < 2; i++) {
      final v = span(b, frame[i]), r = cross[i];
      final gap = math.max(0.0, math.max(v.lo - r.hi, r.lo - v.hi));
      score += gap * gap;
    }
    if (score < best) {
      best = score;
      nearest = b;
    }
  }
  return nearest;
}
