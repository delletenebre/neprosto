import 'dart:math' as math;
import 'dart:ui';

import 'model.dart';

class WorkPlane {
  final String name;
  final Vector3 origin, u, v;
  WorkPlane(this.name, this.origin, this.u, this.v);
  Vector3 get normal => u.cross(v);
  static WorkPlane xy() => WorkPlane('XY', Vector3.zero(), axis(0), axis(1));
  static WorkPlane xz() => WorkPlane('XZ', Vector3.zero(), axis(0), axis(2));
  static WorkPlane yz() => WorkPlane('YZ', Vector3.zero(), axis(1), axis(2));
  WorkPlane through(Vector3 p) => WorkPlane(name, p, u, v);
  Vector3 quantize(Vector3 p, double step) {
    final d = p - origin;
    return origin +
        u * ((d.dot(u) / step).round() * step) +
        v * ((d.dot(v) / step).round() * step);
  }
}

enum ViewAngle {
  perspective('Перспектива', -.56, .47),
  iso('Аксонометрия', -.56, .47),
  top('Сверху', 0, math.pi / 2),
  front('Спереди', 0, 0),
  right('Справа', math.pi / 2, 0),
  back('Сзади', math.pi, 0),
  left('Слева', -math.pi / 2, 0);

  const ViewAngle(this.label, this.yaw, this.pitch);
  final String label;
  final double yaw, pitch;
}

class Camera {
  double yaw = ViewAngle.iso.yaw, pitch = ViewAngle.iso.pitch, scale = 0.5;
  bool perspective = false;
  double eyeDistance = 2400;
  Vector3 target = Vector3.zero();
  Offset pan = Offset.zero;
  Camera copy() => Camera()
    ..yaw = yaw
    ..pitch = pitch
    ..scale = scale
    ..pan = pan
    ..target = target.clone()
    ..perspective = perspective
    ..eyeDistance = eyeDistance;
  Vector3 get right => Vector3(math.cos(yaw), math.sin(yaw), 0);
  Vector3 get eye => Vector3(
    math.sin(yaw) * math.cos(pitch),
    -math.cos(yaw) * math.cos(pitch),
    math.sin(pitch),
  );
  Vector3 get up => eye.cross(right);
  double projectionFactor(Vector3 p) => perspective
      ? eyeDistance /
            math.max(eyeDistance * .001, eyeDistance - (p - target).dot(eye))
      : 1;
  Vector3 towardEye(Vector3 p) =>
      perspective ? eye - (p - target) / eyeDistance : eye;
  Offset project(Vector3 p, Size s) {
    final v = p - target;
    return s.center(Offset.zero) +
        pan +
        Offset(v.dot(right), -v.dot(up)) * (scale * projectionFactor(p));
  }

  Vector3 rayOrigin(Offset p, Size s) {
    final d = (p - s.center(Offset.zero) - pan) / scale;
    return target + right * d.dx - up * d.dy;
  }

  Vector3? onPlane(Offset p, Size s, WorkPlane plane) {
    final n = plane.normal, ray = rayOrigin(p, s), direction = towardEye(ray);
    final denom = direction.dot(n);
    if (denom.abs() < 1e-6) return null;
    final t = (plane.origin - ray).dot(n) / denom;
    return perspective && t >= eyeDistance ? null : ray + direction * t;
  }

  void view(ViewAngle v) {
    perspective = v == ViewAngle.perspective;
    yaw = v.yaw;
    pitch = v.pitch;
  }

  void facePlane(WorkPlane plane) {
    perspective = false;
    final n = plane.normal;
    yaw = math.atan2(n.x, -n.y);
    pitch = math.asin(n.z.clamp(-1, 1));
  }

  void zoom(double factor, Offset focus, Size s) {
    final old = scale;
    scale = (old * factor).clamp(.005, 100);
    final center = s.center(Offset.zero);
    pan = focus - center - (focus - center - pan) * (scale / old);
  }

  void fit(Project p, Size s) {
    pan = Offset.zero;
    final points = [...p.workspaceCorners, ...p.beams.expand((b) => b.corners)];
    if (points.isEmpty) {
      target = Vector3.zero();
      scale = .6;
      return;
    }
    target = Bounds3.points(points).center;
    final rect = Bounds3.points(
      points.map((p) => Vector3(p.dot(right), p.dot(up), p.dot(eye))),
    );
    final width = math.max(1, rect.high.x - rect.low.x),
        height = math.max(1, rect.high.y - rect.low.y);
    scale = math
        .min(s.width * .79 / width, s.height * .67 / height)
        .clamp(.005, 20);
    final mid = rect.center;
    target = right * mid.x + up * mid.y + eye * mid.z;
    if (perspective) {
      eyeDistance = math.max(100, (rect.high - rect.low).length * 1.8);
      final bounds = Bounds3.points(
        points.map((p) {
          final at = project(p, s) - s.center(Offset.zero);
          return Vector3(at.dx, at.dy, 0);
        }),
      );
      final span = bounds.high - bounds.low;
      final factor = math.min(
        s.width * .79 / math.max(1, span.x),
        s.height * .67 / math.max(1, span.y),
      );
      scale = (scale * factor).clamp(.005, 20);
      pan = Offset(-bounds.center.x, -bounds.center.y) * factor;
    }
  }
}

class SceneFace {
  final Beam beam;
  final int face;
  final List<Vector3> world;
  final List<Offset> points;
  final Vector3 normal;
  final Path path;
  final Rect bounds;
  final double depth;
  SceneFace(
    this.beam,
    this.face,
    this.world,
    this.points,
    this.normal,
    Camera cam,
  ) : path = Path()..addPolygon(points, true),
      bounds = Rect.fromLTRB(
        points.map((p) => p.dx).reduce(math.min),
        points.map((p) => p.dy).reduce(math.min),
        points.map((p) => p.dx).reduce(math.max),
        points.map((p) => p.dy).reduce(math.max),
      ),
      depth = world.fold(0.0, (a, b) => a + b.dot(cam.eye)) / 4;
  WorkPlane get plane => WorkPlane(
    'Грань',
    world[0],
    (world[1] - world[0]).normalized(),
    normal.cross((world[1] - world[0]).normalized()),
  );
}

enum SnapMode {
  auto('Авто'),
  corner('Угол'),
  edge('Середина ребра'),
  faceCenter('Центр грани'),
  center('Центр детали'),
  surface('Плоскость');

  final String label;
  const SnapMode(this.label);
}

class Scene {
  final Project project;
  final Camera camera;
  final Size size;
  final List<SceneFace> faces = [];
  Scene(this.project, this.camera, this.size) {
    if (camera.perspective) {
      for (final b in project.beams) {
        for (final p in b.corners) {
          camera.eyeDistance = math.max(
            camera.eyeDistance,
            (p - camera.target).dot(camera.eye) * 1.25,
          );
        }
      }
    }
    for (final b in project.beams) {
      final corners = b.corners;
      final normals = List.generate(6, b.faceNormal);
      for (var i = 0; i < 6; i++) {
        if (normals[i].dot(camera.towardEye(corners[faceCorners[i].first])) <
            1e-6) {
          continue;
        }
        final world = [for (final k in faceCorners[i]) corners[k]];
        faces.add(
          SceneFace(
            b,
            i,
            world,
            [for (final p in world) camera.project(p, size)],
            normals[i],
            camera,
          ),
        );
      }
    }
    _order();
  }

  // Order overlapping faces by their depths on the same viewing ray. Sorting
  // by centre alone hides near ends of long rails behind short legs.
  void _order() {
    faces.sort((a, b) => a.depth.compareTo(b.depth));
    final ahead = [for (final _ in faces) <int>[]],
        incoming = List.filled(faces.length, 0);
    for (var i = 0; i < faces.length; i++) {
      final a = faces[i];
      for (var j = i + 1; j < faces.length; j++) {
        final b = faces[j];
        if (a.beam.id == b.beam.id || !a.bounds.overlaps(b.bounds)) continue;
        final overlap = Path.combine(
          PathOperation.intersect,
          a.path,
          b.path,
        ).getBounds();
        if (overlap.width < .05 || overlap.height < .05) continue;
        final ray = camera.rayOrigin(overlap.center, size);
        final direction = camera.towardEye(ray);
        double depthAt(SceneFace f) =>
            (f.world.first - ray).dot(f.normal) / direction.dot(f.normal);
        final delta = depthAt(a) - depthAt(b);
        if (delta.abs() < 1e-6) continue;
        final far = delta < 0 ? i : j, near = delta < 0 ? j : i;
        ahead[far].add(near);
        incoming[near]++;
      }
    }
    final ordered = <SceneFace>[], used = <int>{};
    while (ordered.length < faces.length) {
      var i = incoming.indexOf(0);
      if (i < 0) {
        i = List.generate(
          faces.length,
          (i) => i,
        ).firstWhere((k) => !used.contains(k));
      }
      used.add(i);
      incoming[i] = -1;
      ordered.add(faces[i]);
      for (final j in ahead[i]) {
        if (!used.contains(j)) incoming[j]--;
      }
    }
    faces
      ..clear()
      ..addAll(ordered);
  }

  SceneFace? hit(Offset pos) {
    for (final f in faces.reversed) {
      if (f.bounds.contains(pos) && f.path.contains(pos)) return f;
    }
    return null;
  }

  Anchor? snap(
    Offset pos, {
    Set<int> exclude = const {},
    Set<int>? only,
    SnapMode mode = SnapMode.auto,
    double radius = 13,
  }) {
    bool eligible(int id) =>
        !exclude.contains(id) && (only == null || only.contains(id));
    if (mode == SnapMode.surface) {
      for (final f in faces.reversed) {
        if (!eligible(f.beam.id) || !f.path.contains(pos)) continue;
        final p = camera.onPlane(pos, size, f.plane)!;

        return Anchor(p, f.beam.id, 0, f.beam.localAt(p), 'Плоскость', f.face);
      }
      return null;
    }
    Anchor? best;
    var bestDistance = radius, bestDepth = double.negativeInfinity;
    void consider(Anchor candidate, {bool internal = false}) {
      final p = candidate.point, screen = camera.project(p, size);
      final distance = (screen - pos).distance, depth = p.dot(camera.eye);
      if (distance > radius ||
          distance > bestDistance + .001 ||
          ((distance - bestDistance).abs() < .001 && depth <= bestDepth)) {
        return;
      }
      final ray = camera.rayOrigin(screen, size);
      final direction = camera.towardEye(ray);
      final hidden = faces.reversed.any(
        (f) =>
            !exclude.contains(f.beam.id) &&
            !(internal && f.beam.id == candidate.beam) &&
            f.bounds.contains(screen) &&
            f.path.contains(screen) &&
            ray.dot(camera.eye) +
                    (f.world.first - ray).dot(f.normal) /
                        direction.dot(f.normal) >
                depth + .02,
      );
      if (hidden) return;
      best = candidate;
      bestDistance = distance;
      bestDepth = depth;
    }

    for (final b in project.beams) {
      if (!eligible(b.id)) continue;
      final corners = b.corners;
      if (mode == SnapMode.corner || mode == SnapMode.auto) {
        for (var i = 0; i < 8; i++) {
          consider(Anchor(corners[i], b.id, i));
        }
      }
      if (mode == SnapMode.edge || mode == SnapMode.auto) {
        for (var i = 0; i < 8; i++) {
          for (var d = 0; d < 3; d++) {
            if ((i & (1 << d)) != 0) continue;
            final t = Vector3(
              (i & 1).toDouble(),
              ((i >> 1) & 1).toDouble(),
              ((i >> 2) & 1).toDouble(),
            )..[d] = .5;
            consider(
              Anchor(
                (corners[i] + corners[i | (1 << d)]) * .5,
                b.id,
                0,
                t,
                'Середина ребра',
              ),
            );
          }
        }
      }
      if (mode == SnapMode.center || mode == SnapMode.auto) {
        consider(
          Anchor(
            b.pointAt(Vector3.all(.5)),
            b.id,
            0,
            Vector3.all(.5),
            'Центр детали',
          ),
          internal: true,
        );
      }
    }
    if (mode == SnapMode.faceCenter || mode == SnapMode.auto) {
      for (final f in faces) {
        if (!eligible(f.beam.id)) continue;
        final t = Vector3.all(.5)..[f.face ~/ 2] = (f.face % 2).toDouble();
        consider(
          Anchor(f.beam.pointAt(t), f.beam.id, 0, t, 'Центр грани', f.face),
        );
      }
    }
    return best;
  }
}

class TurnArrow {
  final int sign;
  final List<Offset> path;
  final Offset label;
  TurnArrow(this.sign, this.path, this.label);
  Offset get tip => path.last;
}

class RotationDial {
  final List<Offset> ring;
  final List<TurnArrow> arrows;
  final Offset center, axisEnd;
  RotationDial(this.ring, this.arrows, this.center, this.axisEnd);
  factory RotationDial.project(
    Camera camera,
    Size size,
    Vector3 pivot,
    Vector3 normal,
  ) {
    final center = camera.project(pivot, size);
    var major = normal.cross(camera.towardEye(pivot));
    if (major.length2 < 1e-8) {
      major = camera.right - normal * normal.dot(camera.right);
    }
    major.normalize();
    if (major.dot(camera.right) < 0) major = -major;
    final minor = normal.cross(major),
        radius = 76 / (camera.scale * camera.projectionFactor(pivot));
    Offset at(double t) => camera.project(
      pivot + (major * math.cos(t) + minor * math.sin(t)) * radius,
      size,
    );
    final ring = [for (var i = 0; i <= 80; i++) at(i * math.pi / 40)];
    final arrows = <TurnArrow>[];
    for (final sign in [-1, 1]) {
      final finish = sign > 0 ? 0.0 : math.pi;
      final path = [
        for (var i = 0; i <= 20; i++) at(finish - sign * (20 - i) * .055),
      ];
      final outward = path.last - center;
      arrows.add(
        TurnArrow(sign, path, path.last + outward / outward.distance * 23),
      );
    }
    return RotationDial(
      ring,
      arrows,
      center,
      camera.project(pivot + normal * (radius * 1.05), size),
    );
  }
  int? hit(Offset at) {
    for (final a in arrows) {
      if (Rect.fromCenter(
            center: a.label,
            width: 49,
            height: 24,
          ).contains(at) ||
          a.path.any((p) => (p - at).distance <= 9)) {
        return a.sign;
      }
    }
    return null;
  }
}
