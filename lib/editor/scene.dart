import '../l10n/strings.dart';

import 'dart:math' as math;
import 'dart:ui';

import 'model.dart';

class WorkPlane {
  final String name;
  String get displayName => switch (name) {
    'Грань' => editorStrings.face,
    'Вертикаль' => editorStrings.vertical,
    _ => name,
  };
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
  perspective(-.56, .47),
  iso(-.56, .47),
  top(0, math.pi / 2),
  front(0, 0),
  right(math.pi / 2, 0),
  back(math.pi, 0),
  left(-math.pi / 2, 0),
  bottom(0, -math.pi / 2);

  const ViewAngle(this.yaw, this.pitch);

  final double yaw, pitch;
  String? get projectionPlane => switch (this) {
    top || bottom => 'XY',
    front || back => 'XZ',
    left || right => 'YZ',
    _ => null,
  };
  String get label => switch (this) {
    ViewAngle.perspective => editorStrings.perspective,
    ViewAngle.iso => editorStrings.axonometric,
    ViewAngle.top => editorStrings.viewTop,
    ViewAngle.front => editorStrings.viewFront,
    ViewAngle.right => editorStrings.viewRight,
    ViewAngle.back => editorStrings.viewBack,
    ViewAngle.left => editorStrings.viewLeft,
    ViewAngle.bottom => editorStrings.viewBottom,
  };
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

  void orbit(Offset delta, Vector3 pivot) {
    // Preserve the pivot's camera coordinates, including depth in perspective.
    final offset = pivot - target;
    final x = offset.dot(right), y = offset.dot(up), z = offset.dot(eye);
    yaw -= delta.dx * .009;
    pitch = (pitch + delta.dy * .008).clamp(-math.pi / 2, math.pi / 2);
    target = pivot - right * x - up * y - eye * z;
  }

  void facePlane(WorkPlane plane) {
    perspective = false;
    final n = plane.normal;
    yaw = n.x.abs() + n.y.abs() < 1e-8 ? 0 : math.atan2(n.x, -n.y);
    pitch = math.asin(n.z.clamp(-1, 1));
  }

  void zoom(double factor, Offset focus, Size s) {
    final old = scale;
    scale = (old * factor).clamp(.005, 100);
    final center = s.center(Offset.zero);
    pan = focus - center - (focus - center - pan) * (scale / old);
  }

  void fit(Project p, Size s) => fitPoints([
    ...p.workspaceCorners,
    ...p.beams.expand((b) => b.corners),
  ], s);

  void fitPoints(List<Vector3> points, Size s) {
    pan = Offset.zero;
    if (points.isEmpty) {
      target = Vector3.zero();
      scale = .6;
      return;
    }
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
      final previousScale = scale;
      scale = (scale * factor).clamp(.005, 20);
      pan =
          Offset(-bounds.center.x, -bounds.center.y) * (scale / previousScale);
    }
  }
}

class SceneFace {
  final Beam beam;
  final int face;
  final List<Vector3> world;
  final List<Vector3>? profileLocal;
  final List<Offset> points;
  final Vector3 normal;
  final Path path;
  Path? boreRim;
  final Rect bounds;
  final double depth;
  SceneFace(
    this.beam,
    this.face,
    this.world,
    this.points,
    this.normal,
    Camera cam,
    Size viewport, {
    this.profileLocal,
  }) : path = Path()..addPolygon(points, true),
       bounds = Rect.fromLTRB(
         points.map((p) => p.dx).reduce(math.min),
         points.map((p) => p.dy).reduce(math.min),
         points.map((p) => p.dx).reduce(math.max),
         points.map((p) => p.dy).reduce(math.max),
       ),
       depth = world.fold(0.0, (a, b) => a + b.dot(cam.eye)) / world.length {
    final bore = beam.bore;
    if (bore == null || face < 4) return;
    final r = bore.diameter / 2;
    final surface = profileLocal?.first.z ?? (face.isOdd ? 1.0 : 0.0);
    Path opening(double z) {
      final center = beam.pointAt(Vector3(bore.u, bore.v, z));
      return Path()..addPolygon([
        for (var i = 0; i < 40; i++)
          cam.project(
            center +
                beam.along * (r * math.cos(i * math.pi / 20)) +
                beam.across * (r * math.sin(i * math.pi / 20)),
            viewport,
          ),
      ], true);
    }

    final near = Path.combine(PathOperation.intersect, path, opening(surface));
    final through = Path.combine(
      PathOperation.intersect,
      near,
      opening(face.isOdd ? 0 : 1),
    );
    boreRim = Path.combine(PathOperation.difference, near, through);
    path.fillType = PathFillType.evenOdd;
    path.addPath(through, Offset.zero);
  }
  WorkPlane get plane => WorkPlane(
    'Грань',
    world[0],
    (world[1] - world[0]).normalized(),
    normal.cross((world[1] - world[0]).normalized()),
  );
}

/// One boundary of a visible face. Dragging it changes the dimension across
/// that boundary within the face (for example, the width of a shelf top).
class ResizeEdge {
  final SceneFace face;
  final int index;
  const ResizeEdge(this.face, this.index);

  int get _next => (index + 1) % face.points.length;
  Offset get start => face.points[index];
  Offset get end => face.points[_next];
  int get _corner => faceCorners[face.face][index];
  int get axis {
    if (face.profileLocal case final local?) {
      final a = local[index], b = local[_next];
      return [0, 1, 2].firstWhere((i) => i != face.face ~/ 2 && a[i] == b[i]);
    }
    final alongEdge = (_corner ^ faceCorners[face.face][_next]).bitLength - 1;
    return 3 - (face.face ~/ 2) - alongEdge;
  }

  bool get positive => face.profileLocal == null
      ? (_corner & (1 << axis)) != 0
      : face.profileLocal![index][axis] == 1;
  Vector3 get direction {
    final b = face.beam;
    return [b.along, b.across, b.up][axis] * (positive ? 1.0 : -1.0);
  }

  bool canResize(Camera camera) =>
      (face.profileLocal == null ||
          face.profileLocal![index][axis] == 0 ||
          positive) &&
      !face.beam.locked(axis) &&
      (end - start).distanceSquared > .0001 &&
      direction
              .cross(camera.towardEye(face.world[index]).normalized())
              .length2 >
          .0001;

  double distanceSquared(Offset pos) => segmentDistanceSquared(pos, start, end);
}

Offset? _closestOnSegment(Offset pos, Offset start, Offset end) {
  final line = end - start, offset = pos - start;
  if (line.distanceSquared < .0001) return null;
  final t = (offset.dx * line.dx + offset.dy * line.dy) / line.distanceSquared;
  return start + line * t.clamp(0.0, 1.0);
}

double segmentDistanceSquared(Offset pos, Offset start, Offset end) {
  final point = _closestOnSegment(pos, start, end);
  return point == null ? double.infinity : (pos - point).distanceSquared;
}

typedef RulerTarget = ({
  Anchor anchor,
  SceneFace? face,
  (Vector3, Vector3)? guide,
});

enum SnapMode {
  auto,
  corner,
  edge,
  faceCenter,
  center,
  surface;

  String get label => switch (this) {
    SnapMode.auto => editorStrings.automatic,
    SnapMode.corner => editorStrings.corner,
    SnapMode.edge => editorStrings.edgeMidpoint,
    SnapMode.faceCenter => editorStrings.faceCenter,
    SnapMode.center => editorStrings.partCenter,
    SnapMode.surface => editorStrings.plane,
  };
}

class Scene {
  final Project project;
  final Camera camera;
  final Size size;
  final List<SceneFace> faces = [];
  Scene(Project document, this.camera, this.size)
    : project = document.visibleGeometry {
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
      if (b.rabbets.isNotEmpty) {
        for (final surface in b.profileFaces) {
          final normal = normals[surface.face];
          if (normal.dot(camera.towardEye(b.pointAt(surface.local.first))) <
              1e-6) {
            continue;
          }
          final world = surface.local.map(b.pointAt).toList();
          faces.add(
            SceneFace(
              b,
              surface.face,
              world,
              [for (final p in world) camera.project(p, size)],
              normal,
              camera,
              size,
              profileLocal: surface.local,
            ),
          );
        }
        continue;
      }
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
            size,
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
        if ((a.beam.id == b.beam.id && a.beam.rabbets.isEmpty) ||
            !a.bounds.overlaps(b.bounds)) {
          continue;
        }
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

  SceneFace? hit(Offset pos, {Set<int> exclude = const {}}) {
    for (final f in faces.reversed) {
      if (!exclude.contains(f.beam.id) &&
          f.bounds.contains(pos) &&
          f.path.contains(pos)) {
        return f;
      }
    }
    return null;
  }

  ResizeEdge? edgeAt(Offset pos, {required SceneFace? surface}) {
    const radius = 7.0;
    ResizeEdge? nearest;
    var distance = radius * radius;
    for (final f in surface == null ? faces.reversed : [surface]) {
      if (!f.bounds.inflate(radius).contains(pos)) continue;
      for (var i = 0; i < f.points.length; i++) {
        final edge = ResizeEdge(f, i);
        final d = edge.distanceSquared(pos);
        if (d < distance) {
          nearest = edge;
          distance = d;
        }
      }
    }
    return nearest;
  }

  RulerTarget? rulerTarget(
    Offset pos, {
    required bool sticky,
    SnapMode mode = SnapMode.auto,
  }) {
    final surface = hit(pos);
    final face = surface ?? (sticky ? edgeAt(pos, surface: null)?.face : null);
    final feature = sticky
        ? snap(pos, mode: mode, only: face == null ? null : {face.beam.id})
        : null;
    final line = sticky && mode == SnapMode.auto && face != null
        ? _rulerLine(pos, face)
        : null;
    if (feature != null) {
      final distance = (camera.project(feature.point, size) - pos).distance;
      // Leave a small capture area for corners and midpoints along a guide.
      if (line == null ||
          distance <=
              (camera.project(line.anchor.point, size) - pos).distance + 3) {
        final local =
            feature.local ?? project.byId[feature.beam]!.localAt(feature.point);
        bool onFace(SceneFace f) =>
            f.beam.id == feature.beam &&
            (local[f.face ~/ 2] -
                        (f.profileLocal?.first[f.face ~/ 2] ?? f.face % 2))
                    .abs() <
                1e-6 &&
            f.bounds.inflate(.01).contains(camera.project(feature.point, size));
        final support = face != null && onFace(face)
            ? face
            : faces.reversed.where(onFace).firstOrNull;
        return (anchor: feature, face: support, guide: null);
      }
    }
    if (line != null) return line;
    if (surface == null) return null;
    final p = camera.onPlane(pos, size, surface.plane);
    if (p == null) return null;
    return (
      anchor: Anchor(
        p,
        surface.beam.id,
        0,
        surface.beam.localAt(p),
        'Грань',
        surface.face,
      ),
      face: surface,
      guide: null,
    );
  }

  RulerTarget? _rulerLine(Offset pos, SceneFace face) {
    RulerTarget? best;
    var bestDistance = 8.0;
    final centerHeight =
        face.world.fold(0.0, (sum, p) => sum + p.z) / face.world.length;
    void consider(Vector3 a, Vector3 b, String label) {
      final screen = _closestOnSegment(
        pos,
        camera.project(a, size),
        camera.project(b, size),
      );
      if (screen == null) return;
      final distance = (pos - screen).distance;
      if (distance >= bestDistance) return;
      final p = camera.onPlane(screen, size, face.plane);
      if (p == null) return;
      final front = hit(screen);
      if (front != null && front.beam.id != face.beam.id) {
        final frontPoint = camera.onPlane(screen, size, front.plane);
        if (frontPoint != null && (frontPoint - p).dot(camera.eye) > .02) {
          return;
        }
      }
      best = (
        anchor: Anchor(
          p,
          face.beam.id,
          0,
          face.beam.localAt(p),
          label,
          face.face,
        ),
        face: face,
        guide: (a, b),
      );
      bestDistance = distance;
    }

    final corners = face.world;
    for (var i = 0; i < corners.length; i++) {
      final a = corners[i], b = corners[(i + 1) % corners.length];
      var label = 'Ребро';
      if ((a.z - b.z).abs() < 1e-6 && (a.z - centerHeight).abs() > 1e-6) {
        label = a.z > centerHeight ? 'Верхнее ребро' : 'Нижнее ребро';
      }
      consider(a, b, label);
    }
    for (var i = 0; corners.length == 4 && i < 2; i++) {
      consider(
        (corners[i] + corners[i + 1]) * .5,
        (corners[i + 2] + corners[(i + 3) % 4]) * .5,
        'Средняя линия',
      );
    }
    return best;
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
      if (b.rabbets.isNotEmpty) {
        final section = b.sectionOutline;
        for (var i = 0; i < section.length; i++) {
          final p = section[i], next = section[(i + 1) % section.length];
          for (final x in [0.0, 1.0]) {
            final t = p.clone()..x = x;
            if (mode == SnapMode.corner || mode == SnapMode.auto) {
              consider(Anchor(b.pointAt(t), b.id, 0, t));
            }
            if (mode == SnapMode.edge || mode == SnapMode.auto) {
              final mid = (p + next) * .5
                ..x = x;
              consider(Anchor(b.pointAt(mid), b.id, 0, mid, 'Середина ребра'));
            }
          }
          if (mode == SnapMode.edge || mode == SnapMode.auto) {
            final mid = p.clone()..x = .5;
            consider(Anchor(b.pointAt(mid), b.id, 0, mid, 'Середина ребра'));
          }
        }
      }
      final corners = b.corners;
      if (b.rabbets.isEmpty &&
          (mode == SnapMode.corner || mode == SnapMode.auto)) {
        for (var i = 0; i < 8; i++) {
          consider(Anchor(corners[i], b.id, i));
        }
      }
      if (b.rabbets.isEmpty &&
          (mode == SnapMode.edge || mode == SnapMode.auto)) {
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
        final t = f.profileLocal == null
            ? (Vector3.all(.5)..[f.face ~/ 2] = (f.face % 2).toDouble())
            : f.profileLocal!.reduce((a, b) => a + b) /
                  f.points.length.toDouble();
        if (f.profileLocal != null &&
            !f.path.contains(camera.project(f.beam.pointAt(t), size))) {
          continue;
        }
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
