import 'package:equatable/equatable.dart';

/// Domain entity representing an interactive pedagogical quest in Kids Zone.
class KidsQuest extends Equatable {
  /// Unique identifier of the quest.
  final String id;

  /// Game subtype or curriculum domain (e.g., 'alphabet', 'colors').
  final String gameType;

  /// Progression level number.
  final int level;

  /// Primary instruction text presented to the child.
  final String instruction;

  /// Optional prompt or question text.
  final String? question;

  /// Correct target answer or identifier.
  final String? correctAnswer;

  /// List of candidate answer choices.
  final List<String>? options;

  /// Dynamic pedagogical metadata parameters.
  final Map<String, dynamic>? metadata;

  /// Custom painter identifier for visual asset generation.
  final String? painter;

  /// Custom shader identifier for animation effects.
  final String? shader;

  /// Associated emoji representation.
  final String? emoji;

  /// Helpful hint text guiding the child.
  final String hint;

  /// Educational explanation or learning takeaway.
  final String? explanation;

  /// Example vocabulary word associated with the lesson.
  final String? wordExample;

  /// Emoji representation corresponding to [wordExample].
  final String? wordEmoji;

  /// Capital letter representation for alphabet exercises.
  final String? capitalLetter;

  /// Phonetic pronunciation guide.
  final String? phonetic;

  /// Fun educational trivia fact.
  final String? funFact;

  /// Audio identifier or sound effect for animal games.
  final String? animalSound;

  /// Creates a [KidsQuest] domain entity.
  const KidsQuest({
    required this.id,
    required this.gameType,
    required this.level,
    required this.instruction,
    this.question,
    this.correctAnswer,
    this.options,
    this.metadata,
    this.painter,
    this.shader,
    this.emoji,
    this.hint = "Think carefully!",
    this.explanation,
    this.wordExample,
    this.wordEmoji,
    this.capitalLetter,
    this.phonetic,
    this.funFact,
    this.animalSound,
  });

  @override
  List<Object?> get props => [
    id,
    gameType,
    level,
    instruction,
    question,
    correctAnswer,
    options,
    metadata,
    painter,
    shader,
    emoji,
    hint,
    explanation,
    wordExample,
    wordEmoji,
    capitalLetter,
    phonetic,
    funFact,
    animalSound,
  ];

  /// Creates a copy of this [KidsQuest] with the given fields replaced.
  KidsQuest copyWith({
    String? id,
    String? gameType,
    int? level,
    String? instruction,
    String? question,
    String? correctAnswer,
    List<String>? options,
    Map<String, dynamic>? metadata,
    String? painter,
    String? shader,
    String? emoji,
    String? hint,
    String? explanation,
    String? wordExample,
    String? wordEmoji,
    String? capitalLetter,
    String? phonetic,
    String? funFact,
    String? animalSound,
  }) {
    return KidsQuest(
      id: id ?? this.id,
      gameType: gameType ?? this.gameType,
      level: level ?? this.level,
      instruction: instruction ?? this.instruction,
      question: question ?? this.question,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      options: options ?? this.options,
      metadata: metadata ?? this.metadata,
      painter: painter ?? this.painter,
      shader: shader ?? this.shader,
      emoji: emoji ?? this.emoji,
      hint: hint ?? this.hint,
      explanation: explanation ?? this.explanation,
      wordExample: wordExample ?? this.wordExample,
      wordEmoji: wordEmoji ?? this.wordEmoji,
      capitalLetter: capitalLetter ?? this.capitalLetter,
      phonetic: phonetic ?? this.phonetic,
      funFact: funFact ?? this.funFact,
      animalSound: animalSound ?? this.animalSound,
    );
  }
}
