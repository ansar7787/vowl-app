import 'package:flutter/foundation.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';

/// Domain entity representing an interactive oral speech challenge.
@immutable
class SpeakingQuest extends GameQuest {
  /// Target lexical token missing from sentence fill-in speech prompts.
  final String? missingWord;

  /// Situational prompt guiding the user's spoken response.
  final String? prompt;

  /// Canonical model response demonstrating ideal pronunciation and grammar.
  final String? sampleAnswer;

  /// Native language translation of the target speech prompt.
  final String? translation;

  /// Contextual narrative framing the conversational situation.
  final String? situationText;

  /// Environmental visual description for scene narration challenges.
  final String? sceneText;

  /// Accepted lexical alternatives fulfilling the speaking requirement.
  final List<String>? acceptedSynonyms;

  /// IPA or phonetic respelling aiding correct pronunciation.
  final String? phoneticHint;

  /// Definition or semantic explanation of the spoken expression.
  final String? meaning;

  /// Exemplary sentence demonstrating colloquial usage.
  final String? sampleUsage;

  /// Conversational dialogue cue delivered by the virtual partner.
  final String? partnerDialogue;

  /// Specific phonetic sound targeted for acoustic analysis.
  final String? targetPhoneme;

  /// Idiomatic phrase or target expression.
  final String? expression;

  /// Quick conversational reply suggestions.
  final List<String>? smartReplies;

  /// Pedagogical phonetic guidance (tongue placement, voicing).
  final String? pronunciationTips;

  /// Contextual clue aiding spontaneous speech production.
  final String? contextClue;

  /// Key vocabulary items expected in the user's response.
  final List<String>? keyVocabulary;

  /// Secondary extension question encouraging natural conversational flow.
  final String? followUpQuestion;

  /// Emotional tone tag (e.g. enthusiastic, apologetic, formal).
  final String? emotionTag;

  /// Frequent phonological or grammatical pitfalls.
  final List<String>? commonMistakes;

  /// Additional antonym tokens recognized in antonym speaking exercises.
  final List<String>? bonusAntonyms;

  /// Practical real-world example scenario.
  final String? situationExample;

  /// Pragmatic affective framing context.
  final String? emotionContext;

  /// Creates a [SpeakingQuest] entity.
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
    this.emotionContext,
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
    emotionContext,
  ];
}
