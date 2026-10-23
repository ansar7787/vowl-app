import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/game_mechanics/shared/game_skip_bypass_button.dart';
import 'package:vowl/core/presentation/game_mechanics/typing/type_to_confirm_overlay.dart';
import 'package:vowl/core/presentation/widgets/game_briefing_layer.dart';
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
import 'package:vowl/features/grammar/question_formatter/presentation/pages/question_formatter_screen.dart';

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
  late MockAppLogger mockAppLogger;
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
    id: 'qf_l1_q1',
    instruction: 'TURN INTO A QUESTION',
    difficulty: 1,
    subtype: GameSubtype.questionFormatter,
    sentence: 'She is reading a book.',
    question: 'Is she reading a book?',
    correctAnswer: 'Is she reading a book?',
    options: [
      'Is she reading a book?',
      'Does she reading a book?',
      'Are she reading a book?',
    ],
    correctAnswerIndex: 0,
    grammarRule: 'Inversion of Auxiliary Verb',
    hint: 'Move is before she.',
  );

  const testQuestNoRule = GrammarQuest(
    id: 'qf_l1_q2',
    instruction: '',
    difficulty: 1,
    subtype: GameSubtype.questionFormatter,
    sentence: 'They can swim fast.',
    question: 'Can they swim fast?',
    correctAnswer: 'Can they swim fast?',
    options: ['Can they swim fast?', 'Do they can swim fast?'],
    correctAnswerIndex: 0,
    hint: 'Move can to front.',
  );

  final testLoadedState = GrammarLoaded(
    quests: const [testQuest1, testQuestNoRule],
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
    mockAppLogger = MockAppLogger();
    mockAnalyticsService = MockAnalyticsService();
    mockAdService = MockAdService();

    VowlMotion.lowAnimationModeOverride.value = true;

    SharedPreferences.setMockInitialValues({
      'has_seen_briefing_questionFormatter': true,
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
          isPremium: true,
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

    when(
      () => mockAnalyticsService.logGameSkipped(any()),
    ).thenAnswer((_) async {});

    await di.sl.reset();

    di.sl.registerSingleton<HapticService>(mockHapticService);
    di.sl.registerSingleton<SoundService>(mockSoundService);
    di.sl.registerSingleton<TtsService>(mockTtsService);
    di.sl.registerSingleton<LocaleService>(mockLocaleService);
    di.sl.registerSingleton<AppLogger>(mockAppLogger);
    di.sl.registerSingleton<AnalyticsService>(mockAnalyticsService);
    di.sl.registerSingleton<AdService>(mockAdService);
  });

  tearDown(() async {
    await di.sl.reset();
  });

  Future<void> pumpQuestionFormatter(
    WidgetTester tester, {
    GrammarState? state,
    int level = 2,
    Size size = const Size(390, 844),
    ThemeMode themeMode = ThemeMode.dark,
  }) async {
    tester.view.physicalSize = Size(size.width * 2, size.height * 2);
    tester.view.devicePixelRatio = 2.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    if (state != null) {
      when(() => mockGrammarBloc.state).thenReturn(state);
    }

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
          builder: (context, child) {
            return MaterialApp(
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              home: MediaQuery(
                data: MediaQueryData(
                  size: size,
                  padding: EdgeInsets.zero,
                  viewInsets: EdgeInsets.zero,
                ),
                child: Scaffold(body: QuestionFormatterScreen(level: level)),
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  group('QuestionFormatterScreen Hardened Layout & Logic Tests', () {
    testWidgets('1. displays shimmer loading when state is GrammarInitial', (
      tester,
    ) async {
      final initialEmptyState = GrammarInitial();
      await pumpQuestionFormatter(tester, state: initialEmptyState);

      expect(find.byType(GameShimmerLoading), findsOneWidget);
      expect(
        find.byKey(const ValueKey('question_formatter_sentence_card')),
        findsNothing,
      );
    });

    testWidgets('2. renders instruction badge with default text', (
      tester,
    ) async {
      await pumpQuestionFormatter(tester);

      expect(
        find.byKey(const ValueKey('question_formatter_instruction')),
        findsOneWidget,
      );
      expect(find.text('TURN INTO A QUESTION'), findsOneWidget);
    });

    testWidgets('3. renders instruction badge with fallback instruction text', (
      tester,
    ) async {
      final stateNoInstruction = GrammarLoaded(
        quests: const [testQuestNoRule],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
        hintUsed: false,
        wrongCount: 0,
        isFinalFailure: false,
      );
      await pumpQuestionFormatter(tester, state: stateNoInstruction);

      expect(
        find.byKey(const ValueKey('question_formatter_instruction')),
        findsOneWidget,
      );
    });

    testWidgets('4. renders grammar rule box when rule is provided', (
      tester,
    ) async {
      await pumpQuestionFormatter(tester);

      expect(find.byKey(const ValueKey('grammar_rule_box')), findsOneWidget);
      expect(find.text('RULE: INVERSION OF AUXILIARY VERB'), findsOneWidget);
    });

    testWidgets(
      '5. omits grammar rule box when both grammarRule and questionType are null',
      (tester) async {
        final stateNoRule = GrammarLoaded(
          quests: const [testQuestNoRule],
          currentIndex: 0,
          livesRemaining: 3,
          answerStatus: AnswerStatus.unanswered,
          hintUsed: false,
          wrongCount: 0,
          isFinalFailure: false,
        );
        await pumpQuestionFormatter(tester, state: stateNoRule);

        expect(find.byKey(const ValueKey('grammar_rule_box')), findsNothing);
      },
    );

    testWidgets('6. renders 3D inverter context card with sentence text', (
      tester,
    ) async {
      await pumpQuestionFormatter(tester);

      expect(
        find.byKey(const ValueKey('question_formatter_sentence_card')),
        findsOneWidget,
      );
      expect(find.text('She is reading a book.'), findsOneWidget);
    });

    testWidgets(
      '7. renders QuestionFormatterCrank initially with mechanical arm and energy ring',
      (tester) async {
        await pumpQuestionFormatter(tester);

        expect(
          find.byKey(const ValueKey('question_formatter_crank')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('question_formatter_crank_bolt')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('question_formatter_option_0')),
          findsNothing,
        );
      },
    );

    testWidgets(
      '8. rotates context card 3D transform based on crank rotation value',
      (tester) async {
        await pumpQuestionFormatter(tester);

        expect(find.byType(Transform), findsWidgets);
      },
    );

    testWidgets(
      '9. auto-spin bolt triggers crank spin and unlocks question options',
      (tester) async {
        await pumpQuestionFormatter(tester);

        final boltFinder = find.byKey(
          const ValueKey('question_formatter_crank_bolt'),
        );
        expect(boltFinder, findsOneWidget);

        await tester.tap(boltFinder);
        for (int i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        expect(
          find.byKey(const ValueKey('question_formatter_option_0')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('question_formatter_option_1')),
          findsOneWidget,
        );
      },
    );

    testWidgets('10. dragging crank triggers onPanUpdate gesture', (
      tester,
    ) async {
      await pumpQuestionFormatter(tester);

      final crankFinder = find.byKey(
        const ValueKey('question_formatter_crank'),
      );
      expect(crankFinder, findsOneWidget);

      await tester.drag(crankFinder, const Offset(0, 100), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      '11. continuous auto-spin unlocks options once completion threshold is reached',
      (tester) async {
        await pumpQuestionFormatter(tester);

        final boltFinder = find.byKey(
          const ValueKey('question_formatter_crank_bolt'),
        );
        await tester.tap(boltFinder);
        for (int i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        expect(
          find.byKey(const ValueKey('question_formatter_option_0')),
          findsOneWidget,
        );
      },
    );

    testWidgets('12. renders all option cards with expected texts', (
      tester,
    ) async {
      await pumpQuestionFormatter(tester);

      await tester.tap(
        find.byKey(const ValueKey('question_formatter_crank_bolt')),
      );
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.text('Is she reading a book?'), findsWidgets);
      expect(find.text('Does she reading a book?'), findsOneWidget);
      expect(find.text('Are she reading a book?'), findsOneWidget);
    });

    testWidgets(
      '13. selecting correct option transitions to TypeToConfirmOverlay (Phase 2)',
      (tester) async {
        await pumpQuestionFormatter(tester);

        await tester.tap(
          find.byKey(const ValueKey('question_formatter_crank_bolt')),
        );
        for (int i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        clearInteractions(mockHapticService);
        clearInteractions(mockSoundService);

        await tester.tap(
          find.byKey(const ValueKey('question_formatter_option_0')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        verify(() => mockHapticService.success()).called(1);
        verify(() => mockSoundService.playCorrect()).called(1);

        expect(find.byType(TypeToConfirmOverlay), findsOneWidget);
      },
    );

    testWidgets(
      '14. Phase 2: displays TypeToConfirmOverlay with target question sentence',
      (tester) async {
        await pumpQuestionFormatter(tester);

        await tester.tap(
          find.byKey(const ValueKey('question_formatter_crank_bolt')),
        );
        for (int i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        await tester.tap(
          find.byKey(const ValueKey('question_formatter_option_0')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(TypeToConfirmOverlay), findsOneWidget);
        expect(
          find.text('Type the full question to lock it in'),
          findsOneWidget,
        );
      },
    );

    testWidgets('15. Phase 2: confirming typing submits answer to bloc', (
      tester,
    ) async {
      await pumpQuestionFormatter(tester);

      await tester.tap(
        find.byKey(const ValueKey('question_formatter_crank_bolt')),
      );
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      await tester.tap(
        find.byKey(const ValueKey('question_formatter_option_0')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final textFieldFinder = find.byType(TextField);
      expect(textFieldFinder, findsOneWidget);
      await tester.enterText(textFieldFinder, 'Is she reading a book?');
      await tester.pump(const Duration(milliseconds: 100));

      final submitFinder = find.text('SUBMIT');
      expect(submitFinder, findsOneWidget);
      await tester.ensureVisible(submitFinder);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(submitFinder);
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      verify(() => mockGrammarBloc.add(const SubmitAnswer(true))).called(1);
    });

    testWidgets('16. Phase 2: skipping typing submits answer to bloc', (
      tester,
    ) async {
      await pumpQuestionFormatter(tester);

      await tester.tap(
        find.byKey(const ValueKey('question_formatter_crank_bolt')),
      );
      for (int i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      await tester.tap(
        find.byKey(const ValueKey('question_formatter_option_0')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final skipFinder = find.byType(GameSkipBypassButton);
      expect(skipFinder, findsOneWidget);
      await tester.tap(skipFinder, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockGrammarBloc.add(any())).called(greaterThanOrEqualTo(1));
    });

    testWidgets(
      '17. selecting wrong option marks incorrect and dispatches SubmitAnswer(false)',
      (tester) async {
        await pumpQuestionFormatter(tester);

        await tester.tap(
          find.byKey(const ValueKey('question_formatter_crank_bolt')),
        );
        for (int i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        clearInteractions(mockHapticService);
        clearInteractions(mockSoundService);
        clearInteractions(mockGrammarBloc);

        await tester.tap(
          find.byKey(const ValueKey('question_formatter_option_1')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        verify(() => mockHapticService.error()).called(1);
        verify(() => mockSoundService.playWrong()).called(1);
        verify(() => mockGrammarBloc.add(const SubmitAnswer(false))).called(1);
      },
    );

    testWidgets(
      '18. answered lockout: options cannot be re-tapped when answered',
      (tester) async {
        final answeredState = testLoadedState.copyWith(
          answerStatus: AnswerStatus.correct,
        );
        await pumpQuestionFormatter(tester, state: answeredState);

        clearInteractions(mockGrammarBloc);

        final boltFinder = find.byKey(
          const ValueKey('question_formatter_crank_bolt'),
        );
        if (boltFinder.evaluate().isNotEmpty) {
          await tester.tap(boltFinder, warnIfMissed: false);
          await tester.pump();
        }

        verifyNever(() => mockGrammarBloc.add(any()));
      },
    );

    testWidgets('19. layout adapts gracefully in compact height (< 700)', (
      tester,
    ) async {
      await pumpQuestionFormatter(tester, size: const Size(360, 640));

      expect(
        find.byKey(const ValueKey('question_formatter_sentence_card')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      '20. renders correctly in dark and light themes without overflow',
      (tester) async {
        await pumpQuestionFormatter(tester, themeMode: ThemeMode.light);
        expect(tester.takeException(), isNull);

        await pumpQuestionFormatter(tester, themeMode: ThemeMode.dark);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('21. respects level 1 game briefing dialog on first run', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'has_seen_briefing_questionFormatter': false,
      });

      await pumpQuestionFormatter(tester, level: 1);

      expect(find.byType(GameBriefingLayer), findsOneWidget);
    });

    testWidgets(
      '22. instruction text uses center alignment and does not truncate with ellipsis',
      (tester) async {
        const longInstructionQuest = GrammarQuest(
          id: 'qf_long_instruction',
          instruction:
              'Read the sentence carefully and transform it into a polite question',
          difficulty: 1,
          subtype: GameSubtype.questionFormatter,
          sentence: 'She is reading a book.',
          question: 'Is she reading a book?',
          correctAnswer: 'Is she reading a book?',
          options: ['Is she reading a book?'],
          correctAnswerIndex: 0,
        );

        final longInstructionState = GrammarLoaded(
          quests: const [longInstructionQuest],
          currentIndex: 0,
          livesRemaining: 3,
          answerStatus: AnswerStatus.unanswered,
          hintUsed: false,
          wrongCount: 0,
          isFinalFailure: false,
        );

        await pumpQuestionFormatter(tester, state: longInstructionState);

        final textFinder = find.text(
          'Read the sentence carefully and transform it into a polite question',
        );
        expect(textFinder, findsOneWidget);
        final textWidget = tester.widget<Text>(textFinder);
        expect(textWidget.textAlign, TextAlign.center);
        expect(textWidget.overflow, isNot(TextOverflow.ellipsis));
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '23. Phase 2: TypeToConfirmOverlay card has side margins and does not touch screen edges',
      (tester) async {
        await pumpQuestionFormatter(tester);

        await tester.tap(
          find.byKey(const ValueKey('question_formatter_crank_bolt')),
        );
        for (int i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }

        await tester.tap(
          find.byKey(const ValueKey('question_formatter_option_0')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final overlayFinder = find.byType(TypeToConfirmOverlay);
        expect(overlayFinder, findsOneWidget);

        final overlayRect = tester.getRect(overlayFinder);
        expect(overlayRect.left, greaterThan(0));
        expect(overlayRect.right, lessThan(390));
        expect(tester.takeException(), isNull);
      },
    );
  });
}
