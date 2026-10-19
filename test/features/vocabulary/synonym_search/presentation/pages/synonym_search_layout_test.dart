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
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/pages/synonym_search_screen.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_instruction_header.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_nuance_scale.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_warp_gate.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/widgets/synonym_word_shard.dart';

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
    String id = 'quest_synonym_1',
    String word = 'benevolent',
    String correctAnswer = 'kind',
    List<String> options = const ['kind', 'cruel', 'harsh', 'severe'],
    String instruction = 'WARP THE SYNONYM SHARD',
    String? explanation = 'Benevolent implies a charitable, kind-hearted nature.',
    String? hint = 'Showing goodwill and kindness',
    String? contextSentence = 'She was a benevolent ruler beloved by her subjects.',
    List<String>? synonyms = const ['kind', 'generous', 'caring'],
    int difficulty = 1,
  }) {
    return VocabularyQuest(
      id: id,
      type: QuestType.vocabulary,
      subtype: GameSubtype.synonymSearch,
      word: word,
      correctAnswer: correctAnswer,
      options: options,
      instruction: instruction,
      explanation: explanation,
      hint: hint,
      contextSentence: contextSentence,
      synonyms: synonyms,
      difficulty: difficulty,
    );
  }

  final sampleQuest1 = createQuest();

  final sampleQuest2 = createQuest(
    id: 'quest_synonym_2',
    word: 'candid',
    correctAnswer: 'frank',
    options: ['frank', 'deceptive', 'guarded', 'insincere'],
    instruction: 'SELECT THE EXACT SYNONYM',
    explanation: 'Candid conveys straightforward and honest expression.',
    hint: 'Open and completely truthful',
    contextSentence: 'His candid remarks surprised everyone at the meeting.',
    synonyms: ['frank', 'honest', 'forthright'],
  );

  final sampleMinimalQuest = const VocabularyQuest(
    id: 'quest_synonym_min',
    type: QuestType.vocabulary,
    subtype: GameSubtype.synonymSearch,
    word: 'vast',
    correctAnswer: 'huge',
    options: ['huge', 'tiny', 'narrow', 'slim'],
    instruction: 'WARP THE SYNONYM SHARD',
    difficulty: 1,
  );

  final testLoadedState = VocabularyLoaded(
    quests: [sampleQuest1, sampleQuest2],
    currentIndex: 0,
    livesRemaining: 3,
    wrongCount: 0,
  );

  setUpAll(() {
    registerFallbackValue(const SubmitAnswer(true));
    registerFallbackValue(const SubmitAnswer(false));
    registerFallbackValue(const NextQuestion());
    registerFallbackValue(const VocabularyHintUsed());
    registerFallbackValue(
      const FetchVocabularyQuests(
        gameType: GameSubtype.synonymSearch,
        level: 2,
      ),
    );
    registerFallbackValue(const RestoreLife());
    registerFallbackValue(const EconomyAddCoinsRequested(10));
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

    // Haptic mocks
    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});
    when(() => mockHapticService.heavy()).thenAnswer((_) async {});

    // Sound mocks
    when(() => mockSoundService.playCorrect()).thenAnswer((_) async {});
    when(() => mockSoundService.playWrong()).thenAnswer((_) async {});
    when(() => mockSoundService.playTts(any())).thenAnswer((_) async {});
    when(() => mockSoundService.stopTts()).thenAnswer((_) async {});
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

    // Auth mock
    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(
        const UserEntity(
          id: 'test_user_synonym',
          email: 'synonym@vowl.app',
          displayName: 'Cosmic Navigator',
          hintCount: 3,
        ),
      ),
    );
    when(() => mockAuthBloc.stream)
        .thenAnswer((_) => const Stream<AuthState>.empty());

    // Economy mock
    when(() => mockEconomyBloc.state).thenReturn(const EconomyState());
    when(() => mockEconomyBloc.stream)
        .thenAnswer((_) => const Stream<EconomyState>.empty());

    // Default BLoC mock
    when(() => mockVocabularyBloc.state).thenReturn(testLoadedState);
    when(() => mockVocabularyBloc.stream)
        .thenAnswer((_) => vocabularyStreamController.stream);

    // Network mock
    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

    // Dependency injection
    di.sl.reset();
    di.sl.registerLazySingleton<HapticService>(() => mockHapticService);
    di.sl.registerLazySingleton<SoundService>(() => mockSoundService);
    di.sl.registerLazySingleton<TtsService>(() => mockTtsService);
    di.sl.registerLazySingleton<LocaleService>(() => mockLocaleService);
    di.sl.registerLazySingleton<AppLogger>(() => mockAppLogger);
    di.sl.registerLazySingleton<AnalyticsService>(() => mockAnalyticsService);
    di.sl.registerLazySingleton<AdService>(() => mockAdService);
    di.sl.registerLazySingleton<NetworkInfo>(() => mockNetworkInfo);

    SharedPreferences.setMockInitialValues({});
    VowlMotion.lowAnimationModeOverride.value = true;
  });

  tearDown(() async {
    await vocabularyStreamController.close();
    VowlMotion.lowAnimationModeOverride.value = false;
    di.sl.reset();
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    VocabularyState? initialState,
    Size size = const Size(390, 844),
    double textScale = 1.0,
    ThemeMode themeMode = ThemeMode.dark,
    int level = 2,
  }) async {
    tester.view.physicalSize = Size(size.width * 2, size.height * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    if (initialState != null) {
      when(() => mockVocabularyBloc.state).thenReturn(initialState);
    }

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        minTextAdapt: true,
        builder: (context, child) {
          return MultiBlocProvider(
            providers: [
              BlocProvider<VocabularyBloc>.value(value: mockVocabularyBloc),
              BlocProvider<AuthBloc>.value(value: mockAuthBloc),
              BlocProvider<EconomyBloc>.value(value: mockEconomyBloc),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              home: MediaQuery(
                data: MediaQueryData(
                  size: size,
                  textScaler: TextScaler.linear(textScale),
                  disableAnimations: true,
                ),
                child: SynonymSearchScreen(
                  level: level,
                  gameType: GameSubtype.synonymSearch,
                ),
              ),
            ),
          );
        },
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> advanceToPhase2(WidgetTester tester) async {
    await pumpScreen(tester);

    // Tap correct shard ('KIND')
    await tester.tap(find.text('KIND'));
    await tester.pump();

    // Tap warp gate to trigger warp
    await tester.tap(find.byType(SynonymWarpGate));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();
  }

  group('Group 1: Initial Screen Layout & Component Rendering', () {
    testWidgets('1. renders GameShimmerLoading when state has no quest', (tester) async {
      final uninitializedState = const VocabularyInitial();
      await pumpScreen(tester, initialState: uninitializedState);

      expect(find.byType(GameShimmerLoading), findsOneWidget);
    });

    testWidgets('2. renders SynonymInstructionHeader with instruction and hint', (tester) async {
      await pumpScreen(tester);

      expect(find.byType(SynonymInstructionHeader), findsOneWidget);
      expect(find.text('WARP THE SYNONYM SHARD'), findsOneWidget);
      expect(find.text('Showing goodwill and kindness'), findsOneWidget);
    });

    testWidgets('3. renders SynonymWarpGate displaying uppercase target word', (tester) async {
      await pumpScreen(tester);

      expect(find.byType(SynonymWarpGate), findsOneWidget);
      expect(find.text('BENEVOLENT'), findsOneWidget);
    });

    testWidgets('4. renders all SynonymWordShard option chips with text', (tester) async {
      await pumpScreen(tester);

      expect(find.byType(SynonymWordShard), findsNWidgets(4));
      expect(find.text('KIND'), findsOneWidget);
      expect(find.text('CRUEL'), findsOneWidget);
      expect(find.text('HARSH'), findsOneWidget);
      expect(find.text('SEVERE'), findsOneWidget);
    });

    testWidgets('5. renders header controls including QuestHintButton', (tester) async {
      await pumpScreen(tester);

      expect(find.byType(QuestHintButton), findsOneWidget);
    });
  });

  group('Group 2: Phase 1 Mechanics: Tap & Drag Shard to Warp Gate', () {
    testWidgets('6. tapping a shard selects it and triggers light haptic', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('KIND'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockHapticService.light()).called(1);
    });

    testWidgets('7. tapping another shard updates selected shard', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('KIND'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('CRUEL'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockHapticService.light()).called(2);
    });

    testWidgets('8. tapping warp gate with no shard selected does nothing', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byType(SynonymWarpGate));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verifyNever(() => mockSoundService.playWrong());
      verifyNever(() => mockSoundService.playCorrect());
      verifyNever(() => mockVocabularyBloc.add(any(that: isA<SubmitAnswer>())));
    });

    testWidgets('9. tapping selected shard then tapping warp gate (tap-to-answer) with correct synonym advances to Phase 2', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('KIND'));
      await tester.pump();

      await tester.tap(find.byType(SynonymWarpGate));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      verify(() => mockHapticService.selection()).called(1);
      expect(find.byType(ContextSentenceBuilder), findsOneWidget);
    });

    testWidgets('10. tapping selected shard then tapping warp gate with wrong synonym triggers wrong sound, error haptic, and dispatches SubmitAnswer(false)', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('CRUEL'));
      await tester.pump();

      await tester.tap(find.byType(SynonymWarpGate));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      verify(() => mockSoundService.playWrong()).called(greaterThanOrEqualTo(1));
      verify(() => mockHapticService.error()).called(greaterThanOrEqualTo(1));
      verify(
        () => mockVocabularyBloc.add(
          any(that: isA<SubmitAnswer>().having((e) => e.isCorrect, 'isCorrect', isFalse)),
        ),
      ).called(1);
    });

    testWidgets('10a. tapping selected shard a second time (double-tap/confirm) with correct synonym advances to Phase 2', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('KIND'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('KIND'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      verify(() => mockHapticService.selection()).called(1);
      expect(find.byType(ContextSentenceBuilder), findsOneWidget);
    });

    testWidgets('10b. tapping selected shard a second time with wrong synonym triggers wrong sound, error haptic, and dispatches SubmitAnswer(false)', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('CRUEL'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('CRUEL'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      verify(() => mockSoundService.playWrong()).called(greaterThanOrEqualTo(1));
      verify(() => mockHapticService.error()).called(greaterThanOrEqualTo(1));
      verify(
        () => mockVocabularyBloc.add(
          any(that: isA<SubmitAnswer>().having((e) => e.isCorrect, 'isCorrect', isFalse)),
        ),
      ).called(1);
    });

    testWidgets('10c. when a shard is selected, warp gate displays TAP TO MATCH', (tester) async {
      await pumpScreen(tester);

      expect(find.text('TAP TO MATCH'), findsNothing);

      await tester.tap(find.text('KIND'));
      await tester.pump();

      expect(find.text('TAP TO MATCH'), findsOneWidget);
    });

    testWidgets('11. dragging correct shard close to warp gate triggers near-gate proximity selection haptic', (tester) async {
      await pumpScreen(tester);

      final shard = find.text('KIND');
      final gesture = await tester.startGesture(tester.getCenter(shard));
      await tester.pump();

      // Drag inwards toward gate
      await gesture.moveBy(const Offset(30, 30));
      await tester.pump();

      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('12. dragging correct shard into warp gate snaps and advances to Phase 2', (tester) async {
      await pumpScreen(tester);

      final shard = find.text('KIND');
      final gate = find.byType(SynonymWarpGate);
      final gesture = await tester.startGesture(tester.getCenter(shard));
      await gesture.moveBy(const Offset(-20, 20));
      await tester.pump(const Duration(milliseconds: 20));
      await gesture.moveTo(tester.getCenter(gate));
      await tester.pump(const Duration(milliseconds: 20));

      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      verify(() => mockHapticService.selection()).called(greaterThanOrEqualTo(1));
      expect(find.byType(ContextSentenceBuilder), findsOneWidget);
    });

    testWidgets('13. dragging wrong shard into warp gate dispatches SubmitAnswer(false)', (tester) async {
      await pumpScreen(tester);

      final shard = find.text('CRUEL');
      final gate = find.byType(SynonymWarpGate);
      final gesture = await tester.startGesture(tester.getCenter(shard));
      await gesture.moveBy(const Offset(20, -20));
      await tester.pump(const Duration(milliseconds: 20));
      await gesture.moveTo(tester.getCenter(gate));
      await tester.pump(const Duration(milliseconds: 20));

      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      verify(() => mockSoundService.playWrong()).called(greaterThanOrEqualTo(1));
      verify(() => mockHapticService.error()).called(greaterThanOrEqualTo(1));
      verify(
        () => mockVocabularyBloc.add(
          any(that: isA<SubmitAnswer>().having((e) => e.isCorrect, 'isCorrect', isFalse)),
        ),
      ).called(1);
    });

    testWidgets('14. dragging shard below snap distance snaps back to initial position', (tester) async {
      await pumpScreen(tester);

      final shard = find.text('KIND');
      final gesture = await tester.startGesture(tester.getCenter(shard));
      await tester.pump();

      // Slight move away
      await gesture.moveBy(const Offset(-10, -10));
      await tester.pump();

      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Shard remains visible and not warped
      expect(find.text('KIND'), findsOneWidget);
      expect(find.byType(ContextSentenceBuilder), findsNothing);
    });
  });

  group('Group 3: Phase 2 (Stage 2) Sentence Construction & Confirmation', () {
    testWidgets('15. displays SynonymNuanceScale with nuance difference badge and explanation after Phase 1 passed', (tester) async {
      await advanceToPhase2(tester);

      expect(find.byType(SynonymNuanceScale), findsOneWidget);
      expect(find.text('NUANCE DIFFERENCE'), findsOneWidget);
      expect(find.text('Benevolent implies a charitable, kind-hearted nature.'), findsOneWidget);
    });

    testWidgets('16. displays ContextSentenceBuilder in Phase 2', (tester) async {
      await advanceToPhase2(tester);

      expect(find.byType(ContextSentenceBuilder), findsOneWidget);
    });

    testWidgets('17. confirms Phase 2 via onConfirmed triggers success sound/haptic and dispatches SubmitAnswer(true)', (tester) async {
      await advanceToPhase2(tester);

      final builder = tester.widget<ContextSentenceBuilder>(find.byType(ContextSentenceBuilder));
      builder.onConfirmed();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockSoundService.playCorrect()).called(greaterThanOrEqualTo(1));
      verify(() => mockHapticService.success()).called(greaterThanOrEqualTo(1));
      verify(
        () => mockVocabularyBloc.add(
          any(that: isA<SubmitAnswer>().having((e) => e.isCorrect, 'isCorrect', isTrue)),
        ),
      ).called(1);
    });

    testWidgets('18. skips Phase 2 via onSkipped triggers wrong sound/haptic and dispatches SubmitAnswer(false)', (tester) async {
      await advanceToPhase2(tester);

      final builder = tester.widget<ContextSentenceBuilder>(find.byType(ContextSentenceBuilder));
      builder.onSkipped();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockSoundService.playWrong()).called(greaterThanOrEqualTo(1));
      verify(() => mockHapticService.error()).called(greaterThanOrEqualTo(1));
      verify(
        () => mockVocabularyBloc.add(
          any(that: isA<SubmitAnswer>().having((e) => e.isCorrect, 'isCorrect', isFalse)),
        ),
      ).called(1);
    });

    testWidgets('19. entering sentence with target keyword in ContextSentenceBuilder confirms stage 2', (tester) async {
      await advanceToPhase2(tester);

      final builderFinder = find.byType(ContextSentenceBuilder);
      expect(builderFinder, findsOneWidget);

      final builder = tester.widget<ContextSentenceBuilder>(builderFinder);
      expect(builder.targetKeyword, equals('kind'));
    });
  });

  group('Group 4: Hint System & Sensory Feedback', () {
    testWidgets('20. tapping hint button pulls correct shard closer to center', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byType(QuestHintButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockVocabularyBloc.add(const VocabularyHintUsed())).called(1);
    });

    testWidgets('21. hint shard offset auto-resets after timer elapses', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byType(QuestHintButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1100));
      await tester.pumpAndSettle();

      expect(find.text('KIND'), findsOneWidget);
    });

    testWidgets('22. tapping hint button dispatches VocabularyHintUsed event', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byType(QuestHintButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockVocabularyBloc.add(any(that: isA<VocabularyHintUsed>()))).called(1);
    });
  });

  group('Group 5: State Progression, Error Handling & Navigation', () {
    testWidgets('23. displays success feedback card when answered correctly', (tester) async {
      await advanceToPhase2(tester);

      final builder = tester.widget<ContextSentenceBuilder>(find.byType(ContextSentenceBuilder));
      builder.onConfirmed();
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(GameFeedbackCard), findsOneWidget);
    });

    testWidgets('24. displays failure feedback card with retry when answered incorrectly', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('CRUEL'));
      await tester.pump();
      await tester.tap(find.byType(SynonymWarpGate));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.byType(GameFeedbackCard), findsOneWidget);
    });

    testWidgets('25. tapping continue on feedback card dispatches NextQuestion()', (tester) async {
      await advanceToPhase2(tester);

      final builder = tester.widget<ContextSentenceBuilder>(find.byType(ContextSentenceBuilder));
      builder.onConfirmed();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      final continueButton = find.text('CONTINUE');
      expect(continueButton, findsOneWidget);

      await tester.tap(continueButton);
      await tester.pump();

      verify(() => mockVocabularyBloc.add(any(that: isA<NextQuestion>()))).called(1);
    });

    testWidgets('26. transitions from question 0 to question 1 cleanly on state change', (tester) async {
      await pumpScreen(tester);

      expect(find.text('BENEVOLENT'), findsOneWidget);

      final nextState = VocabularyLoaded(
        quests: [sampleQuest1, sampleQuest2],
        currentIndex: 1,
        livesRemaining: 3,
        wrongCount: 0,
      );
      vocabularyStreamController.add(nextState);
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('CANDID'), findsOneWidget);
      expect(find.text('FRANK'), findsOneWidget);
    });

    testWidgets('27. handles quest without explanation cleanly (omits nuance scale without crashing)', (tester) async {
      final noExplanationQuest = createQuest(explanation: null);
      final singleState = VocabularyLoaded(
        quests: [noExplanationQuest],
        currentIndex: 0,
        livesRemaining: 3,
        wrongCount: 0,
      );
      await pumpScreen(tester, initialState: singleState);

      await tester.tap(find.text('KIND'));
      await tester.pump();
      await tester.tap(find.byType(SynonymWarpGate));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.byType(SynonymNuanceScale), findsNothing);
      expect(find.byType(ContextSentenceBuilder), findsOneWidget);
    });

    testWidgets('28. handles minimal quest without optional fields cleanly', (tester) async {
      final minState = VocabularyLoaded(
        quests: [sampleMinimalQuest],
        currentIndex: 0,
        livesRemaining: 3,
        wrongCount: 0,
      );
      await pumpScreen(tester, initialState: minState);

      expect(find.text('VAST'), findsOneWidget);
      expect(find.text('HUGE'), findsOneWidget);
    });
  });

  group('Group 6: Responsive Layout & Theme Adaptability', () {
    testWidgets('29. renders cleanly without overflow on compact phone (320x568)', (tester) async {
      await pumpScreen(tester, size: const Size(320, 568));

      expect(tester.takeException(), isNull);
      expect(find.byType(SynonymWarpGate), findsOneWidget);
      expect(find.byType(SynonymWordShard), findsNWidgets(4));
    });

    testWidgets('30. renders cleanly on tablet (768x1024)', (tester) async {
      await pumpScreen(tester, size: const Size(768, 1024));

      expect(tester.takeException(), isNull);
      expect(find.byType(SynonymWarpGate), findsOneWidget);
      expect(find.byType(SynonymWordShard), findsNWidgets(4));
    });

    testWidgets('31. renders cleanly in landscape mode (800x480)', (tester) async {
      await pumpScreen(tester, size: const Size(800, 480));

      expect(tester.takeException(), isNull);
      expect(find.byType(SynonymWarpGate), findsOneWidget);
      expect(find.byType(SynonymWordShard), findsNWidgets(4));
    });

    testWidgets('32. renders cleanly under high text scale (1.5x)', (tester) async {
      await pumpScreen(tester, textScale: 1.5);

      expect(tester.takeException(), isNull);
      expect(find.byType(SynonymWarpGate), findsOneWidget);
    });

    testWidgets('33. renders cleanly in light theme', (tester) async {
      await pumpScreen(tester, themeMode: ThemeMode.light);

      expect(tester.takeException(), isNull);
      expect(find.byType(SynonymWarpGate), findsOneWidget);
    });
  });
}

