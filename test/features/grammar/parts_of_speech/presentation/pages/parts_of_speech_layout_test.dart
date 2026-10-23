import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
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
import 'package:vowl/features/grammar/parts_of_speech/presentation/pages/parts_of_speech_screen.dart';
import 'package:vowl/features/grammar/parts_of_speech/presentation/widgets/speech_context_card.dart';
import 'package:vowl/features/grammar/parts_of_speech/presentation/widgets/speech_draggable_word.dart';
import 'package:vowl/features/grammar/parts_of_speech/presentation/widgets/speech_instruction.dart';
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
    id: 'pos_l1_q1',
    instruction: 'CLASSIFY THE PART OF SPEECH',
    difficulty: 1,
    subtype: GameSubtype.partsOfSpeech,
    sentence: 'The quick brown fox jumps over the lazy dog.',
    targetWord: 'quick',
    options: ['Noun', 'Verb', 'Adjective', 'Adverb'],
    correctAnswerIndex: 2, // 'Adjective'
    grammarRule: 'Adjectives modify nouns.',
    ruleExplanation: 'Describes a quality of the noun.',
  );

  const testQuestNoun = GrammarQuest(
    id: 'pos_l1_q2',
    instruction: 'FLICK OR TAP TO ANSWER',
    difficulty: 1,
    subtype: GameSubtype.partsOfSpeech,
    sentence: 'Honesty is the best policy.',
    targetWord: 'Honesty',
    options: ['Noun', 'Verb', 'Adj', 'Adv'],
    correctAnswerIndex: 0, // 'Noun'
  );

  const testQuestTransformations = GrammarQuest(
    id: 'pos_l1_q3',
    instruction: 'IDENTIFY WORD FORMS',
    difficulty: 1,
    subtype: GameSubtype.partsOfSpeech,
    sentence: 'She sings every morning.',
    targetWord: 'sings',
    options: ['Noun', 'Verb', 'Adj', 'Adv'],
    correctAnswerIndex: 1,
    transformations: ['sing', 'sang', 'sung'],
  );

  const testQuestFallbackOptions = GrammarQuest(
    id: 'pos_l1_q4',
    instruction: 'FLICK OR TAP TO ANSWER',
    difficulty: 1,
    subtype: GameSubtype.partsOfSpeech,
    sentence: 'The bird flew away.',
    targetWord: 'flew',
    options: [], // Triggers _fallbackOptions
    correctAnswerIndex: 1,
  );

  final testLoadedState = GrammarLoaded(
    quests: const [
      testQuest1,
      testQuestNoun,
      testQuestTransformations,
      testQuestFallbackOptions,
    ],
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
      'has_seen_briefing_partsOfSpeech': true,
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

  Future<void> pumpPartsOfSpeech(
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
            home: PartsOfSpeechScreen(
              level: level,
              gameType: GameSubtype.partsOfSpeech,
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  group('PartsOfSpeechScreen Layout & Mechanics', () {
    testWidgets(
      '1. renders initial quest with instruction, context card, 4 vortices, and draggable word chip',
      (tester) async {
        await pumpPartsOfSpeech(tester);

        expect(find.byType(SpeechInstruction), findsOneWidget);
        expect(
          find.byKey(const ValueKey('speech_instruction')),
          findsOneWidget,
        );
        expect(find.text('CLASSIFY THE PART OF SPEECH'), findsOneWidget);

        expect(find.byType(SpeechContextCard), findsOneWidget);
        expect(
          find.byKey(const ValueKey('speech_context_card')),
          findsOneWidget,
        );
        expect(
          find.text(
            'The quick brown fox jumps over the lazy dog.',
            findRichText: true,
          ),
          findsWidgets,
        );

        expect(find.byKey(const ValueKey('grammar_rule_box')), findsOneWidget);
        expect(find.text('Adjectives modify nouns.'), findsOneWidget);

        for (int i = 0; i < 4; i++) {
          expect(find.byKey(ValueKey('speech_vortex_$i')), findsOneWidget);
        }
        expect(find.text('NOUN'), findsOneWidget);
        expect(find.text('VERB'), findsOneWidget);
        expect(find.text('ADJECTIVE'), findsOneWidget);
        expect(find.text('ADVERB'), findsOneWidget);

        expect(find.byType(SpeechDraggableWord), findsOneWidget);
        expect(
          find.byKey(const ValueKey('speech_draggable_word')),
          findsOneWidget,
        );
        expect(find.text('quick'), findsOneWidget);
      },
    );

    testWidgets('2. hides grammar rule box when quest.grammarRule is null', (
      tester,
    ) async {
      final stateWithoutRule = GrammarLoaded(
        quests: const [testQuestNoun],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
        hintUsed: false,
        wrongCount: 0,
        isFinalFailure: false,
      );

      await pumpPartsOfSpeech(tester, state: stateWithoutRule);

      expect(find.byKey(const ValueKey('grammar_rule_box')), findsNothing);
      expect(find.byKey(const ValueKey('speech_context_card')), findsOneWidget);
      expect(
        find.text('Honesty is the best policy.', findRichText: true),
        findsWidgets,
      );
    });

    testWidgets(
      '3. renders quest transformations wrap inside context card when present',
      (tester) async {
        final stateTransformations = GrammarLoaded(
          quests: const [testQuestTransformations],
          currentIndex: 0,
          livesRemaining: 3,
          answerStatus: AnswerStatus.unanswered,
          hintUsed: false,
          wrongCount: 0,
          isFinalFailure: false,
        );

        await pumpPartsOfSpeech(tester, state: stateTransformations);

        expect(find.text('sing'), findsOneWidget);
        expect(find.text('sang'), findsOneWidget);
        expect(find.text('sung'), findsOneWidget);
      },
    );

    testWidgets(
      '4. renders fallback options when quest.options is empty or fewer than 4',
      (tester) async {
        final stateFallback = GrammarLoaded(
          quests: const [testQuestFallbackOptions],
          currentIndex: 0,
          livesRemaining: 3,
          answerStatus: AnswerStatus.unanswered,
          hintUsed: false,
          wrongCount: 0,
          isFinalFailure: false,
        );

        await pumpPartsOfSpeech(tester, state: stateFallback);

        expect(find.text('NOUN'), findsOneWidget);
        expect(find.text('VERB'), findsOneWidget);
        expect(find.text('ADJ'), findsOneWidget);
        expect(find.text('ADV'), findsOneWidget);
      },
    );

    testWidgets('5. tapping word chip toggles selection state', (tester) async {
      await pumpPartsOfSpeech(tester);

      final wordChip = find.byKey(const ValueKey('speech_draggable_word'));
      expect(wordChip, findsOneWidget);

      // Tap once to select
      await tester.tap(wordChip);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      verify(() => mockHapticService.selection()).called(1);

      // Tap again to unselect
      await tester.tap(wordChip);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      verify(() => mockHapticService.selection()).called(1);
    });

    testWidgets(
      '6. direct tap: tapping word then tapping correct vortex dispatches SubmitAnswer(true)',
      (tester) async {
        await pumpPartsOfSpeech(tester);

        final wordChip = find.byKey(const ValueKey('speech_draggable_word'));
        await tester.tap(wordChip);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Index 2 is 'Adjective' (correct answer for testQuest1)
        final vortex2 = find.byKey(const ValueKey('speech_vortex_2'));
        await tester.tap(vortex2);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

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
      '7. direct tap: tapping word then tapping incorrect vortex dispatches SubmitAnswer(false)',
      (tester) async {
        await pumpPartsOfSpeech(tester);

        final wordChip = find.byKey(const ValueKey('speech_draggable_word'));
        await tester.tap(wordChip);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Index 0 is 'Noun' (wrong answer for testQuest1)
        final vortex0 = find.byKey(const ValueKey('speech_vortex_0'));
        await tester.tap(vortex0);
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
      '8. tapping vortex without selecting word does not submit answer',
      (tester) async {
        await pumpPartsOfSpeech(tester);

        final vortex2 = find.byKey(const ValueKey('speech_vortex_2'));
        await tester.tap(vortex2);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        verifyNever(() => mockGrammarBloc.add(any(that: isA<SubmitAnswer>())));
      },
    );

    testWidgets(
      '9. drag interaction: dragging word chip past threshold towards correct vortex triggers SubmitAnswer(true)',
      (tester) async {
        await pumpPartsOfSpeech(tester);

        final wordChip = find.byKey(const ValueKey('speech_draggable_word'));
        expect(wordChip, findsOneWidget);

        // Drag towards bottom-left (dx < 0, dy > 0 -> index 2: Adjective)
        final gesture = await tester.startGesture(tester.getCenter(wordChip));
        await gesture.moveBy(const Offset(-40, 40));
        await tester.pump();
        await gesture.moveBy(const Offset(-100, 100));
        await tester.pump();
        await gesture.up();
        await tester.pump(const Duration(milliseconds: 200));

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
      '10. drag interaction: dragging word chip past threshold towards incorrect vortex triggers SubmitAnswer(false)',
      (tester) async {
        await pumpPartsOfSpeech(tester);

        final wordChip = find.byKey(const ValueKey('speech_draggable_word'));
        expect(wordChip, findsOneWidget);

        // Drag towards top-left (dx < 0, dy < 0 -> index 0: Noun)
        final gesture = await tester.startGesture(tester.getCenter(wordChip));
        await gesture.moveBy(const Offset(-40, -40));
        await tester.pump();
        await gesture.moveBy(const Offset(-100, -100));
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
      '11. drag interaction: dragging word chip within threshold does not submit answer',
      (tester) async {
        await pumpPartsOfSpeech(tester);

        final wordChip = find.byKey(const ValueKey('speech_draggable_word'));
        // Minor drag under threshold
        await tester.drag(wordChip, const Offset(-10, -10));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        verifyNever(() => mockGrammarBloc.add(any(that: isA<SubmitAnswer>())));
      },
    );

    testWidgets(
      '12. lockout: when isAnswered is true, draggable word is hidden from vortex area preventing re-answering',
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

        await pumpPartsOfSpeech(tester, state: answeredState);

        expect(
          find.byKey(const ValueKey('speech_draggable_word')),
          findsNothing,
        );
      },
    );

    testWidgets(
      '13. shimmer loading: displays GameShimmerLoading when state is not loaded',
      (tester) async {
        await pumpPartsOfSpeech(tester, state: const GrammarInitial());

        expect(find.byType(GameShimmerLoading), findsOneWidget);
        expect(
          find.byKey(const ValueKey('speech_draggable_word')),
          findsNothing,
        );
      },
    );

    testWidgets(
      '14. hint button dispatches GrammarHintUsed once without double-dispatch',
      (tester) async {
        await pumpPartsOfSpeech(tester);

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
        'has_seen_briefing_partsOfSpeech': false,
      });

      await pumpPartsOfSpeech(tester, level: 1);

      expect(find.byType(GameBriefingLayer), findsOneWidget);
    });

    testWidgets(
      '16. reduced motion: lowAnimationModeOverride gates infinite vortex rotation and draggable scale animation',
      (tester) async {
        VowlMotion.lowAnimationModeOverride.value = true;
        await pumpPartsOfSpeech(tester);

        expect(find.byType(PartsOfSpeechScreen), findsOneWidget);
        expect(
          find.byKey(const ValueKey('speech_draggable_word')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '17. compact viewport (320x568) renders cleanly without overflow',
      (tester) async {
        await pumpPartsOfSpeech(tester, width: 320, height: 568);

        expect(find.byType(PartsOfSpeechScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '18. tablet viewport (768x1024) renders cleanly with proper layout',
      (tester) async {
        await pumpPartsOfSpeech(tester, width: 768, height: 1024);

        expect(find.byType(PartsOfSpeechScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('19. dark mode renders correctly with dark theme styling', (
      tester,
    ) async {
      await pumpPartsOfSpeech(tester, themeMode: ThemeMode.dark);

      expect(find.byType(PartsOfSpeechScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('20. final failure state displays game over layout cleanly', (
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

      await pumpPartsOfSpeech(tester, state: failedState);

      expect(find.byType(PartsOfSpeechScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      '21. instruction text is center aligned, wraps without ellipses, and replaces robotic text',
      (tester) async {
        const roboticQuest = GrammarQuest(
          id: 'pos_robotic',
          instruction: 'IDENTIFY THE FUNCTION',
          difficulty: 1,
          subtype: GameSubtype.partsOfSpeech,
          sentence: 'The dog barked loudly.',
          targetWord: 'loudly',
          options: ['Noun', 'Verb', 'Adj', 'Adv'],
          correctAnswerIndex: 3,
        );

        final roboticState = GrammarLoaded(
          quests: const [roboticQuest],
          currentIndex: 0,
          livesRemaining: 3,
          answerStatus: AnswerStatus.unanswered,
          hintUsed: false,
          wrongCount: 0,
          isFinalFailure: false,
        );

        await pumpPartsOfSpeech(tester, state: roboticState);

        // Buzzword/robotic instruction replaced with natural text
        expect(find.text('Choose the correct part of speech'), findsOneWidget);

        // Verify Text widget properties: center aligned and no ellipsis
        final instructionTextFinder = find.descendant(
          of: find.byType(SpeechInstruction),
          matching: find.byType(Text),
        );
        expect(instructionTextFinder, findsOneWidget);
        final instructionText = tester.widget<Text>(instructionTextFinder);
        expect(instructionText.textAlign, TextAlign.center);
        expect(instructionText.overflow, isNot(TextOverflow.ellipsis));
      },
    );

    testWidgets('22. grammar rule displays without ellipses and wraps cleanly', (
      tester,
    ) async {
      const longRuleQuest = GrammarQuest(
        id: 'pos_long_rule',
        instruction: 'CLASSIFY THE PART OF SPEECH',
        difficulty: 1,
        subtype: GameSubtype.partsOfSpeech,
        sentence: 'She sings every morning.',
        targetWord: 'sings',
        options: ['Noun', 'Verb', 'Adj', 'Adv'],
        correctAnswerIndex: 1,
        grammarRule:
            'Action verbs express physical or mental actions taken by the subject of a clause.',
      );

      final longRuleState = GrammarLoaded(
        quests: const [longRuleQuest],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
        hintUsed: false,
        wrongCount: 0,
        isFinalFailure: false,
      );

      await pumpPartsOfSpeech(tester, state: longRuleState);

      final ruleTextFinder = find.descendant(
        of: find.byKey(const ValueKey('grammar_rule_box')),
        matching: find.byType(Text),
      );
      expect(ruleTextFinder, findsOneWidget);
      final ruleText = tester.widget<Text>(ruleTextFinder);
      expect(ruleText.textAlign, TextAlign.center);
      expect(ruleText.overflow, isNot(TextOverflow.ellipsis));
      expect(ruleText.maxLines, isNull);
    });
  });
}
