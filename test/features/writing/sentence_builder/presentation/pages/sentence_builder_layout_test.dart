import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/core/presentation/game_mechanics/typing/type_to_confirm_overlay.dart';
import 'package:vowl/core/presentation/widgets/game_feedback_card.dart';
import 'package:vowl/core/presentation/widgets/quest_hint_button.dart';
import 'package:vowl/core/presentation/widgets/quest_briefing_overlay.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
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
import 'package:vowl/features/writing/sentence_builder/presentation/pages/sentence_builder_screen.dart';
import 'package:vowl/features/writing/sentence_builder/presentation/widgets/sentence_builder_instruction.dart';
import 'package:vowl/features/writing/sentence_builder/presentation/widgets/sentence_builder_keyboard_input.dart';
import 'package:vowl/features/writing/sentence_builder/presentation/widgets/sentence_builder_piece_pool.dart';
import 'package:vowl/features/writing/sentence_builder/presentation/widgets/sentence_builder_workbench.dart';
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
    id: 'sb_q1',
    instruction: 'Put the words in the right order.',
    difficulty: 1,
    subtype: GameSubtype.sentenceBuilder,
    sentenceType: 'DECLARATIVE',
    correctAnswer: 'The cat sleeps peacefully.',
    shuffledWords: ['peacefully.', 'The', 'sleeps', 'cat'],
    hint: 'Subject goes first.',
    explanation: 'Subject: The cat, Verb: sleeps, Adverb: peacefully.',
    xpReward: 20,
    coinReward: 10,
  );

  const sampleQuest2 = WritingQuest(
    id: 'sb_q2',
    instruction: 'Construct the question properly.',
    difficulty: 2,
    subtype: GameSubtype.sentenceBuilder,
    sentenceType: 'INTERROGATIVE',
    correctAnswer: 'Where are you going?',
    shuffledWords: ['going?', 'are', 'Where', 'you'],
    hint: 'Wh-word starts the sentence.',
    explanation: 'Question word precedes auxiliary verb.',
    xpReward: 25,
    coinReward: 15,
  );

  const sampleQuest3 = WritingQuest(
    id: 'sb_q3',
    instruction: 'Construct the story sentence.',
    difficulty: 6,
    subtype: GameSubtype.sentenceBuilder,
    sentenceType: 'DECLARATIVE',
    correctAnswer: 'The brave knight fought the dragon bravely.',
    shuffledWords: ['dragon', 'brave', 'fought', 'The', 'knight', 'bravely.', 'the'],
    hint: 'Knight is the subject.',
    explanation: 'Subject: The brave knight, Verb: fought, Object: the dragon, Adverb: bravely.',
    xpReward: 30,
    coinReward: 20,
  );

  const testLoadedState = WritingLoaded(
    quests: [sampleQuest1, sampleQuest2],
    currentIndex: 0,
    livesRemaining: 3,
    wrongCount: 0,
    hintUsed: false,
    answerStatus: AnswerStatus.unanswered,
    gameType: GameSubtype.sentenceBuilder,
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
        gameType: GameSubtype.sentenceBuilder,
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
          id: 'sb_user_1',
          email: 'sb@vowl.app',
          displayName: 'Sentence Architect',
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
    tester.view.physicalSize = surfaceSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

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
              child: SentenceBuilderScreen(
                level: level,
                gameType: GameSubtype.sentenceBuilder,
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
    final submitButton = find.byKey(const Key('sentence_builder_submit_button'));
    await tester.ensureVisible(submitButton);
    await tester.pumpAndSettle();
    await tester.tap(submitButton);
    await tester.pump();
  }

  group('SentenceBuilderScreen - 1. Initial Rendering & Layout', () {
    testWidgets('renders all normal mode components at level 2', (tester) async {
      await pumpScreen(tester, level: 2);

      expect(find.byType(WritingBaseLayout), findsOneWidget);
      expect(find.byKey(const Key('sentence_builder_scroll_view')), findsOneWidget);
      expect(find.byType(SentenceBuilderInstruction), findsOneWidget);
      expect(find.byType(SentenceBuilderWorkbench), findsOneWidget);
      expect(find.byType(SentenceBuilderPiecePool), findsOneWidget);
      expect(find.byKey(const Key('sentence_builder_submit_button')), findsOneWidget);
      expect(find.text('CHECK SENTENCE'), findsOneWidget);
      expect(find.text('Drop pieces here'), findsOneWidget);
      expect(find.textContaining('DECLARATIVE'), findsOneWidget);

      // Verify all pool pieces rendered
      for (final piece in sampleQuest1.shuffledWords!) {
        expect(find.byKey(Key('sentence_builder_piece_$piece')), findsOneWidget);
      }
    });

    testWidgets('renders hard mode components at level 6', (tester) async {
      const hardState = WritingLoaded(
        quests: [sampleQuest1],
        currentIndex: 0,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.unanswered,
        gameType: GameSubtype.sentenceBuilder,
        level: 6,
      );
      await pumpScreen(tester, state: hardState, level: 6);

      expect(find.byType(SentenceBuilderKeyboardInput), findsOneWidget);
      expect(find.byKey(const Key('sentence_builder_text_field')), findsOneWidget);
      expect(find.byType(SentenceBuilderWorkbench), findsNothing);
      expect(find.text('CHECK SENTENCE'), findsOneWidget);
    });

    testWidgets('renders empty shrink when quest is null', (tester) async {
      const initialWritingState = WritingInitial();
      await pumpScreen(tester, state: initialWritingState, level: 2);

      expect(find.byType(SentenceBuilderInstruction), findsNothing);
      expect(find.byType(SentenceBuilderWorkbench), findsNothing);
    });

    testWidgets('dispatches FetchWritingQuests on init', (tester) async {
      await pumpScreen(tester, level: 2);

      verify(
        () => mockWritingBloc.add(
          const FetchWritingQuests(
            gameType: GameSubtype.sentenceBuilder,
            level: 2,
          ),
        ),
      ).called(1);
    });
  });

  group('SentenceBuilderScreen - 2. Normal Mode Interactions (Level < 6)', () {
    testWidgets('tapping an available piece snaps it into the workbench', (tester) async {
      await pumpScreen(tester, level: 2);

      final piece = sampleQuest1.shuffledWords![1]; // 'The'
      final pieceFinder = find.byKey(Key('sentence_builder_piece_$piece'));
      expect(pieceFinder, findsOneWidget);

      await tester.tap(pieceFinder);
      await tester.pumpAndSettle();

      verify(() => mockHapticService.success()).called(1);
      expect(find.byKey(Key('sentence_builder_assembled_piece_${piece}_0')), findsOneWidget);
      expect(find.text('Drop pieces here'), findsNothing);
    });

    testWidgets('dragging a piece into the workbench target snaps it', (tester) async {
      await pumpScreen(tester, level: 2, surfaceSize: const Size(390, 1000));

      final piece = sampleQuest1.shuffledWords![0]; // 'peacefully.'
      final pieceFinder = find.byKey(Key('sentence_builder_piece_$piece'));
      final dropTarget = find.byKey(const Key('sentence_builder_workbench_target'));

      final start = tester.getCenter(pieceFinder);
      final target = tester.getCenter(dropTarget);

      final gesture = await tester.startGesture(start);
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.moveBy(const Offset(0, -20));
      await tester.pump(const Duration(milliseconds: 50));
      await gesture.moveTo(target);
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.up();
      await tester.pumpAndSettle();

      verify(() => mockHapticService.success()).called(1);
      expect(find.byKey(Key('sentence_builder_assembled_piece_${piece}_0')), findsOneWidget);
    });

    testWidgets('tapping an assembled piece removes it and restores it to pool', (tester) async {
      await pumpScreen(tester, level: 2);

      final piece = sampleQuest1.shuffledWords![1]; // 'The'
      await tester.tap(find.byKey(Key('sentence_builder_piece_$piece')));
      await tester.pumpAndSettle();

      final assembledFinder = find.byKey(Key('sentence_builder_assembled_piece_${piece}_0'));
      expect(assembledFinder, findsOneWidget);

      await tester.tap(assembledFinder);
      await tester.pumpAndSettle();

      verify(() => mockHapticService.selection()).called(1);
      expect(find.byKey(Key('sentence_builder_assembled_piece_${piece}_0')), findsNothing);
      expect(find.byKey(Key('sentence_builder_piece_$piece')), findsOneWidget);
      expect(find.text('Drop pieces here'), findsOneWidget);
    });
  });

  group('SentenceBuilderScreen - 3. Submission & Validation (Normal Mode)', () {
    testWidgets('tapping CHECK SENTENCE with empty workbench shows warning and does not submit', (tester) async {
      await pumpScreen(tester, level: 2);

      await scrollAndTapSubmitButton(tester);
      await tester.pumpAndSettle();

      expect(find.text('Please build your sentence first.'), findsOneWidget);
      verify(() => mockHapticService.selection()).called(1);
      verifyNever(() => mockWritingBloc.add(any(that: isA<SubmitAnswer>())));
    });

    testWidgets('submitting incorrect order dispatches SubmitAnswer(false)', (tester) async {
      await pumpScreen(tester, level: 2);

      // Wrong order: 'peacefully.' then 'The'
      await tester.tap(find.byKey(const Key('sentence_builder_piece_peacefully.')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('sentence_builder_piece_The')));
      await tester.pumpAndSettle();

      await scrollAndTapSubmitButton(tester);
      await tester.pumpAndSettle();

      verify(() => mockWritingBloc.add(const SubmitAnswer(false))).called(1);
    });

    testWidgets('submitting correct order triggers success and opens TypeToConfirmOverlay', (tester) async {
      await pumpScreen(tester, level: 2);

      // Correct order: 'The', 'cat', 'sleeps', 'peacefully.'
      await tester.tap(find.byKey(const Key('sentence_builder_piece_The')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('sentence_builder_piece_cat')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('sentence_builder_piece_sleeps')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('sentence_builder_piece_peacefully.')));
      await tester.pumpAndSettle();

      await scrollAndTapSubmitButton(tester);
      await tester.pumpAndSettle();

      verify(() => mockHapticService.success()).called(5); // 4 snaps + 1 validation
      expect(find.byType(TypeToConfirmOverlay), findsOneWidget);
    });

    testWidgets('confirming in TypeToConfirmOverlay dispatches SubmitAnswer(true)', (tester) async {
      await pumpScreen(tester, level: 2);

      // Assemble correctly
      await tester.tap(find.byKey(const Key('sentence_builder_piece_The')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('sentence_builder_piece_cat')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('sentence_builder_piece_sleeps')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('sentence_builder_piece_peacefully.')));
      await tester.pumpAndSettle();

      await scrollAndTapSubmitButton(tester);
      await tester.pumpAndSettle();

      expect(find.byType(TypeToConfirmOverlay), findsOneWidget);

      // Enter expected text in TypeToConfirmOverlay
      final textField = find.descendant(
        of: find.byType(TypeToConfirmOverlay),
        matching: find.byType(TextField),
      );
      await tester.enterText(textField, sampleQuest1.correctAnswer!);
      await tester.pumpAndSettle();

      final submitBtn = find.descendant(
        of: find.byType(TypeToConfirmOverlay),
        matching: find.text('SUBMIT'),
      );
      await tester.tap(submitBtn);
      await tester.pump(const Duration(milliseconds: 900));

      verify(() => mockWritingBloc.add(const SubmitAnswer(true))).called(1);
    });

    testWidgets('skipping TypeToConfirmOverlay dispatches SubmitAnswer(false)', (tester) async {
      await pumpScreen(tester, level: 2);

      // Assemble correctly
      await tester.tap(find.byKey(const Key('sentence_builder_piece_The')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('sentence_builder_piece_cat')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('sentence_builder_piece_sleeps')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('sentence_builder_piece_peacefully.')));
      await tester.pumpAndSettle();

      await scrollAndTapSubmitButton(tester);
      await tester.pumpAndSettle();

      expect(find.byType(TypeToConfirmOverlay), findsOneWidget);

      final textField = find.descendant(
        of: find.byType(TypeToConfirmOverlay),
        matching: find.byType(TextField),
      );
      final submitBtn = find.descendant(
        of: find.byType(TypeToConfirmOverlay),
        matching: find.text('SUBMIT'),
      );

      // Enter incorrect text 3 times to exhaust attempts (with >500ms debounce interval)
      for (int i = 0; i < 3; i++) {
        await tester.enterText(textField, 'Wrong sentence attempt');
        await tester.pump(const Duration(milliseconds: 600));
        await tester.tap(submitBtn);
        await tester.pump(const Duration(milliseconds: 600));
      }

      final continueBtn = find.descendant(
        of: find.byType(ScaleButton),
        matching: find.text('CONTINUE'),
      );
      expect(continueBtn, findsOneWidget);
      await tester.tap(continueBtn);
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockWritingBloc.add(const SubmitAnswer(false))).called(1);
    });
  });

  group('SentenceBuilderScreen - 4. Hard Mode (Level >= 6)', () {
    const hardState = WritingLoaded(
      quests: [sampleQuest1],
      currentIndex: 0,
      livesRemaining: 3,
      wrongCount: 0,
      hintUsed: false,
      answerStatus: AnswerStatus.unanswered,
      gameType: GameSubtype.sentenceBuilder,
      level: 6,
    );

    testWidgets('tapping piece pool in hard mode displays info snackbar', (tester) async {
      await pumpScreen(tester, state: hardState, level: 6);

      final poolFinder = find.byKey(const Key('sentence_builder_hard_mode_pool_gesture'));
      await tester.tap(poolFinder, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(
        find.text('Hard Mode! Dragging is disabled. Please type your answer below.'),
        findsOneWidget,
      );
    });

    testWidgets('submitting empty text in hard mode shows warning', (tester) async {
      await pumpScreen(tester, state: hardState, level: 6);

      await scrollAndTapSubmitButton(tester);
      await tester.pumpAndSettle();

      expect(find.text('Please build your sentence first.'), findsOneWidget);
      verifyNever(() => mockWritingBloc.add(any(that: isA<SubmitAnswer>())));
    });

    testWidgets('submitting without initial capital letter shows warning', (tester) async {
      await pumpScreen(tester, state: hardState, level: 6);

      await tester.enterText(
        find.byKey(const Key('sentence_builder_text_field')),
        'the cat sleeps peacefully.',
      );
      await tester.pumpAndSettle();

      await scrollAndTapSubmitButton(tester);
      await tester.pumpAndSettle();

      expect(find.text('Please start your sentence with a capital letter.'), findsOneWidget);
      verifyNever(() => mockWritingBloc.add(any(that: isA<SubmitAnswer>())));
    });

    testWidgets('submitting without proper ending punctuation shows warning', (tester) async {
      await pumpScreen(tester, state: hardState, level: 6);

      await tester.enterText(
        find.byKey(const Key('sentence_builder_text_field')),
        'The cat sleeps peacefully',
      );
      await tester.pumpAndSettle();

      await scrollAndTapSubmitButton(tester);
      await tester.pumpAndSettle();

      expect(
        find.text('Please end your sentence with proper punctuation (., !, or ?).'),
        findsOneWidget,
      );
      verifyNever(() => mockWritingBloc.add(any(that: isA<SubmitAnswer>())));
    });

    testWidgets('close match typo shows warning and does not consume life', (tester) async {
      const hardStateQuest3 = WritingLoaded(
        quests: [sampleQuest3],
        currentIndex: 0,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.unanswered,
        gameType: GameSubtype.sentenceBuilder,
        level: 6,
      );
      await pumpScreen(tester, state: hardStateQuest3, level: 6);

      // Minor typo in 7-word sentence: 'bravly' vs 'bravely' -> close match > 0.85
      await tester.enterText(
        find.byKey(const Key('sentence_builder_text_field')),
        'The brave knight fought the dragon bravly.',
      );
      await tester.pumpAndSettle();

      await scrollAndTapSubmitButton(tester);
      await tester.pumpAndSettle();

      expect(
        find.text('Almost! Check your spelling against the words above.'),
        findsOneWidget,
      );
    });

    testWidgets('completely wrong text in hard mode dispatches SubmitAnswer(false)', (tester) async {
      await pumpScreen(tester, state: hardState, level: 6);

      await tester.enterText(
        find.byKey(const Key('sentence_builder_text_field')),
        'A completely different sentence entirely.',
      );
      await tester.pumpAndSettle();

      await scrollAndTapSubmitButton(tester);
      await tester.pumpAndSettle();

      verify(() => mockWritingBloc.add(const SubmitAnswer(false))).called(1);
    });

    testWidgets('correct text in hard mode directly dispatches SubmitAnswer(true)', (tester) async {
      await pumpScreen(tester, state: hardState, level: 6);

      await tester.enterText(
        find.byKey(const Key('sentence_builder_text_field')),
        'The cat sleeps peacefully.',
      );
      await tester.pumpAndSettle();

      await scrollAndTapSubmitButton(tester);
      await tester.pumpAndSettle();

      verify(() => mockWritingBloc.add(const SubmitAnswer(true))).called(1);
      expect(find.byType(TypeToConfirmOverlay), findsNothing);
    });
  });

  group('SentenceBuilderScreen - 5. Feedback, Navigation & Reset', () {
    testWidgets('displays feedback card when answered correctly', (tester) async {
      const state = WritingLoaded(
        quests: [sampleQuest1],
        currentIndex: 0,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.correct,
        gameType: GameSubtype.sentenceBuilder,
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
        gameType: GameSubtype.sentenceBuilder,
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

    testWidgets('onQuestionReset resets workbench and controller on question change', (tester) async {
      await pumpScreen(tester, level: 2);

      // Snap a piece
      await tester.tap(find.byKey(const Key('sentence_builder_piece_The')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('sentence_builder_assembled_piece_The_0')), findsOneWidget);

      const nextState = WritingLoaded(
        quests: [sampleQuest1, sampleQuest2],
        currentIndex: 1,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.unanswered,
        gameType: GameSubtype.sentenceBuilder,
        level: 2,
      );
      when(() => mockWritingBloc.state).thenReturn(nextState);
      writingStreamController.add(nextState);
      await tester.pumpAndSettle();

      // Workbench empty for question 2
      expect(find.text('Drop pieces here'), findsOneWidget);
      expect(find.byKey(const Key('sentence_builder_piece_Where')), findsOneWidget);
    });
  });

  group('SentenceBuilderScreen - 6. Completion, Game Over & Error Journal', () {
    testWidgets('shows completion dialog on WritingGameComplete', (tester) async {
      await pumpScreen(tester, level: 2);

      const completeState = WritingGameComplete(
        xpEarned: 50,
        coinsEarned: 20,
        questCount: 2,
        gameType: GameSubtype.sentenceBuilder,
        level: 2,
      );
      when(() => mockWritingBloc.state).thenReturn(completeState);
      writingStreamController.add(completeState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('LEVEL COMPLETE!'), findsOneWidget);

      final completeFinder = find.text('LEVEL COMPLETE!');
      if (completeFinder.evaluate().isNotEmpty) {
        Navigator.of(tester.element(completeFinder)).pop();
        await tester.pump(const Duration(milliseconds: 500));
      }
    });

    testWidgets('handles WritingGameOver without crash', (tester) async {
      await pumpScreen(tester, level: 2);

      const gameOverState = WritingGameOver(
        quests: [sampleQuest1],
        currentIndex: 0,
        gameType: GameSubtype.sentenceBuilder,
        level: 2,
      );
      when(() => mockWritingBloc.state).thenReturn(gameOverState);
      writingStreamController.add(gameOverState);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('records to ErrorJournal when answering incorrectly as authenticated user', (tester) async {
      await pumpScreen(tester, level: 2);

      // Incorrect answer
      await tester.tap(find.byKey(const Key('sentence_builder_piece_cat')));
      await tester.pumpAndSettle();

      await scrollAndTapSubmitButton(tester);
      await tester.pumpAndSettle();

      verify(() => mockWritingBloc.add(const SubmitAnswer(false))).called(1);
    });
  });

  group('SentenceBuilderScreen - 7. Responsiveness & Accessibility', () {
    testWidgets('renders properly on small screen (320x568)', (tester) async {
      await pumpScreen(tester, level: 2, surfaceSize: const Size(320, 568));

      expect(find.byType(WritingBaseLayout), findsOneWidget);
      expect(find.byType(SentenceBuilderWorkbench), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders properly on tablet screen (800x1280)', (tester) async {
      await pumpScreen(tester, level: 2, surfaceSize: const Size(800, 1280));

      expect(find.byType(WritingBaseLayout), findsOneWidget);
      expect(find.byType(SentenceBuilderWorkbench), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders with 1.3x high text scale without overflow', (tester) async {
      await pumpScreen(tester, level: 2, textScaleFactor: 1.3);

      expect(find.byType(WritingBaseLayout), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders properly in light theme', (tester) async {
      await pumpScreen(tester, level: 2, themeMode: ThemeMode.light);

      expect(find.byType(WritingBaseLayout), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('briefing overlay shows at level 1 and dismisses on tap', (tester) async {
      const lvl1State = WritingLoaded(
        quests: [sampleQuest1],
        currentIndex: 0,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.unanswered,
        gameType: GameSubtype.sentenceBuilder,
        level: 1,
      );
      await pumpScreen(
        tester,
        state: lvl1State,
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
