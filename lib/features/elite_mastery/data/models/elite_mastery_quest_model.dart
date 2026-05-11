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
    return EliteMasteryQuestModel(
      id: json['id'] as String,
      instruction: json['instruction'] as String? ?? '',
      difficulty: (json['difficulty'] as num?)?.toInt() ?? 1,
      subtype: GameSubtype.values.firstWhere(
        (e) => e.name == json['subtype'],
        orElse: () => GameSubtype.storyBuilder,
      ),
      interactionType: _parseInteractionType(json['interactionType'] as String?),
      xpReward: (json['xpReward'] as num?)?.toInt() ?? 10,
      coinReward: (json['coinReward'] as num?)?.toInt() ?? 10,
      options: (json['options'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      correctAnswerIndex: (json['correctAnswerIndex'] as num?)?.toInt(),
      correctAnswer: json['correctAnswer'] as String?,
      hint: json['hint'] as String?,
      visualConfig: json['visual_config'] != null 
          ? VisualConfig.fromJson(json['visual_config'] as Map<String, dynamic>)
          : null,
      sentences: (json['sentences'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      correctOrder: (json['correctOrder'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList(),
      idiom: json['idiom'] as String?,
      word: json['word'] as String?,
      speedMultiplier: (json['speedMultiplier'] as num?)?.toDouble(),
      audioUrl: json['audioUrl'] as String?,
      textToSpeak: json['textToSpeak'] as String?,
      text: json['text'] as String? ?? json['textToSpeak'] as String?,
    );
  }

  static InteractionType _parseInteractionType(String? type) {
    switch (type) {
      case 'reorder': return InteractionType.reorder;
      case 'match': return InteractionType.match;
      case 'spell': return InteractionType.spell;
      case 'voice': return InteractionType.voice;
      case 'speech': return InteractionType.speech;
      case 'choice': return InteractionType.choice;
      default: return InteractionType.choice;
    }
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
