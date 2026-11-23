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
    String? message;
    try {
      if (await savePartsWorkbook(project, entries)) {
        message = kIsWeb ? 'Скачивание началось' : 'Файл Excel сохранён';
      }
    } catch (_) {
      message = 'Не удалось сохранить файл Excel. Попробуйте ещё раз.';
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
    final groups = <(int, int, int, int, int, int, int), List<Beam>>{};
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
          ? '${p.beams.length} шт.'
          : 'Найдено ${entries.fold<int>(0, (n, row) => n + row.parts.length)} из ${p.beams.length}';
      return DeskDialog(
        maxWidth: 880,
        title: const Text('Список деталей'),
        content: SizedBox(
          width: 800,
          height: (MediaQuery.sizeOf(context).height * .52).clamp(190.0, 480.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${p.name} · $count · ${unit.title.toLowerCase()}',
                      style: const TextStyle(fontSize: 12, color: muted),
                    ),
                  ),
                  SizedBox(
                    width: 174,
                    child: CupertinoSearchTextField(
                      placeholder: 'Найти деталь',
                      onChanged: (v) => setState(() => query = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final (i, title) in [
                    'Деталь',
                    'Длина заготовки',
                    'Ширина',
                    'Толщина',
                    'Кол-во',
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
                      const Text(
                        'Торцы',
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
                              ? 'В проекте пока нет деталей'
                              : 'Детали не найдены',
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
                              SizedBox(
                                height: 35,
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
                                              : 'Прямые',
                                          style: mono,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (multiple && expanded)
                                for (final item in r.parts)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 22),
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
              style: const TextStyle(color: muted, fontSize: 12),
            ),
          DeskButton(
            onPressed: entries.isEmpty || exporting
                ? null
                : () => exportWorkbook(p, entries),
            icon: const Icon(CupertinoIcons.square_arrow_up, size: 15),
            label: const Text('Экспорт в Excel'),
          ),
          DeskButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Готово'),
          ),
        ],
      );
    },
  );
}
