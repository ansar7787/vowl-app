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
    super.hint = "Think carefully!",
  });

  factory KidsQuestModel.fromJson(Map<String, dynamic> json) {
    return KidsQuestModel(
      id:
          json['id'] as String? ??
          'unknown_${DateTime.now().millisecondsSinceEpoch}',
      gameType: json['gameType'] as String? ?? 'unknown',
      level: (json['level'] is int) ? (json['level'] as int) : 1,
      instruction:
          json['instruction'] as String? ?? 'Look and find the answer!',
      question: json['question'] as String?,
      correctAnswer: json['correctAnswer'] as String?,
      options: (json['options'] is List)
          ? (json['options'] as List<dynamic>).map((e) => e.toString()).toList()
          : null,
      imageUrl: json['imageUrl'] as String?,
      audioUrl: json['audioUrl'] as String?,
      metadata: (json['metadata'] is Map)
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
      painter: json['painter'] as String?,
      shader: json['shader'] as String?,
      hint: json['hint'] as String? ?? 'Think carefully!',
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
      'hint': hint,
    };
  }
}
