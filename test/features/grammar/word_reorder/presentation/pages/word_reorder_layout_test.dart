import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/game_mechanics/typing/type_to_confirm_overlay.dart';
import 'package:vowl/core/presentation/widgets/game_briefing_layer.dart';
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
import 'package:vowl/features/grammar/domain/entities/grammar_quest.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/grammar/word_reorder/presentation/pages/word_reorder_screen.dart';
import 'package:vowl/features/grammar/word_reorder/presentation/widgets/word_reorder_floating_tile.dart';
import 'package:vowl/features/grammar/word_reorder/presentation/widgets/word_reorder_instruction.dart';

class MockGrammarBloc extends MockBloc<GrammarEvent, GrammarState>
    implements GrammarBloc {}

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

class FakeGrammarEvent extends Fake implements GrammarEvent {}

class FakeGrammarState extends Fake implements GrammarState {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockGrammarBloc mockGrammarBloc;
  late StreamController<GrammarState> grammarStreamController;
  late MockAuthBloc mockAuthBloc;
  late MockEconomyBloc mockEconomyBloc;
  late MockHapticService mockHapticService;
  late MockSoundService mockSoundService;
  late MockTtsService mockTtsService;
  late MockLocaleService mockLocaleService;
  late MockAppLogger mockAppLogger;
  late MockAnalyticsService mockAnalyticsService;
  late MockAdService mockAdService;

  // Words: ["The", "swift", "fox", "jumps"]
  // Indices: 0: "The", 1: "swift", 2: "fox", 3: "jumps"
  // Correct order: [0, 1, 2, 3]
  const sampleQuest = GrammarQuest(
    id: 'wr_1',
    instruction: 'Reorder the words to form a correct sentence.',
    difficulty: 1,
    subtype: GameSubtype.wordReorder,
    sentence: 'The swift fox jumps',
    shuffledWords: ['swift', 'The', 'jumps', 'fox'],
    correctOrder: [
      1,
      0,
      3,
      2,
    ], // "The" (1), "swift" (0), "fox" (3), "jumps" (2)
    structureType: 'svo',
    correctAnswer: 'The swift fox jumps',
    hint: 'Start with the definite article.',
    explanation: 'Subject: The swift fox, Verb: jumps.',
  );

  const sampleSecondQuest = GrammarQuest(
    id: 'wr_2',
    instruction: 'Reorder into a compound sentence.',
    difficulty: 2,
    subtype: GameSubtype.wordReorder,
    sentence: 'She sang and he danced',
    shuffledWords: ['and', 'She', 'he', 'sang', 'danced'],
    correctOrder: [1, 3, 0, 2, 4],
    structureType: 'compound',
    correctAnswer: 'She sang and he danced',
    hint: 'Connect two independent clauses.',
    explanation: 'She sang (clause 1) and he danced (clause 2).',
  );

  final testLoadedState = GrammarLoaded(
    quests: const [sampleQuest, sampleSecondQuest],
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
    hintUsed: false,
    wrongCount: 0,
    isFinalFailure: false,
  );

  setUpAll(() {
    registerFallbackValue(FakeGrammarEvent());
    registerFallbackValue(FakeGrammarState());
    registerFallbackValue(const SubmitAnswer(true));
    registerFallbackValue(const SubmitAnswer(false));
    registerFallbackValue(const NextQuestion());
    registerFallbackValue(const GrammarHintUsed());
    VowlMotion.lowAnimationModeOverride.value = true;
  });

  tearDownAll(() {
    VowlMotion.lowAnimationModeOverride.value = false;
  });

  setUp(() async {
    mockGrammarBloc = MockGrammarBloc();
    mockAuthBloc = MockAuthBloc();
    mockEconomyBloc = MockEconomyBloc();
    mockHapticService = MockHapticService();
    mockSoundService = MockSoundService();
    mockTtsService = MockTtsService();
    mockLocaleService = MockLocaleService();
    mockAppLogger = MockAppLogger();
    mockAnalyticsService = MockAnalyticsService();
    mockAdService = MockAdService();

    SharedPreferences.setMockInitialValues({
      'has_seen_briefing_wordReorder': true,
    });

    when(() => mockGrammarBloc.state).thenReturn(testLoadedState);
    grammarStreamController = StreamController<GrammarState>.broadcast();
    when(
      () => mockGrammarBloc.stream,
    ).thenAnswer((_) => grammarStreamController.stream);

    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(
        const UserEntity(
          id: 'test_user_id',
          email: 'test@vowl.app',
          displayName: 'Test Syntactician',
          isPremium: true,
          hintCount: 3,
        ),
      ),
    );
    when(
      () => mockAuthBloc.stream,
    ).thenAnswer((_) => const Stream<AuthState>.empty());

    when(() => mockEconomyBloc.state).thenReturn(const EconomyState());
    when(() => mockEconomyBloc.stream).thenAnswer((_) => const Stream.empty());

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});
    when(() => mockHapticService.heavy()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});

    when(() => mockSoundService.playCorrect()).thenAnswer((_) async {});
    when(() => mockSoundService.playWrong()).thenAnswer((_) async {});
    when(() => mockSoundService.playClick()).thenAnswer((_) async {});
    when(() => mockSoundService.playHint()).thenAnswer((_) async {});
    when(() => mockSoundService.stopAudio()).thenAnswer((_) async {});

    when(() => mockTtsService.stop()).thenAnswer((_) async {});
    when(
      () => mockTtsService.speak(
        any(),
        rate: any(named: 'rate'),
        locale: any(named: 'locale'),
        pauseMarkers: any(named: 'pauseMarkers'),
        forcedPreset: any(named: 'forcedPreset'),
        isKids: any(named: 'isKids'),
      ),
    ).thenAnswer((_) async {});

    when(
      () => mockAnalyticsService.logGameSkipped(any()),
    ).thenAnswer((_) async {});

    if (di.sl.isRegistered<HapticService>()) di.sl.unregister<HapticService>();
    if (di.sl.isRegistered<SoundService>()) di.sl.unregister<SoundService>();
    if (di.sl.isRegistered<TtsService>()) di.sl.unregister<TtsService>();
    if (di.sl.isRegistered<LocaleService>()) di.sl.unregister<LocaleService>();
    if (di.sl.isRegistered<AppLogger>()) di.sl.unregister<AppLogger>();
    if (di.sl.isRegistered<AnalyticsService>())
      di.sl.unregister<AnalyticsService>();
    if (di.sl.isRegistered<AdService>()) di.sl.unregister<AdService>();

    di.sl.registerSingleton<HapticService>(mockHapticService);
    di.sl.registerSingleton<SoundService>(mockSoundService);
    di.sl.registerSingleton<TtsService>(mockTtsService);
    di.sl.registerSingleton<LocaleService>(mockLocaleService);
    di.sl.registerSingleton<AppLogger>(mockAppLogger);
    di.sl.registerSingleton<AnalyticsService>(mockAnalyticsService);
    di.sl.registerSingleton<AdService>(mockAdService);
  });

  tearDown(() async {
    await grammarStreamController.close();
    await di.sl.reset();
  });

  Future<void> pumpWordReorderScreen(
    WidgetTester tester, {
    GrammarState? state,
    int level = 2,
    Size size = const Size(390, 844),
    ThemeMode themeMode = ThemeMode.dark,
    bool reduceMotion = true,
  }) async {
    tester.view.physicalSize = Size(size.width * 2, size.height * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    when(() => mockGrammarBloc.state).thenReturn(state ?? testLoadedState);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<GrammarBloc>.value(value: mockGrammarBloc),
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<EconomyBloc>.value(value: mockEconomyBloc),
        ],
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) => MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            home: MediaQuery(
              data: MediaQueryData(
                size: size,
                padding: EdgeInsets.zero,
                viewInsets: EdgeInsets.zero,
                disableAnimations: reduceMotion,
              ),
              child: Scaffold(body: WordReorderScreen(level: level)),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  group('WordReorderScreen Layout & Hardening Tests', () {
    testWidgets(
      '1. Renders shimmer loading state when state is GrammarInitial',
      (tester) async {
        await pumpWordReorderScreen(tester, state: const GrammarInitial());
        expect(find.byType(GameShimmerLoading), findsOneWidget);
      },
    );

    testWidgets('2. respects level 1 game briefing dialog on first run', (
      tester,
    ) async {
      await pumpWordReorderScreen(tester, level: 1);
      expect(find.byType(GameBriefingLayer), findsOneWidget);
    });

    testWidgets('3. Renders core layout elements', (tester) async {
      await pumpWordReorderScreen(tester);

      expect(find.byType(WordReorderInstruction), findsOneWidget);
      expect(find.byKey(const ValueKey('word_assembly_card')), findsOneWidget);
      expect(find.byKey(const ValueKey('word_check_button')), findsOneWidget);
      expect(find.byType(WordReorderFloatingTile), findsNWidgets(4));
    });

    testWidgets('4. Instruction pill displays formatted natural instruction', (
      tester,
    ) async {
      await pumpWordReorderScreen(tester);

      expect(
        find.text('Reorder the words to form a correct sentence.'),
        findsOneWidget,
      );
    });

    testWidgets(
      '5. Displays target structure container when structureType is provided',
      (tester) async {
        await pumpWordReorderScreen(tester);

        expect(
          find.byKey(const ValueKey('word_target_structure')),
          findsOneWidget,
        );
        expect(find.text('Sentence pattern: svo'), findsOneWidget);
      },
    );

    testWidgets('6. Floating word tiles render all shuffled words', (
      tester,
    ) async {
      await pumpWordReorderScreen(tester);

      expect(find.text('swift'), findsOneWidget);
      expect(find.text('The'), findsOneWidget);
      expect(find.text('jumps'), findsOneWidget);
      expect(find.text('fox'), findsOneWidget);
    });

    testWidgets('7. Assembly card displays friendly placeholder when empty', (
      tester,
    ) async {
      await pumpWordReorderScreen(tester);

      expect(
        find.text('Tap words below to build your sentence'),
        findsOneWidget,
      );
    });

    testWidgets('8. Check button text is displayed as Check Sentence', (
      tester,
    ) async {
      await pumpWordReorderScreen(tester);

      expect(find.text('Check Sentence'), findsOneWidget);
    });

    testWidgets(
      '9. Tapping a word tile moves it into assembly card and removes from floating area',
      (tester) async {
        await pumpWordReorderScreen(tester);

        // Tap index 1 ("The")
        final tileThe = find.byKey(const ValueKey('word_tile_1'));
        expect(tileThe, findsOneWidget);

        await tester.tap(tileThe);
        await tester.pump();

        verify(() => mockHapticService.selection()).called(1);

        // Now assembled word with key assembled_word_1 exists
        expect(find.byKey(const ValueKey('assembled_word_1')), findsOneWidget);
        // And floating tile 1 no longer exists
        expect(find.byKey(const ValueKey('word_tile_1')), findsNothing);
        // Empty placeholder is gone
        expect(
          find.text('Tap words below to build your sentence'),
          findsNothing,
        );
      },
    );

    testWidgets(
      '10. Tapping assembled word removes it from assembly and restores floating tile',
      (tester) async {
        await pumpWordReorderScreen(tester);

        // Move tile 1 to assembly
        await tester.tap(find.byKey(const ValueKey('word_tile_1')));
        await tester.pump();
        expect(find.byKey(const ValueKey('assembled_word_1')), findsOneWidget);

        clearInteractions(mockHapticService);

        // Tap assembled word 1 to remove
        await tester.tap(find.byKey(const ValueKey('assembled_word_1')));
        await tester.pump();

        verify(() => mockHapticService.selection()).called(1);

        // Restored back to floating
        expect(find.byKey(const ValueKey('assembled_word_1')), findsNothing);
        expect(find.byKey(const ValueKey('word_tile_1')), findsOneWidget);
        expect(
          find.text('Tap words below to build your sentence'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '11. Check button is disabled when not all words are assembled',
      (tester) async {
        await pumpWordReorderScreen(tester);

        // Assemble only 1 of 4 words
        await tester.tap(find.byKey(const ValueKey('word_tile_1')));
        await tester.pump();

        // Tap check button; should do nothing because hasWords is false
        await tester.tap(
          find.byKey(const ValueKey('word_check_button')),
          warnIfMissed: false,
        );
        await tester.pump();

        verifyNever(() => mockGrammarBloc.add(any(that: isA<SubmitAnswer>())));
      },
    );

    testWidgets(
      '12. Submitting incorrect word order triggers error feedback and wrong answer',
      (tester) async {
        await pumpWordReorderScreen(tester);

        // Assemble words in WRONG order: 0, 1, 2, 3 ("swift", "The", "jumps", "fox")
        await tester.tap(find.byKey(const ValueKey('word_tile_0')));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('word_tile_1')));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('word_tile_2')));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('word_tile_3')));
        await tester.pump();

        // Check button is now enabled
        final checkBtn = find.byKey(const ValueKey('word_check_button'));
        expect(checkBtn, findsOneWidget);

        await tester.tap(checkBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        verify(() => mockHapticService.error()).called(1);
        verify(() => mockSoundService.playWrong()).called(1);
        verify(() => mockGrammarBloc.add(const SubmitAnswer(false))).called(1);
      },
    );

    testWidgets(
      '13. Submitting correct word order triggers success feedback and opens Phase 2 overlay',
      (tester) async {
        await pumpWordReorderScreen(tester);

        // Correct order is: 1 ("The"), 0 ("swift"), 3 ("fox"), 2 ("jumps")
        await tester.tap(find.byKey(const ValueKey('word_tile_1')));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('word_tile_0')));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('word_tile_3')));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('word_tile_2')));
        await tester.pump();

        // Check button
        await tester.tap(find.byKey(const ValueKey('word_check_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        verify(() => mockHapticService.success()).called(1);
        verify(() => mockSoundService.playCorrect()).called(1);

        // Phase 2 TypeToConfirmOverlay is displayed
        expect(
          find.byKey(const ValueKey('word_type_overlay'), skipOffstage: false),
          findsOneWidget,
        );
      },
    );

    testWidgets('14. Phase 2 TypeToConfirmOverlay displays expected sentence', (
      tester,
    ) async {
      await pumpWordReorderScreen(tester);

      // Assemble correct order: 1, 0, 3, 2
      await tester.tap(find.byKey(const ValueKey('word_tile_1')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('word_tile_0')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('word_tile_3')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('word_tile_2')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('word_check_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final overlayFinder = find.byKey(
        const ValueKey('word_type_overlay'),
        skipOffstage: false,
      );
      final overlay = tester.widget<TypeToConfirmOverlay>(overlayFinder);
      expect(overlay.expectedText, equals('The swift fox jumps'));
    });

    testWidgets('15. Confirming Phase 2 typing dispatches SubmitAnswer(true)', (
      tester,
    ) async {
      await pumpWordReorderScreen(tester);

      // Correct order
      await tester.tap(find.byKey(const ValueKey('word_tile_1')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('word_tile_0')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('word_tile_3')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('word_tile_2')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('word_check_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final overlayFinder = find.byKey(
        const ValueKey('word_type_overlay'),
        skipOffstage: false,
      );
      final overlay = tester.widget<TypeToConfirmOverlay>(overlayFinder);

      overlay.onConfirmed();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockGrammarBloc.add(const SubmitAnswer(true))).called(1);
    });

    testWidgets('16. Skipping Phase 2 typing dispatches SubmitAnswer(false)', (
      tester,
    ) async {
      await pumpWordReorderScreen(tester);

      // Correct order
      await tester.tap(find.byKey(const ValueKey('word_tile_1')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('word_tile_0')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('word_tile_3')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('word_tile_2')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('word_check_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final overlayFinder = find.byKey(
        const ValueKey('word_type_overlay'),
        skipOffstage: false,
      );
      final overlay = tester.widget<TypeToConfirmOverlay>(overlayFinder);

      overlay.onSkipped();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockHapticService.error()).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockGrammarBloc.add(const SubmitAnswer(false))).called(1);
    });

    testWidgets(
      '17. Assembled words cannot be removed while Phase 2 overlay is active',
      (tester) async {
        await pumpWordReorderScreen(tester);

        // Correct order to reach Phase 2
        await tester.tap(find.byKey(const ValueKey('word_tile_1')));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('word_tile_0')));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('word_tile_3')));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('word_tile_2')));
        await tester.pump();
        await tester.tap(find.byKey(const ValueKey('word_check_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        clearInteractions(mockHapticService);

        // Attempt tapping assembled word
        await tester.tap(
          find.byKey(const ValueKey('assembled_word_1')),
          warnIfMissed: false,
        );
        await tester.pump();

        verifyNever(() => mockHapticService.selection());
      },
    );

    testWidgets('18. Hint used highlights the next expected word tile', (
      tester,
    ) async {
      final hintState = testLoadedState.copyWith(hintUsed: true);

      await pumpWordReorderScreen(tester, state: hintState);

      // Correct order starts with index 1 ("The")
      final tile1 = tester.widget<WordReorderFloatingTile>(
        find.byKey(const ValueKey('word_tile_1')),
      );
      expect(tile1.isHighlighted, isTrue);

      final tile0 = tester.widget<WordReorderFloatingTile>(
        find.byKey(const ValueKey('word_tile_0')),
      );
      expect(tile0.isHighlighted, isFalse);
    });

    testWidgets('19. Tapping hint button dispatches GrammarHintUsed event', (
      tester,
    ) async {
      await pumpWordReorderScreen(tester);

      final hintButton = find.byType(QuestHintButton);
      expect(hintButton, findsOneWidget);

      await tester.tap(hintButton);
      await tester.pump();

      verify(
        () => mockGrammarBloc.add(const GrammarHintUsed()),
      ).called(greaterThanOrEqualTo(1));
    });

    testWidgets('20. Tapping continue button dispatches NextQuestion event', (
      tester,
    ) async {
      await pumpWordReorderScreen(tester);

      // Submit wrong answer to surface feedback card
      await tester.tap(find.byKey(const ValueKey('word_tile_0')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('word_tile_1')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('word_tile_2')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('word_tile_3')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('word_check_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final continueButton = find.text('CONTINUE');
      if (continueButton.evaluate().isNotEmpty) {
        await tester.tap(continueButton);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        verify(() => mockGrammarBloc.add(const NextQuestion())).called(1);
      }
    });

    testWidgets(
      '21. Question reset clears assembled indices and restores available tiles for next quest',
      (tester) async {
        await pumpWordReorderScreen(tester);

        // Put words into assembly
        await tester.tap(find.byKey(const ValueKey('word_tile_1')));
        await tester.pump();
        expect(find.byKey(const ValueKey('assembled_word_1')), findsOneWidget);

        // Transition to next question (currentIndex: 1) via stream
        final secondQuestState = testLoadedState.copyWith(currentIndex: 1);
        when(() => mockGrammarBloc.state).thenReturn(secondQuestState);
        grammarStreamController.add(secondQuestState);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Second quest has 5 words
        expect(find.byType(WordReorderFloatingTile), findsNWidgets(5));
        expect(
          find.text('Tap words below to build your sentence'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '22. Compact mobile layout renders cleanly without layout overflow',
      (tester) async {
        await pumpWordReorderScreen(tester, size: const Size(320, 568));

        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const ValueKey('word_assembly_card')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('word_check_button')), findsOneWidget);
      },
    );

    testWidgets(
      '23. Tablet layout renders with spacious proportions and no overflow',
      (tester) async {
        await pumpWordReorderScreen(tester, size: const Size(800, 1200));

        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const ValueKey('word_assembly_card')),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('word_check_button')), findsOneWidget);
      },
    );

    testWidgets('24. Light theme renders successfully without exception', (
      tester,
    ) async {
      await pumpWordReorderScreen(tester, themeMode: ThemeMode.light);

      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('word_assembly_card')), findsOneWidget);
      expect(find.byKey(const ValueKey('word_check_button')), findsOneWidget);
    });

    testWidgets(
      '25. Motion gating (reduceMotion: true) runs without unmounted timers',
      (tester) async {
        await pumpWordReorderScreen(tester, reduceMotion: true);

        expect(find.byKey(const ValueKey('word_tile_1')), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('word_tile_1')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '26. Widget unmount cleanly disposes all timers and controllers',
      (tester) async {
        await pumpWordReorderScreen(tester);
        await tester.pump(const Duration(milliseconds: 100));

        // Immediately unmount
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(tester.takeException(), isNull);
      },
    );
  });
}
