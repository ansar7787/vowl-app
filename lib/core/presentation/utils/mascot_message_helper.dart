import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/utils/vowl_assets.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_assets.dart';

/// Centralized utility for determining the mascot's message and emotional state
/// across all game modes, eliminating switch-statement duplication in features.
///
/// Performance: All message key lookups are O(1) via [Map] constants
/// (previously O(n) switch chains).
class MascotMessageHelper {
  MascotMessageHelper._();

  // ─── Message key tables ──────────────────────────────────────────────────
  // Each state maps category string → i18n key.
  // Missing categories fall back to the `default` entry.

  static const _completeKeys = <String, String>{
    'grammar': 'mascot.complete_grammar',
    'vocabulary': 'mascot.complete_vocabulary',
    'elite_mastery': 'mascot.complete_elite_mastery',
    'speaking': 'mascot.complete_speaking',
    'writing': 'mascot.complete_writing',
    'reading': 'mascot.complete_reading',
    'listening': 'mascot.complete_listening',
    'roleplay': 'mascot.complete_roleplay',
    'accent': 'mascot.complete_accent',
    'kids': 'mascot.complete_kids',
    '': 'mascot.complete_default',
  };

  static const _correctKeys = <String, String>{
    'grammar': 'mascot.correct_grammar',
    'vocabulary': 'mascot.correct_vocabulary',
    'elite_mastery': 'mascot.correct_elite_mastery',
    'speaking': 'mascot.correct_speaking',
    'writing': 'mascot.correct_writing',
    'reading': 'mascot.correct_reading',
    'listening': 'mascot.correct_listening',
    'roleplay': 'mascot.correct_roleplay',
    'accent': 'mascot.correct_accent',
    'kids': 'mascot.correct_kids',
    '': 'mascot.correct_default',
  };

  static const _incorrectKeys = <String, String>{
    'grammar': 'mascot.incorrect_grammar',
    'vocabulary': 'mascot.incorrect_vocabulary',
    'elite_mastery': 'mascot.incorrect_elite_mastery',
    'speaking': 'mascot.incorrect_speaking',
    'writing': 'mascot.incorrect_writing',
    'reading': 'mascot.incorrect_reading',
    'listening': 'mascot.incorrect_listening',
    'roleplay': 'mascot.incorrect_roleplay',
    'accent': 'mascot.incorrect_accent',
    'kids': 'mascot.incorrect_kids',
    '': 'mascot.incorrect_default',
  };

  // Hint messages only exist for a subset of categories.
  static const _hintKeys = <String, String>{
    'speaking': 'mascot.hint_speaking',
    'reading': 'mascot.hint_reading',
    'writing': 'mascot.hint_writing',
    'kids': 'mascot.hint_kids',
    '': 'mascot.hint_default',
  };

  static const _idleKeys = <String, String>{
    'grammar': 'mascot.idle_grammar',
    'vocabulary': 'mascot.idle_vocabulary',
    'elite_mastery': 'mascot.idle_elite_mastery',
    'speaking': 'mascot.idle_speaking',
    'writing': 'mascot.idle_writing',
    'reading': 'mascot.idle_reading',
    'listening': 'mascot.idle_listening',
    'roleplay': 'mascot.idle_roleplay',
    'accent': 'mascot.idle_accent',
    '': 'mascot.idle_default',
  };

  // ─── Public API ──────────────────────────────────────────────────────────

  /// Determines the mascot's emotional display state from current game context.
  static VowlMascotState getMascotState({
    required bool isComplete,
    required bool isGameOver,
    required bool isAnswered,
    required bool? isCorrect,
    required int lives,
    int maxLives = 3,
  }) {
    if (isComplete) return VowlMascotState.happy;
    if (isGameOver) return VowlMascotState.worried;
    if (isAnswered) {
      return isCorrect == true
          ? VowlMascotState.happy
          : VowlMascotState.thinking;
    }
    // isCorrect can be non-null before isAnswered is set (e.g., mid-transition).
    if (isCorrect == true) return VowlMascotState.happy;
    if (isCorrect == false) return VowlMascotState.thinking;
    if (lives < maxLives) return VowlMascotState.worried;
    return VowlMascotState.neutral;
  }

  /// Returns a localised message string for the mascot speech bubble.
  ///
  /// [category] — game category name (e.g. `'grammar'`, `'vocabulary'`).
  /// [mascotId] — user-selected mascot identifier.
  static String getMessage(
    BuildContext context, {
    required String category,
    required String mascotId,
    required bool isComplete,
    required bool isAnswered,
    required bool? isCorrect,
    required int lives,
    int maxLives = 3,
  }) {
    final lowerCat = category.toLowerCase();
    final isKids = lowerCat.contains('kids');

    final mascotEmoji = isKids
        ? (KidsAssets.mascotMap[mascotId] ?? '🦉')
        : VowlAssets.getMascotEmoji(mascotId);
    final mascotName = isKids
        ? (KidsAssets.mascotNames[mascotId] ?? 'Buddy')
        : VowlAssets.getMascotName(mascotId);

    // Normalise the category key: handle 'elitemastery' → 'elite_mastery'.
    final catKey = _normaliseCategoryKey(lowerCat);

    if (isComplete) {
      return context.tr(
        _completeKeys[catKey] ?? _completeKeys['']!,
        args: [mascotEmoji],
      );
    }

    if (isCorrect == true) {
      return context.tr(
        _correctKeys[catKey] ?? _correctKeys['']!,
        args: [mascotEmoji],
      );
    }

    if (isCorrect == false) {
      return context.tr(
        _incorrectKeys[catKey] ?? _incorrectKeys['']!,
        args: [mascotEmoji],
      );
    }

    if (lives < maxLives && !isAnswered) {
      // Use category-specific hint key only where one is defined.
      final hintKey = _hintKeys.containsKey(catKey) ? catKey : '';
      return context.tr(_hintKeys[hintKey]!, args: [mascotEmoji]);
    }

    // Idle — kids only use emoji; all others use name + emoji.
    if (isKids) {
      return context.tr('mascot.idle_kids', args: [mascotEmoji]);
    }
    return context.tr(
      _idleKeys[catKey] ?? _idleKeys['']!,
      args: [mascotName, mascotEmoji],
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  /// Normalises various spellings of category names to canonical lookup keys.
  static String _normaliseCategoryKey(String lowerCat) {
    if (lowerCat.contains('kids')) return 'kids';
    if (lowerCat == 'elitemastery' || lowerCat == 'elite_mastery') {
      return 'elite_mastery';
    }
    const valid = {
      'grammar',
      'vocabulary',
      'speaking',
      'writing',
      'reading',
      'listening',
      'roleplay',
      'accent',
    };
    return valid.contains(lowerCat) ? lowerCat : '';
  }
}
