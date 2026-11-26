import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoIcons;
import 'package:material_ui/material_ui.dart';

import '../l10n/strings.dart';
import 'controls.dart';
import 'desk_text_field.dart';
import 'desktop.dart';
import 'finish_painter.dart';
import 'palette.dart';
import 'part_finish.dart';

int? parseHexColor(String text) {
  final digits = text.trim().replaceFirst(RegExp('^#'), '');
  return RegExp(r'^[a-fA-F0-9]{6}$').hasMatch(digits)
      ? int.parse(digits, radix: 16)
      : null;
}

FinishPreset? _presetFor(PartFinish? finish) =>
    FinishPreset.values.where((p) => p.finish == finish).firstOrNull;

class PartFinishButton extends StatelessWidget {
  const PartFinishButton(this.finish, this.onChanged, {super.key});
  final PartFinish? finish;
  final ValueChanged<PartFinish> onChanged;

  @override
  Widget build(BuildContext context) {
    final current = finish;
    return DeskButton(
      onPressed: () async {
        final chosen = await showDeskDialog<PartFinish>(
          context: context,
          builder: (_) => _FinishDialog(current ?? woodFinish),
        );
        if (context.mounted && chosen != null && chosen != finish) {
          onChanged(chosen);
        }
      },
      child: Row(
        spacing: controlGap,
        children: [
          if (current != null)
            Tooltip(
              message: [
                if (current.texture.material == PartMaterial.panel)
                  context.strings.woodBasedPanelFullName,
                _presetFor(current)?.label ?? hexColor(current.rgb),
              ].join(' · '),
              child: _Sample(current),
            ),
          Expanded(
            child: Text(
              current?.texture.material.label ?? context.strings.mixedValues,
            ),
          ),
          const Icon(CupertinoIcons.chevron_down, size: 13),
        ],
      ),
    );
  }
}

class _FinishDialog extends StatefulWidget {
  const _FinishDialog(this.initial);
  final PartFinish initial;

  @override
  State<_FinishDialog> createState() => _FinishDialogState();
}

class _FinishDialogState extends State<_FinishDialog> {
  late PartFinish finish = widget.initial;
  final materialDrafts = <PartMaterial, PartFinish>{};
  late final hex = TextEditingController(text: hexColor(finish.rgb));
  bool valid = true;

  @override
  void dispose() {
    hex.dispose();
    super.dispose();
  }

  void select(PartFinish value) => setState(() {
    finish = value;
    valid = true;
    hex.text = hexColor(value.rgb);
  });

  void typeColor(String value) => setState(() {
    final rgb = parseHexColor(value);
    valid = rgb != null;
    if (rgb != null) finish = (texture: finish.texture, rgb: rgb);
  });

  void apply() {
    if (valid) Navigator.pop(context, finish);
  }

  @override
  Widget build(BuildContext context) => DeskDialog(
    maxWidth: 390,
    title: Text(context.strings.partFinish),
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DeskSegments(
          finish.texture.material,
          {
            for (final material in PartMaterial.values)
              material: material.label,
          },
          (material) {
            if (material == finish.texture.material) return;
            materialDrafts[finish.texture.material] = finish;
            select(materialDrafts[material] ?? material.defaultPreset.finish);
          },
        ),
        const SizedBox(height: 14),
        _Sample(finish, height: 48),
        const SizedBox(height: 14),
        FinishColorPicker(
          label: finish.texture.material == PartMaterial.panel
              ? context.strings.panelFaceColor
              : context.strings.finishColor,
          selectedRgb: finish.rgb,
          hex: hex,
          valid: valid,
          onText: typeColor,
          onSelect: (rgb) => select((texture: finish.texture, rgb: rgb)),
          apply: apply,
        ),
      ],
    ),
    actions: [
      DeskButton(
        plain: true,
        onPressed: () => Navigator.pop(context),
        child: Text(context.strings.cancel),
      ),
      DeskButton(
        primary: true,
        onPressed: valid ? apply : null,
        child: Text(context.strings.apply),
      ),
    ],
  );
}

class FinishColorPicker extends StatelessWidget {
  const FinishColorPicker({
    super.key,
    required this.label,
    required this.selectedRgb,
    required this.hex,
    required this.valid,
    required this.onText,
    required this.onSelect,
    required this.apply,
  });
  final String label;
  final int selectedRgb;
  final TextEditingController hex;
  final bool valid;
  final ValueChanged<String> onText;
  final ValueChanged<int> onSelect;
  final VoidCallback apply;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Expanded(child: sectionTitle(label)),
          SizedBox(
            width: 100,
            child: DeskTextField(
              controller: hex,
              placeholder: '#RRGGBB',
              onChanged: onText,
              onSubmitted: (_) => apply(),
            ),
          ),
        ],
      ),
      if (!valid)
        Text(
          context.strings.invalidHexColor,
          style: TextStyle(color: context.colors.danger),
        ),
      const SizedBox(height: 8),
      Wrap(
        spacing: controlGap,
        runSpacing: controlGap,
        children: [
          for (final (rgb, name) in [
            (FinishPreset.plywood.finish.rgb, context.strings.plywood),
            (woodFinish.rgb, context.strings.pineColor),
            (FinishPreset.oakBoard.finish.rgb, context.strings.oakColor),
            (FinishPreset.whiteBoard.finish.rgb, context.strings.whiteColor),
            (0xd9c9b3, context.strings.beigeColor),
            (FinishPreset.aluminum.finish.rgb, context.strings.grayColor),
            (
              FinishPreset.graphiteSteel.finish.rgb,
              context.strings.graphiteColor,
            ),
            (0x252629, context.strings.blackColor),
            (0x456351, context.strings.greenColor),
            (0x446688, context.strings.blueColor),
            (0xa44c3c, context.strings.brickColor),
          ])
            Tooltip(
              message: '$name · ${hexColor(rgb)}',
              child: Semantics(
                label: name,
                selected: valid && selectedRgb == rgb,
                child: DeskControl(
                  minimumSize: const Size.square(27),
                  background: Color(0xff000000 | rgb),
                  outlined: true,
                  onPressed: () => onSelect(rgb),
                  child: valid && selectedRgb == rgb
                      ? Icon(
                          CupertinoIcons.check_mark,
                          size: 15,
                          color:
                              Color(0xff000000 | rgb).computeLuminance() < .35
                              ? Colors.white
                              : Colors.black,
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
        ],
      ),
    ],
  );
}

class _Sample extends StatelessWidget {
  const _Sample(this.finish, {this.height = 16});
  final PartFinish finish;
  final double height;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(3),
    child: CustomPaint(
      size: Size(35, height),
      painter: _SamplePainter(finish),
    ),
  );
}

class _SamplePainter extends CustomPainter {
  const _SamplePainter(this.finish);
  final PartFinish finish;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final color = finishColor(finish);
    canvas.drawRect(rect, Paint()..color = color);
    paintFinishTexture(
      canvas,
      finish.texture,
      color,
      rect.topLeft,
      rect.topRight,
      rect.bottomRight,
      rect.bottomLeft,
    );
    canvas.drawRect(
      rect.deflate(.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..color = const Color(0x35000000),
    );
  }

  @override
  bool shouldRepaint(_SamplePainter old) => old.finish != finish;
}
