import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neprosto/editor/controller.dart';
import 'package:neprosto/editor/model.dart';
import 'package:neprosto/editor/scene.dart';
import 'package:neprosto/editor/stock_sketch.dart';
import 'package:neprosto/main.dart';

void main() {
  test(
    'A raised beam starts at the anchor and keeps the reference section',
    () {
      const size = Size(900, 600);
      final p = Project.bench(), ref = p.beams.first;
      final base = ref.origin + axis(2) * ref.size.z;
      final sketch = StockSketch(WorkPlane.xy().through(base), ref);
      for (final view in [
        ViewAngle.front,
        ViewAngle.iso,
        ViewAngle.perspective,
      ]) {
        final cam = Camera()
          ..view(view)
          ..fit(p, size);
        final end = base + cam.right * 175 + axis(2) * 250;
        final pointer = cam.project(end, size);
        for (final upright in [true, false]) {
          final anchor = sketch.raisedEnd(
            cam,
            size,
            pointer,
            base,
            null,
            verticalOnly: upright,
          )!;
          final expected = upright ? base + axis(2) * 250 : end;
          expect(anchor.point.distanceTo(expected), lessThan(1e-7));
          final beam = sketch.make(99, base, anchor.point, raised: true);
          expect(beam.origin, base);
          expect(beam.size.y, ref.size.y);
          expect(beam.size.z, ref.size.z);
          expect(beam.along.dot(beam.across).abs(), lessThan(1e-8));
          expect(beam.up.length, closeTo(1, 1e-8));
        }
      }
      final top = Camera()
        ..view(ViewAngle.top)
        ..scale = 2;
      final at = top.project(base, size);
      expect(
        sketch
            .raisedEnd(
              top,
              size,
              at + const Offset(80, -120),
              base,
              null,
              verticalOnly: true,
            )!
            .point,
        base + axis(2) * 60,
      );
      expect(
        sketch
            .raisedEnd(
              top,
              size,
              at + const Offset(80, 120),
              base,
              null,
              verticalOnly: true,
            )!
            .point,
        base,
      );
    },
  );
  testWidgets(
    'Changing held modifiers updates the same preview and commits it once',
    (t) async {
      await t.binding.setSurfaceSize(const Size(1240, 800));
      addTearDown(() => t.binding.setSurfaceSize(null));
      final e = Editor(Project('Чертёж', []))..snap = false;
      await t.pumpWidget(NeprostoApp(editor: e));
      await t.pumpAndSettle();
      await t.tap(find.text('Новая деталь'));
      await t.pump();
      final drawing = find.byKey(const Key('drawing'));
      final start = t.getCenter(drawing);
      await t.tapAt(start);
      await t.pump();
      final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: start);
      final end = start + const Offset(36, -60);
      await mouse.moveTo(end);
      await t.pump();
      expect(e.preview!.along.z.abs(), lessThan(1e-8));
      await t.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await t.pump();
      expect(e.preview!.along.z, inExclusiveRange(0, 1));
      await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await t.pump();
      expect(e.preview!.along, axis(2));
      await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await t.pump();
      expect(e.preview!.along.z, inExclusiveRange(0, 1));
      await t.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await t.pump();
      expect(e.preview!.along.z.abs(), lessThan(1e-8));
      await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await t.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await t.pump();
      final preview = e.preview!;
      await t.tapAt(end);
      await t.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await t.pumpAndSettle();
      expect(e.single!.along, axis(2));
      expect(e.single!.size, preview.size);
      e.undo();
      expect(e.project.beams, isEmpty);
      await mouse.removePointer();
    },
  );
}
