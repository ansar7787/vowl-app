import 'package:flutter/gestures.dart';
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
    submittedAnswers = [];
    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});

    controller = FlashcardController(
      hapticService: mockHapticService,
      onSubmitAnswer: (mastered) {
        submittedAnswers.add(mastered);
      },
    );
  });

  tearDown(() {
    controller.dispose();
  });

  group('FlashcardController', () {
    test('initial state is correct', () {
      expect(controller.isAnswered, isFalse);
      expect(controller.isRetrying, isFalse);
      expect(controller.isCorrect, isNull);
      expect(controller.showConfetti, isFalse);
      expect(controller.isHintActive, isFalse);
      expect(controller.isFlipped.value, isFalse);
      expect(controller.dragOffset.value, equals(Offset.zero));
      expect(controller.dragAngle.value, equals(0.0));
    });

    test('flipCard toggles isFlipped and triggers haptic light', () {
      controller.flipCard();
      expect(controller.isFlipped.value, isTrue);
      verify(() => mockHapticService.light()).called(1);

      controller.flipCard();
      expect(controller.isFlipped.value, isFalse);
      verify(() => mockHapticService.light()).called(1);
    });

    test('submitAnswer updates state, offset, and calls callback', () {
      controller.submitAnswer(true);

      expect(controller.isAnswered, isTrue);
      expect(controller.isCorrect, isTrue);
      expect(controller.dragOffset.value.dx, equals(1000));
      expect(submittedAnswers, equals([true]));

      // Cannot submit twice
      controller.submitAnswer(false);
      expect(submittedAnswers, equals([true]));
    });

    test('submitAnswer with false indicates review needed', () {
      controller.submitAnswer(false);

      expect(controller.isAnswered, isTrue);
      expect(controller.isCorrect, isFalse);
      expect(controller.dragOffset.value.dx, equals(-1000));
      expect(submittedAnswers, equals([false]));
    });

    test('onHorizontalDragUpdate updates drag offset and angle', () {
      controller.onHorizontalDragUpdate(
        DragUpdateDetails(
          globalPosition: const Offset(50, 0),
          delta: const Offset(30, 0),
        ),
      );

      expect(controller.dragOffset.value.dx, equals(30));
      expect(controller.dragAngle.value, closeTo(30 / 500, 0.001));
    });

    test('onHorizontalDragEnd below threshold snaps back to zero', () {
      controller.onHorizontalDragUpdate(
        DragUpdateDetails(
          globalPosition: const Offset(20, 0),
          delta: const Offset(20, 0),
        ),
      );

      controller.onHorizontalDragEnd(DragEndDetails(), 80.0);

      expect(controller.dragOffset.value, equals(Offset.zero));
      expect(controller.dragAngle.value, equals(0.0));
      expect(controller.isAnswered, isFalse);
    });

    test('onHorizontalDragEnd above threshold submits answer', () {
      controller.onHorizontalDragUpdate(
        DragUpdateDetails(
          globalPosition: const Offset(100, 0),
          delta: const Offset(100, 0),
        ),
      );

      controller.onHorizontalDragEnd(DragEndDetails(), 80.0);

      expect(controller.isAnswered, isTrue);
      expect(submittedAnswers, equals([true]));
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

    test('reset clears interaction state', () {
      controller.submitAnswer(true);
      controller.reset(false);

      expect(controller.isAnswered, isFalse);
      expect(controller.isRetrying, isFalse);
      expect(controller.isCorrect, isNull);
      expect(controller.isHintActive, isFalse);
      expect(controller.isFlipped.value, isFalse);
      expect(controller.dragOffset.value, equals(Offset.zero));
    });
  });
}
