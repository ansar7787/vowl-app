import 'package:vowl/features/kids_zone/domain/entities/kids_quest.dart';

class KidsQuestModel extends KidsQuest {
  const KidsQuestModel({
    required super.id,
    required super.gameType,
    required super.level,
    required super.instruction,
    super.question,
    super.correctAnswer,
    super.options,
    super.imageUrl,
    super.audioUrl,
    super.metadata,
    super.painter,
    super.shader,
    super.emoji,
    super.hint = "Think carefully!",
    super.explanation,
    super.wordExample,
    super.wordEmoji,
    super.capitalLetter,
    super.phonetic,
    super.funFact,
    super.animalSound,
  });

  factory KidsQuestModel.fromJson(Map<String, dynamic> json) {
    // Helper to parse lists safely and prevent TypeErrors
    List<String>? parseStringList(dynamic value) {
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      return null;
    }

    return KidsQuestModel(
      id: json['id'] as String? ?? '',
      gameType: json['gameType'] as String? ?? 'unknown',
      level: (json['level'] as num?)?.toInt() ?? 1,
      instruction: json['instruction'] as String? ?? 'Look and find the answer!',
      question: json['question'] as String?,
      correctAnswer: json['correctAnswer'] as String?,
      options: parseStringList(json['options']),
      imageUrl: json['imageUrl'] as String?,
      audioUrl: json['audioUrl'] as String?,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
      painter: json['painter'] as String?,
      shader: json['shader'] as String?,
      emoji: json['emoji'] as String?,
      hint: json['hint'] as String? ?? 'Think carefully!',
      explanation: json['explanation'] as String?,
      wordExample: json['wordExample'] as String?,
      wordEmoji: json['wordEmoji'] as String?,
      capitalLetter: json['capitalLetter'] as String?,
      phonetic: json['phonetic'] as String?,
      funFact: json['funFact'] as String?,
      animalSound: json['animalSound'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gameType': gameType,
      'level': level,
      'instruction': instruction,
      'question': question,
      'correctAnswer': correctAnswer,
      'options': options,
      'imageUrl': imageUrl,
      'audioUrl': audioUrl,
      'metadata': metadata,
      'painter': painter,
      'shader': shader,
      'emoji': emoji,
      'hint': hint,
      'explanation': explanation,
      'wordExample': wordExample,
      'wordEmoji': wordEmoji,
      'capitalLetter': capitalLetter,
      'phonetic': phonetic,
      'funFact': funFact,
      'animalSound': animalSound,
    };
  }
}
