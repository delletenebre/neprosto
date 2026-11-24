import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:neprosto/l10n/app_localizations.dart';
import 'package:neprosto/l10n/strings.dart';
import 'package:neprosto/editor/model.dart';
import 'package:neprosto/editor/parts_workbook.dart';

num number(Data? cell) => switch (cell?.value) {
  IntCellValue(:final value) => value,
  DoubleCellValue(:final value) => value,
  _ => throw StateError('Expected a numeric Excel cell'),
};

void main() {
  test(
    'Excel omits trailing zeros and keeps numeric dimensions on both sheets',
    () {
      final part = Beam(
        1,
        'Полка',
        Vector3.zero(),
        Vector3(1195.04, 15.50, 12.001),
        axis(0),
        axis(1),
      );
      final book = Excel.decodeBytes(
        encodePartsWorkbook(LengthUnit.millimeter, [
          StockRow([part]),
        ]),
      );
      for (final sheet in book.tables.values) {
        final sizes = sheet.rows[1].sublist(1, 4);
        expect(sizes.map(number), [1195.04, 15.5, 12.001]);
        expect(sizes.map((c) => c!.cellStyle!.numberFormat.formatCode), [
          '0.0#',
          '0.0#',
          '0',
        ]);
      }
    },
  );

  test(
    'Excel preserves grouped counts, individual names, units and bevels',
    () {
      final board = Beam(
        1,
        'Полка 1',
        Vector3.zero(),
        Vector3(600, 80, 15),
        axis(0),
        axis(1),
      );
      final second = board.copy(id: 2, name: 'Полка 2');
      final bevel = board.copy(
        id: 3,
        name: '=A1 & <торец>',
        startCut: (y: 40, z: 0),
      );
      final rows = [
        StockRow([bevel]),
        StockRow([board, second]),
      ];
      final initialStrings = editorStrings;
      addTearDown(() => editorStrings = initialStrings);
      for (final (locale, stock, parts, header, widthMark) in [
        ('ru', 'Заготовки', 'Детали', 'Длина заготовки', '+Ш'),
        ('en', 'Stock', 'Parts', 'Stock length', '+W'),
        ('ky', 'Даярдамалар', 'Тетиктер', 'Даярдаманын узундугу', '+Т'),
      ]) {
        editorStrings = lookupAppLocalizations(Locale(locale));
        for (final unit in LengthUnit.values) {
          final book = Excel.decodeBytes(encodePartsWorkbook(unit, rows));
          expect(book.tables.keys, orderedEquals([stock, parts]));
          final summary = book[stock].rows, details = book[parts].rows;
          expect(summary, hasLength(3));
          expect(details, hasLength(4));
          expect(summary.first[1]!.value.toString(), '$header, ${unit.symbol}');
          expect(summary[2][0]!.value.toString(), 'Полка');
          expect(summary[2][4]!.value, const IntCellValue(2));
          expect(number(summary[1][1]), closeTo(620 / unit.factor, 1e-9));
          expect(summary[1][5]!.value.toString(), '26.57° $widthMark');
          expect(summary[1][6]!.value.toString(), '0°');
          expect(details[1][0]!.value, TextCellValue(bevel.name));
          expect(details.skip(2).map((r) => r[0]!.value.toString()), [
            'Полка 1',
            'Полка 2',
          ]);
          expect(number(details[2][3]), closeTo(15 / unit.factor, 1e-9));
        }
      }
    },
  );
}
