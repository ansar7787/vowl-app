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
import 'package:vowl/features/grammar/conditionals/presentation/pages/conditionals_screen.dart';
import 'package:vowl/features/grammar/conditionals/presentation/widgets/conditionals_instruction.dart';
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
    id: 'cond_l1_q1',
    instruction: 'Complete the conditional sentence.',
    difficulty: 1,
    subtype: GameSubtype.conditionals,
    question: 'If it rains tomorrow,',
    prompt: 'If it rains tomorrow,',
    options: [
      'we will stay inside.',
      'we stayed inside.',
      'we would stay inside.',
    ],
    correctAnswerIndex: 0,
    correctAnswer: 'If it rains tomorrow, we will stay inside.',
    conditionalType: '1',
    hint: 'This is a real possibility in the future.',
    explanation:
        'First conditional uses present simple after if, followed by will + base verb.',
  );

  const testQuest2 = GrammarQuest(
    id: 'cond_l1_q2',
    instruction: 'Choose the correct outcome.',
    difficulty: 1,
    subtype: GameSubtype.conditionals,
    question: 'If you heat ice,',
    prompt: 'If you heat ice,',
    options: ['it would melt.', 'it will melt.', 'it melts.'],
    correctAnswerIndex: 2,
    correctAnswer: 'If you heat ice, it melts.',
    conditionalType: '0',
    hint: 'This is a general scientific fact.',
  );

  const testQuestWithoutType = GrammarQuest(
    id: 'cond_l1_q3',
    instruction: 'Pick the outcome.',
    difficulty: 1,
    subtype: GameSubtype.conditionals,
    question: 'If I won the lottery,',
    prompt: 'If I won the lottery,',
    options: ['I will travel.', 'I would travel the world.'],
    correctAnswerIndex: 1,
    correctAnswer: 'If I won the lottery, I would travel the world.',
  );

  final testLoadedState = GrammarLoaded(
    quests: const [testQuest1, testQuest2, testQuestWithoutType],
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
      'has_seen_briefing_conditionals': true,
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

  Future<void> pumpConditionals(
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
            home: ConditionalsScreen(
              level: level,
              gameType: GameSubtype.conditionals,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('ConditionalsScreen Layout & Mechanics', () {
    testWidgets(
      '1. renders initial quest with condition card, type chip, and options list',
      (tester) async {
        await pumpConditionals(tester);

        expect(find.byType(ConditionalsInstruction), findsOneWidget);
        expect(find.text('Complete the conditional sentence.'), findsOneWidget);
        expect(find.text('First Conditional'), findsOneWidget);
        expect(find.text('IF CLAUSE'), findsOneWidget);
        expect(find.text('If it rains tomorrow,'), findsOneWidget);

        expect(find.text('we will stay inside.'), findsOneWidget);
        expect(find.text('we stayed inside.'), findsOneWidget);
        expect(find.text('we would stay inside.'), findsOneWidget);
      },
    );

    testWidgets(
      '2. hides conditionalType chip when quest conditionalType is null',
      (tester) async {
        final stateWithoutType = GrammarLoaded(
          quests: const [testQuestWithoutType],
          currentIndex: 0,
          livesRemaining: 3,
          answerStatus: AnswerStatus.unanswered,
          hintUsed: false,
          wrongCount: 0,
          isFinalFailure: false,
        );

        await pumpConditionals(tester, state: stateWithoutType);

        expect(find.textContaining('TYPE:'), findsNothing);
        expect(find.text('If I won the lottery,'), findsOneWidget);
        expect(find.text('I would travel the world.'), findsOneWidget);
      },
    );

    testWidgets('3. renders shimmer loading when state is GrammarLoading', (
      tester,
    ) async {
      await pumpConditionals(tester, state: const GrammarLoading());

      expect(find.byType(GameShimmerLoading), findsOneWidget);
      expect(find.byType(ConditionalsInstruction), findsNothing);
    });

    testWidgets(
      '4. tapping incorrect option submits wrong answer to GrammarBloc',
      (tester) async {
        await pumpConditionals(tester);

        final wrongOption = find.byKey(
          const ValueKey('conditional_option_1'),
        ); // 'we stayed inside.'
        expect(wrongOption, findsOneWidget);

        await tester.tap(wrongOption);
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
      '5. tapping correct option transitions to Phase 2 TypeToConfirmOverlay',
      (tester) async {
        await pumpConditionals(tester);

        final correctOption = find.byKey(
          const ValueKey('conditional_option_0'),
        ); // 'we will stay inside.'
        expect(correctOption, findsOneWidget);

        await tester.tap(correctOption);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        verify(() => mockHapticService.heavy()).called(1);
        verify(() => mockSoundService.playCorrect()).called(1);

        await tester.drag(find.byType(CustomScrollView), const Offset(0, -800));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          find.byType(TypeToConfirmOverlay, skipOffstage: false),
          findsOneWidget,
        );
        expect(
          find.text(
            'Type the answer to confirm',
            skipOffstage: false,
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '6. Phase 2: typing correct sentence confirms and submits answer',
      (tester) async {
        await pumpConditionals(tester);

        final correctOption = find.byKey(
          const ValueKey('conditional_option_0'),
        );
        await tester.tap(correctOption);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        await tester.drag(find.byType(CustomScrollView), const Offset(0, -800));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final textField = find.byType(TextField);
        expect(textField, findsOneWidget);

        await tester.enterText(
          textField,
          'If it rains tomorrow, we will stay inside.',
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

    testWidgets('7. Phase 2: skipping confirm dispatches wrong answer', (
      tester,
    ) async {
      await pumpConditionals(tester);

      final correctOption = find.byKey(const ValueKey('conditional_option_0'));
      await tester.tap(correctOption);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -800));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);

      await tester.enterText(textFieldFinder, 'Wrong sentence entered');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final submitBtn = find.text('SUBMIT');

      // Attempt 1 (ScaleButton debounce)
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

      // Now out of attempts, button changes to 'CONTINUE'
      final continueBtn = find.text('CONTINUE').last;
      expect(continueBtn, findsOneWidget);

      await tester.tap(continueBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
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
    });

    testWidgets('8. tapping options when already answered does nothing', (
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

      await pumpConditionals(tester, state: answeredState);

      await tester.tap(find.byKey(const ValueKey('conditional_option_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verifyNever(() => mockGrammarBloc.add(any(that: isA<SubmitAnswer>())));
    });

    testWidgets('9. tapping hint button dispatches GrammarHintUsed', (
      tester,
    ) async {
      await pumpConditionals(tester);

      final hintButton = find.byType(QuestHintButton);
      expect(hintButton, findsOneWidget);

      await tester.tap(hintButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockGrammarBloc.add(const GrammarHintUsed())).called(1);
    });

    testWidgets('10. shows level 1 briefing dialog when not yet seen', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});

      await pumpConditionals(tester, level: 1);

      expect(find.byType(GameBriefingLayer), findsOneWidget);

      final commenceButton = find.text('COMMENCE QUEST');
      if (commenceButton.evaluate().isNotEmpty) {
        await tester.tap(commenceButton);
      } else {
        await tester.tap(find.byType(GameBriefingLayer));
      }
      await tester.pumpAndSettle();

      expect(find.text('If it rains tomorrow,'), findsOneWidget);
    });

    testWidgets(
      '11. respects reduced motion when lowAnimationModeOverride is enabled',
      (tester) async {
        VowlMotion.lowAnimationModeOverride.value = true;
        await pumpConditionals(tester);
        expect(find.byType(ConditionalsScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '12. handles compact mobile layout (320x568) without overflow',
      (tester) async {
        await pumpConditionals(tester, width: 320, height: 568);

        expect(find.byType(ConditionalsScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('13. handles tablet viewport (768x1024) without overflow', (
      tester,
    ) async {
      await pumpConditionals(tester, width: 768, height: 1024);

      expect(find.byType(ConditionalsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('14. renders correctly in dark mode', (tester) async {
      await pumpConditionals(tester, themeMode: ThemeMode.dark);

      expect(find.byType(ConditionalsScreen), findsOneWidget);
      expect(find.text('If it rains tomorrow,'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('15. renders zero/fact conditional type correctly', (
      tester,
    ) async {
      final stateZero = GrammarLoaded(
        quests: const [testQuest2],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
        hintUsed: false,
        wrongCount: 0,
        isFinalFailure: false,
      );

      await pumpConditionals(tester, state: stateZero);

      expect(find.text('Zero Conditional'), findsOneWidget);
      expect(find.text('If you heat ice,'), findsOneWidget);
      expect(find.text('it melts.'), findsOneWidget);
    });

    testWidgets(
      '16. renders final failure state with explanation and continue',
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

        await pumpConditionals(tester, state: failureState);

        expect(find.byType(ConditionalsScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
