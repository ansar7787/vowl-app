import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/vocabulary/contextual_usage/presentation/pages/contextual_usage_learn_screen.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';

class MockHapticService extends Mock implements HapticService {}

class MockSoundService extends Mock implements SoundService {}

class MockTtsService extends Mock implements TtsService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockHapticService mockHapticService;
  late MockSoundService mockSoundService;
  late MockTtsService mockTtsService;

  setUp(() async {
    mockHapticService = MockHapticService();
    mockSoundService = MockSoundService();
    mockTtsService = MockTtsService();

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});

    when(() => mockSoundService.playCorrect()).thenAnswer((_) async {});
    when(() => mockSoundService.playWrong()).thenAnswer((_) async {});

    when(() => mockTtsService.stop()).thenAnswer((_) async {});
    when(
      () => mockTtsService.speak(
        any(),
        rate: any(named: 'rate'),
        locale: any(named: 'locale'),
      ),
    ).thenAnswer((_) async {});

    await di.sl.reset();
    di.sl.registerSingleton<HapticService>(mockHapticService);
    di.sl.registerSingleton<SoundService>(mockSoundService);
    di.sl.registerSingleton<TtsService>(mockTtsService);
  });

  Widget buildTestableWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, _) => MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: child,
        ),
      ),
    );
  }

  group('ContextualUsageLearnScreen', () {
    testWidgets(
        'renders context matrix, pragmatic rule, interactive tryout, and advances',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844) * 2.0;
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestableWidget(
          ContextualUsageLearnScreen(
            level: 1,
            initialQuests: [
              VocabularyQuest(
                id: 'VOC_CONTEXT_L1_TEST_1',
                type: QuestType.vocabulary,
                subtype: GameSubtype.contextualUsage,
                word: 'BORROW',
                correctAnswer: 'BORROW',
                options: const ['LEND', 'RENT', 'BORROW', 'LOAN'],
                instruction: 'Select the word that best completes the sentence.',
                hint:
                    'Think about whether the speaker wants to receive something temporarily.',
                explanation:
                    'Borrow means to take something temporarily, intending to return it.',
                prompt: "Could I _____ your pen? I'll give it back after class.",
                contextSentence:
                    "Could I borrow your pen? I'll give it back after class.",
                usageExample:
                    "Could I borrow your pen? I'll give it back after class.",
                nuanceDifference:
                    'Borrow is receiving; Lend is giving temporarily.',
                registerLevel: 1,
                difficulty: 1,
              ),
              VocabularyQuest(
                id: 'VOC_CONTEXT_L1_TEST_2',
                type: QuestType.vocabulary,
                subtype: GameSubtype.contextualUsage,
                word: 'LEND',
                correctAnswer: 'LEND',
                options: const ['BORROW', 'LEND', 'OWE', 'GIVE'],
                instruction: 'Select the word that best completes the sentence.',
                hint: 'Ask yourself who is doing the giving here.',
                explanation:
                    'Lend means to give something temporarily, expecting it back.',
                prompt: 'My sister offered to _____ me some money until payday.',
                contextSentence:
                    'My sister offered to lend me some money until payday.',
                usageExample:
                    'My sister offered to lend me some money until payday.',
                nuanceDifference:
                    'Lend is giving temporarily; Borrow is receiving.',
                registerLevel: 1,
                difficulty: 1,
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(ContextualUsageLearnScreen), findsOneWidget);
      expect(find.text('PRAGMATIC RULE'), findsOneWidget);
      expect(find.text('INTERACTIVE QUICK TRYOUT'), findsOneWidget);

      // Tap BORROW option chip
      final borrowChip = find.text('BORROW');
      expect(borrowChip, findsWidgets);
      await tester.ensureVisible(borrowChip.first);
      await tester.tap(borrowChip.first, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Advance to next dilemma
      final nextButton = find.textContaining('Next Context Dilemma');
      expect(nextButton, findsOneWidget);
      await tester.ensureVisible(nextButton);
      await tester.tap(nextButton, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    });
  });
}
