import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/vocabulary/flashcards/presentation/pages/flashcards_practice_screen.dart';
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
      'renders active recall typing exercise, evaluates answer and advances',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(const FlashcardsPracticeScreen(level: 1)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.byType(FlashcardsPracticeScreen), findsOneWidget);
        expect(find.byType(FlashcardPracticeTypingCard), findsOneWidget);

        // Enter answer in typing field
        final textField = find.byType(TextField);
        expect(textField, findsOneWidget);
        await tester.enterText(textField, 'Hello');
        await tester.pump();

        // Tap Check Answer button
        final checkButton = find.text('Check Answer');
        expect(checkButton, findsOneWidget);
        await tester.tap(checkButton);
        await tester.pump(const Duration(milliseconds: 300));

        // Correct feedback displayed
        expect(find.text('CORRECT'), findsOneWidget);
        expect(find.text('Spot on! Correct answer.'), findsOneWidget);

        // Tap Next Exercise
        final nextButton = find.textContaining('Next Exercise');
        expect(nextButton, findsOneWidget);
        await tester.tap(nextButton);
        await tester.pump(const Duration(milliseconds: 300));
      },
    );
  });
}
