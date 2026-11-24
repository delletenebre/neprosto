import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart' show Icons, Tooltip;

import '../l10n/strings.dart';
import 'controls.dart';
import 'desktop.dart';
import 'model.dart';

class DoorIcon extends StatelessWidget {
  const DoorIcon(this.side, {this.color, super.key});
  final DoorHinge side;
  final Color? color;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: side.label,
    child: RotatedBox(
      quarterTurns: switch (side) {
        DoorHinge.left => 0,
        DoorHinge.right => 2,
        DoorHinge.top => 1,
        DoorHinge.bottom => 3,
      },
      child: Icon(Icons.meeting_room_outlined, size: 16, color: color),
    ),
  );
}

class DoorSettingsDraft {
  DoorSettingsDraft(Beam part) : hinge = part.hinge, angle = part.openingAngle;
  DoorHinge? hinge;
  double angle;
  bool _angleReadable = true;
  bool get valid => hinge == null || (_angleReadable && validDoorAngle(angle));
}

class PartTypePicker extends StatelessWidget {
  const PartTypePicker(
    this.draft, {
    required this.refresh,
    required this.submit,
    super.key,
  });
  final DoorSettingsDraft draft;
  final VoidCallback refresh, submit;

  @override
  Widget build(BuildContext context) {
    final s = context.strings;
    final label = draft.hinge?.label ?? s.ordinaryPart;
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: controlGap,
      children: [
        DeskMenu<DoorHinge?>(
          title: '${s.partType} · $label',
          selected: draft.hinge,
          items: [
            (null, s.ordinaryPart),
            for (final side in DoorHinge.values) (side, side.label),
          ],
          change: (side) {
            if (draft.hinge == null) draft._angleReadable = true;
            draft.hinge = side;
            refresh();
          },
          child: Row(
            spacing: controlGap,
            children: [
              Text(s.partType),
              Expanded(child: Text(label, textAlign: TextAlign.end)),
              const Icon(CupertinoIcons.chevron_up_chevron_down, size: 11),
            ],
          ),
        ),
        if (draft.hinge != null)
          Row(
            children: [
              Expanded(child: Text(s.doorAngle)),
              SizedBox(
                width: 90,
                child: ValueBox(
                  draft.angle,
                  (value) {
                    draft.angle = value;
                    refresh();
                  },
                  key: const ValueKey('dialog-door-angle'),
                  unit: '°',
                  live: true,
                  onSubmitted: submit,
                  onValidityChanged: (ok) {
                    if (draft._angleReadable == ok) return;
                    draft._angleReadable = ok;
                    refresh();
                  },
                ),
              ),
            ],
          ),
      ],
    );
  }
}
