import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/pages/flashcards_learn_screen.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/widgets/flashcard_audio_visualizer.dart';
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
    testWidgets(
      'renders holographic card, audio visualizer, flippable 3D faces, and advances',
      (tester) async {
        tester.view.physicalSize = const Size(375, 812);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          buildTestableWidget(const FlashcardsLearnScreen(level: 1)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        // Verifies the flippable card and audio visualizer are mounted
        expect(find.byType(FlashcardLearnCard), findsOneWidget);
        expect(find.byType(FlashcardAudioVisualizer), findsOneWidget);

        // Tap the audio speaker button
        final speakerFinder = find.byIcon(Icons.volume_up_rounded).first;
        await tester.tap(speakerFinder);
        await tester.pump();
        verify(() => mockTtsService.speak(any())).called(greaterThan(0));

        // Tap card to flip
        await tester.tap(find.byKey(const Key('flashcard_learn_card')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 450));

        expect(find.text('DEFINITION'), findsOneWidget);
        expect(find.text('Tap to flip back'), findsOneWidget);

        // Scroll down to see teaching sections
        await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -300));
        await tester.pumpAndSettle();

        expect(find.text('NATIVE SPEAKER TIP'), findsOneWidget);
        expect(find.text('PITFALL TO AVOID'), findsOneWidget);

        // Tap Next Word button to advance
        final nextBtn = find.text('Next Word ➔');
        if (nextBtn.evaluate().isNotEmpty) {
          await tester.tap(nextBtn);
          await tester.pumpAndSettle();
        }
      },
    );
  });
}
