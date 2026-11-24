import '../l10n/strings.dart';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/services.dart';

import 'assembly.dart';
import 'controller.dart';
import 'controls.dart';
import 'desk_text_field.dart';
import 'desktop.dart';
import 'model.dart';
import 'palette.dart';

Future<void> showProjectSettings(BuildContext context, Editor editor) async {
  final project = editor.project;
  final bounds = project.partBounds;
  final partSize = bounds == null ? null : bounds.high - bounds.low;
  final originalSize =
      project.workspaceSize ?? partSize ?? Vector3(3000, 3000, 2500);
  final size = originalSize.clone();
  final invalid = <int>{};
  var name = project.name;
  var resizeProducts = false;
  String? resizeError;
  final result = await showDeskDialog<Project>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (_, update) {
        Project namedProject() =>
            name == project.name ? project : project.copy(name: name);
        void toggleResize(bool value) => update(() {
          resizeProducts = value;
          resizeError = null;
        });
        void apply() {
          if (name.isEmpty || invalid.isNotEmpty) return;
          var next = namedProject();
          if (resizeProducts && partSize != null) {
            final ids = project.byId.keys.toSet();
            for (var i = 0; i < 3; i++) {
              if (size[i] == originalSize[i]) continue;
              final target = partSize[i] * (size[i] / originalSize[i]);
              final resized = resizeAssembly(next, ids, axis(i), target);
              if (resized.error != null) {
                update(() => resizeError = resized.error);
                return;
              }
              next = resized.project;
            }
          }
          final renameOnly = name != project.name && size == originalSize;
          if (!renameOnly && size != project.workspaceSize) {
            next = next.withWorkspace(size.clone());
          }
          Navigator.pop(ctx, next);
        }

        return CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.escape): () =>
                Navigator.pop(ctx),
          },
          child: DeskDialog(
            maxWidth: 360,
            title: Text(context.strings.projectSettings),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                sectionTitle(context.strings.projectName),
                const SizedBox(height: 6),
                DeskTextField(
                  key: const ValueKey('project-settings-name'),
                  initialValue: project.name,
                  placeholder: context.strings.projectName,
                  onChanged: (value) => update(() => name = value.trim()),
                  onSubmitted: (_) => apply(),
                ),
                const SizedBox(height: 12),
                sectionTitle(context.strings.projectBounds),
                const SizedBox(height: 6),
                for (final (i, label) in [
                  context.strings.xWidth,
                  context.strings.yDepth,
                  context.strings.zHeight,
                ].indexed)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        Expanded(child: Text(label)),
                        SizedBox(
                          width: 112,
                          child: ValueBox(
                            size[i],
                            (v) => update(() {
                              size[i] = v;
                              invalid.remove(i);
                              resizeError = null;
                            }),
                            key: ValueKey('workspace-$i'),
                            live: true,
                            autofocus: i == 0,
                            onValidityChanged: (valid) {
                              if (!valid) update(() => invalid.add(i));
                            },
                            onSubmitted: apply,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (partSize != null) ...[
                  const SizedBox(height: 8),
                  MergeSemantics(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      excludeFromSemantics: true,
                      onTap: () => toggleResize(!resizeProducts),
                      child: Row(
                        children: [
                          Expanded(child: Text(context.strings.resizeProducts)),
                          DeskSwitch(
                            value: resizeProducts,
                            onChanged: toggleResize,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                if (resizeError case final message?) ...[
                  const SizedBox(height: 6),
                  Text(
                    message,
                    style: TextStyle(
                      color: context.colors.danger,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              if (project.workspaceSize != null)
                DeskButton(
                  plain: true,
                  onPressed: name.isEmpty
                      ? null
                      : () => Navigator.pop(
                          ctx,
                          namedProject().withWorkspace(null),
                        ),
                  child: Text(context.strings.removeBounds),
                ),
              DeskButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(context.strings.cancel),
              ),
              DeskButton(
                primary: true,
                onPressed: name.isNotEmpty && invalid.isEmpty ? apply : null,
                child: Text(context.strings.apply),
              ),
            ],
          ),
        );
      },
    ),
  );
  if (result != null && context.mounted && identical(editor.project, project)) {
    editor.commit(result);
  }
}
