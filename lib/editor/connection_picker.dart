import 'package:material_ui/material_ui.dart';

import '../l10n/strings.dart';
import 'controller.dart';
import 'desktop.dart';
import 'drawing.dart';
import 'model.dart';
import 'palette.dart';
import 'scene.dart';

Future<void> chooseConnection(BuildContext context, Editor editor) async {
  if (!editor.canAddConnection) return;
  final contacts = editor.selectedContacts;
  final ruler = editor.connectionRuler;
  final result = await showDeskDialog<ConnectionPattern>(
    context: context,
    builder: (_) => _ConnectionPicker(
      editor.connectionPattern,
      ruler,
      editor.displayUnit,
      contacts,
    ),
  );
  if (result == null || !context.mounted) return;
  if (contacts.isEmpty) {
    if (editor.selection.length <= 1) editor.beginConnection(result);
    return;
  }
  final plan = _plan(contacts, ruler, result);
  if (plan == null) return;
  final contact = plan.contact;
  if (editor.selection.length != 2 ||
      [contact.part, contact.mate].any(
        (b) =>
            editor.project.byId[b.id] != b || !editor.selection.contains(b.id),
      )) {
    return;
  }
  final layouts = plan.layouts;
  final ids = {
    for (final entry in layouts.entries)
      if (entry.value.faces.isNotEmpty || entry.value.edges.isNotEmpty)
        entry.key,
  };
  editor.connectionPattern = result;
  editor.commit(
    editor.project.edit(ids, (b) => withDrillLayout(b, layouts[b.id]!)),
  );
}

ConnectionPlan? _plan(
  List<PartContact> contacts,
  ConnectionRuler ruler,
  ConnectionPattern pattern,
) => contacts
    .map((contact) => contact.plan(pattern, ruler))
    .nonNulls
    .firstOrNull;

class _ConnectionPicker extends StatefulWidget {
  const _ConnectionPicker(this.previous, this.ruler, this.unit, this.contacts);
  final ConnectionPattern previous;
  final ConnectionRuler ruler;
  final LengthUnit unit;
  final List<PartContact> contacts;
  @override
  State<_ConnectionPicker> createState() => _ConnectionPickerState();
}

class _ConnectionPickerState extends State<_ConnectionPicker> {
  bool get paired => widget.contacts.isNotEmpty;
  bool get cabinet => paired && widget.contacts.first.cabinet;
  late final defaults = {
    for (final kind in ConnectionKind.values)
      if (paired || kind != ConnectionKind.woodScrew)
        if (_available(kind) case final back?) kind: back,
  };
  late ConnectionKind kind = defaults.containsKey(widget.previous.kind)
      ? widget.previous.kind
      : defaults.keys.firstOrNull ?? widget.previous.kind;
  late int count = !paired && kind == widget.previous.kind
      ? widget.previous.dowels
      : kind == ConnectionKind.dowel
      ? 1
      : 0;
  late DowelSide side = widget.previous.side;
  late bool back = defaults[kind] ?? widget.previous.back;

  bool? _available(ConnectionKind kind) {
    if (!paired) return widget.previous.back;
    for (final back in [widget.previous.back, !widget.previous.back]) {
      final pattern = ConnectionPattern(
        kind,
        dowels: kind == ConnectionKind.dowel ? 1 : 0,
        back: back,
      );
      if (_plan(widget.contacts, widget.ruler, pattern) != null) return back;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings, colors = context.colors;
    final pattern = ConnectionPattern(
      kind,
      dowels: count,
      side: side,
      back: back,
    );
    final alone = kind == ConnectionKind.dowel;
    final placement = paired
        ? _plan(widget.contacts, widget.ruler, pattern)
        : null;
    final adjustableRow = kind != ConnectionKind.pocket && (!paired || cabinet);
    return DeskDialog(
      maxWidth: 525,
      title: Text(s.addConnection),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          if (paired)
            Text(
              [
                widget.contacts.first.part,
                widget.contacts.first.mate,
              ].map((b) => '${b.name} · ${b.finish.texture.label}').join(' / '),
              style: TextStyle(color: colors.muted, fontSize: 12),
            ),
          if (defaults.isNotEmpty)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final choice in defaults.keys)
                  DeskButton(
                    key: ValueKey('connection-${choice.name}'),
                    primary: kind == choice,
                    child: Text(choice.label),
                    onPressed: () => setState(() {
                      if (kind == choice) return;
                      kind = choice;
                      count = choice == ConnectionKind.dowel ? 1 : 0;
                      back = defaults[choice]!;
                    }),
                  ),
              ],
            ),
          if (defaults.isNotEmpty && adjustableRow) ...[
            Text(s.dowels),
            DeskSegments(
              count,
              {
                for (final n in (alone ? [1, 2, 3] : [0, 1, 2])) n: '$n',
              },
              (n) => setState(() {
                count = n;
                if (n == 1 && side == DowelSide.both) side = DowelSide.after;
                if (n == 2 && !alone) side = DowelSide.both;
              }),
            ),
            if (!alone && count > 0)
              DeskSegments(side, {
                DowelSide.before: s.beforeHardware,
                if (count == 2) DowelSide.both: s.bothHardware,
                DowelSide.after: s.afterHardware,
              }, (v) => setState(() => side = v)),
          ],
          if (defaults.isNotEmpty &&
              [
                ConnectionKind.minifix,
                ConnectionKind.maxifix,
                ConnectionKind.pocket,
              ].contains(kind))
            DeskSegments(back, {
              false: s.faceA,
              true: s.faceB,
            }, (v) => setState(() => back = v)),
          if (paired)
            if (placement != null)
              _PairConnectionPreview(placement)
            else
              Text(
                s.connectionLayoutUnavailable,
                style: TextStyle(color: colors.muted),
              ),
          if (!paired && kind != ConnectionKind.pocket)
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.field,
                border: Border.all(color: colors.line),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 8,
                  children: [
                    Text(
                      s.baseDistance,
                      style: TextStyle(color: colors.muted, fontSize: 12),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final (i, item) in pattern.stations.indexed)
                          Expanded(
                            child: Column(
                              spacing: 3,
                              children: [
                                SizedBox(
                                  height: 16,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Positioned(
                                        left: 0,
                                        right: 0,
                                        child: Divider(
                                          height: 1,
                                          color: colors.line,
                                        ),
                                      ),
                                      Container(
                                        width: item == ConnectionKind.dowel
                                            ? 9
                                            : 13,
                                        height: item == ConnectionKind.dowel
                                            ? 9
                                            : 13,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: item == ConnectionKind.dowel
                                              ? colors.field
                                              : colors.accent,
                                          border: Border.all(
                                            color: colors.accent,
                                            width: 1.6,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${widget.unit.format(widget.ruler.first + i * widget.ruler.pitch)} ${widget.unit.symbol}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  item.label,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      actions: [
        DeskButton(
          plain: true,
          onPressed: () => Navigator.pop(context),
          child: Text(s.cancel),
        ),
        DeskButton(
          primary: true,
          onPressed: paired && placement == null
              ? null
              : () => Navigator.pop(context, pattern),
          child: Text(paired ? s.apply : s.placeOnDrawing),
        ),
      ],
    );
  }
}

class _PairConnectionPreview extends StatelessWidget {
  const _PairConnectionPreview(this.plan);

  final ConnectionPlan plan;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final parts = [plan.contact.part, plan.contact.mate];
    final holes = <(Vector3, Vector3)>[];
    for (final part in parts) {
      final layout = plan.layouts[part.id]!;
      Vector3 world(Vector3 p) =>
          part.origin + part.along * p.x + part.across * p.y + part.up * p.z;
      for (final drill in [
        for (final h in layout.faces) ...h.drills(part.size),
        for (final h in layout.edges) ...h.drills(part.size),
      ]) {
        holes.add((world(drill.entry), world(drill.stop)));
      }
    }
    return SizedBox(
      height: 192,
      child: LayoutBuilder(
        builder: (context, box) {
          final camera = Camera()..view(ViewAngle.iso);
          final size = box.biggest;
          camera.fitPoints([
            ...plan.contact.overlap,
            for (final (start, stop) in holes) ...[start, stop],
          ], size);
          final scene = Scene(Project('', parts), camera, size);
          return ColoredBox(
            color: colors.paper,
            child: ClipRect(
              child: CustomPaint(
                key: const ValueKey('paired-connection-preview'),
                painter: DrawingPainter(
                  scene: scene,
                  selection: const {},
                  dimensions: false,
                  dimensionsVisible: false,
                  colors: colors,
                ),
                foregroundPainter: _PairConnectionMarks(
                  camera,
                  holes,
                  plan.marks,
                  colors,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PairConnectionMarks extends CustomPainter {
  const _PairConnectionMarks(this.camera, this.holes, this.marks, this.colors);

  final Camera camera;
  final List<(Vector3, Vector3)> holes;
  final List<Vector3> marks;
  final EditorPalette colors;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = colors.accent
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (final (start, stop) in holes) {
      canvas.drawLine(
        camera.project(start, size),
        camera.project(stop, size),
        stroke,
      );
    }
    for (final mark in marks) {
      final at = camera.project(mark, size);
      canvas.drawCircle(at, 4, stroke);
      canvas.drawCircle(at, 2, Paint()..color = colors.field);
    }
  }

  @override
  bool shouldRepaint(_PairConnectionMarks oldDelegate) => true;
}
