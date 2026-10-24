import 'package:vowl/core/domain/entities/game_quest.dart';

/// Domain entity representing an accent training exercise quest item.
class AccentQuest extends GameQuest {
  /// The target vocabulary word being pronounced.
  final String? word;

  /// International Phonetic Alphabet (IPA) hint for pronunciation.
  final String? phoneticHint;

  /// User prompt or conversational context cue.
  final String? prompt;

  /// Model audio or textual sample answer.
  final String? sampleAnswer;

  /// Segmented word tokens in the challenge sequence.
  final List<String>? words;

  /// Contour map indicating pitch/tone levels per syllable.
  final List<int>? intonationMap;

  /// Syllable breakdown for rhythm training.
  final List<String>? syllables;

  /// Expected speech rate in words per minute or relative scale.
  final double? targetSpeed;

  /// Melodic pitch contour pattern indices.
  final List<int>? pitchPatterns;

  /// Stress pattern indicator (e.g., primary vs secondary stress).
  final String? stressPattern;

  /// First word of a minimal pair comparison.
  final String? word1;

  /// Second word of a minimal pair comparison.
  final String? word2;

  /// IPA transcription for [word1].
  final String? ipa1;

  /// IPA transcription for [word2].
  final String? ipa2;

  /// Articulation and mouth position guidance note.
  final String? mouthPosition;

  /// Slow phonetic breakdown of the target phrase.
  final String? slowForm;

  /// Descriptive dialect or accent label (e.g., "Received Pronunciation", "General American").
  final String? accentName;

  /// Phonetic rule explanation governing the accent variation.
  final String? phoneticRule;

  /// Sociolinguistic or geographic dialect notes.
  final String? dialectNote;

  /// Pitch variation guidelines for speech inflection.
  final String? pitchRule;

  /// Vocal tract and vowel tension instruction.
  final String? vowelTensionRule;

  /// Prosody and modulation pattern description.
  final String? modulationPattern;

  /// Sentence emphasis and focal stress instructions.
  final String? emphasisRule;

  /// Connected speech flow and rhythm guidelines.
  final String? flowRule;

  /// Speech tempo and pause cadence rules.
  final String? pacingRule;

  /// Syllabic stress placement rules.
  final String? stressRule;

  /// Emotional tone or pragmatic context.
  final String? emotionContext;

  /// Zero-based index of the primary stressed syllable.
  final int? stressIndex;

  /// Connected speech phonological linking classification.
  final String? linkingType;

  /// Normalized speed rate coefficient.
  final double? speedLevel;

  /// Acoustic formant vowel quadrilateral position map.
  final Map<String, dynamic>? vowelChart;

  /// Consonant voicing characteristic (voiced vs unvoiced).
  final String? voicing;

  /// Pulmonary airflow characteristic (e.g., plosive, fricative).
  final String? airflow;

  /// Natural conversational playback speed.
  final double? naturalSpeed;

  /// Enunciated slow playback speed for clarity.
  final double? clearSpeed;

  /// Geographic or cultural dialect zone.
  final String? dialectRegion;

  /// Phonological phenomenon classification (assimilation, elision, linking).
  final String? phenomenonType;

  /// Colloquial or contracted spoken representation.
  final String? spokenForm;

  /// Semantic shift or nuance imparted by intonation or dialect choice.
  final String? meaningShift;

  /// Creates an [AccentQuest] entity with comprehensive phonological attributes.
  const AccentQuest({
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
    this.word,
    this.phoneticHint,
    super.textToSpeak,
    super.visualConfig,
    this.prompt,
    this.sampleAnswer,
    super.explanation,
    this.words,
    this.intonationMap,
    this.syllables,
    this.targetSpeed,
    this.pitchPatterns,
    this.stressPattern,
    this.word1,
    this.word2,
    this.ipa1,
    this.ipa2,
    this.mouthPosition,
    this.slowForm,
    this.accentName,
    this.phoneticRule,
    this.dialectNote,
    this.pitchRule,
    this.vowelTensionRule,
    this.modulationPattern,
    this.emphasisRule,
    this.flowRule,
    this.pacingRule,
    this.stressRule,
    this.emotionContext,
    this.stressIndex,
    this.linkingType,
    this.speedLevel,
    this.vowelChart,
    this.voicing,
    this.airflow,
    this.naturalSpeed,
    this.clearSpeed,
    this.dialectRegion,
    this.phenomenonType,
    this.spokenForm,
    this.meaningShift,
    super.targetWord,
    super.question,
    super.sentence,
  });

  /// Convenience getter returning [phoneticHint].
  String? get phonetic => phoneticHint;

  /// Creates a copy of this [AccentQuest] with updated phonological properties.
  AccentQuest copyWith({
    String? id,
    QuestType? type,
    String? instruction,
    int? difficulty,
    GameSubtype? subtype,
    InteractionType? interactionType,
    int? xpReward,
    int? coinReward,
    int? livesAllowed,
    List<String>? options,
    int? correctAnswerIndex,
    String? correctAnswer,
    String? hint,
    String? word,
    String? phoneticHint,
    String? targetWord,
    String? question,
    String? textToSpeak,
    String? prompt,
    String? sampleAnswer,
    String? explanation,
    List<String>? words,
    List<int>? intonationMap,
    List<String>? syllables,
    double? targetSpeed,
    List<int>? pitchPatterns,
    String? sentence,
    String? stressPattern,
    String? word1,
    String? word2,
    String? ipa1,
    String? ipa2,
    String? mouthPosition,
    String? slowForm,
    String? accentName,
    String? phoneticRule,
    String? dialectNote,
    String? pitchRule,
    String? vowelTensionRule,
    String? modulationPattern,
    String? emphasisRule,
    String? flowRule,
    String? pacingRule,
    String? stressRule,
    String? emotionContext,
    int? stressIndex,
    String? linkingType,
    double? speedLevel,
    Map<String, dynamic>? vowelChart,
    String? voicing,
    String? airflow,
    double? naturalSpeed,
    double? clearSpeed,
    String? dialectRegion,
    String? phenomenonType,
    String? spokenForm,
    String? meaningShift,
  }) {
    return AccentQuest(
      id: id ?? this.id,
      type: type ?? this.type,
      instruction: instruction ?? this.instruction,
      difficulty: difficulty ?? this.difficulty,
      subtype: subtype ?? this.subtype,
      interactionType: interactionType ?? this.interactionType,
      xpReward: xpReward ?? this.xpReward,
      coinReward: coinReward ?? this.coinReward,
      livesAllowed: livesAllowed ?? this.livesAllowed,
      options: options ?? this.options,
      correctAnswerIndex: correctAnswerIndex ?? this.correctAnswerIndex,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      hint: hint ?? this.hint,
      word: word ?? this.word,
      phoneticHint: phoneticHint ?? this.phoneticHint,
      targetWord: targetWord ?? this.targetWord,
      question: question ?? this.question,
      sentence: sentence ?? this.sentence,
      textToSpeak: textToSpeak ?? this.textToSpeak,
      prompt: prompt ?? this.prompt,
      sampleAnswer: sampleAnswer ?? this.sampleAnswer,
      explanation: explanation ?? this.explanation,
      words: words ?? this.words,
      intonationMap: intonationMap ?? this.intonationMap,
      syllables: syllables ?? this.syllables,
      targetSpeed: targetSpeed ?? this.targetSpeed,
      pitchPatterns: pitchPatterns ?? this.pitchPatterns,
      stressPattern: stressPattern ?? this.stressPattern,
      word1: word1 ?? this.word1,
      word2: word2 ?? this.word2,
      ipa1: ipa1 ?? this.ipa1,
      ipa2: ipa2 ?? this.ipa2,
      mouthPosition: mouthPosition ?? this.mouthPosition,
      slowForm: slowForm ?? this.slowForm,
      accentName: accentName ?? this.accentName,
      phoneticRule: phoneticRule ?? this.phoneticRule,
      dialectNote: dialectNote ?? this.dialectNote,
      pitchRule: pitchRule ?? this.pitchRule,
      vowelTensionRule: vowelTensionRule ?? this.vowelTensionRule,
      modulationPattern: modulationPattern ?? this.modulationPattern,
      emphasisRule: emphasisRule ?? this.emphasisRule,
      flowRule: flowRule ?? this.flowRule,
      pacingRule: pacingRule ?? this.pacingRule,
      stressRule: stressRule ?? this.stressRule,
      emotionContext: emotionContext ?? this.emotionContext,
      stressIndex: stressIndex ?? this.stressIndex,
      linkingType: linkingType ?? this.linkingType,
      speedLevel: speedLevel ?? this.speedLevel,
      vowelChart: vowelChart ?? this.vowelChart,
      voicing: voicing ?? this.voicing,
      airflow: airflow ?? this.airflow,
      naturalSpeed: naturalSpeed ?? this.naturalSpeed,
      clearSpeed: clearSpeed ?? this.clearSpeed,
      dialectRegion: dialectRegion ?? this.dialectRegion,
      phenomenonType: phenomenonType ?? this.phenomenonType,
      spokenForm: spokenForm ?? this.spokenForm,
      meaningShift: meaningShift ?? this.meaningShift,
    );
  }

  @override
  List<Object?> get props => [
    ...super.props,
    word,
    phoneticHint,
    targetWord,
    prompt,
    sampleAnswer,
    words,
    intonationMap,
    syllables,
    targetSpeed,
    pitchPatterns,
    stressPattern,
    word1,
    word2,
    ipa1,
    ipa2,
    mouthPosition,
    slowForm,
    accentName,
    phoneticRule,
    dialectNote,
    pitchRule,
    vowelTensionRule,
    modulationPattern,
    emphasisRule,
    flowRule,
    pacingRule,
    stressRule,
    emotionContext,
    stressIndex,
    linkingType,
    speedLevel,
    vowelChart,
    voicing,
    airflow,
    naturalSpeed,
    clearSpeed,
    dialectRegion,
    phenomenonType,
    spokenForm,
    meaningShift,
  ];
}
