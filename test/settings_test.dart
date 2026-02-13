
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
    final radioGroupFinder = find.byType(RadioGroup<String>);
    final radioGroup = tester.widget<RadioGroup<String>>(radioGroupFinder);
    expect(radioGroup.groupValue, 'Auto');

    // Tap to change quality
    await tester.tap(find.text('1080p'));
    await tester.pumpAndSettle();

    // Verify RadioGroup state updated
    final updatedRadioGroup = tester.widget<RadioGroup<String>>(radioGroupFinder);
    expect(updatedRadioGroup.groupValue, '1080p');

    // Verify Switches (WiFi only, Auto Download)
    expect(find.byType(Switch), findsNWidgets(2));

    // Initial switch states (WiFi only is default true)
    final firstSwitchFinder = find.byType(Switch).first;
    final firstSwitch = tester.widget<Switch>(firstSwitchFinder);
    expect(firstSwitch.value, true);

    // Tap a switch (WiFi only)
    await tester.tap(firstSwitchFinder);
    await tester.pumpAndSettle();

    // Verify switch state updated
    final updatedFirstSwitch = tester.widget<Switch>(firstSwitchFinder);
    expect(updatedFirstSwitch.value, false);
  });
}
