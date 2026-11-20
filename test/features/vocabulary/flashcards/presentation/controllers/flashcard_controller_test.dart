import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/controllers/flashcard_controller.dart';

class MockHapticService extends Mock implements HapticService {}

void main() {
  late MockHapticService mockHapticService;
  late List<bool> submittedAnswers;
  late FlashcardController controller;

  setUp(() {
    mockHapticService = MockHapticService();
    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});

    submittedAnswers = [];
    controller = FlashcardController(
      hapticService: mockHapticService,
      onSubmitAnswer: (mastered) => submittedAnswers.add(mastered),
    );
  });

  tearDown(() {
    controller.dispose();
  });

  group('FlashcardController', () {
    test('initial state is correct', () {
      expect(controller.isAnswered, isFalse);
      expect(controller.isCorrect, isNull);
      expect(controller.isRetrying, isFalse);
      expect(controller.isHintActive, isFalse);
      expect(controller.showConfetti, isFalse);
      expect(controller.isFlipped.value, isFalse);
      expect(controller.dragOffset.value, Offset.zero);
      expect(controller.dragAngle.value, 0.0);
      expect(controller.dragProgress.value, 0.0);
      expect(controller.comboStreak.value, 0);
    });

    test('flipCard toggles isFlipped and triggers haptic light', () {
      controller.flipCard();
      expect(controller.isFlipped.value, isTrue);
      verify(() => mockHapticService.light()).called(1);

      controller.flipCard();
      expect(controller.isFlipped.value, isFalse);
    });

    test('submitAnswer(true) updates state, increases combo, and sets dragProgress', () {
      controller.submitAnswer(true);

      expect(controller.isAnswered, isTrue);
      expect(controller.isCorrect, isTrue);
      expect(controller.dragOffset.value.dx, 1000);
      expect(controller.dragProgress.value, 1.0);
      expect(controller.comboStreak.value, 1);
      expect(submittedAnswers, [true]);
      verify(() => mockHapticService.success()).called(1);
    });

    test('submitAnswer(false) resets combo and triggers error haptic', () {
      controller.comboStreak.value = 3;
      controller.submitAnswer(false);

      expect(controller.isAnswered, isTrue);
      expect(controller.isCorrect, isFalse);
      expect(controller.dragOffset.value.dx, -1000);
      expect(controller.dragProgress.value, -1.0);
      expect(controller.comboStreak.value, 0);
      expect(submittedAnswers, [false]);
      verify(() => mockHapticService.error()).called(1);
    });

    test('onHorizontalDragUpdate updates drag offset, angle, and progress', () {
      controller.onHorizontalDragUpdate(
        DragUpdateDetails(
          globalPosition: const Offset(50, 0),
          delta: const Offset(60, 0),
        ),
        120.0,
      );

      expect(controller.dragOffset.value.dx, 60.0);
      expect(controller.dragAngle.value, 60.0 / 500);
      expect(controller.dragProgress.value, 0.5);
    });

    test('onHorizontalDragEnd below threshold snaps back to zero', () {
      controller.dragOffset.value = const Offset(40, 0);
      controller.dragAngle.value = 40.0 / 500;
      controller.dragProgress.value = 0.3;

      controller.onHorizontalDragEnd(
        DragEndDetails(velocity: Velocity.zero),
        100.0,
      );

      expect(controller.dragOffset.value, Offset.zero);
      expect(controller.dragAngle.value, 0.0);
      expect(controller.dragProgress.value, 0.0);
      expect(controller.isAnswered, isFalse);
    });

    test('onHorizontalDragEnd above threshold submits answer', () {
      controller.dragOffset.value = const Offset(150, 0);
      controller.dragProgress.value = 1.0;

      controller.onHorizontalDragEnd(
        DragEndDetails(velocity: Velocity.zero),
        100.0,
      );

      expect(controller.isAnswered, isTrue);
      expect(controller.isCorrect, isTrue);
      expect(submittedAnswers, [true]);
    });

    test('requestHint reveals card face temporarily', () {
      controller.requestHint();

      expect(controller.isFlipped.value, isTrue);
      expect(controller.isHintActive, isTrue);
    });

    test('completeGame enables confetti', () {
      controller.completeGame();
      expect(controller.showConfetti, isTrue);
    });

    test('reset clears interaction state and clears combo on retry', () {
      controller.submitAnswer(true);
      expect(controller.comboStreak.value, 1);

      controller.reset(true);

      expect(controller.isAnswered, isFalse);
      expect(controller.isCorrect, isNull);
      expect(controller.isFlipped.value, isFalse);
      expect(controller.dragOffset.value, Offset.zero);
      expect(controller.dragProgress.value, 0.0);
      expect(controller.comboStreak.value, 0);
    });
  });
}
