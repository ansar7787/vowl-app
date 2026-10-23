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
import 'package:vowl/features/grammar/preposition_choice/presentation/pages/preposition_choice_screen.dart';
import 'package:vowl/features/grammar/preposition_choice/presentation/widgets/preposition_choice_instruction.dart';
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
    id: 'prep_l1_q1',
    instruction: 'TRACE OR TAP THE PREPOSITION',
    difficulty: 1,
    subtype: GameSubtype.prepositionChoice,
    sentenceWithBlank: 'The cat jumped ____ the fence.',
    correctAnswer: 'The cat jumped over the fence.',
    options: ['IN', 'OVER', 'AT', 'UNDER'],
    correctAnswerIndex: 1, // 'OVER'
    grammarRule: 'Preposition of Movement',
    prepositionCategory: 'Movement',
    hint: 'Think about moving above something to the other side.',
  );

  const testQuestCategoryOnly = GrammarQuest(
    id: 'prep_l1_q2',
    instruction: 'TRACE OR TAP A NODE',
    difficulty: 1,
    subtype: GameSubtype.prepositionChoice,
    sentenceWithBlank: 'The book is ____ the table.',
    correctAnswer: 'The book is on the table.',
    options: ['IN', 'ON', 'AT', 'UNDER'],
    correctAnswerIndex: 1, // 'ON'
    prepositionCategory: 'Place',
  );

  const testQuestNoRules = GrammarQuest(
    id: 'prep_l1_q3',
    instruction: 'SELECT THE PREPOSITION',
    difficulty: 1,
    subtype: GameSubtype.prepositionChoice,
    sentenceWithBlank: 'He arrived ____ 5 PM.',
    correctAnswer: 'He arrived at 5 PM.',
    options: ['IN', 'ON', 'AT', 'UNDER'],
    correctAnswerIndex: 2, // 'AT'
  );

  final testLoadedState = GrammarLoaded(
    quests: const [testQuest1, testQuestCategoryOnly, testQuestNoRules],
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
      'has_seen_briefing_prepositionChoice': true,
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

  Future<void> pumpPrepositionChoice(
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
            home: PrepositionChoiceScreen(
              level: level,
              gameType: GameSubtype.prepositionChoice,
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  group('PrepositionChoiceScreen Layout & Mechanics', () {
    testWidgets(
      '1. renders initial quest with instruction, grammar rule box, context card, canvas, and node touch targets',
      (tester) async {
        await pumpPrepositionChoice(tester);

        expect(find.byType(PrepositionChoiceInstruction), findsOneWidget);
        expect(
          find.byKey(const ValueKey('preposition_choice_instruction')),
          findsOneWidget,
        );
        expect(find.text('TRACE OR TAP THE PREPOSITION'), findsOneWidget);

        expect(find.byKey(const ValueKey('grammar_rule_box')), findsOneWidget);
        expect(find.text('RULE: PREPOSITION OF MOVEMENT'), findsOneWidget);

        expect(
          find.byKey(const ValueKey('preposition_context_card')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('preposition_path_canvas')),
          findsOneWidget,
        );

        for (int i = 0; i < 4; i++) {
          expect(find.byKey(ValueKey('preposition_node_$i')), findsOneWidget);
        }
      },
    );

    testWidgets(
      '2. hides grammar rule box when quest has neither grammarRule nor prepositionCategory',
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

        await pumpPrepositionChoice(tester, state: stateWithoutRule);

        expect(find.byKey(const ValueKey('grammar_rule_box')), findsNothing);
        expect(
          find.byKey(const ValueKey('preposition_context_card')),
          findsOneWidget,
        );
      },
    );

    testWidgets('3. displays prepositionCategory when grammarRule is null', (
      tester,
    ) async {
      final stateCategory = GrammarLoaded(
        quests: const [testQuestCategoryOnly],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
        hintUsed: false,
        wrongCount: 0,
        isFinalFailure: false,
      );

      await pumpPrepositionChoice(tester, state: stateCategory);

      expect(find.byKey(const ValueKey('grammar_rule_box')), findsOneWidget);
      expect(find.text('RULE: PLACE'), findsOneWidget);
    });

    testWidgets(
      '4. displays quest hint inside grammar rule box when hintUsed is true',
      (tester) async {
        final stateWithHint = GrammarLoaded(
          quests: const [testQuest1],
          currentIndex: 0,
          livesRemaining: 3,
          answerStatus: AnswerStatus.unanswered,
          hintUsed: true,
          wrongCount: 0,
          isFinalFailure: false,
        );

        await pumpPrepositionChoice(tester, state: stateWithHint);

        expect(
          find.text('Think about moving above something to the other side.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '5. tapping incorrect node submits wrong answer to GrammarBloc',
      (tester) async {
        await pumpPrepositionChoice(tester);

        // Option 0 is 'IN' (wrong for testQuest1)
        final node0 = find.byKey(const ValueKey('preposition_node_0'));
        await tester.tap(node0);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

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
      '6. tapping correct node triggers success haptic and reveals TypeToConfirmOverlay (Phase 2)',
      (tester) async {
        await pumpPrepositionChoice(tester);

        // Option 1 is 'OVER' (correct for testQuest1)
        final node1 = find.byKey(const ValueKey('preposition_node_1'));
        await tester.tap(node1);
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
        await pumpPrepositionChoice(tester);

        // Tap correct node
        final node1 = find.byKey(const ValueKey('preposition_node_1'));
        await tester.tap(node1);
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
          'The cat jumped over the fence.',
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
        await pumpPrepositionChoice(tester);

        // Tap correct node
        final node1 = find.byKey(const ValueKey('preposition_node_1'));
        await tester.tap(node1);
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

        // Attempt 1
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
      '9. dragging to incorrect node triggers wrong answer submission',
      (tester) async {
        await pumpPrepositionChoice(tester);

        final canvasFinder = find.byKey(
          const ValueKey('preposition_path_canvas'),
        );
        expect(canvasFinder, findsOneWidget);

        final node0 = find.byKey(const ValueKey('preposition_node_0'));
        await tester.ensureVisible(node0);
        await tester.pump();
        final node0Center = tester.getCenter(node0);

        // Pan into node 0 from canvas center
        final gesture = await tester.startGesture(
          tester.getCenter(canvasFinder),
        );
        await gesture.moveBy(const Offset(0, 20));
        await tester.pump();
        await gesture.moveTo(node0Center);
        await tester.pump();
        await gesture.up();
        await tester.pump(const Duration(milliseconds: 200));

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
      '10. dragging to correct node triggers success audio/haptics and Phase 2',
      (tester) async {
        await pumpPrepositionChoice(tester);

        final canvasFinder = find.byKey(
          const ValueKey('preposition_path_canvas'),
        );
        expect(canvasFinder, findsOneWidget);

        final node1 = find.byKey(const ValueKey('preposition_node_1'));
        await tester.ensureVisible(node1);
        await tester.pump();
        final node1Center = tester.getCenter(node1);

        // Pan into node 1 from canvas center
        final gesture = await tester.startGesture(
          tester.getCenter(canvasFinder),
        );
        await gesture.moveBy(const Offset(0, 20));
        await tester.pump();
        await gesture.moveTo(node1Center);
        await tester.pump();
        await gesture.up();
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
      '11. panning in canvas without reaching any node does not submit answer',
      (tester) async {
        await pumpPrepositionChoice(tester);

        final canvasFinder = find.byKey(
          const ValueKey('preposition_path_canvas'),
        );
        final center = tester.getCenter(canvasFinder);

        final gesture = await tester.startGesture(center);
        await gesture.moveBy(const Offset(5, 5));
        await tester.pump();
        await gesture.up();
        await tester.pump(const Duration(milliseconds: 200));

        verifyNever(() => mockGrammarBloc.add(any(that: isA<SubmitAnswer>())));
      },
    );

    testWidgets(
      '12. lockout: when question is answered, tapping nodes does not submit another answer',
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

        await pumpPrepositionChoice(tester, state: answeredState);

        final node0 = find.byKey(const ValueKey('preposition_node_0'));
        await tester.ensureVisible(node0);
        await tester.pump();
        await tester.tap(node0, warnIfMissed: false);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        verifyNever(() => mockGrammarBloc.add(any(that: isA<SubmitAnswer>())));
      },
    );

    testWidgets(
      '13. shimmer loading: displays GameShimmerLoading when state is not loaded',
      (tester) async {
        await pumpPrepositionChoice(tester, state: const GrammarInitial());

        expect(find.byType(GameShimmerLoading), findsOneWidget);
        expect(
          find.byKey(const ValueKey('preposition_path_canvas')),
          findsNothing,
        );
      },
    );

    testWidgets(
      '14. hint button dispatches GrammarHintUsed once without double dispatch',
      (tester) async {
        await pumpPrepositionChoice(tester);

        final hintFinder = find.byType(QuestHintButton);
        expect(hintFinder, findsOneWidget);

        await tester.tap(hintFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        verify(
          () => mockGrammarBloc.add(any(that: isA<GrammarHintUsed>())),
        ).called(1);
      },
    );

    testWidgets('15. level 1 briefing dialog displays for first-time user', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'has_seen_briefing_prepositionChoice': false,
      });

      await pumpPrepositionChoice(tester, level: 1);

      expect(find.byType(GameBriefingLayer), findsOneWidget);
    });

    testWidgets(
      '16. reduced motion: lowAnimationModeOverride gates shimmer and entrance animations',
      (tester) async {
        VowlMotion.lowAnimationModeOverride.value = true;
        await pumpPrepositionChoice(tester);

        expect(find.byType(PrepositionChoiceScreen), findsOneWidget);
        expect(
          find.byKey(const ValueKey('preposition_path_canvas')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '17. compact viewport (320x568) renders cleanly without overflow',
      (tester) async {
        await pumpPrepositionChoice(tester, width: 320, height: 568);

        expect(find.byType(PrepositionChoiceScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '18. tablet viewport (768x1024) renders cleanly with proper layout',
      (tester) async {
        await pumpPrepositionChoice(tester, width: 768, height: 1024);

        expect(find.byType(PrepositionChoiceScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('19. dark mode renders correctly with dark theme styling', (
      tester,
    ) async {
      await pumpPrepositionChoice(tester, themeMode: ThemeMode.dark);

      expect(find.byType(PrepositionChoiceScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('20. final failure state renders game over layout cleanly', (
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

      await pumpPrepositionChoice(tester, state: failedState);

      expect(find.byType(PrepositionChoiceScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      '21. instruction text is center aligned, does not truncate with ellipsis, and replaces buzzword',
      (tester) async {
        const questWithBuzzword = GrammarQuest(
          id: 'buzz_q',
          instruction: 'TRACE OR TAP A NODE',
          difficulty: 1,
          subtype: GameSubtype.prepositionChoice,
          sentenceWithBlank: 'The keys are ____ the counter.',
          correctAnswer: 'The keys are on the counter.',
          options: ['ON', 'IN', 'AT', 'UNDER'],
          correctAnswerIndex: 0,
        );

        final buzzState = GrammarLoaded(
          quests: const [questWithBuzzword],
          currentIndex: 0,
          livesRemaining: 3,
          answerStatus: AnswerStatus.unanswered,
          hintUsed: false,
          wrongCount: 0,
          isFinalFailure: false,
        );

        await pumpPrepositionChoice(tester, state: buzzState);

        final textFinder = find.descendant(
          of: find.byType(PrepositionChoiceInstruction),
          matching: find.byType(Text),
        );
        expect(textFinder, findsOneWidget);
        final textWidget = tester.widget<Text>(textFinder);

        expect(textWidget.textAlign, TextAlign.center);
        expect(textWidget.overflow, isNot(TextOverflow.ellipsis));
        expect(textWidget.data, 'Trace or tap the correct preposition');
      },
    );

    testWidgets(
      '22. Phase 2 TypeToConfirmOverlay card has standard side padding and does not touch screen edges',
      (tester) async {
        await pumpPrepositionChoice(tester, width: 390, height: 844);

        // Tap correct node (node 1 is OVER)
        final node1 = find.byKey(const ValueKey('preposition_node_1'));
        await tester.tap(node1);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));

        final overlayFinder = find.byType(TypeToConfirmOverlay);
        expect(overlayFinder, findsOneWidget);

        final paddingFinder = find
            .ancestor(of: overlayFinder, matching: find.byType(Padding))
            .first;

        final paddingWidget = tester.widget<Padding>(paddingFinder);
        final insets = paddingWidget.padding.resolve(TextDirection.ltr);

        expect(insets.left, greaterThanOrEqualTo(16));
        expect(insets.right, greaterThanOrEqualTo(16));

        final overlayRect = tester.getRect(overlayFinder);
        expect(overlayRect.left, greaterThan(0));
        expect(overlayRect.right, lessThan(390));
      },
    );
  });
}
