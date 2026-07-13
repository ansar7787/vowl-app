import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The central production-grade theme declaration for Vowl, coordinating
/// light, dark, and midnight configurations with seamless system-level overlays.
class AppTheme {
  AppTheme._(); // Non-instantiable.

  // ---------------------------------------------------------------------------
  // Palette — Primary
  // ---------------------------------------------------------------------------

  /// Primary brand colour: Indigo (Trust + Focus).
  static const Color primaryIndigo = Color(
    0xFF6366F1,
  ); // Deepened to Indigo 700 for LCD consistency

  /// Secondary brand colour: Emerald (Success + Progress).
  static const Color secondaryEmerald = Color(
    0xFF059669,
  ); // Deepened to Emerald 600

  /// Accent colour: Amber (Rewards + Stars).
  static const Color accentAmber = Color(0xFFD97706); // Deepened to Amber 600

  // ---------------------------------------------------------------------------
  // Palette — Surface tints
  // ---------------------------------------------------------------------------

  /// Light-surface indigo tint (Indigo 50).
  static const Color primaryIndigoTintLight = Color(0xFFEEF2FF);

  /// Dark-surface indigo tint (Indigo 950).
  static const Color primaryIndigoTintDark = Color(0xFF1E1B4B);

  // FIX (MEDIUM-1): Extracted repeated `Color(0xFF8B5CF6)` into a named
  // constant. Previously appeared in both darkTheme and midnightTheme without
  // a name, risking silent drift if one was changed and the other was not.
  /// Lighter indigo for dark-surface primary text/icons (Indigo 400).
  static const Color primaryIndigoDark = Color(0xFF8B5CF6);

  // FIX (MEDIUM-1): Extracted repeated `Color(0xFF0B0F19)` into a named
  // constant used for the midnight mode card/surface colour.
  /// Near-black card base for midnight mode — high contrast surface.
  static const Color midnightCardBase = Color(0xFF0B0F19);

  // ---------------------------------------------------------------------------
  // Palette — Light mode surfaces
  // ---------------------------------------------------------------------------

  /// Light scaffold background (Slate 50).
  static const Color scaffoldLight = Color(0xFFF8FAFC);

  /// Light card surface (pure white).
  static const Color cardLight = Color(0xFFFFFFFF);

  /// Light border colour (Slate 200).
  static const Color borderLight = Color(0xFFE2E8F0);

  // ---------------------------------------------------------------------------
  // Palette — Dark mode surfaces
  // ---------------------------------------------------------------------------

  /// Dark scaffold background (Slate 900).
  static const Color scaffoldDark = Color(0xFF0F172A);

  /// Dark card surface (Slate 800).
  static const Color cardDark = Color(0xFF1E293B);

  /// Dark border colour (Slate 700).
  static const Color borderDark = Color(0xFF334155);

  // ---------------------------------------------------------------------------
  // Light Theme
  // ---------------------------------------------------------------------------

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Outfit',
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
    textTheme: const TextTheme().apply(
      fontFamily: 'Outfit',
      bodyColor: Color(0xFF0F172A), // Slate 900
      displayColor: primaryIndigo,
    ),
    appBarTheme: const AppBarTheme(
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      backgroundColor: primaryIndigo,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Outfit',
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
        textStyle: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
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

  // ---------------------------------------------------------------------------
  // Dark Theme
  // ---------------------------------------------------------------------------

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Outfit',
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryIndigo,
      brightness: Brightness.dark,
      // FIX (MEDIUM-1): Now references the named constant instead of a
      // magic Color literal.
      primary: primaryIndigoDark,
      secondary: secondaryEmerald,
      tertiary: accentAmber,
      surface: cardDark,
      primaryContainer: primaryIndigoTintDark,
    ),
    scaffoldBackgroundColor: scaffoldDark,
    canvasColor: scaffoldDark,
    cardColor: cardDark,
    dividerColor: borderDark,
    textTheme: const TextTheme().apply(
      fontFamily: 'Outfit',
      bodyColor: Color(0xFFF8FAFC), // Slate 50
      displayColor: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Outfit',
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
        textStyle: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
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
        // FIX (MEDIUM-1): Named constant instead of repeated magic value.
        borderSide: const BorderSide(color: primaryIndigoDark, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    ),
  );

  // ---------------------------------------------------------------------------
  // Midnight Theme
  // ---------------------------------------------------------------------------

  static final ThemeData midnightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Outfit',
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryIndigo,
      brightness: Brightness.dark,
      // FIX (MEDIUM-1): Named constants for both repeated values.
      primary: primaryIndigoDark,
      secondary: secondaryEmerald,
      tertiary: accentAmber,
      surface: midnightCardBase,
      primaryContainer: primaryIndigoTintDark,
    ),
    scaffoldBackgroundColor: Colors.black,
    canvasColor: Colors.black,
    // FIX (MEDIUM-1): Named constant instead of magic Color literal.
    cardColor: midnightCardBase,
    // Note: Using cardDark (Slate 800) for dividers; it provides enough
    // contrast against the pure-black scaffold without a third colour value.
    dividerColor: cardDark,
    textTheme: const TextTheme().apply(
      fontFamily: 'Outfit',
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        fontFamily: 'Outfit',
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
        textStyle: const TextStyle(
          fontFamily: 'Outfit',
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: midnightCardBase.withValues(alpha: 0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: cardDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: cardDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        // FIX (MEDIUM-1): Named constant.
        borderSide: const BorderSide(color: primaryIndigoDark, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    ),
  );
}
