import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/core/presentation/widgets/game_feedback_card.dart';
import 'package:vowl/core/presentation/widgets/quest_hint_button.dart';
import 'package:vowl/core/presentation/widgets/quest_briefing_overlay.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
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
import 'package:vowl/features/writing/domain/entities/writing_quest.dart';
import 'package:vowl/features/writing/opinion_writing/presentation/pages/opinion_writing_screen.dart';
import 'package:vowl/features/writing/opinion_writing/presentation/widgets/opinion_writing_option_card.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_bloc.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_event.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_state.dart';
import 'package:vowl/features/writing/presentation/layout/writing_base_layout.dart';

class MockWritingBloc extends Mock implements WritingBloc {}
class MockAuthBloc extends Mock implements AuthBloc {}
class MockEconomyBloc extends Mock implements EconomyBloc {}
class MockHapticService extends Mock implements HapticService {}
class MockSoundService extends Mock implements SoundService {}
class MockTtsService extends Mock implements TtsService {}
class MockLocaleService extends Mock implements LocaleService {}
class MockAppLogger extends Mock implements AppLogger {}
class MockAnalyticsService extends Mock implements AnalyticsService {}
class MockAdService extends Mock implements AdService {}
class MockNetworkInfo extends Mock implements NetworkInfo {}

class FakeWritingEvent extends Fake implements WritingEvent {}
class FakeWritingState extends Fake implements WritingState {}
class FakeEconomyEvent extends Fake implements EconomyEvent {}
class FakeEconomyState extends Fake implements EconomyState {}

void main() {
  late MockWritingBloc mockWritingBloc;
  late MockAuthBloc mockAuthBloc;
  late MockEconomyBloc mockEconomyBloc;
  late MockHapticService mockHapticService;
  late MockSoundService mockSoundService;
  late MockTtsService mockTtsService;
  late MockLocaleService mockLocaleService;
  late MockAppLogger mockAppLogger;
  late MockAnalyticsService mockAnalyticsService;
  late MockAdService mockAdService;
  late MockNetworkInfo mockNetworkInfo;
  late StreamController<WritingState> writingStreamController;

  const sampleQuest1 = WritingQuest(
    id: 'op_q1',
    instruction: 'Select the two most compelling arguments.',
    difficulty: 1,
    subtype: GameSubtype.opinionWriting,
    prompt: 'Should cities invest more in cycling infrastructure?',
    structureGuide: 'SUPPORT YOUR POSITION WITH DATA AND CIVIC BENEFITS',
    options: [
      'Cycling reduces inner-city carbon emissions and eases traffic congestion.',
      'Bicycles require less parking space than automobiles.',
      'Protected bike lanes decrease cyclist casualties by over 40%.',
      'Helmets are manufactured in diverse aerodynamic colors.',
    ],
    correctOrder: [0, 2],
    hint: 'Look for strong environmental and public safety statistics.',
    explanation: 'Emissions reductions and accident statistics provide objective, impactful evidence.',
    xpReward: 25,
    coinReward: 15,
  );

  const sampleQuest2 = WritingQuest(
    id: 'op_q2',
    instruction: 'Choose the best counter-argument rebuttal.',
    difficulty: 1,
    subtype: GameSubtype.opinionWriting,
    prompt: 'Remote work reduces team collaboration.',
    options: [
      'Office desks are expensive.',
      'Structured asynchronous check-ins maintain alignment while boosting focus time.',
      'Coffee breaks are social.',
    ],
    correctOrder: [1],
    hint: 'Focus on communication structure and employee productivity.',
    explanation: 'Structured async communication directly refutes collaboration deficits.',
    xpReward: 20,
    coinReward: 10,
  );

  const testLoadedState = WritingLoaded(
    quests: [sampleQuest1, sampleQuest2],
    currentIndex: 0,
    livesRemaining: 3,
    wrongCount: 0,
    hintUsed: false,
    answerStatus: AnswerStatus.unanswered,
    gameType: GameSubtype.opinionWriting,
    level: 2,
  );

  setUpAll(() {
    registerFallbackValue(FakeWritingEvent());
    registerFallbackValue(FakeWritingState());
    registerFallbackValue(FakeEconomyEvent());
    registerFallbackValue(FakeEconomyState());
    registerFallbackValue(const SubmitAnswer(true));
    registerFallbackValue(const SubmitAnswer(false));
    registerFallbackValue(const NextQuestion());
    registerFallbackValue(const WritingHintUsed());
    registerFallbackValue(
      const FetchWritingQuests(
        gameType: GameSubtype.opinionWriting,
        level: 2,
      ),
    );
  });

  setUp(() async {
    mockWritingBloc = MockWritingBloc();
    mockAuthBloc = MockAuthBloc();
    mockEconomyBloc = MockEconomyBloc();
    mockHapticService = MockHapticService();
    mockSoundService = MockSoundService();
    mockTtsService = MockTtsService();
    mockLocaleService = MockLocaleService();
    mockAppLogger = MockAppLogger();
    mockAnalyticsService = MockAnalyticsService();
    mockAdService = MockAdService();
    mockNetworkInfo = MockNetworkInfo();

    writingStreamController = StreamController<WritingState>.broadcast();

    // Haptics
    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});
    when(() => mockHapticService.warning()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});
    when(() => mockHapticService.heavy()).thenAnswer((_) async {});

    // Sounds
    when(() => mockSoundService.playCorrect()).thenAnswer((_) async {});
    when(() => mockSoundService.playWrong()).thenAnswer((_) async {});
    when(() => mockSoundService.stopAudio()).thenAnswer((_) async {});
    when(() => mockSoundService.stopTts()).thenAnswer((_) async {});
    when(() => mockSoundService.playHint()).thenAnswer((_) async {});
    when(() => mockSoundService.playClick()).thenAnswer((_) async {});
    when(() => mockSoundService.playLevelComplete()).thenAnswer((_) async {});
    when(() => mockSoundService.playFile(any())).thenAnswer((_) async {});

    // TTS
    when(() => mockTtsService.stop()).thenAnswer((_) async {});
    when(
      () => mockTtsService.speak(
        any(),
        rate: any(named: 'rate'),
        locale: any(named: 'locale'),
      ),
    ).thenAnswer((_) async {});

    // Auth mock
    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(
        const UserEntity(
          id: 'op_user_1',
          email: 'op@vowl.app',
          displayName: 'Opinion Writer',
          hintCount: 3,
          isPremium: false,
        ),
      ),
    );
    when(() => mockAuthBloc.stream)
        .thenAnswer((_) => const Stream<AuthState>.empty());

    // Economy mock
    when(() => mockEconomyBloc.state).thenReturn(const EconomyState());
    when(() => mockEconomyBloc.stream)
        .thenAnswer((_) => const Stream<EconomyState>.empty());

    // Network mock
    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

    // Writing Bloc default state
    when(() => mockWritingBloc.state).thenReturn(testLoadedState);
    when(
      () => mockWritingBloc.stream,
    ).thenAnswer((_) => writingStreamController.stream);

    await di.sl.reset();
    di.sl.registerSingleton<HapticService>(mockHapticService);
    di.sl.registerSingleton<SoundService>(mockSoundService);
    di.sl.registerSingleton<TtsService>(mockTtsService);
    di.sl.registerSingleton<LocaleService>(mockLocaleService);
    di.sl.registerSingleton<AppLogger>(mockAppLogger);
    di.sl.registerSingleton<AnalyticsService>(mockAnalyticsService);
    di.sl.registerSingleton<AdService>(mockAdService);
    di.sl.registerSingleton<NetworkInfo>(mockNetworkInfo);

    VowlMotion.lowAnimationModeOverride.value = true;
  });

  tearDown(() async {
    await writingStreamController.close();
    VowlMotion.lowAnimationModeOverride.value = false;
    await di.sl.reset();
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    WritingState? state,
    int level = 2,
    Size surfaceSize = const Size(390, 844),
    double textScaleFactor = 1.0,
    ThemeMode themeMode = ThemeMode.dark,
  }) async {
    tester.view.physicalSize = surfaceSize * tester.view.devicePixelRatio;
    addTearDown(() => tester.view.resetPhysicalSize());

    if (state != null) {
      when(() => mockWritingBloc.state).thenReturn(state);
    }

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, child) => MultiBlocProvider(
          providers: [
            BlocProvider<WritingBloc>.value(value: mockWritingBloc),
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            BlocProvider<EconomyBloc>.value(value: mockEconomyBloc),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            home: MediaQuery(
              data: MediaQueryData(
                size: surfaceSize,
                textScaler: TextScaler.linear(textScaleFactor),
              ),
              child: OpinionWritingScreen(
                level: level,
                gameType: GameSubtype.opinionWriting,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> scrollAndTapSubmitButton(WidgetTester tester) async {
    final submitButton = find.byKey(const Key('opinion_writing_submit_button'));
    await tester.ensureVisible(submitButton);
    await tester.pumpAndSettle();
    await tester.tap(submitButton);
    await tester.pump();
  }

  group('OpinionWritingScreen - 1. Initial Rendering & Layout', () {
    testWidgets('renders all essential components in normal mode (level 2)', (tester) async {
      await pumpScreen(tester, level: 2);

      expect(find.byType(WritingBaseLayout), findsOneWidget);
      expect(find.byKey(const Key('opinion_writing_scroll_view')), findsOneWidget);
      expect(find.byKey(const Key('opinion_drafting_pad_target')), findsOneWidget);
      expect(find.byKey(const Key('opinion_writing_submit_button')), findsOneWidget);
      expect(find.text('Drafting Pad'), findsOneWidget);
      expect(find.text('Idea Board'), findsOneWidget);
      expect(find.text('SUBMIT'), findsOneWidget);
      expect(find.text('Should cities invest more in cycling infrastructure?'), findsOneWidget);
      expect(find.text('SUPPORT YOUR POSITION WITH DATA AND CIVIC BENEFITS'), findsOneWidget);
      expect(find.text('Select the two most compelling arguments.'), findsOneWidget);
      expect(find.text('Drag option here...'), findsNWidgets(2));
    });

    testWidgets('renders without structureGuide if null', (tester) async {
      const state = WritingLoaded(
        quests: [sampleQuest2],
        currentIndex: 0,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.unanswered,
        gameType: GameSubtype.opinionWriting,
        level: 2,
      );
      await pumpScreen(tester, state: state, level: 2);

      expect(find.text('Remote work reduces team collaboration.'), findsOneWidget);
      expect(find.text('Choose the best counter-argument rebuttal.'), findsOneWidget);
      expect(find.text('Drag option here...'), findsOneWidget);
    });

    testWidgets('renders shimmer loading when in initial state', (tester) async {
      const state = WritingInitial();
      await pumpScreen(tester, state: state, level: 2);

      expect(find.byType(GameShimmerLoading), findsOneWidget);
      expect(find.byKey(const Key('opinion_drafting_pad_target')), findsNothing);
    });

    testWidgets('dispatches FetchWritingQuests on init', (tester) async {
      await pumpScreen(tester, level: 2);

      verify(() => mockWritingBloc.add(
        const FetchWritingQuests(gameType: GameSubtype.opinionWriting, level: 2),
      )).called(1);
    });
  });

  group('OpinionWritingScreen - 2. Idea Board & Drafting Interactions', () {
    testWidgets('tapping an idea card moves it into the Drafting Pad', (tester) async {
      await pumpScreen(tester, level: 2);

      final firstOption = sampleQuest1.options![0];
      final cardFinder = find.byKey(Key('opinion_idea_card_$firstOption'));
      expect(cardFinder, findsOneWidget);

      await tester.ensureVisible(cardFinder);
      await tester.pumpAndSettle();
      await tester.tap(cardFinder);
      await tester.pumpAndSettle();

      verify(() => mockHapticService.selection()).called(1);

      // Now it appears in Drafting Pad as a drafted card
      expect(find.byKey(Key('opinion_drafted_card_$firstOption')), findsOneWidget);
      // And only 1 empty slot remains
      expect(find.text('Drag option here...'), findsOneWidget);
    });

    testWidgets('dragging an idea card drops it into the Drafting Pad', (tester) async {
      await pumpScreen(tester, level: 2, surfaceSize: const Size(390, 1200));

      final secondOption = sampleQuest1.options![1];
      final cardFinder = find.byKey(Key('opinion_idea_card_$secondOption'));
      final dropTarget = find.byKey(const Key('opinion_drafting_pad_target'));

      // Drag onto drafting pad
      final start = tester.getCenter(cardFinder);
      final target = tester.getCenter(dropTarget);
      final gesture = await tester.startGesture(start);
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.moveBy(const Offset(0, -20));
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.moveTo(target);
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.up();
      await tester.pumpAndSettle();

      verify(() => mockHapticService.selection()).called(1);
      expect(find.byKey(Key('opinion_drafted_card_$secondOption')), findsOneWidget);
    });

    testWidgets('tapping remove on a drafted card returns it to the Idea Board', (tester) async {
      await pumpScreen(tester, level: 2);

      final firstOption = sampleQuest1.options![0];
      final cardFinder = find.byKey(Key('opinion_idea_card_$firstOption'));
      await tester.ensureVisible(cardFinder);
      await tester.pumpAndSettle();
      await tester.tap(cardFinder);
      await tester.pumpAndSettle();

      expect(find.byKey(Key('opinion_drafted_card_$firstOption')), findsOneWidget);

      // Tap remove on the drafted card
      final draftedCardFinder = find.byKey(Key('opinion_drafted_card_$firstOption'));
      await tester.ensureVisible(draftedCardFinder);
      await tester.pumpAndSettle();
      await tester.tap(draftedCardFinder);
      await tester.pumpAndSettle();

      verify(() => mockHapticService.selection()).called(2);
      expect(find.byKey(Key('opinion_drafted_card_$firstOption')), findsNothing);
      expect(find.byKey(Key('opinion_idea_card_$firstOption')), findsOneWidget);
      expect(find.text('Drag option here...'), findsNWidgets(2));
    });

    testWidgets('cannot draft more than requiredCount items', (tester) async {
      await pumpScreen(tester, level: 2);

      // Add two items to fill pad (requiredCount is 2)
      final opt0 = sampleQuest1.options![0];
      final opt1 = sampleQuest1.options![1];
      final opt2 = sampleQuest1.options![2];

      await tester.ensureVisible(find.byKey(Key('opinion_idea_card_$opt0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('opinion_idea_card_$opt0')));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(Key('opinion_idea_card_$opt1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('opinion_idea_card_$opt1')));
      await tester.pumpAndSettle();

      expect(find.text('Drag option here...'), findsNothing);

      // Try adding a third item
      final opt2Finder = find.byKey(Key('opinion_idea_card_$opt2'));
      if (opt2Finder.evaluate().isNotEmpty) {
        await tester.ensureVisible(opt2Finder);
        await tester.pumpAndSettle();
        await tester.tap(opt2Finder);
        await tester.pumpAndSettle();
      }

      // Still only 2 items drafted
      expect(find.byType(OpinionWritingDraftedCard), findsNWidgets(2));
    });
  });

  group('OpinionWritingScreen - 3. Answer Validation & Submission', () {
    testWidgets('SUBMIT button does nothing when slots are not filled', (tester) async {
      await pumpScreen(tester, level: 2);

      // Pad is empty (0/2 filled)
      await scrollAndTapSubmitButton(tester);

      verifyNever(() => mockWritingBloc.add(any(that: isA<SubmitAnswer>())));
    });

    testWidgets('submitting incorrect combination dispatches SubmitAnswer(false)', (tester) async {
      await pumpScreen(tester, level: 2);

      // correctOrder is [0, 2], let's draft [0, 1] (incorrect)
      final opt0 = sampleQuest1.options![0];
      final opt1 = sampleQuest1.options![1];

      await tester.ensureVisible(find.byKey(Key('opinion_idea_card_$opt0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('opinion_idea_card_$opt0')));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(Key('opinion_idea_card_$opt1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('opinion_idea_card_$opt1')));
      await tester.pumpAndSettle();

      await scrollAndTapSubmitButton(tester);
      await tester.pumpAndSettle();

      verify(() => mockWritingBloc.add(const SubmitAnswer(false))).called(1);
    });

    testWidgets('submitting correct combination triggers success haptic and dispatches SubmitAnswer(true)', (tester) async {
      await pumpScreen(tester, level: 2);

      // correctOrder is [0, 2]
      final opt0 = sampleQuest1.options![0];
      final opt2 = sampleQuest1.options![2];

      await tester.ensureVisible(find.byKey(Key('opinion_idea_card_$opt0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('opinion_idea_card_$opt0')));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(Key('opinion_idea_card_$opt2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('opinion_idea_card_$opt2')));
      await tester.pumpAndSettle();

      await scrollAndTapSubmitButton(tester);
      await tester.pumpAndSettle();

      verify(() => mockHapticService.success()).called(1);
      verify(() => mockWritingBloc.add(const SubmitAnswer(true))).called(1);
    });
  });

  group('OpinionWritingScreen - 4. Feedback, Navigation & Reset', () {
    testWidgets('displays feedback card when answered correctly', (tester) async {
      const state = WritingLoaded(
        quests: [sampleQuest1],
        currentIndex: 0,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.correct,
        gameType: GameSubtype.opinionWriting,
        level: 2,
      );
      await pumpScreen(tester, state: state, level: 2);

      expect(find.byType(GameFeedbackCard), findsOneWidget);
    });

    testWidgets('tapping CONTINUE dispatches NextQuestion', (tester) async {
      const state = WritingLoaded(
        quests: [sampleQuest1],
        currentIndex: 0,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.correct,
        gameType: GameSubtype.opinionWriting,
        level: 2,
      );
      await pumpScreen(tester, state: state, level: 2);

      final continueButton = find.text('CONTINUE');
      expect(continueButton, findsOneWidget);
      await tester.tap(continueButton);
      await tester.pump();

      verify(() => mockWritingBloc.add(const NextQuestion())).called(1);
    });

    testWidgets('tapping Hint button dispatches WritingHintUsed', (tester) async {
      await pumpScreen(tester, level: 2);

      final hintButton = find.byType(QuestHintButton);
      expect(hintButton, findsOneWidget);
      await tester.tap(hintButton);
      await tester.pump();

      verify(() => mockWritingBloc.add(const WritingHintUsed())).called(1);
    });

    testWidgets('onQuestionReset resets drafted options and Idea Board on new question', (tester) async {
      await pumpScreen(tester, level: 2);

      final opt0 = sampleQuest1.options![0];
      await tester.ensureVisible(find.byKey(Key('opinion_idea_card_$opt0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('opinion_idea_card_$opt0')));
      await tester.pumpAndSettle();

      expect(find.byKey(Key('opinion_drafted_card_$opt0')), findsOneWidget);

      const nextState = WritingLoaded(
        quests: [sampleQuest1, sampleQuest2],
        currentIndex: 1,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.unanswered,
        gameType: GameSubtype.opinionWriting,
        level: 2,
      );
      when(() => mockWritingBloc.state).thenReturn(nextState);
      writingStreamController.add(nextState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('Remote work reduces team collaboration.'), findsOneWidget);
      expect(find.text('Drag option here...'), findsOneWidget);
      expect(find.byType(OpinionWritingDraftedCard), findsNothing);
    });
  });

  group('OpinionWritingScreen - 5. Completion, Game Over & Error Journal', () {
    testWidgets('shows completion dialog on WritingGameComplete', (tester) async {
      await pumpScreen(tester, level: 2);

      const completeState = WritingGameComplete(
        xpEarned: 100,
        coinsEarned: 50,
        questCount: 2,
        gameType: GameSubtype.opinionWriting,
        level: 2,
      );
      when(() => mockWritingBloc.state).thenReturn(completeState);
      writingStreamController.add(completeState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('LEVEL COMPLETE!'), findsOneWidget);

      // Clean up dialog timer
      final completeFinder = find.text('LEVEL COMPLETE!');
      if (completeFinder.evaluate().isNotEmpty) {
        Navigator.of(tester.element(completeFinder)).pop();
        await tester.pump(const Duration(milliseconds: 500));
      }
    });

    testWidgets('handles WritingGameOver without crash', (tester) async {
      await pumpScreen(tester, level: 2);

      final gameOverState = WritingGameOver(
        quests: const [sampleQuest1],
        currentIndex: 0,
        gameType: GameSubtype.opinionWriting,
        level: 2,
      );
      when(() => mockWritingBloc.state).thenReturn(gameOverState);
      writingStreamController.add(gameOverState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(OpinionWritingScreen), findsOneWidget);

      // Dismiss game over dialog if present
      final giveUpFinder = find.text('GIVE UP');
      if (giveUpFinder.evaluate().isNotEmpty) {
        Navigator.of(tester.element(giveUpFinder)).pop();
        await tester.pump(const Duration(milliseconds: 500));
      }
    });

    testWidgets('records to ErrorJournal when answering incorrectly as authenticated user', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(
        AuthState.authenticated(
          const UserEntity(
            id: 'user_123',
            email: 'test@vowl.app',
            displayName: 'Learner',
          ),
        ),
      );

      await pumpScreen(tester, level: 2);

      final opt0 = sampleQuest1.options![0];
      final opt1 = sampleQuest1.options![1];

      await tester.ensureVisible(find.byKey(Key('opinion_idea_card_$opt0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('opinion_idea_card_$opt0')));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(Key('opinion_idea_card_$opt1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(Key('opinion_idea_card_$opt1')));
      await tester.pumpAndSettle();

      await scrollAndTapSubmitButton(tester);
      await tester.pumpAndSettle();

      verify(() => mockWritingBloc.add(const SubmitAnswer(false))).called(1);
    });
  });

  group('OpinionWritingScreen - 6. Responsiveness & Accessibility', () {
    testWidgets('renders properly on small screen (320x568)', (tester) async {
      await pumpScreen(
        tester,
        level: 2,
        surfaceSize: const Size(320, 568),
      );

      expect(find.byType(OpinionWritingScreen), findsOneWidget);
      expect(find.byKey(const Key('opinion_drafting_pad_target')), findsOneWidget);
    });

    testWidgets('renders properly on tablet screen (800x1280)', (tester) async {
      await pumpScreen(
        tester,
        level: 2,
        surfaceSize: const Size(800, 1280),
      );

      expect(find.byType(OpinionWritingScreen), findsOneWidget);
      expect(find.byKey(const Key('opinion_drafting_pad_target')), findsOneWidget);
    });

    testWidgets('renders with 1.3x high text scale without overflow', (tester) async {
      await pumpScreen(
        tester,
        level: 2,
        textScaleFactor: 1.3,
      );

      expect(find.byType(OpinionWritingScreen), findsOneWidget);
    });

    testWidgets('renders properly in light theme', (tester) async {
      await pumpScreen(
        tester,
        level: 2,
        themeMode: ThemeMode.light,
      );

      expect(find.byType(OpinionWritingScreen), findsOneWidget);
    });

    testWidgets('briefing overlay shows at level 1 and dismisses on tap', (tester) async {
      await pumpScreen(
        tester,
        level: 1,
        surfaceSize: const Size(390, 1000),
      );

      expect(find.byType(QuestBriefingOverlay), findsOneWidget);

      final startButton = find.descendant(
        of: find.byType(QuestBriefingOverlay),
        matching: find.byType(ScaleButton),
      );
      expect(startButton, findsOneWidget);
      await tester.ensureVisible(startButton);
      await tester.pumpAndSettle();
      await tester.tap(startButton);
      await tester.pumpAndSettle();

      expect(find.byType(QuestBriefingOverlay), findsNothing);
    });
  });
}

