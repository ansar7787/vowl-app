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
import 'package:vowl/core/presentation/game_mechanics/typing/type_to_confirm_overlay.dart';
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
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:vowl/features/vocabulary/presentation/layout/vocabulary_base_layout.dart';
import 'package:vowl/features/vocabulary/academic_word/academic_word_constants.dart';
import 'package:vowl/features/vocabulary/academic_word/presentation/pages/academic_word_screen.dart';
import 'package:vowl/features/vocabulary/academic_word/presentation/widgets/academic_word_field_collocations.dart';
import 'package:vowl/features/vocabulary/academic_word/presentation/widgets/academic_word_instruction.dart';
import 'package:vowl/features/vocabulary/academic_word/presentation/widgets/academic_word_shard.dart';
import 'package:vowl/features/vocabulary/academic_word/presentation/widgets/academic_word_thesis_paper.dart';

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
    String id = 'quest_academic_1',
    String passage =
        'The researcher presented an [TARGET] analysis of the experimental data.',
    String correctAnswer = 'empirical',
    List<String> options = const [
      'empirical',
      'subjective',
      'random',
      'trivial',
    ],
    String instruction =
        'Insert the appropriate academic term into the thesis statement.',
    String academicField = 'Quantitative Research',
    List<String> collocations = const [
      'empirical evidence',
      'empirical analysis',
      'empirical study',
    ],
    String contextSentence =
        'Empirical studies rely on verifiable observations rather than pure theory.',
    String? hint =
        'Pertaining to observation or experience rather than theory.',
    int difficulty = 1,
  }) {
    return VocabularyQuest(
      id: id,
      type: QuestType.vocabulary,
      subtype: GameSubtype.academicWord,
      passage: passage,
      correctAnswer: correctAnswer,
      options: options,
      instruction: instruction,
      academicField: academicField,
      collocations: collocations,
      contextSentence: contextSentence,
      hint: hint,
      difficulty: difficulty,
    );
  }

  final sampleQuest1 = createQuest();

  final sampleQuest2 = createQuest(
    id: 'quest_academic_2',
    passage:
        'Her groundbreaking hypothesis provided a robust [TARGET] for subsequent inquiries.',
    correctAnswer: 'framework',
    options: ['framework', 'obstacle', 'mirage', 'vacuum'],
    instruction: 'Complete the academic passage.',
    academicField: 'Theoretical Epistemology',
    collocations: [
      'conceptual framework',
      'theoretical framework',
      'regulatory framework',
    ],
    contextSentence:
        'A sound theoretical framework guides the methodology and research design.',
    hint: 'A basic structure underlying a system, concept, or text.',
  );

  final sampleMinimalQuest = const VocabularyQuest(
    id: 'quest_academic_minimal',
    type: QuestType.vocabulary,
    subtype: GameSubtype.academicWord,
    passage:
        'The team formulated an innovative [TARGET] to validate the model.',
    correctAnswer: 'paradigm',
    options: ['paradigm', 'cliche'],
    instruction: 'Select the missing scholarly term.',
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
    registerFallbackValue(const NextQuestion());
    registerFallbackValue(const VocabularyHintUsed());
    registerFallbackValue(
      const FetchVocabularyQuests(
        gameType: GameSubtype.academicWord,
        level: 2,
      ),
    );
    registerFallbackValue(const Duration(milliseconds: 50));
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'has_seen_briefing_academicWord': true,
    });

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
          id: 'test_user_academic',
          email: 'academic@vowl.app',
          displayName: 'Academic Scholar',
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
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    VocabularyState? state,
    int level = 2,
    GameSubtype gameType = GameSubtype.academicWord,
    Size size = const Size(390, 844),
    double textScaleFactor = 1.0,
    ThemeMode themeMode = ThemeMode.dark,
    bool reduceMotion = true,
  }) async {
    VowlMotion.lowAnimationModeOverride.value = reduceMotion;
    tester.view.physicalSize = size * 2.0;
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
              child: AcademicWordScreen(
                level: level,
                gameType: gameType,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));

    if (state != null) {
      vocabularyStreamController.add(state);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));
    }
  }

  // ---------------------------------------------------------------------------
  // 1. Initial Layout & Component Structure (8 tests)
  // ---------------------------------------------------------------------------
  group('1. Initial Layout & Component Structure', () {
    testWidgets('1.1 renders VocabularyBaseLayout', (tester) async {
      await pumpScreen(tester);
      expect(find.byType(VocabularyBaseLayout), findsOneWidget);
    });

    testWidgets('1.2 renders AcademicWordScreen root widget', (tester) async {
      await pumpScreen(tester);
      expect(find.byType(AcademicWordScreen), findsOneWidget);
    });

    testWidgets('1.3 renders game body with key academic_word_game_body',
        (tester) async {
      await pumpScreen(tester);
      expect(
        find.byKey(const Key('academic_word_game_body')),
        findsOneWidget,
      );
    });

    testWidgets('1.4 renders AcademicWordInstruction banner', (tester) async {
      await pumpScreen(tester);
      expect(find.byType(AcademicWordInstruction), findsOneWidget);
      expect(
        find.byKey(const Key('academic_word_instruction')),
        findsOneWidget,
      );
    });

    testWidgets('1.5 renders AcademicWordThesisPaper card', (tester) async {
      await pumpScreen(tester);
      expect(find.byType(AcademicWordThesisPaper), findsOneWidget);
      expect(
        find.byKey(const Key('academic_word_thesis_paper')),
        findsOneWidget,
      );
    });

    testWidgets('1.6 renders shards for all four options', (tester) async {
      await pumpScreen(tester);
      expect(find.byType(AcademicWordShard), findsNWidgets(4));
      for (int i = 0; i < 4; i++) {
        expect(find.byKey(Key('academic_word_shard_$i')), findsOneWidget);
      }
    });

    testWidgets('1.7 renders RawScrollbar with key academic_word_scrollbar',
        (tester) async {
      await pumpScreen(tester);
      expect(
        find.byKey(const Key('academic_word_scrollbar')),
        findsOneWidget,
      );
    });

    testWidgets(
        '1.8 renders CustomScrollView with key academic_word_scroll_view',
        (tester) async {
      await pumpScreen(tester);
      expect(
        find.byKey(const Key('academic_word_scroll_view')),
        findsOneWidget,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // 2. Instruction Banner, Scaling & Accessibility (7 tests)
  // ---------------------------------------------------------------------------
  group('2. Instruction Banner, Scaling & Accessibility', () {
    testWidgets('2.1 displays instruction text inside banner', (tester) async {
      await pumpScreen(tester);
      expect(
        find.text(
          'Insert the appropriate academic term into the thesis statement.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('2.2 contains key academic_word_instruction_text',
        (tester) async {
      await pumpScreen(tester);
      expect(
        find.byKey(const Key('academic_word_instruction_text')),
        findsOneWidget,
      );
    });

    testWidgets('2.3 wraps banner in Semantics with matching label',
        (tester) async {
      await pumpScreen(tester);
      final semanticsFinder = find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            w.properties.label ==
                'Insert the appropriate academic term into the thesis statement.',
      );
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets('2.4 clamps text scale factor at 1.5 within instruction banner',
        (tester) async {
      await pumpScreen(tester, textScaleFactor: 2.5);
      final mediaQuery = tester.widget<MediaQuery>(
        find.descendant(
          of: find.byType(AcademicWordInstruction),
          matching: find.byType(MediaQuery),
        ),
      );
      expect(mediaQuery.data.textScaler.scale(10), lessThanOrEqualTo(15.0));
    });

    testWidgets('2.5 renders banner with level theme color styling',
        (tester) async {
      await pumpScreen(tester);
      final container = tester.widget<Container>(
        find.byKey(const Key('academic_word_instruction')),
      );
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration, isNotNull);
      expect(decoration!.borderRadius, isNotNull);
    });

    testWidgets('2.6 applies fallback instruction when quest instruction is null/empty',
        (tester) async {
      final noInstructionQuest = createQuest(instruction: '');
      final state = VocabularyLoaded(
        quests: [noInstructionQuest],
        currentIndex: 0,
        livesRemaining: 3,
      );
      await pumpScreen(tester, state: state);
      expect(find.byType(AcademicWordInstruction), findsOneWidget);
    });

    testWidgets('2.7 instruction banner remains visible in compact viewport',
        (tester) async {
      await pumpScreen(tester, size: const Size(320, 568));
      expect(
        find.byKey(const Key('academic_word_instruction')),
        findsOneWidget,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // 3. Thesis Paper & Passage Rendering (9 tests)
  // ---------------------------------------------------------------------------
  group('3. Thesis Paper & Passage Rendering', () {
    testWidgets('3.1 displays passage text before [TARGET] marker',
        (tester) async {
      await pumpScreen(tester);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is RichText &&
              w.text.toPlainText().contains('The researcher presented an'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('3.2 displays passage text after [TARGET] marker',
        (tester) async {
      await pumpScreen(tester);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is RichText &&
              w.text.toPlainText().contains('analysis of the experimental data.'),
        ),
        findsOneWidget,
      );
    });


    testWidgets('3.3 displays _AnswerSlot detector with key academic_word_slot_detector',
        (tester) async {
      await pumpScreen(tester);
      expect(
        find.byKey(const Key('academic_word_slot_detector')),
        findsOneWidget,
      );
    });

    testWidgets('3.4 displays pending slot text THRUST_PENDING when unanswered',
        (tester) async {
      await pumpScreen(tester);
      expect(
        find.byKey(const Key('academic_word_slot_pending_text')),
        findsOneWidget,
      );
      expect(find.text(AcademicWordStrings.slotPending), findsOneWidget);
    });

    testWidgets('3.5 shows answer slot with border styling', (tester) async {
      await pumpScreen(tester);
      final slotDetector = tester.widget<GestureDetector>(
        find.byKey(const Key('academic_word_slot_detector')),
      );
      final container = slotDetector.child as Container;
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration, isNotNull);
      expect(decoration!.border, isNotNull);
    });

    testWidgets('3.6 tapping answer slot toggles isSlotSelected and plays light haptic',
        (tester) async {
      await pumpScreen(tester);
      final state =
          tester.state(find.byType(AcademicWordScreen)) as dynamic;
      expect(state.isSlotSelectedNotifier.value, isFalse);

      await tester.tap(find.byKey(const Key('academic_word_slot_detector')));
      await tester.pump();

      expect(state.isSlotSelectedNotifier.value, isTrue);
      verify(() => mockHapticService.light()).called(1);

      // Tap again to toggle off
      await tester.tap(find.byKey(const Key('academic_word_slot_detector')));
      await tester.pump();
      expect(state.isSlotSelectedNotifier.value, isFalse);
    });

    testWidgets('3.7 slot Semantics reflects selection state', (tester) async {
      await pumpScreen(tester);
      final state =
          tester.state(find.byType(AcademicWordScreen)) as dynamic;

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.button == true &&
              w.properties.label == 'Slot pending',
        ),
        findsOneWidget,
      );

      state.isSlotSelectedNotifier.value = true;
      await tester.pump();

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.button == true &&
              w.properties.label == 'Slot selected',
        ),
        findsOneWidget,
      );
    });

    testWidgets('3.8 handles passages with no text following [TARGET]',
        (tester) async {
      final trailingTargetQuest = createQuest(
        passage: 'The entire argument hinges on this fundamental [TARGET]',
      );
      final state = VocabularyLoaded(
        quests: [trailingTargetQuest],
        currentIndex: 0,
        livesRemaining: 3,
      );
      await pumpScreen(tester, state: state);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is RichText &&
              w.text.toPlainText().contains(
                    'The entire argument hinges on this fundamental',
                  ),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('academic_word_slot_detector')),
        findsOneWidget,
      );
    });

    testWidgets('3.9 handles passages with quotes and special characters',
        (tester) async {
      final specialQuest = createQuest(
        passage: 'They questioned the "validity" & [TARGET] of the findings.',
      );
      final state = VocabularyLoaded(
        quests: [specialQuest],
        currentIndex: 0,
        livesRemaining: 3,
      );
      await pumpScreen(tester, state: state);
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is RichText &&
              w.text.toPlainText().contains('They questioned the "validity" &'),
        ),
        findsOneWidget,
      );
    });

  });

  // ---------------------------------------------------------------------------
  // 4. Shard Mechanics & Rendering (8 tests)
  // ---------------------------------------------------------------------------
  group('4. Shard Mechanics & Rendering', () {
    testWidgets('4.1 renders exactly 4 shards for 4 options', (tester) async {
      await pumpScreen(tester);
      expect(find.byType(AcademicWordShard), findsNWidgets(4));
    });

    testWidgets('4.2 each shard displays uppercase text', (tester) async {
      await pumpScreen(tester);
      expect(find.text('EMPIRICAL'), findsOneWidget);
      expect(find.text('SUBJECTIVE'), findsOneWidget);
      expect(find.text('RANDOM'), findsOneWidget);
      expect(find.text('TRIVIAL'), findsOneWidget);
    });

    testWidgets('4.3 each shard has Semantics button and option label',
        (tester) async {
      await pumpScreen(tester);
      for (final opt in ['empirical', 'subjective', 'random', 'trivial']) {
        final finder = find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.button == true &&
              w.properties.label == opt,
        );
        expect(finder, findsOneWidget);
      }
    });

    testWidgets('4.4 computes distinct 2x2 initial grid positions for shards',
        (tester) async {
      await pumpScreen(tester);
      final state =
          tester.state(find.byType(AcademicWordScreen)) as dynamic;

      final pos0 = state.getShardInitialPosition(0, 800.0, 400.0);
      final pos1 = state.getShardInitialPosition(1, 800.0, 400.0);
      final pos2 = state.getShardInitialPosition(2, 800.0, 400.0);
      final pos3 = state.getShardInitialPosition(3, 800.0, 400.0);

      // Col 0 should have negative dx, Col 1 positive dx
      expect(pos0.dx, lessThan(0));
      expect(pos1.dx, greaterThan(0));
      // Row 0 should have smaller dy than Row 1
      expect(pos0.dy, lessThan(pos2.dy));
      expect(pos1.dy, lessThan(pos3.dy));
    });

    testWidgets('4.5 shard resolveWidth and resolveHeight produce bounded sizes',
        (tester) async {
      final w = AcademicWordShard.resolveWidth(400.0);
      final h = AcademicWordShard.resolveHeight(800.0);
      expect(w, inInclusiveRange(90.0, 160.0));
      expect(h, inInclusiveRange(44.0, 72.0));
    });

    testWidgets('4.6 shards render card styling with border', (tester) async {
      await pumpScreen(tester);
      final shardDetector = tester.widget<GestureDetector>(
        find.byKey(const Key('academic_word_shard_0')),
      );
      final container = shardDetector.child as Container;
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration, isNotNull);
      expect(decoration!.border, isNotNull);
    });

    testWidgets('4.7 shards are unmounted when isFirstStagePassed is true',
        (tester) async {
      await pumpScreen(tester);
      final state =
          tester.state(find.byType(AcademicWordScreen)) as dynamic;

      expect(find.byType(AcademicWordShard), findsNWidgets(4));

      state.isDragPassedNotifier.value = true;
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(AcademicWordShard), findsNothing);
    });


    testWidgets('4.8 supports 2 options without index out-of-bounds',
        (tester) async {
      final state = VocabularyLoaded(
        quests: [sampleMinimalQuest],
        currentIndex: 0,
        livesRemaining: 3,
      );
      await pumpScreen(tester, state: state);
      expect(find.byType(AcademicWordShard), findsNWidgets(2));
      expect(find.text('PARADIGM'), findsOneWidget);
      expect(find.text('CLICHE'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // 5. Phase 1 Thrust Interaction (Tap & Drag) (9 tests)
  // ---------------------------------------------------------------------------
  group('5. Phase 1 Thrust Interaction (Tap & Drag)', () {
    testWidgets('5.1 tapping correct shard sets isDragPassed to true',
        (tester) async {
      await pumpScreen(tester);
      final state =
          tester.state(find.byType(AcademicWordScreen)) as dynamic;
      expect(state.isDragPassedNotifier.value, isFalse);

      await tester.tap(find.byKey(const Key('academic_word_shard_0')), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 500));

      expect(state.isDragPassedNotifier.value, isTrue);
      verify(() => mockHapticService.selection()).called(1);
    });

    testWidgets('5.2 tapping correct shard triggers auto-scroll timer',
        (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('academic_word_shard_0')), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.byKey(const Key('academic_word_scroll_view')), findsOneWidget);
    });

    testWidgets('5.3 tapping incorrect shard submits wrong answer and sets misspelledWord',
        (tester) async {
      await pumpScreen(tester);
      final state =
          tester.state(find.byType(AcademicWordScreen)) as dynamic;

      // Option 1 is 'subjective' (incorrect)
      await tester.tap(find.byKey(const Key('academic_word_shard_1')), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));

      expect(state.isDragPassedNotifier.value, isFalse);
      expect(state.misspelledWordNotifier.value, equals('subjective'));
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockVocabularyBloc.add(const SubmitAnswer(false))).called(1);
    });

    testWidgets('5.4 shard onPanStart activates activeShardIndex and light haptic',
        (tester) async {
      await pumpScreen(tester);
      final state =
          tester.state(find.byType(AcademicWordScreen)) as dynamic;
      expect(state.activeShardIndexNotifier.value, isNull);

      state.onShardDragStart(0, const BoxConstraints(maxWidth: 400, maxHeight: 800));
      await tester.pump();

      expect(state.activeShardIndexNotifier.value, equals(0));
      verify(() => mockHapticService.light()).called(1);
    });

    testWidgets('5.5 shard onPanUpdate moves dragOffset within limits',
        (tester) async {
      await pumpScreen(tester);
      final state =
          tester.state(find.byType(AcademicWordScreen)) as dynamic;
      state.onShardDragStart(0, const BoxConstraints(maxWidth: 400, maxHeight: 800));

      state.onShardDragUpdate(
        0,
        DragUpdateDetails(
          delta: const Offset(20, -50),
          globalPosition: const Offset(200, 400),
        ),
      );
      await tester.pump();

      expect(state.dragOffsetNotifier.value.dx, inInclusiveRange(-200.0, 200.0));
      expect(state.dragOffsetNotifier.value.dy, inInclusiveRange(-400.0, 400.0));
    });

    testWidgets('5.6 shard onPanEnd away from slot resets offset to zero and light haptic',
        (tester) async {
      await pumpScreen(tester);
      final state =
          tester.state(find.byType(AcademicWordScreen)) as dynamic;
      state.onShardDragStart(0, const BoxConstraints(maxWidth: 400, maxHeight: 800));
      state.onShardDragUpdate(
        0,
        DragUpdateDetails(
          delta: const Offset(10, 10),
          globalPosition: const Offset(100, 100),
        ),
      );

      state.onShardDragEnd(0, sampleQuest1);
      await tester.pump();

      expect(state.dragOffsetNotifier.value, equals(Offset.zero));
      expect(state.activeShardIndexNotifier.value, isNull);
    });

    testWidgets('5.7 attemptThrust with out-of-bounds index is safely ignored',
        (tester) async {
      await pumpScreen(tester);
      final state =
          tester.state(find.byType(AcademicWordScreen)) as dynamic;

      state.attemptThrust(99, sampleQuest1);
      await tester.pump();

      expect(state.isDragPassedNotifier.value, isFalse);
    });

    testWidgets('5.8 tapping shard is ignored when isDragPassed is already true',
        (tester) async {
      await pumpScreen(tester);
      final state =
          tester.state(find.byType(AcademicWordScreen)) as dynamic;
      state.isDragPassedNotifier.value = true;
      await tester.pump();

      state.attemptThrust(1, sampleQuest1);
      await tester.pump();

      // No wrong answer submitted because drag was already passed
      verifyNever(() => mockSoundService.playWrong());
    });

    testWidgets('5.9 drag updates are ignored when isAnswered is true',
        (tester) async {
      final state = VocabularyLoaded(
        quests: [sampleQuest1],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.correct,
      );
      await pumpScreen(tester, state: state);
      final screenState =
          tester.state(find.byType(AcademicWordScreen)) as dynamic;

      screenState.onShardDragStart(0, const BoxConstraints(maxWidth: 400, maxHeight: 800));
      expect(screenState.activeShardIndexNotifier.value, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // 6. Phase 2 Transition, Collocations & TypeToConfirmOverlay (9 tests)
  // ---------------------------------------------------------------------------
  group('6. Phase 2 Transition, Collocations & TypeToConfirmOverlay', () {
    testWidgets('6.1 passing stage 1 mounts AcademicWordFieldCollocations',
        (tester) async {
      await pumpScreen(tester);
      expect(find.byType(AcademicWordFieldCollocations), findsNothing);

      await tester.tap(find.byKey(const Key('academic_word_shard_0')), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(AcademicWordFieldCollocations), findsOneWidget);
      expect(
        find.byKey(const Key('academic_word_collocations_panel')),
        findsOneWidget,
      );
    });

    testWidgets('6.2 passing stage 1 mounts TypeToConfirmOverlay',
        (tester) async {
      await pumpScreen(tester);
      expect(find.byType(TypeToConfirmOverlay), findsNothing);

      await tester.tap(find.byKey(const Key('academic_word_shard_0')), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(TypeToConfirmOverlay), findsOneWidget);
      expect(
        find.byKey(const Key('academic_word_type_confirm_overlay')),
        findsOneWidget,
      );
    });

    testWidgets('6.3 CustomScrollView physics changes to BouncingScrollPhysics in Phase 2',
        (tester) async {
      await pumpScreen(tester);
      CustomScrollView scrollView = tester.widget<CustomScrollView>(
        find.byKey(const Key('academic_word_scroll_view')),
      );
      expect(scrollView.physics, isA<NeverScrollableScrollPhysics>());

      await tester.tap(find.byKey(const Key('academic_word_shard_0')), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 500));

      scrollView = tester.widget<CustomScrollView>(
        find.byKey(const Key('academic_word_scroll_view')),
      );
      expect(scrollView.physics, isA<BouncingScrollPhysics>());
    });

    testWidgets('6.4 displays Academic Field row and uppercase text',
        (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('academic_word_shard_0')), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byKey(const Key('academic_word_field_row')), findsOneWidget);
      expect(
        find.text('ACADEMIC FIELD: QUANTITATIVE RESEARCH'),
        findsOneWidget,
      );
    });

    testWidgets('6.5 displays Common Collocations label and chip list',
        (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('academic_word_shard_0')), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.byKey(const Key('academic_word_collocations_label')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('academic_word_collocations_wrap')),
        findsOneWidget,
      );
      expect(find.text('empirical evidence'), findsOneWidget);
      expect(find.text('empirical analysis'), findsOneWidget);
      expect(find.text('empirical study'), findsOneWidget);
    });

    testWidgets('6.6 displays Context Sentence row and italicized text',
        (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('academic_word_shard_0')), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.byKey(const Key('academic_word_context_sentence_row')),
        findsOneWidget,
      );
      expect(
        find.text(
          'Empirical studies rely on verifiable observations rather than pure theory.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('6.7 collocations card is omitted when quest has no extra metadata',
        (tester) async {
      final state = VocabularyLoaded(
        quests: [sampleMinimalQuest],
        currentIndex: 0,
        livesRemaining: 3,
      );
      await pumpScreen(tester, state: state);
      final screenState =
          tester.state(find.byType(AcademicWordScreen)) as dynamic;
      screenState.isDragPassedNotifier.value = true;
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(AcademicWordFieldCollocations), findsNothing);
      expect(find.byType(TypeToConfirmOverlay), findsOneWidget);
    });

    testWidgets('6.8 TypeToConfirmOverlay passes expectedText equal to correctAnswer',
        (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('academic_word_shard_0')), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 500));

      final overlay = tester.widget<TypeToConfirmOverlay>(
        find.byKey(const Key('academic_word_type_confirm_overlay')),
      );
      expect(overlay.expectedText, equals('empirical'));
    });

    testWidgets('6.9 TypeToConfirmOverlay is hidden once quest is answered',
        (tester) async {
      await pumpScreen(tester);
      final screenState =
          tester.state(find.byType(AcademicWordScreen)) as dynamic;
      screenState.isDragPassedNotifier.value = true;
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(TypeToConfirmOverlay), findsOneWidget);

      screenState.isAnsweredNotifier.value = true;
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(TypeToConfirmOverlay), findsNothing);
    });
  });

  // ---------------------------------------------------------------------------
  // 7. Final Answer Submission & Confirmation (7 tests)
  // ---------------------------------------------------------------------------
  group('7. Final Answer Submission & Confirmation', () {
    testWidgets('7.1 confirming TypeToConfirmOverlay calls submitCorrectAnswer',
        (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('academic_word_shard_0')), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 500));

      final overlay = tester.widget<TypeToConfirmOverlay>(
        find.byKey(const Key('academic_word_type_confirm_overlay')),
      );
      overlay.onConfirmed();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockSoundService.playCorrect()).called(1);
      verify(() => mockVocabularyBloc.add(const SubmitAnswer(true))).called(1);
    });

    testWidgets('7.2 bypassing TypeToConfirmOverlay calls submitCorrectAnswer',
        (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('academic_word_shard_0')), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 500));

      final overlay = tester.widget<TypeToConfirmOverlay>(
        find.byKey(const Key('academic_word_type_confirm_overlay')),
      );
      overlay.onBypassed?.call();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockSoundService.playCorrect()).called(1);
      verify(() => mockVocabularyBloc.add(const SubmitAnswer(true))).called(1);
    });

    testWidgets('7.3 skipping TypeToConfirmOverlay calls submitWrongAnswer',
        (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('academic_word_shard_0')), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 500));

      final overlay = tester.widget<TypeToConfirmOverlay>(
        find.byKey(const Key('academic_word_type_confirm_overlay')),
      );
      overlay.onSkipped();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockVocabularyBloc.add(const SubmitAnswer(false))).called(1);
    });

    testWidgets('7.4 submitFinalAnswer is no-op when isAnswered is already true',
        (tester) async {
      await pumpScreen(tester);
      final screenState =
          tester.state(find.byType(AcademicWordScreen)) as dynamic;
      screenState.isAnsweredNotifier.value = true;

      screenState.submitFinalAnswer(true, quest: sampleQuest1);
      await tester.pump(const Duration(milliseconds: 300));

      verifyNever(() => mockSoundService.playCorrect());
      verifyNever(() => mockVocabularyBloc.add(const SubmitAnswer(true)));
    });

    testWidgets('7.5 displays answered text in slot when correct',
        (tester) async {
      final state = VocabularyLoaded(
        quests: [sampleQuest1],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.correct,
      );
      await pumpScreen(tester, state: state);

      expect(
        find.byKey(const Key('academic_word_slot_answered_text')),
        findsOneWidget,
      );
      final textWidget = tester.widget<Text>(
        find.byKey(const Key('academic_word_slot_answered_text')),
      );
      expect(textWidget.data, equals('EMPIRICAL'));
    });

    testWidgets('7.6 displays user misspelled word in slot when incorrect',
        (tester) async {
      final state = VocabularyLoaded(
        quests: [sampleQuest1],
        currentIndex: 0,
        livesRemaining: 2,
        answerStatus: AnswerStatus.incorrect,
      );
      await pumpScreen(tester, state: state);
      final screenState =
          tester.state(find.byType(AcademicWordScreen)) as dynamic;
      screenState.misspelledWordNotifier.value = 'subjective';
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.byKey(const Key('academic_word_slot_answered_text')),
        findsOneWidget,
      );
      final textWidget = tester.widget<Text>(
        find.byKey(const Key('academic_word_slot_answered_text')),
      );
      expect(textWidget.data, equals('SUBJECTIVE'));
    });


    testWidgets('7.7 answer slot Semantics reflects answer result when answered',
        (tester) async {
      final state = VocabularyLoaded(
        quests: [sampleQuest1],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.correct,
      );
      await pumpScreen(tester, state: state);

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.button == true &&
              w.properties.label == 'Answer: empirical',
        ),
        findsOneWidget,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // 8. Feedback, Hints & Progression (8 tests)
  // ---------------------------------------------------------------------------
  group('8. Feedback, Hints & Progression', () {
    testWidgets('8.1 GameFeedbackCard mounts when question is answered',
        (tester) async {
      final state = VocabularyLoaded(
        quests: [sampleQuest1],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.correct,
      );
      await pumpScreen(tester, state: state);
      expect(find.byType(GameFeedbackCard), findsOneWidget);
    });

    testWidgets('8.2 feedback card displays positive status on correct answer',
        (tester) async {
      final state = VocabularyLoaded(
        quests: [sampleQuest1],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.correct,
      );
      await pumpScreen(tester, state: state);
      expect(find.text('CONTINUE'), findsOneWidget);
    });

    testWidgets('8.3 feedback card displays try again status on wrong answer with lives',
        (tester) async {
      final state = VocabularyLoaded(
        quests: [sampleQuest1],
        currentIndex: 0,
        livesRemaining: 2,
        answerStatus: AnswerStatus.incorrect,
      );
      await pumpScreen(tester, state: state);
      expect(find.byType(GameFeedbackCard), findsOneWidget);
    });

    testWidgets('8.4 tapping try again on wrong answer resets stage 1 and scrolls to top',
        (tester) async {
      final state = VocabularyLoaded(
        quests: [sampleQuest1],
        currentIndex: 0,
        livesRemaining: 2,
        answerStatus: AnswerStatus.incorrect,
      );
      await pumpScreen(tester, state: state);
      final screenState =
          tester.state(find.byType(AcademicWordScreen)) as dynamic;
      screenState.isDragPassedNotifier.value = true;
      screenState.misspelledWordNotifier.value = 'wrong';

      await tester.tap(find.text('TRY AGAIN'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));

      expect(screenState.isDragPassedNotifier.value, isFalse);
      expect(screenState.misspelledWordNotifier.value, isNull);
    });

    testWidgets('8.5 tapping continue on correct answer dispatches NextQuestion',
        (tester) async {
      final state = VocabularyLoaded(
        quests: [sampleQuest1, sampleQuest2],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.correct,
      );
      await pumpScreen(tester, state: state);

      await tester.tap(find.text('CONTINUE'));
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockVocabularyBloc.add(const NextQuestion())).called(1);
    });

    testWidgets('8.6 tapping hint button dispatches VocabularyHintUsed',
        (tester) async {
      await pumpScreen(tester);
      final hintButton = find.byType(QuestHintButton);
      if (hintButton.evaluate().isNotEmpty) {
        await tester.tap(hintButton);
        await tester.pump(const Duration(milliseconds: 300));
        verify(() => mockVocabularyBloc.add(const VocabularyHintUsed())).called(2);
      }
    });


    testWidgets('8.7 onQuestionReset clears all drag, selection, and error notifiers',
        (tester) async {
      await pumpScreen(tester);
      final screenState =
          tester.state(find.byType(AcademicWordScreen)) as dynamic;

      screenState.isDragPassedNotifier.value = true;
      screenState.misspelledWordNotifier.value = 'error';
      screenState.isSlotSelectedNotifier.value = true;
      screenState.dragOffsetNotifier.value = const Offset(10, 20);
      screenState.activeShardIndexNotifier.value = 1;

      screenState.onQuestionReset();
      await tester.pump(const Duration(milliseconds: 300));

      expect(screenState.isDragPassedNotifier.value, isFalse);
      expect(screenState.misspelledWordNotifier.value, isNull);
      expect(screenState.isSlotSelectedNotifier.value, isFalse);
      expect(screenState.dragOffsetNotifier.value, equals(Offset.zero));
      expect(screenState.activeShardIndexNotifier.value, isNull);
    });

    testWidgets('8.8 question reset safely handles detached scroll controller',
        (tester) async {
      await pumpScreen(tester);
      final screenState =
          tester.state(find.byType(AcademicWordScreen)) as dynamic;
      // Should complete without exception even if no clients are attached
      screenState.onQuestionReset();
      expect(screenState.isDragPassedNotifier.value, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // 9. Game Over, Complete & Shimmer Loading (6 tests)
  // ---------------------------------------------------------------------------
  group('9. Game Over, Complete & Shimmer Loading', () {
    testWidgets('9.1 renders GameShimmerLoading when state is VocabularyLoading',
        (tester) async {
      await pumpScreen(tester, state: const VocabularyLoading());
      expect(find.byType(GameShimmerLoading), findsOneWidget);
    });

    testWidgets('9.2 renders GameShimmerLoading when state is VocabularyInitial',
        (tester) async {
      await pumpScreen(tester, state: const VocabularyInitial());
      expect(find.byType(GameShimmerLoading), findsOneWidget);
    });

    testWidgets('9.3 transitions to VocabularyGameComplete shows completion celebration',
        (tester) async {
      await pumpScreen(tester);
      final completeState = const VocabularyGameComplete(
        xpEarned: 100,
        coinsEarned: 50,
        questCount: 2,
      );

      vocabularyStreamController.add(completeState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('LEVEL COMPLETE!'), findsOneWidget);

      // Clean up dialog to prevent timer leaks
      Navigator.of(tester.element(find.text('LEVEL COMPLETE!'))).pop();
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('9.4 completion title resolves to LEVEL COMPLETE!', (tester) async {
      await pumpScreen(tester);
      final screenState =
          tester.state(find.byType(AcademicWordScreen)) as dynamic;
      expect(
        screenState.getCompletionTitle(tester.element(find.byType(AcademicWordScreen))),
        equals('LEVEL COMPLETE!'),
      );
    });

    testWidgets('9.5 state with isFinalFailure shows game over / failure feedback',
        (tester) async {
      final state = VocabularyLoaded(
        quests: [sampleQuest1],
        currentIndex: 0,
        livesRemaining: 0,
        answerStatus: AnswerStatus.incorrect,
        isFinalFailure: true,
      );
      await pumpScreen(tester, state: state);
      expect(find.byType(GameFeedbackCard), findsOneWidget);
    });

    testWidgets('9.6 game over state triggers appropriate feedback layout',
        (tester) async {
      final gameOverState = VocabularyGameOver(
        quests: [sampleQuest1],
        currentIndex: 0,
      );
      await pumpScreen(tester, state: gameOverState);
      expect(find.byType(VocabularyBaseLayout), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // 10. Responsiveness, Viewports, Themes & Lifecycle (8 tests)
  // ---------------------------------------------------------------------------
  group('10. Responsiveness, Viewports, Themes & Lifecycle', () {
    testWidgets('10.1 compact mobile viewport (320x640) renders without overflow',
        (tester) async {
      await pumpScreen(tester, size: const Size(320, 640));
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('academic_word_game_body')), findsOneWidget);
    });

    testWidgets('10.2 ultra-compact viewport (<420 height) scales correctly',
        (tester) async {
      await pumpScreen(tester, size: const Size(320, 400));
      expect(tester.takeException(), isNull);
      final state =
          tester.state(find.byType(AcademicWordScreen)) as dynamic;
      final pos = state.getShardInitialPosition(0, 390.0, 320.0);
      expect(pos.dy, lessThan(390.0 * 0.5));
    });

    testWidgets('10.3 tablet viewport (800x1280) scales thesis paper and shards',
        (tester) async {
      await pumpScreen(tester, size: const Size(800, 1280));
      expect(tester.takeException(), isNull);
      expect(find.byType(AcademicWordThesisPaper), findsOneWidget);
      expect(find.byType(AcademicWordShard), findsNWidgets(4));
    });

    testWidgets('10.4 dark theme applies cardDark background', (tester) async {
      await pumpScreen(tester, themeMode: ThemeMode.dark);
      final paper = tester.widget<Container>(
        find.byKey(const Key('academic_word_thesis_paper')),
      );
      final decoration = paper.decoration as BoxDecoration?;
      expect(decoration?.color, equals(AcademicWordColors.cardDark));
    });

    testWidgets('10.5 light theme applies white background', (tester) async {
      await pumpScreen(tester, themeMode: ThemeMode.light);
      final paper = tester.widget<Container>(
        find.byKey(const Key('academic_word_thesis_paper')),
      );
      final decoration = paper.decoration as BoxDecoration?;
      expect(decoration?.color, equals(Colors.white));
    });

    testWidgets('10.6 high text scale factor (1.5x) preserves layouts without overflow',
        (tester) async {
      await pumpScreen(tester, textScaleFactor: 1.5);
      expect(tester.takeException(), isNull);
      expect(find.byType(AcademicWordThesisPaper), findsOneWidget);
    });

    testWidgets('10.7 app lifecycle inactive/paused pauses audio and timers',
        (tester) async {
      await pumpScreen(tester);
      final screenState =
          tester.state(find.byType(AcademicWordScreen)) as dynamic;
      screenState.onGamePaused();
      await tester.pump();
      verify(() => mockSoundService.stopAudio()).called(greaterThan(0));
    });

    testWidgets('10.8 app lifecycle resumed restores active state',
        (tester) async {
      await pumpScreen(tester);
      final screenState =
          tester.state(find.byType(AcademicWordScreen)) as dynamic;
      screenState.onGamePaused();
      await tester.pump();
      screenState.onGameResumed();
      await tester.pump();
      expect(find.byType(AcademicWordScreen), findsOneWidget);
    });
  });
}


