part of 'model.dart';

/// Offsets to the drill centre are measured in millimetres along the stock's
/// length and width. Each offset can be anchored to either end of its axis.
class PanelHole {
  const PanelHole(
    this.x,
    this.y,
    this.diameter, {
    this.name = '',
    this.fromEnd = false,
    this.fromFarEdge = false,
    this.depth,
    this.back = false,
  });
  final double x, y, diameter;
  final String name;
  final bool fromEnd, fromFarEdge, back;
  final double? depth;
  Record get _values =>
      (x, y, diameter, fromEnd, fromFarEdge, depth, back, name);
  @override
  bool operator ==(Object other) =>
      other is PanelHole && _values == other._values;
  @override
  int get hashCode => _values.hashCode;

  double centerX(Vector3 size) => fromEnd ? size.x - x : x;
  double centerY(Vector3 size) => fromFarEdge ? size.y - y : y;
  bool fits(Vector3 size) {
    final radius = diameter / 2;
    return diameter.isFinite &&
        radius > 0 &&
        x >= radius &&
        y >= radius &&
        x + radius <= size.x &&
        y + radius <= size.y &&
        (depth == null || (depth! > 0 && depth! < size.z));
  }

  Map<String, Object> toJson() => {
    'x': x,
    'y': y,
    'diameter': diameter,
    if (name.isNotEmpty) 'name': name,
    if (fromEnd) 'fromEnd': true,
    if (fromFarEdge) 'fromFarEdge': true,
    'depth': ?depth,
    if (back) 'back': true,
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
        return PanelHole(
          x.toDouble(),
          y.toDouble(),
          d.toDouble(),
          name: data['name'] as String? ?? '',
          fromEnd: data['fromEnd'] as bool? ?? false,
          fromFarEdge: data['fromFarEdge'] as bool? ?? false,
          back: data['back'] as bool? ?? false,
          depth: (depth as num?)?.toDouble(),
        );
      }
    }
    throw FormatException(editorStrings.invalidPartGeometry);
  }
}

extension HoleLimits on Beam {
  double minimumHoleSize(int dim) => holes.fold(
    0.0,
    (limit, h) => math.max(limit, switch (dim) {
      0 => h.x + h.diameter / 2,
      1 => h.y + h.diameter / 2,
      _ => h.depth == null ? 0.0 : h.depth! + 1e-6,
    }),
  );
}
