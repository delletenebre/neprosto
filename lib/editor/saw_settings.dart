part of 'end_cut_dialog.dart';

class _SawSetting extends StatelessWidget {
  const _SawSetting({
    required this.tool,
    required this.blade,
    required this.angle,
    required this.tableCutaway,
    this.changeView,
  });

  final SawType tool;
  final bool blade;
  final double angle;
  final bool tableCutaway;
  final ValueChanged<bool>? changeView;

  @override
  Widget build(BuildContext context) {
    final s = context.strings, colors = context.colors;
    // Handheld travel points away from the operator, opposite the miter handle.
    final reading = !blade && tool == SawType.handheld ? -angle : angle;
    final rounded = Units.angleOf(context).round(angle.abs());
    final degrees = NumberFormat('0.##', s.localeName).format(rounded);
    final value = switch ((rounded, blade, tool)) {
      (0, _, _) => '0°',
      (_, false, SawType.table) =>
        reading > 0 ? s.sawFenceNear(degrees) : s.sawFenceFar(degrees),
      _ => reading < 0 ? s.sawAngleLeft(degrees) : s.sawAngleRight(degrees),
    };
    final title = blade
        ? s.sawBladeTilt
        : switch (tool) {
            SawType.miter => s.sawTableRotation,
            SawType.handheld => s.sawCutLine,
            SawType.table => s.sawCrosscutFence,
          };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.paper,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 2,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 2,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(
            height: 150,
            child: CustomPaint(
              painter: SawPreview(
                tool: tool,
                bladeView: blade,
                angle: reading,
                angleLabel: '$degrees°',
                cutaway: tableCutaway,
                colors: colors,
                labelStyle: DefaultTextStyle.of(context).style,
                feedLabel: s.sawFeed,
              ),
            ),
          ),
          if (blade && tool == SawType.table)
            DeskSegmentedControl<bool>(
              value: tableCutaway,
              change: changeView!,
              children: {
                for (final (cutaway, label) in [
                  (true, s.sawTableSight),
                  (false, s.sawFeedView),
                ])
                  cutaway: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
              },
            ),
        ],
      ),
    );
  }
}
