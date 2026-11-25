import '../l10n/strings.dart';
import 'palette.dart';
import 'platform_ui.dart';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:material_ui/material_ui.dart' as m;

import 'desktop.dart';
import 'project_tabs.dart';

class ProjectTabBar extends StatefulWidget {
  const ProjectTabBar({
    required this.tabs,
    required this.active,
    required this.select,
    required this.create,
    this.newProjectButton,
    required this.close,
    required this.menuItems,
    required this.onMenuAction,
    super.key,
  });
  final List<ProjectTab> tabs;
  final ProjectTab active;
  final ValueChanged<ProjectTab> select, close;
  final VoidCallback create;
  final Key? newProjectButton;
  final List<(String, String)> menuItems;
  final void Function(String action, ProjectTab tab) onMenuAction;

  @override
  State<ProjectTabBar> createState() => _ProjectTabBarState();
}

class _ProjectTabBarState extends State<ProjectTabBar> {
  ProjectTab? hovered;
  BorderRadius? get tabRadius => macControls ? BorderRadius.zero : null;

  void revealActive() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final context = GlobalObjectKey(widget.active).currentContext;
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

  Future<void> showTabMenu(ProjectTab tab, Offset position) async {
    final source = DialogSource.of(GlobalObjectKey(tab).currentContext);
    final index = await showDeskPopup(
      context,
      position,
      title: tab.committed.name,
      showTitle: true,
      source: source,
      rows: [
        DeskPopupRow(context.strings.rename, symbol: 'pencil'),
        DeskPopupRow(
          context.strings.closeTab,
          symbol: 'xmark',
          breakBefore: true,
        ),
      ],
    );
    if (!mounted || index == null || !widget.tabs.contains(tab)) return;
    DialogSource.invoke(
      source,
      () => widget.onMenuAction(index == 0 ? 'rename' : 'close', tab),
    );
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
      padding: macControls
          ? const EdgeInsetsDirectional.only(start: 3, end: 11)
          : const EdgeInsetsDirectional.only(end: 8),
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
    final body = Container(
      key: GlobalObjectKey(tab),
      width: width,
      padding: macControls
          ? EdgeInsets.zero
          : const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
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
        fit: macControls ? StackFit.expand : StackFit.loose,
        alignment: AlignmentDirectional.centerStart,
        children: [
          Semantics(
            selected: selected,
            child: selected
                ? DeskMenu<String>(
                    title: '${context.strings.project} · $description',
                    borderRadius: tabRadius,
                    items: widget.menuItems,
                    dividers: {
                      if (widget.menuItems.first.$1 != 'save') 'save',
                      'rename',
                      'close',
                    },
                    change: (action) => widget.onMenuAction(action, tab),
                    child: content,
                  )
                : m.Tooltip(
                    message: description,
                    child: DeskControl(
                      onPressed: () => widget.select(tab),
                      borderRadius: tabRadius,
                      child: content,
                    ),
                  ),
          ),
          if (showClose)
            PositionedDirectional(
              start: macControls ? 3 : 0,
              child: macControls
                  ? _MacTabCloseButton(
                      label: context.strings.closeProjectTab(name),
                      onPressed: () => widget.close(tab),
                    )
                  : DeskIcon(
                      CupertinoIcons.xmark,
                      context.strings.closeProjectTab(name),
                      () => widget.close(tab),
                      size: 13,
                    ),
            ),
        ],
      ),
    );
    return MouseRegion(
      key: ObjectKey(tab),
      onEnter: (_) => setState(() => hovered = tab),
      onExit: (_) {
        if (hovered == tab) setState(() => hovered = null);
      },
      child: macControls
          ? GestureDetector(
              excludeFromSemantics: true,
              onSecondaryTapUp: (details) =>
                  showTabMenu(tab, details.globalPosition),
              child: body,
            )
          : body,
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
        crossAxisAlignment: macControls
            ? CrossAxisAlignment.stretch
            : CrossAxisAlignment.center,
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
                  crossAxisAlignment: macControls
                      ? CrossAxisAlignment.stretch
                      : CrossAxisAlignment.center,
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
            key: widget.newProjectButton,
            borderRadius: tabRadius,
            size: macControls ? 15 : 17,
          ),
        ],
      );
    },
  );
}

class _MacTabCloseButton extends StatelessWidget {
  const _MacTabCloseButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final dark = context.colors.isDark;
    final ink = dark ? m.Colors.white : m.Colors.black;
    return m.Tooltip(
      message: label,
      waitDuration: const Duration(milliseconds: 600),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 29, maxHeight: 28),
        child: m.TextButton(
          onPressed: () =>
              DialogSource.invoke(DialogSource.of(context), onPressed),
          style:
              m.TextButton.styleFrom(
                minimumSize: const Size.square(16),
                fixedSize: const Size.square(16),
                padding: EdgeInsets.zero,
                visualDensity: m.VisualDensity.standard,
                tapTargetSize: m.MaterialTapTargetSize.padded,
                splashFactory: m.NoSplash.splashFactory,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ).copyWith(
                overlayColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.pressed)) {
                    return ink.withValues(alpha: dark ? .18 : .14);
                  }
                  if (states.contains(WidgetState.hovered)) {
                    return ink.withValues(alpha: dark ? .10 : .20);
                  }
                  return m.Colors.transparent;
                }),
                side: WidgetStateProperty.resolveWith(
                  (states) => states.contains(WidgetState.focused)
                      ? BorderSide(color: context.colors.accent, width: 1.5)
                      : BorderSide.none,
                ),
              ),
          child: Icon(
            CupertinoIcons.xmark,
            size: 11,
            color: ink.withValues(alpha: dark ? .40 : .44),
          ),
        ),
      ),
    );
  }
}
