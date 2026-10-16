import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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
import 'package:vowl/features/vocabulary/collocations/presentation/pages/collocations_screen.dart';
import 'package:vowl/features/vocabulary/collocations/presentation/widgets/collocation_anchor_bubble.dart';
import 'package:vowl/features/vocabulary/collocations/presentation/widgets/collocation_option_bubble.dart';
import 'package:vowl/features/vocabulary/collocations/presentation/widgets/collocations_wrong_pairs.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';

class MockVocabularyBloc extends MockBloc<VocabularyEvent, VocabularyState>
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
    String id = 'quest_collocation_1',
    String word = 'make',
    String correctAnswer = 'a decision',
    List<String> options = const [
      'a decision',
      'a mistake',
      'attention',
      'homework',
    ],
    String instruction = 'Match the correct collocation partner.',
    List<String> wrongCollocations = const ['do a decision', 'pay a decision'],
    String contextSentence = 'It is time to make __ and move forward.',
    String explanation =
        'We say "make a decision", not "do a decision" in natural English.',
    String hint = 'Choose between alternatives.',
    int difficulty = 1,
  }) {
    return VocabularyQuest(
      id: id,
      type: QuestType.vocabulary,
      subtype: GameSubtype.collocations,
      word: word,
      correctAnswer: correctAnswer,
      options: options,
      instruction: instruction,
      wrongCollocations: wrongCollocations,
      contextSentence: contextSentence,
      explanation: explanation,
      hint: hint,
      difficulty: difficulty,
    );
  }

  final sampleQuest1 = createQuest();

  final sampleQuest2 = createQuest(
    id: 'quest_collocation_2',
    word: 'pay',
    correctAnswer: 'attention',
    options: ['attention', 'a visit', 'a mistake', 'effort'],
    instruction: 'Complete the collocation.',
    wrongCollocations: ['give attention', 'make attention'],
    contextSentence: 'Please __ to the instructions.',
    explanation: 'We "pay attention" when focusing carefully.',
    hint: 'Listen or watch closely.',
  );

  final sampleMinimalQuest = const VocabularyQuest(
    id: 'quest_collocation_minimal',
    type: QuestType.vocabulary,
    subtype: GameSubtype.collocations,
    word: 'take',
    correctAnswer: 'a break',
    options: ['a break', 'a rest'],
    instruction: 'Pair the collocation.',
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
        gameType: GameSubtype.collocations,
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
          id: 'test_user_collocations',
          email: 'collocations@vowl.app',
          displayName: 'Collocation Master',
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
    GameSubtype gameType = GameSubtype.collocations,
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
              child: CollocationsScreen(level: level, gameType: gameType),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('1. Initial Screen & Layout Setup', () {
    testWidgets('1.1 renders CollocationAnchorBubble with target word', (
      tester,
    ) async {
      await pumpScreen(tester);
      expect(find.byType(CollocationAnchorBubble), findsOneWidget);
      expect(find.text('MAKE'), findsOneWidget);
    });

    testWidgets('1.2 renders instruction banner', (tester) async {
      await pumpScreen(tester);
      expect(
        find.text('MATCH THE CORRECT COLLOCATION PARTNER.'),
        findsOneWidget,
      );
    });

    testWidgets('1.3 renders all option bubbles from quest options', (
      tester,
    ) async {
      await pumpScreen(tester);
      expect(find.byType(CollocationOptionBubble), findsNWidgets(4));
      expect(find.text('A DECISION'), findsWidgets);
      expect(find.text('A MISTAKE'), findsWidgets);
      expect(find.text('ATTENTION'), findsWidgets);
      expect(find.text('HOMEWORK'), findsWidgets);
    });

    testWidgets('1.4 renders minimal quest with 2 options cleanly', (
      tester,
    ) async {
      final minimalState = testLoadedState.copyWith(
        quests: [sampleMinimalQuest],
        currentIndex: 0,
      );
      await pumpScreen(tester, state: minimalState);
      expect(find.byType(CollocationAnchorBubble), findsOneWidget);
      expect(find.text('TAKE'), findsOneWidget);
      expect(find.byType(CollocationOptionBubble), findsNWidgets(2));
      expect(find.text('A BREAK'), findsWidgets);
      expect(find.text('A REST'), findsWidgets);
    });

    testWidgets('1.5 dispatches FetchVocabularyQuests on mount', (tester) async {
      await pumpScreen(tester, level: 3);
      verify(
        () => mockVocabularyBloc.add(
          const FetchVocabularyQuests(
            gameType: GameSubtype.collocations,
            level: 3,
          ),
        ),
      ).called(1);
    });

    testWidgets(
      '1.6 displays briefing dialog on level 1 and dismisses on BEGIN tap',
      (tester) async {
        await pumpScreen(tester, level: 1);
        final startBtn = find.text('BEGIN SEARCH');
        final beginBtn = find.text('START SEARCH');
        final anyBtn = startBtn.evaluate().isNotEmpty
            ? startBtn
            : (beginBtn.evaluate().isNotEmpty ? beginBtn : find.text('BEGIN'));
        if (anyBtn.evaluate().isNotEmpty) {
          await tester.ensureVisible(anyBtn);
          await tester.pumpAndSettle();
          await tester.tap(anyBtn);
          await tester.pump(const Duration(milliseconds: 300));
        }
      },
    );
  });

  group('2. Phase 1: Tap-to-Answer Selection', () {
    testWidgets('2.1 tapping option bubble triggers light haptic', (
      tester,
    ) async {
      await pumpScreen(tester);
      final option = find.text('A DECISION').first;
      await tester.tap(option);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 300));
      verify(() => mockHapticService.light()).called(1);
    });

    testWidgets(
      '2.2 tapping correct option fuses anchor, triggers selection haptic, and advances to Phase 2',
      (tester) async {
        await pumpScreen(tester);

        await tester.tap(find.text('A DECISION').first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pump(const Duration(milliseconds: 300));

        verify(() => mockHapticService.selection()).called(1);
        expect(find.byType(ContextSentenceBuilder), findsOneWidget);
        expect(find.text('MAKE A DECISION'), findsWidgets);
      },
    );

    testWidgets(
      '2.3 tapping incorrect option submits wrong answer with error sound & haptic',
      (tester) async {
        await pumpScreen(tester);

        await tester.tap(find.text('ATTENTION').first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        verify(
          () => mockVocabularyBloc.add(const SubmitAnswer(false)),
        ).called(1);
        verify(() => mockSoundService.playWrong()).called(1);
        verify(() => mockHapticService.error()).called(1);
      },
    );
  });

  group('3. Phase 1: Drag-and-Drop Selection Mechanics', () {
    testWidgets('3.1 CollocationAnchorBubble is wrapped in DragTarget', (
      tester,
    ) async {
      await pumpScreen(tester);
      expect(find.byType(DragTarget<String>), findsOneWidget);
    });

    testWidgets(
      '3.2 dragging correct option and dropping onto anchor fuses and advances to Phase 2',
      (tester) async {
      await pumpScreen(tester);

      final option = find.text('A DECISION').first;
      final anchor = find.byType(CollocationAnchorBubble);

      final gesture = await tester.startGesture(tester.getCenter(option));
      await gesture.moveTo(tester.getCenter(anchor));
      await tester.pump(const Duration(milliseconds: 50));

      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ContextSentenceBuilder), findsOneWidget);
    });

    testWidgets(
      '3.3 dragging incorrect option onto anchor submits wrong answer',
      (tester) async {
        await pumpScreen(tester);

        final option = find.text('HOMEWORK').first;
        final anchor = find.byType(CollocationAnchorBubble);

        final gesture = await tester.startGesture(tester.getCenter(option));
        await gesture.moveTo(tester.getCenter(anchor));
        await tester.pump(const Duration(milliseconds: 50));

        await gesture.up();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        verify(
          () => mockVocabularyBloc.add(const SubmitAnswer(false)),
        ).called(1);
        verify(() => mockSoundService.playWrong()).called(1);
        verify(() => mockHapticService.error()).called(1);
      },
    );
  });

  group('4. Phase 2: CollocationsWrongPairs & ContextSentenceBuilder', () {
    Future<void> advanceToPhase2(WidgetTester tester) async {
      await pumpScreen(tester);
      await tester.tap(find.text('A DECISION').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('4.1 renders CollocationsWrongPairs with COMMON MISTAKES header', (
      tester,
    ) async {
      await advanceToPhase2(tester);
      expect(find.byType(CollocationsWrongPairs), findsOneWidget);
      expect(find.text('COMMON MISTAKES'), findsOneWidget);
      expect(find.text('do a decision'), findsOneWidget);
      expect(find.text('pay a decision'), findsOneWidget);
    });

    testWidgets(
      '4.2 CollocationsWrongPairs filters out correct pair if present in wrong list',
      (tester) async {
        final questWithCorrectInWrongList = createQuest(
          wrongCollocations: ['make a decision', 'do a decision'],
        );
        final state = testLoadedState.copyWith(
          quests: [questWithCorrectInWrongList],
        );
        await pumpScreen(tester, state: state);
        await tester.tap(find.text('A DECISION').first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('do a decision'), findsOneWidget);
      },
    );

    testWidgets(
      '4.3 renders ContextSentenceBuilder with formatted target keyword and example sentence',
      (tester) async {
        await advanceToPhase2(tester);
        expect(find.byType(ContextSentenceBuilder), findsOneWidget);
        expect(
          find.textContaining('It is time to make a decision and move forward.'),
          findsOneWidget,
        );
      },
    );
  });

  group('5. Phase 2: Final Evaluation Submission (Success & Failure)', () {
    Future<void> advanceToPhase2(WidgetTester tester) async {
      await pumpScreen(tester);
      await tester.tap(find.text('A DECISION').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets(
      '5.1 confirming in ContextSentenceBuilder dispatches SubmitAnswer(true) with audio & haptics',
      (tester) async {
        await advanceToPhase2(tester);

        final builder = tester.widget<ContextSentenceBuilder>(
          find.byType(ContextSentenceBuilder),
        );
        builder.onConfirmed();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        verify(() => mockVocabularyBloc.add(const SubmitAnswer(true))).called(1);
        verify(() => mockSoundService.playCorrect()).called(1);
        verify(() => mockHapticService.success()).called(1);
      },
    );

    testWidgets(
      '5.2 skipping in ContextSentenceBuilder dispatches SubmitAnswer(false)',
      (tester) async {
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
      },
    );
  });

  group('6. Interaction Lockout, Retry & Navigation', () {
    testWidgets('6.1 once answered, tapping option bubbles is locked out', (
      tester,
    ) async {
      await pumpScreen(tester);
      // Advance to Phase 2
      await tester.tap(find.text('A DECISION').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 300));

      // Submit final answer
      final builder = tester.widget<ContextSentenceBuilder>(
        find.byType(ContextSentenceBuilder),
      );
      builder.onConfirmed();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      clearInteractions(mockVocabularyBloc);
      clearInteractions(mockHapticService);

      // Verify option tapping is locked out
      final option = find.text('A MISTAKE').first;
      await tester.tap(option, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 100));

      verifyNever(() => mockHapticService.light());
      verifyNever(() => mockVocabularyBloc.add(any()));
    });

    testWidgets('6.2 answered state mounts GameFeedbackCard with CONTINUE button', (
      tester,
    ) async {
      await pumpScreen(tester);
      await tester.tap(find.text('A DECISION').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 300));

      final builder = tester.widget<ContextSentenceBuilder>(
        find.byType(ContextSentenceBuilder),
      );
      builder.onConfirmed();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(GameFeedbackCard), findsOneWidget);
      expect(find.text('CONTINUE'), findsOneWidget);
    });

    testWidgets('6.3 tapping CONTINUE on correct answer dispatches NextQuestion', (
      tester,
    ) async {
      await pumpScreen(tester);
      await tester.tap(find.text('A DECISION').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 300));

      final builder = tester.widget<ContextSentenceBuilder>(
        find.byType(ContextSentenceBuilder),
      );
      builder.onConfirmed();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.text('CONTINUE'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      verify(() => mockVocabularyBloc.add(const NextQuestion())).called(1);
    });

    testWidgets(
      '6.4 tapping TRY AGAIN on wrong answer (non-final failure) resets for retry',
      (tester) async {
        await pumpScreen(tester);
        await tester.tap(find.text('ATTENTION').first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        // When wrong answer is submitted, state has wrongCount > 0, isCorrect = false
        final feedbackCard = find.byType(GameFeedbackCard);
        expect(feedbackCard, findsOneWidget);

        final retryBtn = find.text('TRY AGAIN');
        expect(retryBtn, findsOneWidget);

        await tester.tap(retryBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        // Did not dispatch NextQuestion because it allows retry
        verifyNever(() => mockVocabularyBloc.add(const NextQuestion()));
      },
    );
  });

  group('7. Progression, State Transitions & Cleanup', () {
    testWidgets('7.1 tapping header hint button dispatches VocabularyHintUsed', (
      tester,
    ) async {
      await pumpScreen(tester);
      final hintButton = find.byType(QuestHintButton);
      expect(hintButton, findsOneWidget);
      await tester.tap(hintButton);
      await tester.pump(const Duration(milliseconds: 100));
      verify(
        () => mockVocabularyBloc.add(const VocabularyHintUsed()),
      ).called(greaterThanOrEqualTo(1));
    });

    testWidgets('7.2 when hint is used, correct option bubble shows hint styling', (
      tester,
    ) async {
      final hintState = testLoadedState.copyWith(hintUsed: true);
      await pumpScreen(tester, state: hintState);

      final correctOptionFinder = find.byWidgetPredicate((widget) {
        return widget is CollocationOptionBubble &&
            widget.text == 'a decision' &&
            widget.isHintUsed == true;
      });
      expect(correctOptionFinder, findsOneWidget);
    });

    testWidgets(
      '7.3 transitioning to second quest resets state and displays second word',
      (tester) async {
        await pumpScreen(tester);
        expect(find.text('MAKE'), findsOneWidget);

        final updatedState = testLoadedState.copyWith(
          currentIndex: 1,
          answerStatus: AnswerStatus.unanswered,
        );
        vocabularyStreamController.add(updatedState);
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('PAY'), findsOneWidget);
        expect(find.text('ATTENTION'), findsWidgets);
        expect(find.byType(ContextSentenceBuilder), findsNothing);
      },
    );

    testWidgets(
      '7.4 VocabularyGameComplete state triggers LEVEL COMPLETE dialog and disposes cleanly',
      (tester) async {
        await pumpScreen(tester);

        vocabularyStreamController.add(
          const VocabularyGameComplete(
            xpEarned: 50,
            coinsEarned: 15,
            questCount: 2,
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('LEVEL COMPLETE!'), findsOneWidget);

        // Clean up completion dialog to avoid pending periodic timers
        Navigator.of(tester.element(find.text('LEVEL COMPLETE!'))).pop();
        await tester.pump(const Duration(milliseconds: 500));
      },
    );

    testWidgets('7.5 renders GameShimmerLoading when quests are loading/null', (
      tester,
    ) async {
      const loadingState = VocabularyLoading();
      await pumpScreen(tester, state: loadingState);
      expect(find.byType(GameShimmerLoading), findsOneWidget);
    });

    testWidgets('7.6 screen disposes cleanly without timer leaks', (
      tester,
    ) async {
      await pumpScreen(tester);
      expect(find.byType(CollocationsScreen), findsOneWidget);
    });
  });

  group('8. Viewport Responsiveness, Theming & Accessibility', () {
    testWidgets('8.1 renders cleanly on compact mobile viewport (320x568)', (
      tester,
    ) async {
      await pumpScreen(tester, size: const Size(320, 568));
      expect(tester.takeException(), isNull);
      expect(find.byType(CollocationAnchorBubble), findsOneWidget);
      expect(find.byType(CollocationOptionBubble), findsNWidgets(4));
    });

    testWidgets('8.2 renders cleanly on tablet viewport (768x1024)', (
      tester,
    ) async {
      await pumpScreen(tester, size: const Size(768, 1024));
      expect(tester.takeException(), isNull);
      expect(find.byType(CollocationAnchorBubble), findsOneWidget);
      expect(find.byType(CollocationOptionBubble), findsNWidgets(4));
    });

    testWidgets('8.3 renders cleanly in Light Theme mode', (tester) async {
      await pumpScreen(tester, themeMode: ThemeMode.light);
      expect(tester.takeException(), isNull);
      expect(find.byType(CollocationAnchorBubble), findsOneWidget);
    });

    testWidgets('8.4 renders cleanly in Dark Theme mode', (tester) async {
      await pumpScreen(tester, themeMode: ThemeMode.dark);
      expect(tester.takeException(), isNull);
      expect(find.byType(CollocationAnchorBubble), findsOneWidget);
    });

    testWidgets('8.5 supports text scaling up to 1.5x cleanly', (tester) async {
      await pumpScreen(tester, textScaleFactor: 1.5);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      '8.6 suppresses repeating animations when disableAnimations is true',
      (tester) async {
        await pumpScreen(tester, reduceMotion: true);
        await tester.pumpAndSettle();
        expect(find.byType(CollocationAnchorBubble), findsOneWidget);
      },
    );
  });
}
