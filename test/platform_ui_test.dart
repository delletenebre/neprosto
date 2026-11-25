import 'package:cupertino_ui/cupertino_ui.dart' as cu;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:neprosto/editor/controller.dart';
import 'package:neprosto/editor/desktop.dart';
import 'package:neprosto/editor/drawing.dart';
import 'package:neprosto/editor/inspector.dart';
import 'package:neprosto/editor/scene.dart';
import 'package:neprosto/editor/work_plane_picker.dart';
import 'package:neprosto/editor/model.dart';
import 'package:neprosto/editor/palette.dart';
import 'package:neprosto/editor/parts_panel.dart';
import 'package:neprosto/editor/project_tab_bar.dart';
import 'package:neprosto/editor/project_tabs.dart';
import 'package:neprosto/main.dart';

void main() {
  testWidgets(
    'Parts and dimensions show their creation button below the tabs',
    (t) async {
      await t.binding.setSurfaceSize(const Size(1200, 780));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final editor = Editor(Project('Тест', []));
      await t.pumpWidget(NeprostoApp(editor: editor));
      await t.pumpAndSettle();

      final dimensionsTab = find.text('Размеры  0');
      Future<void> tapCreationButton(String label) async {
        final button = find.ancestor(
          of: find.text(label),
          matching: find.byType(DeskButton),
        );
        expect(
          t.getRect(button).top,
          greaterThan(t.getRect(dimensionsTab).bottom),
        );
        await t.tap(button);
        await t.pumpAndSettle();
      }

      await tapCreationButton('Новая деталь');
      expect(editor.tool, Tool.beam);
      await t.tap(dimensionsTab);
      await t.pumpAndSettle();
      await tapCreationButton('Новый размер');
      expect(editor.tool, Tool.measure);
    },
    variant: TargetPlatformVariant({
      TargetPlatform.macOS,
      TargetPlatform.windows,
    }),
  );

  testWidgets(
    'Dragging the same edge moves the part or resizes it with Shift',
    (t) async {
      await t.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final part = Beam(
        1,
        'Полка',
        Vector3.zero(),
        Vector3(100, 34, 10),
        axis(0),
        axis(1),
      );
      final other = part.copy(id: 2, origin: Vector3(0, 60, 0));
      final project = Project('Шкаф', [part, other]);
      final editor = Editor(project)
        ..setView(ViewAngle.top)
        ..select(1)
        ..snapByDefault = false
        ..fitRequested = false;
      editor.camera.scale = 2;
      await t.pumpWidget(NeprostoApp(editor: editor));
      await t.pumpAndSettle();
      final drawing = find.byKey(const Key('drawing'));
      DrawingPainter painter() =>
          t.widget<CustomPaint>(drawing).painter! as DrawingPainter;
      Offset screen(Vector3 p) =>
          t.getTopLeft(drawing) + editor.camera.project(p, t.getSize(drawing));
      final at = screen(Vector3(50, 34, 10));
      final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: at);
      await mouse.moveTo(at);
      await t.pump();
      expect(painter().resizePart, isNull);
      expect(painter().hover, isNull);
      expect(painter().moveHighlight, {1});
      await mouse.down(at);
      await mouse.moveBy(const Offset(0, -80));
      await mouse.up();
      await t.pump();
      expect(editor.single!.size, part.size);
      expect(editor.single!.origin, Vector3(0, 40, 0));
      editor.undo();
      await mouse.moveTo(at);
      await t.pump();
      for (final key in [
        LogicalKeyboardKey.shiftLeft,
        LogicalKeyboardKey.shiftRight,
      ]) {
        await t.sendKeyDownEvent(key);
        await t.pump();
        expect(painter().resizePart, 1);
        expect(painter().moveHighlight, isEmpty);
        expect(painter().activeEdge?.axis, 1);
        expect(painter().activeEdge?.positive, true);
        await t.sendKeyUpEvent(key);
        await t.pump();
        expect(painter().activeEdge, isNull);
        expect(painter().resizePart, isNull);
      }
      await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await mouse.down(at);
      await mouse.moveBy(const Offset(0, -80));
      await mouse.up();
      await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await t.pump();
      expect(editor.single!.origin, part.origin);
      expect(editor.single!.size, Vector3(100, 60, 10));
      expect(editor.project.byId[2], same(other));
      editor.undo();
      expect(editor.project, same(project));
      expect(editor.canUndo, false);
      await mouse.removePointer();
      await t.pump(kDoubleTapTimeout);
    },
    variant: TargetPlatformVariant({
      TargetPlatform.macOS,
      TargetPlatform.windows,
    }),
  );

  testWidgets(
    'A locked dimension has a distinct fill and space before its lock',
    (t) async {
      await t.binding.setSurfaceSize(const Size(1200, 780));
      addTearDown(() => t.binding.setSurfaceSize(null));
      addTearDown(t.platformDispatcher.clearPlatformBrightnessTestValue);
      await t.pumpWidget(NeprostoApp(editor: Editor(Project.bench())));
      await t.pumpAndSettle();
      await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await t.sendKeyEvent(LogicalKeyboardKey.keyW);
      await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await t.pumpAndSettle();

      final field = find.byKey(const ValueKey('dialog-size-2'));
      final lock = find.byTooltip('Блокировать размер · Толщина');
      final unlock = find.byTooltip('Разблокировать размер · Толщина');
      Color? fill() {
        if (defaultTargetPlatform == TargetPlatform.macOS) {
          return t
              .widget<cu.CupertinoTextField>(
                find.descendant(
                  of: field,
                  matching: find.byType(cu.CupertinoTextField),
                ),
              )
              .decoration!
              .color;
        }
        return t
            .widget<InputDecorator>(
              find.descendant(of: field, matching: find.byType(InputDecorator)),
            )
            .decoration
            .fillColor;
      }

      for (final palette in EditorPalette.values) {
        t.platformDispatcher.platformBrightnessTestValue = palette.brightness;
        await t.pumpAndSettle();
        expect(t.getRect(lock).left - t.getRect(field).right, 6);
        expect(fill(), palette.field);
        await t.tap(lock);
        await t.pumpAndSettle();
        expect(fill(), palette.chrome);
        await t.tap(unlock);
        await t.pumpAndSettle();
        expect(fill(), palette.field);
      }
    },
    variant: TargetPlatformVariant({
      TargetPlatform.macOS,
      TargetPlatform.windows,
    }),
  );

  testWidgets(
    'Hover replaces the folder in place and closes only the hovered project',
    (t) async {
      await t.binding.setSurfaceSize(const Size(1300, 800));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final tabs = ProjectTabs(Editor(Project.bench()), dirty: true)..create();
      final active = tabs.value;
      await t.pumpWidget(NeprostoApp.withTabs(tabs));
      await t.pumpAndSettle();
      final bar = find.byType(ProjectTabBar);
      final title = find.descendant(of: bar, matching: find.text('Скамья'));
      final close = find.byTooltip('Закрыть вкладку «Скамья»');
      final benchTab = find.byKey(ObjectKey(tabs.items.first));
      final activeTab = find.byKey(ObjectKey(active));
      BoxDecoration frame(Finder tab) =>
          t
                  .widget<Container>(
                    find
                        .descendant(of: tab, matching: find.byType(Container))
                        .first,
                  )
                  .decoration!
              as BoxDecoration;
      expect(frame(benchTab).border, isNotNull);
      expect(frame(activeTab).border, isNotNull);
      expect(frame(benchTab).color, isNot(frame(activeTab).color));
      expect(t.getRect(benchTab).right, lessThan(t.getRect(activeTab).left));
      void expectFlatTab(Finder tab) {
        final surface = find
            .descendant(of: tab, matching: find.byType(Material))
            .first;
        final shape =
            t.widget<Material>(surface).shape! as RoundedRectangleBorder;
        expect(shape.borderRadius, BorderRadius.zero);
        final outer = t.getRect(tab), inner = t.getRect(surface);
        final border = frame(tab).border!.dimensions.resolve(TextDirection.ltr);
        expect(inner, border.deflateRect(outer));
      }

      if (defaultTargetPlatform == TargetPlatform.macOS) {
        expectFlatTab(activeTab);
        expectFlatTab(benchTab);
      }
      final folder = find.descendant(
        of: find.byKey(ObjectKey(tabs.items.first)),
        matching: find.byIcon(cu.CupertinoIcons.folder),
      );
      final dot = find.descendant(
        of: bar,
        matching: find.byIcon(cu.CupertinoIcons.circle_fill),
      );
      final position = t.getRect(title);
      final folderPosition = t.getRect(folder);
      expect(position.left - folderPosition.right, greaterThanOrEqualTo(6));
      expect(close, findsNothing);
      expect(dot, findsOneWidget);
      final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(position.center);
      await t.pumpAndSettle();
      if (defaultTargetPlatform == TargetPlatform.macOS) {
        expectFlatTab(benchTab);
      }
      expect(folder, findsNothing);
      expect(t.getCenter(close), folderPosition.center);
      expect(t.getRect(benchTab).contains(t.getTopLeft(close)), isTrue);
      expect(t.getRect(benchTab).contains(t.getBottomRight(close)), isTrue);
      expect(t.getRect(title), position);
      expect(dot, findsOneWidget);
      await mouse.moveTo(Offset.zero);
      await t.pumpAndSettle();
      expect(close, findsNothing);
      expect(t.getRect(folder), folderPosition);
      expect(dot, findsOneWidget);
      await mouse.moveTo(position.center);
      await t.pumpAndSettle();
      var target = t.getCenter(close);
      if (defaultTargetPlatform == TargetPlatform.macOS) {
        final hitArea = t.getRect(close);
        final paintArea = t.getRect(
          find.descendant(of: close, matching: find.byType(Material)),
        );
        expect(hitArea.size, const Size(29, 28));
        expect(paintArea.size, const Size.square(16));
        expect(paintArea.center, hitArea.center);
        target = hitArea.centerRight - const Offset(2, 0);
        expect(paintArea.contains(target), isFalse);
      }
      await mouse.moveTo(target);
      await mouse.down(target);
      await mouse.up();
      await t.pumpAndSettle();
      expect(find.textContaining('проект «Скамья»'), findsOneWidget);
      await t.tap(find.text('Не сохранять'));
      await t.pumpAndSettle();
      expect(tabs.items.single, same(active));
      expect(title, findsNothing);
    },
    variant: TargetPlatformVariant({
      TargetPlatform.macOS,
      TargetPlatform.windows,
    }),
  );

  testWidgets(
    'Mac tab context menu acts on the clicked project without switching documents',
    (t) async {
      await t.binding.setSurfaceSize(const Size(1100, 680));
      addTearDown(() => t.binding.setSurfaceSize(null));
      const popup = MethodChannel('neprosto/popup');
      final messenger = t.binding.defaultBinaryMessenger;
      int? choice;
      final menus = <Map<Object?, Object?>>[];
      messenger.setMockMethodCallHandler(popup, (call) async {
        if (call.method != 'contextMenu') return null;
        menus.add(call.arguments as Map<Object?, Object?>);
        return choice;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(popup, null));
      final tabs = ProjectTabs(Editor(Project.bench()))..create();
      final active = tabs.value, bench = tabs.items.first;
      await t.pumpWidget(NeprostoApp.withTabs(tabs));
      await t.pumpAndSettle();
      Future<void> openMenu() async {
        await t.tap(
          find.byKey(ObjectKey(bench)),
          buttons: kSecondaryMouseButton,
        );
        await t.pumpAndSettle();
      }

      await openMenu();
      expect(menus.single['heading'], 'Скамья');
      expect(menus.single['items'], ['Переименовать…', 'Закрыть вкладку']);
      expect(tabs.value, same(active));
      choice = 0;
      await openMenu();
      await t.enterText(find.byType(EditableText).last, 'Скамья у окна');
      await t.tap(find.text('Готово'));
      await t.pumpAndSettle();
      expect(bench.committed.name, 'Скамья у окна');
      expect(tabs.value, same(active));
      expect(find.text('Скамья у окна'), findsOneWidget);
      choice = 1;
      await openMenu();
      expect(find.textContaining('проект «Скамья у окна»'), findsOneWidget);
      await t.tap(find.text('Не сохранять'));
      await t.pumpAndSettle();
      expect(tabs.items.single, same(active));
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets(
    'Project dialog uses platform action order, keyboard dismissal and default action',
    (t) async {
      await t.binding.setSurfaceSize(const Size(1280, 800));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final platform = defaultTargetPlatform;
      final apple =
          platform == TargetPlatform.macOS || platform == TargetPlatform.iOS;
      final tabs = ProjectTabs(Editor(Project.bench()), dirty: true);
      await t.pumpWidget(NeprostoApp.withTabs(tabs));
      await t.pumpAndSettle();
      final modifier = apple
          ? LogicalKeyboardKey.metaLeft
          : LogicalKeyboardKey.controlLeft;
      await t.sendKeyDownEvent(modifier);
      await t.sendKeyEvent(LogicalKeyboardKey.keyW);
      await t.sendKeyUpEvent(modifier);
      await t.pumpAndSettle();
      final dialog = find.byType(DeskDialog);
      final save = find.descendant(
        of: dialog,
        matching: find.text('Сохранить'),
      );
      final cancel = find.text('Отмена');
      final (confirm, cancelPosition) = (
        t.getCenter(save),
        t.getCenter(cancel),
      );
      if ((confirm.dy - cancelPosition.dy).abs() < 1) {
        expect(
          confirm.dx < cancelPosition.dx,
          platform == TargetPlatform.windows,
        );
      } else {
        expect(
          confirm.dy < cancelPosition.dy,
          apple || platform == TargetPlatform.windows,
        );
      }
      if (apple) await t.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await t.sendKeyEvent(
        apple ? LogicalKeyboardKey.period : LogicalKeyboardKey.escape,
      );
      if (apple) await t.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await t.pumpAndSettle();
      expect(dialog, findsNothing);
      expect(tabs.value.dirty, isTrue);

      await t.tap(find.byTooltip('Настройки'));
      await t.pumpAndSettle();
      final step = find.byKey(const ValueKey('input-step'));
      expect(
        find.descendant(
          of: step,
          matching: find.byType(apple ? cu.CupertinoTextField : TextFormField),
        ),
        findsOneWidget,
      );
      final done = find.text('Готово');
      expect(done, findsOneWidget);
      expect(
        t.getCenter(done).dx < t.getCenter(cancel).dx,
        platform == TargetPlatform.windows,
      );
      expect(Focus.of(t.element(done)).hasFocus, isFalse);
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.pumpAndSettle();
      expect(dialog, findsNothing);
    },
    variant: TargetPlatformVariant({
      TargetPlatform.macOS,
      TargetPlatform.windows,
      TargetPlatform.linux,
      TargetPlatform.android,
      TargetPlatform.iOS,
    }),
  );

  testWidgets(
    'The Mac File menu uses the active project and respects modal dialogs',
    (t) async {
      await t.binding.setSurfaceSize(const Size(900, 570));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final messenger = t.binding.defaultBinaryMessenger;
      const popup = MethodChannel('neprosto/popup');
      const editorMenu = MethodChannel('neprosto/editor');
      var menuEnabled = false;
      messenger.setMockMethodCallHandler(popup, (call) async {
        if (call.method == 'workspaceMenuEnabled') {
          menuEnabled = call.arguments as bool;
        } else if (call.method == 'appearance') {
          expect(call.arguments['menu']['np.file'], 'Файл');
        }
        return null;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(popup, null));

      Future<ByteData?> invoke(String action) =>
          messenger.handlePlatformMessage(
            editorMenu.name,
            editorMenu.codec.encodeMethodCall(MethodCall(action)),
            null,
          );
      final tabs = ProjectTabs(Editor(Project.bench()));
      await t.pumpWidget(NeprostoApp.withTabs(tabs));
      await t.pumpAndSettle();
      expect(menuEnabled, isTrue);

      final openPicker = invoke('new');
      await t.pumpAndSettle();
      expect(menuEnabled, isFalse);
      await invoke('demo');
      expect(tabs.items, hasLength(1));
      await t.tap(find.text('Отмена'));
      await t.pumpAndSettle();
      await openPicker;
      expect(menuEnabled, isTrue);
      await invoke('demo');
      await t.pumpAndSettle();
      expect(tabs.items, hasLength(2));
      await invoke('close');
      await t.pumpAndSettle();
      expect(tabs.items, hasLength(1));
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets(
    'Drawing toolbar keeps related controls together when resized',
    (t) async {
      addTearDown(() => t.binding.setSurfaceSize(null));
      await t.binding.setSurfaceSize(const Size(1380, 800));
      await t.pumpWidget(NeprostoApp(editor: Editor(Project.bench())));
      await t.pumpAndSettle();
      final bar = find.byKey(const ValueKey('drawing-toolbar'));
      Finder control(String label) =>
          find.descendant(of: bar, matching: find.byTooltip(label));

      for (final width in [1380.0, 880.0, 790.0]) {
        await t.binding.setSurfaceSize(Size(width, 800));
        await t.pumpAndSettle();
        final undo = control('Отменить'), redo = control('Повторить');
        final save = control('Сохранить'), settings = control('Настройки');
        final plane = find.descendant(
          of: bar,
          matching: find.byType(WorkPlanePicker),
        );
        final grid = control('Видимость сетки');
        final zoomOut = control('Отдалить'), zoomIn = control('Приблизить');
        for (final action in [
          undo,
          redo,
          save,
          plane,
          grid,
          zoomOut,
          zoomIn,
          settings,
        ]) {
          expect(action.hitTestable(), findsOneWidget);
          expect(t.getRect(bar).contains(t.getCenter(action)), isTrue);
        }
        for (final (a, b) in [
          (undo, redo),
          (redo, save),
          (plane, grid),
          (zoomOut, zoomIn),
        ]) {
          final first = t.getRect(a), second = t.getRect(b);
          expect(first.center.dy, closeTo(second.center.dy, 1));
          expect(second.left - first.right, inInclusiveRange(0, toolbarGap));
        }
        expect(t.getCenter(settings).dy, closeTo(t.getCenter(zoomIn).dy, 1));
        expect(t.getRect(settings).right, closeTo(t.getRect(bar).right - 7, 1));
        if (defaultTargetPlatform == TargetPlatform.macOS) {
          final dividers = find.descendant(
            of: bar,
            matching: find.byType(VerticalDivider),
          );
          final select = find.descendant(
            of: bar,
            matching: find.byIcon(cu.CupertinoIcons.location_north),
          );
          final betweenGroups = t.getCenter(dividers.first);
          expect(
            betweenGroups.dx,
            inExclusiveRange(t.getRect(save).right, t.getRect(select).left),
          );
          expect(betweenGroups.dy, closeTo(t.getCenter(select).dy, 1));
        }
        if (width == 1380) {
          expect(t.getCenter(undo).dy, closeTo(t.getCenter(grid).dy, 1));
          expect(t.getCenter(save).dx, lessThan(t.getCenter(plane).dx));
        }
      }
    },
    variant: TargetPlatformVariant({
      TargetPlatform.macOS,
      TargetPlatform.windows,
    }),
  );

  testWidgets(
    'Mac window toolbar follows the document and toggles the drawing panels',
    (t) async {
      await t.binding.setSurfaceSize(const Size(880, 570));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final messenger = t.binding.defaultBinaryMessenger;
      const popup = MethodChannel('neprosto/popup');
      const commands = MethodChannel('neprosto/editor');
      late Map<Object?, Object?> toolbar;
      messenger.setMockMethodCallHandler(popup, (call) async {
        if (call.method != 'documentToolbar') return null;
        toolbar = call.arguments as Map<Object?, Object?>;
        return true;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(popup, null));
      Future<void> invoke(String action) async {
        await messenger.handlePlatformMessage(
          commands.name,
          commands.codec.encodeMethodCall(MethodCall(action)),
          null,
        );
        await t.pumpAndSettle();
      }

      final editor = Editor(Project.bench());
      final tabs = ProjectTabs(editor);
      await t.pumpWidget(NeprostoApp.withTabs(tabs));
      await t.pumpAndSettle();
      final drawingToolbar = find.byKey(const ValueKey('drawing-toolbar'));
      Finder action(String label) =>
          find.descendant(of: drawingToolbar, matching: find.byTooltip(label));
      bool enabled(String label) =>
          t
              .widget<DeskControl>(
                find.descendant(
                  of: action(label),
                  matching: find.byType(DeskControl),
                ),
              )
              .onPressed !=
          null;
      expect(action('Настройки').hitTestable(), findsOneWidget);
      expect(action('Сохранить').hitTestable(), findsOneWidget);
      expect(toolbar['labels'], {
        'partsSidebar': 'Дерево деталей',
        'inspector': 'Свойства',
      });
      expect(toolbar['title'], editor.project.name);
      expect(toolbar['edited'], false);
      expect(enabled('Отменить'), isFalse);
      expect(enabled('Повторить'), isFalse);
      final drawing = find.byKey(const Key('drawing'));
      final originalWidth = t.getSize(drawing).width;
      expect(
        t.getBottomRight(find.byIcon(cu.CupertinoIcons.location_north)).dy,
        lessThanOrEqualTo(t.getTopLeft(drawing).dy),
      );

      editor.commit(editor.project.copy(name: 'Полка'));
      await t.pumpAndSettle();
      expect(toolbar['title'], 'Полка');
      expect(toolbar['edited'], true);
      expect(enabled('Отменить'), isTrue);
      await t.tap(action('Отменить'));
      await t.pumpAndSettle();
      expect(toolbar['title'], 'Скамья');
      expect(toolbar['edited'], false);
      expect(enabled('Повторить'), isTrue);
      await t.tap(action('Повторить'));
      await t.pumpAndSettle();
      expect(toolbar['title'], 'Полка');

      await invoke('inspector');
      expect(find.byType(Inspector), findsNothing);
      expect(t.getSize(drawing).width, greaterThan(originalWidth));
      await invoke('partsSidebar');
      expect(find.byType(PartsPanel), findsNothing);
      expect(toolbar['panels'], {'partsSidebar': false, 'inspector': false});
      await invoke('inspector');
      await invoke('partsSidebar');
      expect(find.byType(Inspector), findsOneWidget);
      expect(find.byType(PartsPanel), findsOneWidget);
      expect(t.getSize(drawing).width, originalWidth);
      tabs.create();
      await t.pumpAndSettle();
      expect(toolbar['title'], tabs.value.committed.name);
      expect(enabled('Отменить'), isFalse);
      expect(enabled('Повторить'), isFalse);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );

  testWidgets('Mac project picker keeps the logo accent in both appearances', (
    t,
  ) async {
    await t.binding.setSurfaceSize(const Size(900, 570));
    addTearDown(() => t.binding.setSurfaceSize(null));
    addTearDown(t.platformDispatcher.clearPlatformBrightnessTestValue);
    await t.pumpWidget(NeprostoApp(editor: Editor(Project.bench())));
    await t.pumpAndSettle();
    await t.tap(find.byTooltip('Новый проект'));
    await t.pumpAndSettle();
    final create = find.text('Создать проект');
    final surface = find
        .ancestor(of: create, matching: find.byType(Material))
        .first;
    final units = find.byType(cu.CupertinoSlidingSegmentedControl<LengthUnit>);
    for (final palette in EditorPalette.values) {
      t.platformDispatcher.platformBrightnessTestValue = palette.brightness;
      await t.pumpAndSettle();
      final context = t.element(create);
      expect(context.colors, palette);
      expect(t.widget<Material>(surface).color, const Color(0xffdfed87));
      expect(
        DefaultTextStyle.of(context).style.color,
        EditorPalette.onHighlight,
      );
      expect(
        t
            .widget<cu.CupertinoSlidingSegmentedControl<LengthUnit>>(units)
            .thumbColor,
        EditorPalette.highlight,
      );
    }
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets(
    'Mac default button stays solid and only keyboard focus draws its matching outline',
    (t) async {
      await t.pumpWidget(
        cu.CupertinoApp(
          localizationsDelegates: const [DefaultMaterialLocalizations.delegate],
          home: DeskDialog(
            title: const Text('Настройки'),
            content: const SizedBox(width: 200),
            actions: [
              DeskButton(onPressed: () {}, child: const Text('Отмена')),
              DeskButton(
                primary: true,
                onPressed: () {},
                child: const Text('Готово'),
              ),
            ],
          ),
        ),
      );
      await t.pumpAndSettle();
      final label = find.text('Готово');
      final surface = find
          .ancestor(of: label, matching: find.byType(Material))
          .first;
      RoundedRectangleBorder shape() =>
          t.widget<Material>(surface).shape! as RoundedRectangleBorder;
      final idle = shape();
      expect(idle.side, BorderSide.none);
      final fill = t.widget<Material>(surface).color!;
      expect(fill.a, 1);
      final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(t.getCenter(label));
      await t.pumpAndSettle();
      expect(shape().side, BorderSide.none);
      final labelColor = DefaultTextStyle.of(t.element(label)).style.color;
      await mouse.down(t.getCenter(label));
      await t.pump();
      expect(shape().side, BorderSide.none);
      expect(t.widget<Material>(surface).color, fill);
      expect(DefaultTextStyle.of(t.element(label)).style.color, labelColor);
      await mouse.up();
      await mouse.removePointer();
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.pumpAndSettle();
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.pumpAndSettle();
      expect(Focus.of(t.element(label)).hasFocus, isTrue);
      expect(shape().borderRadius, idle.borderRadius);
      expect(shape().side.width, 2);
      expect(t.widget<Material>(surface).color, fill);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
  );
}
