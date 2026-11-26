part of 'hole_dialog.dart';

String _edgeLabel(BuildContext context, DoorHinge side) => switch (side) {
  DoorHinge.left => context.strings.fromLeft,
  DoorHinge.right => context.strings.fromRight,
  DoorHinge.top => context.strings.fromTop,
  DoorHinge.bottom => context.strings.fromBottom,
};

class _BoltBoreDraft {
  _BoltBoreDraft(LengthInput input, double thickness, [BoltBore? saved])
    : enabled = saved != null,
      diameter = LengthEditingController(input, saved?.diameter ?? 8),
      offset = LengthEditingController(
        input,
        saved?.faceOffset ?? thickness / 2,
      );
  bool enabled;
  final LengthEditingController diameter, offset;

  BoltBore? get value {
    final bit = diameter.millimeters, z = offset.millimeters;
    return enabled && bit != null && z != null
        ? (diameter: bit, faceOffset: z)
        : null;
  }

  void dispose() {
    diameter.dispose();
    offset.dispose();
  }
}

class _BoringMeasurements extends StatelessWidget {
  const _BoringMeasurements({
    required this.unit,
    required this.centerDistance,
    required this.diameterField,
    required this.centerField,
    required this.rimField,
    required this.bolt,
    required this.onChanged,
    required this.depthField,
    this.belowDimensions,
    this.reference,
    this.faceField,
    required this.finishDepth,
    this.diameter,
    this.depth,
    this.rim,
    this.linkedAction,
    this.errors = const {},
  });
  final LengthUnit unit;
  final double? centerDistance, diameter, depth, rim;
  final _BoltBoreDraft bolt;
  final VoidCallback onChanged;
  final Widget? linkedAction;
  final Widget diameterField, centerField, rimField;
  final Widget depthField;
  final Widget? reference, belowDimensions, faceField;
  final VoidCallback finishDepth;
  final Map<String, String?> errors;
  @override
  Widget build(BuildContext context) {
    String format(double? value) {
      if (value == null) return '—';
      final projectValue = '${unit.format(value)} ${unit.symbol}';
      return unit == LengthUnit.inch
          ? '$projectValue (${LengthUnit.millimeter.format(value)} ${context.strings.mm})'
          : projectValue;
    }

    final s = context.strings, colors = context.colors;
    final scaler = MediaQuery.textScalerOf(context);
    final center = centerDistance;
    final caption = TextStyle(color: colors.muted, fontSize: 12);
    final valueStyle = TextStyle(
      color: colors.ink,
      fontSize: 13,
      fontWeight: FontWeight.w600,
    );
    final border = BorderSide(color: colors.line, width: .75);

    Widget measure(String label, double? value, Widget field) {
      final error = errors[label];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: 4,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  label,
                  style: error == null
                      ? caption
                      : caption.copyWith(color: colors.danger),
                ),
              ),
              if (error != null)
                Tooltip(
                  message: error,
                  child: Icon(
                    Icons.warning_amber_rounded,
                    size: 14,
                    color: colors.danger,
                  ),
                ),
            ],
          ),
          Semantics(label: label, child: field),
          if (unit == LengthUnit.inch)
            Text(
              value == null
                  ? '—'
                  : '${LengthUnit.millimeter.format(value)} ${s.mm}',
              style: caption.copyWith(fontSize: 11),
            ),
        ],
      );
    }

    final dimensions = [
      measure(s.boreCenterDistance, center, centerField),
      measure(s.boreRimDistance, rim, rimField),
    ];
    void toggle(bool enabled) {
      bolt.enabled = enabled;
      onChanged();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final textScale = scaler.scale(12) / 12;
        final depthInHeader =
            width >= 365 * textScale && unit != LengthUnit.inch;
        final stop = SelectableText.rich(
          TextSpan(
            style: caption,
            children: [
              TextSpan(text: '${s.boltBoreDepth}  '),
              TextSpan(text: format(center), style: valueStyle),
            ],
          ),
        );
        final boltInputs = [
          measure(
            s.holeDiameter,
            bolt.diameter.millimeters,
            DraftLengthField(
              bolt.diameter,
              onChanged,
              key: const ValueKey('cup-bolt-diameter'),
            ),
          ),
          measure(
            s.boltFaceOffset,
            bolt.offset.millimeters,
            DraftLengthField(
              bolt.offset,
              onChanged,
              key: const ValueKey('cup-bolt-offset'),
            ),
          ),
        ];
        final divider = Divider(color: colors.line, height: 1, thickness: .75);
        Widget fieldRow(List<Widget> cells, {Widget? leading}) => Row(
          spacing: 10,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ?leading,
            for (final cell in cells) Expanded(child: cell),
          ],
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            _DrillDisclosure(
              onClose: finishDepth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: [
                  fieldRow([
                    measure(s.holeDiameter, diameter, diameterField),
                    measure(s.rabbetDepth, depth, depthField),
                  ]),
                  ?faceField,
                ],
              ),
            ),
            if (reference != null)
              Text(
                s.boringReferenceEdge,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            fieldRow(dimensions, leading: reference),
            ?belowDimensions,
            if (linkedAction != null)
              linkedAction!
            else
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.panel,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.fromBorderSide(border),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      MergeSemantics(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          excludeFromSemantics: true,
                          onTap: () => toggle(!bolt.enabled),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 28),
                            child: Row(
                              spacing: 8,
                              children: [
                                Expanded(
                                  child: Text(
                                    s.boltBoreOption,
                                    style: valueStyle,
                                  ),
                                ),
                                if (bolt.enabled && depthInHeader)
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth: width * .46,
                                    ),
                                    child: stop,
                                  ),
                                DeskSwitch(
                                  value: bolt.enabled,
                                  onChanged: toggle,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (bolt.enabled) ...[
                        const SizedBox(height: 5),
                        divider,
                        const SizedBox(height: 8),
                        fieldRow(boltInputs),
                        if (!depthInHeader) ...[
                          const SizedBox(height: 6),
                          stop,
                        ],
                        const SizedBox(height: 3),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _DrillDisclosure extends StatefulWidget {
  const _DrillDisclosure({required this.child, required this.onClose});
  final Widget child;
  final VoidCallback onClose;
  @override
  State<_DrillDisclosure> createState() => _DrillDisclosureState();
}

class _DrillDisclosureState extends State<_DrillDisclosure> {
  bool expanded = false;
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colors.line, width: .75),
        borderRadius: BorderRadius.circular(7),
        color: colors.panel,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            expanded: expanded,
            child: DeskControl(
              key: const ValueKey('drilling-disclosure'),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              onPressed: () {
                if (expanded) widget.onClose();
                setState(() => expanded = !expanded);
              },
              child: Row(
                children: [
                  Icon(
                    expanded ? Icons.expand_more : Icons.chevron_right,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      context.strings.drillingParameters,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 10),
              child: widget.child,
            ),
        ],
      ),
    );
  }
}

class _EdgeBoringDialog extends StatefulWidget {
  const _EdgeBoringDialog({
    required this.part,
    required this.unit,
    required this.side,
    required this.edge,
    required this.back,
    required this.firstAtMax,
    required this.existing,
    required this.edgeHoles,
  });

  final Beam part;
  final LengthUnit unit;
  final DoorHinge side;
  final PanelEdge edge;
  final bool back, firstAtMax;
  final List<PanelHole> existing;
  final List<EdgeHole> edgeHoles;

  @override
  State<_EdgeBoringDialog> createState() => _EdgeBoringState();
}

class _EdgeBoringState extends State<_EdgeBoringDialog> {
  // Hardware dimensions are independent of the editor's movement increment.
  late final LengthInput input = (unit: widget.unit, increment: null);
  late final diameter = LengthEditingController(input, 35);
  late final rim = LengthEditingController(input, 5);
  late final center = LengthEditingController(
    input,
    rim.millimeters! + diameter.millimeters! / 2,
  );
  late final depth = _HoleDepth(input, 13 < size.z ? 13 : null, size.z);
  late final bolt = _BoltBoreDraft(input, size.z);
  bool fromCenter = false;
  bool get blind => depth.blind;

  // Changing the bit preserves the last distance entered at the machine.
  void syncOffsets() {
    final bit = diameter.millimeters;
    final source = fromCenter ? center : rim;
    final target = fromCenter ? rim : center;
    final value = source.millimeters;
    target.setMillimeters(
      value == null || bit == null || bit <= 0
          ? null
          : value + (fromCenter ? -bit : bit) / 2,
    );
  }

  late final endMargin = widget.unit == LengthUnit.inch
      ? 4 * widget.unit.factor
      : 100.0;
  late final first = LengthEditingController(input, endMargin),
      last = LengthEditingController(input, endMargin);
  Vector3 get size => widget.part.size;
  double get length => widget.edge.length(size);
  late final count = TextEditingController(
    text: switch (length) {
      <= 750 => '2',
      <= 1500 => '3',
      <= 2100 => '4',
      _ => '5',
    },
  );

  @override
  void dispose() {
    bolt.dispose();
    for (final field in [diameter, center, rim, depth, first, last, count]) {
      field.dispose();
    }
    super.dispose();
  }

  ({List<PanelHole> holes, String? error}) layout(double? distance, int? n) {
    final s = context.strings;
    final bit = diameter.millimeters, maxDiameter = math.min(size.x, size.y);
    if (bit == null || bit <= 0 || bit > maxDiameter) {
      return (
        holes: const [],
        error: s.holeDiameterRange(
          '${input.unit.format(maxDiameter)} ${input.unit.symbol}',
        ),
      );
    }
    final radius = bit / 2;
    if (distance == null ||
        distance < 0 ||
        widget.edge.width(size) < distance + bit) {
      return (holes: const [], error: s.boreOutsidePanel);
    }
    final drillDepth = blind ? depth.millimeters : null;
    if (blind &&
        (drillDepth == null || drillDepth <= 0 || drillDepth >= size.z)) {
      return (
        holes: const [],
        error: s.holeDepthRange(
          '${input.unit.format(size.z)} ${input.unit.symbol}',
        ),
      );
    }
    if (n == null || n < 1) return (holes: const [], error: s.enterBoreCount);
    final shaft = bolt.value;
    if (bolt.enabled &&
        shaft?.fitsSection(size.z, drillDepth ?? size.z) != true) {
      return (holes: const [], error: s.boltBoreInvalid);
    }
    final spacing = math.max(bit, shaft?.diameter ?? 0.0);
    final start = first.millimeters, end = n == 1 ? 0.0 : last.millimeters;
    if (start == null ||
        end == null ||
        start < spacing / 2 ||
        start > length - spacing / 2 ||
        (n > 1 && end < spacing / 2)) {
      return (holes: const [], error: s.boreEndMarginsInvalid);
    }
    final step = n == 1 ? 0.0 : (length - start - end) / (n - 1);
    if (n > 1 && step < spacing) {
      return (holes: const [], error: s.boreSpacingInvalid);
    }
    final holes = <PanelHole>[];
    final existing = [
      for (final h in widget.existing) ...h.drills(size),
      for (final h in widget.edgeHoles) ...h.drills(size),
    ];
    for (var i = 0; i < n; i++) {
      final isLast = n > 1 && i == n - 1;
      final offset = isLast ? end : start + i * step;
      final fromMax = isLast != widget.firstAtMax;
      final edge = widget.edge;
      final center = distance + radius;
      final hole = PanelHole(
        edge.alongWidth ? center : offset,
        edge.alongWidth ? offset : center,
        bit,
        fromEnd: edge.alongWidth ? edge.atMax : fromMax,
        fromFarEdge: edge.alongWidth ? fromMax : edge.atMax,
        back: widget.back,
        depth: drillDepth,
        boringEdge: edge,
        boltBore: shaft,
      );
      if (hole.drills(size).any((drill) => existing.any(drill.intersects))) {
        return (holes: const [], error: s.boreCollision);
      }
      holes.add(hole);
    }
    return (holes: holes, error: null);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final caption = TextStyle(fontSize: 12, color: context.colors.muted);
    final distance = rim.millimeters;
    final n = int.tryParse(count.text.trim());
    final result = layout(distance, n);
    Widget field(String label, Widget child) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 4,
      children: [
        Text(label, style: caption),
        Semantics(label: label, child: child),
      ],
    );
    Widget lengthInput(
      String key,
      LengthEditingController c, [
      VoidCallback? sync,
    ]) => DraftLengthField(
      c,
      () => setState(() => sync?.call()),
      key: ValueKey(key),
    );
    return DeskDialog(
      maxWidth: 520,
      title: Text(s.edgeBoringTitle),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: 10,
        children: [
          _BoringMeasurements(
            unit: widget.unit,
            centerDistance: center.millimeters,
            rim: distance,
            diameter: diameter.millimeters,
            diameterField: lengthInput('cup-diameter', diameter, syncOffsets),
            depth: depth.millimeters,
            bolt: bolt,
            onChanged: () => setState(() {}),
            centerField: lengthInput('cup-center', center, () {
              fromCenter = true;
              syncOffsets();
            }),
            rimField: lengthInput('cup-rim', rim, () {
              fromCenter = false;
              syncOffsets();
            }),
            depthField: _depthField(depth, 'cup-depth', () => setState(() {})),
            finishDepth: () {
              if (depth.finish()) setState(() {});
            },
            belowDimensions: _BoreRowPlan(
              side: widget.side,
              panelSize: size,
              edge: widget.edge,
              diameter: diameter.millimeters,
              center: center.millimeters,
              start: first.millimeters,
              end: last.millimeters,
              count: n,
              blind: blind,
              bolt: bolt.value,
              unit: widget.unit,
            ),
          ),
          field(
            s.boreCount,
            DeskTextField(
              key: const ValueKey('cup-count'),
              controller: count,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
          ),
          Text(
            s.boreEndOffsets,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Row(
            spacing: 12,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: field(
                  widget.side.onSide ? s.fromTop : s.fromLeft,
                  lengthInput('cup-first', first),
                ),
              ),
              if (n != 1)
                Expanded(
                  child: field(
                    widget.side.onSide ? s.fromBottom : s.fromRight,
                    lengthInput('cup-last', last),
                  ),
                ),
            ],
          ),
          if (result.holes.length > 1)
            Text(
              s.boreCenterPitch(
                '${widget.unit.format((length - first.millimeters! - last.millimeters!) / (result.holes.length - 1))} ${widget.unit.symbol}',
              ),
              style: caption,
            ),
          if (result.error case final error?)
            Text(
              error,
              style: TextStyle(fontSize: 12, color: context.colors.danger),
            ),
        ],
      ),
      actions: [
        DeskButton(
          plain: true,
          onPressed: () => Navigator.pop(context),
          child: Text(s.cancel),
        ),
        DeskButton(
          primary: true,
          onPressed: result.error == null
              ? () => Navigator.pop(context, result.holes)
              : null,
          child: Text(s.addBoreRow),
        ),
      ],
    );
  }
}
