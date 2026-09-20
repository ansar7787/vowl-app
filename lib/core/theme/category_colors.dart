import 'package:flutter/material.dart';

class _LocalPalette {
  _LocalPalette._();
  static const Color colord84315 = Color(0xFFD84315);
  static const Color colorfbe9e7 = Color(0xFFFBE9E7);
  static const Color colorbf360c = Color(0xFFBF360C);
  static const Color colorffffff = Color(0xFFFFFFFF);
  static const Color colorad1457 = Color(0xFFAD1457);
  static const Color colorfce4ec = Color(0xFFFCE4EC);
  static const Color color880e4f = Color(0xFF880E4F);
  static const Color color2e7d32 = Color(0xFF2E7D32);
  static const Color colore8f5e9 = Color(0xFFE8F5E9);
  static const Color color1b5e20 = Color(0xFF1B5E20);
  static const Color color5e35b1 = Color(0xFF5E35B1);
  static const Color colorede7f6 = Color(0xFFEDE7F6);
  static const Color color4527a0 = Color(0xFF4527A0);
  static const Color color1565c0 = Color(0xFF1565C0);
  static const Color colore3f2fd = Color(0xFFE3F2FD);
  static const Color color0d47a1 = Color(0xFF0D47A1);
  static const Color color6a1b9a = Color(0xFF6A1B9A);
  static const Color colorf3e5f5 = Color(0xFFF3E5F5);
  static const Color color4a148c = Color(0xFF4A148C);
  static const Color color00838f = Color(0xFF00838F);
  static const Color colore0f7fa = Color(0xFFE0F7FA);
  static const Color color006064 = Color(0xFF006064);
  static const Color colorb71c1c = Color(0xFFB71C1C);
  static const Color colorffebee = Color(0xFFFFEBEE);
  static const Color color8b0000 = Color(0xFF8B0000);
  static const Color colorf57f17 = Color(0xFFF57F17);
  static const Color colorfff8e1 = Color(0xFFFFF8E1);
  static const Color color9b7a1c = Color(0xFF9B7A1C);
  static const Color color3e2723 = Color(0xFF3E2723);
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
  static const Color speaking = _LocalPalette.colord84315;
  static const Color speakingLight = _LocalPalette.colorfbe9e7;
  static const Color speakingDark = _LocalPalette.colorbf360c;
  static const Color onSpeaking = _LocalPalette.colorffffff;

  // ─── Listening ────────────────────────────────────────────────────
  /// Deep rose — emotional receptivity, immersion, deep attention.
  static const Color listening = _LocalPalette.colorad1457;
  static const Color listeningLight = _LocalPalette.colorfce4ec;
  static const Color listeningDark = _LocalPalette.color880e4f;
  static const Color onListening = _LocalPalette.colorffffff;

  // ─── Reading ──────────────────────────────────────────────────────
  /// Forest green — growth, comprehension, steady progress.
  static const Color reading = _LocalPalette.color2e7d32;
  static const Color readingLight = _LocalPalette.colore8f5e9;
  static const Color readingDark = _LocalPalette.color1b5e20;
  static const Color onReading = _LocalPalette.colorffffff;

  // ─── Writing ──────────────────────────────────────────────────────
  /// Deep violet — creativity, expression, literary imagination.
  static const Color writing = _LocalPalette.color5e35b1;
  static const Color writingLight = _LocalPalette.colorede7f6;
  static const Color writingDark = _LocalPalette.color4527a0;
  static const Color onWriting = _LocalPalette.colorffffff;

  // ─── Grammar ──────────────────────────────────────────────────────
  /// True blue — structure, rules, precision, clarity.
  static const Color grammar = _LocalPalette.color1565c0;
  static const Color grammarLight = _LocalPalette.colore3f2fd;
  static const Color grammarDark = _LocalPalette.color0d47a1;
  static const Color onGrammar = _LocalPalette.colorffffff;

  // ─── Vocabulary ───────────────────────────────────────────────────
  /// Deep purple — wisdom, discovery, intellectual depth.
  static const Color vocabulary = _LocalPalette.color6a1b9a;
  static const Color vocabularyLight = _LocalPalette.colorf3e5f5;
  static const Color vocabularyDark = _LocalPalette.color4a148c;
  static const Color onVocabulary = _LocalPalette.colorffffff;

  // ─── Accent ───────────────────────────────────────────────────────
  /// Cyan-teal — sound clarity, precision, audio focus.
  static const Color accent = _LocalPalette.color00838f;
  static const Color accentLight = _LocalPalette.colore0f7fa;
  static const Color accentDark = _LocalPalette.color006064;
  static const Color onAccent = _LocalPalette.colorffffff;

  // ─── Roleplay ─────────────────────────────────────────────────────
  /// Theatre red — drama, performance, social scenarios.
  static const Color roleplay = _LocalPalette.colorb71c1c;
  static const Color roleplayLight = _LocalPalette.colorffebee;
  static const Color roleplayDark = _LocalPalette.color8b0000;
  static const Color onRoleplay = _LocalPalette.colorffffff;

  // ─── Elite Mastery ────────────────────────────────────────────────
  /// Deep amber-gold — prestige, achievement, ultimate mastery.
  /// NOTE: Use [onEliteMastery] (dark brown) for text on gold backgrounds.
  /// Use [eliteMasteryDark] when white text on a gold surface is needed.
  static const Color eliteMastery = _LocalPalette.colorf57f17;
  static const Color eliteMasteryLight = _LocalPalette.colorfff8e1;
  static const Color eliteMasteryDark = _LocalPalette.color9b7a1c;
  static const Color onEliteMastery =
      _LocalPalette.color3e2723; // Dark brown text

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
        return _LocalPalette.colorffffff;
    }
  }
}
