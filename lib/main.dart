import 'package:anidong/screens/splash_screen.dart';
import 'package:anidong/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Jadikan fungsi main menjadi async
Future<void> main() async {
  // Tambahkan baris ini. Ini sangat penting!
  // Memastikan semua binding platform siap sebelum menjalankan aplikasi.
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AniDong',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        brightness: Brightness.dark,
        primaryColor: AppColors.accent,
        // Pastikan Anda menggunakan GoogleFonts di sini
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme).apply(
          bodyColor: AppColors.primaryText,
          displayColor: AppColors.primaryText,
        ),
        iconTheme: const IconThemeData(color: AppColors.secondaryText),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
