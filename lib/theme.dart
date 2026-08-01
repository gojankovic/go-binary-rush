import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/palette_settings.dart';

// ── Palette data ──────────────────────────────────────────────
class Palette {
  final Color bg;
  final Color g0, g1, g2, g3, g4, g5;
  final Color amber, red, cyan;

  const Palette({
    required this.bg,
    required this.g0,
    required this.g1,
    required this.g2,
    required this.g3,
    required this.g4,
    required this.g5,
    required this.amber,
    required this.red,
    required this.cyan,
  });
}

const _greenPalette = Palette(
  bg: Color(0xFF000000),
  g0: Color(0xFF0A1A0A),
  g1: Color(0xFF163B1F),
  g2: Color(0xFF2A7A3A),
  g3: Color(0xFF4ECF6A),
  g4: Color(0xFF7DFF97),
  g5: Color(0xFFB8FFC7),
  amber: Color(0xFFFFB547),
  red: Color(0xFFFF4D4D),
  cyan: Color(0xFF4DD6FF),
);

const _altPalette = Palette(
  bg: Color(0xFF000000),
  g0: Color(0xFF071218),
  g1: Color(0xFF173544),
  g2: Color(0xFF2A6B8E),
  g3: Color(0xFF4EBDDF),
  g4: Color(0xFF7DE2FF),
  g5: Color(0xFFB8F2FF),
  amber: Color(0xFFFFB547),
  red: Color(0xFFFF8A47),
  cyan: Color(0xFF7DE2FF),
);

Palette get _current => PaletteSettings.index.value == PaletteSettings.indexAlt
    ? _altPalette
    : _greenPalette;

// ── Palette façade ────────────────────────────────────────────
class AppColors {
  static Color get bg => _current.bg;
  static Color get g0 => _current.g0;
  static Color get g1 => _current.g1;
  static Color get g2 => _current.g2;
  static Color get g3 => _current.g3;
  static Color get g4 => _current.g4;
  static Color get g5 => _current.g5;
  static Color get amber => _current.amber;
  static Color get red => _current.red;
  static Color get cyan => _current.cyan;
}

// ── Glow helpers ──────────────────────────────────────────────
class AppGlow {
  static List<BoxShadow> get sm => [
    BoxShadow(color: AppColors.g4.withValues(alpha: 0.45), blurRadius: 4),
  ];
  static List<BoxShadow> get md => [
    BoxShadow(color: AppColors.g4.withValues(alpha: 0.55), blurRadius: 10),
    BoxShadow(color: AppColors.g3.withValues(alpha: 0.25), blurRadius: 22),
  ];
  static List<BoxShadow> get lg => [
    BoxShadow(color: AppColors.g4.withValues(alpha: 0.65), blurRadius: 18),
    BoxShadow(color: AppColors.g3.withValues(alpha: 0.35), blurRadius: 40),
  ];
  static List<BoxShadow> get amber => [
    BoxShadow(color: AppColors.amber.withValues(alpha: 0.55), blurRadius: 8),
  ];
  static List<BoxShadow> get red => [
    BoxShadow(color: AppColors.red.withValues(alpha: 0.55), blurRadius: 8),
  ];
}

// ── Text styles ───────────────────────────────────────────────
class AppText {
  static TextStyle kicker({Color? color}) => GoogleFonts.jetBrainsMono(
    fontSize: 10,
    letterSpacing: 2.2,
    color: color ?? AppColors.g2,
  );
  static TextStyle label({Color? color}) => GoogleFonts.jetBrainsMono(
    fontSize: 13,
    letterSpacing: 1.8,
    color: color ?? AppColors.g3,
    shadows: AppGlow.sm
        .map((s) => Shadow(color: s.color, blurRadius: s.blurRadius))
        .toList(),
  );
  static TextStyle hudValue({Color? color}) => GoogleFonts.jetBrainsMono(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: color ?? AppColors.g4,
    shadows: AppGlow.sm
        .map((s) => Shadow(color: s.color, blurRadius: s.blurRadius))
        .toList(),
  );
  static TextStyle bigTarget({Color? color}) => GoogleFonts.jetBrainsMono(
    fontSize: 64,
    fontWeight: FontWeight.bold,
    color: color ?? AppColors.g5,
    height: 1.0,
    shadows: AppGlow.lg
        .map((s) => Shadow(color: s.color, blurRadius: s.blurRadius))
        .toList(),
  );
  static TextStyle mono({
    double size = 14,
    Color? color,
    FontWeight weight = FontWeight.normal,
  }) => GoogleFonts.jetBrainsMono(
    fontSize: size,
    color: color ?? AppColors.g3,
    fontWeight: weight,
  );
}

// ── Theme ─────────────────────────────────────────────────────

// Only Regular (w400), SemiBold (w600), Bold (w700) JetBrainsMono ttf's are
// bundled in google_fonts/. Material's default TextTheme uses w500 (Medium)
// for several roles; with runtime fetch disabled that would throw. Snap any
// requested weight to the nearest bundled neighbour.
FontWeight _snapToBundledWeight(FontWeight? w) {
  if (w == null) return FontWeight.w400;
  final v = w.value;
  if (v <= 400) return FontWeight.w400;
  if (v <= 600) return FontWeight.w600;
  return FontWeight.w700;
}

TextStyle? _safeStyle(TextStyle? s) {
  if (s == null) return null;
  return s.copyWith(fontWeight: _snapToBundledWeight(s.fontWeight));
}

TextTheme _normalizeWeights(TextTheme base) {
  return TextTheme(
    displayLarge: _safeStyle(base.displayLarge),
    displayMedium: _safeStyle(base.displayMedium),
    displaySmall: _safeStyle(base.displaySmall),
    headlineLarge: _safeStyle(base.headlineLarge),
    headlineMedium: _safeStyle(base.headlineMedium),
    headlineSmall: _safeStyle(base.headlineSmall),
    titleLarge: _safeStyle(base.titleLarge),
    titleMedium: _safeStyle(base.titleMedium),
    titleSmall: _safeStyle(base.titleSmall),
    bodyLarge: _safeStyle(base.bodyLarge),
    bodyMedium: _safeStyle(base.bodyMedium),
    bodySmall: _safeStyle(base.bodySmall),
    labelLarge: _safeStyle(base.labelLarge),
    labelMedium: _safeStyle(base.labelMedium),
    labelSmall: _safeStyle(base.labelSmall),
  );
}

ThemeData buildAppTheme() {
  final base = ThemeData.dark();
  return base.copyWith(
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.dark(surface: AppColors.bg, primary: AppColors.g4),
    textTheme: GoogleFonts.jetBrainsMonoTextTheme(
      _normalizeWeights(base.textTheme),
    ).apply(bodyColor: AppColors.g3, displayColor: AppColors.g4),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.bg,
      elevation: 0,
      iconTheme: IconThemeData(color: AppColors.g2),
      titleTextStyle: GoogleFonts.jetBrainsMono(
        color: AppColors.g4,
        fontSize: 15,
        letterSpacing: 4,
      ),
    ),
  );
}
