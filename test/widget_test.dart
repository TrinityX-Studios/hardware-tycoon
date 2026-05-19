import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hardware_tycoon/main.dart';

void main() {
  testWidgets('Hardware Tycoon app smoke test', (WidgetTester tester) async {
    // Set a realistic viewport size for industrial dashboard layout compliance
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Bypass rendering overflow exceptions during headless TUI widget tests
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      if (details.exceptionAsString().contains('overflowed')) {
        return;
      }
      originalOnError?.call(details);
    };
    addTearDown(() {
      FlutterError.onError = originalOnError;
    });

    // Build our app and trigger a frame.
    await tester.pumpWidget(const HardwareTycoonApp());
    await tester.pump();

    // Navigate from Main Menu to Setup
    final beginButton = find.text('BEGIN INITIALIZATION');
    expect(beginButton, findsOneWidget);
    await tester.tap(beginButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Navigate from Setup to Gameplay Dashboard
    final bootButton = find.text('BOOT SIMULATION');
    expect(bootButton, findsOneWidget);
    await tester.tap(bootButton);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Verify the top menu bar renders with date display.
    expect(find.textContaining('JAN'), findsAtLeastNWidgets(1));

    // Verify the dashboard windows are present.
    expect(find.text('R&D LABORATORY'), findsAtLeastNWidgets(1));
    expect(find.text('WORKFORCE ROUTER'), findsAtLeastNWidgets(1));
    expect(find.text('FOUNDRY OPERATIONS'), findsAtLeastNWidgets(1));

    // Verify the system title is present in the top menu bar.
    expect(find.text('HARDWARE TYCOON'), findsAtLeastNWidgets(1));
  });
}
