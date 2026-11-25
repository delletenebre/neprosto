import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoIcons;
import 'package:material_ui/material_ui.dart';

import '../l10n/strings.dart';
import 'controller.dart';
import 'controls.dart';
import 'desktop.dart';
import 'palette.dart';
import 'platform_ui.dart';
import 'scene.dart';
import 'view_angle_icon.dart';

class ViewportFooter extends StatelessWidget {
  const ViewportFooter(
    this.editor, {
    required this.setRulerSnap,
    required this.editSettings,
    super.key,
  });

  final Editor editor;
  final ValueChanged<bool> setRulerSnap;
  final VoidCallback editSettings;

  @override
  Widget build(BuildContext context) {
    final s = context.strings, colors = context.colors;
    final ruler = editor.tool == Tool.measure;
    final snap = ruler ? editor.snapByDefault : editor.snap;
    final mode = snap ? editor.snapMode.label : s.off;
    final unit = editor.displayUnit;

    void changeSnap(bool enabled, [SnapMode? mode]) {
      if (mode != null) editor.snapMode = mode;
      editor.hover = null;
      if (ruler) {
        setRulerSnap(enabled);
      } else {
        editor.snap = enabled;
        editor.refresh();
      }
    }

    Widget group(Widget control, {Widget? leading}) => Material(
      color: colors.field,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: colors.line, width: .8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[
              leading,
              SizedBox(
                height: 15,
                child: VerticalDivider(width: 5, color: colors.line),
              ),
            ],
            Flexible(child: control),
          ],
        ),
      ),
    );

    Widget viewButton(ViewAngle angle) {
      final selected = editor.selectedView == angle;
      return Tooltip(
        message: selected && editor.activeView == null
            ? '${s.freeView} · ${angle.label}'
            : angle.label,
        child: Semantics(
          selected: selected,
          child: DeskControl(
            key: ValueKey(angle),
            onPressed: () => editor.setView(angle),
            minimumSize: const Size(28, 26),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            background: selected ? colors.pale : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 5,
              children: [
                ViewAngleIcon(
                  angle,
                  color: selected ? colors.accent : colors.muted,
                ),
                if (selected)
                  Text(
                    angle.label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    Widget viewGroup(List<ViewAngle> angles) => group(
      Wrap(
        spacing: 2,
        runSpacing: 2,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: angles.map(viewButton).toList(),
      ),
    );
    final views = Semantics(
      container: true,
      explicitChildNodes: true,
      label: s.views,
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          viewGroup(const [ViewAngle.perspective, ViewAngle.iso]),
          viewGroup(const [
            ViewAngle.top,
            ViewAngle.bottom,
            ViewAngle.front,
            ViewAngle.back,
            ViewAngle.left,
            ViewAngle.right,
          ]),
        ],
      ),
    );

    final step = group(
      Tooltip(
        message: s.editingIncrement,
        child: DeskButton(
          plain: true,
          onPressed: editSettings,
          child: Text(s.step(editor.step.label(unit))),
        ),
      ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.panel,
        border: Border(top: BorderSide(color: colors.line, width: .7)),
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final snapControl = group(
            MenuChoice<SnapMode>(
              label: '${s.snapToAnchors} · $mode',
              compactLabel: mode,
              selected: snap ? editor.snapMode : null,
              items: [
                for (final value in SnapMode.values) (value, value.label),
              ],
              change: (value) => changeSnap(true, value),
            ),
            leading: Tooltip(
              message: ruler
                  ? s.rulerSnapModifier(primaryModifierLabel)
                  : s.snapToAnchors,
              child: Semantics(
                label: s.snapToAnchors,
                toggled: snap,
                child: DeskControl(
                  onPressed: () => changeSnap(!snap),
                  minimumSize: const Size(26, 24),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  background: snap ? colors.pale : null,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 5,
                    children: [
                      Icon(
                        CupertinoIcons.scope,
                        size: 15,
                        color: snap ? colors.accent : colors.muted,
                      ),
                      if (box.maxWidth >= 540)
                        Text(
                          s.snapLabel,
                          style: TextStyle(fontSize: 12, color: colors.ink),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
          final settings = Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [snapControl, step],
          );
          return Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 4,
            children: [views, settings],
          );
        },
      ),
    );
  }
}
