import 'dart:math' as math;

import 'model.dart';

/// A separating-axis test for oriented boxes. The same axes give the time
/// interval during which a moving end face touches a stationary beam.
class _Box {
  final Vector3 center, half;
  final List<Vector3> basis;
  _Box(this.center, this.half, this.basis);
  factory _Box.beam(Beam b) => _Box(
    (b.origin + b.corner(7)) * .5,
    b.size * .5,
    [b.along, b.across, b.up],
  );
  double radius(Vector3 n) =>
      half.x * basis[0].dot(n).abs() +
      half.y * basis[1].dot(n).abs() +
      half.z * basis[2].dot(n).abs();
}

Iterable<Vector3> _axes(_Box a, _Box b) sync* {
  yield* a.basis;
  yield* b.basis;
  for (final u in a.basis) {
    for (final v in b.basis) {
      final n = u.cross(v);
      if (n.length2 > 1e-12) yield n.normalized();
    }
  }
}

Iterable<Vector3> _polyAxes(Beam a, Beam b) sync* {
  for (var i = 0; i < 6; i++) {
    yield a.faceNormal(i);
    yield b.faceNormal(i);
  }
  List<Vector3> edges(Beam p) => [
    p.along,
    for (final cut in [p.startCut, p.endCut]) ...[
      (p.across * p.size.y + p.along * cut.y).normalized(),
      (p.up * p.size.z + p.along * cut.z).normalized(),
    ],
  ];
  final bs = edges(b);
  for (final u in edges(a)) {
    for (final v in bs) {
      final n = u.cross(v);
      if (n.length2 > 1e-12) yield n.normalized();
    }
  }
}

({double lo, double hi}) _range(List<Vector3> pts, Vector3 axis) {
  var lo = double.infinity, hi = -lo;
  for (final p in pts) {
    final v = p.dot(axis);
    lo = math.min(lo, v);
    hi = math.max(hi, v);
  }
  return (lo: lo, hi: hi);
}

bool intersects(Beam a, Beam b) {
  if (a.rabbets.isNotEmpty || b.rabbets.isNotEmpty) {
    return a.solidStrips().any(
      (first) => b.solidStrips().any((second) => intersects(first, second)),
    );
  }
  if (a.bevelled || b.bevelled) {
    final ac = a.corners, bc = b.corners;
    for (final n in _polyAxes(a, b)) {
      final ra = _range(ac, n), rb = _range(bc, n);
      if (ra.hi <= rb.lo + 1e-6 || rb.hi <= ra.lo + 1e-6) return false;
    }
    return true;
  }
  final first = _Box.beam(a),
      second = _Box.beam(b),
      delta = second.center - first.center;
  return _axes(first, second).every(
    (n) => first.radius(n) + second.radius(n) - delta.dot(n).abs() > 1e-6,
  );
}

class Contact {
  final double travel;
  final int obstacle;
  Contact(this.travel, this.obstacle);
}

Contact? firstContact(
  Beam beam,
  int dimension,
  bool positive,
  Iterable<Beam> neighbours,
) {
  if (beam.rabbets.isNotEmpty) {
    Contact? first;
    for (final strip in beam.solidStrips(vertical: dimension == 2)) {
      final hit = firstContact(strip, dimension, positive, neighbours);
      if (hit != null && (first == null || hit.travel < first.travel)) {
        first = hit;
      }
    }
    return first;
  }
  final box = _Box.beam(beam);
  final direction = box.basis[dimension] * (positive ? 1.0 : -1.0);
  final half = box.half.clone()..[dimension] = 0;
  final face = _Box(
    box.center + direction * box.half[dimension],
    half,
    box.basis,
  );
  Contact? first;
  for (final other in neighbours.expand((b) => b.solidStrips())) {
    if (other.id == beam.id) continue;
    if (beam.bevelled || other.bevelled) {
      final f = [
            for (var i = 0; i < 8; i++)
              if (((i >> dimension) & 1) == (positive ? 1 : 0)) beam.corner(i),
          ],
          target = other.corners;
      var enter = double.negativeInfinity, exit = double.infinity;
      for (final n in _polyAxes(beam, other)) {
        final a = _range(f, n), b = _range(target, n), v = direction.dot(n);
        if (v.abs() < 1e-8) {
          if (a.hi <= b.lo + 1e-7 || b.hi <= a.lo + 1e-7) {
            exit = double.negativeInfinity;
            break;
          }
        } else {
          final t0 = (b.lo - a.hi) / v, t1 = (b.hi - a.lo) / v;
          enter = math.max(enter, math.min(t0, t1));
          exit = math.min(exit, math.max(t0, t1));
        }
      }
      final travel = math.max(0.0, enter);
      if (exit > travel + 1e-7 && (first == null || travel < first.travel)) {
        first = Contact(travel, other.id);
      }
      continue;
    }
    final b = _Box.beam(other), separation = b.center - face.center;
    var enter = double.negativeInfinity, leave = double.infinity;
    for (final n in _axes(face, b)) {
      final radius = face.radius(n) + b.radius(n),
          offset = separation.dot(n),
          speed = direction.dot(n);
      if (speed.abs() < 1e-8) {
        // Parts with only side-to-side contact can slide past each other.
        if (radius - offset.abs() <= 1e-6) {
          leave = double.negativeInfinity;
          break;
        }
      } else {
        final t0 = (offset - radius) / speed, t1 = (offset + radius) / speed;
        enter = math.max(enter, math.min(t0, t1));
        leave = math.min(leave, math.max(t0, t1));
      }
    }
    if (leave <= math.max(0, enter) + 1e-7) continue;
    final travel = math.max(0.0, enter);
    if (first == null || travel < first.travel) {
      first = Contact(travel, other.id);
    }
  }
  return first;
}

Vector3 faceCenter(Beam b, int dimension, bool positive) {
  return b.pointAt(Vector3.all(.5)..[dimension] = positive ? 1 : 0);
}

Beam resizeEnd(
  Beam b,
  int dimension,
  bool positive,
  double change, {
  Contact? stop,
}) {
  if (b.locked(dimension)) return b;
  final oldSize = b.size[dimension];
  final newSize = (oldSize + change)
      .clamp(
        math.max(b.minimumSize(dimension), math.min(1.0, oldSize)),
        oldSize + (stop?.travel ?? double.infinity),
      )
      .toDouble();
  final dir = [b.along, b.across, b.up][dimension];
  return b.copy(
    size: b.size.clone()..[dimension] = newSize,
    origin: positive ? b.origin : b.origin - dir * (newSize - oldSize),
  );
}

extension ProjectContact on Project {
  Set<int> get overlaps {
    final result = <int>{};
    final sorted = [
      for (final b in beams) (beam: b, bounds: Bounds3.points(b.corners)),
    ]..sort((a, b) => a.bounds.low.x.compareTo(b.bounds.low.x));
    for (var i = 0; i < sorted.length; i++) {
      final a = sorted[i];
      for (var j = i + 1; j < sorted.length; j++) {
        final b = sorted[j];
        if (b.bounds.low.x >= a.bounds.high.x - 1e-6) break;
        if (b.bounds.low.y >= a.bounds.high.y ||
            b.bounds.high.y <= a.bounds.low.y ||
            b.bounds.low.z >= a.bounds.high.z ||
            b.bounds.high.z <= a.bounds.low.z) {
          continue;
        }
        if (intersects(a.beam, b.beam)) {
          result.add(a.beam.id);
          result.add(b.beam.id);
        }
      }
    }
    return result;
  }
}

Project mate(
  Project project,
  Set<int> selection,
  Anchor from,
  Anchor to, {
  bool withinWorkspace = false,
}) {
  final a = from.resolve(project), b = to.resolve(project);
  if (from.label != 'Плоскость' ||
      to.label != 'Плоскость' ||
      from.face == null ||
      to.face == null) {
    return project.move(selection, b - a, withinWorkspace: withinWorkspace);
  }
  Vector3 normal(Anchor ref) {
    final part = project.byId[ref.beam]!;
    return part.faceNormal(ref.face!);
  }

  final source = normal(from), target = -normal(to);
  final angle = math.acos(source.dot(target).clamp(-1, 1));
  if (angle < 1e-7) {
    return project.move(selection, b - a, withinWorkspace: withinWorkspace);
  }
  var pivotAxis = source.cross(target);
  if (pivotAxis.length < 1e-7) {
    pivotAxis = source.cross(source.z.abs() < .9 ? axis(2) : axis(1));
  }
  pivotAxis.normalize();
  final placed = project.edit(
    selection,
    (part) => part.copy(
      origin: b + turn(part.origin - a, pivotAxis, angle),
      along: turn(part.along, pivotAxis, angle).normalized(),
      across: turn(part.across, pivotAxis, angle).normalized(),
    ),
  );
  final limits = withinWorkspace
      ? project.moveLimits(selection, placed: placed)
      : null;
  if (limits == null) return placed;
  // Reject an orientation that cannot fit even after shifting the whole group.
  for (var i = 0; i < 3; i++) {
    if (limits.low[i] > limits.high[i] + 1e-7) return project;
  }
  final correction = Vector3.zero()..clamp(limits.low, limits.high);
  return correction.length2 < 1e-14
      ? placed
      : placed.move(selection, correction);
}

class _Solid {
  final Beam part;
  late final corners = part.corners;
  late final bounds = Bounds3.points(corners);
  _Solid(this.part);
}

class _MoveContact extends Contact {
  final Vector3 normal;
  _MoveContact(super.travel, super.obstacle, this.normal);
}

/// Sweeps the selected stock from its last position, reusing the geometry
/// throughout a drag. Each rabbet strip and each group member moves separately
/// through the collision test, all with the same translation.
class MoveContacts {
  final _moving = <_Solid>[], _fixed = <_Solid>[];

  MoveContacts(Project project, Set<int> ids) {
    for (final part in project.beams) {
      final solids = ids.contains(part.id) ? _moving : _fixed;
      solids.addAll(part.solidStrips().map(_Solid.new));
    }
  }

  _MoveContact? _sweep(Vector3 start, Vector3 direction, double distance) {
    _MoveContact? nearest;
    final path = distance.isFinite
        ? Bounds3.points([start, start + direction * distance])
        : null;
    for (final a in _moving) {
      final swept = path == null
          ? null
          : Bounds3(a.bounds.low + path.low, a.bounds.high + path.high);
      for (final b in _fixed) {
        if (swept != null && !swept.overlapsVolume(b.bounds)) continue;
        var normal = direction;
        var enter = double.negativeInfinity, exit = double.infinity;
        for (final n in _polyAxes(a.part, b.part)) {
          final ra = _range(a.corners, n), rb = _range(b.corners, n);
          final offset = start.dot(n), speed = direction.dot(n);
          final lo = rb.lo - ra.hi - offset, hi = rb.hi - ra.lo - offset;
          final parallel = distance.isFinite
              ? (speed * distance).abs() < 1e-8
              : speed.abs() < 1e-8;
          if (parallel) {
            if (lo >= -1e-7 || hi <= 1e-7) {
              exit = double.negativeInfinity;
              break;
            }
          } else {
            final t0 = lo / speed, t1 = hi / speed;
            final entry = math.min(t0, t1);
            if (entry > enter) {
              enter = entry;
              normal = n;
            }
            exit = math.min(exit, math.max(t0, t1));
          }
          if (exit <= enter + 1e-8 || enter >= distance) break;
        }
        if (enter >= distance || exit <= math.max(0, enter) + 1e-7) continue;
        if (enter < -.00001 && exit <= -enter + 1e-7) {
          continue; // Already overlapping and moving out.
        }
        final travel = math.max(0.0, enter);
        if (nearest == null || travel < nearest.travel) {
          nearest = _MoveContact(travel, b.part.id, normal);
        }
      }
    }
    return nearest;
  }

  bool overlapsAt(Vector3 offset) {
    for (final a in _moving) {
      final bounds = Bounds3(a.bounds.low + offset, a.bounds.high + offset);
      final moved = a.part.copy(origin: a.part.origin + offset);
      for (final b in _fixed) {
        if (bounds.overlapsVolume(b.bounds) && intersects(moved, b.part)) {
          return true;
        }
      }
    }
    return false;
  }

  Vector3 limitDrag(
    Vector3 start,
    Vector3 target, {
    Vector3? planeNormal,
    Bounds3? workspace,
  }) {
    final delta = target - start, distance = delta.length;
    if (distance < 1e-10) return target;
    final direction = delta / distance;
    final hit = _sweep(start, direction, distance);
    if (hit == null) return target;
    final contact = start + direction * hit.travel;
    if (planeNormal == null || delta.dot(planeNormal).abs() > 1e-7) {
      return contact;
    }
    // Slide along the intersection of the contact face and working plane.
    final tangent = planeNormal.cross(hit.normal);
    if (tangent.normalize() < 1e-8) return contact;
    var slide = (target - contact).dot(tangent);
    if (slide < 0) {
      tangent.negate();
      slide = -slide;
    }
    if (workspace != null) {
      for (var i = 0; i < 3; i++) {
        if (tangent[i].abs() < 1e-12) continue;
        final wall = tangent[i] > 0 ? workspace.high[i] : workspace.low[i];
        slide = math.min(slide, (wall - contact[i]) / tangent[i]);
      }
    }
    if (slide < 1e-8) return contact;
    final next = _sweep(contact, tangent, slide);
    return contact + tangent * (next?.travel ?? slide);
  }
}

Contact? travelToStop(Project project, Set<int> ids, Vector3 direction) {
  final contacts = MoveContacts(project, ids);
  return contacts._sweep(Vector3.zero(), direction, double.infinity);
}
