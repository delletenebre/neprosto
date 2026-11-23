import 'dart:ui';

enum StockAxis {
  length('Длина', 'Д', Color(0xff245b9b)),
  width('Ширина', 'Ш', Color(0xff14705e)),
  thickness('Толщина', 'Т', Color(0xff914a1b));

  const StockAxis(this.label, this.letter, this.color);
  final String label, letter;
  final Color color;
}
