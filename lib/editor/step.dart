import 'dart:convert';

import 'model.dart';

class EditStep {
  final bool enabled;
  final Map<LengthUnit, double> values;
  EditStep({this.enabled = true, Map<LengthUnit, double> values = const {}})
    : values = Map.unmodifiable(values);
  double value(LengthUnit unit) =>
      values[unit] ?? (unit == LengthUnit.inch ? 1 / 16 : 1);
  double millimeters(LengthUnit unit) => value(unit) * unit.factor;
  double round(double mm, LengthUnit unit) {
    if (!enabled) return mm;
    final step = millimeters(unit);
    return (mm / step).round() * step;
  }

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
