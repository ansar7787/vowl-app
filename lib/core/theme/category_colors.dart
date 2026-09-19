import 'package:flutter/material.dart';

/// Production category color token system for Vowl.
///
/// Audited 2026-09 for LCD robustness, color-blindness safety, AA contrast
/// compliance, and inter-category distinction.
///
/// Each category provides:
/// - [base]: Primary brand color (icons, badges, progress fills, accents).
/// - [light]: Soft tint for light-mode card/container backgrounds.
/// - [dark]: Darker variant for text-on-light surfaces or dark-mode emphasis.
/// - [onBase]: Text/icon color to use **on top** of [base] (white or dark).
///
/// Usage:
/// ```dart
/// final color = CategoryColors.forCategory('speaking');
/// final tint  = CategoryColors.lightTint('speaking');
/// ```
class CategoryColors {
  CategoryColors._(); // Non-instantiable.

  // ─── Speaking ─────────────────────────────────────────────────────
  /// Burnt orange — vocal energy, warmth, expression.
  static const Color speaking = Color(0xFFD84315);
  static const Color speakingLight = Color(0xFFFBE9E7);
  static const Color speakingDark = Color(0xFFBF360C);
  static const Color onSpeaking = Color(0xFFFFFFFF);

  // ─── Listening ────────────────────────────────────────────────────
  /// Deep rose — emotional receptivity, immersion, deep attention.
  static const Color listening = Color(0xFFAD1457);
  static const Color listeningLight = Color(0xFFFCE4EC);
  static const Color listeningDark = Color(0xFF880E4F);
  static const Color onListening = Color(0xFFFFFFFF);

  // ─── Reading ──────────────────────────────────────────────────────
  /// Forest green — growth, comprehension, steady progress.
  static const Color reading = Color(0xFF2E7D32);
  static const Color readingLight = Color(0xFFE8F5E9);
  static const Color readingDark = Color(0xFF1B5E20);
  static const Color onReading = Color(0xFFFFFFFF);

  // ─── Writing ──────────────────────────────────────────────────────
  /// Deep violet — creativity, expression, literary imagination.
  static const Color writing = Color(0xFF5E35B1);
  static const Color writingLight = Color(0xFFEDE7F6);
  static const Color writingDark = Color(0xFF4527A0);
  static const Color onWriting = Color(0xFFFFFFFF);

  // ─── Grammar ──────────────────────────────────────────────────────
  /// True blue — structure, rules, precision, clarity.
  static const Color grammar = Color(0xFF1565C0);
  static const Color grammarLight = Color(0xFFE3F2FD);
  static const Color grammarDark = Color(0xFF0D47A1);
  static const Color onGrammar = Color(0xFFFFFFFF);

  // ─── Vocabulary ───────────────────────────────────────────────────
  /// Deep purple — wisdom, discovery, intellectual depth.
  static const Color vocabulary = Color(0xFF6A1B9A);
  static const Color vocabularyLight = Color(0xFFF3E5F5);
  static const Color vocabularyDark = Color(0xFF4A148C);
  static const Color onVocabulary = Color(0xFFFFFFFF);

  // ─── Accent ───────────────────────────────────────────────────────
  /// Cyan-teal — sound clarity, precision, audio focus.
  static const Color accent = Color(0xFF00838F);
  static const Color accentLight = Color(0xFFE0F7FA);
  static const Color accentDark = Color(0xFF006064);
  static const Color onAccent = Color(0xFFFFFFFF);

  // ─── Roleplay ─────────────────────────────────────────────────────
  /// Theatre red — drama, performance, social scenarios.
  static const Color roleplay = Color(0xFFB71C1C);
  static const Color roleplayLight = Color(0xFFFFEBEE);
  static const Color roleplayDark = Color(0xFF8B0000);
  static const Color onRoleplay = Color(0xFFFFFFFF);

  // ─── Elite Mastery ────────────────────────────────────────────────
  /// Deep amber-gold — prestige, achievement, ultimate mastery.
  /// NOTE: Use [onEliteMastery] (dark brown) for text on gold backgrounds.
  /// Use [eliteMasteryDark] when white text on a gold surface is needed.
  static const Color eliteMastery = Color(0xFFF57F17);
  static const Color eliteMasteryLight = Color(0xFFFFF8E1);
  static const Color eliteMasteryDark = Color(0xFF9B7A1C);
  static const Color onEliteMastery = Color(0xFF3E2723); // Dark brown text

  // ─── Utility Methods ──────────────────────────────────────────────

  /// Returns the primary category color for [category].
  static Color forCategory(String category) {
    switch (category
        .trim()
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('_', '')) {
      case 'speaking':
        return speaking;
      case 'listening':
        return listening;
      case 'reading':
        return reading;
      case 'writing':
        return writing;
      case 'grammar':
        return grammar;
      case 'vocabulary':
        return vocabulary;
      case 'accent':
        return accent;
      case 'roleplay':
        return roleplay;
      case 'elitemastery':
        return eliteMastery;
      default:
        return grammar;
    }
  }

  /// Returns light tint (for light-mode backgrounds) for [category].
  static Color lightTint(String category) {
    switch (category
        .trim()
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('_', '')) {
      case 'speaking':
        return speakingLight;
      case 'listening':
        return listeningLight;
      case 'reading':
        return readingLight;
      case 'writing':
        return writingLight;
      case 'grammar':
        return grammarLight;
      case 'vocabulary':
        return vocabularyLight;
      case 'accent':
        return accentLight;
      case 'roleplay':
        return roleplayLight;
      case 'elitemastery':
        return eliteMasteryLight;
      default:
        return grammarLight;
    }
  }

  /// Returns dark variant (for dark-mode text or emphasis) for [category].
  static Color darkVariant(String category) {
    switch (category
        .trim()
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('_', '')) {
      case 'speaking':
        return speakingDark;
      case 'listening':
        return listeningDark;
      case 'reading':
        return readingDark;
      case 'writing':
        return writingDark;
      case 'grammar':
        return grammarDark;
      case 'vocabulary':
        return vocabularyDark;
      case 'accent':
        return accentDark;
      case 'roleplay':
        return roleplayDark;
      case 'elitemastery':
        return eliteMasteryDark;
      default:
        return grammarDark;
    }
  }

  /// Returns the appropriate text/icon color to place **on** the primary
  /// category surface (white for most, dark brown for Elite Mastery gold).
  static Color onColor(String category) {
    switch (category
        .trim()
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('_', '')) {
      case 'elitemastery':
        return onEliteMastery;
      default:
        return const Color(0xFFFFFFFF);
    }
  }
}
