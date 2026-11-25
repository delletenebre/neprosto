import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoIcons;
import 'package:flutter/widgets.dart';

import '../l10n/strings.dart';
import 'desktop.dart';
import 'palette.dart';
import 'project_tabs.dart';

typedef ProjectTabChoice = ({String action, RecentProject? recent});

Future<ProjectTabChoice?> chooseProjectForTab(
  BuildContext context,
  List<RecentProject> recent, {
  DialogSource? source,
}) => showDeskDialog<ProjectTabChoice>(
  context: context,
  source: source,
  builder: (ctx) {
    final strings = ctx.strings;
    void choose(String action, [RecentProject? project]) =>
        Navigator.pop(ctx, (action: action, recent: project));
    return DeskDialog(
      title: Text(strings.recentProjects),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (recent.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                strings.noRecentProjects,
                style: TextStyle(color: ctx.colors.muted),
              ),
            ),
          for (final project in recent)
            DeskControl(
              onPressed: () => choose('recent', project),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              child: Row(
                children: [
                  Icon(CupertinoIcons.doc, size: 18, color: ctx.colors.muted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (project.file case final file?)
                          Text(
                            file.path,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: ctx.colors.muted,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      actions: [
        DeskButton(
          plain: true,
          onPressed: () => Navigator.pop(ctx),
          child: Text(strings.cancel),
        ),
        DeskButton(
          onPressed: () => choose('open'),
          child: Text(strings.openProjectMenu),
        ),
        DeskButton(
          primary: true,
          onPressed: () => choose('new'),
          child: Text(strings.createProject),
        ),
      ],
    );
  },
);
