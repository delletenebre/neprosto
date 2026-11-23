import 'dart:math' as math;

import 'model.dart';

class JointPreview {
  final Beam fixed, moving;
  final double inside;
  JointPreview(this.fixed, this.moving, this.inside);
  double get saw => (180 - inside) / 2;
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
    throw const FormatException('Введите внутренний угол между 0° и 180°');
  }
  if ((a.size.y - b.size.y).abs() > .001 ||
      (a.size.z - b.size.z).abs() > .001) {
    throw const FormatException(
      'Для симметричного стыка выберите одинаковые сечения',
    );
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
    final divisor = normal.dot(stock.along);
    final slope = (
      y: -normal.dot(stock.across) * stock.size.y / divisor,
      z: -normal.dot(stock.up) * stock.size.z / divisor,
    );
    final result = stock.copy(
      startCut: end ? null : slope,
      endCut: end ? slope : null,
    );
    if (result.size.x < result.minimumLength) {
      throw const FormatException(
        'Заготовка слишком короткая для этого запила',
      );
    }
    return result;
  }

  return JointPreview(cut(a, firstEnd), cut(moved, secondEnd), inside);
}
