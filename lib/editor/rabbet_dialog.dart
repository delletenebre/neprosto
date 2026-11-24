import 'dart:math' as math;

import 'package:flutter/foundation.dart' show mapEquals;
import 'package:material_ui/material_ui.dart';

import '../l10n/strings.dart';
import 'arithmetic.dart';
import 'controller.dart';
import 'desk_text_field.dart';
import 'desktop.dart';
import 'model.dart';
import 'palette.dart';

Future<void> showRabbets(BuildContext context, Editor editor, Beam part) async {
  final result = await showDeskDialog<Beam>(
    context: context,
    builder: (_) => _RabbetDialog(part, editor.project.unit),
  );
  if (result != null &&
      context.mounted &&
      identical(editor.project.byId[part.id], part) &&
      !mapEquals(part.rabbets, result.rabbets)) {
    editor.commit(editor.project.edit({part.id}, (_) => result));
  }
}

class _RabbetDialog extends StatefulWidget {
  const _RabbetDialog(this.part, this.unit);
  final Beam part;
  final LengthUnit unit;
  @override
  State<_RabbetDialog> createState() => _RabbetDialogState();
}

class _RabbetDialogState extends State<_RabbetDialog> {
  late var edge = widget.part.rabbets.keys.firstOrNull ?? RabbetEdge.topLeft;
  late final fields = {
    for (final e in RabbetEdge.values)
      e: (
        width: controller(widget.part.rabbets[e]?.width),
        depth: controller(widget.part.rabbets[e]?.depth),
      ),
  };

  TextEditingController controller(double? mm) =>
      TextEditingController(text: mm == null ? '' : widget.unit.format(mm));

  double? read(String text, double? original) {
    if (original != null && text == widget.unit.format(original)) {
      return original;
    }
    final value = calculate(text);
    return value == null ? null : value * widget.unit.factor;
  }

  @override
  void dispose() {
    for (final f in fields.values) {
      f.width.dispose();
      f.depth.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings, unit = widget.unit, part = widget.part;
    final cuts = <RabbetEdge, Rabbet>{};
    RabbetEdge? invalid;
    for (final e in fields.entries) {
      final w = e.value.width.text.trim(), d = e.value.depth.text.trim();
      if (w.isEmpty && d.isEmpty) continue;
      final width = read(w, part.rabbets[e.key]?.width);
      final depth = read(d, part.rabbets[e.key]?.depth);
      if (width == null ||
          !width.isFinite ||
          width <= 0 ||
          depth == null ||
          !depth.isFinite ||
          depth <= 0) {
        invalid ??= e.key;
      } else {
        cuts[e.key] = (width: width, depth: depth);
      }
    }
    final draft = part.copy(rabbets: cuts);
    final valid = invalid == null && draft.cutsFit;
    final current = fields[edge]!;

    Widget choices(RabbetEdge left, RabbetEdge right) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final e in [left, right])
          Flexible(
            child: Semantics(
              selected: e == edge,
              child: DeskButton(
                active: edge == e,
                onPressed: () => setState(() => edge = e),
                child: Text(e.label),
              ),
            ),
          ),
      ],
    );

    Widget field(String label, TextEditingController input) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 4),
          Semantics(
            label: label,
            child: DeskTextField(
              key: ObjectKey(input),
              controller: input,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => setState(() {}),
              suffix: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(unit.symbol),
              ),
            ),
          ),
        ],
      ),
    );

    return DeskDialog(
      title: Text(s.rabbetTitle),
      maxWidth: 440,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Text(
            '${part.name} · ${unit.format(part.size.y)} × ${unit.format(part.size.z)} ${unit.symbol}',
          ),
          Text(s.rabbetView, style: TextStyle(color: context.colors.muted)),
          choices(RabbetEdge.topLeft, RabbetEdge.topRight),
          SizedBox(
            height: 106,
            child: LayoutBuilder(
              builder: (_, box) => GestureDetector(
                key: const ValueKey('rabbet-section'),
                behavior: HitTestBehavior.opaque,
                excludeFromSemantics: true,
                onTapUp: (tap) {
                  final right = tap.localPosition.dx >= box.maxWidth / 2;
                  final top = tap.localPosition.dy < box.maxHeight / 2;
                  setState(
                    () => edge = RabbetEdge.values.firstWhere(
                      (e) => e.right == right && e.top == top,
                    ),
                  );
                },
                child: CustomPaint(
                  painter: _SectionDiagram(
                    draft.cutsFit ? draft : part,
                    edge,
                    context.colors,
                  ),
                ),
              ),
            ),
          ),
          choices(RabbetEdge.bottomLeft, RabbetEdge.bottomRight),
          Row(
            spacing: 12,
            children: [
              field(s.width, current.width),
              field(s.rabbetDepth, current.depth),
            ],
          ),
          if (!valid)
            Text(
              [if (invalid != null) invalid.label, s.invalidRabbet].join(' · '),
              style: TextStyle(color: context.colors.danger),
            ),
          Align(
            alignment: Alignment.centerLeft,
            child: DeskButton(
              onPressed:
                  current.width.text.isEmpty && current.depth.text.isEmpty
                  ? null
                  : () {
                      setState(() {
                        current.width.clear();
                        current.depth.clear();
                      });
                    },
              child: Text(s.rabbetRemove),
            ),
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
          onPressed: valid ? () => Navigator.pop(context, draft) : null,
          child: Text(s.apply),
        ),
      ],
    );
  }
}

class _SectionDiagram extends CustomPainter {
  const _SectionDiagram(this.part, this.selected, this.colors);
  final Beam part;
  final RabbetEdge selected;
  final EditorPalette colors;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(
      (size.width - 16) / part.size.y,
      (size.height - 12) / part.size.z,
    );
    final rect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: part.size.y * scale,
      height: part.size.z * scale,
    );
    Offset at(double y, double z) =>
        Offset(rect.left + y * rect.width, rect.bottom - z * rect.height);
    final shape = Path()
      ..addPolygon([for (final p in part.sectionOutline) at(p.y, p.z)], true);
    canvas.drawRect(rect, Paint()..color = colors.chrome);
    canvas.drawPath(
      shape,
      Paint()..color = colors.diagramColor(const Color(0xffdfbd91)),
    );
    canvas.drawPath(
      shape,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = colors.ink,
    );
    final corner = at(selected.right ? 1 : 0, selected.top ? 1 : 0);
    if (part.rabbets[selected] case final cut?) {
      final inset =
          corner +
          Offset(
            (selected.right ? -1 : 1) * cut.width * scale,
            (selected.top ? 1 : -1) * cut.depth * scale,
          );
      canvas.drawRect(
        Rect.fromPoints(corner, inset),
        Paint()..color = colors.accent.withValues(alpha: .20),
      );
      canvas.drawPath(
        Path()
          ..moveTo(corner.dx, inset.dy)
          ..lineTo(inset.dx, inset.dy)
          ..lineTo(inset.dx, corner.dy),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = colors.accent,
      );
    }
    canvas.drawCircle(corner, 3.5, Paint()..color = colors.accent);
  }

  @override
  bool shouldRepaint(_SectionDiagram old) =>
      old.part != part || old.selected != selected || old.colors != colors;
}
