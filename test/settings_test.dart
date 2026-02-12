
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

    // Tap to change quality
    await tester.tap(find.text('1080p'));
    await tester.pumpAndSettle();

    // Verify RadioGroup state updated
    final updatedRadioGroup = tester.widget<RadioGroup<String>>(find.byType(RadioGroup<String>));
    expect(updatedRadioGroup.groupValue, '1080p');

    // Verify Switches
    expect(find.byType(Switch), findsNWidgets(3)); // Notifications, WiFi only, Auto Download

    // Initial switch states
    final notificationSwitch = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
    expect(notificationSwitch.value, true);

    // Tap a switch (Notifications)
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    // Verify switch state updated
    final updatedNotificationSwitch = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
    expect(updatedNotificationSwitch.value, false);
  });
}
