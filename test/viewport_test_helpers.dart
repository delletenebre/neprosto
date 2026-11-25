import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neprosto/editor/scene.dart';

Future<void> selectViewportView(WidgetTester tester, ViewAngle view) async {
  await tester.tap(find.byKey(ValueKey(view)));
  await tester.pumpAndSettle();
}
