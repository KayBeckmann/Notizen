import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:notizen/main.dart';

void main() {
  testWidgets('App starts and shows title', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: NotizenApp(),
      ),
    );

    // Wait for the app to settle
    await tester.pumpAndSettle();

    // Verify that the app shows the expected title
    expect(find.text('Notizen'), findsWidgets);
  });

  testWidgets('FAB is visible on home screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: NotizenApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify that the FAB is present
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.text('Neue Notiz'), findsOneWidget);
  });
}
