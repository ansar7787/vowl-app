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
import 'package:vowl/features/roleplay/emergency_hub/presentation/pages/emergency_hub_screen.dart';

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
    id: 'eh_1',
    instruction: 'Broadcast emergency coordinates to rescue dispatch.',
    difficulty: 1,
    subtype: GameSubtype.emergencyHub,
    dispatcherQuestion:
        'Mayday Mayday! Reactor core pressure spiking. Transmit stabilization override phrase!',
    urgencyLevel: 4,
    correctAnswer: 'Alpha Vector Seven Nine Zero',
    hint: 'State Alpha Vector first.',
    explanation:
        'Clear NATO phonetic transmission ensures immediate dispatch recognition.',
  );

  const sampleQuest2 = RoleplayQuest(
    id: 'eh_2',
    instruction: 'Deploy perimeter evacuation signal.',
    difficulty: 2,
    subtype: GameSubtype.emergencyHub,
    dispatcherQuestion:
        'Perimeter breached in Sector Four. Send containment order immediately!',
    urgencyLevel: 5,
    correctAnswer: 'Containment Lockdown Sector Four',
    hint: 'Containment Lockdown.',
    explanation: 'Standard security containment broadcast protocol.',
  );

  final testLoadedState = RoleplayLoaded(
    quests: const [sampleQuest1, sampleQuest2],
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
    hintUsed: false,
    gameType: GameSubtype.emergencyHub,
    level: 2,
    wrongCount: 0,
    isFinalFailure: false,
  );

  setUpAll(() {
    registerFallbackValue(FakeRoleplayEvent());
    registerFallbackValue(FakeRoleplayState());
    registerFallbackValue(const NextQuestion());
    registerFallbackValue(const SubmitAnswer(true));
    registerFallbackValue(const SubmitAnswer(false));
    registerFallbackValue(const RoleplayHintUsed());
    registerFallbackValue(const RoleplaySpeakConfirmed(5));
    registerFallbackValue(const Duration(milliseconds: 50));
    VowlMotion.lowAnimationModeOverride.value = true;
  });

  tearDownAll(() {
    VowlMotion.lowAnimationModeOverride.value = false;
  });

  setUp(() {
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

    when(() => mockAudioRecorder.hasPermission()).thenAnswer((_) async => true);
    when(() => mockAudioRecorder.startRecording()).thenAnswer((_) async => true);
    when(() => mockAudioRecorder.stopRecording())
        .thenAnswer((_) async => '/tmp/emergency_hub_test.m4a');
    when(() => mockAudioRecorder.isRecording).thenReturn(false);
    when(() => mockAudioRecorder.onAmplitudeChanged(any()))
        .thenAnswer((_) => Stream.value(Amplitude(current: -10, max: -5)));
    when(() => mockAudioRecorder.dispose()).thenAnswer((_) async {});

    VowlMotion.lowAnimationModeOverride.value = true;

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
      'has_seen_briefing_emergencyHub': true,
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
    VowlMotion.lowAnimationModeOverride.value = false;
    await roleplayStreamController.close();
  });

  Future<void> pumpEmergencyHubScreen(
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
              child: EmergencyHubScreen(
                level: level,
                gameType: GameSubtype.emergencyHub,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Finder findChip(String word) => find.descendant(
        of: find.byKey(const Key('emergency_hub_word_chips_wrap')),
        matching: find.text(word),
      );

  group('EmergencyHubScreen Layout & Mechanics Tests', () {
    testWidgets('1. Initial layout renders TelexCard, TerminalInput, ValveChamber, and no launch button initially', (tester) async {
      await pumpEmergencyHubScreen(tester);

      expect(find.byKey(const Key('emergency_hub_telex_card')), findsOneWidget);
      expect(find.byKey(const Key('emergency_hub_terminal_input')), findsOneWidget);
      expect(find.byKey(const Key('emergency_hub_valve_chamber')), findsOneWidget);
      expect(find.byKey(const Key('emergency_hub_launch_button')), findsNothing);
    });

    testWidgets('2. TelexCard renders warning icon, broadcast title, instruction, dispatcher question, and urgency label', (tester) async {
      await pumpEmergencyHubScreen(tester);

      expect(find.byKey(const Key('emergency_hub_telex_warning_icon')), findsOneWidget);
      expect(find.byKey(const Key('emergency_hub_telex_broadcast_title')), findsOneWidget);
      expect(find.text('INCOMING BROADCAST'), findsOneWidget);
      expect(find.byKey(const Key('emergency_hub_telex_instruction_text')), findsOneWidget);
      expect(find.byKey(const Key('emergency_hub_telex_question_text')), findsOneWidget);
      expect(find.byKey(const Key('emergency_hub_telex_urgency_label')), findsOneWidget);
    });

    testWidgets('3. Formatted instruction text displays uppercase instruction from quest', (tester) async {
      await pumpEmergencyHubScreen(tester);

      expect(find.text(sampleQuest1.instruction), findsOneWidget);
    });

    testWidgets('4. Dispatcher question text rendering matches custom quest prompt', (tester) async {
      await pumpEmergencyHubScreen(tester);

      expect(find.text(sampleQuest1.dispatcherQuestion!), findsOneWidget);
    });

    testWidgets('5. Urgency level bars display exactly 5 bars with correct active count', (tester) async {
      await pumpEmergencyHubScreen(tester);

      for (int i = 0; i < 5; i++) {
        expect(find.byKey(Key('emergency_hub_urgency_bar_$i')), findsOneWidget);
      }
    });

    testWidgets('6. Urgency level fallback renders cleanly when quest urgencyLevel is null', (tester) async {
      const nullUrgencyQuest = RoleplayQuest(
        id: 'eh_null_urgency',
        instruction: 'Broadcast override.',
        difficulty: 1,
        subtype: GameSubtype.emergencyHub,
        dispatcherQuestion: 'Alert question',
        urgencyLevel: null,
        correctAnswer: 'Alpha Beta',
      );
      final nullState = testLoadedState.copyWith(
        quests: [nullUrgencyQuest],
      );
      await pumpEmergencyHubScreen(tester, state: nullState);

      for (int i = 0; i < 5; i++) {
        expect(find.byKey(Key('emergency_hub_urgency_bar_$i')), findsOneWidget);
      }
    });

    testWidgets('7. TerminalInput renders INPUT TERMINAL header, keyboard icon, and placeholder', (tester) async {
      await pumpEmergencyHubScreen(tester);

      expect(find.text('INPUT TERMINAL'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_rounded), findsOneWidget);
      expect(find.byKey(const Key('emergency_hub_terminal_text_field')), findsOneWidget);
      expect(find.text('Select words to build broadcast'), findsOneWidget);
    });

    testWidgets('8. Word chips wrap renders chips corresponding to words in correctAnswer', (tester) async {
      await pumpEmergencyHubScreen(tester);

      expect(find.byKey(const Key('emergency_hub_word_chips_wrap')), findsOneWidget);

      final words = sampleQuest1.correctAnswer!.split(' ');
      for (final word in words) {
        expect(find.text(word), findsOneWidget);
      }
    });

    testWidgets('9. Tapping a word chip adds word to TextField and displays backspace button', (tester) async {
      await pumpEmergencyHubScreen(tester);

      final words = sampleQuest1.correctAnswer!.split(' ');
      await tester.tap(findChip(words.first));
      await tester.pump();

      final textField = tester.widget<TextField>(
        find.byKey(const Key('emergency_hub_terminal_text_field')),
      );
      expect(textField.controller!.text, words.first);
      expect(find.byKey(const Key('emergency_hub_backspace_button')), findsOneWidget);
    });

    testWidgets('10. Tapping multiple word chips builds space-separated phrase in TextField', (tester) async {
      await pumpEmergencyHubScreen(tester);

      final words = sampleQuest1.correctAnswer!.split(' ');
      for (final word in words) {
        await tester.tap(findChip(word));
        await tester.pump();
      }

      final textField = tester.widget<TextField>(
        find.byKey(const Key('emergency_hub_terminal_text_field')),
      );
      expect(textField.controller!.text, sampleQuest1.correctAnswer);
    });

    testWidgets('11. Tapping an already selected word chip removes it from the phrase in TextField', (tester) async {
      await pumpEmergencyHubScreen(tester);

      final words = sampleQuest1.correctAnswer!.split(' ');
      final firstWord = words.first;

      await tester.tap(findChip(firstWord));
      await tester.pump();

      // Tap it again to deselect
      await tester.tap(findChip(firstWord));
      await tester.pump();

      final textField = tester.widget<TextField>(
        find.byKey(const Key('emergency_hub_terminal_text_field')),
      );
      expect(textField.controller!.text, isEmpty);
      expect(find.byKey(const Key('emergency_hub_backspace_button')), findsNothing);
    });

    testWidgets('12. Tapping backspace button removes the last selected word chip and updates TextField', (tester) async {
      await pumpEmergencyHubScreen(tester);

      final words = sampleQuest1.correctAnswer!.split(' ');
      await tester.tap(findChip(words[0]));
      await tester.pump();
      await tester.tap(findChip(words[1]));
      await tester.pump();

      var textField = tester.widget<TextField>(
        find.byKey(const Key('emergency_hub_terminal_text_field')),
      );
      expect(textField.controller!.text, '${words[0]} ${words[1]}');

      await tester.tap(find.byKey(const Key('emergency_hub_backspace_button')));
      await tester.pump();

      textField = tester.widget<TextField>(
        find.byKey(const Key('emergency_hub_terminal_text_field')),
      );
      expect(textField.controller!.text, words[0]);
    });

    testWidgets('13. Backspace button disappears when all word chips are deselected', (tester) async {
      await pumpEmergencyHubScreen(tester);

      final words = sampleQuest1.correctAnswer!.split(' ');
      await tester.tap(findChip(words[0]));
      await tester.pump();
      expect(find.byKey(const Key('emergency_hub_backspace_button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('emergency_hub_backspace_button')));
      await tester.pump();
      expect(find.byKey(const Key('emergency_hub_backspace_button')), findsNothing);
    });

    testWidgets('14. ValveChamber renders circular valve, wheel knob, lock icon, and initial status text', (tester) async {
      await pumpEmergencyHubScreen(tester);

      expect(find.byKey(const Key('emergency_hub_valve_gesture')), findsOneWidget);
      expect(find.byKey(const Key('emergency_hub_valve_wheel_knob')), findsOneWidget);
      expect(find.byKey(const Key('emergency_hub_valve_lock_icon')), findsOneWidget);
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
      expect(find.text('LOCK PENDING (TURN TO 90%)'), findsOneWidget);
    });

    testWidgets('15. Initial rotation (0.0) displays locked state with LOCK PENDING', (tester) async {
      await pumpEmergencyHubScreen(tester);

      expect(find.text('LOCK PENDING (TURN TO 90%)'), findsOneWidget);
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
      expect(find.byIcon(Icons.lock_open_rounded), findsNothing);
    });

    testWidgets('16. Accessible valve alignment button aligns valve to 1.0 with selection haptic', (tester) async {
      await pumpEmergencyHubScreen(tester);

      final semanticsFinder = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Emergency release valve',
      );
      expect(semanticsFinder, findsOneWidget);

      final semanticsWidget = tester.widget<Semantics>(semanticsFinder);
      semanticsWidget.properties.onTap!();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockHapticService.selection()).called(1);
      expect(find.text('ALIGNED (READY)'), findsOneWidget);
      expect(find.byIcon(Icons.lock_open_rounded), findsOneWidget);
    });

    testWidgets('17. Dragging valve to >= 0.85 updates rotation and transitions to ALIGNED (READY)', (tester) async {
      await pumpEmergencyHubScreen(tester);

      final gesture = tester.widget<GestureDetector>(
        find.byKey(const Key('emergency_hub_valve_gesture')),
      );

      // Center is (100, 100). dx = -30, dy = -90 gives progress ~0.90 (>= 0.85)
      gesture.onPanUpdate!(
        DragUpdateDetails(
          globalPosition: Offset.zero,
          localPosition: const Offset(70, 10),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('ALIGNED (READY)'), findsOneWidget);
      expect(find.byIcon(Icons.lock_open_rounded), findsOneWidget);
    });

    testWidgets('18. Dragging valve back to < 0.85 reverts to LOCK PENDING state', (tester) async {
      await pumpEmergencyHubScreen(tester);

      final gesture = tester.widget<GestureDetector>(
        find.byKey(const Key('emergency_hub_valve_gesture')),
      );

      // First align to >= 0.85
      gesture.onPanUpdate!(
        DragUpdateDetails(
          globalPosition: Offset.zero,
          localPosition: const Offset(70, 10),
        ),
      );
      await tester.pump();
      expect(find.text('ALIGNED (READY)'), findsOneWidget);

      // Now drag to bottom center (progress ~0.50)
      gesture.onPanUpdate!(
        DragUpdateDetails(
          globalPosition: Offset.zero,
          localPosition: const Offset(100, 200),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('LOCK PENDING (TURN TO 90%)'), findsOneWidget);
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    });

    testWidgets('19. Launch button is hidden when code input is empty even if valve is aligned', (tester) async {
      await pumpEmergencyHubScreen(tester);

      // Align valve
      final semanticsFinder = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Emergency release valve',
      );
      tester.widget<Semantics>(semanticsFinder).properties.onTap!();
      await tester.pump();

      expect(find.text('ALIGNED (READY)'), findsOneWidget);
      expect(find.byKey(const Key('emergency_hub_launch_button')), findsNothing);
    });

    testWidgets('20. Launch button appears when words are selected in terminal input', (tester) async {
      await pumpEmergencyHubScreen(tester);

      final words = sampleQuest1.correctAnswer!.split(' ');
      await tester.tap(findChip(words.first));
      await tester.pump();

      expect(find.byKey(const Key('emergency_hub_launch_button')), findsOneWidget);
    });

    testWidgets('21. When words are selected but valve is NOT aligned, button displays ALIGN VALVE TO LAUNCH and onTap is disabled', (tester) async {
      await pumpEmergencyHubScreen(tester);

      final words = sampleQuest1.correctAnswer!.split(' ');
      await tester.tap(findChip(words.first));
      await tester.pump();

      expect(find.text('ALIGN VALVE TO LAUNCH'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);

      final scaleButton = tester.widget<ScaleButton>(
        find.byKey(const Key('emergency_hub_launch_button')),
      );
      expect(scaleButton.onTap, isNull);
    });

    testWidgets('22. When words are selected AND valve IS aligned, button displays LAUNCH EMERGENCY BEACON and onTap is active', (tester) async {
      await pumpEmergencyHubScreen(tester);

      final words = sampleQuest1.correctAnswer!.split(' ');
      await tester.tap(findChip(words.first));
      await tester.pump();

      // Align valve
      final semanticsFinder = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Emergency release valve',
      );
      tester.widget<Semantics>(semanticsFinder).properties.onTap!();
      await tester.pump();

      expect(find.text('LAUNCH EMERGENCY BEACON'), findsOneWidget);
      expect(find.byIcon(Icons.flash_on_rounded), findsOneWidget);

      final scaleButton = tester.widget<ScaleButton>(
        find.byKey(const Key('emergency_hub_launch_button')),
      );
      expect(scaleButton.onTap, isNotNull);
    });

    testWidgets('23. Tapping LAUNCH with incorrect code phrase immediately submits wrong answer with error sound & haptic', (tester) async {
      await pumpEmergencyHubScreen(tester);

      final words = sampleQuest1.correctAnswer!.split(' ');
      // Only select one word (incomplete/wrong answer)
      await tester.tap(findChip(words.first));
      await tester.pump();

      // Align valve
      final semanticsFinder = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Emergency release valve',
      );
      tester.widget<Semantics>(semanticsFinder).properties.onTap!();
      await tester.pump();

      await tester.tap(find.byKey(const Key('emergency_hub_launch_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockRoleplayBloc.add(any(that: isA<SubmitAnswer>()
          .having((e) => e.isCorrect, 'isCorrect', false)))).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockHapticService.error()).called(1);
    });

    testWidgets('24. Incorrect code phrase does NOT mount SpeakToConfirmOverlay', (tester) async {
      await pumpEmergencyHubScreen(tester);

      final words = sampleQuest1.correctAnswer!.split(' ');
      await tester.tap(findChip(words.first));
      await tester.pump();

      final semanticsFinder = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Emergency release valve',
      );
      tester.widget<Semantics>(semanticsFinder).properties.onTap!();
      await tester.pump();

      await tester.tap(find.byKey(const Key('emergency_hub_launch_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(SpeakToConfirmOverlay), findsNothing);
    });

    testWidgets('25. Tapping LAUNCH with correct code phrase advances to Phase 2 SpeakToConfirmOverlay without early BLoC submission', (tester) async {
      await pumpEmergencyHubScreen(tester);

      final words = sampleQuest1.correctAnswer!.split(' ');
      for (final word in words) {
        await tester.tap(findChip(word));
        await tester.pump();
      }

      // Align valve
      final semanticsFinder = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Emergency release valve',
      );
      tester.widget<Semantics>(semanticsFinder).properties.onTap!();
      await tester.pump();

      await tester.tap(find.byKey(const Key('emergency_hub_launch_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verifyNever(() => mockRoleplayBloc.add(any(that: isA<SubmitAnswer>())));
      verify(() => mockHapticService.selection()).called(greaterThanOrEqualTo(1));
      expect(find.byType(SpeakToConfirmOverlay), findsOneWidget);
    });

    testWidgets('26. Phase 2 SpeakToConfirmOverlay displays expectedText matching quest.correctAnswer', (tester) async {
      await pumpEmergencyHubScreen(tester);

      final words = sampleQuest1.correctAnswer!.split(' ');
      for (final word in words) {
        await tester.tap(findChip(word));
        await tester.pump();
      }

      final semanticsFinder = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Emergency release valve',
      );
      tester.widget<Semantics>(semanticsFinder).properties.onTap!();
      await tester.pump();

      await tester.tap(find.byKey(const Key('emergency_hub_launch_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byType(SpeakToConfirmOverlay),
      );
      expect(overlay.expectedText, sampleQuest1.correctAnswer);
    });

    testWidgets('27. SpeakToConfirmOverlay "Nailed It" dispatches RoleplaySpeakConfirmed(5) bonus coins and SubmitAnswer(true) with success sound & haptic', (tester) async {
      await pumpEmergencyHubScreen(tester);

      final words = sampleQuest1.correctAnswer!.split(' ');
      for (final word in words) {
        await tester.tap(findChip(word));
        await tester.pump();
      }

      final semanticsFinder = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Emergency release valve',
      );
      tester.widget<Semantics>(semanticsFinder).properties.onTap!();
      await tester.pump();

      await tester.tap(find.byKey(const Key('emergency_hub_launch_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byType(SpeakToConfirmOverlay),
      );
      overlay.onConfirmed();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockRoleplayBloc.add(const RoleplaySpeakConfirmed(5))).called(1);
      verify(() => mockRoleplayBloc.add(const SubmitAnswer(true))).called(1);
      verify(() => mockSoundService.playCorrect()).called(1);
      verify(() => mockHapticService.success()).called(1);
    });

    testWidgets('28. SpeakToConfirmOverlay "Needs Work" dispatches SubmitAnswer(false) with error sound & haptic', (tester) async {
      await pumpEmergencyHubScreen(tester);

      final words = sampleQuest1.correctAnswer!.split(' ');
      for (final word in words) {
        await tester.tap(findChip(word));
        await tester.pump();
      }

      final semanticsFinder = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Emergency release valve',
      );
      tester.widget<Semantics>(semanticsFinder).properties.onTap!();
      await tester.pump();

      await tester.tap(find.byKey(const Key('emergency_hub_launch_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byType(SpeakToConfirmOverlay),
      );
      overlay.onSkipped();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockRoleplayBloc.add(const SubmitAnswer(false))).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockHapticService.error()).called(1);
    });

    testWidgets('29. In answered state, launch button and SpeakToConfirmOverlay unmount', (tester) async {
      await pumpEmergencyHubScreen(tester);

      final answeredState = testLoadedState.copyWith(
        answerStatus: AnswerStatus.correct,
      );
      when(() => mockRoleplayBloc.state).thenReturn(answeredState);
      roleplayStreamController.add(answeredState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const Key('emergency_hub_launch_button')), findsNothing);
      expect(find.byType(SpeakToConfirmOverlay), findsNothing);
    });

    testWidgets('30. In answered state, bottom bar CONTINUE button appears; tapping it dispatches NextQuestion', (tester) async {
      await pumpEmergencyHubScreen(tester);

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

      verify(() => mockRoleplayBloc.add(any(that: isA<NextQuestion>()))).called(1);
    });

    testWidgets('31. Answer lockout: once answered, tapping valve or chips does not dispatch further actions', (tester) async {
      await pumpEmergencyHubScreen(tester);

      final answeredState = testLoadedState.copyWith(
        answerStatus: AnswerStatus.correct,
      );
      when(() => mockRoleplayBloc.state).thenReturn(answeredState);
      roleplayStreamController.add(answeredState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Attempt to align valve
      final semanticsFinder = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Emergency release valve',
      );
      tester.widget<Semantics>(semanticsFinder).properties.onTap!();
      await tester.pump();

      // No haptic from valve since answered
      verifyNever(() => mockHapticService.heavy());
    });

    testWidgets('32. Question transition: when next quest loads, rotation resets to 0.0, stage resets cleanly', (tester) async {
      await pumpEmergencyHubScreen(tester);

      // Advance to quest 2
      final nextQuestState = testLoadedState.copyWith(
        currentIndex: 1,
        answerStatus: AnswerStatus.unanswered,
      );
      when(() => mockRoleplayBloc.state).thenReturn(nextQuestState);
      roleplayStreamController.add(nextQuestState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text(sampleQuest2.dispatcherQuestion!), findsOneWidget);
      expect(find.text('LOCK PENDING (TURN TO 90%)'), findsOneWidget);
    });

    testWidgets('33. Hint button in header dispatches selection haptic and RoleplayHintUsed', (tester) async {
      await pumpEmergencyHubScreen(tester);

      final hintButton = find.byType(QuestHintButton);
      expect(hintButton, findsOneWidget);
      await tester.tap(hintButton);
      await tester.pump();

      verify(() => mockHapticService.selection()).called(1);
      verify(() => mockRoleplayBloc.add(any(that: isA<RoleplayHintUsed>()))).called(1);
    });

    testWidgets('34. Level 1 briefing layer displays EMERGENCY VOICE and dismisses on HELP NOW tap', (tester) async {
      SharedPreferences.setMockInitialValues({
        'has_seen_briefing_emergencyHub': false,
      });

      await pumpEmergencyHubScreen(
        tester,
        level: 1,
      );

      expect(find.byType(GameBriefingLayer), findsOneWidget);
      expect(find.text('EMERGENCY VOICE'), findsOneWidget);

      final enterBtn = find.descendant(
        of: find.byType(GameBriefingLayer),
        matching: find.text('HELP NOW'),
      );
      expect(enterBtn, findsOneWidget);
      await tester.tap(enterBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(GameBriefingLayer), findsNothing);
    });

    testWidgets('35. GameShimmerLoading displays on initial/loading state', (tester) async {
      await pumpEmergencyHubScreen(tester, state: const RoleplayInitial());

      expect(find.byType(GameShimmerLoading), findsOneWidget);
    });

    testWidgets('36. Game over state renders cleanly without error', (tester) async {
      const gameOverState = RoleplayGameOver(
        quests: [sampleQuest1],
        currentIndex: 0,
        gameType: GameSubtype.emergencyHub,
        level: 2,
      );
      await pumpEmergencyHubScreen(tester, state: gameOverState);

      expect(find.byType(EmergencyHubScreen), findsOneWidget);
    });

    testWidgets('37. Dark and light themes render cleanly without errors', (tester) async {
      await pumpEmergencyHubScreen(tester, themeMode: ThemeMode.light);
      expect(find.byType(EmergencyHubScreen), findsOneWidget);

      await tester.pumpWidget(const SizedBox());

      await pumpEmergencyHubScreen(tester, themeMode: ThemeMode.dark);
      expect(find.byType(EmergencyHubScreen), findsOneWidget);
    });

    testWidgets('38. Small mobile screen (320x568) and tablet viewport (768x1024) render cleanly with zero overflow', (tester) async {
      await pumpEmergencyHubScreen(tester, size: const Size(320, 568));
      expect(find.byType(EmergencyHubScreen), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pumpWidget(const SizedBox());

      await pumpEmergencyHubScreen(tester, size: const Size(768, 1024));
      expect(find.byType(EmergencyHubScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('39. Reduced motion mode suppresses repeating pulse animation on valve and telex warning icon', (tester) async {
      await pumpEmergencyHubScreen(tester, reduceMotion: true);

      expect(find.byKey(const Key('emergency_hub_telex_warning_icon')), findsOneWidget);
      expect(find.byKey(const Key('emergency_hub_valve_chamber')), findsOneWidget);
    });
  });
}

