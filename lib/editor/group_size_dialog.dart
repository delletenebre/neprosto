part of 'size_dialog.dart';

Future<Project?> _editGroupSize(
  BuildContext context,
  Editor editor,
  Project project,
  int group,
  Offset position,
  DialogSource? source,
) {
  final members = project.beams.where((b) => b.group == group).toList();
  final ids = {for (final member in members) member.id};
  Bounds3 boundsOf(Project p) =>
      Bounds3.points(ids.expand((id) => p.byId[id]!.corners));
  final bounds = boundsOf(project);
  final originalSize = bounds.high - bounds.low;
  final size = originalSize.clone();
  final editedOffsets = <int, double>{};
  final invalidFields = <int>{};
  final initialName = project.groupName(group);
  final firstFinish = members.first.finish;
  final initialFinish = members.every((b) => b.finish == firstFinish)
      ? firstFinish
      : null;
  var name = initialName, finish = initialFinish;
  var resized = project, offsets = project.offsetsOf(bounds);
  String? error;

  void resize(int axisIndex, double value) {
    size[axisIndex] = value;
    var next = project;
    for (var i = 0; i < 3; i++) {
      if (size[i] == originalSize[i]) continue;
      final result = resizeAssembly(
        next,
        ids,
        axis(i),
        size[i],
        displayUnit: editor.displayUnit,
      );
      if (result.error != null) {
        error = result.error;
        return;
      }
      next = result.project;
    }
    resized = next;
    offsets = resized.offsetsOf(boundsOf(resized));
    error = null;
  }

  return _showSizeDialog<Project>(context, position, source, (ctx, update) {
    final s = ctx.strings;
    bool ready() =>
        name.trim().isNotEmpty && invalidFields.isEmpty && error == null;
    void validate(int field, bool valid) => update(() {
      if (valid) {
        invalidFields.remove(field);
      } else {
        invalidFields.add(field);
      }
    });
    void apply() {
      if (!ready()) return;
      var next = resized.withGroupName(group, name);
      final delta = Vector3.zero();
      for (final entry in editedOffsets.entries) {
        delta.add(
          offsetDirection(entry.key) * (entry.value - offsets[entry.key]),
        );
      }
      if (delta.length2 > 0) {
        next = next.move(ids, delta, withinWorkspace: editor.movementSnapping);
      }
      final chosen = finish;
      if (chosen != null && chosen != initialFinish) {
        next = next.edit(ids, (b) => b.copy(finish: chosen));
      }
      Navigator.pop(ctx, next);
    }

    return DeskDialog(
      compact: true,
      title: DeskTextField(
        key: const ValueKey('group-dialog-name'),
        initialValue: initialName,
        placeholder: s.groupName,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: ctx.colors.ink,
        ),
        onChanged: (v) => update(() => name = v),
        onSubmitted: (_) => apply(),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          sectionTitle(s.assemblyDimensions),
          for (final (i, label) in [s.xWidth, s.yDepth, s.zHeight].indexed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(
                    child: Text(label, style: const TextStyle(fontSize: 12)),
                  ),
                  SizedBox(
                    width: 104,
                    child: ValueBox(
                      size[i],
                      (v) => update(() => resize(i, v)),
                      key: ValueKey('group-extent-$i'),
                      live: true,
                      autofocus: i == 0,
                      onValidityChanged: (ok) => validate(i, ok),
                      onSubmitted: apply,
                    ),
                  ),
                ],
              ),
            ),
          if (error != null)
            Text(
              error!,
              style: TextStyle(color: ctx.colors.danger, fontSize: 12),
            ),
          const SizedBox(height: 8),
          sectionTitle(s.partOffsets),
          for (var i = 0; i < 3; i++)
            PartOffsetRow(
              i,
              ValueBox(
                editedOffsets[i] ?? offsets[i],
                (v) => update(() => editedOffsets[i] = v),
                key: ValueKey('dialog-position-$i'),
                signed: true,
                live: true,
                onValidityChanged: (ok) => validate(3 + i, ok),
                onSubmitted: apply,
              ),
              fieldWidth: 104,
            ),
          const SizedBox(height: 8),
          Row(
            spacing: controlGap,
            children: [
              Text(s.partFinish),
              Expanded(
                child: PartFinishButton(
                  finish,
                  (v) => update(() => finish = v),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        DeskButton(
          plain: true,
          onPressed: () => Navigator.pop(ctx),
          child: Text(s.cancel),
        ),
        DeskButton(
          primary: true,
          onPressed: ready() ? apply : null,
          child: Text(s.apply),
        ),
      ],
    );
  });
}
