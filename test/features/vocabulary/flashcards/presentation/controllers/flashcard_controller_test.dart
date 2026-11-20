import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/controllers/flashcard_controller.dart';

class MockHapticService extends Mock implements HapticService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockHapticService mockHapticService;
  late List<bool> submittedAnswers;
  late FlashcardController controller;

  setUp(() {
    mockHapticService = MockHapticService();
    submittedAnswers = [];

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});

    controller = FlashcardController(
      hapticService: mockHapticService,
      onSubmitAnswer: (mastered) => submittedAnswers.add(mastered),
    );
  });

  tearDown(() {
    controller.dispose();
  });

  group('FlashcardController Unit Tests', () {
    test('initial state has correct default values', () {
      expect(controller.isAnswered, isFalse);
      expect(controller.isRetrying, isFalse);
      expect(controller.isCorrect, isNull);
      expect(controller.showConfetti, isFalse);
      expect(controller.isHintActive, isFalse);
      expect(controller.dragOffset.value, Offset.zero);
      expect(controller.dragAngle.value, 0.0);
      expect(controller.dragProgress.value, 0.0);
      expect(controller.isFlipped.value, isFalse);
      expect(controller.comboStreak.value, 0);
    });

    test('flipCard toggles isFlipped and triggers haptic', () {
      controller.flipCard();
      expect(controller.isFlipped.value, isTrue);
      verify(() => mockHapticService.light()).called(1);

      controller.flipCard();
      expect(controller.isFlipped.value, isFalse);
      verify(() => mockHapticService.light()).called(1);
    });

    test('onHorizontalDragUpdate updates offset, angle, and progress', () {
      controller.onHorizontalDragUpdate(
        DragUpdateDetails(
          globalPosition: const Offset(60, 0),
          delta: const Offset(60, 0),
        ),
        120.0,
      );

      expect(controller.dragOffset.value.dx, 60.0);
      expect(controller.dragAngle.value, 60.0 / 500);
      expect(controller.dragProgress.value, 0.5);
    });

    test('onHorizontalDragEnd with dx > threshold submits mastered (true)', () {
      controller.onHorizontalDragUpdate(
        DragUpdateDetails(
          globalPosition: const Offset(150, 0),
          delta: const Offset(150, 0),
        ),
        120.0,
      );

      controller.onHorizontalDragEnd(
        DragEndDetails(
          velocity: const Velocity(pixelsPerSecond: Offset(200, 0)),
        ),
        120.0,
      );

      expect(controller.isAnswered, isTrue);
      expect(controller.isCorrect, isTrue);
      expect(controller.comboStreak.value, 1);
      expect(submittedAnswers, [true]);
      verify(() => mockHapticService.success()).called(1);
    });

    test('onHorizontalDragEnd with dx < -threshold submits review (false)', () {
      controller.onHorizontalDragUpdate(
        DragUpdateDetails(
          globalPosition: const Offset(-150, 0),
          delta: const Offset(-150, 0),
        ),
        120.0,
      );

      controller.onHorizontalDragEnd(
        DragEndDetails(
          velocity: const Velocity(pixelsPerSecond: Offset(-200, 0)),
        ),
        120.0,
      );

      expect(controller.isAnswered, isTrue);
      expect(controller.isCorrect, isFalse);
      expect(controller.comboStreak.value, 0);
      expect(submittedAnswers, [false]);
      verify(() => mockHapticService.error()).called(1);
    });

    test(
      'onHorizontalDragEnd below threshold snaps back without submitting',
      () {
        controller.onHorizontalDragUpdate(
          DragUpdateDetails(
            globalPosition: const Offset(40, 0),
            delta: const Offset(40, 0),
          ),
          120.0,
        );

        controller.onHorizontalDragEnd(
          DragEndDetails(velocity: Velocity.zero),
          120.0,
        );

        expect(controller.isAnswered, isFalse);
        expect(controller.isCorrect, isNull);
        expect(controller.dragOffset.value, Offset.zero);
        expect(controller.dragAngle.value, 0.0);
        expect(controller.dragProgress.value, 0.0);
        expect(submittedAnswers, isEmpty);
      },
    );

    test('combo streak increments on multiple consecutive correct answers', () {
      controller.submitAnswer(true);
      expect(controller.comboStreak.value, 1);

      controller.reset(false);
      expect(controller.comboStreak.value, 1);

      controller.submitAnswer(true);
      expect(controller.comboStreak.value, 2);

      controller.reset(false);
      controller.submitAnswer(false);
      expect(controller.comboStreak.value, 0);
    });

    test('reset with retry=true zeroes out combo streak', () {
      controller.submitAnswer(true);
      expect(controller.comboStreak.value, 1);

      controller.reset(true);
      expect(controller.comboStreak.value, 0);
      expect(controller.isRetrying, isTrue);
    });

    test('requestHint sets isFlipped and isHintActive', () {
      controller.requestHint();
      expect(controller.isFlipped.value, isTrue);
      expect(controller.isHintActive, isTrue);
    });

    test('completeGame sets showConfetti', () {
      controller.completeGame();
      expect(controller.showConfetti, isTrue);
    });
  });
}
