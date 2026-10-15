import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' show RewardItem;
import 'package:mocktail/mocktail.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/game_mechanics/shared/game_skip_bypass_button.dart';
import 'package:vowl/core/presentation/game_mechanics/shared/speed_challenge_timer.dart';
import 'package:vowl/core/presentation/widgets/game_briefing_layer.dart';
import 'package:vowl/core/presentation/widgets/quest_hint_button.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/theme/app_theme.dart';
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
import 'package:vowl/features/accent/domain/entities/accent_quest.dart';
import 'package:vowl/features/accent/presentation/bloc/accent_bloc.dart';
import 'package:vowl/features/accent/speed_variance/presentation/pages/speed_variance_screen.dart';
import 'package:vowl/features/accent/speed_variance/presentation/widgets/speed_variance_instruction.dart';
import 'package:vowl/features/accent/speed_variance/presentation/widgets/speed_variance_prompt_card.dart';
import 'package:vowl/features/accent/speed_variance/presentation/widgets/speed_variance_speed_toggle.dart';
import 'package:vowl/features/accent/speed_variance/presentation/widgets/speed_variance_tempo_dial.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';

class MockAccentBloc extends MockBloc<AccentEvent, AccentState>
    implements AccentBloc {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockEconomyBloc extends MockBloc<EconomyEvent, EconomyState>
    implements EconomyBloc {}

class MockHapticService extends Mock implements HapticService {}

class MockSoundService extends Mock implements SoundService {}

class MockTtsService extends Mock implements TtsService {}

class MockSpeechService extends Mock implements SpeechService {}

class MockAudioRecordingService extends Mock implements AudioRecordingService {}

class MockLocaleService extends Mock implements LocaleService {}

class MockAppLogger extends Mock implements AppLogger {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockAdService extends Mock implements AdService {}

class FakeAccentEvent extends Fake implements AccentEvent {}

class FakeAccentState extends Fake implements AccentState {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAccentBloc mockAccentBloc;
  late MockAuthBloc mockAuthBloc;
  late MockEconomyBloc mockEconomyBloc;
  late MockHapticService mockHapticService;
  late MockSoundService mockSoundService;
  late MockTtsService mockTtsService;
  late MockSpeechService mockSpeechService;
  late MockAudioRecordingService mockAudioRecorder;
  late MockLocaleService mockLocaleService;
  late MockAppLogger mockLogger;
  late MockAnalyticsService mockAnalyticsService;
  late MockAdService mockAdService;

  setUpAll(() {
    registerFallbackValue(FakeAccentEvent());
    registerFallbackValue(FakeAccentState());
    registerFallbackValue(const SubmitAnswer(true));
    registerFallbackValue(const SubmitAnswer(false));
    registerFallbackValue(const NextQuestion());
    registerFallbackValue(const AccentHintUsed());
    registerFallbackValue(const AccentSpeakConfirmed(5));
    registerFallbackValue(const Duration(milliseconds: 50));
  });

  const testQuest1 = AccentQuest(
    id: 'ACC_SPEEDVARIANCE_L71_Q1',
    instruction: 'Adjust the speed',
    difficulty: 1,
    subtype: GameSubtype.speedVariance,
    word: "Sorry, I talk a lot when I'm nervous, I'll stop, sorry, where was I?",
    textToSpeak: "Sorry, I talk a lot when I'm nervous, I'll stop, sorry, where was I?",
    options: [
      'Decelerating (careful, slow speech)',
      'Accelerating (nervous chatter runs fast)',
    ],
    correctAnswer: 'Accelerating (nervous chatter runs fast)',
    correctAnswerIndex: 1,
    targetSpeed: 1.37,
    naturalSpeed: 1.0,
    clearSpeed: 0.75,
    hint: "What does the sentence tell us about the speaker's state?",
    explanation: 'The speaker tells us that nerves make them talk quickly.',
  );

  const testQuest2 = AccentQuest(
    id: 'ACC_SPEEDVARIANCE_L71_Q2',
    instruction: 'Adjust the speed',
    difficulty: 1,
    subtype: GameSubtype.speedVariance,
    word: "I've asked three times now, and I'd like an answer today.",
    textToSpeak: "I've asked three times now, and I'd like an answer today.",
    options: [
      'Decelerating (controlled frustration is delivered slowly and firmly)',
      'Accelerating (frustration makes the speaker hurry)',
    ],
    correctAnswer: 'Decelerating (controlled frustration is delivered slowly and firmly)',
    correctAnswerIndex: 0,
    targetSpeed: 0.73,
    naturalSpeed: 1.0,
    clearSpeed: 0.75,
    hint: 'Which sounds more in control: a rushed demand, or a slow one?',
    explanation: 'Slowing down gives the words authority.',
  );

  const testLoadedState = AccentLoaded(
    quests: [testQuest1, testQuest2],
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
    gameType: GameSubtype.speedVariance,
    level: 2,
    hintUsed: false,
    wrongCount: 0,
    isFinalFailure: false,
  );

  setUp(() async {
    mockAccentBloc = MockAccentBloc();
    mockAuthBloc = MockAuthBloc();
    mockEconomyBloc = MockEconomyBloc();
    mockHapticService = MockHapticService();
    mockSoundService = MockSoundService();
    mockTtsService = MockTtsService();
    mockSpeechService = MockSpeechService();
    mockAudioRecorder = MockAudioRecordingService();
    mockLocaleService = MockLocaleService();
    mockLogger = MockAppLogger();
    mockAnalyticsService = MockAnalyticsService();
    mockAdService = MockAdService();

    VowlMotion.lowAnimationModeOverride.value = true;

    SharedPreferences.setMockInitialValues({
      'has_seen_briefing_speedVariance': true,
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

    when(() => mockAccentBloc.state).thenReturn(testLoadedState);
    when(() => mockAccentBloc.stream)
        .thenAnswer((_) => const Stream<AccentState>.empty());

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
    when(
      () => mockSoundService.playTts(
        any(),
        speed: any(named: 'speed'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockSoundService.playFile(any())).thenAnswer((_) async {});

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

    when(() => mockSpeechService.initializeStt()).thenAnswer((_) async => true);
    when(() => mockSpeechService.stop()).thenAnswer((_) async {});
    when(() => mockSpeechService.cancel()).thenAnswer((_) async {});
    when(() => mockSpeechService.isListening).thenReturn(false);
    when(() => mockSpeechService.isPlaying).thenReturn(false);

    when(() => mockAudioRecorder.hasPermission()).thenAnswer((_) async => true);
    when(() => mockAudioRecorder.startRecording()).thenAnswer((_) async => true);
    when(
      () => mockAudioRecorder.stopRecording(),
    ).thenAnswer((_) async => '/tmp/audio_speed_variance.m4a');
    when(() => mockAudioRecorder.isRecording).thenReturn(false);
    when(
      () => mockAudioRecorder.onAmplitudeChanged(any()),
    ).thenAnswer((_) => Stream.value(Amplitude(current: -10, max: -5)));
    when(() => mockAudioRecorder.dispose()).thenAnswer((_) async {});

    when(() => mockAnalyticsService.logSelfEvaluation(any())).thenAnswer((_) async {});
    when(() => mockAnalyticsService.logGameSkipped(any())).thenAnswer((_) async {});

    when(
      () => mockAdService.showRewardedAd(
        context: any(named: 'context'),
        isPremium: any(named: 'isPremium'),
        onUserEarnedReward: any(named: 'onUserEarnedReward'),
        onDismissed: any(named: 'onDismissed'),
      ),
    ).thenAnswer((inv) {
      final onReward = inv.namedArguments[#onUserEarnedReward] as dynamic;
      onReward?.call(RewardItem(1, 'coin'));
    });

    await di.sl.reset();

    di.sl.registerSingleton<HapticService>(mockHapticService);
    di.sl.registerSingleton<SoundService>(mockSoundService);
    di.sl.registerSingleton<TtsService>(mockTtsService);
    di.sl.registerSingleton<SpeechService>(mockSpeechService);
    di.sl.registerSingleton<AudioRecordingService>(mockAudioRecorder);
    di.sl.registerSingleton<LocaleService>(mockLocaleService);
    di.sl.registerSingleton<AppLogger>(mockLogger);
    di.sl.registerSingleton<AnalyticsService>(mockAnalyticsService);
    di.sl.registerSingleton<AdService>(mockAdService);
  });

  tearDown(() async {
    VowlMotion.lowAnimationModeOverride.value = false;
    await di.sl.reset();
  });

  Future<void> pumpSpeedVariance(
    WidgetTester tester, {
    AccentState? state,
    int level = 2,
    ThemeMode themeMode = ThemeMode.light,
    double width = 390,
    double height = 1000,
  }) async {
    if (state != null) {
      when(() => mockAccentBloc.state).thenReturn(state);
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
          BlocProvider<AccentBloc>.value(value: mockAccentBloc),
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<EconomyBloc>.value(value: mockEconomyBloc),
        ],
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, _) => MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            home: SpeedVarianceScreen(level: level),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('SpeedVarianceScreen - Component Layout & Initial State', () {
    testWidgets('renders all initial UI components cleanly', (tester) async {
      await pumpSpeedVariance(tester);

      expect(find.byType(SpeedVarianceInstruction), findsOneWidget);
      expect(find.text('ADJUST THE SPEED'), findsOneWidget);

      expect(find.byType(SpeedVariancePromptCard), findsOneWidget);
      expect(find.text("Sorry, I talk a lot when I'm nervous, I'll stop, sorry, where was I?"), findsOneWidget);

      expect(find.byType(SpeedChallengeTimer), findsOneWidget);
      expect(find.byKey(const ValueKey('speed_variance_pulse_speaker')), findsOneWidget);
      expect(find.text("HEAR\nSPEED"), findsOneWidget);

      expect(find.byKey(const ValueKey('speed_variance_chrome_dial')), findsOneWidget);
      expect(find.text("ROTATE DIAL OR TAP PREFERENCE"), findsOneWidget);

      expect(find.byKey(const ValueKey('speed_variance_option_0')), findsOneWidget);
      expect(find.byKey(const ValueKey('speed_variance_option_1')), findsOneWidget);
      expect(find.text('Decelerating'), findsOneWidget);
      expect(find.text('Accelerating'), findsOneWidget);

      // Phase 2 components are not mounted initially
      expect(find.byKey(const ValueKey('speak_to_confirm_overlay')), findsNothing);
      expect(find.byType(SpeedVarianceSpeedToggle), findsNothing);
    });

    testWidgets('tapping pulse speaker triggers TTS audio at target speed and selection haptics', (tester) async {
      await pumpSpeedVariance(tester);

      final speaker = find.byKey(const ValueKey('speed_variance_pulse_speaker'));
      await tester.tap(speaker);
      await tester.pump();

      verify(() => mockHapticService.selection()).called(1);
      verify(() => mockSoundService.playTts(
        "Sorry, I talk a lot when I'm nervous, I'll stop, sorry, where was I?",
        speed: 1.37,
      )).called(1);
    });

    testWidgets('renders GameShimmerLoading when in AccentInitial state', (tester) async {
      await pumpSpeedVariance(
        tester,
        state: const AccentInitial(),
      );

      expect(find.byType(GameShimmerLoading), findsOneWidget);
      expect(find.byType(SpeedVarianceTempoDial), findsNothing);
    });

    testWidgets('tapping hint button dispatches AccentHintUsed without duplicates', (tester) async {
      await pumpSpeedVariance(tester);

      final hintBtn = find.byType(QuestHintButton);
      expect(hintBtn, findsOneWidget);

      await tester.tap(hintBtn);
      await tester.pump();

      verify(() => mockAccentBloc.add(const AccentHintUsed())).called(1);
    });
  });

  group('SpeedVarianceScreen - Phase 1 Dial & Tap Flow', () {
    testWidgets('tapping wrong option submits wrong answer and stops timer', (tester) async {
      await pumpSpeedVariance(tester);

      // testQuest1 correctAnswerIndex is 1. Option 0 is wrong.
      final wrongOption = find.byKey(const ValueKey('speed_variance_option_0'));
      await tester.tap(wrongOption);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockHapticService.error()).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockAccentBloc.add(const SubmitAnswer(false))).called(1);
    });

    testWidgets('dragging chrome dial left past threshold selects option 0 (wrong)', (tester) async {
      await pumpSpeedVariance(tester);

      final dial = find.byKey(const ValueKey('speed_variance_chrome_dial'));
      expect(dial, findsOneWidget);

      final gesture = await tester.startGesture(tester.getCenter(dial));
      await gesture.moveBy(const Offset(-80, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(-80, 0));
      await tester.pump();
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockHapticService.error()).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockAccentBloc.add(const SubmitAnswer(false))).called(1);
    });

    testWidgets('dragging chrome dial right past threshold selects option 1 (correct)', (tester) async {
      await pumpSpeedVariance(tester);

      final dial = find.byKey(const ValueKey('speed_variance_chrome_dial'));
      expect(dial, findsOneWidget);

      final gesture = await tester.startGesture(tester.getCenter(dial));
      await gesture.moveBy(const Offset(80, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(80, 0));
      await tester.pump();
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockHapticService.success()).called(1);
      verify(() => mockSoundService.playCorrect()).called(1);

      // Should advance to Stage 2 without early SubmitAnswer
      verifyNever(() => mockAccentBloc.add(const SubmitAnswer(true)));
      expect(find.byType(SpeedVarianceSpeedToggle), findsOneWidget);
    });

    testWidgets('timer expiration via onTimeUp triggers wrong answer submission', (tester) async {
      await pumpSpeedVariance(tester);

      final timerState = tester.state<SpeedChallengeTimerState>(
        find.byType(SpeedChallengeTimer),
      );
      timerState.widget.onTimeUp();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockAccentBloc.add(const SubmitAnswer(false))).called(1);
    });

    testWidgets('tapping correct option advances to Stage 2 without submitting answer prematurely', (tester) async {
      await pumpSpeedVariance(tester);

      final correctOption = find.byKey(const ValueKey('speed_variance_option_1'));
      await tester.tap(correctOption);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockHapticService.success()).called(1);
      verify(() => mockSoundService.playCorrect()).called(1);
      verifyNever(() => mockAccentBloc.add(const SubmitAnswer(true)));

      // Speed toggle and instruction update visible
      expect(find.byType(SpeedVarianceSpeedToggle), findsOneWidget);
      expect(find.text("GREAT JOB! NOW RECORD YOURSELF SAYING THE WORD."), findsOneWidget);
    });

    testWidgets('interaction lockout prevents duplicate taps once answered', (tester) async {
      await pumpSpeedVariance(tester);

      // Submit wrong answer
      final wrongOption = find.byKey(const ValueKey('speed_variance_option_0'));
      await tester.tap(wrongOption);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockAccentBloc.add(const SubmitAnswer(false))).called(1);

      // Secondary tap on another option must be locked
      final correctOption = find.byKey(const ValueKey('speed_variance_option_1'));
      await tester.ensureVisible(correctOption);
      await tester.pumpAndSettle();
      await tester.tap(correctOption, warnIfMissed: false);
      await tester.pump();

      verifyNever(() => mockAccentBloc.add(const SubmitAnswer(true)));
      expect(find.byType(SpeedVarianceSpeedToggle), findsNothing);
    });
  });

  group('SpeedVarianceScreen - Phase 2 Speaking & Speed Toggle Flow', () {
    testWidgets('in Stage 2, tapping speed toggle buttons switches speed and plays audio', (tester) async {
      await pumpSpeedVariance(tester);

      // Advance to Stage 2
      await tester.tap(find.byKey(const ValueKey('speed_variance_option_1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Tap CLEAR speed toggle
      final clearToggle = find.byKey(const ValueKey('speed_toggle_clear'));
      expect(clearToggle, findsOneWidget);
      await tester.ensureVisible(clearToggle);
      await tester.pumpAndSettle();
      await tester.tap(clearToggle);
      await tester.pump();

      verify(() => mockSoundService.playTts(
        "Sorry, I talk a lot when I'm nervous, I'll stop, sorry, where was I?",
        speed: 0.75, // clearSpeed
      )).called(1);

      // Tap NATURAL speed toggle
      final naturalToggle = find.byKey(const ValueKey('speed_toggle_natural'));
      expect(naturalToggle, findsOneWidget);
      await tester.ensureVisible(naturalToggle);
      await tester.pumpAndSettle();
      await tester.tap(naturalToggle);
      await tester.pump();

      verify(() => mockSoundService.playTts(
        "Sorry, I talk a lot when I'm nervous, I'll stop, sorry, where was I?",
        speed: 1.0, // naturalSpeed
      )).called(1);
    });

    testWidgets('in Stage 2, tapping pulse speaker plays TTS at currently toggled speed', (tester) async {
      await pumpSpeedVariance(tester);

      // Advance to Stage 2
      await tester.tap(find.byKey(const ValueKey('speed_variance_option_1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Toggle to CLEAR
      final clearToggle = find.byKey(const ValueKey('speed_toggle_clear'));
      await tester.ensureVisible(clearToggle);
      await tester.pumpAndSettle();
      await tester.tap(clearToggle);
      await tester.pump();

      // Tap pulse speaker
      final speaker = find.byKey(const ValueKey('speed_variance_pulse_speaker'));
      await tester.ensureVisible(speaker);
      await tester.pumpAndSettle();
      await tester.tap(speaker);
      await tester.pump();

      verify(() => mockSoundService.playTts(
        "Sorry, I talk a lot when I'm nervous, I'll stop, sorry, where was I?",
        speed: 0.75, // clearSpeed
      )).called(2); // 1 from toggle, 1 from speaker
    });

    testWidgets('recording audio and confirming "Nailed It" dispatches AccentSpeakConfirmed(5) and SubmitAnswer(true)', (tester) async {
      await pumpSpeedVariance(tester);

      // Advance to Stage 2
      await tester.tap(find.byKey(const ValueKey('speed_variance_option_1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      await tester.dragFrom(const Offset(20, 600), const Offset(0, -700));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final overlay = find.byKey(const ValueKey('speak_to_confirm_overlay'));
      expect(overlay, findsOneWidget);

      // Switch to manual evaluation mode
      final switchModeBtn = find.text('Evaluate myself manually');
      await tester.ensureVisible(switchModeBtn);
      await tester.pumpAndSettle();
      expect(switchModeBtn, findsOneWidget);
      await tester.tap(switchModeBtn);
      await tester.pumpAndSettle();

      final micBtn = find.byKey(const ValueKey('speaking_mic_btn'));
      await tester.ensureVisible(micBtn);
      await tester.pumpAndSettle();
      expect(micBtn, findsOneWidget);

      // Start recording
      await tester.tap(micBtn);
      await tester.pump();
      await tester.runAsync(
        () async => await Future.delayed(const Duration(milliseconds: 600)),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Stop recording
      await tester.tap(micBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      final nailedItBtn = find.text('Nailed It');
      await tester.ensureVisible(nailedItBtn);
      await tester.pumpAndSettle();
      expect(nailedItBtn, findsOneWidget);
      await tester.tap(nailedItBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockHapticService.success()).called(2); // 1 for option, 1 for speak
      verify(() => mockSoundService.playCorrect()).called(2);
      verify(() => mockAccentBloc.add(const AccentSpeakConfirmed(5))).called(1);
      verify(() => mockAccentBloc.add(const SubmitAnswer(true))).called(1);
    });

    testWidgets('evaluating "Needs Work" triggers error feedback and SubmitAnswer(false)', (tester) async {
      await pumpSpeedVariance(tester);

      // Advance to Stage 2
      await tester.tap(find.byKey(const ValueKey('speed_variance_option_1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      await tester.dragFrom(const Offset(20, 600), const Offset(0, -700));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final overlay = find.byKey(const ValueKey('speak_to_confirm_overlay'));
      expect(overlay, findsOneWidget);

      final switchModeBtn = find.text('Evaluate myself manually');
      await tester.ensureVisible(switchModeBtn);
      await tester.pumpAndSettle();
      await tester.tap(switchModeBtn);
      await tester.pumpAndSettle();

      final micBtn = find.byKey(const ValueKey('speaking_mic_btn'));
      await tester.ensureVisible(micBtn);
      await tester.pumpAndSettle();

      await tester.tap(micBtn);
      await tester.pump();
      await tester.runAsync(
        () async => await Future.delayed(const Duration(milliseconds: 600)),
      );
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(micBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      final needsWorkBtn = find.text('Needs Work');
      await tester.ensureVisible(needsWorkBtn);
      await tester.pumpAndSettle();
      expect(needsWorkBtn, findsOneWidget);
      await tester.tap(needsWorkBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockHapticService.error()).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockAccentBloc.add(const SubmitAnswer(false))).called(1);
    });

    testWidgets('rewarded ad bypass button triggers ad and submits answer', (tester) async {
      await pumpSpeedVariance(tester);

      // Advance to Stage 2
      await tester.tap(find.byKey(const ValueKey('speed_variance_option_1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      await tester.dragFrom(const Offset(20, 600), const Offset(0, -700));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final adBtn = find.byType(GameSkipBypassButton);
      await tester.ensureVisible(adBtn);
      await tester.pumpAndSettle();
      expect(adBtn, findsOneWidget);

      await tester.tap(adBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockAdService.showRewardedAd(
        context: any(named: 'context'),
        isPremium: any(named: 'isPremium'),
        onUserEarnedReward: any(named: 'onUserEarnedReward'),
        onDismissed: any(named: 'onDismissed'),
      )).called(1);
      verify(() => mockAccentBloc.add(const SubmitAnswer(true))).called(1);
    });

    testWidgets('tapping continue button when answered dispatches NextQuestion', (tester) async {
      await pumpSpeedVariance(tester);

      // Submit wrong answer
      final wrongOption = find.byKey(const ValueKey('speed_variance_option_0'));
      await tester.tap(wrongOption);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final continueBtn = find.text('TRY AGAIN');
      await tester.ensureVisible(continueBtn);
      await tester.pumpAndSettle();
      expect(continueBtn, findsOneWidget);
      await tester.tap(continueBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockAccentBloc.add(const NextQuestion())).called(1);
    });
  });

  group('SpeedVarianceScreen - Briefing, Small Screens & Accessibility', () {
    testWidgets('renders and dismisses GameBriefingLayer on Level 1', (tester) async {
      SharedPreferences.setMockInitialValues({
        'has_seen_briefing_speedVariance': false,
      });

      await pumpSpeedVariance(tester, level: 1, height: 1200);

      expect(find.byType(GameBriefingLayer), findsOneWidget);

      final startBtn = find.descendant(
        of: find.byType(GameBriefingLayer),
        matching: find.byType(ScaleButton),
      );
      expect(startBtn, findsOneWidget);

      await tester.tap(startBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(GameBriefingLayer), findsNothing);
    });

    testWidgets('renders cleanly on small device (320x568) in dark theme without overflow', (tester) async {
      await pumpSpeedVariance(
        tester,
        themeMode: ThemeMode.dark,
        width: 320,
        height: 568,
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(SpeedVariancePromptCard), findsOneWidget);
      expect(find.byKey(const ValueKey('speed_variance_chrome_dial')), findsOneWidget);
    });

    testWidgets('respects reduced motion when lowAnimationModeOverride is enabled', (tester) async {
      VowlMotion.lowAnimationModeOverride.value = true;

      await pumpSpeedVariance(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(SpeedVariancePromptCard), findsOneWidget);
    });
  });
}

