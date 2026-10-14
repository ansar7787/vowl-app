import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/game_mechanics/reading/evidence_highlight_wrapper.dart';
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
import 'package:vowl/features/reading/reading_inference/presentation/pages/reading_inference_screen.dart';
import 'package:vowl/features/reading/reading_inference/presentation/widgets/reading_inference_foggy_mirror.dart';
import 'package:vowl/features/reading/reading_inference/presentation/widgets/reading_inference_instruction.dart';
import 'package:vowl/features/reading/reading_inference/presentation/widgets/reading_inference_option.dart';

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

  const testInferenceWithClues = ReadingQuest(
    id: 'RDG_READINGINFERENCE_L1_Q1',
    instruction: 'Read the passage and select the correct inference.',
    difficulty: 1,
    subtype: GameSubtype.readingInference,
    passage:
        '[Morning Routine] Every morning at seven, Kofi makes his bed, feeds his cat, and sits down to breakfast.',
    question: "What do Kofi's morning habits suggest?",
    options: [
      'He has to hurry to get to work on time.',
      'They follow the same pattern each day.',
      'He prefers cooking to any other activity.',
      'He lives alone with his cat.',
    ],
    correctAnswer: 'They follow the same pattern each day.',
    hint: 'Notice the word "every" and the order of his tasks.',
    explanation:
        'Kofi does the same tasks, in the same order, at the same time each morning.',
    clueWords: [
      'Every morning at seven',
      'makes his bed, feeds his cat',
    ],
  );

  const testDirectInferenceQuest = ReadingQuest(
    id: 'RDG_READINGINFERENCE_L1_Q2',
    instruction: 'Select the correct inference.',
    difficulty: 1,
    subtype: GameSubtype.readingInference,
    passage: 'Direct inference without clue words.',
    question: 'What is the direct inference?',
    options: ['Option Correct', 'Option Wrong'],
    correctAnswer: 'Option Correct',
    clueWords: [],
  );

  const testLoadedState = ReadingLoaded(
    quests: [testInferenceWithClues],
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

  Future<void> pumpReadingInference(
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
              body: ReadingInferenceScreen(level: level),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('ReadingInferenceScreen - Production Layout & Mechanics Tests', () {
    testWidgets(
        '1. Initial rendering with instruction, foggy mirror, question, and auto-clear button',
        (tester) async {
      await pumpReadingInference(tester);

      // Verify instruction pill
      expect(find.byType(ReadingInferenceInstruction), findsOneWidget);
      expect(
        find.textContaining('SELECT THE CORRECT INFERENCE'),
        findsOneWidget,
      );

      // Verify foggy mirror with passage text
      expect(find.byType(ReadingInferenceFoggyMirror), findsOneWidget);
      expect(
        find.textContaining('Every morning at seven, Kofi makes his bed'),
        findsOneWidget,
      );

      // Verify Auto-Clear Fog button
      expect(find.text('Auto-Clear Fog'), findsOneWidget);

      // Verify question text
      expect(find.text("What do Kofi's morning habits suggest?"), findsOneWidget);

      // Verify 4 options rendered
      expect(find.byType(ReadingInferenceOption), findsNWidgets(4));
    });

    testWidgets(
        '2. Tapping Auto-Clear Fog sets clarity to 1.0 and hides auto-clear button',
        (tester) async {
      await pumpReadingInference(tester);

      final autoClearBtn = find.text('Auto-Clear Fog');
      expect(autoClearBtn, findsOneWidget);

      await tester.tap(autoClearBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      verify(() => mockHapticService.selection()).called(1);
      expect(find.text('Auto-Clear Fog'), findsNothing);
    });

    testWidgets(
        '3. Rubbing on foggy mirror adds rub points and clears fog progressively',
        (tester) async {
      await pumpReadingInference(tester);

      final mirrorFinder = find.byType(ReadingInferenceFoggyMirror);
      expect(mirrorFinder, findsOneWidget);

      // Tap across the mirror at multiple offsets to record >= 5 rub points
      final center = tester.getCenter(mirrorFinder);
      for (int i = 0; i < 10; i++) {
        await tester.tapAt(center + Offset(i * 4.0, (i % 2) * 5.0));
        await tester.pump(const Duration(milliseconds: 20));
      }

      // Verify selection haptic triggered by rub points % 5 == 0
      verify(() => mockHapticService.selection()).called(greaterThanOrEqualTo(1));
    });

    testWidgets(
        '4. Options are disabled when clarity < 0.3, tapping does not submit answer',
        (tester) async {
      await pumpReadingInference(tester);

      // Tap option while clarity is 0.0
      final correctOption = find.text('They follow the same pattern each day.');
      await tester.tap(correctOption, warnIfMissed: false);
      await tester.pump();

      // Verify no SubmitAnswer event was dispatched
      verifyNever(() => mockReadingBloc.add(any(that: isA<SubmitAnswer>())));
    });

    testWidgets(
        '5. Selecting correct option on direct quest (no clue words) dispatches SubmitAnswer(true) immediately',
        (tester) async {
      const directState = ReadingLoaded(
        quests: [testDirectInferenceQuest],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
      );

      await pumpReadingInference(tester, state: directState);

      // Clear fog first
      await tester.tap(find.text('Auto-Clear Fog'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap correct option
      final correctOption = find.text('Option Correct');
      await tester.ensureVisible(correctOption);
      await tester.pumpAndSettle();

      await tester.tap(correctOption);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockHapticService.success()).called(1);
      verify(() => mockSoundService.playCorrect()).called(1);
      verify(() => mockReadingBloc.add(const SubmitAnswer(true))).called(1);
    });

    testWidgets(
        '6. Selecting correct option on quest with clue words reveals EvidenceHighlightWrapper',
        (tester) async {
      await pumpReadingInference(tester);

      // Clear fog first
      await tester.tap(find.text('Auto-Clear Fog'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap correct option
      final correctOption = find.text('They follow the same pattern each day.');
      await tester.ensureVisible(correctOption);
      await tester.pumpAndSettle();

      await tester.tap(correctOption);
      await tester.pump();
      // Wait for the 600ms delayed evidence phase trigger
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump(const Duration(milliseconds: 500));

      // Verify evidence wrapper appears
      expect(find.byType(EvidenceHighlightWrapper), findsOneWidget);
      expect(
        find.textContaining('Highlight the clue words that gave you the answer!'),
        findsOneWidget,
      );
    });

    testWidgets(
        '7. Highlighting evidence in EvidenceHighlightWrapper completes question and dispatches SubmitAnswer(true)',
        (tester) async {
      await pumpReadingInference(tester);

      // Clear fog
      await tester.tap(find.text('Auto-Clear Fog'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap correct option
      final correctOption = find.text('They follow the same pattern each day.');
      await tester.ensureVisible(correctOption);
      await tester.pumpAndSettle();
      await tester.tap(correctOption);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(EvidenceHighlightWrapper), findsOneWidget);

      // Scroll to evidence clue word in the wrapper ('Every') and tap
      final clueFinder = find.text('Every');
      expect(clueFinder, findsOneWidget);
      await tester.ensureVisible(clueFinder);
      await tester.pumpAndSettle();

      await tester.tap(clueFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      // Verify completion
      verify(() => mockReadingBloc.add(const SubmitAnswer(true))).called(1);
    });

    testWidgets(
        '8. Selecting incorrect option dispatches SubmitAnswer(false) and plays wrong SFX',
        (tester) async {
      await pumpReadingInference(tester);

      // Clear fog
      await tester.tap(find.text('Auto-Clear Fog'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap wrong option
      final wrongOption = find.text('He has to hurry to get to work on time.');
      await tester.ensureVisible(wrongOption);
      await tester.pumpAndSettle();

      await tester.tap(wrongOption);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockHapticService.error()).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockReadingBloc.add(const SubmitAnswer(false))).called(1);
    });

    testWidgets(
        '9. Lockout: Tapping options after answer submitted ignores further taps',
        (tester) async {
      await pumpReadingInference(tester);

      // Clear fog
      await tester.tap(find.text('Auto-Clear Fog'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap wrong option to submit
      final wrongOption = find.text('He has to hurry to get to work on time.');
      await tester.ensureVisible(wrongOption);
      await tester.pumpAndSettle();
      await tester.tap(wrongOption);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      clearInteractions(mockReadingBloc);

      // Tap another option
      final anotherOption = find.text('He prefers cooking to any other activity.');
      await tester.tap(anotherOption, warnIfMissed: false);
      await tester.pump();

      verifyNever(() => mockReadingBloc.add(any()));
    });

    testWidgets(
        '10. Post-answer state shows continue button which dispatches NextQuestion',
        (tester) async {
      const answeredState = ReadingLoaded(
        quests: [testDirectInferenceQuest],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.correct,
      );

      await pumpReadingInference(tester, state: answeredState);

      final continueBtn = find.text('CONTINUE');
      expect(continueBtn, findsOneWidget);

      await tester.tap(continueBtn);
      await tester.pump();

      verify(() => mockReadingBloc.add(const NextQuestion())).called(1);
    });

    testWidgets(
        '11. Tapping hint button in header dispatches ReadingHintUsed',
        (tester) async {
      await pumpReadingInference(tester);

      final hintFinder = find.byType(QuestHintButton);
      expect(hintFinder, findsOneWidget);

      await tester.tap(hintFinder);
      await tester.pump();

      verify(() => mockReadingBloc.add(const ReadingHintUsed())).called(2);
    });

    testWidgets(
        '12. ReadingInitial state renders GameShimmerLoading',
        (tester) async {
      await pumpReadingInference(tester, state: const ReadingInitial());

      expect(find.byType(GameShimmerLoading), findsOneWidget);
      expect(find.byType(ReadingInferenceFoggyMirror), findsNothing);
    });

    testWidgets(
        '13. Level 1 displays GameBriefingLayer and dismisses on start tap',
        (tester) async {
      await pumpReadingInference(tester, level: 1);

      expect(find.byType(GameBriefingLayer), findsOneWidget);
      final startBtn = find.text('DEDUCE SUBTEXT');
      expect(startBtn, findsOneWidget);
      await tester.ensureVisible(startBtn);
      await tester.pumpAndSettle();

      await tester.tap(startBtn);
      await tester.pumpAndSettle();

      expect(find.byType(GameBriefingLayer), findsNothing);
    });

    testWidgets(
        '14. Dark theme mode renders cleanly without errors',
        (tester) async {
      await pumpReadingInference(tester, themeMode: ThemeMode.dark);

      expect(find.byType(ReadingInferenceFoggyMirror), findsOneWidget);
      expect(
        find.textContaining('Every morning at seven, Kofi makes his bed'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        '15. Compact 320dp small screen layout safety with zero overflow',
        (tester) async {
      await pumpReadingInference(
        tester,
        width: 320,
        height: 568,
      );

      expect(find.byType(ReadingInferenceScreen), findsOneWidget);
      expect(find.byType(ReadingInferenceFoggyMirror), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

