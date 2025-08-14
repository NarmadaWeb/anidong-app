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
        hintColor: AppColors.secondaryText,
        cardColor: AppColors.darkSurface,
        dividerColor: AppColors.surface,
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme).apply(
          bodyColor: AppColors.primaryText,
          displayColor: AppColors.primaryText,
        ),
        iconTheme: const IconThemeData(color: AppColors.secondaryText),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: AppColors.primaryText,
        ),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: MaterialColor(AppColors.accent.value, {
            50: AppColors.accent.withOpacity(0.1),
            100: AppColors.accent.withOpacity(0.2),
            200: AppColors.accent.withOpacity(0.3),
            300: AppColors.accent.withOpacity(0.4),
            400: AppColors.accent.withOpacity(0.6),
            500: AppColors.accent.withOpacity(0.8),
            600: AppColors.accent,
            700: AppColors.accent,
            800: AppColors.accent,
            900: AppColors.accent,
          }),
          brightness: Brightness.dark,
          backgroundColor: AppColors.background,
        ).copyWith(secondary: AppColors.accent),
      ),
      home: const SplashScreen(),
    );
  }
}
