import 'package:flutter/material.dart';

class AppTheme {
  static const Color accent = Color(0xFF2563EB);   
  static const Color accentLight = Color(0xFF60A5FA);
  static const Color accentGold = Color(0xFFD97706);
  static const Color success = Color(0xFF16A34A);
  static const Color danger = Color(0xFFDC2626);
  static const Color warning = Color(0xFFF59E0B);

  static ThemeData light() {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF7F7FA),
      fontFamily: 'Sans',
      primaryColor: accent,
      colorScheme: const ColorScheme.light(
        primary: accent,
        secondary: accentLight,
        surface: Colors.white,
        onSurface: Color(0xFF1A1A2E),
        onPrimary: Colors.white,
        outline: Color(0xFFE5E7EB),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF1A1A2E),
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
      ),
      cardColor: Colors.white,
      dividerColor: const Color(0xFFE5E7EB),
    );
  }

  // ─── DARK THEME DATA ───
  static ThemeData dark() {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0F0F14),
      fontFamily: 'Sans',
      primaryColor: accent,
      colorScheme: const ColorScheme.dark(
        primary: accent,
        secondary: accentLight,
        surface: Color(0xFF1A1A24),
        onSurface: Color(0xFFF0F0F5),
        onPrimary: Colors.white,
        outline: Color(0xFF2A2A38),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A1A24),
        foregroundColor: Color(0xFFF0F0F5),
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: Colors.transparent,
      ),
      cardColor: const Color(0xFF1A1A24),
      dividerColor: const Color(0xFF2A2A38),
    );
  }
}

/// Kısa erişim — Theme.of(context) yerine extension ile
extension AppColorsExt on BuildContext {
  ColorScheme get colors => Theme.of(this).colorScheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // Sık kullanılanlar
  Color get bg => Theme.of(this).scaffoldBackgroundColor;
  Color get card => Theme.of(this).cardColor;
  Color get textPrimary => colors.onSurface;
  Color get textSecondary => isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);
  Color get border => colors.outline;
  Color get accent => colors.primary;
}
