import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/listening/data/models/listening_quest_model.dart';
import 'package:vowl/features/listening/domain/entities/listening_quest.dart';

void main() {
  const tId = 'listening_test_id';

  group('ListeningQuestModel', () {
    test('should be a subclass of ListeningQuest entity', () {
      const tModel = ListeningQuestModel(
        id: tId,
        instruction: 'i',
        difficulty: 1,
      );
      expect(tModel, isA<ListeningQuest>());
    });

    test('fromJson should correctly map audioUrl and transcript', () {
      final Map<String, dynamic> jsonMap = {
        'instruction': 'Listen',
        'difficulty': 1,
        'subtype': 'audioSentenceOrder',
        'audioUrl': 'http://test.com/audio.mp3',
        'transcript': 'Test transcript',
      };

      final result = ListeningQuestModel.fromJson(jsonMap, tId);

      expect(result.audioUrl, 'http://test.com/audio.mp3');
      expect(result.transcript, 'Test transcript');
    });
  });
}
