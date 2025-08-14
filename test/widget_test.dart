import 'package:anidong/main.dart';
import 'package:anidong/screens/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App starts and displays home screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // The app starts with a SplashScreen. We need to wait for animations
    // and transitions to complete. pumpAndSettle is good for this.
    await tester.pumpAndSettle();

    // After the splash screen, the MainScreen should be visible,
    // and within it, the HomeScreen should be the initial page.
    expect(find.byType(HomeScreen), findsOneWidget);

    // Also, let's verify a key element from the home screen is present,
    // like the section title for "New Episodes".
    expect(find.text('New Episodes'), findsOneWidget);
  });
}
