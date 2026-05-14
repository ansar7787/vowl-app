import 'package:vowl/core/domain/entities/game_quest.dart';

class SpeakingQuest extends GameQuest {
  final String? missingWord;
  final String? prompt;
  final String? sampleAnswer;
  final String? translation;
  final String? situationText;
  final String? sceneText;
  final List<String>? acceptedSynonyms;
  final String? phoneticHint;
  final String? meaning;
  final String? sampleUsage;
  final String? partnerDialogue;
  final String? targetPhoneme;
  final String? expression;

  const SpeakingQuest({
    required super.id,
    super.type,
    required super.instruction,
    required super.difficulty,
    super.subtype,
    super.interactionType = InteractionType.speech,
    super.xpReward,
    super.coinReward,
    super.livesAllowed,
    super.options,
    super.correctAnswerIndex,
    super.correctAnswer,
    super.hint,
    super.textToSpeak,
    super.visualConfig,
    this.missingWord,
    this.prompt,
    this.sampleAnswer,
    super.explanation,
    this.translation,
    this.situationText,
    this.sceneText,
    this.acceptedSynonyms,
    this.phoneticHint,
    this.meaning,
    this.sampleUsage,
    this.partnerDialogue,
    this.targetPhoneme,
    this.expression,
  });
}

