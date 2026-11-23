import 'package:flutter/foundation.dart';

import 'model.dart';
import 'hotkeys.dart';
import 'scene.dart';
import 'step.dart';
import 'stock_sketch.dart';
import 'contact.dart';
import 'positioning.dart';

enum Tool { select, move, beam, measure, face, rotate, align, gap }

class Editor extends ChangeNotifier {
  Project project;
  EditStep step = EditStep();
  EditorHotkeys hotkeys = EditorHotkeys();
  void Function(Project)? onDocumentChange;
  Set<int> selection = {};
  final List<Project> _past = [], _future = [];
  Camera camera = Camera();
  final _viewCameras = <ViewAngle, (Camera, WorkPlane)>{};
  ViewAngle get activeView =>
      view ?? (camera.perspective ? ViewAngle.perspective : ViewAngle.iso);
  WorkPlane plane = WorkPlane.xy();
  Tool tool = Tool.select;
  ViewAngle? view = ViewAngle.iso;
  bool snap = true, magneticResize = true;
  bool snapByDefault = true;
  bool dimensionsByDefault = true;
  bool dimensionTabHeld = false;
  bool get dimensionsVisible => dimensionsByDefault != dimensionTabHeld;

  void holdDimensionTab(bool held) {
    if (dimensionTabHeld == held) return;
    dimensionTabHeld = held;
    refresh();
  }

  (Vector3, Vector3)? guide;
  SnapMode snapMode = SnapMode.auto;
  int resizeAxis = 0, rotationAxis = 2;
  int? hoveredSize, focusedSize;
  int? get highlightedSize => hoveredSize ?? focusedSize;
  void markSize(int axis, bool active, {bool focus = false}) {
    final old = focus ? focusedSize : hoveredSize;
    if (!active && old != axis) return;
    final next = active ? axis : null;
    if (next == old) return;
    if (focus) {
      focusedSize = next;
    } else {
      hoveredSize = next;
    }
    refresh();
  }

  bool localRotation = false;
  List<Vector3> get rotationBasis {
    final part = single;
    return localRotation && part != null
        ? [part.along, part.across, part.up]
        : [axis(0), axis(1), axis(2)];
  }

  double angle = 0;
  void setAngle(double next) {
    angle = next % 360;
    if (angle.abs() < 1e-8 || (360 - angle).abs() < 1e-8) angle = 0;
    refresh();
  }

  void chooseRotationAxis(int next) {
    rotationAxis = next;
    angle = 0;
    ensureVisibleRotationPlane();
    refresh();
  }

  void ensureVisibleRotationPlane() {
    final n = rotationBasis[rotationAxis];
    if (n.dot(camera.eye).abs() < .20) {
      final u = rotationBasis[(rotationAxis + 1) % 3];
      camera.facePlane(WorkPlane('', Vector3.zero(), u, n.cross(u)));
      view = null;
    }
  }

  int? referenceId;
  StockAlignment alignment = StockAlignment.middle;
  StockAlignment? hoverAlignment;
  bool overAlignmentPanel = false;
  bool hasPlacementChoice = false;
  Project? _suggestedProject;
  int? _suggestedFor;
  StockPlacement? _suggested;
  bool _useThickness(Beam part) {
    final verticality = part.up.z.abs() - part.across.z.abs();
    return verticality.abs() < .00001
        ? part.size.z < part.size.y
        : verticality < 0;
  }

  StockPlacement? get suggestedPlacement {
    final part = single;
    if (part == null) return null;
    if (!identical(_suggestedProject, project) || _suggestedFor != part.id) {
      _suggestedProject = project;
      _suggestedFor = part.id;
      final ref = adjacentSupport(project, part);
      _suggested = ref == null
          ? null
          : StockPlacement(part, ref, _useThickness(part));
    }
    return _suggested;
  }

  StockAlignment? get visibleAlignment =>
      hoverAlignment ??
      (tool == Tool.align && hasPlacementChoice ? alignment : null);
  StockPlacement? get alignmentPlacement => tool == Tool.align
      ? placement
      : tool == Tool.select
      ? suggestedPlacement
      : null;
  StockPlacement? get previewPlacement =>
      visibleAlignment == null ? null : alignmentPlacement;
  Beam? get alignmentSupport {
    if (tool == Tool.align && referenceId == null) return faceHover?.beam;
    return tool == Tool.align || overAlignmentPanel || visibleAlignment != null
        ? alignmentPlacement?.reference
        : null;
  }

  void showAlignmentSupport(bool over) {
    if (overAlignmentPanel == over) return;
    overAlignmentPanel = over;
    refresh();
  }

  void hoverPlacement(StockAlignment option, bool over) {
    if (!over && hoverAlignment != option) return;
    final next = over ? option : null;
    if (hoverAlignment == next) return;
    hoverAlignment = next;
    refresh();
  }

  void chooseAlignment(StockAlignment option, {double? offset}) {
    if (tool != Tool.align) {
      final initial = suggestedPlacement;
      if (initial == null) return;
      chooseSupport(
        initial.reference.id,
        alongThickness: initial.alongThickness,
      );
    }
    if (placement == null) return;
    hoverAlignment = null;
    hasPlacementChoice = true;
    alignment = option;
    if (offset != null) manualOffset = offset;
    refresh();
  }

  bool alignThickness = false;
  double manualOffset = 0;
  StockPlacement? get placement {
    final part = single, ref = project.byId[referenceId];
    return part == null || ref == null || ref.id == part.id
        ? null
        : StockPlacement(part, ref, alignThickness);
  }

  void beginAlignment() {
    final part = single;
    if (part == null) return;
    if (project.beams.length < 2) {
      message = 'Добавьте вторую деталь для выравнивания';
      refresh();
      return;
    }
    resetTransient();
    referenceId = null;
    alignThickness = _useThickness(part);
    alignment = StockAlignment.offset;
    tool = Tool.align;
    refresh();
  }

  void chooseSupport(int id, {bool? alongThickness}) {
    if (project.byId[id] == null || single == null || id == single!.id) return;
    if (tool != Tool.align) beginAlignment();
    if (alongThickness != null) alignThickness = alongThickness;
    referenceId = id;
    hoverAlignment = null;
    hasPlacementChoice = false;
    alignment = StockAlignment.offset;
    manualOffset = placement!.current;
    faceHover = null;
    refresh();
  }

  double get alignmentDelta {
    final p = placement;
    return p == null ? 0 : p.offset(alignment, manualOffset) - p.current;
  }

  Project get displayed {
    if (tool == Tool.rotate && selection.isNotEmpty) {
      return project.rotate(selection, rotationBasis[rotationAxis], angle);
    }
    final p = tool == Tool.align ? placement : null;
    if (p != null && alignmentDelta.abs() > 1e-7) {
      return project.edit(selection, (_) => p.placed(alignment, manualOffset));
    }
    return project;
  }

  void applyAlignment() {
    if (tool != Tool.align ||
        !hasPlacementChoice ||
        placement == null ||
        alignmentDelta.abs() < 1e-7) {
      return;
    }
    final result = displayed;
    final p = placement!;
    _suggestedFor = p.part.id;
    _suggestedProject = result;
    _suggested = StockPlacement(
      result.byId[p.part.id]!,
      p.reference,
      alignThickness,
    );
    tool = Tool.select;
    resetTransient();
    commit(result);
  }

  void shift(int screenAxis, int sign, {required bool untilStop}) {
    if (selection.isEmpty || tool != Tool.select) return;
    final screenDirection = screenAxis == 0 ? camera.right : camera.up;
    var dim = 0;
    if (screenAxis == 1 && camera.pitch.abs() < 1.3) {
      dim = 2;
    } else {
      for (var i = 1; i < 3; i++) {
        if (screenDirection[i].abs() > screenDirection[dim].abs()) dim = i;
      }
    }
    final direction =
        axis(dim) *
        (screenDirection[dim] >= 0 ? sign.toDouble() : -sign.toDouble());
    var travel = step.enabled
        ? step.millimeters(project.unit)
        : 1 / camera.scale;
    if (untilStop) {
      final stop = travelToStop(project, selection, direction);
      if (stop == null) {
        message = 'В этом направлении нет упора';
        refresh();
        return;
      }
      travel = stop.travel;
      message = 'Упор · ${project.byId[stop.obstacle]!.name}';
    } else {
      message = 'Сдвиг · ${project.unit.format(travel)} ${project.unit.symbol}';
    }
    if (travel < 1e-7) {
      refresh();
      return;
    }
    commit(project.move(selection, direction * travel));
  }

  void applyRotation() {
    if (selection.isEmpty) return;
    final next = displayed;
    tool = Tool.select;
    resetTransient();
    commit(next);
  }

  int? firstShelf;
  Dimension? gapPreview;
  Anchor? first, hover;
  StockSketch? sketch;
  SceneFace? faceHover;
  Beam? preview;
  String message = '';
  bool fitRequested = true;
  Project? _checked;
  Set<int> _overlaps = {};
  Set<int> get overlaps {
    if (!identical(_checked, project)) {
      _overlaps = project.overlaps;
      _checked = project;
    }
    return _overlaps;
  }

  Editor(this.project);
  bool get canUndo => _past.isNotEmpty;
  bool get canRedo => _future.isNotEmpty;
  List<Beam> get selected =>
      project.beams.where((b) => selection.contains(b.id)).toList();
  Beam? get single =>
      selection.length == 1 ? project.byId[selection.first] : null;
  void refresh() => notifyListeners();
  void _updateWorkspaceView(Project next) {
    if (project.workspaceSize == next.workspaceSize) return;
    _viewCameras.clear();
    fitRequested = true;
  }

  void commit(Project next, {Project? before}) {
    final old = before ?? project;
    if (identical(old, next)) return;
    _past.add(old);
    if (_past.length > 100) _past.removeAt(0);
    _future.clear();
    _updateWorkspaceView(next);
    project = next;
    onDocumentChange?.call(project);
    _prune();
    notifyListeners();
  }

  void _prune() {
    selection = selection.where(project.byId.containsKey).toSet();
  }

  void resetTransient() {
    overAlignmentPanel = false;
    hoverAlignment = null;
    hasPlacementChoice = false;
    hoveredSize = focusedSize = null;
    sketch = null;
    guide = null;
    firstShelf = null;
    gapPreview = null;
    first = null;
    hover = null;
    preview = null;
    faceHover = null;
    message = '';
  }

  void undo() {
    if (!canUndo) return;
    _future.add(project);
    _updateWorkspaceView(_past.last);
    project = _past.removeLast();
    resetTransient();
    _prune();
    onDocumentChange?.call(project);
    notifyListeners();
  }

  void redo() {
    if (!canRedo) return;
    _past.add(project);
    _updateWorkspaceView(_future.last);
    project = _future.removeLast();
    resetTransient();
    _prune();
    onDocumentChange?.call(project);
    notifyListeners();
  }

  void load(Project next) {
    _viewCameras.clear();
    _past.clear();
    _future.clear();
    project = next;
    selection = {};
    resetTransient();
    tool = Tool.select;
    plane = WorkPlane.xy();
    view = ViewAngle.iso;
    camera.view(view!);
    fitRequested = true;
    onDocumentChange?.call(project);
    notifyListeners();
  }

  void select(int? id, {bool multi = false, bool individual = false}) {
    resetTransient();
    if (id == null) {
      selection = {};
    } else {
      final target = individual ? {id} : project.assembly(id);
      if (multi) {
        selection = selection.containsAll(target)
            ? (selection.difference(target))
            : {...selection, ...target};
      } else {
        selection = target;
      }
    }
    notifyListeners();
  }

  void setTool(Tool next) {
    resetTransient();
    tool = next;
    if (next == Tool.rotate) {
      angle = 0;
      ensureVisibleRotationPlane();
    }
    notifyListeners();
  }

  void setPlane(WorkPlane next) {
    resetTransient();
    plane = next;
    if (next.normal.dot(camera.eye).abs() < .025) {
      camera.facePlane(next);
      view = null;
    }
    if (tool == Tool.face) tool = Tool.select;
    notifyListeners();
  }

  void setView(ViewAngle next) {
    if (next == view) return;
    if (!fitRequested) _viewCameras[activeView] = (camera.copy(), plane);
    resetTransient();
    view = next;
    if (_viewCameras[next] case final saved?) {
      camera = saved.$1.copy();
      plane = saved.$2;
      fitRequested = false;
      notifyListeners();
      return;
    }
    camera.view(next);
    plane = switch (next) {
      ViewAngle.front || ViewAngle.back => WorkPlane.xz(),
      ViewAngle.left || ViewAngle.right => WorkPlane.yz(),
      _ => WorkPlane.xy(),
    };
    fitRequested = true;
    notifyListeners();
  }

  bool get canGroup {
    if (selection.length < 2) return false;
    final group = project.byId[selection.first]!.group;
    return group == null ||
        selection.any((id) => project.byId[id]!.group != group);
  }

  bool get canUngroup => selection.any((id) => project.byId[id]?.group != null);

  void group() {
    if (!canGroup) return;
    final all = {for (final id in selection) ...project.assembly(id)};
    final group = project.nextGroup;
    selection = all;
    commit(project.edit(all, (b) => b.copy(group: group)));
  }

  void ungroup() {
    if (!canUngroup) return;
    final all = {for (final id in selection) ...project.assembly(id)};
    commit(project.edit(all, (b) => b.copy(ungroup: true)));
  }

  void delete() {
    if (selection.isNotEmpty) {
      resetTransient();
      commit(project.remove(selection));
    }
  }

  void duplicate() {
    if (selection.isEmpty) return;
    var next = project.nextId, nextGroup = project.nextGroup;
    final groups = <int, int>{};
    final copies = selected
        .map(
          (b) => b.copy(
            id: next++,
            origin: b.origin + plane.u * 50 + plane.v * 50,
            group: b.group == null
                ? null
                : groups.putIfAbsent(b.group!, () => nextGroup++),
          ),
        )
        .toList();
    selection = copies.map((b) => b.id).toSet();
    commit(project.copy(beams: [...project.beams, ...copies]));
  }

  void extend(bool positive) {
    final b = single;
    if (b == null) return;
    if (b.locked(resizeAxis)) {
      message = 'Размер заблокирован';
      notifyListeners();
      return;
    }
    final hit = firstContact(b, resizeAxis, positive, project.beams);
    if (hit == null) {
      message = 'В этом направлении нет упора';
      notifyListeners();
      return;
    }
    message = 'Упор · ${project.byId[hit.obstacle]!.name}';
    if (hit.travel < 1e-6) {
      notifyListeners();
      return;
    }
    commit(
      project.edit(
        selection,
        (b) => resizeEnd(b, resizeAxis, positive, hit.travel, stop: hit),
      ),
    );
  }
}
