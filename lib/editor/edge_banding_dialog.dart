import 'package:material_ui/material_ui.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart'
    show PhosphorIconsRegular;

import '../l10n/strings.dart';
import 'controller.dart';
import 'controls.dart';
import 'desk_text_field.dart';
import 'desktop.dart';
import 'finish_picker.dart';
import 'model.dart';
import 'palette.dart';
import 'part_finish.dart';
import 'step.dart';

Future<EdgeBanding?> editEdgeBanding(
  BuildContext context,
  Beam part,
  LengthUnit unit,
) async {
  if (!part.supportsEdgeBanding) return null;
  return showDeskDialog<EdgeBanding>(
    context: context,
    // Keep the edge labels in the installed orientation while a door is open.
    builder: (_) => _BandingDialog(
      part.doorOpen && part.hinge != null ? part.swingDoor(1) : part,
      unit,
    ),
  );
}

Future<void> showEdgeBanding(
  BuildContext context,
  Editor editor,
  Beam part,
) async {
  final result = await editEdgeBanding(context, part, editor.displayUnit);
  if (context.mounted &&
      result != null &&
      result != part.banding &&
      editor.project.byId[part.id] == part) {
    editor.commit(
      editor.project.edit({part.id}, (b) => b.copy(banding: result)),
    );
  }
}

class EdgeBandingButton extends StatelessWidget {
  const EdgeBandingButton(this.part, this.unit, this.onPressed, {super.key});
  final Beam part;
  final LengthUnit unit;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final band = part.banding;
    return DeskButton(
      onPressed: onPressed,
      child: Row(
        spacing: controlGap,
        children: [
          if (band.edges.isEmpty)
            const Icon(PhosphorIconsRegular.boundingBox, size: 15)
          else
            Container(
              width: 16,
              height: 12,
              decoration: BoxDecoration(
                color: Color(0xff000000 | band.rgb),
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: context.colors.line),
              ),
            ),
          Expanded(
            child: Text(
              context.strings.edgeBanding,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (band.edges.isNotEmpty)
            Text(
              '${unit.format(band.thickness)} ${unit.symbol} · ${band.edges.length}/4',
              style: TextStyle(fontSize: 12, color: context.colors.muted),
            ),
          const Icon(PhosphorIconsRegular.caretDown, size: 13),
        ],
      ),
    );
  }
}

class _BandingDialog extends StatefulWidget {
  const _BandingDialog(this.part, this.unit);
  final Beam part;
  final LengthUnit unit;

  @override
  State<_BandingDialog> createState() => _BandingDialogState();
}

class _BandingDialogState extends State<_BandingDialog> {
  late final band = widget.part.banding;
  late final edges = {...band.edges};
  late int rgb = edges.isEmpty ? widget.part.finish.rgb : band.rgb;
  late final hex = TextEditingController(text: hexColor(rgb));
  bool validColor = true;
  late final LengthInput input = (unit: widget.unit, increment: null);
  late final thickness = LengthEditingController(
    input,
    edges.isEmpty ? 1 : band.thickness,
  );
  late bool automaticWidth = band.width == null;
  late final width = LengthEditingController(
    input,
    band.width ?? widget.part.size.z,
  );
  late final panelWidth = TextEditingController(
    text: input.format(widget.part.size.z),
  );

  bool get validSize =>
      EdgeBanding.validSize(thickness.millimeters) &&
      (automaticWidth || EdgeBanding.validSize(width.millimeters));
  bool get ready => edges.isEmpty || validColor && validSize;

  @override
  void dispose() {
    hex.dispose();
    thickness.dispose();
    width.dispose();
    panelWidth.dispose();
    super.dispose();
  }

  void apply() {
    if (!ready) return;
    Navigator.pop(
      context,
      edges.isEmpty
          ? const EdgeBanding.none()
          : EdgeBanding(
              edges: edges,
              rgb: rgb,
              thickness: thickness.millimeters!,
              width: automaticWidth ? null : width.millimeters,
            ),
    );
  }

  void toggleEdge(PanelEdge edge) => setState(() {
    if (!edges.remove(edge)) edges.add(edge);
  });

  Widget widthMode() {
    final s = context.strings;
    void toggle() => setState(() => automaticWidth = !automaticWidth);
    return Tooltip(
      message: s.matchPanelThickness,
      child: MergeSemantics(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: toggle,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 4,
            children: [
              Checkbox.adaptive(
                key: const ValueKey('band-auto-width'),
                value: automaticWidth,
                activeColor: EditorPalette.highlight,
                checkColor: EditorPalette.onHighlight,
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: (_) => toggle(),
              ),
              Text(s.automatic, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    return DeskDialog(
      maxWidth: 440,
      title: Text('${s.edgeBanding} · ${widget.part.name}'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                s.bandingEdges,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Wrap(
                spacing: controlGap,
                children: [
                  DeskButton(
                    plain: true,
                    onPressed: edges.length == PanelEdge.values.length
                        ? null
                        : () => setState(() => edges.addAll(PanelEdge.values)),
                    child: Text(s.bandWholePerimeter),
                  ),
                  DeskButton(
                    plain: true,
                    onPressed: edges.isEmpty
                        ? null
                        : () => setState(edges.clear),
                    child: Text(s.deselectAllEdges),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          _EdgeDiagram(
            part: widget.part,
            edges: edges,
            rgb: rgb,
            toggle: toggleEdge,
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 12,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: controlGap,
                  children: [
                    Text('${s.bandThickness}, ${widget.unit.symbol}'),
                    DeskTextField(
                      controller: thickness,
                      onChanged: (_) => setState(thickness.edited),
                      onSubmitted: (_) => apply(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: controlGap,
                  children: [
                    Text('${s.bandWidth}, ${widget.unit.symbol}'),
                    Row(
                      spacing: controlGap,
                      children: [
                        Expanded(
                          child: DeskTextField(
                            controller: automaticWidth ? panelWidth : width,
                            enabled: !automaticWidth,
                            style: automaticWidth
                                ? TextStyle(
                                    fontSize: 13,
                                    color: context.colors.muted,
                                  )
                                : null,
                            cupertinoDecoration: automaticWidth
                                ? BoxDecoration(
                                    color: context.colors.chrome,
                                    border: Border.all(
                                      color: context.colors.line,
                                    ),
                                    borderRadius: BorderRadius.circular(5),
                                  )
                                : null,
                            onChanged: (_) => setState(width.edited),
                            onSubmitted: (_) => apply(),
                          ),
                        ),
                        widthMode(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!validSize)
            Text(
              s.positiveBandSize,
              style: TextStyle(color: context.colors.danger),
            ),
          const SizedBox(height: 14),
          FinishColorPicker(
            label: s.edgeBandColor,
            selectedRgb: rgb,
            hex: hex,
            valid: validColor,
            apply: apply,
            onText: (text) => setState(() {
              final value = parseHexColor(text);
              validColor = value != null;
              if (value != null) rgb = value;
            }),
            onSelect: (value) => setState(() {
              rgb = value;
              hex.text = hexColor(value);
              validColor = true;
            }),
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
          onPressed: ready ? apply : null,
          child: Text(s.apply),
        ),
      ],
    );
  }
}

class _EdgeDiagram extends StatelessWidget {
  const _EdgeDiagram({
    required this.part,
    required this.edges,
    required this.rgb,
    required this.toggle,
  });

  final Beam part;
  final Set<PanelEdge> edges;
  final int rgb;
  final ValueChanged<PanelEdge> toggle;

  Widget target(
    BuildContext context,
    PanelEdge edge,
    Alignment side,
    Rect bounds,
  ) {
    final selected = edges.contains(edge);
    final colors = context.colors;
    final label = part.bandingEdgeLabel(edge);
    final marker = Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? EditorPalette.highlight : colors.field,
        border: Border.all(color: selected ? colors.accent : colors.muted),
      ),
      child: Icon(
        selected ? PhosphorIconsRegular.check : PhosphorIconsRegular.plus,
        size: 12,
        color: selected ? EditorPalette.onHighlight : colors.muted,
      ),
    );
    final name = Flexible(
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          color: selected ? colors.ink : colors.muted,
        ),
      ),
    );
    final before = side == Alignment.topCenter || side == Alignment.centerLeft;
    return Positioned.fromRect(
      rect: bounds,
      child: Tooltip(
        message: label,
        excludeFromSemantics: true,
        child: Semantics(
          toggled: selected,
          child: DeskControl(
            key: ValueKey('band-${edge.name}'),
            onPressed: () => toggle(edge),
            child: Align(
              alignment: -side,
              child: Flex(
                direction: side.x == 0 ? Axis.vertical : Axis.horizontal,
                mainAxisSize: MainAxisSize.min,
                spacing: 4,
                children: before ? [name, marker] : [marker, name],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final layout = part.bandingLayout;
    final colors = context.colors;
    final aspect = layout.top.length(part.size) / layout.left.length(part.size);
    BorderSide border(PanelEdge edge) => edges.contains(edge)
        ? BorderSide(color: Color(0xff000000 | rgb), width: 4)
        : BorderSide(color: colors.muted);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.paper,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.line),
      ),
      child: LayoutBuilder(
        builder: (_, box) {
          final width = box.maxWidth;
          final panel = applyBoxFit(
            BoxFit.contain,
            Size(aspect.clamp(.65, 3), 1),
            Size(width * .51, 108),
          ).destination;
          final margin = MediaQuery.textScalerOf(context).scale(12) + 24;
          final height = panel.height + 2 * margin;
          final rect = Rect.fromCenter(
            center: Offset(width / 2, height / 2),
            width: panel.width,
            height: panel.height,
          );
          // Targets meet at the corners. Their markers sit directly on the edge.
          const radius = 9.0;
          final left = rect.left - radius, right = rect.right + radius;
          final top = rect.top + radius, bottom = rect.bottom - radius;
          return SizedBox(
            height: height,
            child: Stack(
              children: [
                Positioned.fromRect(
                  rect: rect,
                  child: Container(
                    key: const ValueKey('band-panel'),
                    decoration: BoxDecoration(
                      color: Color(0xff000000 | part.finish.rgb),
                      border: Border(
                        top: border(layout.top),
                        right: border(layout.right),
                        bottom: border(layout.bottom),
                        left: border(layout.left),
                      ),
                    ),
                    foregroundDecoration: BoxDecoration(
                      border: Border.all(
                        color: colors.muted.withValues(alpha: .7),
                        width: .75,
                      ),
                    ),
                  ),
                ),
                target(
                  context,
                  layout.top,
                  Alignment.topCenter,
                  Rect.fromLTRB(left, 0, right, top),
                ),
                target(
                  context,
                  layout.left,
                  Alignment.centerLeft,
                  Rect.fromLTRB(3, top, rect.left + radius, bottom),
                ),
                target(
                  context,
                  layout.right,
                  Alignment.centerRight,
                  Rect.fromLTRB(rect.right - radius, top, width - 3, bottom),
                ),
                target(
                  context,
                  layout.bottom,
                  Alignment.bottomCenter,
                  Rect.fromLTRB(left, bottom, right, height),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
