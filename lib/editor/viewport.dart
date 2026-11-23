import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'contact.dart';
import 'controller.dart';
import 'drawing.dart';
import 'model.dart';
import 'move_snap.dart';
import 'part_menu.dart';
import 'scene.dart';
import 'stock_sketch.dart';
import 'size_dialog.dart';
import 'stock_axis.dart';

class DrawingViewport extends StatefulWidget {
  const DrawingViewport(this.editor, {super.key});
  final Editor editor;
  @override
  State<DrawingViewport> createState() => _DrawingViewportState();
}

class _DrawingViewportState extends State<DrawingViewport> {
  Editor get e => widget.editor;
  Scene? cached;
  Object? signature;
  Scene get scene => cached!;
  Size size = Size.zero;
  Offset? down, last;
  Offset? hoverPosition;
  Offset? doubleClickPosition;
  DrawingPainter? painted;
  MapEntry<StockAxis, Rect>? sizeLabel(Offset pos) => painted
      ?.stockLabels
      .entries
      .where((item) => item.value.inflate(2).contains(pos))
      .firstOrNull;
  int buttons = 0;
  Project? before;
  Set<int> moving = {};
  Anchor? source;
  MoveSnap? moveSnap;
  List<MoveGuide> moveGuides = [];
  int? modifierClick;
  bool get sticky =>
      e.snapByDefault !=
      (HardwareKeyboard.instance.isControlPressed ||
          HardwareKeyboard.instance.isMetaPressed);
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(modifierChanged);
  }

  bool modifierChanged(KeyEvent ev) {
    if (![
      LogicalKeyboardKey.controlLeft,
      LogicalKeyboardKey.controlRight,
      LogicalKeyboardKey.metaLeft,
      LogicalKeyboardKey.metaRight,
    ].contains(ev.logicalKey)) {
      return false;
    }
    if (moveSnap != null && dragged && last != null && e.tool == Tool.select) {
      translate(last!);
      e.refresh();
    } else if (e.tool == Tool.measure && hoverPosition != null) {
      hover(hoverPosition!);
    }
    return false;
  }

  bool? end;
  Contact? stop;
  EndMagnet magnet = EndMagnet();
  List<EndAlignment> alignmentTargets = [];
  final clock = Stopwatch()..start();
  Timer? pending;
  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(modifierChanged);
    pending?.cancel();
    super.dispose();
  }

  void stretch(Beam b, double travel, double pixelsPerMm) {
    pending?.cancel();
    e.guide = null;
    final hit = e.magneticResize
        ? magnet.update(
            travel,
            alignmentTargets,
            7 / pixelsPerMm,
            clock.elapsed,
          )
        : null;
    if (hit == null && e.magneticResize && magnet.candidate != null) {
      final remaining =
          const Duration(milliseconds: 180) - (clock.elapsed - magnet.since!);
      pending = Timer(remaining.isNegative ? Duration.zero : remaining, () {
        if (mounted && before != null && end != null && e.tool == Tool.select) {
          stretch(b, travel, pixelsPerMm);
          e.refresh();
        }
      });
    }
    e.project = before!.edit(
      moving,
      (b) => resizeEnd(
        b,
        e.resizeAxis,
        end!,
        hit?.travel ??
            e.step.round(b.size[e.resizeAxis] + travel, e.project.unit) -
                b.size[e.resizeAxis],
        stop: stop,
      ),
    );
    final part = e.project.byId[b.id]!;
    if (hit != null) {
      e.guide = (faceCenter(part, e.resizeAxis, end!), hit.target);
      e.message = 'Выровнено · ${before!.byId[hit.id]!.name}';
    } else {
      e.message = stop != null && travel >= stop!.travel
          ? 'Упор · ${before!.byId[stop!.obstacle]!.name}'
          : 'Размер · ${e.project.unit.format(part.size[e.resizeAxis])} ${e.project.unit.symbol}';
    }
  }

  bool dragged = false;
  double pinchScale = 1;

  Anchor? pick(
    Offset at, {
    Set<int> exclude = const {},
    Set<int>? only,
    WorkPlane? plane,
    bool free = true,
  }) {
    if (e.snap) {
      final a = scene.snap(at, exclude: exclude, only: only, mode: e.snapMode);
      if (a != null) return a;
    }
    if (!free) return null;
    final work = plane ?? e.plane;
    final p = e.camera.onPlane(at, size, work);
    return p == null
        ? null
        : Anchor(
            e.step.enabled
                ? work.quantize(p, e.step.millimeters(e.project.unit))
                : p,
          );
  }

  void hover(Offset pos) {
    hoverPosition = pos;
    if (e.tool == Tool.align) {
      final hit = e.referenceId == null ? scene.hit(pos) : null;
      e.faceHover = hit?.beam.id == e.single?.id ? null : hit;
      e.hover = null;
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
    final isMove = e.tool == Tool.move;
    e.faceHover = e.tool == Tool.face || (e.tool == Tool.beam && !stage)
        ? scene.hit(pos)
        : null;
    final constrained = isMove && !stage && e.selection.isNotEmpty;
    e.hover = switch (e.tool) {
      Tool.face || Tool.rotate || Tool.align => null,
      Tool.select => e.snap ? scene.snap(pos, mode: e.snapMode) : null,
      Tool.measure => measurePoint(pos),
      Tool.beam => beamPoint(pos),
      _ => pick(
        pos,
        only: constrained ? e.selection : null,
        exclude: isMove && stage ? e.selection : {},
        free: !isMove || (stage && e.snapMode != SnapMode.surface),
      ),
    };
    if (e.tool == Tool.beam &&
        e.first != null &&
        e.hover != null &&
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
        e.hover!.beam == null &&
        e.step.enabled) {
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
        e.preview = e.sketch!.make(e.project.nextId, start, finish);
      } else if (isMove && e.selection.isNotEmpty) {
        e.preview = mate(
          e.project,
          e.selection,
          e.first!,
          e.hover!,
        ).byId[e.first!.beam];
      }
    }
    e.refresh();
  }

  Anchor? beamPoint(Offset pos) {
    final sketch = e.sketch;
    final hit = e.snap ? scene.snap(pos, mode: e.snapMode) : null;
    final plane = sketch?.plane ?? e.plane;
    if (hit != null &&
        (sketch?.reference == null ||
            (hit.point - plane.origin).dot(plane.normal).abs() < .001)) {
      return hit;
    }
    final face = e.faceHover;
    if (sketch == null && face != null) {
      final point = e.camera.onPlane(pos, size, face.plane);
      if (point != null) {
        return Anchor(
          point,
          face.beam.id,
          0,
          face.beam.localAt(point),
          'Грань',
          face.face,
        );
      }
    }
    final point = e.camera.onPlane(pos, size, plane);
    if (point == null) return null;
    return Anchor(
      e.step.enabled
          ? plane.quantize(point, e.step.millimeters(e.project.unit))
          : point,
    );
  }

  StockSketch beginSketch(Anchor start) {
    final ref = e.project.byId[start.beam];
    var plane = e.plane.through(start.point);
    if (ref != null &&
        (e.activeView == ViewAngle.iso ||
            e.activeView == ViewAngle.perspective)) {
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
    if (sticky) {
      final hit = scene.snap(pos, mode: e.snapMode);
      if (hit != null) return hit;
    }
    final surface = scene.hit(pos)?.plane;
    final plane =
        surface ??
        (e.first == null ? e.plane : e.plane.through(e.first!.point));
    final point = e.camera.onPlane(pos, size, plane);
    return point == null ? null : Anchor(point);
  }

  void clickTool(Offset pos) {
    if (e.tool == Tool.gap) {
      hover(pos);
      final target = e.faceHover?.beam;
      if (target == null) return;
      if (e.firstShelf == null) {
        e.firstShelf = target.id;
        e.message = 'Выберите вторую полку';
        e.refresh();
        return;
      }
      if (e.gapPreview == null) {
        e.message =
            'Выберите другую полку с общей проекцией и параллельной гранью';
        e.refresh();
        return;
      }
      final gap = e.gapPreview!;
      e.resetTransient();
      e.message =
          'Просвет · ${e.project.unit.format(gap.length(e.project))} ${e.project.unit.symbol}';
      e.commit(e.project.copy(dimensions: [...e.project.dimensions, gap]));
      return;
    }
    if (e.tool == Tool.align) {
      final target = scene.hit(pos)?.beam;
      if (e.referenceId == null &&
          target != null &&
          target.id != e.single?.id) {
        e.chooseSupport(target.id);
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
      e.message = 'Выберите опору на детали';
      e.refresh();
      return;
    }
    if (e.first == null) {
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
          e.message =
              '${part.name} · ${units.format(part.size.y)} × ${units.format(part.size.z)} ${units.symbol} · укажите конец';
        }
      }
      e.refresh();
      return;
    }
    final start = e.first!,
        from = start.resolve(e.project),
        to = a.resolve(e.project);
    if (from.distanceTo(to) < .001 && e.tool != Tool.move) return;
    switch (e.tool) {
      case Tool.move:
        final next = mate(e.project, e.selection, start, a);
        e.setTool(Tool.select);
        e.commit(next);
      case Tool.beam:
        if (from.distanceTo(to) < 1) return;
        final beam = e.preview;
        if (beam == null) return;
        e.setTool(Tool.select);
        e.selection = {beam.id};
        e.commit(e.project.copy(beams: [...e.project.beams, beam]));
      case Tool.measure:
        e.resetTransient();
        e.commit(
          e.project.copy(
            dimensions: [...e.project.dimensions, Dimension(start, a)],
          ),
        );
      default:
        break;
    }
  }

  Future<void> doubleClick() async {
    final at = doubleClickPosition;
    final kb = HardwareKeyboard.instance;
    if (at == null ||
        e.tool != Tool.select ||
        kb.isAltPressed ||
        kb.isShiftPressed ||
        kb.isSpacePressed) {
      return;
    }
    if (kb.isControlPressed || kb.isMetaPressed) {
      final label = sizeLabel(at), part = e.single;
      if (label == null || part == null) return;
      final box = context.findRenderObject()! as RenderBox;
      final index = label.key.index;
      final value = await editDimensionLabel(
        context,
        part,
        label.key,
        box.localToGlobal(label.value.center),
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
    e.select(partAtPointer.id, individual: true);
    final box = context.findRenderObject()! as RenderBox;
    await showPartProperties(context, e, partAtPointer, box.localToGlobal(at));
  }

  void addPartAt(Offset at) {
    final p = e.camera.onPlane(at, size, e.plane);
    if (p == null) return;
    final origin = e.step.enabled
        ? e.plane.quantize(p, e.step.millimeters(e.project.unit))
        : p;
    final id = e.project.nextId;
    final part = Beam(
      id,
      Beam.defaultName(id),
      origin,
      Vector3(300, StockSketch.defaultWidth, StockSketch.defaultThickness),
      e.plane.u,
      e.plane.v,
    );
    e.resetTransient();
    e.selection = {id};
    e.commit(e.project.copy(beams: [...e.project.beams, part]));
  }

  void start(PointerDownEvent ev) {
    FocusManager.instance.primaryFocus?.unfocus();
    FocusManager.instance.applyFocusChangesIfNeeded();
    pending?.cancel();
    e.guide = null;
    down = last = ev.localPosition;
    buttons = ev.buttons;
    dragged = false;
    before = null;
    moving = {};
    end = null;
    source = null;
    moveSnap = null;
    moveGuides = [];
    modifierClick = null;
    if (buttons != kPrimaryMouseButton || e.tool != Tool.select) return;
    final part = e.single;
    if (part != null &&
        (HardwareKeyboard.instance.isControlPressed ||
            HardwareKeyboard.instance.isMetaPressed) &&
        sizeLabel(down!) != null) {
      return;
    }
    if (part != null && !part.locked(e.resizeAxis)) {
      for (final positive in [false, true]) {
        if ((e.camera.project(faceCenter(part, e.resizeAxis, positive), size) -
                    down!)
                .distance <
            8) {
          end = positive;
          before = e.project;
          moving = {part.id};
          stop = firstContact(part, e.resizeAxis, positive, e.project.beams);
          magnet = EndMagnet();
          alignmentTargets =
              alignedEnds(
                    part,
                    e.resizeAxis,
                    positive,
                    e.project.beams,
                    80 / e.camera.scale,
                  )
                  .where(
                    (t) => stop == null || t.travel <= stop!.travel + .00001,
                  )
                  .toList();
          return;
        }
      }
    }
    final alt = HardwareKeyboard.instance.isAltPressed;
    final hits = <int>{
      for (final f in scene.faces.reversed)
        if (f.path.contains(down!)) f.beam.id,
    }.toList();
    final snapped = e.snap ? scene.snap(down!, mode: e.snapMode) : null;
    final id = alt && hits.isNotEmpty
        ? hits[(hits.indexOf(e.single?.id ?? -1) + 1) % hits.length]
        : hits.firstOrNull ?? snapped?.beam;
    final multi = HardwareKeyboard.instance.isShiftPressed;
    if (!multi &&
        id != null &&
        (HardwareKeyboard.instance.isControlPressed ||
            HardwareKeyboard.instance.isMetaPressed)) {
      modifierClick = id;
    } else if (multi || id == null || !e.selection.contains(id) || alt) {
      e.select(id, multi: multi, individual: alt);
    }
    if (id == null || multi) return;
    before = e.project;
    moving = e.selection.contains(id)
        ? {...e.selection}
        : e.project.assembly(id);
    source = snapped != null && moving.contains(snapped.beam) ? snapped : null;
    final face = scene.hit(down!);
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
    final free =
        (e.step.enabled
            ? plane.quantize(point, e.step.millimeters(initial.unit))
            : point) -
        anchor;
    var delta = free;
    moveGuides = [];
    e.hover = null;
    e.message = '';
    if (sticky) {
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
      final gap = moveGuides.map((g) => g.gap).nonNulls.firstOrNull;
      if (gap != null) {
        e.message =
            'Равные зазоры · ${initial.unit.format(gap)} ${initial.unit.symbol}';
      } else if (moveGuides.isNotEmpty) {
        e.message = 'По краю';
      }
    } else {
      moveSnap!.release();
    }
    e.project = delta.length2 < 1e-14 ? initial : initial.move(moving, delta);
  }

  void move(PointerMoveEvent ev) {
    if (down == null) return;
    final pos = ev.localPosition, delta = pos - last!;
    last = pos;
    if (!dragged &&
        (pos - down!).distance < (buttons == kSecondaryMouseButton ? 5 : 3)) {
      return;
    }
    dragged = true;
    if (buttons == kSecondaryMouseButton) {
      e.camera.yaw -= delta.dx * .009;
      e.camera.pitch = (e.camera.pitch + delta.dy * .008).clamp(-1.54, 1.54);
      e.view = null;
      e.hover = null;
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
    if (e.tool != Tool.select || before == null) return;
    if (end != null) {
      final b = before!.byId[moving.single]!;
      final anchor = faceCenter(b, e.resizeAxis, end!);
      final direction =
          [b.along, b.across, b.up][e.resizeAxis] * (end! ? 1.0 : -1.0);
      final projected =
          e.camera.project(anchor + direction, size) -
          e.camera.project(anchor, size);
      if (projected.distanceSquared < 1e-6) {
        e.message = 'Поверните вид, чтобы видеть направление торца';
        e.refresh();
        return;
      }
      final offset = pos - down!;
      final travel =
          (offset.dx * projected.dx + offset.dy * projected.dy) /
          projected.distanceSquared;
      stretch(b, travel, projected.distance);
    } else if (source != null) {
      if (modifierClick != null && !e.selection.contains(modifierClick)) {
        e.select(modifierClick);
      }
      modifierClick = null;
      moveSnap ??= MoveSnap(before!, moving, e.plane);
      translate(pos);
    }
    e.refresh();
  }

  void finish(PointerUpEvent ev) {
    if (down != null && !dragged && buttons == kSecondaryMouseButton) {
      final at = ev.localPosition;
      unawaited(
        showDrawingMenu(
          context,
          e,
          ev.position,
          partId: scene.hit(at)?.beam.id,
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
    pending?.cancel();
    e.guide = null;
    down = null;
    before = null;
    end = null;
    moveSnap = null;
    moveGuides = [];
    modifierClick = null;
    moving = {};
    e.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        size = box.biggest;
        if (e.fitRequested) {
          e.camera.fit(e.project, size);
          e.fitRequested = false;
        }
        final c = e.camera;
        final sig = (
          e.project,
          e.tool,
          e.referenceId,
          e.alignment,
          e.alignThickness,
          e.manualOffset,
          e.rotationAxis,
          e.localRotation,
          e.angle,
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
        if (signature != sig) {
          cached = Scene(
            e.tool == Tool.align ? e.project : e.displayed,
            c,
            size,
          );
          signature = sig;
        }
        final placement = e.previewPlacement, option = e.visibleAlignment;
        return MouseRegion(
          cursor: e.tool == Tool.select
              ? SystemMouseCursors.basic
              : SystemMouseCursors.precise,
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
              pending?.cancel();
              moveSnap = null;
              moveGuides = [];
              modifierClick = null;
              e.guide = null;
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
                e.camera.yaw -= ev.panDelta.dx * .009;
                e.camera.pitch = (e.camera.pitch + ev.panDelta.dy * .008).clamp(
                  -1.54,
                  1.54,
                );
                e.view = null;
              } else {
                e.camera.pan += ev.panDelta;
              }
              e.camera.zoom(ev.scale / pinchScale, ev.localPosition, size);
              pinchScale = ev.scale;
              e.refresh();
            },
            child: GestureDetector(
              onDoubleTapDown: e.tool == Tool.select
                  ? (details) => doubleClickPosition = details.localPosition
                  : null,
              onDoubleTap: e.tool == Tool.select ? doubleClick : null,
              child: RepaintBoundary(
                child: CustomPaint(
                  key: const Key('drawing'),
                  size: size,
                  painter: painted = DrawingPainter(
                    scene: scene,
                    selection: e.selection,
                    referenceId: e.firstShelf,
                    alignmentSupport: e.alignmentSupport,
                    gapPreview: e.gapPreview,
                    plane: e.plane,
                    first: e.first,
                    hover: e.hover,
                    preview: placement != null && option != null
                        ? placement.placed(option, e.manualOffset)
                        : e.preview,
                    previewColor: alignmentColors[option] ?? accent,
                    activeFace: e.faceHover,
                    grid: true,
                    dimensionsVisible: e.dimensionsVisible,
                    dimensions:
                        (e.tool != Tool.rotate || e.highlightedSize != null) &&
                        moveGuides.isEmpty,
                    gridStep: 50,
                    overlaps: e.tool == Tool.rotate || e.tool == Tool.align
                        ? scene.project.overlaps
                        : e.overlaps,
                    handleAxis:
                        e.tool == Tool.select &&
                            (e.highlightedSize == null ||
                                e.highlightedSize == e.resizeAxis) &&
                            e.single?.locked(e.resizeAxis) == false
                        ? e.resizeAxis
                        : null,
                    original: e.tool == Tool.rotate ? e.project : null,
                    rotationAxis: e.rotationAxis,
                    rotationBasis: e.rotationBasis,
                    localRotation: e.localRotation && e.single != null,
                    highlightedSize: e.highlightedSize,
                    guide: e.guide,
                    moveGuides: moveGuides,
                    angle: e.angle,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

extension on HardwareKeyboard {
  bool get isSpacePressed => isLogicalKeyPressed(LogicalKeyboardKey.space);
}
