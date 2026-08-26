import 'package:flutter/material.dart';

/// Design tokens for TLU Study Planner.
///
/// Light mode : white is the primary surface, blue is the sub/accent colour,
///              text is near-black.
/// Dark  mode : near-black surfaces with blue accents and white text.
///
/// Every colour used by the redesigned screens comes from here, so retheming
/// the app is a single-file change.
class AppColors {
  AppColors._();

  // ─────────────────────────── Blue ramp (shared) ───────────────────────────
  static const Color blue50 = Color(0xFFEFF6FF);
  static const Color blue100 = Color(0xFFDBEAFE);
  static const Color blue200 = Color(0xFFBFDBFE);
  static const Color blue300 = Color(0xFF93C5FD);
  static const Color blue400 = Color(0xFF60A5FA);
  static const Color blue500 = Color(0xFF3B82F6);
  static const Color blue600 = Color(0xFF2563EB);
  static const Color blue700 = Color(0xFF1D4ED8);
  static const Color blue900 = Color(0xFF1E3A8A);

  // ───────────────────────────── Light palette ──────────────────────────────
  static const Color _bgL = Color(0xFFF4F7FC); // page background
  static const Color _surfaceL = Color(0xFFFFFFFF); // cards, sheets  (primary)
  static const Color _surfaceAltL = Color(0xFFF7FAFF); // subtle fills
  static const Color _borderL = Color(0xFFE3EAF5);
  static const Color _textL = Color(0xFF0F172A); // black words
  static const Color _textSoftL = Color(0xFF475569);
  static const Color _textMutedL = Color(0xFF94A3B8);
  static const Color _accentL = blue600; // blue  (sub colour)
  static const Color _accentSoftL = blue400;
  static const Color _accentTintL = blue50;

  // ────────────────────────────── Dark palette ──────────────────────────────
  static const Color _bgD = Color(0xFF0A0E17); // near black
  static const Color _surfaceD = Color(0xFF121826);
  static const Color _surfaceAltD = Color(0xFF19212F);
  static const Color _borderD = Color(0xFF232C3D);
  static const Color _textD = Color(0xFFF1F5F9); // white words
  static const Color _textSoftD = Color(0xFFB6C2D4);
  static const Color _textMutedD = Color(0xFF7A8699);
  static const Color _accentD = blue400; // blue reads better on black
  static const Color _accentSoftD = blue300;
  static const Color _accentTintD = Color(0xFF16233E);

  static bool _isDark(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark;

  // Surfaces
  static Color bg(BuildContext c) => _isDark(c) ? _bgD : _bgL;
  static Color surface(BuildContext c) => _isDark(c) ? _surfaceD : _surfaceL;
  static Color surfaceAlt(BuildContext c) =>
      _isDark(c) ? _surfaceAltD : _surfaceAltL;
  static Color border(BuildContext c) => _isDark(c) ? _borderD : _borderL;

  // Text
  static Color text(BuildContext c) => _isDark(c) ? _textD : _textL;
  static Color textSoft(BuildContext c) => _isDark(c) ? _textSoftD : _textSoftL;
  static Color textMuted(BuildContext c) =>
      _isDark(c) ? _textMutedD : _textMutedL;

  // Accent (blue)
  static Color accent(BuildContext c) => _isDark(c) ? _accentD : _accentL;
  static Color accentSoft(BuildContext c) =>
      _isDark(c) ? _accentSoftD : _accentSoftL;
  static Color accentTint(BuildContext c) =>
      _isDark(c) ? _accentTintD : _accentTintL;

  /// Text/icon colour that sits on top of a filled accent surface.
  static Color onAccent(BuildContext c) =>
      _isDark(c) ? const Color(0xFF08111F) : Colors.white;

  /// The gradient used by the "selected day" pill and the primary CTA.
  static List<Color> accentGradient(BuildContext c) => _isDark(c)
      ? const [blue500, Color(0xFF1E40AF)]
      : const [blue500, blue700];

  // Status colours (used by class cards / exam states)
  static Color success(BuildContext c) =>
      _isDark(c) ? const Color(0xFF4ADE80) : const Color(0xFF16A34A);
  static Color warning(BuildContext c) =>
      _isDark(c) ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
  static Color danger(BuildContext c) =>
      _isDark(c) ? const Color(0xFFF87171) : const Color(0xFFDC2626);

}

/// Shared shape / spacing tokens so radii stay consistent across screens.
class AppRadius {
  AppRadius._();
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 28;
  static const double pill = 999;
}
