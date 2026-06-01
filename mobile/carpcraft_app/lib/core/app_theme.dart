import 'package:flutter/material.dart';

ThemeData buildCarpCraftTheme() {
  const seed = Color(0xFF176B5B);
  const amber = Color(0xFFC58B2B);
  const ink = Color(0xFF17211F);

  final scheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.light,
  ).copyWith(
    primary: seed,
    secondary: amber,
    surface: const Color(0xFFF7F8F4),
    onSurface: ink,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFFF1F4EE),
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      backgroundColor: Color(0xFFF1F4EE),
      foregroundColor: ink,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFDDE5DD)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        minimumSize: const Size(48, 48),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        minimumSize: const Size(48, 48),
      ),
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0),
      titleLarge: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0),
      titleMedium: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0),
      bodyMedium: TextStyle(height: 1.35, letterSpacing: 0),
    ),
  );
}
