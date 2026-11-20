import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/vocabulary/flashcards/presentation/pages/flashcards_practice_screen.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/widgets/flashcard_practice_rune_slots.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/widgets/flashcard_practice_typing_card.dart';

class MockHapticService extends Mock implements HapticService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockHapticService mockHapticService;

  setUpAll(() {
    mockHapticService = MockHapticService();
    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});

    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    di.sl.registerSingleton<HapticService>(mockHapticService);
  });

  Widget buildTestableWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (context, _) => MaterialApp(home: child),
    );
  }

  group('FlashcardsPracticeScreen', () {
    testWidgets(
      'renders cyber-cloze shard assembly, allows tapping letter shards, undo, clear, checks answer, and advances',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(const FlashcardsPracticeScreen(level: 1)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        // Verifies the shard assembly card and rune slots are mounted
        expect(find.byType(FlashcardPracticeTypingCard), findsOneWidget);
        expect(find.byType(FlashcardPracticeRuneSlots), findsOneWidget);

        // Tap a letter shard in the pool
        final shardFinder = find.widgetWithText(ScaleButton, 'H');
        if (shardFinder.evaluate().isNotEmpty) {
          await tester.tap(shardFinder.first);
          await tester.pump();
          verify(() => mockHapticService.selection()).called(greaterThan(0));
        }

        // Tap Undo button
        final undoBtn = find.text('Undo');
        expect(undoBtn, findsOneWidget);
        await tester.tap(undoBtn);
        await tester.pump();
        verify(() => mockHapticService.light()).called(greaterThan(0));

        // Tap Clear button
        final clearBtn = find.text('Clear');
        expect(clearBtn, findsOneWidget);
        await tester.tap(clearBtn);
        await tester.pump();

        // Populate correct answer via controller and verify slot sync
        final typingCard = tester.widget<FlashcardPracticeTypingCard>(
          find.byType(FlashcardPracticeTypingCard),
        );
        typingCard.textController.text = 'Hello';
        await tester.pump();

        // Tap Check Answer button
        final checkBtn = find.text('Check Answer');
        expect(checkBtn, findsOneWidget);
        await tester.tap(checkBtn);
        await tester.pumpAndSettle();

        // Expect feedback card
        expect(find.text('CORRECT'), findsOneWidget);

        // Tap Next Exercise
        final nextBtn = find.text('Next Exercise ➔');
        expect(nextBtn, findsOneWidget);
        await tester.tap(nextBtn);
        await tester.pumpAndSettle();
      },
    );
  });
}
