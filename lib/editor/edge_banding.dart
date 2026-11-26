part of 'model.dart';

class EdgeBanding {
  const EdgeBanding.none()
    : edges = const {},
      rgb = 0,
      thickness = 0,
      width = null;

  EdgeBanding({
    required Set<PanelEdge> edges,
    required this.rgb,
    required this.thickness,
    this.width,
  }) : edges = Set.unmodifiable(edges);

  final Set<PanelEdge> edges;
  final int rgb;
  final double thickness;
  // An unspecified width follows the panel when it is resized.
  final double? width;

  Map<String, dynamic> toJson() => {
    'edges': [
      for (final e in PanelEdge.values)
        if (edges.contains(e)) e.name,
    ],
    'rgb': rgb,
    'thickness': thickness,
    'width': ?width,
  };

  factory EdgeBanding.fromJson(Object? value) {
    if (value == null) return const EdgeBanding.none();
    if (value case {'edges': List names, 'rgb': int rgb, 'thickness': num t}
        when rgb >= 0 && rgb <= 0xffffff && validSize(t)) {
      final width = value['width'];
      final byName = PanelEdge.values.asNameMap();
      if ((width == null || width is num && validSize(width)) &&
          names.every(byName.containsKey)) {
        if (names.isEmpty) return const EdgeBanding.none();
        return EdgeBanding(
          edges: {for (final name in names) byName[name]!},
          rgb: rgb,
          thickness: t.toDouble(),
          width: (width as num?)?.toDouble(),
        );
      }
    }
    throw FormatException(editorStrings.invalidEdgeBanding);
  }

  static bool validSize(num? n) => n != null && n.isFinite && n > 0 && n <= 1e8;

  @override
  bool operator ==(Object other) =>
      other is EdgeBanding &&
      rgb == other.rgb &&
      thickness == other.thickness &&
      width == other.width &&
      edges.length == other.edges.length &&
      edges.containsAll(other.edges);

  @override
  int get hashCode =>
      Object.hash(rgb, thickness, width, Object.hashAllUnordered(edges));
}

// Keep selections in stock coordinates. Describe aligned cabinet panels in
// their installed orientation, and oblique pieces in their own length/width axes.
extension BandingEdgeLayout on Beam {
  ({PanelEdge left, PanelEdge right, PanelEdge top, PanelEdge bottom})
  get bandingLayout {
    int worldAxis(Vector3 v) =>
        [0, 1, 2].firstWhere((i) => v[i].abs() > .99999, orElse: () => -1);
    final x = worldAxis(along), y = worldAxis(across);
    if (x < 0 || y < 0) {
      return (
        left: PanelEdge.start,
        right: PanelEdge.end,
        top: PanelEdge.far,
        bottom: PanelEdge.near,
      );
    }
    final (xMin, xMax) = along[x] > 0
        ? (PanelEdge.start, PanelEdge.end)
        : (PanelEdge.end, PanelEdge.start);
    final (yMin, yMax) = across[y] > 0
        ? (PanelEdge.near, PanelEdge.far)
        : (PanelEdge.far, PanelEdge.near);
    return x < y
        ? (left: xMin, right: xMax, top: yMax, bottom: yMin)
        : (left: yMin, right: yMax, top: xMax, bottom: xMin);
  }

  String bandingEdgeLabel(PanelEdge edge) {
    final v = edge.alongWidth ? along : across;
    final sign = edge.atMax ? 1 : -1;
    final s = editorStrings;
    if (v.x.abs() > .99999) return sign * v.x < 0 ? s.leftHand : s.rightHand;
    if (v.y.abs() > .99999) return sign * v.y < 0 ? s.frontEdge : s.backEdge;
    if (v.z.abs() > .99999) return sign * v.z < 0 ? s.lower : s.upper;
    return switch (edge) {
      PanelEdge.start => s.startCut,
      PanelEdge.end => s.endCut,
      PanelEdge.near => '${s.width} −',
      PanelEdge.far => '${s.width} +',
    };
  }
}
