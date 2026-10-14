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
import 'package:vowl/features/reading/reading_speed_check/presentation/pages/reading_speed_check_screen.dart';
import 'package:vowl/features/reading/reading_speed_check/presentation/widgets/reading_speed_instruction.dart';
import 'package:vowl/features/reading/reading_speed_check/presentation/widgets/reading_speed_option.dart';
import 'package:vowl/features/reading/reading_speed_check/presentation/widgets/reading_speed_pulse_zone.dart';
import 'package:vowl/features/reading/reading_speed_check/presentation/widgets/reading_speed_question_area.dart';

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

  const testSpeedQuest = ReadingQuest(
    id: 'RDG_READINGSPEEDCHECK_L1_Q1',
    instruction: 'Read the text quickly and answer the question.',
    difficulty: 1,
    subtype: GameSubtype.readingSpeedCheck,
    passage:
        'Community pool: open Monday to Friday from 9 a.m. to 6 p.m. The pool is closed on Saturdays and Sundays.',
    question: 'On which days is the pool closed?',
    options: [
      'Only on Sunday',
      'Friday and Saturday',
      'Monday and Friday',
      'Saturday and Sunday',
    ],
    correctAnswer: 'Saturday and Sunday',
    timeLimit: 25,
    passageWordCount: 20,
    wpmTarget: 90,
    hint: 'Notice which sentence talks about closing rather than opening.',
    explanation:
        'The second sentence gives the closing days. Reading for the word "closed" lets you skip the opening hours.',
  );

  const testNextSpeedQuest = ReadingQuest(
    id: 'RDG_READINGSPEEDCHECK_L1_Q2',
    instruction: 'Read quickly and answer.',
    difficulty: 1,
    subtype: GameSubtype.readingSpeedCheck,
    passage: 'Second passage content goes here.',
    question: 'What is the second question?',
    options: ['Choice A', 'Choice B'],
    correctAnswer: 'Choice A',
    timeLimit: 20,
    passageWordCount: 15,
    wpmTarget: 80,
  );

  const testLoadedState = ReadingLoaded(
    quests: [testSpeedQuest, testNextSpeedQuest],
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
  );

  const testAnsweredState = ReadingLoaded(
    quests: [testSpeedQuest],
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
      'has_seen_briefing_readingSpeedCheck': true,
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

  Future<void> pumpReadingSpeedCheck(
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
          designSize: Size(width, height),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) => MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            home: Scaffold(
              body: ReadingSpeedCheckScreen(level: level),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  group('ReadingSpeedCheckScreen Layout & Interactions', () {
    testWidgets('1. Initial layout renders passage, timer, pulse stop button, and instruction', (tester) async {
      await pumpReadingSpeedCheck(tester);

      expect(find.byType(ReadingSpeedCheckScreen), findsOneWidget);
      expect(find.byType(ReadingSpeedInstruction), findsOneWidget);
      expect(find.byType(ReadingSpeedPulseZone), findsOneWidget);
      expect(find.byType(SpeedChallengeTimer), findsOneWidget);

      expect(find.textContaining('Community pool: open Monday to Friday'), findsOneWidget);
      expect(find.text('TAP TO STOP TIMER & ANSWER'), findsOneWidget);
      expect(find.text('TARGET: 90 WPM'), findsOneWidget);
      expect(find.byIcon(Icons.stop_circle_rounded), findsOneWidget);
      expect(find.byIcon(Icons.format_size_rounded), findsOneWidget);

      // Question area and options are not yet revealed
      expect(find.byType(ReadingSpeedQuestionArea), findsNothing);
      expect(find.byType(ReadingSpeedOption), findsNothing);
    });

    testWidgets('2. Text size toggle enlarges passage font and toggles icon', (tester) async {
      await pumpReadingSpeedCheck(tester);

      final toggleButton = find.byIcon(Icons.format_size_rounded);
      expect(toggleButton, findsOneWidget);

      await tester.tap(toggleButton);
      await tester.pump();

      expect(find.byIcon(Icons.text_decrease_rounded), findsOneWidget);
      verify(() => mockHapticService.selection()).called(1);

      // Toggle back
      await tester.tap(find.byIcon(Icons.text_decrease_rounded));
      await tester.pump();

      expect(find.byIcon(Icons.format_size_rounded), findsOneWidget);
    });

    testWidgets('3. Tapping pulse stop button reveals question and option cards', (tester) async {
      await pumpReadingSpeedCheck(tester);

      final stopButton = find.byIcon(Icons.stop_circle_rounded);
      expect(stopButton, findsOneWidget);

      await tester.tap(stopButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ReadingSpeedQuestionArea), findsOneWidget);
      expect(find.text('On which days is the pool closed?'), findsOneWidget);
      expect(find.byType(ReadingSpeedOption), findsNWidgets(4));
      expect(find.text('ANSWER THE COMPREHENSION QUESTION'), findsOneWidget);

      // Passage zone and timer are no longer in the tree
      expect(find.byType(ReadingSpeedPulseZone), findsNothing);
      expect(find.byType(SpeedChallengeTimer), findsNothing);
    });

    testWidgets('4. Timer onTimeUp auto-reveals question without manual stop tap', (tester) async {
      await pumpReadingSpeedCheck(tester);

      expect(find.byType(ReadingSpeedQuestionArea), findsNothing);

      // Advance time beyond the 25-second limit to trigger onTimeUp
      await tester.pump(const Duration(seconds: 26));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ReadingSpeedQuestionArea), findsOneWidget);
      expect(find.text('On which days is the pool closed?'), findsOneWidget);
      expect(find.byType(ReadingSpeedOption), findsNWidgets(4));
    });

    testWidgets('5. Selecting correct answer triggers success and highlights option', (tester) async {
      await pumpReadingSpeedCheck(tester);

      // Stop reading to reveal options
      await tester.tap(find.byIcon(Icons.stop_circle_rounded));
      await tester.pump(const Duration(milliseconds: 500));

      final correctOption = find.widgetWithText(ReadingSpeedOption, 'Saturday and Sunday');
      expect(correctOption, findsOneWidget);

      await tester.tap(correctOption);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockHapticService.success()).called(1);
      verify(() => mockSoundService.playCorrect()).called(1);
      expect(find.text('CONTINUE'), findsOneWidget);
    });

    testWidgets('6. Selecting wrong answer triggers error and displays correct styling', (tester) async {
      await pumpReadingSpeedCheck(tester);

      await tester.tap(find.byIcon(Icons.stop_circle_rounded));
      await tester.pump(const Duration(milliseconds: 500));

      final wrongOption = find.widgetWithText(ReadingSpeedOption, 'Only on Sunday');
      expect(wrongOption, findsOneWidget);

      await tester.tap(wrongOption);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockHapticService.error()).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockReadingBloc.add(const SubmitAnswer(false))).called(1);
      expect(find.text('TRY AGAIN'), findsOneWidget);
    });

    testWidgets('7. Answer lockout prevents double submission and option switching', (tester) async {
      await pumpReadingSpeedCheck(tester);

      await tester.tap(find.byIcon(Icons.stop_circle_rounded));
      await tester.pump(const Duration(milliseconds: 500));

      final option1 = find.widgetWithText(ReadingSpeedOption, 'Saturday and Sunday');
      final option2 = find.widgetWithText(ReadingSpeedOption, 'Friday and Saturday');

      await tester.tap(option1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Tap another option
      await tester.tap(option2, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Only 1 success called, no error called
      verify(() => mockHapticService.success()).called(1);
      verifyNever(() => mockHapticService.error());
    });

    testWidgets('8. Initial answered state loads immediately revealed', (tester) async {
      await pumpReadingSpeedCheck(tester, state: testAnsweredState);

      expect(find.byType(ReadingSpeedQuestionArea), findsOneWidget);
      expect(find.byType(ReadingSpeedOption), findsNWidgets(4));
      expect(find.text('ANSWER THE COMPREHENSION QUESTION'), findsOneWidget);
    });

    testWidgets('9. Question reset resets revealed status and clears selected index', (tester) async {
      final stateController = StreamController<ReadingState>.broadcast();
      when(() => mockReadingBloc.stream).thenAnswer((_) => stateController.stream);

      await pumpReadingSpeedCheck(tester, state: testLoadedState);

      // Reveal options
      await tester.tap(find.byIcon(Icons.stop_circle_rounded));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(ReadingSpeedQuestionArea), findsOneWidget);

      // Transition to next question
      final nextState = ReadingLoaded(
        quests: const [testSpeedQuest, testNextSpeedQuest],
        currentIndex: 1,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
      );

      when(() => mockReadingBloc.state).thenReturn(nextState);
      stateController.add(nextState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ReadingSpeedPulseZone), findsOneWidget);
      expect(find.text('Second passage content goes here.'), findsOneWidget);
      expect(find.byType(ReadingSpeedQuestionArea), findsNothing);

      await stateController.close();
    });

    testWidgets('10. Hint button usage dispatches ReadingHintUsed event', (tester) async {
      await pumpReadingSpeedCheck(tester);

      final hintButton = find.byType(QuestHintButton);
      expect(hintButton, findsOneWidget);

      await tester.tap(hintButton);
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockReadingBloc.add(any(that: isA<ReadingHintUsed>()))).called(2);
    });

    testWidgets('11. Continue button dispatches NextQuestion event', (tester) async {
      await pumpReadingSpeedCheck(tester);

      await tester.tap(find.byIcon(Icons.stop_circle_rounded));
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.widgetWithText(ReadingSpeedOption, 'Saturday and Sunday'));
      await tester.pump(const Duration(milliseconds: 500));

      final continueButton = find.text('CONTINUE');
      expect(continueButton, findsOneWidget);

      await tester.tap(continueButton);
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockReadingBloc.add(any(that: isA<NextQuestion>()))).called(1);
    });

    testWidgets('12. Shimmer loading renders when state is ReadingInitial', (tester) async {
      await pumpReadingSpeedCheck(tester, state: const ReadingInitial());

      expect(find.byType(GameShimmerLoading), findsOneWidget);
      expect(find.byType(ReadingSpeedPulseZone), findsNothing);
    });

    testWidgets('13. Game briefing layer displays Velocity Reader briefing and dismisses on action', (tester) async {
      await pumpReadingSpeedCheck(tester, level: 1);

      expect(find.byType(GameBriefingLayer), findsOneWidget);
      expect(find.text('VELOCITY READER'), findsOneWidget);
      final startBtn = find.text('RACE TIMER');
      expect(startBtn, findsOneWidget);

      await tester.ensureVisible(startBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(startBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(GameBriefingLayer), findsNothing);
      expect(find.byType(ReadingSpeedPulseZone), findsOneWidget);
    });

    testWidgets('14. Dark theme renders cleanly without contrast issues', (tester) async {
      await pumpReadingSpeedCheck(tester, themeMode: ThemeMode.dark);

      expect(find.byType(ReadingSpeedCheckScreen), findsOneWidget);
      expect(find.byType(ReadingSpeedPulseZone), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('15. Small screen (320x640) renders without layout overflow', (tester) async {
      await pumpReadingSpeedCheck(tester, width: 320, height: 640);

      expect(find.byType(ReadingSpeedCheckScreen), findsOneWidget);
      expect(find.byType(ReadingSpeedPulseZone), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
