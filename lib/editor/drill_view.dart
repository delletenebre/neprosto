part of 'hole_dialog.dart';

/// The two millimetre coordinates stored by a face bore or an edge bore.
/// Project along the drilling axis onto the visible surface, including bevels.
class _DrillSurface {
  _DrillSurface(this.scene, this.face);
  final Scene scene;
  final SceneFace face;
  Beam get part => face.beam;
  int get index => face.face;
  int get normal => index ~/ 2;
  int get u => normal == 0 ? 1 : 0;
  int get v => normal == 2 ? 1 : 2;
  late final basis = [part.along, part.across, part.up];
  Offset? coordinates(Offset pointer) {
    final world = scene.pointOnFace(pointer, face);
    if (world == null) return null;
    final delta = world - part.origin;
    return Offset(delta.dot(basis[u]), delta.dot(basis[v]));
  }

  Offset screen(Offset uv) {
    final p = part.origin + basis[u] * uv.dx + basis[v] * uv.dy;
    final direction = basis[normal];
    final travel =
        face.normal.dot(face.world.first - p) / face.normal.dot(direction);
    return scene.camera.project(p + direction * travel, scene.size);
  }

  Offset defaultDatum(bool far) => normal == 2
      ? Offset.zero
      : Offset(far ? part.size[u] : 0, part.size.z / 2);

  Offset target(Offset raw, _DrillSettings jig, bool far, bool settingZero) {
    if (!jig.magnet) return raw;
    final origin = jig.datums[index];
    final base = origin ?? defaultDatum(far);
    double coordinate(
      double value,
      double span,
      double start,
      bool horizontal,
    ) {
      if (settingZero) {
        // Capture exact midpoints and ends without quantizing a custom datum.
        final unit = horizontal ? const Offset(1, 0) : const Offset(0, 1);
        final pixels = (screen(raw + unit) - screen(raw)).distance;
        final tolerance = math.min(span / 4, 9 / math.max(.001, pixels));
        for (final anchor in [span / 2, 0.0, span]) {
          if ((value - anchor).abs() <= tolerance) return anchor;
        }
        return value;
      }
      if (!jig.validGrid) return value;
      final step = jig.pitch.millimeters!;
      if (origin != null || (!horizontal && normal != 2)) {
        return start + roundToIncrement(value - start, step);
      }
      final ruler = ConnectionRuler(first: jig.first.millimeters!, pitch: step);
      if (span < ruler.first + (jig.diameter.millimeters ?? 0) / 2) {
        return span / 2;
      }
      final reversed = horizontal && normal != 2 && far;
      final snapped = ruler.snap(reversed ? span - value : value);
      return reversed ? span - snapped : snapped;
    }

    return Offset(
      coordinate(raw.dx, part.size[u], base.dx, true),
      coordinate(raw.dy, part.size[v], base.dy, false),
    );
  }

  DrillLayout bore(Offset point, _DrillSettings jig, bool far) {
    final bit = jig.diameter.millimeters!, requested = jig.depth.millimeters;
    final depth = requested != null && requested < part.size[normal]
        ? requested
        : null;
    final zero = jig.datums[index];
    final datum = zero == null ? null : (u: zero.dx, v: zero.dy);
    if (normal == 2) {
      return (
        faces: [
          PanelHole(
            point.dx,
            point.dy,
            bit,
            depth: depth,
            datum: datum,
            back: index.isOdd && (depth != null || datum != null),
            name: jig.kind == EdgeHoleKind.plain ? '' : jig.kind.label,
          ),
        ],
        edges: [],
      );
    }
    return (
      faces: [],
      edges: [
        (
          edge: PanelEdge.values[index],
          kind: jig.kind,
          datum: datum ?? (u: far ? part.size[u] : 0.0, v: part.size.z / 2),
          fromEnd: far,
          back: false,
          offset: far ? part.size[u] - point.dx : point.dx,
          height: point.dy,
          diameter: bit,
          depth: depth,
        ),
      ],
    );
  }

  bool containsBore(Offset point, double radius) {
    if (!part.bevelled && part.rabbets.isEmpty) return true;
    bool onFace(Offset p) {
      final hit = scene.hit(screen(p));
      return hit?.face == index && hit!.isOuterFace;
    }

    return onFace(point) &&
        List.generate(
          32,
          (i) => i * math.pi / 16,
        ).every((angle) => onFace(point + Offset.fromDirection(angle, radius)));
  }
}

typedef _DrillHit = ({
  _DrillSurface surface,
  Offset point,
  DrillLayout? layout,
  String? issue,
});

class _DrillView extends StatefulWidget {
  const _DrillView({
    required this.hotkeys,
    required this.part,
    required this.unit,
    required this.viewBack,
    required this.edge,
    required this.far,
    required this.jig,
    required this.orient,
    required this.historyRevision,
    required this.changeDatum,
    required this.selectView,
    required this.place,
  });
  final Beam part;
  final EditorHotkeys hotkeys;
  final LengthUnit unit;
  final bool viewBack, far;
  final PanelEdge edge;
  final _DrillSettings jig;
  final void Function(Beam part, Object? sequence) orient;
  final int historyRevision;
  final ValueChanged<VoidCallback> changeDatum;
  final ValueChanged<int?> selectView;
  final ValueChanged<DrillLayout> place;
  @override
  State<_DrillView> createState() => _DrillViewState();
}

class _DrillViewState extends State<_DrillView> with TickerProviderStateMixin {
  final camera = Camera();
  late final animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  )..addListener(animate);
  Offset from = Offset.zero, to = Offset.zero;
  Offset? pointer;
  int? aimedFace;
  int? lastFace;
  bool get shift => HardwareKeyboard.instance.isShiftPressed;
  late bool shiftDown = shift;
  bool initialized = false;
  Size? framedSize;
  Vector3? pivot, pinnedPivot;
  late int rotationAxis = widget.part.up.x.abs() > widget.part.up.y.abs()
      ? 1
      : 0;
  ViewAngle? selectedView = ViewAngle.iso;
  double fromRoll = 0;
  bool get pickingPivot =>
      shift &&
      (HardwareKeyboard.instance.isMetaPressed ||
          HardwareKeyboard.instance.isControlPressed);
  bool wasPickingPivot = false, rotating = false;
  bool touchOrbit = false;
  Object? rotationGesture;
  Scene? cached;
  late final stockAnimation =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 260),
        value: 1,
      )..addListener(() {
        setState(() => cached = null);
      });
  double stockDegrees = 0;
  Vector3? stockPivot, stockNormal;
  Vector3 get rotationCenter =>
      pinnedPivot ?? Bounds3.points(widget.part.corners).center;
  void toggleRotation() => setState(() {
    rotating = !rotating;
    pointer = null;
  });
  void rotateStock(double degrees, {bool animate = true, Vector3? around}) {
    final normal = around ?? axis(rotationAxis), center = rotationCenter;
    if (stockAnimation.isAnimating &&
        (stockNormal! - normal).length2 < 1e-8 &&
        (stockPivot! - center).length2 < 1e-8) {
      stockDegrees =
          stockDegrees *
              (1 - Curves.easeInOut.transform(stockAnimation.value)) +
          degrees;
    } else {
      stockDegrees = degrees;
    }
    stockPivot = center;
    stockNormal = normal;
    final project = Project('', [widget.part], const [], widget.unit);
    final next = project
        .rotate({widget.part.id}, normal, degrees, pivot: center)
        .beams
        .single;
    animation.stop();
    setState(() {
      pointer = null;
      aimedFace = lastFace = null;
      cached = null;
    });
    widget.orient(next, animate ? null : rotationGesture);
    if (animate && !MediaQuery.disableAnimationsOf(context)) {
      stockAnimation.forward(from: 0);
    } else {
      stockAnimation.value = 1;
    }
  }

  Future<void> stockMenu(Scene scene, TapUpDetails tap) async {
    final face = scene.hit(tap.localPosition);
    if (face == null || !face.isOuterFace || stockAnimation.isAnimating) return;
    final normal = face.normal.normalized(), down = -axis(2);
    final cos = normal.dot(down).clamp(-1.0, 1.0);
    if (cos > 1 - 1e-9) return;
    final choice = await showDeskPopup(
      context,
      tap.globalPosition,
      title: context.strings.rotatePart,
      rows: [
        DeskPopupRow(
          context.strings.layFaceDown,
          icon: Icons.rotate_90_degrees_ccw,
          symbol: 'rotate.left',
        ),
      ],
    );
    if (!mounted || choice != 0) return;
    var spindle = normal.cross(down);
    if (spindle.length2 < 1e-10) spindle = face.world[1] - face.world.first;
    rotateStock(math.acos(cos) * 180 / math.pi, around: spindle.normalized());
  }

  void chooseView(ViewAngle view) {
    final direction = (Camera()..view(view)).eye;
    final physical = [
      for (var f = 0; f < 6; f++)
        if (widget.part.faceNormal(f).dot(direction) > .9999) f,
    ].firstOrNull;
    setState(() {
      selectedView = view;
      camera.perspective = view == ViewAngle.perspective;
      aimedFace = lastFace = physical;
      turnTo(direction);
    });
    widget.selectView(physical);
  }

  Offset angles(Vector3 direction) {
    final n = direction.normalized();
    return Offset(
      n.x.abs() + n.y.abs() < 1e-8 ? 0 : math.atan2(n.x, -n.y),
      math.asin(n.z.clamp(-1, 1)),
    );
  }

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(keyChanged);
  }

  bool keyChanged(KeyEvent event) {
    if (shift != shiftDown || pickingPivot != wasPickingPivot) {
      setState(() {
        shiftDown = shift;
        wasPickingPivot = pickingPivot;
      });
    }
    if (event is KeyDownEvent &&
        ModalRoute.of(context)?.isCurrent == true &&
        FocusManager.instance.primaryFocus?.context
                ?.findAncestorWidgetOfExactType<EditableText>() ==
            null &&
        !event.synthesized) {
      final chord = chordFor(event);
      if (chord == null) return false;
      if (widget.hotkeys.commandFor(chord) == Command.rotate) {
        toggleRotation();
        return true;
      }
      if (chord.primary || chord.alt || chord.shift) return false;
      final i = [
        LogicalKeyboardKey.keyX,
        LogicalKeyboardKey.keyY,
        LogicalKeyboardKey.keyZ,
      ].indexOf(chord.key);
      if (i >= 0 && (rotating || pinnedPivot != null)) {
        setState(() {
          rotationAxis = i;
          rotating = true;
        });
        return true;
      }
    }
    return false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!initialized) {
      initialized = true;
      camera.view(ViewAngle.iso);
    } else if (MediaQuery.disableAnimationsOf(context) &&
        animation.isAnimating) {
      animation.value = 1;
    }
  }

  @override
  void didUpdateWidget(_DrillView old) {
    super.didUpdateWidget(old);
    cached = null;
    if (widget.historyRevision != old.historyRevision) {
      stockAnimation.value = 1;
      pointer = null;
      lastFace = null;
      rotationGesture = null;
    }
  }

  void turnTo(Vector3 direction) {
    animation.stop();
    from = Offset(camera.yaw, camera.pitch);
    fromRoll = camera.roll;
    final dest = angles(direction);
    final delta = (dest.dx - from.dx + math.pi) % (2 * math.pi) - math.pi;
    to = Offset(from.dx + delta, dest.dy);
    pointer = null;
    framedSize = null;
    cached = null;
    if (MediaQuery.disableAnimationsOf(context)) {
      camera
        ..yaw = to.dx
        ..pitch = to.dy
        ..roll = 0;
    } else {
      animation.forward(from: 0);
    }
  }

  void animate() {
    final orientation = Offset.lerp(
      from,
      to,
      Curves.easeInOutCubic.transform(animation.value),
    )!;
    setState(() {
      camera
        ..yaw = orientation.dx
        ..pitch = orientation.dy
        ..roll =
            fromRoll * (1 - Curves.easeInOutCubic.transform(animation.value));
      framedSize = null;
      cached = null;
    });
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(keyChanged);
    stockAnimation.dispose();
    animation.dispose();
    super.dispose();
  }

  Scene sceneFor(Size viewport) {
    if (cached case final scene? when scene.size == viewport) return scene;
    if (framedSize != viewport) {
      camera.fitPoints(widget.part.corners, viewport);
      // The spatial view needs no margin for external stock dimensions.
      camera.scale *= 1.18;
      framedSize = viewport;
    }
    var project = Project('', [widget.part], const [], widget.unit);
    if (stockAnimation.value < 1 && stockNormal != null) {
      project = project.rotate(
        {widget.part.id},
        stockNormal!,
        stockDegrees * (Curves.easeInOut.transform(stockAnimation.value) - 1),
        pivot: stockPivot,
      );
    }
    return cached = Scene(project, camera.copy(), viewport);
  }

  void beginOrbit(Scene scene, Offset at) {
    rotationGesture = Object();
    final face = scene.hit(at);
    pivot =
        (face == null ? null : scene.pointOnFace(at, face)) ??
        Bounds3.points(widget.part.corners).center;
  }

  void navigate(VoidCallback move) {
    animation.stop();
    setState(() {
      move();
      pointer = null;
      cached = null;
    });
  }

  void orbit(Offset delta) {
    if (delta == Offset.zero) return;
    if (rotating) {
      final normal = axis(rotationAxis);
      final tangent = Offset(normal.dot(camera.up), normal.dot(camera.right));
      final pixels = tangent.distance < .1
          ? delta.dx
          : (delta.dx * tangent.dx + delta.dy * tangent.dy) / tangent.distance;
      rotateStock(pixels * .5, animate: false);
      return;
    }
    navigate(() {
      camera.orbit(delta, pinnedPivot ?? pivot ?? camera.target);
      if (aimedFace != null) widget.selectView(null);
      aimedFace = null;
      selectedView = null;
    });
  }

  bool farFor(int face) => face == widget.edge.faceIndex && widget.far;

  _DrillHit? pick(Scene scene, Offset at) {
    final face = scene.hit(at);
    if (face == null || !face.isOuterFace) return null;
    final surface = _DrillSurface(scene, face);
    final raw = surface.coordinates(at);
    if (raw == null) return null;
    final jig = widget.jig, far = farFor(face.face);
    final point = surface.target(raw, jig, far, shift);
    DrillLayout? layout;
    String? issue;
    if (!shift) {
      if (!jig.validBit) {
        issue = context.strings.connectionDoesNotFit;
      } else if (jig.magnet && !jig.validGrid) {
        issue = context.strings.drillGridInvalid;
      } else {
        layout = surface.bore(point, jig, far);
        issue = layoutIssue(widget.part, layout);
        if (issue == null &&
            !surface.containsBore(point, jig.diameter.millimeters! / 2)) {
          issue = context.strings.connectionDoesNotFit;
        }
      }
    }
    return (surface: surface, point: point, layout: layout, issue: issue);
  }

  void tap(Scene scene, Offset at) {
    if (animation.isAnimating || stockAnimation.isAnimating) return;
    if (pickingPivot) {
      final face = scene.hit(at);
      if (face != null) {
        final point = scene.pointOnFace(at, face);
        if (point != null) setState(() => pinnedPivot = point);
      }
      return;
    }
    if (rotating) {
      final sign = RotationDial.project(
        scene.camera,
        scene.size,
        rotationCenter,
        axis(rotationAxis),
      ).hit(at);
      if (sign != null) rotateStock(sign * 90.0);
      return;
    }
    final hit = pick(scene, at);
    if (hit == null) return;
    setState(() {
      pointer = at;
      lastFace = hit.surface.index;
    });
    if (shift) {
      widget.changeDatum(
        () => widget.jig.datums[hit.surface.index] = hit.point,
      );
    } else if (hit.issue == null && hit.layout != null) {
      widget.place(hit.layout!);
      setState(() => pointer = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings, colors = context.colors, jig = widget.jig;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 6,
      children: [
        Container(
          height: (MediaQuery.sizeOf(context).height * .5).clamp(270, 510),
          decoration: BoxDecoration(
            color: colors.paper,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.line),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (_, box) {
                    final scene = sceneFor(box.biggest);
                    final hit = pointer == null || rotating || pickingPivot
                        ? null
                        : pick(scene, pointer!);
                    final focus =
                        hit?.surface.index ??
                        lastFace ??
                        aimedFace ??
                        (widget.viewBack ? 5 : 4);
                    final visible = scene.faces
                        .where((f) => f.isOuterFace && f.face == focus)
                        .firstOrNull;
                    final surface = visible == null
                        ? null
                        : _DrillSurface(scene, visible);
                    final base = surface == null
                        ? null
                        : jig.datums[focus] ??
                              surface.defaultDatum(farFor(focus));
                    final zero = surface?.screen(base!);
                    final hoveringDatum =
                        zero != null &&
                        pointer != null &&
                        (pointer! - zero).distance <= _DatumMarker.hitRadius;

                    final draw = DrawingPainter(
                      scene: scene,
                      selection: {widget.part.id},
                      dimensions: false,
                      colors: colors,
                      activeFace: rotating ? null : visible,
                      rotationPivot: rotating ? rotationCenter : null,
                      rotationAxis: rotationAxis,
                      rotationBasis: rotating
                          ? [axis(0), axis(1), axis(2)]
                          : null,
                    );
                    String measure(double n) =>
                        '${widget.unit.format(n)} ${widget.unit.symbol}';
                    final delta = hit == null || base == null || hoveringDatum
                        ? null
                        : hit.point - base;
                    return _HoleNavigation(
                      beginOrbit: (at) => beginOrbit(scene, at),
                      orbit: orbit,
                      pan: (delta) => navigate(() => camera.pan += delta),
                      zoom: (factor, focus) => navigate(
                        () => camera.zoom(factor, focus, scene.size),
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: MouseRegion(
                              cursor: rotating
                                  ? SystemMouseCursors.grab
                                  : SystemMouseCursors.precise,
                              onHover: (e) {
                                if (!rotating && !animation.isAnimating) {
                                  setState(() {
                                    pointer = e.localPosition;
                                    lastFace =
                                        scene.hit(pointer!)?.face ?? lastFace;
                                  });
                                }
                              },
                              onExit: (_) {
                                if (mounted && pointer != null) {
                                  setState(() => pointer = null);
                                }
                              },
                              child: GestureDetector(
                                key: const ValueKey('drill-canvas'),
                                behavior: HitTestBehavior.opaque,
                                supportedDevices: const {
                                  PointerDeviceKind.mouse,
                                  PointerDeviceKind.touch,
                                  PointerDeviceKind.stylus,
                                  PointerDeviceKind.invertedStylus,
                                },
                                onTapUp: (e) => tap(scene, e.localPosition),
                                onSecondaryTapUp: (e) => stockMenu(scene, e),
                                onPanStart: (e) {
                                  touchOrbit =
                                      rotating ||
                                      e.kind == PointerDeviceKind.touch;
                                  if (touchOrbit) {
                                    beginOrbit(scene, e.localPosition);
                                  }
                                },
                                onPanUpdate: (e) {
                                  if (touchOrbit) orbit(e.delta);
                                },
                                child: CustomPaint(
                                  painter: draw,
                                  foregroundPainter: _DrillGuides(
                                    colors,
                                    surface,
                                    base,
                                    hoveringDatum ? null : hit,
                                    jig.diameter.millimeters,
                                    shift,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          ViewCube(scene, chooseView),
                          if (!rotating &&
                              zero != null &&
                              (Offset.zero & box.biggest).contains(zero))
                            _DatumMarker(zero, box.biggest),
                          if (pinnedPivot case final pin?) ...[
                            Positioned.fromRect(
                              rect: Rect.fromCircle(
                                center: scene.camera.project(pin, box.biggest),
                                radius: 8,
                              ),
                              child: IgnorePointer(
                                child: Icon(
                                  Icons.gps_fixed,
                                  key: const ValueKey('orbit-pivot'),
                                  size: 16,
                                  color: colors.axisColor(2),
                                ),
                              ),
                            ),
                          ],
                          if (!rotating && pinnedPivot != null)
                            Positioned(
                              left: 6,
                              top: 6,
                              child: DeskIcon(
                                Icons.close,
                                s.clearOrbitPivot,
                                () => setState(() => pinnedPivot = null),
                              ),
                            ),
                          if (delta != null)
                            Positioned(
                              top: pinnedPivot != null ? 44 : 7,
                              left: 8,
                              right: 8,
                              child: IgnorePointer(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: _DrillBadge(
                                    '${_drillSideLabel(widget.part, focus)}   ·   ${surface!.u == 0 ? s.length : s.width} Δ ${measure(farFor(focus) ? -delta.dx : delta.dx)}   ·   ${surface.v == 2 ? s.thickness : s.width} Δ ${measure(delta.dy)}${hit?.issue == null ? '' : '   ·   ${hit!.issue}'}',
                                    error: hit?.issue != null,
                                    key: const ValueKey('drill-distance'),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 0, 6, 5),
                child: Wrap(
                  spacing: toolbarGap,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ViewportViews(
                      selectedView: selectedView,
                      onView: chooseView,
                    ),
                    rotationControl(),
                  ],
                ),
              ),
            ],
          ),
        ),
        Row(
          spacing: 8,
          children: [
            Expanded(
              child: IndexedStack(
                index: rotating ? 1 : 0,
                alignment: AlignmentDirectional.centerStart,
                children: [
                  for (final hint in [
                    '${s.drillHint} · ${s.holeNavigationHint(primaryModifierLabel)}',
                    s.stockTurnHint,
                  ])
                    Text(
                      hint,
                      style: TextStyle(fontSize: 12, color: colors.muted),
                    ),
                ],
              ),
            ),
            DeskIcon(
              Icons.restart_alt,
              s.resetDatum,
              jig.datums.isEmpty
                  ? null
                  : () => widget.changeDatum(jig.datums.clear),
            ),
            DeskIcon(Icons.fit_screen_outlined, s.fitToWindow, () {
              navigate(() => framedSize = null);
            }),
          ],
        ),
      ],
    );
  }

  Widget rotationControl() {
    final planes = ExcludeFocus(
      excluding: !rotating,
      child: ExcludeSemantics(
        excluding: !rotating,
        child: IgnorePointer(
          ignoring: !rotating,
          child: RotationPlanePicker(
            rotationAxis,
            (i) => setState(() => rotationAxis = i),
          ),
        ),
      ),
    );
    const toggleWidth = 30.0;
    Widget button(double progress) => Semantics(
      expanded: rotating,
      child: SizedBox(
        width: toggleWidth,
        child: DeskIcon(
          progress == 1 ? Icons.close : PhosphorIconsRegular.arrowClockwise,
          rotating
              ? context.strings.close
              : context.strings.rotateShortcut(
                  widget.hotkeys[Command.rotate].label,
                ),
          toggleRotation,
          key: const ValueKey('drill-rotation'),
          size: 17 - 4 * progress,
          foreground: Color.lerp(
            context.colors.muted,
            context.colors.ink,
            progress,
          ),
          glyphBuilder: progress > 0 && progress < 1
              ? (color, size) => CustomPaint(
                  key: const ValueKey('rotation-glyph-transition'),
                  size: Size.square(size),
                  painter: _RotationGlyph(
                    progress,
                    color,
                    Directionality.of(context),
                  ),
                )
              : null,
        ),
      ),
    );
    // Lay out the full strip even when closed. The button and canvas then
    // keep their positions when the footer wraps on a narrow window.
    Widget strip(BuildContext context, double progress, Widget? picker) =>
        Stack(
          alignment: Alignment.centerLeft,
          children: [
            Positioned.fill(
              child: LayoutBuilder(
                builder: (_, box) => Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width:
                        toggleWidth + (box.maxWidth - toggleWidth) * progress,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: Color.lerp(null, context.colors.chrome, progress),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                button(progress),
                Flexible(
                  child: ClipRect(
                    child: FractionalTranslation(
                      translation: Offset(progress - 1, 0),
                      child: picker,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
    final target = rotating ? 1.0 : 0.0;
    if (MediaQuery.disableAnimationsOf(context)) {
      return strip(context, target, planes);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(end: target),
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeInOutCubic,
      builder: strip,
      child: planes,
    );
  }
}

/// The shaft straightens into one diagonal. Its two arrowhead strokes spread
/// into the other, keeping their joint on the shaft as it moves to the centre.
class _RotationGlyph extends CustomPainter {
  const _RotationGlyph(this.progress, this.color, this.direction);
  final double progress;
  final Color color;
  final TextDirection direction;

  // Centre lines of the existing Phosphor arrow and Material close glyphs,
  // expressed in the same 24-unit icon box.
  static const radius = 8.25;
  static const crossArm = 6.28;
  static const bottomRight = Offset(12 + crossArm, 12 + crossArm);
  static const topLeft = Offset(12 - crossArm, 12 - crossArm);
  static final shaft = () {
    final start = math.atan2(6, 5.67);
    final path = Path()
      ..addArc(
        const Rect.fromLTWH(12 - radius, 12 - radius, radius * 2, radius * 2),
        start,
        7 * math.pi / 4 - start,
      )
      ..lineTo(21.75, 9.75);
    return path.computeMetrics().single;
  }();

  Offset pointOnShaft(double along) => Offset.lerp(
    shaft.getTangentForOffset(along * shaft.length)!.position,
    Offset.lerp(bottomRight, topLeft, along)!,
    progress,
  )!;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    if (direction == TextDirection.rtl) {
      canvas.translate(24, 0);
      canvas.scale(-1, 1);
    }
    final tail = pointOnShaft(0);
    final line = Path()..moveTo(tail.dx, tail.dy);
    for (var i = 1; i <= 32; i++) {
      final p = pointOnShaft(i / 32);
      line.lineTo(p.dx, p.dy);
    }
    final joint = pointOnShaft(1 - progress / 2);
    final left =
        joint +
        Offset.lerp(
          const Offset(-4.5, 0),
          const Offset(-crossArm, crossArm),
          progress,
        )!;
    final right =
        joint +
        Offset.lerp(
          const Offset(0, -4.5),
          const Offset(crossArm, -crossArm),
          progress,
        )!;
    line
      ..moveTo(left.dx, left.dy)
      ..lineTo(joint.dx, joint.dy)
      ..lineTo(right.dx, right.dy);
    final pen = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 + .5 * progress
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(line, pen);
    // The arrow has round tips, while the close glyph has flat ends.
    pen.style = PaintingStyle.fill;
    for (final tip in [tail, left, right]) {
      canvas.drawCircle(tip, .75 * (1 - progress), pen);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RotationGlyph old) =>
      progress != old.progress ||
      color != old.color ||
      direction != old.direction;
}

/// The marker passes clicks through to the drawing; only its label reacts to hover.
class _DatumMarker extends StatelessWidget {
  const _DatumMarker(this.zero, this.viewport);
  static const hitRadius = 7.0;
  final Offset zero;
  final Size viewport;
  @override
  Widget build(BuildContext context) => _HoverDatumMarker(zero, viewport);
}

class _HoverDatumMarker extends StatefulWidget {
  const _HoverDatumMarker(this.zero, this.viewport);
  final Offset zero;
  final Size viewport;
  @override
  State<_HoverDatumMarker> createState() => _HoverDatumMarkerState();
}

class _HoverDatumMarkerState extends State<_HoverDatumMarker> {
  bool hovered = false;
  @override
  Widget build(BuildContext context) {
    final zero = widget.zero, viewport = widget.viewport;
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            left: zero.dx - _DatumMarker.hitRadius,
            top: zero.dy - _DatumMarker.hitRadius,
            width: _DatumMarker.hitRadius * 2,
            height: _DatumMarker.hitRadius * 2,
            child: MouseRegion(
              opaque: false,
              hitTestBehavior: HitTestBehavior.translucent,
              onEnter: (_) => setState(() => hovered = true),
              onExit: (_) => setState(() => hovered = false),
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    key: const ValueKey('drill-zero-point'),
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: EditorPalette.highlight,
                      border: Border.all(
                        color: EditorPalette.onHighlight,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 3,
                        height: 3,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: EditorPalette.onHighlight,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (hovered)
            Positioned(
              left: zero.dx < viewport.width - 82 ? zero.dx + 6 : null,
              right: zero.dx >= viewport.width - 82
                  ? viewport.width - zero.dx + 6
                  : null,
              top: zero.dy < 24 ? zero.dy + 5 : null,
              bottom: zero.dy >= 24 ? viewport.height - zero.dy + 5 : null,
              child: IgnorePointer(
                child: _DrillBadge(
                  '${context.strings.datum} 0',
                  datum: true,
                  key: const ValueKey('drill-datum'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DrillBadge extends StatelessWidget {
  const _DrillBadge(
    this.text, {
    super.key,
    this.datum = false,
    this.error = false,
  });
  final String text;
  final bool datum, error;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: datum ? EditorPalette.highlight : context.colors.field,
      borderRadius: BorderRadius.circular(4),
      border: Border.all(
        color: error ? context.colors.danger : context.colors.accent,
      ),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: datum
              ? EditorPalette.onHighlight
              : error
              ? context.colors.danger
              : context.colors.ink,
        ),
      ),
    ),
  );
}

class _DrillGuides extends CustomPainter {
  const _DrillGuides(
    this.colors,
    this.surface,
    this.base,
    this.hit,
    this.bit,
    this.settingZero,
  );
  final EditorPalette colors;
  final _DrillSurface? surface;
  final Offset? base;
  final _DrillHit? hit;
  final double? bit;
  final bool settingZero;
  @override
  void paint(Canvas canvas, Size size) {
    final s = surface, origin = base;
    if (s == null || origin == null) return;
    final zero = s.screen(origin);
    final pen = Paint()
      ..color = colors.accent
      ..strokeWidth = 1.5;
    final p = hit;
    if (p != null) {
      final center = s.screen(p.point);
      final corner = s.screen(Offset(p.point.dx, origin.dy));
      canvas.drawLine(zero, corner, pen);
      canvas.drawLine(corner, center, pen);
      pen.color = p.issue == null ? colors.accent : colors.danger;
      final radius = bit == null || bit! <= 0 || !bit!.isFinite
          ? 0.0
          : bit! / 2;
      if (!settingZero && radius > 0) {
        final path = Path()
          ..addPolygon([
            for (var i = 0; i < 40; i++)
              s.screen(
                p.point + Offset.fromDirection(i * math.pi / 20, radius),
              ),
          ], true);
        canvas.drawPath(
          path,
          Paint()..color = pen.color.withValues(alpha: .30),
        );
        canvas.drawPath(path, pen..style = PaintingStyle.stroke);
      }
      canvas.drawCircle(center, 4, pen..style = PaintingStyle.stroke);
      for (final d in [const Offset(8, 0), const Offset(0, 8)]) {
        canvas.drawLine(center - d, center + d, pen);
      }
    }
  }

  @override
  bool shouldRepaint(_DrillGuides old) => true;
}
