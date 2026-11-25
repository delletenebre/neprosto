import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoIcons;
import 'package:material_ui/material_ui.dart';

import '../l10n/strings.dart';
import 'controls.dart';
import 'desk_text_field.dart';
import 'desktop.dart';
import 'finish_painter.dart';
import 'palette.dart';
import 'part_finish.dart';

String _hex(int rgb) =>
    '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';

FinishPreset? _presetFor(PartFinish? finish) =>
    FinishPreset.values.where((p) => p.finish == finish).firstOrNull;

class PartFinishButton extends StatelessWidget {
  const PartFinishButton(this.finish, this.onChanged, {super.key});
  final PartFinish? finish;
  final ValueChanged<PartFinish> onChanged;

  @override
  Widget build(BuildContext context) {
    final current = finish;
    final preset = _presetFor(current);
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
          if (current != null) _Sample(current),
          Expanded(
            child: Text(
              preset?.label ??
                  current?.texture.label ??
                  context.strings.mixedValues,
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
  late final hex = TextEditingController(text: _hex(finish.rgb));
  bool valid = true;

  @override
  void dispose() {
    hex.dispose();
    super.dispose();
  }

  void select(PartFinish value) => setState(() {
    finish = value;
    valid = true;
    hex.text = _hex(value.rgb);
  });

  void typeColor(String value) => setState(() {
    final digits = value.trim().replaceFirst(RegExp('^#'), '');
    valid = RegExp(r'^[a-fA-F0-9]{6}$').hasMatch(digits);
    if (valid) {
      finish = (texture: finish.texture, rgb: int.parse(digits, radix: 16));
    }
  });

  void apply() {
    if (valid) Navigator.pop(context, finish);
  }

  Widget presetPicker(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: context.colors.field,
      border: Border.all(color: context.colors.line),
      borderRadius: BorderRadius.circular(6),
    ),
    child: DropdownButton<FinishPreset>(
      value: valid ? _presetFor(finish) : null,
      hint: Text(context.strings.chooseFinishPreset),
      isDense: true,
      isExpanded: true,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      underline: const SizedBox.shrink(),
      icon: const Icon(CupertinoIcons.chevron_down, size: 14),
      borderRadius: BorderRadius.circular(6),
      dropdownColor: context.colors.field,
      style: DefaultTextStyle.of(context).style
          .copyWith(fontSize: 13, color: context.colors.ink),
      onChanged: (preset) {
        if (preset != null) select(preset.finish);
      },
      items: [
        for (final preset in FinishPreset.values)
          DropdownMenuItem(
            value: preset,
            child: Row(
              spacing: controlGap,
              children: [
                _Sample(preset.finish, width: 22),
                Flexible(
                  child: Text(preset.label, overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => DeskDialog(
    maxWidth: 390,
    title: Text(context.strings.partFinish),
    content: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Sample(finish, height: 48),
        const SizedBox(height: 14),
        sectionTitle(context.strings.finishPresets),
        const SizedBox(height: 6),
        presetPicker(context),
        const SizedBox(height: 14),
        sectionTitle(context.strings.finishTexture),
        const SizedBox(height: 6),
        DeskSegments(
          finish.texture.choice,
          {for (final texture in PartTexture.choices) texture: texture.label},
          (texture) =>
              setState(() => finish = (texture: texture, rgb: finish.rgb)),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: sectionTitle(context.strings.finishColor)),
            SizedBox(
              width: 100,
              child: DeskTextField(
                controller: hex,
                placeholder: '#RRGGBB',
                onChanged: typeColor,
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
                message: '$name · ${_hex(rgb)}',
                child: Semantics(
                  label: name,
                  selected: valid && finish.rgb == rgb,
                  child: DeskControl(
                    minimumSize: const Size.square(27),
                    background: Color(0xff000000 | rgb),
                    outlined: true,
                    onPressed: () =>
                        select((texture: finish.texture, rgb: rgb)),
                    child: valid && finish.rgb == rgb
                        ? Icon(
                            CupertinoIcons.check_mark,
                            size: 15,
                            color: finishColor(finish).computeLuminance() < .35
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

class _Sample extends StatelessWidget {
  const _Sample(this.finish, {this.width = 35, this.height = 16});
  final PartFinish finish;
  final double width, height;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(3),
    child: CustomPaint(
      size: Size(width, height),
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
