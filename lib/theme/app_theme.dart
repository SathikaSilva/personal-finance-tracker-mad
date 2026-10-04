import 'package:flutter/material.dart';

// Application color palette and Material 3 theme configurations
class AppColors {
  static const Color primary = Color(0xFF52758A);
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color darkBg = Color(0xFF1F2937);
  static const Color darkCard = Color(0xFF283446);
  static const Color danger = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
}

class AppTheme {
  // Official Android recommended typography font family
  static const String fontFamily = 'Roboto';

  // Light Theme
  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        fontFamily: fontFamily,
        typography: Typography.material2021(platform: TargetPlatform.android),
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.lightBg,
        primaryColor: AppColors.primary,
        colorScheme: const ColorScheme.light(primary: AppColors.primary),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.lightBg,
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
      );

  // Dark Theme
  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        fontFamily: fontFamily,
        typography: Typography.material2021(platform: TargetPlatform.android),
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.darkBg,
        primaryColor: AppColors.primary,
        colorScheme: const ColorScheme.dark(primary: AppColors.primary),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.darkBg,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: AppColors.darkCard,
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.darkCard,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
      );
}
