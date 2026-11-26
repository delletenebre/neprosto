import '../l10n/strings.dart';

import 'dart:math' as math;
import 'dart:ui';

import 'model.dart';
import 'step.dart';

class WorkPlane {
  final String name;
  String get displayName => switch (name) {
    'XY' => editorStrings.horizontalPlane,
    'XZ' => editorStrings.frontPlane,
    'YZ' => editorStrings.side,
    'Грань' => editorStrings.partFacePlane,
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
  Vector3 quantize(Vector3 p, double? step) {
    if (step == null) return p;
    final d = p - origin;
    return origin +
        u * roundToIncrement(d.dot(u), step) +
        v * roundToIncrement(d.dot(v), step);
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
  double roll = 0;
  bool perspective = false;
  double eyeDistance = 2400;
  Vector3 target = Vector3.zero();
  Offset pan = Offset.zero;
  Camera copy() => Camera()
    ..yaw = yaw
    ..pitch = pitch
    ..roll = roll
    ..scale = scale
    ..pan = pan
    ..target = target.clone()
    ..perspective = perspective
    ..eyeDistance = eyeDistance;
  Vector3 get right {
    final level = Vector3(math.cos(yaw), math.sin(yaw), 0);
    return roll == 0 ? level : turn(level, eye, roll);
  }

  Vector3 get eye => Vector3(
    math.sin(yaw) * math.cos(pitch),
    -math.cos(yaw) * math.cos(pitch),
    math.sin(pitch),
  );
  Vector3 get up => eye.cross(right);
  int? get orthographicDepthAxis {
    if (perspective) return null;
    final direction = eye;
    return [0, 1, 2].where((i) => direction[i].abs() > 1 - 1e-12).firstOrNull;
  }

  double projectionFactor(Vector3 p) => perspective
      ? eyeDistance /
            math.max(eyeDistance * .001, eyeDistance - (p - target).dot(eye))
      : 1;
  Vector3 towardEye(Vector3 p) =>
      perspective ? eye - (p - target) / eyeDistance : eye;
  (Vector3, Vector3)? clipLine(Vector3 a, Vector3 b) {
    if (perspective) {
      final limit = eyeDistance * .95;
      final da = (a - target).dot(eye), db = (b - target).dot(eye);
      if (da > limit && db > limit) return null;
      if (da > limit || db > limit) {
        final cut = a + (b - a) * ((limit - da) / (db - da));
        if (da > limit) {
          a = cut;
        } else {
          b = cut;
        }
      }
    }
    return (a, b);
  }

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
    roll = 0;
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

  void orbitAroundAxis(Vector3 normal, double radians, Vector3 pivot) {
    final nextEye = turn(eye, normal, radians);
    final nextRight = turn(right, normal, radians);
    target = pivot + turn(target - pivot, normal, radians);
    if (nextEye.x.abs() + nextEye.y.abs() > 1e-9) {
      yaw = math.atan2(nextEye.x, -nextEye.y);
    }
    pitch = math.asin(nextEye.z.clamp(-1, 1));
    final level = Vector3(math.cos(yaw), math.sin(yaw), 0);
    roll = math.atan2(
      nextRight.dot(nextEye.cross(level)),
      nextRight.dot(level),
    );
  }

  void facePlane(WorkPlane plane) {
    roll = 0;
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
  Path? boreRim, boreFloor;
  final _earlyOccluders = <SceneFace>[];
  late final Path? paintClip = _earlyOccluders.isEmpty
      ? null
      : _earlyOccluders.fold<Path>(
          Path()..addRect(bounds.inflate(8)),
          (clip, front) =>
              Path.combine(PathOperation.difference, clip, front.path),
        );
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
    if (beam.holes.isEmpty && beam.edgeHoles.isEmpty) return;
    final facePath = Path.from(path);
    final cutouts = Path();
    final basis = [beam.along, beam.across, beam.up];
    final axis = face ~/ 2;
    final drills = [
      for (final hole in beam.holes)
        if (axis == 2 || hole.boringEdge?.faceIndex == face)
          ...hole.drills(beam.size),
      for (final hole in beam.edgeHoles)
        if (hole.kind == EdgeHoleKind.pocket
            ? face == (hole.back ? 5 : 4)
            : hole.edge.faceIndex ~/ 2 == axis)
          hole.drills(beam.size).first,
    ];
    for (final drill in drills) {
      if (drill.axis != axis || (!drill.through && drill.face != face)) {
        continue;
      }
      final stop = drill.through && drill.face != face
          ? drill.entry
          : drill.stop;
      final floorCenter =
          beam.origin +
          beam.along * stop.x +
          beam.across * stop.y +
          beam.up * stop.z;
      // Project along the bit onto the actual surface, including bevels
      // and the recessed faces left by a rabbet.
      final segment = drill.stop - drill.entry;
      final direction = drill.angled
          ? (basis[0] * segment.x + basis[1] * segment.y + basis[2] * segment.z)
                .normalized()
          : basis[axis];
      final normalComponent = normal.dot(direction);
      if (normalComponent.abs() < 1e-8) continue;
      double toSurface(Vector3 p) =>
          normal.dot(world.first - p) / normalComponent;
      if (!drill.through && normal.dot(floorCenter - world.first) >= 0) {
        continue;
      }
      final lateral = drill.angled
          ? beam.up.cross(direction).normalized()
          : basis[(axis + 1) % 3];
      final u = lateral * (drill.diameter / 2);
      final v = direction.cross(lateral) * (drill.diameter / 2);
      final rimPoints = <Offset>[], floorPoints = <Offset>[];
      for (var i = 0; i < 40; i++) {
        final angle = i * math.pi / 20;
        final p = floorCenter + u * math.cos(angle) + v * math.sin(angle);
        rimPoints.add(cam.project(p + direction * toSurface(p), viewport));
        floorPoints.add(cam.project(p, viewport));
      }
      final near = Path.combine(
        PathOperation.intersect,
        facePath,
        Path()..addPolygon(rimPoints, true),
      );
      if (near.getBounds().isEmpty) continue;
      final floor = Path.combine(
        PathOperation.intersect,
        near,
        Path()..addPolygon(floorPoints, true),
      );
      (boreRim ??= Path()).addPath(
        Path.combine(PathOperation.difference, near, floor),
        Offset.zero,
      );
      if (drill.angled) {
        final ratio = pocketPilotDiameter / drill.diameter;
        final pilot = Path()
          ..addPolygon([
            for (var i = 0; i < 40; i++)
              cam.project(
                floorCenter +
                    (u * math.cos(i * math.pi / 20) +
                            v * math.sin(i * math.pi / 20)) *
                        ratio,
                viewport,
              ),
          ], true);
        boreRim!.addPath(
          Path.combine(PathOperation.intersect, floor, pilot),
          Offset.zero,
        );
      }
      if (drill.through) {
        cutouts.addPath(floor, Offset.zero);
      } else {
        (boreFloor ??= Path()).addPath(floor, Offset.zero);
      }
    }
    if (!cutouts.getBounds().isEmpty) {
      final solid = Path.combine(PathOperation.difference, facePath, cutouts);
      path.reset();
      path.fillType = solid.fillType;
      path.addPath(solid, Offset.zero);
    }
  }

  bool get isOuterFace =>
      profileLocal == null || profileLocal!.first[face ~/ 2] == face % 2;

  Iterable<List<Vector3>> get bandingPolygons sync* {
    final band = beam.banding;
    if (band.edges.isEmpty) return;
    // Only the outer panel surfaces receive tape. A routed recess stays bare.
    if (!isOuterFace) return;
    var surface = world;
    final width = band.width;
    if (width != null && width < beam.size.z) {
      final inset = (beam.size.z - width) / 2;
      final up = beam.up;
      double height(Vector3 p) => (p - beam.origin).dot(up);
      surface = clipPolygon(surface, (p) => height(p) - inset);
      surface = clipPolygon(surface, (p) => beam.size.z - inset - height(p));
    }
    for (final edge in band.edges) {
      final side = edge.faceIndex;
      if (side == face) {
        if (surface.length >= 3) yield surface;
        continue;
      }
      if (side ~/ 2 == face ~/ 2) continue;
      // Intersect this face with the physical tape thickness, including on mitres.
      final normal = beam.faceNormal(side);
      final outer = beam.corner(faceCorners[side].first);
      final strip = clipPolygon(
        surface,
        (p) => band.thickness + (p - outer).dot(normal),
      );
      if (strip.length >= 3) yield strip;
    }
  }

  WorkPlane get plane => WorkPlane(
    'Грань',
    world[0],
    (world[1] - world[0]).normalized(),
    normal.cross((world[1] - world[0]).normalized()),
  );

  // Visible normals point toward the eye. If all vertices lie on one side
  // of the other face, their order is exact even at a shared bevelled edge.
  int? _sideOf(SceneFace other) {
    var side = 0;
    for (final vertex in world) {
      final distance = (vertex - other.world.first).dot(other.normal);
      if (distance.abs() < 1e-6) continue;
      final sign = distance > 0 ? 1 : -1;
      if (side != 0 && side != sign) return null;
      side = sign;
    }
    return side;
  }
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

double? _segmentFraction(Offset pos, Offset start, Offset end) {
  final line = end - start, offset = pos - start;
  if (line.distanceSquared < .0001) return null;
  final t = (offset.dx * line.dx + offset.dy * line.dy) / line.distanceSquared;
  return t.clamp(0.0, 1.0);
}

Offset? _closestOnSegment(Offset pos, Offset start, Offset end) {
  final t = _segmentFraction(pos, start, end);
  return t == null ? null : start + (end - start) * t;
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
  final LengthInput input;
  final Camera camera;
  final Size size;
  final List<SceneFace> faces = [];
  Scene(Project document, this.camera, this.size, {LengthInput? input})
    : input = input ?? (unit: document.unit, increment: null),
      project = document.visibleGeometry {
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
        num depthDifference() {
          final sideA = a._sideOf(b);
          if (sideA != null) return sideA;
          final sideB = b._sideOf(a);
          if (sideB != null) return -sideB;
          final ray = camera.rayOrigin(overlap.center, size);
          final direction = camera.towardEye(ray);
          double depthAt(SceneFace f) =>
              (f.world.first - ray).dot(f.normal) / direction.dot(f.normal);
          return depthAt(a) - depthAt(b);
        }

        final delta = depthDifference();
        if (delta.abs() < 1e-6) continue;
        final far = delta < 0 ? i : j, near = delta < 0 ? j : i;
        ahead[far].add(near);
        incoming[near]++;
      }
    }
    final ordered = <SceneFace>[];
    while (ordered.length < faces.length) {
      var i = incoming.indexOf(0);
      if (i < 0) {
        // Long members can form a visibility cycle. Paint the face with the
        // fewest pending predecessors and mask it out of those drawn later.
        for (var j = 0; j < faces.length; j++) {
          if (incoming[j] > 0 && (i < 0 || incoming[j] < incoming[i])) i = j;
        }
        for (var j = 0; j < faces.length; j++) {
          if (incoming[j] > 0 && ahead[j].contains(i)) {
            faces[j]._earlyOccluders.add(faces[i]);
          }
        }
      }
      incoming[i] = -1;
      ordered.add(faces[i]);
      for (final j in ahead[i]) {
        if (incoming[j] >= 0) incoming[j]--;
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
          f.path.contains(pos) &&
          !f._earlyOccluders.any(
            (near) =>
                !exclude.contains(near.beam.id) && near.path.contains(pos),
          )) {
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

  Vector3? pointOnFace(Offset pos, SceneFace face) {
    final plane = face.plane;
    final raw = camera.onPlane(pos, size, plane);
    if (raw == null || input.increment == null) return raw;
    final point = plane.quantize(raw, input.stepMm);
    final screen = camera.project(point, size);
    // A rounded click must still belong to the face, including around cutouts.
    if (face.path.contains(screen)) return point;
    for (var i = 0; i < face.points.length; i++) {
      if (segmentDistanceSquared(
            screen,
            face.points[i],
            face.points[(i + 1) % face.points.length],
          ) <
          1e-10) {
        return point;
      }
    }
    return raw;
  }

  RulerTarget? rulerTarget(
    Offset pos, {
    required bool sticky,
    SnapMode mode = SnapMode.auto,
    Vector3? planeOrigin,
  }) {
    final surface = hit(pos);
    final part = _partRulerTarget(pos, surface, sticky, mode);
    if (!sticky || surface != null || project.workspaceSize == null) {
      return part;
    }
    final boundary = workspaceTarget(pos, mode, planeOrigin);
    if (part == null || boundary == null) return part ?? boundary;
    double distance(RulerTarget t) =>
        (camera.project(t.anchor.point, size) - pos).distance;
    return distance(boundary) + .001 < distance(part) ? boundary : part;
  }

  RulerTarget? _partRulerTarget(
    Offset pos,
    SceneFace? surface,
    bool sticky,
    SnapMode mode,
  ) {
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
    final p = pointOnFace(pos, surface);
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

  RulerTarget? workspaceTarget(
    Offset pos,
    SnapMode mode,
    Vector3? planeOrigin, {
    Set<int> exclude = const {},
  }) {
    if (mode != SnapMode.auto &&
        mode != SnapMode.edge &&
        mode != SnapMode.corner) {
      return null;
    }
    final room = project.workspaceSize;
    if (room == null || room.x <= 0 || room.y <= 0 || room.z <= 0) return null;
    final corners = project.workspaceCorners;
    RulerTarget? best;
    var bestScore = double.infinity, bestDepth = double.negativeInfinity;
    void consider(
      Vector3 point,
      String label,
      (Vector3, Vector3) guide, {
      Offset? onLine,
    }) {
      final screen = camera.project(point, size);
      final distance = ((onLine ?? screen) - pos).distance;
      if (distance > (onLine == null ? 13 : 8)) return;
      // Give a corner or midpoint a small capture area along the edge.
      final score = distance - (onLine == null ? 3 : 0);
      final depth = point.dot(camera.eye);
      if (score > bestScore + .001 ||
          ((score - bestScore).abs() <= .001 && depth <= bestDepth) ||
          hit(screen, exclude: exclude) != null) {
        return;
      }
      best = (
        anchor: Anchor.workspace(point, room, label),
        face: null,
        guide: guide,
      );
      bestScore = score;
      bestDepth = depth;
    }

    void edge(Vector3 a, Vector3 b) {
      final clipped = camera.clipLine(a, b);
      if (clipped == null) return;
      final (from, to) = clipped;
      if (mode != SnapMode.edge) {
        if (identical(from, a)) consider(a, 'Угол', clipped);
        if (identical(to, b)) consider(b, 'Угол', clipped);
      }
      if (mode == SnapMode.corner) return;
      final mid = (a + b) * .5;
      if ((mid - from).dot(mid - to) <= 0) {
        consider(mid, 'Середина ребра', clipped);
      }
      if (mode != SnapMode.auto) return;
      final start = camera.project(from, size), end = camera.project(to, size);
      final t = _segmentFraction(pos, start, end);
      if (t == null) return;
      final screen = start + (end - start) * t;
      if ((screen - pos).distance > 8 ||
          hit(screen, exclude: exclude) != null) {
        return;
      }
      // Interpolate in world space using the projected endpoints' depth factors.
      final fromWeight = (1 - t) * camera.projectionFactor(from);
      final toWeight = t * camera.projectionFactor(to);
      final raw = from + (to - from) * (toWeight / (fromWeight + toWeight));
      final direction = (b - a).normalized();
      final offset = input.round((raw - a).dot(direction));
      final point =
          a +
          direction *
              offset.clamp((from - a).dot(direction), (to - a).dot(direction));
      consider(point, 'Ребро', clipped, onLine: screen);
    }

    // In an axis view the front and back outlines coincide. Measure on the
    // current plane so the invisible depth does not add to the ruler length.
    final depthAxis = camera.orthographicDepthAxis;
    if (depthAxis != null) {
      final depth = (planeOrigin?[depthAxis] ?? 0.0).clamp(
        0.0,
        room[depthAxis],
      );
      final ring = faceCorners[2 * depthAxis];
      for (final i in ring) {
        corners[i][depthAxis] = depth;
      }
      for (var i = 0; i < ring.length; i++) {
        edge(corners[ring[i]], corners[ring[(i + 1) % ring.length]]);
      }
    } else {
      forEachBoxEdge(corners, edge);
    }
    return best;
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
      final along = b - a;
      final length = along.length;
      if (length == 0) return;
      final direction = along / length;
      final distanceAlong = input.round((p - a).dot(direction));
      final point = a + direction * distanceAlong.clamp(0.0, length);
      best = (
        anchor: Anchor(
          point,
          face.beam.id,
          0,
          face.beam.localAt(point),
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
        final p = pointOnFace(pos, f);
        if (p == null) continue;

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
      final label = path.last + outward / outward.distance * 23;
      final marginX = math.min(26.0, size.width / 2);
      final marginY = math.min(14.0, size.height / 2);
      arrows.add(
        TurnArrow(
          sign,
          path,
          Offset(
            label.dx.clamp(marginX, size.width - marginX),
            label.dy.clamp(marginY, size.height - marginY),
          ),
        ),
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
