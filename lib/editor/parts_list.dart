import '../l10n/strings.dart';
import 'palette.dart';
import 'desk_text_field.dart';

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:material_ui/material_ui.dart' show Divider;

import 'controller.dart';
import 'desktop.dart';
import 'drawing.dart';
import 'model.dart';
import 'parts_workbook.dart';
import 'storage.dart';

class PartsList extends StatefulWidget {
  const PartsList(this.editor, {required this.rename, super.key});
  final Editor editor;
  final Future<void> Function(Beam) rename;
  @override
  State<PartsList> createState() => _PartsListState();
}

class _PartsListState extends State<PartsList> {
  var query = '', column = 0, ascending = true;
  final opened = <int>{};
  bool exporting = false;
  String? exportMessage;

  Future<void> exportWorkbook(Project project, List<StockRow> entries) async {
    if (exporting || entries.isEmpty) return;
    setState(() {
      exportMessage = null;
      exporting = true;
    });
    final strings = context.strings;
    String? message;
    try {
      if (await savePartsWorkbook(project, entries)) {
        message = kIsWeb ? strings.downloadStarted : strings.excelFileSaved;
      }
    } catch (_) {
      message = strings.workbookSaveError;
    } finally {
      if (mounted) {
        setState(() {
          exporting = false;
          exportMessage = message;
        });
      }
    }
  }

  List<StockRow> rows(Project p) {
    final groups = <Record, List<Beam>>{};
    int key(double n) => (n * 1e6).round();
    for (final b in p.beams) {
      if (!b.name.toLowerCase().contains(query.trim().toLowerCase())) continue;
      final shape = (
        key(b.size.x),
        key(b.size.y),
        key(b.size.z),
        key(b.startCut.y),
        key(b.startCut.z),
        key(b.endCut.y),
        key(b.endCut.z),
        ([
          for (final h in b.holes)
            [
              key(h.centerX(b.size)),
              key(h.centerY(b.size)),
              key(h.diameter),
              if (h.depth != null) ...[key(h.depth!), h.back ? 1 : 0],
            ].join(','),
        ]..sort()).join('|'),
        (
          b.rabbets[RabbetEdge.topLeft],
          b.rabbets[RabbetEdge.topRight],
          b.rabbets[RabbetEdge.bottomLeft],
          b.rabbets[RabbetEdge.bottomRight],
        ),
      );
      (groups[shape] ??= []).add(b);
    }
    final result = groups.values.map(StockRow.new).toList();
    result.sort((a, b) {
      final diff = column == 0
          ? a.name.toLowerCase().compareTo(b.name.toLowerCase())
          : a.number(column).compareTo(b.number(column));
      if (diff == 0) return a.sample.id.compareTo(b.sample.id);
      return ascending ? diff : -diff;
    });
    return result;
  }

  Widget cell(int i, Widget child) => Expanded(
    flex: const [32, 19, 14, 14, 12, 22][i],
    child: Align(
      alignment: i == 0 ? Alignment.centerLeft : Alignment.centerRight,
      child: child,
    ),
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.editor,
    builder: (_, _) {
      final p = widget.editor.project, unit = p.unit;
      final entries = rows(p), cuts = p.beams.any((b) => b.bevelled);
      final count = query.trim().isEmpty
          ? context.strings.pieceCount(p.beams.length)
          : context.strings.searchMatches(
              entries.fold<int>(0, (n, row) => n + row.parts.length),
              p.beams.length,
            );
      return DeskDialog(
        maxWidth: 880,
        title: Text(context.strings.partsList),
        content: SizedBox(
          width: 800,
          height: (MediaQuery.sizeOf(context).height * .52).clamp(190.0, 480.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                spacing: controlGap,
                children: [
                  Expanded(
                    child: Text(
                      '${p.name} · $count · ${unit.title.toLowerCase()}',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.colors.muted,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 174,
                    child: DeskSearchField(
                      placeholder: context.strings.findAPart,
                      onChanged: (v) => setState(() => query = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final (i, title) in [
                    context.strings.part,
                    context.strings.stockLength,
                    context.strings.width,
                    context.strings.thickness,
                    context.strings.qty,
                  ].indexed)
                    cell(
                      i,
                      DeskButton(
                        plain: true,
                        onPressed: () => setState(() {
                          ascending = i == column ? !ascending : true;
                          column = i;
                        }),
                        child: Text(
                          '$title${i == column ? (ascending ? ' ↑' : ' ↓') : ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  if (cuts)
                    cell(
                      5,
                      Text(
                        context.strings.ends,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const Divider(height: 1),
              Expanded(
                child: entries.isEmpty
                    ? Center(
                        child: Text(
                          p.beams.isEmpty
                              ? context.strings.thisProjectHasNoPartsYet
                              : context.strings.noMatchingParts,
                        ),
                      )
                    : ListView.builder(
                        itemCount: entries.length,
                        itemBuilder: (_, i) {
                          final r = entries[i],
                              b = r.sample,
                              multiple = r.parts.length > 1,
                              expanded = opened.contains(b.id);
                          return Column(
                            children: [
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: 35,
                                ),
                                child: Row(
                                  children: [
                                    cell(
                                      0,
                                      DeskButton(
                                        plain: true,
                                        icon: Icon(
                                          multiple
                                              ? (expanded
                                                    ? CupertinoIcons
                                                          .chevron_down
                                                    : CupertinoIcons
                                                          .chevron_right)
                                              : CupertinoIcons.pencil,
                                          size: 13,
                                        ),
                                        onPressed: multiple
                                            ? () => setState(() {
                                                if (!opened.remove(b.id)) {
                                                  opened.add(b.id);
                                                }
                                              })
                                            : () => widget.rename(b),
                                        label: Text(
                                          r.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    for (var n = 1; n <= 4; n++)
                                      cell(
                                        n,
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            right: 8,
                                          ),
                                          child: Text(
                                            n == 4
                                                ? '${r.parts.length}'
                                                : unit.format(r.number(n)),
                                            style: mono,
                                          ),
                                        ),
                                      ),
                                    if (cuts)
                                      cell(
                                        5,
                                        Text(
                                          b.bevelled
                                              ? '${stockCut(b, false)} / ${stockCut(b, true)}'
                                              : context.strings.square,
                                          style: mono,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (b.rabbets.isNotEmpty)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      left: 12,
                                      bottom: 4,
                                    ),
                                    child: Text(
                                      '${context.strings.rabbetTitle} · ${stockRabbets(b, unit)}',
                                      style: mono,
                                    ),
                                  ),
                                ),
                              if (multiple && expanded)
                                for (final item in r.parts)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      22,
                                      2,
                                      0,
                                      2,
                                    ),
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: DeskButton(
                                        plain: true,
                                        onPressed: () => widget.rename(item),
                                        icon: const Icon(
                                          CupertinoIcons.pencil,
                                          size: 12,
                                        ),
                                        label: Text(item.name),
                                      ),
                                    ),
                                  ),
                              const Divider(height: 1),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        actions: [
          if (exportMessage != null)
            Text(
              exportMessage!,
              style: TextStyle(color: context.colors.muted, fontSize: 12),
            ),
          DeskButton(
            onPressed: entries.isEmpty || exporting
                ? null
                : () => exportWorkbook(p, entries),
            icon: const Icon(CupertinoIcons.square_arrow_up, size: 15),
            label: Text(context.strings.exportToExcel),
          ),
          DeskButton(
            primary: true,
            onPressed: () => Navigator.pop(context),
            child: Text(context.strings.close),
          ),
        ],
      );
    },
  );
}
