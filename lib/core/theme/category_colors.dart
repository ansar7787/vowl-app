import 'package:flutter/material.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color c_D84315 = Color(0xFFD84315);
  static const Color c_FBE9E7 = Color(0xFFFBE9E7);
  static const Color c_BF360C = Color(0xFFBF360C);
  static const Color c_FFFFFF = Color(0xFFFFFFFF);
  static const Color c_AD1457 = Color(0xFFAD1457);
  static const Color c_FCE4EC = Color(0xFFFCE4EC);
  static const Color c_880E4F = Color(0xFF880E4F);
  static const Color c_2E7D32 = Color(0xFF2E7D32);
  static const Color c_E8F5E9 = Color(0xFFE8F5E9);
  static const Color c_1B5E20 = Color(0xFF1B5E20);
  static const Color c_5E35B1 = Color(0xFF5E35B1);
  static const Color c_EDE7F6 = Color(0xFFEDE7F6);
  static const Color c_4527A0 = Color(0xFF4527A0);
  static const Color c_1565C0 = Color(0xFF1565C0);
  static const Color c_E3F2FD = Color(0xFFE3F2FD);
  static const Color c_0D47A1 = Color(0xFF0D47A1);
  static const Color c_6A1B9A = Color(0xFF6A1B9A);
  static const Color c_F3E5F5 = Color(0xFFF3E5F5);
  static const Color c_4A148C = Color(0xFF4A148C);
  static const Color c_00838F = Color(0xFF00838F);
  static const Color c_E0F7FA = Color(0xFFE0F7FA);
  static const Color c_006064 = Color(0xFF006064);
  static const Color c_B71C1C = Color(0xFFB71C1C);
  static const Color c_FFEBEE = Color(0xFFFFEBEE);
  static const Color c_8B0000 = Color(0xFF8B0000);
  static const Color c_F57F17 = Color(0xFFF57F17);
  static const Color c_FFF8E1 = Color(0xFFFFF8E1);
  static const Color c_9B7A1C = Color(0xFF9B7A1C);
  static const Color c_3E2723 = Color(0xFF3E2723);
}

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
  static const Color speaking = _LocalPalette.c_D84315;
  static const Color speakingLight = _LocalPalette.c_FBE9E7;
  static const Color speakingDark = _LocalPalette.c_BF360C;
  static const Color onSpeaking = _LocalPalette.c_FFFFFF;

  // ─── Listening ────────────────────────────────────────────────────
  /// Deep rose — emotional receptivity, immersion, deep attention.
  static const Color listening = _LocalPalette.c_AD1457;
  static const Color listeningLight = _LocalPalette.c_FCE4EC;
  static const Color listeningDark = _LocalPalette.c_880E4F;
  static const Color onListening = _LocalPalette.c_FFFFFF;

  // ─── Reading ──────────────────────────────────────────────────────
  /// Forest green — growth, comprehension, steady progress.
  static const Color reading = _LocalPalette.c_2E7D32;
  static const Color readingLight = _LocalPalette.c_E8F5E9;
  static const Color readingDark = _LocalPalette.c_1B5E20;
  static const Color onReading = _LocalPalette.c_FFFFFF;

  // ─── Writing ──────────────────────────────────────────────────────
  /// Deep violet — creativity, expression, literary imagination.
  static const Color writing = _LocalPalette.c_5E35B1;
  static const Color writingLight = _LocalPalette.c_EDE7F6;
  static const Color writingDark = _LocalPalette.c_4527A0;
  static const Color onWriting = _LocalPalette.c_FFFFFF;

  // ─── Grammar ──────────────────────────────────────────────────────
  /// True blue — structure, rules, precision, clarity.
  static const Color grammar = _LocalPalette.c_1565C0;
  static const Color grammarLight = _LocalPalette.c_E3F2FD;
  static const Color grammarDark = _LocalPalette.c_0D47A1;
  static const Color onGrammar = _LocalPalette.c_FFFFFF;

  // ─── Vocabulary ───────────────────────────────────────────────────
  /// Deep purple — wisdom, discovery, intellectual depth.
  static const Color vocabulary = _LocalPalette.c_6A1B9A;
  static const Color vocabularyLight = _LocalPalette.c_F3E5F5;
  static const Color vocabularyDark = _LocalPalette.c_4A148C;
  static const Color onVocabulary = _LocalPalette.c_FFFFFF;

  // ─── Accent ───────────────────────────────────────────────────────
  /// Cyan-teal — sound clarity, precision, audio focus.
  static const Color accent = _LocalPalette.c_00838F;
  static const Color accentLight = _LocalPalette.c_E0F7FA;
  static const Color accentDark = _LocalPalette.c_006064;
  static const Color onAccent = _LocalPalette.c_FFFFFF;

  // ─── Roleplay ─────────────────────────────────────────────────────
  /// Theatre red — drama, performance, social scenarios.
  static const Color roleplay = _LocalPalette.c_B71C1C;
  static const Color roleplayLight = _LocalPalette.c_FFEBEE;
  static const Color roleplayDark = _LocalPalette.c_8B0000;
  static const Color onRoleplay = _LocalPalette.c_FFFFFF;

  // ─── Elite Mastery ────────────────────────────────────────────────
  /// Deep amber-gold — prestige, achievement, ultimate mastery.
  /// NOTE: Use [onEliteMastery] (dark brown) for text on gold backgrounds.
  /// Use [eliteMasteryDark] when white text on a gold surface is needed.
  static const Color eliteMastery = _LocalPalette.c_F57F17;
  static const Color eliteMasteryLight = _LocalPalette.c_FFF8E1;
  static const Color eliteMasteryDark = _LocalPalette.c_9B7A1C;
  static const Color onEliteMastery = _LocalPalette.c_3E2723; // Dark brown text

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
        return _LocalPalette.c_FFFFFF;
    }
  }
}
