import 'package:meta/meta.dart';

/// Single educational card used in the Learn phase.
@immutable
class TeachingCard {
  final String title;
  final String explanation;
  final String? audioExample;
  final String? nativeSpeakerInsight;

  const TeachingCard({
    required this.title,
    required this.explanation,
    this.audioExample,
    this.nativeSpeakerInsight,
  });

  factory TeachingCard.fromJson(Map<String, dynamic> json) => TeachingCard(
    title: json['title'] as String? ?? '',
    explanation: json['explanation'] as String? ?? '',
    audioExample: json['audioExample'] as String?,
    nativeSpeakerInsight: json['nativeSpeakerInsight'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'explanation': explanation,
    if (audioExample != null) 'audioExample': audioExample,
    if (nativeSpeakerInsight != null)
      'nativeSpeakerInsight': nativeSpeakerInsight,
  };
}

/// Single interactive exercise used in the Practice phase.
@immutable
class PracticeExercise {
  final String exerciseType;
  final String interactionType;
  final String? sentence;
  final String? question;
  final String? correctAnswer;
  final int? correctAnswerIndex;
  final List<String> options;
  final String? hint;
  final String? feedbackIfWrong;
  final List<String> feedbackPerOption;

  const PracticeExercise({
    required this.exerciseType,
    required this.interactionType,
    this.sentence,
    this.question,
    this.correctAnswer,
    this.correctAnswerIndex,
    this.options = const [],
    this.hint,
    this.feedbackIfWrong,
    this.feedbackPerOption = const [],
  });

  factory PracticeExercise.fromJson(Map<String, dynamic> json) =>
      PracticeExercise(
        exerciseType: json['exerciseType'] as String? ?? 'generic',
        interactionType: json['interactionType'] as String? ?? 'choice',
        sentence: json['sentence'] as String?,
        question: json['question'] as String?,
        correctAnswer: json['correctAnswer'] is String
            ? json['correctAnswer'] as String
            : null,
        correctAnswerIndex: json['correctAnswer'] is int
            ? json['correctAnswer'] as int
            : (json['correctAnswerIndex'] as int?),
        options:
            (json['options'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        hint: json['hint'] as String?,
        feedbackIfWrong: json['feedbackIfWrong'] as String?,
        feedbackPerOption:
            (json['feedbackPerOption'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );

  Map<String, dynamic> toJson() => {
    'exerciseType': exerciseType,
    'interactionType': interactionType,
    if (sentence != null) 'sentence': sentence,
    if (question != null) 'question': question,
    if (correctAnswer != null) 'correctAnswer': correctAnswer,
    if (correctAnswerIndex != null) 'correctAnswerIndex': correctAnswerIndex,
    if (options.isNotEmpty) 'options': options,
    if (hint != null) 'hint': hint,
    if (feedbackIfWrong != null) 'feedbackIfWrong': feedbackIfWrong,
    if (feedbackPerOption.isNotEmpty) 'feedbackPerOption': feedbackPerOption,
  };
}

/// Core phased quest representing a level or exercise set in Learn/Practice.
@immutable
class PhasedQuest {
  final String id;
  final int level;
  final String? conceptTitle;
  final String? visualAnchor;
  final String? word;
  final String? definition;
  final String? pronunciation;
  final String? example;
  final String? usageExample;
  final String? nativeTip;
  final List<String> familyWords;
  final String? commonMistake;
  final List<TeachingCard> teachingCards;
  final List<PracticeExercise> exercises;
  final Map<String, dynamic> rawExtra;

  const PhasedQuest({
    required this.id,
    required this.level,
    this.conceptTitle,
    this.visualAnchor,
    this.word,
    this.definition,
    this.pronunciation,
    this.example,
    this.usageExample,
    this.nativeTip,
    this.familyWords = const [],
    this.commonMistake,
    this.teachingCards = const [],
    this.exercises = const [],
    this.rawExtra = const {},
  });

  String? get origin => rawExtra['origin'] as String?;
  String? get topicEmoji => rawExtra['topicEmoji'] as String?;
  String? get literalVsFigurative => rawExtra['literalVsFigurative'] as String?;
  String? get contextSentence =>
      (rawExtra['contextSentence'] ?? example) as String?;
  String? get instruction => rawExtra['instruction'] as String?;
  String? get hint => rawExtra['hint'] as String?;
  List<String>? get options => (rawExtra['options'] as List<dynamic>?)
      ?.map((e) => e.toString())
      .toList();
  String? get correctAnswer => rawExtra['correctAnswer'] as String?;
  String? get explanation => rawExtra['explanation'] as String?;
  static String getCefrForLevel(int level) {
    if (level <= 40) return 'A2';
    if (level <= 80) return 'B1';
    if (level <= 120) return 'B2';
    if (level <= 160) return 'C1';
    return 'C2';
  }

  String? get cefr => rawExtra['cefr'] as String?;
  String get cefrLevel {
    final explicit = cefr;
    if (explicit != null && explicit.isNotEmpty) return explicit.toUpperCase();
    return getCefrForLevel(level);
  }

  factory PhasedQuest.fromJson(Map<String, dynamic> json) => PhasedQuest(
    id: json['id'] as String? ?? '',
    level: json['level'] as int? ?? 1,
    conceptTitle: json['conceptTitle'] as String?,
    visualAnchor: json['visualAnchor'] as String?,
    word: json['word'] as String?,
    definition: json['definition'] as String?,
    pronunciation: (json['pronunciation'] ?? json['phonetic']) as String?,
    example: (json['example'] ?? json['exampleSentence']) as String?,
    usageExample: json['usageExample'] as String?,
    nativeTip: json['nativeTip'] as String?,
    familyWords:
        (json['familyWords'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        const [],
    commonMistake: json['commonMistake'] as String?,
    teachingCards:
        (json['teachingCards'] as List<dynamic>?)
            ?.map((e) => TeachingCard.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
    exercises:
        (json['exercises'] as List<dynamic>?)
            ?.map((e) => PracticeExercise.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [],
    rawExtra: json,
  );
}

/// Batch containing a slice of phased quests (e.g. levels 1-10).
@immutable
class PhasedQuestBatch {
  final String gameType;
  final String phase;
  final int batchIndex;
  final String levels;
  final List<PhasedQuest> quests;

  const PhasedQuestBatch({
    required this.gameType,
    required this.phase,
    required this.batchIndex,
    required this.levels,
    required this.quests,
  });

  factory PhasedQuestBatch.fromJson(Map<String, dynamic> json) =>
      PhasedQuestBatch(
        gameType: json['gameType'] as String? ?? '',
        phase: json['phase'] as String? ?? 'learn',
        batchIndex: json['batchIndex'] as int? ?? 1,
        levels: json['levels'] as String? ?? '1-10',
        quests:
            (json['quests'] as List<dynamic>?)
                ?.map((e) => PhasedQuest.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}
