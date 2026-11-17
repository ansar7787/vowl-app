import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/core/data/models/phased_quest_model.dart';

void main() {
  group('PhasedQuestModel Parsing', () {
    test('parses TeachingCard correctly', () {
      final json = {
        'title': 'Nuance',
        'explanation': 'Big vs Large',
        'audioExample': 'audio.mp3',
        'nativeSpeakerInsight': 'Use big deal, not large deal',
      };
      final card = TeachingCard.fromJson(json);
      expect(card.title, equals('Nuance'));
      expect(card.explanation, equals('Big vs Large'));
      expect(card.audioExample, equals('audio.mp3'));
      expect(card.nativeSpeakerInsight, equals('Use big deal, not large deal'));
      expect(card.toJson(), equals(json));
    });

    test('parses PracticeExercise correctly', () {
      final json = {
        'exerciseType': 'fillGap',
        'interactionType': 'typing',
        'sentence': 'Hello, _____!',
        'correctAnswer': 'world',
        'hint': 'Planet',
        'feedbackIfWrong': 'Say world',
      };
      final exercise = PracticeExercise.fromJson(json);
      expect(exercise.exerciseType, equals('fillGap'));
      expect(exercise.interactionType, equals('typing'));
      expect(exercise.sentence, equals('Hello, _____!'));
      expect(exercise.correctAnswer, equals('world'));
      expect(exercise.hint, equals('Planet'));
    });

    test('parses PhasedQuestBatch with nested quests', () {
      final json = {
        'gameType': 'flashcards',
        'phase': 'learn',
        'batchIndex': 1,
        'levels': '1-10',
        'quests': [
          {
            'id': 'VOC_FLASHCARDS_L1_LEARN',
            'level': 1,
            'word': 'HELLO',
            'definition': 'Greeting',
            'teachingCards': [
              {
                'title': 'Greeting Tip',
                'explanation': 'Say hello when you meet someone.',
              }
            ],
            'exercises': [
              {
                'exerciseType': 'contextPick',
                'interactionType': 'choice',
                'options': ['A', 'B'],
                'correctAnswer': 1,
              }
            ]
          }
        ]
      };

      final batch = PhasedQuestBatch.fromJson(json);
      expect(batch.gameType, equals('flashcards'));
      expect(batch.phase, equals('learn'));
      expect(batch.batchIndex, equals(1));
      expect(batch.quests.length, equals(1));

      final quest = batch.quests.first;
      expect(quest.id, equals('VOC_FLASHCARDS_L1_LEARN'));
      expect(quest.word, equals('HELLO'));
      expect(quest.teachingCards.length, equals(1));
      expect(quest.exercises.length, equals(1));
      expect(quest.exercises.first.correctAnswerIndex, equals(1));
    });
  });
}
