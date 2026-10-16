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
import 'package:vowl/core/utils/ml_services/language_id_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/features/writing/domain/entities/writing_quest.dart';
import 'package:vowl/features/writing/short_answer_writing/presentation/pages/short_answer_writing_screen.dart';
import 'package:vowl/features/writing/short_answer_writing/presentation/widgets/short_answer_instruction.dart';
import 'package:vowl/features/writing/short_answer_writing/presentation/widgets/short_answer_quill_prompt.dart';
import 'package:vowl/features/writing/short_answer_writing/presentation/widgets/short_answer_booster_tokens.dart';
import 'package:vowl/features/writing/short_answer_writing/presentation/widgets/short_answer_inkwell.dart';
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
class MockLanguageIdService extends Mock implements LanguageIdService {}

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
  late MockLanguageIdService mockLanguageIdService;
  late StreamController<WritingState> writingStreamController;

  const sampleQuest1 = WritingQuest(
    id: 'saw_q1',
    instruction: 'Answer the prompt using the required keywords.',
    prompt: 'How do deep-sea hydrothermal vent ecosystems survive without sunlight?',
    difficulty: 2,
    subtype: GameSubtype.shortAnswerWriting,
    options: ['bacteria', 'sulfide', 'chemosynthesis'],
    hint: 'Mention chemosynthesis by bacteria using sulfide.',
    explanation: 'Chemosynthetic bacteria convert hydrogen sulfide into organic matter.',
    sampleAnswer: 'Bacteria use hydrogen sulfide for chemosynthesis to produce food.',
    xpReward: 25,
    coinReward: 15,
  );

  const sampleQuest2 = WritingQuest(
    id: 'saw_q2',
    instruction: 'Explain renewable energy advantages.',
    prompt: 'Why are solar and wind energy important for combating climate change?',
    difficulty: 2,
    subtype: GameSubtype.shortAnswerWriting,
    options: ['clean', 'renewable', 'emissions'],
    hint: 'Focus on zero emissions from clean sources.',
    explanation: 'Clean renewable sources reduce greenhouse gas emissions.',
    sampleAnswer: 'Clean renewable energy dramatically reduces global emissions.',
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
    gameType: GameSubtype.shortAnswerWriting,
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
        gameType: GameSubtype.shortAnswerWriting,
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
    mockLanguageIdService = MockLanguageIdService();

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
          id: 'saw_user_1',
          email: 'saw@vowl.app',
          displayName: 'Short Answer Scholar',
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

    // Language ID mock
    when(() => mockLanguageIdService.identifyLanguage(any()))
        .thenAnswer((_) async => 'en');

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
    di.sl.registerSingleton<LanguageIdService>(mockLanguageIdService);

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
              child: ShortAnswerScreen(
                level: level,
                gameType: GameSubtype.shortAnswerWriting,
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
    final submitButton = find.byKey(const Key('short_answer_submit_button'));
    await tester.ensureVisible(submitButton);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.tap(submitButton);
    await tester.pump(const Duration(milliseconds: 600));
  }

  group('ShortAnswerScreen - 1. Initial Rendering & Layout', () {
    testWidgets('renders all screen components properly at level 2', (tester) async {
      await pumpScreen(tester, level: 2);

      expect(find.byType(WritingBaseLayout), findsOneWidget);
      expect(find.byKey(const Key('short_answer_scroll_view')), findsOneWidget);
      expect(find.byType(ShortAnswerInstruction), findsOneWidget);
      expect(find.byType(ShortAnswerQuillPrompt), findsOneWidget);
      expect(find.byType(ShortAnswerBoosterTokens), findsOneWidget);
      expect(find.byType(ShortAnswerInkwell), findsOneWidget);
      expect(find.byKey(const Key('short_answer_text_field')), findsOneWidget);
      expect(find.byKey(const Key('short_answer_submit_button')), findsOneWidget);
      expect(find.text('SUBMIT'), findsOneWidget);
      expect(find.text('PROMPT'), findsOneWidget);
      expect(find.text('REQUIRED KEYWORDS (USE ALL)'), findsOneWidget);

      // Verify all required booster tokens render
      for (final kw in sampleQuest1.options!) {
        expect(find.byKey(Key('short_answer_booster_token_$kw')), findsOneWidget);
      }
    });

    testWidgets('renders shimmer loading when state has null quest', (tester) async {
      const initialWritingState = WritingInitial();
      await pumpScreen(tester, state: initialWritingState, level: 2);

      expect(find.byType(GameShimmerLoading), findsOneWidget);
      expect(find.byType(ShortAnswerInstruction), findsNothing);
    });

    testWidgets('dispatches FetchWritingQuests on init', (tester) async {
      await pumpScreen(tester, level: 2);

      verify(
        () => mockWritingBloc.add(
          const FetchWritingQuests(
            gameType: GameSubtype.shortAnswerWriting,
            level: 2,
          ),
        ),
      ).called(1);
    });
  });

  group('ShortAnswerScreen - 2. Inkwell & Word Count Interactions', () {
    testWidgets('typing updates word count and ink level', (tester) async {
      await pumpScreen(tester, level: 2);

      expect(find.text('0 / 4 WORDS MIN'), findsOneWidget);

      final textField = find.byKey(const Key('short_answer_text_field'));
      await tester.enterText(textField, 'Bacteria live near hydrothermal vents.');
      await tester.pumpAndSettle();

      expect(find.text('5 / 4 WORDS MIN'), findsOneWidget);
    });

    testWidgets('typing target keywords updates booster token indicators', (tester) async {
      await pumpScreen(tester, level: 2);

      final tokenBacteria = find.byKey(const Key('short_answer_booster_token_bacteria'));
      expect(
        find.descendant(
          of: tokenBacteria,
          matching: find.byIcon(Icons.radio_button_unchecked_rounded),
        ),
        findsOneWidget,
      );

      final textField = find.byKey(const Key('short_answer_text_field'));
      await tester.enterText(textField, 'Bacteria use chemicals.');
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: tokenBacteria,
          matching: find.byIcon(Icons.check_circle_rounded),
        ),
        findsOneWidget,
      );
    });

    testWidgets('inkwell and textfield are disabled when quest is answered', (tester) async {
      const answeredState = WritingLoaded(
        quests: [sampleQuest1],
        currentIndex: 0,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.correct,
        gameType: GameSubtype.shortAnswerWriting,
        level: 2,
      );
      await pumpScreen(tester, state: answeredState, level: 2);

      final textField = tester.widget<TextField>(
        find.byKey(const Key('short_answer_text_field')),
      );
      expect(textField.enabled, isFalse);
      expect(find.byKey(const Key('short_answer_submit_button')), findsNothing);
    });
  });

  group('ShortAnswerScreen - 3. Submission & Client-Side Validation', () {
    testWidgets('tapping SUBMIT with empty text does not submit or count strikes', (tester) async {
      await pumpScreen(tester, level: 2);

      await scrollAndTapSubmitButton(tester);
      await tester.pumpAndSettle();

      verifyNever(() => mockWritingBloc.add(any(that: isA<SubmitAnswer>())));
    });

    testWidgets('submitting without initial capital letter shows warning and strike count', (tester) async {
      await pumpScreen(tester, level: 2);

      final textField = find.byKey(const Key('short_answer_text_field'));
      await tester.enterText(textField, 'bacteria use sulfide chemosynthesis.');
      await tester.pumpAndSettle();

      await scrollAndTapSubmitButton(tester);
      await tester.pumpAndSettle();

      expect(
        find.text('Please start your answer with a capital letter. (2 tries left)'),
        findsOneWidget,
      );
      verifyNever(() => mockWritingBloc.add(any(that: isA<SubmitAnswer>())));
    });

    testWidgets('submitting without proper ending punctuation shows warning and strike count', (tester) async {
      await pumpScreen(tester, level: 2);

      final textField = find.byKey(const Key('short_answer_text_field'));
      await tester.enterText(textField, 'Bacteria use sulfide chemosynthesis');
      await tester.pumpAndSettle();

      await scrollAndTapSubmitButton(tester);
      await tester.pumpAndSettle();

      expect(
        find.text('Please end your answer with proper punctuation (., !, or ?). (2 tries left)'),
        findsOneWidget,
      );
      verifyNever(() => mockWritingBloc.add(any(that: isA<SubmitAnswer>())));
    });

    testWidgets('submitting with fewer than 4 words shows warning and strike count', (tester) async {
      await pumpScreen(tester, level: 2);

      final textField = find.byKey(const Key('short_answer_text_field'));
      await tester.enterText(textField, 'Bacteria survive peacefully.');
      await tester.pumpAndSettle();

      await scrollAndTapSubmitButton(tester);
      await tester.pumpAndSettle();

      expect(
        find.text('Keep writing! A valid answer requires at least 4 words. (2 tries left)'),
        findsOneWidget,
      );
      verifyNever(() => mockWritingBloc.add(any(that: isA<SubmitAnswer>())));
    });

    testWidgets('submitting non-English text triggers language warning and strike count', (tester) async {
      when(() => mockLanguageIdService.identifyLanguage(any()))
          .thenAnswer((_) async => 'es');

      await pumpScreen(tester, level: 2);

      final textField = find.byKey(const Key('short_answer_text_field'));
      await tester.enterText(textField, 'Las bacterias sobreviven sin luz solar.');
      await tester.pumpAndSettle();

      await scrollAndTapSubmitButton(tester);
      await tester.pumpAndSettle();

      expect(
        find.text('Your answer must be written in English. Please write a natural sentence! (2 tries left)'),
        findsOneWidget,
      );
      verifyNever(() => mockWritingBloc.add(any(that: isA<SubmitAnswer>())));
    });

    testWidgets('submitting without all required keywords shows warning and strike count', (tester) async {
      await pumpScreen(tester, level: 2);

      final textField = find.byKey(const Key('short_answer_text_field'));
      // Contains 'bacteria' and 'sulfide', but missing 'chemosynthesis'
      await tester.enterText(textField, 'Bacteria utilize hydrogen sulfide deeply.');
      await tester.pumpAndSettle();

      await scrollAndTapSubmitButton(tester);
      await tester.pumpAndSettle();

      expect(
        find.text('Use all key words to complete your answer! (2 tries left)'),
        findsOneWidget,
      );
      verifyNever(() => mockWritingBloc.add(any(that: isA<SubmitAnswer>())));
    });

    testWidgets('three consecutive validation failures triggers SubmitAnswer(false)', (tester) async {
      await pumpScreen(tester, level: 2);

      final textField = find.byKey(const Key('short_answer_text_field'));

      // Strike 1
      await tester.enterText(textField, 'bacteria without capital letter.');
      await tester.pump(const Duration(milliseconds: 600));
      await scrollAndTapSubmitButton(tester);
      await tester.pump(const Duration(milliseconds: 600));

      // Strike 2
      await tester.enterText(textField, 'bacteria without capital letter again.');
      await tester.pump(const Duration(milliseconds: 600));
      await scrollAndTapSubmitButton(tester);
      await tester.pump(const Duration(milliseconds: 600));

      // Strike 3 (Terminal Strike)
      await tester.enterText(textField, 'bacteria without capital letter third time.');
      await tester.pump(const Duration(milliseconds: 600));
      await scrollAndTapSubmitButton(tester);
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockWritingBloc.add(const SubmitAnswer(false))).called(1);
    });

    testWidgets('valid answer with all keywords and correct grammar dispatches SubmitAnswer(true)', (tester) async {
      await pumpScreen(tester, level: 2);

      final textField = find.byKey(const Key('short_answer_text_field'));
      // Valid sentence with bacteria, sulfide, chemosynthesis
      await tester.enterText(
        textField,
        'Bacteria use hydrogen sulfide for chemosynthesis to produce food.',
      );
      await tester.pumpAndSettle();

      await scrollAndTapSubmitButton(tester);
      await tester.pumpAndSettle();

      verify(() => mockHapticService.success()).called(1);
      verify(() => mockWritingBloc.add(const SubmitAnswer(true))).called(1);
    });
  });

  group('ShortAnswerScreen - 4. Sample Answer & Explanation Display', () {
    testWidgets('shows sample answer and explanation when answered correctly', (tester) async {
      const correctState = WritingLoaded(
        quests: [sampleQuest1],
        currentIndex: 0,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.correct,
        gameType: GameSubtype.shortAnswerWriting,
        level: 2,
      );
      await pumpScreen(tester, state: correctState, level: 2);

      expect(find.text('SAMPLE ANSWER'), findsAtLeast(1));
      expect(find.text(sampleQuest1.sampleAnswer!), findsAtLeast(1));
      expect(find.text(sampleQuest1.explanation!), findsAtLeast(1));
    });

    testWidgets('shows sample answer and explanation on final failure', (tester) async {
      const finalFailureState = WritingLoaded(
        quests: [sampleQuest1],
        currentIndex: 0,
        livesRemaining: 0,
        wrongCount: 3,
        hintUsed: false,
        isFinalFailure: true,
        answerStatus: AnswerStatus.incorrect,
        gameType: GameSubtype.shortAnswerWriting,
        level: 2,
      );
      await pumpScreen(tester, state: finalFailureState, level: 2);

      expect(find.text('SAMPLE ANSWER'), findsAtLeast(1));
      expect(find.text(sampleQuest1.sampleAnswer!), findsAtLeast(1));
      expect(find.text(sampleQuest1.explanation!), findsAtLeast(1));
    });
  });

  group('ShortAnswerScreen - 5. Feedback, Navigation & Reset', () {
    testWidgets('displays feedback card when answered correctly', (tester) async {
      const state = WritingLoaded(
        quests: [sampleQuest1],
        currentIndex: 0,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.correct,
        gameType: GameSubtype.shortAnswerWriting,
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
        gameType: GameSubtype.shortAnswerWriting,
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

    testWidgets('onQuestionReset resets text controller and word count on question change', (tester) async {
      await pumpScreen(tester, level: 2);

      final textField = find.byKey(const Key('short_answer_text_field'));
      await tester.enterText(textField, 'Some initial response written here.');
      await tester.pumpAndSettle();
      expect(find.text('5 / 4 WORDS MIN'), findsOneWidget);

      const nextState = WritingLoaded(
        quests: [sampleQuest1, sampleQuest2],
        currentIndex: 1,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.unanswered,
        gameType: GameSubtype.shortAnswerWriting,
        level: 2,
      );
      when(() => mockWritingBloc.state).thenReturn(nextState);
      writingStreamController.add(nextState);
      await tester.pumpAndSettle();

      expect(find.text('0 / 4 WORDS MIN'), findsOneWidget);
      expect(find.text(sampleQuest2.prompt!), findsOneWidget);
    });
  });

  group('ShortAnswerScreen - 6. Completion, Game Over & Error Journal', () {
    testWidgets('shows completion dialog on WritingGameComplete', (tester) async {
      await pumpScreen(tester, level: 2);

      const completeState = WritingGameComplete(
        xpEarned: 60,
        coinsEarned: 30,
        questCount: 2,
        gameType: GameSubtype.shortAnswerWriting,
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
        gameType: GameSubtype.shortAnswerWriting,
        level: 2,
      );
      when(() => mockWritingBloc.state).thenReturn(gameOverState);
      writingStreamController.add(gameOverState);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('records to ErrorJournal when answering incorrectly as authenticated user', (tester) async {
      await pumpScreen(tester, level: 2);

      final textField = find.byKey(const Key('short_answer_text_field'));

      // Exhaust strikes to submit incorrect answer
      for (int i = 0; i < 3; i++) {
        await tester.enterText(textField, 'invalid lower attempt.');
        await tester.pump(const Duration(milliseconds: 600));
        await scrollAndTapSubmitButton(tester);
      }

      verify(() => mockWritingBloc.add(const SubmitAnswer(false))).called(1);
    });
  });

  group('ShortAnswerScreen - 7. Responsiveness & Accessibility', () {
    testWidgets('renders properly on small screen (320x568)', (tester) async {
      await pumpScreen(tester, level: 2, surfaceSize: const Size(320, 568));

      expect(find.byType(WritingBaseLayout), findsOneWidget);
      expect(find.byType(ShortAnswerInkwell), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders properly on tablet screen (800x1280)', (tester) async {
      await pumpScreen(tester, level: 2, surfaceSize: const Size(800, 1280));

      expect(find.byType(WritingBaseLayout), findsOneWidget);
      expect(find.byType(ShortAnswerInkwell), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders with 1.3x high text scale without overflow', (tester) async {
      await pumpScreen(tester, level: 2, textScaleFactor: 1.3);

      expect(find.byType(WritingBaseLayout), findsOneWidget);
      expect(find.byType(ShortAnswerScreen), findsOneWidget);
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
        gameType: GameSubtype.shortAnswerWriting,
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
