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
  const PartsList(this.editor, {super.key});
  final Editor editor;
  @override
  State<PartsList> createState() => _PartsListState();
}

class _PartsListState extends State<PartsList> {
  var query = '', column = 0, ascending = true;
  bool exporting = false;
  String? exportMessage;

  Future<void> exportWorkbook(Project project, {bool bazis = false}) async {
    if (exporting) return;
    final entries = rows(project, forExport: true);
    if (entries.isEmpty) return;
    setState(() {
      exportMessage = null;
      exporting = true;
    });
    final strings = context.strings;
    String? message;
    try {
      if (await savePartsWorkbook(
        project,
        entries,
        unit: widget.editor.displayUnit,
        bazis: bazis,
      )) {
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

  int sizeKey(double n) => (n * 1e6).round();

  Record stockShape(Beam b) {
    return (
      b.banding,
      sizeKey(b.size.x),
      sizeKey(b.size.y),
      sizeKey(b.size.z),
      sizeKey(b.startCut.y),
      sizeKey(b.startCut.z),
      sizeKey(b.endCut.y),
      sizeKey(b.endCut.z),
      ([
        for (final h in b.holes)
          [
            sizeKey(h.centerX(b.size)),
            sizeKey(h.centerY(b.size)),
            sizeKey(h.diameter),
            if (h.depth != null) ...[sizeKey(h.depth!), h.back ? 1 : 0],
            if (h.boltBore case final bolt?) ...[
              h.boringEdge!.faceIndex,
              sizeKey(bolt.diameter),
              sizeKey(h.back ? b.size.z - bolt.faceOffset : bolt.faceOffset),
            ],
          ].join(','),
      ]..sort()).join('|'),
      ([
        for (final h in b.edgeHoles)
          [
            h.edge.index,
            h.kind.index,
            if (h.kind == EdgeHoleKind.pocket) h.back ? 1 : 0,
            sizeKey(h.position(b.size)),
            sizeKey(h.height),
            sizeKey(h.diameter),
            if (h.depth != null) sizeKey(h.depth!),
          ].join(','),
      ]..sort()).join('|'),
      (
        b.rabbets[RabbetEdge.topLeft],
        b.rabbets[RabbetEdge.topRight],
        b.rabbets[RabbetEdge.bottomLeft],
        b.rabbets[RabbetEdge.bottomRight],
      ),
    );
  }

  List<StockRow> rows(Project p, {bool forExport = false}) {
    final groups = <Record, List<Beam>>{};
    final search = query.trim().toLowerCase();
    for (final b in p.beams) {
      if (!b.name.toLowerCase().contains(search)) continue;
      final key = forExport
          ? stockShape(b)
          : (
              b.name,
              sizeKey(blankLength(b)),
              sizeKey(b.size.y),
              sizeKey(b.size.z),
            );
      (groups[key] ??= []).add(b);
    }
    String name(StockRow row) => forExport ? row.name : row.sample.name;
    final result = groups.values.map(StockRow.new).toList();
    result.sort((a, b) {
      final diff = column == 0
          ? name(a).toLowerCase().compareTo(name(b).toLowerCase())
          : a.number(column).compareTo(b.number(column));
      if (diff == 0) return a.sample.id.compareTo(b.sample.id);
      return ascending ? diff : -diff;
    });
    return result;
  }

  Widget cell(int i, Widget child) => Expanded(
    flex: const [41, 19, 14, 14, 12][i],
    child: Align(
      alignment: i == 0 ? Alignment.centerLeft : Alignment.centerRight,
      child: child,
    ),
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.editor,
    builder: (_, _) {
      final p = widget.editor.project, unit = widget.editor.displayUnit;
      final entries = rows(p);
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
                    : ListView.separated(
                        itemCount: entries.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final row = entries[i];
                          return ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 32),
                            child: Row(
                              children: [
                                cell(
                                  0,
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    child: Text(row.sample.name),
                                  ),
                                ),
                                for (var n = 1; n <= 4; n++)
                                  cell(
                                    n,
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: Text(
                                        n == 4
                                            ? '${row.parts.length}'
                                            : unit.formatStockLength(
                                                row.number(n),
                                              ),
                                        style: mono,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
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
                : () => exportWorkbook(p, bazis: true),
            label: Text(context.strings.bazisExport),
          ),
          DeskButton(
            onPressed: entries.isEmpty || exporting
                ? null
                : () => exportWorkbook(p),
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
