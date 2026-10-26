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
import 'package:vowl/features/accent/presentation/bloc/accent_bloc.dart';
import 'package:vowl/features/accent/vowel_distinction/presentation/pages/vowel_distinction_screen.dart';
import 'package:vowl/features/accent/vowel_distinction/presentation/widgets/vowel_distinction_instruction.dart';
import 'package:vowl/features/accent/vowel_distinction/presentation/widgets/vowel_distinction_prompt_card.dart';
import 'package:vowl/features/accent/vowel_distinction/presentation/widgets/vowel_distinction_pulse_speaker.dart';
import 'package:vowl/features/accent/vowel_distinction/presentation/widgets/vowel_distinction_spectral_slider.dart';
import 'package:vowl/features/accent/vowel_distinction/presentation/widgets/vowel_trapezoid_chart.dart';
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
    id: 'ACC_VOWELDISTINCTION_L41_Q1',
    instruction: 'SLIDE OR TAP TO MATCH THE TARGET VOWEL SOUND',
    difficulty: 1,
    subtype: GameSubtype.vowelDistinction,
    word: 'hot',
    textToSpeak: 'hot',
    options: ['/ɒ/', '/ʌ/'],
    correctAnswer: '/ɒ/',
    correctAnswerIndex: 0,
    hint: "Drop the jaw: 'hot' feels back and open.",
    explanation: 'The tongue pulls back, giving a back open vowel.',
    vowelTensionRule: '/ɒ/ is back and open; /ʌ/ is central.',
    vowelChart: {
      'x': 0.95,
      'y': 0.8,
    },
  );

  const testQuest2 = AccentQuest(
    id: 'ACC_VOWELDISTINCTION_L41_Q2',
    instruction: 'SLIDE OR TAP TO MATCH THE TARGET VOWEL SOUND',
    difficulty: 1,
    subtype: GameSubtype.vowelDistinction,
    word: 'run',
    textToSpeak: 'run',
    options: ['/ɒ/', '/ʌ/'],
    correctAnswer: '/ʌ/',
    correctAnswerIndex: 1,
    hint: "Neutral lips and relaxed tongue.",
    explanation: "'run' uses the central vowel.",
    vowelTensionRule: '/ʌ/ is central and unrounded.',
  );

  const testLoadedState = AccentLoaded(
    quests: [testQuest1, testQuest2],
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
    gameType: GameSubtype.vowelDistinction,
    level: 41,
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
      'has_seen_briefing_vowelDistinction': true,
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
    ).thenAnswer((_) async => '/tmp/audio_vowel_distinction.m4a');
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
    ).thenAnswer((inv) async {
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

  tearDown(() {
    VowlMotion.lowAnimationModeOverride.value = false;
  });

  Future<void> pumpVowelDistinction(
    WidgetTester tester, {
    AccentState? state,
    int level = 41,
    double width = 390,
    double height = 844,
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    if (state != null) {
      when(() => mockAccentBloc.state).thenReturn(state);
    }

    tester.view.physicalSize = Size(width * 2, height * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) => MultiBlocProvider(
          providers: [
            BlocProvider<AccentBloc>.value(value: mockAccentBloc),
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            BlocProvider<EconomyBloc>.value(value: mockEconomyBloc),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            home: VowelDistinctionScreen(
              level: level,
              gameType: GameSubtype.vowelDistinction,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('VowelDistinctionScreen - Phase 1 Spectral Slider & Core Layout', () {
    testWidgets('shows GameShimmerLoading when state is AccentInitial', (
      tester,
    ) async {
      await pumpVowelDistinction(
        tester,
        state: const AccentInitial(),
      );

      expect(find.byType(GameShimmerLoading), findsOneWidget);
    });

    testWidgets('renders all primary widgets correctly when loaded', (
      tester,
    ) async {
      await pumpVowelDistinction(tester);

      expect(find.byType(VowelDistinctionInstruction), findsOneWidget);
      expect(find.byType(VowelDistinctionPromptCard), findsOneWidget);
      expect(find.text('HOT'), findsOneWidget);
      expect(find.byType(VowelDistinctionPulseSpeaker), findsOneWidget);
      expect(find.text('HEAR VOWEL'), findsOneWidget);
      expect(find.byType(VowelDistinctionSpectralSlider), findsOneWidget);

      // Verify vowel orbs and slider
      expect(find.byKey(const ValueKey('vowel_orb_0')), findsOneWidget);
      expect(find.byKey(const ValueKey('vowel_orb_1')), findsOneWidget);
      expect(find.byKey(const ValueKey('vowel_spectral_slider')), findsOneWidget);

      expect(find.text('/ɒ/'), findsOneWidget);
      expect(find.text('/ʌ/'), findsOneWidget);
    });

    testWidgets('tapping pulse speaker button triggers playTts and haptic', (
      tester,
    ) async {
      await pumpVowelDistinction(tester);

      final speakerBtn = find.byKey(
        const ValueKey('vowel_distinction_pulse_speaker_btn'),
      );
      expect(speakerBtn, findsOneWidget);

      await tester.tap(speakerBtn);
      await tester.pump();

      verify(() => mockHapticService.selection()).called(1);
      verify(() => mockSoundService.playTts('hot')).called(1);
    });

    testWidgets('tapping wrong vowel orb triggers wrong sound and error haptic', (
      tester,
    ) async {
      await pumpVowelDistinction(tester);

      // Option 1 is '/ʌ/', correct is 0 ('/ɒ/')
      final wrongOrb = find.byKey(const ValueKey('vowel_orb_1'));
      await tester.tap(wrongOrb);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockHapticService.error()).called(1);
      verify(() => mockSoundService.playWrong()).called(1);

      // Feedback card is displayed with TRY AGAIN
      expect(find.text('TRY AGAIN'), findsOneWidget);
    });

    testWidgets('tapping wrong orb locks interaction to prevent duplicate taps', (
      tester,
    ) async {
      await pumpVowelDistinction(tester);

      final wrongOrb = find.byKey(const ValueKey('vowel_orb_1'));
      await tester.tap(wrongOrb);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      clearInteractions(mockSoundService);
      clearInteractions(mockHapticService);

      // Attempt to tap another orb
      final orb0 = find.byKey(const ValueKey('vowel_orb_0'));
      await tester.tap(orb0, warnIfMissed: false);
      await tester.pump();

      verifyNever(() => mockSoundService.playWrong());
      verifyNever(() => mockSoundService.playCorrect());
      verifyNever(() => mockHapticService.error());
    });

    testWidgets(
      'tapping correct vowel orb advances to Phase 2 and mounts VowelTrapezoidChart',
      (tester) async {
        await pumpVowelDistinction(tester);

        // Orb 0 is '/ɒ/', which is correct
        final correctOrb = find.byKey(const ValueKey('vowel_orb_0'));
        await tester.tap(correctOrb);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        verify(() => mockHapticService.success()).called(1);
        verify(() => mockSoundService.playCorrect()).called(1);

        // VowelTrapezoidChart should now be mounted in place of pulse speaker
        expect(find.byType(VowelTrapezoidChart), findsOneWidget);

        // Drag to reveal the lazy Phase 2 sliver
        await tester.dragFrom(const Offset(20, 600), const Offset(0, -700));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // SpeakToConfirmOverlay should now be mounted
        expect(find.byType(SpeakToConfirmOverlay), findsOneWidget);
      },
    );

    testWidgets('sliding spectral slider to left selects option 0', (
      tester,
    ) async {
      await pumpVowelDistinction(tester);

      final slider = find.byKey(const ValueKey('vowel_spectral_slider'));
      expect(slider, findsOneWidget);

      // Drag slider all the way to the left
      await tester.drag(slider, const Offset(-150, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockHapticService.success()).called(1);
      verify(() => mockSoundService.playCorrect()).called(1);
      expect(find.byType(VowelTrapezoidChart), findsOneWidget);
    });
  });

  group('VowelDistinctionScreen - Phase 2 Verbal Evaluation & Overlay', () {
    testWidgets('Phase 2 microphone interaction and self-eval Nailed It', (
      tester,
    ) async {
      await pumpVowelDistinction(tester);

      // Complete Phase 1
      final correctOrb = find.byKey(const ValueKey('vowel_orb_0'));
      await tester.tap(correctOrb);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      await tester.dragFrom(const Offset(20, 600), const Offset(0, -700));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

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

      verify(() => mockHapticService.success()).called(2);
      verify(() => mockSoundService.playCorrect()).called(2);
      verify(() => mockAccentBloc.add(const AccentSpeakConfirmed(5))).called(1);
      verify(() => mockAccentBloc.add(const SubmitAnswer(true))).called(1);
    });

    testWidgets('Phase 2 self-eval Needs Work records wrong answer', (
      tester,
    ) async {
      await pumpVowelDistinction(tester);

      // Complete Phase 1
      final correctOrb = find.byKey(const ValueKey('vowel_orb_0'));
      await tester.tap(correctOrb);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      await tester.dragFrom(const Offset(20, 600), const Offset(0, -700));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

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
      expect(find.text('TRY AGAIN'), findsOneWidget);
    });

    testWidgets('Phase 2 skip bypass button shows ad and submits correct', (
      tester,
    ) async {
      await pumpVowelDistinction(tester);

      // Complete Phase 1
      final correctOrb = find.byKey(const ValueKey('vowel_orb_0'));
      await tester.tap(correctOrb);
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

    testWidgets('tapping continue button when answered dispatches NextQuestion', (
      tester,
    ) async {
      await pumpVowelDistinction(tester);

      final wrongOrb = find.byKey(const ValueKey('vowel_orb_1'));
      await tester.tap(wrongOrb);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final continueBtn = find.text('TRY AGAIN');
      expect(continueBtn, findsOneWidget);
      await tester.tap(continueBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockAccentBloc.add(const NextQuestion())).called(1);
    });

    testWidgets(
      'tapping TRY AGAIN on feedback card resets state and dismisses feedback card when bloc retries',
      (tester) async {
        final stateController = StreamController<AccentState>.broadcast();
        addTearDown(stateController.close);

        when(() => mockAccentBloc.stream)
            .thenAnswer((_) => stateController.stream);

        await pumpVowelDistinction(tester);

        // Tap wrong answer
        final wrongOrb = find.byKey(const ValueKey('vowel_orb_1'));
        await tester.tap(wrongOrb);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('TRY AGAIN'), findsOneWidget);

        // Simulate bloc emitting retry state (unanswered, 2 lives)
        final retryState = testLoadedState.copyWith(
          livesRemaining: 2,
          answerStatus: AnswerStatus.unanswered,
        );
        when(() => mockAccentBloc.state).thenReturn(retryState);
        stateController.add(retryState);

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Feedback card is dismissed
        expect(find.text('TRY AGAIN'), findsNothing);

        await tester.pump(const Duration(seconds: 2));
      },
    );
  });

  group('VowelDistinctionScreen - Briefing, Hint & Motion Settings', () {
    testWidgets('renders and dismisses GameBriefingLayer on Level 1', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'has_seen_briefing_vowelDistinction': false,
      });

      await pumpVowelDistinction(tester, level: 1, height: 1000);

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

    testWidgets('tapping hint button dispatches AccentHintUsed', (
      tester,
    ) async {
      await pumpVowelDistinction(tester);

      final hintBtn = find.byType(QuestHintButton);
      expect(hintBtn, findsOneWidget);

      await tester.tap(hintBtn);
      await tester.pump();

      verify(() => mockAccentBloc.add(const AccentHintUsed())).called(1);
    });

    testWidgets('respects low animation mode (reduced motion)', (
      tester,
    ) async {
      VowlMotion.lowAnimationModeOverride.value = true;

      await pumpVowelDistinction(tester);

      expect(find.byType(VowelDistinctionPulseSpeaker), findsOneWidget);
      expect(find.byType(VowelDistinctionSpectralSlider), findsOneWidget);
    });
  });

  group('VowelDistinctionScreen - Multi-Screen Responsiveness & Zero Overflow', () {
    testWidgets('renders cleanly on standard phone screen (390x844)', (
      tester,
    ) async {
      await pumpVowelDistinction(tester, width: 390, height: 844);

      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly on compact screen (320x568) with no overflows', (
      tester,
    ) async {
      await pumpVowelDistinction(tester, width: 320, height: 568);

      expect(tester.takeException(), isNull);
      expect(find.byType(VowelDistinctionSpectralSlider), findsOneWidget);
    });

    testWidgets('renders cleanly on tablet screen (768x1024)', (
      tester,
    ) async {
      await pumpVowelDistinction(tester, width: 768, height: 1024);

      expect(tester.takeException(), isNull);
      expect(find.byType(VowelDistinctionSpectralSlider), findsOneWidget);
    });

    testWidgets('renders properly in dark mode', (
      tester,
    ) async {
      await pumpVowelDistinction(tester, themeMode: ThemeMode.dark);

      expect(tester.takeException(), isNull);
      expect(find.byType(VowelDistinctionSpectralSlider), findsOneWidget);
    });
  });
}

