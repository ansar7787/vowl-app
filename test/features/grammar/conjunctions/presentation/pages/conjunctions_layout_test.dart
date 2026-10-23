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
import 'package:vowl/features/grammar/conjunctions/presentation/pages/conjunctions_screen.dart';
import 'package:vowl/features/grammar/conjunctions/presentation/widgets/conjunctions_brick_sheet.dart';
import 'package:vowl/features/grammar/conjunctions/presentation/widgets/conjunctions_instruction.dart';
import 'package:vowl/features/grammar/domain/entities/grammar_quest.dart';
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
    id: 'cj_l1_q1',
    instruction: 'JOIN THE JUNCTION',
    difficulty: 1,
    subtype: GameSubtype.conjunctions,
    sentenceWithBlank:
        'She packed her laptop, her charger, ___ a notebook before the conference.',
    sentence:
        'She packed her laptop, her charger, ___ a notebook before the conference.',
    question:
        'She packed her laptop, her charger, ___ a notebook before the conference.',
    options: ['but', 'so', 'and', 'because'],
    correctAnswerIndex: 2,
    correctAnswer: 'and',
    hint:
        'Think about whether these three items are all going into the same bag.',
    explanation:
        'All three items belong on the same list of things she is bringing, so and simply adds the last one.',
    grammarRule: 'Coordinating Conjunctions — Addition',
    conjunctionPurpose: 'Addition',
  );

  const testQuest2 = GrammarQuest(
    id: 'cj_l1_q2',
    instruction: 'JOIN THE JUNCTION',
    difficulty: 1,
    subtype: GameSubtype.conjunctions,
    sentenceWithBlank:
        'My neighbor waters his plants every morning ___ walks his dog right after.',
    sentence:
        'My neighbor waters his plants every morning ___ walks his dog right after.',
    question:
        'My neighbor waters his plants every morning ___ walks his dog right after.',
    options: ['and', 'but', 'until', 'although'],
    correctAnswerIndex: 0,
    correctAnswer: 'and',
    hint: 'Both actions are simply part of the same morning routine.',
    explanation:
        'Nothing here contrasts or depends on anything else — and just links two routine actions together.',
  );

  const testQuestFanboys = GrammarQuest(
    id: 'cj_l1_q3',
    instruction: 'JOIN THE JUNCTION',
    difficulty: 1,
    subtype: GameSubtype.conjunctions,
    sentenceWithBlank: 'I like coffee... I like tea.',
    sentence: 'I like coffee... I like tea.',
    question: 'I like coffee... I like tea.',
    options: ['or', 'and', 'so'],
    correctAnswerIndex: 1,
    correctAnswer: 'and',
    grammarRule: 'Coordinating Conjunctions',
    conjunctionPurpose: 'Addition',
  );

  final testLoadedState = GrammarLoaded(
    quests: const [testQuest1, testQuest2, testQuestFanboys],
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
      'has_seen_briefing_conjunctions': true,
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
          displayName: 'Test Explorer',
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

  Future<void> pumpConjunctions(
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
            home: ConjunctionsScreen(
              level: level,
              gameType: GameSubtype.conjunctions,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('ConjunctionsScreen Layout & Mechanics', () {
    testWidgets(
      '1. renders initial quest with island pieces, magnetic junction, and brick sheet',
      (tester) async {
        await pumpConjunctions(tester);

        expect(find.byType(ConjunctionsInstruction), findsOneWidget);
        expect(
          find.text('Choose the conjunction to connect the sentence'),
          findsOneWidget,
        );

        expect(
          find.byKey(const ValueKey('conjunction_rule_box')),
          findsOneWidget,
        );
        expect(
          find.text('Coordinating Conjunctions — Addition'),
          findsOneWidget,
        );

        expect(
          find.text('She packed her laptop, her charger,'),
          findsOneWidget,
        );
        expect(find.text('Choose conjunction'), findsOneWidget);
        expect(find.text('a notebook before the conference.'), findsOneWidget);

        expect(find.byType(ConjunctionsBrickSheet), findsOneWidget);
        expect(
          find.byKey(const ValueKey('conjunction_brick_but')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('conjunction_brick_so')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('conjunction_brick_and')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('conjunction_brick_because')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '2. renders FANBOYS mnemonic when grammarRule is Coordinating Conjunctions',
      (tester) async {
        final stateFanboys = GrammarLoaded(
          quests: const [testQuestFanboys],
          currentIndex: 0,
          livesRemaining: 3,
          answerStatus: AnswerStatus.unanswered,
          hintUsed: false,
          wrongCount: 0,
          isFinalFailure: false,
        );

        await pumpConjunctions(tester, state: stateFanboys);

        expect(
          find.byKey(const ValueKey('conjunction_rule_box')),
          findsOneWidget,
        );
        expect(find.text('F = For'), findsOneWidget);
        expect(find.text('A = And'), findsOneWidget);
        expect(find.text('N = Nor'), findsOneWidget);
        expect(find.text('B = But'), findsOneWidget);
        expect(find.text('O = Or'), findsOneWidget);
        expect(find.text('Y = Yet'), findsOneWidget);
        expect(find.text('S = So'), findsOneWidget);
      },
    );

    testWidgets(
      '3. hides rule box when grammarRule and conjunctionPurpose are null',
      (tester) async {
        final stateWithoutRules = GrammarLoaded(
          quests: const [testQuest2],
          currentIndex: 0,
          livesRemaining: 3,
          answerStatus: AnswerStatus.unanswered,
          hintUsed: false,
          wrongCount: 0,
          isFinalFailure: false,
        );

        await pumpConjunctions(tester, state: stateWithoutRules);

        expect(
          find.byKey(const ValueKey('conjunction_rule_box')),
          findsNothing,
        );
        expect(
          find.text('My neighbor waters his plants every morning'),
          findsOneWidget,
        );
        expect(find.text('walks his dog right after.'), findsOneWidget);
      },
    );

    testWidgets('4. renders shimmer loading when state is GrammarLoading', (
      tester,
    ) async {
      await pumpConjunctions(tester, state: const GrammarLoading());

      expect(find.byType(GameShimmerLoading), findsOneWidget);
      expect(find.byType(ConjunctionsInstruction), findsNothing);
    });

    testWidgets(
      '5. tapping incorrect brick places it and submits wrong answer to GrammarBloc',
      (tester) async {
        await pumpConjunctions(tester);

        final wrongBrick = find.byKey(const ValueKey('conjunction_brick_but'));
        expect(wrongBrick, findsOneWidget);

        await tester.tap(wrongBrick);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 400));

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
      '6. tapping correct brick places it and transitions to Phase 2 TypeToConfirmOverlay',
      (tester) async {
        await pumpConjunctions(tester);

        final correctBrick = find.byKey(
          const ValueKey('conjunction_brick_and'),
        );
        expect(correctBrick, findsOneWidget);

        await tester.tap(correctBrick);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 400));

        verify(() => mockHapticService.heavy()).called(1);
        verify(() => mockSoundService.playCorrect()).called(1);

        await tester.drag(find.byType(CustomScrollView), const Offset(0, -800));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(
          find.byType(TypeToConfirmOverlay, skipOffstage: false),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '7. Phase 2: typing correct sentence confirms and submits answer',
      (tester) async {
        await pumpConjunctions(tester);

        final correctBrick = find.byKey(
          const ValueKey('conjunction_brick_and'),
        );
        await tester.tap(correctBrick);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 400));

        await tester.drag(find.byType(CustomScrollView), const Offset(0, -800));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        final textFieldFinder = find.byType(TextField);
        expect(textFieldFinder, findsOneWidget);

        await tester.enterText(
          textFieldFinder,
          'She packed her laptop, her charger, and a notebook before the conference.',
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        final submitBtn = find.text('SUBMIT');
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
        await pumpConjunctions(tester);

        final correctBrick = find.byKey(
          const ValueKey('conjunction_brick_and'),
        );
        await tester.tap(correctBrick);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 400));

        await tester.drag(find.byType(CustomScrollView), const Offset(0, -800));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final textFieldFinder = find.byType(TextField);
        expect(textFieldFinder, findsOneWidget);

        await tester.enterText(textFieldFinder, 'Wrong typed sentence');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        final submitBtn = find.text('SUBMIT');

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

        // Button converts to CONTINUE
        final continueBtn = find.text('CONTINUE').last;
        expect(continueBtn, findsOneWidget);

        await tester.tap(continueBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 400));

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

    testWidgets('9. dragging brick onto magnetic junction triggers Phase 2', (
      tester,
    ) async {
      await pumpConjunctions(tester);

      final correctBrick = find.byKey(const ValueKey('conjunction_brick_and'));
      final target = find.byKey(const ValueKey('magnetic_junction'));

      final gesture = await tester.startGesture(tester.getCenter(correctBrick));
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.moveTo(tester.getCenter(target));
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 400));

      verify(() => mockSoundService.playCorrect()).called(1);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -800));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.byType(TypeToConfirmOverlay, skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('10. interacting when already answered does nothing', (
      tester,
    ) async {
      final answeredState = GrammarLoaded(
        quests: const [testQuest1, testQuest2],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.correct,
        hintUsed: false,
        wrongCount: 0,
        isFinalFailure: false,
      );

      await pumpConjunctions(tester, state: answeredState);

      final brickFinder = find.byKey(const ValueKey('conjunction_brick_so'));
      expect(brickFinder, findsOneWidget);

      await tester.tap(brickFinder, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      verifyNever(() => mockGrammarBloc.add(any(that: isA<SubmitAnswer>())));
    });

    testWidgets(
      '11. tapping hint button dispatches GrammarHintUsed without double dispatch',
      (tester) async {
        await pumpConjunctions(tester);

        final hintButton = find.byType(QuestHintButton);
        expect(hintButton, findsOneWidget);

        await tester.tap(hintButton);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        verify(() => mockGrammarBloc.add(const GrammarHintUsed())).called(1);
      },
    );

    testWidgets('12. shows level 1 briefing dialog when not yet seen', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await pumpConjunctions(tester, level: 1);

      expect(find.byType(GameBriefingLayer), findsOneWidget);

      final commenceButton = find.text('COMMENCE QUEST');
      if (commenceButton.evaluate().isNotEmpty) {
        await tester.tap(commenceButton);
      } else {
        await tester.tap(find.byType(GameBriefingLayer));
      }
      await tester.pumpAndSettle();

      expect(find.text('She packed her laptop, her charger,'), findsOneWidget);
    });

    testWidgets(
      '13. respects reduced motion when lowAnimationModeOverride is enabled',
      (tester) async {
        VowlMotion.lowAnimationModeOverride.value = true;
        await pumpConjunctions(tester);
        expect(find.byType(ConjunctionsScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '14. handles compact mobile layout (320x568) without overflow',
      (tester) async {
        await pumpConjunctions(tester, width: 320, height: 568);

        expect(find.byType(ConjunctionsScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('15. handles tablet viewport (768x1024) without overflow', (
      tester,
    ) async {
      await pumpConjunctions(tester, width: 768, height: 1024);

      expect(find.byType(ConjunctionsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('16. renders correctly in dark mode', (tester) async {
      await pumpConjunctions(tester, themeMode: ThemeMode.dark);

      expect(find.byType(ConjunctionsScreen), findsOneWidget);
      expect(find.text('She packed her laptop, her charger,'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      '17. renders final failure state with explanation and continue',
      (tester) async {
        final failureState = GrammarLoaded(
          quests: const [testQuest1, testQuest2],
          currentIndex: 0,
          livesRemaining: 0,
          answerStatus: AnswerStatus.incorrect,
          hintUsed: false,
          wrongCount: 3,
          isFinalFailure: true,
        );

        await pumpConjunctions(tester, state: failureState);

        expect(find.byType(ConjunctionsScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
