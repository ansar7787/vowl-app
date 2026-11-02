import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/arena/data/utils/arena_question_generator.dart';

void main() {
  group('ArenaQuestionGenerator', () {
    test('generates exactly 5 questions by default', () {
      final questions = ArenaQuestionGenerator.generateQuestions();
      expect(questions.length, 5);
      for (final q in questions) {
        expect(q.question.isNotEmpty, true);
        expect(q.options.length, 4);
        expect(q.correctIndex, inInclusiveRange(0, 3));
        expect(q.explanation.isNotEmpty, true);
      }
    });

    test('generates identical questions when given the same seed (deterministic matchmaking)', () {
      const seed = 12345;
      final sessionA = ArenaQuestionGenerator.generateQuestions(seed: seed);
      final sessionB = ArenaQuestionGenerator.generateQuestions(seed: seed);

      expect(sessionA.length, sessionB.length);
      for (var i = 0; i < sessionA.length; i++) {
        expect(sessionA[i].question, sessionB[i].question);
        expect(sessionA[i].correctIndex, sessionB[i].correctIndex);
        expect(sessionA[i].options, sessionB[i].options);
      }
    });

    test('supports custom question count', () {
      final questions = ArenaQuestionGenerator.generateQuestions(count: 3);
      expect(questions.length, 3);
    });
  });
}

