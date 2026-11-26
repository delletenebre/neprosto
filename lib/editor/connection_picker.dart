import 'package:material_ui/material_ui.dart';

import '../l10n/strings.dart';
import 'controller.dart';
import 'desktop.dart';
import 'model.dart';
import 'palette.dart';

Future<void> chooseConnection(BuildContext context, Editor editor) async {
  final result = await showDeskDialog<ConnectionPattern>(
    context: context,
    builder: (_) => _ConnectionPicker(
      editor.connectionPattern,
      editor.connectionRuler,
      editor.displayUnit,
    ),
  );
  if (result != null && context.mounted) editor.beginConnection(result);
}

class _ConnectionPicker extends StatefulWidget {
  const _ConnectionPicker(this.previous, this.ruler, this.unit);
  final ConnectionPattern previous;
  final ConnectionRuler ruler;
  final LengthUnit unit;
  @override
  State<_ConnectionPicker> createState() => _ConnectionPickerState();
}

class _ConnectionPickerState extends State<_ConnectionPicker> {
  late ConnectionKind kind = widget.previous.kind;
  late int count = widget.previous.dowels;
  late DowelSide side = widget.previous.side;
  late bool back = widget.previous.back;
  @override
  Widget build(BuildContext context) {
    final s = context.strings, colors = context.colors;
    final pattern = ConnectionPattern(
      kind,
      dowels: count,
      side: side,
      back: back,
    );
    final alone = kind == ConnectionKind.dowel;
    return DeskDialog(
      maxWidth: 525,
      title: Text(s.addConnection),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final choice in ConnectionKind.values)
                DeskButton(
                  key: ValueKey('connection-${choice.name}'),
                  primary: kind == choice,
                  child: Text(choice.label),
                  onPressed: () => setState(() {
                    if (kind == choice) return;
                    kind = choice;
                    count = choice == ConnectionKind.dowel ? 1 : 0;
                  }),
                ),
            ],
          ),
          if (kind != ConnectionKind.pocket) ...[
            Text(s.dowels),
            DeskSegments(
              count,
              {
                for (final n in (alone ? [1, 2, 3] : [0, 1, 2])) n: '$n',
              },
              (n) => setState(() {
                count = n;
                if (n == 1 && side == DowelSide.both) side = DowelSide.after;
                if (n == 2 && !alone) side = DowelSide.both;
              }),
            ),
            if (!alone && count > 0)
              DeskSegments(side, {
                DowelSide.before: s.beforeHardware,
                if (count == 2) DowelSide.both: s.bothHardware,
                DowelSide.after: s.afterHardware,
              }, (v) => setState(() => side = v)),
          ],
          if ([
            ConnectionKind.minifix,
            ConnectionKind.maxifix,
            ConnectionKind.pocket,
          ].contains(kind))
            DeskSegments(back, {
              false: s.faceA,
              true: s.faceB,
            }, (v) => setState(() => back = v)),
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.field,
              border: Border.all(color: colors.line),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  Text(
                    s.baseDistance,
                    style: TextStyle(color: colors.muted, fontSize: 12),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final (i, item) in pattern.stations.indexed)
                        Expanded(
                          child: Column(
                            spacing: 3,
                            children: [
                              SizedBox(
                                height: 16,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Positioned(
                                      left: 0,
                                      right: 0,
                                      child: Divider(
                                        height: 1,
                                        color: colors.line,
                                      ),
                                    ),
                                    Container(
                                      width: item == ConnectionKind.dowel
                                          ? 9
                                          : 13,
                                      height: item == ConnectionKind.dowel
                                          ? 9
                                          : 13,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: item == ConnectionKind.dowel
                                            ? colors.field
                                            : colors.accent,
                                        border: Border.all(
                                          color: colors.accent,
                                          width: 1.6,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${widget.unit.format(widget.ruler.first + i * widget.ruler.pitch)} ${widget.unit.symbol}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                item.label,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
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
          onPressed: () => Navigator.pop(context, pattern),
          child: Text(s.placeOnDrawing),
        ),
      ],
    );
  }
}
