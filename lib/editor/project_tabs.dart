import '../l10n/strings.dart';

import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'controller.dart';
import 'model.dart';
import 'storage.dart';

class RecentProject {
  RecentProject.linked(this.name, ProjectFile link)
    : file = link,
      id = link.path,
      snapshot = null;
  RecentProject.local(this.id, Project project)
    : file = null,
      name = project.name,
      snapshot = project;

  final String id, name;
  final ProjectFile? file;
  final Project? snapshot;

  Map<String, Object?> toJson() => file != null
      ? {'name': name, 'file': file!.toJson()}
      : {'id': id, 'project': snapshot!.toJson()};

  factory RecentProject.fromJson(Map data) => data['file'] == null
      ? RecentProject.local(
          data['id'] as String,
          Project.fromJson(data['project']),
        )
      : RecentProject.linked(
          data['name'] as String,
          ProjectFile.fromJson(data['file']),
        );
}

class ProjectTab {
  ProjectTab(this.editor, {this.file, this.recentId, bool dirty = false})
    : saved = dirty ? null : editor.project,
      committed = editor.project,
      draft = editor.project {
    editor.onDocumentChange = (project) => committed = project;
  }

  final Editor editor;
  ProjectFile? file;
  String? recentId;
  String? get documentId => file?.path ?? recentId;
  Project? saved;
  Project committed;
  Project draft;
  bool get dirty => !identical(committed, saved);

  Map<String, Object?> toJson() => {
    'project': draft.toJson(),
    'dirty': !identical(draft, saved),
    if (file != null) 'file': file!.toJson(),
    if (file == null && recentId != null) 'recentId': recentId,
  };

  factory ProjectTab.fromJson(Map<String, dynamic> data) => ProjectTab(
    Editor(Project.fromJson(data['project'])),
    dirty: data['dirty'] == true,
    file: data['file'] == null ? null : ProjectFile.fromJson(data['file']),
    recentId: data['recentId'] as String?,
  );
}

class ProjectTabs extends ValueNotifier<ProjectTab> {
  ProjectTabs._(this.items, int index) : super(items[index]);
  factory ProjectTabs(Editor editor, {bool dirty = false}) =>
      ProjectTabs._([ProjectTab(editor, dirty: dirty)], 0);

  final List<ProjectTab> items;
  static const storageKey = 'project-tabs-v1';
  static const recentKey = 'recent-projects-v1';
  static const recentLimit = 10;
  List<RecentProject> recent = const [];

  void restoreRecent(String? source) {
    if (source != null) {
      recent = [
        for (final data in (jsonDecode(source) as List).take(recentLimit))
          RecentProject.fromJson(data),
      ];
      return;
    }
    // Seed the history from file links in sessions saved before it existed.
    for (final tab in [...items.where((tab) => tab != value), value]) {
      if (tab.file case final file?) {
        remember(RecentProject.linked(tab.committed.name, file));
      }
    }
  }

  void remember(RecentProject entry, {String? previousId}) {
    recent = [
      entry,
      ...recent
          .where((item) => item.id != entry.id && item.id != previousId)
          .take(recentLimit - 1),
    ];
  }

  void refreshRecentFile(
    ProjectFile previous,
    ProjectFile output,
    String name,
  ) {
    final index = recent.indexWhere((entry) => entry.id == previous.path);
    if (index < 0) return;
    recent = List.of(recent)..[index] = RecentProject.linked(name, output);
  }

  RecentProject savedDocument(ProjectTab tab, Project project) {
    if (tab.file case final file?) {
      return RecentProject.linked(project.name, file);
    }
    final id = tab.recentId ??=
        'local-${DateTime.now().microsecondsSinceEpoch}';
    return RecentProject.local(id, project);
  }

  ProjectTab? forDocument(String id) =>
      items.where((tab) => tab.documentId == id).firstOrNull;

  void openDocument(Project project, {ProjectFile? source, String? recentId}) {
    final id = source?.path ?? recentId;
    final existing = id == null ? null : forDocument(id);
    if (existing == null) {
      final writable = source?.path.toLowerCase().endsWith('.neprosto') == true;
      open(
        project,
        file: writable ? source : null,
        recentId: writable ? null : id,
      );
    } else {
      select(existing);
    }
    remember(
      source != null
          ? RecentProject.linked(project.name, source)
          : savedDocument(value, project),
      previousId: recentId,
    );
  }

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
      ..step = previous.step
      ..displayUnit = previous.displayUnit;
    value = tab;
  }

  void open(
    Project project, {
    ProjectFile? file,
    String? recentId,
    bool dirty = false,
  }) {
    final tab = ProjectTab(
      Editor(project),
      file: file,
      recentId: recentId,
      dirty: dirty,
    );
    items.add(tab);
    select(tab);
  }

  void create({Project? template, LengthUnit? unit}) {
    final names = items.map((tab) => tab.committed.name).toSet();
    var name = template?.name ?? editorStrings.untitled;
    for (var n = 2; names.contains(name); n++) {
      name = template == null
          ? editorStrings.numberedUntitled(n)
          : '${template.name} $n';
    }
    final project =
        template?.copy(name: name) ??
        Project(name, [], const [], unit ?? value.editor.displayUnit);
    open(project.withDefaultWorkspace(), dirty: template != null);
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
