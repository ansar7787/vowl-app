import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/features/roleplay/data/models/roleplay_quest_model.dart';
import 'package:vowl/features/roleplay/domain/entities/roleplay_quest.dart';

void main() {
  const tId = 'roleplay_test_id';

  group('RoleplayQuestModel', () {
    test('should be a subclass of RoleplayQuest entity', () {
      final tModel = RoleplayQuestModel(
        id: tId,
        instruction: 'Complete the scene',
        difficulty: 1,
        subtype: GameSubtype.socialSpark,
      );
      expect(tModel, isA<RoleplayQuest>());
    });

    test('fromJson should correctly map shuffledWords', () {
      // Arrange
      final Map<String, dynamic> jsonMap = {
        'instruction': 'Reorder the response',
        'difficulty': 1,
        'subtype': 'socialSpark',
        'shuffledWords': ['Hello', 'how', 'are', 'you'],
        'correctAnswer': 'Hello how are you',
      };

      // Act
      final result = RoleplayQuestModel.fromJson(jsonMap, tId);

      // Assert
      expect(result.shuffledWords, ['Hello', 'how', 'are', 'you']);
      expect(result.subtype, GameSubtype.socialSpark);
    });

    test('fromJson should default shuffledWords to keywords if absent', () {
      // Arrange
      final Map<String, dynamic> jsonMap = {
        'instruction': 'Reorder',
        'difficulty': 1,
        'subtype': 'socialSpark',
        'keywords': ['word1', 'word2'],
      };

      // Act
      final result = RoleplayQuestModel.fromJson(jsonMap, tId);

      // Assert
      expect(result.shuffledWords, ['word1', 'word2']);
    });
  });
}
