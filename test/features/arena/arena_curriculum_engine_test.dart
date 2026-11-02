import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/core/data/services/asset_quest_service.dart';
import 'package:vowl/features/arena/data/services/arena_curriculum_engine.dart';
import 'package:vowl/features/arena/domain/entities/arena_duel_session.dart';

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

    test('resolveDiscipline maps all curriculum game types correctly', () {
      expect(ArenaCurriculumEngine.resolveDiscipline('word_clash'), 'word_clash');
      expect(ArenaCurriculumEngine.resolveDiscipline('synonymSearch'), 'word_clash');
      expect(ArenaCurriculumEngine.resolveDiscipline('antonymSearch'), 'word_clash');

      expect(ArenaCurriculumEngine.resolveDiscipline('phrase_duel'), 'phrase_duel');
      expect(ArenaCurriculumEngine.resolveDiscipline('collocations'), 'phrase_duel');
      expect(ArenaCurriculumEngine.resolveDiscipline('idioms'), 'phrase_duel');
      expect(ArenaCurriculumEngine.resolveDiscipline('phrasalVerbs'), 'phrase_duel');

      expect(ArenaCurriculumEngine.resolveDiscipline('sentence_strike'), 'sentence_strike');
      expect(ArenaCurriculumEngine.resolveDiscipline('academicWord'), 'sentence_strike');

      expect(ArenaCurriculumEngine.resolveDiscipline('context_blitz'), 'context_blitz');
      expect(ArenaCurriculumEngine.resolveDiscipline('contextClues'), 'context_blitz');
    });

    test('ArenaQuestion serializes and deserializes discipline accurately', () {
      final question = ArenaQuestion(
        question: 'What is the closest synonym for "Resilient"?',
        options: ['Fragile', 'Enduring', 'Hesitant', 'Trivial'],
        correctIndex: 1,
        explanation: 'Resilient means durable.',
        discipline: 'word_clash',
      );

      final map = question.toMap();
      expect(map['discipline'], 'word_clash');

      final reconstructed = ArenaQuestion.fromMap(map);
      expect(reconstructed.discipline, 'word_clash');
      expect(reconstructed.question, question.question);
      expect(reconstructed.options, question.options);
      expect(reconstructed.correctIndex, question.correctIndex);
      expect(reconstructed.explanation, question.explanation);
    });
  });
}
