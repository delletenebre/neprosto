import '../l10n/strings.dart';

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
  final cut = end ? b.endCut : b.startCut;
  final width = markingAngle(cut.y, b.size.y);
  final thickness = markingAngle(cut.z, b.size.z);
  final marks = [
    if (width.abs() >= 1e-6)
      '${mm(width.abs())}° ${width > 0 ? editorStrings.positiveWidth : editorStrings.negativeWidth}',
    if (thickness.abs() >= 1e-6)
      '${mm(thickness.abs())}° ${thickness > 0 ? editorStrings.positiveThickness : editorStrings.negativeThickness}',
  ];
  return marks.isEmpty ? '0°' : marks.join(' · ');
}

String stockRabbets(Beam part, LengthUnit unit) => [
  for (final edge in RabbetEdge.values)
    if (part.rabbets[edge] case final cut?)
      '${edge.label} · ${unit.format(cut.width)} × ${unit.format(cut.depth)} ${unit.symbol}',
].join('\n');

Uint8List encodePartsWorkbook(LengthUnit unit, List<StockRow> rows) {
  final book = Excel.createExcel();
  book.rename(book.getDefaultSheet()!, editorStrings.stock);
  final summary = book[editorStrings.stock],
      details = book[editorStrings.partsLabel];
  final hasCuts = rows.any((r) => r.sample.bevelled);
  final hasRabbets = rows.any((r) => r.sample.rabbets.isNotEmpty);
  final headerStyle = CellStyle(
    bold: true,
    fontColorHex: ExcelColor.white,
    backgroundColorHex: ExcelColor.fromHexString('FF334B62'),
    verticalAlign: VerticalAlign.Center,
  );

  for (final sheet in [summary, details]) {
    final columns = [
      (
        sheet == summary ? editorStrings.stockPiece : editorStrings.partName,
        40.0,
      ),
      (editorStrings.stockLengthInUnits(unit.symbol), 25.0),
      (editorStrings.widthLabel(unit.symbol), 18.0),
      (editorStrings.thicknessLabel(unit.symbol), 18.0),
      if (sheet == summary) (editorStrings.quantityPcs, 18.0),
      if (hasCuts) ...[
        (editorStrings.startCut, 30.0),
        (editorStrings.endCut, 30.0),
      ],
      if (hasRabbets) (editorStrings.rabbetTitle, 46.0),
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
  final wholeSizeStyle = CellStyle(numberFormat: NumFormat.defaultNumeric);
  final fractionalSizeStyle = CellStyle(
    numberFormat: const CustomNumericNumFormat(formatCode: '0.0#'),
  );
  final profileStyle = CellStyle(textWrapping: TextWrapping.WrapText);
  void writePart(Sheet sheet, Beam part, String name, {int? count}) {
    final sizes = [
      blankLength(part) / unit.factor,
      part.size.y / unit.factor,
      part.size.z / unit.factor,
    ];
    final rowIndex = sheet.maxRows;
    sheet.appendRow([
      TextCellValue(name),
      for (final size in sizes) DoubleCellValue(size),
      if (count != null) IntCellValue(count),
      if (hasCuts) ...[
        TextCellValue(stockCut(part, false)),
        TextCellValue(stockCut(part, true)),
      ],
      if (hasRabbets) TextCellValue(stockRabbets(part, unit)),
    ]);
    if (part.rabbets.length > 1) {
      sheet.setRowHeight(rowIndex, 16.0 * part.rabbets.length);
      sheet
              .cell(
                CellIndex.indexByColumnRow(
                  columnIndex: sheet.maxColumns - 1,
                  rowIndex: rowIndex,
                ),
              )
              .cellStyle =
          profileStyle;
    }
    for (final (i, size) in sizes.indexed) {
      final cell = CellIndex.indexByColumnRow(
        columnIndex: i + 1,
        rowIndex: rowIndex,
      );
      sheet.cell(cell).cellStyle = (size * 100).round() % 100 == 0
          ? wholeSizeStyle
          : fractionalSizeStyle;
    }
  }

  for (final row in rows) {
    writePart(summary, row.sample, row.name, count: row.parts.length);
    for (final part in row.parts) {
      writePart(details, part, part.name);
    }
  }
  return Uint8List.fromList(book.encode()!);
}
