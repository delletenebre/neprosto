part of 'model.dart';

bool facesMeet(Beam a, int fa, Beam b, int fb) {
  final gap = _faceGap(a, fa, b, fb);
  return gap != null && gap.from.distanceTo(gap.to) < 1e-6;
}

/// Clip the facing polygons in their common plane. A ruler remains normal
/// to the shelves when one slides sideways or the whole assembly rotates.
typedef _FaceGap = ({
  Vector3 from,
  Vector3 to,
  Vector3 direction,
  List<Vector3> polygon,
});

_FaceGap? _faceGap(Beam a, int fa, Beam b, int fb) {
  final n = a.faceNormal(fa);
  if (n.dot(b.faceNormal(fb)) > -1 + 1e-7) return null;
  if (a.rabbets.isEmpty && b.rabbets.isEmpty) {
    return _polygonGap(
      faceCorners[fa].map(a.corner).toList(),
      faceCorners[fb].map(b.corner).toList(),
      n,
    );
  }
  // Slice perpendicular to the measured face so only exposed surfaces are used.
  final targets = [
    for (final strip in b.solidStrips(vertical: fb ~/ 2 == 2))
      faceCorners[fb].map(strip.corner).toList(),
  ];
  _FaceGap? best;
  var nearest = double.infinity;
  for (final strip in a.solidStrips(vertical: fa ~/ 2 == 2)) {
    final face = faceCorners[fa].map(strip.corner).toList();
    for (final other in targets) {
      final gap = _polygonGap(face, other, n);
      if (gap == null) continue;
      final distance = gap.to.distanceToSquared(gap.from);
      if (distance < nearest) {
        nearest = distance;
        best = gap;
      }
    }
  }
  return best;
}

_FaceGap? _polygonGap(List<Vector3> face, List<Vector3> other, Vector3 n) {
  final distance = (other.first - face.first).dot(n);
  if (distance < -.00001) return null;
  var polygon = other.map((p) => p - n * distance).toList();
  for (var i = 0; i < 4; i++) {
    final start = face[i],
        edge = face[(i + 1) % 4] - start,
        inward = n.cross(edge).normalized();
    if (polygon.isEmpty) return null;
    polygon = clipPolygon(polygon, (p) => (p - start).dot(inward));
  }
  if (polygon.length < 3) return null;
  final base = polygon.first;
  var area = 0.0;
  for (var i = 1; i < polygon.length - 1; i++) {
    area += (polygon[i] - base).cross(polygon[i + 1] - base).dot(n);
  }
  if (area.abs() < 1e-6) return null;
  final p = polygon.reduce((a, b) => a + b) / polygon.length.toDouble();
  return (
    from: p,
    to: p + n * math.max(0, distance),
    direction: n,
    polygon: polygon,
  );
}

Dimension? shelfClearance(Beam first, Beam second) {
  if (first.id == second.id) return null;
  // Prefer wide shelf faces when two touching edges are also coplanar.
  final order = [0, 1, 2]
    ..sort((a, b) => first.size[a].compareTo(first.size[b]));
  for (final dim in order) {
    for (final f in [2 * dim, 2 * dim + 1]) {
      for (var g = 0; g < 6; g++) {
        final segment = _faceGap(first, f, second, g);
        if (segment == null) continue;
        Anchor anchor(Beam beam, Vector3 p, int face) =>
            Anchor(p, beam.id, 0, beam.localAt(p), 'Грань полки', face);
        return Dimension(
          anchor(first, segment.from, f),
          anchor(second, segment.to, g),
          clearance: true,
        );
      }
    }
  }
  return null;
}
