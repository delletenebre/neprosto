import 'dart:math' as math;

import 'package:flutter/foundation.dart' show mapEquals;
import 'package:material_ui/material_ui.dart';

import '../l10n/strings.dart';
import 'controls.dart';
import 'controller.dart';
import 'step.dart';
import 'desktop.dart';
import 'model.dart';
import 'palette.dart';

Future<void> showRabbets(BuildContext context, Editor editor, Beam part) async {
  final result = await showDeskDialog<Beam>(
    context: context,
    builder: (_) => _RabbetDialog(part, editor.lengthInput),
  );
  if (result != null &&
      context.mounted &&
      identical(editor.project.byId[part.id], part) &&
      !mapEquals(part.rabbets, result.rabbets)) {
    editor.commit(editor.project.edit({part.id}, (_) => result));
  }
}

class _RabbetDialog extends StatefulWidget {
  const _RabbetDialog(this.part, this.input);
  final Beam part;
  final LengthInput input;
  @override
  State<_RabbetDialog> createState() => _RabbetDialogState();
}

class _RabbetDialogState extends State<_RabbetDialog> {
  late var edge = widget.part.rabbets.keys.firstOrNull ?? RabbetEdge.topLeft;
  late final fields = {
    for (final e in RabbetEdge.values)
      e: (
        width: LengthEditingController(
          widget.input,
          widget.part.rabbets[e]?.width,
        ),
        depth: LengthEditingController(
          widget.input,
          widget.part.rabbets[e]?.depth,
        ),
      ),
  };

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
    final s = context.strings, unit = widget.input.unit, part = widget.part;
    final cuts = <RabbetEdge, Rabbet>{};
    RabbetEdge? invalid;
    for (final e in fields.entries) {
      final w = e.value.width.text.trim(), d = e.value.depth.text.trim();
      if (w.isEmpty && d.isEmpty) continue;
      final width = e.value.width.millimeters;
      final depth = e.value.depth.millimeters;
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

    Widget field(String label, LengthEditingController input) => Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 4),
          Semantics(
            label: label,
            child: DraftLengthField(
              input,
              () => setState(() {}),
              key: ObjectKey(input),
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
            '${part.name} · ${widget.input.format(part.size.y)} × ${widget.input.format(part.size.z)} ${unit.symbol}',
          ),
          Text(s.rabbetView, style: TextStyle(color: context.colors.muted)),
          _SectionPicker(
            part: draft.cutsFit ? draft : part,
            selected: edge,
            onChanged: (value) => setState(() => edge = value),
          ),
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
                        current.width.setMillimeters(null);
                        current.depth.setMillimeters(null);
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

class _SectionPicker extends StatelessWidget {
  const _SectionPicker({
    required this.part,
    required this.selected,
    required this.onChanged,
  });

  final Beam part;
  final RabbetEdge selected;
  final ValueChanged<RabbetEdge> onChanged;

  Widget marker(RabbetEdge edge, EditorPalette colors) {
    final active = selected == edge;
    return Tooltip(
      message: edge.label,
      excludeFromSemantics: true,
      child: Semantics(
        label: edge.label,
        selected: active,
        child: DeskControl(
          borderRadius: BorderRadius.circular(14),
          onPressed: () => onChanged(edge),
          child: Container(
            width: active ? 11 : 8,
            height: active ? 11 : 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? colors.accent : colors.field,
              border: Border.all(
                color: active ? colors.field : colors.muted,
                width: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return LayoutBuilder(
      builder: (_, box) {
        final target = math.min(28.0, box.maxWidth / 2);
        final scale = math.min(
          (box.maxWidth - target) / part.size.y,
          94 / part.size.z,
        );
        final section = Size(part.size.y * scale, part.size.z * scale);
        final size = Size(
          math.max(section.width, target) + target,
          math.max(section.height, target) + target,
        );
        final rect = Rect.fromCenter(
          center: size.center(Offset.zero),
          width: section.width,
          height: section.height,
        );
        final handles = (Offset.zero & size).deflate(target / 2);
        return Center(
          child: SizedBox.fromSize(
            size: size,
            child: Stack(
              fit: StackFit.expand,
              children: [
                GestureDetector(
                  key: const ValueKey('rabbet-section'),
                  behavior: HitTestBehavior.opaque,
                  excludeFromSemantics: true,
                  onTapUp: (tap) => onChanged(
                    RabbetEdge.values.firstWhere(
                      (e) =>
                          e.right == (tap.localPosition.dx >= rect.center.dx) &&
                          e.top == (tap.localPosition.dy < rect.center.dy),
                    ),
                  ),
                  child: CustomPaint(
                    painter: _SectionDiagram(
                      part,
                      selected,
                      colors,
                      rect,
                      handles,
                    ),
                  ),
                ),
                for (final edge in RabbetEdge.values)
                  Positioned.fromRect(
                    rect: Rect.fromCenter(
                      center: _corner(handles, edge),
                      width: target,
                      height: target,
                    ),
                    child: marker(edge, colors),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Offset _corner(Rect rect, RabbetEdge edge) => Offset(
  edge.right ? rect.right : rect.left,
  edge.top ? rect.top : rect.bottom,
);

class _SectionDiagram extends CustomPainter {
  const _SectionDiagram(
    this.part,
    this.selected,
    this.colors,
    this.rect,
    this.handles,
  );
  final Beam part;
  final RabbetEdge selected;
  final EditorPalette colors;
  final Rect rect, handles;

  @override
  void paint(Canvas canvas, Size size) {
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
    final corner = _corner(rect, selected);
    if (part.rabbets[selected] case final cut?) {
      final scale = rect.width / part.size.y;
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
    if (rect != handles) {
      final guide = Paint()..color = colors.muted;
      for (final edge in RabbetEdge.values) {
        canvas.drawLine(_corner(rect, edge), _corner(handles, edge), guide);
      }
    }
  }

  @override
  bool shouldRepaint(_SectionDiagram old) =>
      old.part != part ||
      old.selected != selected ||
      old.colors != colors ||
      old.rect != rect ||
      old.handles != handles;
}
