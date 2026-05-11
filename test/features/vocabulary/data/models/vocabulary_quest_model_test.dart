import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/features/vocabulary/data/models/vocabulary_quest_model.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';

void main() {
  const tId = 'test_id';
  final tVocabularyQuestModel = VocabularyQuestModel(
    id: tId,
    instruction: 'Select the synonym',
    difficulty: 1,
    subtype: GameSubtype.flashcards,
    word: 'ubiquitous',
    definition: 'present, appearing, or found everywhere',
    options: ['everywhere', 'rare', 'hidden', 'small'],
    correctAnswerIndex: 0,
  );

  group('VocabularyQuestModel', () {
    test('should be a subclass of VocabularyQuest entity', () {
      expect(tVocabularyQuestModel, isA<VocabularyQuest>());
    });

    test('fromJson should return a valid model from JSON', () {
      // Arrange
      final Map<String, dynamic> jsonMap = {
        'instruction': 'Select the synonym',
        'difficulty': 1,
        'subtype': 'flashcards',
        'word': 'ubiquitous',
        'definition': 'present, appearing, or found everywhere',
        'options': ['everywhere', 'rare', 'hidden', 'small'],
        'correctAnswerIndex': 0,
      };

      // Act
      final result = VocabularyQuestModel.fromJson(jsonMap, tId);

      // Assert
      // Note: correct index might change due to shuffle in fromJson, 
      // but we can check other properties.
      expect(result.id, tId);
      expect(result.word, 'ubiquitous');
      expect(result.subtype, GameSubtype.flashcards);
      expect(result.options!.contains('everywhere'), true);
    });

    test('toMap should return a JSON map containing the proper data', () {
      // Act
      final result = tVocabularyQuestModel.toMap();

      // Assert
      expect(result['word'], 'ubiquitous');
      expect(result['subtype'], 'flashcards');
      expect(result['instruction'], 'Select the synonym');
    });
  });
}
