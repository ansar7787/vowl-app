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
import 'package:vowl/features/grammar/direct_indirect_speech/presentation/pages/direct_indirect_speech_screen.dart';
import 'package:vowl/features/grammar/direct_indirect_speech/presentation/widgets/direct_indirect_speech_instruction.dart';
import 'package:vowl/features/grammar/direct_indirect_speech/presentation/widgets/direct_indirect_speech_mirror.dart';
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
    id: 'dis_l1_q1',
    instruction: 'TRANSFORM THE SPEECH',
    difficulty: 1,
    subtype: GameSubtype.directIndirectSpeech,
    question:
        'Convert to reported speech: Maria said, "I walk to school every day."',
    sentence: 'Maria said, "I walk to school every day."',
    sentenceWithBlank: 'Maria said, "I walk to school every day."',
    options: [
      'Maria said that she walks to school every day.',
      'Maria said that I walked to school every day.',
      'Maria said that she walked to school every day.',
    ],
    correctAnswerIndex: 2,
    correctAnswer: 'Maria said that she walked to school every day.',
    hint:
        "Check what happens to the verb tense and to the pronoun 'I' when Maria's own words are reported.",
    explanation:
        "'Walk' backshifts to 'walked', and 'I' becomes 'she' because Maria is the speaker being reported.",
    grammarRule: 'Tense Backshift',
    changesList: ["'walk' → 'walked'", "'I' → 'she'"],
  );

  const testQuestNoRules = GrammarQuest(
    id: 'dis_l1_q2',
    instruction: 'CHOOSE THE REPORTED SPEECH',
    difficulty: 1,
    subtype: GameSubtype.directIndirectSpeech,
    question: 'Convert to reported speech: Tom said, "I like ice cream."',
    sentence: 'Tom said, "I like ice cream."',
    sentenceWithBlank: 'Tom said, "I like ice cream."',
    options: [
      'Tom said that he liked ice cream.',
      'Tom said that I liked ice cream.',
    ],
    correctAnswerIndex: 0,
    correctAnswer: 'Tom said that he liked ice cream.',
  );

  const testQuestAsciiArrow = GrammarQuest(
    id: 'dis_l1_q3',
    instruction: 'TRANSFORM THE SPEECH',
    difficulty: 1,
    subtype: GameSubtype.directIndirectSpeech,
    question: 'Convert to reported speech: Sara said, "I can swim."',
    sentence: 'Sara said, "I can swim."',
    sentenceWithBlank: 'Sara said, "I can swim."',
    options: ['Sara said that she could swim.', 'Sara said that she can swim.'],
    correctAnswerIndex: 0,
    correctAnswer: 'Sara said that she could swim.',
    grammarRule: 'Modal Shift',
    changesList: ['can -> could'],
  );

  const testQuestSentenceFallback = GrammarQuest(
    id: 'dis_l1_q4',
    instruction: 'TRANSFORM THE SPEECH',
    difficulty: 1,
    subtype: GameSubtype.directIndirectSpeech,
    prompt: 'Direct speech: He shouted, "Help me!"',
    options: ['He shouted to help him.', 'He shouted to help me.'],
    correctAnswerIndex: 0,
    correctAnswer: 'He shouted to help him.',
  );

  final testLoadedState = GrammarLoaded(
    quests: const [
      testQuest1,
      testQuestNoRules,
      testQuestAsciiArrow,
      testQuestSentenceFallback,
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
      'has_seen_briefing_directIndirectSpeech': true,
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

  Future<void> pumpDirectIndirectSpeech(
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
            home: DirectIndirectSpeechScreen(
              level: level,
              gameType: GameSubtype.directIndirectSpeech,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('DirectIndirectSpeechScreen Layout & Mechanics', () {
    testWidgets(
      '1. renders initial quest with instruction, mirror, rule box, and reflection chips',
      (tester) async {
        await pumpDirectIndirectSpeech(tester);

        expect(find.byType(DirectIndirectSpeechInstruction), findsOneWidget);
        expect(find.text('Transform the speech'), findsOneWidget);

        expect(find.byType(DirectIndirectSpeechMirror), findsOneWidget);
        expect(find.byKey(const ValueKey('speech_mirror')), findsOneWidget);
        expect(find.text('Direct Speech'), findsOneWidget);
        expect(
          find.text('Maria said, "I walk to school every day."'),
          findsOneWidget,
        );

        expect(
          find.byKey(const ValueKey('rule_and_changes_box')),
          findsOneWidget,
        );
        expect(find.text('Tense Backshift'), findsOneWidget);
        expect(find.text("'walk'"), findsOneWidget);
        expect(find.text("'walked'"), findsOneWidget);
        expect(find.text("'I'"), findsOneWidget);
        expect(find.text("'she'"), findsOneWidget);

        expect(find.byKey(const ValueKey('reflection_chip_0')), findsOneWidget);
        expect(find.byKey(const ValueKey('reflection_chip_1')), findsOneWidget);
        expect(find.byKey(const ValueKey('reflection_chip_2')), findsOneWidget);
        expect(
          find.text('Maria said that she walked to school every day.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '2. hides rule and changes box when both grammarRule and changesList are null',
      (tester) async {
        final stateNoRules = GrammarLoaded(
          quests: const [testQuestNoRules],
          currentIndex: 0,
          livesRemaining: 3,
          answerStatus: AnswerStatus.unanswered,
          hintUsed: false,
          wrongCount: 0,
          isFinalFailure: false,
        );

        await pumpDirectIndirectSpeech(tester, state: stateNoRules);

        expect(
          find.byKey(const ValueKey('rule_and_changes_box')),
          findsNothing,
        );
        expect(find.text('Tom said, "I like ice cream."'), findsOneWidget);
        expect(find.text('Tom said that he liked ice cream.'), findsOneWidget);
      },
    );

    testWidgets(
      '3. correctly splits and renders changes using ascii arrow (->)',
      (tester) async {
        final stateAscii = GrammarLoaded(
          quests: const [testQuestAsciiArrow],
          currentIndex: 0,
          livesRemaining: 3,
          answerStatus: AnswerStatus.unanswered,
          hintUsed: false,
          wrongCount: 0,
          isFinalFailure: false,
        );

        await pumpDirectIndirectSpeech(tester, state: stateAscii);

        expect(
          find.byKey(const ValueKey('rule_and_changes_box')),
          findsOneWidget,
        );
        expect(find.text('Modal Shift'), findsOneWidget);
        expect(find.text('can'), findsOneWidget);
        expect(find.text('could'), findsOneWidget);
      },
    );

    testWidgets('4. renders shimmer loading when state is GrammarLoading', (
      tester,
    ) async {
      await pumpDirectIndirectSpeech(tester, state: const GrammarLoading());

      expect(find.byType(GameShimmerLoading), findsOneWidget);
      expect(find.byType(DirectIndirectSpeechMirror), findsNothing);
    });

    testWidgets(
      '5. tapping incorrect reflection flips mirror and submits wrong answer',
      (tester) async {
        await pumpDirectIndirectSpeech(tester);

        final wrongChip = find.byKey(const ValueKey('reflection_chip_0'));
        expect(wrongChip, findsOneWidget);

        await tester.tap(wrongChip);
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
      '6. tapping correct reflection flips mirror to REPORTED SPEECH and reveals TypeToConfirmOverlay',
      (tester) async {
        await pumpDirectIndirectSpeech(tester);

        final correctChip = find.byKey(const ValueKey('reflection_chip_2'));
        expect(correctChip, findsOneWidget);

        await tester.ensureVisible(correctChip);
        await tester.pumpAndSettle();

        await tester.tap(correctChip);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 600));

        verify(() => mockHapticService.success()).called(1);
        verify(() => mockSoundService.playCorrect()).called(1);

        expect(
          find.byType(TypeToConfirmOverlay, skipOffstage: false),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '7. Phase 2: typing correct indirect speech confirms and submits answer',
      (tester) async {
        await pumpDirectIndirectSpeech(tester);

        final correctChip = find.byKey(const ValueKey('reflection_chip_2'));
        await tester.ensureVisible(correctChip);
        await tester.pumpAndSettle();

        await tester.tap(correctChip);
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
          'Maria said that she walked to school every day.',
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
        await pumpDirectIndirectSpeech(tester);

        final correctChip = find.byKey(const ValueKey('reflection_chip_2'));
        await tester.ensureVisible(correctChip);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        await tester.tap(correctChip);
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

        // Attempt 1 (ScaleButton 500ms debounce)
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
      },
    );

    testWidgets('9. interacting when already answered does nothing', (
      tester,
    ) async {
      final answeredState = GrammarLoaded(
        quests: const [testQuest1, testQuestNoRules],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.correct,
        hintUsed: false,
        wrongCount: 0,
        isFinalFailure: false,
      );

      await pumpDirectIndirectSpeech(tester, state: answeredState);

      final chipFinder = find.byKey(const ValueKey('reflection_chip_0'));
      expect(chipFinder, findsOneWidget);

      await tester.tap(chipFinder, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      verifyNever(() => mockGrammarBloc.add(any(that: isA<SubmitAnswer>())));
    });

    testWidgets(
      '10. tapping hint button dispatches GrammarHintUsed without double dispatch',
      (tester) async {
        await pumpDirectIndirectSpeech(tester);

        final hintButton = find.byType(QuestHintButton);
        expect(hintButton, findsOneWidget);

        await tester.tap(hintButton);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        verify(() => mockGrammarBloc.add(const GrammarHintUsed())).called(1);
      },
    );

    testWidgets(
      '11. shows level 1 briefing dialog when not yet seen and dismisses',
      (tester) async {
        SharedPreferences.setMockInitialValues({});

        await pumpDirectIndirectSpeech(tester, level: 1);

        expect(find.byType(GameBriefingLayer), findsOneWidget);

        final commenceButton = find.text('COMMENCE QUEST');
        if (commenceButton.evaluate().isNotEmpty) {
          await tester.tap(commenceButton);
        } else {
          await tester.tap(find.byType(GameBriefingLayer));
        }
        await tester.pumpAndSettle();

        expect(
          find.text('Maria said, "I walk to school every day."'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '12. respects reduced motion when lowAnimationModeOverride is enabled',
      (tester) async {
        VowlMotion.lowAnimationModeOverride.value = true;
        await pumpDirectIndirectSpeech(tester);
        expect(find.byType(DirectIndirectSpeechScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '13. handles compact mobile layout (320x568) without overflow',
      (tester) async {
        await pumpDirectIndirectSpeech(tester, width: 320, height: 568);

        expect(find.byType(DirectIndirectSpeechScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('14. handles tablet viewport (768x1024) without overflow', (
      tester,
    ) async {
      await pumpDirectIndirectSpeech(tester, width: 768, height: 1024);

      expect(find.byType(DirectIndirectSpeechScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('15. renders correctly in dark mode', (tester) async {
      await pumpDirectIndirectSpeech(tester, themeMode: ThemeMode.dark);

      expect(find.byType(DirectIndirectSpeechScreen), findsOneWidget);
      expect(
        find.text('Maria said, "I walk to school every day."'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      '16. uses rawQuestion colon-split fallback when sentence is omitted',
      (tester) async {
        final stateFallback = GrammarLoaded(
          quests: const [testQuestSentenceFallback],
          currentIndex: 0,
          livesRemaining: 3,
          answerStatus: AnswerStatus.unanswered,
          hintUsed: false,
          wrongCount: 0,
          isFinalFailure: false,
        );

        await pumpDirectIndirectSpeech(tester, state: stateFallback);

        expect(find.text('He shouted, Help me!'), findsOneWidget);
      },
    );

    testWidgets(
      '17. renders final failure state with explanation and continue',
      (tester) async {
        final failureState = GrammarLoaded(
          quests: const [testQuest1, testQuestNoRules],
          currentIndex: 0,
          livesRemaining: 0,
          answerStatus: AnswerStatus.incorrect,
          hintUsed: false,
          wrongCount: 3,
          isFinalFailure: true,
        );

        await pumpDirectIndirectSpeech(tester, state: failureState);

        expect(find.byType(DirectIndirectSpeechScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
