import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import 'grid_visibility.dart';
import 'model.dart';
import 'palette.dart';
import 'scene.dart';

class GridPainter extends CustomPainter {
  static const _near = .05;

  GridPainter({
    required Camera camera,
    required this.project,
    required this.plane,
    required this.visibility,
    required this.colors,
  }) : camera = camera.copy();

  final Camera camera;
  final Project project;
  final WorkPlane plane;
  final GridVisibility visibility;
  final EditorPalette colors;

  Color _lineTint(Vector3 direction) {
    for (var i = 0; i < 3; i++) {
      if (direction[i].abs() > 1 - 1e-6) return colors.axisColor(i);
    }
    return colors.muted;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final viewport = Offset.zero & size;
    canvas.drawRect(viewport, Paint()..color = colors.paper);
    canvas.save();
    canvas.clipRect(viewport);
    if (visibility.automatic) {
      _grid(canvas, size, plane);
    } else {
      for (final axes in GridPlane.values) {
        if (visibility.planes.contains(axes)) {
          final gridPlane = axes.plane.through(Vector3(0, project.rearY, 0));
          _grid(canvas, size, gridPlane);
        }
      }
    }
    canvas.restore();
  }

  Rect? _visibleGrid(WorkPlane plane, Size size) {
    final viewport = Offset.zero & size;
    final screen = [
      viewport.topLeft,
      viewport.topRight,
      viewport.bottomLeft,
      viewport.bottomRight,
    ];
    final points = <Vector3>[];
    if (!camera.perspective) {
      for (final point in screen) {
        final p = camera.onPlane(point, size, plane);
        if (p != null) points.add(p);
      }
    } else {
      // Intersect the grid plane with the visible frustum, including when the
      // horizon crosses the viewport and the upper corner rays miss the floor.
      final distance = camera.eyeDistance;
      final far = math.max(distance * 4, size.longestSide / camera.scale * 4);
      final rays = [for (final p in screen) camera.rayOrigin(p, size)];
      final corners = [
        for (final depth in [distance * (1 - _near), -far])
          for (final ray in rays) ray + camera.towardEye(ray) * depth,
      ];
      final normal = plane.normal;
      final heights = [for (final p in corners) (p - plane.origin).dot(normal)];
      for (var i = 0; i < 8; i++) {
        if (heights[i].abs() < 1e-7) points.add(corners[i]);
        for (final bit in [1, 2, 4]) {
          if ((i & bit) != 0) continue;
          final j = i | bit;
          if (heights[i] * heights[j] >= 0) continue;
          points.add(
            corners[i] +
                (corners[j] - corners[i]) *
                    (heights[i] / (heights[i] - heights[j])),
          );
        }
      }
    }
    if (points.isEmpty) return null;
    return _planeBounds(plane, points);
  }

  Rect _planeBounds(WorkPlane plane, List<Vector3> points) => points
      .map((p) {
        final d = p - plane.origin;
        final at = Offset(d.dot(plane.u), d.dot(plane.v));
        return Rect.fromPoints(at, at);
      })
      .reduce((a, b) => a.expandToInclude(b));

  void _grid(Canvas canvas, Size size, WorkPlane plane) {
    final normal = plane.normal;
    final at =
        camera.target - normal * (camera.target - plane.origin).dot(normal);
    final facing = camera.towardEye(at).normalized().dot(normal).abs();
    final opacity = ((facing - .035) / .32).clamp(0.0, 1.0);
    if (opacity == 0) return;
    var bounds = _visibleGrid(plane, size);
    if (bounds == null || bounds.isEmpty) return;
    final room = project.workspaceSize;
    if (room != null) {
      var polygon = [
        for (final p in [
          bounds.topLeft,
          bounds.topRight,
          bounds.bottomRight,
          bounds.bottomLeft,
        ])
          plane.origin + plane.u * p.dx + plane.v * p.dy,
      ];
      for (var i = 0; i < 3; i++) {
        polygon = clipPolygon(polygon, (p) => p[i]);
        polygon = clipPolygon(polygon, (p) => room[i] - p[i]);
      }
      if (camera.perspective) {
        final nearDepth = camera.eyeDistance * (1 - _near);
        final eye = camera.eye;
        polygon = clipPolygon(
          polygon,
          (p) => nearDepth - (p - camera.target).dot(eye),
        );
      }
      if (polygon.length < 3) return;
      bounds = _planeBounds(plane, polygon);
      canvas.save();
      canvas.clipPath(
        Path()..addPolygon([
          for (final p in polygon) camera.project(p, size),
        ], true),
      );
    }

    var step = 50.0;
    while (step * camera.scale < 5) {
      step *= 5;
    }
    final center = size.center(Offset.zero) + camera.pan;
    final right = camera.right * camera.scale, down = -camera.up * camera.scale;
    final eye = camera.eye;
    // In homogeneous screen coordinates a world line stays linear. Project
    // the plane basis once, then divide by w only for visible endpoints.
    Vector3 transform(Vector3 delta) => Vector3(
      delta.dot(right),
      delta.dot(down),
      camera.perspective ? -delta.dot(eye) / camera.eyeDistance : 0,
    );
    final origin = transform(plane.origin - camera.target)..z += 1;
    final du = transform(plane.u), dv = transform(plane.v);
    Offset screen(Vector3 p) =>
        Offset(center.dx + p.x / p.z, center.dy + p.y / p.z);

    final anchor = camera.project(at, size);
    final u = camera.project(at + plane.u * step, size) - anchor;
    final v = camera.project(at + plane.v * step, size) - anchor;
    final area = (u.dx * v.dy - u.dy * v.dx).abs();

    void family(
      double min,
      double max,
      double spacing,
      Vector3 along,
      Vector3 start,
      Vector3 end,
      Color tint,
    ) {
      var stride = 1;
      while ((max - min) / (step * stride) > 500) {
        stride *= 5;
      }
      final interval = step * stride;
      final first = (min / interval).ceil(), last = (max / interval).floor();
      final span = end - start;
      Path? minor, major, axis;
      double alpha(int multiple) =>
          opacity * ((spacing * multiple - 4) / 9).clamp(0.0, 1.0);
      final minorAlpha = alpha(1), majorAlpha = alpha(stride > 1 ? stride : 5);
      for (var i = first; i <= last; i++) {
        final bold = stride > 1 || i % 5 == 0;
        if (i != 0 && (bold ? majorAlpha : minorAlpha) == 0) continue;
        var a = start + along * (i * interval), b = a + span;
        // Match the near clipping plane used to find the visible grid.
        if (a.z < _near && b.z < _near) continue;
        if (a.z < _near) {
          a += span * ((_near - a.z) / span.z);
        } else if (b.z < _near) {
          b = a + span * ((_near - a.z) / span.z);
        }
        final path = switch (i) {
          0 => axis ??= Path(),
          _ when bold => major ??= Path(),
          _ => minor ??= Path(),
        };
        final from = screen(a), to = screen(b);
        path.moveTo(from.dx, from.dy);
        path.lineTo(to.dx, to.dy);
      }
      void draw(Path? path, double mix, double alpha, double width) {
        if (path == null) return;
        canvas.drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..color = Color.lerp(
              colors.paper,
              tint,
              mix,
            )!.withValues(alpha: alpha)
            ..strokeWidth = width,
        );
      }

      draw(minor, .17, minorAlpha, .75);
      draw(major, .32, majorAlpha, .75);
      draw(axis, .5, opacity, 1);
    }

    family(
      bounds.left,
      bounds.right,
      area / math.max(.001, v.distance),
      du,
      origin + dv * bounds.top,
      origin + dv * bounds.bottom,
      _lineTint(plane.v),
    );
    family(
      bounds.top,
      bounds.bottom,
      area / math.max(.001, u.distance),
      dv,
      origin + du * bounds.left,
      origin + du * bounds.right,
      _lineTint(plane.u),
    );
    if (room != null) canvas.restore();
  }

  @override
  bool shouldRepaint(GridPainter old) {
    if (colors != old.colors ||
        visibility.encode() != old.visibility.encode()) {
      return true;
    }
    if (visibility.automatic && plane != old.plane) return true;
    if (!visibility.automatic && visibility.planes.isEmpty) return false;
    if (project.workspaceSize != old.project.workspaceSize) return true;
    if (!visibility.automatic && project.rearY != old.project.rearY) {
      return true;
    }
    final previous = old.camera;
    return camera.yaw != previous.yaw ||
        camera.pitch != previous.pitch ||
        camera.perspective != previous.perspective ||
        camera.eyeDistance != previous.eyeDistance ||
        camera.scale != previous.scale ||
        camera.pan != previous.pan ||
        camera.target != previous.target;
  }
}
