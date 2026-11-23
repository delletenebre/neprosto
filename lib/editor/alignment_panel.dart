import 'package:cupertino_ui/cupertino_ui.dart' as cu;
import 'package:material_ui/material_ui.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart'
    show PhosphorIconsRegular;

import 'controller.dart';
import 'controls.dart';
import 'desktop.dart';
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
    final p = e.alignmentPlacement;
    final staged = e.tool == Tool.align;
    final selected = staged && e.hasPlacementChoice ? e.alignment : null;
    final moving = e.single!;
    final dir = p?.direction;
    final dim = dir == null
        ? 1
        : [0, 1, 2].reduce((a, b) => dir[a].abs() >= dir[b].abs() ? a : b);
    final (near, far, datum) = [
      ('Левый', 'Правый', 'левого края'),
      ('Передний', 'Задний', 'переднего края'),
      ('Нижний', 'Верхний', 'нижнего края'),
    ][dim];
    final offset = p == null
        ? 0.0
        : selected == null
        ? p.current
        : p.offset(selected, e.manualOffset);
    final useThickness = p?.alongThickness ?? false;
    return MouseRegion(
      onEnter: (_) => e.showAlignmentSupport(true),
      onExit: (_) => e.showAlignmentSupport(false),
      child: Container(
        padding: const EdgeInsets.fromLTRB(15, 13, 15, 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: line)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            sectionTitle('Выравнивание'),
            const SizedBox(height: 7),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Опорная деталь',
                    style: TextStyle(fontSize: 12, color: muted),
                  ),
                ),
                Tooltip(
                  message: 'Указать опору на чертеже',
                  child: DeskButton(
                    plain: true,
                    onPressed: () {
                      discardInput();
                      e.beginAlignment();
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(cu.CupertinoIcons.scope, size: 13, color: accent),
                        SizedBox(width: 3),
                        Text(
                          'На чертеже',
                          style: TextStyle(fontSize: 11, color: accent),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            DeskMenu<int>(
              title: 'Выбрать опорную деталь из списка',
              items: [
                for (final b in e.project.beams)
                  if (b.id != moving.id) (b.id, b.name),
              ],
              change: (id) {
                discardInput();
                e.chooseSupport(id);
              },
              child: Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: line),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: p == null ? muted : supportColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        p?.reference.name ?? 'Выберите опору…',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: ink),
                      ),
                    ),
                    const Icon(
                      cu.CupertinoIcons.chevron_down,
                      size: 12,
                      color: muted,
                    ),
                  ],
                ),
              ),
            ),
            if (p == null)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  'Щёлкните по опоре на чертеже или выберите её из списка.',
                  style: TextStyle(fontSize: 12, color: muted),
                ),
              ),
            if (p != null) ...[
              const SizedBox(height: 9),
              const Text(
                'Направление',
                style: TextStyle(fontSize: 12, color: muted),
              ),
              const SizedBox(height: 4),
              DeskSegments<bool>(
                useThickness,
                const {false: 'По ширине', true: 'По толщине'},
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
                    p,
                    e.visibleAlignment ?? StockAlignment.offset,
                    selected == null ? p.current : e.manualOffset,
                  ),
                ),
              ),
              cu.CupertinoSlidingSegmentedControl<StockAlignment>(
                groupValue: selected == StockAlignment.offset ? null : selected,
                padding: const EdgeInsets.all(2),
                children: {
                  for (final (option, label, icon) in [
                    (
                      StockAlignment.front,
                      '$near\nкрай',
                      dim == 0
                          ? PhosphorIconsRegular.alignLeft
                          : PhosphorIconsRegular.alignBottom,
                    ),
                    (
                      StockAlignment.middle,
                      'Центр',
                      dim == 0
                          ? PhosphorIconsRegular.alignCenterHorizontal
                          : PhosphorIconsRegular.alignCenterVertical,
                    ),
                    (
                      StockAlignment.back,
                      '$far\nкрай',
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
                              color: alignmentColors[option],
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
                                    color: alignmentColors[option],
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
                onValueChanged: (v) {
                  if (v == null) return;
                  discardInput();
                  e.chooseAlignment(v);
                },
              ),
              const SizedBox(height: 9),
              Text(
                'Отступ от $datum опоры',
                style: const TextStyle(fontSize: 12, color: ink),
              ),
              const SizedBox(height: 3),
              SizedBox(
                key: const Key('placement-offset'),
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
              Text(
                valid ? '0 — заподлицо, минус — выступ' : 'Проверьте выражение',
                style: TextStyle(
                  fontSize: 10.5,
                  color: valid ? muted : cu.CupertinoColors.systemRed,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DeskButton(
                    plain: true,
                    onPressed: staged || !valid
                        ? () {
                            discardInput();
                            e.setTool(Tool.select);
                          }
                        : null,
                    child: const Text('Отмена'),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: DeskButton(
                    primary: true,
                    onPressed:
                        valid &&
                            staged &&
                            e.hasPlacementChoice &&
                            e.alignmentDelta.abs() > 1e-7
                        ? () {
                            discardInput();
                            e.applyAlignment();
                          }
                        : null,
                    child: const Text('Применить'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportSection extends CustomPainter {
  final StockPlacement placement;
  final StockAlignment alignment;
  final double manual;
  _SupportSection(this.placement, this.alignment, this.manual);
  @override
  void paint(Canvas canvas, Size size) {
    final p = placement,
        support = p.far - p.near,
        offset = p.offset(alignment, manual);
    final low = offset < 0 ? offset : 0.0,
        high = offset + p.width > support ? offset + p.width : support;
    final scale = (size.width - 56) / (high - low);
    double x(double v) => 50 + (v - low) * scale;
    final pen = Paint()..color = line;
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

    strip('Деталь', 6, offset, offset + p.width, alignmentColors[alignment]!);
    strip('Опора', 26, 0, support, supportColor);
  }

  @override
  bool shouldRepaint(_SupportSection old) => true;
}
