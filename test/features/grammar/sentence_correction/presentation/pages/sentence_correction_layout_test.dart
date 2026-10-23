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
import 'package:vowl/features/grammar/sentence_correction/presentation/pages/sentence_correction_screen.dart';
import 'package:vowl/features/grammar/sentence_correction/presentation/widgets/sentence_correction_diagnostic_word.dart';
import 'package:vowl/features/grammar/sentence_correction/presentation/widgets/sentence_correction_instruction.dart';

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
    VowlMotion.lowAnimationModeOverride.value = true;
    registerFallbackValue(FakeGrammarEvent());
    registerFallbackValue(FakeGrammarState());
    registerFallbackValue(const SubmitAnswer(true));
    registerFallbackValue(const SubmitAnswer(false));
    registerFallbackValue(const NextQuestion());
    registerFallbackValue(const GrammarHintUsed());
    registerFallbackValue(const Duration(milliseconds: 50));
  });

  const testQuest1 = GrammarQuest(
    id: 'sc_l1_q1',
    instruction: 'Sentence Correction',
    difficulty: 1,
    subtype: GameSubtype.sentenceCorrection,
    sentence: 'She go to school every day.',
    question: 'She go to school every day.',
    correctAnswer: 'goes',
    incorrectPart: 'go',
    correctedPart: 'goes',
    options: ['goes', 'going', 'gone'],
    correctAnswerIndex: 0,
    hint: 'Subject she requires third-person singular.',
  );

  const testQuestFallback = GrammarQuest(
    id: 'sc_l1_q2',
    instruction: '',
    difficulty: 1,
    subtype: GameSubtype.sentenceCorrection,
    sentence: 'They plays soccer on weekends.',
    question: 'They plays soccer on weekends.',
    correctAnswer: 'play',
    incorrectPart: 'plays',
    correctedPart: 'play',
    options: ['play', 'played', 'playing'],
    correctAnswerIndex: 0,
    hint: 'Plural subject takes base verb.',
  );

  final testLoadedState = GrammarLoaded(
    quests: const [testQuest1, testQuestFallback],
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
      'has_seen_briefing_sentenceCorrection': true,
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

  Future<void> pumpSentenceCorrectionScreen(
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
                disableAnimations: true,
              ),
              child: Scaffold(body: SentenceCorrectionScreen(level: level)),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  tearDownAll(() {
    VowlMotion.lowAnimationModeOverride.value = false;
  });

  group('SentenceCorrectionScreen Layout & Hardening Tests', () {
    testWidgets('1. displays shimmer loading when state is GrammarInitial', (
      tester,
    ) async {
      await pumpSentenceCorrectionScreen(tester, state: GrammarInitial());
      expect(find.byType(GameShimmerLoading), findsOneWidget);
    });

    testWidgets('2. displays shimmer loading when state is GrammarLoading', (
      tester,
    ) async {
      await pumpSentenceCorrectionScreen(tester, state: GrammarLoading());
      expect(find.byType(GameShimmerLoading), findsOneWidget);
    });

    testWidgets('3. renders instruction badge with default text', (
      tester,
    ) async {
      await pumpSentenceCorrectionScreen(tester);
      expect(find.byType(SentenceCorrectionInstruction), findsOneWidget);
      expect(find.text('Sentence Correction'), findsOneWidget);
    });

    testWidgets(
      '4. renders instruction badge with custom fallback instruction text',
      (tester) async {
        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(390, 844),
            builder: (context, _) => const MaterialApp(
              home: Scaffold(
                body: SentenceCorrectionInstruction(
                  primaryColor: Colors.blue,
                  instruction: 'CUSTOM SCAN INSTRUCTION',
                ),
              ),
            ),
          ),
        );
        expect(find.text('CUSTOM SCAN INSTRUCTION'), findsOneWidget);
      },
    );

    testWidgets('5. renders diagnostic context card with sentence words', (
      tester,
    ) async {
      await pumpSentenceCorrectionScreen(tester);
      expect(
        find.byKey(const ValueKey('sentence_correction_context_card')),
        findsOneWidget,
      );
      expect(find.text('She'), findsOneWidget);
      expect(find.text('go'), findsOneWidget);
      expect(find.text('to'), findsOneWidget);
    });

    testWidgets('6. each word renders as a SentenceCorrectionDiagnosticWord', (
      tester,
    ) async {
      await pumpSentenceCorrectionScreen(tester);
      expect(find.byType(SentenceCorrectionDiagnosticWord), findsNWidgets(6));
    });

    testWidgets(
      '7. renders scanner status row with animated indicator and status text',
      (tester) async {
        await pumpSentenceCorrectionScreen(tester);
        expect(find.text('Tap the word with the mistake'), findsOneWidget);
      },
    );

    testWidgets('8. tapping a word marks it as suspected word', (tester) async {
      await pumpSentenceCorrectionScreen(tester);
      final wordGo = find.text('go');
      expect(wordGo, findsOneWidget);
      await tester.tap(wordGo);
      await tester.pump(const Duration(milliseconds: 200));

      verify(() => mockHapticService.selection()).called(1);
    });

    testWidgets(
      '9. tapping suspected word opens options panel with repair candidates',
      (tester) async {
        await pumpSentenceCorrectionScreen(tester);
        await tester.tap(find.text('go'));
        await tester.pump();

        expect(
          find.byKey(const ValueKey('sentence_correction_options_panel')),
          findsOneWidget,
        );
      },
    );

    testWidgets('10. options panel displays all repair options', (
      tester,
    ) async {
      await pumpSentenceCorrectionScreen(tester);
      await tester.tap(find.text('go'));
      await tester.pump();

      expect(find.text('goes'), findsOneWidget);
      expect(find.text('going'), findsOneWidget);
      expect(find.text('gone'), findsOneWidget);
    });

    testWidgets('11. tapping an option marks it selected', (tester) async {
      await pumpSentenceCorrectionScreen(tester);
      await tester.tap(find.text('go'));
      await tester.pump();

      await tester.tap(find.text('goes'));
      await tester.pump();

      verify(() => mockHapticService.selection()).called(2);
    });

    testWidgets(
      '12. Confirm Correction button is disabled when no option selected',
      (tester) async {
        await pumpSentenceCorrectionScreen(tester);
        await tester.tap(find.text('go'));
        await tester.pump();

        final repairBtn = find.text('Confirm Correction');
        expect(repairBtn, findsOneWidget);
        await tester.tap(repairBtn);
        await tester.pump();

        verifyNever(() => mockSoundService.playCorrect());
        verifyNever(() => mockSoundService.playWrong());
      },
    );

    testWidgets(
      '13. Confirm Correction with correct word and correct option passes Phase 1 and transitions to TypeToConfirmOverlay',
      (tester) async {
        await pumpSentenceCorrectionScreen(tester);
        // Tap correct glitch word 'go' (index 1)
        await tester.tap(find.text('go'));
        await tester.pump();

        // Tap correct repair option 'goes'
        await tester.tap(find.text('goes'));
        await tester.pump();

        final repairBtn = find.text('Confirm Correction');
        await tester.ensureVisible(repairBtn);
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(repairBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 800));

        verify(() => mockSoundService.playCorrect()).called(1);
        verify(() => mockHapticService.heavy()).called(1);
        expect(find.byType(TypeToConfirmOverlay), findsOneWidget);
      },
    );

    testWidgets(
      '14. Confirm Correction with wrong word triggers wrong zap and feedback card',
      (tester) async {
        await pumpSentenceCorrectionScreen(tester);
        // Tap wrong word 'She' (index 0)
        await tester.tap(find.text('She'));
        await tester.pump();

        // Tap option 'goes'
        await tester.tap(find.text('goes'));
        await tester.pump();

        final repairBtn = find.text('Confirm Correction');
        await tester.ensureVisible(repairBtn);
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(repairBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 800));

        verify(() => mockSoundService.playWrong()).called(1);
        verify(() => mockHapticService.error()).called(1);
        expect(
          find.byKey(const ValueKey('sentence_correction_feedback')),
          findsOneWidget,
        );
        expect(find.text('INCORRECT WORD'), findsOneWidget);
      },
    );

    testWidgets(
      '15. Confirm Correction with correct word but wrong option triggers feedback card with INCORRECT REPLACEMENT',
      (tester) async {
        await pumpSentenceCorrectionScreen(tester);
        // Tap correct glitch word 'go'
        await tester.tap(find.text('go'));
        await tester.pump();

        // Tap wrong repair option 'going'
        await tester.tap(find.text('going'));
        await tester.pump();

        final repairBtn = find.text('Confirm Correction');
        await tester.ensureVisible(repairBtn);
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(repairBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 800));

        verify(() => mockSoundService.playWrong()).called(1);
        verify(() => mockHapticService.error()).called(1);
        expect(
          find.byKey(const ValueKey('sentence_correction_feedback')),
          findsOneWidget,
        );
        expect(find.text('INCORRECT REPLACEMENT'), findsOneWidget);
      },
    );

    testWidgets(
      '16. Phase 2: TypeToConfirmOverlay is displayed with target sentence',
      (tester) async {
        await pumpSentenceCorrectionScreen(tester);
        await tester.tap(find.text('go'));
        await tester.pump();
        await tester.tap(find.text('goes'));
        await tester.pump();

        final repairBtn = find.text('Confirm Correction');
        await tester.ensureVisible(repairBtn);
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(repairBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        final overlayFinder = find.byType(TypeToConfirmOverlay);
        expect(overlayFinder, findsOneWidget);

        final paddingFinder = find.ancestor(
          of: overlayFinder,
          matching: find.byType(Padding),
        );
        final paddingWidget = tester.widget<Padding>(paddingFinder.first);
        final edgeInsets = paddingWidget.padding as EdgeInsets;
        expect(edgeInsets.left, greaterThanOrEqualTo(20));
        expect(edgeInsets.right, greaterThanOrEqualTo(20));
      },
    );

    testWidgets(
      '17. Phase 2: confirming typing submits answer (true) to bloc',
      (tester) async {
        await pumpSentenceCorrectionScreen(tester);
        await tester.tap(find.text('go'));
        await tester.pump();
        await tester.tap(find.text('goes'));
        await tester.pump();

        final repairBtn = find.text('Confirm Correction');
        await tester.ensureVisible(repairBtn);
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(repairBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 800));

        final textField = find.byType(TextField);
        expect(textField, findsOneWidget);
        await tester.enterText(textField, 'goes');
        await tester.pump();

        final submitBtn = find.text('SUBMIT');
        await tester.ensureVisible(submitBtn);
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(submitBtn);
        await tester.pump(const Duration(milliseconds: 1000));
        await tester.pump(const Duration(milliseconds: 200));

        verify(() => mockGrammarBloc.add(const SubmitAnswer(true))).called(1);
      },
    );

    testWidgets('18. Phase 2: skipping typing dispatches event to bloc', (
      tester,
    ) async {
      await pumpSentenceCorrectionScreen(tester);
      await tester.tap(find.text('go'));
      await tester.pump();
      await tester.tap(find.text('goes'));
      await tester.pump();

      final repairBtn = find.text('Confirm Correction');
      await tester.ensureVisible(repairBtn);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(repairBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      final skipBtn = find.byType(GameSkipBypassButton);
      expect(skipBtn, findsOneWidget);
      await tester.ensureVisible(skipBtn);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(skipBtn);
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pump(const Duration(milliseconds: 200));

      verify(() => mockGrammarBloc.add(any())).called(greaterThanOrEqualTo(1));
    });

    testWidgets(
      '19. tapping words is disabled once answered (answer lockout)',
      (tester) async {
        await pumpSentenceCorrectionScreen(tester);
        // Trigger wrong answer
        await tester.tap(find.text('She'));
        await tester.pump();
        await tester.tap(find.text('goes'));
        await tester.pump();
        final repairBtn = find.text('Confirm Correction');
        await tester.ensureVisible(repairBtn);
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(repairBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 800));

        // Clear invocations from initial wrong answer
        clearInteractions(mockHapticService);

        // Now tapping any word should do nothing
        await tester.tap(find.text('go'), warnIfMissed: false);
        await tester.pump();

        verifyNever(() => mockHapticService.selection());
      },
    );

    testWidgets('20. onContinue callback triggers NextQuestion event', (
      tester,
    ) async {
      await pumpSentenceCorrectionScreen(tester);
      // Trigger wrong answer to show CONTINUE button
      await tester.tap(find.text('She'));
      await tester.pump();
      await tester.tap(find.text('goes'));
      await tester.pump();
      final repairBtn = find.text('Confirm Correction');
      await tester.ensureVisible(repairBtn);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(repairBtn);
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

    testWidgets('21. onHint callback triggers GrammarHintUsed event', (
      tester,
    ) async {
      await pumpSentenceCorrectionScreen(tester);

      final hintFinder = find.byType(QuestHintButton);
      expect(hintFinder, findsOneWidget);
      await tester.tap(hintFinder);
      await tester.pump();

      verify(() => mockGrammarBloc.add(const GrammarHintUsed())).called(1);
    });

    testWidgets('22. layout adapts gracefully in compact height (< 700)', (
      tester,
    ) async {
      await pumpSentenceCorrectionScreen(tester, size: const Size(360, 640));
      expect(
        find.byKey(const ValueKey('sentence_correction_context_card')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      '23. renders correctly in dark and light themes without overflow',
      (tester) async {
        await pumpSentenceCorrectionScreen(tester, themeMode: ThemeMode.dark);
        expect(find.byType(SentenceCorrectionScreen), findsOneWidget);

        await pumpSentenceCorrectionScreen(tester, themeMode: ThemeMode.light);
        expect(find.byType(SentenceCorrectionScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('24. respects level 1 game briefing dialog on first run', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'has_seen_briefing_sentenceCorrection': false,
      });

      await pumpSentenceCorrectionScreen(tester, level: 1);

      expect(find.byType(GameBriefingLayer), findsOneWidget);
    });
  });
}
