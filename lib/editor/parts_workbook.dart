import '../l10n/strings.dart';

import 'dart:typed_data';

import 'package:excel/excel.dart';

import 'model.dart';
import 'part_finish.dart';
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

String stockBanding(Beam part, LengthUnit unit) {
  final band = part.banding;
  if (band.edges.isEmpty) return '';
  final sides = [
    for (final edge in PanelEdge.values)
      if (band.edges.contains(edge))
        '${edge.alongWidth ? editorStrings.lengthInitial : editorStrings.widthInitial}${edge.atMax ? '+' : '−'}',
  ].join(', ');
  return '${unit.format(band.thickness)} × ${unit.format(band.width ?? part.size.z)} ${unit.symbol} · ${hexColor(band.rgb)} · $sides';
}

String stockRabbets(Beam part, LengthUnit unit) => [
  for (final edge in RabbetEdge.values)
    if (part.rabbets[edge] case final cut?)
      '${edge.label} · ${unit.format(cut.width)} × ${unit.format(cut.depth)} ${unit.symbol}',
].join('\n');

String stockHoles(Beam part, LengthUnit unit) {
  final s = editorStrings;
  return [
    for (final h in part.holes) ...[
      'Ø${unit.format(h.diameter)} · ${s.length} ${unit.format(h.centerX(part.size))} · '
          '${s.width} ${unit.format(h.centerY(part.size))} · '
          '${h.depth == null ? s.throughHole : '${h.back ? s.faceB : s.faceA} · ${s.rabbetDepth} ${unit.format(h.depth!)}'}',
      if (h.boltBore case final bolt? when h.boringEdge != null)
        '${s.boltBoreOption} Ø${unit.format(bolt.diameter)} · '
            '${h.boringEdge!.alongWidth ? s.lengthInitial : s.widthInitial}${h.boringEdge!.atMax ? '+' : '−'} · '
            '${h.boringEdge!.alongWidth ? s.width : s.length} ${unit.format(h.boringEdge!.alongWidth ? h.centerY(part.size) : h.centerX(part.size))} · '
            '${h.back ? s.faceB : s.faceA} → ${unit.format(bolt.faceOffset)} · '
            '${s.rabbetDepth} ${unit.format(h.boringEdge!.centerInset(h, part.size))}',
    ],
    for (final h in part.edgeHoles)
      '${h.kind.label} Ø${unit.format(h.diameter)} · ${h.edge.alongWidth ? s.lengthInitial : s.widthInitial}${h.edge.atMax ? '+' : '−'} · '
          '${s.datum} ${h.edge.alongWidth ? s.widthInitial : s.lengthInitial}${h.fromEnd ? '+' : '−'} → ${unit.format(h.offset)} · '
          '${h.back ? s.faceB : s.faceA} → ${unit.format(h.height)} · '
          '${h.kind == EdgeHoleKind.pocket
              ? '15° · Ø${unit.format(pocketPilotDiameter)} · ${s.pocketShoulder} ${unit.format(h.depth!)}'
              : h.depth == null
              ? s.throughHole
              : '${s.rabbetDepth} ${unit.format(h.depth!)}'}',
  ].join('\n');
}

/// Column names match the Russian BAZIS cutting-job import dialog. Cutting
/// sizes are always millimetres and each project position gets its own row.
Uint8List encodeBazisCutList(List<StockRow> rows) {
  final book = Excel.createExcel();
  book.rename(book.getDefaultSheet()!, 'Панели');
  final sheet = book['Панели'];
  const columns = [
    'Позиция',
    'Наименование',
    'Материал',
    'Толщина',
    'Длина',
    'Ширина',
    'Кол-во',
  ];
  sheet.appendRow(columns.map(TextCellValue.new).toList());
  for (final row in rows) {
    for (final b in row.parts) {
      final preset = FinishPreset.values
          .where((p) => p.finish == b.finish)
          .firstOrNull;
      final material =
          preset?.label ?? '${b.finish.texture.name} ${hexColor(b.finish.rgb)}';
      sheet.appendRow([
        IntCellValue(b.id),
        TextCellValue(b.name),
        TextCellValue(material),
        DoubleCellValue(b.size.z),
        DoubleCellValue(blankLength(b)),
        DoubleCellValue(b.size.y),
        IntCellValue(1),
      ]);
    }
  }
  sheet.setColumnWidth(1, 38);
  sheet.setColumnWidth(2, 28);
  return Uint8List.fromList(book.encode()!);
}

Uint8List encodePartsWorkbook(LengthUnit unit, List<StockRow> rows) {
  final book = Excel.createExcel();
  book.rename(book.getDefaultSheet()!, editorStrings.stock);
  final summary = book[editorStrings.stock],
      details = book[editorStrings.partsLabel];
  final hasBanding = rows.any((r) => r.sample.banding.edges.isNotEmpty);
  final hasCuts = rows.any((r) => r.sample.bevelled);
  final hasRabbets = rows.any((r) => r.sample.rabbets.isNotEmpty);
  final hasHoles = rows.any((r) => r.sample.drillingCount > 0);
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
      if (hasBanding) (editorStrings.edgeBanding, 54.0),
      if (hasCuts) ...[
        (editorStrings.startCut, 30.0),
        (editorStrings.endCut, 30.0),
      ],
      if (hasRabbets) (editorStrings.rabbetTitle, 46.0),
      if (hasHoles) ('${editorStrings.panelHoles} (${unit.symbol})', 64.0),
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
      if (hasBanding) TextCellValue(stockBanding(part, unit)),
      if (hasCuts) ...[
        TextCellValue(stockCut(part, false)),
        TextCellValue(stockCut(part, true)),
      ],
      if (hasRabbets) TextCellValue(stockRabbets(part, unit)),
      if (hasHoles) TextCellValue(stockHoles(part, unit)),
    ]);
    final drillings = part.drillingCount;
    final lines = part.rabbets.length > drillings
        ? part.rabbets.length
        : drillings;
    if (lines > 1) {
      sheet.setRowHeight(rowIndex, 16.0 * lines);
      for (final column in [
        if (part.rabbets.length > 1) sheet.maxColumns - (hasHoles ? 2 : 1),
        if (drillings > 1) sheet.maxColumns - 1,
      ]) {
        sheet
                .cell(
                  CellIndex.indexByColumnRow(
                    columnIndex: column,
                    rowIndex: rowIndex,
                  ),
                )
                .cellStyle =
            profileStyle;
      }
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
