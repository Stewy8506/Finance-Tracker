import 'package:flutter/material.dart';

const _kAccent = Color(0xFF6366F1); // Indigo

ThemeData buildDarkTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: _kAccent,
    brightness: Brightness.dark,
    primary: _kAccent,
    secondary: const Color(0xFF818CF8),
    surface: const Color(0xFF1E1E2E),
    onSurface: const Color(0xFFE0E0F0),
    error: const Color(0xFFF87171),
    tertiary: const Color(0xFF34D399),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: const Color(0xFF12121F),
    fontFamily: 'Roboto',
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF12121F),
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1E1E2E),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF2D2D42), width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF1A1A2E),
      indicatorColor: _kAccent.withValues(alpha: 0.2),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: _kAccent, size: 24);
        }
        return const IconThemeData(color: Color(0xFF6B7280), size: 24);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
              color: _kAccent, fontSize: 11, fontWeight: FontWeight.w600);
        }
        return const TextStyle(color: Color(0xFF6B7280), fontSize: 11);
      }),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: _kAccent,
      inactiveTrackColor: _kAccent.withValues(alpha: 0.2),
      thumbColor: _kAccent,
      overlayColor: _kAccent.withValues(alpha: 0.12),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF2D2D42),
      selectedColor: _kAccent.withValues(alpha: 0.3),
      labelStyle: const TextStyle(fontSize: 12),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1E1E2E),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2D2D42)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2D2D42)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _kAccent, width: 2),
      ),
      labelStyle: const TextStyle(color: Color(0xFF9CA3AF)),
      hintStyle: const TextStyle(color: Color(0xFF6B7280)),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: _kAccent,
      unselectedLabelColor: Color(0xFF6B7280),
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(color: _kAccent, width: 2),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _kAccent,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF2D2D42),
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF2D2D42),
      thickness: 1,
    ),
    textTheme: const TextTheme(
      displaySmall:
          TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -1),
      headlineMedium:
          TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5),
      headlineSmall:
          TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      titleLarge:
          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      titleMedium:
          TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      bodyLarge: TextStyle(fontSize: 16),
      bodyMedium: TextStyle(fontSize: 14),
      bodySmall:
          TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
      labelSmall:
          TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
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
    success: Color(0xFF34D399),
    warning: Color(0xFFFBBF24),
    high: Color(0xFFF87171),
    medium: Color(0xFFFBBF24),
    low: Color(0xFF34D399),
    cardGradientStart: Color(0xFF1E1E2E),
    cardGradientEnd: Color(0xFF252538),
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
    return this;
  }
}
