import 'package:anidong/main.dart';
import 'package:anidong/screens/oauth/login_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App starts and displays login screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Wait for auth status check
    await tester.pumpAndSettle();

    // The app should start with a LoginScreen if not authenticated.
    expect(find.byType(LoginScreen), findsOneWidget);

    // Verify welcome text
    expect(find.text('Welcome to AniDong'), findsOneWidget);
  });
}
