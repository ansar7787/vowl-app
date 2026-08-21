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
  final List<String>? smartReplies;
  final String? pronunciationTips;
  final String? contextClue;
  final List<String>? keyVocabulary;
  final String? followUpQuestion;
  final String? emotionTag;
  final List<String>? commonMistakes;
  final List<String>? bonusAntonyms;
  final String? situationExample;

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
    this.smartReplies,
    this.pronunciationTips,
    this.contextClue,
    this.keyVocabulary,
    this.followUpQuestion,
    this.emotionTag,
    this.commonMistakes,
    this.bonusAntonyms,
    this.situationExample,
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
    smartReplies,
    pronunciationTips,
    contextClue,
    keyVocabulary,
    followUpQuestion,
    emotionTag,
    commonMistakes,
    bonusAntonyms,
    situationExample,
  ];
}
