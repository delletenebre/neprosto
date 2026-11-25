import '../l10n/strings.dart';

import 'dart:math' as math;

import 'model.dart';

class AssemblyResize {
  final Project project;
  final String? error;
  AssemblyResize(this.project, [this.error]);
}

// Reserve spans occupied by rigid cross-sections. Scale only the intervals
// between them so a rail ending at a post face still ends at that same face.
AssemblyResize resizeAssembly(
  Project project,
  Set<int> ids,
  Vector3 direction,
  double target, {
  LengthUnit? displayUnit,
}) {
  final spans = <({Beam beam, double lo, double hi, int dim})>[];
  for (final b in project.beams.where((b) => ids.contains(b.id))) {
    final coords = b.corners.map((p) => p.dot(direction));
    final basis = [b.along, b.across, b.up];
    final dim = basis.indexWhere((n) => n.dot(direction).abs() > 1 - 1e-7);
    spans.add((
      beam: b,
      lo: coords.reduce(math.min),
      hi: coords.reduce(math.max),
      dim: dim,
    ));
  }
  if (spans.isEmpty) return AssemblyResize(project);
  final start = spans.map((s) => s.lo).reduce(math.min),
      end = spans.map((s) => s.hi).reduce(math.max);
  final rigid =
      spans
          .where((s) => s.dim < 0 || s.beam.bevelled || s.beam.locked(s.dim))
          .toList()
        ..sort((a, b) => a.lo.compareTo(b.lo));
  final intervals = <({double lo, double hi})>[];
  for (final part in rigid) {
    if (intervals.isEmpty || intervals.last.hi < part.lo - 1e-7) {
      intervals.add((lo: part.lo, hi: part.hi));
    } else {
      final previous = intervals.removeLast();
      intervals.add((lo: previous.lo, hi: math.max(previous.hi, part.hi)));
    }
  }
  final fixed = intervals.fold(0.0, (a, b) => a + b.hi - b.lo);
  final free = end - start - fixed;
  if ((target - (end - start)).abs() < 1e-7) return AssemblyResize(project);
  if (free < 1e-6) {
    return AssemblyResize(project, editorStrings.fixedDimensionsFillSpan);
  }
  if (target <= fixed) {
    final unit = displayUnit ?? project.unit;
    return AssemblyResize(
      project,
      editorStrings.overallSizeMustExceed(unit.format(fixed), unit.symbol),
    );
  }
  final factor = (target - fixed) / free;
  double map(double x) {
    final reserved = intervals.fold(
      0.0,
      (sum, i) => sum + (x - i.lo).clamp(0, i.hi - i.lo),
    );
    return start + reserved + (x - start - reserved) * factor;
  }

  final updates = <int, Beam>{};
  for (final s in spans) {
    final b = s.beam, origin = b.origin.dot(direction);
    final size = b.size.clone();
    if (s.dim >= 0 && !b.bevelled && !b.locked(s.dim)) {
      size[s.dim] = map(s.hi) - map(s.lo);
      if (size[s.dim] < .001) {
        return AssemblyResize(project, editorStrings.partDimensionIsTooSmall);
      }
      if (size[s.dim] < b.minimumSize(s.dim)) {
        return AssemblyResize(
          project,
          size[s.dim] < b.minimumHoleSize(s.dim)
              ? editorStrings.invalidHole
              : editorStrings.invalidRabbet,
        );
      }
    }
    updates[b.id] = b.copy(
      origin: b.origin + direction * (map(origin) - origin),
      size: size,
    );
  }
  return AssemblyResize(project.edit(ids, (b) => updates[b.id]!));
}
