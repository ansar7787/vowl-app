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
import 'package:vowl/core/presentation/widgets/game_progress_header.dart';
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
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/features/roleplay/domain/entities/roleplay_quest.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_bloc.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_event.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_state.dart';
import 'package:vowl/features/roleplay/job_interview/presentation/pages/job_interview_screen.dart';
import 'package:vowl/features/roleplay/job_interview/presentation/widgets/job_interview_instruction.dart';
import 'package:vowl/features/roleplay/job_interview/presentation/widgets/job_interview_interviewer_panel.dart';
import 'package:vowl/features/roleplay/job_interview/presentation/widgets/job_interview_response_console.dart';
import 'package:vowl/features/roleplay/job_interview/presentation/widgets/job_interview_telemetry_dashboard.dart';
import 'package:vowl/features/roleplay/job_interview/presentation/widgets/job_interview_fusion_painter.dart';

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
    id: 'ji_1',
    instruction: 'Select the most professional response to the interviewer.',
    difficulty: 1,
    subtype: GameSubtype.jobInterview,
    interviewerQuestion: 'How do you handle tight deadlines under pressure?',
    options: [
      'I prioritize tasks, maintain communication, and stay calm.',
      'I panic initially and then ask everyone else to do it.',
      'I ignore the deadline and deliver when ready.',
      'I pretend I forgot about the project entirely.',
    ],
    correctAnswerIndex: 0,
    correctAnswer: 'I prioritize tasks, maintain communication, and stay calm.',
    interviewerReaction: [
      'impressed',
      'disappointed',
      'unconvinced',
      'uncertain',
    ],
    professionalismRating: 5,
    hint: 'Show organizational habits and composed problem solving.',
    explanation: 'Prioritizing tasks and clear communication demonstrates leadership.',
  );

  const sampleQuest2 = RoleplayQuest(
    id: 'ji_2',
    instruction: 'Choose how to address a workplace conflict.',
    difficulty: 2,
    subtype: GameSubtype.jobInterview,
    interviewerQuestion: 'What would you do if a colleague disagreed with your proposal?',
    options: [
      'I would listen to their rationale and find constructive middle ground.',
      'I would argue until they gave in completely.',
      'I would complain immediately to human resources.',
      'I would refuse to speak with them further.',
    ],
    correctAnswerIndex: 0,
    correctAnswer: 'I would listen to their rationale and find constructive middle ground.',
    interviewerReaction: [
      'interested',
      'losing interest',
      'unconvinced',
      'disappointed',
    ],
    professionalismRating: 4,
    hint: 'Emphasize collaboration and perspective taking.',
    explanation: 'Active listening and seeking consensus shows mature teamwork.',
  );

  final testLoadedState = RoleplayLoaded(
    quests: const [sampleQuest1, sampleQuest2],
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
    hintUsed: false,
    gameType: GameSubtype.jobInterview,
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
      'has_seen_briefing_jobInterview': true,
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
        .thenAnswer((_) async => '/tmp/job_interview_test.m4a');
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

  Future<void> pumpJobInterviewScreen(
    WidgetTester tester, {
    RoleplayState? state,
    int level = 2,
    ThemeMode themeMode = ThemeMode.dark,
    Size size = const Size(390, 1100),
    bool reduceMotion = false,
  }) async {
    tester.view.physicalSize = size * 2.0;
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

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, child) => MultiBlocProvider(
          providers: [
            BlocProvider<RoleplayBloc>.value(value: mockRoleplayBloc),
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            BlocProvider<EconomyBloc>.value(value: mockEconomyBloc),
          ],
          child: MaterialApp(
            themeMode: themeMode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: MediaQuery(
              data: MediaQueryData(
                size: size,
                disableAnimations: reduceMotion,
              ),
              child: Scaffold(
                body: JobInterviewScreen(
                  level: level,
                  gameType: GameSubtype.jobInterview,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Finder findOptionByText(String text) =>
      find.ancestor(of: find.text(text), matching: find.byType(ScaleButton));

  group('JobInterviewScreen Layout & Rendering Hierarchy', () {
    testWidgets('1. renders JobInterviewInstruction on screen', (tester) async {
      await pumpJobInterviewScreen(tester);
      expect(find.byType(JobInterviewInstruction), findsOneWidget);
      expect(
        find.byKey(const Key('job_interview_instruction_container')),
        findsOneWidget,
      );
    });

    testWidgets('2. renders JobInterviewTelemetryDashboard', (tester) async {
      await pumpJobInterviewScreen(tester);
      expect(find.byType(JobInterviewTelemetryDashboard), findsOneWidget);
      expect(
        find.byKey(const Key('job_interview_telemetry_dashboard')),
        findsOneWidget,
      );
    });

    testWidgets('3. renders JobInterviewInterviewerPanel with question', (tester) async {
      await pumpJobInterviewScreen(tester);
      expect(find.byType(JobInterviewInterviewerPanel), findsOneWidget);
      expect(
        find.byKey(const Key('job_interview_interviewer_panel')),
        findsOneWidget,
      );
    });

    testWidgets('4. renders JobInterviewResponseConsole with options', (tester) async {
      await pumpJobInterviewScreen(tester);
      expect(find.byType(JobInterviewResponseConsole), findsOneWidget);
      expect(
        find.byKey(const Key('job_interview_response_console')),
        findsOneWidget,
      );
    });

    testWidgets('5. renders app bar with GameProgressHeader and lives', (tester) async {
      await pumpJobInterviewScreen(tester);
      expect(find.byType(GameProgressHeader), findsOneWidget);
      expect(find.byType(QuestHintButton), findsOneWidget);
    });
  });

  group('Instruction Component Tests', () {
    testWidgets('6. displays custom quest instruction text', (tester) async {
      await pumpJobInterviewScreen(tester);
      expect(
        find.byKey(const Key('job_interview_instruction_text')),
        findsOneWidget,
      );
      expect(
        find.text('Select the most professional response to the interviewer.'),
        findsOneWidget,
      );
    });

    testWidgets('7. instruction widget falls back to default text when null',
        (tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, child) => const MaterialApp(
            home: Scaffold(
              body: JobInterviewInstruction(
                primaryColor: Colors.blue,
                instruction: null,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(
        find.text('Choose the best answer to show off your professional skills.'),
        findsOneWidget,
      );
    });

    testWidgets('8. instruction container has rounded border decoration',
        (tester) async {
      await pumpJobInterviewScreen(tester);
      final container = tester.widget<Container>(
        find.byKey(const Key('job_interview_instruction_container')),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(16.r));
    });
  });

  group('Telemetry Dashboard Tests', () {
    testWidgets('9. initial dashboard displays PROFESSIONAL HARMONICS label',
        (tester) async {
      await pumpJobInterviewScreen(tester);
      expect(
        find.byKey(const Key('job_interview_telemetry_harmonics_label')),
        findsOneWidget,
      );
      expect(find.text('PROFESSIONAL HARMONICS:'), findsOneWidget);
    });

    testWidgets('10. initial compatibility percentage is 50% COMPATIBLE',
        (tester) async {
      await pumpJobInterviewScreen(tester);
      expect(
        find.byKey(const Key('job_interview_telemetry_percentage_text')),
        findsOneWidget,
      );
      expect(find.text('50% COMPATIBLE'), findsOneWidget);
    });

    testWidgets('11. renders CustomPaint with ProfessionalismFusionPainter',
        (tester) async {
      await pumpJobInterviewScreen(tester);
      expect(
        find.byKey(const Key('job_interview_reactor_painter')),
        findsOneWidget,
      );
      final customPaint = tester.widget<CustomPaint>(
        find.byKey(const Key('job_interview_reactor_painter')),
      );
      expect(customPaint.painter, isA<ProfessionalismFusionPainter>());
    });

    testWidgets('12. Semantics label announces current professionalism level',
        (tester) async {
      await pumpJobInterviewScreen(tester);
      expect(
        find.bySemanticsLabel('Professionalism level is at 50 percent'),
        findsOneWidget,
      );
    });

    testWidgets('13. reactor box has fixed dimensions 72x72', (tester) async {
      await pumpJobInterviewScreen(tester);
      final box = tester.widget<SizedBox>(
        find.byKey(const Key('job_interview_reactor_box')),
      );
      expect(box.width, 72.r);
      expect(box.height, 72.r);
    });

    testWidgets('14. telemetry progress bar container renders on screen',
        (tester) async {
      await pumpJobInterviewScreen(tester);
      expect(
        find.byKey(const Key('job_interview_telemetry_progress_bar')),
        findsOneWidget,
      );
    });
  });

  group('Interviewer Panel Tests', () {
    testWidgets('15. displays interviewer question text', (tester) async {
      await pumpJobInterviewScreen(tester);
      expect(
        find.byKey(const Key('job_interview_interviewer_question_text')),
        findsOneWidget,
      );
      expect(
        find.text('How do you handle tight deadlines under pressure?'),
        findsOneWidget,
      );
    });

    testWidgets('16. initial title is CHIEF EXECUTIVE V-407 when reaction is null',
        (tester) async {
      await pumpJobInterviewScreen(tester);
      expect(
        find.byKey(const Key('job_interview_interviewer_title')),
        findsOneWidget,
      );
      expect(find.text('CHIEF EXECUTIVE V-407'), findsOneWidget);
    });

    testWidgets('17. initial subtitle is ACTIVE BIO-TRANSCEIVER when reaction is null',
        (tester) async {
      await pumpJobInterviewScreen(tester);
      expect(
        find.byKey(const Key('job_interview_interviewer_subtitle')),
        findsOneWidget,
      );
      expect(find.text('ACTIVE BIO-TRANSCEIVER'), findsOneWidget);
    });

    testWidgets('18. initial interviewer icon is business_center_rounded',
        (tester) async {
      await pumpJobInterviewScreen(tester);
      expect(
        find.byKey(const Key('job_interview_interviewer_icon')),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.business_center_rounded), findsOneWidget);
    });

    testWidgets('19. reaction impressed renders uppercase title, subtitle, and satisfied icon',
        (tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, child) => MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(
              body: JobInterviewInterviewerPanel(
                text: 'Tell me about yourself.',
                color: Colors.blue,
                isDark: true,
                reaction: 'impressed',
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('IMPRESSED'), findsOneWidget);
      expect(find.text('INTERVIEWER REACTION'), findsOneWidget);
      expect(find.byIcon(Icons.sentiment_very_satisfied_rounded), findsOneWidget);
    });

    testWidgets('20. reaction disappointed renders uppercase title, subtitle, and dissatisfied icon',
        (tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, child) => MaterialApp(
            theme: AppTheme.darkTheme,
            home: const Scaffold(
              body: JobInterviewInterviewerPanel(
                text: 'Tell me about yourself.',
                color: Colors.blue,
                isDark: true,
                reaction: 'disappointed',
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('DISAPPOINTED'), findsOneWidget);
      expect(find.text('INTERVIEWER REACTION'), findsOneWidget);
      expect(find.byIcon(Icons.sentiment_dissatisfied_rounded), findsOneWidget);
    });
  });

  group('Response Console & Shuffling Tests', () {
    testWidgets('21. renders all 4 interview response options', (tester) async {
      await pumpJobInterviewScreen(tester);
      expect(find.text(sampleQuest1.options![0]), findsOneWidget);
      expect(find.text(sampleQuest1.options![1]), findsOneWidget);
      expect(find.text(sampleQuest1.options![2]), findsOneWidget);
      expect(find.text(sampleQuest1.options![3]), findsOneWidget);
    });

    testWidgets('22. initially all option stones display diamond_rounded icon',
        (tester) async {
      await pumpJobInterviewScreen(tester);
      expect(find.byIcon(Icons.diamond_rounded), findsNWidgets(4));
    });

    testWidgets('23. renders two-option batch without crashing', (tester) async {
      const twoOptionQuest = RoleplayQuest(
        id: 'ji_two',
        instruction: 'Pick one',
        difficulty: 1,
        subtype: GameSubtype.jobInterview,
        interviewerQuestion: 'Do you prefer team work or solo work?',
        options: ['I excel in team environments.', 'I strictly work alone.'],
        correctAnswerIndex: 0,
        correctAnswer: 'I excel in team environments.',
      );
      final state = testLoadedState.copyWith(quests: [twoOptionQuest]);
      await pumpJobInterviewScreen(tester, state: state);

      expect(find.text('I excel in team environments.'), findsOneWidget);
      expect(find.text('I strictly work alone.'), findsOneWidget);
    });

    testWidgets('24. single-option fallback quest renders cleanly', (tester) async {
      const singleOptionQuest = RoleplayQuest(
        id: 'ji_single',
        instruction: 'Confirm agreement',
        difficulty: 1,
        subtype: GameSubtype.jobInterview,
        interviewerQuestion: 'Are you ready to join our engineering department?',
        options: ['Yes, absolutely ready.'],
        correctAnswerIndex: 0,
        correctAnswer: 'Yes, absolutely ready.',
      );
      final state = testLoadedState.copyWith(quests: [singleOptionQuest]);
      await pumpJobInterviewScreen(tester, state: state);

      expect(find.text('Yes, absolutely ready.'), findsOneWidget);
    });

    testWidgets('25. option text style has centered alignment', (tester) async {
      await pumpJobInterviewScreen(tester);
      final textWidget = tester.widget<Text>(
        find.text(sampleQuest1.options![0]),
      );
      expect(textWidget.textAlign, TextAlign.center);
    });
  });

  group('Option Selection & Scoring Mechanics Tests', () {
    testWidgets('26. tapping incorrect option stone triggers error haptic and audio',
        (tester) async {
      await pumpJobInterviewScreen(tester);
      final wrongOptionText = sampleQuest1.options![1];
      await tester.tap(findOptionByText(wrongOptionText));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockHapticService.error()).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
    });

    testWidgets('27. tapping incorrect option dispatches SubmitAnswer(false) with userAnswer',
        (tester) async {
      await pumpJobInterviewScreen(tester);
      final wrongOptionText = sampleQuest1.options![1];
      await tester.tap(findOptionByText(wrongOptionText));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(
        () => mockRoleplayBloc.add(
          any(that: isA<SubmitAnswer>().having((e) => e.isCorrect, 'isCorrect', false)),
        ),
      ).called(1);
    });

    testWidgets('28. incorrect selection drops mercuryLevel by 20% (50% -> 30%)',
        (tester) async {
      await pumpJobInterviewScreen(tester);
      final wrongOptionText = sampleQuest1.options![1];
      await tester.tap(findOptionByText(wrongOptionText));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('30% COMPATIBLE'), findsOneWidget);
    });

    testWidgets('29. incorrect selection renders cancel_rounded icon on selected stone',
        (tester) async {
      await pumpJobInterviewScreen(tester);
      final wrongOptionText = sampleQuest1.options![1];
      await tester.tap(findOptionByText(wrongOptionText));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byIcon(Icons.cancel_rounded), findsOneWidget);
    });

    testWidgets('30. incorrect selection does NOT mount SpeakToConfirmOverlay',
        (tester) async {
      await pumpJobInterviewScreen(tester);
      final wrongOptionText = sampleQuest1.options![1];
      await tester.tap(findOptionByText(wrongOptionText));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(SpeakToConfirmOverlay), findsNothing);
    });

    testWidgets('31. tapping correct option stone triggers selection haptic and mounts SpeakToConfirmOverlay',
        (tester) async {
      await pumpJobInterviewScreen(tester);
      final correctOptionText = sampleQuest1.correctAnswer!;
      await tester.tap(findOptionByText(correctOptionText));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockHapticService.selection()).called(1);
      expect(find.byType(SpeakToConfirmOverlay), findsOneWidget);
      expect(
        find.byKey(const Key('job_interview_speak_overlay')),
        findsOneWidget,
      );
    });

    testWidgets('32. correct option selection does NOT dispatch SubmitAnswer early',
        (tester) async {
      await pumpJobInterviewScreen(tester);
      final correctOptionText = sampleQuest1.correctAnswer!;
      await tester.tap(findOptionByText(correctOptionText));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verifyNever(() => mockRoleplayBloc.add(any(that: isA<SubmitAnswer>())));
    });

    testWidgets('33. in Phase 2 correct option stone renders verified_rounded icon',
        (tester) async {
      await pumpJobInterviewScreen(tester);
      final correctOptionText = sampleQuest1.correctAnswer!;
      await tester.tap(findOptionByText(correctOptionText));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
    });
  });

  group('Phase 2 Speech Confirmation & Evaluation Tests', () {
    testWidgets('34. SpeakToConfirmOverlay displays expectedText matching chosen correct answer',
        (tester) async {
      await pumpJobInterviewScreen(tester);
      final correctOptionText = sampleQuest1.correctAnswer!;
      await tester.tap(findOptionByText(correctOptionText));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byKey(const Key('job_interview_speak_overlay')),
      );
      expect(overlay.expectedText, correctOptionText);
    });

    testWidgets('35. tapping Nailed It dispatches RoleplaySpeakConfirmed(5) and SubmitAnswer(true)',
        (tester) async {
      await pumpJobInterviewScreen(tester);
      final correctOptionText = sampleQuest1.correctAnswer!;
      await tester.tap(findOptionByText(correctOptionText));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Scroll to bring SpeakToConfirmOverlay into view
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Switch to manual evaluation
      final manualBtn = find.text('Evaluate myself manually');
      expect(manualBtn, findsOneWidget);
      await tester.tap(manualBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Record audio
      final micBtn = find.byKey(const ValueKey('speaking_mic_btn'));
      expect(micBtn, findsOneWidget);
      await tester.tap(micBtn);
      await tester.pump();
      await tester.runAsync(() async => await Future.delayed(const Duration(milliseconds: 600)));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(micBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Scroll slightly more so Nailed It is visible
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final nailedItBtn = find.text('Nailed It');
      expect(nailedItBtn, findsOneWidget);
      await tester.tap(nailedItBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockRoleplayBloc.add(const RoleplaySpeakConfirmed(5))).called(1);
      verify(
        () => mockRoleplayBloc.add(
          any(that: isA<SubmitAnswer>().having((e) => e.isCorrect, 'isCorrect', true)),
        ),
      ).called(1);
      verify(() => mockSoundService.playCorrect()).called(1);
    });

    testWidgets('36. successful verbal evaluation boosts mercuryLevel by professionalism score',
        (tester) async {
      await pumpJobInterviewScreen(tester);
      final correctOptionText = sampleQuest1.correctAnswer!;
      await tester.tap(findOptionByText(correctOptionText));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final manualBtn = find.text('Evaluate myself manually');
      await tester.tap(manualBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final micBtn = find.byKey(const ValueKey('speaking_mic_btn'));
      await tester.tap(micBtn);
      await tester.pump();
      await tester.runAsync(() async => await Future.delayed(const Duration(milliseconds: 600)));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(micBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Nailed It'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable).first);
      scrollable.position.jumpTo(0.0);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // sampleQuest1 has professionalismRating 5 -> (5 / 5.0) * 0.3 = 0.3 boost -> 50% + 30% = 80%
      expect(find.text('80% COMPATIBLE'), findsOneWidget);
    });

    testWidgets('37. tapping Needs Work calls submitWrongAnswer and drops mercuryLevel',
        (tester) async {
      await pumpJobInterviewScreen(tester);
      final correctOptionText = sampleQuest1.correctAnswer!;
      await tester.tap(findOptionByText(correctOptionText));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final manualBtn = find.text('Evaluate myself manually');
      await tester.tap(manualBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final micBtn = find.byKey(const ValueKey('speaking_mic_btn'));
      await tester.tap(micBtn);
      await tester.pump();
      await tester.runAsync(() async => await Future.delayed(const Duration(milliseconds: 600)));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(micBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final needsWorkBtn = find.text('Needs Work');
      expect(needsWorkBtn, findsOneWidget);
      await tester.tap(needsWorkBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(
        () => mockRoleplayBloc.add(
          any(that: isA<SubmitAnswer>().having((e) => e.isCorrect, 'isCorrect', false)),
        ),
      ).called(1);
      verify(() => mockSoundService.playWrong()).called(1);

      // Bring telemetry dashboard back into view
      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable).first);
      scrollable.position.jumpTo(0.0);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('30% COMPATIBLE'), findsOneWidget);
    });

    testWidgets('38. fallback boost (0.25) is used when professionalismRating is null',
        (tester) async {
      const questNoProf = RoleplayQuest(
        id: 'ji_no_prof',
        instruction: 'Pick answer',
        difficulty: 1,
        subtype: GameSubtype.jobInterview,
        interviewerQuestion: 'Why should we hire you?',
        options: ['Because I am dedicated and skilled.', 'No reason.'],
        correctAnswerIndex: 0,
        correctAnswer: 'Because I am dedicated and skilled.',
        professionalismRating: null,
      );
      final state = testLoadedState.copyWith(quests: [questNoProf]);
      await pumpJobInterviewScreen(tester, state: state);

      await tester.tap(findOptionByText('Because I am dedicated and skilled.'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Evaluate myself manually'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final micBtn = find.byKey(const ValueKey('speaking_mic_btn'));
      await tester.tap(micBtn);
      await tester.pump();
      await tester.runAsync(() async => await Future.delayed(const Duration(milliseconds: 600)));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(micBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.text('Nailed It'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Bring telemetry dashboard back into view
      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable).first);
      scrollable.position.jumpTo(0.0);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 50% + 25% fallback = 75%
      expect(find.text('75% COMPATIBLE'), findsOneWidget);
    });
  });

  group('Answer Lockout & Navigation Tests', () {
    testWidgets('39. once answered, tapping other options does not trigger events',
        (tester) async {
      await pumpJobInterviewScreen(tester);
      final wrongOptionText = sampleQuest1.options![1];
      await tester.tap(findOptionByText(wrongOptionText));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      clearInteractions(mockRoleplayBloc);

      // Attempt to tap another option
      final anotherOption = sampleQuest1.options![2];
      await tester.tap(findOptionByText(anotherOption), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verifyZeroInteractions(mockRoleplayBloc);
    });

    testWidgets('40. once answered, bottom bar renders CONTINUE button',
        (tester) async {
      await pumpJobInterviewScreen(tester);
      final answeredState = testLoadedState.copyWith(
        answerStatus: AnswerStatus.correct,
      );
      when(() => mockRoleplayBloc.state).thenReturn(answeredState);
      roleplayStreamController.add(answeredState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final continueBtn = find.text('CONTINUE');
      expect(continueBtn, findsOneWidget);
      await tester.tap(continueBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('41. tapping CONTINUE dispatches NextQuestion event',
        (tester) async {
      await pumpJobInterviewScreen(tester);
      final answeredState = testLoadedState.copyWith(
        answerStatus: AnswerStatus.correct,
      );
      when(() => mockRoleplayBloc.state).thenReturn(answeredState);
      roleplayStreamController.add(answeredState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final continueBtn = find.text('CONTINUE');
      expect(continueBtn, findsOneWidget);
      await tester.tap(continueBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockRoleplayBloc.add(any(that: isA<NextQuestion>()))).called(1);
    });
  });

  group('Question Transition & Lifecycle Tests', () {
    testWidgets('42. onQuestionReset resets mercury level to 50%', (tester) async {
      await pumpJobInterviewScreen(tester);
      // Drop mercury level by wrong answer
      final wrongOptionText = sampleQuest1.options![1];
      await tester.tap(findOptionByText(wrongOptionText));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('30% COMPATIBLE'), findsOneWidget);

      // Transition to next quest
      final nextQuestState = testLoadedState.copyWith(currentIndex: 1);
      when(() => mockRoleplayBloc.state).thenReturn(nextQuestState);
      roleplayStreamController.add(nextQuestState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('50% COMPATIBLE'), findsOneWidget);
    });

    testWidgets('43. tapping hint button dispatches RoleplayHintUsed',
        (tester) async {
      await pumpJobInterviewScreen(tester);
      await tester.tap(find.byType(QuestHintButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockRoleplayBloc.add(any(that: isA<RoleplayHintUsed>()))).called(1);
    });

    testWidgets('44. Level 1 displays GameBriefingLayer with Career Closer',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'has_seen_briefing_jobInterview': false,
      });

      await pumpJobInterviewScreen(
        tester,
        level: 1,
        size: const Size(390, 1100),
      );

      expect(find.byType(GameBriefingLayer), findsOneWidget);
      expect(find.text('CAREER CLOSER'), findsOneWidget);
      expect(find.text('START INTERVIEW'), findsOneWidget);

      await tester.tap(find.text('START INTERVIEW'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(GameBriefingLayer), findsNothing);
    });

    testWidgets('45. GameShimmerLoading renders when state is RoleplayInitial', (tester) async {
      await pumpJobInterviewScreen(tester, state: const RoleplayInitial());
      expect(find.byType(GameShimmerLoading), findsOneWidget);
      expect(find.byType(JobInterviewInterviewerPanel), findsNothing);
    });

    testWidgets('46. Game over state renders cleanly without error', (tester) async {
      const gameOverState = RoleplayGameOver(
        quests: [sampleQuest1],
        currentIndex: 0,
        gameType: GameSubtype.jobInterview,
        level: 2,
      );
      await pumpJobInterviewScreen(tester, state: gameOverState);
      expect(find.byType(JobInterviewScreen), findsOneWidget);
    });
  });

  group('Themes, Responsiveness & Motion Tests', () {
    testWidgets('47. renders cleanly in light theme mode', (tester) async {
      await pumpJobInterviewScreen(tester, themeMode: ThemeMode.light);
      expect(find.byType(JobInterviewInstruction), findsOneWidget);
      expect(find.byType(JobInterviewTelemetryDashboard), findsOneWidget);
      expect(find.byType(JobInterviewInterviewerPanel), findsOneWidget);
      expect(find.byType(JobInterviewResponseConsole), findsOneWidget);
    });

    testWidgets('48. renders cleanly in dark theme mode', (tester) async {
      await pumpJobInterviewScreen(tester, themeMode: ThemeMode.dark);
      expect(find.byType(JobInterviewInstruction), findsOneWidget);
      expect(find.byType(JobInterviewTelemetryDashboard), findsOneWidget);
      expect(find.byType(JobInterviewInterviewerPanel), findsOneWidget);
      expect(find.byType(JobInterviewResponseConsole), findsOneWidget);
    });

    testWidgets('49. renders on compact mobile (320x568) with zero overflow',
        (tester) async {
      await pumpJobInterviewScreen(
        tester,
        size: const Size(320, 568),
      );
      expect(find.byType(JobInterviewInstruction), findsOneWidget);
      expect(find.byType(JobInterviewTelemetryDashboard), findsOneWidget);
      expect(find.byType(JobInterviewInterviewerPanel), findsOneWidget);
      expect(find.byType(JobInterviewResponseConsole), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('50. reduceMotion suppresses repeating animations without errors',
        (tester) async {
      await pumpJobInterviewScreen(tester, reduceMotion: true);
      expect(find.byType(JobInterviewInstruction), findsOneWidget);
      expect(find.byType(JobInterviewTelemetryDashboard), findsOneWidget);
      expect(find.byType(JobInterviewInterviewerPanel), findsOneWidget);
      expect(find.byType(JobInterviewResponseConsole), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

