import 'package:flutter/material.dart';

class AppThemes {
  // --------------------------------------------------
  // LIGHT THEME
  // --------------------------------------------------
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF5EDE3),
    primaryColor: const Color(0xFF6C7A4C),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF5EDE3),
      elevation: 6,
      iconTheme: IconThemeData(color: Color(0xFF6C7A4C)),
      titleTextStyle: TextStyle(
        color: Color(0xFF6C7A4C),
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),

    colorScheme: const ColorScheme.light(
      primary: Color(0xFF6C7A4C),
      secondary: Color(0xFFC56A45),
      surface: Color(0xFFE8E2D2),
    ),

    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.black87),
      bodySmall: TextStyle(color: Colors.black54),
    ),
  );

  // --------------------------------------------------
  // DARK THEME
  // --------------------------------------------------
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF121212),
    primaryColor: const Color(0xFF9DB28B),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      elevation: 6,
      iconTheme: IconThemeData(color: Color(0xFF9DB28B)),
      titleTextStyle: TextStyle(
        color: Color(0xFF9DB28B),
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),

    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF9DB28B),
      secondary: Color(0xFFD89A6A),
      surface: Color(0xFF2A2A2A),
    ),

    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.white70),
      bodySmall: TextStyle(color: Colors.white60),
    ),
  );
}
