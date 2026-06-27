import 'package:flutter/material.dart';

const _primaryBlue = Color(0xFF1565C0);

class AppTheme {
  AppTheme._();

  // ── Light Theme ──────────────────────────────────────────────────────────────

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

  // ── Dark Theme ───────────────────────────────────────────────────────────────

  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,

    colorScheme: const ColorScheme.dark(
      // ignore: deprecated_member_use
      background:       Color(0xFF0F1117),
      surface:          Color(0xFF1E2435),
      surfaceContainerHighest: Color(0xFF252D40),
      primary:          Color(0xFF4D8FD6),
      primaryContainer: Color(0xFF2D4A7A),
      onPrimary:        Color(0xFFFFFFFF),
      // ignore: deprecated_member_use
      onBackground:     Color(0xFFE8EAF0),
      onSurface:        Color(0xFFE8EAF0),
      secondary:        Color(0xFF5B9BD5),
      error:            Color(0xFFE05555),
      outline:          Color(0xFF2D3548),
    ),

    scaffoldBackgroundColor: const Color(0xFF0F1117),

    cardTheme: const CardThemeData(
      color: Color(0xFF1E2435),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        side: BorderSide(color: Color(0xFF2D3548), width: 1),
      ),
      margin: EdgeInsets.zero,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF141924),
      foregroundColor: Color(0xFFE8EAF0),
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        color: Color(0xFFE8EAF0),
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF4D8FD6),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.3),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF4D8FD6),
        side: const BorderSide(color: Color(0xFF4D8FD6)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.3),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF4D8FD6),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),

    inputDecorationTheme: const InputDecorationTheme(
      filled: true,
      fillColor: Color(0xFF1A2030),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: Color(0xFF2D3548)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: Color(0xFF2D3548)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: Color(0xFF4D8FD6), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: Color(0xFFE05555)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(8)),
        borderSide: BorderSide(color: Color(0xFFE05555), width: 2),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: TextStyle(color: Color(0xFF9BA3B8), fontSize: 14),
      hintStyle: TextStyle(color: Color(0xFF6B7491), fontSize: 14),
      prefixIconColor: Color(0xFF9BA3B8),
    ),

    dividerTheme: const DividerThemeData(color: Color(0xFF252D40), thickness: 1),

    listTileTheme: const ListTileThemeData(
      tileColor: Color(0xFF1E2435),
      textColor: Color(0xFFE8EAF0),
      iconColor: Color(0xFF9BA3B8),
    ),

    iconTheme: const IconThemeData(color: Color(0xFF9BA3B8), size: 20),

    chipTheme: const ChipThemeData(
      backgroundColor: Color(0xFF252D40),
      labelStyle: TextStyle(color: Color(0xFFE8EAF0)),
      side: BorderSide(color: Color(0xFF2D3548)),
    ),

    dropdownMenuTheme: const DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(Color(0xFF1E2435)),
        surfaceTintColor: WidgetStatePropertyAll(Colors.transparent),
      ),
    ),

    dialogTheme: const DialogThemeData(
      backgroundColor: Color(0xFF1E2435),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        side: BorderSide(color: Color(0xFF2D3548)),
      ),
      titleTextStyle: TextStyle(
        color: Color(0xFFE8EAF0),
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: TextStyle(
        color: Color(0xFF9BA3B8),
        fontSize: 14,
      ),
    ),

    snackBarTheme: const SnackBarThemeData(
      backgroundColor: Color(0xFF252D40),
      contentTextStyle: TextStyle(color: Color(0xFFE8EAF0)),
    ),

    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Color(0xFF4D8FD6),
    ),

    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return const Color(0xFF4D8FD6);
        return const Color(0xFF4A5268);
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return const Color(0xFF2D4A7A);
        return const Color(0xFF252D40);
      }),
    ),

    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return const Color(0xFF4D8FD6);
        return Colors.transparent;
      }),
      side: const BorderSide(color: Color(0xFF4D8FD6), width: 2),
      checkColor: const WidgetStatePropertyAll(Colors.white),
    ),

    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return const Color(0xFF4D8FD6);
        return const Color(0xFF6B7491);
      }),
    ),

    tabBarTheme: const TabBarThemeData(
      labelColor: Color(0xFF4D8FD6),
      unselectedLabelColor: Color(0xFF9BA3B8),
      indicatorColor: Color(0xFF4D8FD6),
      dividerColor: Color(0xFF252D40),
    ),

    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: const Color(0xFF252D40),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFF2D3548)),
      ),
      textStyle: const TextStyle(color: Color(0xFFE8EAF0), fontSize: 12),
    ),

    scrollbarTheme: const ScrollbarThemeData(
      thumbColor: WidgetStatePropertyAll(Color(0xFF2D3548)),
      trackColor: WidgetStatePropertyAll(Color(0xFF1E2435)),
    ),

    textTheme: _textTheme(Brightness.dark),
  );

  // ── Shared text theme ────────────────────────────────────────────────────────

  static TextTheme _textTheme(Brightness brightness) {
    final base  = brightness == Brightness.light ? const Color(0xFF1A1A2E) : const Color(0xFFE8EAF0);
    final muted = brightness == Brightness.light ? const Color(0xFF64748B) : const Color(0xFF9BA3B8);
    return TextTheme(
      displayLarge:  TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: base, letterSpacing: -0.5),
      displayMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: base, letterSpacing: -0.3),
      headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: base),
      headlineMedium:TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: base),
      headlineSmall: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: base),
      titleLarge:    TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: base),
      titleMedium:   TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: base),
      titleSmall:    TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: muted),
      bodyLarge:     TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: base),
      bodyMedium:    TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: base),
      bodySmall:     TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: muted),
      labelLarge:    TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: base, letterSpacing: 0.3),
      labelMedium:   TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: muted, letterSpacing: 0.2),
      labelSmall:    TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: muted, letterSpacing: 0.3),
    );
  }
}
