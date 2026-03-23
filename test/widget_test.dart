import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:notizen/main.dart';

void main() {
  testWidgets('App starts and shows AppBar', (WidgetTester tester) async {
    // Set compact screen size (phone)
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: NotizenApp(),
      ),
    );

    // Pump a few frames instead of pumpAndSettle to avoid timeout
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify that the app shows the AppBar
    expect(find.byType(AppBar), findsOneWidget);
  });

  testWidgets('FAB is visible on compact (phone) screen', (WidgetTester tester) async {
    // Set compact screen size (phone) - less than 600dp
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: NotizenApp(),
      ),
    );

    // Pump a few frames instead of pumpAndSettle to avoid timeout
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify that the FAB is present on compact layout
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.text('Neue Notiz'), findsOneWidget);
  });
}
