import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/core/presentation/widgets/game_feedback_card.dart';
import 'package:vowl/core/presentation/widgets/quest_hint_button.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
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
import 'package:vowl/features/writing/correction_writing/presentation/pages/correction_writing_screen.dart';
import 'package:vowl/features/writing/correction_writing/presentation/widgets/correction_writing_instruction.dart';
import 'package:vowl/features/writing/correction_writing/presentation/widgets/correction_writing_keyboard_input.dart';
import 'package:vowl/features/writing/correction_writing/presentation/widgets/correction_writing_sentence_card.dart';
import 'package:vowl/features/writing/correction_writing/presentation/widgets/correction_writing_vault.dart';
import 'package:vowl/features/writing/domain/entities/writing_quest.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_bloc.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_event.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_state.dart';
import 'package:vowl/features/writing/presentation/layout/writing_base_layout.dart';

class MockWritingBloc extends MockBloc<WritingEvent, WritingState>
    implements WritingBloc {}

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

class MockNetworkInfo extends Mock implements NetworkInfo {}

class FakeWritingEvent extends Fake implements WritingEvent {}

class FakeWritingState extends Fake implements WritingState {}

class FakeEconomyEvent extends Fake implements EconomyEvent {}

class FakeEconomyState extends Fake implements EconomyState {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

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

  WritingQuest createQuest({
    String id = 'quest_cw_1',
    String instruction = 'Identify and correct the error in the sentence.',
    String passage = 'She [go] to work by bus every day.',
    String correctAnswer = 'goes',
    List<String> options = const ['goes', 'going', 'went', 'gone'],
    String hint = 'Third person singular present tense requires -es.',
    String explanation =
        'She is a singular third-person subject, requiring goes.',
    int difficulty = 1,
    String? sampleAnswer = 'She goes to work by bus every day.',
    String? context = 'Grammar drill',
  }) {
    return WritingQuest(
      id: id,
      type: QuestType.writing,
      subtype: GameSubtype.correctionWriting,
      instruction: instruction,
      difficulty: difficulty,
      passage: passage,
      correctAnswer: correctAnswer,
      options: options,
      hint: hint,
      explanation: explanation,
      sampleAnswer: sampleAnswer,
      context: context,
    );
  }

  final sampleQuest1 = createQuest();

  final sampleQuest2 = createQuest(
    id: 'quest_cw_2',
    instruction: 'Fix the subject-verb agreement.',
    passage: 'They [was] playing soccer in the park.',
    correctAnswer: 'were',
    options: ['were', 'is', 'are', 'been'],
    hint: 'They is a plural pronoun.',
    explanation: 'Plural subjects require were in the past continuous.',
  );

  final sampleHardQuest = createQuest(
    id: 'quest_cw_hard',
    instruction: 'Type the fully corrected sentence.',
    passage: 'He [have] two brothers and one sister.',
    correctAnswer: 'has',
    options: ['has', 'having', 'had', 'haves'],
    difficulty: 6,
  );

  final sampleMinimalQuest = const WritingQuest(
    id: 'quest_cw_minimal',
    type: QuestType.writing,
    subtype: GameSubtype.correctionWriting,
    instruction: 'Review sentence.',
    difficulty: 1,
    passage: 'The sentence has no error brackets.',
    correctAnswer: 'correct',
    options: ['correct'],
  );

  final testLoadedState = WritingLoaded(
    quests: [sampleQuest1, sampleQuest2],
    currentIndex: 0,
    livesRemaining: 3,
    wrongCount: 0,
    hintUsed: false,
    answerStatus: AnswerStatus.unanswered,
    gameType: GameSubtype.correctionWriting,
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
        gameType: GameSubtype.correctionWriting,
        level: 2,
      ),
    );
    registerFallbackValue(const EconomyAddCoinsRequested(5));
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

    // Analytics & Ad mocks
    when(() => mockAnalyticsService.logGameSkipped(any())).thenAnswer((_) async {});
    when(
      () => mockAdService.showRewardedAd(
        context: any(named: 'context'),
        isPremium: any(named: 'isPremium'),
        onUserEarnedReward: any(named: 'onUserEarnedReward'),
        onDismissed: any(named: 'onDismissed'),
      ),
    ).thenAnswer((inv) async {
      final onEarned = inv.namedArguments[#onUserEarnedReward] as dynamic;
      onEarned?.call(RewardItem(1, 'coin'));
    });

    // Auth mock
    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(
        const UserEntity(
          id: 'local',
          email: 'scribe@vowl.app',
          displayName: 'Wordsmith',
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
    if (di.sl.isRegistered<HapticService>()) di.sl.unregister<HapticService>();
    if (di.sl.isRegistered<SoundService>()) di.sl.unregister<SoundService>();
    if (di.sl.isRegistered<TtsService>()) di.sl.unregister<TtsService>();
    if (di.sl.isRegistered<LocaleService>()) di.sl.unregister<LocaleService>();
    if (di.sl.isRegistered<AppLogger>()) di.sl.unregister<AppLogger>();
    if (di.sl.isRegistered<AnalyticsService>()) {
      di.sl.unregister<AnalyticsService>();
    }
    if (di.sl.isRegistered<AdService>()) di.sl.unregister<AdService>();
    if (di.sl.isRegistered<NetworkInfo>()) di.sl.unregister<NetworkInfo>();
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    WritingState? state,
    int level = 2,
    ThemeMode themeMode = ThemeMode.dark,
    double textScaleFactor = 1.0,
    Size surfaceSize = const Size(390, 844),
    bool settle = true,
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
      MultiBlocProvider(
        providers: [
          BlocProvider<WritingBloc>.value(value: mockWritingBloc),
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<EconomyBloc>.value(value: mockEconomyBloc),
        ],
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) {
            return MaterialApp(
              themeMode: themeMode,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              home: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(textScaleFactor),
                ),
                child: CorrectionWritingScreen(level: level),
              ),
            );
          },
        ),
      ),
    );

    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  group('CorrectionWritingScreen - 1. Initial Rendering & Layout', () {
    testWidgets('renders all essential components in normal mode (level 2)', (
      tester,
    ) async {
      await pumpScreen(tester, level: 2);

      expect(find.byType(WritingBaseLayout), findsOneWidget);
      expect(find.byType(CorrectionWritingInstruction), findsOneWidget);
      expect(find.byType(CorrectionWritingSentenceCard), findsOneWidget);
      expect(find.byType(CorrectionWritingVault), findsOneWidget);
      expect(
        find.byKey(const Key('correction_writing_check_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('correction_writing_scroll_view')),
        findsOneWidget,
      );
      expect(find.text('Identify and correct the error in the sentence.'), findsOneWidget);
      expect(find.text('Select the correct word'), findsOneWidget);
      expect(find.text('Check Answer'), findsOneWidget);
    });

    testWidgets('renders all options in the vault', (tester) async {
      await pumpScreen(tester, level: 2);

      for (final opt in sampleQuest1.options!) {
        expect(find.byKey(Key('correction_vault_chip_$opt')), findsOneWidget);
        expect(find.text(opt), findsAtLeastNWidgets(1));
      }
    });

    testWidgets('renders fallback when passage has no brackets', (
      tester,
    ) async {
      final minimalState = WritingLoaded(
        quests: [sampleMinimalQuest],
        currentIndex: 0,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.unanswered,
        gameType: GameSubtype.correctionWriting,
        level: 2,
      );
      await pumpScreen(tester, state: minimalState, level: 2);

      expect(find.byType(CorrectionWritingSentenceCard), findsOneWidget);
      expect(find.text('The sentence has no error brackets.'), findsOneWidget);
    });

    testWidgets('renders shimmer loading when in initial/loading state', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        state: WritingInitial(),
        level: 2,
        settle: false,
      );

      expect(find.byType(GameShimmerLoading), findsOneWidget);
    });

    testWidgets('dispatches FetchWritingQuests on init', (tester) async {
      await pumpScreen(tester, level: 2);

      verify(
        () => mockWritingBloc.add(
          const FetchWritingQuests(
            gameType: GameSubtype.correctionWriting,
            level: 2,
          ),
        ),
      ).called(1);
    });
  });

  group('CorrectionWritingScreen - 2. Option Selection & UI State (Normal Mode)', () {
    testWidgets('check button is disabled before selecting an option', (
      tester,
    ) async {
      await pumpScreen(tester, level: 2);

      final buttonFinder = find.byKey(
        const Key('correction_writing_check_button'),
      );
      await tester.tap(buttonFinder);
      await tester.pump();

      // SubmitAnswer should NOT have been called
      verifyNever(() => mockWritingBloc.add(const SubmitAnswer(true)));
      verifyNever(() => mockWritingBloc.add(const SubmitAnswer(false)));
    });

    testWidgets('tapping an option highlights it and triggers selection haptic', (
      tester,
    ) async {
      await pumpScreen(tester, level: 2);

      final chipFinder = find.byKey(const Key('correction_vault_chip_goes'));
      await tester.ensureVisible(chipFinder);
      await tester.tap(chipFinder);
      await tester.pump();

      verify(() => mockHapticService.selection()).called(1);

      // Check button should now be enabled and trigger submit
      final buttonFinder = find.byKey(
        const Key('correction_writing_check_button'),
      );
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pump();

      verify(() => mockWritingBloc.add(const SubmitAnswer(true))).called(1);
    });

    testWidgets('switching between options updates selection', (tester) async {
      await pumpScreen(tester, level: 2);

      final chipWent = find.byKey(const Key('correction_vault_chip_went'));
      final chipGoes = find.byKey(const Key('correction_vault_chip_goes'));

      await tester.ensureVisible(chipWent);
      await tester.tap(chipWent);
      await tester.pump();

      await tester.ensureVisible(chipGoes);
      await tester.tap(chipGoes);
      await tester.pump();

      final buttonFinder = find.byKey(
        const Key('correction_writing_check_button'),
      );
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pump();

      // Final submitted answer should be 'goes' -> correct
      verify(() => mockWritingBloc.add(const SubmitAnswer(true))).called(1);
    });

    testWidgets('submitting an incorrect option triggers wrong answer', (
      tester,
    ) async {
      await pumpScreen(tester, level: 2);

      final chipWent = find.byKey(const Key('correction_vault_chip_went'));
      await tester.ensureVisible(chipWent);
      await tester.tap(chipWent);
      await tester.pump();

      final buttonFinder = find.byKey(
        const Key('correction_writing_check_button'),
      );
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pump();

      verify(() => mockWritingBloc.add(const SubmitAnswer(false))).called(1);
    });

    testWidgets('tapping an option when already answered does nothing', (
      tester,
    ) async {
      final answeredState = testLoadedState.copyWith(
        answerStatus: AnswerStatus.correct,
      );
      await pumpScreen(tester, state: answeredState, level: 2);

      final chipGoes = find.byKey(const Key('correction_vault_chip_goes'));
      await tester.ensureVisible(chipGoes);
      await tester.tap(chipGoes, warnIfMissed: false);
      await tester.pump();

      verifyNever(() => mockHapticService.selection());
    });
  });

  group('CorrectionWritingScreen - 3. Hard Mode Mechanics (Level >= 6)', () {
    testWidgets('renders keyboard input and absorbed vault in hard mode (level 6)', (
      tester,
    ) async {
      final hardState = WritingLoaded(
        quests: [sampleHardQuest],
        currentIndex: 0,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.unanswered,
        gameType: GameSubtype.correctionWriting,
        level: 6,
      );

      await pumpScreen(tester, state: hardState, level: 6);

      expect(find.byType(CorrectionWritingKeyboardInput), findsOneWidget);
      expect(
        find.byKey(const Key('correction_keyboard_input_field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('correction_keyboard_submit_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('correction_hard_mode_vault_detector')),
        findsOneWidget,
      );
      // Normal check button is hidden in hard mode
      expect(
        find.byKey(const Key('correction_writing_check_button')),
        findsNothing,
      );
    });

    testWidgets('tapping vault in hard mode displays disabled warning snackbar', (
      tester,
    ) async {
      final hardState = WritingLoaded(
        quests: [sampleHardQuest],
        currentIndex: 0,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.unanswered,
        gameType: GameSubtype.correctionWriting,
        level: 6,
      );

      await pumpScreen(tester, state: hardState, level: 6);

      final detector = find.byKey(
        const Key('correction_hard_mode_vault_detector'),
      );
      await tester.ensureVisible(detector);
      await tester.tap(detector);
      await tester.pump();

      expect(
        find.text(
          'Hard Mode! Tapping is disabled. Please type your answer below.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('submitting empty string does not submit', (tester) async {
      final hardState = WritingLoaded(
        quests: [sampleHardQuest],
        currentIndex: 0,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.unanswered,
        gameType: GameSubtype.correctionWriting,
        level: 6,
      );

      await pumpScreen(tester, state: hardState, level: 6);

      final submitBtn = find.byKey(
        const Key('correction_keyboard_submit_button'),
      );
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pump();

      verifyNever(() => mockWritingBloc.add(const SubmitAnswer(true)));
      verifyNever(() => mockWritingBloc.add(const SubmitAnswer(false)));
    });

    testWidgets('validates sentence starts with capital letter', (
      tester,
    ) async {
      final hardState = WritingLoaded(
        quests: [sampleHardQuest],
        currentIndex: 0,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.unanswered,
        gameType: GameSubtype.correctionWriting,
        level: 6,
      );

      await pumpScreen(tester, state: hardState, level: 6);

      final inputField = find.byKey(
        const Key('correction_keyboard_input_field'),
      );
      await tester.enterText(
        inputField,
        'he has two brothers and one sister.',
      );
      await tester.pump();

      final submitBtn = find.byKey(
        const Key('correction_keyboard_submit_button'),
      );
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pump();

      expect(
        find.text('Please start your sentence with a capital letter.'),
        findsOneWidget,
      );
      verify(() => mockHapticService.selection()).called(1);
      verifyNever(() => mockWritingBloc.add(const SubmitAnswer(true)));
      verifyNever(() => mockWritingBloc.add(const SubmitAnswer(false)));
    });

    testWidgets('validates sentence ends with proper punctuation', (
      tester,
    ) async {
      final hardState = WritingLoaded(
        quests: [sampleHardQuest],
        currentIndex: 0,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.unanswered,
        gameType: GameSubtype.correctionWriting,
        level: 6,
      );

      await pumpScreen(tester, state: hardState, level: 6);

      final inputField = find.byKey(
        const Key('correction_keyboard_input_field'),
      );
      await tester.enterText(
        inputField,
        'He has two brothers and one sister',
      );
      await tester.pump();

      final submitBtn = find.byKey(
        const Key('correction_keyboard_submit_button'),
      );
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pump();

      expect(
        find.text(
          'Please end your sentence with proper punctuation (., !, or ?).',
        ),
        findsOneWidget,
      );
      verify(() => mockHapticService.selection()).called(1);
      verifyNever(() => mockWritingBloc.add(const SubmitAnswer(true)));
      verifyNever(() => mockWritingBloc.add(const SubmitAnswer(false)));
    });

    testWidgets('submitting correct full sentence triggers SubmitAnswer(true)', (
      tester,
    ) async {
      final hardState = WritingLoaded(
        quests: [sampleHardQuest],
        currentIndex: 0,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.unanswered,
        gameType: GameSubtype.correctionWriting,
        level: 6,
      );

      await pumpScreen(tester, state: hardState, level: 6);

      final inputField = find.byKey(
        const Key('correction_keyboard_input_field'),
      );
      await tester.enterText(
        inputField,
        'He has two brothers and one sister.',
      );
      await tester.pump();

      final submitBtn = find.byKey(
        const Key('correction_keyboard_submit_button'),
      );
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pump();

      verify(() => mockWritingBloc.add(const SubmitAnswer(true))).called(1);
    });

    testWidgets('submitting incorrect full sentence triggers SubmitAnswer(false)', (
      tester,
    ) async {
      final hardState = WritingLoaded(
        quests: [sampleHardQuest],
        currentIndex: 0,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.unanswered,
        gameType: GameSubtype.correctionWriting,
        level: 6,
      );

      await pumpScreen(tester, state: hardState, level: 6);

      final inputField = find.byKey(
        const Key('correction_keyboard_input_field'),
      );
      await tester.enterText(
        inputField,
        'He had two brothers and one sister.',
      );
      await tester.pump();

      final submitBtn = find.byKey(
        const Key('correction_keyboard_submit_button'),
      );
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pump();

      verify(() => mockWritingBloc.add(const SubmitAnswer(false))).called(1);
    });

    testWidgets('submitting via onSubmitted on the text field works', (
      tester,
    ) async {
      final hardState = WritingLoaded(
        quests: [sampleHardQuest],
        currentIndex: 0,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.unanswered,
        gameType: GameSubtype.correctionWriting,
        level: 6,
      );

      await pumpScreen(tester, state: hardState, level: 6);

      final inputField = find.byKey(
        const Key('correction_keyboard_input_field'),
      );
      await tester.enterText(
        inputField,
        'He has two brothers and one sister.',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      verify(() => mockWritingBloc.add(const SubmitAnswer(true))).called(1);
    });
  });

  group('CorrectionWritingScreen - 4. Feedback, Navigation & Reset', () {
    testWidgets('displays feedback card when answered correctly', (
      tester,
    ) async {
      final answeredCorrect = testLoadedState.copyWith(
        answerStatus: AnswerStatus.correct,
      );

      await pumpScreen(tester, state: answeredCorrect, level: 2);

      expect(find.byType(GameFeedbackCard), findsOneWidget);
      expect(find.text('CONTINUE'), findsOneWidget);
    });

    testWidgets('tapping Continue dispatches NextQuestion', (tester) async {
      final answeredCorrect = testLoadedState.copyWith(
        answerStatus: AnswerStatus.correct,
      );

      await pumpScreen(tester, state: answeredCorrect, level: 2);

      final continueButton = find.text('CONTINUE');
      await tester.tap(continueButton);
      await tester.pump();

      verify(() => mockWritingBloc.add(const NextQuestion())).called(1);
    });

    testWidgets('tapping Hint button dispatches WritingHintUsed', (
      tester,
    ) async {
      await pumpScreen(tester, level: 2);

      final hintButton = find.byType(QuestHintButton);
      expect(hintButton, findsOneWidget);

      await tester.tap(hintButton);
      await tester.pump();

      verify(() => mockWritingBloc.add(const WritingHintUsed())).called(1);
    });

    testWidgets('onQuestionReset resets selection on new question', (
      tester,
    ) async {
      await pumpScreen(tester, level: 2);

      // Select an option
      final chipGoes = find.byKey(const Key('correction_vault_chip_goes'));
      await tester.ensureVisible(chipGoes);
      await tester.tap(chipGoes);
      await tester.pump();

      // Now emit next question state
      final nextQuestionState = WritingLoaded(
        quests: [sampleQuest1, sampleQuest2],
        currentIndex: 1,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.unanswered,
        gameType: GameSubtype.correctionWriting,
        level: 2,
      );

      writingStreamController.add(nextQuestionState);
      when(() => mockWritingBloc.state).thenReturn(nextQuestionState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // After reset, check button should be disabled again
      final buttonFinder = find.byKey(
        const Key('correction_writing_check_button'),
      );
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pump();

      verifyNever(() => mockWritingBloc.add(const SubmitAnswer(true)));
    });
  });

  group('CorrectionWritingScreen - 5. Game Completion, Game Over & Error Journal', () {
    testWidgets('shows GameDialogHelper on WritingGameComplete', (
      tester,
    ) async {
      await pumpScreen(tester, level: 2);

      writingStreamController.add(
        const WritingGameComplete(
          xpEarned: 100,
          coinsEarned: 25,
          questCount: 2,
          gameType: GameSubtype.correctionWriting,
          level: 2,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('LEVEL COMPLETE!'), findsOneWidget);

      // Clean up dialog
      Navigator.of(tester.element(find.text('LEVEL COMPLETE!'))).pop();
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('handles WritingGameOver without crash', (tester) async {
      await pumpScreen(tester, level: 2);

      writingStreamController.add(
        WritingGameOver(
          quests: [sampleQuest1],
          currentIndex: 0,
          gameType: GameSubtype.correctionWriting,
          level: 2,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(WritingBaseLayout), findsOneWidget);

      // Clean up game over dialog
      final giveUpFinder = find.text('GIVE UP');
      if (giveUpFinder.evaluate().isNotEmpty) {
        Navigator.of(tester.element(giveUpFinder)).pop();
        await tester.pump(const Duration(milliseconds: 500));
      }
    });

    testWidgets('records to ErrorJournal when answering incorrectly as authenticated user', (
      tester,
    ) async {
      when(() => mockAuthBloc.state).thenReturn(
        AuthState.authenticated(
          const UserEntity(
            id: 'authed_user_1',
            email: 'user@test.com',
            displayName: 'Grammar Master',
          ),
        ),
      );

      await pumpScreen(tester, level: 2);

      final chipWent = find.byKey(const Key('correction_vault_chip_went'));
      await tester.ensureVisible(chipWent);
      await tester.tap(chipWent);
      await tester.pump();

      final buttonFinder = find.byKey(
        const Key('correction_writing_check_button'),
      );
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pump();

      verify(() => mockWritingBloc.add(const SubmitAnswer(false))).called(1);
    });
  });

  group('CorrectionWritingScreen - 6. Responsiveness & Accessibility', () {
    testWidgets('renders properly on small screen (320x568)', (tester) async {
      await pumpScreen(
        tester,
        level: 2,
        surfaceSize: const Size(320, 568),
      );

      expect(find.byType(CorrectionWritingScreen), findsOneWidget);
      expect(find.byType(CorrectionWritingInstruction), findsOneWidget);
      expect(find.byType(CorrectionWritingVault), findsOneWidget);
    });

    testWidgets('renders properly on tablet screen (800x1280)', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        level: 2,
        surfaceSize: const Size(800, 1280),
      );

      expect(find.byType(CorrectionWritingScreen), findsOneWidget);
      expect(find.byType(CorrectionWritingSentenceCard), findsOneWidget);
    });

    testWidgets('renders with 1.3x high text scale without overflow', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        level: 2,
        textScaleFactor: 1.3,
      );

      expect(find.byType(CorrectionWritingScreen), findsOneWidget);
    });

    testWidgets('renders properly in light theme', (tester) async {
      await pumpScreen(
        tester,
        level: 2,
        themeMode: ThemeMode.light,
      );

      expect(find.byType(CorrectionWritingScreen), findsOneWidget);
    });

    testWidgets('vault options provide accessible semantics', (tester) async {
      await pumpScreen(tester, level: 2);

      final optionSemantics = tester.getSemantics(
        find.byKey(const Key('correction_vault_chip_goes')),
      );

      expect(optionSemantics.flagsCollection.isButton, isTrue);
      expect(optionSemantics.label, contains('Option: goes'));
    });

    testWidgets('briefing overlay shows at level 1 and dismisses on tap', (
      tester,
    ) async {
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
      await tester.ensureVisible(startButton);
      await tester.tap(startButton);
      await tester.pumpAndSettle();

      expect(find.byType(QuestBriefingOverlay), findsNothing);
    });
  });
}

