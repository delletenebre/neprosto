import '../l10n/strings.dart';

import 'dart:ui';

enum StockAxis {
  length(Color(0xff245b9b)),
  width(Color(0xff14705e)),
  thickness(Color(0xff914a1b));

  const StockAxis(this.color);

  final Color color;
  String get label => switch (this) {
    StockAxis.length => editorStrings.length,
    StockAxis.width => editorStrings.width,
    StockAxis.thickness => editorStrings.thickness,
  };

  String get letter => switch (this) {
    StockAxis.length => editorStrings.lengthInitial,
    StockAxis.width => editorStrings.widthInitial,
    StockAxis.thickness => editorStrings.thicknessInitial,
  };
}
