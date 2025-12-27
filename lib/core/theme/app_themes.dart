import 'package:flutter/material.dart';

/// ============================================================================
/// APP THEMES - PICCTURE
/// ============================================================================
/// Earthy color palette with Material 3 theming
/// Colors:
/// - Surface: #F6F4EF (warm beige)
/// - Primary: #8B7355 (earthy brown)
/// - Background: #FFFDF9 (off-white)
/// ============================================================================
class AppThemes {
  AppThemes._();

  // ═══════════════════════════════════════════════════════════════════════════
  // COLORS
  // ═══════════════════════════════════════════════════════════════════════════
  
  // Light theme colors
  static const Color _lightSurface = Color(0xFFF6F4EF);
  static const Color _lightBackground = Color(0xFFFFFDF9);
  static const Color _lightPrimary = Color(0xFF8B7355);
  static const Color _lightOnPrimary = Colors.white;
  static const Color _lightSecondary = Color(0xFFA89880);
  static const Color _lightOnSurface = Color(0xFF1C1B1F);
  static const Color _lightOnSurfaceVariant = Color(0xFF6B6B6B);

  // Dark theme colors
  static const Color _darkSurface = Color(0xFF1C1B1F);
  static const Color _darkBackground = Color(0xFF121212);
  static const Color _darkPrimary = Color(0xFFD4C4B0);
  static const Color _darkOnPrimary = Color(0xFF3D3227);
  static const Color _darkSecondary = Color(0xFFCBC0B5);
  static const Color _darkOnSurface = Color(0xFFE6E1E5);
  static const Color _darkOnSurfaceVariant = Color(0xFFCAC4D0);

  // ═══════════════════════════════════════════════════════════════════════════
  // LIGHT THEME
  // ═══════════════════════════════════════════════════════════════════════════
  static final ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      surface: _lightSurface,
      primary: _lightPrimary,
      onPrimary: _lightOnPrimary,
      secondary: _lightSecondary,
      onSecondary: Colors.white,
      onSurface: _lightOnSurface,
      onSurfaceVariant: _lightOnSurfaceVariant,
      surfaceContainerHighest: Color(0xFFEBE9E4),
      outline: Color(0xFFCCC8C3),
      outlineVariant: Color(0xFFE0DDD8),
      error: Color(0xFFBA1A1A),
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: _lightBackground,
    
    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: _lightBackground,
      foregroundColor: _lightOnSurface,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: _lightOnSurface,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),

    // Bottom Navigation
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: _lightBackground,
      selectedItemColor: _lightPrimary,
      unselectedItemColor: _lightOnSurfaceVariant,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),

    // Cards
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE0DDD8), width: 0.5),
      ),
    ),

    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _lightPrimary,
        foregroundColor: _lightOnPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _lightPrimary,
        side: const BorderSide(color: _lightPrimary),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _lightPrimary,
      ),
    ),

    // Input
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF0EDE8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _lightPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFBA1A1A)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),

    // Divider
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE0DDD8),
      thickness: 0.5,
    ),

    // Chips
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFF0EDE8),
      selectedColor: _lightPrimary.withValues(alpha: 0.2),
      labelStyle: const TextStyle(fontSize: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),

    // Dialog
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),

    // Bottom Sheet
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),

    // Snackbar
    snackBarTheme: SnackBarThemeData(
      backgroundColor: _lightOnSurface,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      behavior: SnackBarBehavior.floating,
    ),

    // FloatingActionButton
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _lightPrimary,
      foregroundColor: _lightOnPrimary,
      elevation: 2,
    ),

    // TabBar
    tabBarTheme: const TabBarThemeData(
      labelColor: _lightPrimary,
      unselectedLabelColor: _lightOnSurfaceVariant,
      indicatorColor: _lightPrimary,
    ),

    // Switch
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return _lightPrimary;
        return Colors.grey;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _lightPrimary.withValues(alpha: 0.5);
        }
        return Colors.grey.withValues(alpha: 0.3);
      }),
    ),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // DARK THEME
  // ═══════════════════════════════════════════════════════════════════════════
  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      surface: _darkSurface,
      primary: _darkPrimary,
      onPrimary: _darkOnPrimary,
      secondary: _darkSecondary,
      onSecondary: Colors.black,
      onSurface: _darkOnSurface,
      onSurfaceVariant: _darkOnSurfaceVariant,
      surfaceContainerHighest: Color(0xFF2B2930),
      outline: Color(0xFF49454F),
      outlineVariant: Color(0xFF3D3A43),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
    ),
    scaffoldBackgroundColor: _darkBackground,
    
    // AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: _darkBackground,
      foregroundColor: _darkOnSurface,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: _darkOnSurface,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),

    // Bottom Navigation
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: _darkBackground,
      selectedItemColor: _darkPrimary,
      unselectedItemColor: _darkOnSurfaceVariant,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),

    // Cards
    cardTheme: CardThemeData(
      color: _darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF3D3A43), width: 0.5),
      ),
    ),

    // Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _darkPrimary,
        foregroundColor: _darkOnPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _darkPrimary,
        side: const BorderSide(color: _darkPrimary),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    ),

    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _darkPrimary,
      ),
    ),

    // Input
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2B2930),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _darkPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFFB4AB)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),

    // Divider
    dividerTheme: const DividerThemeData(
      color: Color(0xFF3D3A43),
      thickness: 0.5,
    ),

    // Chips
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF2B2930),
      selectedColor: _darkPrimary.withValues(alpha: 0.3),
      labelStyle: const TextStyle(fontSize: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),

    // Dialog
    dialogTheme: DialogThemeData(
      backgroundColor: _darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    ),

    // Bottom Sheet
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: _darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),

    // Snackbar
    snackBarTheme: SnackBarThemeData(
      backgroundColor: _darkOnSurface,
      contentTextStyle: const TextStyle(color: Colors.black),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      behavior: SnackBarBehavior.floating,
    ),

    // FloatingActionButton
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: _darkPrimary,
      foregroundColor: _darkOnPrimary,
      elevation: 2,
    ),

    // TabBar
    tabBarTheme: const TabBarThemeData(
      labelColor: _darkPrimary,
      unselectedLabelColor: _darkOnSurfaceVariant,
      indicatorColor: _darkPrimary,
    ),

    // Switch
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return _darkPrimary;
        return Colors.grey;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _darkPrimary.withValues(alpha: 0.5);
        }
        return Colors.grey.withValues(alpha: 0.3);
      }),
    ),
  );
}
