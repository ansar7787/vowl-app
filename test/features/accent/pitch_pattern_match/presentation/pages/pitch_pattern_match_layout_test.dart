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
import 'package:vowl/core/presentation/game_mechanics/speaking/speak_to_confirm_overlay.dart';
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
import 'package:vowl/features/accent/pitch_pattern_match/presentation/pages/pitch_pattern_match_screen.dart';
import 'package:vowl/features/accent/pitch_pattern_match/presentation/widgets/pitch_pattern_match_instruction.dart';
import 'package:vowl/features/accent/pitch_pattern_match/presentation/widgets/pitch_pattern_match_melodic_canvas.dart';
import 'package:vowl/features/accent/pitch_pattern_match/presentation/widgets/pitch_pattern_match_prompt_card.dart';
import 'package:vowl/features/accent/pitch_pattern_match/presentation/widgets/pitch_pattern_match_pulse_speaker.dart';
import 'package:vowl/features/accent/pitch_pattern_match/presentation/widgets/pitch_pattern_match_vertical_fader.dart';
import 'package:vowl/features/accent/presentation/bloc/accent_bloc.dart';
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
    id: 'ACC_PPM_L1_Q1',
    instruction: 'Listen and select the pitch contour that matches the speaker.',
    difficulty: 1,
    subtype: GameSubtype.pitchPatternMatch,
    word: 'Where are you going?',
    textToSpeak: 'Where are you going?',
    emotionContext: 'Curious / Inquiring',
    options: ['Rising pitch (Question)', 'Falling pitch (Statement)'],
    correctAnswerIndex: 0,
    pitchPatterns: [0, 1, 3, 2, 4],
    hint: 'Listen to how the pitch changes on the last word.',
    explanation: 'Questions with curious emotion typically end in rising pitch.',
  );

  const testQuest2 = AccentQuest(
    id: 'ACC_PPM_L1_Q2',
    instruction: 'Listen and select the pitch contour that matches the speaker.',
    difficulty: 1,
    subtype: GameSubtype.pitchPatternMatch,
    word: 'I am leaving now.',
    textToSpeak: 'I am leaving now.',
    emotionContext: 'Decisive / Firm',
    options: ['Rising pitch (Incomplete)', 'Falling pitch (Finality)'],
    correctAnswerIndex: 1,
    pitchPatterns: [4, 3, 2, 1, 0],
    hint: 'Listen for finality at the end of the sentence.',
    explanation: 'Definitive statements typically finish with falling pitch.',
  );

  const testLoadedState = AccentLoaded(
    quests: [testQuest1, testQuest2],
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
    gameType: GameSubtype.pitchPatternMatch,
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
      'has_seen_briefing_pitchPatternMatch': true,
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
    when(() => mockSoundService.playTts(any())).thenAnswer((_) async {});
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
    ).thenAnswer((_) async => '/tmp/audio_pattern.m4a');
    when(() => mockAudioRecorder.isRecording).thenReturn(false);
    when(
      () => mockAudioRecorder.onAmplitudeChanged(any()),
    ).thenAnswer((_) => Stream.value(Amplitude(current: -10, max: -5)));
    when(() => mockAudioRecorder.dispose()).thenAnswer((_) async {});

    when(() => mockAnalyticsService.logSelfEvaluation(any())).thenAnswer((_) async {});
    when(() => mockAnalyticsService.logGameSkipped(any())).thenAnswer((_) async {});

    when(() => mockAdService.showRewardedAd(
          context: any(named: 'context'),
          isPremium: any(named: 'isPremium'),
          onUserEarnedReward: any(named: 'onUserEarnedReward'),
          onDismissed: any(named: 'onDismissed'),
        )).thenAnswer((inv) async {
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

  Future<void> pumpPitchPatternMatch(
    WidgetTester tester, {
    AccentState? state,
    int level = 2,
    ThemeMode themeMode = ThemeMode.light,
    double width = 390,
    double height = 844,
  }) async {
    if (state != null) {
      when(() => mockAccentBloc.state).thenReturn(state);
    }

    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

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
          builder: (context, child) => MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            home: PitchPatternMatchScreen(level: level),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('PitchPatternMatchScreen - Component Layout & Initial State', () {
    testWidgets('renders all initial UI components cleanly', (tester) async {
      await pumpPitchPatternMatch(tester);

      expect(find.byType(PitchPatternMatchInstruction), findsOneWidget);
      expect(
        find.text('LISTEN AND SELECT THE PITCH CONTOUR THAT MATCHES THE SPEAKER.'),
        findsOneWidget,
      );
      expect(find.byType(PitchPatternMatchPromptCard), findsOneWidget);
      expect(find.text('Where are you going?'), findsOneWidget);
      expect(find.text('CURIOUS / INQUIRING'), findsOneWidget);
      expect(find.byType(PitchPatternMatchPulseSpeaker), findsOneWidget);
      expect(find.text('LISTEN'), findsOneWidget);
      expect(find.byType(PitchPatternMatchVerticalFader), findsOneWidget);
      expect(find.text('Rising pitch (Question)'), findsOneWidget);
      expect(find.text('Falling pitch (Statement)'), findsOneWidget);

      // Phase 2 overlay and melodic canvas shouldn't be visible in initial unanswered state
      expect(find.byType(SpeakToConfirmOverlay), findsNothing);
      expect(find.byType(PitchPatternMatchMelodicCanvas), findsNothing);
    });

    testWidgets('tapping pulse speaker triggers TTS, haptic, and starts wave preview', (tester) async {
      await pumpPitchPatternMatch(tester);

      final speakerBtn = find.byKey(const ValueKey('pitch_pattern_speaker_btn'));
      expect(speakerBtn, findsOneWidget);

      await tester.tap(speakerBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockHapticService.selection()).called(1);
      verify(() => mockSoundService.playTts('Where are you going?')).called(1);

      // Pulse speaker wave triggers preview canvas
      expect(find.byType(PitchPatternMatchMelodicCanvas), findsOneWidget);
    });

    testWidgets('tapping hint button dispatches AccentHintUsed without duplicates', (tester) async {
      await pumpPitchPatternMatch(tester);

      final hintBtn = find.byType(QuestHintButton);
      expect(hintBtn, findsOneWidget);

      await tester.tap(hintBtn);
      await tester.pump();

      verify(() => mockAccentBloc.add(any(that: isA<AccentHintUsed>()))).called(1);
    });

    testWidgets('renders GameShimmerLoading when in AccentInitial state', (tester) async {
      await pumpPitchPatternMatch(tester, state: const AccentInitial());

      expect(find.byType(GameShimmerLoading), findsOneWidget);
      expect(find.byType(PitchPatternMatchVerticalFader), findsNothing);
    });
  });

  group('PitchPatternMatchScreen - Phase 1 Option & Slider Flow', () {
    testWidgets('tapping wrong option triggers error audio/haptics and submits wrong answer', (tester) async {
      await pumpPitchPatternMatch(tester);

      // Option 1 ('Falling pitch (Statement)') is wrong (correctIndex is 0)
      final wrongOption = find.byKey(const ValueKey('pitch_pattern_option_1'));
      expect(wrongOption, findsOneWidget);

      await tester.tap(wrongOption);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockHapticService.error()).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockAccentBloc.add(const SubmitAnswer(false))).called(1);

      // Phase 2 overlay remains unmounted
      expect(find.byType(SpeakToConfirmOverlay), findsNothing);
    });

    testWidgets('tapping correct option advances to Stage 2 verbal evaluation without early answer submission', (tester) async {
      await pumpPitchPatternMatch(tester);

      // Option 0 ('Rising pitch (Question)') is correct
      final correctOption = find.byKey(const ValueKey('pitch_pattern_option_0'));
      expect(correctOption, findsOneWidget);

      await tester.tap(correctOption);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockHapticService.success()).called(1);
      verify(() => mockSoundService.playCorrect()).called(1);
      verifyNever(() => mockAccentBloc.add(const SubmitAnswer(true)));

      // Instruction changes to stage 2 recording instruction
      expect(
        find.text('GREAT JOB! NOW RECORD YOURSELF SAYING THE WORD.'),
        findsOneWidget,
      );

      // Melodic canvas becomes mounted
      expect(find.byType(PitchPatternMatchMelodicCanvas), findsOneWidget);

      // Scroll down to bring SpeakToConfirmOverlay into view
      await tester.drag(
        find.byType(CustomScrollView),
        const Offset(0, -600),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SpeakToConfirmOverlay), findsOneWidget);
      expect(find.text('NOW SAY IT'), findsOneWidget);
      expect(find.text('Where are you going?'), findsWidgets);
    });

    testWidgets('dragging vertical slider bar up selects top option via threshold', (tester) async {
      await pumpPitchPatternMatch(tester);

      final slider = find.byKey(const ValueKey('pitch_pattern_slider'));
      expect(slider, findsOneWidget);

      // Drag up: with quarterTurns: 3, dragging towards top increases slider value > 0.9 -> selects option 0
      await tester.drag(slider, const Offset(0, -100));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockHapticService.success()).called(1);
      verify(() => mockSoundService.playCorrect()).called(1);
      verifyNever(() => mockAccentBloc.add(const SubmitAnswer(true)));

      expect(
        find.text('GREAT JOB! NOW RECORD YOURSELF SAYING THE WORD.'),
        findsOneWidget,
      );
    });

    testWidgets('dragging vertical slider bar down selects bottom option via threshold', (tester) async {
      await pumpPitchPatternMatch(tester);

      final slider = find.byKey(const ValueKey('pitch_pattern_slider'));
      expect(slider, findsOneWidget);

      // Drag down: dragging towards bottom decreases slider value < 0.1 -> selects option 1 (wrong)
      await tester.drag(slider, const Offset(0, 100));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockHapticService.error()).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockAccentBloc.add(const SubmitAnswer(false))).called(1);
    });

    testWidgets('interaction lockout prevents secondary taps once answered', (tester) async {
      await pumpPitchPatternMatch(tester);

      // Submit wrong answer
      final wrongOption = find.byKey(const ValueKey('pitch_pattern_option_1'));
      await tester.tap(wrongOption);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockAccentBloc.add(const SubmitAnswer(false))).called(1);

      // Further taps on correct option are ignored
      final correctOption = find.byKey(const ValueKey('pitch_pattern_option_0'));
      await tester.tap(correctOption, warnIfMissed: false);
      await tester.pump();

      verifyNever(() => mockAccentBloc.add(const SubmitAnswer(true)));
    });
  });

  group('PitchPatternMatchScreen - Phase 2 Speaking & Multi-Turn Flow', () {
    testWidgets('recording audio and confirming "Nailed It" dispatches AccentSpeakConfirmed(5) and SubmitAnswer(true)', (tester) async {
      await pumpPitchPatternMatch(tester);

      // Advance stage 1
      await tester.tap(find.byKey(const ValueKey('pitch_pattern_option_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Scroll to SpeakToConfirmOverlay
      await tester.drag(
        find.byType(CustomScrollView),
        const Offset(0, -600),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SpeakToConfirmOverlay), findsOneWidget);

      // Switch to manual evaluation controls
      final manualEvalOption = find.text('Evaluate myself manually');
      expect(manualEvalOption, findsOneWidget);
      await tester.tap(manualEvalOption);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final micBtn = find.byKey(const ValueKey('speaking_mic_btn'));
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

      // Tap Nailed It
      final nailedItBtn = find.text('Nailed It');
      expect(nailedItBtn, findsOneWidget);
      await tester.ensureVisible(nailedItBtn);
      await tester.tap(nailedItBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockHapticService.success()).called(2); // 1 for option, 1 for speak
      verify(() => mockSoundService.playCorrect()).called(2);
      verify(() => mockAccentBloc.add(const AccentSpeakConfirmed(5))).called(1);
      verify(() => mockAccentBloc.add(const SubmitAnswer(true))).called(1);
    });

    testWidgets('evaluating "Needs Work" triggers error feedback and SubmitAnswer(false)', (tester) async {
      await pumpPitchPatternMatch(tester);

      // Advance stage 1
      await tester.tap(find.byKey(const ValueKey('pitch_pattern_option_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Scroll to SpeakToConfirmOverlay
      await tester.drag(
        find.byType(CustomScrollView),
        const Offset(0, -600),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Switch to manual evaluation
      await tester.tap(find.text('Evaluate myself manually'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final micBtn = find.byKey(const ValueKey('speaking_mic_btn'));
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
      expect(needsWorkBtn, findsOneWidget);
      await tester.ensureVisible(needsWorkBtn);
      await tester.tap(needsWorkBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockHapticService.error()).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockAccentBloc.add(const SubmitAnswer(false))).called(1);
    });

    testWidgets('tapping rewarded skip button bypasses speaking challenge and submits answer', (tester) async {
      await pumpPitchPatternMatch(tester);

      // Advance stage 1
      await tester.tap(find.byKey(const ValueKey('pitch_pattern_option_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Scroll to SpeakToConfirmOverlay
      await tester.drag(
        find.byType(CustomScrollView),
        const Offset(0, -600),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final skipBtn = find.byType(GameSkipBypassButton);
      expect(skipBtn, findsOneWidget);

      await tester.tap(skipBtn);
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
      await pumpPitchPatternMatch(tester);

      // Submit wrong answer to become answered
      final wrongOption = find.byKey(const ValueKey('pitch_pattern_option_1'));
      await tester.tap(wrongOption);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final continueBtn = find.text('TRY AGAIN');
      expect(continueBtn, findsOneWidget);

      await tester.tap(continueBtn);
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockAccentBloc.add(const NextQuestion())).called(1);
    });
  });

  group('PitchPatternMatchScreen - Briefing, Small Screens & Accessibility', () {
    testWidgets('renders and dismisses GameBriefingLayer on Level 1', (tester) async {
      SharedPreferences.setMockInitialValues({
        'has_seen_briefing_pitchPatternMatch': false,
      });

      await pumpPitchPatternMatch(tester, level: 1, height: 1300);

      expect(find.byType(GameBriefingLayer), findsOneWidget);

      final briefingBtn = find.descendant(
        of: find.byType(GameBriefingLayer),
        matching: find.byType(ScaleButton),
      );
      expect(briefingBtn, findsOneWidget);

      await tester.tap(briefingBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(GameBriefingLayer), findsNothing);
    });

    testWidgets('renders cleanly on small device (320x568) in dark theme without overflow', (tester) async {
      await pumpPitchPatternMatch(
        tester,
        themeMode: ThemeMode.dark,
        width: 320,
        height: 568,
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(PitchPatternMatchPromptCard), findsOneWidget);
      expect(find.byType(PitchPatternMatchVerticalFader), findsOneWidget);
    });

    testWidgets('respects reduced motion when lowAnimationModeOverride is enabled', (tester) async {
      VowlMotion.lowAnimationModeOverride.value = true;

      await pumpPitchPatternMatch(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(PitchPatternMatchScreen), findsOneWidget);

      final speakerBtn = find.byKey(const ValueKey('pitch_pattern_speaker_btn'));
      await tester.tap(speakerBtn);
      await tester.pump();

      verify(() => mockSoundService.playTts('Where are you going?')).called(1);
    });

    testWidgets('instruction text has centered text alignment and wraps cleanly without ellipsis', (tester) async {
      const longInstructionQuest = AccentQuest(
        id: 'ACC_PPM_LONG_INST',
        instruction: 'Listen carefully and select the pitch pattern contour that best matches what you hear.',
        difficulty: 1,
        subtype: GameSubtype.pitchPatternMatch,
        word: 'Are we almost there yet or should we stop?',
        textToSpeak: 'Are we almost there yet or should we stop?',
        emotionContext: 'Curious / Inquiring',
        options: ['Rising pitch (Question)', 'Falling pitch (Statement)'],
        correctAnswerIndex: 0,
        pitchPatterns: [0, 1, 2, 3, 4],
      );

      await pumpPitchPatternMatch(
        tester,
        state: testLoadedState.copyWith(quests: [longInstructionQuest]),
      );

      final instructionWidget = tester.widget<Text>(
        find.descendant(
          of: find.byType(PitchPatternMatchInstruction),
          matching: find.byType(Text),
        ),
      );
      expect(instructionWidget.textAlign, equals(TextAlign.center));
      expect(instructionWidget.maxLines, isNull);
      expect(instructionWidget.overflow, isNot(TextOverflow.ellipsis));
      expect(tester.takeException(), isNull);
    });

    testWidgets('prompt card word wraps cleanly without ellipsis or overflow', (tester) async {
      const longSentenceQuest = AccentQuest(
        id: 'ACC_PPM_LONG_SENT',
        instruction: 'Listen and select the pitch pattern.',
        difficulty: 1,
        subtype: GameSubtype.pitchPatternMatch,
        word: 'Could you please explain why the schedule was postponed without any prior announcement?',
        textToSpeak: 'Could you please explain why the schedule was postponed without any prior announcement?',
        emotionContext: 'Concerned / Questioning',
        options: ['Rising pitch', 'Falling pitch'],
        correctAnswerIndex: 0,
        pitchPatterns: [0, 1, 2, 3, 4],
      );

      await pumpPitchPatternMatch(
        tester,
        state: testLoadedState.copyWith(quests: [longSentenceQuest]),
      );

      final wordFinder = find.text('Could you please explain why the schedule was postponed without any prior announcement?');
      expect(wordFinder, findsOneWidget);
      final wordWidget = tester.widget<Text>(wordFinder);
      expect(wordWidget.maxLines, isNull);
      expect(wordWidget.overflow, isNot(TextOverflow.ellipsis));
      expect(tester.takeException(), isNull);
    });

    testWidgets('cards have standard horizontal padding and do not touch screen edges', (tester) async {
      await pumpPitchPatternMatch(tester, width: 390);

      // Verify prompt card does not touch screen edges (left >= 20, right <= 370)
      final promptRect = tester.getRect(find.byType(PitchPatternMatchPromptCard));
      expect(promptRect.left, greaterThanOrEqualTo(20.0));
      expect(promptRect.right, lessThanOrEqualTo(370.0));

      // Advance stage 1 to Phase 2
      await tester.tap(find.byKey(const ValueKey('pitch_pattern_option_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify SpeakToConfirmOverlay does not touch screen edges
      final speakOverlayRect = tester.getRect(find.byType(SpeakToConfirmOverlay));
      expect(speakOverlayRect.left, greaterThanOrEqualTo(20.0));
      expect(speakOverlayRect.right, lessThanOrEqualTo(370.0));
      expect(tester.takeException(), isNull);
    });
  });
}

