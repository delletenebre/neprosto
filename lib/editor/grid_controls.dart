import '../l10n/strings.dart';
import 'palette.dart';

import 'package:cupertino_ui/cupertino_ui.dart';

import 'desktop.dart';
import 'grid_visibility.dart';

class GridControls extends StatelessWidget {
  const GridControls(this.value, this.changed, {super.key});
  final GridVisibility value;
  final ValueChanged<GridVisibility> changed;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    spacing: controlGap,
    children: [
      DeskSegments(value.automatic, {
        true: context.strings.workPlane,
        false: context.strings.byAxes,
      }, (automatic) => changed(value.follow(automatic))),
      if (!value.automatic) ...[
        for (final plane in GridPlane.values)
          Semantics(
            checked: value.planes.contains(plane),
            child: DeskControl(
              key: ValueKey('grid-${plane.name}'),
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
              minimumSize: const Size(0, 28),
              onPressed: () => changed(value.toggle(plane)),
              child: Row(
                children: [
                  Icon(
                    value.planes.contains(plane)
                        ? CupertinoIcons.check_mark_circled_solid
                        : CupertinoIcons.circle,
                    size: 17,
                    color: value.planes.contains(plane)
                        ? plane.color
                        : context.colors.muted,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${plane.axes} · ${plane.label}',
                    style: TextStyle(fontSize: 13, color: context.colors.ink),
                  ),
                ],
              ),
            ),
          ),
      ],
    ],
  );
}
