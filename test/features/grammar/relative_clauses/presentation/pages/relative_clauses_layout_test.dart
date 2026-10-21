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
import 'package:vowl/core/presentation/widgets/game_feedback_card.dart';
import 'package:vowl/core/presentation/widgets/quest_hint_button.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
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
import 'package:vowl/features/grammar/relative_clauses/presentation/pages/relative_clauses_screen.dart';
import 'package:vowl/features/grammar/relative_clauses/presentation/widgets/relative_clauses_instruction.dart';

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
    id: 'rc_l1_q1',
    instruction: 'TAP OR DRAG TO CONNECT',
    difficulty: 1,
    subtype: GameSubtype.relativeClauses,
    question: 'The scientist _____ won the Nobel prize.',
    sentence: 'The scientist who discovered it won the Nobel prize.',
    correctAnswer: 'who discovered it',
    options: [
      'who discovered it',
      'which was blue',
      'where they met',
    ],
    correctAnswerIndex: 0,
    clauseType: 'defining',
    hint: 'Use who for people.',
  );

  const testQuestNoClause = GrammarQuest(
    id: 'rc_l1_q2',
    instruction: 'TAP OR DRAG TO CONNECT',
    difficulty: 1,
    subtype: GameSubtype.relativeClauses,
    question: 'The car _____ is outside.',
    sentence: 'The car which was red is outside.',
    correctAnswer: 'which was red',
    options: [
      'which was red',
      'who was fast',
    ],
    correctAnswerIndex: 0,
    clauseType: null,
    hint: 'Use which for things.',
  );

  final testLoadedState = GrammarLoaded(
    quests: const [testQuest1, testQuestNoClause],
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
      'has_seen_briefing_relativeClauses': true,
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

  Future<void> pumpRelativeClausesScreen(
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
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            home: MediaQuery(
              data: MediaQueryData(
                size: size,
                padding: EdgeInsets.zero,
                viewInsets: EdgeInsets.zero,
              ),
              child: Scaffold(
                body: RelativeClausesScreen(level: level),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  group('RelativeClausesScreen Layout & Hardening Tests', () {
    testWidgets('1. initializes without crash on GrammarInitial (shows shimmer)',
        (tester) async {
      await pumpRelativeClausesScreen(tester, state: GrammarInitial());
      expect(find.byType(GameShimmerLoading), findsOneWidget);
    });

    testWidgets('2. displays shimmer loading when state is GrammarLoading',
        (tester) async {
      await pumpRelativeClausesScreen(tester, state: GrammarLoading());
      expect(find.byType(GameShimmerLoading), findsOneWidget);
    });

    testWidgets('3. renders RelativeClausesInstruction badge with text TAP OR DRAG TO CONNECT',
        (tester) async {
      await pumpRelativeClausesScreen(tester);
      expect(find.byType(RelativeClausesInstruction), findsOneWidget);
      expect(find.text('TAP OR DRAG TO CONNECT'), findsOneWidget);
    });

    testWidgets('4. displays clause type badge when quest has clauseType',
        (tester) async {
      await pumpRelativeClausesScreen(tester);
      expect(find.byKey(const ValueKey('clause_box')), findsOneWidget);
      expect(find.text('CLAUSE: DEFINING'), findsOneWidget);
    });

    testWidgets('5. omits clause type badge when quest clauseType is null',
        (tester) async {
      final stateNoClause = GrammarLoaded(
        quests: const [testQuestNoClause],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
        hintUsed: false,
        wrongCount: 0,
        isFinalFailure: false,
      );
      await pumpRelativeClausesScreen(tester, state: stateNoClause);
      expect(find.byKey(const ValueKey('clause_box')), findsNothing);
    });

    testWidgets('6. renders context card with blank before answering',
        (tester) async {
      await pumpRelativeClausesScreen(tester);
      expect(
        find.byKey(const ValueKey('relative_clauses_context_card')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('relative_clauses_context_card')),
          matching: find.textContaining('The scientist'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('7. renders quantum arena custom paint widget',
        (tester) async {
      await pumpRelativeClausesScreen(tester);
      expect(
        find.byKey(const ValueKey('relative_clauses_arena')),
        findsOneWidget,
      );
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('8. arena exists with active dimensions', (tester) async {
      await pumpRelativeClausesScreen(tester);
      final arena = tester.getRect(find.byKey(const ValueKey('relative_clauses_arena')));
      expect(arena.width, greaterThan(0));
      expect(arena.height, greaterThan(0));
    });

    testWidgets(
        '9. tapping correct node triggers sound and haptic and transitions to Phase 2',
        (tester) async {
      await pumpRelativeClausesScreen(tester);
      final arenaRect =
          tester.getRect(find.byKey(const ValueKey('relative_clauses_arena')));

      // Node 0 is at x: 50.0, y: arenaRect.height - 140.0
      final target = arenaRect.topLeft + Offset(50.0, arenaRect.height - 140.0);
      await tester.tapAt(target);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockSoundService.playCorrect()).called(1);
      verify(() => mockHapticService.heavy()).called(1);
      expect(
        find.byType(TypeToConfirmOverlay, skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('10. TypeToConfirmOverlay displays expected sentence text prompt',
        (tester) async {
      await pumpRelativeClausesScreen(tester);
      final arenaRect =
          tester.getRect(find.byKey(const ValueKey('relative_clauses_arena')));
      await tester.tapAt(arenaRect.topLeft + Offset(50.0, arenaRect.height - 140.0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.text(
          'Type the complete sentence to lock it in',
          skipOffstage: false,
        ),
        findsOneWidget,
      );
    });

    testWidgets(
        '11. submitting correct typed sentence completes quest and dispatches SubmitAnswer(true)',
        (tester) async {
      await pumpRelativeClausesScreen(tester);
      final arenaRect =
          tester.getRect(find.byKey(const ValueKey('relative_clauses_arena')));
      await tester.tapAt(arenaRect.topLeft + Offset(50.0, arenaRect.height - 140.0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.byType(TypeToConfirmOverlay, skipOffstage: false),
        findsOneWidget,
      );

      // Scroll down to bring TypeToConfirmOverlay fully onstage
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -800));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
      await tester.enterText(
        textField,
        'The scientist who discovered it won the Nobel prize.',
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final submitBtn = find.text('SUBMIT');
      expect(submitBtn, findsOneWidget);
      await tester.tap(submitBtn);
      // Wait for the 800ms delay in TypeToConfirmOverlay
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pump(const Duration(milliseconds: 200));

      verify(() => mockGrammarBloc.add(const SubmitAnswer(true))).called(1);
    });

    testWidgets(
        '12. skipping TypeToConfirmOverlay dispatches SubmitAnswer to bloc',
        (tester) async {
      await pumpRelativeClausesScreen(tester);
      final arenaRect =
          tester.getRect(find.byKey(const ValueKey('relative_clauses_arena')));
      await tester.tapAt(arenaRect.topLeft + Offset(50.0, arenaRect.height - 140.0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.byType(TypeToConfirmOverlay, skipOffstage: false),
        findsOneWidget,
      );

      // Scroll down to bring TypeToConfirmOverlay fully onstage
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -800));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final skipBtn = find.byType(GameSkipBypassButton);
      expect(skipBtn, findsOneWidget);
      await tester.tap(skipBtn);
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pump(const Duration(milliseconds: 200));

      verify(() => mockGrammarBloc.add(any())).called(greaterThanOrEqualTo(1));
    });

    testWidgets(
        '13. tapping wrong node plays wrong sound and dispatches SubmitAnswer(false)',
        (tester) async {
      await pumpRelativeClausesScreen(tester);
      final arenaRect =
          tester.getRect(find.byKey(const ValueKey('relative_clauses_arena')));

      // Node 1 is at x: arenaRect.width / 2, y: arenaRect.height - 110.0
      final target =
          arenaRect.topLeft + Offset(arenaRect.width / 2, arenaRect.height - 110.0);
      await tester.tapAt(target);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockHapticService.error()).called(1);
      verify(() => mockGrammarBloc.add(const SubmitAnswer(false))).called(1);
    });

    testWidgets('14. tapping arena after answered is ignored (answer lockout)',
        (tester) async {
      final stateAnswered = GrammarLoaded(
        quests: const [testQuest1],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.correct,
        hintUsed: false,
        wrongCount: 0,
        isFinalFailure: false,
      );
      await pumpRelativeClausesScreen(tester, state: stateAnswered);
      final arenaRect =
          tester.getRect(find.byKey(const ValueKey('relative_clauses_arena')));
      final target = arenaRect.topLeft + Offset(50.0, arenaRect.height - 140.0);
      await tester.tapAt(target);
      await tester.pump();

      verifyNever(() => mockSoundService.playCorrect());
      verifyNever(() => mockGrammarBloc.add(const SubmitAnswer(true)));
      verifyNever(() => mockGrammarBloc.add(const SubmitAnswer(false)));
    });

    testWidgets('15. panning across arena updates pointer position without error',
        (tester) async {
      await pumpRelativeClausesScreen(tester);
      final arenaFinder = find.byKey(const ValueKey('relative_clauses_arena'));
      expect(arenaFinder, findsOneWidget);

      await tester.drag(arenaFinder, const Offset(0, -30), warnIfMissed: false);
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('16. panning after answered is ignored', (tester) async {
      final stateAnswered = GrammarLoaded(
        quests: const [testQuest1],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.correct,
        hintUsed: false,
        wrongCount: 0,
        isFinalFailure: false,
      );
      await pumpRelativeClausesScreen(tester, state: stateAnswered);
      final arenaRect =
          tester.getRect(find.byKey(const ValueKey('relative_clauses_arena')));

      final start = arenaRect.topLeft + Offset(arenaRect.width / 2, 40.0);
      final end = arenaRect.topLeft + Offset(50.0, arenaRect.height - 140.0);

      final gesture = await tester.startGesture(start);
      await tester.pump();
      await gesture.moveTo(end);
      await tester.pump();
      await gesture.up();
      await tester.pump();

      verifyNever(() => mockSoundService.playCorrect());
      verifyNever(() => mockGrammarBloc.add(const SubmitAnswer(true)));
      verifyNever(() => mockGrammarBloc.add(const SubmitAnswer(false)));
    });

    testWidgets('17. displays correctly in compact height (< 700px)',
        (tester) async {
      await pumpRelativeClausesScreen(
        tester,
        size: const Size(360, 640),
      );
      expect(find.byType(RelativeClausesInstruction), findsOneWidget);
      expect(
        find.byKey(const ValueKey('relative_clauses_context_card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('relative_clauses_arena')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('18. renders correctly in dark mode', (tester) async {
      await pumpRelativeClausesScreen(
        tester,
        themeMode: ThemeMode.dark,
      );
      expect(find.byType(RelativeClausesScreen), findsOneWidget);
      expect(find.byType(RelativeClausesInstruction), findsOneWidget);
    });

    testWidgets('19. renders correctly in light mode', (tester) async {
      await pumpRelativeClausesScreen(
        tester,
        themeMode: ThemeMode.light,
      );
      expect(find.byType(RelativeClausesScreen), findsOneWidget);
      expect(find.byType(RelativeClausesInstruction), findsOneWidget);
    });

    testWidgets('20. onContinue callback triggers NextQuestion event',
        (tester) async {
      await pumpRelativeClausesScreen(tester);
      final arenaRect =
          tester.getRect(find.byKey(const ValueKey('relative_clauses_arena')));

      // Tap wrong node 1 to transition to answered state
      final target =
          arenaRect.topLeft + Offset(arenaRect.width / 2, arenaRect.height - 110.0);
      await tester.tapAt(target);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final continueFinder = find.descendant(
        of: find.byType(GameFeedbackCard),
        matching: find.byType(ScaleButton),
      );
      expect(continueFinder, findsOneWidget);
      await tester.tap(continueFinder);
      await tester.pump();

      verify(() => mockGrammarBloc.add(const NextQuestion())).called(1);
    });

    testWidgets('21. onHint callback triggers GrammarHintUsed event',
        (tester) async {
      await pumpRelativeClausesScreen(tester);

      final hintFinder = find.byType(QuestHintButton);
      expect(hintFinder, findsOneWidget);
      await tester.tap(hintFinder);
      await tester.pump();

      verify(() => mockGrammarBloc.add(const GrammarHintUsed())).called(1);
    });

    testWidgets(
        '22. level 1 briefing overlay is shown if not previously seen',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'has_seen_briefing_relativeClauses': false,
      });

      await pumpRelativeClausesScreen(tester, level: 1);

      expect(find.byType(GameBriefingLayer), findsOneWidget);
    });
  });
}
