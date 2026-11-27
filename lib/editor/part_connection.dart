part of 'model.dart';

const _contactTolerance = 1e-6;

List<PartContact> connectionContacts(List<Beam> selected) {
  if (selected.length != 2 || selected.any((b) => b.hidden)) return const [];
  final [a, b] = selected;
  final contacts = <PartContact>[];
  for (var face = 0; face < 6; face++) {
    for (var other = 0; other < 6; other++) {
      final gap = _faceGap(a, face, b, other);
      if (gap == null || gap.from.distanceTo(gap.to) >= _contactTolerance) {
        continue;
      }
      contacts.addAll([
        PartContact(a, face, b, other, gap.polygon, gap.from),
        PartContact(b, other, a, face, gap.polygon, gap.from),
      ]);
    }
  }
  return contacts;
}

class PartContact {
  PartContact(
    this.part,
    this.face,
    this.mate,
    this.mateFace,
    this.overlap,
    this.center,
  );

  final Beam part, mate;
  final int face, mateFace;
  final List<Vector3> overlap;
  final Vector3 center;

  bool get cabinet => [part, mate].any(
    (b) => switch (b.finish.texture) {
      PartTexture.laminate || PartTexture.woodLaminate => true,
      _ => false,
    },
  );

  // Drills are stored on the rectangular stock axes. A cut or rabbet can
  // remove material from that nominal drilling path.
  bool get _rectangular => [part, mate].every(
    (b) => !b.bevelled && b.rabbets.isEmpty && b.material != PartMaterial.metal,
  );

  Vector3 get direction {
    if (face < 4) return face < 2 ? part.across : part.along;
    double span(Vector3 axis) {
      final coordinates = overlap.map((p) => p.dot(axis));
      return coordinates.reduce(math.max) - coordinates.reduce(math.min);
    }

    return span(part.along) >= span(part.across) ? part.along : part.across;
  }

  bool get _alongLength => direction.dot(part.along).abs() > .5;
  double get length => _alongLength ? part.size.x : part.size.y;
  PanelEdge datumEdge(bool fromEnd) => _alongLength
      ? (fromEnd ? PanelEdge.end : PanelEdge.start)
      : (fromEnd ? PanelEdge.far : PanelEdge.near);

  // Intersect the drill row with the actual mating polygon inset by the
  // required radial clearance. The other part can be shifted or rotated.
  (double, double)? _limits(Vector3 datum, Vector3 axis, double clearance) {
    var low = double.negativeInfinity, high = double.infinity;
    final normal = part.faceNormal(face);
    for (var i = 0; i < overlap.length; i++) {
      final a = overlap[i], b = overlap[(i + 1) % overlap.length];
      if (a.distanceToSquared(b) < 1e-12) continue;
      var inward = normal.cross(b - a).normalized();
      if ((center - a).dot(inward) < 0) inward = -inward;
      final slope = axis.dot(inward);
      final bound = clearance - (datum - a).dot(inward);
      if (slope.abs() < _contactTolerance) {
        if (bound > _contactTolerance) return null;
      } else if (slope > 0) {
        low = math.max(low, bound / slope);
      } else {
        high = math.min(high, bound / slope);
      }
    }
    return low <= high ? (low, high) : null;
  }

  ({Vector3 datum, double low, double high, double clearance})? _rowGeometry(
    ConnectionPattern pattern,
    Vector3 axis,
    double diameter,
    double inset,
  ) {
    final kind = pattern.kind;
    final cam =
        kind == ConnectionKind.minifix || kind == ConnectionKind.maxifix;
    final pocket = kind == ConnectionKind.pocket;
    final screw = kind == ConnectionKind.woodScrew;
    final confirmat = kind == ConnectionKind.confirmat;
    final edge = face < 4 ? PanelEdge.values[face] : null;
    if ((cam || confirmat) && (!cabinet || edge == null || mateFace < 4)) {
      return null;
    }
    if (screw && cabinet) return null;
    if (pocket &&
        (cabinet ||
            edge == null ||
            part.size.z < 12 ||
            (part.finish.texture != PartTexture.wood &&
                part.finish.texture != PartTexture.plywood))) {
      return null;
    }

    final datum = center - axis * (center - part.origin).dot(axis);
    final row = ConnectionPattern(kind, back: pattern.back);
    final camTemplate = cam
        ? row.layout(part, edge!, false, 0, 0).faces.single
        : null;
    if (cam || pocket) {
      final z = camTemplate?.drills(part.size).last.entry.z ?? part.size.z / 2;
      datum.add(part.up * (z - (datum - part.origin).dot(part.up)));
    }
    final clearance = switch (kind) {
      ConnectionKind.pocket => 9.525 / 2,
      ConnectionKind.minifix => 4.0,
      ConnectionKind.maxifix => 4.5,
      ConnectionKind.confirmat => math.max(
        3.5,
        pattern.dowels > 0 ? diameter / 2 : 0.0,
      ),
      ConnectionKind.woodScrew => 2.25,
      ConnectionKind.dowel => diameter / 2,
    };
    final margin = clearance + _contactTolerance;
    final limits = _limits(datum, axis, margin);
    if (limits == null) return null;
    final (low, high) = limits;
    final (start, end) = _limits(datum, axis, 0)!;
    return (
      datum: datum,
      low: math.max(low, start + inset),
      high: math.min(high, end - inset),
      clearance: margin,
    );
  }

  ConnectionPlan? plan(
    ConnectionPattern pattern,
    ConnectionRuler ruler, {
    bool fromEnd = false,
    List<ConnectionPattern>? groups,
  }) {
    if (!_rectangular) return null;
    final patterns = cabinet ? groups ?? [pattern] : [pattern];
    if (patterns.isEmpty) return null;
    final axis = direction;
    final thickness = math.min(part.size.z, mate.size.z);
    // Round dowels in the sizes used by the wolfcraft Dowelmaster.
    final diameter = thickness <= 14
        ? 6.0
        : thickness <= 18
        ? 8.0
        : 10.0;
    final inset = cabinet ? ruler.first : 0.0;
    final geometry = [
      for (final pattern in patterns)
        _rowGeometry(pattern, axis, diameter, inset),
    ].nonNulls.toList();
    if (geometry.length != patterns.length) return null;
    final low = geometry.map((r) => r.low).reduce(math.max);
    final high = geometry.map((r) => r.high).reduce(math.min);
    if (high < low) return null;
    final reverse = cabinet && fromEnd;
    final stationDirection = reverse ? -axis : axis;
    final stationRows = cabinet
        ? _cabinetStations(
            patterns,
            reverse ? length - high : low,
            reverse ? length - low : high,
            ruler,
          )
        : [_woodStations(pattern.kind, low, high, geometry.single.clearance)];
    if (stationRows.isEmpty) return null;

    final primary = <DrillLayout>[], secondary = <DrillLayout>[];
    final marks = <Vector3>[];
    for (final (index, stations) in stationRows.indexed) {
      final row = geometry[index];
      final base = reverse ? row.datum + axis * length : row.datum;
      final layout = _buildRow(
        patterns[index],
        stations,
        base,
        stationDirection,
        diameter,
        reverse,
      );
      if (layout == null) return null;
      primary.add(layout.first);
      secondary.add(layout.second);
      marks.addAll(layout.marks);
    }
    final base = geometry.first.datum;
    final plan = ConnectionPlan(this, stationRows, marks, {
      part.id: primary,
      mate.id: secondary,
    }, cabinet ? base + axis * (reverse ? length : 0) : null);
    if (layoutIssue(part, plan.layouts[part.id]!) != null ||
        layoutIssue(mate, plan.layouts[mate.id]!) != null) {
      return null;
    }
    return plan;
  }

  ({DrillLayout first, DrillLayout second, List<Vector3> marks})? _buildRow(
    ConnectionPattern pattern,
    List<(ConnectionKind, double)> stations,
    Vector3 base,
    Vector3 direction,
    double diameter,
    bool fromEnd,
  ) {
    final aDepth = part.size[face ~/ 2], bDepth = mate.size[mateFace ~/ 2];
    final first = (faces: <PanelHole>[], edges: <EdgeHole>[]);
    final second = (faces: <PanelHole>[], edges: <EdgeHole>[]);
    final edge = face < 4 ? PanelEdge.values[face] : null;
    final row = ConnectionPattern(pattern.kind, back: pattern.back);
    final baseDirection = cabinet ? direction : null;
    final marks = <Vector3>[];
    for (final (item, distance) in stations) {
      final point = base + direction * distance;
      marks.add(point);
      switch (item) {
        case ConnectionKind.dowel:
          final aMax = aDepth - 2, bMax = bDepth - 2;
          if (math.min(aMax, bMax) < diameter) return null;
          final total = math.min(diameter == 6 ? 32.0 : 42.0, aMax + bMax);
          final a = (total / 2)
              .clamp(
                math.max(diameter, total - bMax),
                math.min(aMax, total - diameter),
              )
              .toDouble();
          _addBore(
            first,
            part,
            face,
            point,
            diameter,
            a,
            EdgeHoleKind.dowel,
            baseDirection: baseDirection,
          );
          _addBore(
            second,
            mate,
            mateFace,
            point,
            diameter,
            total - a,
            EdgeHoleKind.dowel,
            baseDirection: baseDirection,
          );
        case ConnectionKind.confirmat:
        case ConnectionKind.woodScrew:
          final isConfirmat = item == ConnectionKind.confirmat;
          final depth = isConfirmat ? 50 - bDepth : math.min(aDepth - 2, 30.0);
          if (depth < (isConfirmat ? 20 : 12) ||
              depth > aDepth - 1 ||
              bDepth > 40) {
            return null;
          }
          final bit = isConfirmat
              ? EdgeHoleKind.confirmat
              : EdgeHoleKind.woodScrew;
          _addBore(
            first,
            part,
            face,
            point,
            isConfirmat ? 5 : 3,
            depth,
            bit,
            baseDirection: baseDirection,
          );
          _addBore(
            second,
            mate,
            mateFace ^ 1,
            point,
            isConfirmat ? 7 : 4.5,
            null,
            bit,
            baseDirection: baseDirection,
          );
        case ConnectionKind.minifix:
        case ConnectionKind.maxifix:
          if (bDepth < 12) return null;
          first.faces.add(
            row.layout(part, edge!, fromEnd, distance, 0).faces.single,
          );
          final d = item == ConnectionKind.maxifix ? 8.0 : 5.0;
          _addBore(
            second,
            mate,
            mateFace,
            point,
            d,
            math.min(11.0, bDepth - 2),
            EdgeHoleKind.plain,
            name: item.label,
            baseDirection: baseDirection,
          );
        case ConnectionKind.pocket:
          final pocketHole = row
              .layout(part, edge!, false, distance, 0)
              .edges
              .single;
          final direction =
              part.faceNormal(face) * math.cos(pocketAngle) +
              part.up * ((pattern.back ? -1 : 1) * math.sin(pocketAngle));
          final tip = _stockPoint(mate, point + direction * 12);
          if ([0, 1, 2].any((i) => tip[i] < 2 || tip[i] > mate.size[i] - 2)) {
            return null;
          }
          first.edges.add(pocketHole);
      }
    }
    return pattern.issue(part, first) == null
        ? (first: first, second: second, marks: marks)
        : null;
  }
}

class ConnectionPlan {
  ConnectionPlan(
    this.contact,
    this.stationRows,
    this.marks,
    this.rows,
    this.datum,
  );

  final PartContact contact;
  final List<List<(ConnectionKind, double)>> stationRows;
  late final stations = stationRows.expand((row) => row).toList();
  final List<Vector3> marks;
  final Map<int, List<DrillLayout>> rows;
  final Vector3? datum;
  late final layouts = rows.map(
    (id, row) => MapEntry(id, (
      faces: [for (final group in row) ...group.faces],
      edges: [for (final group in row) ...group.edges],
    )),
  );
}

List<List<(ConnectionKind, double)>> _cabinetStations(
  List<ConnectionPattern> patterns,
  double low,
  double high,
  ConnectionRuler ruler,
) {
  final first = math.max(
    0,
    ((low - ruler.first - _contactTolerance) / ruler.pitch).ceil(),
  );
  final last = ((high - ruler.first + _contactTolerance) / ruler.pitch).floor();
  final kinds = patterns.map((p) => p.stations).toList();
  final required = kinds.fold(0, (sum, row) => sum + row.length);
  final free = last - first + 1 - required;
  if (free < 0) return const [];
  var next = first;
  return [
    for (final (group, row) in kinds.indexed)
      [
        for (final item in row)
          (
            item,
            ruler.first +
                (next++ +
                        (kinds.length == 1
                            ? 0
                            : (free * group / (kinds.length - 1)).round())) *
                    ruler.pitch,
          ),
      ],
  ];
}

List<(ConnectionKind, double)> _woodStations(
  ConnectionKind kind,
  double low,
  double high,
  double clearance,
) {
  final pocket = kind == ConnectionKind.pocket;
  final length = high - low + 2 * clearance;
  if (length < (pocket ? 76.2 : 60)) return [(kind, (low + high) / 2)];
  // Kreg's long-joint layout starts near both ends, with up to 8 in between.
  final inset = pocket ? math.min(25.4, length / 4) : 3 * clearance;
  final first = low + math.max(0.0, inset - clearance);
  final last = high - math.max(0.0, inset - clearance);
  if (last <= first) return [(kind, (low + high) / 2)];
  final count = pocket && length <= 254
      ? (length <= 127 ? 2 : 3)
      : ((last - first) / (pocket ? 203.2 : 150)).ceil().clamp(1, 255) + 1;
  return [
    for (var i = 0; i < count; i++)
      (kind, first + (last - first) * i / (count - 1)),
  ];
}

Vector3 _stockPoint(Beam b, Vector3 world) {
  final d = world - b.origin;
  return Vector3(d.dot(b.along), d.dot(b.across), d.dot(b.up));
}

void _addBore(
  DrillLayout layout,
  Beam b,
  int face,
  Vector3 world,
  double diameter,
  double? depth,
  EdgeHoleKind kind, {
  String? name,
  Vector3? baseDirection,
}) {
  final p = _stockPoint(b, world);
  bool endsAtMax(Vector3 axis) =>
      (baseDirection?.dot(axis) ?? 0) < -1 + _contactTolerance;
  if (face >= 4) {
    final fromEnd = endsAtMax(b.along), fromFar = endsAtMax(b.across);
    layout.faces.add(
      PanelHole(
        fromEnd ? b.size.x - p.x : p.x,
        fromFar ? b.size.y - p.y : p.y,
        diameter,
        fromEnd: fromEnd,
        fromFarEdge: fromFar,
        depth: depth,
        back: face.isOdd && depth != null,
        name: name ?? kind.label,
      ),
    );
    return;
  }
  final edge = PanelEdge.values[face];
  final fromEnd = endsAtMax(edge.alongWidth ? b.across : b.along);
  final position = p[edge.alongWidth ? 1 : 0];
  layout.edges.add((
    edge: edge,
    kind: kind,
    datum: null,
    fromEnd: fromEnd,
    back: false,
    offset: fromEnd ? edge.length(b.size) - position : position,
    height: p.z,
    diameter: diameter,
    depth: depth,
  ));
}
