import '../l10n/strings.dart';
import 'palette.dart';

import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'contact.dart';
import 'controller.dart';
import 'drawing.dart';
import 'dialog_motion.dart';
import 'grid_painter.dart';
import 'model.dart';
import 'move_snap.dart';
import 'part_menu.dart';
import 'platform_ui.dart';
import 'scene.dart';
import 'stock_sketch.dart';
import 'size_dialog.dart';
import 'stock_axis.dart';
import 'step.dart';
import 'view_cube.dart';

class DrawingViewport extends StatefulWidget {
  const DrawingViewport(this.editor, {super.key});
  final Editor editor;
  @override
  State<DrawingViewport> createState() => DrawingViewportState();
}

class DrawingViewportState extends State<DrawingViewport> {
  Editor get e => widget.editor;
  Scene? cached;
  Object? signature;
  Scene get scene => cached!;
  Size size = Size.zero;
  Offset? down, last;
  Vector3? orbitPivot;
  Offset? hoverPosition;
  Set<int> selectionAtPress = const {}, selectionAtFirstTap = const {};
  bool? firstTapWithCommand;
  DrawingPainter? painted;
  RulerTarget? rulerTarget;
  MapEntry<StockAxis, Rect>? sizeLabel(Offset pos) => painted
      ?.stockLabels
      .entries
      .where((item) => item.value.inflate(2).contains(pos))
      .firstOrNull;
  DialogSource? partDialogSource(Beam? part) {
    if (part == null) return null;
    final bounds = scene.faces
        .where((face) => face.beam.id == part.id)
        .map((face) => face.bounds)
        .fold<Rect?>(null, (rect, face) => rect?.expandToInclude(face) ?? face);
    return bounds == null
        ? null
        : DialogSource.of(context, bounds.intersect(Offset.zero & size));
  }

  int buttons = 0;
  Project? before;
  Set<int> moving = {};
  Anchor? source;
  MoveSnap? moveSnap;
  List<MoveGuide> moveGuides = [];
  int? modifierClick;
  bool get raising =>
      e.tool == Tool.beam &&
      e.first != null &&
      (HardwareKeyboard.instance.isMetaPressed ||
          HardwareKeyboard.instance.isControlPressed);

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(modifierChanged);
  }

  bool modifierChanged(KeyEvent ev) {
    final key = ev.logicalKey;
    final command = {
      LogicalKeyboardKey.controlLeft,
      LogicalKeyboardKey.controlRight,
      LogicalKeyboardKey.metaLeft,
      LogicalKeyboardKey.metaRight,
    }.contains(key);
    final shift =
        key == LogicalKeyboardKey.shiftLeft ||
        key == LogicalKeyboardKey.shiftRight;
    if ((command || shift) &&
        e.tool == Tool.beam &&
        e.first != null &&
        hoverPosition != null &&
        ModalRoute.of(context)?.isCurrent == true) {
      hover(hoverPosition!);
      return false;
    }
    if ((shift ||
            key == LogicalKeyboardKey.altLeft ||
            key == LogicalKeyboardKey.altRight ||
            key == LogicalKeyboardKey.space) &&
        e.tool == Tool.select &&
        down == null &&
        ModalRoute.of(context)?.isCurrent == true) {
      e.refresh();
    }
    if (!command) return false;
    final kb = HardwareKeyboard.instance;
    final held = appleControls ? kb.isMetaPressed : kb.isControlPressed;
    final wasPicking = e.pickingAlignmentSupport;
    if (!held || (down == null && ModalRoute.of(context)?.isCurrent == true)) {
      e.holdReferencePick(held);
    }
    if (wasPicking != e.pickingAlignmentSupport && hoverPosition != null) {
      hover(hoverPosition!);
    }
    if (moveSnap != null && dragged && last != null && e.tool == Tool.select) {
      translate(last!);
      e.refresh();
    } else if ((e.tool == Tool.measure || e.tool == Tool.move) &&
        hoverPosition != null) {
      hover(hoverPosition!);
    }
    return false;
  }

  ResizeEdge? resizeEdge;
  WorkPlane? dragPlane;
  Contact? stop;

  bool get shiftResize =>
      HardwareKeyboard.instance.isShiftPressed &&
      !HardwareKeyboard.instance.isSpacePressed &&
      !HardwareKeyboard.instance.isAltPressed;

  bool canResizePart(Beam part) => e.selection.contains(part.id)
      ? e.selection.length == 1
      : part.group == null;

  bool canResizeEdge(ResizeEdge edge) =>
      canResizePart(edge.face.beam) && edge.canResize(e.camera);

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(modifierChanged);
    super.dispose();
  }

  MouseCursor resizeCursor(ResizeEdge edge) {
    final origin = edge.face.world[edge.index];
    final line =
        e.camera.project(origin + edge.direction, size) -
        e.camera.project(origin, size);
    return switch ((line.direction / (math.pi / 4)).round() % 4) {
      0 => SystemMouseCursors.resizeLeftRight,
      1 => SystemMouseCursors.resizeUpLeftDownRight,
      2 => SystemMouseCursors.resizeUpDown,
      _ => SystemMouseCursors.resizeUpRightDownLeft,
    };
  }

  ({Set<int> move, int? resize, ResizeEdge? edge, MouseCursor cursor})
  selectionFeedback() {
    const idle = (
      move: <int>{},
      resize: null,
      edge: null,
      cursor: SystemMouseCursors.basic,
    );
    if (e.tool != Tool.select) {
      if (e.tool == Tool.ruler) {
        final pos = hoverPosition;
        if (pos == null || painted?.dimensionAt(pos) == null) return idle;
        return (
          move: const {},
          resize: null,
          edge: null,
          cursor: SystemMouseCursors.click,
        );
      }
      return (
        move: const {},
        resize: null,
        edge: null,
        cursor: SystemMouseCursors.precise,
      );
    }
    if (down != null) {
      final edge = resizeEdge;
      if (edge != null && scene.project.byId.containsKey(edge.face.beam.id)) {
        return (
          move: const {},
          resize: edge.face.beam.id,
          edge: edge,
          cursor: resizeCursor(edge),
        );
      }
      if (source == null) return idle;
      return (
        move: moving,
        resize: null,
        edge: null,
        cursor: SystemMouseCursors.move,
      );
    }
    final pos = hoverPosition;
    final surface = pos == null ? null : scene.hit(pos);
    final edge = pos != null && (shiftResize || surface == null)
        ? scene.edgeAt(pos, surface: surface)
        : null;
    final part = surface?.beam ?? edge?.face.beam;
    if (!shiftResize) {
      if (part == null) return idle;
      final ids = e.selection.contains(part.id)
          ? e.selection
          : scene.project.assembly(part.id);
      return (
        move: ids,
        resize: null,
        edge: null,
        cursor: SystemMouseCursors.move,
      );
    }
    final marked = part ?? e.single;
    if (marked == null || !canResizePart(marked)) return idle;
    final active = edge != null && edge.canResize(e.camera) ? edge : null;
    return (
      move: const {},
      resize: marked.id,
      edge: active,
      cursor: active == null ? SystemMouseCursors.basic : resizeCursor(active),
    );
  }

  void stretch(ResizeEdge edge, Offset pos) {
    final plane = dragPlane!;
    final point = e.camera.onPlane(pos, size, plane);
    if (point == null) return;
    final initial = before!, part = edge.face.beam;
    final dim = edge.axis, travel = (point - plane.origin).dot(plane.u);
    final target = e.step.round(part.size[dim] + travel, initial.unit);
    final resized = resizeEnd(
      part,
      dim,
      edge.positive,
      target - part.size[dim],
      stop: stop,
    );
    e.project = resized.size[dim] == part.size[dim]
        ? initial
        : initial.edit({part.id}, (_) => resized);
    e.message = stop != null && travel >= stop!.travel
        ? context.strings.stop(initial.byId[stop!.obstacle]!.name)
        : '';
  }

  bool dragged = false;
  double pinchScale = 1;

  Anchor? pick(Offset at) {
    if (e.snap) {
      final a = scene.snap(at, mode: e.snapMode);
      if (a != null) return a;
    }
    final point = pointOnWorkPlane(at);
    return point == null ? null : Anchor(point);
  }

  Anchor? facePoint(Offset at, SceneFace face) {
    final point = scene.pointOnFace(at, face);
    return point == null
        ? null
        : Anchor(
            point,
            face.beam.id,
            0,
            face.beam.localAt(point),
            'Грань',
            face.face,
          );
  }

  Anchor? partPoint(Offset at, {Set<int>? only, Set<int> exclude = const {}}) {
    if (e.snap) {
      final hit = scene.snap(
        at,
        only: only,
        exclude: exclude,
        mode: e.snapMode,
      );
      if (hit != null || e.snapMode == SnapMode.surface) return hit;
    }
    if (!e.snap || e.snapMode == SnapMode.auto) {
      final face = scene.hit(at, exclude: exclude);
      if (face != null && (only == null || only.contains(face.beam.id))) {
        return facePoint(at, face);
      }
    }
    return null;
  }

  Anchor? movePoint(Offset at) {
    final first = e.first;
    if (e.tool == Tool.align) {
      if (e.pickingAlignmentSupport ||
          (first != null && e.selection.contains(first.beam))) {
        return partPoint(at, exclude: e.selection);
      }
      return partPoint(at, only: first == null ? null : e.selection);
    }
    final hit = partPoint(
      at,
      only: first == null && e.selection.isNotEmpty ? e.selection : null,
      exclude: first == null ? const {} : e.selection,
    );
    if (hit != null ||
        first == null ||
        (e.snap && e.snapMode == SnapMode.surface)) {
      return hit;
    }
    final point = pointOnWorkPlane(at);
    return point == null ? null : Anchor(point);
  }

  (Anchor, Anchor) moveEndpoints(Anchor first, Anchor second) =>
      e.selection.contains(first.beam) ? (first, second) : (second, first);

  Project moveToAnchors(Anchor from, Anchor to) => mate(
    e.project,
    e.selection,
    from,
    to,
    withinWorkspace: e.tool == Tool.move && e.movementSnapping,
  );

  void hover(Offset pos) {
    hoverPosition = pos;
    if (e.partToPlace != null) {
      e.refresh();
      return;
    }
    if (e.pickingAlignmentSupport) {
      e.hover = movePoint(pos);
      final hit = scene.hit(pos, exclude: e.selection);
      e.faceHover = e.hover == null || hit?.beam.id == e.hover?.beam
          ? hit
          : null;
      e.preview = null;
      e.refresh();
      return;
    }
    if (e.tool == Tool.gap) {
      final hit = scene.hit(pos);
      e.faceHover = hit;
      final first = e.project.byId[e.firstShelf];
      e.gapPreview = first != null && hit != null && first.id != hit.beam.id
          ? shelfClearance(first, hit.beam)
          : null;
      e.refresh();
      return;
    }
    final stage = e.first != null;
    final isMove = e.tool == Tool.move || e.tool == Tool.align;
    e.faceHover = e.tool == Tool.face || (e.tool == Tool.beam && !stage)
        ? scene.hit(pos)
        : null;
    e.hover = switch (e.tool) {
      Tool.face || Tool.rotate || Tool.gap => null,
      Tool.select || Tool.ruler => null,
      Tool.measure => measurePoint(pos),
      Tool.beam => beamPoint(pos),
      Tool.move || Tool.align => movePoint(pos),
    };
    if (e.tool == Tool.beam &&
        e.first != null &&
        e.hover != null &&
        !raising &&
        HardwareKeyboard.instance.isShiftPressed) {
      final delta = e.hover!.point - e.first!.point;
      final plane = e.sketch!.plane;
      final direction = delta.dot(plane.u).abs() >= delta.dot(plane.v).abs()
          ? plane.u
          : plane.v;
      e.hover = Anchor(e.first!.point + direction * delta.dot(direction));
    }
    if (e.tool == Tool.beam &&
        e.first != null &&
        e.hover != null &&
        e.hover!.beam == null) {
      final base = e.first!.point, delta = e.hover!.point - base;
      if (delta.length > 1e-7) {
        e.hover = Anchor(
          base +
              delta.normalized() * e.step.round(delta.length, e.project.unit),
        );
      }
    }
    e.preview = null;
    if (e.first != null && e.hover != null) {
      final start = e.first!.resolve(e.project),
          finish = e.hover!.resolve(e.project);
      if (e.tool == Tool.beam && start.distanceTo(finish) >= 1) {
        e.preview = e.sketch!.make(
          e.project.nextId,
          start,
          finish,
          raised: raising,
        );
      } else if (isMove && e.selection.isNotEmpty) {
        final (from, to) = moveEndpoints(e.first!, e.hover!);
        e.preview = moveToAnchors(from, to).byId[from.beam];
      }
    }
    e.refresh();
  }

  Anchor? beamPoint(Offset pos) {
    final sketch = e.sketch;
    final hit = e.snap ? scene.snap(pos, mode: e.snapMode) : null;
    if (raising && sketch != null) {
      return sketch.raisedEnd(
        e.camera,
        size,
        pos,
        e.first!.resolve(e.project),
        hit,
        verticalOnly: HardwareKeyboard.instance.isShiftPressed,
      );
    }
    final plane = sketch?.plane ?? e.plane;
    if (hit != null &&
        (sketch?.reference == null ||
            (hit.point - plane.origin).dot(plane.normal).abs() < .001)) {
      return hit;
    }
    final face = e.faceHover;
    if (sketch == null && face != null) {
      final anchor = facePoint(pos, face);
      if (anchor != null) return anchor;
    }
    final point = e.camera.onPlane(pos, size, plane);
    if (point == null) return null;
    return Anchor(plane.quantize(point, scene.input.stepMm));
  }

  StockSketch beginSketch(Anchor start) {
    final ref = e.project.byId[start.beam];
    var plane = e.plane.through(start.point);
    if (ref != null && e.activeView?.projectionPlane == null) {
      final visible = scene.faces.reversed.where(
        (f) =>
            f.beam.id == ref.id &&
            (start.point - f.world.first).dot(f.normal).abs() < .001,
      );
      final clicked = e.faceHover;
      final face = clicked != null && visible.contains(clicked)
          ? clicked
          : visible.firstOrNull;
      if (face != null) {
        final n = face.normal;
        final u = ref.along.dot(n).abs() < .00001 ? ref.along : face.plane.u;
        plane = WorkPlane('Грань', start.point, u, n.cross(u));
      }
    }
    return StockSketch(plane, ref);
  }

  Anchor? measurePoint(Offset pos) {
    rulerTarget = scene.rulerTarget(
      pos,
      sticky: e.movementSnapping,
      mode: e.snapMode,
    );
    if (rulerTarget case final target?) return target.anchor;
    final first = e.first;
    final plane = first == null
        ? e.plane
        : e.plane.through(first.resolve(e.project));
    final point = e.camera.onPlane(pos, size, plane);
    return point == null
        ? null
        : Anchor(plane.quantize(point, scene.input.stepMm));
  }

  void clickTool(Offset pos) {
    if (e.tool == Tool.ruler) {
      e.selectDimension(painted?.dimensionAt(pos));
      return;
    }
    if (e.partToPlace case final part?) {
      final anchor = pick(pos);
      if (anchor != null) {
        insertPart(part.copy(id: e.project.nextId, origin: anchor.point));
      }
      return;
    }
    if (e.tool == Tool.gap) {
      hover(pos);
      final target = e.faceHover?.beam;
      if (target == null) return;
      if (e.firstShelf == null) {
        e.firstShelf = target.id;
        e.message = context.strings.selectTheSecondShelf;
        e.refresh();
        return;
      }
      if (e.gapPreview == null) {
        e.message = context.strings.chooseParallelShelf;
        e.refresh();
        return;
      }
      final gap = e.gapPreview!;
      e.addDimension(gap);
      return;
    }
    if (e.pickingAlignmentSupport) {
      hover(pos);
      final anchor = e.hover;
      final target = anchor?.beam ?? e.faceHover?.beam.id;
      if (target != null) {
        e.chooseSupport(target);
        if (e.pickingAlignmentSupport) {
          hover(pos);
        } else {
          e.first = anchor;
          e.refresh();
        }
      }
      return;
    }
    hover(pos);
    if (e.tool == Tool.face) {
      final face = e.faceHover;
      if (face != null) e.setPlane(face.plane);
      return;
    }
    final a = e.hover;
    if (a == null) {
      e.message = e.tool == Tool.move || e.tool == Tool.align
          ? ''
          : context.strings.selectAnAnchorOnThePart;
      e.refresh();
      return;
    }
    if (e.first == null) {
      if (e.tool == Tool.align) {
        if (!e.selection.contains(a.beam)) e.chooseSupport(a.beam!);
        e.hasPlacementChoice = false;
        e.hoverAlignment = null;
        e.hover = null;
      }
      if (e.tool == Tool.move) {
        if (a.beam == null) return;
        if (!e.selection.contains(a.beam)) e.select(a.beam);
      }
      e.first = a;
      e.message = '';
      if (e.tool == Tool.beam) {
        e.sketch = beginSketch(a);
        if (e.sketch!.reference case final part?) {
          final units = e.project.unit;
          e.message = context.strings.sketchEndHint(
            part.name,
            e.lengthInput.format(part.size.y),
            e.lengthInput.format(part.size.z),
            units.symbol,
          );
        }
      }
      e.refresh();
      return;
    }
    final start = e.first!,
        from = start.resolve(e.project),
        to = a.resolve(e.project);
    if (from.distanceTo(to) < .001 &&
        e.tool != Tool.move &&
        e.tool != Tool.align) {
      return;
    }
    switch (e.tool) {
      case Tool.move || Tool.align:
        final (source, target) = moveEndpoints(start, a);
        final next = moveToAnchors(source, target);
        e.setTool(Tool.select);
        e.commit(next);
      case Tool.beam:
        if (from.distanceTo(to) < 1) return;
        final beam = e.preview;
        if (beam == null) return;
        insertPart(beam);
      case Tool.measure:
        e.addDimension(Dimension(start, a));
      default:
        break;
    }
  }

  Future<void> handleTap(SerialTapUpDetails tap) async {
    final at = tap.localPosition;
    final kb = HardwareKeyboard.instance;
    if (kb.isAltPressed || kb.isShiftPressed || kb.isSpacePressed) {
      firstTapWithCommand = null;
      return;
    }
    final command = kb.isControlPressed || kb.isMetaPressed;
    if (tap.count == 1 || firstTapWithCommand != command) {
      selectionAtFirstTap = selectionAtPress;
      firstTapWithCommand = command;
      return;
    }
    firstTapWithCommand = null;
    if (command) {
      final label = sizeLabel(at), part = e.single;
      if (label == null || part == null) return;
      final index = label.key.index;
      if (part.locked(index)) {
        e.message = context.strings.dimensionLocked;
        e.refresh();
        return;
      }
      final value = await editDimensionLabel(
        context,
        part,
        label.key,
        label.value,
      );
      if (mounted &&
          value != null &&
          part.size[index] != value &&
          e.project.byId[part.id] == part) {
        e.commit(
          e.project.edit({
            part.id,
          }, (b) => b.copy(size: b.size.clone()..[index] = value)),
        );
      }
      return;
    }
    final partAtPointer = scene.hit(at)?.beam;
    if (partAtPointer == null) return;
    if (selectionAtFirstTap.length < 2 ||
        !selectionAtFirstTap.contains(partAtPointer.id) ||
        !e.selection.contains(partAtPointer.id)) {
      e.select(partAtPointer.id, individual: true);
    }
    final box = context.findRenderObject()! as RenderBox;
    await showPartProperties(
      context,
      e,
      box.localToGlobal(at),
      source: partDialogSource(partAtPointer),
    );
  }

  Beam newPart(Vector3 origin) {
    final id = e.project.nextId;
    return Beam(
      id,
      Beam.defaultName(id),
      origin,
      Vector3(300, StockSketch.defaultWidth, StockSketch.defaultThickness),
      e.plane.u,
      e.plane.v,
    );
  }

  Vector3? pointOnWorkPlane(Offset at) {
    final point = e.camera.onPlane(at, size, e.plane);
    return point == null ? null : e.plane.quantize(point, scene.input.stepMm);
  }

  void insertPart(Beam part) {
    e.tool = Tool.select;
    e.resetTransient();
    e.selection = {part.id};
    e.commit(e.project.copy(beams: [...e.project.beams, part]));
  }

  void addPartAt(Offset at) {
    final origin = pointOnWorkPlane(at);
    if (origin != null) insertPart(newPart(origin));
  }

  Future<void> addWithDimensions() async {
    if (down != null) return;
    final document = e.project;
    final at = hoverPosition ?? size.center(Offset.zero);
    final sketch = e.tool == Tool.beam ? e.sketch : null;
    final start = sketch == null ? null : e.first?.resolve(document);
    final draft =
        e.partToPlace ??
        (sketch != null && start != null
            ? e.preview ??
                  sketch.make(
                    document.nextId,
                    start,
                    start + sketch.plane.u * 300,
                  )
            : newPart(e.plane.origin));
    final box = context.findRenderObject()! as RenderBox;
    final preview = painted?.preview;
    final previewBounds = preview == null
        ? null
        : (Path()..addPolygon([
            for (final p in preview.corners) e.camera.project(p, size),
          ], true));
    final part = await editPartSize(
      context,
      e,
      draft,
      box.localToGlobal(at),
      creating: true,
      source: previewBounds == null
          ? null
          : DialogSource.of(
              context,
              previewBounds.getBounds().intersect(Offset.zero & size),
            ),
    );
    if (!mounted || !identical(document, e.project)) return;
    e.hoveredSize = e.focusedSize = null;
    if (part != null) {
      e.beginPlacing(part);
    } else {
      e.refresh();
    }
  }

  void start(PointerDownEvent ev) {
    FocusManager.instance.primaryFocus?.unfocus();
    FocusManager.instance.applyFocusChangesIfNeeded();
    down = last = hoverPosition = ev.localPosition;
    orbitPivot = null;
    buttons = ev.buttons;
    dragged = false;
    before = null;
    moving = {};
    resizeEdge = null;
    source = null;
    moveSnap = null;
    moveGuides = [];
    modifierClick = null;
    if (buttons != kPrimaryMouseButton || e.tool != Tool.select) return;
    selectionAtPress = e.selection;
    final part = e.single;
    if (part != null &&
        (HardwareKeyboard.instance.isControlPressed ||
            HardwareKeyboard.instance.isMetaPressed) &&
        sizeLabel(down!) != null) {
      return;
    }
    final face = scene.hit(down!);
    final edge = shiftResize || face == null
        ? scene.edgeAt(down!, surface: face)
        : null;
    if (shiftResize && edge != null && canResizeEdge(edge)) {
      final anchor = e.camera.onPlane(down!, size, edge.face.plane);
      if (anchor != null) {
        resizeEdge = edge;
        before = e.project;
        modifierClick = edge.face.beam.id;
        final direction = edge.direction;
        dragPlane = WorkPlane(
          '',
          anchor,
          direction,
          e.camera.towardEye(anchor).cross(direction).normalized(),
        );
        stop = firstContact(
          edge.face.beam,
          edge.axis,
          edge.positive,
          scene.project.beams,
        );
        e.refresh();
        return;
      }
    }
    final alt = HardwareKeyboard.instance.isAltPressed;
    final snapped = e.snap ? scene.snap(down!, mode: e.snapMode) : null;
    int? id = face?.beam.id ?? edge?.face.beam.id ?? snapped?.beam;
    if (alt && face != null) {
      final hits = <int>{
        for (final f in scene.faces.reversed)
          if (f.path.contains(down!)) f.beam.id,
      }.toList();
      id = hits[(hits.indexOf(e.single?.id ?? -1) + 1) % hits.length];
    }
    final multi = HardwareKeyboard.instance.isShiftPressed;
    if (multi && alt) {
      e.select(id, multi: true, individual: true);
      return;
    }
    if (id != null &&
        (multi ||
            HardwareKeyboard.instance.isControlPressed ||
            HardwareKeyboard.instance.isMetaPressed)) {
      modifierClick = id;
    } else if (id == null || !e.selection.contains(id) || alt) {
      e.select(id, individual: alt);
    }
    if (id == null || multi) return;
    before = e.project;
    moving = e.selection.contains(id)
        ? {...e.selection}
        : e.project.visibleGeometry.assembly(id);
    source = snapped != null && moving.contains(snapped.beam) ? snapped : null;
    final hitPoint = face == null
        ? null
        : e.camera.onPlane(down!, size, face.plane);
    source ??= Anchor(hitPoint ?? e.project.byId[id]!.origin);
  }

  void translate(Offset pos) {
    final initial = before!, anchor = source!.resolve(initial);
    final plane = e.plane.through(anchor);
    final target = e.camera.project(anchor, size) + pos - down!;
    final point = e.camera.onPlane(target, size, plane);
    if (point == null) return;
    final free = plane.quantize(point, scene.input.stepMm) - anchor;
    var delta = free;
    moveGuides = [];
    e.hover = null;
    e.message = '';
    if (e.movementSnapping) {
      final snap = moveSnap!.apply(point - anchor, free, e.camera);
      delta = snap.delta;
      moveGuides = snap.guides;
      if (e.snap &&
          source!.beam != null &&
          (moveGuides.isEmpty || e.snapMode != SnapMode.auto)) {
        final hit = scene.snap(target, exclude: moving, mode: e.snapMode);
        if (hit != null) {
          delta = hit.point - anchor;
          e.hover = hit;
          moveGuides = [];
        }
      }
      final limited = moveSnap!.workspaceLimits?.clampTranslation(
        delta,
        planeNormal: e.hover == null ? plane.normal : null,
      );
      if (limited != null && limited != delta) {
        delta = limited;
        moveGuides = [];
        moveSnap!.release();
        e.hover = null;
      }
      final gap = moveGuides.map((g) => g.gap).nonNulls.firstOrNull;
      if (gap != null) {
        e.message = context.strings.equalGapValue(
          e.lengthInput.format(gap),
          initial.unit.symbol,
        );
      } else if (moveGuides.isNotEmpty) {
        e.message = context.strings.edgeAligned;
      }
    } else {
      moveSnap!.release();
    }
    e.project = delta.length2 < 1e-14 ? initial : initial.move(moving, delta);
  }

  Vector3 pivotAt(Offset position) {
    final face = scene.hit(position);
    if (face != null) {
      final point = e.camera.onPlane(position, size, face.plane);
      if (point != null) return point;
    }
    if (e.selection.isEmpty) {
      return e.framedProject.partBounds?.center ?? e.camera.target.clone();
    }
    return Bounds3.points(e.selected.expand((b) => b.corners)).center;
  }

  void move(PointerMoveEvent ev) {
    if (down == null) return;
    final pos = ev.localPosition, delta = pos - last!;
    last = pos;
    hoverPosition = (Offset.zero & size).contains(pos) ? pos : null;
    if (!dragged &&
        (pos - down!).distance < (buttons == kSecondaryMouseButton ? 5 : 3)) {
      return;
    }
    dragged = true;
    if (buttons == kSecondaryMouseButton) {
      orbitPivot ??= pivotAt(down!);
      e.orbit(delta, orbitPivot!);
      e.refresh();
      return;
    }
    if (buttons == kMiddleMouseButton ||
        (buttons == kPrimaryMouseButton &&
            HardwareKeyboard.instance.isSpacePressed)) {
      e.camera.pan += delta;
      e.refresh();
      return;
    }
    if (e.partToPlace != null) {
      e.refresh();
      return;
    }
    if (e.tool != Tool.select || before == null) return;
    if (resizeEdge case final edge?) {
      if (modifierClick != null && e.single?.id != edge.face.beam.id) {
        e.select(edge.face.beam.id);
      }
      modifierClick = null;
      stretch(edge, pos);
    } else if (source != null) {
      if (modifierClick != null && !e.selection.contains(modifierClick)) {
        e.select(modifierClick);
      }
      modifierClick = null;
      moveSnap ??= MoveSnap(before!.visibleGeometry, moving, e.plane);
      translate(pos);
    }
    e.refresh();
  }

  void finish(PointerUpEvent ev) {
    if (down != null && !dragged && buttons == kSecondaryMouseButton) {
      final at = ev.localPosition;
      final hit = scene.hit(at);
      unawaited(
        showDrawingMenu(
          context,
          e,
          ev.position,
          partId: hit?.beam.id,
          source: partDialogSource(hit?.beam),
          facePlane: hit?.plane,
          end: switch (hit?.face) {
            0 => false,
            1 => true,
            _ => null,
          },
          addHere: () => addPartAt(at),
        ),
      );
    } else if (!dragged && modifierClick != null) {
      e.select(modifierClick, multi: true);
    } else if (!dragged &&
        buttons == kPrimaryMouseButton &&
        e.tool == Tool.rotate &&
        e.selection.isNotEmpty) {
      final pivot = Bounds3.points(e.selected.expand((b) => b.corners)).center;
      final dial = RotationDial.project(
        e.camera,
        size,
        pivot,
        e.rotationBasis[e.rotationAxis],
      );
      final sign = dial.hit(ev.localPosition);
      if (sign != null) e.setAngle(e.angle + sign * 90);
    } else if (!dragged &&
        buttons == kPrimaryMouseButton &&
        e.tool != Tool.select &&
        e.tool != Tool.rotate) {
      clickTool(ev.localPosition);
    } else if (dragged && before != null && !identical(e.project, before)) {
      e.commit(e.project, before: before);
    }
    if (before != null && dragged) {
      e.hover = null;
      e.message = '';
    }
    down = null;
    before = null;
    resizeEdge = null;
    moveSnap = null;
    moveGuides = [];
    modifierClick = null;
    moving = {};
    e.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final motion = e.doorSwing;
    if (motion != null &&
        e.tool == Tool.select &&
        identical(e.project.byId[motion.to.id], motion.to) &&
        !MediaQuery.disableAnimationsOf(context)) {
      return TweenAnimationBuilder<double>(
        key: ObjectKey(motion.to),
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeInOut,
        builder: (_, t, _) => _viewport(0, swingingDoor: motion.from, swing: t),
        onEnd: () {
          if (e.doorSwing == motion) e.doorSwing = null;
        },
      );
    }
    if (e.tool != Tool.rotate || e.selection.isEmpty) return _viewport(0);
    if (MediaQuery.disableAnimationsOf(context)) return _viewport(e.angle);
    return TweenAnimationBuilder<double>(
      key: ValueKey((
        e.project,
        e.rotationAxis,
        e.localRotation,
        Object.hashAllUnordered(e.selection),
      )),
      tween: Tween(begin: e.rotationDegrees, end: e.rotationDegrees),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeInOut,
      builder: (_, degrees, _) => _viewport(degrees),
    );
  }

  Widget _viewport(
    double previewAngle, {
    Beam? swingingDoor,
    double swing = 1,
  }) {
    return LayoutBuilder(
      builder: (context, box) {
        size = box.biggest;
        if (e.fitRequested) {
          e.camera.fit(e.framedProject, size);
          e.fitRequested = false;
        }
        final c = e.camera;
        final sig = (
          e.project,
          e.lengthInput,
          e.tool,
          e.referenceId,
          e.alignment,
          e.alignThickness,
          e.manualOffset,
          e.rotationAxis,
          e.localRotation,
          previewAngle,
          swing,
          e.tool == Tool.rotate ? Object.hashAll(e.selection) : 0,
          c.yaw,
          c.perspective,
          c.eyeDistance,
          c.pitch,
          c.scale,
          c.pan,
          c.target.x,
          c.target.y,
          c.target.z,
          size,
        );
        final sceneChanged = signature != sig;
        if (sceneChanged) {
          var document = e.tool == Tool.rotate
              ? e.rotationPreview(previewAngle)
              : e.project;
          if (swingingDoor != null && swing < 1) {
            document = document.edit({
              swingingDoor.id,
            }, (_) => swingingDoor.swingDoor(swing));
          }
          cached = Scene(document, c, size, input: e.lengthInput);
          signature = sig;
        }
        if (sceneChanged && e.tool == Tool.measure && hoverPosition != null) {
          e.hover = measurePoint(hoverPosition!);
        }
        final placement = e.previewPlacement, option = e.visibleAlignment;
        final partToPlace = e.partToPlace;
        final anchor = partToPlace != null && hoverPosition != null
            ? pick(hoverPosition!)
            : null;
        final feedback = selectionFeedback();
        final drawing = MouseRegion(
          cursor: feedback.cursor,
          onEnter: (ev) {
            hoverPosition = ev.localPosition;
            if (e.tool == Tool.measure) {
              hover(ev.localPosition);
            } else if (e.tool == Tool.select || e.partToPlace != null) {
              e.refresh();
            }
          },
          onHover: (ev) => hover(ev.localPosition),
          onExit: (_) {
            hoverPosition = null;
            e.hover = null;
            e.preview = null;
            e.faceHover = null;
            e.refresh();
          },
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: start,
            onPointerMove: move,
            onPointerUp: finish,
            onPointerCancel: (_) {
              resizeEdge = null;
              moveSnap = null;
              moveGuides = [];
              modifierClick = null;
              e.hover = null;
              e.message = '';
              if (before != null) {
                e.project = before!;
              }
              before = null;
              down = null;
              e.refresh();
            },
            onPointerSignal: (ev) {
              if (ev is PointerScrollEvent) {
                if (HardwareKeyboard.instance.isControlPressed ||
                    HardwareKeyboard.instance.isMetaPressed) {
                  e.camera.zoom(
                    math.exp(-ev.scrollDelta.dy.clamp(-400, 400) * .0035),
                    ev.localPosition,
                    size,
                  );
                } else {
                  e.camera.pan -= ev.scrollDelta;
                }
                e.refresh();
              }
            },
            onPointerPanZoomStart: (_) {
              orbitPivot = null;
              pinchScale = 1;
            },
            onPointerPanZoomUpdate: (ev) {
              if (HardwareKeyboard.instance.isControlPressed ||
                  HardwareKeyboard.instance.isMetaPressed) {
                e.camera.zoom(
                  math.exp(ev.panDelta.dy.clamp(-400, 400) * .008),
                  ev.localPosition,
                  size,
                );
              } else if (HardwareKeyboard.instance.isAltPressed) {
                orbitPivot ??= pivotAt(ev.localPosition);
                e.orbit(ev.panDelta, orbitPivot!);
              } else {
                e.camera.pan += ev.panDelta;
              }
              e.camera.zoom(ev.scale / pinchScale, ev.localPosition, size);
              pinchScale = ev.scale;
              e.refresh();
            },
            child: RawGestureDetector(
              gestures: {
                if (e.tool == Tool.select)
                  SerialTapGestureRecognizer:
                      GestureRecognizerFactoryWithHandlers<
                        SerialTapGestureRecognizer
                      >(
                        () => SerialTapGestureRecognizer(
                          allowedButtonsFilter: (buttons) =>
                              buttons == kPrimaryButton,
                        ),
                        (recognizer) => recognizer.onSerialTapUp = handleTap,
                      ),
              },
              child: Stack(
                fit: StackFit.expand,
                children: [
                  RepaintBoundary(
                    child: CustomPaint(
                      painter: GridPainter(
                        camera: c,
                        project: e.project,
                        plane: e.plane,
                        visibility: e.gridVisibility,
                        colors: context.colors,
                      ),
                    ),
                  ),
                  RepaintBoundary(
                    child: CustomPaint(
                      key: const Key('drawing'),
                      size: size,
                      painter: painted = DrawingPainter(
                        colors: context.colors,
                        scene: scene,
                        hiddenOutlines: e.showHiddenOutlines
                            ? e.project.beams.where((b) => b.hidden)
                            : const [],
                        selection: e.selection,
                        selectedDimension: e.selectedDimension,
                        referenceId: e.firstShelf,
                        alignmentSupport: e.alignmentSupport,
                        gapPreview: e.gapPreview,
                        first: e.first,
                        hover: anchor ?? e.hover,
                        preview: anchor != null
                            ? partToPlace!.copy(origin: anchor.point)
                            : placement != null && option != null
                            ? placement.placed(option, e.manualOffset)
                            : e.preview,
                        previewColor: option == null
                            ? context.colors.accent
                            : context.colors.diagramColor(
                                alignmentColors[option]!,
                              ),
                        activeFace: e.faceHover,
                        rulerTarget:
                            e.tool == Tool.measure &&
                                e.hover == rulerTarget?.anchor
                            ? rulerTarget
                            : null,
                        showRise: raising,
                        dimensionsVisible: e.dimensionsVisible,
                        showAllStockSizes: e.rulerActive,
                        dimensions:
                            e.rulerActive ||
                            (e.tool != Tool.rotate ||
                                    e.highlightedSize != null) &&
                                moveGuides.isEmpty,
                        overlaps: e.tool == Tool.rotate || e.tool == Tool.align
                            ? scene.project.overlaps
                            : e.overlaps,
                        moveHighlight: feedback.move,
                        resizePart: feedback.resize,
                        activeEdge: feedback.edge,
                        edgePointer: hoverPosition,
                        original: e.tool == Tool.rotate ? e.project : null,
                        rotationAxis: e.rotationAxis,
                        rotationBasis: e.rotationBasis,
                        localRotation: e.localRotation && e.single != null,
                        highlightedSize: e.highlightedSize,
                        positionGuide: e.positionGuide,
                        moveGuides: moveGuides,
                        angle: previewAngle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        return Stack(
          fit: StackFit.expand,
          children: [drawing, ViewCube(scene, e.setView)],
        );
      },
    );
  }
}

extension on HardwareKeyboard {
  bool get isSpacePressed => isLogicalKeyPressed(LogicalKeyboardKey.space);
}
