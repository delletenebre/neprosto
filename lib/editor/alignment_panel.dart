import '../l10n/strings.dart';
import 'palette.dart';

import 'package:cupertino_ui/cupertino_ui.dart' as cu;
import 'package:material_ui/material_ui.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart'
    show PhosphorIconsRegular;

import 'controller.dart';
import 'controls.dart';
import 'desktop.dart';
import 'platform_ui.dart';
import 'drawing.dart';
import 'positioning.dart';

class AlignmentPanel extends StatefulWidget {
  const AlignmentPanel(this.editor, {super.key});
  final Editor editor;

  @override
  State<AlignmentPanel> createState() => _AlignmentPanelState();
}

class _AlignmentPanelState extends State<AlignmentPanel> {
  bool valid = true;
  int fieldVersion = 0;
  Editor get e => widget.editor;

  void discardInput() {
    FocusManager.instance.primaryFocus?.unfocus();
    FocusManager.instance.applyFocusChangesIfNeeded();
    setState(() {
      valid = true;
      fieldVersion++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = e.placement;
    final selected = e.hasPlacementChoice ? e.alignment : null;
    final moving = e.single!;
    final dir = p?.direction;
    final dim = dir == null
        ? 1
        : [0, 1, 2].reduce((a, b) => dir[a].abs() >= dir[b].abs() ? a : b);
    final (near, far, datum) = [
      (
        context.strings.leftHand,
        context.strings.rightHand,
        context.strings.leftReferenceEdge,
      ),
      (
        context.strings.frontFacing,
        context.strings.rear,
        context.strings.frontReferenceEdge,
      ),
      (
        context.strings.lower,
        context.strings.upper,
        context.strings.bottomReferenceEdge,
      ),
    ][dim];
    final offset = p == null
        ? 0.0
        : selected == null
        ? p.current
        : p.offset(selected, e.manualOffset);
    final useThickness = p?.alongThickness ?? false;
    final parts = e.project.visibleGeometry.beams;
    return ColoredBox(
      color: context.colors.panel,
      child: ListView(
        primary: false,
        padding: const EdgeInsets.all(15),
        children: [
          Text(
            context.strings.alignment,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text(
            context.strings.movingPart,
            style: TextStyle(fontSize: 12, color: context.colors.muted),
          ),
          const SizedBox(height: controlGap),
          partPicker(
            title: context.strings.chooseThePartToMove,
            selected: moving.id,
            label: moving.name,
            items: [for (final b in parts) (b.id, b.name)],
            change: (id) {
              if (id == moving.id) return;
              discardInput();
              e.select(id, individual: true);
              e.beginAlignment();
            },
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: controlGap,
            runSpacing: toolbarGap,
            children: [
              Text(
                context.strings.referencePart,
                style: TextStyle(fontSize: 12, color: context.colors.muted),
              ),
              Tooltip(
                message:
                    '${context.strings.pickReferenceOnDrawing} · $primaryModifierLabel',
                child: DeskButton(
                  plain: true,
                  active: e.pickingAlignmentSupport,
                  onPressed: () {
                    discardInput();
                    e.beginAlignment(pickReference: true);
                  },
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: toolbarGap,
                    children: [
                      Icon(
                        cu.CupertinoIcons.scope,
                        size: 13,
                        color: context.colors.accent,
                      ),
                      Text(
                        context.strings.onDrawing,
                        style: TextStyle(
                          fontSize: 11,
                          color: context.colors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: controlGap),
          partPicker(
            title: context.strings.chooseReferenceFromList,
            selected: p?.reference.id,
            label: p?.reference.name ?? context.strings.chooseAReference,
            marker: p == null
                ? context.colors.muted
                : context.colors.diagramColor(supportColor),
            items: [
              for (final b in parts)
                if (b.id != moving.id) (b.id, b.name),
            ],
            change: (id) {
              discardInput();
              e.chooseSupport(id);
            },
          ),
          if (p == null)
            Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                context.strings.clickAReferenceInTheDrawingOr,
                style: TextStyle(fontSize: 12, color: context.colors.muted),
              ),
            ),
          if (p != null) ...[
            const SizedBox(height: 9),
            Text(
              context.strings.direction,
              style: TextStyle(fontSize: 12, color: context.colors.muted),
            ),
            const SizedBox(height: 4),
            DeskSegments<bool>(
              useThickness,
              {
                false: context.strings.alongWidth,
                true: context.strings.alongThickness,
              },
              (v) {
                if (v == useThickness) return;
                discardInput();
                e.chooseSupport(p.reference.id, alongThickness: v);
              },
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 44,
              child: CustomPaint(
                painter: _SupportSection(
                  context.colors,
                  p,
                  e.visibleAlignment ?? StockAlignment.offset,
                  selected == null ? p.current : e.manualOffset,
                ),
              ),
            ),
            const SizedBox(height: controlGap),
            DeskSegmentedControl<StockAlignment>(
              value: selected == StockAlignment.offset ? null : selected,
              children: {
                for (final (option, label, icon) in [
                  (
                    StockAlignment.front,
                    context.strings.edgeCaption(near),
                    dim == 0
                        ? PhosphorIconsRegular.alignLeft
                        : PhosphorIconsRegular.alignBottom,
                  ),
                  (
                    StockAlignment.middle,
                    context.strings.centerPoint,
                    dim == 0
                        ? PhosphorIconsRegular.alignCenterHorizontal
                        : PhosphorIconsRegular.alignCenterVertical,
                  ),
                  (
                    StockAlignment.back,
                    context.strings.edgeCaption(far),
                    dim == 0
                        ? PhosphorIconsRegular.alignRight
                        : PhosphorIconsRegular.alignTop,
                  ),
                ])
                  option: MouseRegion(
                    key: ValueKey('align-${option.name}'),
                    onEnter: (_) => e.hoverPlacement(option, true),
                    onExit: (_) => e.hoverPlacement(option, false),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon,
                            size: 18,
                            color: option == selected
                                ? alignmentColors[option]
                                : context.colors.diagramColor(
                                    alignmentColors[option]!,
                                  ),
                          ),
                          const SizedBox(height: 2),
                          SizedBox(
                            height: 24,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                label,
                                softWrap: false,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  height: 1.05,
                                  fontSize: 11,
                                  color: option == selected
                                      ? alignmentColors[option]
                                      : context.colors.diagramColor(
                                          alignmentColors[option]!,
                                        ),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              },
              change: (v) {
                discardInput();
                e.chooseAlignment(v);
              },
            ),
            const SizedBox(height: 9),
            Row(
              spacing: 8,
              children: [
                Expanded(
                  child: Text(
                    context.strings.referenceEdgeOffset(datum),
                    style: TextStyle(fontSize: 12, color: context.colors.ink),
                  ),
                ),
                SizedBox(
                  key: const Key('placement-offset'),
                  width: inspectorFieldWidth,
                  child: ValueBox(
                    offset,
                    (v) => e.chooseAlignment(StockAlignment.offset, offset: v),
                    key: ValueKey((
                      moving.id,
                      p.reference.id,
                      useThickness,
                      fieldVersion,
                    )),
                    signed: true,
                    live: true,
                    onValidityChanged: (v) {
                      if (valid != v) setState(() => valid = v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: controlGap),
            Text(
              valid
                  ? context.strings.flushOffsetHint
                  : context.strings.checkTheExpression,
              style: TextStyle(
                fontSize: 10.5,
                color: valid ? context.colors.muted : context.colors.danger,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            spacing: controlGap,
            children: [
              Expanded(
                child: DeskButton(
                  plain: true,
                  onPressed: () {
                    discardInput();
                    e.setTool(Tool.select);
                  },
                  child: Text(context.strings.cancel),
                ),
              ),
              Expanded(
                child: DeskButton(
                  primary: true,
                  onPressed:
                      valid &&
                          e.hasPlacementChoice &&
                          e.alignmentDelta.abs() > 1e-7
                      ? () {
                          discardInput();
                          e.applyAlignment();
                        }
                      : null,
                  child: Text(context.strings.apply),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget partPicker({
    required String title,
    required String label,
    required int? selected,
    required List<(int, String)> items,
    required ValueChanged<int> change,
    Color? marker,
  }) => DeskMenu<int>(
    title: title,
    selected: selected,
    items: items,
    change: change,
    child: Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: context.colors.field,
        border: Border.all(color: context.colors.line),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        spacing: controlGap,
        children: [
          if (marker != null)
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: marker, shape: BoxShape.circle),
            ),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: context.colors.ink),
            ),
          ),
          Icon(
            cu.CupertinoIcons.chevron_down,
            size: 12,
            color: context.colors.muted,
          ),
        ],
      ),
    ),
  );
}

class _SupportSection extends CustomPainter {
  final StockPlacement placement;
  final StockAlignment alignment;
  final double manual;
  final EditorPalette colors;
  _SupportSection(this.colors, this.placement, this.alignment, this.manual);
  @override
  void paint(Canvas canvas, Size size) {
    final p = placement,
        support = p.far - p.near,
        offset = p.offset(alignment, manual);
    final low = offset < 0 ? offset : 0.0,
        high = offset + p.width > support ? offset + p.width : support;
    final scale = (size.width - 56) / (high - low);
    double x(double v) => 50 + (v - low) * scale;
    final pen = Paint()..color = colors.line;
    for (final n in [0.0, support]) {
      canvas.drawLine(Offset(x(n), 3), Offset(x(n), 41), pen);
    }
    void strip(String text, double y, double a, double b, Color color) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(fontSize: 10, color: color),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(canvas, Offset(0, y - 1));
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTRB(x(a), y, x(b), y + 13),
        const Radius.circular(2),
      );
      canvas.drawRRect(rect, Paint()..color = color.withValues(alpha: .18));
      canvas.drawRRect(
        rect,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke,
      );
    }

    strip(
      editorStrings.part,
      6,
      offset,
      offset + p.width,
      colors.diagramColor(alignmentColors[alignment]!),
    );
    strip(
      editorStrings.anchor,
      26,
      0,
      support,
      colors.diagramColor(supportColor),
    );
  }

  @override
  bool shouldRepaint(_SupportSection old) => true;
}
