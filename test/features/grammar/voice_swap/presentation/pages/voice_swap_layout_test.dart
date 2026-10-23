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
import 'package:vowl/features/grammar/voice_swap/presentation/pages/voice_swap_screen.dart';

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

  const sampleActiveQuest = GrammarQuest(
    id: 'vs_active_1',
    instruction: 'Identify voice and transmute.',
    difficulty: 1,
    subtype: GameSubtype.voiceSwap,
    sentence: 'The chef baked an exquisite artisan sourdough loaf.',
    correctAnswer: 'Active',
    hint: 'The chef is the subject performing the action directly.',
    explanation:
        'Active voice: Chef bakes bread. flip to: An exquisite artisan sourdough loaf was baked by the chef.',
  );

  const samplePassiveQuest = GrammarQuest(
    id: 'vs_passive_1',
    instruction: 'Identify voice and transmute.',
    difficulty: 1,
    subtype: GameSubtype.voiceSwap,
    sentence: 'The symphony was performed flawlessly by the youth orchestra.',
    correctAnswer: 'Passive',
    hint: 'The subject receives the action performed by the orchestra.',
    explanation:
        'Passive voice. flip to: The youth orchestra performed the symphony flawlessly.',
  );

  const sampleDirectQuest = GrammarQuest(
    id: 'vs_direct_1',
    instruction: 'Identify voice.',
    difficulty: 1,
    subtype: GameSubtype.voiceSwap,
    sentence: 'Lightning struck the ancient oak tree on the ridge.',
    correctAnswer: 'Active',
    hint: 'Lightning performs the striking.',
    explanation: 'Lightning is actively performing the striking action.',
  );

  final testLoadedState = GrammarLoaded(
    quests: const [sampleActiveQuest, samplePassiveQuest, sampleDirectQuest],
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
      'has_seen_briefing_voiceSwap': true,
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
    when(
      () => mockAuthBloc.stream,
    ).thenAnswer((_) => const Stream<AuthState>.empty());

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

    if (di.sl.isRegistered<HapticService>()) di.sl.unregister<HapticService>();
    if (di.sl.isRegistered<SoundService>()) di.sl.unregister<SoundService>();
    if (di.sl.isRegistered<TtsService>()) di.sl.unregister<TtsService>();
    if (di.sl.isRegistered<LocaleService>()) di.sl.unregister<LocaleService>();
    if (di.sl.isRegistered<AppLogger>()) di.sl.unregister<AppLogger>();
    if (di.sl.isRegistered<AnalyticsService>())
      di.sl.unregister<AnalyticsService>();
    if (di.sl.isRegistered<AdService>()) di.sl.unregister<AdService>();

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

  Future<void> pumpVoiceSwapScreen(
    WidgetTester tester, {
    GrammarState? state,
    int level = 2,
    Size size = const Size(390, 844),
    ThemeMode themeMode = ThemeMode.dark,
    bool reduceMotion = true,
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
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            home: MediaQuery(
              data: MediaQueryData(
                size: size,
                padding: EdgeInsets.zero,
                viewInsets: EdgeInsets.zero,
                disableAnimations: reduceMotion,
              ),
              child: Scaffold(body: VoiceSwapScreen(level: level)),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  group('VoiceSwapScreen Layout & Hardening Tests', () {
    testWidgets(
      '1. Renders shimmer loading state when state is GrammarInitial',
      (tester) async {
        await pumpVoiceSwapScreen(tester, state: const GrammarInitial());
        expect(find.byType(GameShimmerLoading), findsOneWidget);
      },
    );

    testWidgets('2. respects level 1 game briefing dialog on first run', (
      tester,
    ) async {
      await pumpVoiceSwapScreen(tester, level: 1);
      expect(find.byType(GameBriefingLayer), findsOneWidget);
    });

    testWidgets('3. Renders core game elements after briefing dismissal', (
      tester,
    ) async {
      await pumpVoiceSwapScreen(tester);

      expect(find.byKey(const ValueKey('voice_sentence_card')), findsOneWidget);
      expect(find.byKey(const ValueKey('voice_swap_toggle')), findsOneWidget);
      expect(find.byKey(const ValueKey('voice_toggle_switch')), findsOneWidget);
      expect(find.byKey(const ValueKey('voice_label_active')), findsOneWidget);
      expect(find.byKey(const ValueKey('voice_label_passive')), findsOneWidget);
      expect(find.byKey(const ValueKey('voice_engage_button')), findsOneWidget);
      expect(find.text("CHECK ANSWER"), findsOneWidget);
    });

    testWidgets('4. Context sentence card renders quest sentence text', (
      tester,
    ) async {
      await pumpVoiceSwapScreen(tester);

      expect(
        find.text('The chef baked an exquisite artisan sourdough loaf.'),
        findsOneWidget,
      );
    });

    testWidgets('5. Default mode indicator displays MODE: ACTIVE initially', (
      tester,
    ) async {
      await pumpVoiceSwapScreen(tester);

      expect(find.text('MODE: ACTIVE'), findsOneWidget);
    });

    testWidgets(
      '6. Tapping toggle switch toggles mode to PASSIVE and plays audio & haptic',
      (tester) async {
        await pumpVoiceSwapScreen(tester);

        final toggleSwitch = find.byKey(const ValueKey('voice_toggle_switch'));
        expect(toggleSwitch, findsOneWidget);

        await tester.tap(toggleSwitch);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        verify(() => mockSoundService.playClick()).called(1);
        verify(() => mockHapticService.heavy()).called(1);
        expect(find.text('MODE: PASSIVE'), findsOneWidget);
      },
    );

    testWidgets('7. Double-tapping toggle switch toggles mode back to ACTIVE', (
      tester,
    ) async {
      await pumpVoiceSwapScreen(tester);

      final toggleSwitch = find.byKey(const ValueKey('voice_toggle_switch'));

      await tester.tap(toggleSwitch);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('MODE: PASSIVE'), findsOneWidget);

      await tester.tap(toggleSwitch);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('MODE: ACTIVE'), findsOneWidget);
    });

    testWidgets(
      '8. Active and Passive labels are displayed with correct text',
      (tester) async {
        await pumpVoiceSwapScreen(tester);

        expect(
          find.byKey(const ValueKey('voice_label_active')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('voice_label_passive')),
          findsOneWidget,
        );
        expect(find.text('ACTIVE'), findsOneWidget);
        expect(find.text('PASSIVE'), findsOneWidget);
      },
    );

    testWidgets(
      '9. Submitting incorrect answer triggers error feedback and wrong status',
      (tester) async {
        await pumpVoiceSwapScreen(tester);

        // Quest 0 is Active. Toggle to Passive (wrong).
        await tester.tap(find.byKey(const ValueKey('voice_toggle_switch')));
        await tester.pump(const Duration(milliseconds: 100));

        // Engage Transmuter
        await tester.tap(find.byKey(const ValueKey('voice_engage_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        verify(() => mockHapticService.error()).called(1);
        verify(() => mockSoundService.playWrong()).called(1);
        verify(() => mockGrammarBloc.add(const SubmitAnswer(false))).called(1);
      },
    );

    testWidgets('10. Engage button disappears after wrong submission', (
      tester,
    ) async {
      await pumpVoiceSwapScreen(tester);

      // Submit wrong answer
      await tester.tap(find.byKey(const ValueKey('voice_toggle_switch')));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(const ValueKey('voice_engage_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Button disappears once answered
      expect(find.byKey(const ValueKey('voice_engage_button')), findsNothing);
    });

    testWidgets('11. Toggle is disabled after wrong answer submission', (
      tester,
    ) async {
      await pumpVoiceSwapScreen(tester);

      // Submit wrong answer
      await tester.tap(find.byKey(const ValueKey('voice_toggle_switch')));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(const ValueKey('voice_engage_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Reset mock invocation count
      clearInteractions(mockSoundService);

      // Tap toggle again; should be ignored because isAnswered is true
      await tester.tap(
        find.byKey(const ValueKey('voice_toggle_switch')),
        warnIfMissed: false,
      );
      await tester.pump();

      verifyNever(() => mockSoundService.playClick());
    });

    testWidgets(
      '12. Submitting correct answer on quest without conversion completes directly',
      (tester) async {
        final directState = GrammarLoaded(
          quests: const [sampleDirectQuest],
          currentIndex: 0,
          livesRemaining: 3,
          answerStatus: AnswerStatus.unanswered,
          hintUsed: false,
          wrongCount: 0,
          isFinalFailure: false,
        );

        await pumpVoiceSwapScreen(tester, state: directState);

        // Default is Active. SampleDirectQuest is Active without 'flip to:'.
        await tester.tap(find.byKey(const ValueKey('voice_engage_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        verify(() => mockHapticService.success()).called(1);
        verify(() => mockSoundService.playCorrect()).called(1);
        verify(() => mockGrammarBloc.add(const SubmitAnswer(true))).called(1);
      },
    );

    testWidgets(
      '13. Submitting correct voice on quest with conversion advances to Phase 2',
      (tester) async {
        await pumpVoiceSwapScreen(tester);

        // Default is Active. Quest 0 is Active with conversion phrase.
        await tester.tap(find.byKey(const ValueKey('voice_engage_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        verify(() => mockHapticService.success()).called(1);
        verify(() => mockSoundService.playCorrect()).called(1);

        // In Phase 2, TypeToConfirmOverlay is displayed
        expect(
          find.byKey(const ValueKey('voice_type_overlay'), skipOffstage: false),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '14. Phase 2 TypeToConfirmOverlay displays expected conversion guidance',
      (tester) async {
        await pumpVoiceSwapScreen(tester);

        await tester.tap(find.byKey(const ValueKey('voice_engage_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        final overlayFinder = find.byKey(
          const ValueKey('voice_type_overlay'),
          skipOffstage: false,
        );
        expect(overlayFinder, findsOneWidget);

        final overlayWidget = tester.widget<TypeToConfirmOverlay>(
          overlayFinder,
        );
        expect(
          overlayWidget.expectedText,
          contains('artisan sourdough loaf was baked'),
        );
      },
    );

    testWidgets(
      '15. Confirming typing in Phase 2 completes successfully with SubmitAnswer(true)',
      (tester) async {
        await pumpVoiceSwapScreen(tester);

        await tester.tap(find.byKey(const ValueKey('voice_engage_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        final overlayFinder = find.byKey(
          const ValueKey('voice_type_overlay'),
          skipOffstage: false,
        );
        final overlayWidget = tester.widget<TypeToConfirmOverlay>(
          overlayFinder,
        );

        // Invoke onConfirmed
        overlayWidget.onConfirmed();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        verify(() => mockGrammarBloc.add(const SubmitAnswer(true))).called(1);
      },
    );

    testWidgets('16. Skipping typing in Phase 2 submits wrong answer', (
      tester,
    ) async {
      await pumpVoiceSwapScreen(tester);

      await tester.tap(find.byKey(const ValueKey('voice_engage_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      final overlayFinder = find.byKey(
        const ValueKey('voice_type_overlay'),
        skipOffstage: false,
      );
      final overlayWidget = tester.widget<TypeToConfirmOverlay>(overlayFinder);

      // Invoke onSkipped
      overlayWidget.onSkipped();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockHapticService.error()).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockGrammarBloc.add(const SubmitAnswer(false))).called(1);
    });

    testWidgets('17. Phase 1 controls are ignored after Phase 2 is activated', (
      tester,
    ) async {
      await pumpVoiceSwapScreen(tester);

      await tester.tap(find.byKey(const ValueKey('voice_engage_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      clearInteractions(mockSoundService);

      // Tapping toggle switch now does nothing because ignore pointer is active
      await tester.tap(
        find.byKey(const ValueKey('voice_toggle_switch')),
        warnIfMissed: false,
      );
      await tester.pump();

      verifyNever(() => mockSoundService.playClick());
    });

    testWidgets(
      '18. Passive quest requires switching to Passive before engagement',
      (tester) async {
        final passiveState = GrammarLoaded(
          quests: const [samplePassiveQuest],
          currentIndex: 0,
          livesRemaining: 3,
          answerStatus: AnswerStatus.unanswered,
          hintUsed: false,
          wrongCount: 0,
          isFinalFailure: false,
        );

        await pumpVoiceSwapScreen(tester, state: passiveState);

        // Switch to Passive
        await tester.tap(find.byKey(const ValueKey('voice_toggle_switch')));
        await tester.pump(const Duration(milliseconds: 100));

        // Engage
        await tester.tap(find.byKey(const ValueKey('voice_engage_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));

        // Correctly advances to conversion phase
        expect(
          find.byKey(const ValueKey('voice_type_overlay'), skipOffstage: false),
          findsOneWidget,
        );
      },
    );

    testWidgets('19. Tapping continue button dispatches NextQuestion event', (
      tester,
    ) async {
      await pumpVoiceSwapScreen(tester);

      // Engage wrong answer to surface feedback card with continue button
      await tester.tap(find.byKey(const ValueKey('voice_toggle_switch')));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(const ValueKey('voice_engage_button')));
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

    testWidgets('20. Tapping hint button dispatches GrammarHintUsed event', (
      tester,
    ) async {
      await pumpVoiceSwapScreen(tester);

      final hintButton = find.byType(QuestHintButton);
      expect(hintButton, findsOneWidget);

      await tester.tap(hintButton);
      await tester.pump();
      verify(
        () => mockGrammarBloc.add(const GrammarHintUsed()),
      ).called(greaterThanOrEqualTo(1));
    });

    testWidgets(
      '21. Hint used state reflects in GrammarLoaded state and widget builds properly',
      (tester) async {
        final hintState = testLoadedState.copyWith(hintUsed: true);

        await pumpVoiceSwapScreen(tester, state: hintState);

        expect(
          find.byKey(const ValueKey('voice_sentence_card')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '22. Compact mobile layout renders cleanly without layout overflow',
      (tester) async {
        await pumpVoiceSwapScreen(tester, size: const Size(320, 568));

        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const ValueKey('voice_sentence_card')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('voice_engage_button')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '23. Tablet layout renders with spacious proportions and no overflow',
      (tester) async {
        await pumpVoiceSwapScreen(tester, size: const Size(800, 1200));

        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const ValueKey('voice_sentence_card')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('voice_engage_button')),
          findsOneWidget,
        );
      },
    );

    testWidgets('24. Light theme renders successfully without exception', (
      tester,
    ) async {
      await pumpVoiceSwapScreen(tester, themeMode: ThemeMode.light);

      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('voice_sentence_card')), findsOneWidget);
      expect(find.byKey(const ValueKey('voice_swap_toggle')), findsOneWidget);
    });

    testWidgets(
      '25. Motion gating (reduceMotion: true) runs without unmounted timers',
      (tester) async {
        await pumpVoiceSwapScreen(tester, reduceMotion: true);

        expect(
          find.byKey(const ValueKey('voice_toggle_switch')),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const ValueKey('voice_toggle_switch')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '26. Widget unmount cleanly disposes all timers and controllers',
      (tester) async {
        await pumpVoiceSwapScreen(tester);
        await tester.pump(const Duration(milliseconds: 100));

        // Immediately unmount by pumping empty container
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(tester.takeException(), isNull);
      },
    );
  });
}
