import 'package:flutter/material.dart';

class SolarizedTheme {
  // 1. Define the raw Solarized palette as private constants
  static const _base03 = Color(0xFF002B36);
  static const _base02 = Color(0xFF073642);
  static const _base01 = Color(0xFF586E75);
  static const _base00 = Color(0xFF657B83);
  static const _base0 = Color(0xFF839496);
  static const _base1 = Color(0xFF93A1A1);
  static const _base2 = Color(0xFFEEE8D5);
  static const _base3 = Color(0xFFFDF6E3);

  static const _yellow = Color(0xFFB58900);
  static const _orange = Color(0xFFCB4B16);
  static const _red = Color(0xFFDC322F);
  static const _magenta = Color(0xFFD33682);
  static const _violet = Color(0xFF6C71C4);
  static const _blue = Color(0xFF268BD2);
  static const _cyan = Color(0xFF2AA198);
  static const _green = Color(0xFF859900);

  // 2. Create the Light Theme (Your current focus)
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        surface: _base3, // Main Background
        onSurface: _base00, // Body Text
        primary: _blue, // Action Buttons (Spotify)
        onPrimary: Colors.white,
        secondary: _cyan, // Accents
        onSecondary: Colors.white,
        surfaceContainer: _base2, // Cards/Secondary backgrounds
        outline: _base1, // Dividers/Borders
        error: _red,
        tertiary: _magenta,
      ),
      // Set global text styles to use Solarized text colors
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: _base00),
        bodyMedium: TextStyle(color: _base00),
        labelSmall: TextStyle(color: _base1), // For your footer!
      ),
    );
  }

  // 3. Create the Dark Theme (For the "Vibe" switch later)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        surface: _base03,
        onSurface: _base0,
        primary: _blue,
        secondary: _cyan,
        surfaceContainer: _base02,
        outline: _base01,
        error: _red,
        tertiary: _violet,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: _base0),
        bodyMedium: TextStyle(color: _base0),
        labelSmall: TextStyle(color: _base01),
      ),
    );
  }

  // Inside SolarizedTheme class
  static Color get successColor => _green;
  static Color get warningColor => _yellow;
}
