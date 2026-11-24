import '../l10n/strings.dart';
import 'palette.dart';
import 'platform_ui.dart';

import 'package:cupertino_ui/cupertino_ui.dart' as cu;

import 'desktop.dart';
import 'desk_text_field.dart';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart'
    show PhosphorIconsRegular;

import 'controller.dart';
import 'hotkeys.dart';
import 'controls.dart';
import 'drawing.dart';
import 'model.dart';
import 'part_menu.dart';
import 'size_dialog.dart';

class PartsPanel extends StatefulWidget {
  final Editor editor;
  final VoidCallback showPartsList;
  final ValueChanged<List<Vector3>> centerOn;
  const PartsPanel(
    this.editor, {
    required this.showPartsList,
    required this.centerOn,
    super.key,
  });
  @override
  State<PartsPanel> createState() => _PartsPanelState();
}

class _PartsPanelState extends State<PartsPanel> {
  final collapsedGroups = <int?>{};
  Object? hoveredDimensionId;
  Editor get e => widget.editor;

  Widget partControl(Beam b, {required Widget child}) {
    void select([SerialTapUpDetails? tap]) {
      FocusManager.instance.primaryFocus?.unfocus();
      FocusManager.instance.applyFocusChangesIfNeeded();
      if (e.pickingAlignmentSupport) {
        e.chooseSupport(b.id);
        return;
      }
      if (e.tool == Tool.rotate || e.tool == Tool.align) {
        e.setTool(Tool.select);
      }
      final k = HardwareKeyboard.instance;
      final multi = k.isShiftPressed || k.isMetaPressed || k.isControlPressed;
      if (tap != null && tap.count == 2 && !multi && !k.isAltPressed) {
        e.select(b.id, individual: true);
        final part = e.single;
        if (part != null && part.id == b.id) {
          showPartProperties(context, e, part, tap.globalPosition);
        }
      } else {
        e.select(b.id, multi: multi, individual: k.isAltPressed);
      }
    }

    return DeskControl(
      onPressed: b.hidden ? null : select,
      child: RawGestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        gestures: {
          if (!b.hidden && !e.pickingAlignmentSupport)
            SerialTapGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<
                  SerialTapGestureRecognizer
                >(
                  () => SerialTapGestureRecognizer(
                    allowedButtonsFilter: (buttons) =>
                        buttons == kPrimaryButton,
                  ),
                  (recognizer) => recognizer.onSerialTapUp = select,
                ),
        },
        child: child,
      ),
    );
  }

  Widget item(Beam b) {
    final active = e.selection.contains(b.id);
    return Padding(
      key: ValueKey(b.id),
      padding: const EdgeInsets.only(bottom: 2),
      child: GestureDetector(
        onSecondaryTapUp: (details) =>
            showDrawingMenu(context, e, details.globalPosition, partId: b.id),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: active ? context.selectionFill : Colors.transparent,
            borderRadius: BorderRadius.circular(5),
          ),
          child: _PartVisibilityRow(
            hasHiddenParts: b.hidden,
            showHiddenIndicator: true,
            tooltip: b.hidden
                ? context.strings.showPart
                : context.strings.hidePart,
            toggleVisibility: () => e.setPartsHidden({b.id}, !b.hidden),
            onCenter: b.hidden && !e.showHiddenOutlines
                ? null
                : () {
                    if (!b.hidden) {
                      if (e.tool != Tool.select) e.setTool(Tool.select);
                      e.select(b.id, individual: true);
                    }
                    widget.centerOn(b.corners);
                  },
            trailing: Expanded(
              child: partControl(
                b,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    4,
                    macControls ? 3 : 6,
                    7,
                    macControls ? 3 : 6,
                  ),
                  child: Row(
                    spacing: toolbarGap,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: b.hidden
                                    ? context.colors.disabled
                                    : context.colors.ink,
                                fontWeight: active
                                    ? FontWeight.w600
                                    : (macControls
                                          ? FontWeight.w400
                                          : FontWeight.w500),
                              ),
                            ),
                            Text(
                              '${e.project.unit.format(b.size.x)} × ${e.project.unit.format(b.size.y)} × ${e.project.unit.format(b.size.z)}',
                              style: mono.copyWith(
                                fontSize: 10,
                                color: b.hidden
                                    ? context.colors.disabled
                                    : context.colors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (e.overlaps.contains(b.id))
                        Tooltip(
                          message: context.strings.intersection,
                          child: Icon(
                            cu.CupertinoIcons.exclamationmark_triangle,
                            size: 15,
                            color: context.colors.danger,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget groupHeader(int? id, List<Beam> members) {
    final hasHidden = members.any((b) => b.hidden);
    final collapsed = collapsedGroups.contains(id);
    final title = id == null
        ? context.strings.assemblyParts
        : e.project.groupNames[id] ?? context.strings.numberedGroup(id);
    return _PartVisibilityRow(
      key: ValueKey('group-header-$id'),
      hasHiddenParts: hasHidden,
      tooltip: hasHidden
          ? context.strings.showGroupParts
          : context.strings.hideGroupParts,
      toggleVisibility: () =>
          e.setPartsHidden({for (final b in members) b.id}, !hasHidden),
      leading: Expanded(
        child: _EditableTitle(
          title: title,
          tooltip: context.strings.renameGroup,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: context.colors.muted,
          ),
          rename: id == null
              ? null
              : (name) {
                  final project = e.project;
                  e.commit(
                    project.copy(groupNames: {...project.groupNames, id: name}),
                  );
                },
          child: Semantics(
            expanded: !collapsed,
            child: DeskControl(
              minimumSize: const Size(0, 28),
              onPressed: () => setState(() {
                if (collapsed) {
                  collapsedGroups.remove(id);
                } else {
                  collapsedGroups.add(id);
                }
              }),
              child: Row(
                children: [
                  Container(
                    width: 29,
                    alignment: Alignment.center,
                    child: Icon(
                      collapsed
                          ? cu.CupertinoIcons.chevron_right
                          : cu.CupertinoIcons.chevron_down,
                      size: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      trailing: Padding(
        padding: const EdgeInsets.only(left: 4, right: 12),
        child: Text(
          '${members.length}',
          style: mono.copyWith(color: context.colors.muted),
        ),
      ),
    );
  }

  Widget dimensionRow(Project p, Dimension d, int index) {
    final geometry = d.geometry(p);
    final title =
        d.name ??
        '${d.clearance ? context.strings.clearance : context.strings.dimension} ${index + 1}';
    final selected = e.selectedDimension == d;
    final rowId = e.dimensionRowId(d);
    return Semantics(
      key: ObjectKey(rowId),
      selected: selected,
      child: MouseRegion(
        onEnter: (_) => setState(() => hoveredDimensionId = rowId),
        onExit: (_) {
          if (hoveredDimensionId == rowId) {
            setState(() => hoveredDimensionId = null);
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => e.selectDimension(d),
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: selected ? context.selectionFill : Colors.transparent,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _EditableTitle(
                  title: title,
                  showActions: selected || hoveredDimensionId == rowId,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: context.colors.ink,
                  ),
                  tooltip: context.strings.renameDimension,
                  onCenter:
                      geometry == null ||
                          p.byId[d.a.beam]?.hidden == true ||
                          p.byId[d.b.beam]?.hidden == true
                      ? null
                      : () {
                          e.selectDimension(d);
                          widget.centerOn([geometry.from, geometry.to]);
                        },
                  trailing: iconAction(
                    cu.CupertinoIcons.xmark,
                    context.strings.deleteDimension,
                    () => e.removeDimension(d),
                    size: 14,
                  ),
                  rename: (name) => e.updateDimension(d, d.copy(name: name)),
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: controlGap),
                if (geometry != null)
                  Row(
                    children: [
                      Expanded(
                        child: ValueBox(
                          geometry.from.distanceTo(geometry.to),
                          (v) =>
                              e.updateDimension(d, d.withLength(e.project, v)),
                          enabled: !d.locked && geometry.direction.length2 > 0,
                        ),
                      ),
                      const SizedBox(width: 6),
                      dimensionLockButton(
                        title,
                        d.locked,
                        () => e.updateDimension(d, d.copy(locked: !d.locked)),
                      ),
                    ],
                  )
                else
                  Text(context.strings.noOverlappingProjection, style: mono),
                const Divider(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groups = <int?, List<Beam>>{};
    for (final b in e.project.beams) {
      (groups[b.group] ??= []).add(b);
    }
    final p = e.project;
    final measures = e.rulerActive;
    final addLabel = measures
        ? context.strings.newDimension
        : context.strings.newPart;
    final sections = DeskSegments(
      measures,
      {
        false: context.strings.partsTabCount(p.beams.length),
        true: context.strings.dimensionTabCount(p.dimensions.length),
      },
      (v) {
        if (v != measures) e.setTool(v ? Tool.ruler : Tool.select);
      },
    );
    void add() => e.setTool(measures ? Tool.measure : Tool.beam);
    final addTip = '$addLabel · ${e.hotkeys[Command.add].label}';
    return ColoredBox(
      color: context.colors.chrome,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (macControls)
            Container(
              constraints: const BoxConstraints(minHeight: 35),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: context.colors.line, width: .7),
                ),
              ),
              child: Row(
                children: [
                  Expanded(child: sections),
                  DeskIcon(cu.CupertinoIcons.plus, addTip, add, size: 15),
                ],
              ),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 13, 10, 10),
              child: sections,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 10, 8),
              child: Tooltip(
                message: addTip,
                child: DeskButton(
                  onPressed: add,
                  icon: const Icon(cu.CupertinoIcons.plus, size: 16),
                  label: Text(addLabel),
                ),
              ),
            ),
          ],
          if (e.tool == Tool.measure || e.tool == Tool.gap)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 10, 8),
              child: DeskSegments(e.tool, {
                Tool.measure: context.strings.twoPoints,
                Tool.gap: context.strings.clearance,
              }, e.setTool),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: measures
                  ? [
                      for (final (i, d) in p.dimensions.indexed)
                        dimensionRow(p, d, i),
                    ]
                  : [
                      for (final entry in groups.entries) ...[
                        groupHeader(entry.key, entry.value),
                        const SizedBox(height: toolbarGap),
                        if (!collapsedGroups.contains(entry.key))
                          ...entry.value.map(item),
                      ],
                    ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: macControls
                ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
                : const EdgeInsets.fromLTRB(12, 8, 10, 0),
            child: DeskButton(
              plain: macControls,
              onPressed: widget.showPartsList,
              icon: const Icon(cu.CupertinoIcons.list_bullet, size: 16),
              label: Text(context.strings.partsList),
            ),
          ),
          if (!measures && (!macControls || e.selection.isNotEmpty))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              child: Row(
                spacing: toolbarGap,
                children: [
                  iconAction(
                    cu.CupertinoIcons.square_stack,
                    context.strings.groupLabel,
                    e.canGroup ? e.group : null,
                  ),
                  iconAction(
                    cu.CupertinoIcons.rectangle_on_rectangle_angled,
                    context.strings.ungroup,
                    e.canUngroup ? e.ungroup : null,
                  ),
                  const Spacer(),
                  iconAction(
                    cu.CupertinoIcons.doc_on_doc,
                    context.strings.duplicate,
                    e.selection.isEmpty ? null : e.duplicate,
                  ),
                  iconAction(
                    cu.CupertinoIcons.trash,
                    context.strings.delete,
                    e.selection.isEmpty ? null : e.delete,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _EditableTitle extends StatefulWidget {
  const _EditableTitle({
    required this.title,
    required this.tooltip,
    required this.style,
    required this.child,
    this.rename,
    this.showActions = false,
    this.onCenter,
    this.trailing,
  });
  final String title, tooltip;
  final bool showActions;
  final TextStyle style;
  final Widget child;
  final Widget? trailing;
  final ValueChanged<String>? rename;
  final VoidCallback? onCenter;

  @override
  State<_EditableTitle> createState() => _EditableTitleState();
}

class _EditableTitleState extends State<_EditableTitle> {
  final input = TextEditingController();
  bool hovered = false, editing = false;

  void start() {
    final title = widget.title;
    input.value = TextEditingValue(
      text: title,
      selection: TextSelection(baseOffset: 0, extentOffset: title.length),
    );
    setState(() => editing = true);
  }

  void finish({bool save = true}) {
    if (!editing || !mounted) return;
    setState(() => editing = false);
    final name = input.text.trim();
    if (save && name.isNotEmpty && name != widget.title) {
      widget.rename?.call(name);
    }
  }

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final actionsVisible = hovered || widget.showActions;
    return MouseRegion(
      onEnter: (_) => setState(() => hovered = true),
      onExit: (_) => setState(() => hovered = false),
      child: editing
          ? Focus(
              onFocusChange: (focused) {
                if (!focused) finish();
              },
              onKeyEvent: (_, event) {
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.escape) {
                  finish(save: false);
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: DeskTextField(
                controller: input,
                autofocus: true,
                style: widget.style.copyWith(color: context.colors.ink),
                onSubmitted: (_) => finish(),
              ),
            )
          : Row(
              spacing: toolbarGap,
              children: [
                Expanded(
                  child: DefaultTextStyle.merge(
                    style: widget.style,
                    child: widget.child,
                  ),
                ),
                if (widget.rename != null && actionsVisible)
                  DeskIcon(
                    cu.CupertinoIcons.pencil,
                    widget.tooltip,
                    start,
                    size: 13,
                  ),
                if (actionsVisible && widget.onCenter != null)
                  DeskIcon(
                    PhosphorIconsRegular.crosshair,
                    context.strings.centerCamera,
                    widget.onCenter,
                    size: 15,
                  ),
                ?widget.trailing,
              ],
            ),
    );
  }
}

class _PartVisibilityRow extends StatefulWidget {
  const _PartVisibilityRow({
    super.key,
    required this.hasHiddenParts,
    this.showHiddenIndicator = false,
    this.onCenter,
    required this.tooltip,
    required this.toggleVisibility,
    this.leading,
    required this.trailing,
  });

  final bool hasHiddenParts, showHiddenIndicator;
  final String tooltip;
  final VoidCallback toggleVisibility;
  final VoidCallback? onCenter;
  final Widget? leading;
  final Widget trailing;

  @override
  State<_PartVisibilityRow> createState() => _PartVisibilityRowState();
}

class _PartVisibilityRowState extends State<_PartVisibilityRow> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => hovered = true),
    onExit: (_) => setState(() => hovered = false),
    child: Row(
      spacing: toolbarGap,
      children: [
        ?widget.leading,
        Stack(
          alignment: Alignment.center,
          children: [
            if (macControls &&
                widget.showHiddenIndicator &&
                !hovered &&
                !widget.hasHiddenParts)
              Icon(
                cu.CupertinoIcons.cube,
                size: 14,
                color: context.colors.muted,
              ),
            Visibility(
              visible:
                  hovered ||
                  (widget.showHiddenIndicator && widget.hasHiddenParts),
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              maintainSemantics: true,
              child: DeskIcon(
                widget.hasHiddenParts
                    ? (hovered
                          ? cu.CupertinoIcons.eye
                          : PhosphorIconsRegular.eyeClosed)
                    : PhosphorIconsRegular.eyeSlash,
                widget.tooltip,
                widget.toggleVisibility,
                size: 18,
                foreground: hovered ? null : context.colors.disabled,
              ),
            ),
          ],
        ),
        widget.trailing,
        if (widget.onCenter != null)
          Visibility(
            visible: hovered,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: DeskIcon(
              PhosphorIconsRegular.crosshair,
              context.strings.centerCamera,
              widget.onCenter,
              size: 15,
            ),
          ),
      ],
    ),
  );
}
