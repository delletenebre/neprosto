part of 'model.dart';

class ConnectionRuler {
  const ConnectionRuler({this.first = 37, this.pitch = 32});
  final double first, pitch;

  factory ConnectionRuler.restore(double? first, double? pitch) {
    bool valid(double? value) =>
        value != null && value.isFinite && value >= .001 && value <= 1e8;
    return ConnectionRuler(
      first: valid(first) ? first! : 37,
      pitch: valid(pitch) ? pitch! : 32,
    );
  }

  double snap(double distance) =>
      first + math.max(0, ((distance - first) / pitch).round()) * pitch;
}

enum ConnectionKind {
  dowel,
  confirmat,
  minifix,
  maxifix,
  pocket;

  String get label => switch (this) {
    dowel => editorStrings.dowel,
    confirmat => editorStrings.confirmat,
    minifix => 'Minifix',
    maxifix => 'Maxifix',
    pocket => 'Pocket Hole',
  };
}

enum DowelSide { before, after, both }

typedef ConnectionBase = ({int partId, PanelEdge edge, bool fromEnd});
typedef DrillLayout = ({List<PanelHole> faces, List<EdgeHole> edges});

class ConnectionPattern {
  const ConnectionPattern(
    this.kind, {
    this.dowels = 0,
    this.side = DowelSide.after,
    this.back = false,
  });
  final ConnectionKind kind;
  // Number of dowels accompanying the fitting, or total for a dowel-only row.
  final int dowels;
  final DowelSide side;
  final bool back;

  // Stations are ordered from the datum. The first mark always locates the
  // first physical hole, also when a dowel precedes the fitting.
  List<ConnectionKind> get stations {
    if (kind == ConnectionKind.dowel) {
      return List.filled(dowels.clamp(1, 3), kind);
    }
    if (kind == ConnectionKind.pocket) return [kind];
    final before = switch (side) {
      DowelSide.before => dowels,
      DowelSide.after => 0,
      DowelSide.both => dowels ~/ 2,
    };
    return [
      ...List.filled(before, ConnectionKind.dowel),
      kind,
      ...List.filled(dowels - before, ConnectionKind.dowel),
    ];
  }

  DrillLayout layout(
    Beam part,
    PanelEdge edge,
    bool fromEnd,
    double first,
    double pitch,
  ) {
    final faces = <PanelHole>[], edges = <EdgeHole>[];
    for (final (index, spec) in stations.indexed) {
      final offset = first + index * pitch;
      if (spec == ConnectionKind.minifix || spec == ConnectionKind.maxifix) {
        final maxi = spec == ConnectionKind.maxifix;
        final distance = maxi ? 35.0 : 34.0;
        // Minifix 15 and Maxifix 35, with 34 mm and 35 mm bolts respectively.
        final section = part.size.z;
        final axisHeight = maxi
            ? 9.5
            : section >= 18
            ? 9.0
            : section >= 16
            ? 8.0
            : 7.5;
        faces.add(
          PanelHole(
            edge.alongWidth ? distance : offset,
            edge.alongWidth ? offset : distance,
            maxi ? 35 : 15,
            fromEnd: edge.alongWidth ? edge.atMax : fromEnd,
            fromFarEdge: edge.alongWidth ? fromEnd : edge.atMax,
            back: back,
            depth: maxi ? 15.5 : axisHeight + 4.5,
            boringEdge: edge,
            boltBore: (faceOffset: axisHeight, diameter: maxi ? 9 : 8),
            name: spec.label,
          ),
        );
      } else {
        final pocket = spec == ConnectionKind.pocket,
            screw = spec == ConnectionKind.confirmat;
        edges.add((
          datum: null,
          kind: pocket
              ? EdgeHoleKind.pocket
              : screw
              ? EdgeHoleKind.confirmat
              : EdgeHoleKind.dowel,
          edge: edge,
          fromEnd: fromEnd,
          offset: offset,
          height: part.size.z / 2,
          diameter: pocket
              ? 9.525
              : screw
              ? 5.0
              : 8.0,
          back: pocket && back,
          depth: pocket
              ? part.size.z / (2 * math.sin(pocketAngle)) - 12
              : screw
              ? 35.0
              : 20.0,
        ));
      }
    }
    return (faces: faces, edges: edges);
  }

  String? issue(Beam part, DrillLayout layout) {
    if (kind == ConnectionKind.maxifix && part.size.z < 19 ||
        kind == ConnectionKind.minifix && part.size.z < 15) {
      return editorStrings.camThickness;
    }
    return layoutIssue(part, layout);
  }
}

String? layoutIssue(Beam part, DrillLayout additions) {
  final size = part.size;
  if (additions.faces.any((h) => !h.fits(size)) ||
      additions.edges.any((h) => !h.fits(size))) {
    return editorStrings.connectionDoesNotFit;
  }
  final occupied = [
    for (final h in part.holes) ...h.drills(size),
    for (final h in part.edgeHoles) ...h.drills(size),
  ];
  for (final group in [
    for (final h in additions.faces) h.drills(size),
    for (final h in additions.edges) h.drills(size),
  ]) {
    if (group.any((d) => occupied.any(d.intersects))) {
      return editorStrings.boreCollision;
    }
    occupied.addAll(group);
  }
  return null;
}
