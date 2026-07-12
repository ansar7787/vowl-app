import 'package:equatable/equatable.dart';

class KidsQuest extends Equatable {
  final String id;
  final String gameType; // e.g., 'alphabet', 'colors'
  final int level;
  final String instruction;
  final String? question;
  final String? correctAnswer;
  final List<String>? options;
  final String? imageUrl;
  final String? audioUrl;
  final Map<String, dynamic>? metadata;
  final String? painter;
  final String? shader;
  final String? emoji;
  final String hint;
  final String? explanation;

  const KidsQuest({
    required this.id,
    required this.gameType,
    required this.level,
    required this.instruction,
    this.question,
    this.correctAnswer,
    this.options,
    this.imageUrl,
    this.audioUrl,
    this.metadata,
    this.painter,
    this.shader,
    this.emoji,
    this.hint = "Think carefully!",
    this.explanation,
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
    imageUrl,
    audioUrl,
    metadata,
    painter,
    shader,
    emoji,
    hint,
    explanation,
  ];

  KidsQuest copyWith({
    String? id,
    String? gameType,
    int? level,
    String? instruction,
    String? question,
    String? correctAnswer,
    List<String>? options,
    String? imageUrl,
    String? audioUrl,
    Map<String, dynamic>? metadata,
    String? painter,
    String? shader,
    String? emoji,
    String? hint,
    String? explanation,
  }) {
    return KidsQuest(
      id: id ?? this.id,
      gameType: gameType ?? this.gameType,
      level: level ?? this.level,
      instruction: instruction ?? this.instruction,
      question: question ?? this.question,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      options: options ?? this.options,
      imageUrl: imageUrl ?? this.imageUrl,
      audioUrl: audioUrl ?? this.audioUrl,
      metadata: metadata ?? this.metadata,
      painter: painter ?? this.painter,
      shader: shader ?? this.shader,
      emoji: emoji ?? this.emoji,
      hint: hint ?? this.hint,
      explanation: explanation ?? this.explanation,
    );
  }
}
