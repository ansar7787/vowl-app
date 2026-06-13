import 'package:flutter/material.dart';
import 'package:vowl/core/presentation/utils/vowl_assets.dart';
import 'package:vowl/core/presentation/widgets/vowl_mascot.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_assets.dart';

/// Centralized utility for determining the Mascot's message and visual state 
/// across all game modes, preventing code duplication in every feature.
class MascotMessageHelper {
  MascotMessageHelper._();

  /// Determines the mascot's emotional state based on game progression.
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
      return isCorrect == true ? VowlMascotState.happy : VowlMascotState.thinking;
    }
    if (isCorrect == true) return VowlMascotState.happy;
    if (lives < maxLives && !isAnswered) return VowlMascotState.worried;
    if (isCorrect == false) return VowlMascotState.thinking;
    
    return VowlMascotState.neutral;
  }

  /// Dynamically generates a game-specific message for the mascot speech bubble.
  static String getMessage(
    BuildContext context, {
    required String category, // e.g., 'grammar', 'vocabulary', 'speaking', etc.
    required String mascotId,
    required bool isComplete,
    required bool isAnswered,
    required bool? isCorrect,
    required int lives,
    int maxLives = 3,
  }) {
    final isKids = category.toLowerCase().contains('kids');
    final mascotName = isKids 
        ? (KidsAssets.mascotNames[mascotId] ?? 'Buddy') 
        : VowlAssets.getMascotName(mascotId);
    final mascotEmoji = isKids 
        ? (KidsAssets.mascotMap[mascotId] ?? '🦉') 
        : VowlAssets.getMascotEmoji(mascotId);

    if (isComplete) {
      switch (category.toLowerCase()) {
        case 'grammar': return context.tr('mascot.complete_grammar', args: [mascotEmoji]);
        case 'vocabulary': return context.tr('mascot.complete_vocabulary', args: [mascotEmoji]);
        case 'elite_mastery': return context.tr('mascot.complete_elite_mastery', args: [mascotEmoji]);
        case 'speaking': return context.tr('mascot.complete_speaking', args: [mascotEmoji]);
        case 'writing': return context.tr('mascot.complete_writing', args: [mascotEmoji]);
        case 'reading': return context.tr('mascot.complete_reading', args: [mascotEmoji]);
        case 'listening': return context.tr('mascot.complete_listening', args: [mascotEmoji]);
        case 'roleplay': return context.tr('mascot.complete_roleplay', args: [mascotEmoji]);
        case 'accent': return context.tr('mascot.complete_accent', args: [mascotEmoji]);
        case 'kids': return context.tr('mascot.complete_kids', args: [mascotEmoji]);
        default: return context.tr('mascot.complete_default', args: [mascotEmoji]);
      }
    }

    if (isCorrect == true) {
      switch (category.toLowerCase()) {
        case 'grammar': return context.tr('mascot.correct_grammar', args: [mascotEmoji]);
        case 'vocabulary': return context.tr('mascot.correct_vocabulary', args: [mascotEmoji]);
        case 'elite_mastery': return context.tr('mascot.correct_elite_mastery', args: [mascotEmoji]);
        case 'speaking': return context.tr('mascot.correct_speaking', args: [mascotEmoji]);
        case 'writing': return context.tr('mascot.correct_writing', args: [mascotEmoji]);
        case 'reading': return context.tr('mascot.correct_reading', args: [mascotEmoji]);
        case 'listening': return context.tr('mascot.correct_listening', args: [mascotEmoji]);
        case 'roleplay': return context.tr('mascot.correct_roleplay', args: [mascotEmoji]);
        case 'accent': return context.tr('mascot.correct_accent', args: [mascotEmoji]);
        case 'kids': return context.tr('mascot.correct_kids', args: [mascotEmoji]);
        default: return context.tr('mascot.correct_default', args: [mascotEmoji]);
      }
    }

    if (isCorrect == false) {
      switch (category.toLowerCase()) {
        case 'grammar': return context.tr('mascot.incorrect_grammar', args: [mascotEmoji]);
        case 'vocabulary': return context.tr('mascot.incorrect_vocabulary', args: [mascotEmoji]);
        case 'elite_mastery': return context.tr('mascot.incorrect_elite_mastery', args: [mascotEmoji]);
        case 'speaking': return context.tr('mascot.incorrect_speaking', args: [mascotEmoji]);
        case 'writing': return context.tr('mascot.incorrect_writing', args: [mascotEmoji]);
        case 'reading': return context.tr('mascot.incorrect_reading', args: [mascotEmoji]);
        case 'listening': return context.tr('mascot.incorrect_listening', args: [mascotEmoji]);
        case 'roleplay': return context.tr('mascot.incorrect_roleplay', args: [mascotEmoji]);
        case 'accent': return context.tr('mascot.incorrect_accent', args: [mascotEmoji]);
        case 'kids': return context.tr('mascot.incorrect_kids', args: [mascotEmoji]);
        default: return context.tr('mascot.incorrect_default', args: [mascotEmoji]);
      }
    }

    if (lives < maxLives && !isAnswered) {
      switch (category.toLowerCase()) {
        case 'speaking': return context.tr('mascot.hint_speaking', args: [mascotEmoji]);
        case 'reading': return context.tr('mascot.hint_reading', args: [mascotEmoji]);
        case 'writing': return context.tr('mascot.hint_writing', args: [mascotEmoji]);
        case 'kids': return context.tr('mascot.hint_kids', args: [mascotEmoji]);
        default: return context.tr('mascot.hint_default', args: [mascotEmoji]);
      }
    }

    final lowerCat = category.toLowerCase();
    if (lowerCat.contains('kids')) return context.tr('mascot.idle_kids', args: [mascotEmoji]);

    switch (lowerCat) {
      case 'grammar': return context.tr('mascot.idle_grammar', args: [mascotName, mascotEmoji]);
      case 'vocabulary': return context.tr('mascot.idle_vocabulary', args: [mascotName, mascotEmoji]);
      case 'elite_mastery': return context.tr('mascot.idle_elite_mastery', args: [mascotName, mascotEmoji]);
      case 'speaking': return context.tr('mascot.idle_speaking', args: [mascotName, mascotEmoji]);
      case 'writing': return context.tr('mascot.idle_writing', args: [mascotName, mascotEmoji]);
      case 'reading': return context.tr('mascot.idle_reading', args: [mascotName, mascotEmoji]);
      case 'listening': return context.tr('mascot.idle_listening', args: [mascotName, mascotEmoji]);
      case 'roleplay': return context.tr('mascot.idle_roleplay', args: [mascotName, mascotEmoji]);
      case 'accent': return context.tr('mascot.idle_accent', args: [mascotName, mascotEmoji]);
      default: return context.tr('mascot.idle_default', args: [mascotName, mascotEmoji]);
    }
  }
}
