import 'dart:math' as math;
import 'dart:ui' show Offset, Size;

import 'model.dart';
import 'scene.dart';

class StockSketch {
  static const defaultWidth = 30.0, defaultThickness = 40.0;
  final WorkPlane plane;
  final Beam? reference;
  StockSketch(this.plane, this.reference);

  Anchor? raisedEnd(
    Camera camera,
    Size size,
    Offset cursor,
    Vector3 start,
    Anchor? hit, {
    required bool verticalOnly,
  }) {
    final z = axis(2), horizontal = camera.right;
    final vertical = WorkPlane('Вертикаль', start, horizontal, z);
    if (hit != null && hit.point.z >= start.z) {
      final delta = hit.point - start;
      final onPath = verticalOnly
          ? delta.x.abs() + delta.y.abs() < .001
          : delta.dot(vertical.normal).abs() < .001;
      if (onPath) return hit;
    }

    double across, rise;
    if (camera.up.z.abs() < .20) {
      // Height has no visible projection in plan view. Use upward pointer travel.
      final scale = camera.scale * camera.projectionFactor(start);
      final drag = (cursor - camera.project(start, size)) / scale;
      across = drag.dx;
      rise = -drag.dy;
    } else {
      final point = camera.onPlane(cursor, size, vertical);
      if (point == null) return null;
      final delta = point - start;
      across = delta.dot(horizontal);
      rise = delta.z;
    }
    return Anchor(
      start +
          horizontal * (verticalOnly ? 0.0 : across) +
          z * math.max(0.0, rise),
    );
  }

  Beam make(int id, Vector3 start, Vector3 end, {bool raised = false}) {
    final ref = reference;
    final name = Beam.defaultName(id);
    if (raised) {
      final widthAxis = ref?.across.clone() ?? axis(0);
      widthAxis.z = 0;
      if (widthAxis.length2 < 1e-8) widthAxis.setFrom(ref!.along);
      widthAxis.z = 0;
      return Beam.between(
        id,
        name,
        start,
        end,
        axis(2).cross(widthAxis).normalized(),
        ref?.size.y ?? defaultWidth,
        ref?.size.z ?? defaultThickness,
      );
    }
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
