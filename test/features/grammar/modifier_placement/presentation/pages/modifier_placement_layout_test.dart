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
import 'package:vowl/features/grammar/modifier_placement/presentation/pages/modifier_placement_screen.dart';
import 'package:vowl/features/grammar/modifier_placement/presentation/widgets/modifier_magnetic_arena.dart';
import 'package:vowl/features/grammar/modifier_placement/presentation/widgets/modifier_placement_instruction.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';

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
  late MockAuthBloc mockAuthBloc;
  late MockEconomyBloc mockEconomyBloc;
  late MockHapticService mockHapticService;
  late MockSoundService mockSoundService;
  late MockTtsService mockTtsService;
  late MockLocaleService mockLocaleService;
  late MockAppLogger mockLogger;
  late MockAnalyticsService mockAnalyticsService;
  late MockAdService mockAdService;

  setUpAll(() {
    registerFallbackValue(FakeGrammarEvent());
    registerFallbackValue(FakeGrammarState());
    registerFallbackValue(const SubmitAnswer(true));
    registerFallbackValue(const SubmitAnswer(false));
    registerFallbackValue(const NextQuestion());
    registerFallbackValue(const GrammarHintUsed());
    registerFallbackValue(const Duration(milliseconds: 50));
  });

  const testQuest1 = GrammarQuest(
    id: 'mp_l1_q1',
    instruction: 'PLACE THE MODIFIER',
    difficulty: 1,
    subtype: GameSubtype.modifierPlacement,
    sentence: "Insert the modifier 'red' into the correct position.",
    correctAnswer: 'She picked a red apple from the basket.',
    shuffledWords: [
      'basket.',
      'picked',
      'a',
      'She',
      'red',
      'from',
      'apple',
      'the',
    ],
    modifierType: 'Adjective',
    grammarRule: 'Adjective Placement (Attributive)',
    ruleExplanation: 'Use adjectives directly before the noun.',
  );

  const testQuestNoRules = GrammarQuest(
    id: 'mp_l1_q2',
    instruction: 'INSERT THE MODIFIER',
    difficulty: 1,
    subtype: GameSubtype.modifierPlacement,
    sentence: "Insert the modifier 'quickly' into the correct position.",
    correctAnswer: 'The rabbit ran quickly into the burrow.',
    shuffledWords: [
      'burrow.',
      'ran',
      'The',
      'quickly',
      'into',
      'rabbit',
      'the',
    ],
  );

  const testQuestExplanationOnly = GrammarQuest(
    id: 'mp_l1_q3',
    instruction: 'POSITION THE ADVERB',
    difficulty: 1,
    subtype: GameSubtype.modifierPlacement,
    sentence: "Insert the modifier 'quietly' into the correct position.",
    correctAnswer: 'He quietly closed the door.',
    shuffledWords: ['door.', 'closed', 'He', 'quietly', 'the'],
    modifierType: 'Adverb',
    ruleExplanation: 'Adverbs often sit right before the action verb.',
  );

  final testLoadedState = GrammarLoaded(
    quests: const [testQuest1, testQuestNoRules, testQuestExplanationOnly],
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
    hintUsed: false,
    wrongCount: 0,
    isFinalFailure: false,
  );

  setUp(() async {
    mockGrammarBloc = MockGrammarBloc();
    mockAuthBloc = MockAuthBloc();
    mockEconomyBloc = MockEconomyBloc();
    mockHapticService = MockHapticService();
    mockSoundService = MockSoundService();
    mockTtsService = MockTtsService();
    mockLocaleService = MockLocaleService();
    mockLogger = MockAppLogger();
    mockAnalyticsService = MockAnalyticsService();
    mockAdService = MockAdService();

    VowlMotion.lowAnimationModeOverride.value = true;

    SharedPreferences.setMockInitialValues({
      'has_seen_briefing_modifierPlacement': true,
    });

    when(
      () => mockLocaleService.tr(
        any(),
        fallback: any(named: 'fallback'),
        args: any(named: 'args'),
      ),
    ).thenAnswer(
      (inv) =>
          inv.namedArguments[#fallback] as String? ??
          inv.positionalArguments.first as String,
    );

    when(() => mockLocaleService.currentLocale).thenReturn(const Locale('en'));

    when(() => mockGrammarBloc.state).thenReturn(testLoadedState);
    when(
      () => mockGrammarBloc.stream,
    ).thenAnswer((_) => const Stream<GrammarState>.empty());

    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(
        const UserEntity(
          id: 'test_user_id',
          email: 'test@vowl.app',
          displayName: 'Test Grammarian',
          hintCount: 3,
        ),
      ),
    );
    when(
      () => mockAuthBloc.stream,
    ).thenAnswer((_) => const Stream<AuthState>.empty());

    when(() => mockEconomyBloc.state).thenReturn(const EconomyState());
    when(
      () => mockEconomyBloc.stream,
    ).thenAnswer((_) => const Stream<EconomyState>.empty());

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});
    when(() => mockHapticService.heavy()).thenAnswer((_) async {});
    when(() => mockHapticService.warning()).thenAnswer((_) async {});

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

    await di.sl.reset();

    di.sl.registerSingleton<HapticService>(mockHapticService);
    di.sl.registerSingleton<SoundService>(mockSoundService);
    di.sl.registerSingleton<TtsService>(mockTtsService);
    di.sl.registerSingleton<LocaleService>(mockLocaleService);
    di.sl.registerSingleton<AppLogger>(mockLogger);
    di.sl.registerSingleton<AnalyticsService>(mockAnalyticsService);
    di.sl.registerSingleton<AdService>(mockAdService);
  });

  tearDown(() async {
    VowlMotion.lowAnimationModeOverride.value = false;
    await di.sl.reset();
  });

  Future<void> pumpModifierPlacement(
    WidgetTester tester, {
    GrammarState? state,
    int level = 2,
    ThemeMode themeMode = ThemeMode.light,
    double width = 390,
    double height = 844,
  }) async {
    if (state != null) {
      when(() => mockGrammarBloc.state).thenReturn(state);
    }

    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

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
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            home: ModifierPlacementScreen(
              level: level,
              gameType: GameSubtype.modifierPlacement,
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  group('ModifierPlacementScreen Layout & Mechanics', () {
    testWidgets(
      '1. renders initial quest with instruction, modifier type chip, grammar rule box, context card, arena with empty slots, and draggable modifier magnet',
      (tester) async {
        await pumpModifierPlacement(tester);

        expect(find.byType(ModifierPlacementInstruction), findsOneWidget);
        expect(find.text('Place the modifier'), findsOneWidget);

        expect(find.byKey(const ValueKey('grammar_rule_box')), findsOneWidget);
        expect(find.text('Grammar Rule'), findsOneWidget);
        expect(find.text('Adjective Placement (Attributive)'), findsOneWidget);

        expect(
          find.byKey(const ValueKey('modifier_type_chip')),
          findsOneWidget,
        );
        expect(find.text('Modifier: Adjective'), findsOneWidget);

        expect(
          find.byKey(const ValueKey('modifier_context_card')),
          findsOneWidget,
        );
        expect(find.byType(ModifierMagneticArena), findsOneWidget);
        expect(
          find.byKey(const ValueKey('modifier_magnetic_arena')),
          findsOneWidget,
        );

        expect(
          find.byKey(const ValueKey('draggable_modifier_magnet')),
          findsOneWidget,
        );
        expect(find.text('red'), findsWidgets);
        expect(
          find.byKey(const ValueKey('finalize_syntax_button')),
          findsNothing,
        );
      },
    );

    testWidgets(
      '2. hides grammar rule box when quest has neither grammarRule nor ruleExplanation',
      (tester) async {
        final stateWithoutRule = GrammarLoaded(
          quests: const [testQuestNoRules],
          currentIndex: 0,
          livesRemaining: 3,
          answerStatus: AnswerStatus.unanswered,
          hintUsed: false,
          wrongCount: 0,
          isFinalFailure: false,
        );

        await pumpModifierPlacement(tester, state: stateWithoutRule);

        expect(find.byKey(const ValueKey('grammar_rule_box')), findsNothing);
        expect(find.byKey(const ValueKey('modifier_type_chip')), findsNothing);
        expect(
          find.byKey(const ValueKey('modifier_context_card')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '3. renders grammar rule box when ruleExplanation is present instead of grammarRule',
      (tester) async {
        final stateWithExplanation = GrammarLoaded(
          quests: const [testQuestExplanationOnly],
          currentIndex: 0,
          livesRemaining: 3,
          answerStatus: AnswerStatus.unanswered,
          hintUsed: false,
          wrongCount: 0,
          isFinalFailure: false,
        );

        await pumpModifierPlacement(tester, state: stateWithExplanation);

        expect(find.byKey(const ValueKey('grammar_rule_box')), findsOneWidget);
        expect(
          find.text('Adverbs often sit right before the action verb.'),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('modifier_type_chip')),
          findsOneWidget,
        );
        expect(find.text('Modifier: Adverb'), findsOneWidget);
      },
    );

    testWidgets('4. renders shimmer loading when state is GrammarLoading', (
      tester,
    ) async {
      await pumpModifierPlacement(tester, state: const GrammarLoading());

      expect(find.byType(GameShimmerLoading), findsOneWidget);
      expect(
        find.byKey(const ValueKey('modifier_magnetic_arena')),
        findsNothing,
      );
    });

    testWidgets(
      '5. dragging modifier magnet onto slot drops modifier and displays finalize syntax button',
      (tester) async {
        await pumpModifierPlacement(tester);

        final magnetFinder = find.byKey(
          const ValueKey('draggable_modifier_magnet'),
        );
        expect(magnetFinder, findsOneWidget);

        final slot3 = find.byKey(const ValueKey('modifier_slot_3'));
        expect(slot3, findsOneWidget);

        // Drag magnet to slot 3
        final magnetCenter = tester.getCenter(magnetFinder);
        final slotCenter = tester.getCenter(slot3);
        final gesture = await tester.startGesture(magnetCenter);
        await tester.pump();
        await gesture.moveTo(slotCenter);
        await tester.pump();
        await gesture.up();
        await tester.pump(const Duration(milliseconds: 300));

        verify(() => mockHapticService.selection()).called(1);
        expect(
          find.byKey(const ValueKey('modifier_occupied_chip_3')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('finalize_syntax_button')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '6. tapping empty slot directly drops modifier and displays finalize syntax button',
      (tester) async {
        await pumpModifierPlacement(tester);

        final slot3 = find.byKey(const ValueKey('modifier_slot_3'));
        expect(slot3, findsOneWidget);

        await tester.tap(slot3);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        verify(() => mockHapticService.selection()).called(1);
        expect(
          find.byKey(const ValueKey('modifier_occupied_chip_3')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('finalize_syntax_button')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '7. tapping occupied modifier chip resets slot back to empty and reveals draggable magnet',
      (tester) async {
        await pumpModifierPlacement(tester);

        // First place modifier into slot 3
        final slot3 = find.byKey(const ValueKey('modifier_slot_3'));
        await tester.tap(slot3);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final occupiedChip = find.byKey(
          const ValueKey('modifier_occupied_chip_3'),
        );
        expect(occupiedChip, findsOneWidget);

        // Tap occupied chip to reset
        await tester.tap(occupiedChip);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        verify(() => mockHapticService.selection()).called(2);
        expect(
          find.byKey(const ValueKey('modifier_occupied_chip_3')),
          findsNothing,
        );
        expect(
          find.byKey(const ValueKey('draggable_modifier_magnet')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('finalize_syntax_button')),
          findsNothing,
        );
      },
    );

    testWidgets(
      '8. submitting incorrect slot placement triggers wrong answer feedback',
      (tester) async {
        await pumpModifierPlacement(tester);

        // Place into slot 0 (incorrect position: "red She picked a apple...")
        final slot0 = find.byKey(const ValueKey('modifier_slot_0'));
        await tester.tap(slot0);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final finalizeBtn = find.byKey(
          const ValueKey('finalize_syntax_button'),
        );
        expect(finalizeBtn, findsOneWidget);
        await tester.tap(finalizeBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        verify(() => mockHapticService.error()).called(1);
        verify(() => mockSoundService.playWrong()).called(1);

        verify(
          () => mockGrammarBloc.add(
            any(
              that: isA<SubmitAnswer>().having(
                (e) => e.isCorrect,
                'isCorrect',
                false,
              ),
            ),
          ),
        ).called(1);
      },
    );

    testWidgets(
      '9. submitting correct slot placement opens Phase 2 TypeToConfirmOverlay with success audio/haptics',
      (tester) async {
        await pumpModifierPlacement(tester);

        // Place into slot 3 (correct position: "She picked a red apple...")
        final slot3 = find.byKey(const ValueKey('modifier_slot_3'));
        await tester.tap(slot3);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final finalizeBtn = find.byKey(
          const ValueKey('finalize_syntax_button'),
        );
        expect(finalizeBtn, findsOneWidget);
        await tester.tap(finalizeBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        verify(() => mockHapticService.success()).called(1);
        verify(() => mockSoundService.playCorrect()).called(1);

        expect(
          find.byType(TypeToConfirmOverlay, skipOffstage: false),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '10. Phase 2: typing full sentence in TypeToConfirmOverlay confirms and submits correct answer',
      (tester) async {
        await pumpModifierPlacement(tester);

        // Select correct slot 3
        final slot3 = find.byKey(const ValueKey('modifier_slot_3'));
        await tester.tap(slot3);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final finalizeBtn = find.byKey(
          const ValueKey('finalize_syntax_button'),
        );
        await tester.tap(finalizeBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 500));

        final textFieldFinder = find.byType(TextField);
        await tester.ensureVisible(textFieldFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        expect(textFieldFinder, findsOneWidget);

        await tester.enterText(
          textFieldFinder,
          'She picked a red apple from the basket.',
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        final submitBtn = find.text('SUBMIT');
        await tester.ensureVisible(submitBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        expect(submitBtn, findsOneWidget);

        await tester.tap(submitBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1000));
        await tester.pump(const Duration(milliseconds: 500));

        verify(
          () => mockGrammarBloc.add(
            any(
              that: isA<SubmitAnswer>().having(
                (e) => e.isCorrect,
                'isCorrect',
                true,
              ),
            ),
          ),
        ).called(1);
      },
    );

    testWidgets(
      '11. Phase 2: skipping confirm (after 3 failed attempts) dispatches wrong answer',
      (tester) async {
        await pumpModifierPlacement(tester);

        // Select correct slot 3
        final slot3 = find.byKey(const ValueKey('modifier_slot_3'));
        await tester.tap(slot3);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final finalizeBtn = find.byKey(
          const ValueKey('finalize_syntax_button'),
        );
        await tester.tap(finalizeBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 500));

        final textFieldFinder = find.byType(TextField);
        await tester.ensureVisible(textFieldFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        await tester.enterText(textFieldFinder, 'Wrong typed sentence');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        final submitBtn = find.text('SUBMIT');
        await tester.ensureVisible(submitBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Attempt 1 (ScaleButton 500ms debounce guard)
        await tester.tap(submitBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        // Attempt 2
        await tester.tap(submitBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        // Attempt 3
        await tester.tap(submitBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        final continueBtn = find.text('CONTINUE').last;
        await tester.ensureVisible(continueBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        expect(continueBtn, findsOneWidget);

        await tester.tap(continueBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        verify(
          () => mockGrammarBloc.add(
            any(
              that: isA<SubmitAnswer>().having(
                (e) => e.isCorrect,
                'isCorrect',
                false,
              ),
            ),
          ),
        ).called(1);
      },
    );

    testWidgets(
      '12. finalize syntax button is hidden when question is already answered',
      (tester) async {
        final answeredState = GrammarLoaded(
          quests: const [testQuest1],
          currentIndex: 0,
          livesRemaining: 3,
          answerStatus: AnswerStatus.correct,
          hintUsed: false,
          wrongCount: 0,
          isFinalFailure: false,
        );

        await pumpModifierPlacement(tester, state: answeredState);

        expect(
          find.byKey(const ValueKey('finalize_syntax_button')),
          findsNothing,
        );
      },
    );

    testWidgets('13. hint button triggers hint without double dispatch', (
      tester,
    ) async {
      await pumpModifierPlacement(tester);

      final hintFinder = find.byType(QuestHintButton);
      expect(hintFinder, findsOneWidget);

      await tester.tap(hintFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      verify(
        () => mockGrammarBloc.add(any(that: isA<GrammarHintUsed>())),
      ).called(1);
    });

    testWidgets('14. level 1 briefing dialog displays for first-time user', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'has_seen_briefing_modifierPlacement': false,
      });

      await pumpModifierPlacement(tester, level: 1);

      expect(find.byType(GameBriefingLayer), findsOneWidget);
    });

    testWidgets(
      '15. respects reduced motion when lowAnimationModeOverride is enabled',
      (tester) async {
        VowlMotion.lowAnimationModeOverride.value = true;
        await pumpModifierPlacement(tester);

        expect(find.byType(ModifierPlacementScreen), findsOneWidget);
        expect(
          find.byKey(const ValueKey('modifier_magnetic_arena')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('16. compact viewport (320x568) renders without overflow', (
      tester,
    ) async {
      await pumpModifierPlacement(tester, width: 320, height: 568);

      expect(find.byType(ModifierPlacementScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('17. tablet viewport (768x1024) renders with proper layout', (
      tester,
    ) async {
      await pumpModifierPlacement(tester, width: 768, height: 1024);

      expect(find.byType(ModifierPlacementScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('18. dark mode renders correctly with dark theme styling', (
      tester,
    ) async {
      await pumpModifierPlacement(tester, themeMode: ThemeMode.dark);

      expect(find.byType(ModifierPlacementScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('19. final failure state displays game over layout', (
      tester,
    ) async {
      final failedState = GrammarLoaded(
        quests: const [testQuest1],
        currentIndex: 0,
        livesRemaining: 0,
        answerStatus: AnswerStatus.incorrect,
        hintUsed: false,
        wrongCount: 3,
        isFinalFailure: true,
      );

      await pumpModifierPlacement(tester, state: failedState);

      expect(find.byType(ModifierPlacementScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      '20. renders Confirm Placement action button with standard text without buzzwords',
      (tester) async {
        await pumpModifierPlacement(tester);

        final slot3 = find.byKey(const ValueKey('modifier_slot_3'));
        await tester.tap(slot3);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final confirmBtn = find.text('Confirm Placement');
        expect(confirmBtn, findsOneWidget);
        expect(find.text('FINALIZE SYNTAX'), findsNothing);
      },
    );

    testWidgets(
      '21. instruction centers text properly and does not truncate with ellipses',
      (tester) async {
        const longInstructionQuest = GrammarQuest(
          id: 'mp_long_instruction',
          instruction:
              'Place the descriptive adjective into its natural grammatical position',
          difficulty: 1,
          subtype: GameSubtype.modifierPlacement,
          sentence: "Insert the modifier 'red' into the correct position.",
          correctAnswer: 'She picked a red apple from the basket.',
          shuffledWords: [
            'basket.',
            'picked',
            'a',
            'She',
            'red',
            'from',
            'apple',
            'the',
          ],
        );
        final longState = GrammarLoaded(
          quests: const [longInstructionQuest],
          currentIndex: 0,
          livesRemaining: 3,
          answerStatus: AnswerStatus.unanswered,
          hintUsed: false,
          wrongCount: 0,
          isFinalFailure: false,
        );

        await pumpModifierPlacement(tester, state: longState);
        final textFinder = find.byKey(
          const ValueKey('modifier_placement_instruction_text'),
        );
        expect(textFinder, findsOneWidget);

        final textWidget = tester.widget<Text>(textFinder);
        expect(textWidget.textAlign, equals(TextAlign.center));
        expect(textWidget.overflow, isNot(equals(TextOverflow.ellipsis)));
      },
    );

    testWidgets(
      '22. TypeToConfirmOverlay has standard horizontal padding and does not touch screen edges',
      (tester) async {
        await pumpModifierPlacement(tester);

        // Place into slot 3 and confirm
        final slot3 = find.byKey(const ValueKey('modifier_slot_3'));
        await tester.tap(slot3);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final finalizeBtn = find.byKey(
          const ValueKey('finalize_syntax_button'),
        );
        await tester.tap(finalizeBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        final overlayFinder = find.byKey(
          const ValueKey('modifier_type_overlay'),
          skipOffstage: false,
        );
        expect(overlayFinder, findsOneWidget);

        final paddingFinder = find.ancestor(
          of: overlayFinder,
          matching: find.byType(Padding),
        );
        expect(paddingFinder, findsWidgets);

        final directPadding = tester.widget<Padding>(paddingFinder.first);
        final edgeInsets = directPadding.padding.resolve(TextDirection.ltr);
        expect(edgeInsets.left, greaterThanOrEqualTo(16));
        expect(edgeInsets.right, greaterThanOrEqualTo(16));
      },
    );

    testWidgets(
      '23. Level 1 game completion does not render GameBriefingLayer behind completion dialog',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'has_seen_briefing_modifierPlacement': false,
        });

        const completeState = GrammarGameComplete(
          xpEarned: 50,
          coinsEarned: 10,
          questCount: 5,
        );

        await pumpModifierPlacement(
          tester,
          level: 1,
          state: completeState,
        );

        expect(find.byType(GameBriefingLayer), findsNothing);
      },
    );
  });
}
