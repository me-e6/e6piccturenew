import 'package:flutter/material.dart';

class AppThemes {
  // --------------------------------------------------
  // LIGHT THEME
  // --------------------------------------------------
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF6C7A4C),
      secondary: Color(0xFFC56A45),
      background: Color(0xFFF5EDE3),
      surface: Color(0xFFE8E2D2),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onBackground: Colors.black87,
      onSurface: Colors.black87,
    ),

    scaffoldBackgroundColor: const Color(0xFFF5EDE3),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF5EDE3),
      foregroundColor: Color(0xFF6C7A4C),
      elevation: 1,
    ),

    iconTheme: const IconThemeData(color: Color(0xFF6C7A4C)),

    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.black87),
      bodySmall: TextStyle(color: Colors.black54),
      titleMedium: TextStyle(color: Colors.black87),
    ),
  );

  // --------------------------------------------------
  // DARK THEME
  // --------------------------------------------------
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF9DB28B),
      secondary: Color(0xFFD89A6A),
      background: Color(0xFF121212),
      surface: Color(0xFF1E1E1E),
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onBackground: Colors.white70,
      onSurface: Colors.white70,
    ),

    scaffoldBackgroundColor: const Color(0xFF121212),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Color(0xFF9DB28B),
      elevation: 1,
    ),

    iconTheme: const IconThemeData(color: Color(0xFF9DB28B)),

    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.white70),
      bodySmall: TextStyle(color: Colors.white60),
      titleMedium: TextStyle(color: Colors.white),
    ),
  );
}
