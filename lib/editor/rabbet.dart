part of 'model.dart';

/// Corners in counterclockwise order, looking at the stock from its end (+X).
enum RabbetEdge {
  bottomLeft(false, false),
  bottomRight(true, false),
  topRight(true, true),
  topLeft(false, true);

  const RabbetEdge(this.right, this.top);
  final bool right, top;
  String get label => switch (this) {
    bottomLeft => editorStrings.rabbetBottomLeft,
    bottomRight => editorStrings.rabbetBottomRight,
    topRight => editorStrings.rabbetTopRight,
    topLeft => editorStrings.rabbetTopLeft,
  };
}

typedef Rabbet = ({double width, double depth});

Map<RabbetEdge, Rabbet> _readRabbets(Object? data) {
  if (data == null) return const {};
  if (data is! Map) throw FormatException(editorStrings.invalidRabbet);
  final cuts = <RabbetEdge, Rabbet>{};
  for (final entry in data.entries) {
    final edge = RabbetEdge.values
        .where((e) => e.name == entry.key)
        .firstOrNull;
    if (edge == null) throw FormatException(editorStrings.invalidRabbet);
    if (entry.value case [num w, num d]
        when w.isFinite && d.isFinite && w > 0 && d > 0) {
      cuts[edge] = (width: w.toDouble(), depth: d.toDouble());
    } else {
      throw FormatException(editorStrings.invalidRabbet);
    }
  }
  return cuts;
}

extension RabbetGeometry on Beam {
  /// Keep a web of wood between cuts that meet in the other dimension.
  double minimumSize(int dim) {
    if (dim == 0) return minimumLength;
    if (rabbets.isEmpty) return 0;
    final width = dim == 1;
    double extent(Rabbet c) => width ? c.width : c.depth;
    double other(Rabbet c) => width ? c.depth : c.width;
    var limit = 0.0;
    for (final a in rabbets.entries) {
      limit = math.max(limit, extent(a.value));
      for (final b in rabbets.entries) {
        final oppositeY = a.key.right != b.key.right;
        final oppositeZ = a.key.top != b.key.top;
        if (!(width ? oppositeY : oppositeZ)) continue;
        if (!(width ? oppositeZ : oppositeY) ||
            other(a.value) + other(b.value) >= size[width ? 2 : 1]) {
          limit = math.max(limit, extent(a.value) + extent(b.value));
        }
      }
    }
    return limit + 1e-6;
  }

  bool get cutsFit =>
      size.x >= minimumLength &&
      size.y >= minimumSize(1) &&
      size.z >= minimumSize(2);

  /// Normalized Y/Z outline. The same vertices drive the diagram and the solid.
  List<Vector3> get sectionOutline {
    final points = <Vector3>[];
    for (final edge in RabbetEdge.values) {
      final y = edge.right ? 1.0 : 0.0, z = edge.top ? 1.0 : 0.0;
      final cut = rabbets[edge];
      if (cut == null) {
        points.add(Vector3(0, y, z));
        continue;
      }
      final insetY = y + (edge.right ? -1 : 1) * cut.width / size.y;
      final insetZ = z + (edge.top ? -1 : 1) * cut.depth / size.z;
      final horizontal = Vector3(0, insetY, z),
          vertical = Vector3(0, y, insetZ);
      final fromVertical = edge.right == edge.top;
      points.addAll([
        fromVertical ? vertical : horizontal,
        Vector3(0, insetY, insetZ),
        fromVertical ? horizontal : vertical,
      ]);
    }
    return points;
  }

  /// Each side is ordered like the corresponding stock face, including the
  /// two new faces inside each rabbet. The end caps can be concave.
  Iterable<({int face, List<Vector3> local})> get profileFaces sync* {
    final section = sectionOutline;
    yield (face: 0, local: section.reversed.toList());
    yield (face: 1, local: [for (final p in section) p.clone()..x = 1]);
    for (var i = 0; i < section.length; i++) {
      final a = section[i], b = section[(i + 1) % section.length];
      final face = a.z == b.z ? (b.y > a.y ? 4 : 5) : (b.z > a.z ? 3 : 2);
      yield (
        face: face,
        local: [
          for (final k in faceCorners[face])
            Vector3(
              (k & 1).toDouble(),
              k & 2 == 0 ? math.min(a.y, b.y) : math.max(a.y, b.y),
              k & 4 == 0 ? math.min(a.z, b.z) : math.max(a.z, b.z),
            ),
        ],
      );
    }
  }

  /// Convex horizontal strips for collision queries. Trim both end planes to
  /// each strip so compound mitres remain coplanar across the whole profile.
  Iterable<Beam> solidStrips({bool vertical = false}) sync* {
    if (rabbets.isEmpty) {
      yield this;
      return;
    }
    double fraction(Rabbet cut) =>
        vertical ? cut.width / size.y : cut.depth / size.z;
    bool high(RabbetEdge edge) => vertical ? edge.right : edge.top;
    final levels = {
      0.0,
      1.0,
      for (final e in rabbets.entries)
        high(e.key) ? 1 - fraction(e.value) : fraction(e.value),
    }.toList()..sort();
    for (var i = 1; i < levels.length; i++) {
      final lo = levels[i - 1], hi = levels[i], middle = (lo + hi) / 2;
      var startSpan = 0.0, endSpan = 1.0;
      for (final e in rabbets.entries) {
        if ((high(e.key) ? 1 - middle : middle) >= fraction(e.value)) continue;
        final amount = vertical
            ? e.value.depth / size.z
            : e.value.width / size.y;
        if (vertical ? e.key.top : e.key.right) {
          endSpan = math.min(endSpan, 1 - amount);
        } else {
          startSpan = math.max(startSpan, amount);
        }
      }
      final left = vertical ? lo : startSpan, right = vertical ? hi : endSpan;
      final bottom = vertical ? startSpan : lo, top = vertical ? endSpan : hi;
      final midZ = (bottom + top) / 2;
      final midY = (left + right) / 2;
      final start = offsetAt(startCut, midY, midZ),
          end = size.x + offsetAt(endCut, midY, midZ);
      yield Beam(
        id,
        name,
        origin +
            along * start +
            across * (left * size.y) +
            up * (bottom * size.z),
        Vector3(end - start, size.y * (right - left), size.z * (top - bottom)),
        along,
        across,
        startCut: (
          y: startCut.y * (right - left),
          z: startCut.z * (top - bottom),
        ),
        endCut: (y: endCut.y * (right - left), z: endCut.z * (top - bottom)),
      );
    }
  }
}
