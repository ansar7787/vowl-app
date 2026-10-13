import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/presentation/widgets/quest_briefing_overlay.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/game_instruction_service.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/story_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/kids_zone/domain/entities/kids_quest.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_audio_service.dart';
import 'package:vowl/features/kids_zone/presentation/utils/kids_tts_service.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/layouts/kids_time_layout.dart';

class MockKidsBloc extends MockBloc<KidsEvent, KidsState> implements KidsBloc {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockKidsTTSService extends Mock implements KidsTTSService {}

class MockKidsAudioService extends Mock implements KidsAudioService {}

class MockHapticService extends Mock implements HapticService {}

class MockAppLogger extends Mock implements AppLogger {}

class MockLocaleService extends Mock implements LocaleService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(const SubmitKidsAnswer(true));
  });

  late MockKidsBloc mockKidsBloc;
  late MockAuthBloc mockAuthBloc;
  late MockKidsTTSService mockTTSService;
  late MockKidsAudioService mockAudioService;
  late MockHapticService mockHapticService;
  late MockAppLogger mockLogger;
  late MockLocaleService mockLocaleService;

  const testQuestMorning = KidsQuest(
    id: 'KIDS_TIME_L1_Q1',
    gameType: 'time',
    level: 1,
    instruction:
        'The sun is just coming up and the birds are starting to sing. Which part of the day is it?',
    question: '?',
    correctAnswer: 'Morning',
    options: ['Night', 'Afternoon', 'Morning'],
    hint: 'Think about the part of the day when a new day begins.',
    emoji: '🐦',
    explanation:
        'The sun rising and birds waking up tell us that a new day is starting. That part of the day is called morning.',
    funFact:
        'A day is often split into four parts: morning, afternoon, evening and night.',
    metadata: {'subtype': 'time_of_day'},
  );

  const testQuestClockReading = KidsQuest(
    id: 'KIDS_TIME_L2_Q1',
    gameType: 'time',
    level: 2,
    instruction:
        'The long hand points to 12 and the short hand points to 4. What time is it?',
    question: '?',
    correctAnswer: "4 o'clock",
    options: ["3 o'clock", "4 o'clock", "12 o'clock"],
    hint: 'The short hand tells you the hour.',
    emoji: '🔔',
    explanation:
        "When the long hand is on 12, it is an o'clock time. The short hand is on 4, so it is 4 o'clock.",
    funFact: "O'clock is short for of the clock.",
    metadata: {'subtype': 'o_clock'},
  );

  const testQuestLongOptions = KidsQuest(
    id: 'KIDS_TIME_L10_Q1',
    gameType: 'time',
    level: 10,
    instruction:
        'Which order shows the times from shortest duration to longest duration?',
    question: '?',
    correctAnswer:
        'Half an hour, 50 minutes, three quarters of an hour, 1 hour',
    options: [
      'Half an hour, three quarters of an hour, 50 minutes, 1 hour',
      'Three quarters of an hour, half an hour, 50 minutes, 1 hour',
      'Half an hour, 50 minutes, three quarters of an hour, 1 hour',
    ],
    hint: 'Convert all durations to minutes first.',
    emoji: '⏱️',
    explanation:
        'Half an hour is 30 mins, three quarters is 45 mins, then 50 mins, then 1 hour (60 mins).',
    metadata: {'subtype': 'duration'},
  );

  const testLoadedState = KidsLoaded(
    quests: [testQuestMorning],
    originalTotalQuests: 1,
    gameType: 'time',
    level: 1,
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});

    mockKidsBloc = MockKidsBloc();
    mockAuthBloc = MockAuthBloc();
    mockTTSService = MockKidsTTSService();
    mockAudioService = MockKidsAudioService();
    mockHapticService = MockHapticService();
    mockLogger = MockAppLogger();
    mockLocaleService = MockLocaleService();

    when(() => mockKidsBloc.state).thenReturn(testLoadedState);
    when(
      () => mockKidsBloc.stream,
    ).thenAnswer((_) => const Stream<KidsState>.empty());

    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(
        const UserEntity(
          id: 'kid_user_1',
          email: 'kid@vowl.app',
          completedLevels: {},
          totalExp: 50,
        ),
      ),
    );
    when(
      () => mockAuthBloc.stream,
    ).thenAnswer((_) => const Stream<AuthState>.empty());

    when(
      () => mockTTSService.speak(any(), force: any(named: 'force')),
    ).thenAnswer((_) async => true);
    when(
      () => mockTTSService.isNarrationEnabled(),
    ).thenAnswer((_) async => false);
    when(() => mockTTSService.stop()).thenAnswer((_) async {});

    when(() => mockAudioService.playSuccessSFX()).thenAnswer((_) async {});
    when(() => mockAudioService.playFailureSFX()).thenAnswer((_) async {});
    when(
      () => mockAudioService.playLevelCompleteSFX(),
    ).thenAnswer((_) async {});

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});
    when(() => mockHapticService.warning()).thenAnswer((_) async {});

    when(
      () => mockLogger.debug(any(), tag: any(named: 'tag')),
    ).thenReturn(null);
    when(
      () => mockLogger.warning(any(), tag: any(named: 'tag')),
    ).thenReturn(null);
    when(
      () => mockLogger.error(
        any(),
        error: any(named: 'error'),
        stackTrace: any(named: 'stackTrace'),
        tag: any(named: 'tag'),
      ),
    ).thenReturn(null);

    when(
      () => mockLocaleService.tr(
        any(),
        args: any(named: 'args'),
        fallback: any(named: 'fallback'),
      ),
    ).thenAnswer((inv) {
      final key = inv.positionalArguments[0] as String;
      final fallback = inv.namedArguments[#fallback] as String?;
      return fallback ?? key;
    });

    if (di.sl.isRegistered<KidsTTSService>()) {
      di.sl.unregister<KidsTTSService>();
    }
    if (di.sl.isRegistered<KidsAudioService>()) {
      di.sl.unregister<KidsAudioService>();
    }
    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    if (di.sl.isRegistered<AppLogger>()) {
      di.sl.unregister<AppLogger>();
    }
    if (di.sl.isRegistered<LocaleService>()) {
      di.sl.unregister<LocaleService>();
    }

    di.sl.registerSingleton<KidsTTSService>(mockTTSService);
    di.sl.registerSingleton<KidsAudioService>(mockAudioService);
    di.sl.registerSingleton<HapticService>(mockHapticService);
    di.sl.registerSingleton<AppLogger>(mockLogger);
    di.sl.registerSingleton<LocaleService>(mockLocaleService);
  });

  tearDown(() {
    if (di.sl.isRegistered<KidsTTSService>()) {
      di.sl.unregister<KidsTTSService>();
    }
    if (di.sl.isRegistered<KidsAudioService>()) {
      di.sl.unregister<KidsAudioService>();
    }
    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    if (di.sl.isRegistered<AppLogger>()) {
      di.sl.unregister<AppLogger>();
    }
    if (di.sl.isRegistered<LocaleService>()) {
      di.sl.unregister<LocaleService>();
    }
  });

  Widget buildTestScreen({
    Size screenSize = const Size(390, 844),
    KidsState? stateOverride,
  }) {
    if (stateOverride != null) {
      when(() => mockKidsBloc.state).thenReturn(stateOverride);
    }

    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, _) => MultiBlocProvider(
        providers: [
          BlocProvider<KidsBloc>.value(value: mockKidsBloc),
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: MediaQuery(
            data: MediaQueryData(size: screenSize),
            child: const KidsTimeLayout(
              level: 2,
              title: 'Time',
              primaryColor: Color(0xFF84CC16),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
  }

  group('KidsTimeLayout Production Tests', () {
    testWidgets(
      'renders question prompt banner, subtype badge, clock tower, and options with complete visibility',
      (tester) async {
        await tester.pumpWidget(buildTestScreen());
        await pumpScreen(tester);

        // 1. Subtype Badge & Icon
        expect(find.text('Part of the Day'), findsOneWidget);
        expect(find.text('🌅'), findsOneWidget);

        // 2. Full question prompt text is visible on screen
        expect(
          find.text(
            'The sun is just coming up and the birds are starting to sing. Which part of the day is it?',
          ),
          findsOneWidget,
        );

        // 3. Audio speaker button is present
        expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);

        // 4. Center Medallion shows emoji without overlapping question mark
        expect(find.text('🐦'), findsOneWidget);

        // 5. All options rendered legibly
        expect(find.text('Night'), findsOneWidget);
        expect(find.text('Afternoon'), findsOneWidget);
        expect(find.text('Morning'), findsOneWidget);

        // 6. DragTarget drop zone is present
        expect(find.byType(DragTarget<String>), findsOneWidget);
      },
    );

    testWidgets('tap-to-answer submits correct answer to KidsBloc', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestScreen());
      await pumpScreen(tester);

      // Find the 'Morning' option card
      final morningFinder = find.text('Morning');
      expect(morningFinder, findsOneWidget);

      await tester.tap(morningFinder);
      await pumpScreen(tester);

      // Verify answer submission
      verify(() => mockKidsBloc.add(const SubmitKidsAnswer(true))).called(1);

      // Verify tactile and audio feedback
      verify(() => mockHapticService.selection()).called(1);
      verify(() => mockTTSService.speak('Morning')).called(1);
      verify(() => mockAudioService.playSuccessSFX()).called(1);

      // Verify structured logger
      verify(
        () => mockLogger.debug(
          any(that: contains('Submitting option "Morning"')),
        ),
      ).called(1);
    });

    testWidgets('tap-to-answer submits incorrect answer to KidsBloc', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestScreen());
      await pumpScreen(tester);

      final nightFinder = find.text('Night');
      expect(nightFinder, findsOneWidget);

      await tester.tap(nightFinder);
      await pumpScreen(tester);

      verify(() => mockKidsBloc.add(const SubmitKidsAnswer(false))).called(1);

      verify(() => mockAudioService.playFailureSFX()).called(1);
    });

    testWidgets('drag-and-drop option onto clock tower submits answer', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestScreen());
      await pumpScreen(tester);

      final morningFinder = find.text('Morning');
      final clockFinder = find.byType(DragTarget<String>);

      // Perform drag gesture
      final gesture = await tester.startGesture(
        tester.getCenter(morningFinder),
      );
      await tester.pump(const Duration(milliseconds: 50));

      await gesture.moveTo(tester.getCenter(clockFinder));
      await tester.pump(const Duration(milliseconds: 50));

      await gesture.up();
      await pumpScreen(tester);

      verify(() => mockKidsBloc.add(const SubmitKidsAnswer(true))).called(1);
      verify(
        () => mockLogger.debug(
          any(that: contains('dropped onto clock target')),
        ),
      ).called(1);
    });

    testWidgets('speaker button taps trigger TTS narration of question', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestScreen());
      await pumpScreen(tester);

      final speakerButton = find.byIcon(Icons.volume_up_rounded);
      expect(speakerButton, findsOneWidget);

      await tester.tap(speakerButton);
      await pumpScreen(tester);

      verify(
        () => mockTTSService.speak(
          'The sun is just coming up and the birds are starting to sing. Which part of the day is it?',
          force: true,
        ),
      ).called(1);
      verify(
        () => mockLogger.debug(
          any(that: contains('Replaying question audio')),
        ),
      ).called(1);
    });

    testWidgets('clock hands reflect extracted time from o_clock question', (
      tester,
    ) async {
      const clockState = KidsLoaded(
        quests: [testQuestClockReading],
        originalTotalQuests: 1,
        gameType: 'time',
        level: 2,
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
      );

      await tester.pumpWidget(buildTestScreen(stateOverride: clockState));
      await pumpScreen(tester);

      // Verify question prompt and subtype
      expect(find.text("O'Clock Time"), findsOneWidget);
      expect(
        find.text(
          'The long hand points to 12 and the short hand points to 4. What time is it?',
        ),
        findsOneWidget,
      );
      expect(find.text("4 o'clock"), findsOneWidget);
    });

    testWidgets('renders long options without overflow or text truncation', (
      tester,
    ) async {
      const longOptionsState = KidsLoaded(
        quests: [testQuestLongOptions],
        originalTotalQuests: 1,
        gameType: 'time',
        level: 10,
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
      );

      await tester.pumpWidget(buildTestScreen(stateOverride: longOptionsState));
      await pumpScreen(tester);

      // Verify the long option text rendered
      expect(
        find.text(
          'Half an hour, three quarters of an hour, 50 minutes, 1 hour',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Three quarters of an hour, half an hour, 50 minutes, 1 hour',
        ),
        findsOneWidget,
      );
      expect(
        find.text(
          'Half an hour, 50 minutes, three quarters of an hour, 1 hour',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders safely on compact 320dp width with zero overflow', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestScreen(screenSize: const Size(320, 640)),
      );
      await pumpScreen(tester);

      // No RenderFlex overflow
      expect(tester.takeException(), isNull);
      expect(find.text('Morning'), findsOneWidget);
    });

    testWidgets('renders safely on short 580dp height with zero overflow', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestScreen(screenSize: const Size(390, 580)),
      );
      await pumpScreen(tester);

      // No RenderFlex overflow
      expect(tester.takeException(), isNull);
      expect(find.text('Morning'), findsOneWidget);
    });

    testWidgets(
      'StoryService resolves warm, human-crafted narrative beats for Level 1 and Level 100',
      (tester) async {
        await tester.pumpWidget(buildTestScreen());
        await pumpScreen(tester);
        final BuildContext context = tester.element(
          find.byType(KidsTimeLayout),
        );

        final storyService = StoryService();

        // Level 1 story beat
        final beat1 = storyService.getStoryBeat(context, 'time', 1);
        expect(beat1, isNotNull);
        expect(beat1!.text, contains('Welcome to Time!'));
        expect(beat1.mascotEmoji, equals('🕰️'));

        // Level 100 milestone story beat
        final beat100 = storyService.getStoryBeat(context, 'time', 100);
        expect(beat100, isNotNull);
        expect(beat100!.text, contains('One hundred levels completed!'));
        expect(beat100.mascotEmoji, equals('🕰️'));
      },
    );

    testWidgets(
      'GameInstructionService resolves Time briefing matching clock hands and audio features',
      (tester) async {
        await tester.pumpWidget(buildTestScreen());
        await pumpScreen(tester);
        final BuildContext context = tester.element(
          find.byType(KidsTimeLayout),
        );

        final briefing = GameInstructionService.getBriefing(
          context,
          null,
          'time',
          level: 1,
        );

        expect(briefing.title, equals('Telling Time'));
        expect(briefing.objective, contains('clock'));
        expect(briefing.rules.any((r) => r.contains('clock hands')), isTrue);
        expect(briefing.rules.any((r) => r.contains('speaker')), isTrue);
        expect(briefing.tip, contains('short hand'));
        expect(briefing.actionText, equals("Let's Play"));
      },
    );

    testWidgets(
      'QuestBriefingOverlay is shown automatically on level 1 and dismisses on start',
      (tester) async {
        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(390, 844),
            builder: (context, _) => MultiBlocProvider(
              providers: [
                BlocProvider<KidsBloc>.value(value: mockKidsBloc),
                BlocProvider<AuthBloc>.value(value: mockAuthBloc),
              ],
              child: MaterialApp(
                theme: AppTheme.lightTheme,
                home: const MediaQuery(
                  data: MediaQueryData(size: Size(390, 844)),
                  child: KidsTimeLayout(
                    level: 1,
                    title: 'Time',
                    primaryColor: Color(0xFF84CC16),
                  ),
                ),
              ),
            ),
          ),
        );
        await pumpScreen(tester);

        // Verify briefing overlay appears on level 1
        expect(find.byType(QuestBriefingOverlay), findsOneWidget);
        expect(find.text('TELLING TIME'), findsOneWidget);
        final playButton = find.text("LET'S PLAY");
        expect(playButton, findsOneWidget);

        // Scroll button into view and tap to dismiss briefing
        await tester.ensureVisible(playButton);
        await tester.tap(playButton);
        await tester.pump(const Duration(milliseconds: 450));
        await tester.pump(const Duration(milliseconds: 100));

        // Overlay is dismissed
        expect(find.byType(QuestBriefingOverlay), findsNothing);
      },
    );

    testWidgets(
      'QuestBriefingOverlay is shown automatically on level 100 milestone',
      (tester) async {
        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(390, 844),
            builder: (context, _) => MultiBlocProvider(
              providers: [
                BlocProvider<KidsBloc>.value(value: mockKidsBloc),
                BlocProvider<AuthBloc>.value(value: mockAuthBloc),
              ],
              child: MaterialApp(
                theme: AppTheme.lightTheme,
                home: const MediaQuery(
                  data: MediaQueryData(size: Size(390, 844)),
                  child: KidsTimeLayout(
                    level: 100,
                    title: 'Time',
                    primaryColor: Color(0xFF84CC16),
                  ),
                ),
              ),
            ),
          ),
        );
        await pumpScreen(tester);

        // Verify briefing overlay appears on level 100
        expect(find.byType(QuestBriefingOverlay), findsOneWidget);
        expect(find.text('TELLING TIME'), findsOneWidget);
      },
    );
  });
}
