import 'dart:async';
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
import 'package:vowl/features/reading/read_and_match/presentation/pages/read_and_match_screen.dart';
import 'package:vowl/features/reading/read_and_match/presentation/widgets/read_and_match_instruction.dart';
import 'package:vowl/features/reading/read_and_match/presentation/widgets/read_and_match_terminal.dart';

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

  const testMatchQuest = ReadingQuest(
    id: 'RDG_READANDMATCH_L1_Q1',
    instruction: 'Match each energy source with its description.',
    difficulty: 1,
    subtype: GameSubtype.readAndMatch,
    pairs: [
      {'key': 'Solar', 'value': 'Energy from sunlight'},
      {'key': 'Wind', 'value': 'Power from air currents'},
      {'key': 'Hydro', 'value': 'Electricity from moving water'},
    ],
    hint: 'Think about where each power type originates.',
    explanation:
        'Solar comes from the sun, wind from atmosphere, and hydro from water.',
  );

  const testNextMatchQuest = ReadingQuest(
    id: 'RDG_READANDMATCH_L1_Q2',
    instruction: 'Match vocabulary terms with their antonyms.',
    difficulty: 1,
    subtype: GameSubtype.readAndMatch,
    pairs: [
      {'key': 'Ancient', 'value': 'Modern'},
      {'key': 'Abundant', 'value': 'Scarce'},
    ],
    hint: 'Find the opposing meanings.',
  );

  const testLoadedState = ReadingLoaded(
    quests: [testMatchQuest, testNextMatchQuest],
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
  );

  const testAnsweredState = ReadingLoaded(
    quests: [testMatchQuest],
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
      'has_seen_briefing_readAndMatch': true,
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

  Future<void> pumpReadAndMatch(
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
              body: ReadAndMatchScreen(level: level),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  group('ReadAndMatchScreen Layout & Interactions', () {
    testWidgets('1. Initial layout renders instruction, terminals, and laser canvas', (tester) async {
      await pumpReadAndMatch(tester);

      expect(find.byType(ReadAndMatchScreen), findsOneWidget);
      expect(find.byType(ReadAndMatchInstruction), findsOneWidget);
      expect(find.text('Match each energy source with its description.'), findsOneWidget);

      // Verify 3 keys and 3 values terminals are present
      expect(find.byType(ReadAndMatchTerminal), findsNWidgets(6));
      expect(find.text('Solar'), findsOneWidget);
      expect(find.text('Wind'), findsOneWidget);
      expect(find.text('Hydro'), findsOneWidget);
      expect(find.text('Energy from sunlight'), findsOneWidget);
      expect(find.text('Power from air currents'), findsOneWidget);
      expect(find.text('Electricity from moving water'), findsOneWidget);

      // Verify CustomPaint with LaserBridgePainter
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('2. Tapping a left key activates it and triggers selection haptic', (tester) async {
      await pumpReadAndMatch(tester);

      final solarFinder = find.widgetWithText(ReadAndMatchTerminal, 'Solar');
      expect(solarFinder, findsOneWidget);

      await tester.tap(solarFinder);
      await tester.pump();

      verify(() => mockHapticService.selection()).called(1);

      // Verify the terminal widget has isActive == true
      final terminal = tester.widget<ReadAndMatchTerminal>(solarFinder);
      expect(terminal.isActive, isTrue);
    });

    testWidgets('3. Tapping the active key again deselects it', (tester) async {
      await pumpReadAndMatch(tester);

      final solarFinder = find.widgetWithText(ReadAndMatchTerminal, 'Solar');

      // First tap activates
      await tester.tap(solarFinder);
      await tester.pump();
      expect(tester.widget<ReadAndMatchTerminal>(solarFinder).isActive, isTrue);

      // Second tap deselects
      await tester.tap(solarFinder);
      await tester.pump();
      expect(tester.widget<ReadAndMatchTerminal>(solarFinder).isActive, isFalse);
    });

    testWidgets('4. Tapping another left key switches the active selection', (tester) async {
      await pumpReadAndMatch(tester);

      final solarFinder = find.widgetWithText(ReadAndMatchTerminal, 'Solar');
      final windFinder = find.widgetWithText(ReadAndMatchTerminal, 'Wind');

      await tester.tap(solarFinder);
      await tester.pump();
      expect(tester.widget<ReadAndMatchTerminal>(solarFinder).isActive, isTrue);
      expect(tester.widget<ReadAndMatchTerminal>(windFinder).isActive, isFalse);

      await tester.tap(windFinder);
      await tester.pump();
      expect(tester.widget<ReadAndMatchTerminal>(solarFinder).isActive, isFalse);
      expect(tester.widget<ReadAndMatchTerminal>(windFinder).isActive, isTrue);
    });

    testWidgets('5. Tapping right value while a key is active establishes a match pair', (tester) async {
      await pumpReadAndMatch(tester);

      final solarFinder = find.widgetWithText(ReadAndMatchTerminal, 'Solar');
      final sunlightFinder = find.widgetWithText(ReadAndMatchTerminal, 'Energy from sunlight');

      // Select Solar key
      await tester.tap(solarFinder);
      await tester.pump();

      // Tap sunlight value
      await tester.tap(sunlightFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      verify(() => mockHapticService.success()).called(1);

      // Both should now be marked isMatched
      expect(tester.widget<ReadAndMatchTerminal>(solarFinder).isMatched, isTrue);
      expect(tester.widget<ReadAndMatchTerminal>(sunlightFinder).isMatched, isTrue);
      expect(tester.widget<ReadAndMatchTerminal>(solarFinder).isActive, isFalse);
    });

    testWidgets('6. Tapping a matched right value without active key unpairs it', (tester) async {
      await pumpReadAndMatch(tester);

      final solarFinder = find.widgetWithText(ReadAndMatchTerminal, 'Solar');
      final sunlightFinder = find.widgetWithText(ReadAndMatchTerminal, 'Energy from sunlight');

      // Establish match
      await tester.tap(solarFinder);
      await tester.pump();
      await tester.tap(sunlightFinder);
      await tester.pump();
      expect(tester.widget<ReadAndMatchTerminal>(solarFinder).isMatched, isTrue);

      // Tap matched value without active key -> unpairs and makes Solar active
      await tester.tap(sunlightFinder);
      await tester.pump();

      expect(tester.widget<ReadAndMatchTerminal>(sunlightFinder).isMatched, isFalse);
      expect(tester.widget<ReadAndMatchTerminal>(solarFinder).isActive, isTrue);
    });

    testWidgets('7. Completing all pairs correctly triggers success and dispatches SubmitAnswer(true)', (tester) async {
      await pumpReadAndMatch(tester);

      // Match 1: Solar -> Energy from sunlight
      await tester.tap(find.widgetWithText(ReadAndMatchTerminal, 'Solar'));
      await tester.pump();
      await tester.tap(find.widgetWithText(ReadAndMatchTerminal, 'Energy from sunlight'));
      await tester.pump();

      // Match 2: Wind -> Power from air currents
      await tester.tap(find.widgetWithText(ReadAndMatchTerminal, 'Wind'));
      await tester.pump();
      await tester.tap(find.widgetWithText(ReadAndMatchTerminal, 'Power from air currents'));
      await tester.pump();

      // Match 3: Hydro -> Electricity from moving water
      await tester.tap(find.widgetWithText(ReadAndMatchTerminal, 'Hydro'));
      await tester.pump();
      await tester.tap(find.widgetWithText(ReadAndMatchTerminal, 'Electricity from moving water'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockHapticService.success()).called(greaterThanOrEqualTo(3));
      verify(() => mockSoundService.playCorrect()).called(1);
      verify(() => mockReadingBloc.add(const SubmitAnswer(true))).called(1);

      expect(find.text('CONTINUE'), findsOneWidget);
    });

    testWidgets('8. Completing all pairs with an error dispatches SubmitAnswer(false) and shows Try Again', (tester) async {
      await pumpReadAndMatch(tester);

      // Match 1: Solar -> Power from air currents (INCORRECT)
      await tester.tap(find.widgetWithText(ReadAndMatchTerminal, 'Solar'));
      await tester.pump();
      await tester.tap(find.widgetWithText(ReadAndMatchTerminal, 'Power from air currents'));
      await tester.pump();

      // Match 2: Wind -> Energy from sunlight (INCORRECT)
      await tester.tap(find.widgetWithText(ReadAndMatchTerminal, 'Wind'));
      await tester.pump();
      await tester.tap(find.widgetWithText(ReadAndMatchTerminal, 'Energy from sunlight'));
      await tester.pump();

      // Match 3: Hydro -> Electricity from moving water
      await tester.tap(find.widgetWithText(ReadAndMatchTerminal, 'Hydro'));
      await tester.pump();
      await tester.tap(find.widgetWithText(ReadAndMatchTerminal, 'Electricity from moving water'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockHapticService.error()).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockReadingBloc.add(const SubmitAnswer(false))).called(1);

      expect(find.text('TRY AGAIN'), findsOneWidget);

      // Advance time beyond the 1500ms reset timer and settle animation
      await tester.pump(const Duration(milliseconds: 1600));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
    });

    testWidgets('9. Interaction lockout prevents further taps once answered', (tester) async {
      await pumpReadAndMatch(tester);

      // Match all correctly
      await tester.tap(find.widgetWithText(ReadAndMatchTerminal, 'Solar'));
      await tester.pump();
      await tester.tap(find.widgetWithText(ReadAndMatchTerminal, 'Energy from sunlight'));
      await tester.pump();

      await tester.tap(find.widgetWithText(ReadAndMatchTerminal, 'Wind'));
      await tester.pump();
      await tester.tap(find.widgetWithText(ReadAndMatchTerminal, 'Power from air currents'));
      await tester.pump();

      await tester.tap(find.widgetWithText(ReadAndMatchTerminal, 'Hydro'));
      await tester.pump();
      await tester.tap(find.widgetWithText(ReadAndMatchTerminal, 'Electricity from moving water'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      clearInteractions(mockHapticService);
      clearInteractions(mockSoundService);

      // Tap on terminal while answered
      await tester.tap(find.widgetWithText(ReadAndMatchTerminal, 'Solar'), warnIfMissed: false);
      await tester.pump();

      verifyNever(() => mockHapticService.selection());
      verifyNever(() => mockSoundService.playCorrect());
    });

    testWidgets('10. Continue button dispatches NextQuestion event', (tester) async {
      await pumpReadAndMatch(tester);

      // Complete all matches
      await tester.tap(find.widgetWithText(ReadAndMatchTerminal, 'Solar'));
      await tester.pump();
      await tester.tap(find.widgetWithText(ReadAndMatchTerminal, 'Energy from sunlight'));
      await tester.pump();

      await tester.tap(find.widgetWithText(ReadAndMatchTerminal, 'Wind'));
      await tester.pump();
      await tester.tap(find.widgetWithText(ReadAndMatchTerminal, 'Power from air currents'));
      await tester.pump();

      await tester.tap(find.widgetWithText(ReadAndMatchTerminal, 'Hydro'));
      await tester.pump();
      await tester.tap(find.widgetWithText(ReadAndMatchTerminal, 'Electricity from moving water'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      final continueBtn = find.text('CONTINUE');
      expect(continueBtn, findsOneWidget);

      await tester.tap(continueBtn);
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockReadingBloc.add(any(that: isA<NextQuestion>()))).called(1);
    });

    testWidgets('11. Hint button in header dispatches ReadingHintUsed', (tester) async {
      await pumpReadAndMatch(tester);

      final hintButton = find.byType(QuestHintButton);
      expect(hintButton, findsOneWidget);

      await tester.tap(hintButton);
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockReadingBloc.add(any(that: isA<ReadingHintUsed>()))).called(1);
    });

    testWidgets('12. Shimmer loading renders when state is ReadingInitial', (tester) async {
      await pumpReadAndMatch(tester, state: const ReadingInitial());

      expect(find.byType(GameShimmerLoading), findsOneWidget);
      expect(find.byType(ReadAndMatchTerminal), findsNothing);
    });

    testWidgets('13. Game briefing layer displays Read & Match briefing and dismisses on action', (tester) async {
      await pumpReadAndMatch(tester, level: 1);

      expect(find.byType(GameBriefingLayer), findsOneWidget);
      expect(find.text('READ & MATCH'), findsOneWidget);
      final startBtn = find.text('MATCH ITEMS');
      expect(startBtn, findsOneWidget);

      await tester.ensureVisible(startBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(startBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(GameBriefingLayer), findsNothing);
      expect(find.byType(ReadAndMatchTerminal), findsNWidgets(6));
    });

    testWidgets('14. Dark theme renders cleanly without contrast issues', (tester) async {
      await pumpReadAndMatch(tester, themeMode: ThemeMode.dark);

      expect(find.byType(ReadAndMatchScreen), findsOneWidget);
      expect(find.byType(ReadAndMatchTerminal), findsNWidgets(6));
      expect(tester.takeException(), isNull);
    });

    testWidgets('15. Small screen (320x640) renders without layout overflow', (tester) async {
      await pumpReadAndMatch(tester, width: 320, height: 640);

      expect(find.byType(ReadAndMatchScreen), findsOneWidget);
      expect(find.byType(ReadAndMatchTerminal), findsNWidgets(6));
      expect(tester.takeException(), isNull);
    });

    testWidgets('16. Initial answered state loads cleanly with continue button', (tester) async {
      await pumpReadAndMatch(tester, state: testAnsweredState);

      expect(find.byType(ReadAndMatchScreen), findsOneWidget);
      expect(find.text('CONTINUE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
