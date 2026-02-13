import 'package:anidong/data/services/database_helper.dart';
import 'package:anidong/main.dart';
import 'package:anidong/screens/splash_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUp(() {
    DatabaseHelper.databasePath = inMemoryDatabasePath;
  });

  testWidgets('App starts and displays splash screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // The app should start with a SplashScreen.
    expect(find.byType(SplashScreen), findsOneWidget);

    // Pump to handle the initial frames but not necessarily the 3-second delay
    await tester.pump();
  });
}
