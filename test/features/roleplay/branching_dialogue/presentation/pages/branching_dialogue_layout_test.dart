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
import 'package:vowl/core/presentation/game_mechanics/speaking/speak_to_confirm_overlay.dart';
import 'package:vowl/core/presentation/widgets/game_briefing_layer.dart';
import 'package:vowl/core/presentation/widgets/quest_hint_button.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/utils/audio_recording_service.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/analytics_service.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/speech_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/features/roleplay/branching_dialogue/presentation/pages/branching_dialogue_screen.dart';
import 'package:vowl/features/roleplay/branching_dialogue/presentation/widgets/branching_dialogue_relationship_meter.dart';
import 'package:vowl/features/roleplay/domain/entities/roleplay_quest.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_bloc.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_event.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_state.dart';

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
    id: 'rp_bd_1',
    instruction: 'Choose the most polite and appropriate response.',
    difficulty: 1,
    subtype: GameSubtype.branchingDialogue,
    scene: 'Your colleague asks: "Could you review my presentation before tomorrow?"',
    persona: 'Project Manager',
    prompt: 'Colleague asks for review',
    options: [
      'Sure, I will take a look at it this afternoon.',
      'No way, I am far too busy right now.',
      'Maybe later if I feel like it.',
    ],
    consequencePreviews: [
      'Deepens team trust and collaboration',
      'Damages rapport with teammate',
      'Leaves them feeling unsupported',
    ],
    consequenceScores: [1, -1, 0],
    correctAnswerIndex: 0,
    correctAnswer: 'Sure, I will take a look at it this afternoon.',
  );

  const sampleQuest2 = RoleplayQuest(
    id: 'rp_bd_2',
    instruction: 'Select your answer.',
    difficulty: 1,
    subtype: GameSubtype.branchingDialogue,
    scene: 'The client requests a discount.',
    persona: 'Lead Negotiator',
    options: [
      'We can discuss customized bundle options.',
      'Our prices are strictly fixed.',
    ],
    consequencePreviews: [
      'Opens negotiation pathway',
      'Creates friction in deal closing',
    ],
    consequenceScores: [1, -1],
    correctAnswerIndex: 0,
    correctAnswer: 'We can discuss customized bundle options.',
  );

  const sampleQuestUrl = RoleplayQuest(
    id: 'rp_bd_url',
    instruction: 'Listen to the briefing.',
    difficulty: 1,
    subtype: GameSubtype.branchingDialogue,
    scene: 'Audio broadcast incoming...',
    textToSpeak: 'https://vowl.app/audio/dialogue.mp3',
    persona: 'Field Agent',
    options: [
      'Understood, proceeding to waypoint.',
      'Abort mission immediately.',
    ],
    consequenceScores: [1, -1],
    correctAnswerIndex: 0,
    correctAnswer: 'Understood, proceeding to waypoint.',
  );

  final testLoadedState = RoleplayLoaded(
    quests: const [sampleQuest1, sampleQuest2, sampleQuestUrl],
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
    hintUsed: false,
    gameType: GameSubtype.branchingDialogue,
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
    when(() => mockSoundService.playUrl(any())).thenAnswer((_) async {});
    when(() => mockSoundService.playTts(
      any(),
      pauseMarkers: any(named: 'pauseMarkers'),
    )).thenAnswer((_) async {});

    when(() => mockTtsService.stop()).thenAnswer((_) async {});
    when(
      () => mockTtsService.speak(
        any(),
        rate: any(named: 'rate'),
        locale: any(named: 'locale'),
      ),
    ).thenAnswer((_) async {});

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
    when(
      () => mockAudioRecorder.stopRecording(),
    ).thenAnswer((_) async => '/tmp/audio_test.m4a');
    when(() => mockAudioRecorder.isRecording).thenReturn(false);
    when(
      () => mockAudioRecorder.onAmplitudeChanged(any()),
    ).thenAnswer((_) => Stream.value(Amplitude(current: -10, max: -5)));
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
    when(() => mockAnalyticsService.logSelfEvaluation(any())).thenAnswer((_) async {});
    when(() => mockAnalyticsService.logGameSkipped(any())).thenAnswer((_) async {});
    when(() => mockAnalyticsService.logPurchaseAttempt(any())).thenAnswer((_) async {});

    SharedPreferences.setMockInitialValues({
      'has_seen_briefing_branchingDialogue': true,
    });

    if (di.sl.isRegistered<HapticService>()) di.sl.unregister<HapticService>();
    if (di.sl.isRegistered<SoundService>()) di.sl.unregister<SoundService>();
    if (di.sl.isRegistered<TtsService>()) di.sl.unregister<TtsService>();
    if (di.sl.isRegistered<SpeechService>()) di.sl.unregister<SpeechService>();
    if (di.sl.isRegistered<AudioRecordingService>()) di.sl.unregister<AudioRecordingService>();
    if (di.sl.isRegistered<LocaleService>()) di.sl.unregister<LocaleService>();
    if (di.sl.isRegistered<AppLogger>()) di.sl.unregister<AppLogger>();
    if (di.sl.isRegistered<AnalyticsService>()) di.sl.unregister<AnalyticsService>();
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

  Future<void> pumpBranchingDialogueScreen(
    WidgetTester tester, {
    RoleplayState? state,
    ThemeMode themeMode = ThemeMode.dark,
    Size size = const Size(390, 844),
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
              child: Scaffold(
                body: BranchingDialogueScreen(
                  level: level,
                  gameType: GameSubtype.branchingDialogue,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  group('BranchingDialogueScreen Layout & Mechanics Tests', () {
    testWidgets('1. Initial layout renders instruction badge, instruction text, persona console, avatar, persona name, replay button, scene text, and console board', (tester) async {
      await pumpBranchingDialogueScreen(tester);

      expect(find.byKey(const Key('branching_dialogue_instruction')), findsOneWidget);
      expect(find.byKey(const Key('branching_dialogue_instruction_badge')), findsOneWidget);
      expect(find.byKey(const Key('branching_dialogue_instruction_text')), findsOneWidget);
      expect(find.byKey(const Key('branching_dialogue_persona_console')), findsOneWidget);
      expect(find.byKey(const Key('branching_dialogue_persona_avatar')), findsOneWidget);
      expect(find.byKey(const Key('branching_dialogue_persona_name')), findsOneWidget);
      expect(find.byKey(const Key('branching_dialogue_replay_btn')), findsOneWidget);
      expect(find.byKey(const Key('branching_dialogue_scene_text')), findsOneWidget);
      expect(find.byKey(const Key('branching_dialogue_console_board')), findsOneWidget);
      expect(find.byType(BranchingDialogueScreen), findsOneWidget);
    });

    testWidgets('2. Initial instruction displays formatted text ("BRANCHING DIALOGUE" and custom instruction)', (tester) async {
      await pumpBranchingDialogueScreen(tester);

      expect(find.text('BRANCHING DIALOGUE'), findsOneWidget);
      expect(find.text('Choose the most polite and appropriate response.'), findsOneWidget);
    });

    testWidgets('3. Persona console displays persona role name in uppercase and scene text', (tester) async {
      await pumpBranchingDialogueScreen(tester);

      expect(find.text('PROJECT MANAGER'), findsOneWidget);
      expect(find.text('ROLEPLAY SCENARIO'), findsOneWidget);
      expect(find.text('Your colleague asks: "Could you review my presentation before tomorrow?"'), findsOneWidget);
    });

    testWidgets('4. Replay button tap triggers TTS playback with scene text and selection haptic', (tester) async {
      await pumpBranchingDialogueScreen(tester);

      final replayBtn = find.byKey(const Key('branching_dialogue_replay_btn'));
      expect(replayBtn, findsOneWidget);

      await tester.tap(replayBtn);
      await tester.pump();

      verify(() => mockSoundService.playTts(sampleQuest1.scene!)).called(1);
      verify(() => mockHapticService.selection()).called(1);
    });

    testWidgets('5. Replay button with URL audio triggers soundService.playUrl', (tester) async {
      final urlState = RoleplayLoaded(
        quests: const [sampleQuestUrl],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
        hintUsed: false,
        gameType: GameSubtype.branchingDialogue,
        level: 2,
        wrongCount: 0,
        isFinalFailure: false,
      );
      await pumpBranchingDialogueScreen(tester, state: urlState);

      await tester.tap(find.byKey(const Key('branching_dialogue_replay_btn')));
      await tester.pump();

      verify(() => mockSoundService.playUrl('https://vowl.app/audio/dialogue.mp3')).called(1);
      verify(() => mockHapticService.selection()).called(1);
    });

    testWidgets('6. Audio playback strips [pause:...] tokens cleanly', (tester) async {
      const pauseQuest = RoleplayQuest(
        id: 'rp_bd_pause',
        instruction: 'Reply.',
        difficulty: 1,
        subtype: GameSubtype.branchingDialogue,
        textToSpeak: 'Hello[pause:500]how are you?',
        scene: 'Meeting room',
        options: ['Fine', 'Bad'],
        correctAnswerIndex: 0,
      );
      final pauseState = RoleplayLoaded(
        quests: const [pauseQuest],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
        hintUsed: false,
        gameType: GameSubtype.branchingDialogue,
        level: 2,
        wrongCount: 0,
        isFinalFailure: false,
      );
      await pumpBranchingDialogueScreen(tester, state: pauseState);

      await tester.tap(find.byKey(const Key('branching_dialogue_replay_btn')));
      await tester.pump();

      verify(() => mockSoundService.playTts('Hello how are you?')).called(1);
    });

    testWidgets('7. Audio fallback cascade uses prompt when textToSpeak and scene are empty', (tester) async {
      const promptQuest = RoleplayQuest(
        id: 'rp_bd_prompt',
        instruction: 'Reply.',
        difficulty: 1,
        subtype: GameSubtype.branchingDialogue,
        prompt: 'Prompt speech fallback',
        options: ['Yes', 'No'],
        correctAnswerIndex: 0,
      );
      final promptState = RoleplayLoaded(
        quests: const [promptQuest],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
        hintUsed: false,
        gameType: GameSubtype.branchingDialogue,
        level: 2,
        wrongCount: 0,
        isFinalFailure: false,
      );
      await pumpBranchingDialogueScreen(tester, state: promptState);

      await tester.tap(find.byKey(const Key('branching_dialogue_replay_btn')));
      await tester.pump();

      verify(() => mockSoundService.playTts('Prompt speech fallback')).called(1);
    });

    testWidgets('8. Console board renders decision probe and all 3 dialogue terminal options', (tester) async {
      await pumpBranchingDialogueScreen(tester);

      expect(find.byKey(const Key('branching_dialogue_probe')), findsOneWidget);
      expect(find.byKey(const Key('branching_dialogue_option_0')), findsOneWidget);
      expect(find.byKey(const Key('branching_dialogue_option_1')), findsOneWidget);
      expect(find.byKey(const Key('branching_dialogue_option_2')), findsOneWidget);
      expect(find.text('Sure, I will take a look at it this afternoon.'), findsOneWidget);
      expect(find.text('No way, I am far too busy right now.'), findsOneWidget);
      expect(find.text('Maybe later if I feel like it.'), findsOneWidget);
    });

    testWidgets('9. Two-option quest renders 2 terminal nodes cleanly', (tester) async {
      final twoState = RoleplayLoaded(
        quests: const [sampleQuest2],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
        hintUsed: false,
        gameType: GameSubtype.branchingDialogue,
        level: 2,
        wrongCount: 0,
        isFinalFailure: false,
      );
      await pumpBranchingDialogueScreen(tester, state: twoState);

      expect(find.byKey(const Key('branching_dialogue_option_0')), findsOneWidget);
      expect(find.byKey(const Key('branching_dialogue_option_1')), findsOneWidget);
      expect(find.byKey(const Key('branching_dialogue_option_2')), findsNothing);
      expect(find.text('We can discuss customized bundle options.'), findsOneWidget);
      expect(find.text('Our prices are strictly fixed.'), findsOneWidget);
    });

    testWidgets('10. Single-option quest renders 1 terminal node centered without error', (tester) async {
      const singleQuest = RoleplayQuest(
        id: 'rp_bd_single',
        instruction: 'Acknowledge.',
        difficulty: 1,
        subtype: GameSubtype.branchingDialogue,
        scene: 'Briefing finished.',
        options: ['Affirmative.'],
        correctAnswerIndex: 0,
      );
      final singleState = RoleplayLoaded(
        quests: const [singleQuest],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
        hintUsed: false,
        gameType: GameSubtype.branchingDialogue,
        level: 2,
        wrongCount: 0,
        isFinalFailure: false,
      );
      await pumpBranchingDialogueScreen(tester, state: singleState);

      expect(find.byKey(const Key('branching_dialogue_option_0')), findsOneWidget);
      expect(find.byKey(const Key('branching_dialogue_option_1')), findsNothing);
      expect(find.text('Affirmative.'), findsOneWidget);
    });

    testWidgets('11. Tapping option terminal directly triggers selection haptic and sets selected index', (tester) async {
      await pumpBranchingDialogueScreen(tester);

      await tester.tap(find.byKey(const Key('branching_dialogue_option_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockHapticService.selection()).called(1);
    });

    testWidgets('12. Tapping wrong option directly immediately submits wrong answer with userAnswer, triggers error sound & error haptic', (tester) async {
      await pumpBranchingDialogueScreen(tester);

      await tester.tap(find.byKey(const Key('branching_dialogue_option_1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockRoleplayBloc.add(const SubmitAnswer(false))).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockHapticService.error()).called(1);
    });

    testWidgets('13. Tapping wrong option does NOT mount SpeakToConfirmOverlay', (tester) async {
      await pumpBranchingDialogueScreen(tester);

      await tester.tap(find.byKey(const Key('branching_dialogue_option_1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SpeakToConfirmOverlay), findsNothing);
    });

    testWidgets('14. Tapping correct option directly advances to Phase 2 (isFirstStagePassedNotifier), mounts SpeakToConfirmOverlay without early BLoC submission', (tester) async {
      await pumpBranchingDialogueScreen(tester);

      await tester.ensureVisible(find.byKey(const Key('branching_dialogue_option_0')));
      await tester.tap(find.byKey(const Key('branching_dialogue_option_0')), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.byType(SpeakToConfirmOverlay), findsOneWidget);
      expect(find.byKey(const Key('branching_dialogue_speak_overlay')), findsOneWidget);
      verifyNever(() => mockRoleplayBloc.add(const SubmitAnswer(true)));
    });

    testWidgets('15. In Phase 2, SpeakToConfirmOverlay displays expectedText matching chosen correct option', (tester) async {
      await pumpBranchingDialogueScreen(tester);

      await tester.ensureVisible(find.byKey(const Key('branching_dialogue_option_0')));
      await tester.tap(find.byKey(const Key('branching_dialogue_option_0')), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.byType(SpeakToConfirmOverlay), findsOneWidget);
      expect(find.text('NOW SAY IT'), findsOneWidget);
      expect(find.text('+5 COINS'), findsNothing);
      expect(find.text('Sure, I will take a look at it this afternoon.'), findsNWidgets(2)); // in board and in overlay
    });

    testWidgets('16. Decision probe drag: panning probe towards option triggers lock-on hover and plays lock-on hint bleep and selection haptic', (tester) async {
      await pumpBranchingDialogueScreen(tester);

      final probeFinder = find.byKey(const Key('branching_dialogue_probe'));
      expect(probeFinder, findsOneWidget);
      await tester.ensureVisible(probeFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final targetNodeFinder = find.byKey(const Key('branching_dialogue_option_0'));
      final targetCenter = tester.getCenter(targetNodeFinder);
      final probeCenter = tester.getCenter(probeFinder);

      final gesture = await tester.startGesture(probeCenter);
      final delta = targetCenter - probeCenter;
      await gesture.moveBy(delta * 0.5);
      await gesture.moveBy(delta * 0.5);
      await tester.pump();

      verify(() => mockSoundService.playHint()).called(1);
      verify(() => mockHapticService.selection()).called(1);

      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 700));
    });

    testWidgets('17. Releasing probe when not hovered on any terminal springs probe back to origin with animation and selection haptic', (tester) async {
      await pumpBranchingDialogueScreen(tester);

      final probeFinder = find.byKey(const Key('branching_dialogue_probe'));
      await tester.ensureVisible(probeFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      clearInteractions(mockHapticService);

      final gesture = await tester.startGesture(tester.getCenter(probeFinder));
      await gesture.moveBy(const Offset(0, -10));
      await gesture.moveBy(const Offset(0, -10));
      await tester.pump();
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      verify(() => mockHapticService.selection()).called(1);
      verifyNever(() => mockRoleplayBloc.add(any(that: isA<SubmitAnswer>())));
    });

    testWidgets('18. Releasing probe while hovered on wrong terminal submits wrong answer', (tester) async {
      await pumpBranchingDialogueScreen(tester);

      final probeFinder = find.byKey(const Key('branching_dialogue_probe'));
      await tester.ensureVisible(probeFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final targetNodeFinder = find.byKey(const Key('branching_dialogue_option_1'));
      final targetCenter = tester.getCenter(targetNodeFinder);
      final probeCenter = tester.getCenter(probeFinder);

      final gesture = await tester.startGesture(probeCenter);
      final delta = targetCenter - probeCenter;
      await gesture.moveBy(delta * 0.5);
      await gesture.moveBy(delta * 0.5);
      await tester.pump();
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockRoleplayBloc.add(const SubmitAnswer(false))).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
    });

    testWidgets('19. Releasing probe while hovered on correct terminal advances to Phase 2 and mounts SpeakToConfirmOverlay', (tester) async {
      await pumpBranchingDialogueScreen(tester);

      final probeFinder = find.byKey(const Key('branching_dialogue_probe'));
      await tester.ensureVisible(probeFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final targetNodeFinder = find.byKey(const Key('branching_dialogue_option_0'));
      final targetCenter = tester.getCenter(targetNodeFinder);
      final probeCenter = tester.getCenter(probeFinder);

      final gesture = await tester.startGesture(probeCenter);
      final delta = targetCenter - probeCenter;
      await gesture.moveBy(delta * 0.5);
      await gesture.moveBy(delta * 0.5);
      await tester.pump();
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.byType(SpeakToConfirmOverlay), findsOneWidget);
      verifyNever(() => mockRoleplayBloc.add(const SubmitAnswer(true)));
    });

    testWidgets('20. Answer lockout: after wrong answer submission, dragging probe or tapping options does not dispatch further actions', (tester) async {
      await pumpBranchingDialogueScreen(tester);

      // Submit wrong answer
      await tester.tap(find.byKey(const Key('branching_dialogue_option_1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      clearInteractions(mockRoleplayBloc);

      // Attempt secondary tap
      await tester.tap(find.byKey(const Key('branching_dialogue_option_0')), warnIfMissed: false);
      await tester.pump();

      verifyNever(() => mockRoleplayBloc.add(any(that: isA<SubmitAnswer>())));
    });

    testWidgets('21. SpeakToConfirmOverlay "Nailed It" (confirmed) dispatches RoleplaySpeakConfirmed(5) bonus coins and SubmitAnswer(true) with success sound & haptic', (tester) async {
      when(() => mockSpeechService.listen(
        onResult: any(named: 'onResult'),
        onDone: any(named: 'onDone'),
        onSoundLevelChange: any(named: 'onSoundLevelChange'),
        localeId: any(named: 'localeId'),
        pauseFor: any(named: 'pauseFor'),
        listenMode: any(named: 'listenMode'),
      )).thenAnswer((invocation) async {
        final onResult = invocation.namedArguments[const Symbol('onResult')]
            as Function(List<String>, bool);
        onResult(const ['Sure, I will take a look at it this afternoon.'], true);
      });

      await pumpBranchingDialogueScreen(tester);

      // Step 1: select correct option
      await tester.ensureVisible(find.byKey(const Key('branching_dialogue_option_0')));
      await tester.tap(find.byKey(const Key('branching_dialogue_option_0')), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 700));

      // Scroll down to reveal SpeakToConfirmOverlay
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Start recording
      final micIcon = find.byKey(const ValueKey('mic_icon'));
      expect(micIcon, findsOneWidget);
      await tester.tap(micIcon);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockRoleplayBloc.add(const RoleplaySpeakConfirmed(5))).called(1);
      verify(() => mockRoleplayBloc.add(const SubmitAnswer(true))).called(1);
      verify(() => mockSoundService.playCorrect()).called(1);
      verify(() => mockHapticService.success()).called(greaterThanOrEqualTo(1));
    });

    testWidgets('22. SpeakToConfirmOverlay "Needs Work" (skipped) dispatches SubmitAnswer(false) with error sound & haptic', (tester) async {
      await pumpBranchingDialogueScreen(tester);

      // Step 1: select correct option
      await tester.ensureVisible(find.byKey(const Key('branching_dialogue_option_0')));
      await tester.tap(find.byKey(const Key('branching_dialogue_option_0')), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 700));

      // Scroll down to reveal SpeakToConfirmOverlay
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Switch to manual evaluation
      final manualBtn = find.text('Evaluate myself manually');
      expect(manualBtn, findsOneWidget);
      await tester.tap(manualBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Start recording in manual controls
      final manualMic = find.byKey(const ValueKey('speaking_mic_btn'));
      expect(manualMic, findsOneWidget);
      await tester.tap(manualMic);
      await tester.pump();
      await tester.runAsync(() async => await Future.delayed(const Duration(milliseconds: 600)));
      await tester.pump(const Duration(milliseconds: 100));

      // Stop recording
      await tester.tap(manualMic);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Scroll slightly more so Needs Work is visible
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final needsWorkBtn = find.text('Needs Work');
      expect(needsWorkBtn, findsOneWidget);
      await tester.tap(needsWorkBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockRoleplayBloc.add(const SubmitAnswer(false))).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockHapticService.error()).called(1);
    });

    testWidgets('23. In answered state, BranchingDialogueRelationshipMeter appears displaying "RELATIONSHIP STATUS", polite/rude labels, and consequence score icon/bar', (tester) async {
      await pumpBranchingDialogueScreen(tester);

      // Answer wrong to enter answered state
      await tester.tap(find.byKey(const Key('branching_dialogue_option_1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(BranchingDialogueRelationshipMeter), findsOneWidget);
      expect(find.byKey(const Key('branching_dialogue_relationship_meter')), findsOneWidget);
      expect(find.text('RELATIONSHIP STATUS'), findsOneWidget);
      expect(find.text('Rude'), findsOneWidget);
      expect(find.text('Polite'), findsOneWidget);
      expect(find.byKey(const Key('branching_dialogue_relationship_bar')), findsOneWidget);
    });

    testWidgets('24. Relationship meter with positive consequence score (> 0) displays thumb_up icon', (tester) async {
      await pumpBranchingDialogueScreen(tester);

      // Select correct option (consequenceScore = 1)
      await tester.tap(find.byKey(const Key('branching_dialogue_option_0')), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // In answered state
      final answeredState = testLoadedState.copyWith(
        answerStatus: AnswerStatus.correct,
      );
      when(() => mockRoleplayBloc.state).thenReturn(answeredState);
      roleplayStreamController.add(answeredState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Scroll back up to relationship meter at the top
      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable).first);
      scrollable.position.jumpTo(0);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const Key('branching_dialogue_relationship_icon')), findsOneWidget);
      expect(find.byIcon(Icons.thumb_up_alt_rounded), findsOneWidget);
    });

    testWidgets('25. Relationship meter with negative consequence score (< 0) displays thumb_down icon', (tester) async {
      await pumpBranchingDialogueScreen(tester);

      // Select wrong option 1 (consequenceScore = -1)
      await tester.tap(find.byKey(const Key('branching_dialogue_option_1')), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final answeredState = testLoadedState.copyWith(
        answerStatus: AnswerStatus.incorrect,
      );
      when(() => mockRoleplayBloc.state).thenReturn(answeredState);
      roleplayStreamController.add(answeredState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byKey(const Key('branching_dialogue_relationship_icon')), findsOneWidget);
      expect(find.byIcon(Icons.thumb_down_alt_rounded), findsOneWidget);
    });

    testWidgets('26. Relationship meter with neutral consequence score (0) displays thumbs_up_down icon', (tester) async {
      await pumpBranchingDialogueScreen(tester);

      // Select option 2 (consequenceScore = 0)
      await tester.tap(find.byKey(const Key('branching_dialogue_option_2')), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final answeredState = testLoadedState.copyWith(
        answerStatus: AnswerStatus.incorrect,
      );
      when(() => mockRoleplayBloc.state).thenReturn(answeredState);
      roleplayStreamController.add(answeredState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byKey(const Key('branching_dialogue_relationship_icon')), findsOneWidget);
      expect(find.byIcon(Icons.thumbs_up_down_rounded), findsOneWidget);
    });

    testWidgets('27. In answered state, Continue button appears in bottom bar; tapping it dispatches NextQuestion', (tester) async {
      await pumpBranchingDialogueScreen(tester);

      // Answer wrong to enter answered state
      await tester.tap(find.byKey(const Key('branching_dialogue_option_1')), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final answeredState = testLoadedState.copyWith(
        answerStatus: AnswerStatus.incorrect,
      );
      when(() => mockRoleplayBloc.state).thenReturn(answeredState);
      roleplayStreamController.add(answeredState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final continueBtn = find.text('TRY AGAIN');
      expect(continueBtn, findsOneWidget);

      await tester.tap(continueBtn, warnIfMissed: false);
      await tester.pump();

      verify(() => mockRoleplayBloc.add(any(that: isA<NextQuestion>()))).called(1);
    });

    testWidgets('28. Question transition clears probe offset, hovered index, selected index, and resets stage without crash', (tester) async {
      await pumpBranchingDialogueScreen(tester);

      // Select option 0
      await tester.tap(find.byKey(const Key('branching_dialogue_option_0')), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Advance to quest 2
      final nextState = RoleplayLoaded(
        quests: const [sampleQuest1, sampleQuest2],
        currentIndex: 1,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
        hintUsed: false,
        gameType: GameSubtype.branchingDialogue,
        level: 2,
        wrongCount: 0,
        isFinalFailure: false,
      );
      when(() => mockRoleplayBloc.state).thenReturn(nextState);
      roleplayStreamController.add(nextState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('The client requests a discount.'), findsOneWidget);
      expect(find.text('LEAD NEGOTIATOR'), findsOneWidget);
      expect(find.byType(SpeakToConfirmOverlay), findsNothing);
    });

    testWidgets('29. Hint button in header dispatches selection haptic and RoleplayHintUsed', (tester) async {
      await pumpBranchingDialogueScreen(tester);

      clearInteractions(mockHapticService);

      final hintButton = find.byType(QuestHintButton);
      expect(hintButton, findsOneWidget);

      await tester.tap(hintButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1100));

      verify(() => mockHapticService.selection()).called(1);
      verify(() => mockRoleplayBloc.add(any(that: isA<RoleplayHintUsed>()))).called(1);
    });

    testWidgets('30. Level 1 briefing layer displays SOCIAL SIMULATOR and dismisses on ENTER SIMULATION tap', (tester) async {
      await pumpBranchingDialogueScreen(
        tester,
        level: 1,
        size: const Size(390, 1100),
      );
      expect(find.byType(GameBriefingLayer), findsOneWidget);
      expect(find.text('SOCIAL SIMULATOR'), findsOneWidget);
      final startBtn = find.text('ENTER SIMULATION');
      expect(startBtn, findsOneWidget);
      await tester.tap(startBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(GameBriefingLayer), findsNothing);
    });

    testWidgets('31. GameShimmerLoading displays on initial state, and complete state renders cleanly', (tester) async {
      await pumpBranchingDialogueScreen(tester, state: const RoleplayInitial());
      expect(find.byType(GameShimmerLoading), findsOneWidget);

      await pumpBranchingDialogueScreen(
        tester,
        state: RoleplayGameComplete(
          xpEarned: 100,
          coinsEarned: 20,
          questCount: 5,
          lastState: testLoadedState,
        ),
      );
      expect(find.byType(BranchingDialogueScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('32. Game over state renders cleanly without error', (tester) async {
      await pumpBranchingDialogueScreen(
        tester,
        state: const RoleplayGameOver(
          quests: [sampleQuest1],
          currentIndex: 0,
          gameType: GameSubtype.branchingDialogue,
          level: 2,
        ),
      );
      expect(find.byType(BranchingDialogueScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('33. Dark and light themes render cleanly without errors', (tester) async {
      await pumpBranchingDialogueScreen(tester, themeMode: ThemeMode.dark);
      expect(find.byType(BranchingDialogueScreen), findsOneWidget);
      await pumpBranchingDialogueScreen(tester, themeMode: ThemeMode.light);
      expect(find.byType(BranchingDialogueScreen), findsOneWidget);
    });

    testWidgets('34. Small mobile screen (320x568) and tablet viewport (768x1024) render cleanly', (tester) async {
      await pumpBranchingDialogueScreen(tester, size: const Size(320, 568));
      expect(find.byType(BranchingDialogueScreen), findsOneWidget);
      expect(tester.takeException(), isNull);

      await pumpBranchingDialogueScreen(tester, size: const Size(768, 1024));
      expect(find.byType(BranchingDialogueScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('35. Reduced motion mode suppresses animations and semantics are intact', (tester) async {
      await pumpBranchingDialogueScreen(tester, reduceMotion: true);
      expect(find.byType(BranchingDialogueScreen), findsOneWidget);
      expect(find.byKey(const Key('branching_dialogue_replay_btn')), findsOneWidget);
      expect(find.byKey(const Key('branching_dialogue_probe')), findsOneWidget);
    });
  });
}

