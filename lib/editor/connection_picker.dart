import 'package:material_ui/material_ui.dart';

import '../l10n/strings.dart';
import 'controller.dart';
import 'desktop.dart';
import 'drawing.dart';
import 'model.dart';
import 'palette.dart';
import 'scene.dart';

typedef _ConnectionChoice = ({ConnectionPattern pattern, ConnectionPlan? plan});

Future<void> chooseConnection(BuildContext context, Editor editor) async {
  if (!editor.canAddConnection) return;
  final navigator = Navigator.of(context, rootNavigator: true);
  final contacts = editor.selectedContacts;
  final ruler = editor.connectionRuler;
  final result = await showDeskDialog<_ConnectionChoice>(
    context: context,
    builder: (_) => _ConnectionPicker(
      editor.connectionPattern,
      ruler,
      editor.displayUnit,
      contacts,
    ),
  );
  if (result == null || !navigator.mounted) return;
  if (contacts.isEmpty) {
    if (editor.selection.length <= 1) editor.beginConnection(result.pattern);
    return;
  }
  final plan = result.plan;
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
  editor.connectionPattern = result.pattern;
  editor.commit(
    editor.project.edit(ids, (b) => plan.rows[b.id]!.fold(b, withDrillLayout)),
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
  static const _kitCounts = [1, 2, 3, 4, 5, 6];
  static const _cabinetKinds = [
    ConnectionKind.dowel,
    ConnectionKind.confirmat,
    ConnectionKind.minifix,
    ConnectionKind.maxifix,
  ];

  late final PartContact? cabinetContact = _findCabinetContact();
  late final defaults = {
    for (final kind in ConnectionKind.values)
      if (paired || kind != ConnectionKind.woodScrew) kind: ?_available(kind),
  };
  late ConnectionPattern shared =
      !paired && defaults.containsKey(widget.previous.kind)
      ? widget.previous
      : _defaultPattern(
          defaults.containsKey(widget.previous.kind)
              ? widget.previous.kind
              : defaults.keys.firstOrNull ?? widget.previous.kind,
        );
  final overrides = <int, ConnectionPattern>{};
  int editingGroup = -1;
  late bool fromEnd = cabinetContact?.plan(shared, widget.ruler) == null;
  late int kitCount = _cabinetPlan(2) == null ? 1 : 2;

  ConnectionPattern _defaultPattern(ConnectionKind kind) {
    return ConnectionPattern(
      kind,
      dowels: kind == ConnectionKind.dowel ? 1 : 0,
      back: defaults[kind] ?? widget.previous.back,
    );
  }

  PartContact? _findCabinetContact() {
    if (!cabinet) return null;
    final ordered = [
      ...widget.contacts.where((c) => c.face < 4),
      ...widget.contacts.where((c) => c.face >= 4),
    ];
    for (final contact in ordered) {
      for (final kind in _cabinetKinds) {
        for (final back in [false, true]) {
          final pattern = ConnectionPattern(kind, back: back);
          for (final base in [false, true]) {
            if (contact.plan(pattern, widget.ruler, fromEnd: base) != null) {
              return contact;
            }
          }
        }
      }
    }
    return null;
  }

  bool? _available(ConnectionKind kind) {
    if (!paired) return widget.previous.back;
    for (final back in [widget.previous.back, !widget.previous.back]) {
      final pattern = ConnectionPattern(
        kind,
        dowels: kind == ConnectionKind.dowel ? 1 : 0,
        back: back,
      );
      if (cabinet) {
        if (cabinetContact?.plan(pattern, widget.ruler) != null ||
            cabinetContact?.plan(pattern, widget.ruler, fromEnd: true) !=
                null) {
          return back;
        }
      } else if (_plan(widget.contacts, widget.ruler, pattern) != null) {
        return back;
      }
    }
    return null;
  }

  ConnectionPlan? _cabinetPlan(int count) => cabinetContact?.plan(
    shared,
    widget.ruler,
    fromEnd: fromEnd,
    groups: [for (var i = 0; i < count; i++) overrides[i] ?? shared],
  );

  void _edit(ConnectionPattern pattern) {
    setState(() {
      if (cabinet && editingGroup >= 0) {
        overrides[editingGroup] = pattern;
      } else {
        shared = pattern;
        overrides.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.strings, colors = context.colors;
    final pattern = overrides[editingGroup] ?? shared;
    final kind = pattern.kind, count = pattern.dowels;
    final alone = kind == ConnectionKind.dowel;
    final placement = cabinet
        ? _cabinetPlan(kitCount)
        : paired
        ? _plan(widget.contacts, widget.ruler, pattern)
        : null;
    final adjustableRow = kind != ConnectionKind.pocket && (!paired || cabinet);
    final reference = cabinetContact;
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
          if (reference != null) ...[
            Text(s.connectionDatumEdge),
            DeskSegments(
              fromEnd,
              {
                for (final end in [false, true])
                  end: reference.part.bandingEdgeLabel(
                    reference.datumEdge(end),
                  ),
              },
              (value) => setState(() => fromEnd = value),
              key: const ValueKey('connection-datum-edge'),
            ),
            Text(s.connectionKitCount),
            DeskSegments(
              kitCount,
              {
                for (final count in _kitCounts)
                  if (count == kitCount || _cabinetPlan(count) != null)
                    count: '$count',
              },
              (count) => setState(() {
                kitCount = count;
                if (editingGroup >= count) editingGroup = -1;
              }),
              key: const ValueKey('connection-kit-count'),
            ),
            if (kitCount > 1) ...[
              Text(s.connectionEditKit),
              DeskSegments(
                editingGroup,
                {
                  -1: s.connectionAllKits,
                  for (var i = 0; i < kitCount; i++) i: '${i + 1}',
                },
                (index) => setState(() => editingGroup = index),
                key: const ValueKey('connection-edit-kit'),
              ),
            ],
          ],
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
                    onPressed: () {
                      if (kind != choice) _edit(_defaultPattern(choice));
                    },
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
              (n) => _edit(
                ConnectionPattern(
                  kind,
                  dowels: n,
                  back: pattern.back,
                  side: !alone && n == 2
                      ? DowelSide.both
                      : n == 1 && pattern.side == DowelSide.both
                      ? DowelSide.after
                      : pattern.side,
                ),
              ),
              key: const ValueKey('connection-dowel-count'),
            ),
            if (!alone && count > 0)
              DeskSegments(
                pattern.side,
                {
                  DowelSide.before: s.beforeHardware,
                  if (count == 2) DowelSide.both: s.bothHardware,
                  DowelSide.after: s.afterHardware,
                },
                (value) => _edit(
                  ConnectionPattern(
                    kind,
                    dowels: count,
                    side: value,
                    back: pattern.back,
                  ),
                ),
              ),
          ],
          if (defaults.isNotEmpty &&
              [
                ConnectionKind.minifix,
                ConnectionKind.maxifix,
                ConnectionKind.pocket,
              ].contains(kind))
            DeskSegments(
              pattern.back,
              {false: s.faceA, true: s.faceB},
              (value) => _edit(
                ConnectionPattern(
                  kind,
                  dowels: count,
                  side: pattern.side,
                  back: value,
                ),
              ),
            ),
          if (paired)
            if (placement != null) ...[
              _PairConnectionPreview(placement),
              if (cabinet) ...[
                Text(
                  s.baseDistance,
                  style: TextStyle(color: colors.muted, fontSize: 12),
                ),
                Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  children: [
                    for (final (i, row) in placement.stationRows.indexed)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${i + 1} · ${row.map((item) => item.$1.label).join(' + ')}',
                          ),
                          Text(
                            '${row.map((item) => widget.unit.format(item.$2)).join(' · ')} ${widget.unit.symbol}',
                            style: TextStyle(color: colors.muted, fontSize: 12),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ] else
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
              : () =>
                    Navigator.pop(context, (pattern: shared, plan: placement)),
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
            ?plan.datum,
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
                  plan.datum,
                  colors,
                  DefaultTextStyle.of(context).style,
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
  const _PairConnectionMarks(
    this.camera,
    this.holes,
    this.marks,
    this.datum,
    this.colors,
    this.textStyle,
  );

  final Camera camera;
  final List<(Vector3, Vector3)> holes;
  final List<Vector3> marks;
  final Vector3? datum;
  final EditorPalette colors;
  final TextStyle textStyle;

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
    if (datum case final base?) {
      final at = camera.project(base, size);
      canvas.drawCircle(at, 6, stroke);
      final label = TextPainter(
        text: TextSpan(
          text: '0',
          style: textStyle.copyWith(color: colors.accent, fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, at + Offset(-label.width / 2, 8));
      label.dispose();
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
