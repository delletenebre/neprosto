part of 'model.dart';

extension BoringEdgeGeometry on PanelEdge {
  double centerInset(PanelHole hole, Vector3 size) {
    final offset = alongWidth ? hole.x : hole.y;
    final fromMax = alongWidth ? hole.fromEnd : hole.fromFarEdge;
    return atMax == fromMax ? offset : width(size) - offset;
  }
}

/// The bolt axis is measured from the reference face of the main hole.
typedef BoltBore = ({double diameter, double faceOffset});

extension BoltBoreGeometry on BoltBore {
  bool fitsSection(double thickness, double? depth) =>
      diameter.isFinite &&
      diameter > 0 &&
      faceOffset.isFinite &&
      faceOffset >= diameter / 2 &&
      faceOffset + diameter / 2 <= thickness &&
      depth != null &&
      faceOffset < depth;
}

/// A cylindrical drilling in stock coordinates, from its entry to its stop.
class PanelDrill {
  PanelDrill(
    this.face,
    this.entry,
    this.stop,
    this.diameter, {
    this.through = false,
    this.angled = false,
  });
  final int face;
  final Vector3 entry, stop;
  final double diameter;
  final bool through, angled;
  int get axis => face ~/ 2;
  double get depth => entry.distanceTo(stop);

  bool intersects(PanelDrill other) {
    if (angled || other.angled) {
      // Closest points of the two finite axes. A capsule envelope includes
      // the shoulder of a stepped bit at either end.
      final u = stop - entry,
          v = other.stop - other.entry,
          w = entry - other.entry;
      final a = u.dot(u),
          b = u.dot(v),
          c = v.dot(v),
          d = u.dot(w),
          e = v.dot(w);
      if (a == 0 || c == 0) return false;
      final det = a * c - b * b;
      var t = det > 1e-10 ? ((b * e - c * d) / det).clamp(0.0, 1.0) : 0.0;
      final n = ((b * t + e) / c).clamp(0.0, 1.0);
      t = ((b * n - d) / a).clamp(0.0, 1.0);
      return (w + u * t - v * n).length < (diameter + other.diameter) / 2;
    }
    final a = axis, b = other.axis;
    final r = diameter / 2, s = other.diameter / 2;
    double low(PanelDrill d) => math.min(d.entry[d.axis], d.stop[d.axis]);
    double high(PanelDrill d) => math.max(d.entry[d.axis], d.stop[d.axis]);
    if (a == b) {
      if (high(this) <= low(other) || high(other) <= low(this)) return false;
      final u = (a + 1) % 3, v = (a + 2) % 3;
      final du = entry[u] - other.entry[u], dv = entry[v] - other.entry[v];
      return du * du + dv * dv < (r + s) * (r + s);
    }
    // At the closest point of each finite axis, the circular cross-sections
    // must overlap along their remaining common coordinate.
    double gap(double coordinate, PanelDrill d) =>
        (coordinate - coordinate.clamp(low(d), high(d))).abs();
    final da = gap(other.entry[a], this), db = gap(entry[b], other);
    if (da >= s || db >= r) return false;
    final c = 3 - a - b;
    return (entry[c] - other.entry[c]).abs() <
        math.sqrt(s * s - da * da) + math.sqrt(r * r - db * db);
  }
}

/// A user-picked zero in physical millimetres on the drilling surface.
typedef DrillDatum = ({double u, double v});

DrillDatum? _readDrillDatum(dynamic value) {
  if (value == null) return null;
  if (value case [num u, num v] when u.isFinite && v.isFinite) {
    return (u: u.toDouble(), v: v.toDouble());
  }
  throw FormatException(editorStrings.invalidPartGeometry);
}

/// Offsets to the drill centre are measured in millimetres along the stock's
/// length and width. Each offset can be anchored to either end of its axis.
class PanelHole {
  const PanelHole(
    this.x,
    this.y,
    this.diameter, {
    this.name = '',
    this.datum,
    this.anchorFace,
    this.fromEnd = false,
    this.fromFarEdge = false,
    this.depth,
    this.back = false,
    this.boringEdge,
    this.boltBore,
  });
  final double x, y, diameter;
  final String name;
  final DrillDatum? datum;
  final int? anchorFace;
  final bool fromEnd, fromFarEdge, back;
  final double? depth;
  final PanelEdge? boringEdge;
  final BoltBore? boltBore;
  Record get _values => (
    x,
    y,
    diameter,
    fromEnd,
    fromFarEdge,
    depth,
    back,
    name,
    boringEdge,
    boltBore,
    datum,
    anchorFace,
  );
  @override
  bool operator ==(Object other) =>
      other is PanelHole && _values == other._values;
  @override
  int get hashCode => _values.hashCode;

  double centerX(Vector3 size) => fromEnd ? size.x - x : x;
  double centerY(Vector3 size) => fromFarEdge ? size.y - y : y;
  Iterable<PanelDrill> drills(Vector3 size) sync* {
    final entry = Vector3(centerX(size), centerY(size), back ? size.z : 0);
    final length = depth ?? size.z;
    yield PanelDrill(
      back ? 5 : 4,
      entry,
      entry.clone()..z += back ? -length : length,
      diameter,
      through: depth == null,
    );
    if (boltBore case final bolt? when boringEdge != null) {
      final edge = boringEdge!;
      final end = entry.clone()
        ..z = back ? size.z - bolt.faceOffset : bolt.faceOffset;
      final axis = edge.faceIndex ~/ 2;
      yield PanelDrill(
        edge.faceIndex,
        end.clone()..[axis] = edge.atMax ? size[axis] : 0,
        end,
        bolt.diameter,
      );
    }
  }

  double minimumSize(int dim) {
    final bolt = boltBore;
    if (dim == 2) {
      return math.max(
        depth == null ? 0.0 : depth! + 1e-6,
        bolt == null ? 0.0 : bolt.faceOffset + bolt.diameter / 2,
      );
    }
    final alongEdge = boringEdge != null && boringEdge!.faceIndex ~/ 2 != dim;
    final width = alongEdge && bolt != null
        ? math.max(diameter, bolt.diameter)
        : diameter;
    return (dim == 0 ? x : y) + width / 2;
  }

  bool fits(Vector3 size) {
    final radius = diameter / 2;
    if (boltBore case final bolt?) {
      final edge = boringEdge, z = depth;
      if (edge == null || !bolt.fitsSection(size.z, z ?? size.z)) return false;
      final along = edge.alongWidth ? y : x;
      if (along < bolt.diameter / 2 ||
          along + bolt.diameter / 2 > edge.length(size)) {
        return false;
      }
    }
    return diameter.isFinite &&
        radius > 0 &&
        x >= radius &&
        y >= radius &&
        x + radius <= size.x &&
        y + radius <= size.y &&
        (depth == null || (depth! > 0 && depth! < size.z));
  }

  Map<String, Object> toJson() => {
    if (datum case final p?) 'datum': [p.u, p.v],
    'anchorFace': ?anchorFace,
    'x': x,
    'y': y,
    'diameter': diameter,
    if (name.isNotEmpty) 'name': name,
    if (fromEnd) 'fromEnd': true,
    if (fromFarEdge) 'fromFarEdge': true,
    'depth': ?depth,
    if (back) 'back': true,
    if (boringEdge != null) 'hingeEdge': boringEdge!.name,
    if (boltBore case final bolt?)
      'boltBore': {'diameter': bolt.diameter, 'faceOffset': bolt.faceOffset},
  };
  factory PanelHole.fromJson(dynamic data) {
    if (data case {'x': num x, 'y': num y, 'diameter': num d}
        when x.isFinite &&
            y.isFinite &&
            d.isFinite &&
            x > 0 &&
            y > 0 &&
            d > 0) {
      final depth = data['depth'];
      if (depth == null || (depth is num && depth.isFinite && depth > 0)) {
        final edge = PanelEdge.values.asNameMap()[data['hingeEdge']];
        BoltBore? bolt;
        if (data['boltBore'] != null) {
          if (data['boltBore']
              case {'diameter': num bit, 'faceOffset': num offset}
              when edge != null &&
                  bit.isFinite &&
                  bit > 0 &&
                  offset.isFinite &&
                  offset > 0) {
            bolt = (diameter: bit.toDouble(), faceOffset: offset.toDouble());
          } else {
            throw FormatException(editorStrings.invalidPartGeometry);
          }
        }
        return PanelHole(
          x.toDouble(),
          y.toDouble(),
          d.toDouble(),
          datum: _readDrillDatum(data['datum']),
          anchorFace: data['anchorFace'] is int
              ? data['anchorFace'] as int
              : null,
          name: data['name'] as String? ?? '',
          fromEnd: data['fromEnd'] as bool? ?? false,
          fromFarEdge: data['fromFarEdge'] as bool? ?? false,
          boringEdge: edge,
          boltBore: bolt,
          back: data['back'] as bool? ?? false,
          depth: (depth as num?)?.toDouble(),
        );
      }
    }
    throw FormatException(editorStrings.invalidPartGeometry);
  }
}

enum EdgeHoleKind {
  plain,
  confirmat,
  dowel,
  pocket,
  openingSensor,
  pushToOpen;

  String get label => switch (this) {
    plain => editorStrings.boltBoreOption,
    confirmat => editorStrings.confirmat,
    dowel => editorStrings.dowel,
    pocket => 'Pocket Hole',
    openingSensor => editorStrings.openingSensor,
    pushToOpen => 'Push-to-open',
  };
}

/// A standalone drilling from an edge. The distance along the edge is
/// anchored to its chosen end, and the height is measured from face A.
typedef EdgeHole = ({
  PanelEdge edge,
  EdgeHoleKind kind,
  DrillDatum? datum,
  bool fromEnd,
  bool back,
  double offset,
  double height,
  double diameter,
  double? depth,
});

const double pocketAngle = math.pi / 12;
const double pocketPilotDiameter = 3.175;

extension EdgeHoleGeometry on EdgeHole {
  double position(Vector3 size) =>
      fromEnd ? edge.length(size) - offset : offset;
  PanelDrill drill(Vector3 size) {
    final ax = edge.faceIndex ~/ 2, p = Vector3.zero()..z = height;
    p[1 - ax] = position(size);
    p[ax] = edge.atMax ? size[ax] : 0;
    final distance = depth ?? size[ax];
    return PanelDrill(
      edge.faceIndex,
      p,
      p.clone()..[ax] += edge.atMax ? -distance : distance,
      diameter,
      through: depth == null,
    );
  }

  Iterable<PanelDrill> drills(Vector3 size) sync* {
    if (kind != EdgeHoleKind.pocket) {
      yield drill(size);
      return;
    }
    final normal = edge.faceIndex ~/ 2;
    final z = height;
    final entry = Vector3.zero()..z = back ? size.z : 0;
    entry[1 - normal] = position(size);
    entry[normal] = edge.atMax
        ? size[normal] - z / math.tan(pocketAngle)
        : z / math.tan(pocketAngle);
    final direction = Vector3.zero()
      ..[normal] = (edge.atMax ? 1 : -1) * math.cos(pocketAngle)
      ..z = (back ? -1 : 1) * math.sin(pocketAngle);
    final shoulder = entry + direction * (depth ?? 0);
    final tip = entry + direction * (z / math.sin(pocketAngle) - 2);
    yield PanelDrill(back ? 5 : 4, entry, shoulder, diameter, angled: true);
    yield PanelDrill(
      back ? 5 : 4,
      shoulder,
      tip,
      pocketPilotDiameter,
      angled: true,
    );
  }

  bool fits(Vector3 size) {
    if (kind == EdgeHoleKind.pocket) {
      final z = height;
      final r = diameter / 2;
      final d = depth;
      return d != null &&
          d.isFinite &&
          d > 0 &&
          diameter.isFinite &&
          diameter > pocketPilotDiameter &&
          z + pocketPilotDiameter / 2 < size.z &&
          offset >= r &&
          offset + r <= edge.length(size) &&
          z / math.tan(pocketAngle) + r / math.sin(pocketAngle) <=
              edge.width(size) &&
          d * math.sin(pocketAngle) >= r * math.cos(pocketAngle) &&
          d < z / math.sin(pocketAngle) - 2 &&
          d * math.sin(pocketAngle) + r * math.cos(pocketAngle) <= size.z;
    }
    return diameter.isFinite &&
        diameter > 0 &&
        offset >= diameter / 2 &&
        offset + diameter / 2 <= edge.length(size) &&
        height >= diameter / 2 &&
        height + diameter / 2 <= size.z &&
        (depth == null || depth! > 0 && depth! < edge.width(size));
  }

  double minimumSize(int axis) {
    if (kind == EdgeHoleKind.pocket) {
      final z = height;
      if (axis == edge.faceIndex ~/ 2) {
        return z / math.tan(pocketAngle) +
            diameter / (2 * math.sin(pocketAngle));
      }
      if (axis == 2) {
        return math.max(
              height + pocketPilotDiameter / 2,
              (depth ?? 0) * math.sin(pocketAngle) +
                  diameter / 2 * math.cos(pocketAngle),
            ) +
            1e-6;
      }
    }
    return axis == 2
        ? height + diameter / 2
        : axis == edge.faceIndex ~/ 2
        ? (depth == null ? 0 : depth! + 1e-6)
        : offset + diameter / 2;
  }

  Map<String, Object> toJson() => {
    if (datum case final p?) 'datum': [p.u, p.v],
    'edge': edge.name,
    'kind': kind.name,
    if (back) 'back': true,
    'offset': offset,
    'height': height,
    'diameter': diameter,
    'depth': ?depth,
    if (fromEnd) 'fromEnd': true,
  };
  static EdgeHole fromJson(dynamic json) {
    if (json case {
      'edge': String e,
      'kind': String k,
      'offset': num o,
      'height': num z,
      'diameter': num bit,
    }) {
      final edge = PanelEdge.values.asNameMap()[e],
          kind = EdgeHoleKind.values.asNameMap()[k];
      final depth = json['depth'],
          fromEnd = json['fromEnd'] ?? false,
          back = json['back'] ?? false;
      if (edge != null &&
          kind != null &&
          back is bool &&
          (kind != EdgeHoleKind.pocket || depth != null) &&
          fromEnd is bool &&
          o.isFinite &&
          o > 0 &&
          z.isFinite &&
          z > 0 &&
          bit.isFinite &&
          bit > 0 &&
          (depth == null || depth is num && depth.isFinite && depth > 0)) {
        return (
          edge: edge,
          kind: kind,
          datum: _readDrillDatum(json['datum']),
          back: back,
          fromEnd: fromEnd,
          offset: o.toDouble(),
          height: z.toDouble(),
          diameter: bit.toDouble(),
          depth: (depth as num?)?.toDouble(),
        );
      }
    }
    throw FormatException(editorStrings.invalidPartGeometry);
  }
}

extension HoleLimits on Beam {
  int get drillingCount =>
      edgeHoles.length +
      holes.length +
      holes.where((hole) => hole.boltBore != null).length;
  double minimumHoleSize(int dim) => edgeHoles.fold(
    holes.fold(0.0, (limit, h) => math.max(limit, h.minimumSize(dim))),
    (limit, h) => math.max(limit, h.minimumSize(dim)),
  );
}
