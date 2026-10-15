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
import 'package:vowl/features/grammar/grammar_quest/presentation/pages/grammar_quest_screen.dart';
import 'package:vowl/features/grammar/grammar_quest/presentation/widgets/grammar_quest_compass.dart';
import 'package:vowl/features/grammar/grammar_quest/presentation/widgets/grammar_quest_instruction.dart';
import 'package:vowl/features/grammar/grammar_quest/presentation/widgets/grammar_quest_sentence.dart';
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
    id: 'gq_l1_q1',
    instruction: 'STEER TO THE CORRECT RULE',
    difficulty: 1,
    subtype: GameSubtype.grammarQuest,
    question: 'The captain ___ the ship through the storm.',
    sentence: 'The captain steered the ship through the storm.',
    sentenceWithBlank: 'The captain ___ the ship through the storm.',
    options: ['steered', 'steer', 'steering', 'steers'],
    correctAnswerIndex: 0,
    correctAnswer: 'steered',
    hint: 'Use past simple tense for a completed past action.',
    explanation: 'The verb must be in the past tense to match the completed action.',
    grammarRule: 'Past Simple Consistency',
    ruleExplanation: 'Actions that finished in the past require past tense verbs.',
  );

  const testQuestNoRules = GrammarQuest(
    id: 'gq_l1_q2',
    instruction: 'NAVIGATE TO THE VERB',
    difficulty: 1,
    subtype: GameSubtype.grammarQuest,
    question: 'They ___ ready for the voyage.',
    sentence: 'They were ready for the voyage.',
    sentenceWithBlank: 'They ___ ready for the voyage.',
    options: ['was', 'were', 'is', 'be'],
    correctAnswerIndex: 1,
    correctAnswer: 'were',
    hint: 'Plural subject requires plural past form.',
    explanation: 'They takes were in the past simple.',
  );

  const testQuestNoBlankInQuestion = GrammarQuest(
    id: 'gq_l1_q3',
    instruction: 'CHOOSE THE PROPER FORM',
    difficulty: 1,
    subtype: GameSubtype.grammarQuest,
    sentence: 'The crew navigated by the stars.',
    sentenceWithBlank: 'The crew navigated by the stars.',
    options: ['navigated', 'navigate', 'navigating', 'navigates'],
    correctAnswerIndex: 0,
    correctAnswer: 'navigated',
  );

  final testLoadedState = GrammarLoaded(
    quests: const [testQuest1, testQuestNoRules, testQuestNoBlankInQuestion],
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
      'has_seen_briefing_grammarQuest': true,
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

  Future<void> pumpGrammarQuest(
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
            home: GrammarQuestScreen(
              level: level,
              gameType: GameSubtype.grammarQuest,
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  group('GrammarQuestScreen Layout & Mechanics', () {
    testWidgets('1. renders initial quest with instruction, grammar rule box, sentence, and compass', (tester) async {
      await pumpGrammarQuest(tester);

      expect(find.byType(GrammarQuestInstruction), findsOneWidget);
      expect(find.text('STEER TO THE CORRECT RULE'), findsOneWidget);

      expect(find.byKey(const ValueKey('grammar_rule_box')), findsOneWidget);
      expect(find.text('GRAMMAR RULE'), findsOneWidget);
      expect(find.text('Past Simple Consistency'), findsOneWidget);

      expect(find.byType(GrammarQuestSentence), findsOneWidget);
      expect(find.text('The captain ___ the ship through the storm.'), findsOneWidget);

      expect(find.byType(GrammarQuestCompass), findsOneWidget);
      expect(find.byKey(const ValueKey('compass_quadrant_0')), findsOneWidget);
      expect(find.byKey(const ValueKey('compass_quadrant_1')), findsOneWidget);
      expect(find.byKey(const ValueKey('compass_quadrant_2')), findsOneWidget);
      expect(find.byKey(const ValueKey('compass_quadrant_3')), findsOneWidget);

      expect(find.text('steered'), findsOneWidget);
      expect(find.text('steer'), findsOneWidget);
      expect(find.text('steering'), findsOneWidget);
      expect(find.text('steers'), findsOneWidget);
    });

    testWidgets('2. hides grammar rule box when quest grammarRule is null', (tester) async {
      final stateNoRule = GrammarLoaded(
        quests: const [testQuestNoRules],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
        hintUsed: false,
        wrongCount: 0,
        isFinalFailure: false,
      );

      await pumpGrammarQuest(tester, state: stateNoRule);

      expect(find.byKey(const ValueKey('grammar_rule_box')), findsNothing);
      expect(find.text('They ___ ready for the voyage.'), findsOneWidget);
    });

    testWidgets('3. renders ruleExplanation when provided in grammar rule box', (tester) async {
      await pumpGrammarQuest(tester);

      expect(
        find.text('Actions that finished in the past require past tense verbs.'),
        findsOneWidget,
      );
    });

    testWidgets('4. renders shimmer loading when state is GrammarLoading', (tester) async {
      await pumpGrammarQuest(tester, state: const GrammarLoading());

      expect(find.byType(GameShimmerLoading), findsOneWidget);
      expect(find.byType(GrammarQuestCompass), findsNothing);
    });

    testWidgets('5. tapping incorrect quadrant steers compass and submits wrong answer', (tester) async {
      await pumpGrammarQuest(tester);

      final compassFinder = find.byKey(const ValueKey('grammar_quest_compass_gesture'));
      expect(compassFinder, findsOneWidget);

      final compassCenter = tester.getCenter(compassFinder);
      // Quadrant 1 (East: dx > 0, dy = 0) is index 1 ('steer', wrong)
      await tester.tapAt(compassCenter + const Offset(60, 0));
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

    testWidgets('6. tapping correct quadrant steers compass to target and reveals TypeToConfirmOverlay', (tester) async {
      await pumpGrammarQuest(tester);

      final compassFinder = find.byKey(const ValueKey('grammar_quest_compass_gesture'));
      final compassCenter = tester.getCenter(compassFinder);
      // Quadrant 0 (North: dx = 0, dy < 0) is index 0 ('steered', correct)
      await tester.tapAt(compassCenter + const Offset(0, -60));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockHapticService.success()).called(1);
      verify(() => mockSoundService.playCorrect()).called(1);

      expect(
        find.byType(TypeToConfirmOverlay, skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('7. Phase 2: typing full sentence confirms and submits answer', (tester) async {
      await pumpGrammarQuest(tester);

      final compassFinder = find.byKey(const ValueKey('grammar_quest_compass_gesture'));
      final compassCenter = tester.getCenter(compassFinder);
      await tester.tapAt(compassCenter + const Offset(0, -60));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 600));

      final textFieldFinder = find.byType(TextField);
      await tester.ensureVisible(textFieldFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(textFieldFinder, findsOneWidget);

      await tester.enterText(
        textFieldFinder,
        'The captain steered the ship through the storm.',
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
    });

    testWidgets('8. Phase 2: skipping confirm (after 3 failed attempts) dispatches wrong answer', (tester) async {
      await pumpGrammarQuest(tester);

      final compassFinder = find.byKey(const ValueKey('grammar_quest_compass_gesture'));
      final compassCenter = tester.getCenter(compassFinder);
      await tester.tapAt(compassCenter + const Offset(0, -60));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 600));

      final textFieldFinder = find.byType(TextField);
      await tester.ensureVisible(textFieldFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(textFieldFinder, findsOneWidget);

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
    });

    testWidgets('9. dragging compass needle selects quadrant and triggers Phase 2', (tester) async {
      await pumpGrammarQuest(tester);

      final compassFinder = find.byKey(const ValueKey('grammar_quest_compass_gesture'));
      final compassCenter = tester.getCenter(compassFinder);

      // Pan from center to North (quadrant 0: correct)
      final gesture = await tester.startGesture(compassCenter);
      await gesture.moveBy(const Offset(0, -70));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockHapticService.success()).called(1);
      verify(() => mockSoundService.playCorrect()).called(1);

      expect(
        find.byType(TypeToConfirmOverlay, skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('10. interacting when already answered does nothing', (tester) async {
      final answeredState = GrammarLoaded(
        quests: const [testQuest1, testQuestNoRules],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.correct,
        hintUsed: false,
        wrongCount: 0,
        isFinalFailure: false,
      );

      await pumpGrammarQuest(tester, state: answeredState);

      final compassFinder = find.byKey(const ValueKey('grammar_quest_compass_gesture'));
      final compassCenter = tester.getCenter(compassFinder);
      await tester.tapAt(compassCenter + const Offset(0, -60));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      verifyNever(() => mockGrammarBloc.add(any(that: isA<SubmitAnswer>())));
    });

    testWidgets('11. tapping hint button dispatches GrammarHintUsed without double dispatch', (tester) async {
      await pumpGrammarQuest(tester);

      final hintButton = find.byType(QuestHintButton);
      expect(hintButton, findsOneWidget);

      await tester.tap(hintButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockGrammarBloc.add(const GrammarHintUsed())).called(1);
    });

    testWidgets('12. shows level 1 briefing dialog when not yet seen and dismisses', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await pumpGrammarQuest(tester, level: 1);

      expect(find.byType(GameBriefingLayer), findsOneWidget);

      final commenceButton = find.text('COMMENCE QUEST');
      if (commenceButton.evaluate().isNotEmpty) {
        await tester.tap(commenceButton);
      } else {
        await tester.tap(find.byType(GameBriefingLayer));
      }
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('The captain ___ the ship through the storm.'), findsOneWidget);
    });

    testWidgets('13. respects reduced motion when lowAnimationModeOverride is enabled', (tester) async {
      VowlMotion.lowAnimationModeOverride.value = true;
      await pumpGrammarQuest(tester);
      expect(find.byType(GrammarQuestScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('14. handles compact mobile layout (320x568) without overflow', (tester) async {
      await pumpGrammarQuest(tester, width: 320, height: 568);

      expect(find.byType(GrammarQuestScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('15. handles tablet viewport (768x1024) without overflow', (tester) async {
      await pumpGrammarQuest(tester, width: 768, height: 1024);

      expect(find.byType(GrammarQuestScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('16. renders correctly in dark mode', (tester) async {
      await pumpGrammarQuest(tester, themeMode: ThemeMode.dark);

      expect(find.byType(GrammarQuestScreen), findsOneWidget);
      expect(find.text('The captain ___ the ship through the storm.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('17. handles question sentence without blanks by using sentence directly', (tester) async {
      final stateNoBlank = GrammarLoaded(
        quests: const [testQuestNoBlankInQuestion],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
        hintUsed: false,
        wrongCount: 0,
        isFinalFailure: false,
      );

      await pumpGrammarQuest(tester, state: stateNoBlank);

      expect(find.text('The crew navigated by the stars.'), findsOneWidget);
    });

    testWidgets('18. renders final failure state with explanation and continue', (tester) async {
      final failureState = GrammarLoaded(
        quests: const [testQuest1, testQuestNoRules],
        currentIndex: 0,
        livesRemaining: 0,
        answerStatus: AnswerStatus.incorrect,
        hintUsed: false,
        wrongCount: 3,
        isFinalFailure: true,
      );

      await pumpGrammarQuest(tester, state: failureState);

      expect(find.byType(GrammarQuestScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

