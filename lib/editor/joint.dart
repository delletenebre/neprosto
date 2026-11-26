import '../l10n/strings.dart';

import 'dart:math' as math;

import 'contact.dart';
import 'model.dart';

class JointPreview {
  final Beam fixed, moving;
  final double inside;
  JointPreview(this.fixed, this.moving, this.inside);
  double get saw => (180 - inside) / 2;
}

/// Signed angle of a line marked on a face, measured from a square crosscut.
double markingAngle(double offset, double span) =>
    math.atan2(offset, span) * 180 / math.pi;

double? markingOffset(double degrees, double span) {
  if (!degrees.isFinite || degrees.abs() >= 90) return null;
  final offset = math.tan(degrees * math.pi / 180) * span;
  return offset.abs() <= Beam.maxCutOffset ? offset : null;
}

/// Stock lies flat with its start on the operator's left. Positive angles
/// move the front miter handle or the top of the blade to the operator's right.
({double miter, double bevel}) sawAngles(Beam b, bool end) {
  final cut = end ? b.endCut : b.startCut;
  final slope = cut.y / b.size.y;
  return (
    miter: -markingAngle(cut.y, b.size.y),
    bevel: markingAngle(cut.z / b.size.z, math.sqrt(1 + slope * slope)),
  );
}

double endAngle(Beam b, bool end) {
  final cut = end ? b.endCut : b.startCut;
  return math.atan(
        math.sqrt(
          math.pow(cut.y / b.size.y, 2) + math.pow(cut.z / b.size.z, 2),
        ),
      ) *
      180 /
      math.pi;
}

List<double> edgeLengths(Beam b) => [
  for (final i in [0, 2, 4, 6]) b.corner(i).distanceTo(b.corner(i + 1)),
];

typedef JointCut = ({Beam stock, Beam part, bool end});
typedef FaceJoint = ({Beam support, int face, JointCut cut});

const _cutTolerance = 1e-6;

Vector3 _inward(Beam part, bool end) => part.along * (end ? -1 : 1);

double jointInsideAngle(Beam a, bool endA, Beam b, bool endB) =>
    math.acos(_inward(a, endA).dot(_inward(b, endB)).clamp(-1, 1)) *
    180 /
    math.pi;

({double y, double z}) _cutSlope(Beam stock, Vector3 normal) {
  final divisor = normal.dot(stock.along);
  final y = -normal.dot(stock.across) * stock.size.y / divisor;
  final z = -normal.dot(stock.up) * stock.size.z / divisor;
  if (!y.isFinite ||
      !z.isFinite ||
      y.abs() > Beam.maxCutOffset ||
      z.abs() > Beam.maxCutOffset) {
    throw FormatException(editorStrings.invalidEndCut);
  }
  return (y: y, z: z);
}

List<Vector3> _cutOutline(Beam part, bool end) => [
  for (final p in part.sectionOutline)
    part.pointAt(Vector3(end ? 1 : 0, p.y, p.z)),
];

double jointOffcutDepth(JointCut cut) {
  final old = _cutOutline(cut.stock, cut.end);
  final next = _cutOutline(cut.part, cut.end);
  final inward = _inward(cut.stock, cut.end);
  return next.indexed
      .map((p) => (p.$2 - old[p.$1]).dot(inward))
      .reduce(math.max);
}

JointCut _trim(Beam stock, bool end, Vector3 point, Vector3 normal) {
  final divisor = normal.dot(stock.along);
  if (divisor.abs() < _cutTolerance) {
    throw FormatException(editorStrings.invalidEndCut);
  }
  final distance = (point - faceCenter(stock, 0, false)).dot(normal) / divisor;
  final length = end ? distance : stock.size.x - distance;
  final slope = _cutSlope(stock, normal);
  final part = stock.copy(
    origin: end ? stock.origin : stock.origin + stock.along * distance,
    size: Vector3(length, stock.size.y, stock.size.z),
    startCut: end ? null : slope,
    endCut: end ? slope : null,
  );
  if (length < part.minimumSize(0)) {
    throw FormatException(editorStrings.stockTooShort);
  }
  if (stock.locked(0) && (length - stock.size.x).abs() > _cutTolerance) {
    throw FormatException(editorStrings.dimensionLocked);
  }
  final old = _cutOutline(stock, end), next = _cutOutline(part, end);
  final inward = _inward(stock, end);
  if (next.indexed.any(
    (p) => (p.$2 - old[p.$1]).dot(inward) < -_cutTolerance,
  )) {
    throw FormatException(editorStrings.jointCutOutsideStock);
  }
  return (stock: stock, part: part, end: end);
}

/// Match the inner and outer longitudinal edges at each level of the bend.
/// Their intersections determine the actual plane, including unequal widths.
List<JointCut> cutJointInPlace(Beam a, bool endA, Beam b, bool endB) {
  final inwardA = _inward(a, endA), inwardB = _inward(b, endB);
  final cross = inwardA.cross(inwardB);
  if (cross.length < _cutTolerance) {
    throw FormatException(editorStrings.jointNoCommonCut);
  }
  final level = cross.normalized();
  List<Vector3> orderedEdges(Beam part, Vector3 inside) =>
      [
        for (final corner in [0, 2, 4, 6]) part.corner(corner),
      ]..sort((p, q) {
        final height = (p - q).dot(level);
        return height.abs() < _cutTolerance
            ? p.dot(inside).compareTo(q.dot(inside))
            : height.sign.toInt();
      });

  final edgesA = orderedEdges(a, level.cross(inwardA));
  final edgesB = orderedEdges(b, inwardB.cross(level));
  final points = <Vector3>[];
  for (var i = 0; i < edgesA.length; i++) {
    final delta = edgesB[i] - edgesA[i];
    if (delta.dot(level).abs() > _cutTolerance) {
      throw FormatException(editorStrings.jointNoCommonCut);
    }
    final distance = delta.cross(inwardB).dot(cross) / cross.length2;
    points.add(edgesA[i] + inwardA * distance);
  }
  final normal = (points[1] - points[0])
      .cross(points[2] - points[0])
      .normalized();
  if ((points[3] - points[0]).dot(normal).abs() > _cutTolerance ||
      normal.dot(inwardA) * normal.dot(inwardB) >= 0) {
    throw FormatException(editorStrings.jointNoCommonCut);
  }
  final first = _trim(a, endA, points.first, normal);
  final second = _trim(b, endB, points.first, normal);
  final outlineA = _cutOutline(first.part, endA);
  final outlineB = _cutOutline(second.part, endB);
  if (outlineA.length != outlineB.length ||
      outlineA.any(
        (p) => !outlineB.any((q) => p.distanceTo(q) < _cutTolerance),
      )) {
    throw FormatException(editorStrings.jointNoCommonCut);
  }
  return [first, second];
}

JointCut trimJointToFace(Beam part, Beam reference, int face) {
  assert(face >= 2 && face < 6);
  final normal = reference.faceNormal(face);
  final end = part.along.dot(normal) < 0;
  final cut = _trim(
    part,
    end,
    reference.corner(faceCorners[face].first),
    normal,
  );
  if (!facesMeet(cut.part, end ? 1 : 0, reference, face)) {
    throw FormatException(editorStrings.jointNoFaceCut);
  }
  return cut;
}

List<JointCut>? endJointOption(Beam a, Beam b) {
  List<JointCut>? best;
  var shortest = double.infinity;
  for (final endA in [false, true]) {
    for (final endB in [false, true]) {
      try {
        final cuts = cutJointInPlace(a, endA, b, endB);
        final depths = cuts.map(jointOffcutDepth).toList();
        if (depths.every((depth) => depth <= _cutTolerance)) continue;
        // A board that continues well past the joint can serve as a support.
        final atEnds = cuts.indexed.every((entry) {
          final (i, cut) = entry;
          final section = math.max(cut.stock.size.y, cut.stock.size.z);
          final slope = cut.end ? cut.part.endCut : cut.part.startCut;
          return depths[i] <=
              section + math.max(section, slope.y.abs() + slope.z.abs());
        });
        if (!atEnds) continue;
        final score = depths[0] + depths[1];
        if (score < shortest) {
          shortest = score;
          best = cuts;
        }
      } on FormatException {
        continue;
      }
    }
  }
  return best;
}

List<FaceJoint> faceJointOptions(Beam a, Beam b) {
  final options = <FaceJoint>[];
  for (final (part, support) in [(a, b), (b, a)]) {
    for (var face = 2; face < 6; face++) {
      try {
        final cut = trimJointToFace(part, support, face);
        if (jointOffcutDepth(cut) > _cutTolerance) {
          options.add((support: support, face: face, cut: cut));
        }
      } on FormatException {
        continue;
      }
    }
  }
  double fractionRemoved(FaceJoint option) =>
      jointOffcutDepth(option.cut) / option.cut.stock.size.x;
  return options..sort((p, q) {
    final byWaste = fractionRemoved(p).compareTo(fractionRemoved(q));
    return byWaste != 0
        ? byWaste
        : (p.support.id == b.id ? 0 : 1).compareTo(
            q.support.id == b.id ? 0 : 1,
          );
  });
}

/// Place the second end at the first end's centre. The cut plane bisects the
/// inward directions. Project that plane onto both sets of longitudinal edges.
JointPreview makeJoint(
  Beam a,
  Beam b, {
  required bool firstEnd,
  required bool secondEnd,
  required double inside,
  required bool bendThroughWidth,
  required bool flip,
}) {
  if (inside <= 0 || inside >= 180 || !inside.isFinite) {
    throw FormatException(editorStrings.invalidInsideAngle);
  }
  if ((a.size.y - b.size.y).abs() > .001 ||
      (a.size.z - b.size.z).abs() > .001) {
    throw FormatException(editorStrings.matchingSectionsRequired);
  }
  final radians = inside * math.pi / 180;
  final inward = a.along * (firstEnd ? -1.0 : 1.0);
  final side = (bendThroughWidth ? a.across : a.up) * (flip ? -1.0 : 1.0);
  final other = inward * math.cos(radians) + side * math.sin(radians);
  final x = other * (secondEnd ? -1.0 : 1.0);
  final y = bendThroughWidth ? a.up.cross(x).normalized() : a.across;
  final z = x.cross(y);
  final vertex = a.pointAt(Vector3(firstEnd ? 1 : 0, .5, .5));
  final origin =
      vertex -
      x * (secondEnd ? b.size.x : 0.0) -
      y * (b.size.y * .5) -
      z * (b.size.z * .5);
  final moved = b.copy(origin: origin, along: x, across: y);
  final normal = (inward - other).normalized();
  Beam cut(Beam stock, bool end) {
    final slope = _cutSlope(stock, normal);
    final result = stock.copy(
      startCut: end ? null : slope,
      endCut: end ? slope : null,
    );
    if (result.size.x < result.minimumLength) {
      throw FormatException(editorStrings.stockTooShort);
    }
    return result;
  }

  return JointPreview(cut(a, firstEnd), cut(moved, secondEnd), inside);
}
