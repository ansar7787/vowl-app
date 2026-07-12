import 'package:flutter/foundation.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';

@immutable
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
    super.correctAnswerCategory,
    super.question,
    super.sentence,
    super.targetWord,
    super.hint,
    super.textToSpeak,
    super.visualConfig,
    super.explanation,
    this.missingWord,
    this.prompt,
    this.sampleAnswer,
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

  @override
  List<Object?> get props => [
    ...super.props,
    missingWord,
    prompt,
    sampleAnswer,
    translation,
    situationText,
    sceneText,
    acceptedSynonyms,
    phoneticHint,
    meaning,
    sampleUsage,
    partnerDialogue,
    targetPhoneme,
    expression,
  ];
}
