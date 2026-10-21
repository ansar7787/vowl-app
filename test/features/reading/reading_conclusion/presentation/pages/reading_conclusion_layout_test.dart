import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/widgets/game_briefing_layer.dart';
import 'package:vowl/core/presentation/widgets/quest_hint_button.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/analytics_service.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/features/reading/domain/entities/reading_quest.dart';
import 'package:vowl/features/reading/presentation/bloc/reading_bloc.dart';
import 'package:vowl/features/reading/reading_conclusion/presentation/pages/reading_conclusion_screen.dart';
import 'package:vowl/features/reading/reading_conclusion/presentation/widgets/reading_conclusion_instruction.dart';
import 'package:vowl/features/reading/reading_conclusion/presentation/widgets/reading_conclusion_logic_chain.dart';
import 'package:vowl/features/reading/reading_conclusion/presentation/widgets/reading_conclusion_options.dart';
import 'package:vowl/features/reading/reading_conclusion/presentation/widgets/reading_conclusion_passage.dart';

class MockReadingBloc extends MockBloc<ReadingEvent, ReadingState>
    implements ReadingBloc {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockEconomyBloc extends MockBloc<EconomyEvent, EconomyState>
    implements EconomyBloc {}

class MockHapticService extends Mock implements HapticService {}

class MockSoundService extends Mock implements SoundService {}

class MockTtsService extends Mock implements TtsService {}

class MockLocaleService extends Mock implements LocaleService {}

class MockAppLogger extends Mock implements AppLogger {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockAdService extends Mock implements AdService {}

class FakeReadingEvent extends Fake implements ReadingEvent {}

class FakeReadingState extends Fake implements ReadingState {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockReadingBloc mockReadingBloc;
  late MockAuthBloc mockAuthBloc;
  late MockEconomyBloc mockEconomyBloc;
  late MockHapticService mockHapticService;
  late MockSoundService mockSoundService;
  late MockTtsService mockTtsService;
  late MockLocaleService mockLocaleService;
  late MockAppLogger mockLogger;
  late MockAnalyticsService mockAnalyticsService;
  late MockAdService mockAdService;

  setUpAll(() {
    registerFallbackValue(FakeReadingEvent());
    registerFallbackValue(FakeReadingState());
    registerFallbackValue(const SubmitAnswer(true));
    registerFallbackValue(const SubmitAnswer(false));
    registerFallbackValue(const NextQuestion());
    registerFallbackValue(const ReadingHintUsed());
  });

  const testConclusionQuest = ReadingQuest(
    id: 'RDG_READINGCONCLUSION_L1_Q1',
    instruction: 'Read the passage and select the correct conclusion.',
    difficulty: 1,
    subtype: GameSubtype.readingConclusion,
    passage:
        'Maya left her bicycle outside overnight. In the morning, the seat and handlebars were covered in tiny drops of water, even though no one had touched the bike.',
    options: [
      'It rained during the night.',
      'Maya washed her bicycle before going to bed.',
      'The bicycle was stored inside a garage.',
      'Someone poured water on the bicycle on purpose.',
    ],
    correctAnswer: 'It rained during the night.',
    hint:
        'Think about what could leave water on a bike that sat outside all night.',
    explanation:
        'The bike was left outside, and water appeared on it overnight without anyone touching it. Rain is the simplest explanation for water covering an untouched outdoor object.',
    logicChain: [
      'Bike left outside overnight -> water found on bike -> no one touched it -> rain fell overnight',
    ],
  );

  const testNoChainQuest = ReadingQuest(
    id: 'RDG_READINGCONCLUSION_L1_Q2',
    instruction: 'Select the conclusion.',
    difficulty: 1,
    subtype: GameSubtype.readingConclusion,
    passage: 'Simple passage without logic chain.',
    options: ['Option A', 'Option B'],
    correctAnswer: 'Option A',
    logicChain: [],
  );

  const testLoadedState = ReadingLoaded(
    quests: [testConclusionQuest],
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
  );

  setUp(() {
    VowlMotion.lowAnimationModeOverride.value = true;
    SharedPreferences.setMockInitialValues({});

    mockReadingBloc = MockReadingBloc();
    mockAuthBloc = MockAuthBloc();
    mockEconomyBloc = MockEconomyBloc();
    mockHapticService = MockHapticService();
    mockSoundService = MockSoundService();
    mockTtsService = MockTtsService();
    mockLocaleService = MockLocaleService();
    mockLogger = MockAppLogger();
    mockAnalyticsService = MockAnalyticsService();
    mockAdService = MockAdService();

    when(() => mockEconomyBloc.state).thenReturn(const EconomyState());
    when(() => mockEconomyBloc.stream)
        .thenAnswer((_) => const Stream<EconomyState>.empty());

    when(() => mockReadingBloc.state).thenReturn(testLoadedState);
    when(() => mockReadingBloc.stream)
        .thenAnswer((_) => const Stream<ReadingState>.empty());

    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(
        const UserEntity(
          id: 'test_user_id',
          email: 'test@vowl.app',
          displayName: 'Test Explorer',
          hintCount: 3,
        ),
      ),
    );
    when(() => mockAuthBloc.stream)
        .thenAnswer((_) => const Stream<AuthState>.empty());

    when(
      () => mockLocaleService.tr(
        any(),
        fallback: any(named: 'fallback'),
        args: any(named: 'args'),
      ),
    ).thenAnswer(
      (inv) =>
          inv.namedArguments[#fallback] as String? ??
          inv.positionalArguments.first as String,
    );

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});
    when(() => mockHapticService.heavy()).thenAnswer((_) async {});
    when(() => mockHapticService.warning()).thenAnswer((_) async {});

    when(() => mockSoundService.stopAudio()).thenAnswer((_) async {});
    when(() => mockSoundService.stopTts()).thenAnswer((_) async {});
    when(
      () => mockSoundService.playTts(
        any(),
        speed: any(named: 'speed'),
        locale: any(named: 'locale'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockSoundService.playCorrect()).thenAnswer((_) async {});
    when(() => mockSoundService.playWrong()).thenAnswer((_) async {});
    when(() => mockSoundService.playHint()).thenAnswer((_) async {});
    when(() => mockSoundService.playClick()).thenAnswer((_) async {});

    when(() => mockTtsService.stop()).thenAnswer((_) async {});
    when(
      () => mockTtsService.speak(
        any(),
        rate: any(named: 'rate'),
        locale: any(named: 'locale'),
        pauseMarkers: any(named: 'pauseMarkers'),
        forcedPreset: any(named: 'forcedPreset'),
        isKids: any(named: 'isKids'),
      ),
    ).thenAnswer((_) async {});

    when(() => mockLogger.debug(any(), tag: any(named: 'tag'))).thenReturn(null);
    when(() => mockLogger.warning(any(), tag: any(named: 'tag'))).thenReturn(null);
    when(
      () => mockLogger.error(
        any(),
        error: any(named: 'error'),
        stackTrace: any(named: 'stackTrace'),
        tag: any(named: 'tag'),
      ),
    ).thenReturn(null);
    when(() => mockAnalyticsService.logGameSkipped(any())).thenAnswer((_) async {});

    di.sl.reset();
    di.sl.registerSingleton<HapticService>(mockHapticService);
    di.sl.registerSingleton<SoundService>(mockSoundService);
    di.sl.registerSingleton<TtsService>(mockTtsService);
    di.sl.registerSingleton<LocaleService>(mockLocaleService);
    di.sl.registerSingleton<AppLogger>(mockLogger);
    di.sl.registerSingleton<AnalyticsService>(mockAnalyticsService);
    di.sl.registerSingleton<AdService>(mockAdService);
  });

  tearDown(() {
    VowlMotion.lowAnimationModeOverride.value = false;
  });

  Future<void> pumpReadingConclusion(
    WidgetTester tester, {
    ReadingState? state,
    int level = 2,
    ThemeMode themeMode = ThemeMode.light,
    double width = 390,
    double height = 844,
  }) async {
    tester.view.physicalSize = Size(width * 2, height * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    if (state != null) {
      when(() => mockReadingBloc.state).thenReturn(state);
    }

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ReadingBloc>.value(value: mockReadingBloc),
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<EconomyBloc>.value(value: mockEconomyBloc),
        ],
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) => MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            home: Scaffold(
              body: ReadingConclusionScreen(level: level),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('ReadingConclusionScreen - Production Layout & Mechanics Tests', () {
    testWidgets(
        '1. Initial rendering of instruction, passage, and options without logic chain',
        (tester) async {
      await pumpReadingConclusion(tester);

      // Verify instruction
      expect(find.byType(ReadingConclusionInstruction), findsOneWidget);
      expect(
        find.textContaining('select the correct conclusion'),
        findsOneWidget,
      );

      // Verify passage container
      expect(find.byType(ReadingConclusionPassage), findsOneWidget);
      expect(
        find.textContaining('Maya left her bicycle outside overnight'),
        findsOneWidget,
      );

      // Verify options rack
      expect(find.byType(ReadingConclusionOptions), findsOneWidget);
      expect(find.text('It rained during the night.'), findsOneWidget);
      expect(
        find.text('Maya washed her bicycle before going to bed.'),
        findsOneWidget,
      );
      expect(
        find.text('The bicycle was stored inside a garage.'),
        findsOneWidget,
      );
      expect(
        find.text('Someone poured water on the bicycle on purpose.'),
        findsOneWidget,
      );

      // Logic chain should NOT be visible when unanswered
      expect(find.byType(ReadingConclusionLogicChain), findsNothing);
      expect(find.text('LOGICAL DEDUCTION'), findsNothing);
    });

    testWidgets(
        '2. Selecting correct option dispatches SubmitAnswer(true), plays success SFX, and reveals Logic Chain',
        (tester) async {
      await pumpReadingConclusion(tester);

      final correctOptionFinder = find.text('It rained during the night.');
      expect(correctOptionFinder, findsOneWidget);

      await tester.ensureVisible(correctOptionFinder);
      await tester.pumpAndSettle();

      await tester.tap(correctOptionFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify haptic & sound
      verify(() => mockHapticService.selection()).called(1);
      verify(() => mockHapticService.success()).called(1);
      verify(() => mockSoundService.playCorrect()).called(1);
      verify(() => mockReadingBloc.add(const SubmitAnswer(true))).called(1);

      // Verify logic chain is now revealed
      expect(find.byType(ReadingConclusionLogicChain), findsOneWidget);
      expect(find.text('LOGICAL DEDUCTION'), findsOneWidget);
      expect(find.text('Bike left outside overnight'), findsOneWidget);
      expect(find.text('water found on bike'), findsOneWidget);
      expect(find.text('no one touched it'), findsOneWidget);
      expect(find.text('rain fell overnight'), findsOneWidget);
    });

    testWidgets(
        '3. Selecting incorrect option dispatches SubmitAnswer(false), plays wrong SFX, and reveals Logic Chain',
        (tester) async {
      await pumpReadingConclusion(tester);

      final wrongOptionFinder = find.text(
        'Maya washed her bicycle before going to bed.',
      );
      expect(wrongOptionFinder, findsOneWidget);

      await tester.ensureVisible(wrongOptionFinder);
      await tester.pumpAndSettle();

      await tester.tap(wrongOptionFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify error feedback
      verify(() => mockHapticService.selection()).called(1);
      verify(() => mockHapticService.error()).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockReadingBloc.add(const SubmitAnswer(false))).called(1);

      // Verify logic chain is revealed even on incorrect answers to help player learn
      expect(find.byType(ReadingConclusionLogicChain), findsOneWidget);
      expect(find.text('LOGICAL DEDUCTION'), findsOneWidget);
      expect(find.text('rain fell overnight'), findsOneWidget);
    });

    testWidgets(
        '4. Lockout: Tapping options after answer submitted ignores further taps',
        (tester) async {
      await pumpReadingConclusion(tester);

      final correctOptionFinder = find.text('It rained during the night.');
      await tester.ensureVisible(correctOptionFinder);
      await tester.pumpAndSettle();
      await tester.tap(correctOptionFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Reset invocations count on bloc
      clearInteractions(mockReadingBloc);

      // Tap another option
      final anotherOption = find.text('The bicycle was stored inside a garage.');
      await tester.tap(anotherOption, warnIfMissed: false);
      await tester.pump();

      // Verify no further submissions
      verifyNever(() => mockReadingBloc.add(any()));
    });

    testWidgets(
        '5. Post-answer state shows continue button which dispatches NextQuestion',
        (tester) async {
      const answeredState = ReadingLoaded(
        quests: [testConclusionQuest],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.correct,
      );

      await pumpReadingConclusion(tester, state: answeredState);

      final continueBtn = find.text('CONTINUE');
      expect(continueBtn, findsOneWidget);

      await tester.tap(continueBtn);
      await tester.pump();

      verify(() => mockReadingBloc.add(const NextQuestion())).called(1);
    });

    testWidgets(
        '6. Tapping hint button in header dispatches ReadingHintUsed',
        (tester) async {
      await pumpReadingConclusion(tester);

      final hintFinder = find.byType(QuestHintButton);
      expect(hintFinder, findsOneWidget);

      await tester.tap(hintFinder);
      await tester.pump();

      verify(() => mockReadingBloc.add(const ReadingHintUsed())).called(1);
    });

    testWidgets(
        '7. ReadingInitial state renders GameShimmerLoading',
        (tester) async {
      await pumpReadingConclusion(tester, state: const ReadingInitial());

      expect(find.byType(GameShimmerLoading), findsOneWidget);
      expect(find.byType(ReadingConclusionPassage), findsNothing);
    });

    testWidgets(
        '8. Level 1 displays GameBriefingLayer and dismisses on start tap',
        (tester) async {
      await pumpReadingConclusion(tester, level: 1);

      expect(find.byType(GameBriefingLayer), findsOneWidget);
      final startBtn = find.text('PREDICT FINAL');
      expect(startBtn, findsOneWidget);
      await tester.ensureVisible(startBtn);
      await tester.pumpAndSettle();

      await tester.tap(startBtn);
      await tester.pumpAndSettle();

      expect(find.byType(GameBriefingLayer), findsNothing);
    });

    testWidgets(
        '9. Dark theme mode renders cleanly without errors',
        (tester) async {
      await pumpReadingConclusion(tester, themeMode: ThemeMode.dark);

      expect(find.byType(ReadingConclusionPassage), findsOneWidget);
      expect(
        find.textContaining('Maya left her bicycle outside overnight'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        '10. Compact 320dp small screen layout safety with zero overflow',
        (tester) async {
      await pumpReadingConclusion(
        tester,
        width: 320,
        height: 568,
      );

      expect(find.byType(ReadingConclusionScreen), findsOneWidget);
      expect(find.byType(ReadingConclusionPassage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        '11. Empty logic chain edge case does not crash or render LogicChain widget',
        (tester) async {
      const stateWithNoChain = ReadingLoaded(
        quests: [testNoChainQuest],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
      );

      await pumpReadingConclusion(tester, state: stateWithNoChain);

      final optionA = find.text('Option A');
      expect(optionA, findsOneWidget);
      await tester.tap(optionA);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ReadingConclusionLogicChain), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        '12. Multi-step logic chain parses into distinct numbered deduction nodes',
        (tester) async {
      const stateAnswered = ReadingLoaded(
        quests: [testConclusionQuest],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.correct,
      );

      await pumpReadingConclusion(
        tester,
        state: stateAnswered,
        height: 1200,
      );

      final logicChainFinder = find.byType(ReadingConclusionLogicChain);
      expect(logicChainFinder, findsOneWidget);
      expect(find.text('LOGICAL DEDUCTION'), findsOneWidget);
      expect(
        find.descendant(of: logicChainFinder, matching: find.text('1')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: logicChainFinder, matching: find.text('2')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: logicChainFinder, matching: find.text('3')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: logicChainFinder, matching: find.text('4')),
        findsOneWidget,
      );
    });

    testWidgets(
        '13. Instruction text has TextAlign.center and wraps cleanly',
        (tester) async {
      const longInstructionQuest = ReadingQuest(
        id: 'RDG_READINGCONCLUSION_L1_Q_LONG',
        instruction:
            'Carefully analyze the short reading passage and select the single most logical conclusion supported by the text.',
        difficulty: 1,
        subtype: GameSubtype.readingConclusion,
        passage: 'Sample passage text for testing instruction alignment.',
        options: ['Option 1', 'Option 2'],
        correctAnswer: 'Option 1',
      );

      await pumpReadingConclusion(
        tester,
        state: const ReadingLoaded(
          quests: [longInstructionQuest],
          currentIndex: 0,
          livesRemaining: 3,
          answerStatus: AnswerStatus.unanswered,
        ),
      );

      final instructionTextFinder = find.descendant(
        of: find.byType(ReadingConclusionInstruction),
        matching: find.byType(Text),
      );
      expect(instructionTextFinder, findsOneWidget);

      final textWidget = tester.widget<Text>(instructionTextFinder);
      expect(textWidget.textAlign, TextAlign.center);
      expect(textWidget.overflow, isNot(TextOverflow.ellipsis));
    });

    testWidgets(
        '14. Option cards render clean letter indicators (A, B, C, D) without text truncation',
        (tester) async {
      await pumpReadingConclusion(tester);

      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
      expect(find.text('D'), findsOneWidget);

      // Verify no Text has ellipsis overflow in option cards
      final optionTexts = tester.widgetList<Text>(
        find.descendant(
          of: find.byType(ReadingConclusionOptions),
          matching: find.byType(Text),
        ),
      );
      for (final text in optionTexts) {
        expect(text.overflow, isNot(TextOverflow.ellipsis));
      }
    });
  });
}

