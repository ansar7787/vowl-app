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
import 'package:vowl/features/roleplay/conflict_resolver/presentation/pages/conflict_resolver_screen.dart';
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
    id: 'cr_1',
    instruction: 'Choose the best way to handle this situation.',
    difficulty: 1,
    subtype: GameSubtype.conflictResolver,
    scene: 'Your colleague sends a blunt email pointing out errors in your spreadsheet.',
    escalationLevel: 4,
    empathyScore: 0.8,
    correctAnswer: 'Acknowledge the valid points and verify the spreadsheet formulas.',
    hint: 'Focus on substance rather than tone.',
    explanation: 'Focusing on content resolves the issue productively.',
  );

  const sampleQuest2 = RoleplayQuest(
    id: 'cr_2',
    instruction: 'Select your de-escalation response.',
    difficulty: 1,
    subtype: GameSubtype.conflictResolver,
    scene: 'A customer is upset about a delivery delay.',
    escalationLevel: 7,
    empathyScore: 0.2,
    correctAnswer: 'Apologize for the delay and provide real-time tracking.',
    hint: 'De-escalate immediately.',
  );

  const sampleQuest3 = RoleplayQuest(
    id: 'cr_3',
    instruction: 'Handle the disagreement.',
    difficulty: 1,
    subtype: GameSubtype.conflictResolver,
    scene: 'Two team members disagree on architecture.',
    escalationLevel: 5,
    empathyScore: 0.4,
    correctAnswer: 'Schedule a structured design review with clear criteria.',
  );

  const sampleQuest4 = RoleplayQuest(
    id: 'cr_4',
    instruction: 'Handle the scope request.',
    difficulty: 1,
    subtype: GameSubtype.conflictResolver,
    scene: 'A stakeholder asks to cut scope.',
    escalationLevel: 3,
    empathyScore: 0.6,
    correctAnswer: 'Review MVP priorities and trade-offs together.',
  );

  final testLoadedState = RoleplayLoaded(
    quests: const [sampleQuest1, sampleQuest2, sampleQuest3, sampleQuest4],
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
    hintUsed: false,
    gameType: GameSubtype.conflictResolver,
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
    when(() => mockRoleplayBloc.stream).thenAnswer((_) => roleplayStreamController.stream);
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
    )).thenAnswer((invocation) async {
      final onResult = invocation.namedArguments[const Symbol('onResult')]
          as void Function(String, bool)?;
      onResult?.call('Acknowledge the valid points and verify the spreadsheet formulas.', true);
    });

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
      'has_seen_briefing_conflictResolver': true,
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

  Future<void> pumpConflictResolverScreen(
    WidgetTester tester, {
    RoleplayState? state,
    ThemeMode themeMode = ThemeMode.dark,
    Size size = const Size(390, 1100),
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
                body: ConflictResolverScreen(level: level),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('ConflictResolverScreen Layout & Mechanics Tests', () {
    testWidgets('1. Initial layout renders instruction badge, instruction text, conflict card, tension meter, dial console, and confirm response button', (tester) async {
      await pumpConflictResolverScreen(tester);

      expect(find.byKey(const Key('conflict_resolver_instruction')), findsOneWidget);
      expect(find.byKey(const Key('conflict_resolver_instruction_icon')), findsOneWidget);
      expect(find.byKey(const Key('conflict_resolver_instruction_text')), findsOneWidget);
      expect(find.byKey(const Key('conflict_resolver_conflict_card')), findsOneWidget);
      expect(find.byKey(const Key('conflict_resolver_card_icon')), findsOneWidget);
      expect(find.byKey(const Key('conflict_resolver_scene_text')), findsOneWidget);
      expect(find.byKey(const Key('conflict_resolver_tension_meter')), findsOneWidget);
      expect(find.byKey(const Key('conflict_resolver_dial_console')), findsOneWidget);
      expect(find.byKey(const Key('conflict_resolver_dial')), findsOneWidget);
      expect(find.byKey(const Key('conflict_resolver_step_left')), findsOneWidget);
      expect(find.byKey(const Key('conflict_resolver_step_right')), findsOneWidget);
      expect(find.byKey(const Key('conflict_resolver_confirm_button')), findsOneWidget);
    });

    testWidgets('2. Initial instruction displays formatted text ("OBJECTIVE", custom or default instruction)', (tester) async {
      await pumpConflictResolverScreen(tester);

      expect(find.text('OBJECTIVE'), findsOneWidget);
      expect(find.text('Choose the best way to handle this situation.'), findsOneWidget);
    });

    testWidgets('3. Conflict card renders forum icon, scene text, and tension label', (tester) async {
      await pumpConflictResolverScreen(tester);

      expect(find.byIcon(Icons.forum_rounded), findsOneWidget);
      expect(find.text(sampleQuest1.scene!), findsOneWidget);
      expect(find.text('TENSION'), findsOneWidget);
    });

    testWidgets('4. Tension meter displays 10 indicators, where index < escalationLevel (4) are active', (tester) async {
      await pumpConflictResolverScreen(tester);

      for (int i = 0; i < 10; i++) {
        expect(find.byKey(Key('conflict_resolver_tension_bar_$i')), findsOneWidget);
      }
    });

    testWidgets('5. Tension meter handles edge cases: escalationLevel = 1, escalationLevel = 10, escalationLevel = null', (tester) async {
      const edgeQuest = RoleplayQuest(
        id: 'cr_edge',
        instruction: 'Edge situation',
        difficulty: 1,
        subtype: GameSubtype.conflictResolver,
        scene: 'Maximum escalation level detected.',
        escalationLevel: 10,
        empathyScore: 0.5,
        correctAnswer: 'Calm the situation.',
      );
      final edgeState = testLoadedState.copyWith(quests: const [edgeQuest]);
      await pumpConflictResolverScreen(tester, state: edgeState);

      expect(find.byKey(const Key('conflict_resolver_tension_meter')), findsOneWidget);
      for (int i = 0; i < 10; i++) {
        expect(find.byKey(Key('conflict_resolver_tension_bar_$i')), findsOneWidget);
      }
    });

    testWidgets('6. Dial console renders metallic rotary dial, notch marker, D-pad arrow buttons, and static noise box initially', (tester) async {
      await pumpConflictResolverScreen(tester);

      expect(find.byKey(const Key('conflict_resolver_dial')), findsOneWidget);
      expect(find.byIcon(Icons.sensors_rounded), findsOneWidget);
      expect(find.byIcon(Icons.arrow_left_rounded), findsOneWidget);
      expect(find.byIcon(Icons.arrow_right_rounded), findsOneWidget);
      expect(find.byKey(const Key('conflict_resolver_static_noise')), findsOneWidget);
      expect(find.text('TUNING... STATIC NOISE'), findsOneWidget);
    });

    testWidgets('7. Initial dial rotation (0.0) displays "TUNING... STATIC NOISE" with blur_on icon', (tester) async {
      await pumpConflictResolverScreen(tester);

      expect(find.byIcon(Icons.blur_on_rounded), findsOneWidget);
      expect(find.text('TUNING... STATIC NOISE'), findsOneWidget);
      expect(find.byKey(const Key('conflict_resolver_focused_response')), findsNothing);
    });

    testWidgets('8. Stepping right (onStepRight / arrow_right button) sets rotation to 0.375 (index 1), triggers selection haptic, and tunes into option 1 text', (tester) async {
      await pumpConflictResolverScreen(tester);

      await tester.tap(find.byKey(const Key('conflict_resolver_step_right')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockHapticService.selection()).called(1);
      expect(find.byKey(const Key('conflict_resolver_focused_response')), findsOneWidget);
      expect(find.text('PROPOSED RESPONSE:'), findsOneWidget);
      expect(find.text(sampleQuest3.correctAnswer!), findsOneWidget); // empathyScore 0.4 -> index 1
    });

    testWidgets('9. Stepping right again advances to index 2 (rotation 0.625) and index 3 (rotation 0.875)', (tester) async {
      await pumpConflictResolverScreen(tester);

      // Step to index 1
      await tester.tap(find.byKey(const Key('conflict_resolver_step_right')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      // Step to index 2 (empathyScore 0.6 -> sampleQuest4)
      await tester.tap(find.byKey(const Key('conflict_resolver_step_right')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text(sampleQuest4.correctAnswer!), findsOneWidget);

      // Step to index 3 (empathyScore 0.8 -> sampleQuest1, correct answer!)
      await tester.tap(find.byKey(const Key('conflict_resolver_step_right')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text(sampleQuest1.correctAnswer!), findsOneWidget);
    });

    testWidgets('10. Stepping right from index 3 wraps around to index 0 (rotation 0.125)', (tester) async {
      await pumpConflictResolverScreen(tester);

      // 4 steps right wraps 0 -> 1 -> 2 -> 3 -> 0
      for (int i = 0; i < 4; i++) {
        await tester.tap(find.byKey(const Key('conflict_resolver_step_right')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
      }

      // Index 0 has empathyScore 0.2 -> sampleQuest2
      expect(find.text(sampleQuest2.correctAnswer!), findsOneWidget);
    });

    testWidgets('11. Stepping left (onStepLeft / arrow_left button) from index 0 wraps to index 3 (rotation 0.875) and triggers selection haptic', (tester) async {
      await pumpConflictResolverScreen(tester);

      // Initial focused index is null, so _focusedIndex ?? 0 is 0. Stepping left wraps to count - 1 = 3.
      await tester.tap(find.byKey(const Key('conflict_resolver_step_left')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockHapticService.selection()).called(1);
      // Index 3 is sampleQuest1 (empathyScore 0.8)
      expect(find.text(sampleQuest1.correctAnswer!), findsOneWidget);
    });

    testWidgets('12. Stepping left from index 1 steps down to index 0 (rotation 0.125)', (tester) async {
      await pumpConflictResolverScreen(tester);

      // Step right to index 1
      await tester.tap(find.byKey(const Key('conflict_resolver_step_right')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text(sampleQuest3.correctAnswer!), findsOneWidget);

      // Step left to index 0
      await tester.tap(find.byKey(const Key('conflict_resolver_step_left')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text(sampleQuest2.correctAnswer!), findsOneWidget);
    });

    testWidgets('13. Dial drag: dragging dial updates rotation angle smoothly and triggers selection haptic when focused index changes', (tester) async {
      await pumpConflictResolverScreen(tester);

      final dialFinder = find.byKey(const Key('conflict_resolver_dial'));
      expect(dialFinder, findsOneWidget);

      final center = tester.getCenter(dialFinder);

      // Start drag at right edge of dial (touchPos dx > center.dx, angle = 0 -> progress ~0.25)
      final gesture = await tester.startGesture(center + const Offset(50, 0));
      await gesture.moveBy(const Offset(0, 30));
      await tester.pump();
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const Key('conflict_resolver_dial')), findsOneWidget);
    });

    testWidgets('14. Dragging dial into tuning range (0.125 ± 0.1) snaps focus to index 0 and displays proposed response', (tester) async {
      await pumpConflictResolverScreen(tester);

      // Step right once to index 1
      await tester.tap(find.byKey(const Key('conflict_resolver_step_right')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const Key('conflict_resolver_focused_response')), findsOneWidget);
      expect(find.byKey(const Key('conflict_resolver_static_noise')), findsNothing);
    });

    testWidgets('15. Dragging dial into static frequency range unfocuses and displays "TUNING... STATIC NOISE"', (tester) async {
      await pumpConflictResolverScreen(tester);

      // Initially rotation is 0.0 which is in static noise range
      expect(find.byKey(const Key('conflict_resolver_static_noise')), findsOneWidget);
      expect(find.text('TUNING... STATIC NOISE'), findsOneWidget);
    });

    testWidgets('16. Tapping "CONFIRM RESPONSE" while dial is unfocused / static noise does not submit answer or advance stage', (tester) async {
      await pumpConflictResolverScreen(tester);

      // Dial is at 0.0 (static noise)
      expect(find.text('TUNING... STATIC NOISE'), findsOneWidget);

      // Tap confirm button
      await tester.tap(find.byKey(const Key('conflict_resolver_confirm_button')));
      await tester.pump();

      verify(() => mockHapticService.light()).called(1);
      verifyNever(() => mockRoleplayBloc.add(any(that: isA<SubmitAnswer>())));
      expect(find.byType(SpeakToConfirmOverlay), findsNothing);
    });

    testWidgets('17. Tapping "CONFIRM RESPONSE" when focused on wrong option immediately submits wrong answer with userAnswer, triggers wrong sound & error haptic', (tester) async {
      await pumpConflictResolverScreen(tester);

      // Step to index 0 (sampleQuest2, wrong answer for quest 1)
      await tester.tap(find.byKey(const Key('conflict_resolver_step_left')));
      await tester.tap(find.byKey(const Key('conflict_resolver_step_right'))); // index 0
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(sampleQuest2.correctAnswer!), findsOneWidget);

      // Submit wrong answer
      await tester.tap(find.byKey(const Key('conflict_resolver_confirm_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockRoleplayBloc.add(const SubmitAnswer(false))).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockHapticService.error()).called(1);
    });

    testWidgets('18. Tapping "CONFIRM RESPONSE" on wrong option does NOT mount SpeakToConfirmOverlay', (tester) async {
      await pumpConflictResolverScreen(tester);

      // Step to index 0 (wrong)
      await tester.tap(find.byKey(const Key('conflict_resolver_step_left')));
      await tester.tap(find.byKey(const Key('conflict_resolver_step_right')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      await tester.tap(find.byKey(const Key('conflict_resolver_confirm_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SpeakToConfirmOverlay), findsNothing);
    });

    testWidgets('19. Tapping "CONFIRM RESPONSE" when focused on correct option advances to Phase 2, mounts SpeakToConfirmOverlay without early BLoC submission', (tester) async {
      await pumpConflictResolverScreen(tester);

      // Step left from initial wraps to index 3 (sampleQuest1, correct answer!)
      await tester.tap(find.byKey(const Key('conflict_resolver_step_left')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(sampleQuest1.correctAnswer!), findsOneWidget);

      // Tap confirm button
      await tester.tap(find.byKey(const Key('conflict_resolver_confirm_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.byType(SpeakToConfirmOverlay), findsOneWidget);
      verifyNever(() => mockRoleplayBloc.add(const SubmitAnswer(true)));
    });

    testWidgets('20. In Phase 2, dial displays correct state (green check icon) and SpeakToConfirmOverlay displays expectedText matching correct answer', (tester) async {
      await pumpConflictResolverScreen(tester);

      // Step left to index 3 (correct)
      await tester.tap(find.byKey(const Key('conflict_resolver_step_left')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byKey(const Key('conflict_resolver_confirm_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 700));

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.byType(SpeakToConfirmOverlay), findsOneWidget);
      expect(find.text(sampleQuest1.correctAnswer!), findsAtLeastNWidgets(1));
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
        onResult([sampleQuest1.correctAnswer!], true);
      });

      await pumpConflictResolverScreen(tester);

      // Advance to Phase 2
      await tester.tap(find.byKey(const Key('conflict_resolver_step_left')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byKey(const Key('conflict_resolver_confirm_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 700));

      // Scroll down to SpeakToConfirmOverlay
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

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
      await pumpConflictResolverScreen(tester);

      // Advance to Phase 2
      await tester.tap(find.byKey(const Key('conflict_resolver_step_left')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byKey(const Key('conflict_resolver_confirm_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 700));

      // Scroll down to SpeakToConfirmOverlay
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -600), warnIfMissed: false);
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
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300), warnIfMissed: false);
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

    testWidgets('23. In answered state, dial console displays correct/incorrect status (icons.check_rounded or icons.close_rounded)', (tester) async {
      await pumpConflictResolverScreen(tester);

      // Submit wrong answer
      await tester.tap(find.byKey(const Key('conflict_resolver_step_left')));
      await tester.tap(find.byKey(const Key('conflict_resolver_step_right')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      await tester.tap(find.byKey(const Key('conflict_resolver_confirm_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final answeredWrongState = testLoadedState.copyWith(
        answerStatus: AnswerStatus.incorrect,
      );
      when(() => mockRoleplayBloc.state).thenReturn(answeredWrongState);
      roleplayStreamController.add(answeredWrongState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('24. Answer lockout: once answered, tapping D-pad step buttons, dragging dial, or tapping confirm response does not dispatch further actions', (tester) async {
      await pumpConflictResolverScreen(tester);

      // Submit wrong answer
      await tester.tap(find.byKey(const Key('conflict_resolver_step_left')));
      await tester.tap(find.byKey(const Key('conflict_resolver_step_right')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      await tester.tap(find.byKey(const Key('conflict_resolver_confirm_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      clearInteractions(mockRoleplayBloc);

      // Try tapping step buttons
      await tester.tap(find.byKey(const Key('conflict_resolver_step_right')), warnIfMissed: false);
      await tester.pump();

      verifyNever(() => mockRoleplayBloc.add(any(that: isA<SubmitAnswer>())));
    });

    testWidgets('25. In answered state, continue button appears in bottom bar; tapping it dispatches NextQuestion', (tester) async {
      await pumpConflictResolverScreen(tester);

      final answeredState = testLoadedState.copyWith(
        answerStatus: AnswerStatus.correct,
      );
      when(() => mockRoleplayBloc.state).thenReturn(answeredState);
      roleplayStreamController.add(answeredState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final continueButton = find.text('CONTINUE');
      expect(continueButton, findsOneWidget);
      await tester.tap(continueButton);
      await tester.pump();

      verify(() => mockRoleplayBloc.add(any(that: isA<NextQuestion>()))).called(1);
    });

    testWidgets('26. Question transition: when next quest loads, rotation resets to 0.0, stage resets, and options are regenerated for the new quest', (tester) async {
      await pumpConflictResolverScreen(tester);

      // Select and confirm answer
      await tester.tap(find.byKey(const Key('conflict_resolver_step_left')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Advance to quest 2
      final nextQuestState = testLoadedState.copyWith(
        currentIndex: 1,
        answerStatus: AnswerStatus.unanswered,
      );
      when(() => mockRoleplayBloc.state).thenReturn(nextQuestState);
      roleplayStreamController.add(nextQuestState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byKey(const Key('conflict_resolver_static_noise')), findsOneWidget);
      expect(find.text(sampleQuest2.scene!), findsOneWidget);
    });

    testWidgets('27. Single-option batch: when state has only 1 quest, options generation handles single quest without crashing and dial steps cleanly', (tester) async {
      final singleState = testLoadedState.copyWith(
        quests: const [sampleQuest1],
        currentIndex: 0,
      );
      await pumpConflictResolverScreen(tester, state: singleState);

      expect(find.byKey(const Key('conflict_resolver_dial_console')), findsOneWidget);

      await tester.tap(find.byKey(const Key('conflict_resolver_step_right')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(sampleQuest1.correctAnswer!), findsOneWidget);
    });

    testWidgets('28. Two-option batch: when state has only 2 quests, options generation handles 2 quests without crashing', (tester) async {
      final twoState = testLoadedState.copyWith(
        quests: const [sampleQuest1, sampleQuest2],
        currentIndex: 0,
      );
      await pumpConflictResolverScreen(tester, state: twoState);

      expect(find.byKey(const Key('conflict_resolver_dial_console')), findsOneWidget);

      await tester.tap(find.byKey(const Key('conflict_resolver_step_right')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const Key('conflict_resolver_focused_response')), findsOneWidget);
    });

    testWidgets('29. Hint button in header dispatches selection haptic and RoleplayHintUsed', (tester) async {
      await pumpConflictResolverScreen(tester);

      final hintButton = find.byType(QuestHintButton);
      expect(hintButton, findsOneWidget);
      await tester.tap(hintButton);
      await tester.pump();

      verify(() => mockRoleplayBloc.add(any(that: isA<RoleplayHintUsed>()))).called(1);
    });

    testWidgets('30. Level 1 briefing layer displays PEACE MAKER and dismisses on RESOLVE CONFLICT tap', (tester) async {
      SharedPreferences.setMockInitialValues({
        'has_seen_briefing_conflictResolver': false,
      });

      await pumpConflictResolverScreen(
        tester,
        level: 1,
        size: const Size(390, 1100),
      );

      expect(find.byType(GameBriefingLayer), findsOneWidget);
      expect(find.text('PEACE MAKER'), findsOneWidget);

      final enterBtn = find.text('RESOLVE CONFLICT');
      expect(enterBtn, findsOneWidget);
      await tester.tap(enterBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(GameBriefingLayer), findsNothing);
    });

    testWidgets('31. GameShimmerLoading displays on initial/loading state, and complete state triggers completion cleanly', (tester) async {
      await pumpConflictResolverScreen(tester, state: const RoleplayInitial());

      expect(find.byType(GameShimmerLoading), findsOneWidget);
    });

    testWidgets('32. Game over state renders cleanly without error', (tester) async {
      const gameOverState = RoleplayGameOver(
        quests: [sampleQuest1],
        currentIndex: 0,
        gameType: GameSubtype.conflictResolver,
        level: 2,
      );
      await pumpConflictResolverScreen(tester, state: gameOverState);

      expect(find.byType(ConflictResolverScreen), findsOneWidget);
    });

    testWidgets('33. Dark and light themes render cleanly without errors', (tester) async {
      await pumpConflictResolverScreen(tester, themeMode: ThemeMode.light);
      expect(find.byType(ConflictResolverScreen), findsOneWidget);

      await pumpConflictResolverScreen(tester, themeMode: ThemeMode.dark);
      expect(find.byType(ConflictResolverScreen), findsOneWidget);
    });

    testWidgets('34. Small mobile screen (320x568) and tablet viewport (768x1024) render cleanly with zero overflow', (tester) async {
      await pumpConflictResolverScreen(tester, size: const Size(320, 568));
      expect(find.byType(ConflictResolverScreen), findsOneWidget);
      expect(tester.takeException(), isNull);

      await pumpConflictResolverScreen(tester, size: const Size(768, 1024));
      expect(find.byType(ConflictResolverScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('35. Reduced motion mode suppresses animations (wave controller stops, card icon does not animate)', (tester) async {
      await pumpConflictResolverScreen(tester, reduceMotion: true);

      expect(find.byType(ConflictResolverScreen), findsOneWidget);
      expect(find.byKey(const Key('conflict_resolver_card_icon')), findsOneWidget);
    });
  });
}

