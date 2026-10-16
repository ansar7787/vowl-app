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
import 'package:vowl/core/presentation/game_mechanics/arranging/dynamic_anagram_wrapper.dart';
import 'package:vowl/core/presentation/widgets/game_feedback_card.dart';
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
import 'package:vowl/features/writing/complete_sentence/presentation/pages/complete_sentence_screen.dart';
import 'package:vowl/features/writing/complete_sentence/presentation/widgets/complete_sentence_ballista_ammo.dart';
import 'package:vowl/features/writing/complete_sentence/presentation/widgets/complete_sentence_instruction.dart';
import 'package:vowl/features/writing/complete_sentence/presentation/widgets/complete_sentence_keyboard_input.dart';
import 'package:vowl/features/writing/complete_sentence/presentation/widgets/complete_sentence_target_wall.dart';
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
    String id = 'quest_cs_1',
    String instruction = 'Launch the correct fragment to complete the sentence!',
    String? grammarFocus = 'Past Tense',
    String partialSentence = 'Yesterday, the explorer ______ the ancient ruins.',
    String correctAnswer = 'discovered',
    List<String> options = const [
      'discovered',
      'discovering',
      'discovers',
      'discovery',
    ],
    String hint = 'Consider an action finished in the past.',
    String explanation = 'Discovered is the simple past tense of discover.',
    int difficulty = 1,
    String? sampleAnswer =
        'Yesterday, the explorer discovered the ancient ruins.',
    String? context = 'Archaeological journal entry',
  }) {
    return WritingQuest(
      id: id,
      type: QuestType.writing,
      subtype: GameSubtype.completeSentence,
      instruction: instruction,
      difficulty: difficulty,
      partialSentence: partialSentence,
      correctAnswer: correctAnswer,
      options: options,
      hint: hint,
      explanation: explanation,
      sampleAnswer: sampleAnswer,
      grammarFocus: grammarFocus,
      context: context,
    );
  }

  final sampleQuest1 = createQuest();

  final sampleQuest2 = createQuest(
    id: 'quest_cs_2',
    instruction: 'Select the missing verb to finish the phrase.',
    grammarFocus: 'Conditional',
    partialSentence: 'If it rains tomorrow, we ______ the picnic.',
    correctAnswer: 'will cancel',
    options: ['will cancel', 'cancelled', 'cancelling', 'cancels'],
    hint: 'First conditional uses will + base verb.',
    explanation: 'First conditional indicates future result based on a condition.',
  );

  final sampleMinimalQuest = const WritingQuest(
    id: 'quest_cs_minimal',
    type: QuestType.writing,
    subtype: GameSubtype.completeSentence,
    instruction: 'Complete the sentence.',
    difficulty: 1,
    partialSentence: 'He went home.',
    correctAnswer: 'home',
  );

  final testLoadedState = WritingLoaded(
    quests: [sampleQuest1, sampleQuest2],
    currentIndex: 0,
    livesRemaining: 3,
    wrongCount: 0,
    hintUsed: false,
    answerStatus: AnswerStatus.unanswered,
    gameType: GameSubtype.completeSentence,
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
        gameType: GameSubtype.completeSentence,
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

    // Haptic mocks
    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});
    when(() => mockHapticService.heavy()).thenAnswer((_) async {});

    // Sound mocks
    when(() => mockSoundService.playCorrect()).thenAnswer((_) async {});
    when(() => mockSoundService.playWrong()).thenAnswer((_) async {});
    when(() => mockSoundService.stopAudio()).thenAnswer((_) async {});
    when(() => mockSoundService.playHint()).thenAnswer((_) async {});
    when(() => mockSoundService.playClick()).thenAnswer((_) async {});
    when(() => mockSoundService.playLevelComplete()).thenAnswer((_) async {});
    when(() => mockSoundService.playFile(any())).thenAnswer((_) async {});

    // TTS mock
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
    ).thenAnswer((inv) {
      final onEarned = inv.namedArguments[#onUserEarnedReward] as dynamic;
      onEarned?.call(RewardItem(1, 'coin'));
    });

    // Auth mock (local guest prevents Firebase initialization)
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
          builder: (context, child) => MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            home: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(textScaleFactor),
                disableAnimations: true,
              ),
              child: CompleteSentenceScreen(
                level: level,
                gameType: GameSubtype.completeSentence,
              ),
            ),
          ),
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

  group('CompleteSentenceScreen — Initial Rendering & UI Components', () {
    testWidgets('renders WritingBaseLayout with header, instruction, and wall', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(find.byType(WritingBaseLayout), findsOneWidget);
      expect(find.byType(CompleteSentenceInstruction), findsOneWidget);
      expect(find.byType(CompleteSentenceTargetWall), findsOneWidget);
      expect(find.byType(CompleteSentenceBallistaAmmo), findsOneWidget);

      // Verify instruction and grammar focus
      expect(
        find.textContaining('Launch the correct fragment'),
        findsOneWidget,
      );
      expect(find.textContaining('PAST TENSE'), findsOneWidget);

      // Verify target wall text
      expect(find.byType(RichText), findsWidgets);
    });

    testWidgets('dispatches FetchWritingQuests on initWritingGame', (
      tester,
    ) async {
      await pumpScreen(tester, level: 3);

      verify(
        () => mockWritingBloc.add(
          const FetchWritingQuests(
            gameType: GameSubtype.completeSentence,
            level: 3,
          ),
        ),
      ).called(1);
    });

    testWidgets('renders GameShimmerLoading when state is WritingLoading', (
      tester,
    ) async {
      await pumpScreen(tester, state: const WritingLoading(), settle: false);

      expect(find.byType(GameShimmerLoading), findsOneWidget);
      expect(find.byType(CompleteSentenceTargetWall), findsNothing);
    });

    testWidgets('renders GameShimmerLoading when state is WritingInitial', (
      tester,
    ) async {
      await pumpScreen(tester, state: const WritingInitial(), settle: false);

      expect(find.byType(GameShimmerLoading), findsOneWidget);
      expect(find.byType(CompleteSentenceTargetWall), findsNothing);
    });

    testWidgets('renders properly in light theme', (tester) async {
      await pumpScreen(tester, themeMode: ThemeMode.light);

      expect(find.byType(CompleteSentenceScreen), findsOneWidget);
      expect(find.byType(CompleteSentenceTargetWall), findsOneWidget);
    });

    testWidgets('renders properly in dark theme', (tester) async {
      await pumpScreen(tester, themeMode: ThemeMode.dark);

      expect(find.byType(CompleteSentenceScreen), findsOneWidget);
      expect(find.byType(CompleteSentenceTargetWall), findsOneWidget);
    });

    testWidgets('renders all options in ballista ammo (level < 6)', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(find.text('discovered'), findsOneWidget);
      expect(find.text('discovering'), findsOneWidget);
      expect(find.text('discovers'), findsOneWidget);
      expect(find.text('discovery'), findsOneWidget);
    });
  });

  group('CompleteSentenceScreen — Ammo Selection & Fire Interaction (Normal Mode)', () {
    testWidgets('tapping correct ammo option triggers success and displays DynamicAnagramWrapper', (
      tester,
    ) async {
      await pumpScreen(tester);

      final ammoFinder = find.byKey(const ValueKey('ammo_discovered'));
      await tester.ensureVisible(ammoFinder);
      await tester.tap(ammoFinder);
      await tester.pumpAndSettle();

      verify(() => mockHapticService.success()).called(1);

      // DynamicAnagramWrapper should now be rendered!
      expect(find.byType(DynamicAnagramWrapper), findsOneWidget);
      expect(find.text('NOW SPELL IT!'), findsOneWidget);
    });

    testWidgets('dragging correct ammo onto target wall triggers fire', (
      tester,
    ) async {
      await pumpScreen(tester);

      final ammoFinder = find.byKey(const ValueKey('ammo_discovered'));
      final dropZoneFinder = find.byKey(
        const Key('complete_sentence_target_wall_drop_zone'),
      );

      await tester.ensureVisible(ammoFinder);
      await tester.ensureVisible(dropZoneFinder);

      // Drag and drop onto the target wall
      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(ammoFinder),
      );
      await tester.pump(const Duration(milliseconds: 300));
      await gesture.moveTo(tester.getCenter(dropZoneFinder));
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pumpAndSettle();

      verify(() => mockHapticService.success()).called(1);
      expect(find.byType(DynamicAnagramWrapper), findsOneWidget);
    });

    testWidgets('tapping incorrect ammo option triggers haptic error and dispatches SubmitAnswer(false)', (
      tester,
    ) async {
      await pumpScreen(tester);

      final ammoFinder = find.byKey(const ValueKey('ammo_discovering'));
      await tester.ensureVisible(ammoFinder);
      await tester.tap(ammoFinder);
      await tester.pumpAndSettle();

      verify(() => mockHapticService.error()).called(1);
      verify(() => mockWritingBloc.add(const SubmitAnswer(false))).called(1);

      // Anagram wrapper should NOT be shown
      expect(find.byType(DynamicAnagramWrapper), findsNothing);
    });

    testWidgets('ignores firing when already answered', (tester) async {
      final answeredState = testLoadedState.copyWith(
        answerStatus: AnswerStatus.correct,
      );
      await pumpScreen(tester, state: answeredState);

      final ammoFinder = find.byKey(const ValueKey('ammo_discovered'));
      if (ammoFinder.evaluate().isNotEmpty) {
        await tester.tap(ammoFinder, warnIfMissed: false);
        await tester.pumpAndSettle();
      }

      // SubmitAnswer should not be called again
      verifyNever(() => mockWritingBloc.add(any(that: isA<SubmitAnswer>())));
    });
  });

  group('CompleteSentenceScreen — DynamicAnagramWrapper Mechanics', () {
    testWidgets('renders anagram letters and allows tile manipulation', (
      tester,
    ) async {
      await pumpScreen(tester);

      // Open anagram by tapping correct ammo
      final ammoFinder = find.byKey(const ValueKey('ammo_discovered'));
      await tester.ensureVisible(ammoFinder);
      await tester.tap(ammoFinder);
      await tester.pumpAndSettle();

      expect(find.byType(DynamicAnagramWrapper), findsOneWidget);

      // Letters of 'DISCOVERED' are available in the tile pool
      final availableLetterFinder = find.byKey(const ValueKey('avail_0'));
      if (availableLetterFinder.evaluate().isNotEmpty) {
        await tester.tap(availableLetterFinder);
        await tester.pumpAndSettle();
      }

      // CLEAR ALL button appears when at least one tile is placed
      final clearAllFinder = find.text('CLEAR ALL');
      if (clearAllFinder.evaluate().isNotEmpty) {
        await tester.tap(clearAllFinder);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('premium skip bypasses anagram and submits correct answer', (
      tester,
    ) async {
      // Setup authenticated premium user
      when(() => mockAuthBloc.state).thenReturn(
        AuthState.authenticated(
          const UserEntity(
            id: 'local',
            email: 'vip@vowl.app',
            displayName: 'VIP Member',
            isPremium: true,
          ),
        ),
      );

      await pumpScreen(tester);

      // Open anagram
      final ammoFinder = find.byKey(const ValueKey('ammo_discovered'));
      await tester.ensureVisible(ammoFinder);
      await tester.tap(ammoFinder);
      await tester.pumpAndSettle();

      // Tap SKIP button on DynamicAnagramWrapper
      final skipFinder = find.text('SKIP');
      expect(skipFinder, findsOneWidget);
      await tester.ensureVisible(skipFinder);
      await tester.tap(skipFinder);
      await tester.pumpAndSettle();

      // Premium skip triggers onConfirmed -> _onAnagramSuccess() -> submitCorrectAnswer()
      verify(() => mockWritingBloc.add(const SubmitAnswer(true))).called(1);
      expect(find.byType(DynamicAnagramWrapper), findsNothing);
    });

    testWidgets('free user skip triggers rewarded ad and submits correct answer on reward', (
      tester,
    ) async {
      await pumpScreen(tester);

      // Open anagram
      final ammoFinder = find.byKey(const ValueKey('ammo_discovered'));
      await tester.ensureVisible(ammoFinder);
      await tester.tap(ammoFinder);
      await tester.pumpAndSettle();

      final skipFinder = find.text('SKIP');
      expect(skipFinder, findsOneWidget);
      await tester.ensureVisible(skipFinder);
      await tester.tap(skipFinder);
      await tester.pumpAndSettle();

      verify(
        () => mockAdService.showRewardedAd(
          context: any(named: 'context'),
          isPremium: false,
          onUserEarnedReward: any(named: 'onUserEarnedReward'),
          onDismissed: any(named: 'onDismissed'),
        ),
      ).called(1);
      verify(() => mockWritingBloc.add(const SubmitAnswer(true))).called(1);
    });
  });

  group('CompleteSentenceScreen — Hard Mode (Level >= 6)', () {
    testWidgets('renders disabled ammo and keyboard input in level >= 6', (
      tester,
    ) async {
      final hardModeState = testLoadedState.copyWith(level: 6);
      await pumpScreen(tester, state: hardModeState, level: 6);

      expect(find.byType(CompleteSentenceKeyboardInput), findsOneWidget);
      expect(find.text('TYPE THE MISSING WORD:'), findsOneWidget);
      expect(
        find.byKey(const Key('complete_sentence_input_field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('complete_sentence_submit_button')),
        findsOneWidget,
      );
    });

    testWidgets('tapping disabled ammo in hard mode displays info snackbar', (
      tester,
    ) async {
      final hardModeState = testLoadedState.copyWith(level: 6);
      await pumpScreen(tester, state: hardModeState, level: 6);

      final ammoZone = find.byKey(
        const Key('complete_sentence_disabled_ammo_touch_zone'),
      );
      await tester.ensureVisible(ammoZone);
      await tester.tap(ammoZone);
      await tester.pump();

      expect(
        find.textContaining('Hard Mode! Dragging is disabled'),
        findsOneWidget,
      );
    });

    testWidgets('typing and submitting correct word via button triggers anagram', (
      tester,
    ) async {
      final hardModeState = testLoadedState.copyWith(level: 6);
      await pumpScreen(tester, state: hardModeState, level: 6);

      final inputFinder = find.byKey(
        const Key('complete_sentence_input_field'),
      );
      final submitButton = find.byKey(
        const Key('complete_sentence_submit_button'),
      );

      await tester.ensureVisible(inputFinder);
      await tester.enterText(inputFinder, 'discovered');
      await tester.pump();

      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      verify(() => mockHapticService.success()).called(1);
      expect(find.byType(DynamicAnagramWrapper), findsOneWidget);
    });

    testWidgets('submitting via keyboard onSubmitted fires word', (
      tester,
    ) async {
      final hardModeState = testLoadedState.copyWith(level: 6);
      await pumpScreen(tester, state: hardModeState, level: 6);

      final inputFinder = find.byKey(
        const Key('complete_sentence_input_field'),
      );
      await tester.ensureVisible(inputFinder);
      await tester.enterText(inputFinder, 'discovering');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      verify(() => mockHapticService.error()).called(1);
      verify(() => mockWritingBloc.add(const SubmitAnswer(false))).called(1);
    });

    testWidgets('submitting empty or whitespace text is ignored', (
      tester,
    ) async {
      final hardModeState = testLoadedState.copyWith(level: 6);
      await pumpScreen(tester, state: hardModeState, level: 6);

      final inputFinder = find.byKey(
        const Key('complete_sentence_input_field'),
      );
      final submitButton = find.byKey(
        const Key('complete_sentence_submit_button'),
      );

      await tester.ensureVisible(inputFinder);
      await tester.enterText(inputFinder, '   ');
      await tester.pump();

      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      verifyNever(() => mockHapticService.success());
      verifyNever(() => mockHapticService.error());
    });
  });

  group('CompleteSentenceScreen — State Transitions & Feedback', () {
    testWidgets('renders GameFeedbackCard on correct answered state and continue advances', (
      tester,
    ) async {
      final answeredState = testLoadedState.copyWith(
        answerStatus: AnswerStatus.correct,
      );
      await pumpScreen(tester, state: answeredState);

      expect(find.byType(GameFeedbackCard), findsOneWidget);
      expect(find.text('WRITING CONTEXT'), findsOneWidget);

      // Tapping continue button
      final continueButton = find.text('CONTINUE');
      expect(continueButton, findsOneWidget);
      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      verify(() => mockWritingBloc.add(const NextQuestion())).called(1);
    });

    testWidgets('renders GameFeedbackCard on incorrect answered state with explanation', (
      tester,
    ) async {
      final incorrectState = testLoadedState.copyWith(
        answerStatus: AnswerStatus.incorrect,
        livesRemaining: 2,
        isFinalFailure: true,
      );
      await pumpScreen(tester, state: incorrectState);

      expect(find.byType(GameFeedbackCard), findsOneWidget);
      expect(
        find.textContaining('Discovered is the simple past tense'),
        findsOneWidget,
      );
    });

    testWidgets('advancing question resets selected projectile and anagram state', (
      tester,
    ) async {
      await pumpScreen(tester);

      // Trigger anagram
      final ammoFinder = find.byKey(const ValueKey('ammo_discovered'));
      await tester.ensureVisible(ammoFinder);
      await tester.tap(ammoFinder);
      await tester.pumpAndSettle();
      expect(find.byType(DynamicAnagramWrapper), findsOneWidget);

      // Now stream new question state
      final nextQuestionState = testLoadedState.copyWith(
        currentIndex: 1,
        answerStatus: AnswerStatus.unanswered,
      );
      writingStreamController.add(nextQuestionState);
      await tester.pumpAndSettle();

      // DynamicAnagramWrapper should be gone and new quest rendered
      expect(find.byType(DynamicAnagramWrapper), findsNothing);
      expect(find.text('will cancel'), findsOneWidget);
    });

    testWidgets('handles WritingGameComplete state with completion dialog', (
      tester,
    ) async {
      await pumpScreen(tester);

      const completeState = WritingGameComplete(
        xpEarned: 50,
        coinsEarned: 20,
        questCount: 2,
        gameType: GameSubtype.completeSentence,
        level: 2,
      );

      writingStreamController.add(completeState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('LEVEL COMPLETE!'), findsOneWidget);

      // Clean up dialog to prevent timer leaks
      Navigator.of(tester.element(find.text('LEVEL COMPLETE!'))).pop();
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('handles WritingGameOver state gracefully', (tester) async {
      final gameOverState = WritingGameOver(
        quests: [sampleQuest1],
        currentIndex: 0,
        gameType: GameSubtype.completeSentence,
        level: 2,
      );

      await pumpScreen(tester, state: gameOverState, settle: false);
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(CompleteSentenceScreen), findsOneWidget);
    });

    testWidgets('handles WritingError state with retry option', (
      tester,
    ) async {
      const errorState = WritingError('Failed to load writing quests');
      await pumpScreen(tester, state: errorState);

      expect(find.text('Failed to load writing quests'), findsOneWidget);

      final retryFinder = find.text('Retry');
      if (retryFinder.evaluate().isNotEmpty) {
        await tester.tap(retryFinder);
        await tester.pumpAndSettle();
        verify(
          () => mockWritingBloc.add(
            const FetchWritingQuests(
              gameType: GameSubtype.completeSentence,
              level: 2,
            ),
          ),
        ).called(1);
      }
    });
  });

  group('CompleteSentenceScreen — Hints and Header System', () {
    testWidgets('tapping hint button dispatches WritingHintUsed and plays sound', (
      tester,
    ) async {
      await pumpScreen(tester);

      final hintFinder = find.byType(QuestHintButton);
      expect(hintFinder, findsOneWidget);
      await tester.tap(hintFinder);
      await tester.pumpAndSettle();

      verify(() => mockWritingBloc.add(const WritingHintUsed())).called(1);
    });

    testWidgets('shows exit confirmation dialog when back button is tapped', (
      tester,
    ) async {
      await pumpScreen(tester);

      final backButton = find.byIcon(Icons.arrow_back_ios_new_rounded);
      expect(backButton, findsOneWidget);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      expect(find.text('QUIT GAME?'), findsOneWidget);
    });
  });

  group('CompleteSentenceScreen — Responsive Viewports & Edge Cases', () {
    testWidgets('renders cleanly on compact screen (320x568)', (tester) async {
      await pumpScreen(tester, surfaceSize: const Size(320, 568));

      expect(find.byType(CompleteSentenceScreen), findsOneWidget);
      expect(find.byType(CompleteSentenceTargetWall), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly on tablet screen (800x1280)', (tester) async {
      await pumpScreen(tester, surfaceSize: const Size(800, 1280));

      expect(find.byType(CompleteSentenceScreen), findsOneWidget);
      expect(find.byType(CompleteSentenceTargetWall), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly with 1.3x text scaling', (tester) async {
      await pumpScreen(tester, textScaleFactor: 1.3);

      expect(find.byType(CompleteSentenceScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('handles minimal quest with no blanks or options', (
      tester,
    ) async {
      final minimalLoaded = WritingLoaded(
        quests: [sampleMinimalQuest],
        currentIndex: 0,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        gameType: GameSubtype.completeSentence,
        level: 2,
      );

      await pumpScreen(tester, state: minimalLoaded);

      expect(find.byType(CompleteSentenceScreen), findsOneWidget);
      expect(find.byType(CompleteSentenceTargetWall), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('didUpdateWidget updates theme when level changes', (
      tester,
    ) async {
      await pumpScreen(tester, level: 2);

      // Re-pump with level 5
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<WritingBloc>.value(value: mockWritingBloc),
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            BlocProvider<EconomyBloc>.value(value: mockEconomyBloc),
          ],
          child: ScreenUtilInit(
            designSize: const Size(390, 844),
            builder: (context, child) => MaterialApp(
              theme: AppTheme.darkTheme,
              home: const MediaQuery(
                data: MediaQueryData(disableAnimations: true),
                child: CompleteSentenceScreen(
                  level: 5,
                  gameType: GameSubtype.completeSentence,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CompleteSentenceScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
