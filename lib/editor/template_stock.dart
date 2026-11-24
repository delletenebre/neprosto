import 'dart:math' as math;
import 'dart:ui';

import 'model.dart';
import 'part_finish.dart';
import 'parts_workbook.dart' show blankLength;

/// A purchased board or sheet and the positions of its parts before cutting.
class StockBlank {
  StockBlank(this.size, this.thickness);
  Size size;
  final double thickness;
  final cuts = <int, Rect>{};
  late final _free = [Offset.zero & size];

  Size get requiredSize => Size(
    cuts.values.map((r) => r.right).reduce(math.max),
    cuts.values.map((r) => r.bottom).reduce(math.max),
  );
}

double templateKerf(LengthUnit unit) => unit == LengthUnit.inch ? 25.4 / 8 : 3;
const _epsilon = .000001;
double _area(Size s) => s.width * s.height;
bool _fits(Size a, Size b) =>
    a.width <= b.width + _epsilon && a.height <= b.height + _epsilon;

List<Size> _stockSizes(Beam part, bool imperial) {
  if (part.finish.texture == PartTexture.wood) {
    return [
      for (final length in imperial ? [72 * 25.4, 96 * 25.4] : [2000.0, 3000.0])
        Size(length, part.size.y),
    ];
  }
  if (imperial) {
    return [
      if (part.finish.texture == PartTexture.plywood ||
          part.finish.texture == PartTexture.mdf)
        const Size(48 * 25.4, 24 * 25.4),
      const Size(96 * 25.4, 48 * 25.4),
    ];
  }
  return switch (part.finish.texture) {
    PartTexture.plywood => const [
      Size(760, 760),
      Size(1525, 1525),
      Size(2440, 1220),
    ],
    PartTexture.mdf => const [
      Size(1220, 610),
      Size(2800, 1220),
      Size(2800, 2070),
    ],
    _ => const [Size(1200, 400), Size(1200, 600), Size(2800, 2070)],
  };
}

/// Compare straight-cut layouts on the offered formats. Grain follows the stock
/// length on wood, plywood and woodgrain laminate. Plain panels may turn 90°.
List<StockBlank> templateStock(Project project) {
  final groups = <(PartFinish, double, double), List<Beam>>{};
  for (final b in project.beams) {
    final section = b.finish.texture == PartTexture.wood ? b.size.y : 0.0;
    final stock = b.finish.texture == PartTexture.mdf
        ? FinishPreset.mdf.finish
        : b.finish;
    (groups[(stock, b.size.z, section)] ??= []).add(b);
  }
  final result = <StockBlank>[];
  final kerf = templateKerf(project.unit);
  for (final parts in groups.values) {
    final sizes = _stockSizes(parts.first, project.unit == LengthUnit.inch);
    final texture = parts.first.finish.texture;
    final rotate =
        texture == PartTexture.mdf || texture == PartTexture.laminate;
    List<StockBlank>? best;
    var bestArea = double.infinity;
    var bestFootprint = double.infinity;
    for (final size in sizes) {
      for (final byLength in [true, false]) {
        double priority(Beam p) =>
            byLength ? blankLength(p) : blankLength(p) * p.size.y;
        final order = [...parts]
          ..sort((a, b) {
            final cmp = priority(b).compareTo(priority(a));
            return cmp == 0 ? a.id.compareTo(b.id) : cmp;
          });
        for (final strip in [true, false]) {
          final blanks = <StockBlank>[];
          for (final part in order) {
            if (blanks.any((b) => _place(b, part, kerf, rotate, strip))) {
              continue;
            }
            final blank = StockBlank(size, part.size.z);
            if (!_place(blank, part, kerf, rotate, strip)) break;
            blanks.add(blank);
          }
          if (blanks.fold(0, (n, b) => n + b.cuts.length) != parts.length) {
            continue;
          }
          var area = 0.0;
          var footprint = 0.0;
          for (final blank in blanks) {
            final used = blank.requiredSize;
            footprint += _area(used);
            final options = sizes.where((s) => _fits(used, s));
            blank.size = options.reduce((a, b) => _area(a) <= _area(b) ? a : b);
            area += _area(blank.size);
          }
          final sameArea = (area - bestArea).abs() < _epsilon;
          if (best == null ||
              area < bestArea - _epsilon ||
              (sameArea &&
                  (blanks.length < best.length ||
                      (blanks.length == best.length &&
                          footprint < bestFootprint - _epsilon)))) {
            best = blanks;
            bestArea = area;
            bestFootprint = footprint;
          }
        }
      }
    }
    if (best == null) throw StateError('Template part exceeds available stock');
    result.addAll(best);
  }
  return result;
}

bool _place(StockBlank blank, Beam part, double kerf, bool rotate, bool strip) {
  var bestIndex = -1;
  var bestScore = double.infinity;
  var chosen = Size.zero;
  final size = Size(blankLength(part), part.size.y);
  for (final (index, slot) in blank._free.indexed) {
    for (final orientation in [
      size,
      if (rotate && size.width != size.height) size.flipped,
    ]) {
      if (!_fits(orientation, slot.size)) continue;
      final score = math.min(
        slot.width - orientation.width,
        slot.height - orientation.height,
      );
      if (score < bestScore) {
        bestIndex = index;
        bestScore = score;
        chosen = orientation;
      }
    }
  }
  if (bestIndex < 0) return false;
  final slot = blank._free.removeAt(bestIndex);
  final cut = slot.topLeft & chosen;
  blank.cuts[part.id] = cut;
  final remaining = [
    Rect.fromLTRB(
      cut.right + kerf,
      slot.top,
      slot.right,
      strip ? cut.bottom : slot.bottom,
    ),
    Rect.fromLTRB(
      slot.left,
      cut.bottom + kerf,
      strip ? slot.right : cut.right,
      slot.bottom,
    ),
  ];
  blank._free.addAll(
    remaining.where((r) => r.width > _epsilon && r.height > _epsilon),
  );
  return true;
}
