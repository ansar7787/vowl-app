import 'package:vowl/core/domain/entities/game_quest.dart';

/// Centralized utility coordinator that classifies gameplay features and returns
/// dynamic structural hints for visual template construction in Vowl.
///
/// Refactored from a massive hardcoded mapping registry to a dynamic, rule-based classifier
/// to ensure zero maintenance overhead when new gameplay subtypes are introduced.
class PromptStrategy {
  // Const constructor supports compile-time optimizations and footprint elimination
  const PromptStrategy();

  /// Classifies the [subtype] and [skill] to dynamically return structural key signatures.
  ///
  /// Used by layout builders to determine available field schemas (e.g. textToSpeak, passage, options).
  String getSpecificInstructions(QuestType skill, GameSubtype subtype) {
    final List<String> signatures = [];

    // 1. Audio and voice boundaries
    if (skill == QuestType.speaking ||
        skill == QuestType.accent ||
        subtype == GameSubtype.accentShadowing) {
      signatures.add('"textToSpeak"');
    }

    // 2. Reading passages and listening stories
    if (skill == QuestType.reading || skill == QuestType.listening) {
      signatures.add('"passage"');
    }

    // 3. Question entities
    if (skill == QuestType.grammar ||
        skill == QuestType.reading ||
        skill == QuestType.listening ||
        skill == QuestType.vocabulary) {
      signatures.add('"question"');
    }

    // 4. Multiple-choice and structural options
    final String name = subtype.name.toLowerCase();
    final bool hasOptions = name.contains('choice') ||
        name.contains('match') ||
        name.contains('search') ||
        name.contains('select') ||
        name.contains('quest') ||
        name.contains('agreement') ||
        name.contains('pos') ||
        name.contains('vocab') ||
        name.contains('phrasal') ||
        name.contains('idiom') ||
        name.contains('article') ||
        name.contains('preposition');

    if (hasOptions) {
      signatures.add('"options"');
    }

    return '{${signatures.join(', ')}}';
  }
}
