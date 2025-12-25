/* import 'package:flutter/material.dart';

class AppThemes {
  // --------------------------------------------------
  // LIGHT THEME
  // --------------------------------------------------
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF6C7A4C),
      secondary: Color(0xFFC56A45),
      surfaceContainer: Color(0xFFF5EDE3),
      surface: Color(0xFFE8E2D2),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
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
      surfaceContainer: Color(0xFF121212),
      surface: Color(0xFF1E1E1E),
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: Colors.white70,
    ),

    scaffoldBackgroundColor: const Color(0xFF121212),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: Color(0xFF9DB28B),
      elevation: 1,
    ),

    iconTheme: const IconThemeData(color: Color.fromARGB(255, 178, 139, 139)),

    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Colors.white70),
      bodySmall: TextStyle(color: Colors.white60),
      titleMedium: TextStyle(color: Colors.white),
    ),
  );
}
 */

//// -- Claude style...

import 'package:flutter/material.dart';

class AppThemes {
  // --------------------------------------------------
  // LIGHT THEME — CLAUDE STYLE
  // --------------------------------------------------
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,

    colorScheme: const ColorScheme.light(
      primary: Color(0xFFC15F3C), // Claude Orange
      secondary: Color(0xFFDA7756), // Terra cotta accent

      surface: Color(0xFFE9E7E1), // Card / container surface
      surfaceContainer: Color(0xFFF4F3EE), // Pampas background

      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFF3D3929),
    ),

    scaffoldBackgroundColor: const Color(0xFFF4F3EE),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF4F3EE),
      foregroundColor: Color(0xFF3D3929),
      elevation: 0.5,
      centerTitle: false,
    ),

    iconTheme: const IconThemeData(color: Color(0xFF3D3929)),

    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Color(0xFF3D3929), height: 1.4),
      bodySmall: TextStyle(color: Color(0xFF6E6A5E)),
      titleMedium: TextStyle(
        color: Color(0xFF3D3929),
        fontWeight: FontWeight.w600,
      ),
    ),

    dividerColor: const Color(0xFFDEDACE),
  );

  // --------------------------------------------------
  // DARK THEME — CLAUDE STYLE
  // --------------------------------------------------
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,

    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFDA7756), // Softer Claude orange
      secondary: Color(0xFFC15F3C),

      surface: Color(0xFF1C1A17),
      surfaceContainer: Color(0xFF12110F),

      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: Color(0xFFECE9E2),
    ),

    scaffoldBackgroundColor: const Color(0xFF12110F),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1C1A17),
      foregroundColor: Color(0xFFECE9E2),
      elevation: 0.5,
    ),

    iconTheme: const IconThemeData(color: Color(0xFFDA7756)),

    textTheme: const TextTheme(
      bodyMedium: TextStyle(color: Color(0xFFECE9E2), height: 1.4),
      bodySmall: TextStyle(color: Color(0xFFCFCAC0)),
      titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
    ),

    dividerColor: const Color(0xFF2A2723),
  );
}
