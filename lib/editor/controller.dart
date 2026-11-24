import '../l10n/strings.dart';

import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';

import 'model.dart';
import 'grid_visibility.dart';
import 'hotkeys.dart';
import 'scene.dart';
import 'step.dart';
import 'stock_sketch.dart';
import 'contact.dart';
import 'positioning.dart';

enum Tool { select, move, beam, ruler, measure, face, rotate, align, gap }

class Editor extends ChangeNotifier {
  Project project;
  EditStep step = EditStep();
  EditorHotkeys hotkeys = EditorHotkeys();
  void Function(Project)? onDocumentChange;
  Set<int> selection = {};
  final List<Project> _past = [], _future = [];
  Camera camera = Camera();
  final _viewCameras = <ViewAngle, (Camera, WorkPlane)>{};
  ViewAngle selectedView = ViewAngle.iso;
  bool _freeView = false;
  ViewAngle? get activeView => _freeView ? null : selectedView;

  GridVisibility gridVisibility = const GridVisibility();
  WorkPlane plane = WorkPlane.xy();
  Tool tool = Tool.select;
  bool snap = true;
  bool snapByDefault = true;
  bool dimensionsByDefault = true;
  bool showHiddenOutlines = false;
  Project get framedProject =>
      showHiddenOutlines ? project : project.visibleGeometry;
  bool dimensionTabHeld = false;
  bool get rulerActive =>
      tool == Tool.ruler || tool == Tool.measure || tool == Tool.gap;
  bool get dimensionsVisible =>
      rulerActive || dimensionsByDefault != dimensionTabHeld;

  void holdDimensionTab(bool held) {
    if (dimensionTabHeld == held) return;
    dimensionTabHeld = held;
    refresh();
  }

  SnapMode snapMode = SnapMode.auto;
  int rotationAxis = 2;
  int? hoveredSize, focusedSize;
  int? _focusedPositionAxis;
  void focusPositionAxis(int dim, bool focused) {
    if (!focused && _focusedPositionAxis != dim) return;
    final next = focused ? dim : null;
    if (_focusedPositionAxis == next) return;
    _focusedPositionAxis = next;
    refresh();
  }

  ({int axis, Vector3 origin})? get positionGuide {
    final dim = _focusedPositionAxis;
    if (dim == null || selection.isEmpty) return null;
    final origin =
        single?.origin ?? Bounds3.points(selected.expand((b) => b.corners)).low;
    return (axis: dim, origin: origin);
  }

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
  // The preview needs a continuous target when a step crosses 0°.
  int _fullTurns = 0;
  double get rotationDegrees => angle + 360 * _fullTurns;

  void setAngle(double next) {
    final previous = angle;
    angle = next % 360;
    if (angle.abs() < 1e-8 || (360 - angle).abs() < 1e-8) angle = 0;
    final delta = angle - previous;
    if (delta > 180 || (delta == 180 && next < previous)) {
      _fullTurns--;
    } else if (delta < -180 || (delta == -180 && next > previous)) {
      _fullTurns++;
    }
    refresh();
  }

  void chooseRotationAxis(int next) {
    rotationAxis = next;
    angle = 0;
    _fullTurns = 0;
    ensureVisibleRotationPlane();
    refresh();
  }

  void ensureVisibleRotationPlane() {
    final n = rotationBasis[rotationAxis];
    if (n.dot(camera.eye).abs() < .20) {
      final u = rotationBasis[(rotationAxis + 1) % 3];
      _rememberView();
      camera.facePlane(WorkPlane('', Vector3.zero(), u, n.cross(u)));
      _freeView = true;
    }
  }

  int? referenceId;
  StockAlignment alignment = StockAlignment.middle;
  StockAlignment? hoverAlignment;
  bool _referencePickHeld = false;
  bool get pickingAlignmentSupport =>
      tool == Tool.align && (_referencePickHeld || referenceId == null);

  void holdReferencePick(bool held) {
    if (tool != Tool.align || _referencePickHeld == held) return;
    _referencePickHeld = held;
    faceHover = null;
    refresh();
  }

  void releaseModifiers() {
    holdReferencePick(false);
    holdDimensionTab(false);
  }

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
      final ref = adjacentSupport(project.visibleGeometry, part);
      _suggested = ref == null
          ? null
          : StockPlacement(part, ref, _useThickness(part));
    }
    return _suggested;
  }

  StockAlignment? get visibleAlignment =>
      hoverAlignment ?? (hasPlacementChoice ? alignment : null);
  StockPlacement? get previewPlacement =>
      pickingAlignmentSupport || visibleAlignment == null ? null : placement;
  Beam? get alignmentSupport {
    if (tool != Tool.align) return null;
    if (pickingAlignmentSupport) {
      return project.byId[hover?.beam] ?? faceHover?.beam;
    }
    final target = hover?.beam;
    if (first != null && target != null && !selection.contains(target)) {
      return project.byId[target];
    }
    return placement?.reference;
  }

  void hoverPlacement(StockAlignment option, bool over) {
    if (tool != Tool.align || (!over && hoverAlignment != option)) return;
    final next = over ? option : null;
    if (hoverAlignment == next) return;
    hoverAlignment = next;
    refresh();
  }

  void chooseAlignment(StockAlignment option, {double? offset}) {
    if (placement == null) return;
    first = hover = null;
    preview = null;
    hoverAlignment = null;
    hasPlacementChoice = true;
    alignment = option;
    if (offset != null) manualOffset = offset;
    refresh();
  }

  bool alignThickness = false;
  double manualOffset = 0;
  StockPlacement? get placement {
    if (tool != Tool.align) return null;
    final part = single, ref = project.visibleGeometry.byId[referenceId];
    return part == null || ref == null || ref.id == part.id
        ? null
        : StockPlacement(part, ref, alignThickness);
  }

  void beginAlignment({bool pickReference = false}) {
    final part = single;
    if (part == null) return;
    if (project.visibleGeometry.beams.length < 2) {
      message = editorStrings.addASecondPartToAlignThem;
      refresh();
      return;
    }
    resetTransient();
    final initial = pickReference ? null : suggestedPlacement;
    referenceId = initial?.reference.id;
    alignThickness = initial?.alongThickness ?? _useThickness(part);
    manualOffset = initial?.current ?? 0;
    alignment = StockAlignment.offset;
    tool = Tool.align;
    refresh();
  }

  void chooseSupport(int id, {bool? alongThickness}) {
    if (tool != Tool.align ||
        !project.visibleGeometry.byId.containsKey(id) ||
        single == null ||
        id == single!.id) {
      return;
    }
    if (alongThickness != null) alignThickness = alongThickness;
    first = hover = null;
    preview = null;
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

  Project rotationPreview(double degrees) => degrees % 360 == 0
      ? project
      : project.rotate(selection, rotationBasis[rotationAxis], degrees % 360);

  Project get displayed {
    if (tool == Tool.rotate) return rotationPreview(angle);
    final p = hasPlacementChoice ? placement : null;
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
      final stop = travelToStop(project.visibleGeometry, selection, direction);
      if (stop == null) {
        message = editorStrings.noStopInThisDirection;
        refresh();
        return;
      }
      travel = stop.travel;
      message = editorStrings.stop(project.byId[stop.obstacle]!.name);
    } else {
      message = editorStrings.nudgeDistance(
        project.unit.format(travel),
        project.unit.symbol,
      );
    }
    if (travel < 1e-7) {
      refresh();
      return;
    }
    commit(project.move(selection, direction * travel));
  }

  bool get canApplyRotation =>
      tool == Tool.rotate && selection.isNotEmpty && angle != 0;

  void applyRotation() {
    if (!canApplyRotation) return;
    final next = displayed;
    tool = Tool.select;
    resetTransient();
    commit(next);
  }

  int? firstShelf;
  Dimension? selectedDimension;
  final _dimensionRowIds = Expando<Object>();
  Object dimensionRowId(Dimension dimension) =>
      _dimensionRowIds[dimension] ?? dimension;

  void selectDimension(Dimension? dimension) {
    resetTransient();
    tool = Tool.ruler;
    selectedDimension = dimension;
    refresh();
  }

  void addDimension(Dimension dimension) {
    resetTransient();
    tool = Tool.ruler;
    selectedDimension = dimension;
    commit(project.copy(dimensions: [...project.dimensions, dimension]));
  }

  void updateDimension(Dimension dimension, Dimension updated) {
    if (!project.dimensions.contains(dimension) || updated == dimension) {
      return;
    }
    // Keep focus in the same row across numeric edits and lock changes.
    _dimensionRowIds[updated] = dimensionRowId(dimension);
    if (selectedDimension == dimension) selectedDimension = updated;
    commit(
      project.copy(
        dimensions: [
          for (final d in project.dimensions) d == dimension ? updated : d,
        ],
      ),
    );
  }

  void removeDimension(Dimension dimension) {
    commit(
      project.copy(dimensions: project.dimensions.where((d) => d != dimension)),
    );
  }

  Dimension? gapPreview;
  Anchor? first, hover;
  StockSketch? sketch;
  Beam? partToPlace;
  SceneFace? faceHover;
  Beam? preview;
  String message = '';
  bool fitRequested = true;
  Project? _checked;
  Set<int> _overlaps = {};
  Set<int> get overlaps {
    if (!identical(_checked, project)) {
      _overlaps = project.visibleGeometry.overlaps;
      _checked = project;
    }
    return _overlaps;
  }

  Editor(this.project);
  ({Beam from, Beam to})? doorSwing;
  Beam configureDoor(Beam part, DoorHinge? hinge, {double? angle}) =>
      part.withDoorHinge(
        hinge,
        towardEye: camera.towardEye(part.pointAt(Vector3.all(.5))),
        screenUp: camera.up,
        angle: angle,
      );
  void toggleDoor(int id) {
    final door = project.byId[id];
    if (door == null || door.hinge == null || door.hidden) return;
    final openedOrClosed = door.swingDoor(1);
    doorSwing = (from: door, to: openedOrClosed);
    commit(project.edit({id}, (_) => openedOrClosed));
  }

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
    if (selectedDimension != null &&
        !project.dimensions.contains(selectedDimension)) {
      selectedDimension = null;
    }
    selection = selection
        .where(project.visibleGeometry.byId.containsKey)
        .toSet();
    if (tool == Tool.align &&
        (single == null || project.visibleGeometry.beams.length < 2)) {
      tool = Tool.select;
      resetTransient();
    }
    if (!project.visibleGeometry.byId.containsKey(referenceId)) {
      referenceId = null;
    }
  }

  void resetTransient({bool keepPartToPlace = false}) {
    selectedDimension = null;
    _referencePickHeld = false;
    hoverAlignment = null;
    hasPlacementChoice = false;
    hoveredSize = focusedSize = null;
    _focusedPositionAxis = null;
    sketch = null;
    if (!keepPartToPlace) partToPlace = null;
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
    selectedView = ViewAngle.iso;
    _freeView = false;
    camera.view(selectedView);
    fitRequested = true;
    onDocumentChange?.call(project);
    notifyListeners();
  }

  void select(int? id, {bool multi = false, bool individual = false}) {
    if (id != null && !project.visibleGeometry.byId.containsKey(id)) return;
    if (tool == Tool.align) tool = Tool.select;
    resetTransient();
    if (id == null) {
      selection = {};
    } else {
      final target = individual ? {id} : project.visibleGeometry.assembly(id);
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

  void selectAll() {
    if (tool == Tool.align) tool = Tool.select;
    resetTransient();
    selection = project.visibleGeometry.byId.keys.toSet();
    refresh();
  }

  void setPartsHidden(Set<int> ids, bool hidden) {
    if (!ids.any((id) => project.byId[id]?.hidden == !hidden)) return;
    resetTransient();
    referenceId = null;
    tool = Tool.select;
    commit(project.edit(ids, (b) => b.copy(hidden: hidden)));
  }

  void showAllHiddenParts() => setPartsHidden({
    for (final b in project.beams)
      if (b.hidden) b.id,
  }, false);

  void setTool(Tool next) {
    resetTransient();
    tool = next;
    if (next == Tool.rotate) {
      chooseRotationAxis(rotationAxis);
      return;
    }
    notifyListeners();
  }

  void beginPlacing(Beam part) {
    resetTransient();
    tool = Tool.beam;
    partToPlace = part;
    notifyListeners();
  }

  void setPlane(WorkPlane next) {
    resetTransient(keepPartToPlace: true);
    if (next.normal.dot(camera.eye).abs() < .025) {
      _rememberView();
      camera.facePlane(next);
      _freeView = true;
    }
    plane = next;
    if (tool == Tool.face) tool = Tool.select;
    notifyListeners();
  }

  void _rememberView() {
    final preset = activeView;
    if (preset != null && !fitRequested) {
      _viewCameras[preset] = (camera.copy(), plane);
    }
  }

  void orbit(Offset delta, Vector3 pivot) {
    if (delta == Offset.zero) return;
    _rememberView();
    _freeView = true;
    camera.orbit(delta, pivot);
    hover = null;
  }

  void setView(ViewAngle next) {
    if (next == activeView) return;
    _rememberView();
    resetTransient(keepPartToPlace: true);
    selectedView = next;
    _freeView = false;
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
    if (rulerActive) {
      if (selectedDimension case final d?) removeDimension(d);
      return;
    }
    if (selection.isNotEmpty) {
      resetTransient();
      commit(project.remove(selection));
    }
  }

  void duplicate() {
    if (selection.isEmpty) return;
    if (tool == Tool.align) {
      tool = Tool.select;
      resetTransient();
    }
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
    commit(
      project.copy(
        beams: [...project.beams, ...copies],
        groupNames: {
          ...project.groupNames,
          for (final entry in groups.entries)
            entry.value: ?project.groupNames[entry.key],
        },
      ),
    );
  }

  void stretchBetweenSupports({required bool height}) {
    final part = single;
    if (part == null || tool != Tool.select) return;
    final basis = [part.along, part.across, part.up];
    var vertical = 0;
    for (var i = 1; i < basis.length; i++) {
      if (basis[i].z.abs() > basis[vertical].z.abs()) vertical = i;
    }
    final horizontal = (vertical + 1) % 3, other = (vertical + 2) % 3;
    final width = basis[horizontal].x.abs() >= basis[other].x.abs()
        ? horizontal
        : other;
    final dim = height ? vertical : width;
    if (part.locked(dim)) {
      message = editorStrings.dimensionLocked;
      refresh();
      return;
    }
    final start = firstContact(part, dim, false, project.visibleGeometry.beams);
    final end = firstContact(part, dim, true, project.visibleGeometry.beams);
    if (start == null || end == null || start.obstacle == end.obstacle) {
      message = editorStrings.referencesAreNeededOnBothSides;
      refresh();
      return;
    }
    final left = project.byId[start.obstacle]!,
        right = project.byId[end.obstacle]!;
    if ((start.travel == 0 && intersects(part, left)) ||
        (end.travel == 0 && intersects(part, right))) {
      message = editorStrings.thePartIntersectsItsReference;
      refresh();
      return;
    }
    if (start.travel + end.travel < 1e-6) {
      message = editorStrings.alreadyTouchesReferences;
      refresh();
      return;
    }
    final grown = resizeEnd(part, dim, false, start.travel);
    message = editorStrings.bothStops(left.name, right.name);
    commit(
      project.edit(selection, (_) => resizeEnd(grown, dim, true, end.travel)),
    );
  }
}
