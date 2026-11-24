import '../l10n/strings.dart';

import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'controller.dart';
import 'model.dart';
import 'storage.dart';

class ProjectTab {
  ProjectTab(this.editor, {this.file, bool dirty = false})
    : saved = dirty ? null : editor.project,
      committed = editor.project,
      draft = editor.project {
    editor.onDocumentChange = (project) => committed = project;
  }

  final Editor editor;
  ProjectFile? file;
  Project? saved;
  Project committed;
  Project draft;
  bool get dirty => !identical(committed, saved);

  Map<String, Object?> toJson() => {
    'project': draft.toJson(),
    'dirty': !identical(draft, saved),
    if (file != null) 'file': file!.toJson(),
  };

  factory ProjectTab.fromJson(Map<String, dynamic> data) => ProjectTab(
    Editor(Project.fromJson(data['project'])),
    dirty: data['dirty'] == true,
    file: data['file'] == null ? null : ProjectFile.fromJson(data['file']),
  );
}

class ProjectTabs extends ValueNotifier<ProjectTab> {
  ProjectTabs._(this.items, int index) : super(items[index]);
  factory ProjectTabs(Editor editor, {bool dirty = false}) =>
      ProjectTabs._([ProjectTab(editor, dirty: dirty)], 0);

  final List<ProjectTab> items;
  static const storageKey = 'project-tabs-v1';

  String encode() => jsonEncode({
    'active': items.indexOf(value),
    'tabs': [for (final tab in items) tab.toJson()],
  });

  factory ProjectTabs.decode(String source) {
    final data = jsonDecode(source);
    final tabs = [
      for (final tab in data['tabs'] as List) ProjectTab.fromJson(tab),
    ];
    if (tabs.isEmpty) throw FormatException(editorStrings.noOpenProjects);
    return ProjectTabs._(
      tabs,
      (data['active'] as int).clamp(0, tabs.length - 1),
    );
  }

  ProjectTab? forFile(ProjectFile file) =>
      items.where((tab) => tab.file?.path == file.path).firstOrNull;

  void select(ProjectTab tab) {
    if (tab == value) return;
    final previous = value.editor;
    previous.releaseModifiers();
    tab.editor
      ..snapByDefault = previous.snapByDefault
      ..dimensionsByDefault = previous.dimensionsByDefault
      ..showHiddenOutlines = previous.showHiddenOutlines
      ..gridVisibility = previous.gridVisibility
      ..hotkeys = previous.hotkeys
      ..step = previous.step;
    value = tab;
  }

  void open(Project project, {ProjectFile? file, bool dirty = false}) {
    final tab = ProjectTab(Editor(project), file: file, dirty: dirty);
    items.add(tab);
    select(tab);
  }

  void create({Project? template, LengthUnit unit = LengthUnit.millimeter}) {
    final names = items.map((tab) => tab.committed.name).toSet();
    var name = template?.name ?? editorStrings.untitled;
    for (var n = 2; names.contains(name); n++) {
      name = template == null
          ? editorStrings.numberedUntitled(n)
          : '${template.name} $n';
    }
    open(
      template?.copy(name: name) ?? Project(name, [], const [], unit),
      dirty: template != null,
    );
  }

  void close(ProjectTab tab) {
    final index = items.indexOf(tab);
    if (index < 0) return;
    final closed = items.removeAt(index);
    closed.editor.onDocumentChange = null;
    if (tab != value) {
      notifyListeners();
    } else if (items.isEmpty) {
      create();
    } else {
      select(items[index.clamp(0, items.length - 1)]);
    }
  }
}
