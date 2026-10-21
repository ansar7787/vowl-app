import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/game_mechanics/shared/speed_challenge_timer.dart';
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
import 'package:vowl/features/reading/skimming_scanning/presentation/pages/skimming_scanning_screen.dart';
import 'package:vowl/features/reading/skimming_scanning/presentation/widgets/skimming_scanning_target_badge.dart';
import 'package:vowl/features/reading/skimming_scanning/presentation/widgets/skimming_scanning_terminal.dart';

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

  const testScanQuest = ReadingQuest(
    id: 'RDG_SKIMSCAN_L1_Q1',
    instruction: 'Locate the celestial event described in the passage.',
    difficulty: 1,
    subtype: GameSubtype.skimmingScanning,
    targetItem: 'solar flare',
    correctAnswer: 'solar flare',
    passage:
        'Astronomers observed a massive solar flare erupting from the active region of the star, releasing unprecedented bursts of radiation across the solar system.',
    timeLimit: 25,
    hint: 'Look for two-word celestial phenomena.',
    explanation: 'The passage explicitly describes a massive solar flare erupting.',
  );

  const testNextScanQuest = ReadingQuest(
    id: 'RDG_SKIMSCAN_L1_Q2',
    instruction: 'Locate the rare mineral described by the researchers.',
    difficulty: 1,
    subtype: GameSubtype.skimmingScanning,
    targetItem: 'palladium',
    correctAnswer: 'palladium',
    passage:
        'Geologists confirmed that the deep rock core contained trace amounts of palladium, an exceptionally dense and valuable platinum group metal.',
    timeLimit: 20,
    hint: 'Search for the specific chemical element name.',
  );

  const testLoadedState = ReadingLoaded(
    quests: [testScanQuest, testNextScanQuest],
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
  );

  const testAnsweredState = ReadingLoaded(
    quests: [testScanQuest],
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.correct,
  );

  setUp(() async {
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

    VowlMotion.lowAnimationModeOverride.value = true;

    SharedPreferences.setMockInitialValues({
      'has_seen_briefing_skimmingScanning': true,
    });

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

    when(() => mockLocaleService.currentLocale).thenReturn(const Locale('en'));

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

    when(() => mockEconomyBloc.state).thenReturn(const EconomyState());
    when(() => mockEconomyBloc.stream)
        .thenAnswer((_) => const Stream<EconomyState>.empty());

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});
    when(() => mockHapticService.heavy()).thenAnswer((_) async {});
    when(() => mockHapticService.warning()).thenAnswer((_) async {});

    when(() => mockSoundService.playCorrect()).thenAnswer((_) async {});
    when(() => mockSoundService.playWrong()).thenAnswer((_) async {});
    when(() => mockSoundService.playClick()).thenAnswer((_) async {});
    when(() => mockSoundService.playHint()).thenAnswer((_) async {});
    when(() => mockSoundService.stopAudio()).thenAnswer((_) async {});
    when(() => mockSoundService.stopTts()).thenAnswer((_) async {});

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

    di.sl.reset();

    di.sl.registerLazySingleton<HapticService>(() => mockHapticService);
    di.sl.registerLazySingleton<SoundService>(() => mockSoundService);
    di.sl.registerLazySingleton<TtsService>(() => mockTtsService);
    di.sl.registerLazySingleton<LocaleService>(() => mockLocaleService);
    di.sl.registerLazySingleton<AppLogger>(() => mockLogger);
    di.sl.registerLazySingleton<AnalyticsService>(() => mockAnalyticsService);
    di.sl.registerLazySingleton<AdService>(() => mockAdService);
  });

  tearDown(() {
    VowlMotion.lowAnimationModeOverride.value = false;
    di.sl.reset();
  });

  Future<void> pumpSkimmingScanning(
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
            home: SkimmingScanningScreen(
              level: level,
              gameType: GameSubtype.skimmingScanning,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('SkimmingScanningScreen Layout & Interactions', () {
    testWidgets('1. Initial layout renders target badge, timer, instruction, and terminal', (
      tester,
    ) async {
      await pumpSkimmingScanning(tester);

      expect(find.byType(SkimmingScanningTargetBadge), findsOneWidget);
      expect(find.text('FIND: SOLAR FLARE'), findsOneWidget);
      expect(find.byType(SpeedChallengeTimer), findsOneWidget);
      expect(find.text('Tap the target in the text below'), findsOneWidget);
      expect(find.byType(SkimmingScanningTerminal), findsOneWidget);
      expect(find.text('solar flare'), findsOneWidget);
    });

    testWidgets('2. Multi-word target combines into single tappable chunk in terminal', (
      tester,
    ) async {
      await pumpSkimmingScanning(tester);

      expect(find.text('solar flare'), findsOneWidget);
      expect(find.text('flare'), findsNothing);
    });

    testWidgets('3. Tapping correct target word dispatches SubmitAnswer(true) with success feedback', (
      tester,
    ) async {
      await pumpSkimmingScanning(tester);

      final targetWordFinder = find.text('solar flare');
      expect(targetWordFinder, findsOneWidget);

      await tester.tap(targetWordFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockSoundService.playCorrect()).called(1);
      verify(() => mockHapticService.success()).called(1);
      verify(() => mockReadingBloc.add(const SubmitAnswer(true))).called(1);
    });

    testWidgets('4. Tapping incorrect word dispatches SubmitAnswer(false) with error feedback', (
      tester,
    ) async {
      await pumpSkimmingScanning(tester);

      final wrongWordFinder = find.text('Astronomers');
      expect(wrongWordFinder, findsOneWidget);

      await tester.tap(wrongWordFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockHapticService.error()).called(1);
      verify(() => mockReadingBloc.add(const SubmitAnswer(false))).called(1);
    });

    testWidgets('5. Countdown timer expiry auto-submits incorrect answer', (
      tester,
    ) async {
      await pumpSkimmingScanning(tester);

      final timer = tester.widget<SpeedChallengeTimer>(
        find.byType(SpeedChallengeTimer),
      );
      timer.onTimeUp();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockHapticService.error()).called(1);
      verify(() => mockReadingBloc.add(const SubmitAnswer(false))).called(1);
    });

    testWidgets('6. Interaction lockout disables further taps once answered', (
      tester,
    ) async {
      final stateController = StreamController<ReadingState>.broadcast();
      when(() => mockReadingBloc.stream).thenAnswer((_) => stateController.stream);

      await pumpSkimmingScanning(tester);

      // Transition to answered state
      stateController.add(testAnsweredState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));

      // Timer and prompt should be removed
      expect(find.byType(SpeedChallengeTimer), findsNothing);
      expect(find.text('Tap the target in the text below'), findsNothing);
      expect(find.text('TARGET FOUND!'), findsOneWidget);

      // Tapping target again should NOT trigger any additional submits
      clearInteractions(mockReadingBloc);
      final word = find.text('solar flare');
      await tester.tap(word, warnIfMissed: false);
      await tester.pump();

      verifyNever(() => mockReadingBloc.add(any(that: isA<SubmitAnswer>())));

      await stateController.close();
    });

    testWidgets('7. Continue button dispatches NextQuestion event in answered state', (
      tester,
    ) async {
      await pumpSkimmingScanning(tester, state: testAnsweredState);
      await tester.pump(const Duration(milliseconds: 600));

      final continueButton = find.text('CONTINUE');
      expect(continueButton, findsOneWidget);

      await tester.tap(continueButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockReadingBloc.add(const NextQuestion())).called(1);
    });

    testWidgets('8. Hint button in header dispatches ReadingHintUsed', (tester) async {
      await pumpSkimmingScanning(tester);

      final hintButton = find.byType(QuestHintButton);
      expect(hintButton, findsOneWidget);

      await tester.tap(hintButton);
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockReadingBloc.add(any(that: isA<ReadingHintUsed>()))).called(1);
    });

    testWidgets('9. Shimmer loading renders when state is ReadingInitial', (
      tester,
    ) async {
      await pumpSkimmingScanning(tester, state: const ReadingInitial());

      expect(find.byType(GameShimmerLoading), findsOneWidget);
      expect(find.byType(SkimmingScanningTerminal), findsNothing);
    });

    testWidgets('10. Game briefing layer renders on Level 1 and dismisses on action', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'has_seen_briefing_skimmingScanning': false,
      });

      await pumpSkimmingScanning(tester, level: 1);

      expect(find.byType(GameBriefingLayer), findsOneWidget);
      expect(find.text('SKIM & SCAN'), findsOneWidget);
      final startBtn = find.text('START SCANNING');
      expect(startBtn, findsOneWidget);

      await tester.ensureVisible(startBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(startBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(GameBriefingLayer), findsNothing);
      expect(find.byType(SkimmingScanningTerminal), findsOneWidget);
    });

    testWidgets('11. Dark theme renders cleanly without visual contrast defects', (
      tester,
    ) async {
      await pumpSkimmingScanning(tester, themeMode: ThemeMode.dark);

      expect(find.byType(SkimmingScanningTargetBadge), findsOneWidget);
      expect(find.byType(SkimmingScanningTerminal), findsOneWidget);
    });

    testWidgets('12. Small screen (320x640) renders without layout overflow', (
      tester,
    ) async {
      await pumpSkimmingScanning(tester, width: 320, height: 640);

      expect(tester.takeException(), isNull);
      expect(find.byType(SkimmingScanningTargetBadge), findsOneWidget);
      expect(find.byType(SkimmingScanningTerminal), findsOneWidget);
    });

    testWidgets('13. Question reset cleanly loads next quest and target item', (
      tester,
    ) async {
      final stateController = StreamController<ReadingState>.broadcast();
      when(() => mockReadingBloc.stream).thenAnswer((_) => stateController.stream);

      await pumpSkimmingScanning(tester);
      expect(find.text('FIND: SOLAR FLARE'), findsOneWidget);

      // Emit second question
      stateController.add(
        const ReadingLoaded(
          quests: [testNextScanQuest],
          currentIndex: 0,
          livesRemaining: 3,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('FIND: PALLADIUM'), findsOneWidget);
      expect(find.textContaining('palladium'), findsWidgets);

      await stateController.close();
    });

    testWidgets('14. Multi-line instruction and interaction prompt wrap with centered text and no ellipses', (
      tester,
    ) async {
      const longInstructionQuest = ReadingQuest(
        id: 'RDG_SKIMSCAN_LONG_Q',
        instruction:
            'Carefully scan through the scientific journal passage below to identify and tap the precise name of the rare atmospheric phenomenon observed during the expedition.',
        difficulty: 1,
        subtype: GameSubtype.skimmingScanning,
        targetItem: 'auroral arc display',
        correctAnswer: 'auroral arc display',
        passage:
            'The arctic research team recorded a distinct auroral arc display expanding across the northern sky at midnight.',
        timeLimit: 30,
      );

      await pumpSkimmingScanning(
        tester,
        state: const ReadingLoaded(
          quests: [longInstructionQuest],
          currentIndex: 0,
          livesRemaining: 3,
        ),
        width: 320,
        height: 640,
      );

      // Verify no overflow exception was thrown
      expect(tester.takeException(), isNull);

      // Verify instruction text exists and has TextAlign.center
      final instructionFinder = find.text(
        'Carefully scan through the scientific journal passage below to identify and tap the precise name of the rare atmospheric phenomenon observed during the expedition.',
      );
      expect(instructionFinder, findsOneWidget);
      final instructionWidget = tester.widget<Text>(instructionFinder);
      expect(instructionWidget.textAlign, TextAlign.center);
      expect(instructionWidget.overflow, isNot(TextOverflow.ellipsis));

      // Verify interaction prompt text exists and has TextAlign.center with no ellipsis
      final promptFinder = find.text('Tap the target in the text below');
      expect(promptFinder, findsOneWidget);
      final promptWidget = tester.widget<Text>(promptFinder);
      expect(promptWidget.textAlign, TextAlign.center);
      expect(promptWidget.overflow, isNot(TextOverflow.ellipsis));

      // Verify target badge text has TextAlign.center with no ellipsis
      final targetBadgeTextFinder = find.text('FIND: AURORAL ARC DISPLAY');
      expect(targetBadgeTextFinder, findsOneWidget);
      final targetBadgeTextWidget = tester.widget<Text>(targetBadgeTextFinder);
      expect(targetBadgeTextWidget.textAlign, TextAlign.center);
      expect(targetBadgeTextWidget.overflow, isNot(TextOverflow.ellipsis));
    });
  });
}

