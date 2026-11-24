import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoIcons;
import 'package:flutter/widgets.dart';

import '../l10n/strings.dart';
import 'desktop.dart';
import 'drawing.dart';
import 'model.dart';
import 'palette.dart';
import 'part_finish.dart';
import 'project_templates.dart';
import 'scene.dart';
import 'template_stock.dart';

typedef NewProjectChoice = ({Project? template, LengthUnit unit});

Future<NewProjectChoice?> chooseProjectTemplate(
  BuildContext context,
  LengthUnit unit,
) => showDeskDialog<NewProjectChoice>(
  context: context,
  builder: (_) =>
      _TemplatePicker(unit == LengthUnit.inch ? unit : LengthUnit.millimeter),
);

class _TemplatePicker extends StatefulWidget {
  const _TemplatePicker(this.unit);
  final LengthUnit unit;
  @override
  State<_TemplatePicker> createState() => _TemplatePickerState();
}

class _TemplatePickerState extends State<_TemplatePicker> {
  var selected = FurnitureTemplate.signatureCabinet;
  late var unit = widget.unit;
  late var project = selected.build(unit);
  late var stock = templateStock(project);

  void select(FurnitureTemplate next, LengthUnit units) => setState(() {
    selected = next;
    unit = units;
    project = selected.build(unit);
    stock = templateStock(project);
  });

  void finish(Project? template) =>
      Navigator.pop(context, (template: template, unit: unit));

  bool expanded = true;

  Iterable<FurnitureTemplate> templatesIn(TemplateCategory category) =>
      FurnitureTemplate.values.where(
        (template) => template.category == category,
      );

  void chooseCategory(TemplateCategory category) {
    if (selected.category == category) {
      setState(() => expanded = !expanded);
    } else {
      expanded = true;
      select(templatesIn(category).first, unit);
    }
  }

  Widget sidebar() => ListView(
    primary: false,
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
    children: [
      for (final category in TemplateCategory.values) ...[
        Semantics(
          expanded: expanded && selected.category == category,
          child: DeskControl(
            onPressed: () => chooseCategory(category),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
            child: Row(
              children: [
                Icon(
                  expanded && selected.category == category
                      ? CupertinoIcons.chevron_down
                      : CupertinoIcons.chevron_right,
                  size: 10,
                  color: context.colors.muted,
                ),
                const SizedBox(width: 7),
                Icon(
                  CupertinoIcons.folder,
                  size: 15,
                  color: context.colors.muted,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    category.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: context.colors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (expanded && selected.category == category)
          for (final template in templatesIn(category))
            Semantics(
              selected: template == selected,
              child: DeskControl(
                background: template == selected ? context.selectionFill : null,
                onPressed: () => select(template, unit),
                padding: const EdgeInsets.fromLTRB(30, 6, 8, 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    template.title,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.colors.ink,
                      fontWeight: template == selected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ),
      ],
    ],
  );

  Widget menuLabel(String title) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Flexible(child: Text(title)),
      const SizedBox(width: 6),
      const Icon(CupertinoIcons.chevron_up_chevron_down, size: 11),
    ],
  );

  String sizeLabel(Iterable<double> dimensions) =>
      '${dimensions.map(unit.format).join(' × ')} ${unit.symbol}';

  void showCuttingLayout() => showDeskDialog<void>(
    context: context,
    builder: (ctx) => DeskDialog(
      maxWidth: 610,
      title: Text('${ctx.strings.cuttingLayout} · ${project.name}'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${selected.material.label} · ${ctx.strings.stockKerf(sizeLabel([templateKerf(unit)]))}',
          ),
          for (final (index, blank) in stock.indexed) ...[
            const SizedBox(height: 14),
            Text(
              '${index + 1}.  ${sizeLabel([blank.size.width, blank.size.height, blank.thickness])}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: AspectRatio(
                  aspectRatio: blank.size.aspectRatio,
                  child: CustomPaint(painter: _CutDiagram(blank, ctx.colors)),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 12,
              runSpacing: 3,
              children: [
                for (final entry in blank.cuts.entries)
                  Text(
                    '#${entry.key}  ${project.byId[entry.key]!.name} · ${sizeLabel([entry.value.width, entry.value.height])}',
                    style: const TextStyle(fontSize: 12),
                  ),
              ],
            ),
          ],
        ],
      ),
      actions: [
        DeskButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(ctx.strings.close),
        ),
      ],
    ),
  );

  Widget details() {
    final bounds = project.partBounds!;
    final size = bounds.high - bounds.low;
    final groups = <(Size, double), List<StockBlank>>{};
    for (final blank in stock) {
      (groups[(blank.size, blank.thickness)] ??= []).add(blank);
    }
    final s = context.strings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          selected.title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: context.colors.ink,
          ),
        ),
        const SizedBox(height: 3),
        Wrap(
          spacing: 9,
          runSpacing: 3,
          children: [
            for (final label in [
              selected.material.label,
              sizeLabel([size.x, size.y, size.z]),
              s.partCount(project.beams.length),
            ])
              Text(
                label,
                style: TextStyle(color: context.colors.muted, fontSize: 12),
              ),
          ],
        ),
        RepaintBoundary(
          child: CustomPaint(
            size: const Size(double.infinity, 190),
            painter: _Preview(project, context.colors, selected),
          ),
        ),
        SizedBox(height: .7, child: ColoredBox(color: context.colors.line)),
        if (selected.constructionNote case final note?) ...[
          const SizedBox(height: 6),
          Text(note, style: TextStyle(color: context.colors.ink, fontSize: 12)),
        ],
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            Text(
              s.stockShopping,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            DeskButton(
              onPressed: showCuttingLayout,
              child: Text(s.cuttingLayout),
            ),
          ],
        ),
        for (final entry in groups.entries) ...[
          const SizedBox(height: 4),
          Builder(
            builder: (_) {
              final (size, thickness) = entry.key;
              final type = selected.material != FinishPreset.wood
                  ? s.stockSheet
                  : size.height == thickness
                  ? s.stockBar
                  : s.stockBoard;
              final offcuts = <Size, int>{};
              for (final blank in entry.value) {
                final used = blank.requiredSize;
                if (used.width * used.height < .8 * size.width * size.height) {
                  offcuts.update(used, (n) => n + 1, ifAbsent: () => 1);
                }
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$type  ${sizeLabel([size.width, size.height, thickness])}  ×  ${entry.value.length}',
                  ),
                  for (final offcut in offcuts.entries)
                    Text(
                      s.stockOffcut(
                        '${sizeLabel([offcut.key.width, offcut.key.height, thickness])}  ×  ${offcut.value}',
                      ),
                      style: TextStyle(
                        fontSize: 12,
                        color: context.colors.muted,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
        const SizedBox(height: 6),
        Text(
          s.stockKerf(sizeLabel([templateKerf(unit)])),
          style: TextStyle(fontSize: 11, color: context.colors.muted),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => DeskDialog(
    maxWidth: 800,
    title: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 6,
      children: [
        Text(context.strings.newProject),
        DeskSegments(unit, {
          LengthUnit.millimeter: context.strings.millimeters,
          LengthUnit.inch: context.strings.inches,
        }, (value) => select(selected, value)),
      ],
    ),
    insetContent: false,
    content: LayoutBuilder(
      builder: (context, constraints) {
        final detailsPane = Padding(
          padding: const EdgeInsets.all(18),
          child: details(),
        );
        if (constraints.maxWidth < 540) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    DeskMenu<TemplateCategory>(
                      title: selected.category.label,
                      selected: selected.category,
                      items: [
                        for (final category in TemplateCategory.values)
                          (category, category.label),
                      ],
                      change: (category) =>
                          select(templatesIn(category).first, unit),
                      child: menuLabel(selected.category.label),
                    ),
                    DeskMenu<FurnitureTemplate>(
                      title: selected.title,
                      selected: selected,
                      items: [
                        for (final template in templatesIn(selected.category))
                          (template, template.title),
                      ],
                      change: (template) => select(template, unit),
                      child: menuLabel(selected.title),
                    ),
                  ],
                ),
              ),
              detailsPane,
            ],
          );
        }
        return SizedBox(
          height: (MediaQuery.sizeOf(context).height - 185).clamp(230.0, 440.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: constraints.maxWidth < 650 ? 190 : 226,
                child: sidebar(),
              ),
              SizedBox(
                width: .7,
                child: ColoredBox(color: context.colors.line),
              ),
              Expanded(
                child: ColoredBox(
                  color: context.colors.paper,
                  child: SingleChildScrollView(
                    key: ValueKey(selected),
                    primary: false,
                    child: detailsPane,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
    leadingAction: DeskButton(
      onPressed: () => finish(null),
      child: Text(context.strings.blankProject),
    ),
    actions: [
      DeskButton(
        plain: true,
        onPressed: () => Navigator.pop(context),
        child: Text(context.strings.cancel),
      ),
      DeskButton(
        primary: true,
        onPressed: () => finish(project),
        child: Text(context.strings.createProject),
      ),
    ],
  );
}

class _Preview extends CustomPainter {
  const _Preview(this.project, this.colors, this.template);
  final Project project;
  final EditorPalette colors;
  final FurnitureTemplate template;

  @override
  void paint(Canvas canvas, Size size) {
    final camera = Camera();
    if (template == FurnitureTemplate.signatureCabinet) {
      camera
        ..yaw = .38
        ..pitch = .23;
    }
    camera.fit(project, size);
    camera.scale *= 1.18;
    DrawingPainter(
      scene: Scene(project, camera, size),
      selection: const {},
      dimensions: false,
      dimensionsVisible: false,
      colors: colors,
    ).paint(canvas, size);
  }

  @override
  bool shouldRepaint(_Preview old) =>
      old.project != project || old.colors != colors;
}

class _CutDiagram extends CustomPainter {
  const _CutDiagram(this.blank, this.colors);
  final StockBlank blank;
  final EditorPalette colors;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / blank.size.width;
    final outline = Paint()
      ..color = colors.line
      ..style = PaintingStyle.stroke;
    canvas.drawRect(Offset.zero & size, Paint()..color = colors.field);
    canvas.drawRect(Offset.zero & size, outline);
    for (final entry in blank.cuts.entries) {
      final r = Rect.fromPoints(
        entry.value.topLeft * scale,
        entry.value.bottomRight * scale,
      );
      canvas.drawRect(r, Paint()..color = colors.pale);
      canvas.drawRect(r, outline);
      final label = TextPainter(
        text: TextSpan(
          text: '#${entry.key}',
          style: TextStyle(fontSize: 10, color: colors.ink),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      if (label.width + 2 <= r.width && label.height <= r.height) {
        label.paint(canvas, r.center - label.size.center(Offset.zero));
      }
      label.dispose();
    }
  }

  @override
  bool shouldRepaint(_CutDiagram old) =>
      old.blank != blank || old.colors != colors;
}
