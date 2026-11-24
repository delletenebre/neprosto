import 'package:cupertino_ui/cupertino_ui.dart' as cu;
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:neprosto/editor/controller.dart';
import 'package:neprosto/editor/desktop.dart';
import 'package:neprosto/editor/drawing.dart';
import 'package:neprosto/editor/scene.dart';
import 'package:neprosto/editor/model.dart';
import 'package:neprosto/editor/palette.dart';
import 'package:neprosto/editor/project_tab_bar.dart';
import 'package:neprosto/editor/project_tabs.dart';
import 'package:neprosto/main.dart';

void main() {
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
      final target = t.getCenter(close);
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
      expect(find.byType(apple ? cu.CupertinoSwitch : Switch), findsWidgets);
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
