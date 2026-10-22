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
import 'package:vowl/features/accent/intonation_mimic/presentation/pages/intonation_mimic_screen.dart';
import 'package:vowl/features/accent/intonation_mimic/presentation/widgets/intonation_mimic_instruction.dart';
import 'package:vowl/features/accent/intonation_mimic/presentation/widgets/intonation_mimic_prompt_card.dart';
import 'package:vowl/features/accent/intonation_mimic/presentation/widgets/intonation_mimic_pulse_speaker.dart';
import 'package:vowl/features/accent/intonation_mimic/presentation/widgets/intonation_mimic_rollercoaster.dart';
import 'package:vowl/features/accent/intonation_mimic/presentation/widgets/intonation_mimic_vertical_fader.dart';
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
    id: 'ACC_IM_L1_Q1',
    instruction: 'Identify the intonation pattern of this sentence.',
    difficulty: 1,
    subtype: GameSubtype.intonationMimic,
    word: 'Really?',
    textToSpeak: 'Really?',
    options: ['Rising Intonation', 'Falling Intonation'],
    correctAnswerIndex: 0,
    intonationMap: [1, 2, 3, 4],
    emotionContext: 'Surprise / Disbelief',
    hint: 'The pitch goes up at the end of the sentence.',
    explanation: 'Questions expressing surprise usually end in a rising pitch contour.',
  );

  const testQuest2 = AccentQuest(
    id: 'ACC_IM_L1_Q2',
    instruction: 'Identify the intonation pattern of this sentence.',
    difficulty: 1,
    subtype: GameSubtype.intonationMimic,
    word: 'I see.',
    textToSpeak: 'I see.',
    options: ['Rising Intonation', 'Falling Intonation'],
    correctAnswerIndex: 1,
    intonationMap: [4, 3, 2, 1],
    emotionContext: 'Acknowledgement',
    hint: 'The pitch falls downward at the conclusion.',
    explanation: 'Definitive statements typically feature a falling terminal pitch.',
  );

  const testLoadedState = AccentLoaded(
    quests: [testQuest1, testQuest2],
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
    gameType: GameSubtype.intonationMimic,
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
      'has_seen_briefing_intonationMimic': true,
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
        locale: any(named: 'locale'),
      ),
    ).thenAnswer((_) async {});

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
    ).thenAnswer((_) async => '/tmp/audio_mimic.m4a');
    when(() => mockAudioRecorder.isRecording).thenReturn(false);
    when(
      () => mockAudioRecorder.onAmplitudeChanged(any()),
    ).thenAnswer((_) => Stream.value(Amplitude(current: -10, max: -5)));
    when(() => mockAudioRecorder.dispose()).thenAnswer((_) async {});

    when(() => mockAnalyticsService.logSelfEvaluation(any())).thenAnswer((_) async {});
    when(() => mockAnalyticsService.logGameSkipped(any())).thenAnswer((_) async {});

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

  Future<void> pumpIntonationMimic(
    WidgetTester tester, {
    AccentState? state,
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
      when(() => mockAccentBloc.state).thenReturn(state);
    }

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
            home: IntonationMimicScreen(
              level: level,
              gameType: GameSubtype.intonationMimic,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  group('IntonationMimicScreen - Layout & Presentation Tests', () {
    testWidgets('1. renders all core UI elements on initial loaded state', (
      tester,
    ) async {
      await pumpIntonationMimic(tester);

      expect(find.byType(IntonationMimicInstruction), findsOneWidget);
      expect(
        find.text('Identify the intonation pattern of this sentence.'),
        findsOneWidget,
      );
      expect(find.byType(IntonationMimicPromptCard), findsOneWidget);
      expect(find.text('Really?'), findsOneWidget);
      expect(find.text('Surprise / Disbelief'), findsOneWidget);

      expect(find.byType(IntonationMimicPulseSpeaker), findsOneWidget);
      expect(find.byKey(const ValueKey('intonation_speaker_btn')), findsOneWidget);

      expect(find.byType(IntonationMimicVerticalFader), findsOneWidget);
      expect(find.byKey(const ValueKey('intonation_option_0')), findsOneWidget);
      expect(find.byKey(const ValueKey('intonation_option_1')), findsOneWidget);
      expect(find.text('Rising Intonation'), findsOneWidget);
      expect(find.text('Falling Intonation'), findsOneWidget);
      expect(find.byKey(const ValueKey('intonation_slider')), findsOneWidget);
    });

    testWidgets('2. tapping pulse speaker triggers playTts and haptic selection', (
      tester,
    ) async {
      await pumpIntonationMimic(tester);

      final speakerBtn = find.byKey(const ValueKey('intonation_speaker_btn'));
      expect(speakerBtn, findsOneWidget);

      await tester.tap(speakerBtn);
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      verify(() => mockHapticService.selection()).called(1);
      verify(() => mockSoundService.playTts('Really?')).called(1);
    });

    testWidgets('3. tapping correct pitch option advances to stage 2 overlay', (
      tester,
    ) async {
      await pumpIntonationMimic(tester);

      final correctOption = find.byKey(const ValueKey('intonation_option_0'));
      expect(correctOption, findsOneWidget);

      await tester.tap(correctOption);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      verify(() => mockHapticService.success()).called(1);
      verify(() => mockSoundService.playCorrect()).called(1);

      // Advances to Stage 2: Rollercoaster is visible at the top before scrolling
      expect(find.byType(IntonationMimicRollercoaster), findsOneWidget);
      expect(
        find.text('Now speak the sentence with the matching intonation.'),
        findsOneWidget,
      );

      // Scroll down to reveal SpeakToConfirmOverlay
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SpeakToConfirmOverlay), findsOneWidget);
    });

    testWidgets('4. tapping wrong pitch option triggers submitWrongAnswer directly', (
      tester,
    ) async {
      await pumpIntonationMimic(tester);

      final wrongOption = find.byKey(const ValueKey('intonation_option_1'));
      expect(wrongOption, findsOneWidget);

      await tester.tap(wrongOption);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockHapticService.error()).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockAccentBloc.add(const SubmitAnswer(false))).called(1);

      // Does not advance to stage 2 SpeakToConfirmOverlay
      expect(find.byType(SpeakToConfirmOverlay), findsNothing);
    });

    testWidgets('5. dragging slider up past threshold auto-submits rising option', (
      tester,
    ) async {
      await pumpIntonationMimic(tester);

      final sliderFinder = find.byKey(const ValueKey('intonation_slider'));
      expect(sliderFinder, findsOneWidget);

      final Slider sliderWidget = tester.widget(sliderFinder);
      sliderWidget.onChanged!(0.95);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockHapticService.success()).called(1);
      verify(() => mockSoundService.playCorrect()).called(1);

      // Scroll down to reveal SpeakToConfirmOverlay
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(SpeakToConfirmOverlay), findsOneWidget);
    });

    testWidgets('6. dragging slider down past threshold auto-submits falling option', (
      tester,
    ) async {
      await pumpIntonationMimic(tester);

      final sliderFinder = find.byKey(const ValueKey('intonation_slider'));
      expect(sliderFinder, findsOneWidget);

      final Slider sliderWidget = tester.widget(sliderFinder);
      sliderWidget.onChanged!(0.05);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockHapticService.error()).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockAccentBloc.add(const SubmitAnswer(false))).called(1);
    });

    testWidgets('7. once answered, subsequent taps on options are ignored', (
      tester,
    ) async {
      await pumpIntonationMimic(tester);

      final wrongOption = find.byKey(const ValueKey('intonation_option_1'));
      await tester.tap(wrongOption);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockAccentBloc.add(const SubmitAnswer(false))).called(1);

      // Attempt second tap
      await tester.tap(wrongOption, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verifyNever(() => mockAccentBloc.add(const SubmitAnswer(true)));
      verifyNever(() => mockAccentBloc.add(const AccentSpeakConfirmed(5)));
    });

    testWidgets('8. stage 2: SpeakToConfirmOverlay shows expected text and switches to manual evaluation', (
      tester,
    ) async {
      await pumpIntonationMimic(tester);

      // Advance to stage 2
      await tester.tap(find.byKey(const ValueKey('intonation_option_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SpeakToConfirmOverlay), findsOneWidget);
      expect(find.text('NOW SAY IT'), findsOneWidget);
      expect(find.text('+5 COINS'), findsNothing);
      expect(find.text('Tap to Speak'), findsOneWidget);

      // Switch to manual evaluation mode
      final manualBtn = find.text('Evaluate myself manually');
      await tester.ensureVisible(manualBtn);
      await tester.pumpAndSettle();
      expect(manualBtn, findsOneWidget);
      await tester.tap(manualBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const ValueKey('speaking_mic_btn')), findsOneWidget);
      expect(find.text('Tap or Hold to speak'), findsOneWidget);
    });

    testWidgets('9. stage 2: recording cycle reveals self-evaluation buttons', (
      tester,
    ) async {
      await pumpIntonationMimic(tester);

      // Advance to stage 2
      await tester.tap(find.byKey(const ValueKey('intonation_option_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 500));

      // Switch to manual evaluation mode
      final manualBtn = find.text('Evaluate myself manually');
      await tester.ensureVisible(manualBtn);
      await tester.pumpAndSettle();
      await tester.tap(manualBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap mic to start recording
      final micBtn = find.byKey(const ValueKey('speaking_mic_btn'));
      await tester.ensureVisible(micBtn);
      await tester.pumpAndSettle();
      await tester.tap(micBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      verify(() => mockAudioRecorder.startRecording()).called(1);
      expect(find.byIcon(Icons.stop_rounded), findsOneWidget);
      expect(find.text('Recording... Tap to stop'), findsOneWidget);

      // Tap stop to finish recording
      await tester.tap(find.byIcon(Icons.stop_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockAudioRecorder.stopRecording()).called(1);

      // Nailed It and Needs Work evaluation buttons appear
      expect(find.text('Nailed It'), findsOneWidget);
      expect(find.text('Needs Work'), findsOneWidget);
    });

    testWidgets('10. stage 2: tapping Nailed It awards coins and submits correct answer', (
      tester,
    ) async {
      await pumpIntonationMimic(tester);

      // Advance to stage 2
      await tester.tap(find.byKey(const ValueKey('intonation_option_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 500));

      // Switch to manual evaluation mode
      final manualBtn = find.text('Evaluate myself manually');
      await tester.ensureVisible(manualBtn);
      await tester.pumpAndSettle();
      await tester.tap(manualBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Record audio
      final micBtn = find.byKey(const ValueKey('speaking_mic_btn'));
      await tester.ensureVisible(micBtn);
      await tester.pumpAndSettle();
      await tester.tap(micBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byIcon(Icons.stop_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Tap Nailed It
      final nailedItBtn = find.text('Nailed It');
      await tester.ensureVisible(nailedItBtn);
      await tester.pumpAndSettle();
      expect(nailedItBtn, findsOneWidget);
      await tester.tap(nailedItBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockAccentBloc.add(const AccentSpeakConfirmed(5))).called(1);
      verify(() => mockAccentBloc.add(const SubmitAnswer(true))).called(1);
      verify(() => mockHapticService.success()).called(greaterThanOrEqualTo(1));
      verify(() => mockSoundService.playCorrect()).called(greaterThanOrEqualTo(1));
    });

    testWidgets('11. stage 2: tapping Needs Work dispatches SubmitAnswer(false)', (
      tester,
    ) async {
      await pumpIntonationMimic(tester);

      // Advance to stage 2
      await tester.tap(find.byKey(const ValueKey('intonation_option_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 500));

      // Switch to manual evaluation mode
      final manualBtn = find.text('Evaluate myself manually');
      await tester.ensureVisible(manualBtn);
      await tester.pumpAndSettle();
      await tester.tap(manualBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Record audio
      final micBtn = find.byKey(const ValueKey('speaking_mic_btn'));
      await tester.ensureVisible(micBtn);
      await tester.pumpAndSettle();
      await tester.tap(micBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byIcon(Icons.stop_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Tap Needs Work
      final needsWorkBtn = find.text('Needs Work');
      await tester.ensureVisible(needsWorkBtn);
      await tester.pumpAndSettle();
      expect(needsWorkBtn, findsOneWidget);
      await tester.tap(needsWorkBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockAccentBloc.add(const SubmitAnswer(false))).called(1);
      verify(() => mockHapticService.error()).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
    });

    testWidgets('12. stage 2: tapping skip button triggers rewarded bypass and submits answer', (
      tester,
    ) async {
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

      await pumpIntonationMimic(tester);

      // Advance to stage 2
      await tester.tap(find.byKey(const ValueKey('intonation_option_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 500));

      final skipBtn = find.byType(GameSkipBypassButton);
      await tester.ensureVisible(skipBtn);
      await tester.pumpAndSettle();
      expect(skipBtn, findsOneWidget);
      await tester.tap(skipBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockAccentBloc.add(const SubmitAnswer(true))).called(1);
    });

    testWidgets('13. tapping continue button when answered dispatches NextQuestion', (
      tester,
    ) async {
      await pumpIntonationMimic(tester);

      // Submit wrong answer to trigger answered state
      await tester.tap(find.byKey(const ValueKey('intonation_option_1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      final actionButton = find.widgetWithText(ScaleButton, 'TRY AGAIN');
      expect(actionButton, findsOneWidget);

      await tester.tap(actionButton);
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockAccentBloc.add(const NextQuestion())).called(1);
    });

    testWidgets('14. tapping hint button dispatches AccentHintUsed', (
      tester,
    ) async {
      await pumpIntonationMimic(tester);

      final hintButton = find.byType(QuestHintButton);
      expect(hintButton, findsOneWidget);

      await tester.tap(hintButton);
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockAccentBloc.add(const AccentHintUsed())).called(1);
    });

    testWidgets('15. renders GameShimmerLoading when state is AccentInitial', (
      tester,
    ) async {
      await pumpIntonationMimic(tester, state: const AccentInitial());

      expect(find.byType(GameShimmerLoading), findsOneWidget);
      expect(find.byType(IntonationMimicVerticalFader), findsNothing);
    });

    testWidgets('16. shows briefing layer on level 1 when unseen and dismisses cleanly', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'has_seen_briefing_intonationMimic': false,
      });

      await pumpIntonationMimic(tester, level: 1, height: 1100);

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
      expect(find.byType(IntonationMimicVerticalFader), findsOneWidget);
    });

    testWidgets('17. renders cleanly without overflow on small 320dp screen & dark theme', (
      tester,
    ) async {
      await pumpIntonationMimic(
        tester,
        themeMode: ThemeMode.dark,
        width: 320,
        height: 568,
      );
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull);
      expect(find.byType(IntonationMimicVerticalFader), findsOneWidget);
      expect(find.byKey(const ValueKey('intonation_option_0')), findsOneWidget);
      expect(find.byKey(const ValueKey('intonation_option_1')), findsOneWidget);
    });

    testWidgets('18. instruction card has symmetric internal padding and centers multi-line text', (
      tester,
    ) async {
      const longInstructionQuest = AccentQuest(
        id: 'ACC_IM_LONG_TEST',
        instruction:
            'A classmate wants to borrow something from you. Which pattern fits this sentence?',
        difficulty: 1,
        subtype: GameSubtype.intonationMimic,
        word: 'Do you have a pen?',
        textToSpeak: 'Do you have a pen?',
        options: [
          'Narrow pitch, low start — neutral report',
          'Wide pitch, high start — happy and friendly',
        ],
        correctAnswerIndex: 0,
        intonationMap: [1, 2, 3, 4],
        emotionContext: 'Friendly Inquiry',
        hint: 'Listen closely.',
        explanation: 'Friendly questions rise.',
      );

      await pumpIntonationMimic(
        tester,
        state: const AccentLoaded(
          quests: [longInstructionQuest],
          currentIndex: 0,
          livesRemaining: 3,
          answerStatus: AnswerStatus.unanswered,
          gameType: GameSubtype.intonationMimic,
          level: 2,
          hintUsed: false,
          wrongCount: 0,
          isFinalFailure: false,
        ),
      );

      final instructionFinder = find.byType(IntonationMimicInstruction);
      expect(instructionFinder, findsOneWidget);

      final containerWidget = tester.widget<Container>(
        find
            .descendant(
              of: instructionFinder,
              matching: find.byType(Container),
            )
            .first,
      );
      final padding = containerWidget.padding as EdgeInsets;
      expect(padding.left, equals(padding.right));

      final textWidget = tester.widget<Text>(
        find.descendant(of: instructionFinder, matching: find.byType(Text)),
      );
      expect(textWidget.textAlign, equals(TextAlign.center));
      expect(textWidget.overflow, isNot(TextOverflow.ellipsis));
    });

    testWidgets('19. stage 2 SpeakToConfirmOverlay mechanism card has standard horizontal padding from screen edges', (
      tester,
    ) async {
      await pumpIntonationMimic(tester);

      final correctOption = find.byKey(const ValueKey('intonation_option_0'));
      await tester.tap(correctOption);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final overlayFinder = find.byType(SpeakToConfirmOverlay);
      expect(overlayFinder, findsOneWidget);

      final parentPadding = tester.widget<Padding>(
        find.ancestor(of: overlayFinder, matching: find.byType(Padding)).first,
      );
      final overlayInsets = parentPadding.padding as EdgeInsets;
      expect(overlayInsets.left, greaterThanOrEqualTo(16.0));
      expect(overlayInsets.right, greaterThanOrEqualTo(16.0));
    });

    testWidgets('20. long sentences and long options never show ellipses', (
      tester,
    ) async {
      const longQuest = AccentQuest(
        id: 'ACC_IM_LONG_TEST_2',
        instruction: 'Identify the intonation pattern of this sentence.',
        difficulty: 1,
        subtype: GameSubtype.intonationMimic,
        word:
            'Could you please let me know if this meeting is still scheduled for this afternoon?',
        textToSpeak:
            'Could you please let me know if this meeting is still scheduled for this afternoon?',
        options: [
          'Rising energy, mild lift at the end — invites more conversation',
          'Low, flat fall at the end — closes the topic politely and firmly',
        ],
        correctAnswerIndex: 0,
        intonationMap: [1, 2, 3, 4],
        emotionContext: 'Polite Formal Request',
        hint: 'Listen closely.',
        explanation: 'Polite requests rise.',
      );

      await pumpIntonationMimic(
        tester,
        state: const AccentLoaded(
          quests: [longQuest],
          currentIndex: 0,
          livesRemaining: 3,
          answerStatus: AnswerStatus.unanswered,
          gameType: GameSubtype.intonationMimic,
          level: 2,
          hintUsed: false,
          wrongCount: 0,
          isFinalFailure: false,
        ),
      );

      // Verify prompt card text
      final wordFinder = find.text(longQuest.word!);
      expect(wordFinder, findsOneWidget);
      final wordWidget = tester.widget<Text>(wordFinder);
      expect(wordWidget.overflow, isNot(TextOverflow.ellipsis));
      expect(wordWidget.maxLines, isNull);

      // Verify options
      for (final option in longQuest.options!) {
        final optFinder = find.text(option);
        expect(optFinder, findsOneWidget);
        final optWidget = tester.widget<Text>(optFinder);
        expect(optWidget.overflow, isNot(TextOverflow.ellipsis));
        expect(optWidget.maxLines, isNull);
      }
      expect(tester.takeException(), isNull);
    });
  });
}
