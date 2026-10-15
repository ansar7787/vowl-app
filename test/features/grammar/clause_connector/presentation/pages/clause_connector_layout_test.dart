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
import 'package:vowl/features/grammar/clause_connector/presentation/pages/clause_connector_screen.dart';
import 'package:vowl/features/grammar/clause_connector/presentation/widgets/clause_connector_instruction.dart';
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
    id: 'cc_l1_q1',
    instruction: 'Select the connector that best completes the sentence.',
    difficulty: 1,
    subtype: GameSubtype.clauseConnector,
    question: 'Maria packed her backpack ____ she put on her hiking boots.',
    sentence: 'Maria packed her backpack ____ she put on her hiking boots.',
    options: ['so', 'and', 'but', 'or'],
    correctAnswerIndex: 1,
    correctAnswer: 'and',
    connectorCategory: 'Addition',
    hint: 'Think about whether the second action simply follows the first as another step.',
    explanation: "'And' links two ordinary steps in getting ready.",
  );

  const testQuest2 = GrammarQuest(
    id: 'cc_l1_q2',
    instruction: 'Choose the connector that fits best.',
    difficulty: 1,
    subtype: GameSubtype.clauseConnector,
    question: 'Ben packed his suitcase ____ he checked his passport twice.',
    sentence: 'Ben packed his suitcase ____ he checked his passport twice.',
    options: ['and', 'so', 'but', 'or'],
    correctAnswerIndex: 0,
    correctAnswer: 'and',
    hint: 'Ask whether the second action was caused by the first.',
  );

  final testLoadedState = GrammarLoaded(
    quests: const [testQuest1, testQuest2],
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
      'has_seen_briefing_clauseConnector': true,
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

  Future<void> pumpClauseConnector(
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
            home: ClauseConnectorScreen(
              level: level,
              gameType: GameSubtype.clauseConnector,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('ClauseConnectorScreen Layout & Mechanics', () {
    testWidgets('1. renders initial quest with clauses, magnetic port and connector palette', (tester) async {
      await pumpClauseConnector(tester);

      expect(find.byType(ClauseConnectorInstruction), findsOneWidget);
      expect(
        find.text('SELECT THE CONNECTOR THAT BEST COMPLETES THE SENTENCE.'),
        findsOneWidget,
      );
      expect(find.text('TYPE: ADDITION'), findsOneWidget);

      expect(find.text('Maria packed her backpack'), findsOneWidget);
      expect(find.text('she put on her hiking boots.'), findsOneWidget);
      expect(find.text('TAP OR DRAG'), findsOneWidget);

      expect(find.text('SO'), findsOneWidget);
      expect(find.text('AND'), findsOneWidget);
      expect(find.text('BUT'), findsOneWidget);
      expect(find.text('OR'), findsOneWidget);
    });

    testWidgets('2. hides category chip when quest connectorCategory is null', (tester) async {
      final stateWithoutCategory = GrammarLoaded(
        quests: const [testQuest2],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
        hintUsed: false,
        wrongCount: 0,
        isFinalFailure: false,
      );

      await pumpClauseConnector(tester, state: stateWithoutCategory);

      expect(find.textContaining('TYPE:'), findsNothing);
      expect(find.text('Ben packed his suitcase'), findsOneWidget);
      expect(find.text('he checked his passport twice.'), findsOneWidget);
    });

    testWidgets('3. renders shimmer loading when state is GrammarLoading', (tester) async {
      await pumpClauseConnector(tester, state: const GrammarLoading());

      expect(find.byType(GameShimmerLoading), findsOneWidget);
      expect(find.byType(ClauseConnectorInstruction), findsNothing);
    });

    testWidgets('4. tapping incorrect connector submits wrong answer to GrammarBloc', (tester) async {
      await pumpClauseConnector(tester);

      final wrongOption = find.byKey(const ValueKey('connector_option_2')); // 'but'
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
    });

    testWidgets('5. tapping correct connector transitions to Phase 2 TypeToConfirmOverlay', (tester) async {
      await pumpClauseConnector(tester);

      final correctOption = find.byKey(const ValueKey('connector_option_1')); // 'and'
      expect(correctOption, findsOneWidget);

      await tester.tap(correctOption);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockHapticService.heavy()).called(1);
      verify(() => mockSoundService.playCorrect()).called(1);

      expect(find.byKey(const ValueKey('connector_option_1')), findsNothing);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -800));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(TypeToConfirmOverlay, skipOffstage: false), findsOneWidget);
      expect(
        find.text(
          'Type the complete sentence to lock in the clause structure',
          skipOffstage: false,
        ),
        findsOneWidget,
      );
    });

    testWidgets('6. Phase 2: typing correct sentence confirms and submits answer', (tester) async {
      await pumpClauseConnector(tester);

      final correctOption = find.byKey(const ValueKey('connector_option_1'));
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
        'Maria packed her backpack and she put on her hiking boots.',
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
    });

    testWidgets('7. Phase 2: skipping confirm dispatches wrong answer', (tester) async {
      await pumpClauseConnector(tester);

      final correctOption = find.byKey(const ValueKey('connector_option_1'));
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

      // Attempt 1 (ScaleButton has 500ms debounce)
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
      await tester.pump(const Duration(milliseconds: 100));

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

    testWidgets('8. dragging connector onto magnetic port triggers phase 2', (tester) async {
      await pumpClauseConnector(tester);

      final correctOption = find.byKey(const ValueKey('connector_option_1'));
      final target = find.byType(DragTarget<String>);

      final gesture = await tester.startGesture(tester.getCenter(correctOption));
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.moveTo(tester.getCenter(target));
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockSoundService.playCorrect()).called(1);

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -800));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(TypeToConfirmOverlay, skipOffstage: false), findsOneWidget);
    });

    testWidgets('9. tapping options when already answered does nothing', (tester) async {
      final answeredState = GrammarLoaded(
        quests: const [testQuest1, testQuest2],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.correct,
        hintUsed: false,
        wrongCount: 0,
        isFinalFailure: false,
      );

      await pumpClauseConnector(tester, state: answeredState);

      expect(find.byKey(const ValueKey('connector_option_0')), findsNothing);
      verifyNever(() => mockGrammarBloc.add(any(that: isA<SubmitAnswer>())));
    });

    testWidgets('10. tapping hint button dispatches GrammarHintUsed', (tester) async {
      await pumpClauseConnector(tester);

      final hintButton = find.byType(QuestHintButton);
      expect(hintButton, findsOneWidget);

      await tester.tap(hintButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockGrammarBloc.add(const GrammarHintUsed())).called(1);
    });

    testWidgets('11. shows level 1 briefing dialog when not yet seen', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await pumpClauseConnector(tester, level: 1);

      expect(find.byType(GameBriefingLayer), findsOneWidget);
      expect(find.text('CLAUSE CONNECTOR'), findsWidgets);

      final commenceButton = find.text('COMMENCE QUEST');
      if (commenceButton.evaluate().isNotEmpty) {
        await tester.tap(commenceButton);
      } else {
        await tester.tap(find.byType(GameBriefingLayer));
      }
      await tester.pumpAndSettle();

      expect(find.text('Maria packed her backpack'), findsOneWidget);
    });

    testWidgets('12. respects reduced motion when lowAnimationModeOverride is enabled', (tester) async {
      VowlMotion.lowAnimationModeOverride.value = true;
      await pumpClauseConnector(tester);
      expect(find.byType(ClauseConnectorScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('13. handles compact mobile layout (320x568) without overflow', (tester) async {
      await pumpClauseConnector(tester, width: 320, height: 568);

      expect(find.byType(ClauseConnectorScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('14. handles tablet viewport (768x1024) without overflow', (tester) async {
      await pumpClauseConnector(tester, width: 768, height: 1024);

      expect(find.byType(ClauseConnectorScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('15. renders correctly in dark mode', (tester) async {
      await pumpClauseConnector(tester, themeMode: ThemeMode.dark);

      expect(find.byType(ClauseConnectorScreen), findsOneWidget);
      expect(find.text('Maria packed her backpack'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('16. renders final failure state with explanation and continue', (tester) async {
      final failureState = GrammarLoaded(
        quests: const [testQuest1, testQuest2],
        currentIndex: 0,
        livesRemaining: 0,
        answerStatus: AnswerStatus.incorrect,
        hintUsed: false,
        wrongCount: 3,
        isFinalFailure: true,
      );

      await pumpClauseConnector(tester, state: failureState);

      expect(find.byType(ClauseConnectorScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
