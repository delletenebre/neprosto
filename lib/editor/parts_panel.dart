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
import 'part_type_picker.dart';

class PartsPanel extends StatefulWidget {
  final Editor editor;
  final VoidCallback showPartsList;
  final Key? partsListButton;
  final ValueChanged<List<Vector3>> centerOn;
  const PartsPanel(
    this.editor, {
    required this.showPartsList,
    this.partsListButton,
    required this.centerOn,
    super.key,
  });
  @override
  State<PartsPanel> createState() => _PartsPanelState();
}

class _PartsPanelState extends State<PartsPanel> {
  final collapsedGroups = <int?>{};
  Object? hoveredDimensionId;
  int? lastPlainRow;
  Editor get e => widget.editor;

  Widget serialTapTarget(
    Widget child,
    GestureSerialTapUpCallback? onTap,
  ) => RawGestureDetector(
    behavior: HitTestBehavior.opaque,
    excludeFromSemantics: true,
    gestures: {
      if (onTap != null)
        SerialTapGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<SerialTapGestureRecognizer>(
              () => SerialTapGestureRecognizer(
                allowedButtonsFilter: (buttons) => buttons == kPrimaryButton,
              ),
              (recognizer) => recognizer.onSerialTapUp = onTap,
            ),
    },
    child: child,
  );

  Widget item(Beam b) => Padding(
    key: ValueKey(b.id),
    padding: const EdgeInsets.only(bottom: 2),
    child: Builder(builder: (row) => partRow(row, b)),
  );

  Widget partRow(BuildContext row, Beam b) {
    final active = e.selection.contains(b.id);
    void select([SerialTapUpDetails? tap]) {
      final k = HardwareKeyboard.instance;
      final multi = k.isShiftPressed || k.isMetaPressed || k.isControlPressed;
      final plainClick = tap != null && !multi && !k.isAltPressed;
      final doubleClick = plainClick && tap.count > 1 && lastPlainRow == b.id;
      lastPlainRow = plainClick && !doubleClick ? b.id : null;
      if (b.hidden) {
        if (doubleClick && e.showHiddenOutlines) widget.centerOn(b.corners);
        return;
      }
      FocusManager.instance.primaryFocus?.unfocus();
      FocusManager.instance.applyFocusChangesIfNeeded();
      if (e.pickingAlignmentSupport) {
        e.chooseSupport(b.id);
      } else if (doubleClick) {
        if (e.tool != Tool.select) e.setTool(Tool.select);
        e.select(b.id, individual: true);
        widget.centerOn(b.corners);
      } else {
        if (e.tool == Tool.rotate || e.tool == Tool.align) {
          e.setTool(Tool.select);
        }
        e.select(b.id, multi: multi, individual: k.isAltPressed);
      }
    }

    return GestureDetector(
      onSecondaryTapUp: (details) => showDrawingMenu(
        context,
        e,
        details.globalPosition,
        partId: b.id,
        source: DialogSource.of(row),
      ),
      child: _PartVisibilityRow(
        onPressed: b.hidden ? null : select,
        selected: active,
        hasHiddenParts: b.hidden,
        showHiddenIndicator: true,
        tooltip: b.hidden ? context.strings.showPart : context.strings.hidePart,
        toggleVisibility: () => e.setPartsHidden({b.id}, !b.hidden),
        trailing: Expanded(
          child: serialTapTarget(
            Padding(
              padding: EdgeInsets.fromLTRB(
                4,
                macControls ? 3 : 6,
                7,
                macControls ? 3 : 6,
              ),
              child: Row(
                spacing: toolbarGap,
                children: [
                  if (b.hinge case final side?)
                    DoorIcon(
                      side,
                      color: b.hidden ? context.colors.disabled : null,
                    ),
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
                          '${e.displayUnit.formatStockLength(b.size.x)} × ${e.displayUnit.formatStockLength(b.size.y)} × ${e.displayUnit.formatStockLength(b.size.z)}',
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
            (!b.hidden || e.showHiddenOutlines) && !e.pickingAlignmentSupport
                ? select
                : null,
          ),
        ),
      ),
    );
  }

  Widget groupHeader(int? id, List<Beam> members, {required bool selected}) {
    final visible = members.where((b) => !b.hidden);
    final first = visible.firstOrNull;
    void selectGroup({bool frame = false}) {
      if (first != null) {
        FocusManager.instance.primaryFocus?.unfocus();
        FocusManager.instance.applyFocusChangesIfNeeded();
        if (e.tool != Tool.select) e.setTool(Tool.select);
        e.select(first.id);
      }
      if (frame) {
        final points = [
          for (final b in e.showHiddenOutlines ? members : visible)
            ...b.corners,
        ];
        if (points.isNotEmpty) widget.centerOn(points);
      }
    }

    final hasHidden = members.any((b) => b.hidden);
    final collapsed = collapsedGroups.contains(id);
    final title = id == null
        ? context.strings.assemblyParts
        : e.project.groupName(id);
    final label = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 28),
      child: Row(
        children: [
          if (e.project.groupDoors[id] case final door?) ...[
            DoorIcon(door.hinge),
            const SizedBox(width: controlGap),
          ],
          Expanded(
            child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
    final header = _PartVisibilityRow(
      key: ValueKey('group-header-$id'),
      hasHiddenParts: hasHidden,
      selected: selected,
      onPressed: id == null || first == null ? null : selectGroup,
      tooltip: hasHidden
          ? context.strings.showGroupParts
          : context.strings.hideGroupParts,
      toggleVisibility: () =>
          e.setPartsHidden({for (final b in members) b.id}, !hasHidden),
      leading: (hovered) => Expanded(
        child: _EditableTitle(
          title: title,
          showActions: hovered,
          tooltip: context.strings.renameGroup,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: context.colors.muted,
          ),
          rename: id == null
              ? null
              : (name) => e.commit(e.project.withGroupName(id, name)),
          child: Row(
            spacing: toolbarGap,
            children: [
              Semantics(
                label: title,
                expanded: !collapsed,
                child: DeskInlineIcon(
                  label: title,
                  icon: collapsed
                      ? PhosphorIconsRegular.caretRight
                      : PhosphorIconsRegular.caretDown,
                  onPressed: () => setState(() {
                    if (collapsed) {
                      collapsedGroups.remove(id);
                    } else {
                      collapsedGroups.add(id);
                    }
                  }),
                ),
              ),
              Expanded(
                child: id == null
                    ? label
                    : serialTapTarget(
                        label,
                        (tap) => selectGroup(frame: tap.count == 2),
                      ),
              ),
            ],
          ),
        ),
      ),
      trailing: serialTapTarget(
        Padding(
          padding: const EdgeInsets.only(left: 4, right: 12),
          child: Text(
            '${members.length}',
            style: mono.copyWith(color: context.colors.muted),
          ),
        ),
        id == null
            ? null
            : (tap) {
                if (tap.count == 2) selectGroup(frame: true);
              },
      ),
    );
    if (id == null) return header;
    return GestureDetector(
      onSecondaryTapUp: first == null
          ? null
          : (tap) {
              selectGroup();
              showDrawingMenu(context, e, tap.globalPosition, partId: first.id);
            },
      child: Semantics(selected: selected, child: header),
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
              color: selected
                  ? context.selectionFill
                  : hoveredDimensionId == rowId
                  ? context.colors.ink.withValues(alpha: .06)
                  : Colors.transparent,
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
                  trailing: DeskInlineIcon(
                    icon: PhosphorIconsRegular.x,
                    label: context.strings.deleteDimension,
                    onPressed: () => e.removeDimension(d),
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
    final selectedGroup = e.selectedGroup;
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
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: context.colors.line, width: .7),
                ),
              ),
              child: sections,
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 13, 10, 10),
              child: sections,
            ),
          Padding(
            padding: macControls
                ? const EdgeInsets.symmetric(horizontal: 8, vertical: 6)
                : const EdgeInsets.fromLTRB(12, 0, 10, 8),
            child: Tooltip(
              message: addTip,
              child: DeskButton(
                onPressed: add,
                icon: const Icon(cu.CupertinoIcons.plus, size: 16),
                label: Text(addLabel),
              ),
            ),
          ),
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
                        groupHeader(
                          entry.key,
                          entry.value,
                          selected:
                              selectedGroup != null &&
                              entry.key == selectedGroup,
                        ),
                        const SizedBox(height: toolbarGap),
                        if (!collapsedGroups.contains(entry.key))
                          ...entry.value.map(item),
                      ],
                    ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 33),
              child: DeskButton(
                onPressed: widget.showPartsList,
                key: widget.partsListButton,
                icon: const Icon(cu.CupertinoIcons.list_bullet, size: 15),
                label: Text(context.strings.partsList),
              ),
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
    required this.showActions,
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
  bool editing = false;

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
    return editing
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
              if (widget.rename != null && widget.showActions)
                DeskInlineIcon(
                  icon: PhosphorIconsRegular.pencilSimple,
                  label: widget.tooltip,
                  onPressed: start,
                ),
              if (widget.showActions && widget.onCenter != null)
                DeskInlineIcon(
                  icon: PhosphorIconsRegular.crosshair,
                  label: context.strings.centerCamera,
                  onPressed: widget.onCenter!,
                ),
              ?widget.trailing,
            ],
          );
  }
}

class _PartVisibilityRow extends StatefulWidget {
  const _PartVisibilityRow({
    super.key,
    required this.hasHiddenParts,
    required this.selected,
    required this.onPressed,
    this.showHiddenIndicator = false,
    required this.tooltip,
    required this.toggleVisibility,
    this.leading,
    required this.trailing,
  });

  final bool hasHiddenParts, showHiddenIndicator, selected;
  final VoidCallback? onPressed;
  final String tooltip;
  final VoidCallback toggleVisibility;
  final Widget Function(bool hovered)? leading;
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
    child: DeskControl(
      onPressed: widget.onPressed,
      background: widget.selected
          ? context.selectionFill
          : hovered && widget.onPressed == null
          ? context.colors.ink.withValues(alpha: .06)
          : null,
      child: Row(
        spacing: toolbarGap,
        children: [
          ?widget.leading?.call(hovered),
          Stack(
            alignment: Alignment.center,
            children: [
              if (macControls &&
                  widget.showHiddenIndicator &&
                  !hovered &&
                  !widget.hasHiddenParts)
                Icon(
                  PhosphorIconsRegular.cube,
                  size: 13,
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
                child: DeskInlineIcon(
                  icon: widget.hasHiddenParts
                      ? (hovered
                            ? PhosphorIconsRegular.eye
                            : PhosphorIconsRegular.eyeClosed)
                      : PhosphorIconsRegular.eyeSlash,
                  label: widget.tooltip,
                  onPressed: widget.toggleVisibility,
                ),
              ),
            ],
          ),
          widget.trailing,
        ],
      ),
    ),
  );
}
