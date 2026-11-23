import 'dart:math' as math;

import 'model.dart';
import 'scene.dart';

typedef GuideSegment = (Vector3, Vector3);

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

/// All extents are measured in the working plane. Building the reference
/// footprints once per drag keeps pointer updates independent of mesh size.
class MoveSnap {
  final List<Vector3> _axes;
  late final _Footprint _moving;
  final List<_Footprint> _fixed = [];
  final List<double?> _held = [null, null];

  MoveSnap(Project project, Set<int> ids, WorkPlane plane)
    : _axes = _basis(project.byId[ids.first]!, plane) {
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

  void release() => _held.fillRange(0, 2, null);

  ({Vector3 delta, List<MoveGuide> guides}) apply(
    Vector3 rawDelta,
    Vector3 steppedDelta,
    Camera camera,
  ) {
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
        if (pixels > (held ? 10 : 6)) return;
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
    return (delta: _world(result), guides: guides);
  }
}
