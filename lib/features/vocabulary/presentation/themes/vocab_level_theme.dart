import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';

@immutable
class VocabLevelTheme {
  /// Brand / accent colour for headings, borders, and interactive elements.
  final Color primaryColor;

  /// Ordered gradient stops used by the mesh background and solid fills.
  /// Index 0 is the dominant top-left colour; index 1 is the scaffold fill.
  final List<Color> backgroundColors;

  /// The underlying core theme result.
  final ThemeResult source;

  const VocabLevelTheme({
    required this.primaryColor,
    required this.backgroundColors,
    required this.source,
  });

  factory VocabLevelTheme.from(ThemeResult rawTheme) {
    return VocabLevelTheme(
      primaryColor: rawTheme.primaryColor,
      backgroundColors: rawTheme.backgroundColors,
      source: rawTheme,
    );
  }
}
