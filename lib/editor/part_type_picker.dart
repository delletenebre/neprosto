import 'dart:math' as math;

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart' show Tooltip;
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../l10n/strings.dart';
import 'controls.dart';
import 'desktop.dart';
import 'model.dart';
import 'palette.dart';

class DoorIcon extends StatelessWidget {
  const DoorIcon(this.side, {this.color, super.key});
  final DoorHinge side;
  final Color? color;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: side.label,
    child: Icon(PhosphorIconsRegular.door, size: 16, color: color),
  );
}

class DoorSettingsDraft {
  DoorSettingsDraft(Beam part) : hinge = part.hinge, angle = part.openingAngle;

  DoorHinge? hinge;
  DoorHinge _lastSide = DoorHinge.left;
  double angle;
  bool _angleReadable = true;
  bool get valid => hinge == null || (_angleReadable && validDoorAngle(angle));

  void setDoor(bool value) {
    if (value == (hinge != null)) return;
    _lastSide = hinge ?? _lastSide;
    hinge = value ? _lastSide : null;
    _angleReadable = true;
    if (!validDoorAngle(angle)) angle = 90;
  }
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
    final s = context.strings, colors = context.colors;
    final hinge = draft.hinge;
    final caption = TextStyle(color: colors.muted, fontSize: 12);
    final edges = {
      DoorHinge.left: s.hingesLeft,
      DoorHinge.right: s.hingesRight,
      DoorHinge.top: s.hingesTop,
      DoorHinge.bottom: s.hingesBottom,
    };
    Widget type(bool door) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 5,
        children: [
          Icon(
            door ? PhosphorIconsRegular.door : PhosphorIconsRegular.rectangle,
            size: 15,
            color: (hinge != null) == door
                ? EditorPalette.onHighlight
                : colors.ink,
          ),
          Flexible(
            child: Text(
              door ? s.doorPanel : s.ordinaryPart,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: controlGap,
      children: [
        Text(s.partType, style: caption),
        DeskSegmentedControl<bool>(
          value: hinge != null,
          children: {false: type(false), true: type(true)},
          change: (door) {
            draft.setDoor(door);
            refresh();
          },
        ),
        if (hinge != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              spacing: 12,
              children: [
                _HingeDiagram(hinge, edges, (side) {
                  draft.hinge = side;
                  refresh();
                }),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        edges[hinge]!,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 3),
                      Text(s.chooseHingeEdge, style: caption),
                      const SizedBox(height: 12),
                      Text(s.doorAngle, style: caption),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 92,
                        child: ValueBox(
                          draft.angle,
                          (value) {
                            draft.angle = value;
                            refresh();
                          },
                          key: const ValueKey('dialog-door-angle'),
                          angle: true,
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
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _HingeDiagram extends StatelessWidget {
  const _HingeDiagram(this.selected, this.labels, this.select);
  final DoorHinge selected;
  final Map<DoorHinge, String> labels;
  final ValueChanged<DoorHinge> select;

  // The visible outline runs through the middle of each edge button.
  static const inset = 16.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    Widget edge(DoorHinge side) => SizedBox(
      width: side.onSide ? inset * 2 : double.infinity,
      height: side.onSide ? double.infinity : inset * 2,
      child: Tooltip(
        message: labels[side]!,
        child: Semantics(
          selected: side == selected,
          inMutuallyExclusiveGroup: true,
          child: DeskControl(
            onPressed: () => select(side),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
    return Container(
      key: const ValueKey('hinge-diagram'),
      width: 112,
      height: 132,
      decoration: BoxDecoration(
        color: colors.paper,
        border: Border.all(color: colors.line),
        borderRadius: BorderRadius.circular(7),
      ),
      child: CustomPaint(
        painter: _DoorFace(selected, colors),
        child: Column(
          children: [
            edge(DoorHinge.top),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [edge(DoorHinge.left), edge(DoorHinge.right)],
              ),
            ),
            edge(DoorHinge.bottom),
          ],
        ),
      ),
    );
  }
}

class _DoorFace extends CustomPainter {
  const _DoorFace(this.side, this.colors);
  final DoorHinge side;
  final EditorPalette colors;

  @override
  void paint(Canvas canvas, Size size) {
    // Draw a left-hinged front in local coordinates, then rotate it around
    // its centre. Swapping the spans for top/bottom keeps the front upright.
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(switch (side) {
      DoorHinge.left => 0.0,
      DoorHinge.top => math.pi / 2,
      DoorHinge.right => math.pi,
      DoorHinge.bottom => -math.pi / 2,
    });
    final face = Rect.fromCenter(
      center: Offset.zero,
      width: (side.onSide ? size.width : size.height) - 2 * _HingeDiagram.inset,
      height:
          (side.onSide ? size.height : size.width) - 2 * _HingeDiagram.inset,
    );
    final ink = Paint()..color = colors.muted;
    canvas.drawRect(face, Paint()..color = colors.chrome);
    canvas.drawRect(
      face,
      Paint()
        ..color = colors.muted
        ..style = PaintingStyle.stroke,
    );
    canvas.drawLine(
      face.topLeft,
      face.bottomLeft,
      Paint()
        ..color = colors.accent
        ..strokeWidth = 2,
    );
    for (final fraction in [.22, .78]) {
      final center = Offset(face.left, face.top + face.height * fraction);
      final barrel = RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 6, height: 13),
        const Radius.circular(2),
      );
      canvas.drawRRect(barrel, Paint()..color = EditorPalette.highlight);
      canvas.drawRRect(
        barrel,
        Paint()
          ..color = colors.accent
          ..style = PaintingStyle.stroke,
      );
    }
    final handle = Rect.fromCenter(
      center: Offset(face.right - 8, 0),
      width: 3,
      height: 14,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(handle, const Radius.circular(1.5)),
      ink,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_DoorFace old) => old.side != side || old.colors != colors;
}
