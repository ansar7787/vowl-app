import 'package:flutter_test/flutter_test.dart';
import 'package:vowl/features/vocabulary/prefix_suffix/presentation/controllers/prefix_suffix_controller.dart';

void main() {
  group('PrefixSuffixController', () {
    late PrefixSuffixController controller;

    setUp(() {
      controller = PrefixSuffixController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('initial state has correct default values', () {
      expect(controller.slottedAffix, isNull);
      expect(controller.isJammed, isFalse);
      expect(controller.isUnlocked, isFalse);
      expect(controller.hintsUsed, 0);
      expect(controller.streak, 0);
      expect(controller.comboMultiplier, 1);
      expect(controller.isAnswered, isFalse);
      expect(controller.isSliced, isFalse);
      expect(controller.isWrongCut, isFalse);
      expect(controller.timeFraction, 1.0);
      expect(controller.secondsRemaining, 5);
    });

    group('Practice phase logic (Vault Cracker)', () {
      test('slotAffix with correct affix sets isUnlocked to true', () {
        final result = controller.slotAffix('PRE-', 'PRE-');

        expect(result, isTrue);
        expect(controller.slottedAffix, 'PRE-');
        expect(controller.isUnlocked, isTrue);
        expect(controller.isJammed, isFalse);
      });

      test('slotAffix with case-insensitive and trimmed match succeeds', () {
        final result = controller.slotAffix('  pre- ', 'PRE-');

        expect(result, isTrue);
        expect(controller.isUnlocked, isTrue);
        expect(controller.isJammed, isFalse);
      });

      test('slotAffix with incorrect affix sets isJammed to true', () {
        final result = controller.slotAffix('RE-', 'PRE-');

        expect(result, isFalse);
        expect(controller.slottedAffix, 'RE-');
        expect(controller.isUnlocked, isFalse);
        expect(controller.isJammed, isTrue);
      });

      test('clearSlot resets slotted affix and feedback flags', () {
        controller.slotAffix('RE-', 'PRE-');
        expect(controller.isJammed, isTrue);

        controller.clearSlot();
        expect(controller.slottedAffix, isNull);
        expect(controller.isJammed, isFalse);
        expect(controller.isUnlocked, isFalse);
      });

      test('useHint increments hintsUsed', () {
        expect(controller.hintsUsed, 0);
        controller.useHint();
        expect(controller.hintsUsed, 1);
        controller.useHint();
        expect(controller.hintsUsed, 2);
      });
    });

    group('Mastery phase logic (Morpheme Precision Slicer)', () {
      test(
        'evaluateSlice with matching cut index increments streak and combo',
        () {
          final result = controller.evaluateSlice(
            cutIndex: 3,
            correctCutIndex: 3,
          );

          expect(result, isTrue);
          expect(controller.isSliced, isTrue);
          expect(controller.isWrongCut, isFalse);
          expect(controller.isAnswered, isTrue);
          expect(controller.streak, 1);
          expect(controller.comboMultiplier, 1);

          // Next round correct slice increases combo
          controller.resetForNextQuest();
          controller.evaluateSlice(cutIndex: 2, correctCutIndex: 2);
          expect(controller.streak, 2);
          expect(controller.comboMultiplier, 2);
        },
      );

      test(
        'evaluateSlice with incorrect cut index resets streak and combo',
        () {
          // Build up streak first
          controller.evaluateSlice(cutIndex: 3, correctCutIndex: 3);
          controller.resetForNextQuest();
          controller.evaluateSlice(cutIndex: 3, correctCutIndex: 3);
          expect(controller.streak, 2);

          // Incorrect cut
          controller.resetForNextQuest();
          final result = controller.evaluateSlice(
            cutIndex: 1,
            correctCutIndex: 3,
          );

          expect(result, isFalse);
          expect(controller.isSliced, isFalse);
          expect(controller.isWrongCut, isTrue);
          expect(controller.isAnswered, isTrue);
          expect(controller.streak, 0);
          expect(controller.comboMultiplier, 1);
        },
      );

      test('evaluateSlice returns false if already answered', () {
        controller.evaluateSlice(cutIndex: 3, correctCutIndex: 3);
        expect(controller.isAnswered, isTrue);

        final secondAttempt = controller.evaluateSlice(
          cutIndex: 3,
          correctCutIndex: 3,
        );
        expect(secondAttempt, isFalse);
      });

      test('resetForNextQuest clears round state but preserves streak', () {
        controller.evaluateSlice(cutIndex: 3, correctCutIndex: 3);
        expect(controller.streak, 1);

        controller.resetForNextQuest();
        expect(controller.isAnswered, isFalse);
        expect(controller.isSliced, isFalse);
        expect(controller.isWrongCut, isFalse);
        expect(controller.slottedAffix, isNull);
        expect(controller.streak, 1);
      });

      test(
        'evaluateSlice correctly handles unbreakable imposter roots with cutIndex 0',
        () {
          final result = controller.evaluateSlice(
            cutIndex: 0,
            correctCutIndex: 0,
          );
          expect(result, isTrue);
          expect(controller.isSliced, isTrue);
          expect(controller.isWrongCut, isFalse);
          expect(controller.streak, 1);
        },
      );
    });
  });
}
