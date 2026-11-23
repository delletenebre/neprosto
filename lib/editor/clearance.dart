part of 'model.dart';

/// Clip the facing polygons in their common plane. A ruler remains normal
/// to the shelves when one slides sideways or the whole assembly rotates.
({Vector3 from, Vector3 to, Vector3 direction})? _faceGap(
  Beam a,
  int fa,
  Beam b,
  int fb,
) {
  final n = a.faceNormal(fa);
  if (n.dot(b.faceNormal(fb)) > -1 + 1e-7) return null;
  final face = faceCorners[fa].map(a.corner).toList(),
      other = faceCorners[fb].map(b.corner).toList();
  final distance = (other.first - face.first).dot(n);
  if (distance < -.00001) return null;
  var polygon = other.map((p) => p - n * distance).toList();
  for (var i = 0; i < 4; i++) {
    final start = face[i],
        edge = face[(i + 1) % 4] - start,
        inward = n.cross(edge).normalized();
    final clipped = <Vector3>[];
    if (polygon.isEmpty) return null;
    var previous = polygon.last, prev = (previous - start).dot(inward);
    for (final current in polygon) {
      final d = (current - start).dot(inward);
      if ((prev >= 0) != (d >= 0)) {
        clipped.add(previous + (current - previous) * (prev / (prev - d)));
      }
      if (d >= 0) clipped.add(current);
      previous = current;
      prev = d;
    }
    polygon = clipped;
  }
  if (polygon.length < 3) return null;
  final base = polygon.first;
  var area = 0.0;
  for (var i = 1; i < polygon.length - 1; i++) {
    area += (polygon[i] - base).cross(polygon[i + 1] - base).dot(n);
  }
  if (area.abs() < 1e-6) return null;
  final p = polygon.reduce((a, b) => a + b) / polygon.length.toDouble();
  return (from: p, to: p + n * math.max(0, distance), direction: n);
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
