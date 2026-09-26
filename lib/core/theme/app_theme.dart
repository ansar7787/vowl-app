import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';

/// The central production-grade theme declaration for Vowl, coordinating
/// light, dark, and midnight configurations with seamless system-level overlays.
class AppTheme {
  AppTheme._(); // Non-instantiable.

  // ---------------------------------------------------------------------------
  // Palette — Primary (delegating to AppColors for single-source-of-truth)
  // ---------------------------------------------------------------------------

  /// Primary brand colour: Indigo (Trust + Focus).
  static const Color primaryIndigo = AppColors.indigo500;

  /// Secondary brand colour: Emerald (Success + Progress).
  static const Color secondaryEmerald = AppColors.emerald600;

  /// Accent colour: Amber (Rewards + Stars).
  static const Color accentAmber = AppColors.amber600;

  // ---------------------------------------------------------------------------
  // Palette — Surface tints (delegating to AppColors)
  // ---------------------------------------------------------------------------

  /// Light-surface indigo tint (Indigo 50).
  static const Color primaryIndigoTintLight = AppColors.indigo50;

  /// Dark-surface indigo tint (Indigo 950).
  static const Color primaryIndigoTintDark = AppColors.indigo950;

  /// Lighter indigo for dark-surface primary text/icons (Violet 500).
  static const Color primaryIndigoDark = AppColors.violet500;

  /// Near-black card base for midnight mode — high contrast surface.
  static const Color midnightCardBase = AppColors.midnightSurface;

  // ---------------------------------------------------------------------------
  // Palette — Light mode surfaces (delegating to AppColors)
  // ---------------------------------------------------------------------------

  /// Light scaffold background (Slate 50).
  static const Color scaffoldLight = AppColors.slate50;

  /// Light card surface (pure white).
  static const Color cardLight = AppColors.white;

  /// Light border colour (Slate 200).
  static const Color borderLight = AppColors.slate200;

  // ---------------------------------------------------------------------------
  // Palette — Dark mode surfaces (delegating to AppColors)
  // ---------------------------------------------------------------------------

  /// Dark scaffold background (Slate 900).
  static const Color scaffoldDark = AppColors.slate900;

  /// Dark card surface (Slate 800).
  static const Color cardDark = AppColors.slate800;

  /// Dark border colour (Slate 700).
  static const Color borderDark = AppColors.slate700;

  // ---------------------------------------------------------------------------
  // Light Theme
  // ---------------------------------------------------------------------------

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Outfit',
    extensions: const <ThemeExtension>[AppColorTokens.light],
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
      bodyColor: AppColors.slate900,
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
    extensions: const <ThemeExtension>[AppColorTokens.dark],
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryIndigo,
      brightness: Brightness.dark,
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
      bodyColor: AppColors.slate50,
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
    extensions: const <ThemeExtension>[AppColorTokens.midnight],
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryIndigo,
      brightness: Brightness.dark,
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
