import 'package:flutter/gestures.dart'
    show PointerDeviceKind, kSecondaryMouseButton;
import 'package:flutter/rendering.dart' show ClipRRectLayer;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:neprosto/editor/controller.dart';
import 'package:neprosto/editor/desktop.dart';
import 'package:neprosto/editor/finish_picker.dart';
import 'package:neprosto/editor/drawing.dart';
import 'package:neprosto/editor/scene.dart';
import 'package:neprosto/editor/model.dart';
import 'package:neprosto/main.dart';

void main() {
  Future<void> mount(WidgetTester tester, [Editor? editor]) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      NeprostoApp(editor: editor ?? Editor(Project.bench())),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'The settings panel travels between the button and its full bounds in both directions',
    (tester) async {
      await mount(tester);
      final button = find.byTooltip('Настройки');
      final source = tester.getRect(button);
      await tester.tap(button);
      await tester.pump();

      final context = tester.element(find.byType(DeskDialog));
      final route = ModalRoute.of(context)! as DeskDialogRoute;
      expect(route.source!.bounds, source);
      final surface = find.byKey(DeskDialogRoute.surfaceKey(context)!);
      final target = tester.getRect(surface);
      expect(source.width, lessThan(target.width));
      expect(source.height, lessThan(target.height));

      void expectFrame() {
        final progress = Curves.easeInOutCubic.transform(
          route.animation!.value,
        );
        expect(progress, inExclusiveRange(.2, .8));
        final frame = Rect.lerp(source, target, progress)!;
        final clips = tester.layers.whereType<ClipRRectLayer>().map(
          (layer) => layer.clipRRect!.outerRect,
        );
        expect(clips, contains(rectMoreOrLessEquals(frame, epsilon: .01)));
      }

      final half = route.transitionDuration ~/ 2;
      await tester.pump(half);
      expectFrame();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pump();
      await tester.pump(half);
      expectFrame();
      await tester.pumpAndSettle();
      expect(surface, findsNothing);
    },
    variant: TargetPlatformVariant({
      TargetPlatform.macOS,
      TargetPlatform.windows,
    }),
  );

  testWidgets(
    'A canvas double-click starts at the projected bounds of the clicked board',
    (tester) async {
      final editor = Editor(Project.bench())..setView(ViewAngle.top);
      await mount(tester, editor);
      final drawing = find.byKey(const Key('drawing'));
      final scene =
          (tester.widget<CustomPaint>(drawing).painter! as DrawingPainter)
              .scene;
      final local = editor.camera.project(Vector3(240, 40, 450), scene.size);
      final board = scene.hit(local)!.beam;
      final origin = tester.getTopLeft(drawing);
      final projectedCorners = board.corners.map(
        (p) => editor.camera.project(p, scene.size),
      );
      final expected = (Path()..addPolygon(projectedCorners.toList(), true))
          .getBounds()
          .intersect(Offset.zero & scene.size)
          .shift(origin);
      await tester.tapAt(origin + local);
      await tester.pump(const Duration(milliseconds: 80));
      await tester.tapAt(origin + local);
      await tester.pumpAndSettle();
      final route =
          ModalRoute.of(tester.element(find.byType(DeskDialog)))!
              as DeskDialogRoute;
      expect(
        route.source!.bounds,
        rectMoreOrLessEquals(expected, epsilon: .01),
      );
    },
  );

  testWidgets(
    'A nested finish dialog uses its own button inside the part dialog',
    (tester) async {
      await mount(tester);
      final row = find.byKey(const ValueKey(1)).first;
      await tester.tap(
        row,
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Название и размеры…'));
      await tester.pumpAndSettle();
      final parent = find.byType(DeskDialog);
      final partRoute =
          ModalRoute.of(tester.element(parent))! as DeskDialogRoute;
      final rowBounds = tester.getRect(row);
      expect(partRoute.source!.bounds.topLeft, rowBounds.topLeft);
      expect(partRoute.source!.bounds.width, rowBounds.width);

      final button = find.descendant(
        of: parent,
        matching: find.byType(PartFinishButton),
      );
      final source = tester.getRect(button);
      await tester.tap(button);
      await tester.pumpAndSettle();
      final nested =
          ModalRoute.of(tester.element(find.byType(DeskDialog).last))!
              as DeskDialogRoute;
      expect(nested.source!.bounds, source);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(ModalRoute.of(tester.element(parent)), same(partRoute));
    },
  );

  testWidgets('Reduced motion presents and dismisses the panel immediately', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await mount(tester);
    await tester.tap(find.byTooltip('Настройки'));
    await tester.pump();
    final panel = find.byType(DeskDialog);
    final route = ModalRoute.of(tester.element(panel))! as DeskDialogRoute;
    expect(route.transitionDuration, Duration.zero);
    expect(route.animation!.isCompleted, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    await tester.pump();
    expect(panel, findsNothing);
  });
}
