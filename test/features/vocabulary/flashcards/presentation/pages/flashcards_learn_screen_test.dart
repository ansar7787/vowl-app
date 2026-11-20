import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/pages/flashcards_learn_screen.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/widgets/flashcard_learn_card.dart';

class MockTtsService extends Mock implements TtsService {}

class MockHapticService extends Mock implements HapticService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockTtsService mockTtsService;
  late MockHapticService mockHapticService;

  setUpAll(() {
    mockTtsService = MockTtsService();
    mockHapticService = MockHapticService();

    when(() => mockTtsService.speak(any())).thenAnswer((_) async {});
    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});

    if (di.sl.isRegistered<TtsService>()) {
      di.sl.unregister<TtsService>();
    }
    di.sl.registerSingleton<TtsService>(mockTtsService);

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

  group('FlashcardsLearnScreen', () {
    testWidgets('renders learn phase scaffold, flippable card, and advances', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableWidget(const FlashcardsLearnScreen(level: 1)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(FlashcardsLearnScreen), findsOneWidget);
      expect(find.byType(FlashcardLearnCard), findsOneWidget);

      // Verify front card content
      expect(find.text('HELLO'), findsOneWidget);
      expect(find.text('/həˈloʊ/'), findsOneWidget);

      // Tap card to flip
      await tester.tap(find.byKey(const Key('flashcard_learn_card')));
      await tester.pumpAndSettle();

      // After flipping, definition is revealed
      expect(find.text('DEFINITION'), findsOneWidget);
      expect(find.textContaining('common greeting'), findsOneWidget);

      // Tap to flip back
      await tester.tap(find.byKey(const Key('flashcard_learn_card')));
      await tester.pumpAndSettle();

      // Advance to next word
      final nextButton = find.textContaining('Next Word');
      if (nextButton.evaluate().isNotEmpty) {
        await tester.tap(nextButton.first);
        await tester.pump(const Duration(milliseconds: 300));
      }
    });
  });
}
