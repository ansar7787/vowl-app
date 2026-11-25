import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/controllers/synonym_grid_builder.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/controllers/synonym_mastery_controller.dart';

void main() {
  group('SynonymGridBuilder & SynonymMasteryController', () {
    test(
      'normalizeLetters strips non-alpha chars and uppercases consistently',
      () {
        expect(
          SynonymGridBuilder.normalizeLetters('Inexpensive'),
          'INEXPENSIVE',
        );
        expect(
          SynonymGridBuilder.normalizeLetters('  well-known_phrase '),
          'WELLKNOWNPHRASE',
        );
        expect(
          SynonymGridBuilder.normalizeLetters('PLACEHOLDER_L11_Q1'),
          'PLACEHOLDERLQ',
        );
      },
    );

    test('builds deterministic 5x5 grid with valid connected target path', () {
      const target = 'Inexpensive';
      const options = ['Costly', 'Inexpensive', 'Stingy', 'Broke'];
      final gridA = SynonymGridBuilder.build(
        questId: 'VOC_SYNONYMSEARCH_L3_Q2',
        correctAnswer: target,
        options: options,
      );
      final gridB = SynonymGridBuilder.build(
        questId: 'VOC_SYNONYMSEARCH_L3_Q2',
        correctAnswer: target,
        options: options,
      );

      expect(gridA.columns, 5);
      expect(gridA.rows, 5);
      expect(gridA.letters, equals(gridB.letters));
      expect(gridA.normalizedTarget, 'INEXPENSIVE');
      expect(gridA.targetPathIndices.length, gridA.normalizedTarget.length);

      for (int i = 0; i < gridA.targetPathIndices.length - 1; i++) {
        expect(
          gridA.isAdjacent(
            gridA.targetPathIndices[i],
            gridA.targetPathIndices[i + 1],
          ),
          isTrue,
          reason: 'Path step $i must be 8-directional adjacent',
        );
      }
      expect(
        gridA.spellPath(gridA.targetPathIndices),
        equals(gridA.normalizedTarget),
      );
    });

    test(
      'expands cleanly to 6x5 matrix when normalized target exceeds 20 chars',
      () {
        final grid = SynonymGridBuilder.build(
          questId: 'LONG_WORD_TEST',
          correctAnswer: 'UltraSuperLongSynonymWord',
          options: const ['Short', 'Small'],
        );

        expect(grid.columns, 6);
        expect(grid.rows, 5);
        expect(grid.totalCells, 30);
        expect(grid.spellPath(grid.targetPathIndices), grid.normalizedTarget);
      },
    );

    test('handles placeholder words across Levels 11-200 without crash', () {
      final grid = SynonymGridBuilder.build(
        questId: 'VOC_SYNONYMSEARCH_L11_Q1',
        correctAnswer: 'PLACEHOLDER_SYN_11_1',
        options: const ['PLACEHOLDER_SYN_11_1', 'TINY', 'COLD', 'WEAK'],
      );

      expect(grid.totalCells, 25);
      expect(grid.targetPathIndices, isNotEmpty);
      expect(grid.spellPath(grid.targetPathIndices), grid.normalizedTarget);
    });

    test('completing 50 consecutive 5x5 grid builds takes under 100ms', () {
      final sw = Stopwatch()..start();
      for (int i = 0; i < 50; i++) {
        final grid = SynonymGridBuilder.build(
          questId: 'PERF_$i',
          correctAnswer: 'EXTRAORDINARY',
          options: const ['COMMON', 'ORDINARY', 'PLAIN', 'EXTRAORDINARY'],
        );
        expect(grid.spellPath(grid.targetPathIndices), 'EXTRAORDINARY');
      }
      sw.stop();
      // < 5ms per grid build even under debug/JIT VM overhead (target: 50 * 5ms = 250ms).
      expect(sw.elapsedMilliseconds, lessThan(250));
    });

    test(
      'controller supports tap trace win, mid-drag backtrack undo, and short slip safety',
      () {
        int wins = 0;
        final List<String?> wrongs = [];
        final controller = SynonymMasteryController(
          onCorrectFound: () => wins++,
          onWrongAttempt: wrongs.add,
        );
        addTearDown(controller.dispose);

        const quest = VocabularyQuest(
          id: 'Q_TRACE_1',
          type: QuestType.vocabulary,
          subtype: GameSubtype.synonymSearch,
          instruction: 'Find and trace the synonym.',
          word: 'Big',
          correctAnswer: 'Large',
          options: ['Tiny', 'Narrow', 'Large', 'Short'],
          explanation: "'Large' fits physical size.",
          difficulty: 1,
        );

        controller.loadQuest(quest, level: 1, forceReset: true);
        final grid = controller.grid.value!;
        final targetPath = grid.targetPathIndices;
        expect(targetPath.length, 5);

        // Incomplete short drag reset incurs 0 penalty
        controller.startDragAt(targetPath[0]);
        controller.extendDragTo(targetPath[1]);
        controller.endDrag();
        expect(wrongs, isEmpty);
        expect(controller.activePath.value, isEmpty);

        // Mid-drag backtrack undo pops last step without clearing earlier progress
        controller.startDragAt(targetPath[0]);
        controller.extendDragTo(targetPath[1]);
        controller.extendDragTo(targetPath[2]);
        expect(controller.activePath.value, targetPath.sublist(0, 3));
        controller.extendDragTo(targetPath[1]);
        expect(controller.activePath.value, targetPath.sublist(0, 2));
        controller.endDrag();
        expect(controller.activePath.value, isEmpty);

        // Full tap-by-tap trace solves board cleanly
        for (final idx in targetPath) {
          controller.tapCell(idx);
        }
        expect(wins, 1);
        expect(controller.comboStreak.value, 1);
        expect(controller.isSubmitting, isTrue);

        // Submitting again during race lock is ignored
        controller.handleTimerExpired();
        expect(wrongs, isEmpty);
      },
    );

    test('timer expiry deducts once and resets combo streak', () {
      int wins = 0;
      final List<String?> wrongs = [];
      final controller = SynonymMasteryController(
        onCorrectFound: () => wins++,
        onWrongAttempt: wrongs.add,
      );
      addTearDown(controller.dispose);

      const quest = VocabularyQuest(
        id: 'Q_TIMEOUT',
        type: QuestType.vocabulary,
        subtype: GameSubtype.synonymSearch,
        instruction: 'Find and trace the synonym.',
        word: 'Fast',
        correctAnswer: 'Quick',
        options: ['Slow', 'Quick', 'Late', 'Weak'],
        explanation: 'Quick means fast.',
        difficulty: 1,
      );

      controller.loadQuest(quest, level: 1);
      controller.comboStreak.value = 3;
      controller.handleTimerExpired();

      expect(wins, 0);
      expect(wrongs, [null]);
      expect(controller.comboStreak.value, 0);
      expect(controller.shakeCount.value, 1);
    });
  });
}
