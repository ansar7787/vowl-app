import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mocktail/mocktail.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/core/presentation/game_mechanics/shared/game_skip_bypass_button.dart';
import 'package:vowl/core/presentation/game_mechanics/speaking/speak_to_confirm_overlay.dart';
import 'package:vowl/core/presentation/widgets/game_error_view.dart';
import 'package:vowl/core/presentation/widgets/quest_hint_button.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/theme/theme_cubit.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/analytics_service.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/audio_recording_service.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/speech_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/features/elite_mastery/domain/entities/elite_mastery_quest.dart';
import 'package:vowl/features/elite_mastery/idiom_match/presentation/pages/idiom_match_screen.dart';
import 'package:vowl/features/elite_mastery/idiom_match/presentation/widgets/idiom_match_options_panel.dart';
import 'package:vowl/features/elite_mastery/presentation/bloc/elite_mastery_bloc.dart';
import 'package:vowl/features/elite_mastery/presentation/layout/elite_base_layout.dart';
import 'package:vowl/features/elite_mastery/presentation/widgets/elite_feedback_card.dart';
import 'package:vowl/features/elite_mastery/presentation/widgets/elite_game_header.dart';
import 'package:vowl/features/elite_mastery/presentation/widgets/elite_hint_card.dart';

class MockEliteMasteryBloc
    extends MockBloc<EliteMasteryEvent, EliteMasteryState>
    implements EliteMasteryBloc {}

class MockThemeCubit extends MockCubit<ThemeState> implements ThemeCubit {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockEconomyBloc extends MockBloc<EconomyEvent, EconomyState>
    implements EconomyBloc {}

class MockHapticService extends Mock implements HapticService {}

class MockSoundService extends Mock implements SoundService {}

class MockTtsService extends Mock implements TtsService {}

class MockAudioRecordingService extends Mock implements AudioRecordingService {}

class MockSpeechService extends Mock implements SpeechService {}

class MockLocaleService extends Mock implements LocaleService {}

class MockAppLogger extends Mock implements AppLogger {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockAdService extends Mock implements AdService {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

class FakeEliteMasteryEvent extends Fake implements EliteMasteryEvent {}

class FakeEliteMasteryState extends Fake implements EliteMasteryState {}

class FakeAuthEvent extends Fake implements AuthEvent {}

class FakeAuthState extends Fake implements AuthState {}

class FakeEconomyEvent extends Fake implements EconomyEvent {}

class FakeEconomyState extends Fake implements EconomyState {}

class FakeThemeState extends Fake implements ThemeState {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  late MockEliteMasteryBloc mockEliteBloc;
  late MockThemeCubit mockThemeCubit;
  late MockAuthBloc mockAuthBloc;
  late MockEconomyBloc mockEconomyBloc;
  late MockHapticService mockHapticService;
  late MockSoundService mockSoundService;
  late MockTtsService mockTtsService;
  late MockAudioRecordingService mockAudioRecorder;
  late MockSpeechService mockSpeechService;
  late MockLocaleService mockLocaleService;
  late MockAppLogger mockAppLogger;
  late MockAnalyticsService mockAnalyticsService;
  late MockAdService mockAdService;
  late MockNetworkInfo mockNetworkInfo;
  late StreamController<EliteMasteryState> eliteStreamController;

  EliteMasteryQuest createSampleIdiomQuest({
    String id = 'quest_im_1',
    String instruction = 'Choose the correct meaning of the idiom.',
    int difficulty = 1,
    String? question = 'Bite the bullet',
    List<String>? options = const [
      'Face a difficult situation with courage',
      'Eat something crunchy',
      'Go to sleep early',
      'Avoid making a decision',
    ],
    int? correctAnswerIndex = 0,
    String? hint = 'Think of wartime surgery before anesthesia was invented.',
    String? explanation =
        'To endure a painful or difficult situation with resilience.',
    String? usageContext =
        'He had to bite the bullet and accept the demotion.',
    String? idiomOrigin =
        'Originates from soldiers biting on lead bullets during surgery.',
    String? visualMetaphor =
        'Clenching teeth against physical pain to prevent screaming.',
  }) {
    return EliteMasteryQuest(
      id: id,
      type: QuestType.eliteMastery,
      subtype: GameSubtype.idiomMatch,
      instruction: instruction,
      difficulty: difficulty,
      question: question,
      options: options,
      correctAnswerIndex: correctAnswerIndex,
      hint: hint,
      explanation: explanation,
      usageContext: usageContext,
      idiomOrigin: idiomOrigin,
      visualMetaphor: visualMetaphor,
    );
  }

  final sampleIdiomQuest1 = createSampleIdiomQuest();

  final sampleIdiomQuest2 = createSampleIdiomQuest(
    id: 'quest_im_2',
    question: 'Burn the midnight oil',
    options: [
      'Work late into the night',
      'Start a dangerous fire',
      'Waste precious fuel',
      'Wake up at dawn',
    ],
    correctAnswerIndex: 0,
    hint: 'Refers to oil lamps used to study or work in the dark.',
  );

  final testLoadedState = EliteMasteryLoaded(
    gameType: GameSubtype.idiomMatch,
    level: 2,
    quests: [sampleIdiomQuest1, sampleIdiomQuest2],
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
  );

  setUpAll(() {
    registerFallbackValue(FakeEliteMasteryEvent());
    registerFallbackValue(FakeEliteMasteryState());
    registerFallbackValue(FakeAuthEvent());
    registerFallbackValue(FakeAuthState());
    registerFallbackValue(FakeEconomyEvent());
    registerFallbackValue(FakeEconomyState());
    registerFallbackValue(FakeThemeState());
    registerFallbackValue(const SubmitEliteAnswer(true));
    registerFallbackValue(const SubmitEliteAnswer(false));
    registerFallbackValue(const NextEliteQuestion());
    registerFallbackValue(const ShowEliteHint());
    registerFallbackValue(const MarkEliteHintUsed());
    registerFallbackValue(
      const FetchEliteMasteryQuests(
        gameType: GameSubtype.idiomMatch,
        level: 2,
      ),
    );
    registerFallbackValue(const EliteSpeakConfirmed(5));
    registerFallbackValue(const EconomyAddCoinsRequested(5));
    registerFallbackValue(const Duration(milliseconds: 100));
    registerFallbackValue(ListenMode.dictation);
  });

  setUp(() async {
    mockEliteBloc = MockEliteMasteryBloc();
    mockThemeCubit = MockThemeCubit();
    mockAuthBloc = MockAuthBloc();
    mockEconomyBloc = MockEconomyBloc();
    mockHapticService = MockHapticService();
    mockSoundService = MockSoundService();
    mockTtsService = MockTtsService();
    mockAudioRecorder = MockAudioRecordingService();
    mockLocaleService = MockLocaleService();
    mockAppLogger = MockAppLogger();
    mockAnalyticsService = MockAnalyticsService();
    mockAdService = MockAdService();
    mockNetworkInfo = MockNetworkInfo();

    eliteStreamController = StreamController<EliteMasteryState>.broadcast();

    // Haptics
    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});
    when(() => mockHapticService.heavy()).thenAnswer((_) async {});

    // Sounds
    when(() => mockSoundService.playCorrect()).thenAnswer((_) async {});
    when(() => mockSoundService.playWrong()).thenAnswer((_) async {});
    when(() => mockSoundService.stopAudio()).thenAnswer((_) async {});
    when(() => mockSoundService.stopTts()).thenAnswer((_) async {});
    when(() => mockSoundService.playHint()).thenAnswer((_) async {});
    when(() => mockSoundService.playClick()).thenAnswer((_) async {});
    when(() => mockSoundService.playLevelComplete()).thenAnswer((_) async {});
    when(() => mockSoundService.playFile(any())).thenAnswer((_) async {});
    when(
      () => mockSoundService.playTts(any(), speed: any(named: 'speed')),
    ).thenAnswer((_) async {});

    // TTS
    when(() => mockTtsService.stop()).thenAnswer((_) async {});
    when(
      () => mockTtsService.speak(
        any(),
        rate: any(named: 'rate'),
        locale: any(named: 'locale'),
      ),
    ).thenAnswer((_) async {});

    // Audio Recorder
    when(() => mockAudioRecorder.isRecording).thenReturn(false);
    when(() => mockAudioRecorder.hasPermission()).thenAnswer((_) async => true);
    when(() => mockAudioRecorder.startRecording()).thenAnswer((_) async => true);
    when(
      () => mockAudioRecorder.stopRecording(),
    ).thenAnswer((_) async => '/mock/audio.m4a');
    when(() => mockAudioRecorder.dispose()).thenAnswer((_) async {});
    when(
      () => mockAudioRecorder.onAmplitudeChanged(any()),
    ).thenAnswer((_) => const Stream<Amplitude>.empty());

    // Speech Service
    mockSpeechService = MockSpeechService();
    when(() => mockSpeechService.isPlaying).thenReturn(false);
    when(() => mockSpeechService.isListening).thenReturn(false);
    when(() => mockSpeechService.initializeStt()).thenAnswer((_) async => true);
    when(() => mockSpeechService.stop()).thenAnswer((_) async {});
    when(() => mockSpeechService.cancel()).thenAnswer((_) async {});
    when(() => mockSpeechService.setWordCallback(any())).thenReturn(null);
    when(() => mockSpeechService.setSpeechRate(any())).thenAnswer((_) async {});
    when(
      () => mockSpeechService.listen(
        onResult: any(named: 'onResult'),
        onDone: any(named: 'onDone'),
        onSoundLevelChange: any(named: 'onSoundLevelChange'),
        localeId: any(named: 'localeId'),
        pauseFor: any(named: 'pauseFor'),
        listenMode: any(named: 'listenMode'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => mockSpeechService.speak(
        any(),
        rate: any(named: 'rate'),
        locale: any(named: 'locale'),
      ),
    ).thenAnswer((_) async {});

    // Analytics & Ads
    when(() => mockAnalyticsService.logGameSkipped(any())).thenAnswer((_) async {});
    when(() => mockAnalyticsService.logSelfEvaluation(any())).thenAnswer((_) async {});
    when(
      () => mockAdService.showRewardedAd(
        context: any(named: 'context'),
        isPremium: any(named: 'isPremium'),
        onUserEarnedReward: any(named: 'onUserEarnedReward'),
        onDismissed: any(named: 'onDismissed'),
      ),
    ).thenAnswer((inv) {
      final onEarned = inv.namedArguments[#onUserEarnedReward] as dynamic;
      onEarned?.call(RewardItem(1, 'coin'));
    });

    // Theme mock
    when(
      () => mockThemeCubit.state,
    ).thenReturn(const ThemeState(themeMode: ThemeMode.dark, isMidnight: false));
    when(
      () => mockThemeCubit.stream,
    ).thenAnswer((_) => const Stream<ThemeState>.empty());

    // Auth mock (premium user)
    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(
        const UserEntity(
          id: 'test_user_id',
          email: 'elite@vowl.app',
          displayName: 'IdiomMaster',
          hintCount: 3,
          isPremium: true,
        ),
      ),
    );
    when(() => mockAuthBloc.stream)
        .thenAnswer((_) => const Stream<AuthState>.empty());

    // Economy mock
    when(() => mockEconomyBloc.state).thenReturn(const EconomyState());
    when(() => mockEconomyBloc.stream)
        .thenAnswer((_) => const Stream<EconomyState>.empty());

    // Network mock
    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

    // Elite Bloc default state
    when(() => mockEliteBloc.state).thenReturn(testLoadedState);
    when(
      () => mockEliteBloc.stream,
    ).thenAnswer((_) => eliteStreamController.stream);

    await di.sl.reset();
    di.sl.registerSingleton<HapticService>(mockHapticService);
    di.sl.registerSingleton<SoundService>(mockSoundService);
    di.sl.registerSingleton<TtsService>(mockTtsService);
    di.sl.registerSingleton<AudioRecordingService>(mockAudioRecorder);
    di.sl.registerSingleton<SpeechService>(mockSpeechService);
    di.sl.registerSingleton<LocaleService>(mockLocaleService);
    di.sl.registerSingleton<AppLogger>(mockAppLogger);
    di.sl.registerSingleton<AnalyticsService>(mockAnalyticsService);
    di.sl.registerSingleton<AdService>(mockAdService);
    di.sl.registerSingleton<NetworkInfo>(mockNetworkInfo);

    VowlMotion.lowAnimationModeOverride.value = true;
  });

  tearDown(() async {
    await eliteStreamController.close();
    VowlMotion.lowAnimationModeOverride.value = false;
    if (di.sl.isRegistered<HapticService>()) di.sl.unregister<HapticService>();
    if (di.sl.isRegistered<SoundService>()) di.sl.unregister<SoundService>();
    if (di.sl.isRegistered<TtsService>()) di.sl.unregister<TtsService>();
    if (di.sl.isRegistered<AudioRecordingService>()) {
      di.sl.unregister<AudioRecordingService>();
    }
    if (di.sl.isRegistered<SpeechService>()) di.sl.unregister<SpeechService>();
    if (di.sl.isRegistered<LocaleService>()) di.sl.unregister<LocaleService>();
    if (di.sl.isRegistered<AppLogger>()) di.sl.unregister<AppLogger>();
    if (di.sl.isRegistered<AnalyticsService>()) {
      di.sl.unregister<AnalyticsService>();
    }
    if (di.sl.isRegistered<AdService>()) di.sl.unregister<AdService>();
    if (di.sl.isRegistered<NetworkInfo>()) di.sl.unregister<NetworkInfo>();
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    EliteMasteryState? state,
    int level = 2,
    ThemeMode themeMode = ThemeMode.dark,
    double textScaleFactor = 1.0,
    Size surfaceSize = const Size(390, 844),
    bool settle = true,
  }) async {
    tester.view.physicalSize = surfaceSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    if (state != null) {
      when(() => mockEliteBloc.state).thenReturn(state);
    }

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<EliteMasteryBloc>.value(value: mockEliteBloc),
          BlocProvider<ThemeCubit>.value(value: mockThemeCubit),
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<EconomyBloc>.value(value: mockEconomyBloc),
        ],
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) {
            return MaterialApp(
              themeMode: themeMode,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              home: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(textScaleFactor),
                  disableAnimations: true,
                ),
                child: IdiomMatchScreen(level: level),
              ),
            );
          },
        ),
      ),
    );

    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 1: Initial Rendering & Layout Hierarchy
  // ═══════════════════════════════════════════════════════════════════════════
  group('IdiomMatchScreen - 1. Initial Rendering & Layout Hierarchy', () {
    testWidgets('renders EliteBaseLayout, EliteGameHeader, CustomScrollView and instruction banner', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(find.byType(EliteBaseLayout), findsOneWidget);
      expect(find.byType(EliteGameHeader), findsOneWidget);
      expect(
        find.byKey(const Key('idiom_match_scroll_view')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('idiom_match_instruction_banner')),
        findsOneWidget,
      );
      expect(
        find.text(sampleIdiomQuest1.instruction),
        findsOneWidget,
      );
    });

    testWidgets('renders idiom prompt card with quotation icon and question text', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(
        find.byKey(const Key('idiom_match_prompt_card')),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.format_quote_rounded), findsOneWidget);
      expect(find.text(sampleIdiomQuest1.question!), findsOneWidget);
    });

    testWidgets('renders IdiomMatchOptionsPanel with all shuffled options', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(find.byType(IdiomMatchOptionsPanel), findsOneWidget);
      for (final option in sampleIdiomQuest1.options!) {
        expect(find.text(option), findsOneWidget);
      }
    });

    testWidgets('renders ShimmerLoading when EliteMasteryLoading is active', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        state: const EliteMasteryLoading(),
        settle: false,
      );

      expect(find.byType(ShimmerLoading), findsWidgets);
      expect(find.byType(IdiomMatchOptionsPanel), findsNothing);
    });

    testWidgets('renders GameErrorView on EliteMasteryError and retries on tap', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        state: const EliteMasteryError('Network failure occurred'),
      );

      expect(find.byType(GameErrorView), findsOneWidget);

      final retryBtn = find.text('TRY AGAIN');
      if (retryBtn.evaluate().isNotEmpty) {
        await tester.tap(retryBtn);
        await tester.pump();
        verify(
          () => mockEliteBloc.add(
            const FetchEliteMasteryQuests(
              gameType: GameSubtype.idiomMatch,
              level: 2,
            ),
          ),
        ).called(greaterThanOrEqualTo(1));
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 2: Option Selection & Stage 1 Evaluation
  // ═══════════════════════════════════════════════════════════════════════════
  group('IdiomMatchScreen - 2. Option Selection & Stage 1 Evaluation', () {
    testWidgets('tapping wrong option triggers haptic error, sound, and marks option as wrong', (
      tester,
    ) async {
      await pumpScreen(tester);

      // 'Eat something crunchy' is an incorrect meaning
      final wrongOption = find.text('Eat something crunchy');
      expect(wrongOption, findsOneWidget);

      await tester.tap(wrongOption);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      verify(() => mockHapticService.error()).called(1);
      verify(() => mockSoundService.playWrong()).called(1);

      // Verify Stage 2 overlay is NOT shown on wrong selection
      expect(find.byType(SpeakToConfirmOverlay), findsNothing);
    });

    testWidgets('tapping wrong option submits wrong answer to bloc', (
      tester,
    ) async {
      await pumpScreen(tester);

      final wrongOption = find.text('Avoid making a decision');
      expect(wrongOption, findsOneWidget);

      await tester.tap(wrongOption);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      verify(() => mockEliteBloc.add(const SubmitEliteAnswer(false))).called(1);
      expect(find.byType(SpeakToConfirmOverlay), findsNothing);
    });

    testWidgets('tapping already-marked wrong option does not re-submit or duplicate error', (
      tester,
    ) async {
      await pumpScreen(tester);

      final wrongOption = find.text('Go to sleep early');
      await tester.tap(wrongOption);
      await tester.pumpAndSettle();

      verify(() => mockHapticService.error()).called(1);

      // Tap the same wrong option again
      await tester.tap(wrongOption, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Still only 1 call
      verifyNever(() => mockHapticService.error());
    });

    testWidgets('tapping correct option passes Stage 1, triggers haptic selection, and reveals Stage 2', (
      tester,
    ) async {
      await pumpScreen(tester);

      // Correct answer is 'Face a difficult situation with courage'
      final correctOption = find.text('Face a difficult situation with courage');
      expect(correctOption, findsOneWidget);

      await tester.tap(correctOption);
      await tester.pumpAndSettle();

      verify(() => mockHapticService.selection()).called(1);

      // Stage 2 SpeakToConfirmOverlay and insights are now visible
      expect(find.byType(SpeakToConfirmOverlay), findsOneWidget);
      expect(
        find.byKey(const Key('idiom_match_insights_panel')),
        findsOneWidget,
      );

      // Verify that SubmitEliteAnswer was NOT called yet (waiting for verbal confirmation)
      verifyNever(() => mockEliteBloc.add(const SubmitEliteAnswer(true)));
    });

    testWidgets('once answered, options are disabled and do not respond to taps', (
      tester,
    ) async {
      await pumpScreen(tester);

      // Pass stage 1
      await tester.tap(find.text('Face a difficult situation with courage'));
      await tester.pumpAndSettle();

      // Premium user skips speech to complete the answer
      final skipBtn = find.text('SKIP');
      if (skipBtn.evaluate().isNotEmpty) {
        await tester.tap(skipBtn);
        await tester.pumpAndSettle();
      }

      // Now game is answered. Tapping options should have no effect
      final otherOption = find.text('Eat something crunchy');
      await tester.tap(otherOption, warnIfMissed: false);
      await tester.pumpAndSettle();

      // No new selection or error haptics after answer complete
      verifyNever(() => mockHapticService.error());
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 3: Pedagogical Insights & Annotations
  // ═══════════════════════════════════════════════════════════════════════════
  group('IdiomMatchScreen - 3. Pedagogical Insights & Annotations', () {
    testWidgets('insights panel is hidden in initial state before Stage 1 is passed', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(
        find.byKey(const Key('idiom_match_insights_panel')),
        findsNothing,
      );
    });

    testWidgets('passing Stage 1 reveals insights panel with EXPLANATION, USAGE CONTEXT, IDIOM ORIGIN, and VISUAL METAPHOR', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Face a difficult situation with courage'));
      await tester.pumpAndSettle();

      final insightsFinder = find.byKey(
        const Key('idiom_match_insights_panel'),
      );
      expect(insightsFinder, findsOneWidget);
      expect(find.text('EXPLANATION'), findsOneWidget);
      expect(find.text(sampleIdiomQuest1.explanation!), findsOneWidget);

      expect(find.text('USAGE CONTEXT'), findsOneWidget);
      expect(find.text(sampleIdiomQuest1.usageContext!), findsOneWidget);

      expect(find.text('IDIOM ORIGIN'), findsOneWidget);
      expect(find.text(sampleIdiomQuest1.idiomOrigin!), findsOneWidget);

      expect(find.text('VISUAL METAPHOR'), findsOneWidget);
      expect(find.text(sampleIdiomQuest1.visualMetaphor!), findsOneWidget);
    });

    testWidgets('insights panel handles subset of annotations gracefully', (
      tester,
    ) async {
      final partialQuest = createSampleIdiomQuest(
        id: 'quest_partial_insights',
        usageContext: null,
        visualMetaphor: null,
      );
      final partialState = EliteMasteryLoaded(
        gameType: GameSubtype.idiomMatch,
        level: 2,
        quests: [partialQuest],
        currentIndex: 0,
        livesRemaining: 3,
      );

      await pumpScreen(tester, state: partialState);

      await tester.tap(find.text('Face a difficult situation with courage'));
      await tester.pumpAndSettle();

      final insightsFinder = find.byKey(
        const Key('idiom_match_insights_panel'),
      );
      expect(insightsFinder, findsOneWidget);
      expect(find.text('EXPLANATION'), findsOneWidget);
      expect(find.text('IDIOM ORIGIN'), findsOneWidget);
      expect(find.text('USAGE CONTEXT'), findsNothing);
      expect(find.text('VISUAL METAPHOR'), findsNothing);
    });

    testWidgets('insights panel is completely omitted if quest has no pedagogical metadata', (
      tester,
    ) async {
      final bareQuest = createSampleIdiomQuest(
        id: 'quest_bare',
        explanation: null,
        usageContext: null,
        idiomOrigin: null,
        visualMetaphor: null,
      );
      final bareState = EliteMasteryLoaded(
        gameType: GameSubtype.idiomMatch,
        level: 2,
        quests: [bareQuest],
        currentIndex: 0,
        livesRemaining: 3,
      );

      await pumpScreen(tester, state: bareState);

      await tester.tap(find.text('Face a difficult situation with courage'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('idiom_match_insights_panel')),
        findsNothing,
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 4: Stage 2 Verbal Confirmation & Bypass
  // ═══════════════════════════════════════════════════════════════════════════
  group('IdiomMatchScreen - 4. Stage 2 Verbal Confirmation & Bypass', () {
    testWidgets('passing Stage 1 reveals SpeakToConfirmOverlay with title, subtitle, and expected text', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Face a difficult situation with courage'));
      await tester.pumpAndSettle();

      expect(find.byType(SpeakToConfirmOverlay), findsOneWidget);
      expect(find.text('SPEAK THE IDIOM'), findsOneWidget);
      expect(find.text('Say the idiom aloud to confirm'), findsOneWidget);
      expect(
        find.text('Face a difficult situation with courage'),
        findsWidgets, // in options panel + overlay expected text
      );
    });

    testWidgets('Stage 2: tapping SKIP via GameSkipBypassButton confirms verbal evaluation for premium user', (
      tester,
    ) async {
      await pumpScreen(tester);

      // Pass Stage 1
      await tester.tap(find.text('Face a difficult situation with courage'));
      await tester.pumpAndSettle();

      final bypassButton = find.byType(GameSkipBypassButton);
      await tester.scrollUntilVisible(bypassButton, 200);
      expect(bypassButton, findsOneWidget);

      await tester.tap(find.text('SKIP'));
      await tester.pumpAndSettle();

      verify(() => mockHapticService.success()).called(1);
      verify(() => mockSoundService.playCorrect()).called(1);
      verify(() => mockEliteBloc.add(const EliteSpeakConfirmed(5))).called(1);
      verify(() => mockEliteBloc.add(const SubmitEliteAnswer(true))).called(1);
    });

    testWidgets('Stage 2: manual evaluation flow - recording audio and tapping Nailed It confirms speaking', (
      tester,
    ) async {
      await pumpScreen(tester);

      // Pass Stage 1
      await tester.tap(find.text('Face a difficult situation with courage'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      await tester.drag(
        find.byKey(const Key('idiom_match_scroll_view')),
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();

      // Switch to manual evaluation
      final manualEvalBtn = find.text('Evaluate myself manually');
      expect(manualEvalBtn, findsOneWidget);
      await tester.tap(manualEvalBtn);
      await tester.pumpAndSettle();

      // Tap microphone button to record
      final micButton = find.byKey(const ValueKey('speaking_mic_btn'));
      expect(micButton, findsOneWidget);
      await tester.tap(micButton);
      await tester.pump();
      verify(() => mockAudioRecorder.startRecording()).called(1);

      // Stop recording
      when(() => mockAudioRecorder.isRecording).thenReturn(true);
      await tester.tap(micButton);
      await tester.pumpAndSettle();
      verify(() => mockAudioRecorder.stopRecording()).called(1);

      // Tap Nailed It
      final nailedItBtn = find.text('Nailed It');
      expect(nailedItBtn, findsOneWidget);
      await tester.tap(nailedItBtn);
      await tester.pumpAndSettle();

      verify(() => mockHapticService.success()).called(1);
      verify(() => mockSoundService.playCorrect()).called(1);
      verify(() => mockEliteBloc.add(const EliteSpeakConfirmed(5))).called(1);
      verify(() => mockEliteBloc.add(const SubmitEliteAnswer(true))).called(1);
    });

    testWidgets('Stage 2: manual evaluation flow - recording audio and tapping Needs Work submits wrong verbal evaluation', (
      tester,
    ) async {
      await pumpScreen(tester);

      // Pass Stage 1
      await tester.tap(find.text('Face a difficult situation with courage'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      await tester.drag(
        find.byKey(const Key('idiom_match_scroll_view')),
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();

      // Switch to manual evaluation
      final manualEvalBtn = find.text('Evaluate myself manually');
      await tester.tap(manualEvalBtn);
      await tester.pumpAndSettle();

      final micButton = find.byKey(const ValueKey('speaking_mic_btn'));
      await tester.tap(micButton);
      await tester.pump();

      when(() => mockAudioRecorder.isRecording).thenReturn(true);
      await tester.tap(micButton);
      await tester.pumpAndSettle();

      // Tap Needs Work
      final needsWorkBtn = find.text('Needs Work');
      expect(needsWorkBtn, findsOneWidget);
      await tester.tap(needsWorkBtn);
      await tester.pumpAndSettle();

      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockHapticService.error()).called(1);
    });

    testWidgets('Stage 2: STT auto-pass skips speech via overlay controls and marks answer as skipped', (
      tester,
    ) async {
      // In non-premium state or tapping skip speaking
      when(() => mockAuthBloc.state).thenReturn(
        AuthState.authenticated(
          const UserEntity(
            id: 'free_user',
            email: 'free@vowl.app',
            isPremium: false,
          ),
        ),
      );

      await pumpScreen(tester);

      await tester.tap(find.text('Face a difficult situation with courage'));
      await tester.pumpAndSettle();

      await tester.drag(
        find.byKey(const Key('idiom_match_scroll_view')),
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();

      // Find the overlay and tap skip speaking
      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byType(SpeakToConfirmOverlay),
      );
      overlay.onSkipped();
      await tester.pumpAndSettle();

      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockHapticService.error()).called(1);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 5: Game Lifecycle & State Transitions
  // ═══════════════════════════════════════════════════════════════════════════
  group('IdiomMatchScreen - 5. Game Lifecycle & State Transitions', () {
    testWidgets('tapping hint button dispatches MarkEliteHintUsed and ShowEliteHint', (
      tester,
    ) async {
      await pumpScreen(tester);

      final hintButton = find.byType(QuestHintButton);
      expect(hintButton, findsOneWidget);

      await tester.tap(hintButton);
      await tester.pump();

      verify(() => mockEliteBloc.add(any(that: isA<MarkEliteHintUsed>()))).called(1);
      verify(() => mockEliteBloc.add(any(that: isA<ShowEliteHint>()))).called(1);
    });

    testWidgets('displays EliteHintCard when isHintVisible is true', (
      tester,
    ) async {
      final hintVisibleState = EliteMasteryLoaded(
        gameType: GameSubtype.idiomMatch,
        level: 2,
        quests: [sampleIdiomQuest1],
        currentIndex: 0,
        livesRemaining: 3,
        isHintVisible: true,
        isHintUsed: true,
      );

      await pumpScreen(tester, state: hintVisibleState);

      expect(find.byType(EliteHintCard), findsOneWidget);
      expect(
        find.text(sampleIdiomQuest1.hint!),
        findsOneWidget,
      );
    });

    testWidgets('tapping hint button when quest hint is empty/null triggers hint ad dialog', (
      tester,
    ) async {
      final noHintQuest = createSampleIdiomQuest(
        id: 'quest_no_hint',
        hint: '',
      );
      final noHintState = EliteMasteryLoaded(
        gameType: GameSubtype.idiomMatch,
        level: 2,
        quests: [noHintQuest],
        currentIndex: 0,
        livesRemaining: 3,
      );

      await pumpScreen(tester, state: noHintState);

      await tester.tap(find.byType(QuestHintButton));
      await tester.pumpAndSettle();

      expect(find.text('NEED A HINT?'), findsOneWidget);
    });

    testWidgets('EliteFeedbackCard appears on answered; tapping continue dispatches NextEliteQuestion', (
      tester,
    ) async {
      final answeredState = EliteMasteryLoaded(
        gameType: GameSubtype.idiomMatch,
        level: 2,
        quests: [sampleIdiomQuest1, sampleIdiomQuest2],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.correct,
      );

      await pumpScreen(tester, state: answeredState);

      expect(find.byType(EliteFeedbackCard), findsOneWidget);

      final continueButton = find.text('CONTINUE');
      expect(continueButton, findsOneWidget);

      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      verify(() => mockEliteBloc.add(const NextEliteQuestion())).called(1);
    });

    testWidgets('state transition to EliteMasteryGameComplete shows level complete dialog and flushes confetti timer', (
      tester,
    ) async {
      await pumpScreen(tester);

      const completeState = EliteMasteryGameComplete(
        xpEarned: 5,
        coinsEarned: 10,
        questCount: 3,
      );

      when(() => mockEliteBloc.state).thenReturn(completeState);
      eliteStreamController.add(completeState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('LEVEL COMPLETE!'), findsOneWidget);

      Navigator.of(tester.element(find.text('LEVEL COMPLETE!'))).pop();
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('EliteMasteryGameOver renders dimmed view with zero lives', (
      tester,
    ) async {
      final gameOverState = EliteMasteryGameOver(
        gameType: GameSubtype.idiomMatch,
        level: 2,
        quests: [sampleIdiomQuest1],
        currentIndex: 0,
      );

      await pumpScreen(tester, state: gameOverState);

      expect(find.byType(AbsorbPointer), findsWidgets);
    });

    testWidgets('gracefully handles empty quests list without throwing', (
      tester,
    ) async {
      final emptyQuestsState = EliteMasteryLoaded(
        gameType: GameSubtype.idiomMatch,
        level: 2,
        quests: const [],
        currentIndex: 0,
        livesRemaining: 3,
      );

      await pumpScreen(tester, state: emptyQuestsState);

      expect(tester.takeException(), isNull);
      expect(find.byType(IdiomMatchScreen), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 6: Responsive Layout, Text Scaling & Accessibility
  // ═══════════════════════════════════════════════════════════════════════════
  group('IdiomMatchScreen - 6. Responsive Layout, Text Scaling & Accessibility', () {
    testWidgets('renders cleanly on compact screen (320x568) without overflow', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        surfaceSize: const Size(320, 568),
      );

      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const Key('idiom_match_scroll_view')),
        findsOneWidget,
      );
    });

    testWidgets('renders cleanly on tablet viewport (800x1280)', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        surfaceSize: const Size(800, 1280),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(IdiomMatchOptionsPanel), findsOneWidget);
    });

    testWidgets('renders properly with enlarged textScaler (1.3x)', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        textScaleFactor: 1.3,
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(IdiomMatchOptionsPanel), findsOneWidget);
      expect(
        find.byKey(const Key('idiom_match_prompt_card')),
        findsOneWidget,
      );
    });

    testWidgets('accessible semantics: options have button semantics', (
      tester,
    ) async {
      await pumpScreen(tester);

      final optionFinder = find.byKey(const Key('idiom_match_option_0'));
      expect(optionFinder, findsOneWidget);

      final semantics = tester.getSemantics(optionFinder);
      expect(semantics.flagsCollection.isButton, isTrue);
    });

    testWidgets('renders cleanly in light and dark theme modes', (
      tester,
    ) async {
      // Light Mode
      when(
        () => mockThemeCubit.state,
      ).thenReturn(const ThemeState(themeMode: ThemeMode.light, isMidnight: false));

      await pumpScreen(
        tester,
        themeMode: ThemeMode.light,
      );

      expect(find.byType(EliteBaseLayout), findsOneWidget);
      expect(find.byType(IdiomMatchOptionsPanel), findsOneWidget);

      // Dark Mode
      when(
        () => mockThemeCubit.state,
      ).thenReturn(const ThemeState(themeMode: ThemeMode.dark, isMidnight: false));

      await pumpScreen(
        tester,
        themeMode: ThemeMode.dark,
      );

      expect(find.byType(EliteBaseLayout), findsOneWidget);
      expect(find.byType(IdiomMatchOptionsPanel), findsOneWidget);
    });
  });
}
