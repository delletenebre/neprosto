import 'dart:math' as math;
import 'dart:ui' show Size;

import 'contact.dart';
import 'model.dart';
import 'scene.dart';

typedef GuideSegment = (Vector3, Vector3);
typedef DragSnap = ({Vector3 delta, List<MoveGuide> guides});

const _capturePixels = 6.0, _releasePixels = 10.0;

class MoveGuide {
  final GuideSegment line;
  // A second segment marks the reference gap whose size was matched.
  final GuideSegment? reference;
  MoveGuide(this.line, [this.reference]);
  double? get gap => reference == null ? null : line.$1.distanceTo(line.$2);
}

class _Footprint {
  final Bounds3 box;
  final List<bool> sides;
  _Footprint(this.box, this.sides);
}

/// The six supporting points of a moving selection or of a single resizing end.
class WorkspaceSnap {
  final Vector3 room;
  final List<Vector3> _ends;
  final Set<int> _held = {};

  WorkspaceSnap(this.room, Iterable<Vector3> points)
    : _ends = List.filled(6, points.first) {
    for (final p in points) {
      for (var i = 0; i < 3; i++) {
        if (p[i] < _ends[2 * i][i]) _ends[2 * i] = p;
        if (p[i] > _ends[2 * i + 1][i]) _ends[2 * i + 1] = p;
      }
    }
  }

  void release() => _held.clear();

  double _offset(int wall) {
    final i = wall ~/ 2;
    return (wall.isOdd ? room[i] : 0.0) - _ends[wall][i];
  }

  double travelLimit(Vector3 direction) {
    var limit = double.infinity;
    for (var i = 0; i < 3; i++) {
      if (direction[i].abs() < 1e-8) continue;
      final wall = 2 * i + (direction[i] > 0 ? 1 : 0);
      limit = math.min(limit, _offset(wall) / direction[i]);
    }
    return math.max(0.0, limit);
  }

  DragSnap apply(
    Vector3 raw,
    Vector3 stepped,
    List<Vector3> directions,
    Camera camera,
  ) {
    final walls = <int>[];
    while (directions.isNotEmpty) {
      int? nearest;
      var bestScore = double.infinity;
      late Vector3 correction;
      for (var i = 0; i < 3; i++) {
        // Move only along the axes that remain free in this gesture.
        final normal = Vector3.zero();
        for (final dir in directions) {
          normal.addScaled(dir, dir[i]);
        }
        if (normal[i] < 1e-10) continue;
        final perUnit = normal / normal[i];
        for (final wall in [2 * i, 2 * i + 1]) {
          final from = _ends[wall] + raw;
          final screen = camera.project(from, Size.zero);
          final to = from + perUnit * (_offset(wall) - raw[i]);
          final pixels = (camera.project(to, Size.zero) - screen).distance;
          final held = _held.contains(wall);
          final score = pixels - (held ? .7 : 0);
          if (pixels > (held ? _releasePixels : _capturePixels) ||
              score >= bestScore ||
              (camera.project(from + normal.normalized(), Size.zero) - screen)
                      .distance <
                  .0001) {
            continue;
          }
          bestScore = score;
          nearest = wall;
          correction = perUnit;
        }
      }
      if (nearest == null) break;
      walls.add(nearest);
      final i = nearest ~/ 2, offset = _offset(nearest);
      stepped = stepped + correction * (offset - stepped[i]);
      if (directions.length == 1) break;
      raw = raw + correction * (offset - raw[i]);
      // After the first snap the remaining motion is along that wall.
      final tangent = directions[0].cross(directions[1]).cross(axis(i));
      directions = [tangent.normalized()];
    }
    _held
      ..clear()
      ..addAll(walls);
    return (
      delta: stepped,
      guides: [for (final wall in walls) _guide(wall, stepped, camera)],
    );
  }

  MoveGuide _guide(int wall, Vector3 delta, Camera camera) {
    final point = _ends[wall] + delta;
    var line = (point, point);
    var longest = 0.0;
    for (var i = 0; i < 3; i++) {
      if (i == wall ~/ 2) continue;
      final a = point.clone()..[i] = _ends[2 * i][i] + delta[i];
      final b = point.clone()..[i] = _ends[2 * i + 1][i] + delta[i];
      final visible = camera.clipLine(a, b);
      if (visible == null) continue;
      final length =
          (camera.project(visible.$2, Size.zero) -
                  camera.project(visible.$1, Size.zero))
              .distanceSquared;
      if (length > longest) {
        line = visible;
        longest = length;
      }
    }
    return MoveGuide(line);
  }
}

/// All extents are measured in the working plane. Building the reference
/// footprints once per drag keeps pointer updates independent of mesh size.
class MoveSnap {
  final Bounds3? workspaceLimits;
  final WorkspaceSnap? _workspace;
  final MoveContacts _contacts;
  Vector3 _lastSnapped = Vector3.zero();
  Vector3? _freePosition;
  final List<Vector3> _axes;
  late final _Footprint _moving;
  final List<_Footprint> _fixed = [];
  final List<double?> _held = [null, null];

  MoveSnap(Project project, Set<int> ids, WorkPlane plane)
    : workspaceLimits = project.moveLimits(ids),
      _workspace = project.workspaceSize == null
          ? null
          : WorkspaceSnap(
              project.workspaceSize!,
              ids.expand((id) => project.byId[id]!.corners),
            ),
      _contacts = MoveContacts(project, ids),
      _axes = _basis(project.byId[ids.first]!, plane) {
    _moving = _footprint(project.beams.where((b) => ids.contains(b.id)));
    for (final b in project.beams) {
      if (!ids.contains(b.id)) _fixed.add(_footprint([b]));
    }
  }

  static List<Vector3> _basis(Beam part, WorkPlane plane) {
    final n = plane.normal;
    final u =
        [
          part.along,
          part.across,
          part.up,
        ].where((dir) => dir.dot(n).abs() < 1e-6).firstOrNull ??
        plane.u;
    return [u, n.cross(u), n];
  }

  Vector3 _local(Vector3 p) =>
      Vector3(p.dot(_axes[0]), p.dot(_axes[1]), p.dot(_axes[2]));
  Vector3 _world(Vector3 p) => _axes[0] * p.x + _axes[1] * p.y + _axes[2] * p.z;

  _Footprint _footprint(Iterable<Beam> parts) {
    final corners = [
      for (final part in parts) part.corners.map(_local).toList(),
    ];
    final box = Bounds3.points(corners.expand((c) => c));
    final sides = <bool>[];
    for (var i = 0; i < 2; i++) {
      for (final edge in [box.low[i], box.high[i]]) {
        sides.add(
          corners.any(
            (c) => faceCorners.any(
              (face) => face.every((k) => (c[k][i] - edge).abs() < 1e-5),
            ),
          ),
        );
      }
    }
    return _Footprint(box, sides);
  }

  void release() {
    _held.fillRange(0, 2, null);
    _workspace?.release();
  }

  void moveFreely(Vector3 delta) {
    release();
    _freePosition = delta;
  }

  Vector3 constrain(Vector3 delta, {Vector3? planeNormal}) {
    final room = workspaceLimits;
    final free = _freePosition;
    if (free != null) {
      // Re-enter sticky mode where the free drag left the part if it fits.
      if ((room == null || room.clampTranslation(free) == free) &&
          !_contacts.overlapsAt(free)) {
        _lastSnapped = free;
      }
      _freePosition = null;
    }
    final target =
        room?.clampTranslation(delta, planeNormal: planeNormal) ?? delta;
    _lastSnapped = _contacts.limitDrag(
      _lastSnapped,
      target,
      planeNormal: planeNormal,
      workspace: room,
    );
    return _lastSnapped;
  }

  DragSnap apply(Vector3 rawDelta, Vector3 steppedDelta, Camera camera) {
    final raw = _local(rawDelta), result = _local(steppedDelta);
    final guides = <MoveGuide>[];
    for (var i = 0; i < 2; i++) {
      final dir = _axes[i];
      final scale =
          camera.scale *
          math.sqrt(
            math.pow(dir.dot(camera.right), 2) +
                math.pow(dir.dot(camera.up), 2),
          );
      if (scale < .0001) continue;
      final other = 1 - i, stock = _moving.box;
      final lo = stock.low + raw, hi = stock.high + raw;
      final width = hi[i] - lo[i];
      var score = double.infinity;
      double? chosen;
      MoveGuide? guide;
      void offer(
        double low,
        MoveGuide Function() makeGuide, {
        bool gap = false,
      }) {
        final pixels = (low - lo[i]).abs() * scale;
        final held = _held[i] != null && (_held[i]! - low).abs() < 1e-6;
        if (pixels > (held ? _releasePixels : _capturePixels)) return;
        final rank = pixels - (held ? .7 : 0) - (gap ? .08 : 0);
        if (rank >= score) return;
        score = rank;
        chosen = low;
        guide = makeGuide();
      }

      Vector3 point(double edge, double across, double depth) {
        final p = Vector3.zero()
          ..[i] = edge
          ..[other] = across
          ..z = depth;
        return _world(p);
      }

      final left = <_Footprint>[], right = <_Footprint>[];
      for (final ref in _fixed) {
        final b = ref.box;
        final near = math.max(lo[other], b.low[other]);
        final far = math.min(hi[other], b.high[other]);
        final depth = math.min(hi.z, b.high.z);
        final thickness = depth - math.max(lo.z, b.low.z);
        if (thickness < -1e-5 || near - far > 100 / camera.scale) continue;
        for (var s = 0; s < 2; s++) {
          if (!_moving.sides[i * 2 + s]) continue;
          for (var r = 0; r < 2; r++) {
            if (!ref.sides[i * 2 + r]) continue;
            final edge = r == 0 ? b.low[i] : b.high[i];
            offer(
              edge - s * width,
              () => MoveGuide((
                point(edge, math.min(lo[other], b.low[other]), depth),
                point(edge, math.max(hi[other], b.high[other]), depth),
              )),
            );
          }
        }
        // A bearer touching the underside of several slats is outside their row.
        if (far - near < 1e-5 || thickness < 1e-5) continue;
        if (b.center[i] < (lo[i] + hi[i]) / 2) {
          left.add(ref);
        } else {
          right.add(ref);
        }
      }
      left.sort((a, b) => b.box.high[i].compareTo(a.box.high[i]));
      right.sort((a, b) => a.box.low[i].compareTo(b.box.low[i]));
      final leftEdge = left.firstOrNull?.box.high[i] ?? double.negativeInfinity;
      final rightEdge = right.firstOrNull?.box.low[i] ?? double.infinity;

      void spacing(
        _Footprint a,
        _Footprint b,
        double low,
        double newStart,
        double refStart,
        double gap,
      ) {
        if (gap <= 1e-5 ||
            low < leftEdge - 1e-5 ||
            low + width > rightEdge + 1e-5) {
          return;
        }
        final near = math.max(
          lo[other],
          math.max(a.box.low[other], b.box.low[other]),
        );
        final far = math.min(
          hi[other],
          math.min(a.box.high[other], b.box.high[other]),
        );
        final depth = math.min(hi.z, math.min(a.box.high.z, b.box.high.z));
        if (near >= far ||
            depth <= math.max(lo.z, math.max(a.box.low.z, b.box.low.z))) {
          return;
        }
        GuideSegment segment(double start) => (
          point(start, (near + far) / 2, depth),
          point(start + gap, (near + far) / 2, depth),
        );
        offer(
          low,
          () => MoveGuide(segment(newStart), segment(refStart)),
          gap: true,
        );
      }

      if (_moving.sides[2 * i] && _moving.sides[2 * i + 1]) {
        if (left.isNotEmpty &&
            right.isNotEmpty &&
            left.first.sides[2 * i + 1] &&
            right.first.sides[2 * i]) {
          final gap = (rightEdge - leftEdge - width) / 2;
          spacing(
            left.first,
            right.first,
            leftEdge + gap,
            leftEdge,
            rightEdge - gap,
            gap,
          );
        }
        if (left.length >= 2 &&
            left[1].sides[2 * i + 1] &&
            left.first.sides[2 * i] &&
            left.first.sides[2 * i + 1]) {
          final start = left[1].box.high[i],
              gap = left.first.box.low[i] - start;
          spacing(left[1], left.first, leftEdge + gap, leftEdge, start, gap);
        }
        if (right.length >= 2 &&
            right[1].sides[2 * i] &&
            right.first.sides[2 * i] &&
            right.first.sides[2 * i + 1]) {
          final start = right.first.box.high[i],
              gap = right[1].box.low[i] - start;
          spacing(
            right.first,
            right[1],
            rightEdge - gap - width,
            rightEdge - gap,
            start,
            gap,
          );
        }
      }
      _held[i] = chosen;
      if (chosen != null) {
        result[i] = chosen! - stock.low[i];
        guides.add(guide!);
      }
    }
    final delta = _world(result);
    for (var i = 0; i < 2; i++) {
      if (_held[i] != null) raw[i] = result[i];
    }
    final wall = _workspace?.apply(_world(raw), delta, [
      for (var i = 0; i < 2; i++)
        if (_held[i] == null) _axes[i],
    ], camera);
    if (wall == null || wall.guides.isEmpty) {
      return (delta: delta, guides: guides);
    }
    return (delta: wall.delta, guides: [...guides, ...wall.guides]);
  }
}
