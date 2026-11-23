import 'package:cupertino_ui/cupertino_ui.dart' as cu;

import 'desktop.dart';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import 'controller.dart';
import 'hotkeys.dart';
import 'controls.dart';
import 'drawing.dart';
import 'model.dart';
import 'part_menu.dart';

class PartsPanel extends StatefulWidget {
  final Editor editor;
  const PartsPanel(this.editor, {super.key});
  @override
  State<PartsPanel> createState() => _PartsPanelState();
}

class _PartsPanelState extends State<PartsPanel> {
  bool measures = false;
  final closed = <String>{};
  Editor get e => widget.editor;
  Widget item(Beam b) {
    final active = e.selection.contains(b.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: GestureDetector(
        onSecondaryTapUp: (details) =>
            showDrawingMenu(context, e, details.globalPosition, partId: b.id),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: active ? pale : Colors.transparent,
            borderRadius: BorderRadius.circular(5),
          ),
          child: cu.CupertinoButton(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            onPressed: () {
              FocusManager.instance.primaryFocus?.unfocus();
              FocusManager.instance.applyFocusChangesIfNeeded();
              if (e.tool == Tool.align && e.referenceId == null) {
                e.chooseSupport(b.id);
                return;
              }
              final k = HardwareKeyboard.instance;
              if (e.tool == Tool.rotate || e.tool == Tool.align) {
                e.setTool(Tool.select);
              }
              e.select(
                b.id,
                multi:
                    k.isShiftPressed || k.isMetaPressed || k.isControlPressed,
                individual: k.isAltPressed,
              );
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(9, 6, 7, 6),
              child: Row(
                children: [
                  Container(
                    width: 23,
                    height: 23,
                    decoration: BoxDecoration(
                      color: active ? Colors.white : const Color(0xfff2ede3),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Icon(
                      cu.CupertinoIcons.cube,
                      size: 14,
                      color: active ? accent : const Color(0xff90764c),
                    ),
                  ),
                  const SizedBox(width: 8),
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
                            fontWeight: active
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${e.project.unit.format(b.size.x)} × ${e.project.unit.format(b.size.y)} × ${e.project.unit.format(b.size.z)}',
                          style: mono.copyWith(fontSize: 10, color: muted),
                        ),
                      ],
                    ),
                  ),
                  if (e.overlaps.contains(b.id))
                    const Tooltip(
                      message: 'Пересечение',
                      child: Icon(
                        cu.CupertinoIcons.exclamationmark_triangle,
                        size: 15,
                        color: Color(0xffba6343),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<Beam>>{};
    for (final b in e.project.beams) {
      final k = b.group == null ? 'Детали изделия' : 'Группа ${b.group}';
      (groups[k] ??= []).add(b);
    }
    final p = e.project;
    return ColoredBox(
      color: const Color(0xfff3f3f5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 13, 10, 10),
            child: DeskSegments(measures, {
              false: 'Детали  ${p.beams.length}',
              true: 'Размеры  ${p.dimensions.length}',
            }, (v) => setState(() => measures = v)),
          ),
          if (!measures)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 10, 8),
              child: Tooltip(
                message: 'Новая деталь · ${e.hotkeys[Command.add].label}',
                child: DeskButton(
                  primary: true,
                  onPressed: () => e.setTool(Tool.beam),
                  icon: const Icon(cu.CupertinoIcons.plus, size: 16),
                  label: const Text('Новая деталь'),
                ),
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              children: measures
                  ? [
                      if (p.dimensions.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: DeskButton(
                            plain: true,
                            onPressed: () => e.setTool(Tool.measure),
                            icon: const Icon(Icons.straighten),
                            label: const Text('Измерить расстояние'),
                          ),
                        ),
                      for (final (i, d) in p.dimensions.indexed)
                        Padding(
                          padding: const EdgeInsets.all(5),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${d.clearance ? 'Просвет' : 'Размер'} ${i + 1}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  iconAction(
                                    cu.CupertinoIcons.xmark,
                                    'Удалить размер',
                                    () {
                                      e.commit(
                                        p.copy(
                                          dimensions: p.dimensions.where(
                                            (m) => m != d,
                                          ),
                                        ),
                                      );
                                    },
                                    size: 14,
                                  ),
                                ],
                              ),
                              if (p.canSetDistance(d))
                                ValueBox(
                                  d.length(p),
                                  (v) => e.commit(p.setDistance(d, v)),
                                  key: ObjectKey(d),
                                )
                              else
                                Text(
                                  d.geometry(p) == null
                                      ? 'Нет общей проекции'
                                      : '${p.unit.format(d.length(p))} ${p.unit.symbol}',
                                  style: mono,
                                ),
                              const SizedBox(height: 4),
                              if (!d.clearance)
                                Text(
                                  [
                                    for (var j = 0; j < 3; j++)
                                      '${'XYZ'[j]} ${p.unit.format((d.b.resolve(p) - d.a.resolve(p))[j])}',
                                  ].join('  '),
                                  style: mono.copyWith(
                                    fontSize: 10,
                                    color: muted,
                                  ),
                                ),
                              const Divider(),
                            ],
                          ),
                        ),
                    ]
                  : [
                      for (final entry in groups.entries) ...[
                        cu.CupertinoButton(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          onPressed: () => setState(() {
                            if (!closed.remove(entry.key)) {
                              closed.add(entry.key);
                            }
                          }),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 6,
                              horizontal: 2,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  closed.contains(entry.key)
                                      ? cu.CupertinoIcons.chevron_right
                                      : cu.CupertinoIcons.chevron_down,
                                  size: 15,
                                  color: muted,
                                ),
                                Expanded(
                                  child: Text(
                                    entry.key,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: muted,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${entry.value.length}',
                                  style: mono.copyWith(color: muted),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (!closed.contains(entry.key))
                          ...entry.value.map(item),
                      ],
                    ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            child: Row(
              children: [
                iconAction(
                  cu.CupertinoIcons.square_stack,
                  'Сгруппировать',
                  e.canGroup ? e.group : null,
                ),
                iconAction(
                  cu.CupertinoIcons.rectangle_on_rectangle_angled,
                  'Разгруппировать',
                  e.canUngroup ? e.ungroup : null,
                ),
                const Spacer(),
                iconAction(
                  cu.CupertinoIcons.doc_on_doc,
                  'Дублировать',
                  e.selection.isEmpty ? null : e.duplicate,
                ),
                iconAction(
                  cu.CupertinoIcons.trash,
                  'Удалить',
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
