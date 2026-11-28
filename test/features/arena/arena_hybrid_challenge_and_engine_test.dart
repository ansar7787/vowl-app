import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/arena/data/services/arena_curriculum_engine.dart';
import 'package:vowl/features/arena/domain/entities/arena_challenge.dart';
import 'package:vowl/features/arena/domain/entities/arena_duel_session.dart';
import 'package:vowl/features/arena/domain/entities/arena_match_record.dart';
import 'package:vowl/features/arena/domain/entities/arena_rank.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ArenaChallenge Serialization & Backward/Forward Compat', () {
    test('serializes and deserializes all 7 v1 mechanic types cleanly', () {
      final samples = <ArenaChallenge>[
        const ArenaChallenge(
          mechanic: ArenaMechanicType.wordSnap,
          id: 'WS_1',
          prompt: 'Unscramble: very large',
          correctAnswer: 'enormous',
          scrambledLetters: 'ONURMOSE',
          hint: '8 letters, starts with E',
          explanation: 'Enormous means very large.',
          difficulty: 'easy',
        ),
        const ArenaChallenge(
          mechanic: ArenaMechanicType.typeDuel,
          id: 'TD_1',
          prompt: 'Person who designs buildings',
          correctAnswer: 'architect',
          acceptedSpellings: ['architect'],
          letterCount: 9,
          explanation: 'Plans structures.',
          difficulty: 'medium',
        ),
        const ArenaChallenge(
          mechanic: ArenaMechanicType.rapidJudge,
          id: 'RJ_1',
          prompt: 'Is each sentence correct?',
          correctAnswer: '',
          explanation: 'Grammar check.',
          difficulty: 'medium',
          rapidItems: [
            RapidJudgeItem(
              sentence: "She don't like coffee.",
              isCorrect: false,
              correction: "She doesn't like coffee.",
              rule: "Requires doesn't.",
            ),
            RapidJudgeItem(
              sentence: 'They are playing.',
              isCorrect: true,
              rule: 'Present continuous.',
            ),
          ],
        ),
        const ArenaChallenge(
          mechanic: ArenaMechanicType.sentenceBuild,
          id: 'SB_1',
          prompt: 'Arrange the words',
          correctAnswer: 'She reads books daily',
          shuffledWords: ['daily', 'She', 'books', 'reads'],
          wordCount: 4,
          explanation: 'SVO order.',
          difficulty: 'easy',
        ),
        const ArenaChallenge(
          mechanic: ArenaMechanicType.spotError,
          id: 'SE_1',
          prompt: 'Tap the wrong word',
          correctAnswer: "they're",
          sentenceTokens: ['Submit', "they're", 'work'],
          errorTokenIndex: 1,
          errorToken: "they're",
          correctedToken: 'their',
          explanation: 'Possessive their.',
          difficulty: 'medium',
        ),
        const ArenaChallenge(
          mechanic: ArenaMechanicType.mcq,
          id: 'MCQ_1',
          prompt: 'Closest synonym to "enormous"?',
          correctAnswer: 'Huge',
          options: ['Tiny', 'Huge', 'Quiet', 'Narrow'],
          correctIndex: 1,
          discipline: 'word_clash',
          explanation: 'Huge = enormous.',
          difficulty: 'hard',
        ),
        const ArenaChallenge(
          mechanic: ArenaMechanicType.speedSpell,
          id: 'SP_1',
          prompt: 'Fill blanks',
          correctAnswer: 'enormous',
          displayMask: 'e_o_m_us',
          missingLetters: ['n', 'r', 'o'],
          missingPositions: [1, 3, 5],
          explanation: 'e-n-o-r-m-o-u-s',
          difficulty: 'hard',
        ),
      ];

      for (final c in samples) {
        final map = c.toMap();
        final decoded = ArenaChallenge.tryFromMap(map);
        expect(decoded, isNotNull);
        expect(decoded!.mechanic, c.mechanic);
        expect(decoded.id, c.id);
        expect(decoded.prompt, c.prompt);
        expect(decoded.correctAnswer, c.correctAnswer);
        expect(decoded.explanation, c.explanation);
      }
    });

    test('fromLegacyQuestion converts ArenaQuestion to MCQ ArenaChallenge', () {
      const legacy = ArenaQuestion(
        question: 'Opposite of ancient?',
        options: ['Historic', 'Old', 'Fragile', 'Modern'],
        correctIndex: 3,
        explanation: 'Modern is the opposite of ancient.',
        discipline: 'word_clash',
        difficulty: 'medium',
      );

      final challenge = ArenaChallenge.fromLegacyQuestion(legacy);
      expect(challenge.mechanic, ArenaMechanicType.mcq);
      expect(challenge.prompt, legacy.question);
      expect(challenge.options, legacy.options);
      expect(challenge.correctIndex, 3);
      expect(challenge.correctAnswer, 'Modern');
      expect(challenge.discipline, 'word_clash');

      final roundTrip = challenge.toLegacyQuestion();
      expect(roundTrip.question, legacy.question);
      expect(roundTrip.correctIndex, legacy.correctIndex);
    });

    test('tryFromMap handles legacy MCQ map and unknown future mechanic gracefully', () {
      // Unknown mechanic -> returns null instead of throwing
      final unknownResult = ArenaChallenge.tryFromMap({
        'mechanic': 'future_hologram_duel_v9',
        'id': 'FUTURE_1',
        'prompt': 'Test',
      });
      expect(unknownResult, isNull);

      // Legacy map without 'mechanic' key -> converts to MCQ
      final legacyResult = ArenaChallenge.tryFromMap({
        'question': 'Choose one',
        'options': ['A', 'B'],
        'correctIndex': 1,
        'explanation': 'B is right.',
      });
      expect(legacyResult, isNotNull);
      expect(legacyResult!.mechanic, ArenaMechanicType.mcq);
      expect(legacyResult.correctAnswer, 'B');
    });
  });

  group('ArenaCurriculumEngine v2 Hybrid Pentathlon', () {
    test('generateHybridPentathlon produces 7 challenges in exact mechanic order', () async {
      final challenges = await ArenaCurriculumEngine.generateHybridPentathlon(
        seed: 2026,
      );
      expect(challenges.length, 7);
      expect(
        challenges.map((c) => c.mechanic).toList(),
        [
          ArenaMechanicType.wordSnap,
          ArenaMechanicType.typeDuel,
          ArenaMechanicType.rapidJudge,
          ArenaMechanicType.sentenceBuild,
          ArenaMechanicType.spotError,
          ArenaMechanicType.mcq,
          ArenaMechanicType.speedSpell,
        ],
      );
    });

    test('generateHybridPentathlon is deterministic for identical seed', () async {
      final runA = await ArenaCurriculumEngine.generateHybridPentathlon(
        seed: 98765,
      );
      final runB = await ArenaCurriculumEngine.generateHybridPentathlon(
        seed: 98765,
      );
      expect(runA.length, 7);
      expect(runB.length, 7);
      for (var i = 0; i < 7; i++) {
        expect(runA[i].id, runB[i].id);
        expect(runA[i].mechanic, runB[i].mechanic);
        expect(runA[i].correctAnswer, runB[i].correctAnswer);
      }
    });

    test('all 6 dedicated JSON batch_1 files parse with valid schemas & counts', () {
      final expectations = <ArenaMechanicType, int>{
        ArenaMechanicType.wordSnap: 20,
        ArenaMechanicType.typeDuel: 20,
        ArenaMechanicType.rapidJudge: 10,
        ArenaMechanicType.sentenceBuild: 20,
        ArenaMechanicType.spotError: 20,
        ArenaMechanicType.speedSpell: 20,
      };

      for (final entry in expectations.entries) {
        final folder = ArenaCurriculumEngine.folderForMechanic(entry.key)!;
        final file = File(
          'assets/curriculum/arena/$folder/${folder}_batch_1.json',
        );
        expect(file.existsSync(), isTrue, reason: '${file.path} should exist');

        final rawJson = file.readAsStringSync();
        final parsed = ArenaCurriculumEngine.parseMechanicBatchJson(
          rawJson,
          entry.key,
        );
        expect(parsed.length, entry.value, reason: 'Batch 1 count for $folder');

        // Verify cloned batch_2 and batch_20 files exist and are valid JSON
        for (final batchNum in [2, 20]) {
          final cloneFile = File(
            'assets/curriculum/arena/$folder/${folder}_batch_$batchNum.json',
          );
          expect(cloneFile.existsSync(), isTrue);
          final decoded = jsonDecode(cloneFile.readAsStringSync());
          expect(decoded['mechanic'], folder);
        }
      }
    });
  });

  group('ArenaRank & ArenaMatchRecord Entities', () {
    test('ArenaRank maps duelWins thresholds accurately', () {
      expect(0.arenaRank, ArenaRank.recruit);
      expect(4.arenaRank, ArenaRank.recruit);
      expect(5.arenaRank, ArenaRank.contender);
      expect(14.arenaRank, ArenaRank.contender);
      expect(15.arenaRank, ArenaRank.gladiator);
      expect(29.arenaRank, ArenaRank.gladiator);
      expect(30.arenaRank, ArenaRank.champion);
      expect(49.arenaRank, ArenaRank.champion);
      expect(50.arenaRank, ArenaRank.legend);
      expect(120.arenaRank, ArenaRank.legend);
      expect(ArenaRank.legend.nextRank, isNull);
      expect(ArenaRank.contender.progressToNext(10), closeTo(0.5, 0.01));
    });

    test('ArenaMatchRecord serializes & deserializes with round breakdowns', () {
      final now = DateTime(2026, 11, 28, 10, 0);
      final record = ArenaMatchRecord(
        id: 'MATCH_1',
        roomCode: 'VOWL-DUEL-111111',
        opponentName: 'RivalPro',
        opponentRank: ArenaRank.gladiator,
        isGhostRival: false,
        result: 'win',
        myScore: 480,
        rivalScore: 390,
        myCorrectCount: 6,
        rivalCorrectCount: 5,
        myTotalTimeMs: 42000,
        rivalTotalTimeMs: 51000,
        rounds: const [
          ArenaRoundResult(
            mechanic: ArenaMechanicType.wordSnap,
            isCorrect: true,
            myTimeMs: 4500,
            myPoints: 70,
            prompt: 'Very large in size',
            correctAnswer: 'enormous',
            explanation: 'Enormous means huge.',
          ),
          ArenaRoundResult(
            mechanic: ArenaMechanicType.rapidJudge,
            isCorrect: true,
            myTimeMs: 12000,
            myPoints: 50,
            rapidCorrectItems: 5,
            rapidTotalItems: 6,
          ),
        ],
        timestamp: now,
      );

      final map = record.toMap();
      final decoded = ArenaMatchRecord.fromMap(map);
      expect(decoded.id, 'MATCH_1');
      expect(decoded.opponentRank, ArenaRank.gladiator);
      expect(decoded.isWin, isTrue);
      expect(decoded.rounds.length, 2);
      expect(decoded.rounds[0].prompt, 'Very large in size');
      expect(decoded.rounds[0].correctAnswer, 'enormous');
      expect(decoded.rounds[0].explanation, 'Enormous means huge.');
      expect(decoded.rounds[1].rapidCorrectItems, 5);
    });

    test('generateHybridPentathlon avoids repeating the same answer across rounds', () async {
      for (final seed in [1, 7, 42, 99, 2026]) {
        final pentathlon =
            await ArenaCurriculumEngine.generateHybridPentathlon(seed: seed);
        expect(pentathlon.length, 7);
        final answers = pentathlon
            .map((c) => c.correctAnswer.trim().toLowerCase())
            .where((a) => a.isNotEmpty)
            .toList();
        expect(answers.toSet().length, answers.length);
      }
    });
  });
}
