import 'dart:typed_data';

import 'package:excel/excel.dart';

import 'model.dart';
import 'joint.dart';

class StockRow {
  final List<Beam> parts;
  StockRow(this.parts);
  Beam get sample => parts.first;
  String get name {
    if (parts.length == 1) return sample.name;
    final names = parts
        .map((b) => b.name.replaceFirst(RegExp(r'\s+\d+$'), ''))
        .toSet();
    return names.join(', ');
  }

  double number(int column) => switch (column) {
    1 => blankLength(sample),
    2 => sample.size.y,
    3 => sample.size.z,
    _ => parts.length.toDouble(),
  };
}

double blankLength(Beam b) {
  return b.size.x +
      (b.startCut.y.abs() +
              b.startCut.z.abs() +
              b.endCut.y.abs() +
              b.endCut.z.abs()) /
          2;
}

String stockCut(Beam b, bool end) {
  final slope = end ? b.endCut : b.startCut;
  final angle = endAngle(b, end);
  if (angle < 1e-6) return '0°';
  final dirs = [
    if (slope.y.abs() > .000001) slope.y > 0 ? '+Ш' : '−Ш',
    if (slope.z.abs() > .000001) slope.z > 0 ? '+Т' : '−Т',
  ].join();
  return '${mm(angle)}° $dirs';
}

Uint8List encodePartsWorkbook(LengthUnit unit, List<StockRow> rows) {
  final book = Excel.createExcel();
  book.rename(book.getDefaultSheet()!, 'Заготовки');
  final summary = book['Заготовки'], details = book['Детали'];
  final hasCuts = rows.any((r) => r.sample.bevelled);
  final headerStyle = CellStyle(
    bold: true,
    fontColorHex: ExcelColor.white,
    backgroundColorHex: ExcelColor.fromHexString('FF334B62'),
    verticalAlign: VerticalAlign.Center,
  );

  for (final sheet in [summary, details]) {
    final columns = [
      (sheet == summary ? 'Заготовка' : 'Название детали', 40.0),
      ('Длина заготовки, ${unit.symbol}', 25.0),
      ('Ширина, ${unit.symbol}', 18.0),
      ('Толщина, ${unit.symbol}', 18.0),
      if (sheet == summary) ('Количество, шт.', 18.0),
      if (hasCuts) ...[('Начальный торец', 22.0), ('Конечный торец', 22.0)],
    ];
    sheet.appendRow([for (final c in columns) TextCellValue(c.$1)]);
    sheet.setRowHeight(0, 24);
    for (final (i, column) in columns.indexed) {
      sheet.setColumnWidth(i, column.$2);
      sheet
              .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
              .cellStyle =
          headerStyle;
    }
  }
  void writePart(Sheet sheet, Beam part, String name, {int? count}) {
    sheet.appendRow([
      TextCellValue(name),
      DoubleCellValue(blankLength(part) / unit.factor),
      DoubleCellValue(part.size.y / unit.factor),
      DoubleCellValue(part.size.z / unit.factor),
      if (count != null) IntCellValue(count),
      if (hasCuts) ...[
        TextCellValue(stockCut(part, false)),
        TextCellValue(stockCut(part, true)),
      ],
    ]);
  }

  for (final row in rows) {
    writePart(summary, row.sample, row.name, count: row.parts.length);
    for (final part in row.parts) {
      writePart(details, part, part.name);
    }
  }
  return Uint8List.fromList(book.encode()!);
}
