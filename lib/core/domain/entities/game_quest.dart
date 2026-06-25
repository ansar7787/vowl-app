import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Defines the exact modality of user interaction required by the quest interface.
enum InteractionType {
  speech,
  choice,
  writing,
  sequence,
  match,
  speaking,
  typing,
  reorder,
  trueFalse,
  text,
  spell,
  voice,
  selection,
  dialogue,
  slider,
  rating,
  mapping,
  bubbles,
  flip,
  lens,
  mirror,
  rub,
  paint,
  sort,
  lab,
  tree,
  slot,
  chain,
  scroll,
  verdict,
  condenser,
  search,
  journal,
  digest,
  audit,
  draft,
  blueprint,
  echo,
  verbalizer,
  narrator,
  pivot,
  clarity,
  radar,
  probe,
  pulse,
  anchor,
  mimic,
  shadow,
  stress,
  linking;

  /// Pre-computed fast lookup table for constant O(1) string-to-enum resolution.
  static final Map<String, InteractionType> _nameMap = {
    for (final val in InteractionType.values) val.name.toLowerCase(): val,
  };

  /// Safely resolves any string value into its matching [InteractionType] in O(1) constant time.
  static InteractionType fromString(
    String? val, {
    InteractionType fallback = InteractionType.choice,
  }) {
    if (val == null) return fallback;
    return _nameMap[val.toLowerCase()] ?? fallback;
  }
}

/// Category grouping representing primary syllabus pillars.
///
/// BUG FIX: this enum previously had a `QuestTypeX.name` extension getter
/// with a manual switch statement returning lowercase serialization names
/// (e.g. 'elitemastery' for eliteMastery). That getter was **dead code**:
/// every Dart enum automatically provides a built-in `name` getter (since
/// Dart 2.15), and the language always resolves a real instance member
/// over an extension member of the same name - extensions can never
/// override anything. So every call site doing `someQuestType.name`
/// silently got the *native* camelCase identifier ('eliteMastery') instead
/// of the intended lowercase serialization form ('elitemastery'), for the
/// one value where they differ. Since other code in this codebase (e.g.
/// the legacy-script lookup keys in `story_service.dart`) expects the
/// lowercase 'elitemastery' form, this was a real, silent correctness bug.
///
/// Fixed by exposing the custom value as a clearly *different*, genuinely
/// reachable name: [serializedName]. Any code elsewhere that was calling
/// `.name` expecting 'elitemastery' must be updated to call
/// `.serializedName` instead - that old call always returned the native
/// camelCase name and never the custom one, so this is a bug fix, not a
/// behavior change from what calling code could have actually observed.
enum QuestType {
  speaking,
  listening,
  reading,
  writing,
  grammar,
  vocabulary,
  accent,
  roleplay,
  eliteMastery;

  /// Pre-computed fast lookup table for constant O(1) string-to-enum resolution.
  static final Map<String, QuestType> _nameMap = {
    for (final val in QuestType.values) val.name.toLowerCase(): val,
    'elitemastery': QuestType.eliteMastery,
  };

  /// Safely resolves any string value into its matching [QuestType] in O(1) constant time.
  static QuestType fromString(
    String? val, {
    QuestType fallback = QuestType.reading,
  }) {
    if (val == null) return fallback;
    return _nameMap[val.toLowerCase()] ?? fallback;
  }
}

/// Identifies the sub-gamification engine type assigned to the quest.
///
/// BUG FIX: each value now carries its [category] directly as a declared
/// field, set via the enum's own constructor. Previously,
/// `GameSubtypeX.category` inferred the category purely from *declaration
/// order* via chained `index <= X.index` comparisons, and `QuestTypeX.
/// subtypes` inverted that via `sublist(startIndex, endIndex)` - both
/// silently and invisibly break (no compile error, no runtime exception,
/// just wrong groupings) the moment anyone inserts a new value in the
/// wrong place or reorders this list, which is exactly the kind of change
/// a ~90-value, actively-growing curriculum enum is likely to need over
/// time. Declaring the category per-value removes that fragility
/// entirely and is self-documenting at the declaration site.
enum GameSubtype {
  // 1. Speaking
  repeatSentence(QuestType.speaking),
  speakMissingWord(QuestType.speaking),
  situationSpeaking(QuestType.speaking),
  sceneDescriptionSpeaking(QuestType.speaking),
  yesNoSpeaking(QuestType.speaking),
  speakSynonym(QuestType.speaking),
  dialogueRoleplay(QuestType.speaking),
  pronunciationFocus(QuestType.speaking),
  speakOpposite(QuestType.speaking),
  dailyExpression(QuestType.speaking),
  // 2. Listening
  audioFillBlanks(QuestType.listening),
  audioMultipleChoice(QuestType.listening),
  audioSentenceOrder(QuestType.listening),
  audioTrueFalse(QuestType.listening),
  soundImageMatch(QuestType.listening),
  fastSpeechDecoder(QuestType.listening),
  emotionRecognition(QuestType.listening),
  detailSpotlight(QuestType.listening),
  listeningInference(QuestType.listening),
  ambientId(QuestType.listening),
  // 3. Reading
  readAndAnswer(QuestType.reading),
  findWordMeaning(QuestType.reading),
  trueFalseReading(QuestType.reading),
  sentenceOrderReading(QuestType.reading),
  readingSpeedCheck(QuestType.reading),
  guessTitle(QuestType.reading),
  readAndMatch(QuestType.reading),
  paragraphSummary(QuestType.reading),
  readingInference(QuestType.reading),
  readingConclusion(QuestType.reading),
  clozeTest(QuestType.reading),
  skimmingScanning(QuestType.reading),
  // 4. Writing
  sentenceBuilder(QuestType.writing),
  completeSentence(QuestType.writing),
  describeSituationWriting(QuestType.writing),
  fixTheSentence(QuestType.writing),
  shortAnswerWriting(QuestType.writing),
  opinionWriting(QuestType.writing),
  dailyJournal(QuestType.writing),
  summarizeStoryWriting(QuestType.writing),
  writingEmail(QuestType.writing),
  correctionWriting(QuestType.writing),
  essayDrafting(QuestType.writing),
  // 5. Grammar
  grammarQuest(QuestType.grammar),
  sentenceCorrection(QuestType.grammar),
  wordReorder(QuestType.grammar),
  tenseMastery(QuestType.grammar),
  partsOfSpeech(QuestType.grammar),
  subjectVerbAgreement(QuestType.grammar),
  clauseConnector(QuestType.grammar),
  voiceSwap(QuestType.grammar),
  questionFormatter(QuestType.grammar),
  articleInsertion(QuestType.grammar),
  modifierPlacement(QuestType.grammar),
  modalsSelection(QuestType.grammar),
  prepositionChoice(QuestType.grammar),
  pronounResolution(QuestType.grammar),
  punctuationMastery(QuestType.grammar),
  relativeClauses(QuestType.grammar),
  conditionals(QuestType.grammar),
  conjunctions(QuestType.grammar),
  directIndirectSpeech(QuestType.grammar),
  // 6. Vocabulary
  flashcards(QuestType.vocabulary),
  synonymSearch(QuestType.vocabulary),
  antonymSearch(QuestType.vocabulary),
  contextClues(QuestType.vocabulary),
  phrasalVerbs(QuestType.vocabulary),
  idioms(QuestType.vocabulary),
  academicWord(QuestType.vocabulary),
  topicVocab(QuestType.vocabulary),
  wordFormation(QuestType.vocabulary),
  prefixSuffix(QuestType.vocabulary),
  collocations(QuestType.vocabulary),
  contextualUsage(QuestType.vocabulary),
  // 7. Accent
  minimalPairs(QuestType.accent),
  intonationMimic(QuestType.accent),
  syllableStress(QuestType.accent),
  wordLinking(QuestType.accent),
  shadowingChallenge(QuestType.accent),
  vowelDistinction(QuestType.accent),
  consonantClarity(QuestType.accent),
  pitchPatternMatch(QuestType.accent),
  speedVariance(QuestType.accent),
  dialectDrill(QuestType.accent),
  connectedSpeech(QuestType.accent),
  pitchModulation(QuestType.accent),
  // 8. Roleplay
  branchingDialogue(QuestType.roleplay),
  situationalResponse(QuestType.roleplay),
  jobInterview(QuestType.roleplay),
  medicalConsult(QuestType.roleplay),
  gourmetOrder(QuestType.roleplay),
  travelDesk(QuestType.roleplay),
  conflictResolver(QuestType.roleplay),
  elevatorPitch(QuestType.roleplay),
  socialSpark(QuestType.roleplay),
  emergencyHub(QuestType.roleplay),
  // 9. Elite Mastery
  storyBuilder(QuestType.eliteMastery),
  idiomMatch(QuestType.eliteMastery),
  speedSpelling(QuestType.eliteMastery),
  accentShadowing(QuestType.eliteMastery);

  /// The syllabus pillar this subtype belongs to. Declared directly per
  /// value instead of inferred from position - see class doc comment.
  final QuestType category;

  const GameSubtype(this.category);

  /// Pre-computed fast lookup table for constant O(1) string-to-enum resolution.
  static final Map<String, GameSubtype> _nameMap = {
    for (final val in GameSubtype.values) val.name.toLowerCase(): val,
  };

  /// Safely resolves any string value into its matching [GameSubtype] in O(1) constant time.
  static GameSubtype fromString(
    String? val, {
    GameSubtype fallback = GameSubtype.repeatSentence,
  }) {
    if (val == null) return fallback;
    return _nameMap[val.toLowerCase()] ?? fallback;
  }
}

/// Helper methods retained for backward compatibility with existing call sites.
extension GameSubtypeX on GameSubtype {
  /// Always `false`. Retained only because it was part of the original
  /// public API; no code path can ever set this to `true`. Safe to ignore
  /// or remove once you've confirmed nothing outside this reviewed slice
  /// depends on it.
  bool get isLegacy => false;
}

extension QuestTypeX on QuestType {
  /// All [GameSubtype] values belonging to this category.
  ///
  /// Previously computed via `GameSubtype.values.sublist(startIndex,
  /// endIndex + 1)` using hardcoded boundary enum values - functionally
  /// equivalent today, but only because the enum's declaration order
  /// happened to be grouped correctly. Now derived directly from each
  /// value's own [GameSubtype.category] field, so it stays correct
  /// regardless of declaration order or future insertions.
  List<GameSubtype> get subtypes =>
      GameSubtype.values.where((s) => s.category == this).toList();

  /// Lowercase, stable serialization name for this category - use this
  /// (not the native `.name`) anywhere you need the legacy lowercase
  /// 'elitemastery' form (Firestore doc IDs, asset folder lookups, the
  /// `legacyAdultScripts` keys in `story_service.dart`, etc.).
  String get serializedName {
    switch (this) {
      case QuestType.speaking:
        return 'speaking';
      case QuestType.listening:
        return 'listening';
      case QuestType.reading:
        return 'reading';
      case QuestType.writing:
        return 'writing';
      case QuestType.grammar:
        return 'grammar';
      case QuestType.vocabulary:
        return 'vocabulary';
      case QuestType.accent:
        return 'accent';
      case QuestType.roleplay:
        return 'roleplay';
      case QuestType.eliteMastery:
        return 'elitemastery';
    }
  }
}

/// Visual configuration for quest UI theming.
/// Maps to the `visual_config` JSON object in curriculum files.
@immutable
class VisualConfig extends Equatable {
  final String painterType;
  final String primaryColor;
  final double pulseIntensity;
  final String shaderEffect;

  const VisualConfig({
    this.painterType = 'DataLogSync',
    this.primaryColor = '0xFF03A9F4',
    this.pulseIntensity = 0.5,
    this.shaderEffect = 'glow_shimmer',
  });

  /// Parse from JSON map.
  factory VisualConfig.fromJson(Map<String, dynamic> json) {
    return VisualConfig(
      painterType: json['painter_type'] as String? ?? 'DataLogSync',
      primaryColor: json['primary_color'] as String? ?? '0xFF03A9F4',
      pulseIntensity: (json['pulse_intensity'] as num?)?.toDouble() ?? 0.5,
      shaderEffect: json['shader_effect'] as String? ?? 'glow_shimmer',
    );
  }

  /// Convert to JSON map.
  Map<String, dynamic> toJson() => {
    'painter_type': painterType,
    'primary_color': primaryColor,
    'pulse_intensity': pulseIntensity,
    'shader_effect': shaderEffect,
  };

  /// Type-safe state manipulator.
  VisualConfig copyWith({
    String? painterType,
    String? primaryColor,
    double? pulseIntensity,
    String? shaderEffect,
  }) {
    return VisualConfig(
      painterType: painterType ?? this.painterType,
      primaryColor: primaryColor ?? this.primaryColor,
      pulseIntensity: pulseIntensity ?? this.pulseIntensity,
      shaderEffect: shaderEffect ?? this.shaderEffect,
    );
  }

  @override
  List<Object?> get props => [
    painterType,
    primaryColor,
    pulseIntensity,
    shaderEffect,
  ];
}

/// Central domain entity model representing a game quest challenge task.
@immutable
class GameQuest extends Equatable {
  final String id;
  final QuestType? type;
  final String instruction;
  final int difficulty;
  final GameSubtype? subtype;
  final InteractionType interactionType;
  final int xpReward;
  final int coinReward;
  final int livesAllowed;
  final List<String>? options;
  final int? correctAnswerIndex;
  final String? correctAnswer;
  final String? correctAnswerCategory;
  final String? question;
  final String? sentence;
  final String? targetWord;
  final String? hint;
  final String? explanation;
  final String? textToSpeak;
  final VisualConfig? visualConfig;

  const GameQuest({
    required this.id,
    this.type,
    required this.instruction,
    required this.difficulty,
    this.subtype,
    this.interactionType = InteractionType.choice,
    this.xpReward = 10,
    this.coinReward = 10,
    this.livesAllowed = 3,
    this.options,
    this.correctAnswerIndex,
    this.correctAnswer,
    this.correctAnswerCategory,
    this.question,
    this.sentence,
    this.targetWord,
    this.hint,
    this.explanation,
    this.textToSpeak,
    this.visualConfig,
  });

  @override
  List<Object?> get props => [
    id,
    type,
    instruction,
    difficulty,
    subtype,
    interactionType,
    xpReward,
    coinReward,
    livesAllowed,
    options,
    correctAnswerIndex,
    correctAnswer,
    correctAnswerCategory,
    question,
    sentence,
    targetWord,
    hint,
    explanation,
    textToSpeak,
    visualConfig,
  ];
}
