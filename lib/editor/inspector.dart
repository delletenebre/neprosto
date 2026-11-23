import 'desktop.dart';

import 'package:cupertino_ui/cupertino_ui.dart' as cu;
import 'package:material_ui/material_ui.dart';

import 'assembly.dart';
import 'joint.dart';
import 'alignment_panel.dart';
import 'joint_dialog.dart';
import 'controller.dart';
import 'hotkeys.dart';
import 'controls.dart';
import 'drawing.dart';
import 'model.dart';
import 'stock_axis.dart';

class Inspector extends StatelessWidget {
  final Editor e;
  final VoidCallback rename;
  const Inspector(this.e, {required this.rename, super.key});
  static const dimensions = ['Длина', 'Ширина', 'Толщина'];
  Widget block(String title, List<Widget> children) => Container(
    padding: const EdgeInsets.fromLTRB(15, 14, 15, 13),
    decoration: const BoxDecoration(
      border: Border(bottom: BorderSide(color: line)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [sectionTitle(title), const SizedBox(height: 10), ...children],
    ),
  );
  Widget row(String name, Widget field, {Widget? trailing}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(
          child: Text(name, style: const TextStyle(fontSize: 12, color: muted)),
        ),
        SizedBox(width: 92, child: field),
        ?trailing,
      ],
    ),
  );
  Widget lock(int i, Iterable<Beam> beams) {
    final locked = beams.every((b) => b.locked(i));
    return iconAction(
      locked ? cu.CupertinoIcons.lock : cu.CupertinoIcons.lock_open,
      '${locked ? 'Разблокировать' : 'Блокировать'} растягивание · ${dimensions[i]}',
      () {
        final ids = beams.map((b) => b.id).toSet();
        e.commit(
          e.project.edit(
            ids,
            (b) => b.copy(
              locks: locked ? b.locks & ~(1 << i) : b.locks | (1 << i),
            ),
          ),
        );
      },
      active: locked,
      size: 15,
    );
  }

  @override
  Widget build(BuildContext context) {
    final part = e.single, selected = e.selected;
    final rotatedPart = e.tool == Tool.rotate && part != null
        ? e.displayed.byId[part.id]
        : null;
    final parts = selected.isEmpty ? e.project.beams : selected;
    final bounds = parts.isEmpty
        ? null
        : Bounds3.points(parts.expand((b) => b.corners));
    final ids = parts.map((b) => b.id).toSet();
    final alignable =
        part != null &&
        e.project.beams.length > 1 &&
        (e.tool == Tool.select || e.tool == Tool.align);
    final title =
        part?.name ??
        (selected.isEmpty
            ? e.project.name
            : 'Выбрано деталей · ${selected.length}');
    return ColoredBox(
      color: Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 15, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alignable ? 'Перемещаемая деталь' : 'Свойства',
                  style: const TextStyle(fontSize: 12, color: muted),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: alignable
                          ? DeskMenu<int>(
                              title: 'Выбрать перемещаемую деталь',
                              items: [
                                for (final b in e.project.beams) (b.id, b.name),
                              ],
                              change: (id) {
                                if (e.single?.id == id) return;
                                e.setTool(Tool.select);
                                e.select(id, individual: true);
                              },
                              child: Row(
                                children: [
                                  Flexible(
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
                                  const SizedBox(width: 4),
                                  const Icon(
                                    cu.CupertinoIcons.chevron_down,
                                    size: 13,
                                    color: muted,
                                  ),
                                ],
                              ),
                            )
                          : Text(
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
                        'Переименовать деталь',
                        rename,
                        size: 15,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (e.tool == Tool.measure || e.tool == Tool.gap)
            block('Линейка', [
              DeskSegments(e.tool, const {
                Tool.measure: 'Две точки',
                Tool.gap: 'Просвет',
              }, e.setTool),
            ]),
          if (selected.length == 2 && e.tool != Tool.rotate)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: DeskButton(
                icon: const Icon(cu.CupertinoIcons.triangle, size: 16),
                label: const Text('Угловой стык…'),
                onPressed: () => showPartJoint(context, e),
              ),
            ),
          if (part != null && part.bevelled)
            block('Разметка торцов', [
              for (final end in [false, true])
                Text(
                  '${end ? 'Конец' : 'Начало'} · ${mm(endAngle(part, end))}° от прямого',
                  style: const TextStyle(fontSize: 12),
                ),
              const SizedBox(height: 5),
              Text(
                'Кромки · ${(edgeLengths(part).map(e.project.unit.format).toSet().toList()).join(' / ')} ${e.project.unit.symbol}',
                style: mono,
              ),
            ]),
          if (alignable) AlignmentPanel(e, key: ValueKey(part.id)),
          if (e.tool == Tool.rotate) ...[
            block('Поворот', [
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
                                      color: axis.color,
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
                  label: e.localRotation ? 'Оси детали' : 'Оси проекта',
                  items: const [(false, 'Оси проекта'), (true, 'Оси детали')],
                  change: (v) {
                    e.localRotation = v;
                    e.chooseRotationAxis(e.rotationAxis);
                  },
                ),
              const SizedBox(height: 7),
              DeskSegments(
                e.rotationAxis,
                e.localRotation && part != null
                    ? const {0: 'Длина', 1: 'Ширина', 2: 'Толщина'}
                    : const {2: 'XY', 1: 'XZ', 0: 'YZ'},
                e.chooseRotationAxis,
              ),
              const SizedBox(height: 6),
              row(
                'Угол',
                ValueBox(
                  e.angle,
                  (v) {
                    e.setAngle(v);
                  },
                  key: const Key('angle'),
                  unit: '°',
                  signed: true,
                  live: true,
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: DeskButton(
                      plain: true,
                      onPressed: () {
                        e.setAngle(e.angle - 90);
                      },
                      child: const Text('−90°'),
                    ),
                  ),
                  Expanded(
                    child: DeskButton(
                      plain: true,
                      onPressed: () {
                        e.setAngle(e.angle + 90);
                      },
                      child: const Text('+90°'),
                    ),
                  ),
                ],
              ),
              DeskButton(
                primary: true,
                onPressed: e.angle == 0 ? null : e.applyRotation,
                child: const Text('Применить'),
              ),
              DeskButton(
                plain: true,
                onPressed: () => e.setTool(Tool.select),
                child: const Text('Отмена'),
              ),
            ]),
          ] else if (part != null && e.tool != Tool.align) ...[
            block('Размеры детали', [
              for (var i = 0; i < 3; i++)
                StockSizeRow(
                  e,
                  StockAxis.values[i],
                  ValueBox(part.size[i], (v) {
                    if (i == 0 && v < part.minimumLength) {
                      e.message = 'Длина меньше перепада запилов';
                      e.refresh();
                      return;
                    }
                    e.commit(
                      e.project.edit({
                        part.id,
                      }, (b) => b.copy(size: b.size.clone()..[i] = v)),
                    );
                  }, key: ValueKey('size-${part.id}-$i')),
                  trailing: lock(i, [part]),
                ),
            ]),
            block('Растянуть до упора', [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Магнит торцов',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  DeskSwitch(
                    value: e.magneticResize,
                    onChanged: (v) {
                      e.magneticResize = v;
                      e.refresh();
                    },
                  ),
                ],
              ),
              MenuChoice<int>(
                label: dimensions[e.resizeAxis],
                icon: Icons.straighten,
                items: [for (var i = 0; i < 3; i++) (i, dimensions[i])],
                change: (i) {
                  e.resizeAxis = i;
                  e.refresh();
                },
              ),
              Row(
                children: [
                  Expanded(
                    child: DeskButton(
                      onPressed: part.locked(e.resizeAxis)
                          ? null
                          : () => e.extend(false),
                      child: const Text('← Начало'),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: DeskButton(
                      onPressed: part.locked(e.resizeAxis)
                          ? null
                          : () => e.extend(true),
                      child: const Text('Конец →'),
                    ),
                  ),
                ],
              ),
            ]),
          ] else if (bounds != null && e.tool != Tool.align) ...[
            block(selected.isEmpty ? 'Габариты изделия' : 'Габариты сборки', [
              for (var i = 0; i < 3; i++)
                row(
                  ['X · ширина', 'Y · глубина', 'Z · высота'][i],
                  ValueBox(bounds.high[i] - bounds.low[i], (v) {
                    final result = resizeAssembly(e.project, ids, axis(i), v);
                    e.message = result.error ?? '';
                    if (result.error != null) {
                      e.refresh();
                    } else {
                      e.commit(result.project);
                    }
                  }, key: ValueKey('extent-$i')),
                ),
            ]),
            if (selected.length > 1)
              block('Блокировки деталей', [
                for (var i = 0; i < 3; i++)
                  Row(
                    children: [
                      Expanded(child: Text(dimensions[i])),
                      lock(i, selected),
                    ],
                  ),
              ]),
          ],
          if (e.tool != Tool.rotate &&
              e.tool != Tool.align &&
              selected.isNotEmpty &&
              bounds != null) ...[
            block('Положение', [
              for (var i = 0; i < 3; i++)
                row(
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
                    key: ValueKey('position-$i'),
                  ),
                ),
              const SizedBox(height: 6),
              DeskButton(
                onPressed: () => e.setTool(Tool.move),
                icon: const Icon(cu.CupertinoIcons.move, size: 15),
                label: const Text('Поставить по опоре'),
              ),
              const SizedBox(height: 5),
              DeskButton(
                onPressed: () => e.setTool(Tool.rotate),
                icon: const Icon(cu.CupertinoIcons.arrow_clockwise, size: 17),
                label: const Text('Повернуть'),
              ),
            ]),
          ],
          if (e.tool != Tool.rotate && selected.isEmpty)
            block('Работа с чертежом', [
              for (final (icon, label, shortcut) in [
                (cu.CupertinoIcons.list_bullet, 'Меню действий', 'ПКМ'),
                (
                  cu.CupertinoIcons.arrow_clockwise,
                  'Повернуть вид',
                  'Тянуть ПКМ',
                ),
                (cu.CupertinoIcons.hand_raised, 'Сдвинуть вид', 'Пробел + ЛКМ'),
                (cu.CupertinoIcons.zoom_in, 'Масштаб', 'Ctrl/⌘ + скролл'),
                (
                  cu.CupertinoIcons.resize,
                  e.dimensionsByDefault ? 'Скрыть размеры' : 'Показать размеры',
                  'Удерживать ${e.hotkeys[Command.dimensions].label}',
                ),
              ])
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Icon(icon, size: 15, color: muted),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          label,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      Text(
                        shortcut,
                        style: mono.copyWith(fontSize: 10, color: muted),
                      ),
                    ],
                  ),
                ),
            ]),
          if (e.overlaps.isNotEmpty)
            block('Пересечения', [
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
            ]),
        ],
      ),
    );
  }
}
