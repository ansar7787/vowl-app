import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/core/presentation/game_mechanics/speaking/speak_to_confirm_overlay.dart';
import 'package:vowl/core/presentation/widgets/game_briefing_layer.dart';
import 'package:vowl/core/presentation/widgets/game_feedback_card.dart';
import 'package:vowl/core/presentation/widgets/game_progress_header.dart';
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
import 'package:vowl/features/roleplay/presentation/layout/roleplay_base_layout.dart';
import 'package:vowl/features/roleplay/situational_response/presentation/pages/situational_response_screen.dart';
import 'package:vowl/features/roleplay/situational_response/presentation/widgets/situational_response_explanation_panel.dart';
import 'package:vowl/features/roleplay/situational_response/presentation/widgets/situational_response_formality_gauge.dart';
import 'package:vowl/features/roleplay/situational_response/presentation/widgets/situational_response_instruction.dart';
import 'package:vowl/features/roleplay/situational_response/presentation/widgets/situational_response_options_panel.dart';
import 'package:vowl/features/roleplay/situational_response/presentation/widgets/situational_response_scene_display.dart';

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
    id: 'sr_1',
    instruction: 'Choose the most natural reaction for this scenario',
    difficulty: 1,
    subtype: GameSubtype.situationalResponse,
    scene: 'Your colleague spilled coffee on your report right before a major meeting.',
    prompt: 'Colleague spilled coffee on report.',
    options: [
      'No worries, we have digital backups and 10 minutes to print.',
      'You ruined everything! How could you be so careless?',
      'Just walk away from me right now.',
      'I am reporting this to executive management immediately.',
    ],
    correctAnswerIndex: 0,
    correctAnswer: 'No worries, we have digital backups and 10 minutes to print.',
    culturalNote: 'Maintaining composure and offering practical solutions shows professional maturity.',
    formalityScore: 75,
    hint: 'Focus on constructive de-escalation and pragmatic problem solving.',
    explanation: 'Remaining calm and utilizing digital backups resolves the issue without unnecessary workplace drama.',
  );

  const sampleQuest2 = RoleplayQuest(
    id: 'sr_2',
    instruction: 'Select the best polite response in transit',
    difficulty: 2,
    subtype: GameSubtype.situationalResponse,
    scene: 'An elderly passenger boards a crowded train looking for an open seat.',
    prompt: 'Elderly passenger boarding train.',
    options: [
      'Please take my seat, I am getting off at the next stop anyway.',
      'Seats are first come first served here.',
      'You should have arrived earlier to find a seat.',
      'Why does everyone always ask me for my seat?',
    ],
    correctAnswerIndex: 0,
    correctAnswer: 'Please take my seat, I am getting off at the next stop anyway.',
    culturalNote: 'Offering seats to elderly passengers is standard etiquette on public transit.',
    formalityScore: 60,
    hint: 'Show consideration and courtesy in shared transit environments.',
    explanation: 'Offering your seat demonstrates empathy and adheres to universal transit etiquette.',
  );

  RoleplayQuest createQuest({
    String id = 'sr_test',
    String instruction = 'Choose the most natural reaction for this scenario',
    int difficulty = 1,
    String? scene = 'Your colleague spilled coffee on your report right before a major meeting.',
    String? prompt = 'Colleague spilled coffee on report.',
    List<String>? options = const [
      'No worries, we have digital backups and 10 minutes to print.',
      'You ruined everything! How could you be so careless?',
      'Just walk away from me right now.',
      'I am reporting this to executive management immediately.',
    ],
    int? correctAnswerIndex = 0,
    String? correctAnswer = 'No worries, we have digital backups and 10 minutes to print.',
    String? culturalNote = 'Maintaining composure and offering practical solutions shows professional maturity.',
    int? formalityScore = 75,
    String? hint = 'Focus on constructive de-escalation and pragmatic problem solving.',
    String? explanation = 'Remaining calm and utilizing digital backups resolves the issue without unnecessary workplace drama.',
    String? textToSpeak,
  }) {
    return RoleplayQuest(
      id: id,
      instruction: instruction,
      difficulty: difficulty,
      subtype: GameSubtype.situationalResponse,
      scene: scene,
      prompt: prompt,
      options: options,
      correctAnswerIndex: correctAnswerIndex,
      correctAnswer: correctAnswer,
      culturalNote: culturalNote,
      formalityScore: formalityScore,
      hint: hint,
      explanation: explanation,
      textToSpeak: textToSpeak,
    );
  }

  final testLoadedState = RoleplayLoaded(
    quests: const [sampleQuest1, sampleQuest2],
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
    hintUsed: false,
    gameType: GameSubtype.situationalResponse,
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
    VowlMotion.lowAnimationModeOverride.value = true;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'has_seen_briefing_situationalResponse': true,
    });

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

    // Default Stubs
    when(() => mockRoleplayBloc.state).thenReturn(testLoadedState);
    whenListen(
      mockRoleplayBloc,
      roleplayStreamController.stream,
      initialState: testLoadedState,
    );

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
    when(() => mockSoundService.playUrl(any())).thenAnswer((_) async {});

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

    when(() => mockAudioRecorder.hasPermission()).thenAnswer((_) async => true);
    when(() => mockAudioRecorder.startRecording()).thenAnswer((_) async => true);
    when(() => mockAudioRecorder.stopRecording())
        .thenAnswer((_) async => '/tmp/situational_response_test.m4a');
    when(() => mockAudioRecorder.isRecording).thenReturn(false);
    when(() => mockAudioRecorder.onAmplitudeChanged(any()))
        .thenAnswer((_) => Stream.value(Amplitude(current: -10, max: -5)));
    when(() => mockAudioRecorder.dispose()).thenAnswer((_) async {});

    when(() => mockLocaleService.tr(any(), fallback: any(named: 'fallback')))
        .thenAnswer((invocation) {
      final fallback = invocation.namedArguments[#fallback] as String?;
      return fallback ?? invocation.positionalArguments[0] as String;
    });

    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
    when(() => mockAnalyticsService.logSelfEvaluation(any()))
        .thenAnswer((_) async {});
    when(() => mockAnalyticsService.logGameSkipped(any()))
        .thenAnswer((_) async {});
    when(() => mockAnalyticsService.logPurchaseAttempt(any()))
        .thenAnswer((_) async {});

    if (di.sl.isRegistered<HapticService>()) di.sl.unregister<HapticService>();
    if (di.sl.isRegistered<SoundService>()) di.sl.unregister<SoundService>();
    if (di.sl.isRegistered<TtsService>()) di.sl.unregister<TtsService>();
    if (di.sl.isRegistered<SpeechService>()) di.sl.unregister<SpeechService>();
    if (di.sl.isRegistered<AudioRecordingService>()) {
      di.sl.unregister<AudioRecordingService>();
    }
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

  tearDown(() {
    roleplayStreamController.close();
  });

  tearDownAll(() {
    VowlMotion.lowAnimationModeOverride.value = false;
    if (di.sl.isRegistered<HapticService>()) di.sl.unregister<HapticService>();
    if (di.sl.isRegistered<SoundService>()) di.sl.unregister<SoundService>();
    if (di.sl.isRegistered<TtsService>()) di.sl.unregister<TtsService>();
    if (di.sl.isRegistered<SpeechService>()) di.sl.unregister<SpeechService>();
    if (di.sl.isRegistered<AudioRecordingService>()) {
      di.sl.unregister<AudioRecordingService>();
    }
    if (di.sl.isRegistered<LocaleService>()) di.sl.unregister<LocaleService>();
    if (di.sl.isRegistered<AppLogger>()) di.sl.unregister<AppLogger>();
    if (di.sl.isRegistered<AnalyticsService>()) di.sl.unregister<AnalyticsService>();
    if (di.sl.isRegistered<AdService>()) di.sl.unregister<AdService>();
    if (di.sl.isRegistered<NetworkInfo>()) di.sl.unregister<NetworkInfo>();
  });

  Future<void> pumpSituationalResponseScreen(
    WidgetTester tester, {
    RoleplayState? state,
    int level = 2,
    ThemeMode themeMode = ThemeMode.dark,
    Size size = const Size(390, 1400),
    bool reduceMotion = false,
  }) async {
    tester.view.physicalSize = Size(size.width * 2, size.height * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final activeState = state ?? testLoadedState;
    when(() => mockRoleplayBloc.state).thenReturn(activeState);
    whenListen(
      mockRoleplayBloc,
      roleplayStreamController.stream,
      initialState: activeState,
    );
    if (!roleplayStreamController.isClosed) {
      roleplayStreamController.add(activeState);
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
              data: MediaQueryData(
                size: size,
                disableAnimations: reduceMotion,
              ),
              child: Scaffold(
                body: SituationalResponseScreen(
                  level: level,
                  gameType: GameSubtype.situationalResponse,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  group('SituationalResponseScreen Layout and Mechanics Tests', () {
    // -------------------------------------------------------------------------
    // 1. Initial Layout & Visual Components (Tests 1-14)
    // -------------------------------------------------------------------------

    testWidgets('1. Initial layout renders RoleplayBaseLayout, header, and progress',
        (tester) async {
      await pumpSituationalResponseScreen(tester);
      expect(find.byType(RoleplayBaseLayout), findsOneWidget);
      expect(find.byType(GameProgressHeader), findsOneWidget);
      expect(find.byType(QuestHintButton), findsOneWidget);
    });

    testWidgets('2. Initial layout renders SituationalResponseInstruction with badge',
        (tester) async {
      await pumpSituationalResponseScreen(tester);
      expect(find.byType(SituationalResponseInstruction), findsOneWidget);
      expect(find.text('SITUATIONAL RESPONSE'), findsOneWidget);
      expect(find.text(sampleQuest1.instruction), findsOneWidget);
    });

    testWidgets('3. Fallback instruction renders default text when quest instruction is empty',
        (tester) async {
      final customQuest = createQuest(instruction: '');
      final customState = testLoadedState.copyWith(quests: [customQuest]);
      await pumpSituationalResponseScreen(tester, state: customState);
      expect(
        find.text('Choose the most natural reaction for this scenario'),
        findsOneWidget,
      );
    });

    testWidgets('4. Active scenario card renders SituationalResponseSceneDisplay with title',
        (tester) async {
      await pumpSituationalResponseScreen(tester);
      expect(find.byType(SituationalResponseSceneDisplay), findsOneWidget);
      expect(find.text('SCENARIO'), findsOneWidget);
      expect(find.byIcon(Icons.theater_comedy_rounded), findsOneWidget);
    });

    testWidgets('5. Active scenario displays quest scene text accurately',
        (tester) async {
      await pumpSituationalResponseScreen(tester);
      expect(find.text(sampleQuest1.scene!), findsOneWidget);
    });

    testWidgets('6. Contextual watermark icon renders coffee icon for coffee keyword',
        (tester) async {
      await pumpSituationalResponseScreen(tester);
      expect(find.byIcon(Icons.local_cafe_rounded), findsOneWidget);
    });

    testWidgets('7. Contextual watermark icon renders transit icon for train keyword',
        (tester) async {
      final trainQuest = createQuest(scene: 'Taking the daily train to central station.');
      final customState = testLoadedState.copyWith(quests: [trainQuest]);
      await pumpSituationalResponseScreen(tester, state: customState);
      expect(find.byIcon(Icons.directions_transit_rounded), findsOneWidget);
    });

    testWidgets('8. Contextual watermark icon renders work icon for office keyword',
        (tester) async {
      final workQuest = createQuest(scene: 'Working with a colleague at the office desk.');
      final customState = testLoadedState.copyWith(quests: [workQuest]);
      await pumpSituationalResponseScreen(tester, state: customState);
      expect(find.byIcon(Icons.work_rounded), findsOneWidget);
    });

    testWidgets('9. Contextual watermark icon renders handshake icon for interview keyword',
        (tester) async {
      final interviewQuest = createQuest(scene: 'Attending a tough interview for a senior role.');
      final customState = testLoadedState.copyWith(quests: [interviewQuest]);
      await pumpSituationalResponseScreen(tester, state: customState);
      expect(find.byIcon(Icons.handshake_rounded), findsOneWidget);
    });

    testWidgets('10. Contextual watermark icon renders medical icon for hospital keyword',
        (tester) async {
      final medQuest = createQuest(scene: 'Visiting the hospital pharmacy for prescription.');
      final customState = testLoadedState.copyWith(quests: [medQuest]);
      await pumpSituationalResponseScreen(tester, state: customState);
      expect(find.byIcon(Icons.medical_services_rounded), findsOneWidget);
    });

    testWidgets('11. Contextual watermark icon renders forum fallback for generic text',
        (tester) async {
      final genericQuest = createQuest(scene: 'A mysterious traveler arrives on a stormy night.');
      final customState = testLoadedState.copyWith(quests: [genericQuest]);
      await pumpSituationalResponseScreen(tester, state: customState);
      expect(find.byIcon(Icons.forum_rounded), findsOneWidget);
    });

    testWidgets('12. "LISTEN" button renders with volume icon and label',
        (tester) async {
      await pumpSituationalResponseScreen(tester);
      expect(find.text('LISTEN'), findsOneWidget);
      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
    });

    testWidgets('13. Options panel renders SituationalResponseOptionsPanel with all 4 options',
        (tester) async {
      await pumpSituationalResponseScreen(tester);
      expect(find.byType(SituationalResponseOptionsPanel), findsOneWidget);
      for (final opt in sampleQuest1.options!) {
        expect(find.text(opt), findsOneWidget);
      }
    });

    testWidgets('14. Option cards initially display chat bubble outline icons',
        (tester) async {
      await pumpSituationalResponseScreen(tester);
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsNWidgets(4));
    });

    // -------------------------------------------------------------------------
    // 2. Audio & TTS Playback Mechanics (Tests 15-19)
    // -------------------------------------------------------------------------

    testWidgets('15. Tapping "LISTEN" triggers soundService.playTts with scene and selection haptic',
        (tester) async {
      await pumpSituationalResponseScreen(tester);
      final listenBtn = find.text('LISTEN');
      await tester.tap(listenBtn);
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockHapticService.selection()).called(1);
      verify(() => mockSoundService.playTts(sampleQuest1.scene!)).called(1);
    });

    testWidgets('16. "LISTEN" button prefers textToSpeak when provided',
        (tester) async {
      final ttsQuest = createQuest(textToSpeak: 'Custom spoken narration for scenario.');
      final customState = testLoadedState.copyWith(quests: [ttsQuest]);
      await pumpSituationalResponseScreen(tester, state: customState);

      await tester.tap(find.text('LISTEN'));
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockSoundService.playTts('Custom spoken narration for scenario.')).called(1);
    });

    testWidgets('17. "LISTEN" button falls back to prompt when scene and textToSpeak are null',
        (tester) async {
      final promptQuest = createQuest(scene: null, textToSpeak: null);
      final customState = testLoadedState.copyWith(quests: [promptQuest]);
      await pumpSituationalResponseScreen(tester, state: customState);

      await tester.tap(find.text('LISTEN'));
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockSoundService.playTts(sampleQuest1.prompt!)).called(1);
    });

    testWidgets('18. "LISTEN" button plays URL via soundService.playUrl when text starts with http',
        (tester) async {
      final urlQuest = createQuest(textToSpeak: 'https://vowl.app/audio/sr_1.mp3');
      final customState = testLoadedState.copyWith(quests: [urlQuest]);
      await pumpSituationalResponseScreen(tester, state: customState);

      await tester.tap(find.text('LISTEN'));
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockSoundService.playUrl('https://vowl.app/audio/sr_1.mp3')).called(1);
    });

    testWidgets('19. "LISTEN" button strips pause tokens cleanly before TTS',
        (tester) async {
      final pauseQuest = createQuest(
        textToSpeak: 'Hello [pause:500] colleagues [pause:1000] please listen.',
      );
      final customState = testLoadedState.copyWith(quests: [pauseQuest]);
      await pumpSituationalResponseScreen(tester, state: customState);

      await tester.tap(find.text('LISTEN'));
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockSoundService.playTts('Hello   colleagues   please listen.')).called(1);
    });

    // -------------------------------------------------------------------------
    // 3. Option Selection & Incorrect Path (Tests 20-26)
    // -------------------------------------------------------------------------

    testWidgets('20. Tapping wrong option triggers error sound, error haptic, and dispatches SubmitAnswer(false)',
        (tester) async {
      await pumpSituationalResponseScreen(tester);
      final wrongOptionText = sampleQuest1.options![1];

      await tester.tap(find.text(wrongOptionText));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockHapticService.error()).called(1);
      verify(() => mockRoleplayBloc.add(const SubmitAnswer(false))).called(1);
    });

    testWidgets('21. Tapping wrong option does NOT mount Phase 2 SpeakToConfirmOverlay',
        (tester) async {
      await pumpSituationalResponseScreen(tester);
      final wrongOptionText = sampleQuest1.options![1];

      await tester.tap(find.text(wrongOptionText));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(SpeakToConfirmOverlay), findsNothing);
    });

    testWidgets('22. Answered wrong option displays close icon and correct option displays check icon',
        (tester) async {
      await pumpSituationalResponseScreen(tester);
      final wrongOptionText = sampleQuest1.options![1];

      await tester.tap(find.text(wrongOptionText));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('23. Answered wrong state reveals explanation panel with "Not quite right!"',
        (tester) async {
      await pumpSituationalResponseScreen(tester);
      final wrongOptionText = sampleQuest1.options![1];

      await tester.tap(find.text(wrongOptionText));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(SituationalResponseExplanationPanel), findsOneWidget);
      expect(find.text('Not quite right!'), findsOneWidget);
      expect(find.text(sampleQuest1.explanation!), findsOneWidget);
    });

    testWidgets('24. Answered state shows Formality Gauge with cultural note on wrong answer',
        (tester) async {
      await pumpSituationalResponseScreen(tester);
      final wrongOptionText = sampleQuest1.options![1];

      await tester.tap(find.text(wrongOptionText));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(SituationalResponseFormalityGauge), findsOneWidget);
      expect(find.text('CULTURAL NOTE'), findsOneWidget);
      expect(find.text(sampleQuest1.culturalNote!), findsOneWidget);
    });

    testWidgets('25. Answered state locks options and secondary taps are ignored',
        (tester) async {
      await pumpSituationalResponseScreen(tester);
      final wrongOptionText = sampleQuest1.options![1];
      final anotherWrong = sampleQuest1.options![2];

      await tester.tap(find.text(wrongOptionText));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      clearInteractions(mockRoleplayBloc);

      await tester.tap(find.text(anotherWrong), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      verifyNever(() => mockRoleplayBloc.add(any()));
    });

    testWidgets('26. Rapid double-tap on option is absorbed without double submission',
        (tester) async {
      await pumpSituationalResponseScreen(tester);
      final wrongOptionText = sampleQuest1.options![1];

      await tester.tap(find.text(wrongOptionText));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text(wrongOptionText), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockRoleplayBloc.add(const SubmitAnswer(false))).called(1);
    });

    // -------------------------------------------------------------------------
    // 4. Correct Option & Phase 2 Transition (Tests 27-33)
    // -------------------------------------------------------------------------

    testWidgets('27. Tapping correct option triggers selection haptics',
        (tester) async {
      await pumpSituationalResponseScreen(tester);
      final correctText = sampleQuest1.correctAnswer!;

      await tester.tap(find.text(correctText));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockHapticService.selection()).called(1);
    });

    testWidgets('28. Tapping correct option does NOT immediately dispatch SubmitAnswer to BLoC',
        (tester) async {
      await pumpSituationalResponseScreen(tester);
      final correctText = sampleQuest1.correctAnswer!;

      await tester.tap(find.text(correctText));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      verifyNever(() => mockRoleplayBloc.add(any(that: isA<SubmitAnswer>())));
    });

    testWidgets('29. Tapping correct option mounts Phase 2 SpeakToConfirmOverlay',
        (tester) async {
      await pumpSituationalResponseScreen(tester);
      final correctText = sampleQuest1.correctAnswer!;

      await tester.tap(find.text(correctText));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(SpeakToConfirmOverlay), findsOneWidget);
    });

    testWidgets('30. SpeakToConfirmOverlay displays expectedText matching correct option',
        (tester) async {
      await pumpSituationalResponseScreen(tester);
      final correctText = sampleQuest1.correctAnswer!;

      await tester.tap(find.text(correctText));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('SPEAK TO RESPOND'), findsOneWidget);
      expect(find.text('Say your response aloud'), findsOneWidget);
      final overlay = tester.widget<SpeakToConfirmOverlay>(find.byType(SpeakToConfirmOverlay));
      expect(overlay.expectedText, equals(correctText));
    });

    testWidgets('31. Formality gauge mounts upon correct option selection in Phase 2',
        (tester) async {
      await pumpSituationalResponseScreen(tester);
      final correctText = sampleQuest1.correctAnswer!;

      await tester.tap(find.text(correctText));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(SituationalResponseFormalityGauge), findsOneWidget);
      expect(find.text('CULTURAL NOTE'), findsOneWidget);
      expect(find.text(sampleQuest1.culturalNote!), findsOneWidget);
    });

    testWidgets('32. Formality gauge displays "Casual" and "Formal" labels',
        (tester) async {
      await pumpSituationalResponseScreen(tester);
      final correctText = sampleQuest1.correctAnswer!;

      await tester.tap(find.text(correctText));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Casual'), findsOneWidget);
      expect(find.text('Formal'), findsOneWidget);
    });

    testWidgets('33. Formality gauge collapses safely when culturalNote and formalityScore are null',
        (tester) async {
      final blankNoteQuest = createQuest(culturalNote: null, formalityScore: null);
      final customState = testLoadedState.copyWith(quests: [blankNoteQuest]);
      await pumpSituationalResponseScreen(tester, state: customState);

      await tester.tap(find.text(blankNoteQuest.correctAnswer!));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('CULTURAL NOTE'), findsNothing);
      expect(find.text('Casual'), findsNothing);
    });

    // -------------------------------------------------------------------------
    // 5. Phase 2 Speech Evaluation Mechanics (Tests 34-39)
    // -------------------------------------------------------------------------

    testWidgets('34. SpeakToConfirmOverlay "Nailed It" dispatches RoleplaySpeakConfirmed(5) bonus coins',
        (tester) async {
      await pumpSituationalResponseScreen(tester);
      final correctText = sampleQuest1.correctAnswer!;

      await tester.tap(find.text(correctText));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      final overlay = tester.widget<SpeakToConfirmOverlay>(find.byType(SpeakToConfirmOverlay));
      overlay.onConfirmed();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockRoleplayBloc.add(const RoleplaySpeakConfirmed(5))).called(1);
    });

    testWidgets('35. SpeakToConfirmOverlay "Nailed It" dispatches SubmitAnswer(true) with success sound & haptic',
        (tester) async {
      await pumpSituationalResponseScreen(tester);
      final correctText = sampleQuest1.correctAnswer!;

      await tester.tap(find.text(correctText));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      final overlay = tester.widget<SpeakToConfirmOverlay>(find.byType(SpeakToConfirmOverlay));
      overlay.onConfirmed();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockSoundService.playCorrect()).called(1);
      verify(() => mockHapticService.success()).called(1);
      verify(() => mockRoleplayBloc.add(const SubmitAnswer(true))).called(1);
    });

    testWidgets('36. SpeakToConfirmOverlay unmounts once answered via "Nailed It"',
        (tester) async {
      await pumpSituationalResponseScreen(tester);
      final correctText = sampleQuest1.correctAnswer!;

      await tester.tap(find.text(correctText));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      final overlay = tester.widget<SpeakToConfirmOverlay>(find.byType(SpeakToConfirmOverlay));
      overlay.onConfirmed();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(SpeakToConfirmOverlay), findsNothing);
    });

    testWidgets('37. Answered correct state shows explanation panel with "Great response!" and verified icon',
        (tester) async {
      await pumpSituationalResponseScreen(tester);
      final correctText = sampleQuest1.correctAnswer!;

      await tester.tap(find.text(correctText));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      final overlay = tester.widget<SpeakToConfirmOverlay>(find.byType(SpeakToConfirmOverlay));
      overlay.onConfirmed();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(SituationalResponseExplanationPanel), findsOneWidget);
      expect(find.text('Great response!'), findsOneWidget);
      expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(SituationalResponseExplanationPanel),
          matching: find.text(sampleQuest1.explanation!),
        ),
        findsOneWidget,
      );
    });

    testWidgets('38. SpeakToConfirmOverlay "Needs Work" dispatches SubmitAnswer(false) with error sound & haptic',
        (tester) async {
      await pumpSituationalResponseScreen(tester);
      final correctText = sampleQuest1.correctAnswer!;

      await tester.tap(find.text(correctText));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      final overlay = tester.widget<SpeakToConfirmOverlay>(find.byType(SpeakToConfirmOverlay));
      overlay.onSkipped();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockHapticService.error()).called(1);
      verify(() => mockRoleplayBloc.add(const SubmitAnswer(false))).called(1);
    });

    testWidgets('39. SpeakToConfirmOverlay unmounts on "Needs Work" and shows "Not quite right!"',
        (tester) async {
      await pumpSituationalResponseScreen(tester);
      final correctText = sampleQuest1.correctAnswer!;

      await tester.tap(find.text(correctText));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      final overlay = tester.widget<SpeakToConfirmOverlay>(find.byType(SpeakToConfirmOverlay));
      overlay.onSkipped();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(SpeakToConfirmOverlay), findsNothing);
      expect(find.text('Not quite right!'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // 6. Navigation, Bottom Sheet & Transitions (Tests 40-44)
    // -------------------------------------------------------------------------

    testWidgets('40. Answered state renders GameFeedbackCard in bottom sheet',
        (tester) async {
      await pumpSituationalResponseScreen(tester);
      final wrongOptionText = sampleQuest1.options![1];

      await tester.tap(find.text(wrongOptionText));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(GameFeedbackCard), findsOneWidget);
    });

    testWidgets('41. Tapping action button in feedback card dispatches NextQuestion()',
        (tester) async {
      await pumpSituationalResponseScreen(tester);
      final wrongOptionText = sampleQuest1.options![1];

      await tester.tap(find.text(wrongOptionText));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      final actionBtn = find.text('TRY AGAIN');
      expect(actionBtn, findsOneWidget);
      await tester.tap(actionBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockRoleplayBloc.add(any(that: isA<NextQuestion>()))).called(1);
    });

    testWidgets('42. State transition to question 2 updates scene and clears previous selection',
        (tester) async {
      await pumpSituationalResponseScreen(tester);

      final nextState = testLoadedState.copyWith(
        currentIndex: 1,
        quests: [sampleQuest1, sampleQuest2],
      );
      roleplayStreamController.add(nextState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text(sampleQuest2.scene!), findsOneWidget);
      expect(find.text(sampleQuest2.correctAnswer!), findsOneWidget);
    });

    testWidgets('43. Two-option quest renders both options cleanly without crashing',
        (tester) async {
      const twoOptionQuest = RoleplayQuest(
        id: 'sr_two',
        instruction: 'Choose right or left response',
        difficulty: 1,
        subtype: GameSubtype.situationalResponse,
        scene: 'A pedestrian asks for simple directions.',
        options: ['Turn right at the bookstore.', 'I cannot help you.'],
        correctAnswerIndex: 0,
        correctAnswer: 'Turn right at the bookstore.',
      );
      final customState = testLoadedState.copyWith(quests: [twoOptionQuest]);
      await pumpSituationalResponseScreen(tester, state: customState);

      expect(find.text('Turn right at the bookstore.'), findsOneWidget);
      expect(find.text('I cannot help you.'), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsNWidgets(2));
    });

    testWidgets('44. Single option fallback quest renders option without error',
        (tester) async {
      const singleOptionQuest = RoleplayQuest(
        id: 'sr_single',
        instruction: 'Affirm the situation',
        difficulty: 1,
        subtype: GameSubtype.situationalResponse,
        scene: 'Someone says hello.',
        correctAnswer: 'Hello there!',
      );
      final customState = testLoadedState.copyWith(quests: [singleOptionQuest]);
      await pumpSituationalResponseScreen(tester, state: customState);

      expect(find.text('Hello there!'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // 7. Hints & Instructions (Tests 45-46)
    // -------------------------------------------------------------------------

    testWidgets('45. Tapping hint button in header dispatches RoleplayHintUsed',
        (tester) async {
      await pumpSituationalResponseScreen(tester);
      clearInteractions(mockRoleplayBloc);
      final hintBtn = find.byType(QuestHintButton);

      await tester.tap(hintBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockRoleplayBloc.add(any(that: isA<RoleplayHintUsed>()))).called(2);
    });

    testWidgets('46. Instruction renders hint banner when hintUsed is true',
        (tester) async {
      final hintState = testLoadedState.copyWith(hintUsed: true);
      await pumpSituationalResponseScreen(tester, state: hintState);

      expect(find.byIcon(Icons.lightbulb_outline_rounded), findsOneWidget);
      expect(find.text(sampleQuest1.hint!), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // 8. Briefing, Shimmer, GameOver & Theming (Tests 47-51)
    // -------------------------------------------------------------------------

    testWidgets('47. Level 1 displays GameBriefingLayer overlay with "Reflex Responder"',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'has_seen_briefing_situationalResponse': false,
      });
      await pumpSituationalResponseScreen(tester, level: 1);

      expect(find.byType(GameBriefingLayer), findsOneWidget);
      expect(find.text('REFLEX RESPONDER'), findsOneWidget);
    });

    testWidgets('48. Uninitialized initial state renders GameShimmerLoading',
        (tester) async {
      await pumpSituationalResponseScreen(tester, state: const RoleplayInitial());
      expect(find.byType(GameShimmerLoading), findsOneWidget);
    });

    testWidgets('49. Game over state with 0 lives renders cleanly',
        (tester) async {
      final gameOverState = testLoadedState.copyWith(livesRemaining: 0);
      await pumpSituationalResponseScreen(tester, state: gameOverState);
      expect(find.byType(SituationalResponseScreen), findsOneWidget);
    });

    testWidgets('50. Light theme renders cleanly with light mode styling',
        (tester) async {
      await pumpSituationalResponseScreen(tester, themeMode: ThemeMode.light);
      expect(find.byType(SituationalResponseScreen), findsOneWidget);
      expect(find.text('SCENARIO'), findsOneWidget);
    });

    testWidgets('51. Compact mobile screen (320x568) renders with zero overflow',
        (tester) async {
      await pumpSituationalResponseScreen(
        tester,
        size: const Size(320, 568),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(SituationalResponseScreen), findsOneWidget);
    });

    testWidgets('52. Tablet viewport (768x1024) renders with zero overflow',
        (tester) async {
      await pumpSituationalResponseScreen(
        tester,
        size: const Size(768, 1024),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(SituationalResponseScreen), findsOneWidget);
    });

    testWidgets('53. Reduced motion mode runs cleanly without ticker exceptions',
        (tester) async {
      await pumpSituationalResponseScreen(tester, reduceMotion: true);
      expect(tester.takeException(), isNull);
      expect(find.byType(SituationalResponseScreen), findsOneWidget);
    });

    testWidgets('54. Accessibility semantics are present on options and listen button',
        (tester) async {
      await pumpSituationalResponseScreen(tester);
      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == 'Listen to scenario',
        ),
        findsOneWidget,
      );
      expect(find.text(sampleQuest1.options![0]), findsOneWidget);
    });
  });
}
