import '../../domain/entities/grammar_quest.dart';
import '../../../../core/domain/entities/game_quest.dart';

class GrammarQuestModel extends GrammarQuest {
  const GrammarQuestModel({
    required super.id,
    super.type,
    required super.instruction,
    required super.difficulty,
    super.subtype,
    super.interactionType = InteractionType.choice,
    super.xpReward,
    super.coinReward,
    super.livesAllowed,
    super.options,
    super.correctAnswerIndex,
    super.correctAnswer,
    super.hint,
    super.sentence,
    super.verb,
    super.word,
    super.targetTense,
    super.secondarySentence,
    super.firstClause,
    super.secondClause,
    super.connectorToUse,
    super.sentenceWithBlank,
    super.articleToInsert,
    super.targetWord,
    super.passage,
    super.passiveSentence,
    super.activeSentence,
  });

  factory GrammarQuestModel.fromJson(Map<String, dynamic> map, String id) {
    final subtype = GameSubtype.values.firstWhere(
      (s) => s.name == map['subtype'],
      orElse: () => GameSubtype.grammarQuest,
    );
    return GrammarQuestModel(
      id: id,
      type: subtype.category,
      subtype: subtype,
      instruction: map['instruction'] ?? 'Solve the grammar puzzle.',
      difficulty: map['difficulty'] ?? 1,
      interactionType: InteractionType.values.firstWhere(
        (i) => i.name == (map['interactionType'] ?? 'choice'),
        orElse: () => InteractionType.choice,
      ),
      xpReward: map['xpReward'] ?? 10,
      coinReward: map['coinReward'] ?? 5,
      livesAllowed: map['livesAllowed'] ?? 3,
      options: map['options'] != null
          ? List<String>.from(map['options'])
          : null,
      correctAnswerIndex: map['correctAnswerIndex'],
      correctAnswer: map['correctAnswer'],
      hint: map['hint'],
      sentence: map['sentence'] ?? map['question'],
      verb: map['verb'],
      word: map['word'],
      targetTense: map['targetTense'],
      secondarySentence: map['secondarySentence'],
      firstClause: map['firstClause'],
      secondClause: map['secondClause'],
      connectorToUse: map['connectorToUse'],
      sentenceWithBlank: map['sentenceWithBlank'],
      articleToInsert: map['articleToInsert'],
      targetWord: map['targetWord'],
      passage: map['passage'],
      passiveSentence: map['passiveSentence'],
      activeSentence: map['activeSentence'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'instruction': instruction,
      'difficulty': difficulty,
      'subtype': subtype?.name,
      'interactionType': interactionType.name,
      'xpReward': xpReward,
      'coinReward': coinReward,
      'livesAllowed': livesAllowed,
      'options': options,
      'correctAnswerIndex': correctAnswerIndex,
      'correctAnswer': correctAnswer,
      'hint': hint,
      'sentence': sentence,
      'verb': verb,
      'word': word,
      'targetTense': targetTense,
      'secondarySentence': secondarySentence,
      'firstClause': firstClause,
      'secondClause': secondClause,
      'connectorToUse': connectorToUse,
      'sentenceWithBlank': sentenceWithBlank,
      'articleToInsert': articleToInsert,
      'targetWord': targetWord,
      'passage': passage,
      'passiveSentence': passiveSentence,
      'activeSentence': activeSentence,
    };
  }
}
