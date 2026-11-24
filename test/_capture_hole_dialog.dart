import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:neprosto/editor/controller.dart';
import 'package:neprosto/editor/desktop.dart';
import 'package:neprosto/editor/model.dart';
import 'package:neprosto/main.dart';

void main() {
  testWidgets('Capture the hole editor', (t) async {
    await t.runAsync(() async {
      for (final family in ['.AppleSystemUIFont','CupertinoSystemText','CupertinoSystemDisplay','Roboto','Arial']) {
        final bytes = await File('/System/Library/Fonts/SFNS.ttf').readAsBytes();
        await (FontLoader(family)..addFont(Future.value(ByteData.sublistView(bytes)))).load();
      }
      await (FontLoader('MaterialIcons')..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
    });
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = const Size(1250, 850);
    addTearDown(t.view.reset);
    final door = Beam(1, 'Распашная дверца с петлями справа', Vector3.zero(), Vector3(2189,597,16), axis(2), -axis(1),
      holes: const [PanelHole(1094.5, 298.5, 38),PanelHole(165,86,35,depth:12,fromEnd:true,fromFarEdge:true)]);
    final editor = Editor(Project('Шкаф', [door]))..select(1);
    await t.pumpWidget(RepaintBoundary(key:const Key('capture'),child:NeprostoApp(editor:editor)));
    await t.pumpAndSettle();
    await t.ensureVisible(find.text('Отверстия'));
    await t.tap(find.text('Отверстия').hitTestable());
    await t.pumpAndSettle();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(const MethodChannel('neprosto/popup'), (_) async => 1);
    await t.tap(find.text('Отверстие 1 из 2'));
    await t.pumpAndSettle();
    expect(find.text('Отверстие 2 из 2'), findsOneWidget);
    final box = find.descendant(of:find.byType(DeskDialog),matching:find.byWidgetPredicate((w)=>w is Container && w.constraints?.maxWidth==790));
    final rect = t.getRect(box).inflate(5);
    final render = t.renderObject<RenderRepaintBoundary>(find.byKey(const Key('capture')));
    await t.runAsync(() async {
      final image = await (render.debugLayer! as OffsetLayer).toImage(rect,pixelRatio:1.5);
      final png=await image.toByteData(format:ui.ImageByteFormat.png);
      await File('/Users/user/.codex/visualizations/2026/11/24/01a20d91-824c-7220-9334-3d9797f6694c/hole-editor.png').writeAsBytes(png!.buffer.asUint8List());
      image.dispose();
    });
  },variant:TargetPlatformVariant.only(TargetPlatform.macOS));
}
