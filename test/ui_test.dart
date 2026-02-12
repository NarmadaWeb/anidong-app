
import 'package:anidong/widgets/mode_switch.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UI Components Tests', () {
    testWidgets('ModeSwitch toggles correctly', (WidgetTester tester) async {
      String currentMode = 'anime';

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ModeSwitch(
            currentMode: currentMode,
            onModeChanged: (newMode) {
              currentMode = newMode;
            },
          ),
        ),
      ));

      expect(find.text('Anime'), findsOneWidget);
      expect(find.text('Donghua'), findsOneWidget);

      // Tap to switch to Donghua
      await tester.tap(find.byType(ModeSwitch));
      await tester.pump();

      expect(currentMode, 'donghua');
    });
  });
}
