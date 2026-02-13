import 'package:anidong/utils/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get light {
    final baseTextTheme = ThemeData.light().textTheme;
    return ThemeData(
      scaffoldBackgroundColor: Colors.white,
      brightness: Brightness.light,
      primaryColor: AppColors.accent,
      hintColor: Colors.grey[600],
      cardColor: Colors.white,
      dividerColor: Colors.grey[200],
      textTheme: GoogleFonts.poppinsTextTheme(baseTextTheme).apply(
        bodyColor: Colors.black87,
        displayColor: Colors.black87,
      ),
      iconTheme: const IconThemeData(color: Colors.black54),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: MaterialColor(AppColors.accent.toARGB32(), {
          50: AppColors.accent.withValues(alpha: 0.1),
          100: AppColors.accent.withValues(alpha: 0.2),
          200: AppColors.accent.withValues(alpha: 0.3),
          300: AppColors.accent.withValues(alpha: 0.4),
          400: AppColors.accent.withValues(alpha: 0.6),
          500: AppColors.accent.withValues(alpha: 0.8),
          600: AppColors.accent,
          700: AppColors.accent,
          800: AppColors.accent,
          900: AppColors.accent,
        }),
        brightness: Brightness.light,
        backgroundColor: Colors.white,
      ).copyWith(
        secondary: AppColors.accent,
        surface: Colors.white,
        onSurface: Colors.black87,
      ),
    );
  }

  static ThemeData get dark {
    final baseTextTheme = ThemeData.dark().textTheme;
    return ThemeData(
      scaffoldBackgroundColor: AppColors.background,
      brightness: Brightness.dark,
      primaryColor: AppColors.accent,
      hintColor: AppColors.secondaryText,
      cardColor: AppColors.darkSurface,
      dividerColor: AppColors.surface,
      textTheme: GoogleFonts.poppinsTextTheme(baseTextTheme).apply(
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
        primarySwatch: MaterialColor(AppColors.accent.toARGB32(), {
          50: AppColors.accent.withValues(alpha: 0.1),
          100: AppColors.accent.withValues(alpha: 0.2),
          200: AppColors.accent.withValues(alpha: 0.3),
          300: AppColors.accent.withValues(alpha: 0.4),
          400: AppColors.accent.withValues(alpha: 0.6),
          500: AppColors.accent.withValues(alpha: 0.8),
          600: AppColors.accent,
          700: AppColors.accent,
          800: AppColors.accent,
          900: AppColors.accent,
        }),
        brightness: Brightness.dark,
        backgroundColor: AppColors.background,
      ).copyWith(secondary: AppColors.accent),
    );
  }
}
