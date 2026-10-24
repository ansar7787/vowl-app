import 'package:vowl/core/domain/entities/game_quest.dart';

/// Domain entity representing a writing quest with grammatical, lexical, and composition metadata.
class WritingQuest extends GameQuest {
  /// Reading passage or stimulus text.
  final String? passage;

  /// Target missing word for sentence completion.
  final String? missingWord;

  /// Writing instruction prompt or question.
  final String? prompt;

  /// Reference sample answer illustrating high-quality output.
  final String? sampleAnswer;

  /// Shuffled word tokens for sentence ordering.
  final List<String>? shuffledWords;

  /// Ordered token indices representing the correct sequence.
  final List<int>? correctOrder;

  /// Narrative story text.
  final String? story;

  /// Scenario or situational context for the writing prompt.
  final String? situation;

  /// Sentence prefix preceding the user input field.
  final String? prefix;

  /// Sentence suffix following the user input field.
  final String? suffix;

  /// Minimum word count threshold.
  final int? minWords;

  /// Required points or key concepts that must be addressed.
  final List<String>? requiredPoints;

  /// Description of the daily journal topic or scenario.
  final String? dayDescription;

  /// Background contextual description.
  final String? context;

  /// Incomplete or partial sentence prompt.
  final String? partialSentence;

  /// Target sentence completion string.
  final String? completion;

  /// Subject line for email drafting.
  final String? subject;

  /// Intended recipient for email drafting.
  final String? recipient;

  /// Broad essay topic title.
  final String? essayTopic;

  /// Associated emoji icons reflecting concepts.
  final List<String>? emojis;

  /// Categorized vocabulary keywords.
  final Map<String, List<String>>? keywords;

  /// Number of grammatical or spelling errors present in text to fix.
  final int? errorCount;

  /// Guiding questions for brainstorming.
  final List<String>? promptQuestions;

  /// Model answer text.
  final String? modelAnswer;

  /// Central thesis statement.
  final String? thesisStatement;

  /// Specific error type being tested.
  final String? errorType;

  /// Outline or structural guideline.
  final String? structureGuide;

  /// Chronological key events of the story to summarize.
  final List<String>? storyKeyEvents;

  /// Formality level expectation (e.g., formal, informal).
  final String? formalityLevel;

  /// Grammatical sentence structure classification.
  final String? sentenceType;

  /// Target grammar rule focus.
  final String? grammarFocus;

  /// Specific lexical keywords expected in the user's submission.
  final List<String>? keywordsExpected;

  /// Creates a [WritingQuest] domain entity.
  const WritingQuest({
    required super.id,
    super.type,
    required super.instruction,
    required super.difficulty,
    super.subtype,
    super.interactionType = InteractionType.writing,
    super.xpReward,
    super.coinReward,
    super.livesAllowed,
    super.options,
    super.correctAnswerIndex,
    super.correctAnswer,
    super.hint,
    this.passage,
    super.question,
    super.textToSpeak,
    super.visualConfig,
    this.missingWord,
    this.prompt,
    this.sampleAnswer,
    super.explanation,
    this.shuffledWords,
    this.correctOrder,
    this.story,
    this.situation,
    this.prefix,
    this.suffix,
    this.minWords,
    this.requiredPoints,
    this.dayDescription,
    this.context,
    this.partialSentence,
    this.completion,
    this.subject,
    this.recipient,
    this.essayTopic,
    this.emojis,
    this.keywords,
    this.errorCount,
    this.promptQuestions,
    this.modelAnswer,
    this.thesisStatement,
    this.errorType,
    this.structureGuide,
    this.storyKeyEvents,
    this.formalityLevel,
    this.sentenceType,
    this.grammarFocus,
    this.keywordsExpected,
  });

  /// Alias returning the flawed [passage] text for sentence correction quests.
  String? get incorrectSentence => passage;

  /// Alias returning the [correctAnswer] text for sentence correction quests.
  String? get correctSentence => correctAnswer;
}
