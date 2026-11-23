import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';

import 'model.dart';
import 'parts_workbook.dart';

const projectType = XTypeGroup(
  label: 'Проект neprosto',
  extensions: ['neprosto'],
);
Future<Project?> openProject() async {
  final file = await openFile(
    acceptedTypeGroups: [
      projectType,
      const XTypeGroup(label: 'Черновики Брус', extensions: ['brus']),
    ],
    confirmButtonText: 'Открыть',
  );
  return file == null ? null : Project.decode(await file.readAsString());
}

String _fileStem(Project p) => p.name.replaceAll(RegExp(r'[/\\:]'), '_');

Future<bool> saveProject(Project p) => _saveFile(
  '${_fileStem(p)}.neprosto',
  projectType,
  'application/json',
  () => utf8.encode(p.encode()),
);

Future<bool> savePartsWorkbook(Project p, List<StockRow> rows) => _saveFile(
  '${_fileStem(p)} — список деталей.xlsx',
  const XTypeGroup(label: 'Книга Excel', extensions: ['xlsx']),
  'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  () => encodePartsWorkbook(p.unit, rows),
);

Future<bool> _saveFile(
  String name,
  XTypeGroup type,
  String mimeType,
  Uint8List Function() encode,
) async {
  final location = kIsWeb
      ? null
      : await getSaveLocation(
          suggestedName: name,
          acceptedTypeGroups: [type],
          confirmButtonText: 'Сохранить',
        );
  if (!kIsWeb && location == null) return false;
  await XFile.fromData(
    encode(),
    name: name,
    mimeType: mimeType,
  ).saveTo(location?.path ?? name);
  return true;
}
