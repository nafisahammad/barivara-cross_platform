import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light({VisualDensity? visualDensity}) {
    const seed = Color(0xFF0A3DFF);
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: seed),
      useMaterial3: true,
      visualDensity: visualDensity ?? VisualDensity.standard,
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontWeight: FontWeight.w900),
        headlineSmall: TextStyle(fontWeight: FontWeight.w900),
        titleLarge: TextStyle(fontWeight: FontWeight.w800),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
        filled: true,
        fillColor: const Color(0xFFF6F6F6),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        height: 72,
        labelTextStyle: WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }

  static ThemeData dark({VisualDensity? visualDensity}) {
    const seed = Color(0xFF0A3DFF);
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      brightness: Brightness.dark,
      visualDensity: visualDensity ?? VisualDensity.standard,
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontWeight: FontWeight.w900),
        headlineSmall: TextStyle(fontWeight: FontWeight.w900),
        titleLarge: TextStyle(fontWeight: FontWeight.w800),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
        filled: true,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        height: 72,
        labelTextStyle: WidgetStatePropertyAll(TextStyle(fontWeight: FontWeight.w700)),
      ),
    );
  }
}
