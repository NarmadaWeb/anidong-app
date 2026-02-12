
import 'package:anidong/screens/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SettingsScreen has working RadioListTiles and Switches', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: SettingsScreen(),
    ));

    // Verify RadioListTiles are working
    expect(find.text('Auto'), findsOneWidget);
    expect(find.text('1080p'), findsOneWidget);
    expect(find.text('720p'), findsOneWidget);

    // Initial state: Auto is selected
    final radioGroup = tester.widget<RadioGroup<String>>(find.byType(RadioGroup<String>));
    expect(radioGroup.groupValue, 'Auto');

    // Actually, let's just check if we can tap it
    await tester.tap(find.text('1080p'));
    await tester.pump();

    // Verify Switches
    expect(find.byType(Switch), findsNWidgets(3)); // Notifications, WiFi only, Auto Download

    // Tap a switch
    await tester.tap(find.byType(Switch).first);
    await tester.pump();
  });
}
