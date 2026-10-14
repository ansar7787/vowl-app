import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/widgets/game_briefing_layer.dart';
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
import 'package:vowl/features/reading/guess_title/presentation/pages/guess_title_screen.dart';
import 'package:vowl/features/reading/guess_title/presentation/widgets/guess_title_cargo_crate.dart';
import 'package:vowl/features/reading/guess_title/presentation/widgets/guess_title_instruction.dart';
import 'package:vowl/features/reading/guess_title/presentation/widgets/guess_title_label_rack.dart';
import 'package:vowl/features/reading/presentation/bloc/reading_bloc.dart';
import 'package:vowl/core/presentation/widgets/quest_hint_button.dart';

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

  const testGuessTitleQuest = ReadingQuest(
    id: 'RDG_GUESSTITLE_L1_Q1',
    instruction: 'Drag the best title for the passage.',
    difficulty: 1,
    subtype: GameSubtype.guessTitle,
    passage:
        'Before Maria goes to the market, she writes a shopping list. She checks the kitchen to see what is already there. At the store, she buys only what is on the list, so she spends less and forgets nothing.',
    options: [
      'A Guide to Choosing Fresh Fruit',
      'Cleaning the Kitchen',
      'Shopping With a List',
      'Cooking Dinner for Friends',
    ],
    correctAnswer: 'Shopping With a List',
    hint:
        'Ask what Maria does before she leaves home, and what that step helps her do later.',
    explanation:
        'Each sentence belongs to one plan: write a list, check the kitchen, then buy only what is needed.',
    whyThisTitle:
        'It names the list that links checking the kitchen with buying only what is needed.',
  );

  const testLoadedState = ReadingLoaded(
    quests: [testGuessTitleQuest],
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

  Future<void> pumpGuessTitle(
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
              body: GuessTitleScreen(level: level),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('GuessTitleScreen - Production Layout & Mechanics Tests', () {
    testWidgets(
        '1. Initial rendering of instruction, cargo crate passage, and label cards',
        (tester) async {
      await pumpGuessTitle(tester);

      // Verify instruction pill
      expect(find.byType(GuessTitleInstruction), findsOneWidget);
      expect(
        find.textContaining('TITLE FOR THE PASSAGE'),
        findsOneWidget,
      );

      // Verify cargo crate with passage
      expect(find.byType(GuessTitleCargoCrate), findsOneWidget);
      expect(
        find.textContaining('Before Maria goes to the market'),
        findsOneWidget,
      );
      expect(find.text('DRAG & DROP TITLE HERE'), findsOneWidget);

      // Verify label cards rack with 4 options (rendered uppercase)
      expect(find.byType(GuessTitleLabelRack), findsOneWidget);
      expect(find.text('A GUIDE TO CHOOSING FRESH FRUIT'), findsOneWidget);
      expect(find.text('CLEANING THE KITCHEN'), findsOneWidget);
      expect(find.text('SHOPPING WITH A LIST'), findsOneWidget);
      expect(find.text('COOKING DINNER FOR FRIENDS'), findsOneWidget);
    });

    testWidgets(
        '2. Drag-and-drop correct label onto cargo crate triggers success audio/haptics and dispatches SubmitAnswer(true)',
        (tester) async {
      await pumpGuessTitle(tester);

      final source = find.text('SHOPPING WITH A LIST');
      final target = find.text('DRAG & DROP TITLE HERE');

      final firstLocation = tester.getCenter(source);
      final targetLocation = tester.getCenter(target);

      final gesture = await tester.startGesture(firstLocation);
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.moveTo(targetLocation);
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));

      // Verify success feedback
      verify(() => mockHapticService.success()).called(1);
      verify(() => mockSoundService.playCorrect()).called(1);
      verify(() => mockReadingBloc.add(const SubmitAnswer(true))).called(1);
    });

    testWidgets(
        '3. Drag-and-drop incorrect label onto cargo crate triggers error audio/haptics and dispatches SubmitAnswer(false)',
        (tester) async {
      await pumpGuessTitle(tester);

      final source = find.text('CLEANING THE KITCHEN');
      final target = find.text('DRAG & DROP TITLE HERE');

      final firstLocation = tester.getCenter(source);
      final targetLocation = tester.getCenter(target);

      final gesture = await tester.startGesture(firstLocation);
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.moveTo(targetLocation);
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));

      // Verify wrong feedback
      verify(() => mockHapticService.error()).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockReadingBloc.add(const SubmitAnswer(false))).called(1);
    });

    testWidgets(
        '4. Tap-to-answer correct option docks title and dispatches SubmitAnswer(true)',
        (tester) async {
      await pumpGuessTitle(tester);

      final correctOption = find.text('SHOPPING WITH A LIST');
      expect(correctOption, findsOneWidget);

      await tester.tap(correctOption);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));

      // Verify feedback and submission
      verify(() => mockHapticService.success()).called(1);
      verify(() => mockSoundService.playCorrect()).called(1);
      verify(() => mockReadingBloc.add(const SubmitAnswer(true))).called(1);
    });

    testWidgets(
        '5. Tap-to-answer incorrect option docks title and dispatches SubmitAnswer(false)',
        (tester) async {
      await pumpGuessTitle(tester);

      final wrongOption = find.text('CLEANING THE KITCHEN');
      expect(wrongOption, findsOneWidget);

      await tester.tap(wrongOption);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));

      // Verify feedback and submission
      verify(() => mockHapticService.error()).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockReadingBloc.add(const SubmitAnswer(false))).called(1);
    });

    testWidgets(
        '6. Post-answer state reveals explanation card and locks cargo crate',
        (tester) async {
      const answeredState = ReadingLoaded(
        quests: [testGuessTitleQuest],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.correct,
      );

      await pumpGuessTitle(tester, state: answeredState);

      // Verify explanation card is visible
      expect(find.text('Why this title?'), findsOneWidget);
      expect(
        find.textContaining('It names the list that links checking the kitchen'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Each sentence belongs to one plan'),
        findsNWidgets(2),
      );

      // Verify DragTarget rejects drops when answered
      final dragTargetFinder = find.byType(DragTarget<String>);
      expect(dragTargetFinder, findsOneWidget);
      final dragTargetWidget =
          tester.widget<DragTarget<String>>(dragTargetFinder);
      expect(
        dragTargetWidget.onWillAcceptWithDetails!(
          DragTargetDetails(
            data: 'Shopping With a List',
            offset: Offset.zero,
          ),
        ),
        isFalse,
      );
    });

    testWidgets(
        '7. Answered incorrect state keeps label rack visible with correct answer highlighted',
        (tester) async {
      const wrongAnsweredState = ReadingLoaded(
        quests: [testGuessTitleQuest],
        currentIndex: 0,
        livesRemaining: 2,
        answerStatus: AnswerStatus.incorrect,
      );

      await pumpGuessTitle(tester, state: wrongAnsweredState);

      // Verify label rack remains visible to show correct answer
      expect(find.byType(GuessTitleLabelRack), findsOneWidget);
      expect(find.text('SHOPPING WITH A LIST'), findsOneWidget);

      // Verify explanation card is also shown
      expect(find.text('Why this title?'), findsOneWidget);
    });

    testWidgets(
        '8. Tapping hint button dispatches ReadingHintUsed',
        (tester) async {
      await pumpGuessTitle(tester);

      final hintFinder = find.byType(QuestHintButton);
      expect(hintFinder, findsOneWidget);

      await tester.tap(hintFinder);
      await tester.pump();

      // ReadingHeader calls bloc add internally and invokes widget.onHint
      verify(() => mockReadingBloc.add(const ReadingHintUsed())).called(2);
    });

    testWidgets(
        '9. Tapping continue button when answered dispatches NextQuestion',
        (tester) async {
      const answeredState = ReadingLoaded(
        quests: [testGuessTitleQuest],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.correct,
      );

      await pumpGuessTitle(tester, state: answeredState);

      final continueBtn = find.text('CONTINUE');
      expect(continueBtn, findsOneWidget);

      await tester.tap(continueBtn);
      await tester.pump();

      verify(() => mockReadingBloc.add(const NextQuestion())).called(1);
    });

    testWidgets(
        '10. ReadingInitial state renders GameShimmerLoading',
        (tester) async {
      await pumpGuessTitle(tester, state: const ReadingInitial());

      expect(find.byType(GameShimmerLoading), findsOneWidget);
      expect(find.byType(GuessTitleCargoCrate), findsNothing);
    });

    testWidgets(
        '11. Level 1 displays GameBriefingLayer and dismisses on start tap',
        (tester) async {
      await pumpGuessTitle(tester, level: 1);

      expect(find.byType(GameBriefingLayer), findsOneWidget);
      final startBtn = find.text('PLAY NOW');
      expect(startBtn, findsOneWidget);

      await tester.tap(startBtn);
      await tester.pumpAndSettle();

      expect(find.byType(GameBriefingLayer), findsNothing);
    });

    testWidgets(
        '12. Dark theme mode renders cleanly without errors',
        (tester) async {
      await pumpGuessTitle(tester, themeMode: ThemeMode.dark);

      expect(find.byType(GuessTitleCargoCrate), findsOneWidget);
      expect(find.byType(GuessTitleLabelRack), findsOneWidget);
      expect(
        find.textContaining('Before Maria goes to the market'),
        findsOneWidget,
      );
    });

    testWidgets(
        '13. Compact 320dp small screen layout safety with zero overflow',
        (tester) async {
      await pumpGuessTitle(
        tester,
        width: 320,
        height: 568,
      );

      expect(find.byType(GuessTitleScreen), findsOneWidget);
      expect(find.byType(GuessTitleCargoCrate), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

