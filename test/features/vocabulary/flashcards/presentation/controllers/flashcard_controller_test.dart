import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/controllers/flashcard_controller.dart';

class MockHapticService extends Mock implements HapticService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockHapticService mockHaptic;
  late FlashcardMasteryController controller;
  bool submittedCorrect = false;
  bool submittedSpeedBonus = false;

  setUp(() {
    mockHaptic = MockHapticService();
    when(() => mockHaptic.selection()).thenAnswer((_) async {});
    when(() => mockHaptic.success()).thenAnswer((_) async {});
    when(() => mockHaptic.error()).thenAnswer((_) async {});

    submittedCorrect = false;
    submittedSpeedBonus = false;

    controller = FlashcardMasteryController(
      hapticService: mockHaptic,
      onSubmitResult: ({required bool isCorrect, required bool speedBonus}) {
        submittedCorrect = isCorrect;
        submittedSpeedBonus = speedBonus;
      },
    );
  });

  tearDown(() {
    controller.dispose();
  });

  group('FlashcardMasteryController', () {
    test('initializes with default values and starts timer', () {
      controller.startTimer();
      expect(controller.isAnswered, isFalse);
      expect(controller.isCorrect, isNull);
      expect(controller.timerProgress.value, equals(1.0));
      expect(controller.isStage2.value, isFalse);
      expect(controller.comboStreak.value, equals(0));
    });

    test('slamCollocation with correct match advances to stage 2', () async {
      bool advancedToStage2 = false;
      controller.slamCollocation(
        index: 0,
        isMatchCorrect: true,
        onAdvanceToStage2: () {
          advancedToStage2 = true;
        },
      );

      expect(controller.selectedCollocationIndex.value, equals(0));
      verify(() => mockHaptic.selection()).called(1);

      await Future.delayed(const Duration(milliseconds: 300));
      expect(controller.isStage2.value, isTrue);
      expect(advancedToStage2, isTrue);
    });

    test('slamCollocation with wrong match fails trial', () {
      controller.slamCollocation(
        index: 1,
        isMatchCorrect: false,
        onAdvanceToStage2: () {},
      );

      expect(controller.isAnswered, isTrue);
      expect(controller.isCorrect, isFalse);
      expect(submittedCorrect, isFalse);
      expect(controller.comboStreak.value, equals(0));
      verify(() => mockHaptic.error()).called(1);
    });

    test(
      'strikeCandidateWord with correct target completes trial with combo',
      () async {
        // Advance to Stage 2 first
        controller.slamCollocation(
          index: 0,
          isMatchCorrect: true,
          onAdvanceToStage2: () {},
        );
        await Future.delayed(const Duration(milliseconds: 300));

        controller.strikeCandidateWord(
          index: 0,
          selectedWord: 'authentic',
          targetWord: 'authentic',
        );

        expect(controller.isAnswered, isTrue);
        expect(controller.isCorrect, isTrue);
        expect(submittedCorrect, isTrue);
        expect(submittedSpeedBonus, isTrue);
        expect(controller.comboStreak.value, equals(1));
        verify(() => mockHaptic.success()).called(1);
      },
    );

    test(
      'strikeCandidateWord with wrong target fails trial and resets streak',
      () async {
        controller.comboStreak.value = 3;
        controller.isStage2.value = true;

        controller.strikeCandidateWord(
          index: 1,
          selectedWord: 'automatic',
          targetWord: 'authentic',
        );

        expect(controller.isAnswered, isTrue);
        expect(controller.isCorrect, isFalse);
        expect(submittedCorrect, isFalse);
        expect(controller.comboStreak.value, equals(0));
        verify(() => mockHaptic.error()).called(1);
      },
    );

    test('reset clears interaction states', () {
      controller.comboStreak.value = 5;
      controller.reset(isRetry: false);

      expect(controller.isAnswered, isFalse);
      expect(controller.isCorrect, isNull);
      expect(controller.isStage2.value, isFalse);
      expect(controller.selectedCollocationIndex.value, isNull);
      expect(controller.selectedCandidateIndex.value, isNull);
      expect(controller.timerProgress.value, equals(1.0));
      expect(controller.comboStreak.value, equals(5));

      controller.reset(isRetry: true);
      expect(controller.comboStreak.value, equals(0));
    });

    test('triggerVictoryCelebration sets showConfetti', () {
      expect(controller.showConfetti, isFalse);
      controller.triggerVictoryCelebration();
      expect(controller.showConfetti, isTrue);
    });
  });
}
