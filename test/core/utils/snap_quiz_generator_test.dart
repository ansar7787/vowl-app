import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/core/utils/snap_quiz_generator.dart';

void main() {
  group('SnapQuizGenerator Tests', () {
    test('generate3QuestionLevel produces exactly 3 GameQuest objects', () {
      final quests = SnapQuizGenerator.generate3QuestionLevel(
        targetWord: 'Laptop',
        definition: 'A portable computer small enough to use on your lap.',
        exampleSentence: 'She typed the report on her new laptop.',
      );

      expect(quests.length, equals(3));

      // Strictly honors 3-question level architecture & 10-coin economy
      for (final q in quests) {
        expect(q.coinReward, equals(10));
        expect(q.xpReward, equals(10));
        expect(q.livesAllowed, equals(3));
        expect(q.options, isNotNull);
        expect(q.options!.length, greaterThanOrEqualTo(3));
        expect(q.correctAnswerIndex, isNotNull);
        expect(q.correctAnswerIndex! >= 0 && q.correctAnswerIndex! < q.options!.length, isTrue);
      }
    });

    test('Question 1 tests word recognition & definition', () {
      const def = 'A way out of a building or room.';
      final quests = SnapQuizGenerator.generate3QuestionLevel(
        targetWord: 'Exit',
        definition: def,
      );

      final q1 = quests[0];
      expect(q1.targetWord, equals('Exit'));
      expect(q1.correctAnswer, equals(def));
      expect(q1.options![q1.correctAnswerIndex!], equals(def));
    });

    test('Question 2 tests phonetics and speech verification', () {
      final quests = SnapQuizGenerator.generate3QuestionLevel(
        targetWord: 'Emergency',
        ipa: '/ɪˈmɜː.dʒən.si/',
      );

      final q2 = quests[1];
      expect(q2.targetWord, equals('Emergency'));
      expect(q2.textToSpeak, equals('Emergency'));
      expect(q2.explanation, contains('/ɪˈmɜː.dʒən.si/'));
    });

    test('Question 3 tests sentence context cloze placement', () {
      final quests = SnapQuizGenerator.generate3QuestionLevel(
        targetWord: 'Coffee',
        exampleSentence: 'I drink hot coffee every morning.',
      );

      final q3 = quests[2];
      expect(q3.targetWord, equals('Coffee'));
      expect(q3.correctAnswer, equals('Coffee'));
      expect(q3.sentence, contains('______'));
      expect(q3.sentence, isNot(contains('coffee')));
      expect(q3.options![q3.correctAnswerIndex!], equals('Coffee'));
    });
  });
}
