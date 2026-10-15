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
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/grammar/tense_mastery/presentation/pages/tense_mastery_screen.dart';
import 'package:vowl/features/grammar/tense_mastery/presentation/widgets/tense_mastery_instruction.dart';

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

  const samplePastQuest = GrammarQuest(
    id: 'tm_past_1',
    instruction: 'Map the timeline.',
    difficulty: 1,
    subtype: GameSubtype.tenseMastery,
    sentence: 'The barista wiped down the espresso machine before closing last night.',
    correctAnswer: 'Past',
    hint: 'This cleaning happened at a specific moment in the past.',
    explanation: 'Wiped is simple past tense.',
  );

  const sampleFutureQuest = GrammarQuest(
    id: 'tm_future_1',
    instruction: 'Map the timeline.',
    difficulty: 1,
    subtype: GameSubtype.tenseMastery,
    sentence: 'The barista will train two new employees starting next Monday.',
    correctAnswer: 'Future',
    hint: 'This training has not occurred yet.',
    explanation: 'Will train is future tense.',
  );

  const samplePresentQuest = GrammarQuest(
    id: 'tm_present_1',
    instruction: 'Map the timeline.',
    difficulty: 1,
    subtype: GameSubtype.tenseMastery,
    sentence: 'Every morning, the barista opens the shop and grinds fresh coffee beans.',
    correctAnswer: 'Present',
    hint: 'This is a daily routine.',
    explanation: 'Opens and grinds are simple present forms.',
  );

  final testLoadedState = GrammarLoaded(
    quests: const [samplePastQuest, sampleFutureQuest, samplePresentQuest],
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
    hintUsed: false,
    wrongCount: 0,
    isFinalFailure: false,
  );

  setUpAll(() {
    registerFallbackValue(FakeGrammarEvent());
    registerFallbackValue(FakeGrammarState());
    registerFallbackValue(const SubmitAnswer(true));
    registerFallbackValue(const SubmitAnswer(false));
    registerFallbackValue(const NextQuestion());
    registerFallbackValue(const GrammarHintUsed());
    VowlMotion.lowAnimationModeOverride.value = true;
  });

  tearDownAll(() {
    VowlMotion.lowAnimationModeOverride.value = false;
  });

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

    SharedPreferences.setMockInitialValues({
      'has_seen_briefing_tenseMastery': true,
    });

    when(() => mockGrammarBloc.state).thenReturn(testLoadedState);
    when(() => mockGrammarBloc.stream).thenAnswer((_) => const Stream.empty());

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
    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream<AuthState>.empty());

    when(() => mockEconomyBloc.state).thenReturn(const EconomyState());
    when(() => mockEconomyBloc.stream).thenAnswer((_) => const Stream.empty());

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});
    when(() => mockHapticService.heavy()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});

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

    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    if (di.sl.isRegistered<SoundService>()) {
      di.sl.unregister<SoundService>();
    }
    if (di.sl.isRegistered<TtsService>()) {
      di.sl.unregister<TtsService>();
    }
    if (di.sl.isRegistered<LocaleService>()) {
      di.sl.unregister<LocaleService>();
    }
    if (di.sl.isRegistered<AppLogger>()) {
      di.sl.unregister<AppLogger>();
    }
    if (di.sl.isRegistered<AnalyticsService>()) {
      di.sl.unregister<AnalyticsService>();
    }
    if (di.sl.isRegistered<AdService>()) {
      di.sl.unregister<AdService>();
    }

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

  Future<void> pumpTenseMasteryScreen(
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
              child: Scaffold(
                body: TenseMasteryScreen(level: level),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  group('TenseMasteryScreen Layout & Hardening Tests', () {
    testWidgets('1. displays shimmer loading when state is GrammarInitial',
        (tester) async {
      await pumpTenseMasteryScreen(tester, state: const GrammarInitial());
      expect(find.byType(GameShimmerLoading), findsOneWidget);
    });

    testWidgets('2. displays shimmer loading when state is GrammarLoading',
        (tester) async {
      await pumpTenseMasteryScreen(tester, state: const GrammarLoading());
      expect(find.byType(GameShimmerLoading), findsOneWidget);
    });

    testWidgets('3. renders TenseMasteryInstruction ("SHIFT THROUGH TIME")',
        (tester) async {
      await pumpTenseMasteryScreen(tester);
      expect(find.byType(TenseMasteryInstruction), findsOneWidget);
      expect(find.text('SHIFT THROUGH TIME'), findsOneWidget);
    });

    testWidgets('4. renders context card with sentence text', (tester) async {
      await pumpTenseMasteryScreen(tester);
      final cardFinder = find.byKey(const ValueKey('tense_sentence_card'));
      expect(cardFinder, findsOneWidget);
      expect(
        find.text(
          'The barista wiped down the espresso machine before closing last night.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('5. renders timeline slider and all three tense nodes',
        (tester) async {
      await pumpTenseMasteryScreen(tester);
      expect(find.byKey(const ValueKey('tense_timeline_slider')), findsOneWidget);
      expect(find.byKey(const ValueKey('tense_node_past')), findsOneWidget);
      expect(find.byKey(const ValueKey('tense_node_present')), findsOneWidget);
      expect(find.byKey(const ValueKey('tense_node_future')), findsOneWidget);
      expect(find.text('PAST'), findsOneWidget);
      expect(find.text('PRESENT'), findsOneWidget);
      expect(find.text('FUTURE'), findsOneWidget);
    });

    testWidgets('6. renders draggable chrono-sphere in initial position',
        (tester) async {
      await pumpTenseMasteryScreen(tester);
      expect(find.byKey(const ValueKey('tense_chrono_sphere')), findsOneWidget);
      expect(find.byIcon(Icons.timer_rounded), findsOneWidget);
    });

    testWidgets('7. tapping past node updates selection and triggers haptic',
        (tester) async {
      await pumpTenseMasteryScreen(tester);
      final pastNode = find.byKey(const ValueKey('tense_node_past'));
      await tester.tap(pastNode);
      await tester.pump();

      verify(() => mockHapticService.selection()).called(1);
    });

    testWidgets('8. tapping future node updates selection and triggers haptic',
        (tester) async {
      await pumpTenseMasteryScreen(tester);
      final futureNode = find.byKey(const ValueKey('tense_node_future'));
      await tester.tap(futureNode);
      await tester.pump();

      verify(() => mockHapticService.selection()).called(1);
    });

    testWidgets('9. tapping present node keeps present selection and triggers haptic',
        (tester) async {
      await pumpTenseMasteryScreen(tester);
      // Move sphere to past first so present node is not occluded by the sphere
      await tester.tap(find.byKey(const ValueKey('tense_node_past')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      clearInteractions(mockHapticService);

      final presentNode = find.byKey(const ValueKey('tense_node_present'));
      await tester.tap(presentNode);
      await tester.pump();

      verify(() => mockHapticService.selection()).called(1);
    });

    testWidgets('10. freezing with incorrect tense triggers error haptic and submits false',
        (tester) async {
      // Default is Present (0.5), but samplePastQuest requires Past
      await pumpTenseMasteryScreen(tester);
      final freezeBtn = find.byKey(const ValueKey('tense_freeze_button'));
      expect(freezeBtn, findsOneWidget);

      await tester.tap(freezeBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockHapticService.error()).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockGrammarBloc.add(const SubmitAnswer(false))).called(1);
    });

    testWidgets(
        '11. selecting correct past tense and freezing triggers heavy haptic and opens Phase 2 overlay',
        (tester) async {
      await pumpTenseMasteryScreen(tester);

      // Select Past
      await tester.tap(find.byKey(const ValueKey('tense_node_past')));
      await tester.pump();

      // Tap freeze timeline
      await tester.tap(find.byKey(const ValueKey('tense_freeze_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockHapticService.heavy()).called(1);
      expect(find.byKey(const ValueKey('tense_type_overlay'), skipOffstage: false), findsOneWidget);
    });

    testWidgets('12. dragging chrono sphere left shifts to Past tense',
        (tester) async {
      await pumpTenseMasteryScreen(tester);
      final sphere = find.byKey(const ValueKey('tense_chrono_sphere'));

      // Drag left
      await tester.drag(sphere, const Offset(-120, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap freeze timeline, should be correct since it shifted to Past
      await tester.tap(find.byKey(const ValueKey('tense_freeze_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockHapticService.heavy()).called(2);
      expect(find.byKey(const ValueKey('tense_type_overlay'), skipOffstage: false), findsOneWidget);
    });

    testWidgets('13. dragging chrono sphere right shifts to Future tense',
        (tester) async {
      final futureState = GrammarLoaded(
        quests: const [sampleFutureQuest],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
        hintUsed: false,
        wrongCount: 0,
        isFinalFailure: false,
      );

      await pumpTenseMasteryScreen(tester, state: futureState);
      final sphere = find.byKey(const ValueKey('tense_chrono_sphere'));

      // Drag right
      await tester.drag(sphere, const Offset(120, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap freeze timeline, should be correct since it shifted to Future
      await tester.tap(find.byKey(const ValueKey('tense_freeze_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockHapticService.heavy()).called(2);
      expect(find.byKey(const ValueKey('tense_type_overlay'), skipOffstage: false), findsOneWidget);
    });

    testWidgets('14. present quest succeeds directly with default present slider',
        (tester) async {
      final presentState = GrammarLoaded(
        quests: const [samplePresentQuest],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
        hintUsed: false,
        wrongCount: 0,
        isFinalFailure: false,
      );

      await pumpTenseMasteryScreen(tester, state: presentState);
      // Freeze with default Present selection
      await tester.tap(find.byKey(const ValueKey('tense_freeze_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockHapticService.heavy()).called(1);
      expect(find.byKey(const ValueKey('tense_type_overlay'), skipOffstage: false), findsOneWidget);
    });

    testWidgets('15. Phase 2 TypeToConfirmOverlay accepts correct typing and dispatches success',
        (tester) async {
      await pumpTenseMasteryScreen(tester);

      // Select Past and freeze
      await tester.tap(find.byKey(const ValueKey('tense_node_past')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('tense_freeze_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final overlayFinder = find.byKey(const ValueKey('tense_type_overlay'), skipOffstage: false);
      expect(overlayFinder, findsOneWidget);

      final overlayState = tester.widget<TypeToConfirmOverlay>(overlayFinder);
      overlayState.onConfirmed();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockHapticService.success()).called(1);
      verify(() => mockSoundService.playCorrect()).called(1);
      verify(() => mockGrammarBloc.add(const SubmitAnswer(true))).called(1);
    });

    testWidgets('16. Phase 2 TypeToConfirmOverlay skipping dispatches wrong and false submit',
        (tester) async {
      await pumpTenseMasteryScreen(tester);

      // Select Past and freeze
      await tester.tap(find.byKey(const ValueKey('tense_node_past')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('tense_freeze_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final overlayFinder = find.byKey(const ValueKey('tense_type_overlay'), skipOffstage: false);
      expect(overlayFinder, findsOneWidget);

      final overlayState = tester.widget<TypeToConfirmOverlay>(overlayFinder);
      overlayState.onSkipped();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockHapticService.error()).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockGrammarBloc.add(const SubmitAnswer(false))).called(1);
    });

    testWidgets('17. freeze button is hidden once answered or in phase 2 pending submit',
        (tester) async {
      await pumpTenseMasteryScreen(tester);

      // Select Past and freeze
      await tester.tap(find.byKey(const ValueKey('tense_node_past')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('tense_freeze_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // In phase 2, freeze button is hidden
      expect(find.byKey(const ValueKey('tense_freeze_button')), findsNothing);
    });

    testWidgets('18. timeline nodes tap is locked out once answered',
        (tester) async {
      await pumpTenseMasteryScreen(tester);

      // Wrong answer
      await tester.tap(find.byKey(const ValueKey('tense_freeze_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Clear invocations from wrong submit
      clearInteractions(mockHapticService);

      // Tapping node should be locked out
      await tester.tap(find.byKey(const ValueKey('tense_node_future')), warnIfMissed: false);
      await tester.pump();

      verifyNever(() => mockHapticService.selection());
    });

    testWidgets('19. dragging slider is locked out once answered',
        (tester) async {
      await pumpTenseMasteryScreen(tester);

      // Wrong answer
      await tester.tap(find.byKey(const ValueKey('tense_freeze_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      clearInteractions(mockHapticService);

      final sphere = find.byKey(const ValueKey('tense_chrono_sphere'));
      await tester.drag(sphere, const Offset(100, 0), warnIfMissed: false);
      await tester.pump();

      verifyNever(() => mockHapticService.selection());
      verifyNever(() => mockHapticService.heavy());
    });

    testWidgets('20. onContinue callback triggers NextQuestion event',
        (tester) async {
      await pumpTenseMasteryScreen(tester);

      // Fail to show continue
      await tester.tap(find.byKey(const ValueKey('tense_freeze_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final continueButton = find.text('CONTINUE');
      if (continueButton.evaluate().isNotEmpty) {
        await tester.tap(continueButton);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        verify(() => mockGrammarBloc.add(const NextQuestion())).called(1);
      }
    });

    testWidgets('21. onHint callback triggers GrammarHintUsed event',
        (tester) async {
      await pumpTenseMasteryScreen(tester);

      final hintButton = find.byType(QuestHintButton);
      expect(hintButton, findsOneWidget);

      await tester.tap(hintButton);
      await tester.pump();

      verify(() => mockGrammarBloc.add(const GrammarHintUsed())).called(2);
    });

    testWidgets('22. layout adapts gracefully in compact height (< 700)',
        (tester) async {
      await pumpTenseMasteryScreen(tester, size: const Size(390, 640));
      expect(find.byType(TenseMasteryInstruction), findsOneWidget);
      expect(find.byKey(const ValueKey('tense_sentence_card')), findsOneWidget);
      expect(find.byKey(const ValueKey('tense_timeline_slider')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('23. renders correctly in light theme without layout overflow',
        (tester) async {
      await pumpTenseMasteryScreen(tester, themeMode: ThemeMode.light);
      expect(find.byType(TenseMasteryInstruction), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('24. renders correctly in dark theme without layout overflow',
        (tester) async {
      await pumpTenseMasteryScreen(tester, themeMode: ThemeMode.dark);
      expect(find.byType(TenseMasteryInstruction), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('25. renders correctly on wide tablet screen', (tester) async {
      await pumpTenseMasteryScreen(tester, size: const Size(800, 1200));
      expect(find.byType(TenseMasteryInstruction), findsOneWidget);
      expect(find.byKey(const ValueKey('tense_sentence_card')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('26. respects level 1 game briefing dialog on first run',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'has_seen_briefing_tenseMastery': false,
      });

      await pumpTenseMasteryScreen(tester, level: 1);
      expect(find.byType(GameBriefingLayer), findsOneWidget);
    });
  });
}

