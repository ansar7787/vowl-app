import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/core/presentation/game_mechanics/arranging/context_sentence_builder.dart';
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
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/features/vocabulary/phrasal_verbs/presentation/pages/phrasal_verbs_screen.dart';
import 'package:vowl/features/vocabulary/phrasal_verbs/presentation/widgets/phrasal_verbs_lcd.dart';
import 'package:vowl/features/vocabulary/phrasal_verbs/presentation/widgets/phrasal_verbs_literal_comparison.dart';
import 'package:vowl/features/vocabulary/phrasal_verbs/presentation/widgets/phrasal_verbs_option_key.dart';
import 'package:vowl/features/vocabulary/phrasal_verbs/presentation/widgets/phrasal_verbs_vault_handle.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MockVocabularyBloc
    extends MockBloc<VocabularyEvent, VocabularyState>
    implements VocabularyBloc {}

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  late MockVocabularyBloc mockVocabularyBloc;
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
  late StreamController<VocabularyState> vocabularyStreamController;

  VocabularyQuest createQuest({
    String id = 'quest_pv_1',
    String word = 'call',
    String correctAnswer = 'off',
    List<String> options = const ['off', 'out', 'up', 'on'],
    String instruction = 'Select the correct particle to unlock the vault.',
    String literalVsFigurative =
        'Literal: To shout loudly away from someone.\nFigurative: To cancel a planned event or meeting.',
    String contextSentence = 'They decided to call __ the concert due to heavy rain.',
    String explanation = 'Call off means to cancel something.',
    String hint = 'DEFINITION: To cancel an event',
    int difficulty = 1,
  }) {
    return VocabularyQuest(
      id: id,
      type: QuestType.vocabulary,
      subtype: GameSubtype.phrasalVerbs,
      word: word,
      correctAnswer: correctAnswer,
      options: options,
      instruction: instruction,
      literalVsFigurative: literalVsFigurative,
      contextSentence: contextSentence,
      explanation: explanation,
      hint: hint,
      difficulty: difficulty,
    );
  }

  final sampleQuest1 = createQuest();

  final sampleQuest2 = createQuest(
    id: 'quest_pv_2',
    word: 'give',
    correctAnswer: 'up',
    options: ['up', 'in', 'away', 'back'],
    instruction: 'Identify the phrasal verb particle.',
    literalVsFigurative:
        'Literal: To hand something in an upward motion.\nFigurative: To surrender or cease an effort.',
    contextSentence: 'Never __ on your dreams.',
    explanation: 'Give up means to surrender or stop trying.',
    hint: 'DEFINITION: To quit or surrender',
  );

  final sampleMinimalQuest = const VocabularyQuest(
    id: 'quest_pv_minimal',
    type: QuestType.vocabulary,
    subtype: GameSubtype.phrasalVerbs,
    word: 'look',
    correctAnswer: 'into',
    options: ['into', 'after'],
    instruction: 'Unlock the vault.',
    difficulty: 2,
  );

  final testLoadedState = VocabularyLoaded(
    quests: [sampleQuest1, sampleQuest2],
    currentIndex: 0,
    livesRemaining: 3,
    wrongCount: 0,
    hintUsed: false,
    answerStatus: AnswerStatus.unanswered,
  );

  setUpAll(() {
    registerFallbackValue(const SubmitAnswer(true));
    registerFallbackValue(const SubmitAnswer(false));
    registerFallbackValue(const NextQuestion());
    registerFallbackValue(const VocabularyHintUsed());
    registerFallbackValue(
      const FetchVocabularyQuests(
        gameType: GameSubtype.phrasalVerbs,
        level: 2,
      ),
    );
    registerFallbackValue(sampleQuest1);
  });

  setUp(() async {
    mockVocabularyBloc = MockVocabularyBloc();
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

    vocabularyStreamController = StreamController<VocabularyState>.broadcast();

    when(() => mockVocabularyBloc.state).thenReturn(testLoadedState);
    whenListen(
      mockVocabularyBloc,
      vocabularyStreamController.stream,
      initialState: testLoadedState,
    );

    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(
        const UserEntity(
          id: 'test_user_phrasal',
          email: 'phrasal@vowl.app',
          displayName: 'Vault Cracker',
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

    when(() => mockSoundService.playCorrect()).thenAnswer((_) async {});
    when(() => mockSoundService.playWrong()).thenAnswer((_) async {});
    when(() => mockSoundService.playTts(any())).thenAnswer((_) async {});
    when(() => mockSoundService.stopTts()).thenAnswer((_) async {});
    when(() => mockSoundService.stopAudio()).thenAnswer((_) async {});
    when(() => mockSoundService.playHint()).thenAnswer((_) async {});
    when(() => mockSoundService.playClick()).thenAnswer((_) async {});
    when(() => mockSoundService.playLevelComplete()).thenAnswer((_) async {});
    when(() => mockSoundService.playFile(any())).thenAnswer((_) async {});

    when(() => mockTtsService.stop()).thenAnswer((_) async {});
    when(
      () => mockTtsService.speak(
        any(),
        rate: any(named: 'rate'),
        locale: any(named: 'locale'),
      ),
    ).thenAnswer((_) async {});

    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

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
    await vocabularyStreamController.close();
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
    VocabularyState? state,
    int level = 2,
    GameSubtype gameType = GameSubtype.phrasalVerbs,
    Size size = const Size(390, 844),
    double textScaleFactor = 1.0,
    ThemeMode themeMode = ThemeMode.dark,
    bool reduceMotion = true,
  }) async {
    VowlMotion.lowAnimationModeOverride.value = reduceMotion;
    tester.view.physicalSize = Size(size.width * 2, size.height * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final targetState = state ?? testLoadedState;
    when(() => mockVocabularyBloc.state).thenReturn(targetState);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<VocabularyBloc>.value(value: mockVocabularyBloc),
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
              data: MediaQueryData(
                size: size,
                textScaler: TextScaler.linear(textScaleFactor),
                disableAnimations: reduceMotion,
              ),
              child: PhrasalVerbsScreen(level: level, gameType: gameType),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> advanceToPhase2(WidgetTester tester) async {
    await pumpScreen(tester);
    await tester.tap(find.text('OFF').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 600));
  }

  group('1. Initial Screen Layout & Phase 1 Presentation', () {
    testWidgets('1.1 renders PhrasalVerbsScreen and initializes quests fetch', (
      tester,
    ) async {
      await pumpScreen(tester, level: 2);
      expect(find.byType(PhrasalVerbsScreen), findsOneWidget);
      verify(
        () => mockVocabularyBloc.add(
          const FetchVocabularyQuests(
            gameType: GameSubtype.phrasalVerbs,
            level: 2,
          ),
        ),
      ).called(1);
    });

    testWidgets('1.2 renders vault security badge and instruction banner', (
      tester,
    ) async {
      await pumpScreen(tester);
      expect(find.text('VAULT SECURITY: L-2'), findsOneWidget);
      expect(find.byIcon(Icons.vpn_key_rounded), findsOneWidget);
      expect(
        find.textContaining('Select the correct particle'),
        findsOneWidget,
      );
    });

    testWidgets('1.3 renders PhrasalVerbsLcd terminal with decrypted definition', (
      tester,
    ) async {
      await pumpScreen(tester);
      expect(find.byType(PhrasalVerbsLcd), findsOneWidget);
      expect(find.text('DECRYPTING TARGET'), findsOneWidget);
      expect(find.text('TO CANCEL AN EVENT'), findsOneWidget);
    });

    testWidgets('1.4 renders central PhrasalVerbsVaultHandle with target verb', (
      tester,
    ) async {
      await pumpScreen(tester);
      expect(find.byType(PhrasalVerbsVaultHandle), findsOneWidget);
      expect(find.text('CALL'), findsOneWidget);
    });

    testWidgets('1.5 renders all particle option keys with uppercase text', (
      tester,
    ) async {
      await pumpScreen(tester);
      expect(find.byType(PhrasalVerbsOptionKey), findsNWidgets(4));
      expect(find.text('OFF'), findsOneWidget);
      expect(find.text('OUT'), findsOneWidget);
      expect(find.text('UP'), findsOneWidget);
      expect(find.text('ON'), findsOneWidget);
    });

    testWidgets('1.6 Phase 2 elements are not visible before Phase 1 passes', (
      tester,
    ) async {
      await pumpScreen(tester);
      expect(find.byType(PhrasalVerbsLiteralComparison), findsNothing);
      expect(find.byType(ContextSentenceBuilder), findsNothing);
    });

    testWidgets('1.7 handles minimal quest with 2 options gracefully', (
      tester,
    ) async {
      final minimalState = testLoadedState.copyWith(
        quests: [sampleMinimalQuest],
        currentIndex: 0,
      );
      await pumpScreen(tester, state: minimalState);
      expect(find.text('LOOK'), findsOneWidget);
      expect(find.byType(PhrasalVerbsOptionKey), findsNWidgets(2));
      expect(find.text('INTO'), findsOneWidget);
      expect(find.text('AFTER'), findsOneWidget);
    });
  });

  group('2. Phase 1 Option Selection & Visual Feedback', () {
    testWidgets('2.1 selecting incorrect option submits wrong answer with error feedback', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.tap(find.text('OUT'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockHapticService.error()).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(
        () => mockVocabularyBloc.add(
          any(that: isA<SubmitAnswer>().having((e) => e.isCorrect, 'isCorrect', false)),
        ),
      ).called(1);
    });

    testWidgets('2.2 selecting correct option triggers selection haptics and advances to Phase 2', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.tap(find.text('OFF'));
      await tester.pump();

      verify(() => mockHapticService.selection()).called(1);

      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(PhrasalVerbsLiteralComparison), findsOneWidget);
      expect(find.byType(ContextSentenceBuilder), findsOneWidget);
    });

    testWidgets('2.3 tapping options while answered or in transition is locked out', (
      tester,
    ) async {
      await pumpScreen(tester);

      // Select correct option
      await tester.tap(find.text('OFF'));
      await tester.pump();

      clearInteractions(mockHapticService);

      // Immediately tap another option
      await tester.tap(find.text('UP'), warnIfMissed: false);
      await tester.pump();

      verifyNever(() => mockHapticService.selection());
      verifyNever(() => mockHapticService.error());

      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pump(const Duration(milliseconds: 600));
    });
  });

  group('3. Phase 2 Literal vs Figurative & Sentence Construction', () {
    testWidgets('3.1 displays literal vs figurative comparison cards', (
      tester,
    ) async {
      await advanceToPhase2(tester);

      expect(find.byType(PhrasalVerbsLiteralComparison), findsOneWidget);
      expect(find.text('LITERAL VS FIGURATIVE'), findsOneWidget);
      expect(find.text('LITERAL'), findsOneWidget);
      expect(find.text('FIGURATIVE'), findsOneWidget);
      expect(
        find.text('To shout loudly away from someone.'),
        findsOneWidget,
      );
      expect(
        find.text('To cancel a planned event or meeting.'),
        findsOneWidget,
      );
    });

    testWidgets('3.2 renders ContextSentenceBuilder with formatted target keyword and example sentence', (
      tester,
    ) async {
      await advanceToPhase2(tester);

      expect(find.byType(ContextSentenceBuilder), findsOneWidget);
      final builder = tester.widget<ContextSentenceBuilder>(
        find.byType(ContextSentenceBuilder),
      );
      expect(builder.targetKeyword, 'call off');
      expect(
        builder.exampleSentence,
        'They decided to call off the concert due to heavy rain.',
      );
    });

    testWidgets('3.3 confirming in ContextSentenceBuilder dispatches SubmitAnswer(true)', (
      tester,
    ) async {
      await advanceToPhase2(tester);

      final builder = tester.widget<ContextSentenceBuilder>(
        find.byType(ContextSentenceBuilder),
      );
      builder.onConfirmed();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      verify(() => mockHapticService.success()).called(1);
      verify(() => mockSoundService.playCorrect()).called(1);
      verify(() => mockVocabularyBloc.add(const SubmitAnswer(true))).called(1);
    });

    testWidgets('3.4 skipping in ContextSentenceBuilder dispatches SubmitAnswer(false)', (
      tester,
    ) async {
      await advanceToPhase2(tester);

      final builder = tester.widget<ContextSentenceBuilder>(
        find.byType(ContextSentenceBuilder),
      );
      builder.onSkipped();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      verify(
        () => mockVocabularyBloc.add(
          any(that: isA<SubmitAnswer>().having((e) => e.isCorrect, 'isCorrect', false)),
        ),
      ).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockHapticService.error()).called(1);
    });
  });

  group('4. Hint System & Audio Lifecycle', () {
    testWidgets('4.1 tapping header hint button dispatches VocabularyHintUsed', (
      tester,
    ) async {
      await pumpScreen(tester);

      final hintButton = find.byType(QuestHintButton);
      expect(hintButton, findsOneWidget);

      await tester.tap(hintButton);
      await tester.pump();

      verify(() => mockVocabularyBloc.add(const VocabularyHintUsed())).called(greaterThanOrEqualTo(1));
    });

    testWidgets('4.2 when hint is used, correct option key receives isHintUsed styling', (
      tester,
    ) async {
      final hintState = testLoadedState.copyWith(hintUsed: true);
      await pumpScreen(tester, state: hintState);

      final optionKeys = tester.widgetList<PhrasalVerbsOptionKey>(
        find.byType(PhrasalVerbsOptionKey),
      );
      final correctKey = optionKeys.firstWhere((k) => k.text == 'off');
      expect(correctKey.isHintUsed, isTrue);
    });
  });

  group('5. State Progression, Dialogs & Error Handling', () {
    testWidgets('5.1 displays GameShimmerLoading when state is uninitialized', (
      tester,
    ) async {
      const emptyState = VocabularyInitial();
      await pumpScreen(tester, state: emptyState);

      expect(find.byType(GameShimmerLoading), findsOneWidget);
    });

    testWidgets('5.2 renders GameFeedbackCard on correct answer and CONTINUE dispatches NextQuestion', (
      tester,
    ) async {
      await advanceToPhase2(tester);

      final builder = tester.widget<ContextSentenceBuilder>(
        find.byType(ContextSentenceBuilder),
      );
      builder.onConfirmed();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Emit answered state
      final answeredState = testLoadedState.copyWith(
        answerStatus: AnswerStatus.correct,
      );
      vocabularyStreamController.add(answeredState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(GameFeedbackCard), findsOneWidget);
      final continueBtn = find.text('CONTINUE');
      expect(continueBtn, findsOneWidget);

      await tester.tap(continueBtn);
      await tester.pump();

      verify(() => mockVocabularyBloc.add(const NextQuestion())).called(1);
    });

    testWidgets('5.3 renders GameFeedbackCard on wrong answer with TRY AGAIN', (
      tester,
    ) async {
      await pumpScreen(tester);

      // Select wrong option in phase 1
      await tester.tap(find.text('OUT'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Emit wrong answered state (non-final failure)
      final wrongState = testLoadedState.copyWith(
        answerStatus: AnswerStatus.incorrect,
        wrongCount: 1,
      );
      vocabularyStreamController.add(wrongState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(GameFeedbackCard), findsOneWidget);
      final tryAgainBtn = find.text('TRY AGAIN');
      expect(tryAgainBtn, findsOneWidget);

      // Tap TRY AGAIN to reset
      await tester.tap(tryAgainBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));

      // Phase 1 is active again
      expect(find.byType(PhrasalVerbsOptionKey), findsNWidgets(4));
    });

    testWidgets('5.4 advancing to next question resets Phase 1 & 2 state cleanly', (
      tester,
    ) async {
      await advanceToPhase2(tester);

      // Advance to quest 2
      final nextQuestState = testLoadedState.copyWith(
        currentIndex: 1,
        answerStatus: AnswerStatus.unanswered,
      );
      vocabularyStreamController.add(nextQuestState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('GIVE'), findsOneWidget);
      expect(find.text('UP'), findsOneWidget);
      expect(find.byType(PhrasalVerbsLiteralComparison), findsNothing);
      expect(find.byType(ContextSentenceBuilder), findsNothing);
    });

    testWidgets('5.5 VocabularyGameComplete state displays LEVEL COMPLETE dialog and disposes cleanly', (
      tester,
    ) async {
      await pumpScreen(tester);

      const completeState = VocabularyGameComplete(
        xpEarned: 50,
        coinsEarned: 10,
        questCount: 2,
      );
      vocabularyStreamController.add(completeState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('LEVEL COMPLETE!'), findsOneWidget);
    });
  });

  group('6. Viewport Responsiveness, Theming & Accessibility', () {
    testWidgets('6.1 renders on compact mobile screen (320x568) without overflow', (
      tester,
    ) async {
      await pumpScreen(tester, size: const Size(320, 568));
      expect(tester.takeException(), isNull);
      expect(find.byType(PhrasalVerbsScreen), findsOneWidget);
      expect(find.text('CALL'), findsOneWidget);
    });

    testWidgets('6.2 renders on tablet screen (768x1024) with responsive layout', (
      tester,
    ) async {
      await pumpScreen(tester, size: const Size(768, 1024));
      expect(tester.takeException(), isNull);
      expect(find.byType(PhrasalVerbsScreen), findsOneWidget);
      expect(find.text('CALL'), findsOneWidget);
    });

    testWidgets('6.3 renders in landscape orientation (800x480) without overflow', (
      tester,
    ) async {
      await pumpScreen(tester, size: const Size(800, 480));
      expect(tester.takeException(), isNull);
      expect(find.byType(PhrasalVerbsScreen), findsOneWidget);
      expect(find.text('CALL'), findsOneWidget);
    });

    testWidgets('6.4 adapts to high text scale (1.5x) gracefully', (
      tester,
    ) async {
      await pumpScreen(tester, textScaleFactor: 1.5);
      expect(tester.takeException(), isNull);
      expect(find.byType(PhrasalVerbsScreen), findsOneWidget);
      expect(find.text('CALL'), findsOneWidget);
    });

    testWidgets('6.5 renders cleanly in light theme mode', (
      tester,
    ) async {
      await pumpScreen(tester, themeMode: ThemeMode.light);
      expect(tester.takeException(), isNull);
      expect(find.byType(PhrasalVerbsScreen), findsOneWidget);
      expect(find.text('CALL'), findsOneWidget);
    });

    testWidgets('6.6 handles minimal quest data gracefully without crash', (
      tester,
    ) async {
      const minimalQuest = VocabularyQuest(
        id: 'quest_min',
        type: QuestType.vocabulary,
        subtype: GameSubtype.phrasalVerbs,
        instruction: 'Unlock the vault.',
        difficulty: 1,
      );
      final minimalState = testLoadedState.copyWith(
        quests: [minimalQuest],
        currentIndex: 0,
      );
      await pumpScreen(tester, state: minimalState);
      expect(tester.takeException(), isNull);
      expect(find.byType(PhrasalVerbsScreen), findsOneWidget);
    });
  });
}
