import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/features/vocabulary/data/models/vocabulary_quest_model.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/features/vocabulary/synonym_search/data/datasources/synonym_phase_local_data_source.dart';
import 'package:vowl/features/vocabulary/synonym_search/data/datasources/synonym_weak_words_store.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/controllers/synonym_learn_controller.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/controllers/synonym_mastery_controller.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/controllers/synonym_practice_controller.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/models/synonym_phase_models.dart';

class _MapAssetBundle extends CachingAssetBundle {
  final Map<String, String> files;

  _MapAssetBundle(this.files);

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final val = files[key];
    if (val == null) {
      throw StateError('Missing asset key: $key');
    }
    return val;
  }

  @override
  Future<ByteData> load(String key) async {
    final str = await loadString(key);
    return ByteData.sublistView(Uint8List.fromList(utf8.encode(str)));
  }
}

void main() {
  group('Synonym Search Curriculum JSONs & Phase Models', () {
    String expectedCefrForBatch(int batch) {
      if (batch <= 4) return 'A2';
      if (batch <= 8) return 'B1';
      if (batch <= 12) return 'B2';
      if (batch <= 16) return 'C1';
      return 'C2';
    }

    int expectedDifficultyForBatch(int batch) {
      if (batch <= 4) return 1;
      if (batch <= 8) return 2;
      if (batch <= 12) return 3;
      if (batch <= 16) return 4;
      return 5;
    }

    test(
      'all 60 Learn, Practice, Mastery JSONs exist, decode, and match CEFR bands',
      () {
        for (int batch = 1; batch <= 20; batch++) {
          final start = (batch - 1) * 10 + 1;
          final end = batch * 10;
          final expectedCefr = expectedCefrForBatch(batch);
          final expectedDiff = expectedDifficultyForBatch(batch);

          // Learn JSON
          final learnFile = File(
            'assets/curriculum/vocabulary/synonymSearch_learn_${start}_$end.json',
          );
          expect(learnFile.existsSync(), isTrue, reason: learnFile.path);
          final learnRaw = learnFile.readAsStringSync();
          expect(
            learnRaw.contains('PLACEHOLDER'),
            isFalse,
            reason: learnFile.path,
          );
          final learnMap = jsonDecode(learnRaw) as Map<String, dynamic>;
          expect(learnMap['cefr'], expectedCefr);
          expect(learnMap['difficulty'], expectedDiff);
          final learnBatch = SynonymLearnBatch.fromJson(learnMap);
          expect(learnBatch.quests.length, 30);
          for (final item in learnBatch.quests) {
            expect(item.cefr, expectedCefr);
            expect(item.difficulty, expectedDiff);
            expect(item.makeovers.length, greaterThanOrEqualTo(2));
            expect(item.cousinWords.length, greaterThanOrEqualTo(2));
          }

          // Practice JSON
          final pracFile = File(
            'assets/curriculum/vocabulary/synonymSearch_practice_${start}_$end.json',
          );
          expect(pracFile.existsSync(), isTrue, reason: pracFile.path);
          final pracRaw = pracFile.readAsStringSync();
          expect(
            pracRaw.contains('PLACEHOLDER'),
            isFalse,
            reason: pracFile.path,
          );
          final pracMap = jsonDecode(pracRaw) as Map<String, dynamic>;
          expect(pracMap['cefr'], expectedCefr);
          expect(pracMap['difficulty'], expectedDiff);
          final pracBatch = SynonymPracticeBatch.fromJson(pracMap);
          expect(pracBatch.quests.length, 30);
          for (final q in pracBatch.quests) {
            expect(q.cefr, expectedCefr);
            expect(q.difficulty, expectedDiff);
            expect(q.exercises.length, 2);
          }

          // Mastery JSON
          final mastFile = File(
            'assets/curriculum/vocabulary/synonymSearch_mastery_${start}_$end.json',
          );
          expect(mastFile.existsSync(), isTrue, reason: mastFile.path);
          final mastRaw = mastFile.readAsStringSync();
          expect(
            mastRaw.contains('PLACEHOLDER'),
            isFalse,
            reason: mastFile.path,
          );
          final mastMap = jsonDecode(mastRaw) as Map<String, dynamic>;
          jsonDecode(mastFile.readAsStringSync()) as Map<String, dynamic>;
          expect(mastMap['cefr'], expectedCefr);
          expect(mastMap['difficulty'], expectedDiff);
          final rawQuests = mastMap['quests'] as List<dynamic>;
          expect(rawQuests.length, 30);
          for (final rawQ in rawQuests) {
            final qMap = Map<String, dynamic>.from(rawQ as Map);
            expect(qMap['cefr'], expectedCefr);
            expect(qMap['difficulty'], expectedDiff);
            final model = VocabularyQuestModel.fromJson(
              qMap,
              qMap['id'] as String? ?? '',
            );
            expect(model.correctAnswer, isNotNull);
            expect(model.options, isNotNull);
            expect(
              model.options!.map((e) => e.toLowerCase()),
              contains(model.correctAnswer!.toLowerCase()),
            );
            final decoysLower = model.options!
                .where(
                  (o) => o.toLowerCase() != model.correctAnswer!.toLowerCase(),
                )
                .map((e) => e.toLowerCase())
                .toSet();
            final cousinLower = (model.synonyms ?? const <String>[])
                .where(
                  (s) => s.toLowerCase() != model.correctAnswer!.toLowerCase(),
                )
                .map((e) => e.toLowerCase())
                .toSet();
            expect(
              decoysLower.intersection(cousinLower),
              isEmpty,
              reason: '${model.id} decoy overlapped listed synonym',
            );
            expect(
              (model.definition ?? '').trim(),
              isNot(equals((model.explanation ?? '').trim())),
              reason:
                  'Mastery quest ${model.id} must have distinct definition and explanation',
            );
          }
        }
      },
    );

    test(
      'buildInterleavedExercisesForLevel alternates swap and ladder cleanly across pairs',
      () {
        final pracFile = File(
          'assets/curriculum/vocabulary/synonymSearch_practice_1_10.json',
        );
        final pracBatch = SynonymPracticeBatch.fromJson(
          jsonDecode(pracFile.readAsStringSync()) as Map<String, dynamic>,
        );

        final interleaved = pracBatch.buildInterleavedExercisesForLevel(1);
        expect(interleaved.length, 6);
        expect(interleaved[0].type, SynonymPracticeExerciseType.contrastSwap);
        expect(interleaved[1].type, SynonymPracticeExerciseType.synonymLadder);
        expect(interleaved[2].type, SynonymPracticeExerciseType.contrastSwap);
        expect(interleaved[3].type, SynonymPracticeExerciseType.synonymLadder);

        // Consecutive drills should never repeat the exact same parent word
        for (int i = 0; i < interleaved.length - 1; i++) {
          expect(interleaved[i].baseWord, isNot(interleaved[i + 1].baseWord));
        }
      },
    );

    test(
      'SynonymCefrHelper scales countdowns by CEFR tier and normalized length',
      () {
        expect(
          SynonymCefrHelper.masteryTimerSeconds(
            level: 1,
            normalizedWordLength: 5,
          ),
          28,
        );
        expect(
          SynonymCefrHelper.masteryTimerSeconds(
            level: 45,
            normalizedWordLength: 5,
          ),
          25,
        );
        expect(
          SynonymCefrHelper.masteryTimerSeconds(
            level: 95,
            normalizedWordLength: 5,
          ),
          22,
        );
        expect(
          SynonymCefrHelper.masteryTimerSeconds(
            level: 130,
            normalizedWordLength: 11,
          ),
          25, // 20 + (11 - 6) = 25s
        );
        expect(
          SynonymCefrHelper.masteryTimerSeconds(
            level: 180,
            normalizedWordLength: 24,
          ),
          35, // clamped at 35s
        );
      },
    );

    test(
      'Learn and Practice controllers update ValueNotifiers and guided reveal cleanly',
      () {
        final learn = SynonymLearnController();
        addTearDown(learn.dispose);
        learn.setItems([SynonymLearnItem.fallback(1)]);
        expect(learn.autoSpeak.value, isFalse);
        learn.toggleAutoSpeak();
        expect(learn.autoSpeak.value, isTrue);
        expect(learn.testedCountForCurrent(), 0);
        learn.toggleMakeoverSwap(0);
        expect(learn.isMakeoverSwapped(0), isTrue);
        expect(learn.testedCountForCurrent(), 1);
        learn.selectCousin(1);
        expect(learn.selectedCousinIndexForCurrent(), 1);
        learn.selectCousin(1);
        expect(learn.selectedCousinIndexForCurrent(), isNull);

        final prac = SynonymPracticeController();
        addTearDown(prac.dispose);
        prac.setExercises(SynonymPracticeQuest.fallbackExercises(1));
        expect(prac.canCheck, isFalse);

        // Wrong contrast placement increments wrongAttempts & triggers shake
        prac.assignContrastWord('Large');
        prac.assignContrastWord('Big');
        expect(prac.canCheck, isTrue);
        expect(prac.checkAnswer(), isFalse);
        expect(prac.wrongAttempts.value, 1);
        expect(prac.shakeCount.value, 1);

        // Guided reveal solves cleanly after misses
        prac.revealGuidedSolution();
        expect(prac.hasChecked.value, isTrue);
        expect(prac.isCorrect.value, isTrue);
        expect(prac.nextExercise(), isTrue);
        expect(prac.currentIndex.value, 1);
      },
    );

    test(
      'SynonymPhaseLocalDataSource resolves batch paths and parses Learn and Practice batches',
      () async {
        expect(SynonymPhaseLocalDataSource.batchSuffixForLevel(1), '1_10');
        expect(SynonymPhaseLocalDataSource.batchSuffixForLevel(11), '11_20');
        expect(SynonymPhaseLocalDataSource.batchSuffixForLevel(100), '91_100');

        final bundle = _MapAssetBundle({
          SynonymPhaseLocalDataSource.learnAssetPath(1): File(
            'assets/curriculum/vocabulary/synonymSearch_learn_1_10.json',
          ).readAsStringSync(),
          SynonymPhaseLocalDataSource.practiceAssetPath(1): File(
            'assets/curriculum/vocabulary/synonymSearch_practice_1_10.json',
          ).readAsStringSync(),
        });

        final dataSource = SynonymPhaseLocalDataSource(bundle: bundle);
        final learnItems = await dataSource.loadLearnItems(1);
        final practiceItems = await dataSource.loadPracticeExercises(1);

        expect(learnItems.length, 3);
        expect(practiceItems.length, 6);
      },
    );

    test(
      'SynonymWeakWordsStore persists priority ordering and marks reviewed pairs',
      () async {
        SharedPreferences.setMockInitialValues({});
        await SynonymWeakWordsStore.resetForTest();

        await SynonymWeakWordsStore.recordWeakPair(
          level: 2,
          baseWord: 'Begin',
          synonym: 'Start',
        );
        await SynonymWeakWordsStore.recordWeakPair(
          level: 5,
          baseWord: 'Marry',
          synonym: 'Wed',
        );
        await SynonymWeakWordsStore.recordWeakPair(
          level: 5,
          baseWord: 'Marry',
          synonym: 'Wed',
        );

        final due = await SynonymWeakWordsStore.loadWeakPairs(excludeLevel: 1);
        expect(due.length, 2);
        expect(due.first.synonym, 'Wed');
        expect(due.first.misses, 2);

        final excluded = await SynonymWeakWordsStore.loadWeakPairs(
          excludeLevel: 5,
        );
        expect(excluded.length, 1);
        expect(excluded.first.synonym, 'Start');

        await SynonymWeakWordsStore.markReviewed(
          baseWord: 'Begin',
          synonym: 'Start',
        );
        final afterReview = await SynonymWeakWordsStore.loadWeakPairs(
          excludeLevel: 5,
        );
        expect(afterReview, isEmpty);
      },
    );

    test(
      'Practice toggleHint repairs wrong slot 0, Learn predictMakeover counts swaps, and Mastery helpers classify modes',
      () {
        final prac = SynonymPracticeController();
        addTearDown(prac.dispose);
        final exercises = SynonymPracticeQuest.fallbackExercises(1);
        prac.setExercises(exercises);

        // Put wrong word in slot 0 -> Hint fixes slot 0
        final expectedSlot0 = exercises.first.slots[0].correctWord;
        final wrongSlot0 = exercises.first.pairWords.firstWhere(
          (w) => w.toLowerCase() != expectedSlot0.toLowerCase(),
        );
        prac.assignContrastWord(wrongSlot0);
        expect(prac.contrastAssignments.value[0], wrongSlot0);
        prac.toggleHint();
        expect(
          prac.contrastAssignments.value[0]?.toLowerCase(),
          expectedSlot0.toLowerCase(),
        );

        final learn = SynonymLearnController();
        addTearDown(learn.dispose);
        learn.setItems([SynonymLearnItem.fallback(1)]);
        learn.predictMakeover(0, predictedNatural: true);
        expect(learn.predictionFor(0), isTrue);
        expect(learn.isMakeoverSwapped(0), isTrue);
        expect(learn.testedCountForCurrent(), 1);

        const q = VocabularyQuest(
          id: 'TEST_CTX',
          type: QuestType.vocabulary,
          subtype: GameSubtype.synonymSearch,
          instruction: 'Pick the matching synonym.',
          difficulty: 1,
          word: 'Happy',
          synonym: 'Glad',
          correctAnswer: 'Glad',
          options: ['Glad', 'Merry', 'Proud', 'Calm'],
          contextSentence: 'I am ___ you came.',
        );
        expect(SynonymMasteryController.isContextReplaceRound(q, 0), isFalse);
        expect(SynonymMasteryController.isContextReplaceRound(q, 1), isTrue);
        expect(
          SynonymMasteryController.shouldHideLengthForRecall(
            level: 40,
            questIndex: 2,
          ),
          isFalse,
        );
        expect(
          SynonymMasteryController.shouldHideLengthForRecall(
            level: 41,
            questIndex: 2,
          ),
          isTrue,
        );
      },
    );
  });
}
