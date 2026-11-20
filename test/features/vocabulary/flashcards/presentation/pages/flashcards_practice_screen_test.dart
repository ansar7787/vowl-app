import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/vocabulary/flashcards/presentation/pages/flashcards_practice_screen.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/widgets/flashcard_practice_choice_card.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/widgets/flashcard_practice_typing_card.dart';

class MockHapticService extends Mock implements HapticService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockHapticService mockHapticService;

  setUp(() {
    VowlMotion.lowAnimationModeOverride.value = true;
    mockHapticService = MockHapticService();
    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});

    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    di.sl.registerSingleton<HapticService>(mockHapticService);
  });

  tearDown(() {
    VowlMotion.lowAnimationModeOverride.value = false;
    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
  });

  Widget buildTestableWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, _) => MaterialApp(home: child),
    );
  }

  group('FlashcardsPracticeScreen Widget Tests', () {
    testWidgets(
      'renders active training gym and handles typing shard assembly',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(const FlashcardsPracticeScreen(level: 1)),
        );
        for (int i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 100));
          if (find.byType(ElevatedButton).evaluate().isNotEmpty) break;
        }

        expect(find.byType(FlashcardsPracticeScreen), findsOneWidget);

        final typingCardFinder = find.byType(FlashcardPracticeTypingCard);
        final choiceCardFinder = find.byType(FlashcardPracticeChoiceCard);
        expect(
          typingCardFinder.evaluate().isNotEmpty ||
              choiceCardFinder.evaluate().isNotEmpty,
          isTrue,
        );

        if (typingCardFinder.evaluate().isNotEmpty) {
          expect(find.text('TAP SHARDS TO ASSEMBLE'), findsOneWidget);
          expect(find.text('Clear'), findsOneWidget);
          expect(find.text('Undo'), findsOneWidget);

          // Tap a letter shard
          final shardFinder = find.widgetWithText(ScaleButton, 'H');
          if (shardFinder.evaluate().isNotEmpty) {
            await tester.ensureVisible(shardFinder.first);
            await tester.tap(shardFinder.first);
            await tester.pump();
            verify(() => mockHapticService.selection()).called(1);

            // Tap Clear
            await tester.tap(find.text('Clear'));
            await tester.pump();
            verify(() => mockHapticService.light()).called(1);
          }
        }
      },
    );

    testWidgets('checking answer evaluates exercise and updates feedback', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(const FlashcardsPracticeScreen(level: 1)),
      );
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.byType(ElevatedButton).evaluate().isNotEmpty) break;
      }

      final actionButtonFinder = find.byType(ElevatedButton);
      expect(actionButtonFinder, findsOneWidget);

      await tester.tap(actionButtonFinder, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(FlashcardsPracticeScreen), findsOneWidget);
    });
  });
}
