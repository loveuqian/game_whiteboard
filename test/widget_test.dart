import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:game_whiteboard/main.dart';

void main() {
  testWidgets('Whiteboard renders smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const WhiteboardApp());

    expect(find.byWidgetPredicate((widget) => widget is SizedBox && widget.width == double.infinity && widget.height == double.infinity), findsOneWidget);
  });
}
