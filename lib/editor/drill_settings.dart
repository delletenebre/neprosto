part of 'hole_dialog.dart';

String _drillSideLabel(Beam part, int face) {
  if (part.supportsEdgeBanding) {
    return face < 4
        ? part.bandingEdgeLabel(PanelEdge.values[face])
        : face == 4
        ? editorStrings.faceA
        : editorStrings.faceB;
  }
  final direction =
      [part.along, part.across, part.up][face ~/ 2] * (face.isOdd ? 1.0 : -1.0);
  if (direction.x.abs() > .9999) {
    return direction.x > 0 ? editorStrings.viewRight : editorStrings.viewLeft;
  }
  if (direction.y.abs() > .9999) {
    return direction.y > 0 ? editorStrings.viewBack : editorStrings.viewFront;
  }
  if (direction.z.abs() > .9999) {
    return direction.z > 0 ? editorStrings.viewTop : editorStrings.viewBottom;
  }
  return '${[editorStrings.length, editorStrings.width, editorStrings.thickness][face ~/ 2]} ${face.isOdd ? '+' : '−'}';
}

class _DrillSettings {
  _DrillSettings(LengthUnit unit, this.ruler, this.datums)
    : input = (unit: unit, increment: null);
  final LengthInput input;
  final ConnectionRuler ruler;
  EdgeHoleKind kind = EdgeHoleKind.openingSensor;
  bool magnet = true;
  bool editRuler = false;
  late final diameter = LengthEditingController(input, 10),
      depth = LengthEditingController(input, 12),
      first = LengthEditingController(input, ruler.first),
      pitch = LengthEditingController(input, ruler.pitch);
  final Map<int, Offset> datums;

  bool get hasDepth => depth.text.trim().isNotEmpty;
  bool get validBit =>
      (diameter.millimeters ?? 0) > 0 &&
      (!hasDepth || (depth.millimeters ?? 0) > 0);
  bool get validGrid =>
      (first.millimeters ?? -1) >= 0 && (pitch.millimeters ?? 0) >= .001;
  void select(EdgeHoleKind value) {
    kind = value;
    diameter.setMillimeters(value == EdgeHoleKind.plain ? 5 : 10);
    depth.setMillimeters(switch (value) {
      EdgeHoleKind.openingSensor => 12,
      EdgeHoleKind.pushToOpen => 50,
      _ => null,
    });
  }

  void dispose() {
    for (final c in [diameter, depth, first, pitch]) {
      c.dispose();
    }
  }
}

class _DrillControls extends StatelessWidget {
  const _DrillControls(this.jig, this.span, this.changed);
  final double span;
  final _DrillSettings jig;
  final VoidCallback changed;

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final presets = [
      (EdgeHoleKind.openingSensor, s.openingSensor),
      (EdgeHoleKind.pushToOpen, 'Push-to-open'),
      (EdgeHoleKind.plain, s.customDrill),
    ];
    Widget field(
      String label,
      LengthEditingController controller,
      String key, {
      String? placeholder,
      VoidCallback? onBlur,
    }) => SizedBox(
      width: 104,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 4,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: context.colors.muted),
          ),
          Semantics(
            label: label,
            child: DraftLengthField(
              controller,
              changed,
              key: ValueKey(key),
              placeholder: placeholder,
              onBlur: onBlur,
            ),
          ),
        ],
      ),
    );
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        MenuChoice<EdgeHoleKind>(
          label: presets.firstWhere((entry) => entry.$1 == jig.kind).$2,
          selected: jig.kind,
          items: presets,
          change: (k) {
            jig.select(k);
            changed();
          },
        ),
        field(s.holeDiameter, jig.diameter, 'drill-diameter'),
        field(
          s.rabbetDepth,
          jig.depth,
          'drill-depth',
          placeholder: s.throughHole,
          onBlur: () {
            if (_finishHoleDepth(jig.depth, span)) changed();
          },
        ),
        DeskButton(
          key: const ValueKey('drill-magnet'),
          active: jig.magnet,
          icon: Icon(PhosphorIconsRegular.magnet),
          label: Text(s.drillMagnet),
          onPressed: () {
            jig.magnet = !jig.magnet;
            changed();
          },
        ),
        if (jig.magnet) ...[
          Tooltip(
            message: s.connectionRuler,
            child: DeskButton(
              key: const ValueKey('drill-ruler'),
              plain: true,
              onPressed: () {
                jig.editRuler = !jig.editRuler;
                changed();
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    jig.editRuler || !jig.validGrid
                        ? s.connectionRuler
                        : '${jig.first.text} + ${jig.pitch.text} ${jig.input.unit.symbol}',
                  ),
                  Icon(
                    jig.editRuler ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          if (jig.editRuler) ...[
            field(s.datumOffset, jig.first, 'drill-inset'),
            field(s.markPitch, jig.pitch, 'drill-pitch'),
          ],
        ],
      ],
    );
  }
}
