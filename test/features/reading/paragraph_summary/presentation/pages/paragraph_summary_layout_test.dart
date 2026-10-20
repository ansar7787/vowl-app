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
import 'package:vowl/features/reading/paragraph_summary/presentation/pages/paragraph_summary_screen.dart';
import 'package:vowl/features/reading/paragraph_summary/presentation/widgets/paragraph_summary_instruction.dart';
import 'package:vowl/features/reading/paragraph_summary/presentation/widgets/paragraph_summary_option_rack.dart';
import 'package:vowl/features/reading/paragraph_summary/presentation/widgets/paragraph_summary_tube.dart';
import 'package:vowl/features/reading/paragraph_summary/presentation/widgets/pinch_hint_animation.dart';
import 'package:vowl/features/reading/presentation/bloc/reading_bloc.dart';

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

  const testSummaryQuest = ReadingQuest(
    id: 'RDG_PARAGRAPHSUMMARY_L1_Q1',
    instruction: 'Choose the best summary for the paragraph.',
    difficulty: 1,
    subtype: GameSubtype.paragraphSummary,
    passage:
        'Amara gets up early on school days. She packs her bag, eats rice and eggs, and catches the bus at seven. By half past seven, she is sitting at her desk.',
    keywords: [
      'School Morning',
      'Getting Ready',
      'Bus to School',
    ],
    options: [
      'Amara is often late for the school bus in the mornings.',
      'Amara gets ready and travels to school in the morning.',
      'Amara studies quietly at her desk after school ends.',
      'Amara eats rice and eggs for breakfast before she leaves home.',
    ],
    correctAnswer: 'Amara gets ready and travels to school in the morning.',
    hint:
        'Ask what the whole paragraph is about, not what happens in just one sentence.',
    explanation:
        'The paragraph follows Amara from waking up to sitting at her desk, so the main idea is her whole morning journey to school.',
    keyPoints: [
      'Amara has a regular morning routine on school days.',
      'She packs her bag, eats breakfast and takes the bus.',
      'The routine gets her to her desk by half past seven.',
    ],
  );

  const testLoadedState = ReadingLoaded(
    quests: [testSummaryQuest],
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

    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    if (di.sl.isRegistered<SoundService>()) di.sl.unregister<SoundService>();
    if (di.sl.isRegistered<TtsService>()) di.sl.unregister<TtsService>();
    if (di.sl.isRegistered<LocaleService>()) di.sl.unregister<LocaleService>();
    if (di.sl.isRegistered<AppLogger>()) di.sl.unregister<AppLogger>();
    if (di.sl.isRegistered<AnalyticsService>()) {
      di.sl.unregister<AnalyticsService>();
    }
    if (di.sl.isRegistered<AdService>()) di.sl.unregister<AdService>();

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

  Future<void> pumpParagraphSummary(
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
              body: ParagraphSummaryScreen(level: level),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('ParagraphSummaryScreen - Production Layout & Mechanics Tests', () {
    testWidgets(
        '1. Initial rendering of instruction, passage tube, and pinch animation',
        (tester) async {
      await pumpParagraphSummary(tester);

      // Verify instruction pill
      expect(find.byType(ParagraphSummaryInstruction), findsOneWidget);
      expect(
        find.textContaining('summary for the paragraph'),
        findsOneWidget,
      );

      // Verify tube with passage text
      expect(find.byType(ParagraphSummaryTube), findsOneWidget);
      expect(
        find.textContaining('Amara gets up early on school days'),
        findsOneWidget,
      );

      // Verify pinch hint animation and instruction
      expect(find.byType(PinchHintAnimation), findsOneWidget);
      expect(
        find.text('Pinch or tap the card to reveal key ideas'),
        findsOneWidget,
      );

      // Verify option rack is not yet visible before distillation
      expect(find.byType(ParagraphSummaryOptionRack), findsNothing);
    });

    testWidgets(
        '2. Tapping tube distills passage into keywords and reveals option rack',
        (tester) async {
      await pumpParagraphSummary(tester);

      // Tap on the tube to trigger distillation
      final tubeFinder = find.byType(ParagraphSummaryTube);
      expect(tubeFinder, findsOneWidget);

      await tester.tap(tubeFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify heavy haptic feedback was triggered
      verify(() => mockHapticService.heavy()).called(1);

      // Verify PinchHintAnimation is gone
      expect(find.byType(PinchHintAnimation), findsNothing);

      // Verify distillation complete message
      expect(
        find.text('Choose the best summary below:'),
        findsOneWidget,
      );

      // Verify keywords are revealed inside the tube
      expect(find.text('School Morning'), findsOneWidget);
      expect(find.text('Getting Ready'), findsOneWidget);
      expect(find.text('Bus to School'), findsOneWidget);

      // Verify ParagraphSummaryOptionRack is revealed with options
      expect(find.byType(ParagraphSummaryOptionRack), findsOneWidget);
      expect(
        find.text('Amara gets ready and travels to school in the morning.'),
        findsOneWidget,
      );
      expect(
        find.text('Amara is often late for the school bus in the mornings.'),
        findsOneWidget,
      );
    });

    testWidgets(
        '3. Pinch gesture on tube distills passage and reveals option rack',
        (tester) async {
      await pumpParagraphSummary(tester);

      // Perform a pinch gesture (scale from 1.0 down to 0.4)
      final tubeFinder = find.byType(ParagraphSummaryTube);
      final center = tester.getCenter(tubeFinder);

      // Start pinch gesture with two pointers
      final pointer1 = await tester.startGesture(center + const Offset(-60, 0));
      final pointer2 = await tester.startGesture(center + const Offset(60, 0));
      await tester.pump(const Duration(milliseconds: 50));

      // Move pointers together to simulate pinch
      await pointer1.moveTo(center + const Offset(-10, 0));
      await pointer2.moveTo(center + const Offset(10, 0));
      await tester.pump(const Duration(milliseconds: 50));

      await pointer1.up();
      await pointer2.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify heavy haptic and distillation
      verify(() => mockHapticService.heavy()).called(1);
      expect(
        find.text('Choose the best summary below:'),
        findsOneWidget,
      );
      expect(find.byType(ParagraphSummaryOptionRack), findsOneWidget);
    });

    testWidgets(
        '4. Selecting correct summary option dispatches SubmitAnswer(true) and plays success SFX',
        (tester) async {
      await pumpParagraphSummary(tester);

      // Distill tube
      await tester.tap(find.byType(ParagraphSummaryTube));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Tap on correct option
      final correctOption = find.text(
        'Amara gets ready and travels to school in the morning.',
      );
      expect(correctOption, findsOneWidget);
      await tester.ensureVisible(correctOption);
      await tester.pumpAndSettle();

      await tester.tap(correctOption);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));

      // Verify feedback and submission
      verify(() => mockHapticService.success()).called(1);
      verify(() => mockSoundService.playCorrect()).called(1);
      verify(() => mockReadingBloc.add(const SubmitAnswer(true))).called(1);
    });

    testWidgets(
        '5. Selecting incorrect summary option dispatches SubmitAnswer(false) and plays wrong SFX',
        (tester) async {
      await pumpParagraphSummary(tester);

      // Distill tube
      await tester.tap(find.byType(ParagraphSummaryTube));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Tap on incorrect option
      final wrongOption = find.text(
        'Amara is often late for the school bus in the mornings.',
      );
      expect(wrongOption, findsOneWidget);
      await tester.ensureVisible(wrongOption);
      await tester.pumpAndSettle();

      await tester.tap(wrongOption);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));

      // Verify wrong feedback and submission
      verify(() => mockHapticService.error()).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockReadingBloc.add(const SubmitAnswer(false))).called(1);
    });

    testWidgets(
        '6. Lockout: Tapping options after answer submitted ignores further taps',
        (tester) async {
      await pumpParagraphSummary(tester);

      // Distill tube
      await tester.tap(find.byType(ParagraphSummaryTube));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Tap correct option once
      final correctOption = find.text(
        'Amara gets ready and travels to school in the morning.',
      );
      await tester.ensureVisible(correctOption);
      await tester.pumpAndSettle();
      await tester.tap(correctOption);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Clear invocations count
      clearInteractions(mockReadingBloc);

      // Tap another option
      final wrongOption = find.text(
        'Amara is often late for the school bus in the mornings.',
      );
      await tester.tap(wrongOption, warnIfMissed: false);
      await tester.pump();

      // Verify no further submissions
      verifyNever(() => mockReadingBloc.add(any()));
    });

    testWidgets(
        '7. Post-answer state shows continue button which dispatches NextQuestion',
        (tester) async {
      const answeredState = ReadingLoaded(
        quests: [testSummaryQuest],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.correct,
      );

      await pumpParagraphSummary(tester, state: answeredState);

      final continueBtn = find.text('CONTINUE');
      expect(continueBtn, findsOneWidget);

      await tester.tap(continueBtn);
      await tester.pump();

      verify(() => mockReadingBloc.add(const NextQuestion())).called(1);
    });

    testWidgets(
        '8. Tapping hint button in header dispatches ReadingHintUsed',
        (tester) async {
      await pumpParagraphSummary(tester);

      final hintFinder = find.byType(QuestHintButton);
      expect(hintFinder, findsOneWidget);

      await tester.tap(hintFinder);
      await tester.pump();

      // ReadingHeader calls bloc add internally and invokes widget.onHint
      verify(() => mockReadingBloc.add(const ReadingHintUsed())).called(2);
    });

    testWidgets(
        '9. ReadingInitial state renders GameShimmerLoading',
        (tester) async {
      await pumpParagraphSummary(tester, state: const ReadingInitial());

      expect(find.byType(GameShimmerLoading), findsOneWidget);
      expect(find.byType(ParagraphSummaryTube), findsNothing);
    });

    testWidgets(
        '10. Level 1 displays GameBriefingLayer and dismisses on start tap',
        (tester) async {
      await pumpParagraphSummary(tester, level: 1);

      expect(find.byType(GameBriefingLayer), findsOneWidget);
      final startBtn = find.text('SUMMARIZE NOW');
      expect(startBtn, findsOneWidget);
      await tester.ensureVisible(startBtn);
      await tester.pumpAndSettle();

      await tester.tap(startBtn);
      await tester.pumpAndSettle();

      expect(find.byType(GameBriefingLayer), findsNothing);
    });

    testWidgets(
        '11. Dark theme mode renders cleanly without errors',
        (tester) async {
      await pumpParagraphSummary(tester, themeMode: ThemeMode.dark);

      expect(find.byType(ParagraphSummaryTube), findsOneWidget);
      expect(
        find.textContaining('Amara gets up early on school days'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        '12. Compact 320dp small screen layout safety with zero overflow',
        (tester) async {
      await pumpParagraphSummary(
        tester,
        width: 320,
        height: 568,
      );

      expect(find.byType(ParagraphSummaryScreen), findsOneWidget);
      expect(find.byType(ParagraphSummaryTube), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

