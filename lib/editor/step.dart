import 'dart:convert';
import 'dart:math' as math;

import 'arithmetic.dart';
import 'model.dart';

extension EditStepFormat on LengthUnit {
  String formatStep(double mm) {
    if (this != LengthUnit.inch) return format(mm);
    final inches = mm / factor;
    if (inches == inches.truncateToDouble()) return inches.toStringAsFixed(0);

    // Find the simplest fraction matching the stored decimal, allowing for
    // floating-point error from converting through millimeters.
    final [mantissa, exponent] = inches.toStringAsExponential().split('e');
    final digits = mantissa.replaceAll('.', '');
    var dividend = BigInt.parse(digits);
    var divisor = BigInt.from(10).pow(digits.length - 1 - int.parse(exponent));
    var previousTop = BigInt.zero, top = BigInt.one;
    var previousBottom = BigInt.one, bottom = BigInt.zero;
    while (divisor != BigInt.zero) {
      final quotient = dividend ~/ divisor;
      (previousTop, top) = (top, quotient * top + previousTop);
      (previousBottom, bottom) = (bottom, quotient * bottom + previousBottom);
      final value = top.toDouble() / bottom.toDouble();
      if ((value - inches).abs() <= inches * 4e-16) break;
      (dividend, divisor) = (divisor, dividend.remainder(divisor));
    }
    return bottom == BigInt.one ? '$top' : '$top/$bottom';
  }
}

double roundToIncrement(double value, double increment) {
  final ticks = value / increment;
  // Beyond 2^52 a double already represents an integral number of ticks.
  if (!ticks.isFinite || ticks.abs() >= 4503599627370496) return value;
  // Keep decimal half steps symmetric despite binary floating-point error.
  final magnitude = ticks.abs();
  final whole = magnitude.floor();
  final tolerance = math.min(magnitude * 2.22e-16, 1e-8);
  final count = magnitude - whole >= .5 - tolerance ? whole + 1 : whole;
  return ticks.sign * count * increment;
}

typedef LengthInput = ({LengthUnit unit, double? increment});

extension LengthInputValues on LengthInput {
  double? get stepMm => increment == null ? null : increment! * unit.factor;

  double round(double mm) =>
      increment == null ? mm : roundToIncrement(mm, stepMm!);

  double? parse(String text) {
    final n = calculate(text);
    if (n == null) return null;
    final mm = n * unit.factor;
    return mm.isFinite ? round(mm) : null;
  }

  String format(double mm) {
    final step = increment;
    if (step == null) return unit.format(mm);
    // A custom increment such as 1/16 inch needs four decimal places.
    final stepText = unit.format(step * unit.factor);
    if (stepText == '0') return unit.format(mm);
    final dot = stepText.indexOf('.');
    final digits = dot < 0 ? 0 : stepText.length - dot - 1;
    return unit.format(mm, digits: digits);
  }
}

class EditStep {
  final bool enabled;
  final Map<LengthUnit, double> values;
  EditStep({this.enabled = true, Map<LengthUnit, double> values = const {}})
    : values = Map.unmodifiable(values);
  double value(LengthUnit unit) =>
      values[unit] ?? (unit == LengthUnit.inch ? 1 / 16 : 1);
  double millimeters(LengthUnit unit) => value(unit) * unit.factor;
  late final _inchLabel =
      '${LengthUnit.inch.formatStep(millimeters(LengthUnit.inch))}″';
  String label(LengthUnit unit) =>
      unit == LengthUnit.inch ? _inchLabel : unit.format(millimeters(unit));
  LengthInput input(LengthUnit unit) =>
      (unit: unit, increment: enabled ? value(unit) : null);
  double round(double mm, LengthUnit unit) => input(unit).round(mm);

  EditStep change(LengthUnit unit, double v, bool use) =>
      EditStep(enabled: use, values: {...values, unit: v});
  String encode() => jsonEncode({
    'enabled': enabled,
    'values': {for (final e in values.entries) e.key.name: e.value},
  });
  factory EditStep.decode(String source) {
    final data = jsonDecode(source);
    final values = <LengthUnit, double>{};
    for (final unit in LengthUnit.values) {
      final n = data['values']?[unit.name];
      if (n is num && n.isFinite && n > 0 && n <= 1e8) {
        values[unit] = n.toDouble();
      }
    }
    return EditStep(enabled: data['enabled'] != false, values: values);
  }
}
