import '../l10n/strings.dart';
import 'palette.dart';
import 'desktop.dart';
import 'platform_ui.dart';

import 'package:cupertino_ui/cupertino_ui.dart' as cu;
import 'package:material_ui/material_ui.dart';

import 'assembly.dart';
import 'joint.dart';
import 'alignment_panel.dart';
import 'joint_dialog.dart';
import 'end_cut_dialog.dart';
import 'rabbet_dialog.dart';
import 'hole_dialog.dart';
import 'parts_workbook.dart' show stockCut;
import 'controller.dart';
import 'hotkeys.dart';
import 'controls.dart';
import 'drawing.dart';
import 'finish_picker.dart';
import 'model.dart';
import 'stock_axis.dart';

class Inspector extends StatelessWidget {
  final Editor e;
  final VoidCallback rename;
  const Inspector(this.e, {required this.rename, super.key});
  List<String> get dimensions => [
    for (final axis in StockAxis.values) axis.label,
  ];
  Widget block(
    BuildContext context,
    String title,
    List<Widget> children, {
    double spacing = 0,
  }) => Container(
    padding: macControls
        ? const EdgeInsets.fromLTRB(12, 10, 12, 10)
        : const EdgeInsets.fromLTRB(15, 14, 15, 13),
    decoration: BoxDecoration(
      border: Border(bottom: BorderSide(color: context.colors.line)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        sectionTitle(title),
        const SizedBox(height: 10),
        Column(
          spacing: spacing,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ],
    ),
  );
  Widget drawingHelp(BuildContext context, List<Widget> rows) => macControls
      ? _DrawingHelp(rows)
      : block(context, context.strings.drawingControls, rows);

  Widget row(
    BuildContext context,
    String name,
    Widget field, {
    Widget? trailing,
  }) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(
          child: Text(
            name,
            style: TextStyle(fontSize: 12, color: context.colors.muted),
          ),
        ),
        SizedBox(width: inspectorFieldWidth, child: field),
        ?trailing,
      ],
    ),
  );
  Widget lock(int i, Iterable<Beam> beams) {
    final locked = beams.every((b) => b.locked(i));
    return sizeLockButton(StockAxis.values[i], locked, () {
      final ids = beams.map((b) => b.id).toSet();
      e.commit(e.project.edit(ids, (b) => b.withSizeLock(i, !locked)));
    });
  }

  Widget shortcutLabel(BuildContext context, String label, String shortcut) =>
      Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: controlGap,
        children: [
          Text(label),
          Text(
            shortcut,
            style: mono.copyWith(fontSize: 11, color: context.colors.muted),
          ),
        ],
      );

  Widget placementPanel(BuildContext context) => ColoredBox(
    color: context.colors.panel,
    child: ListView(
      key: const ValueKey(Tool.move),
      primary: false,
      padding: const EdgeInsets.all(15),
      children: [
        Row(
          spacing: controlGap,
          children: [
            Icon(
              cu.CupertinoIcons.move,
              size: 18,
              color: context.colors.accent,
            ),
            Expanded(
              child: Text(
                context.strings.placeAgainstReference,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        if (e.selection.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            e.single?.name ?? context.strings.selectedParts(e.selection.length),
            style: TextStyle(fontSize: 13, color: context.colors.muted),
          ),
        ],
        const SizedBox(height: 14),
        Semantics(
          liveRegion: true,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.selectionFill,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              e.first == null
                  ? context.strings.setTheSourceAnchorOnThePart
                  : context.strings.setTheDestinationAnchor,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: context.colors.ink,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        DeskButton(
          onPressed: () => e.setTool(Tool.select),
          child: shortcutLabel(context, context.strings.cancel, 'Esc'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (e.tool == Tool.move) return placementPanel(context);
    final part = e.single, selected = e.selected;
    if (e.tool == Tool.align && part != null) {
      return AlignmentPanel(e, key: ValueKey(part.id));
    }
    final rotatedPart = e.tool == Tool.rotate && part != null
        ? e.displayed.byId[part.id]
        : null;
    final bounds = selected.isEmpty
        ? null
        : Bounds3.points(selected.expand((b) => b.corners));
    final title = part?.name ?? context.strings.selectedParts(selected.length);
    return ColoredBox(
      color: context.colors.panel,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          if (selected.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 15, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.strings.properties,
                    style: TextStyle(fontSize: 12, color: context.colors.muted),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    spacing: toolbarGap,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -.5,
                          ),
                        ),
                      ),
                      if (part != null)
                        iconAction(
                          cu.CupertinoIcons.pencil,
                          context.strings.renamePart,
                          rename,
                          size: 15,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (e.tool == Tool.select && part != null && part.hinge != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 0, 15, 8),
                child: DeskButton(
                  onPressed: () => e.toggleDoor(part.id),
                  child: Text(
                    part.doorOpen
                        ? context.strings.closeDoor
                        : context.strings.openDoor,
                  ),
                ),
              ),
            if (e.tool == Tool.select &&
                part != null &&
                e.project.visibleGeometry.beams.length > 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 0, 15, 12),
                child: DeskButton(
                  onPressed: e.beginAlignment,
                  icon: const Icon(cu.CupertinoIcons.scope),
                  label: Text(context.strings.alignToReference),
                ),
              ),
            const Divider(height: 1),
          ],
          if (selected.length == 2 && e.tool != Tool.rotate)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: DeskButton(
                icon: const Icon(cu.CupertinoIcons.triangle, size: 16),
                label: Text(context.strings.miterJointMenu),
                onPressed: () => showPartJoint(context, e),
              ),
            ),
          if (part != null && part.bevelled)
            block(context, context.strings.endMarkings, [
              for (final end in [false, true])
                Text(
                  '${end ? context.strings.endPoint : context.strings.start} · ${stockCut(part, end)}',
                  style: const TextStyle(fontSize: 12),
                ),
              const SizedBox(height: 5),
              Text(
                context.strings.edges(
                  (edgeLengths(
                    part,
                  ).map(e.project.unit.format).toSet().toList()).join(' / '),
                  e.project.unit.symbol,
                ),
                style: mono,
              ),
            ]),
          if (e.tool == Tool.rotate) ...[
            block(context, context.strings.rotation, [
              if (rotatedPart != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      for (final axis in StockAxis.values)
                        Expanded(
                          child: MouseRegion(
                            onEnter: (_) => e.markSize(axis.index, true),
                            onExit: (_) => e.markSize(axis.index, false),
                            child: Builder(
                              builder: (_) {
                                final p = rotatedPart;
                                final dir = [
                                  p.along,
                                  p.across,
                                  p.up,
                                ][axis.index];
                                final axes = [
                                  for (var i = 0; i < 3; i++)
                                    if (dir[i].abs() > .00001) 'XYZ'[i],
                                ].join();
                                return Tooltip(
                                  message: '${axis.label} · $axes',
                                  child: Text(
                                    '${axis.letter} · $axes',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: context.colors.diagramColor(
                                        axis.color,
                                      ),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              if (part != null)
                MenuChoice<bool>(
                  selected: e.localRotation,
                  label: e.localRotation
                      ? context.strings.partAxes
                      : context.strings.projectAxes,
                  items: [
                    (false, context.strings.projectAxes),
                    (true, context.strings.partAxes),
                  ],
                  change: (v) {
                    e.localRotation = v;
                    e.chooseRotationAxis(e.rotationAxis);
                  },
                ),
              DeskSegments(
                e.rotationAxis,
                e.localRotation && part != null
                    ? {
                        0: context.strings.length,
                        1: context.strings.width,
                        2: context.strings.thickness,
                      }
                    : const {2: 'XY', 1: 'XZ', 0: 'YZ'},
                e.chooseRotationAxis,
              ),
              Row(
                spacing: controlGap,
                children: [
                  Text(
                    context.strings.corner,
                    style: TextStyle(fontSize: 12, color: context.colors.muted),
                  ),
                  Expanded(
                    flex: 3,
                    child: ValueBox(
                      e.angle,
                      e.setAngle,
                      key: const Key('angle'),
                      unit: '°',
                      signed: true,
                      live: true,
                      onSubmitted: e.applyRotation,
                    ),
                  ),
                  for (final (delta, label) in const [
                    (-90, '−90°'),
                    (90, '+90°'),
                  ])
                    Expanded(
                      flex: 2,
                      child: DeskButton(
                        plain: true,
                        onPressed: () => e.setAngle(e.angle + delta),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(label),
                        ),
                      ),
                    ),
                ],
              ),
              DeskButton(
                primary: true,
                onPressed: e.canApplyRotation ? e.applyRotation : null,
                child: Text(context.strings.apply),
              ),
              DeskButton(
                plain: true,
                onPressed: () => e.setTool(Tool.select),
                child: Text(context.strings.cancel),
              ),
            ], spacing: controlGap),
          ] else if (part != null) ...[
            block(context, context.strings.partDimensions, [
              for (var i = 0; i < 3; i++)
                StockSizeRow(
                  e,
                  StockAxis.values[i],
                  ValueBox(
                    part.size[i],
                    (v) {
                      if (v < part.minimumSize(i)) {
                        e.message = v < part.minimumHoleSize(i)
                            ? context.strings.invalidHole
                            : i == 0
                            ? context.strings.lengthTooShortForCuts
                            : context.strings.invalidRabbet;
                        e.refresh();
                        return;
                      }
                      e.commit(
                        e.project.edit({
                          part.id,
                        }, (b) => b.copy(size: b.size.clone()..[i] = v)),
                      );
                    },
                    key: ValueKey('size-${part.id}-$i'),
                    enabled: !part.locked(i),
                  ),
                  trailing: lock(i, [part]),
                ),
              const SizedBox(height: 5),
              DeskButton(
                icon: const Icon(cu.CupertinoIcons.triangle, size: 15),
                label: Text(context.strings.endCutsTitle),
                onPressed: () => showEndCuts(context, e, part),
              ),
              const SizedBox(height: 5),
              DeskButton(
                icon: const Icon(cu.CupertinoIcons.crop, size: 15),
                label: Text(context.strings.rabbetTitle),
                onPressed: () => showRabbets(context, e, part),
              ),
              const SizedBox(height: 5),
              DeskButton(
                icon: const Icon(cu.CupertinoIcons.circle, size: 15),
                label: Text(context.strings.panelHoles),
                onPressed: () => showPanelHoles(context, e, part),
              ),
            ]),
            block(context, context.strings.partFinish, [
              PartFinishButton(part.finish, (finish) {
                if (e.project.byId[part.id] == part) {
                  e.commit(
                    e.project.edit({part.id}, (b) => b.copy(finish: finish)),
                  );
                }
              }, key: ValueKey(part.id)),
            ]),
          ] else if (bounds != null) ...[
            block(context, context.strings.assemblyDimensions, [
              for (var i = 0; i < 3; i++)
                row(
                  context,
                  [
                    context.strings.xWidth,
                    context.strings.yDepth,
                    context.strings.zHeight,
                  ][i],
                  ValueBox(bounds.high[i] - bounds.low[i], (v) {
                    final result = resizeAssembly(
                      e.project,
                      e.selection,
                      axis(i),
                      v,
                    );
                    e.message = result.error ?? '';
                    if (result.error != null) {
                      e.refresh();
                    } else {
                      e.commit(result.project);
                    }
                  }, key: ValueKey('extent-$i')),
                ),
            ]),
            block(context, context.strings.partLocks, [
              for (var i = 0; i < 3; i++)
                Row(
                  children: [
                    Expanded(child: Text(dimensions[i])),
                    lock(i, selected),
                  ],
                ),
            ], spacing: controlGap),
          ],
          if (e.tool != Tool.rotate && bounds != null) ...[
            FocusTraversalGroup(
              policy: WidgetOrderTraversalPolicy(),
              child: block(context, context.strings.position, [
                for (var i = 0; i < 3; i++)
                  row(
                    context,
                    'XYZ'[i],
                    ValueBox(
                      (part?.origin ?? bounds.low)[i],
                      (v) {
                        e.commit(
                          e.project.move(
                            e.selection,
                            axis(i) * (v - (part?.origin ?? bounds.low)[i]),
                          ),
                        );
                      },
                      signed: true,
                      onFocusChanged: (focused) =>
                          e.focusPositionAxis(i, focused),
                      key: ValueKey('position-$i'),
                    ),
                  ),
                const SizedBox(height: 6),
                DeskButton(
                  onPressed: () => e.setTool(Tool.move),
                  icon: const Icon(cu.CupertinoIcons.move, size: 15),
                  label: shortcutLabel(
                    context,
                    context.strings.placeAgainstReference,
                    e.hotkeys[Command.move].label,
                  ),
                ),
                const SizedBox(height: 5),
                DeskButton(
                  onPressed: () => e.setTool(Tool.rotate),
                  icon: const Icon(cu.CupertinoIcons.arrow_clockwise, size: 17),
                  label: Text(context.strings.rotate),
                ),
              ]),
            ),
          ],
          if (e.tool != Tool.rotate && selected.isEmpty)
            drawingHelp(context, [
              for (final (icon, label, shortcut) in [
                (
                  cu.CupertinoIcons.list_bullet,
                  context.strings.actionsMenu,
                  context.strings.rightClick,
                ),
                (
                  cu.CupertinoIcons.arrow_clockwise,
                  context.strings.orbitView,
                  context.strings.dragWithRightButton,
                ),
                (
                  cu.CupertinoIcons.hand_raised,
                  context.strings.panView,
                  context.strings.spaceLeftClick,
                ),
                (
                  cu.CupertinoIcons.zoom_in,
                  context.strings.zoom,
                  context.strings.scrollGesture(primaryModifierLabel),
                ),
                if (!e.rulerActive)
                  (
                    cu.CupertinoIcons.resize,
                    e.dimensionsByDefault
                        ? context.strings.hideDimensions
                        : context.strings.showDimensions,
                    context.strings.hold(e.hotkeys[Command.dimensions].label),
                  ),
              ])
                Padding(
                  padding: EdgeInsets.symmetric(vertical: macControls ? 4 : 6),
                  child: Row(
                    children: [
                      if (!macControls) ...[
                        Icon(icon, size: 15, color: context.colors.muted),
                        const SizedBox(width: 7),
                      ],
                      Expanded(
                        child: Text(
                          label,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          shortcut,
                          textAlign: TextAlign.end,
                          style: mono.copyWith(
                            fontSize: 10,
                            color: context.colors.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ]),
          if (e.overlaps.isNotEmpty)
            block(context, context.strings.intersections, [
              for (final b in e.project.beams.where(
                (b) => e.overlaps.contains(b.id),
              ))
                DeskButton(
                  plain: true,
                  onPressed: () => e.select(b.id, individual: true),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(b.name),
                  ),
                ),
            ], spacing: toolbarGap),
        ],
      ),
    );
  }
}

class _DrawingHelp extends StatefulWidget {
  const _DrawingHelp(this.rows);
  final List<Widget> rows;

  @override
  State<_DrawingHelp> createState() => _DrawingHelpState();
}

class _DrawingHelpState extends State<_DrawingHelp> {
  bool expanded = true;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        height: 35,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        alignment: AlignmentDirectional.centerStart,
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: context.colors.line, width: .7),
          ),
        ),
        child: Text(
          context.strings.properties,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 2),
        child: Semantics(
          expanded: expanded,
          child: DeskControl(
            onPressed: () => setState(() => expanded = !expanded),
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
            child: Row(
              children: [
                Icon(
                  expanded
                      ? cu.CupertinoIcons.chevron_down
                      : cu.CupertinoIcons.chevron_right,
                  size: 10,
                  color: context.colors.muted,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    context.strings.drawingControls,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: context.colors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      if (expanded)
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 12, 10),
          child: Column(children: widget.rows),
        ),
    ],
  );
}
