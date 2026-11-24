part of 'project_templates.dart';

// The catalogue drawings give finished millimetres. Beam coordinates are also
// millimetres, including when the editor displays the project in inches.
extension _CatalogJoinery on _Parts {
  void stile(
    String name,
    double x,
    double y,
    double z,
    double wide,
    double deep,
    double high,
  ) => add(name, x, y, z, high, wide, deep, 2, 0);

  // Extrude a board between two parallel long edges in the XZ elevation.
  // At each end the two vertices define the actual saw plane, including mitres.
  void profileBoard(
    String name,
    Vector3 a,
    Vector3 b,
    Vector3 c,
    Vector3 e,
    double depth, {
    bool depthIsStockWidth = false,
  }) {
    final along = (b - a).normalized();
    final width = (c - a).cross(along).length;
    final y = axis(1);
    member(
      name,
      (a + c) * .5,
      (b + e) * .5,
      depthIsStockWidth ? along.cross(y) : y,
      depthIsStockWidth ? depth : width,
      depthIsStockWidth ? width : depth,
      startPlane: (c - a).cross(y),
      endPlane: (e - b).cross(y),
    );
  }

  void rim(
    String name,
    List<Vector3> outside,
    List<Vector3> inside,
    double depth, {
    bool depthIsStockWidth = false,
  }) {
    for (var i = 0; i < outside.length; i++) {
      final j = (i + 1) % outside.length;
      profileBoard(
        name,
        outside[i],
        outside[j],
        inside[i],
        inside[j],
        depth,
        depthIsStockWidth: depthIsStockWidth,
      );
    }
  }
}
