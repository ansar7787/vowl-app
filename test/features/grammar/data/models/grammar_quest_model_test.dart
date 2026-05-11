import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/features/grammar/data/models/grammar_quest_model.dart';
import 'package:vowl/features/grammar/domain/entities/grammar_quest.dart';

void main() {
  const tId = 'grammar_test_id';

  group('GrammarQuestModel', () {
    test('should be a subclass of GrammarQuest entity', () {
      const tModel = GrammarQuestModel(
        id: tId,
        instruction: 'i',
        difficulty: 1,
      );
      expect(tModel, isA<GrammarQuest>());
    });

    test('fromJson should return a valid model', () {
      final Map<String, dynamic> jsonMap = {
        'instruction': 'Fix the sentence',
        'difficulty': 2,
        'subtype': 'sentenceCorrection',
        'correctAnswer': 'Correct',
      };

      final result = GrammarQuestModel.fromJson(jsonMap, tId);

      expect(result.id, tId);
      expect(result.subtype, GameSubtype.sentenceCorrection);
    });
  });
}
