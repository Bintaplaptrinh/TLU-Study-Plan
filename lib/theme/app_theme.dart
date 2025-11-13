import 'package:flutter/material.dart';

/// Centralized theme configuration for the application.
///
/// Applies the "Modern Soft UI" palette across both light and dark modes
/// with rounded shapes and subtle shadows everywhere.
class AppTheme {
  static const Color primaryColor = Color(0xFFFA2426);
  static const Color backgroundColor = Color(0xFFF1F5F8);
  static const Color secondaryColor = Color(0xFF939FD0);
  static const Color accentColor = Color(0xFFFCEE79);

  static ThemeData get lightTheme => _buildLightTheme();
  static ThemeData get darkTheme => _buildDarkTheme();

  static ThemeData _buildLightTheme() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: backgroundColor,
    );

    final colorScheme = ColorScheme.fromSeed(
      seedColor: secondaryColor,
      brightness: Brightness.light,
      background: backgroundColor,
      surface: Colors.white,
    ).copyWith(
      primary: secondaryColor,
      onPrimary: Colors.white,
      secondary: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.5),
      onSecondary: Colors.white,
      tertiary: accentColor,
      onTertiary: const Color(0xFF1D1E25),
      background: backgroundColor,
      onBackground: const Color(0xFF1D1E25),
      surface: Colors.white,
      onSurface: const Color(0xFF1D1E25),
      surfaceTint: secondaryColor.withOpacity(0.08),
      outline: const Color.fromARGB(255, 29, 29, 29).withOpacity(0.5),
      outlineVariant: secondaryColor.withOpacity(0.12),
    );

    return base.copyWith(
      colorScheme: colorScheme,
      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: base.cardTheme.copyWith(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withOpacity(0.06),
        elevation: 6,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: primaryColor.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: base.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(color: secondaryColor.withOpacity(0.4), width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 8,
        shape: CircleBorder(),
      ),
      bottomAppBarTheme: base.bottomAppBarTheme.copyWith(
        color: Colors.white,
        elevation: 12,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withOpacity(0.08),
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: Colors.white,
        selectedColor: accentColor,
        disabledColor: Colors.white70,
        labelStyle: base.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: secondaryColor.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: secondaryColor.withOpacity(0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: secondaryColor.withOpacity(0.2),
        thickness: 1,
      ),
      iconTheme: base.iconTheme.copyWith(color: secondaryColor),
      textTheme: base.textTheme.apply(
        bodyColor: colorScheme.onSurface,
        displayColor: colorScheme.onSurface,
      ),
    );
  }

  static ThemeData _buildDarkTheme() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
    );

    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
    ).copyWith(
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      background: const Color(0xFF12131A),
      surface: const Color(0xFF1C1D25),
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFF12131A),
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: const Color(0xFF1C1D25),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: base.cardTheme.copyWith(
        color: const Color(0xFF1C1D25),
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      floatingActionButtonTheme: base.floatingActionButtonTheme.copyWith(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      bottomAppBarTheme: base.bottomAppBarTheme.copyWith(
        color: const Color(0xFF1C1D25),
        elevation: 8,
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: const Color(0xFF1C1D25),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
      ),
    );
  }
}
