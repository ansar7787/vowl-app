import 'package:flutter/material.dart';

/// Semantic color palette for the 4-way Word Formation morph system.
///
/// Binds consistent, pedagogically distinct sensory colors to each
/// grammatical transformation:
/// - North: Noun (Sky Blue)
/// - East: Adjective (Emerald Green)
/// - South: Adverb (Amber / Golden Orange)
/// - West: Opposite / Negative Polarity (Purple / Violet)
abstract class WordFormationColors {
  /// North: Noun (Sky Blue)
  static const Color northNoun = Color(0xFF0284C7);

  /// East: Adjective (Emerald Green)
  static const Color eastAdjective = Color(0xFF059669);

  /// South: Adverb (Amber / Golden Orange)
  static const Color southAdverb = Color(0xFFD97706);

  /// West: Opposite / Negative Polarity (Purple / Violet)
  static const Color westOpposite = Color(0xFF9333EA);

  /// Resolves the semantic color for a given compass direction.
  static Color forDirection(String? direction) {
    switch (direction?.toLowerCase().trim()) {
      case 'north':
        return northNoun;
      case 'east':
        return eastAdjective;
      case 'south':
        return southAdverb;
      case 'west':
        return westOpposite;
      default:
        return northNoun;
    }
  }

  /// Resolves the semantic color for a grammatical role.
  static Color forRole(String? role) {
    final r = role?.toLowerCase().trim() ?? '';
    if (r.contains('noun')) return northNoun;
    if (r.contains('adj')) return eastAdjective;
    if (r.contains('adv')) return southAdverb;
    if (r.contains('opp')) return westOpposite;
    return northNoun;
  }
}
