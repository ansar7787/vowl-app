import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Education Quiz Master Palette (Option B - The Winner)
  // 1. Primary: Indigo (Trust + Focus)
  // 2. Secondary: Emerald (Success + Progress)
  // 3. Accent: Amber (Rewards + Stars)
  
  static const primaryIndigo = Color(0xFF4F46E5);
  static const secondaryEmerald = Color(0xFF10B981);
  static const accentAmber = Color(0xFFF59E0B);
  
  // Premium Soft Tints (For backgrounds, selections, and highlights without eye strain)
  static const primaryIndigoTintLight = Color(0xFFEEF2FF); // Indigo 50
  static const primaryIndigoTintDark = Color(0xFF1E1B4B);  // Indigo 950
  
  static const scaffoldLight = Color(0xFFF8FAFC); // Slate 50
  static const cardLight = Color(0xFFFFFFFF);
  static const borderLight = Color(0xFFE2E8F0);   // Slate 200
  
  static const scaffoldDark = Color(0xFF0F172A);  // Slate 900
  static const cardDark = Color(0xFF1E293B);      // Slate 800 (Elevated card depth!)
  static const borderDark = Color(0xFF334155);    // Slate 700
  
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryIndigo,
      primary: primaryIndigo,
      secondary: secondaryEmerald,
      tertiary: accentAmber,
      surface: cardLight,
      primaryContainer: primaryIndigoTintLight,
    ),
    scaffoldBackgroundColor: scaffoldLight,
    canvasColor: scaffoldLight,
    cardColor: cardLight,
    dividerColor: borderLight,
    textTheme: GoogleFonts.outfitTextTheme().apply(
      bodyColor: const Color(0xFF0F172A), // Slate 900 for ultra-premium readability
      displayColor: primaryIndigo,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: primaryIndigo,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.outfit(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryIndigo,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        textStyle: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryIndigo, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    ),
  );
 
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryIndigo,
      brightness: Brightness.dark,
      primary: const Color(0xFF818CF8), // Lighter indigo for dark mode
      secondary: secondaryEmerald,
      tertiary: accentAmber,
      surface: cardDark,
      primaryContainer: primaryIndigoTintDark,
    ),
    scaffoldBackgroundColor: scaffoldDark,
    canvasColor: scaffoldDark,
    cardColor: cardDark,
    dividerColor: borderDark,
    textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: const Color(0xFFF8FAFC), // Slate 50
      displayColor: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.outfit(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryIndigo,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        textStyle: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardDark.withValues(alpha: 0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: borderDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: borderDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF818CF8), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    ),
  );

  static final ThemeData midnightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryIndigo,
      brightness: Brightness.dark,
      primary: const Color(0xFF818CF8),
      secondary: secondaryEmerald,
      tertiary: accentAmber,
      surface: const Color(0xFF0B0F19), // Elevated high-contrast card depth!
      primaryContainer: primaryIndigoTintDark,
    ),
    scaffoldBackgroundColor: Colors.black,
    canvasColor: Colors.black,
    cardColor: const Color(0xFF0B0F19),
    dividerColor: const Color(0xFF1E293B),
    textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.outfit(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryIndigo,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        textStyle: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF0B0F19).withValues(alpha: 0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF1E293B)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF1E293B)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF818CF8), width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    ),
  );
}
