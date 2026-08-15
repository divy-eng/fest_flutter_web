import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_first_app/main.dart';

void main() {
  testWidgets('College fest dashboard renders events', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MaterialApp(home: CollegeFestDashboard()));
    await tester.pump();

    await tester.tap(find.text('Events'));
    await tester.pumpAndSettle();

    expect(find.text('KLE Haveri BCA Independence Day 2026'), findsOneWidget);
    expect(find.text('Ai and Machine Learning'), findsOneWidget);
    expect(find.text('Flutter Workshop'), findsOneWidget);
    expect(find.text('Kannada Orchestor'), findsOneWidget);
  });
}
