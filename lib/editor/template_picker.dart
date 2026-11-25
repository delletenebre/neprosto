import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoIcons;
import 'package:flutter/widgets.dart';

import '../l10n/strings.dart';
import 'desktop.dart';
import 'drawing.dart';
import 'model.dart';
import 'palette.dart';
import 'project_templates.dart';
import 'scene.dart';

typedef NewProjectChoice = ({Project? template, LengthUnit unit});

Future<NewProjectChoice?> chooseProjectTemplate(
  BuildContext context,
  LengthUnit unit, {
  DialogSource? source,
}) => showDeskDialog<NewProjectChoice>(
  source: source,
  context: context,
  builder: (_) => _TemplatePicker(unit),
);

class _TemplatePicker extends StatefulWidget {
  const _TemplatePicker(this.unit);
  final LengthUnit unit;
  @override
  State<_TemplatePicker> createState() => _TemplatePickerState();
}

class _TemplatePickerState extends State<_TemplatePicker> {
  var selected = FurnitureTemplate.hoodCabinet;
  LengthUnit get unit => widget.unit;
  late var project = selected.build(unit);
  bool expanded = true;

  void select(FurnitureTemplate next) => setState(() {
    selected = next;
    project = selected.build(unit);
  });

  void finish(Project? template) =>
      Navigator.pop(context, (template: template, unit: unit));

  String get materialLabel {
    final textures = project.beams.map((b) => b.finish.texture).toSet();
    if (textures.length == 1) return selected.material.label;
    return textures.map((texture) => texture.label).join(' + ');
  }

  Iterable<FurnitureTemplate> templatesIn(TemplateCategory category) =>
      FurnitureTemplate.values.where(
        (template) => template.category == category,
      );

  void chooseCategory(TemplateCategory category) {
    if (selected.category == category) {
      setState(() => expanded = !expanded);
    } else {
      expanded = true;
      select(templatesIn(category).first);
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
                onPressed: () => select(template),
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

  Widget details() {
    final bounds = project.partBounds!;
    final size = bounds.high - bounds.low;
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
              materialLabel,
              selected.difficulty.label,
              sizeLabel([size.x, size.y, size.z]),
              s.partCount(project.beams.length),
            ])
              Text(
                label,
                style: TextStyle(color: context.colors.muted, fontSize: 12),
              ),
          ],
        ),
        AspectRatio(
          aspectRatio: 3 / 2,
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _Preview(project, context.colors, selected),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          context.strings.templateAssembly,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 4),
        Text(
          selected.assemblyNote,
          style: TextStyle(
            color: context.colors.ink,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => DeskDialog(
    maxWidth: 800,
    title: Text(context.strings.newProject),
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
                      change: (category) => select(templatesIn(category).first),
                      child: menuLabel(selected.category.label),
                    ),
                    DeskMenu<FurnitureTemplate>(
                      title: selected.title,
                      selected: selected,
                      items: [
                        for (final template in templatesIn(selected.category))
                          (template, template.title),
                      ],
                      change: select,
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
    final model = template == FurnitureTemplate.hoodCabinet
        ? project.edit({
            for (final b in project.beams)
              if (b.hinge != null) b.id,
          }, (b) => b.swingDoor(1))
        : project;
    if (template == FurnitureTemplate.signatureCabinet ||
        template == FurnitureTemplate.hoodCabinet) {
      camera
        ..yaw = .38
        ..pitch = .23;
    } else if (template == FurnitureTemplate.picnicTable) {
      camera
        ..yaw = -.88
        ..pitch = .64;
    }
    camera.fit(model, size);
    camera.scale *= 1.18;
    DrawingPainter(
      scene: Scene(model, camera, size),
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
