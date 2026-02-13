
import 'package:anidong/providers/theme_provider.dart';
import 'package:anidong/screens/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('SettingsScreen has working RadioListTiles and Switches', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({}); // Mock SharedPreferences for ThemeProvider

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );

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

    // Verify Switches (Dark Mode, WiFi only, Auto Download)
    expect(find.byType(Switch), findsNWidgets(3));

    // Initial switch states (WiFi only is default true)
    // Dark Mode (index 0) defaults to true in ThemeProvider mock/init
    // WiFi Only (index 1) defaults to true in SettingsScreen state

    final wifiSwitchFinder = find.byType(Switch).at(1); // WiFi Only is the second switch now
    final wifiSwitch = tester.widget<Switch>(wifiSwitchFinder);
    expect(wifiSwitch.value, true);

    // Tap a switch (WiFi only)
    await tester.ensureVisible(wifiSwitchFinder);
    await tester.tap(wifiSwitchFinder);
    await tester.pumpAndSettle();

    // Verify switch state updated
    final updatedWifiSwitch = tester.widget<Switch>(wifiSwitchFinder);
    expect(updatedWifiSwitch.value, false);
  });
}
