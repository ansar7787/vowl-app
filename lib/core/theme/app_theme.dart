import 'package:vowl/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vowl/core/theme/app_color_tokens.dart';
import 'package:vowl/core/theme/app_dimensions.dart';

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

  /// Lighter indigo for dark-surface primary text/icons (Indigo 400).
  static const Color primaryIndigoDark = AppColors.indigo400;

  /// Near-black card base for midnight mode — high contrast surface.
  static const Color midnightCardBase = AppColors.midnightSurface;

  // ---------------------------------------------------------------------------
  // Palette — Light mode surfaces (delegating to AppColors)
  // ---------------------------------------------------------------------------

  /// Light scaffold background (Option 2: Pure White canvas).
  static const Color scaffoldLight = AppColors.white;

  /// Light card surface (pure white).
  static const Color cardLight = AppColors.white;

  /// Light border colour (Option 2: Slate 200 — crisp hairline boundary for white-on-white).
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

  /// Primary font family used across the application.
  static const String primaryFont = 'Outfit';

  /// Standard font fallbacks for emoji and cross-platform symbol rendering.
  static const List<String> emojiFontFallbacks = [
    'Noto Color Emoji',
    'Apple Color Emoji',
    'Segoe UI Emoji',
  ];

  // ---------------------------------------------------------------------------
  // Light Theme
  // ---------------------------------------------------------------------------

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: primaryFont,
    fontFamilyFallback: emojiFontFallbacks,
    extensions: const <ThemeExtension>[AppColorTokens.light],
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryIndigo,
      primary: primaryIndigo,
      secondary: secondaryEmerald,
      tertiary: accentAmber,
      surface: cardLight,
      surfaceTint: Colors.transparent,
      primaryContainer: primaryIndigoTintLight,
    ),
    scaffoldBackgroundColor: scaffoldLight,
    canvasColor: scaffoldLight,
    cardColor: cardLight,
    dividerColor: borderLight,
    textTheme: const TextTheme().apply(
      fontFamily: primaryFont,
      fontFamilyFallback: emojiFontFallbacks,
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
      surfaceTintColor: Colors.transparent,
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
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
    dialogTheme: const DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    cardTheme: CardThemeData(
      color: cardLight,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: borderLight),
      ),
    ),
    popupMenuTheme: const PopupMenuThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 3,
    ),
  );

  // ---------------------------------------------------------------------------
  // Dark Theme
  // ---------------------------------------------------------------------------

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: primaryFont,
    fontFamilyFallback: emojiFontFallbacks,
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
      surfaceTintColor: Colors.transparent,
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
      fillColor: cardDark,
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
    dialogTheme: const DialogThemeData(
      backgroundColor: cardDark,
      surfaceTintColor: Colors.transparent,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: scaffoldDark,
      surfaceTintColor: Colors.transparent,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    cardTheme: CardThemeData(
      color: cardDark,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: borderDark),
      ),
    ),
    popupMenuTheme: const PopupMenuThemeData(
      color: cardDark,
      surfaceTintColor: Colors.transparent,
      elevation: 3,
    ),
  );

  // ---------------------------------------------------------------------------
  // Midnight Theme
  // ---------------------------------------------------------------------------

  static final ThemeData midnightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: primaryFont,
    fontFamilyFallback: emojiFontFallbacks,
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
      surfaceTintColor: Colors.transparent,
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
      fillColor: midnightCardBase,
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
    dialogTheme: const DialogThemeData(
      backgroundColor: midnightCardBase,
      surfaceTintColor: Colors.transparent,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: midnightCardBase,
      surfaceTintColor: Colors.transparent,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    cardTheme: CardThemeData(
      color: midnightCardBase,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: cardDark),
      ),
    ),
    popupMenuTheme: const PopupMenuThemeData(
      color: midnightCardBase,
      surfaceTintColor: Colors.transparent,
      elevation: 3,
    ),
  );

  /// Returns whether the active theme in [context] is Midnight (AMOLED) mode.
  static bool isMidnight(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark &&
      Theme.of(context).scaffoldBackgroundColor == Colors.black;
}

/// Convenient, production-grade BuildContext extensions for theme detection
/// and token consumption across all widgets.
extension AppThemeContextExtension on BuildContext {
  /// Whether the active theme is dark (either explicitly dark or midnight).
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// Whether the active theme is the pure AMOLED Midnight mode.
  ///
  /// Detected synchronously and fast via scaffoldBackgroundColor == Colors.black,
  /// avoiding any expensive subscriptions or context dependencies.
  bool get isMidnight =>
      isDark && Theme.of(this).scaffoldBackgroundColor == Colors.black;

  /// The active [AppColorTokens] matching the current theme state.
  ///
  /// Guarantees a non-null return value with safe fallbacks.
  AppColorTokens get tokens =>
      Theme.of(this).extension<AppColorTokens>() ??
      (isMidnight
          ? AppColorTokens.midnight
          : (isDark ? AppColorTokens.dark : AppColorTokens.light));
}
