import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'package:tlustudy_planner/theme/app_colors.dart';

/// App-wide Material 3 themes built on top of [AppColors].
///
/// Light : white surfaces, blue accents, black text.
/// Dark  : black surfaces, blue accents, white text.
class AppTheme {
  AppTheme._();

  // Kept for backwards compatibility with screens that still reference these.
  static const Color primaryColor = AppColors.blue600;
  static const Color secondaryColor = AppColors.blue400;
  static const Color accentColor = AppColors.blue500;
  static const Color backgroundColor = Color(0xFFF4F7FC);

  static ThemeData get lightTheme => _build(Brightness.light);
  static ThemeData get darkTheme => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final Color bg = isDark ? const Color(0xFF0A0E17) : const Color(0xFFF4F7FC);
    final Color surface = isDark ? const Color(0xFF121826) : Colors.white;
    final Color surfaceAlt =
        isDark ? const Color(0xFF19212F) : const Color(0xFFF7FAFF);
    final Color border =
        isDark ? const Color(0xFF232C3D) : const Color(0xFFE3EAF5);
    final Color text = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final Color textSoft =
        isDark ? const Color(0xFFB6C2D4) : const Color(0xFF475569);
    final Color accent = isDark ? AppColors.blue400 : AppColors.blue600;
    final Color onAccent = isDark ? const Color(0xFF08111F) : Colors.white;

    final base = ThemeData(useMaterial3: true, brightness: brightness);

    final scheme = ColorScheme(
      brightness: brightness,
      primary: accent,
      onPrimary: onAccent,
      primaryContainer: isDark ? const Color(0xFF16233E) : AppColors.blue50,
      onPrimaryContainer: isDark ? AppColors.blue200 : AppColors.blue700,
      secondary: isDark ? AppColors.blue300 : AppColors.blue500,
      onSecondary: onAccent,
      secondaryContainer: isDark ? const Color(0xFF16233E) : AppColors.blue50,
      onSecondaryContainer: isDark ? AppColors.blue200 : AppColors.blue700,
      tertiary: accent,
      onTertiary: onAccent,
      error: isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626),
      onError: Colors.white,
      errorContainer:
          isDark ? const Color(0xFF3F1212) : const Color(0xFFFEE2E2),
      onErrorContainer:
          isDark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C),
      surface: surface,
      onSurface: text,
      surfaceContainerLowest: isDark ? const Color(0xFF0D1220) : Colors.white,
      surfaceContainerLow: isDark ? const Color(0xFF111827) : surfaceAlt,
      surfaceContainer: isDark ? const Color(0xFF151D2C) : surfaceAlt,
      surfaceContainerHigh: isDark ? const Color(0xFF19212F) : bg,
      surfaceContainerHighest:
          isDark ? const Color(0xFF1E273A) : const Color(0xFFEDF2FA),
      onSurfaceVariant: textSoft,
      outline: border,
      outlineVariant: border,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: isDark ? Colors.white : const Color(0xFF0F172A),
      onInverseSurface: isDark ? const Color(0xFF0F172A) : Colors.white,
      inversePrimary: isDark ? AppColors.blue700 : AppColors.blue200,
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      splashFactory: InkSparkle.splashFactory,
      textTheme: base.textTheme
          .apply(bodyColor: text, displayColor: text)
          .copyWith(
            headlineMedium: base.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              color: text,
            ),
            titleLarge: base.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: text,
            ),
            titleMedium: base.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: text,
            ),
            labelLarge: base.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: text,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: onAccent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: onAccent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          side: BorderSide(color: border, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: onAccent,
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        shape: const CircleBorder(),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: isDark ? const Color(0xFF16233E) : AppColors.blue50,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected) ? accent : textSoft,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 11.5,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
            color: states.contains(WidgetState.selected) ? accent : textSoft,
          ),
        ),
      ),
      bottomAppBarTheme: base.bottomAppBarTheme.copyWith(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: surfaceAlt,
        selectedColor: isDark ? const Color(0xFF16233E) : AppColors.blue50,
        side: BorderSide(color: border),
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          color: text,
          fontSize: 13,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? surfaceAlt : Colors.white,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: TextStyle(color: textSoft.withValues(alpha: 0.8)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: accent, width: 1.8),
        ),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: textSoft, size: 22),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: accent),
      listTileTheme: ListTileThemeData(
        iconColor: textSoft,
        textColor: text,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? const Color(0xFF1E273A) : const Color(0xFF0F172A),
        contentTextStyle: const TextStyle(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
        },
      ),
    );
  }
}
