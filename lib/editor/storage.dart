import '../l10n/strings.dart';

import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'model.dart';
import 'parts_workbook.dart';

XTypeGroup get projectType =>
    XTypeGroup(label: editorStrings.neprostoProject, extensions: ['neprosto']);
const _files = MethodChannel('neprosto/project-files');
bool get _mac => !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

/// A desktop document chosen by the user. AppKit bookmarks retain sandbox access.
class ProjectFile {
  const ProjectFile(this.path, {this.bookmark, this.modified});
  final String path;
  final String? bookmark;
  final double? modified;

  Map<String, Object?> toJson() => {
    'path': path,
    if (bookmark != null) 'bookmark': bookmark,
    if (modified != null) 'modified': modified,
  };

  factory ProjectFile.fromJson(Map data) => ProjectFile(
    data['path'] as String,
    bookmark: data['bookmark'] as String?,
    modified: (data['modified'] as num?)?.toDouble(),
  );
}

Future<({Project project, ProjectFile? file})?> openProject() async {
  final input = await openFile(
    acceptedTypeGroups: [
      projectType,
      XTypeGroup(label: editorStrings.brusDrafts, extensions: ['brus']),
    ],
    confirmButtonText: editorStrings.open,
  );
  if (input == null) return null;
  if (!kIsWeb) return readProjectFile(ProjectFile(input.path));
  return (project: Project.decode(await input.readAsString()), file: null);
}

Future<({Project project, ProjectFile file})> readProjectFile(
  ProjectFile file,
) async {
  if (_mac) {
    final data = (await _files.invokeMapMethod('read', file.toJson()))!;
    return (
      project: Project.decode(utf8.decode(data['bytes'] as Uint8List)),
      file: ProjectFile.fromJson(data),
    );
  }
  return (
    project: Project.decode(await XFile(file.path).readAsString()),
    file: file,
  );
}

String _fileStem(Project p) {
  final stem = p.name
      .trim()
      .replaceAll(RegExp(r'[/\\:]'), '_')
      .replaceFirst(RegExp(r'(\.neprosto)+$', caseSensitive: false), '');
  return stem.isEmpty ? editorStrings.untitled : stem;
}

Future<FileSaveLocation?> _choose(String stem, XTypeGroup type) =>
    getSaveLocation(
      // NSSavePanel supplies the extension from its allowed content type.
      suggestedName: _mac ? stem : '$stem.${type.extensions!.single}',
      acceptedTypeGroups: [type],
      confirmButtonText: editorStrings.save,
    );

Future<ProjectFile?> chooseProjectFile(Project project) async {
  final stem = _fileStem(project);
  if (kIsWeb) return ProjectFile('$stem.neprosto');
  final location = await _choose(stem, projectType);
  return location == null ? null : ProjectFile(location.path);
}

Future<ProjectFile> writeProject(Project project, ProjectFile file) async {
  final bytes = utf8.encode(project.encode());
  if (_mac) {
    final result = await _files.invokeMapMethod('write', {
      ...file.toJson(),
      'bytes': bytes,
    });
    return ProjectFile.fromJson(result!);
  }
  await XFile.fromData(
    bytes,
    name: file.path,
    mimeType: 'application/json',
  ).saveTo(file.path);
  return file;
}

Future<bool> savePartsWorkbook(
  Project p,
  List<StockRow> rows, {
  bool bazis = false,
}) async {
  final stem = bazis
      ? '${_fileStem(p)} - BAZIS'
      : editorStrings.partsFilename(_fileStem(p));
  final name = '$stem.xlsx';
  final location = kIsWeb
      ? null
      : await _choose(
          stem,
          XTypeGroup(label: editorStrings.excelWorkbook, extensions: ['xlsx']),
        );
  if (!kIsWeb && location == null) return false;
  await XFile.fromData(
    bazis ? encodeBazisCutList(rows) : encodePartsWorkbook(p.unit, rows),
    name: name,
    mimeType:
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  ).saveTo(location?.path ?? name);
  return true;
}
