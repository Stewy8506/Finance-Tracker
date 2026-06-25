import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const _kAccent = Color(0xFF818CF8); // Soft Indigo

ThemeData buildDarkTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: _kAccent,
    brightness: Brightness.dark,
    primary: _kAccent,
    secondary: const Color(0xFFA5B4FC),
    surface: const Color(0xFF111215),
    onSurface: const Color(0xFFF4F4F6),
    error: const Color(0xFFEF4444),
    tertiary: const Color(0xFF10B981),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: const Color(0xFF08090A),
    fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF08090A),
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.plusJakartaSans(
        color: colorScheme.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
      ),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF111215),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF1F2128), width: 0.8),
      ),
      margin: EdgeInsets.zero,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF111215),
      indicatorColor: _kAccent.withValues(alpha: 0.15),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: _kAccent, size: 24);
        }
        return const IconThemeData(color: Color(0xFF8E8E93), size: 24);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return GoogleFonts.plusJakartaSans(
              color: _kAccent, fontSize: 11, fontWeight: FontWeight.w600);
        }
        return GoogleFonts.plusJakartaSans(color: const Color(0xFF8E8E93), fontSize: 11);
      }),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: _kAccent,
      inactiveTrackColor: _kAccent.withValues(alpha: 0.2),
      thumbColor: _kAccent,
      overlayColor: _kAccent.withValues(alpha: 0.12),
      trackHeight: 4,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF1F2128),
      selectedColor: _kAccent.withValues(alpha: 0.2),
      labelStyle: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFFF4F4F6)),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF111215),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1F2128)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1F2128)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kAccent, width: 1.5),
      ),
      labelStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF8E8E93)),
      hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF52525B)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: _kAccent,
      unselectedLabelColor: const Color(0xFF8E8E93),
      labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
      unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500, fontSize: 13),
      indicator: const UnderlineTabIndicator(
        borderSide: BorderSide(color: Color(0xFF818CF8), width: 2),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _kAccent,
      foregroundColor: const Color(0xFF08090A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF111215),
      contentTextStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFFF4F4F6)),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF1F2128), width: 0.8),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF1F2128),
      thickness: 0.8,
    ),
    textTheme: TextTheme(
      displaySmall: GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.0,
        color: const Color(0xFFF4F4F6),
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: const Color(0xFFF4F4F6),
      ),
      headlineSmall: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: const Color(0xFFF4F4F6),
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: const Color(0xFFF4F4F6),
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: const Color(0xFFF4F4F6),
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: const Color(0xFFF4F4F6),
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: const Color(0xFFE4E4E7),
      ),
      bodySmall: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: const Color(0xFF8E8E93),
      ),
      labelSmall: GoogleFonts.plusJakartaSans(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        color: const Color(0xFF8E8E93),
      ),
    ),
    extensions: [LedgerColors.dark],
  );
}

/// Custom color tokens for Ledger
class LedgerColors extends ThemeExtension<LedgerColors> {
  final Color success;
  final Color warning;
  final Color high;
  final Color medium;
  final Color low;
  final Color cardGradientStart;
  final Color cardGradientEnd;

  const LedgerColors({
    required this.success,
    required this.warning,
    required this.high,
    required this.medium,
    required this.low,
    required this.cardGradientStart,
    required this.cardGradientEnd,
  });

  static const dark = LedgerColors(
    success: Color(0xFF10B981), // Emerald
    warning: Color(0xFFF59E0B), // Amber
    high: Color(0xFFEF4444),    // Crimson
    medium: Color(0xFFF59E0B),
    low: Color(0xFF10B981),
    cardGradientStart: Color(0xFF111215),
    cardGradientEnd: Color(0xFF111215),
  );

  @override
  ThemeExtension<LedgerColors> copyWith({
    Color? success,
    Color? warning,
    Color? high,
    Color? medium,
    Color? low,
    Color? cardGradientStart,
    Color? cardGradientEnd,
  }) {
    return LedgerColors(
      success: success ?? this.success,
      warning: warning ?? this.warning,
      high: high ?? this.high,
      medium: medium ?? this.medium,
      low: low ?? this.low,
      cardGradientStart: cardGradientStart ?? this.cardGradientStart,
      cardGradientEnd: cardGradientEnd ?? this.cardGradientEnd,
    );
  }

  @override
  ThemeExtension<LedgerColors> lerp(
      ThemeExtension<LedgerColors>? other, double t) {
    if (other is! LedgerColors) return this;
    return LedgerColors(
      success: Color.lerp(success, other.success, t) ?? success,
      warning: Color.lerp(warning, other.warning, t) ?? warning,
      high: Color.lerp(high, other.high, t) ?? high,
      medium: Color.lerp(medium, other.medium, t) ?? medium,
      low: Color.lerp(low, other.low, t) ?? low,
      cardGradientStart: Color.lerp(cardGradientStart, other.cardGradientStart, t) ?? cardGradientStart,
      cardGradientEnd: Color.lerp(cardGradientEnd, other.cardGradientEnd, t) ?? cardGradientEnd,
    );
  }
}
