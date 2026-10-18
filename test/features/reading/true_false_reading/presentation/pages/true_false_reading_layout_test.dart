import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/game_mechanics/reading/evidence_highlight_wrapper.dart';
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
import 'package:vowl/features/reading/domain/entities/reading_quest.dart';
import 'package:vowl/features/reading/presentation/bloc/reading_bloc.dart';
import 'package:vowl/features/reading/true_false_reading/presentation/pages/true_false_reading_screen.dart';
import 'package:vowl/features/reading/true_false_reading/presentation/widgets/pulsing_arrows.dart';
import 'package:vowl/features/reading/true_false_reading/presentation/widgets/true_false_reading_coin_zone.dart';
import 'package:vowl/features/reading/true_false_reading/presentation/widgets/true_false_reading_instruction.dart';
import 'package:vowl/features/reading/true_false_reading/presentation/widgets/true_false_reading_passage.dart';
import 'package:vowl/features/reading/true_false_reading/presentation/widgets/true_false_reading_statement.dart';

class MockReadingBloc extends MockBloc<ReadingEvent, ReadingState>
    implements ReadingBloc {}

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

class FakeReadingEvent extends Fake implements ReadingEvent {}

class FakeReadingState extends Fake implements ReadingState {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockReadingBloc mockReadingBloc;
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
    registerFallbackValue(FakeReadingEvent());
    registerFallbackValue(FakeReadingState());
    registerFallbackValue(const SubmitAnswer(true));
    registerFallbackValue(const SubmitAnswer(false));
    registerFallbackValue(const NextQuestion());
    registerFallbackValue(const ReadingHintUsed());
    registerFallbackValue(const ReadingSpeakConfirmed(5));
  });

  const testDirectQuest = ReadingQuest(
    id: 'RDG_TRUEFALSE_L1_Q1',
    instruction: 'Validate the truth of the statement.',
    difficulty: 1,
    subtype: GameSubtype.trueFalseReading,
    passage:
        'The honey bee is capable of flying at speeds of up to 15 miles per hour when traveling to collect nectar.',
    question: 'Honey bees can fly at speeds reaching 15 miles per hour.',
    correctAnswer: 'true',
    evidenceLine: null,
    hint: 'Check the speed cited in the text.',
    explanation: 'The passage explicitly says bees fly up to 15 miles per hour.',
  );

  const testEvidenceQuest = ReadingQuest(
    id: 'RDG_TRUEFALSE_L1_Q2',
    instruction: 'Validate statement and select supporting evidence.',
    difficulty: 1,
    subtype: GameSubtype.trueFalseReading,
    passage:
        'Octopuses possess three hearts and blue blood that contains copper rather than iron.',
    question: 'An octopus has three distinct hearts.',
    correctAnswer: 'true',
    evidenceLine: 'three hearts',
    hint: 'Look for the anatomical details.',
    explanation: 'The text states that octopuses possess three hearts.',
  );

  const testFalseQuest = ReadingQuest(
    id: 'RDG_TRUEFALSE_L1_Q3',
    instruction: 'Verify whether the statement matches the passage.',
    difficulty: 1,
    subtype: GameSubtype.trueFalseReading,
    passage:
        'Penguins are flightless birds that live almost exclusively in the southern hemisphere.',
    question: 'Penguins naturally inhabit the northern hemisphere Arctic.',
    correctAnswer: 'false',
    evidenceLine: null,
    hint: 'Note where penguins reside.',
    explanation: 'Penguins live almost exclusively in the southern hemisphere.',
  );

  const testLoadedState = ReadingLoaded(
    quests: [testDirectQuest, testEvidenceQuest, testFalseQuest],
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
  );

  setUp(() async {
    mockReadingBloc = MockReadingBloc();
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
      'has_seen_briefing_trueFalseReading': true,
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

    when(() => mockReadingBloc.state).thenReturn(testLoadedState);
    when(() => mockReadingBloc.stream)
        .thenAnswer((_) => const Stream<ReadingState>.empty());

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
    when(() => mockAuthBloc.stream)
        .thenAnswer((_) => const Stream<AuthState>.empty());

    when(() => mockEconomyBloc.state).thenReturn(const EconomyState());
    when(() => mockEconomyBloc.stream)
        .thenAnswer((_) => const Stream<EconomyState>.empty());

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
    when(() => mockSoundService.stopTts()).thenAnswer((_) async {});
    when(() => mockSoundService.playTts(any())).thenAnswer((_) async {});

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

    di.sl.reset();

    di.sl.registerLazySingleton<HapticService>(() => mockHapticService);
    di.sl.registerLazySingleton<SoundService>(() => mockSoundService);
    di.sl.registerLazySingleton<TtsService>(() => mockTtsService);
    di.sl.registerLazySingleton<LocaleService>(() => mockLocaleService);
    di.sl.registerLazySingleton<AppLogger>(() => mockLogger);
    di.sl.registerLazySingleton<AnalyticsService>(() => mockAnalyticsService);
    di.sl.registerLazySingleton<AdService>(() => mockAdService);
  });

  tearDown(() {
    VowlMotion.lowAnimationModeOverride.value = false;
    di.sl.reset();
  });

  Future<void> pumpTrueFalseReading(
    WidgetTester tester, {
    ReadingState? state,
    int level = 2,
    ThemeMode themeMode = ThemeMode.light,
    double width = 390,
    double height = 844,
  }) async {
    tester.view.physicalSize = Size(width * 2, height * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    if (state != null) {
      when(() => mockReadingBloc.state).thenReturn(state);
    }

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ReadingBloc>.value(value: mockReadingBloc),
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
            home: TrueFalseReadingScreen(
              level: level,
              gameType: GameSubtype.trueFalseReading,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  group('TrueFalseReadingScreen - Layout & Initial UI', () {
    testWidgets('renders all core UI elements initially', (tester) async {
      await pumpTrueFalseReading(tester);

      expect(find.byType(TrueFalseReadingInstruction), findsOneWidget);
      expect(
        find.textContaining(
          'VALIDATE THE TRUTH OF THE STATEMENT',
          findRichText: true,
        ),
        findsOneWidget,
      );

      expect(find.byType(TrueFalseReadingPassage), findsOneWidget);
      expect(
        find.textContaining('The honey bee is capable of flying'),
        findsOneWidget,
      );

      expect(find.byType(TrueFalseReadingStatement), findsOneWidget);
      expect(
        find.text('Honey bees can fly at speeds reaching 15 miles per hour.'),
        findsOneWidget,
      );

      expect(find.byType(TrueFalseReadingCoinZone), findsOneWidget);
      expect(find.byKey(const ValueKey('slot_FALSE')), findsOneWidget);
      expect(find.byKey(const ValueKey('slot_TRUE')), findsOneWidget);
      expect(find.byKey(const ValueKey('truth_coin')), findsOneWidget);
      expect(find.byType(PulsingArrows), findsNWidgets(2));
    });

    testWidgets('audio scaffolding plays TTS for passage and statement', (
      tester,
    ) async {
      await pumpTrueFalseReading(tester);

      final passageAudioBtn = find.byKey(
        const ValueKey('passage_audio_button'),
      );
      expect(passageAudioBtn, findsOneWidget);
      await tester.tap(passageAudioBtn);
      await tester.pump(const Duration(milliseconds: 500));

      verify(
        () => mockSoundService.playTts(testDirectQuest.passage!),
      ).called(1);

      final statementAudioBtn = find.byKey(
        const ValueKey('statement_audio_button'),
      );
      expect(statementAudioBtn, findsOneWidget);
      await tester.tap(statementAudioBtn);
      await tester.pump(const Duration(milliseconds: 500));

      verify(
        () => mockSoundService.playTts(testDirectQuest.question!),
      ).called(1);
    });
  });

  group('TrueFalseReadingScreen - Tap-to-Answer Mechanics', () {
    testWidgets(
      'tapping TRUE slot when statement is true triggers correct flow',
      (tester) async {
        await pumpTrueFalseReading(tester);

        await tester.ensureVisible(find.byKey(const ValueKey('slot_TRUE')));
        await tester.pump(const Duration(milliseconds: 300));

        await tester.tap(find.byKey(const ValueKey('slot_TRUE')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1000));

        verify(() => mockHapticService.selection()).called(1);
        verify(() => mockHapticService.success()).called(1);
        verify(() => mockSoundService.playCorrect()).called(1);
        verify(
          () => mockReadingBloc.add(const ReadingSpeakConfirmed(5)),
        ).called(1);
        verify(() => mockReadingBloc.add(const SubmitAnswer(true))).called(1);
      },
    );

    testWidgets(
      'tapping FALSE slot when statement is true triggers wrong flow',
      (tester) async {
        await pumpTrueFalseReading(tester);

        await tester.ensureVisible(find.byKey(const ValueKey('slot_FALSE')));
        await tester.pump(const Duration(milliseconds: 300));

        await tester.tap(find.byKey(const ValueKey('slot_FALSE')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1000));

        verify(() => mockHapticService.selection()).called(1);
        verify(() => mockHapticService.error()).called(1);
        verify(() => mockSoundService.playWrong()).called(1);
        verify(() => mockReadingBloc.add(const SubmitAnswer(false))).called(1);
      },
    );

    testWidgets(
      'tapping FALSE slot when statement is false triggers correct flow',
      (tester) async {
        when(() => mockReadingBloc.state).thenReturn(
          const ReadingLoaded(
            quests: [testFalseQuest],
            currentIndex: 0,
            livesRemaining: 3,
            answerStatus: AnswerStatus.unanswered,
          ),
        );

        await pumpTrueFalseReading(tester);

        await tester.ensureVisible(find.byKey(const ValueKey('slot_FALSE')));
        await tester.pump(const Duration(milliseconds: 300));

        await tester.tap(find.byKey(const ValueKey('slot_FALSE')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1000));

        verify(() => mockHapticService.selection()).called(1);
        verify(() => mockHapticService.success()).called(1);
        verify(() => mockSoundService.playCorrect()).called(1);
        verify(
          () => mockReadingBloc.add(const ReadingSpeakConfirmed(5)),
        ).called(1);
        verify(() => mockReadingBloc.add(const SubmitAnswer(true))).called(1);
      },
    );
  });

  group('TrueFalseReadingScreen - Drag & Drop Coin Mechanics', () {
    testWidgets('dragging coin right to TRUE triggers correct submission', (
      tester,
    ) async {
      await pumpTrueFalseReading(tester);

      await tester.ensureVisible(find.byKey(const ValueKey('truth_coin')));
      await tester.pump(const Duration(milliseconds: 300));

      final coin = find.byKey(const ValueKey('truth_coin'));
      await tester.timedDrag(
        coin,
        const Offset(140, 0),
        const Duration(milliseconds: 300),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));

      verify(() => mockHapticService.selection()).called(1);
      verify(() => mockHapticService.success()).called(1);
      verify(() => mockSoundService.playCorrect()).called(1);
      verify(() => mockReadingBloc.add(const SubmitAnswer(true))).called(1);
    });

    testWidgets('dragging coin left to FALSE triggers incorrect submission', (
      tester,
    ) async {
      await pumpTrueFalseReading(tester);

      await tester.ensureVisible(find.byKey(const ValueKey('truth_coin')));
      await tester.pump(const Duration(milliseconds: 300));

      final coin = find.byKey(const ValueKey('truth_coin'));
      await tester.timedDrag(
        coin,
        const Offset(-140, 0),
        const Duration(milliseconds: 300),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));

      verify(() => mockHapticService.selection()).called(1);
      verify(() => mockHapticService.error()).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockReadingBloc.add(const SubmitAnswer(false))).called(1);
    });

    testWidgets(
      'insufficient drag distance springs back without submitting answer',
      (tester) async {
        await pumpTrueFalseReading(tester);

        await tester.ensureVisible(find.byKey(const ValueKey('truth_coin')));
        await tester.pump(const Duration(milliseconds: 300));

        final coin = find.byKey(const ValueKey('truth_coin'));
        await tester.timedDrag(
          coin,
          const Offset(30, 0),
          const Duration(milliseconds: 300),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        verifyNever(() => mockReadingBloc.add(any(that: isA<SubmitAnswer>())));
        verifyNever(() => mockHapticService.selection());
      },
    );
  });

  group('TrueFalseReadingScreen - Evidence Highlight Flow', () {
    testWidgets(
      'correct coin selection reveals EvidenceHighlightWrapper when evidenceLine exists',
      (tester) async {
        when(() => mockReadingBloc.state).thenReturn(
          const ReadingLoaded(
            quests: [testEvidenceQuest],
            currentIndex: 0,
            livesRemaining: 3,
            answerStatus: AnswerStatus.unanswered,
          ),
        );

        await pumpTrueFalseReading(tester);

        await tester.ensureVisible(find.byKey(const ValueKey('slot_TRUE')));
        await tester.pump(const Duration(milliseconds: 300));

        await tester.tap(find.byKey(const ValueKey('slot_TRUE')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1000));

        // Should not have submitted yet because evidence highlight is required
        verifyNever(() => mockReadingBloc.add(const SubmitAnswer(true)));

        // Scroll down to bring EvidenceHighlightWrapper into the viewport
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // EvidenceHighlightWrapper should be visible
        expect(find.byType(EvidenceHighlightWrapper), findsOneWidget);
        expect(
          find.text('Tap the words that prove your answer'),
          findsOneWidget,
        );

        // Tap the evidence words in the wrapper
        final evidenceWord = find.text('three');
        expect(evidenceWord, findsWidgets);
        await tester.tap(evidenceWord.first);
        await tester.pump(const Duration(milliseconds: 300));

        final heartsWord = find.text('hearts');
        expect(heartsWord, findsWidgets);
        await tester.tap(heartsWord.first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1000));

        verify(() => mockHapticService.success()).called(3);
        verify(() => mockSoundService.playCorrect()).called(1);
        verify(
          () => mockReadingBloc.add(const ReadingSpeakConfirmed(5)),
        ).called(1);
        verify(() => mockReadingBloc.add(const SubmitAnswer(true))).called(1);

        await tester.pump(const Duration(seconds: 3));
      },
    );
  });

  group('TrueFalseReadingScreen - Interaction Lockout & State Controls', () {
    testWidgets('locks interaction once answered preventing subsequent taps', (
      tester,
    ) async {
      await pumpTrueFalseReading(tester);

      await tester.ensureVisible(find.byKey(const ValueKey('slot_TRUE')));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byKey(const ValueKey('slot_TRUE')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));

      verify(() => mockReadingBloc.add(const SubmitAnswer(true))).called(1);

      // Subsequent taps should be locked out
      await tester.tap(find.byKey(const ValueKey('slot_FALSE')), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(const ValueKey('slot_TRUE')), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));

      verifyNever(() => mockReadingBloc.add(const SubmitAnswer(false)));
    });

    testWidgets('tapping continue button dispatches NextQuestion', (
      tester,
    ) async {
      when(() => mockReadingBloc.state).thenReturn(
        const ReadingLoaded(
          quests: [testDirectQuest],
          currentIndex: 0,
          livesRemaining: 3,
          answerStatus: AnswerStatus.correct,
        ),
      );

      await pumpTrueFalseReading(tester);

      final continueBtn = find.text('CONTINUE');
      expect(continueBtn, findsOneWidget);

      await tester.tap(continueBtn);
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockReadingBloc.add(const NextQuestion())).called(1);
    });

    testWidgets('tapping hint button dispatches ReadingHintUsed', (
      tester,
    ) async {
      await pumpTrueFalseReading(tester);

      final hintButton = find.byType(QuestHintButton);
      expect(hintButton, findsOneWidget);

      await tester.tap(hintButton);
      await tester.pump(const Duration(milliseconds: 500));

      verify(
        () => mockReadingBloc.add(any(that: isA<ReadingHintUsed>())),
      ).called(2);
    });

    testWidgets('renders GameShimmerLoading on ReadingInitial state', (
      tester,
    ) async {
      await pumpTrueFalseReading(tester, state: const ReadingInitial());

      expect(find.byType(GameShimmerLoading), findsOneWidget);
      expect(find.byType(TrueFalseReadingCoinZone), findsNothing);
    });

    testWidgets('renders and dismisses GameBriefingLayer on Level 1', (
      tester,
    ) async {
      await pumpTrueFalseReading(tester, level: 1);

      expect(find.byType(GameBriefingLayer), findsOneWidget);

      final startBtn = find.text('VERIFY TRUTH');
      expect(startBtn, findsOneWidget);

      await tester.ensureVisible(startBtn);
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(startBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(GameBriefingLayer), findsNothing);
      expect(find.byType(TrueFalseReadingCoinZone), findsOneWidget);
    });

    testWidgets('resets state on question transition', (tester) async {
      final stateController = StreamController<ReadingState>.broadcast();
      addTearDown(() => stateController.close());

      when(() => mockReadingBloc.stream).thenAnswer((_) => stateController.stream);

      await pumpTrueFalseReading(tester);

      await tester.ensureVisible(find.byKey(const ValueKey('slot_TRUE')));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byKey(const ValueKey('slot_TRUE')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));
      verify(() => mockReadingBloc.add(const SubmitAnswer(true))).called(1);

      // Transition to next question
      when(() => mockReadingBloc.state).thenReturn(
        const ReadingLoaded(
          quests: [testDirectQuest, testFalseQuest],
          currentIndex: 1,
          livesRemaining: 3,
          answerStatus: AnswerStatus.unanswered,
        ),
      );
      stateController.add(
        const ReadingLoaded(
          quests: [testDirectQuest, testFalseQuest],
          currentIndex: 1,
          livesRemaining: 3,
          answerStatus: AnswerStatus.unanswered,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pumpAndSettle();

      expect(
        find.text('Penguins naturally inhabit the northern hemisphere Arctic.'),
        findsOneWidget,
      );
    });
  });

  group('TrueFalseReadingScreen - Theme & Responsiveness', () {
    testWidgets('renders cleanly in dark theme mode', (tester) async {
      await pumpTrueFalseReading(tester, themeMode: ThemeMode.dark);

      expect(find.byType(TrueFalseReadingScreen), findsOneWidget);
      expect(find.byType(TrueFalseReadingCoinZone), findsOneWidget);
    });

    testWidgets(
      'renders without RenderFlex overflow on small 320dp screen width',
      (tester) async {
        await pumpTrueFalseReading(tester, width: 320, height: 640);

        expect(find.byType(TrueFalseReadingScreen), findsOneWidget);
        expect(find.byType(TrueFalseReadingPassage), findsOneWidget);
        expect(find.byType(TrueFalseReadingStatement), findsOneWidget);
        expect(find.byType(TrueFalseReadingCoinZone), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}

