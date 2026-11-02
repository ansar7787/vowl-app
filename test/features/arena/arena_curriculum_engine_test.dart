import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/core/data/services/asset_quest_service.dart';
import 'package:vowl/features/arena/data/services/arena_curriculum_engine.dart';

class FakeQuestService implements QuestService {
  @override
  Future<List<Map<String, dynamic>>> getQuests(String gameType, int level) async {
    return [
      {
        'id': 'VOC_${gameType.toUpperCase()}_L${level}_Q1',
        'word': 'WORD_$gameType',
        'instruction': 'Instruction for $gameType level $level',
        'contextSentence': 'This is a sample $gameType sentence with ___ context.',
        'correctAnswer': 'OPTION_A',
        'options': ['OPTION_A', 'OPTION_B', 'OPTION_C', 'OPTION_D'],
        'explanation': 'Detailed curriculum explanation for $gameType.',
      }
    ];
  }

  @override
  Future<void> preloadBatch(String gameType, int currentLevel) async {}

  @override
  void clearCache() {}
}

void main() {
  group('ArenaCurriculumEngine', () {
    test('generates exactly 5 questions by default', () {
      final questions = ArenaCurriculumEngine.generateQuestions();
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
      final sessionA = ArenaCurriculumEngine.generateQuestions(seed: seed);
      final sessionB = ArenaCurriculumEngine.generateQuestions(seed: seed);

      expect(sessionA.length, sessionB.length);
      for (var i = 0; i < sessionA.length; i++) {
        expect(sessionA[i].question, sessionB[i].question);
        expect(sessionA[i].correctIndex, sessionB[i].correctIndex);
        expect(sessionA[i].options, sessionB[i].options);
      }
    });

    test('supports custom question count', () {
      final questions = ArenaCurriculumEngine.generateQuestions(count: 3);
      expect(questions.length, 3);
    });

    test('supports 7 distinct curriculum disciplines spanning 200 levels each', () {
      expect(ArenaCurriculumEngine.kSupportedGameTypes.length, 7);
      expect(ArenaCurriculumEngine.kSupportedGameTypes, containsAll([
        'synonymSearch',
        'antonymSearch',
        'collocations',
        'idioms',
        'academicWord',
        'contextClues',
        'phrasalVerbs',
      ]));
    });

    test('generateQuestionsAsync loads authentic curriculum quests via QuestService', () async {
      final fakeService = FakeQuestService();
      final questions = await ArenaCurriculumEngine.generateQuestionsAsync(
        count: 5,
        seed: 42,
        questService: fakeService,
      );

      expect(questions.length, 5);
      for (final q in questions) {
        expect(q.question.isNotEmpty, true);
        expect(q.options.length, 4);
        expect(q.correctIndex, inInclusiveRange(0, 3));
        expect(q.options[q.correctIndex].toLowerCase(), 'option_a');
        expect(q.explanation, contains('Detailed curriculum explanation'));
      }
    });

    test('generateQuestionsAsync gracefully falls back when QuestService fails or is null', () async {
      final questions = await ArenaCurriculumEngine.generateQuestionsAsync(
        count: 5,
        seed: 99,
        questService: null,
      );

      expect(questions.length, 5);
      for (final q in questions) {
        expect(q.question.isNotEmpty, true);
        expect(q.options.length, 4);
      }
    });
  });
}
