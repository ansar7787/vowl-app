import '../../domain/entities/elite_mastery_quest.dart';
import '../../../../core/domain/entities/game_quest.dart';

class EliteMasteryQuestModel extends EliteMasteryQuest {
  const EliteMasteryQuestModel({
    required super.id,
    super.type,
    required super.instruction,
    required super.difficulty,
    super.subtype,
    super.interactionType,
    super.xpReward,
    super.coinReward,
    super.livesAllowed,
    super.options,
    super.correctAnswerIndex,
    super.correctAnswer,
    super.hint,
    super.textToSpeak,
    super.visualConfig,
    super.sentences,
    super.correctOrder,
    super.idiom,
    super.word,
    super.speedMultiplier,
    super.audioUrl,
    super.text,
  });

  factory EliteMasteryQuestModel.fromJson(Map<String, dynamic> json) {
    final subtype = GameSubtype.fromString(
      json['subtype'] as String?,
      fallback: GameSubtype.storyBuilder,
    );

    // Helper to safely get a string from dynamic json fields
    String? getString(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      if (value is List) return value.join(' ');
      return value.toString();
    }

    // Helper to parse lists safely and prevent TypeErrors
    List<String>? parseStringList(dynamic value) {
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      return null;
    }

    return EliteMasteryQuestModel(
      id: json['id'] as String? ?? '',
      type: subtype.category,
      instruction: json['instruction'] as String? ?? '',
      difficulty: (json['difficulty'] as num?)?.toInt() ?? 1,
      subtype: subtype,
      interactionType: InteractionType.fromString(
        json['interactionType'] as String?,
        fallback: InteractionType.choice,
      ),
      xpReward: (json['xpReward'] as num?)?.toInt() ?? 10,
      coinReward: (json['coinReward'] as num?)?.toInt() ?? 10,
      options: parseStringList(json['options']),
      correctAnswerIndex: (json['correctAnswerIndex'] as num?)?.toInt(),
      correctAnswer: getString(json['correctAnswer']),
      hint: json['hint'] as String?,
      visualConfig: json['visual_config'] != null
          ? VisualConfig.fromJson(Map<String, dynamic>.from(json['visual_config'] as Map))
          : null,
      sentences: parseStringList(json['sentences']),
      correctOrder: json['correctOrder'] != null
          ? (json['correctOrder'] as List).map((e) => int.tryParse(e.toString()) ?? 0).toList()
          : null,
      idiom: getString(json['idiom']),
      word: getString(json['word']),
      speedMultiplier: (json['speedMultiplier'] as num?)?.toDouble(),
      audioUrl: getString(json['audioUrl']),
      textToSpeak: getString(json['textToSpeak']),
      text: getString(json['text'] ?? json['textToSpeak']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'instruction': instruction,
      'difficulty': difficulty,
      'subtype': subtype?.name,
      'interactionType': interactionType.name,
      'xpReward': xpReward,
      'coinReward': coinReward,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'correctAnswer': correctAnswer,
      'hint': hint,
      'sentences': sentences,
      'correctOrder': correctOrder,
      'idiom': idiom,
      'word': word,
      'speedMultiplier': speedMultiplier,
      'audioUrl': audioUrl,
      'textToSpeak': textToSpeak,
      'text': text,
    };
  }
}
