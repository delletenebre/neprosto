import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:material_ui/material_ui.dart';

import '../l10n/strings.dart';
import 'arithmetic.dart';
import 'controller.dart';
import 'desk_text_field.dart';
import 'desktop.dart';
import 'model.dart';
import 'palette.dart';

Future<void> showPanelHoles(
  BuildContext context,
  Editor editor,
  Beam part,
) async {
  final holes = await showDeskDialog<List<PanelHole>>(
    context: context,
    builder: (_) => _HoleDialog(part, editor.project.unit),
  );
  if (holes != null &&
      context.mounted &&
      identical(editor.project.byId[part.id], part) &&
      !listEquals(holes, part.holes)) {
    editor.commit(editor.project.edit({part.id}, (b) => b.copy(holes: holes)));
  }
}

class _HoleDraft {
  _HoleDraft(this.original, this.unit)
    : fromEnd = original.fromEnd,
      fromFar = original.fromFarEdge,
      blind = original.depth != null,
      back = original.back;
  final PanelHole original;
  final LengthUnit unit;
  bool fromEnd, fromFar, blind, back;
  TextEditingController field(double n) =>
      TextEditingController(text: unit.format(n));
  late final x = field(original.x),
      y = field(original.y),
      diameter = field(original.diameter),
      depth = field(original.depth ?? 12);
  double? read(TextEditingController field, double initial) {
    if (field.text == unit.format(initial)) return initial;
    final n = calculate(field.text);
    return n == null ? null : n * unit.factor;
  }

  PanelHole? get hole {
    final a = read(x, original.x),
        b = read(y, original.y),
        d = read(diameter, original.diameter),
        z = read(depth, original.depth ?? 12);
    if (a == null || b == null || d == null || (blind && z == null)) {
      return null;
    }
    return PanelHole(
      a,
      b,
      d,
      depth: blind ? z : null,
      back: blind && back,
      fromEnd: fromEnd,
      fromFarEdge: fromFar,
    );
  }

  void dispose() {
    for (final c in [x, y, diameter, depth]) {
      c.dispose();
    }
  }
}

class _HoleDialog extends StatefulWidget {
  const _HoleDialog(this.part, this.unit);
  final Beam part;
  final LengthUnit unit;
  @override
  State<_HoleDialog> createState() => _HoleDialogState();
}

class _HoleDialogState extends State<_HoleDialog> {
  late final drafts = [
    for (final h in widget.part.holes) _HoleDraft(h, widget.unit),
  ];
  int selected = 0;
  _HoleDraft? get current => drafts.elementAtOrNull(selected);
  Vector3 get size => widget.part.size;
  // Show an installed upright in portrait, with its stock length vertical.
  bool get upright => widget.part.along.z.abs() > .7;

  @override
  void dispose() {
    for (final draft in drafts) {
      draft.dispose();
    }
    super.dispose();
  }

  void add({bool cup = false}) {
    final diameter = cup ? 35.0 : math.min(5.0, math.min(size.x, size.y) / 2);
    final h = PanelHole(
      cup ? math.min(100, size.x / 2) : size.x / 2,
      cup ? math.min(22, size.y / 2) : size.y / 2,
      diameter,
      fromFarEdge: cup && widget.part.hinge == DoorHinge.right,
      depth: cup ? 12.0 : null,
      back: cup,
    );
    drafts.add(_HoleDraft(h, widget.unit));
    selected = drafts.length - 1;
  }

  Widget number(String label, String key, TextEditingController controller) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label),
          const SizedBox(height: 3),
          Semantics(
            label: label,
            child: DeskTextField(
              key: ValueKey(key),
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              suffix: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(widget.unit.symbol),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      );

  Widget offsetField(_HoleDraft draft, {required bool horizontal}) {
    final along = horizontal != upright;
    final controller = along ? draft.x : draft.y;
    final far = along ? draft.fromEnd : draft.fromFar;
    final s = context.strings;
    final nearLabel = horizontal ? s.fromLeft : s.fromBottom;
    final farLabel = horizontal ? s.fromRight : s.fromTop;
    final label = far ? farLabel : nearLabel;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DeskMenu<bool>(
            title: label,
            selected: far,
            items: [(false, nearLabel), (true, farLabel)],
            change: (value) => setState(() {
              if (value == far) return;
              final n = draft.read(
                controller,
                along ? draft.original.x : draft.original.y,
              );
              if (n != null) {
                controller.text = widget.unit.format(
                  (along ? size.x : size.y) - n,
                );
              }
              if (along) {
                draft.fromEnd = value;
              } else {
                draft.fromFar = value;
              }
            }),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(child: Text(label)),
                const Icon(Icons.unfold_more, size: 14),
              ],
            ),
          ),
          Semantics(
            label: label,
            child: DeskTextField(
              key: ValueKey(horizontal ? 'hole-horizontal' : 'hole-vertical'),
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              suffix: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(widget.unit.symbol),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }

  Widget diagram() => SizedBox(
    height: 165,
    child: LayoutBuilder(
      builder: (context, box) {
        final width = upright ? size.y : size.x,
            height = upright ? size.x : size.y;
        final scale = math.min(
          (box.maxWidth - 16) / width,
          (box.maxHeight - 12) / height,
        );
        final rect = Rect.fromCenter(
          center: box.biggest.center(Offset.zero),
          width: width * scale,
          height: height * scale,
        );
        Offset center(PanelHole h) {
          final x = h.centerX(size), y = h.centerY(size);
          return Offset(
            rect.left + (upright ? y : x) * scale,
            rect.bottom - (upright ? x : y) * scale,
          );
        }

        final marks = [for (final d in drafts) d.hole];
        int? hit(Offset at) {
          for (var i = marks.length - 1; i >= 0; i--) {
            final h = marks[i];
            if (h != null &&
                (center(h) - at).distance <=
                    math.max(6, h.diameter * scale / 2)) {
              return i;
            }
          }
          return null;
        }

        void place(Offset at) {
          if (current == null) add();
          final d = current!;
          final horizontal = ((at.dx - rect.left) / scale).clamp(0.0, width);
          final vertical = ((rect.bottom - at.dy) / scale).clamp(0.0, height);
          final x = upright ? vertical : horizontal,
              y = upright ? horizontal : vertical;
          d.x.text = widget.unit.format(d.fromEnd ? size.x - x : x);
          d.y.text = widget.unit.format(d.fromFar ? size.y - y : y);
        }

        return GestureDetector(
          key: const ValueKey('hole-diagram'),
          behavior: HitTestBehavior.opaque,
          onTapUp: (event) {
            if (!rect.contains(event.localPosition)) return;
            final i = hit(event.localPosition);
            setState(() {
              if (i == null) {
                place(event.localPosition);
              } else {
                selected = i;
              }
            });
          },
          onPanStart: (event) {
            if (!rect.contains(event.localPosition)) return;
            setState(() {
              selected = hit(event.localPosition) ?? selected;
            });
          },
          onPanUpdate: (event) {
            if (rect.contains(event.localPosition)) {
              setState(() => place(event.localPosition));
            }
          },
          child: CustomPaint(
            painter: _HoleDiagram(rect, context.colors, [
              for (final (i, h) in marks.indexed)
                if (h != null && h.diameter > 0 && h.fits(size))
                  (
                    center: center(h),
                    radius: h.diameter * scale / 2,
                    selected: i == selected,
                    blind: h.depth != null,
                  ),
            ]),
          ),
        );
      },
    ),
  );

  @override
  Widget build(BuildContext context) {
    final s = context.strings, unit = widget.unit, d = current;
    final invalid = drafts.indexWhere((d) => d.hole?.fits(size) != true);
    return DeskDialog(
      maxWidth: 480,
      title: Text(s.panelHoles),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          Text(
            '${widget.part.name} · ${[size.x, size.y, size.z].map(unit.format).join(' × ')} ${unit.symbol}',
          ),
          Text(
            '${upright ? s.faceA : s.faceB} · ${s.holeDiagramHelp}',
            style: TextStyle(color: context.colors.muted),
          ),
          diagram(),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (d != null)
                DeskMenu<int>(
                  title: s.panelHoles,
                  selected: selected,
                  items: [
                    for (var i = 0; i < drafts.length; i++) (i, '№ ${i + 1}'),
                  ],
                  change: (v) => setState(() => selected = v),
                  child: Text('№ ${selected + 1} / ${drafts.length} ▾'),
                ),
              DeskButton(
                onPressed: () => setState(() => add()),
                child: Text(s.addHole),
              ),
              DeskButton(
                onPressed: () => setState(() => add(cup: true)),
                child: Text(s.cupHole),
              ),
              if (d != null)
                DeskButton(
                  plain: true,
                  onPressed: () => setState(() {
                    drafts.removeAt(selected).dispose();
                    selected = math.max(
                      0,
                      math.min(selected, drafts.length - 1),
                    );
                  }),
                  child: Text(s.delete),
                ),
            ],
          ),
          if (d != null) ...[
            Row(
              spacing: 12,
              children: [
                offsetField(d, horizontal: true),
                offsetField(d, horizontal: false),
              ],
            ),
            DeskSegments(d.blind, {
              false: s.throughHole,
              true: s.blindHole,
            }, (v) => setState(() => d.blind = v)),
            Row(
              spacing: 12,
              children: [
                Expanded(
                  child: number(s.holeDiameter, 'hole-diameter', d.diameter),
                ),
                if (d.blind)
                  Expanded(child: number(s.rabbetDepth, 'hole-depth', d.depth)),
              ],
            ),
            if (d.blind)
              DeskSegments(d.back, {
                false: s.faceA,
                true: s.faceB,
              }, (v) => setState(() => d.back = v)),
          ],
          if (invalid >= 0)
            Text(
              '№ ${invalid + 1} · ${s.invalidHole}',
              style: TextStyle(color: context.colors.danger),
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
          onPressed: invalid >= 0
              ? null
              : () => Navigator.pop(context, [for (final d in drafts) d.hole!]),
          child: Text(s.apply),
        ),
      ],
    );
  }
}

typedef _HoleMark = ({Offset center, double radius, bool selected, bool blind});

class _HoleDiagram extends CustomPainter {
  _HoleDiagram(this.rect, this.colors, this.marks);
  final Rect rect;
  final EditorPalette colors;
  final List<_HoleMark> marks;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(rect, Paint()..color = colors.chrome);
    final pen = Paint()
      ..style = PaintingStyle.stroke
      ..color = colors.muted;
    canvas.drawRect(rect, pen);
    for (final m in marks) {
      final c = m.center;
      pen.color = m.selected ? colors.accent : colors.muted;
      final r = math.max(2.0, m.radius);
      canvas.drawCircle(
        c,
        r,
        Paint()..color = m.blind ? colors.muted : colors.paper,
      );
      canvas.drawCircle(c, r, pen);
      if (m.selected) {
        canvas.drawLine(c - const Offset(7, 0), c + const Offset(7, 0), pen);
        canvas.drawLine(c - const Offset(0, 7), c + const Offset(0, 7), pen);
      }
    }
  }

  @override
  bool shouldRepaint(_HoleDiagram old) => true;
}
