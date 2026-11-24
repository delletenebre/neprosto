import '../l10n/strings.dart';
import 'palette.dart';
import 'platform_ui.dart';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:material_ui/material_ui.dart' show Tooltip;

import 'desktop.dart';
import 'project_tabs.dart';

class ProjectTabBar extends StatefulWidget {
  const ProjectTabBar({
    required this.tabs,
    required this.active,
    required this.select,
    required this.create,
    required this.close,
    required this.menuItems,
    required this.onMenuAction,
    super.key,
  });
  final List<ProjectTab> tabs;
  final ProjectTab active;
  final ValueChanged<ProjectTab> select, close;
  final VoidCallback create;
  final List<(String, String)> menuItems;
  final ValueChanged<String> onMenuAction;

  @override
  State<ProjectTabBar> createState() => _ProjectTabBarState();
}

class _ProjectTabBarState extends State<ProjectTabBar> {
  final activeKey = GlobalKey();
  ProjectTab? hovered;

  void revealActive() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = activeKey.currentContext;
      if (context != null) Scrollable.ensureVisible(context, alignment: .5);
    });
  }

  @override
  void initState() {
    super.initState();
    revealActive();
  }

  @override
  void didUpdateWidget(ProjectTabBar old) {
    super.didUpdateWidget(old);
    if (widget.active != old.active) revealActive();
  }

  Widget tabButton(ProjectTab tab, {double? width}) {
    final selected = tab == widget.active;
    final name = tab.committed.name;
    final description = tab.dirty ? context.strings.unsavedTab(name) : name;
    final foreground = selected ? context.colors.ink : context.colors.muted;
    final showClose = hovered == tab;
    final label = Text(
      name,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: width == null ? TextAlign.start : TextAlign.center,
      style: TextStyle(
        fontSize: macControls ? 12 : 13,
        color: foreground,
        fontWeight: selected
            ? FontWeight.w600
            : macControls
            ? FontWeight.w400
            : FontWeight.w500,
      ),
    );
    final content = Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: controlGap,
        children: [
          SizedBox(
            width: 29,
            height: 28,
            child: showClose
                ? null
                : Center(
                    child: Icon(
                      CupertinoIcons.folder,
                      size: 16,
                      color: foreground,
                    ),
                  ),
          ),
          if (width == null)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: label,
            )
          else
            Expanded(child: label),
          if (tab.dirty)
            Icon(
              CupertinoIcons.circle_fill,
              size: 5,
              color: context.colors.accent,
            ),
          if (selected)
            Icon(CupertinoIcons.chevron_down, size: 11, color: foreground),
        ],
      ),
    );
    return MouseRegion(
      key: ObjectKey(tab),
      onEnter: (_) => setState(() => hovered = tab),
      onExit: (_) {
        if (hovered == tab) setState(() => hovered = null);
      },
      child: Container(
        key: selected ? activeKey : null,
        width: width,
        padding: EdgeInsets.symmetric(
          horizontal: 3,
          vertical: macControls ? 0 : 2,
        ),
        decoration: BoxDecoration(
          color: macControls
              ? (selected ? context.colors.panel : context.colors.chrome)
              : (selected ? context.colors.pale : context.colors.panel),
          border: macControls
              ? BorderDirectional(
                  end: BorderSide(color: context.colors.line, width: .7),
                  bottom: BorderSide(
                    color: selected
                        ? EditorPalette.highlight
                        : context.colors.line,
                    width: selected ? 2 : .7,
                  ),
                )
              : Border.all(
                  color: selected ? context.colors.accent : context.colors.line,
                ),
          borderRadius: macControls ? null : BorderRadius.circular(7),
        ),
        child: Stack(
          alignment: AlignmentDirectional.centerStart,
          children: [
            Semantics(
              selected: selected,
              child: selected
                  ? DeskMenu<String>(
                      title: '${context.strings.project} · $description',
                      items: widget.menuItems,
                      dividers: {
                        if (widget.menuItems.first.$1 != 'save') 'save',
                        'rename',
                        'close',
                      },
                      change: widget.onMenuAction,
                      child: content,
                    )
                  : Tooltip(
                      message: description,
                      child: DeskControl(
                        onPressed: () => widget.select(tab),
                        child: content,
                      ),
                    ),
            ),
            if (showClose)
              PositionedDirectional(
                start: 0,
                child: DeskIcon(
                  CupertinoIcons.xmark,
                  context.strings.closeProjectTab(name),
                  () => widget.close(tab),
                  size: 13,
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final width = macControls
          ? ((box.maxWidth - 35) / widget.tabs.length - 1).clamp(
              140.0,
              widget.tabs.length == 1 ? 290.0 : double.infinity,
            )
          : null;
      return Row(
        spacing: macControls ? 0 : toolbarGap,
        children: [
          Flexible(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(context).copyWith(
                scrollbars: false,
                dragDevices: {
                  ...ScrollConfiguration.of(context).dragDevices,
                  PointerDeviceKind.mouse,
                },
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  spacing: macControls ? 1 : controlGap,
                  children: [
                    for (final tab in widget.tabs) tabButton(tab, width: width),
                  ],
                ),
              ),
            ),
          ),
          DeskIcon(
            CupertinoIcons.plus,
            context.strings.newProject,
            widget.create,
            size: macControls ? 15 : 17,
          ),
        ],
      );
    },
  );
}
