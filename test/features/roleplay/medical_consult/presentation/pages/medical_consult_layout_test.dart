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
import 'package:vowl/features/roleplay/medical_consult/presentation/pages/medical_consult_screen.dart';
import 'package:vowl/features/roleplay/medical_consult/presentation/widgets/medical_consult_body_diagram.dart';
import 'package:vowl/features/roleplay/medical_consult/presentation/widgets/medical_consult_diagnostic_tray.dart';
import 'package:vowl/features/roleplay/medical_consult/presentation/widgets/medical_consult_instruction.dart';
import 'package:vowl/features/roleplay/medical_consult/presentation/widgets/medical_consult_patient_record.dart';
import 'package:vowl/features/roleplay/medical_consult/presentation/widgets/medical_consult_radar_painter.dart';
import 'package:vowl/features/roleplay/medical_consult/presentation/widgets/medical_consult_scan_bay.dart';

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
    id: 'mc_1',
    instruction: 'Identify and confirm the patient diagnosis.',
    difficulty: 1,
    subtype: GameSubtype.medicalConsult,
    prompt: 'Patient reports severe throbbing headache and blurred vision.',
    symptoms: ['Migraine', 'Nausea', 'Vision Impairment', 'Fatigue'],
    correctAnswer: 'Migraine, Vision Impairment',
    medicalVocab: ['Cephalea', 'Photophobia', 'Ophthalmic'],
    hint: 'Look for symptoms related to the head and sight.',
    explanation: 'Migraine accompanied by visual aura matches the reported complaint.',
  );

  const sampleQuest2 = RoleplayQuest(
    id: 'mc_2',
    instruction: 'Scan and diagnose acute thoracic complaint.',
    difficulty: 2,
    subtype: GameSubtype.medicalConsult,
    prompt: 'Patient experiences sharp chest discomfort and irregular palpitations.',
    symptoms: ['Chest Pain', 'Palpitations', 'Knee Strain', 'Dizziness'],
    correctAnswer: 'Chest Pain, Palpitations',
    medicalVocab: ['Angina', 'Arrhythmia', 'Cardiology'],
    hint: 'Focus on cardiac and thoracic anomalies.',
    explanation: 'Chest pain and palpitations require immediate cardiovascular assessment.',
  );

  final testLoadedState = RoleplayLoaded(
    quests: const [sampleQuest1, sampleQuest2],
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
    hintUsed: false,
    gameType: GameSubtype.medicalConsult,
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
      'has_seen_briefing_medicalConsult': true,
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
        .thenAnswer((_) async => '/tmp/medical_consult_test.m4a');
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

  Future<void> pumpMedicalConsultScreen(
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
                body: MedicalConsultScreen(
                  level: level,
                  gameType: GameSubtype.medicalConsult,
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

  Finder findSymptomChip(String symptom) =>
      find.byKey(Key('medical_consult_symptom_chip_${symptom.replaceAll(' ', '_')}'));

  Future<void> tapConfirm(WidgetTester tester) async {
    final finder = find.byKey(const Key('medical_consult_confirm_button'));
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> tapReset(WidgetTester tester) async {
    final finder = find.byKey(const Key('medical_consult_reset_button'));
    await tester.ensureVisible(finder);
    await tester.pump();
    await tester.tap(finder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('MedicalConsultScreen Layout & Rendering Hierarchy', () {
    testWidgets('1. renders MedicalConsultInstruction on screen', (tester) async {
      await pumpMedicalConsultScreen(tester);
      expect(find.byType(MedicalConsultInstruction), findsOneWidget);
      expect(
        find.byKey(const Key('medical_consult_instruction')),
        findsOneWidget,
      );
    });

    testWidgets('2. renders MedicalConsultPatientRecord on screen', (tester) async {
      await pumpMedicalConsultScreen(tester);
      expect(find.byType(MedicalConsultPatientRecord), findsOneWidget);
      expect(
        find.byKey(const Key('medical_consult_patient_record')),
        findsOneWidget,
      );
    });

    testWidgets('3. renders MedicalConsultScanBay on screen', (tester) async {
      await pumpMedicalConsultScreen(tester);
      expect(find.byType(MedicalConsultScanBay), findsOneWidget);
      expect(
        find.byKey(const Key('medical_consult_scan_bay')),
        findsOneWidget,
      );
    });

    testWidgets('4. renders MedicalConsultDiagnosticTray on screen', (tester) async {
      await pumpMedicalConsultScreen(tester);
      expect(find.byType(MedicalConsultDiagnosticTray), findsOneWidget);
      expect(
        find.byKey(const Key('medical_consult_diagnostic_tray')),
        findsOneWidget,
      );
    });

    testWidgets('5. renders app bar with GameProgressHeader and lives', (tester) async {
      await pumpMedicalConsultScreen(tester);
      expect(find.byType(GameProgressHeader), findsOneWidget);
      expect(find.descendant(of: find.byType(GameProgressHeader), matching: find.text('3')), findsWidgets);
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    });
  });

  group('Instruction Component Tests', () {
    testWidgets('6. displays custom quest instruction text', (tester) async {
      await pumpMedicalConsultScreen(tester);
      expect(find.text(sampleQuest1.instruction), findsOneWidget);
    });

    testWidgets('7. instruction widget falls back to default text when null', (tester) async {
      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, child) => const MaterialApp(
            home: Scaffold(
              body: MedicalConsultInstruction(
                primaryColor: Colors.blue,
                instruction: null,
              ),
            ),
          ),
        ),
      );

      expect(
        find.text('Examine the patient and identify the matching symptoms.'),
        findsOneWidget,
      );
    });

    testWidgets('8. instruction container has rounded border decoration', (tester) async {
      await pumpMedicalConsultScreen(tester);
      final container = tester.widget<Container>(
        find.byKey(const Key('medical_consult_instruction')),
      );
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.borderRadius, BorderRadius.circular(16.r));
    });
  });

  group('Patient Record Component Tests', () {
    testWidgets('9. displays PATIENT COMPLAINT header text', (tester) async {
      await pumpMedicalConsultScreen(tester);
      expect(find.text('PATIENT COMPLAINT'), findsOneWidget);
    });

    testWidgets('10. displays patient complaint prompt string', (tester) async {
      await pumpMedicalConsultScreen(tester);
      expect(find.text(sampleQuest1.prompt!), findsOneWidget);
    });

    testWidgets('11. renders person outline icon in record card', (tester) async {
      await pumpMedicalConsultScreen(tester);
      expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
    });
  });

  group('Holographic Scan Bay & Radar Tests', () {
    testWidgets('12. renders BiometricRadarPainter in CustomPaint', (tester) async {
      await pumpMedicalConsultScreen(tester);
      final customPaintFinder = find.descendant(
        of: find.byKey(const Key('medical_consult_scan_bay')),
        matching: find.byType(CustomPaint),
      );
      expect(customPaintFinder, findsWidgets);
      final hasRadar = tester.widgetList<CustomPaint>(customPaintFinder).any(
        (cp) => cp.painter is BiometricRadarPainter,
      );
      expect(hasRadar, isTrue);
    });

    testWidgets('13. renders wireframe patient body icon', (tester) async {
      await pumpMedicalConsultScreen(tester);
      expect(
        find.descendant(
          of: find.byKey(const Key('medical_consult_scan_bay')),
          matching: find.byIcon(Icons.accessibility_new_rounded),
        ),
        findsOneWidget,
      );
    });

    testWidgets('14. renders interactive drag-to-scan lens', (tester) async {
      await pumpMedicalConsultScreen(tester);
      expect(
        find.byKey(const Key('medical_consult_scan_lens')),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.center_focus_strong_rounded), findsOneWidget);
    });

    testWidgets('15. renders anomaly circles for all symptoms in quest', (tester) async {
      await pumpMedicalConsultScreen(tester);
      for (int i = 0; i < sampleQuest1.symptoms!.length; i++) {
        expect(find.byKey(Key('medical_consult_anomaly_$i')), findsOneWidget);
      }
    });

    testWidgets('16. unscanned anomaly circle displays warning_rounded icon', (tester) async {
      await pumpMedicalConsultScreen(tester);
      final firstAnomaly = find.byKey(const Key('medical_consult_anomaly_0'));
      expect(
        find.descendant(of: firstAnomaly, matching: find.byIcon(Icons.warning_rounded)),
        findsOneWidget,
      );
    });

    testWidgets('17. tapping anomaly circle directly marks it scanned and triggers audio/haptic',
        (tester) async {
      await pumpMedicalConsultScreen(tester);
      final firstAnomaly = find.byKey(const Key('medical_consult_anomaly_0'));
      await tester.tap(firstAnomaly);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockHapticService.selection()).called(1);
      verify(() => mockSoundService.playHint()).called(1);

      // Now it displays check_circle_outline_rounded
      expect(
        find.descendant(
          of: firstAnomaly,
          matching: find.byIcon(Icons.check_circle_outline_rounded),
        ),
        findsOneWidget,
      );
    });

    testWidgets('18. tapping anomaly circle twice does not duplicate scan trigger',
        (tester) async {
      await pumpMedicalConsultScreen(tester);
      final firstAnomaly = find.byKey(const Key('medical_consult_anomaly_0'));
      await tester.tap(firstAnomaly);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      clearInteractions(mockHapticService);
      clearInteractions(mockSoundService);

      await tester.tap(firstAnomaly);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verifyNever(() => mockHapticService.selection());
      verifyNever(() => mockSoundService.playHint());
    });

    testWidgets('19. dragging scan lens moves offset cleanly without crash', (tester) async {
      await pumpMedicalConsultScreen(tester);
      final lensFinder = find.byKey(const Key('medical_consult_scan_lens'));
      await tester.drag(lensFinder, const Offset(30, -30));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(lensFinder, findsOneWidget);
    });
  });

  group('Diagnostic Tray & Symptom Unlocking Tests', () {
    testWidgets('20. diagnostic tray displays DIAGNOSTIC OPTIONS title', (tester) async {
      await pumpMedicalConsultScreen(tester);
      expect(find.text('DIAGNOSTIC OPTIONS'), findsOneWidget);
    });

    testWidgets('21. renders symptom chips for all quest symptoms', (tester) async {
      await pumpMedicalConsultScreen(tester);
      for (final symptom in sampleQuest1.symptoms!) {
        expect(find.text(symptom.toUpperCase()), findsOneWidget);
      }
    });

    testWidgets('22. unscanned symptom chip displays lock_outline_rounded icon', (tester) async {
      await pumpMedicalConsultScreen(tester);
      final chip = findSymptomChip('Migraine');
      expect(
        find.descendant(of: chip, matching: find.byIcon(Icons.lock_outline_rounded)),
        findsOneWidget,
      );
    });

    testWidgets('23. tapping unscanned symptom chip triggers error haptic and snackbar',
        (tester) async {
      await pumpMedicalConsultScreen(tester);
      final chip = findSymptomChip('Migraine');
      await tester.tap(chip);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockHapticService.error()).called(1);
      expect(
        find.text('Examine the patient with the scanner to identify symptoms first.'),
        findsOneWidget,
      );
    });

    testWidgets('24. scanned symptom chip displays biotech_rounded icon', (tester) async {
      await pumpMedicalConsultScreen(tester);
      // Scan Migraine (index 0)
      await tester.tap(find.byKey(const Key('medical_consult_anomaly_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final chip = findSymptomChip('Migraine');
      expect(
        find.descendant(of: chip, matching: find.byIcon(Icons.biotech_rounded)),
        findsOneWidget,
      );
    });

    testWidgets('25. tapping scanned symptom chip selects it and shows check_circle_rounded icon',
        (tester) async {
      await pumpMedicalConsultScreen(tester);
      // Scan Migraine
      await tester.tap(find.byKey(const Key('medical_consult_anomaly_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap to select Migraine
      await tester.tap(findSymptomChip('Migraine'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockHapticService.selection()).called(2); // scan + select
      final chip = findSymptomChip('Migraine');
      expect(
        find.descendant(of: chip, matching: find.byIcon(Icons.check_circle_rounded)),
        findsOneWidget,
      );
    });

    testWidgets('26. tapping selected symptom chip deselects it and reverts to biotech icon',
        (tester) async {
      await pumpMedicalConsultScreen(tester);
      await tester.tap(find.byKey(const Key('medical_consult_anomaly_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Select
      await tester.tap(findSymptomChip('Migraine'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Deselect
      await tester.tap(findSymptomChip('Migraine'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      final chip = findSymptomChip('Migraine');
      expect(
        find.descendant(of: chip, matching: find.byIcon(Icons.biotech_rounded)),
        findsOneWidget,
      );
    });
  });

  group('Diagnosis Selection & Action Button Mechanics', () {
    testWidgets('27. action buttons (Confirm and Reset Scan) are hidden initially',
        (tester) async {
      await pumpMedicalConsultScreen(tester);
      expect(find.byKey(const Key('medical_consult_confirm_button')), findsNothing);
      expect(find.byKey(const Key('medical_consult_reset_button')), findsNothing);
    });

    testWidgets('28. action buttons appear when at least one symptom is diagnosed',
        (tester) async {
      await pumpMedicalConsultScreen(tester);
      await tester.tap(find.byKey(const Key('medical_consult_anomaly_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(findSymptomChip('Migraine'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const Key('medical_consult_confirm_button')), findsOneWidget);
      expect(find.byKey(const Key('medical_consult_reset_button')), findsOneWidget);
    });

    testWidgets('29. tapping Reset Scan button clears diagnosed symptoms and hides buttons',
        (tester) async {
      await pumpMedicalConsultScreen(tester);
      await tester.tap(find.byKey(const Key('medical_consult_anomaly_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(findSymptomChip('Migraine'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const Key('medical_consult_reset_button')), findsOneWidget);
      await tapReset(tester);

      expect(find.byKey(const Key('medical_consult_confirm_button')), findsNothing);
      expect(find.byKey(const Key('medical_consult_reset_button')), findsNothing);
      // Migraine reverts to locked
      expect(
        find.descendant(
          of: findSymptomChip('Migraine'),
          matching: find.byIcon(Icons.lock_outline_rounded),
        ),
        findsOneWidget,
      );
    });

    testWidgets('30. tapping Confirm with incorrect diagnosis submits wrong answer to BLoC',
        (tester) async {
      await pumpMedicalConsultScreen(tester);
      // Scan and select only Migraine (missing Vision Impairment)
      await tester.tap(find.byKey(const Key('medical_consult_anomaly_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(findSymptomChip('Migraine'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tapConfirm(tester);

      verify(
        () => mockRoleplayBloc.add(
          any(that: isA<SubmitAnswer>().having((e) => e.isCorrect, 'isCorrect', false)),
        ),
      ).called(1);
    });

    testWidgets('31. incorrect diagnosis does NOT mount SpeakToConfirmOverlay',
        (tester) async {
      await pumpMedicalConsultScreen(tester);
      await tester.tap(find.byKey(const Key('medical_consult_anomaly_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(findSymptomChip('Migraine'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tapConfirm(tester);

      expect(find.byType(SpeakToConfirmOverlay), findsNothing);
      expect(find.byKey(const Key('medical_consult_speak_overlay')), findsNothing);
    });

    testWidgets('32. tapping Confirm with correct diagnosis advances to Phase 2 SpeakToConfirmOverlay',
        (tester) async {
      await pumpMedicalConsultScreen(tester);
      // Scan and select Migraine (index 0)
      await tester.tap(find.byKey(const Key('medical_consult_anomaly_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(findSymptomChip('Migraine'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Scan and select Vision Impairment (index 2)
      await tester.tap(find.byKey(const Key('medical_consult_anomaly_2')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(findSymptomChip('Vision Impairment'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap Confirm
      await tapConfirm(tester);

      // Should NOT submit answer early to BLoC
      verifyNever(() => mockRoleplayBloc.add(any(that: isA<SubmitAnswer>())));

      // SpeakToConfirmOverlay should be mounted
      expect(find.byType(SpeakToConfirmOverlay), findsOneWidget);
      expect(find.byKey(const Key('medical_consult_speak_overlay')), findsOneWidget);
    });

    testWidgets('33. in Phase 2 action buttons are hidden', (tester) async {
      await pumpMedicalConsultScreen(tester);
      await tester.tap(find.byKey(const Key('medical_consult_anomaly_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(findSymptomChip('Migraine'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byKey(const Key('medical_consult_anomaly_2')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(findSymptomChip('Vision Impairment'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tapConfirm(tester);

      expect(find.byKey(const Key('medical_consult_confirm_button')), findsNothing);
      expect(find.byKey(const Key('medical_consult_reset_button')), findsNothing);
    });
  });

  group('Phase 2 Speech Confirmation & Evaluation', () {
    testWidgets('34. SpeakToConfirmOverlay displays expectedText matching correctAnswer',
        (tester) async {
      await pumpMedicalConsultScreen(tester);
      await tester.tap(find.byKey(const Key('medical_consult_anomaly_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(findSymptomChip('Migraine'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byKey(const Key('medical_consult_anomaly_2')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(findSymptomChip('Vision Impairment'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tapConfirm(tester);

      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byKey(const Key('medical_consult_speak_overlay')),
      );
      expect(overlay.expectedText, sampleQuest1.correctAnswer);
    });

    testWidgets('35. tapping Nailed It dispatches RoleplaySpeakConfirmed(5) and SubmitAnswer(true)',
        (tester) async {
      await pumpMedicalConsultScreen(tester);
      await tester.tap(find.byKey(const Key('medical_consult_anomaly_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(findSymptomChip('Migraine'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byKey(const Key('medical_consult_anomaly_2')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(findSymptomChip('Vision Impairment'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tapConfirm(tester);

      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byType(SpeakToConfirmOverlay),
      );
      overlay.onConfirmed();
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

    testWidgets('36. tapping Needs Work calls submitWrongAnswer and SubmitAnswer(false)',
        (tester) async {
      await pumpMedicalConsultScreen(tester);
      await tester.tap(find.byKey(const Key('medical_consult_anomaly_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(findSymptomChip('Migraine'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byKey(const Key('medical_consult_anomaly_2')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(findSymptomChip('Vision Impairment'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tapConfirm(tester);

      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byType(SpeakToConfirmOverlay),
      );
      overlay.onSkipped();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(
        () => mockRoleplayBloc.add(
          any(that: isA<SubmitAnswer>().having((e) => e.isCorrect, 'isCorrect', false)),
        ),
      ).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
    });

    testWidgets('37. once answered, SpeakToConfirmOverlay unmounts', (tester) async {
      await pumpMedicalConsultScreen(tester);
      await tester.tap(find.byKey(const Key('medical_consult_anomaly_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(findSymptomChip('Migraine'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byKey(const Key('medical_consult_anomaly_2')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(findSymptomChip('Vision Impairment'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tapConfirm(tester);

      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byType(SpeakToConfirmOverlay),
      );
      overlay.onConfirmed();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      roleplayStreamController.add(testLoadedState.copyWith(answerStatus: AnswerStatus.correct));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const Key('medical_consult_speak_overlay')), findsNothing);
    });

    testWidgets('38. once answered, bottom bar renders CONTINUE button', (tester) async {
      await pumpMedicalConsultScreen(tester);
      await tester.tap(find.byKey(const Key('medical_consult_anomaly_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(findSymptomChip('Migraine'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byKey(const Key('medical_consult_anomaly_2')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(findSymptomChip('Vision Impairment'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tapConfirm(tester);

      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byType(SpeakToConfirmOverlay),
      );
      overlay.onConfirmed();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      roleplayStreamController.add(testLoadedState.copyWith(answerStatus: AnswerStatus.correct));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('CONTINUE'), findsOneWidget);
    });
  });

  group('Post-Answer Body Diagram & Vocabulary', () {
    testWidgets('39. in answered state, MedicalConsultBodyDiagram renders', (tester) async {
      await pumpMedicalConsultScreen(tester);
      // Select incorrect diagnosis to quickly transition to answered
      await tester.tap(find.byKey(const Key('medical_consult_anomaly_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(findSymptomChip('Migraine'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tapConfirm(tester);

      expect(find.byType(MedicalConsultBodyDiagram), findsOneWidget);
      expect(
        find.byKey(const Key('medical_consult_body_diagram')),
        findsOneWidget,
      );
    });

    testWidgets('40. MedicalConsultBodyDiagram displays MEDICAL VOCABULARY header', (tester) async {
      await pumpMedicalConsultScreen(tester);
      await tester.tap(find.byKey(const Key('medical_consult_anomaly_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(findSymptomChip('Migraine'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tapConfirm(tester);

      expect(find.text('MEDICAL VOCABULARY'), findsOneWidget);
    });

    testWidgets('41. MedicalConsultBodyDiagram displays vocab items from quest', (tester) async {
      await pumpMedicalConsultScreen(tester);
      await tester.tap(find.byKey(const Key('medical_consult_anomaly_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(findSymptomChip('Migraine'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tapConfirm(tester);

      for (final vocab in sampleQuest1.medicalVocab!) {
        expect(find.text(vocab.toUpperCase()), findsOneWidget);
      }
    });

    testWidgets('42. quest without medicalVocab renders SizedBox in body diagram', (tester) async {
      const questNoVocab = RoleplayQuest(
        id: 'mc_no_vocab',
        instruction: 'Diagnose',
        difficulty: 1,
        subtype: GameSubtype.medicalConsult,
        prompt: 'Patient with fever',
        symptoms: ['Fever'],
        correctAnswer: 'Fever',
        medicalVocab: null,
      );
      final state = testLoadedState.copyWith(quests: [questNoVocab]);
      await pumpMedicalConsultScreen(tester, state: state);
      roleplayStreamController.add(state.copyWith(answerStatus: AnswerStatus.correct));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(MedicalConsultBodyDiagram), findsOneWidget);
      expect(find.byKey(const Key('medical_consult_body_diagram')), findsNothing);
    });
  });

  group('Question Transition & Lifecycle Tests', () {
    testWidgets('43. tapping CONTINUE dispatches NextQuestion event', (tester) async {
      await pumpMedicalConsultScreen(tester);
      await tester.tap(find.byKey(const Key('medical_consult_anomaly_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(findSymptomChip('Migraine'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byKey(const Key('medical_consult_anomaly_2')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(findSymptomChip('Vision Impairment'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tapConfirm(tester);

      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byType(SpeakToConfirmOverlay),
      );
      overlay.onConfirmed();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      roleplayStreamController.add(testLoadedState.copyWith(answerStatus: AnswerStatus.correct));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final continueBtn = find.text('CONTINUE');
      expect(continueBtn, findsOneWidget);
      await tester.tap(continueBtn);
      await tester.pump();

      verify(() => mockRoleplayBloc.add(const NextQuestion())).called(1);
    });

    testWidgets('44. tapping hint button dispatches RoleplayHintUsed', (tester) async {
      await pumpMedicalConsultScreen(tester);
      final hintButton = find.byType(QuestHintButton);
      expect(hintButton, findsOneWidget);
      await tester.tap(hintButton);
      await tester.pump();

      verify(() => mockRoleplayBloc.add(const RoleplayHintUsed())).called(1);
    });

    testWidgets('45. Level 1 displays GameBriefingLayer overlay with Medical briefing',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'has_seen_briefing_medicalConsult': false,
      });
      await pumpMedicalConsultScreen(tester, level: 1);
      expect(find.byType(GameBriefingLayer), findsOneWidget);
      expect(find.text('HEALTH LIAISON'), findsOneWidget);
    });

    testWidgets('46. GameShimmerLoading renders when state is RoleplayInitial', (tester) async {
      await pumpMedicalConsultScreen(
        tester,
        state: const RoleplayInitial(),
      );
      expect(find.byType(GameShimmerLoading), findsOneWidget);
    });
  });

  group('Themes, Responsiveness & Motion Tests', () {
    testWidgets('47. renders cleanly in light theme mode', (tester) async {
      await pumpMedicalConsultScreen(tester, themeMode: ThemeMode.light);
      expect(find.byType(MedicalConsultScreen), findsOneWidget);
      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('48. renders cleanly in dark theme mode', (tester) async {
      await pumpMedicalConsultScreen(tester, themeMode: ThemeMode.dark);
      expect(find.byType(MedicalConsultScreen), findsOneWidget);
      expect(find.byType(CustomScrollView), findsOneWidget);
    });

    testWidgets('49. renders on compact mobile (320x568) with zero overflow', (tester) async {
      await pumpMedicalConsultScreen(
        tester,
        size: const Size(320, 568),
      );
      expect(find.byType(MedicalConsultScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('50. reduceMotion suppresses repeating animations without errors',
        (tester) async {
      await pumpMedicalConsultScreen(tester, reduceMotion: true);
      expect(find.byType(MedicalConsultScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
