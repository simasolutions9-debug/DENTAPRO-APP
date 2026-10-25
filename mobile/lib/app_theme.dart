import "package:flutter/material.dart";

class AppColors {
  static const navy = Color(0xFF094C86);
  static const deepBlue = Color(0xFF07447D);
  static const blue = Color(0xFF176796);
  static const teal = Color(0xFF20C3B8);
  static const cyan = Color(0xFF19A8CC);
  static const aqua = Color(0xFF4AC5D5);
  static const background = Color(0xFFF5F9FC);
  static const surface = Color(0xFFFFFFFF);
  static const ink = Color(0xFF163852);
  static const muted = Color(0xFF7B91A3);
  static const border = Color(0xFFE5EDF2);
  static const gold = Color(0xFFFFB84D);
}

class AppTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.navy,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.blue,
      secondary: AppColors.teal,
      tertiary: AppColors.cyan,
      surface: AppColors.surface,
      onSurface: AppColors.ink,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: "Roboto",
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.navy,
          fontSize: 32,
          height: 1.12,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.7,
        ),
        headlineMedium: TextStyle(
          color: AppColors.navy,
          fontSize: 27,
          height: 1.15,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          color: AppColors.ink,
          fontSize: 19,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
        titleMedium: TextStyle(
          color: AppColors.ink,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(color: AppColors.ink, fontSize: 15, height: 1.45),
        bodyMedium: TextStyle(
          color: AppColors.muted,
          fontSize: 13,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
        labelSmall: TextStyle(
          color: AppColors.muted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.teal,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(56),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.55,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.blue,
          minimumSize: const Size.fromHeight(56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          side: const BorderSide(color: AppColors.border),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.teal.withValues(alpha: 0.14),
        height: 70,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>(
          (states) => TextStyle(
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected)
                ? AppColors.navy
                : AppColors.muted,
          ),
        ),
      ),
    );
  }
}
