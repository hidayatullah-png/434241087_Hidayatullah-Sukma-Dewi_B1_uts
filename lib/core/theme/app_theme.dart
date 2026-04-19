import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  // -- Light Theme (tidak diubah sama sekali) --
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.wrnDeepPurple,
        onPrimary: Colors.white,
        secondary: AppColors.wrnLightPurple,
        onSecondary: Colors.white,
        error: AppColors.error,
        onError: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.wrnDeepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.wrnDeepPurple,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  // -- Dark Theme --
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        // Primary tetap pakai purple palette yang sama
        primary:
            AppColors.wrnLightPurple, // lebih terang agar kontras di dark bg
        onPrimary: Colors.black,
        secondary: AppColors.wrnBtsPurple,
        onSecondary: Colors.white,
        error: Color(0xFFCF6679), // error lebih soft di dark
        onError: Colors.black,
        // Surface & background pakai dark palette yang sudah ada
        surface: AppColors.wrnDarkInput, // 0xFF1E1E2C
        onSurface: AppColors.textWhite,
      ),
      scaffoldBackgroundColor: AppColors.wrnDarkBg, // 0xFF13131D
      // AppBar — pakai dark bg, bukan purple, biar clean
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.wrnDarkBg,
        foregroundColor: AppColors.textWhite,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),

      // ElevatedButton — warna tombol tetap purple, pakai wrnBtsPurple
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.wrnBtsPurple,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Input field — pakai wrnDarkInput sebagai fill color
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.wrnDarkInput,
        hintStyle: const TextStyle(color: AppColors.textGrey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.wrnLightPurple,
            width: 1.5,
          ),
        ),
      ),

      // Card — sedikit lebih terang dari background
      cardTheme: CardThemeData(
        color: AppColors.wrnDarkInput,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppColors.wrnShapePurple.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: AppColors.wrnShapePurple.withOpacity(0.3),
      ),

      // Text — pakai textWhite sebagai default
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.textWhite),
        bodyMedium: TextStyle(color: AppColors.textWhite),
        bodySmall: TextStyle(color: AppColors.textGrey),
        titleLarge: TextStyle(
          color: AppColors.textWhite,
          fontWeight: FontWeight.bold,
        ),
        titleMedium: TextStyle(
          color: AppColors.textWhite,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(color: AppColors.textGrey),
        labelSmall: TextStyle(color: AppColors.textGrey),
      ),

      // Icon default
      iconTheme: const IconThemeData(color: AppColors.textWhite),
    );
  }
}
