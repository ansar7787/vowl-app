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
import 'package:vowl/features/accent/presentation/widgets/accent_self_evaluation_panel.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/features/elite_mastery/accent_shadowing/presentation/pages/accent_shadowing_screen.dart';
import 'package:vowl/features/elite_mastery/accent_shadowing/presentation/widgets/accent_shadowing_options_panel.dart';
import 'package:vowl/features/elite_mastery/accent_shadowing/presentation/widgets/accent_shadowing_target_panel.dart';
import 'package:vowl/features/elite_mastery/domain/entities/elite_mastery_quest.dart';
import 'package:vowl/features/elite_mastery/presentation/bloc/elite_mastery_bloc.dart';
import 'package:vowl/features/elite_mastery/presentation/layout/elite_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_feedback_card.dart';
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

  EliteMasteryQuest createSampleQuest({
    String id = 'quest_as_1',
    String instruction = 'Listen closely and shadow the phrase with native rhythm.',
    int difficulty = 1,
    String text = 'Water flows gently through the river valley.',
    String? textToSpeak,
    List<String>? options = const ['water', 'wa·ter', 'vah-ter'],
    int? correctAnswerIndex = 0,
    String hint = 'Notice the flap T sound in American English.',
    String explanation =
        'The letter t between vowels often becomes an alveolar flap.',
    String targetAccent = '/ˈwɔː.tər/ -> [ˈwɑːɾɚ]',
    String shadowingFocus = 'Alveolar flap /t/ intervocalic reduction',
    String usageContext = 'Casual conversation, standard American English',
    String spellingRule = 'Single t between vowels after stressed vowel',
    String sequenceLogic = 'Listen -> Match Stress -> Speak with Flap',
    double speedMultiplier = 0.4,
  }) {
    return EliteMasteryQuest(
      id: id,
      type: QuestType.eliteMastery,
      subtype: GameSubtype.accentShadowing,
      instruction: instruction,
      difficulty: difficulty,
      text: text,
      textToSpeak: textToSpeak,
      options: options,
      correctAnswerIndex: correctAnswerIndex,
      hint: hint,
      explanation: explanation,
      targetAccent: targetAccent,
      shadowingFocus: shadowingFocus,
      usageContext: usageContext,
      spellingRule: spellingRule,
      sequenceLogic: sequenceLogic,
      speedMultiplier: speedMultiplier,
    );
  }

  final sampleQuestModeA = createSampleQuest();

  final sampleQuestModeB = createSampleQuest(
    id: 'quest_as_mode_b',
    instruction: 'Self-evaluate your shadow pronunciation.',
    options: null,
    correctAnswerIndex: null,
  );

  final sampleFallbackTextQuest = const EliteMasteryQuest(
    id: 'quest_as_fallback',
    instruction: 'Repeat the sentence.',
    difficulty: 1,
    text: null,
    textToSpeak: null,
  );

  final testLoadedState = EliteMasteryLoaded(
    gameType: GameSubtype.accentShadowing,
    level: 2,
    quests: [sampleQuestModeA, sampleQuestModeB],
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
        gameType: GameSubtype.accentShadowing,
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
          displayName: 'ShadowMaster',
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
                child: AccentShadowingScreen(level: level),
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
  group('AccentShadowingScreen - 1. Initial Rendering & Layout Hierarchy', () {
    testWidgets('renders EliteBaseLayout, EliteGameHeader, CustomScrollView and instruction banner', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(find.byType(EliteBaseLayout), findsOneWidget);
      expect(find.byType(EliteGameHeader), findsOneWidget);
      expect(
        find.byKey(const Key('accent_shadowing_scroll_view')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('accent_shadowing_instruction_banner')),
        findsOneWidget,
      );
      expect(
        find.text(sampleQuestModeA.instruction),
        findsOneWidget,
      );
    });

    testWidgets('renders AccentShadowingTargetPanel with target words and listen button', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(find.byType(AccentShadowingTargetPanel), findsOneWidget);
      expect(
        find.byKey(const Key('accent_shadowing_listen_button')),
        findsOneWidget,
      );
      expect(find.text('Water'), findsOneWidget);
      expect(find.text('flows'), findsOneWidget);
      expect(find.text('gently'), findsOneWidget);
    });

    testWidgets('renders AccentShadowingOptionsPanel in Mode A when options exist', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(find.byType(AccentShadowingOptionsPanel), findsOneWidget);
      expect(find.text('water'), findsOneWidget);
      expect(find.text('wa·ter'), findsOneWidget);
      expect(find.text('vah-ter'), findsOneWidget);
    });

    testWidgets('renders AccentSelfEvaluationPanel in Mode B when options are null/empty', (
      tester,
    ) async {
      final stateModeB = EliteMasteryLoaded(
        gameType: GameSubtype.accentShadowing,
        level: 2,
        quests: [sampleQuestModeB],
        currentIndex: 0,
        livesRemaining: 3,
      );

      await pumpScreen(tester, state: stateModeB);

      expect(find.byType(AccentShadowingOptionsPanel), findsNothing);
      expect(find.byType(AccentSelfEvaluationPanel), findsOneWidget);
      expect(find.text('PHASE 2: SPEAKING'), findsOneWidget);
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
      expect(find.byType(AccentShadowingOptionsPanel), findsNothing);
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
              gameType: GameSubtype.accentShadowing,
              level: 2,
            ),
          ),
        ).called(greaterThanOrEqualTo(1));
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 2: Audio & Pronunciation TTS Interactions
  // ═══════════════════════════════════════════════════════════════════════════
  group('AccentShadowingScreen - 2. Audio & Pronunciation TTS Interactions', () {
    testWidgets('tapping listen button plays TTS with default 0.4 speed', (
      tester,
    ) async {
      await pumpScreen(tester);

      final listenButton = find.byKey(
        const Key('accent_shadowing_listen_button'),
      );
      expect(listenButton, findsOneWidget);

      await tester.tap(listenButton);
      await tester.pump();

      verify(
        () => mockSoundService.playTts(
          sampleQuestModeA.text!,
          speed: 0.4,
        ),
      ).called(1);
    });

    testWidgets('tapping listen button respects custom speedMultiplier', (
      tester,
    ) async {
      final fastQuest = createSampleQuest(
        id: 'quest_as_fast',
        speedMultiplier: 0.75,
        text: 'Fast native speech drill.',
      );
      final customSpeedState = EliteMasteryLoaded(
        gameType: GameSubtype.accentShadowing,
        level: 2,
        quests: [fastQuest],
        currentIndex: 0,
        livesRemaining: 3,
      );

      await pumpScreen(tester, state: customSpeedState);

      await tester.tap(find.byKey(const Key('accent_shadowing_listen_button')));
      await tester.pump();

      verify(
        () => mockSoundService.playTts('Fast native speech drill.', speed: 0.75),
      ).called(1);
    });

    testWidgets('falls back gracefully when quest text and textToSpeak are empty', (
      tester,
    ) async {
      final stateFallback = EliteMasteryLoaded(
        gameType: GameSubtype.accentShadowing,
        level: 2,
        quests: [sampleFallbackTextQuest],
        currentIndex: 0,
        livesRemaining: 3,
      );

      await pumpScreen(tester, state: stateFallback);

      expect(find.byType(AccentShadowingTargetPanel), findsOneWidget);
      final panel = tester.widget<AccentShadowingTargetPanel>(
        find.byType(AccentShadowingTargetPanel),
      );
      expect(panel.text, 'Listen and repeat the phrase.');
      expect(find.text('Listen'), findsOneWidget);
      expect(find.text('repeat'), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 3: Mode A Option Selection & Stage 2 Transition
  // ═══════════════════════════════════════════════════════════════════════════
  group('AccentShadowingScreen - 3. Mode A Option Selection & Stage 2 Transition', () {
    testWidgets('tapping wrong option marks it wrong and dispatches SubmitEliteAnswer(false)', (
      tester,
    ) async {
      await pumpScreen(tester);

      // 'vah-ter' is incorrect (correctAnswerIndex is 0 -> 'water')
      final wrongOption = find.text('vah-ter');
      expect(wrongOption, findsOneWidget);

      await tester.tap(wrongOption);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      verify(() => mockHapticService.error()).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockEliteBloc.add(const SubmitEliteAnswer(false))).called(1);

      // Stage 2 overlay is NOT shown on wrong answer
      expect(find.byType(SpeakToConfirmOverlay), findsNothing);
    });

    testWidgets('tapping correct option triggers stage 2, revealing insights and SpeakToConfirmOverlay', (
      tester,
    ) async {
      await pumpScreen(tester);

      // 'water' is correct answer (index 0)
      final correctOption = find.text('water');
      expect(correctOption, findsOneWidget);

      await tester.tap(correctOption);
      await tester.pumpAndSettle();

      verify(() => mockHapticService.selection()).called(1);
      verify(() => mockSoundService.playClick()).called(1);

      // Stage 2 insights and speaking overlay are now visible!
      expect(
        find.byKey(const Key('accent_shadowing_insights_panel')),
        findsOneWidget,
      );
      expect(find.byType(SpeakToConfirmOverlay), findsOneWidget);
      expect(find.text('SPEAK TO SHADOW'), findsOneWidget);
    });

    testWidgets('insights panel renders all detailed pedagogical annotations', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.tap(find.text('water'));
      await tester.pumpAndSettle();

      final insightsFinder = find.byKey(
        const Key('accent_shadowing_insights_panel'),
      );
      await tester.scrollUntilVisible(insightsFinder, 200);

      expect(find.text('Pedagogical Insights'), findsOneWidget);
      expect(find.text('Target Sound'), findsOneWidget);
      expect(find.text(sampleQuestModeA.targetAccent!), findsOneWidget);
      expect(find.text('Phonetic Rule'), findsOneWidget);
      expect(find.text(sampleQuestModeA.shadowingFocus!), findsOneWidget);
      expect(find.text('Usage Context'), findsOneWidget);
      expect(find.text(sampleQuestModeA.usageContext!), findsOneWidget);
      expect(find.text('Spelling Pattern'), findsOneWidget);
      expect(find.text(sampleQuestModeA.spellingRule!), findsOneWidget);
      expect(find.text('Sequence Logic'), findsOneWidget);
      expect(find.text(sampleQuestModeA.sequenceLogic!), findsOneWidget);
      expect(find.text('Explanation'), findsOneWidget);
      expect(find.text(sampleQuestModeA.explanation!), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 4: Confirmation, Skip & Self-Evaluation (Stage 2 & Mode B)
  // ═══════════════════════════════════════════════════════════════════════════
  group('AccentShadowingScreen - 4. Confirmation, Skip & Self-Evaluation', () {
    testWidgets('Stage 2: confirming via GameSkipBypassButton completes verbal evaluation', (
      tester,
    ) async {
      await pumpScreen(tester);

      // 1. Pass Stage 1
      await tester.tap(find.text('water'));
      await tester.pumpAndSettle();

      // 2. Locate Stage 2 SpeakToConfirmOverlay & GameSkipBypassButton
      final bypassButton = find.byType(GameSkipBypassButton);
      await tester.scrollUntilVisible(bypassButton, 200);
      expect(bypassButton, findsOneWidget);

      // Tap SKIP (premium user bypasses directly to confirmed)
      await tester.tap(find.text('SKIP'));
      await tester.pumpAndSettle();

      verify(() => mockHapticService.success()).called(1);
      verify(() => mockSoundService.playCorrect()).called(1);
      verify(() => mockEliteBloc.add(const EliteSpeakConfirmed(5))).called(1);
      verify(() => mockEliteBloc.add(const SubmitEliteAnswer(true))).called(1);
    });

    testWidgets('Stage 2: record speech and tap Nailed It submits correct verbal evaluation', (
      tester,
    ) async {
      await pumpScreen(tester);

      // 1. Pass Stage 1
      await tester.tap(find.text('water'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      await tester.drag(
        find.byKey(const Key('accent_shadowing_scroll_view')),
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();

      // 2. Switch to manual evaluation and start recording
      final manualEvalBtn = find.text('Evaluate myself manually');
      expect(manualEvalBtn, findsOneWidget);
      await tester.tap(manualEvalBtn);
      await tester.pumpAndSettle();

      final micButton = find.byKey(const ValueKey('speaking_mic_btn'));
      expect(micButton, findsOneWidget);
      await tester.tap(micButton);
      await tester.pump();
      verify(() => mockAudioRecorder.startRecording()).called(1);

      // 3. Stop recording
      when(() => mockAudioRecorder.isRecording).thenReturn(true);
      await tester.tap(micButton);
      await tester.pumpAndSettle();
      verify(() => mockAudioRecorder.stopRecording()).called(1);

      // 4. Tap "Nailed It"
      final nailedItBtn = find.text('Nailed It');
      expect(nailedItBtn, findsOneWidget);
      await tester.tap(nailedItBtn);
      await tester.pumpAndSettle();

      verify(() => mockHapticService.success()).called(1);
      verify(() => mockSoundService.playCorrect()).called(1);
      verify(() => mockEliteBloc.add(const EliteSpeakConfirmed(5))).called(1);
      verify(() => mockEliteBloc.add(const SubmitEliteAnswer(true))).called(1);
    });

    testWidgets('Stage 2: record speech and tap Needs Work submits wrong verbal evaluation', (
      tester,
    ) async {
      await pumpScreen(tester);

      // 1. Pass Stage 1
      await tester.tap(find.text('water'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      await tester.drag(
        find.byKey(const Key('accent_shadowing_scroll_view')),
        const Offset(0, -400),
      );
      await tester.pumpAndSettle();

      // 2. Switch to manual evaluation and start recording
      final manualEvalBtn = find.text('Evaluate myself manually');
      expect(manualEvalBtn, findsOneWidget);
      await tester.tap(manualEvalBtn);
      await tester.pumpAndSettle();

      final micButton = find.byKey(const ValueKey('speaking_mic_btn'));
      expect(micButton, findsOneWidget);
      await tester.tap(micButton);
      await tester.pump();

      when(() => mockAudioRecorder.isRecording).thenReturn(true);
      await tester.tap(micButton);
      await tester.pumpAndSettle();

      // 3. Tap "Needs Work"
      final needsWorkBtn = find.text('Needs Work');
      expect(needsWorkBtn, findsOneWidget);
      await tester.tap(needsWorkBtn);
      await tester.pumpAndSettle();

      verify(() => mockHapticService.error()).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockEliteBloc.add(const SubmitEliteAnswer(false))).called(1);
    });

    testWidgets('Mode B: AccentSelfEvaluationPanel Nailed It flow dispatches correct answer', (
      tester,
    ) async {
      final stateModeB = EliteMasteryLoaded(
        gameType: GameSubtype.accentShadowing,
        level: 2,
        quests: [sampleQuestModeB],
        currentIndex: 0,
        livesRemaining: 3,
      );
      await pumpScreen(tester, state: stateModeB);

      // Scroll down to AccentSelfEvaluationPanel
      await tester.drag(
        find.byKey(const Key('accent_shadowing_scroll_view')),
        const Offset(0, -350),
      );
      await tester.pumpAndSettle();

      // Switch to manual evaluation and record
      final manualEvalBtn = find.text('Evaluate myself manually');
      expect(manualEvalBtn, findsOneWidget);
      await tester.tap(manualEvalBtn);
      await tester.pumpAndSettle();

      final micButton = find.byKey(const ValueKey('speaking_mic_btn'));
      expect(micButton, findsOneWidget);
      await tester.tap(micButton);
      await tester.pump();

      when(() => mockAudioRecorder.isRecording).thenReturn(true);
      await tester.tap(micButton);
      await tester.pumpAndSettle();

      // Tap "Nailed It"
      final nailedItBtn = find.text('Nailed It');
      expect(nailedItBtn, findsOneWidget);
      await tester.tap(nailedItBtn);
      await tester.pumpAndSettle();

      verify(() => mockHapticService.success()).called(1);
      verify(() => mockSoundService.playCorrect()).called(1);
      verify(() => mockEliteBloc.add(const EliteSpeakConfirmed(5))).called(1);
      verify(() => mockEliteBloc.add(const SubmitEliteAnswer(true))).called(1);
    });

    testWidgets('Mode B: AccentSelfEvaluationPanel Needs Work flow dispatches wrong answer', (
      tester,
    ) async {
      final stateModeB = EliteMasteryLoaded(
        gameType: GameSubtype.accentShadowing,
        level: 2,
        quests: [sampleQuestModeB],
        currentIndex: 0,
        livesRemaining: 3,
      );
      await pumpScreen(tester, state: stateModeB);

      // Scroll down to AccentSelfEvaluationPanel
      await tester.drag(
        find.byKey(const Key('accent_shadowing_scroll_view')),
        const Offset(0, -350),
      );
      await tester.pumpAndSettle();

      // Switch to manual evaluation and record
      final manualEvalBtn = find.text('Evaluate myself manually');
      expect(manualEvalBtn, findsOneWidget);
      await tester.tap(manualEvalBtn);
      await tester.pumpAndSettle();

      final micButton = find.byKey(const ValueKey('speaking_mic_btn'));
      expect(micButton, findsOneWidget);
      await tester.tap(micButton);
      await tester.pump();

      when(() => mockAudioRecorder.isRecording).thenReturn(true);
      await tester.tap(micButton);
      await tester.pumpAndSettle();

      // Tap "Needs Work"
      final needsWorkBtn = find.text('Needs Work');
      expect(needsWorkBtn, findsOneWidget);
      await tester.tap(needsWorkBtn);
      await tester.pumpAndSettle();

      verify(() => mockHapticService.error()).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockEliteBloc.add(const SubmitEliteAnswer(false))).called(1);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 5: Game Lifecycle, Hints & State Transitions
  // ═══════════════════════════════════════════════════════════════════════════
  group('AccentShadowingScreen - 5. Game Lifecycle, Hints & State Transitions', () {
    testWidgets('tapping hint button dispatches MarkEliteHintUsed and ShowEliteHint', (
      tester,
    ) async {
      await pumpScreen(tester);

      final hintButton = find.byType(QuestHintButton);
      expect(hintButton, findsOneWidget);

      await tester.tap(hintButton);
      await tester.pump();

      verify(() => mockEliteBloc.add(const MarkEliteHintUsed())).called(1);
      verify(() => mockEliteBloc.add(const ShowEliteHint())).called(1);
    });

    testWidgets('displays EliteHintCard when isHintVisible is true', (
      tester,
    ) async {
      final hintVisibleState = EliteMasteryLoaded(
        gameType: GameSubtype.accentShadowing,
        level: 2,
        quests: [sampleQuestModeA],
        currentIndex: 0,
        livesRemaining: 3,
        isHintVisible: true,
        isHintUsed: true,
      );

      await pumpScreen(tester, state: hintVisibleState);

      expect(find.byType(EliteHintCard), findsOneWidget);
      expect(
        find.text(sampleQuestModeA.hint!),
        findsOneWidget,
      );
    });

    testWidgets('GameFeedbackCard appears on answered; tapping continue dispatches NextEliteQuestion', (
      tester,
    ) async {
      final answeredState = EliteMasteryLoaded(
        gameType: GameSubtype.accentShadowing,
        level: 2,
        quests: [sampleQuestModeA, sampleQuestModeB],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.correct,
      );

      await pumpScreen(tester, state: answeredState);

      expect(find.byType(GameFeedbackCard), findsOneWidget);

      final continueButton = find.text('CONTINUE');
      expect(continueButton, findsOneWidget);

      await tester.tap(continueButton);
      await tester.pumpAndSettle();

      verify(() => mockEliteBloc.add(const NextEliteQuestion())).called(1);
    });

    testWidgets('EliteMasteryGameComplete triggers game completion dialog', (
      tester,
    ) async {
      await pumpScreen(tester);

      // Emit game complete event
      eliteStreamController.add(
        const EliteMasteryGameComplete(
          xpEarned: 5,
          coinsEarned: 10,
          questCount: 3,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('LEVEL COMPLETE!'), findsOneWidget);

      // Clean up dialog
      Navigator.of(tester.element(find.text('LEVEL COMPLETE!'))).pop();
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('EliteMasteryGameOver renders dimmed view with zero lives', (
      tester,
    ) async {
      final gameOverState = EliteMasteryGameOver(
        gameType: GameSubtype.accentShadowing,
        level: 2,
        quests: [sampleQuestModeA],
        currentIndex: 0,
      );

      await pumpScreen(tester, state: gameOverState);

      expect(find.byType(AbsorbPointer), findsWidgets);
    });

    testWidgets('gracefully handles empty quests list without throwing', (
      tester,
    ) async {
      final emptyQuestsState = EliteMasteryLoaded(
        gameType: GameSubtype.accentShadowing,
        level: 2,
        quests: const [],
        currentIndex: 0,
        livesRemaining: 3,
      );

      await pumpScreen(tester, state: emptyQuestsState);

      expect(tester.takeException(), isNull);
      expect(find.byType(AccentShadowingScreen), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 6: Responsive Layout, Text Scaling & Accessibility
  // ═══════════════════════════════════════════════════════════════════════════
  group('AccentShadowingScreen - 6. Responsive Layout, Text Scaling & Accessibility', () {
    testWidgets('renders cleanly on compact screen (320x568) without overflow', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        surfaceSize: const Size(320, 568),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(AccentShadowingTargetPanel), findsOneWidget);
      expect(find.byType(AccentShadowingOptionsPanel), findsOneWidget);
    });

    testWidgets('renders cleanly on tablet viewport (800x1280)', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        surfaceSize: const Size(800, 1280),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(AccentShadowingTargetPanel), findsOneWidget);
      expect(find.byType(AccentShadowingOptionsPanel), findsOneWidget);
    });

    testWidgets('renders properly with enlarged textScaler (1.3x)', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        textScaleFactor: 1.3,
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(AccentShadowingTargetPanel), findsOneWidget);
      expect(find.byType(AccentShadowingOptionsPanel), findsOneWidget);
    });

    testWidgets('renders without error in Light Theme mode', (
      tester,
    ) async {
      when(
        () => mockThemeCubit.state,
      ).thenReturn(const ThemeState(themeMode: ThemeMode.light, isMidnight: false));

      await pumpScreen(
        tester,
        themeMode: ThemeMode.light,
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(AccentShadowingTargetPanel), findsOneWidget);
      expect(find.byType(AccentShadowingOptionsPanel), findsOneWidget);
    });

    testWidgets('accessible semantics: listen button and target panel have proper labels', (
      tester,
    ) async {
      await pumpScreen(tester);

      final listenButton = find.byKey(
        const Key('accent_shadowing_listen_button'),
      );
      final listenSemantics = tester.getSemantics(listenButton);
      expect(listenSemantics.flagsCollection.isButton, isTrue);
      expect(
        listenSemantics.label,
        contains('Play pronunciation example'),
      );
    });
  });
}

