part of 'hole_dialog.dart';

class _EditEdgeHole extends StatefulWidget {
  const _EditEdgeHole(this.part, this.unit, this.original);
  final Beam part;
  final LengthUnit unit;
  final EdgeHole original;
  @override
  State<_EditEdgeHole> createState() => _EditEdgeHoleState();
}

class _EditEdgeHoleState extends State<_EditEdgeHole> {
  EdgeHole get h => widget.original;
  late final LengthInput input = (unit: widget.unit, increment: null);
  late final offset = LengthEditingController(input, h.offset),
      height = LengthEditingController(input, h.height),
      bit = LengthEditingController(input, h.diameter),
      depth = _HoleDepth(input, h.depth, h.edge.width(widget.part.size));
  late bool far = h.fromEnd;
  late DrillDatum? datum = h.datum;
  @override
  void dispose() {
    for (final c in [offset, height, bit, depth]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final pocket = h.kind == EdgeHoleKind.pocket;
    final candidate = (
      edge: h.edge,
      kind: h.kind,
      datum: datum,
      fromEnd: far,
      back: h.back,
      offset: offset.millimeters ?? double.nan,
      height: height.millimeters ?? double.nan,
      diameter: bit.millimeters ?? double.nan,
      depth: depth.millimeters,
    );
    final length = h.edge.length(widget.part.size);
    final start = h.edge.alongWidth ? PanelEdge.near : PanelEdge.start;
    final end = h.edge.alongWidth ? PanelEdge.far : PanelEdge.end;
    final zero = datum == null
        ? Offset(far ? length : 0, pocket && h.back ? widget.part.size.z : 0)
        : Offset(datum!.u, datum!.v);
    final center = Offset(
      candidate.position(widget.part.size),
      pocket && h.back
          ? widget.part.size.z - candidate.height
          : candidate.height,
    );
    final issue = depth.blind && depth.millimeters == null
        ? s.connectionDoesNotFit
        : layoutIssue(widget.part, (faces: [], edges: [candidate]));
    void changed() => setState(() {});
    Widget field(String label, Widget child) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 4,
      children: [Text(label), child],
    );
    return DeskDialog(
      maxWidth: 420,
      title: Text(h.kind.label),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          Text(
            '${widget.part.bandingEdgeLabel(h.edge)} · ${input.format(length)} × ${input.format(widget.part.size.z)} ${input.unit.symbol}',
          ),
          LayoutBuilder(
            builder: (_, box) {
              final thickness = widget.part.size.z;
              final span = math.max(1.0, box.maxWidth - 24);
              final section = Rect.fromLTWH(
                12,
                28,
                span,
                (span * thickness / length).clamp(18, 66),
              );
              final view = Size(box.maxWidth, section.bottom + 25);
              Offset project(Offset p) => Offset(
                section.left + section.width * (p.dx / length).clamp(0, 1),
                section.bottom -
                    section.height * (p.dy / thickness).clamp(0, 1),
              );
              final mark = project(center);
              return SizedBox.fromSize(
                size: view,
                child: Stack(
                  children: [
                    Positioned.fromRect(
                      rect: section,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: context.colors.chrome,
                          border: Border.all(color: context.colors.muted),
                        ),
                      ),
                    ),
                    if (center.dx.isFinite && center.dy.isFinite)
                      Positioned(
                        left: mark.dx - 5,
                        top: mark.dy - 5,
                        child: Icon(
                          PhosphorIconsRegular.crosshair,
                          size: 12,
                          color: context.colors.accent,
                        ),
                      ),
                    _DatumMarker(project(zero), view),
                  ],
                ),
              );
            },
          ),
          if (datum != null && center.dx.isFinite && center.dy.isFinite)
            Text(
              'Δ ${input.format(center.dx - zero.dx)} / ${input.format(center.dy - zero.dy)} ${input.unit.symbol}',
            ),
          DeskSegments(
            far,
            {
              false: widget.part.bandingEdgeLabel(start),
              true: widget.part.bandingEdgeLabel(end),
            },
            (value) => setState(() {
              if (offset.millimeters case final mm? when far != value) {
                offset.setMillimeters(h.edge.length(widget.part.size) - mm);
              }
              far = value;
              datum = null;
            }),
          ),
          field(
            '${s.offset} · ${widget.part.bandingEdgeLabel(far ? end : start)}',
            DraftLengthField(offset, changed),
          ),
          field(
            '${s.boltFaceOffset} · ${pocket && h.back ? s.faceB : s.faceA}',
            DraftLengthField(height, changed),
          ),
          Row(
            spacing: 10,
            children: [
              Expanded(
                child: field(s.holeDiameter, DraftLengthField(bit, changed)),
              ),
              Expanded(
                child: field(
                  pocket ? s.pocketShoulder : s.rabbetDepth,
                  pocket
                      ? DraftLengthField(depth, changed)
                      : _depthField(depth, 'edge-hole-depth', changed),
                ),
              ),
            ],
          ),
          if (issue != null)
            Text(issue, style: TextStyle(color: context.colors.danger)),
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
          onPressed: issue == null
              ? () => Navigator.pop(context, candidate)
              : null,
          child: Text(s.apply),
        ),
      ],
    );
  }
}
