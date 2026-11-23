import 'model.dart';
import 'scene.dart';

class StockSketch {
  static const defaultWidth = 30.0, defaultThickness = 40.0;
  final WorkPlane plane;
  final Beam? reference;
  StockSketch(this.plane, this.reference);

  Beam make(int id, Vector3 start, Vector3 end) {
    final ref = reference;
    final name = Beam.defaultName(id);
    if (ref == null) {
      return Beam.between(
        id,
        name,
        start,
        end,
        plane.normal,
        defaultWidth,
        defaultThickness,
      );
    }
    final sideDot = plane.normal.dot(ref.across);
    final upDot = plane.normal.dot(ref.up);
    final sideView = sideDot.abs() > upDot.abs();
    final dot = sideView ? sideDot : upDot;
    final normal = dot < 0 ? -plane.normal : plane.normal;
    final direction = (end - start).normalized();
    // Draw from the visible face while keeping the stock in its reference layer.
    final depth = dot.abs() > .99999 ? (ref.origin - start).dot(normal) : 0.0;
    return Beam(
      id,
      name,
      start + normal * depth,
      Vector3(start.distanceTo(end), ref.size.y, ref.size.z),
      direction,
      sideView ? normal : normal.cross(direction).normalized(),
    );
  }
}
