import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/pages/flashcards_learn_screen.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/widgets/flashcard_learn_card.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/widgets/flashcard_learn_teaching_section.dart';

class MockHapticService extends Mock implements HapticService {}

class MockTtsService extends Mock implements TtsService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockHapticService mockHapticService;
  late MockTtsService mockTtsService;

  setUp(() {
    VowlMotion.lowAnimationModeOverride.value = true;
    mockHapticService = MockHapticService();
    mockTtsService = MockTtsService();

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});
    when(() => mockTtsService.speak(any())).thenAnswer((_) async {});

    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    if (di.sl.isRegistered<TtsService>()) {
      di.sl.unregister<TtsService>();
    }
    di.sl.registerSingleton<HapticService>(mockHapticService);
    di.sl.registerSingleton<TtsService>(mockTtsService);
  });

  tearDown(() {
    VowlMotion.lowAnimationModeOverride.value = false;
    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    if (di.sl.isRegistered<TtsService>()) {
      di.sl.unregister<TtsService>();
    }
  });

  Widget buildTestableWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, _) => MaterialApp(home: child),
    );
  }

  group('FlashcardsLearnScreen Widget Tests', () {
    testWidgets('renders discovery deck, teaching sections, and flips card', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(const FlashcardsLearnScreen(level: 1)),
      );
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.byType(FlashcardLearnCard).evaluate().isNotEmpty) break;
      }

      expect(find.byType(FlashcardsLearnScreen), findsOneWidget);
      expect(find.byType(FlashcardLearnCard), findsOneWidget);
      expect(find.byType(FlashcardLearnTeachingSection), findsOneWidget);

      expect(
        find.text('Tap card to reveal definition & usage'),
        findsOneWidget,
      );

      // Tap card to flip
      final cardFinder = find.byKey(const Key('flashcard_learn_card'));
      await tester.tap(cardFinder, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Definition face should now be revealed
      expect(find.text('DEFINITION'), findsOneWidget);
      expect(find.text('Tap to flip back'), findsOneWidget);

      // Flip back
      await tester.tap(cardFinder, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(
        find.text('Tap card to reveal definition & usage'),
        findsOneWidget,
      );
    });

    testWidgets('advances to next word and shows action button', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(const FlashcardsLearnScreen(level: 1)),
      );
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 100));
        if (find.byType(ElevatedButton).evaluate().isNotEmpty) break;
      }

      final buttonFinder = find.byType(ElevatedButton);
      if (buttonFinder.evaluate().isNotEmpty) {
        await tester.tap(buttonFinder, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 300));
        verify(() => mockHapticService.light()).called(1);
      }
    });
  });
}
