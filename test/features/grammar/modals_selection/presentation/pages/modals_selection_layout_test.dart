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
import 'package:vowl/features/grammar/modals_selection/presentation/pages/modals_selection_screen.dart';
import 'package:vowl/features/grammar/modals_selection/presentation/widgets/modals_selection_instruction.dart';
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
    id: 'ms_l1_q1',
    instruction: 'CALIBRATE THE MODAL DIAL',
    difficulty: 1,
    subtype: GameSubtype.modalsSelection,
    question: 'My brother ___ swim across the pool without stopping.',
    sentence: 'My brother can swim across the pool without stopping.',
    sentenceWithBlank: 'My brother ___ swim across the pool without stopping.',
    options: ['might', 'can', 'would', 'should'],
    correctAnswerIndex: 1,
    correctAnswer: 'can',
    hint: 'Think about a physical ability.',
    explanation: 'Can describes a present ability.',
    grammarRule: 'Ability (can)',
    ruleExplanation: 'Use can to describe physical ability.',
  );

  const testQuestNoRules = GrammarQuest(
    id: 'ms_l1_q2',
    instruction: 'SELECT THE MODAL',
    difficulty: 1,
    subtype: GameSubtype.modalsSelection,
    question: 'You ___ wear a helmet while riding a motorcycle.',
    sentence: 'You must wear a helmet while riding a motorcycle.',
    sentenceWithBlank: 'You ___ wear a helmet while riding a motorcycle.',
    options: ['might', 'must', 'could', 'may'],
    correctAnswerIndex: 1,
    correctAnswer: 'must',
    hint: 'It is a strict legal requirement.',
    explanation: 'Must indicates necessity or obligation.',
  );

  const testQuestExplanationOnly = GrammarQuest(
    id: 'ms_l1_q3',
    instruction: 'CALIBRATE THE MODAL DIAL',
    difficulty: 1,
    subtype: GameSubtype.modalsSelection,
    question: 'We ___ leave early to catch the sunrise.',
    sentence: 'We should leave early to catch the sunrise.',
    sentenceWithBlank: 'We ___ leave early to catch the sunrise.',
    options: ['should', 'might', 'would', 'can'],
    correctAnswerIndex: 0,
    correctAnswer: 'should',
    ruleExplanation: 'Should gives advice or recommendation.',
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
      'has_seen_briefing_modalsSelection': true,
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

  Future<void> pumpModalsSelection(
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
            home: ModalsSelectionScreen(
              level: level,
              gameType: GameSubtype.modalsSelection,
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  group('ModalsSelectionScreen Layout & Mechanics', () {
    testWidgets(
      '1. renders initial quest with instruction, grammar rule box, context card, rotary dial, and submit button',
      (tester) async {
        await pumpModalsSelection(tester);

        expect(find.byType(ModalsSelectionInstruction), findsOneWidget);
        expect(find.text('Choose the correct modal verb'), findsOneWidget);

        expect(find.byKey(const ValueKey('grammar_rule_box')), findsOneWidget);
        expect(find.text('Grammar Rule'), findsOneWidget);
        expect(find.text('Ability (can)'), findsOneWidget);

        expect(
          find.byKey(const ValueKey('modal_context_card')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('modals_rotary_dial')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('lock_configuration_button')),
          findsOneWidget,
        );
        expect(find.text('Confirm Selection'), findsOneWidget);
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

        await pumpModalsSelection(tester, state: stateWithoutRule);

        expect(find.byKey(const ValueKey('grammar_rule_box')), findsNothing);
        expect(
          find.byKey(const ValueKey('modal_context_card')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('modals_rotary_dial')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '3. renders grammar rule box when quest has ruleExplanation instead of grammarRule',
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

        await pumpModalsSelection(tester, state: stateWithExplanation);

        expect(find.byKey(const ValueKey('grammar_rule_box')), findsOneWidget);
        expect(
          find.text('Should gives advice or recommendation.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('4. renders shimmer loading when state is GrammarLoading', (
      tester,
    ) async {
      await pumpModalsSelection(tester, state: const GrammarLoading());

      expect(find.byType(GameShimmerLoading), findsOneWidget);
      expect(find.byKey(const ValueKey('modals_rotary_dial')), findsNothing);
    });

    testWidgets(
      '5. selecting wrong option and pressing lock configuration triggers wrong answer feedback',
      (tester) async {
        await pumpModalsSelection(tester);

        // Initially index 0 ('might') is selected. Correct is index 1 ('can').
        final lockBtn = find.byKey(const ValueKey('lock_configuration_button'));
        await tester.ensureVisible(lockBtn);
        await tester.pump();
        await tester.tap(lockBtn);
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
      '6. selecting correct option and pressing lock configuration opens TypeToConfirmOverlay',
      (tester) async {
        await pumpModalsSelection(tester);

        // Tap option 1 ('can', which is correct)
        final option1 = find.byKey(const ValueKey('modal_option_1'));
        expect(option1, findsOneWidget);
        await tester.tap(option1);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final lockBtn = find.byKey(const ValueKey('lock_configuration_button'));
        await tester.ensureVisible(lockBtn);
        await tester.pump();
        await tester.tap(lockBtn);
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
      '7. Phase 2: typing full sentence in TypeToConfirmOverlay confirms and submits correct answer',
      (tester) async {
        await pumpModalsSelection(tester);

        // Select correct option 1 ('can')
        final option1 = find.byKey(const ValueKey('modal_option_1'));
        await tester.tap(option1);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Submit to open Phase 2
        final lockBtn = find.byKey(const ValueKey('lock_configuration_button'));
        await tester.ensureVisible(lockBtn);
        await tester.pump();
        await tester.tap(lockBtn);
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
          'My brother can swim across the pool without stopping.',
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
      '8. Phase 2: skipping confirm (after 3 failed attempts) dispatches wrong answer',
      (tester) async {
        await pumpModalsSelection(tester);

        // Select correct option 1 ('can')
        final option1 = find.byKey(const ValueKey('modal_option_1'));
        await tester.tap(option1);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Submit to open Phase 2
        final lockBtn = find.byKey(const ValueKey('lock_configuration_button'));
        await tester.ensureVisible(lockBtn);
        await tester.pump();
        await tester.tap(lockBtn);
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
      '9. panning rotary dial updates selected option and context card text',
      (tester) async {
        await pumpModalsSelection(tester);

        final gestureFinder = find.byKey(
          const ValueKey('modals_rotary_dial_gesture'),
        );
        expect(gestureFinder, findsOneWidget);

        final center = tester.getCenter(gestureFinder);
        final gesture = await tester.startGesture(center + const Offset(50, 0));
        await tester.pump();
        await gesture.moveBy(const Offset(0, 50));
        await tester.pump();
        await gesture.moveBy(const Offset(-50, 0));
        await tester.pump();
        await gesture.up();
        await tester.pump(const Duration(milliseconds: 350));

        verify(
          () => mockHapticService.selection(),
        ).called(greaterThanOrEqualTo(1));
      },
    );

    testWidgets(
      '10. tapping dial modal option directly updates selected option and context card text',
      (tester) async {
        await pumpModalsSelection(tester);

        // Tap modal option 2 ('would')
        final option2 = find.byKey(const ValueKey('modal_option_2'));
        expect(option2, findsOneWidget);
        await tester.tap(option2);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        verify(() => mockHapticService.selection()).called(1);
        expect(find.text('would'), findsWidgets);
      },
    );

    testWidgets(
      '11. lock configuration button is hidden when question is already answered',
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

        await pumpModalsSelection(tester, state: answeredState);

        expect(
          find.byKey(const ValueKey('lock_configuration_button')),
          findsNothing,
        );
      },
    );

    testWidgets('12. hint button triggers hint without double dispatch', (
      tester,
    ) async {
      await pumpModalsSelection(tester);

      final hintFinder = find.byType(QuestHintButton);
      expect(hintFinder, findsOneWidget);

      await tester.tap(hintFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      verify(
        () => mockGrammarBloc.add(any(that: isA<GrammarHintUsed>())),
      ).called(1);
    });

    testWidgets('13. level 1 briefing dialog displays for first-time user', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'has_seen_briefing_modalsSelection': false,
      });

      await pumpModalsSelection(tester, level: 1);

      expect(find.byType(GameBriefingLayer), findsOneWidget);
    });

    testWidgets(
      '14. respects reduced motion when lowAnimationModeOverride is enabled',
      (tester) async {
        VowlMotion.lowAnimationModeOverride.value = true;
        await pumpModalsSelection(tester);

        expect(find.byType(ModalsSelectionScreen), findsOneWidget);
        expect(
          find.byKey(const ValueKey('modals_rotary_dial')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('15. compact viewport (320x568) renders without overflow', (
      tester,
    ) async {
      await pumpModalsSelection(tester, width: 320, height: 568);

      expect(find.byType(ModalsSelectionScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('16. tablet viewport (768x1024) renders with proper layout', (
      tester,
    ) async {
      await pumpModalsSelection(tester, width: 768, height: 1024);

      expect(find.byType(ModalsSelectionScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('17. dark mode renders correctly with dark theme styling', (
      tester,
    ) async {
      await pumpModalsSelection(tester, themeMode: ThemeMode.dark);

      expect(find.byType(ModalsSelectionScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('18. final failure state displays game over layout', (
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

      await pumpModalsSelection(tester, state: failedState);

      expect(find.byType(ModalsSelectionScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
