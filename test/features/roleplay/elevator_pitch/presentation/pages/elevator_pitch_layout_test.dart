import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/core/presentation/widgets/game_briefing_layer.dart';
import 'package:vowl/core/presentation/widgets/quest_hint_button.dart';
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
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/features/roleplay/domain/entities/roleplay_quest.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_bloc.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_event.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_state.dart';
import 'package:vowl/features/roleplay/elevator_pitch/presentation/pages/elevator_pitch_screen.dart';

class MockRoleplayBloc extends MockBloc<RoleplayEvent, RoleplayState>
    implements RoleplayBloc {}

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

class MockNetworkInfo extends Mock implements NetworkInfo {}

class FakeRoleplayEvent extends Fake implements RoleplayEvent {}

class FakeRoleplayState extends Fake implements RoleplayState {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockRoleplayBloc mockRoleplayBloc;
  late MockAuthBloc mockAuthBloc;
  late MockEconomyBloc mockEconomyBloc;
  late MockHapticService mockHapticService;
  late MockSoundService mockSoundService;
  late MockTtsService mockTtsService;
  late MockSpeechService mockSpeechService;
  late MockAudioRecordingService mockAudioRecorder;
  late MockLocaleService mockLocaleService;
  late MockAppLogger mockAppLogger;
  late MockAnalyticsService mockAnalyticsService;
  late MockAdService mockAdService;
  late MockNetworkInfo mockNetworkInfo;
  late StreamController<RoleplayState> roleplayStreamController;

  const sampleQuest1 = RoleplayQuest(
    id: 'ep_1',
    instruction: 'Pitch your AI productivity tool.',
    difficulty: 1,
    subtype: GameSubtype.elevatorPitch,
    scene: 'You stepped into an elevator with a top venture capital partner.',
    prompt:
        'You have 30 seconds to pitch FlowState, an AI tool that eliminates context switching for developers.',
    timeLimit: 30,
    correctAnswer:
        'FlowState is an AI workspace that eliminates developer context switching by synthesizing meetings, code, and tickets into proactive daily actions, saving engineers two hours every day.',
    hint: 'Mention the concrete daily time saved.',
    explanation:
        'A strong hook with quantifiable time savings immediately captures investor attention.',
  );

  const sampleQuest2 = RoleplayQuest(
    id: 'ep_2',
    instruction: 'Pitch your clean-energy startup.',
    difficulty: 2,
    subtype: GameSubtype.elevatorPitch,
    scene: 'You meet an angel investor in the lobby.',
    prompt:
        'Pitch HelioGrid, a micro-inverter grid for high-density apartments.',
    timeLimit: 20,
    correctAnswer:
        'HelioGrid turns urban balcony spaces into localized solar micro-grids, lowering household electricity bills by thirty percent without requiring rooftop solar installation permissions.',
    hint: 'Emphasize that rooftop permissions are not needed.',
    explanation: 'Addressing regulatory hurdles upfront builds immediate trust.',
  );

  final testLoadedState = RoleplayLoaded(
    quests: const [sampleQuest1, sampleQuest2],
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
    hintUsed: false,
    gameType: GameSubtype.elevatorPitch,
    level: 2,
    wrongCount: 0,
    isFinalFailure: false,
  );

  setUpAll(() {
    registerFallbackValue(FakeRoleplayEvent());
    registerFallbackValue(FakeRoleplayState());
    registerFallbackValue(const SubmitAnswer(true));
    registerFallbackValue(const SubmitAnswer(false));
    registerFallbackValue(const NextQuestion());
    registerFallbackValue(const RoleplayHintUsed());
    registerFallbackValue(const RoleplaySpeakConfirmed(5));
    registerFallbackValue(const Duration(milliseconds: 50));
    registerFallbackValue(ListenMode.dictation);
    VowlMotion.lowAnimationModeOverride.value = true;
  });

  tearDownAll(() {
    VowlMotion.lowAnimationModeOverride.value = false;
  });

  setUp(() async {
    mockRoleplayBloc = MockRoleplayBloc();
    mockAuthBloc = MockAuthBloc();
    mockEconomyBloc = MockEconomyBloc();
    mockHapticService = MockHapticService();
    mockSoundService = MockSoundService();
    mockTtsService = MockTtsService();
    mockSpeechService = MockSpeechService();
    mockAudioRecorder = MockAudioRecordingService();
    mockLocaleService = MockLocaleService();
    mockAppLogger = MockAppLogger();
    mockAnalyticsService = MockAnalyticsService();
    mockAdService = MockAdService();
    mockNetworkInfo = MockNetworkInfo();

    roleplayStreamController = StreamController<RoleplayState>.broadcast();
    when(() => mockRoleplayBloc.stream)
        .thenAnswer((_) => roleplayStreamController.stream);
    when(() => mockRoleplayBloc.state).thenReturn(testLoadedState);

    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(
        const UserEntity(
          id: 'test_user',
          email: 'test@vowl.app',
          displayName: 'Test Explorer',
          isPremium: true,
          hintCount: 3,
        ),
      ),
    );

    when(() => mockEconomyBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockEconomyBloc.state).thenReturn(const EconomyState());

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});
    when(() => mockHapticService.heavy()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});

    when(() => mockSoundService.playCorrect()).thenAnswer((_) async {});
    when(() => mockSoundService.playWrong()).thenAnswer((_) async {});
    when(() => mockSoundService.playClick()).thenAnswer((_) async {});
    when(() => mockSoundService.playHint()).thenAnswer((_) async {});
    when(() => mockSoundService.playLevelComplete()).thenAnswer((_) async {});
    when(() => mockSoundService.stopAudio()).thenAnswer((_) async {});
    when(() => mockSoundService.stopTts()).thenAnswer((_) async {});
    when(() => mockSoundService.playTts(any())).thenAnswer((_) async {});

    when(() => mockTtsService.stop()).thenAnswer((_) async {});
    when(() => mockTtsService.speak(
      any(),
      rate: any(named: 'rate'),
      locale: any(named: 'locale'),
    )).thenAnswer((_) async {});

    when(() => mockSpeechService.initializeStt()).thenAnswer((_) async => true);
    when(() => mockSpeechService.stop()).thenAnswer((_) async {});
    when(() => mockSpeechService.cancel()).thenAnswer((_) async {});
    when(() => mockSpeechService.isListening).thenReturn(false);
    when(() => mockSpeechService.isPlaying).thenReturn(false);
    when(() => mockSpeechService.listen(
      onResult: any(named: 'onResult'),
      onDone: any(named: 'onDone'),
      onSoundLevelChange: any(named: 'onSoundLevelChange'),
      localeId: any(named: 'localeId'),
      pauseFor: any(named: 'pauseFor'),
      listenMode: any(named: 'listenMode'),
    )).thenAnswer((_) async {});

    when(() => mockAudioRecorder.hasPermission()).thenAnswer((_) async => true);
    when(() => mockAudioRecorder.startRecording()).thenAnswer((_) async => true);
    when(() => mockAudioRecorder.stopRecording())
        .thenAnswer((_) async => '/tmp/pitch_test.m4a');
    when(() => mockAudioRecorder.isRecording).thenReturn(false);
    when(() => mockAudioRecorder.onAmplitudeChanged(any()))
        .thenAnswer((_) => Stream.value(Amplitude(current: -10, max: -5)));
    when(() => mockAudioRecorder.dispose()).thenAnswer((_) async {});

    when(() => mockLocaleService.tr(
      any(),
      args: any(named: 'args'),
      fallback: any(named: 'fallback'),
    )).thenAnswer((invocation) {
      final fallback =
          invocation.namedArguments[const Symbol('fallback')] as String?;
      final key = invocation.positionalArguments[0] as String;
      return fallback ?? key;
    });

    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
    when(() => mockAnalyticsService.logSelfEvaluation(any()))
        .thenAnswer((_) async {});
    when(() => mockAnalyticsService.logGameSkipped(any()))
        .thenAnswer((_) async {});
    when(() => mockAnalyticsService.logPurchaseAttempt(any()))
        .thenAnswer((_) async {});

    SharedPreferences.setMockInitialValues({
      'has_seen_briefing_elevatorPitch': true,
    });

    if (di.sl.isRegistered<HapticService>()) di.sl.unregister<HapticService>();
    if (di.sl.isRegistered<SoundService>()) di.sl.unregister<SoundService>();
    if (di.sl.isRegistered<TtsService>()) di.sl.unregister<TtsService>();
    if (di.sl.isRegistered<SpeechService>()) di.sl.unregister<SpeechService>();
    if (di.sl.isRegistered<AudioRecordingService>()) {
      di.sl.unregister<AudioRecordingService>();
    }
    if (di.sl.isRegistered<LocaleService>()) di.sl.unregister<LocaleService>();
    if (di.sl.isRegistered<AppLogger>()) di.sl.unregister<AppLogger>();
    if (di.sl.isRegistered<AnalyticsService>()) {
      di.sl.unregister<AnalyticsService>();
    }
    if (di.sl.isRegistered<AdService>()) di.sl.unregister<AdService>();
    if (di.sl.isRegistered<NetworkInfo>()) di.sl.unregister<NetworkInfo>();

    di.sl.registerSingleton<HapticService>(mockHapticService);
    di.sl.registerSingleton<SoundService>(mockSoundService);
    di.sl.registerSingleton<TtsService>(mockTtsService);
    di.sl.registerSingleton<SpeechService>(mockSpeechService);
    di.sl.registerSingleton<AudioRecordingService>(mockAudioRecorder);
    di.sl.registerSingleton<LocaleService>(mockLocaleService);
    di.sl.registerSingleton<AppLogger>(mockAppLogger);
    di.sl.registerSingleton<AnalyticsService>(mockAnalyticsService);
    di.sl.registerSingleton<AdService>(mockAdService);
    di.sl.registerSingleton<NetworkInfo>(mockNetworkInfo);
  });

  tearDown(() async {
    await roleplayStreamController.close();
  });

  Future<void> pumpElevatorPitchScreen(
    WidgetTester tester, {
    RoleplayState? state,
    ThemeMode themeMode = ThemeMode.dark,
    Size size = const Size(390, 1400),
    int level = 2,
    bool reduceMotion = false,
  }) async {
    tester.view.physicalSize = Size(size.width * 2, size.height * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final resolvedState = state ?? testLoadedState;
    when(() => mockRoleplayBloc.state).thenReturn(resolvedState);
    if (!roleplayStreamController.isClosed) {
      roleplayStreamController.add(resolvedState);
    }

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<RoleplayBloc>.value(value: mockRoleplayBloc),
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<EconomyBloc>.value(value: mockEconomyBloc),
        ],
        child: ScreenUtilInit(
          designSize: size,
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) => MaterialApp(
            themeMode: themeMode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: MediaQuery(
              data: MediaQuery.of(context).copyWith(
                disableAnimations: reduceMotion,
              ),
              child: Scaffold(
                body: ElevatorPitchScreen(level: level),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('ElevatorPitchScreen Layout & Mechanics Tests', () {
    testWidgets('1. Initial layout renders prompt card, rocket icon, instruction text, prompt text, time limit badge, and recorder widget', (tester) async {
      await pumpElevatorPitchScreen(tester);

      expect(find.byKey(const Key('elevator_pitch_prompt_card')), findsOneWidget);
      expect(find.byKey(const Key('elevator_pitch_card_icon')), findsOneWidget);
      expect(find.byKey(const Key('elevator_pitch_instruction_text')), findsOneWidget);
      expect(find.byKey(const Key('elevator_pitch_prompt_text')), findsOneWidget);
      expect(find.byKey(const Key('elevator_pitch_timer_badge')), findsOneWidget);
      expect(find.byKey(const Key('elevator_pitch_recorder')), findsOneWidget);
    });

    testWidgets('2. Formatted instruction text displays uppercase instruction from quest', (tester) async {
      await pumpElevatorPitchScreen(tester);

      expect(find.text(sampleQuest1.instruction.toUpperCase()), findsOneWidget);
    });

    testWidgets('3. Prompt text rendering matches custom quest prompt', (tester) async {
      await pumpElevatorPitchScreen(tester);

      expect(find.text(sampleQuest1.prompt!), findsOneWidget);
    });

    testWidgets('4. Time limit badge displays formatted "{timeLimit} SECONDS LIMIT" with timer icon', (tester) async {
      await pumpElevatorPitchScreen(tester);

      expect(find.text('${sampleQuest1.timeLimit} SECONDS LIMIT'), findsOneWidget);
      expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
    });

    testWidgets('5. Default time limit fallback (30 seconds) renders when quest timeLimit is null', (tester) async {
      const nullLimitQuest = RoleplayQuest(
        id: 'ep_null',
        instruction: 'Pitch your AI productivity tool.',
        difficulty: 1,
        subtype: GameSubtype.elevatorPitch,
        scene: 'You stepped into an elevator with a top venture capital partner.',
        prompt: 'You have 30 seconds to pitch FlowState.',
        timeLimit: null,
        correctAnswer: 'FlowState is an AI workspace.',
      );
      final nullLimitState = testLoadedState.copyWith(
        quests: [nullLimitQuest],
      );
      await pumpElevatorPitchScreen(tester, state: nullLimitState);

      expect(find.text('30 SECONDS LIMIT'), findsOneWidget);
    });

    testWidgets('6. Recorder initial state (PitchState.ready) renders mic icon, "GET READY" header, instructions, "REFERENCE PITCH" box, and "START PITCH" button', (tester) async {
      await pumpElevatorPitchScreen(tester);

      expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);
      expect(find.text('GET READY'), findsOneWidget);
      expect(find.text('REFERENCE PITCH'), findsOneWidget);
      expect(find.byKey(const Key('elevator_pitch_start_button')), findsOneWidget);
      expect(find.text('START PITCH'), findsOneWidget);
    });

    testWidgets('7. "REFERENCE PITCH" box displays expectedText', (tester) async {
      await pumpElevatorPitchScreen(tester);

      expect(find.text(sampleQuest1.correctAnswer!), findsOneWidget);
    });

    testWidgets('8. Tapping "START PITCH" initializes STT, starts listening, triggers selection haptic, and transitions to PitchState.pitching', (tester) async {
      await pumpElevatorPitchScreen(tester);

      final startBtn = find.byKey(const Key('elevator_pitch_start_button'));
      expect(startBtn, findsOneWidget);
      await tester.tap(startBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockSpeechService.initializeStt()).called(1);
      verify(() => mockSpeechService.listen(
        onResult: any(named: 'onResult'),
        onDone: any(named: 'onDone'),
        onSoundLevelChange: any(named: 'onSoundLevelChange'),
        pauseFor: any(named: 'pauseFor'),
      )).called(1);
      verify(() => mockHapticService.selection()).called(1);

      expect(find.text('RECORDING...'), findsOneWidget);
      expect(find.byKey(const Key('elevator_pitch_countdown_timer')), findsOneWidget);
    });

    testWidgets('9. In PitchState.pitching, displays "RECORDING..." with red recording dot and initial countdown timer ("00:30")', (tester) async {
      await pumpElevatorPitchScreen(tester);

      await tester.tap(find.byKey(const Key('elevator_pitch_start_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const Key('elevator_pitch_recording_dot')), findsOneWidget);
      expect(find.text('00:30'), findsOneWidget);
    });

    testWidgets('10. In PitchState.pitching, countdown timer decrements every second', (tester) async {
      await pumpElevatorPitchScreen(tester);

      await tester.tap(find.byKey(const Key('elevator_pitch_start_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('00:30'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(find.text('00:29'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      expect(find.text('00:27'), findsOneWidget);
    });

    testWidgets('11. Microphone button renders with amplitude scale transformation based on sound level', (tester) async {
      Function(double)? soundLevelCallback;
      when(() => mockSpeechService.listen(
        onResult: any(named: 'onResult'),
        onDone: any(named: 'onDone'),
        onSoundLevelChange: any(named: 'onSoundLevelChange'),
        pauseFor: any(named: 'pauseFor'),
      )).thenAnswer((invocation) async {
        soundLevelCallback = invocation.namedArguments[const Symbol('onSoundLevelChange')]
            as Function(double)?;
      });

      await pumpElevatorPitchScreen(tester);

      await tester.tap(find.byKey(const Key('elevator_pitch_start_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const Key('elevator_pitch_mic_button')), findsOneWidget);

      // Simulate voice amplitude change to +20.0
      soundLevelCallback?.call(20.0);
      await tester.pump();

      expect(find.byIcon(Icons.mic), findsOneWidget);
    });

    testWidgets('12. Linear progress indicator reflects elapsed time / time limit progress', (tester) async {
      await pumpElevatorPitchScreen(tester);

      await tester.tap(find.byKey(const Key('elevator_pitch_start_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final progressBar = tester.widget<LinearProgressIndicator>(
        find.byKey(const Key('elevator_pitch_progress_bar')),
      );
      expect(progressBar.value, equals(0.0));

      await tester.pump(const Duration(seconds: 15));
      final halfwayBar = tester.widget<LinearProgressIndicator>(
        find.byKey(const Key('elevator_pitch_progress_bar')),
      );
      expect(halfwayBar.value, closeTo(0.5, 0.05));
    });

    testWidgets('13. Text "Tap the mic to finish early" is visible during recording', (tester) async {
      await pumpElevatorPitchScreen(tester);

      await tester.tap(find.byKey(const Key('elevator_pitch_start_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Tap the mic to finish early'), findsOneWidget);
    });

    testWidgets('14. Silence detection: receiving 12 silent sound levels (< -40.0) triggers _abortPitchDueToSilence, heavy haptic, and transitions to PitchState.failed', (tester) async {
      Function(double)? soundLevelCallback;
      when(() => mockSpeechService.listen(
        onResult: any(named: 'onResult'),
        onDone: any(named: 'onDone'),
        onSoundLevelChange: any(named: 'onSoundLevelChange'),
        pauseFor: any(named: 'pauseFor'),
      )).thenAnswer((invocation) async {
        soundLevelCallback = invocation.namedArguments[const Symbol('onSoundLevelChange')]
            as Function(double)?;
      });

      await pumpElevatorPitchScreen(tester);

      await tester.tap(find.byKey(const Key('elevator_pitch_start_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Feed 12 silent sound levels (< -40.0)
      for (int i = 0; i < 12; i++) {
        soundLevelCallback?.call(-45.0);
      }
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      verify(() => mockHapticService.heavy()).called(1);
      verify(() => mockSpeechService.stop()).called(1);

      expect(find.text('THE DOORS OPENED'), findsOneWidget);
      expect(find.text('You went silent. You lost their attention.'), findsOneWidget);
    });

    testWidgets('15. In PitchState.failed, displays door icon, "THE DOORS OPENED", explanation, and "CONTINUE" button', (tester) async {
      Function(double)? soundLevelCallback;
      when(() => mockSpeechService.listen(
        onResult: any(named: 'onResult'),
        onDone: any(named: 'onDone'),
        onSoundLevelChange: any(named: 'onSoundLevelChange'),
        pauseFor: any(named: 'pauseFor'),
      )).thenAnswer((invocation) async {
        soundLevelCallback = invocation.namedArguments[const Symbol('onSoundLevelChange')]
            as Function(double)?;
      });

      await pumpElevatorPitchScreen(tester);

      await tester.tap(find.byKey(const Key('elevator_pitch_start_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      for (int i = 0; i < 12; i++) {
        soundLevelCallback?.call(-45.0);
      }
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byIcon(Icons.sensor_door_outlined), findsOneWidget);
      expect(find.byKey(const Key('elevator_pitch_failed_continue_button')), findsOneWidget);
    });

    testWidgets('16. Tapping "CONTINUE" in PitchState.failed calls widget.onFailed -> submitWrongAnswer -> dispatches SubmitAnswer(false) with error sound & haptic', (tester) async {
      Function(double)? soundLevelCallback;
      when(() => mockSpeechService.listen(
        onResult: any(named: 'onResult'),
        onDone: any(named: 'onDone'),
        onSoundLevelChange: any(named: 'onSoundLevelChange'),
        pauseFor: any(named: 'pauseFor'),
      )).thenAnswer((invocation) async {
        soundLevelCallback = invocation.namedArguments[const Symbol('onSoundLevelChange')]
            as Function(double)?;
      });

      await pumpElevatorPitchScreen(tester);

      await tester.tap(find.byKey(const Key('elevator_pitch_start_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      for (int i = 0; i < 12; i++) {
        soundLevelCallback?.call(-45.0);
      }
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.byKey(const Key('elevator_pitch_failed_continue_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockRoleplayBloc.add(const SubmitAnswer(false))).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockHapticService.error()).called(1);
    });

    testWidgets('17. In PitchState.pitching, tapping microphone button finishes pitch early -> transitions to PitchState.evaluating', (tester) async {
      await pumpElevatorPitchScreen(tester);

      await tester.tap(find.byKey(const Key('elevator_pitch_start_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byKey(const Key('elevator_pitch_mic_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockHapticService.success()).called(1);
      verify(() => mockSpeechService.stop()).called(1);

      expect(find.byKey(const Key('elevator_pitch_ai_analysis_card')), findsOneWidget);
    });

    testWidgets('18. In PitchState.pitching, countdown timer reaching 0 automatically finishes pitch -> transitions to PitchState.evaluating', (tester) async {
      await pumpElevatorPitchScreen(tester);

      await tester.tap(find.byKey(const Key('elevator_pitch_start_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Advance timer by 31 seconds
      await tester.pump(const Duration(seconds: 31));
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockHapticService.success()).called(1);
      verify(() => mockSpeechService.stop()).called(1);

      expect(find.byKey(const Key('elevator_pitch_ai_analysis_card')), findsOneWidget);
    });

    testWidgets('19. In PitchState.evaluating, AI evaluation grading: when transcript meets fluency & vocabulary requirements, displays "PITCH SUCCESSFUL" in green', (tester) async {
      when(() => mockSpeechService.listen(
        onResult: any(named: 'onResult'),
        onDone: any(named: 'onDone'),
        onSoundLevelChange: any(named: 'onSoundLevelChange'),
        pauseFor: any(named: 'pauseFor'),
      )).thenAnswer((invocation) async {
        final onResult = invocation.namedArguments[const Symbol('onResult')]
            as Function(List<String>, bool);
        onResult(
          const [
            'FlowState is a workspace that eliminates developer context switching by saving engineers two hours every day.',
          ],
          true,
        );
      });

      await pumpElevatorPitchScreen(tester);

      await tester.tap(find.byKey(const Key('elevator_pitch_start_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byKey(const Key('elevator_pitch_mic_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('PITCH SUCCESSFUL'), findsOneWidget);
    });

    testWidgets('20. In PitchState.evaluating, AI evaluation grading: when transcript fails fluency or keywords requirements, displays "PITCH FAILED" in red', (tester) async {
      when(() => mockSpeechService.listen(
        onResult: any(named: 'onResult'),
        onDone: any(named: 'onDone'),
        onSoundLevelChange: any(named: 'onSoundLevelChange'),
        pauseFor: any(named: 'pauseFor'),
      )).thenAnswer((invocation) async {
        final onResult = invocation.namedArguments[const Symbol('onResult')]
            as Function(List<String>, bool);
        onResult(const ['Hello there.'], true);
      });

      await pumpElevatorPitchScreen(tester);

      await tester.tap(find.byKey(const Key('elevator_pitch_start_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byKey(const Key('elevator_pitch_mic_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('PITCH FAILED'), findsOneWidget);
    });

    testWidgets('21. AI Analysis card displays Fluency (word count) row with words count and pass/fail icon', (tester) async {
      when(() => mockSpeechService.listen(
        onResult: any(named: 'onResult'),
        onDone: any(named: 'onDone'),
        onSoundLevelChange: any(named: 'onSoundLevelChange'),
        pauseFor: any(named: 'pauseFor'),
      )).thenAnswer((invocation) async {
        final onResult = invocation.namedArguments[const Symbol('onResult')]
            as Function(List<String>, bool);
        onResult(
          const [
            'FlowState is a workspace that eliminates developer context switching by saving engineers two hours every day.',
          ],
          true,
        );
      });

      await pumpElevatorPitchScreen(tester);

      await tester.tap(find.byKey(const Key('elevator_pitch_start_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byKey(const Key('elevator_pitch_mic_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Fluency (Word Count)'), findsOneWidget);
      expect(find.text('16 words'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsAtLeastNWidgets(1));
    });

    testWidgets('22. AI Analysis card displays Vocabulary (keywords) row with keyword hit count and pass/fail icon', (tester) async {
      when(() => mockSpeechService.listen(
        onResult: any(named: 'onResult'),
        onDone: any(named: 'onDone'),
        onSoundLevelChange: any(named: 'onSoundLevelChange'),
        pauseFor: any(named: 'pauseFor'),
      )).thenAnswer((invocation) async {
        final onResult = invocation.namedArguments[const Symbol('onResult')]
            as Function(List<String>, bool);
        onResult(
          const [
            'FlowState is a workspace that eliminates developer context switching by saving engineers two hours every day.',
          ],
          true,
        );
      });

      await pumpElevatorPitchScreen(tester);

      await tester.tap(find.byKey(const Key('elevator_pitch_start_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byKey(const Key('elevator_pitch_mic_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Vocabulary (Keywords)'), findsOneWidget);
      expect(find.text('10 hits'), findsOneWidget);
    });

    testWidgets('23. In PitchState.evaluating, native example pitch row displays "Want to hear a perfect pitch?" and "LISTEN" button', (tester) async {
      await pumpElevatorPitchScreen(tester);

      await tester.tap(find.byKey(const Key('elevator_pitch_start_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byKey(const Key('elevator_pitch_mic_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Want to hear a perfect pitch?'), findsOneWidget);
      expect(find.byKey(const Key('elevator_pitch_listen_example_button')), findsOneWidget);
      expect(find.text('LISTEN'), findsOneWidget);
    });

    testWidgets('24. Tapping "LISTEN" button starts TTS playback of expectedText and toggles icon to stop_circle', (tester) async {
      final completer = Completer<void>();
      when(() => mockSoundService.playTts(sampleQuest1.correctAnswer!))
          .thenAnswer((_) => completer.future);

      await pumpElevatorPitchScreen(tester);

      await tester.tap(find.byKey(const Key('elevator_pitch_start_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byKey(const Key('elevator_pitch_mic_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final listenBtn = find.byKey(const Key('elevator_pitch_listen_example_button'));
      await tester.tap(listenBtn);
      await tester.pump();

      verify(() => mockSoundService.playTts(sampleQuest1.correctAnswer!)).called(1);
      expect(find.byIcon(Icons.stop_circle_rounded), findsOneWidget);

      completer.complete();
      await tester.pump();
    });

    testWidgets('25. Tapping "LISTEN" again while playing stops TTS playback and toggles back to play_arrow', (tester) async {
      final completer = Completer<void>();
      when(() => mockSoundService.playTts(sampleQuest1.correctAnswer!))
          .thenAnswer((_) => completer.future);

      await pumpElevatorPitchScreen(tester);

      await tester.tap(find.byKey(const Key('elevator_pitch_start_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byKey(const Key('elevator_pitch_mic_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final listenBtn = find.byKey(const Key('elevator_pitch_listen_example_button'));
      await tester.tap(listenBtn);
      await tester.pump();

      expect(find.byIcon(Icons.stop_circle_rounded), findsOneWidget);

      // Tap again to stop
      await tester.tap(listenBtn);
      await tester.pump();

      verify(() => mockSoundService.stopTts()).called(2);
      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

      completer.complete();
      await tester.pump();
    });

    testWidgets('26. In PitchState.evaluating, when pitch was successful, tapping "CONTINUE" dispatches RoleplaySpeakConfirmed(5) bonus coins and SubmitAnswer(true) with success sound & haptic', (tester) async {
      when(() => mockSpeechService.listen(
        onResult: any(named: 'onResult'),
        onDone: any(named: 'onDone'),
        onSoundLevelChange: any(named: 'onSoundLevelChange'),
        pauseFor: any(named: 'pauseFor'),
      )).thenAnswer((invocation) async {
        final onResult = invocation.namedArguments[const Symbol('onResult')]
            as Function(List<String>, bool);
        onResult(
          const [
            'FlowState is a workspace that eliminates developer context switching by saving engineers two hours every day.',
          ],
          true,
        );
      });

      await pumpElevatorPitchScreen(tester);

      await tester.tap(find.byKey(const Key('elevator_pitch_start_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byKey(const Key('elevator_pitch_mic_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.byKey(const Key('elevator_pitch_evaluating_continue_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockRoleplayBloc.add(const RoleplaySpeakConfirmed(5))).called(1);
      verify(() => mockRoleplayBloc.add(const SubmitAnswer(true))).called(1);
      verify(() => mockSoundService.playCorrect()).called(1);
      verify(() => mockHapticService.success()).called(greaterThanOrEqualTo(1));
    });

    testWidgets('27. In PitchState.evaluating, when pitch failed, tapping "CONTINUE" dispatches SubmitAnswer(false) with error sound & haptic', (tester) async {
      when(() => mockSpeechService.listen(
        onResult: any(named: 'onResult'),
        onDone: any(named: 'onDone'),
        onSoundLevelChange: any(named: 'onSoundLevelChange'),
        pauseFor: any(named: 'pauseFor'),
      )).thenAnswer((invocation) async {
        final onResult = invocation.namedArguments[const Symbol('onResult')]
            as Function(List<String>, bool);
        onResult(const ['Short pitch.'], true);
      });

      await pumpElevatorPitchScreen(tester);

      await tester.tap(find.byKey(const Key('elevator_pitch_start_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byKey(const Key('elevator_pitch_mic_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.byKey(const Key('elevator_pitch_evaluating_continue_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockRoleplayBloc.add(const SubmitAnswer(false))).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockHapticService.error()).called(1);
    });

    testWidgets('28. In answered state, ElevatorPitchRecorder unmounts and bottom bar CONTINUE button appears; tapping it dispatches NextQuestion', (tester) async {
      await pumpElevatorPitchScreen(tester);

      final answeredState = testLoadedState.copyWith(
        answerStatus: AnswerStatus.correct,
      );
      when(() => mockRoleplayBloc.state).thenReturn(answeredState);
      roleplayStreamController.add(answeredState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byKey(const Key('elevator_pitch_recorder')), findsNothing);

      final continueBtn = find.text('CONTINUE');
      expect(continueBtn, findsOneWidget);
      await tester.tap(continueBtn);
      await tester.pump();

      verify(() => mockRoleplayBloc.add(any(that: isA<NextQuestion>()))).called(1);
    });

    testWidgets('29. Question transition: when next quest loads, recorder resets, prompt updates, and stage is clean', (tester) async {
      await pumpElevatorPitchScreen(tester);

      // Advance to quest 2
      final nextQuestState = testLoadedState.copyWith(
        currentIndex: 1,
        answerStatus: AnswerStatus.unanswered,
      );
      when(() => mockRoleplayBloc.state).thenReturn(nextQuestState);
      roleplayStreamController.add(nextQuestState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text(sampleQuest2.prompt!), findsOneWidget);
      expect(find.text('${sampleQuest2.timeLimit} SECONDS LIMIT'), findsOneWidget);
      expect(find.byKey(const Key('elevator_pitch_start_button')), findsOneWidget);
    });

    testWidgets('30. Hint button in header dispatches selection haptic and RoleplayHintUsed', (tester) async {
      await pumpElevatorPitchScreen(tester);

      final hintButton = find.byType(QuestHintButton);
      expect(hintButton, findsOneWidget);
      await tester.tap(hintButton);
      await tester.pump();

      verify(() => mockHapticService.selection()).called(1);
      verify(() => mockRoleplayBloc.add(any(that: isA<RoleplayHintUsed>()))).called(1);
    });

    testWidgets('31. Level 1 briefing layer displays PITCH PERFECT and dismisses on START PITCH tap', (tester) async {
      SharedPreferences.setMockInitialValues({
        'has_seen_briefing_elevatorPitch': false,
      });

      await pumpElevatorPitchScreen(
        tester,
        level: 1,
        size: const Size(390, 1400),
      );

      expect(find.byType(GameBriefingLayer), findsOneWidget);
      expect(find.text('PITCH PERFECT'), findsOneWidget);

      final enterBtn = find.descendant(
        of: find.byType(GameBriefingLayer),
        matching: find.text('START PITCH'),
      );
      expect(enterBtn, findsOneWidget);
      await tester.tap(enterBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(GameBriefingLayer), findsNothing);
    });

    testWidgets('32. GameShimmerLoading displays on initial/loading state', (tester) async {
      await pumpElevatorPitchScreen(tester, state: const RoleplayInitial());

      expect(find.byType(GameShimmerLoading), findsOneWidget);
    });

    testWidgets('33. Game over state renders cleanly without error', (tester) async {
      const gameOverState = RoleplayGameOver(
        quests: [sampleQuest1],
        currentIndex: 0,
        gameType: GameSubtype.elevatorPitch,
        level: 2,
      );
      await pumpElevatorPitchScreen(tester, state: gameOverState);

      expect(find.byType(ElevatorPitchScreen), findsOneWidget);
    });

    testWidgets('34. Dark and light themes render cleanly without errors', (tester) async {
      await pumpElevatorPitchScreen(tester, themeMode: ThemeMode.light);
      expect(find.byType(ElevatorPitchScreen), findsOneWidget);

      await pumpElevatorPitchScreen(tester, themeMode: ThemeMode.dark);
      expect(find.byType(ElevatorPitchScreen), findsOneWidget);
    });

    testWidgets('35. Small mobile screen (320x568) and tablet viewport (768x1024) render cleanly with zero overflow', (tester) async {
      await pumpElevatorPitchScreen(tester, size: const Size(320, 568));
      expect(find.byType(ElevatorPitchScreen), findsOneWidget);
      expect(tester.takeException(), isNull);

      await pumpElevatorPitchScreen(tester, size: const Size(768, 1024));
      expect(find.byType(ElevatorPitchScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('36. Reduced motion mode suppresses repeating animations on recording red dot', (tester) async {
      await pumpElevatorPitchScreen(tester, reduceMotion: true);

      await tester.tap(find.byKey(const Key('elevator_pitch_start_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const Key('elevator_pitch_recording_dot')), findsOneWidget);
    });
  });
}

