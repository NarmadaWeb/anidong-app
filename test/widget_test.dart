import 'package:anidong/main.dart';
import 'package:anidong/screens/splash_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  testWidgets('App starts and displays splash screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // The app should start with a SplashScreen.
    expect(find.byType(SplashScreen), findsOneWidget);

    // Pump to handle the initial frames but not necessarily the 3-second delay
    await tester.pump();

    // To avoid "Timer is still pending" error, we can pump with duration or just let it be.
    // Actually, we should pump for 3 seconds if we want to see it navigate,
    // or just use pumpAndSettle with a long timeout if needed.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
  });
}
