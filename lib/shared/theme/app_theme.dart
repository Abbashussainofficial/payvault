import 'package:flutter/material.dart';

const _primaryBlue = Color(0xFF1565C0);
const _darkBg = Color(0xFF1E1E2E);
const _darkSurface = Color(0xFF2A2A3E);
const _darkCard = Color(0xFF252537);

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primaryBlue,
      brightness: Brightness.light,
      primary: _primaryBlue,
      onPrimary: Colors.white,
      secondary: const Color(0xFF1976D2),
      surface: Colors.white,
      onSurface: const Color(0xFF1A1A2E),
    ),
    scaffoldBackgroundColor: const Color(0xFFF5F7FA),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF1A1A2E),
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: Color(0x1A000000),
      titleTextStyle: TextStyle(
        color: Color(0xFF1A1A2E),
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        side: BorderSide(color: Color(0xFFE8ECF0)),
      ),
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
        textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.3),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _primaryBlue,
        side: BorderSide(color: _primaryBlue),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
        textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.3),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _primaryBlue,
        textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: Color(0xFFDDE3EA)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: Color(0xFFDDE3EA)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: _primaryBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: Color(0xFFE53E3E)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: Color(0xFFE53E3E), width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: TextStyle(color: Color(0xFF64748B), fontSize: 14),
      hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFFE8ECF0), thickness: 1),
    textTheme: _textTheme(Brightness.light),
    iconTheme: const IconThemeData(color: Color(0xFF475569)),
  );

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primaryBlue,
      brightness: Brightness.dark,
      primary: const Color(0xFF4A9EFF),
      onPrimary: Colors.white,
      secondary: const Color(0xFF2196F3),
      surface: _darkSurface,
      onSurface: const Color(0xFFE2E8F0),
    ),
    scaffoldBackgroundColor: _darkBg,
    appBarTheme: AppBarTheme(
      backgroundColor: _darkSurface,
      foregroundColor: const Color(0xFFE2E8F0),
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: Colors.black38,
      titleTextStyle: const TextStyle(
        color: Color(0xFFE2E8F0),
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    ),
    cardTheme: CardThemeData(
      color: _darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
      ),
      margin: EdgeInsets.zero,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.3),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF4A9EFF),
        side: const BorderSide(color: Color(0xFF4A9EFF)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.3),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF4A9EFF),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1A1A2E),
      border: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: Color(0xFF4A9EFF), width: 2),
      ),
      errorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: Color(0xFFFC8181)),
      ),
      focusedErrorBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: Color(0xFFFC8181), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
    ),
    dividerTheme: DividerThemeData(color: Colors.white.withValues(alpha: 0.08), thickness: 1),
    textTheme: _textTheme(Brightness.dark),
    iconTheme: const IconThemeData(color: Color(0xFF94A3B8)),
  );

  static TextTheme _textTheme(Brightness brightness) {
    final base = brightness == Brightness.light ? const Color(0xFF1A1A2E) : const Color(0xFFE2E8F0);
    final muted = brightness == Brightness.light ? const Color(0xFF64748B) : const Color(0xFF94A3B8);
    return TextTheme(
      displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: base, letterSpacing: -0.5),
      displayMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: base, letterSpacing: -0.3),
      headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: base),
      headlineMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: base),
      headlineSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: base),
      titleLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: base),
      titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: base),
      titleSmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: muted),
      bodyLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: base),
      bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: base),
      bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: muted),
      labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: base, letterSpacing: 0.3),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: muted, letterSpacing: 0.2),
      labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: muted, letterSpacing: 0.3),
    );
  }
}
