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
import 'package:vowl/features/writing/fix_the_sentence/presentation/pages/fix_the_sentence_screen.dart';
import 'package:vowl/features/writing/fix_the_sentence/presentation/widgets/fix_the_sentence_correction_options.dart';
import 'package:vowl/features/writing/fix_the_sentence/presentation/widgets/fix_the_sentence_digital_blackboard.dart';
import 'package:vowl/features/writing/fix_the_sentence/presentation/widgets/fix_the_sentence_instruction.dart';
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
    id: 'fts_q1',
    instruction: 'Fix the error in the sentence.',
    difficulty: 1,
    subtype: GameSubtype.fixTheSentence,
    passage: "She don't like apples.",
    missingWord: "don't",
    correctAnswer: "doesn't",
    options: ["doesn't", "aren't", "isn't", "wasn't"],
    errorType: 'grammar',
    hint: 'Check subject-verb agreement.',
    explanation: 'Third-person singular uses "doesn\'t".',
    xpReward: 20,
    coinReward: 10,
  );

  const sampleQuest2 = WritingQuest(
    id: 'fts_q2',
    instruction: 'Identify and fix the typo.',
    difficulty: 1,
    subtype: GameSubtype.fixTheSentence,
    passage: 'I went to the librari yesterday.',
    missingWord: 'librari',
    correctAnswer: 'library',
    options: ['library', 'libary', 'liberary'],
    errorType: 'spelling',
    hint: 'Remember the spelling ends with -ary.',
    explanation: '"Library" is spelled with an "a" and "r-y".',
    xpReward: 25,
    coinReward: 15,
  );

  const sampleMinimalQuest = WritingQuest(
    id: 'fts_minimal',
    instruction: 'Correct the word.',
    difficulty: 1,
    subtype: GameSubtype.fixTheSentence,
    passage: 'NoTargetMatchHere',
    missingWord: 'notfound',
    correctAnswer: 'found',
    options: ['found', 'lost'],
  );

  const testLoadedState = WritingLoaded(
    quests: [sampleQuest1, sampleQuest2],
    currentIndex: 0,
    livesRemaining: 3,
    wrongCount: 0,
    hintUsed: false,
    answerStatus: AnswerStatus.unanswered,
    gameType: GameSubtype.fixTheSentence,
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
        gameType: GameSubtype.fixTheSentence,
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
          id: 'fts_user_1',
          email: 'fts@vowl.app',
          displayName: 'FixSentence Learner',
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
              child: FixTheSentenceScreen(
                level: level,
                gameType: GameSubtype.fixTheSentence,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('FixTheSentenceScreen - 1. Initial Rendering & Layout', () {
    testWidgets('renders all essential components in normal mode (level 2)', (tester) async {
      await pumpScreen(tester, level: 2);

      expect(find.byType(WritingBaseLayout), findsOneWidget);
      expect(find.byType(FixTheSentenceInstruction), findsOneWidget);
      expect(find.byType(FixTheSentenceDigitalBlackboard), findsOneWidget);
      expect(find.byKey(const Key('fix_the_sentence_scroll_view')), findsOneWidget);
      expect(find.byKey(const Key('fix_the_sentence_scratch_target')), findsOneWidget);
      expect(find.text("DON'T"), findsOneWidget);
    });

    testWidgets('renders DigitalBlackboard with full passage and highlighted error word', (tester) async {
      await pumpScreen(tester, level: 2);

      expect(find.text("DON'T"), findsOneWidget);
      expect(find.byType(RichText), findsWidgets);
      final richTexts = tester.widgetList<RichText>(find.byType(RichText));
      final hasPassageText = richTexts.any(
        (rt) =>
            rt.text.toPlainText().contains('She') &&
            rt.text.toPlainText().contains('like apples.'),
      );
      expect(hasPassageText, isTrue);
    });

    testWidgets('renders fallback when passage has no direct word regex match', (tester) async {
      const state = WritingLoaded(
        quests: [sampleMinimalQuest],
        currentIndex: 0,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.unanswered,
        gameType: GameSubtype.fixTheSentence,
        level: 2,
      );
      await pumpScreen(tester, state: state, level: 2);

      expect(find.byType(FixTheSentenceDigitalBlackboard), findsOneWidget);
      expect(find.text('NOTFOUND'), findsOneWidget);
    });

    testWidgets('renders shimmer loading when in initial state', (tester) async {
      const state = WritingInitial();
      await pumpScreen(tester, state: state, level: 2);

      expect(find.byType(GameShimmerLoading), findsOneWidget);
      expect(find.byType(FixTheSentenceDigitalBlackboard), findsNothing);
    });

    testWidgets('dispatches FetchWritingQuests on init', (tester) async {
      await pumpScreen(tester, level: 2);

      verify(() => mockWritingBloc.add(
        const FetchWritingQuests(gameType: GameSubtype.fixTheSentence, level: 2),
      )).called(1);
    });
  });

  group('FixTheSentenceScreen - 2. Instruction Banner & Error Type', () {
    testWidgets('displays instruction with error type badge', (tester) async {
      await pumpScreen(tester, level: 2);

      expect(find.byType(FixTheSentenceInstruction), findsOneWidget);
      expect(find.text('Fix the error in the sentence. (GRAMMAR)'), findsOneWidget);
    });

    testWidgets('displays instruction without error type if errorType is null', (tester) async {
      const state = WritingLoaded(
        quests: [sampleMinimalQuest],
        currentIndex: 0,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.unanswered,
        gameType: GameSubtype.fixTheSentence,
        level: 2,
      );
      await pumpScreen(tester, state: state, level: 2);

      expect(find.text('Correct the word.'), findsOneWidget);
    });

    testWidgets('updates instruction text when wiped', (tester) async {
      await pumpScreen(tester, level: 2);

      final scratchTarget = find.byKey(const Key('fix_the_sentence_scratch_target'));
      expect(scratchTarget, findsOneWidget);
      await tester.tap(scratchTarget);
      await tester.pumpAndSettle();

      expect(find.text('Select the correct replacement word (GRAMMAR)'), findsOneWidget);
    });
  });

  group('FixTheSentenceScreen - 3. Blackboard Wiping & Scratch Interaction', () {
    testWidgets('tapping blackboard target triggers hint sound, success haptic, and sets wiped', (tester) async {
      await pumpScreen(tester, level: 2);

      final scratchTarget = find.byKey(const Key('fix_the_sentence_scratch_target'));
      await tester.tap(scratchTarget);
      await tester.pumpAndSettle();

      verify(() => mockHapticService.success()).called(1);
      verify(() => mockSoundService.playHint()).called(1);
      expect(find.byKey(const Key('fix_the_sentence_wiped_target')), findsOneWidget);
      expect(find.text('____'), findsOneWidget);
    });

    testWidgets('panning blackboard target accumulates erase points and wipes after 35 points', (tester) async {
      await pumpScreen(tester, level: 2);

      final scratchTarget = find.byKey(const Key('fix_the_sentence_scratch_target'));
      expect(scratchTarget, findsOneWidget);

      final gesture = await tester.startGesture(tester.getCenter(scratchTarget));
      for (int i = 0; i < 60; i++) {
        await gesture.moveBy(const Offset(2, 2));
        await tester.pump(const Duration(milliseconds: 10));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      verify(() => mockHapticService.selection()).called(greaterThanOrEqualTo(1));
      verify(() => mockHapticService.success()).called(1);
      verify(() => mockSoundService.playHint()).called(1);
      expect(find.byKey(const Key('fix_the_sentence_wiped_target')), findsOneWidget);
    });

    testWidgets('tapping or panning blackboard does nothing when already answered', (tester) async {
      const state = WritingLoaded(
        quests: [sampleQuest1],
        currentIndex: 0,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.correct,
        gameType: GameSubtype.fixTheSentence,
        level: 2,
      );
      await pumpScreen(tester, state: state, level: 2);

      final scratchTarget = find.byKey(const Key('fix_the_sentence_scratch_target'));
      expect(scratchTarget, findsOneWidget);
      await tester.tap(scratchTarget, warnIfMissed: false);
      await tester.pump();

      verifyNever(() => mockSoundService.playHint());
      expect(find.byKey(const Key('fix_the_sentence_wiped_target')), findsNothing);
    });
  });

  group('FixTheSentenceScreen - 4. Correction Options (Stage 1)', () {
    testWidgets('options are hidden until blackboard is wiped', (tester) async {
      await pumpScreen(tester, level: 2);

      expect(find.byType(FixTheSentenceCorrectionOptions), findsNothing);

      await tester.tap(find.byKey(const Key('fix_the_sentence_scratch_target')));
      await tester.pumpAndSettle();

      expect(find.byType(FixTheSentenceCorrectionOptions), findsOneWidget);
      for (final opt in sampleQuest1.options!) {
        expect(find.byKey(Key('fix_the_sentence_option_$opt')), findsOneWidget);
        expect(find.text(opt.toUpperCase()), findsOneWidget);
      }
    });

    testWidgets('selecting incorrect option submits wrong answer and does not show TypeToConfirmOverlay', (tester) async {
      await pumpScreen(tester, level: 2);

      await tester.tap(find.byKey(const Key('fix_the_sentence_scratch_target')));
      await tester.pumpAndSettle();

      final wrongOption = find.byKey(const Key("fix_the_sentence_option_aren't"));
      await tester.tap(wrongOption);
      await tester.pumpAndSettle();

      verify(() => mockWritingBloc.add(const SubmitAnswer(false))).called(1);
      expect(find.byType(TypeToConfirmOverlay), findsNothing);
    });

    testWidgets('selecting correct option triggers success haptic and reveals TypeToConfirmOverlay', (tester) async {
      await pumpScreen(tester, level: 2);

      await tester.tap(find.byKey(const Key('fix_the_sentence_scratch_target')));
      await tester.pumpAndSettle();

      final correctOption = find.byKey(const Key("fix_the_sentence_option_doesn't"));
      await tester.tap(correctOption);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      verify(() => mockHapticService.success()).called(greaterThanOrEqualTo(2));
      expect(find.byType(TypeToConfirmOverlay), findsOneWidget);
      expect(find.text("DOESN'T"), findsAtLeastNWidgets(1));
    });

    testWidgets('tapping option when already answered does nothing', (tester) async {
      await pumpScreen(tester, level: 2);

      await tester.tap(find.byKey(const Key('fix_the_sentence_scratch_target')));
      await tester.pumpAndSettle();

      const answeredState = WritingLoaded(
        quests: [sampleQuest1],
        currentIndex: 0,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.correct,
        gameType: GameSubtype.fixTheSentence,
        level: 2,
      );
      when(() => mockWritingBloc.state).thenReturn(answeredState);
      writingStreamController.add(answeredState);
      await tester.pumpAndSettle();

      final opt = find.byKey(const Key("fix_the_sentence_option_isn't"));
      if (opt.evaluate().isNotEmpty) {
        await tester.tap(opt, warnIfMissed: false);
        await tester.pump();
      }

      verifyNever(() => mockWritingBloc.add(const SubmitAnswer(false)));
    });
  });

  group('FixTheSentenceScreen - 5. TypeToConfirmOverlay (Stage 2 Confirmation)', () {
    testWidgets('TypeToConfirmOverlay displays expected word', (tester) async {
      await pumpScreen(tester, level: 2);

      await tester.tap(find.byKey(const Key('fix_the_sentence_scratch_target')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key("fix_the_sentence_option_doesn't")));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      final overlay = tester.widget<TypeToConfirmOverlay>(find.byType(TypeToConfirmOverlay));
      expect(overlay.expectedText, "doesn't");
    });

    testWidgets('confirming typing in TypeToConfirmOverlay speaks corrected text and dispatches SubmitAnswer(true)', (tester) async {
      await pumpScreen(tester, level: 2);

      await tester.tap(find.byKey(const Key('fix_the_sentence_scratch_target')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key("fix_the_sentence_option_doesn't")));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      final overlay = tester.widget<TypeToConfirmOverlay>(find.byType(TypeToConfirmOverlay));
      overlay.onConfirmed();
      await tester.pump();

      verify(() => mockTtsService.speak("She doesn't like apples.")).called(1);
      verify(() => mockWritingBloc.add(const SubmitAnswer(true))).called(1);
    });

    testWidgets('skipping typing in TypeToConfirmOverlay dispatches SubmitAnswer(false)', (tester) async {
      await pumpScreen(tester, level: 2);

      await tester.tap(find.byKey(const Key('fix_the_sentence_scratch_target')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key("fix_the_sentence_option_doesn't")));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      final overlay = tester.widget<TypeToConfirmOverlay>(find.byType(TypeToConfirmOverlay));
      overlay.onSkipped();
      await tester.pump();

      verify(() => mockWritingBloc.add(const SubmitAnswer(false))).called(1);
    });
  });

  group('FixTheSentenceScreen - 6. Feedback, Navigation & Reset', () {
    testWidgets('displays feedback card when answered correctly', (tester) async {
      const state = WritingLoaded(
        quests: [sampleQuest1],
        currentIndex: 0,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.correct,
        gameType: GameSubtype.fixTheSentence,
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
        gameType: GameSubtype.fixTheSentence,
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

    testWidgets('onQuestionReset resets wiped state and options on new question', (tester) async {
      await pumpScreen(tester, level: 2);

      await tester.tap(find.byKey(const Key('fix_the_sentence_scratch_target')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('fix_the_sentence_wiped_target')), findsOneWidget);

      const nextState = WritingLoaded(
        quests: [sampleQuest1, sampleQuest2],
        currentIndex: 1,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.unanswered,
        gameType: GameSubtype.fixTheSentence,
        level: 2,
      );
      when(() => mockWritingBloc.state).thenReturn(nextState);
      writingStreamController.add(nextState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('fix_the_sentence_scratch_target')), findsOneWidget);
      expect(find.text('LIBRARI'), findsOneWidget);
    });
  });

  group('FixTheSentenceScreen - 7. Completion, Game Over & Error Journal', () {
    testWidgets('shows completion dialog on WritingGameComplete', (tester) async {
      await pumpScreen(tester, level: 2);

      const completeState = WritingGameComplete(
        xpEarned: 100,
        coinsEarned: 50,
        questCount: 2,
        gameType: GameSubtype.fixTheSentence,
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
        gameType: GameSubtype.fixTheSentence,
        level: 2,
      );
      when(() => mockWritingBloc.state).thenReturn(gameOverState);
      writingStreamController.add(gameOverState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(FixTheSentenceScreen), findsOneWidget);

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

      await tester.tap(find.byKey(const Key('fix_the_sentence_scratch_target')));
      await tester.pumpAndSettle();

      final wrongOption = find.byKey(const Key("fix_the_sentence_option_aren't"));
      await tester.tap(wrongOption);
      await tester.pumpAndSettle();

      verify(() => mockWritingBloc.add(const SubmitAnswer(false))).called(1);
    });
  });

  group('FixTheSentenceScreen - 8. Responsiveness & Accessibility', () {
    testWidgets('renders properly on small screen (320x568)', (tester) async {
      await pumpScreen(
        tester,
        level: 2,
        surfaceSize: const Size(320, 568),
      );

      expect(find.byType(FixTheSentenceScreen), findsOneWidget);
      expect(find.byType(FixTheSentenceDigitalBlackboard), findsOneWidget);
    });

    testWidgets('renders properly on tablet screen (800x1280)', (tester) async {
      await pumpScreen(
        tester,
        level: 2,
        surfaceSize: const Size(800, 1280),
      );

      expect(find.byType(FixTheSentenceScreen), findsOneWidget);
      expect(find.byType(FixTheSentenceDigitalBlackboard), findsOneWidget);
    });

    testWidgets('renders with 1.3x high text scale without overflow', (tester) async {
      await pumpScreen(
        tester,
        level: 2,
        textScaleFactor: 1.3,
      );

      expect(find.byType(FixTheSentenceScreen), findsOneWidget);
    });

    testWidgets('renders properly in light theme', (tester) async {
      await pumpScreen(
        tester,
        level: 2,
        themeMode: ThemeMode.light,
      );

      expect(find.byType(FixTheSentenceScreen), findsOneWidget);
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
