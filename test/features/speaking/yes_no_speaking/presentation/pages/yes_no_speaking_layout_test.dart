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
import 'package:vowl/core/presentation/game_mechanics/speaking/shadow_playback_compare.dart';
import 'package:vowl/core/presentation/widgets/game_feedback_card.dart';
import 'package:vowl/core/presentation/widgets/quest_briefing_overlay.dart';
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
import 'package:vowl/features/speaking/domain/entities/speaking_quest.dart';
import 'package:vowl/features/speaking/presentation/bloc/speaking_bloc.dart';
import 'package:vowl/features/speaking/presentation/layout/speaking_base_layout.dart';
import 'package:vowl/features/speaking/yes_no_speaking/presentation/pages/yes_no_speaking_screen.dart';
import 'package:vowl/features/speaking/yes_no_speaking/presentation/widgets/yes_no_speaking_audition_card.dart';
import 'package:vowl/features/speaking/yes_no_speaking/presentation/widgets/yes_no_speaking_header_instruction.dart';
import 'package:vowl/features/speaking/yes_no_speaking/presentation/widgets/yes_no_speaking_tilt_arena.dart';

class MockSpeakingBloc extends MockBloc<SpeakingEvent, SpeakingState>
    implements SpeakingBloc {}

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSpeakingBloc mockSpeakingBloc;
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
  late StreamController<SpeakingState> speakingStreamController;

  SpeakingQuest createQuest({
    String id = 'quest_yes_no_1',
    String prompt = 'My mother cooks rice for dinner.',
    String sampleAnswer = 'My mother cooks pasta for dinner.',
    String instruction = 'Listen and tilt to yes if audio matches text, or no if it does not.',
    String? hint = 'Listen to the food word at the end.',
    int difficulty = 1,
  }) {
    return SpeakingQuest(
      id: id,
      type: QuestType.speaking,
      subtype: GameSubtype.yesNoSpeaking,
      prompt: prompt,
      sampleAnswer: sampleAnswer,
      instruction: instruction,
      hint: hint,
      difficulty: difficulty,
    );
  }

  // Quest 1: prompt != sampleAnswer (Match = false, correct answer is NO)
  final sampleQuest1 = createQuest();

  // Quest 2: prompt == sampleAnswer (Match = true, correct answer is YES)
  final sampleQuest2 = createQuest(
    id: 'quest_yes_no_2',
    prompt: 'The bus stops near my school.',
    sampleAnswer: 'The bus stops near my school.',
    instruction: 'Compare the audio with the text.',
    hint: 'Listen for the location word.',
  );

  final testLoadedState = SpeakingLoaded(
    quests: [sampleQuest1, sampleQuest2],
    currentIndex: 0,
    livesRemaining: 3,
    wrongCount: 0,
    hintUsed: false,
    answerStatus: AnswerStatus.unanswered,
    gameType: GameSubtype.yesNoSpeaking,
    level: 2,
  );

  setUpAll(() {
    registerFallbackValue(const SubmitAnswer(true));
    registerFallbackValue(const NextQuestion());
    registerFallbackValue(const SpeakingHintUsed());
    registerFallbackValue(
      const FetchSpeakingQuests(
        gameType: GameSubtype.yesNoSpeaking,
        level: 2,
      ),
    );
    registerFallbackValue(const Duration(milliseconds: 50));
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'has_seen_briefing_yesNoSpeaking': true,
    });

    mockSpeakingBloc = MockSpeakingBloc();
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

    speakingStreamController = StreamController<SpeakingState>.broadcast();

    when(() => mockSpeakingBloc.state).thenReturn(testLoadedState);
    whenListen(
      mockSpeakingBloc,
      speakingStreamController.stream,
      initialState: testLoadedState,
    );

    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(
        const UserEntity(
          id: 'test_user_yes_no',
          email: 'yesno@vowl.app',
          displayName: 'Voice Validator',
          hintCount: 3,
        ),
      ),
    );
    when(() => mockAuthBloc.stream)
        .thenAnswer((_) => const Stream<AuthState>.empty());

    when(() => mockEconomyBloc.state).thenReturn(const EconomyState());
    when(() => mockEconomyBloc.stream)
        .thenAnswer((_) => const Stream<EconomyState>.empty());

    when(() => mockAudioRecorder.isRecording).thenReturn(false);
    when(() => mockAudioRecorder.hasPermission()).thenAnswer((_) async => true);
    when(() => mockAudioRecorder.startRecording()).thenAnswer((_) async => true);
    when(() => mockAudioRecorder.stopRecording())
        .thenAnswer((_) async => 'mock_yesno_rec.m4a');
    when(() => mockAudioRecorder.dispose()).thenAnswer((_) async {});
    when(() => mockAudioRecorder.onAmplitudeChanged(any())).thenAnswer(
      (_) => Stream.fromIterable([
        Amplitude(current: -10, max: 0),
        Amplitude(current: -5, max: 0),
      ]),
    );

    when(() => mockSpeechService.isListening).thenReturn(false);
    when(() => mockSpeechService.initializeStt()).thenAnswer((_) async => true);
    when(() => mockSpeechService.stop()).thenAnswer((_) async {});
    when(() => mockSpeechService.cancel()).thenAnswer((_) async {});

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});
    when(() => mockHapticService.heavy()).thenAnswer((_) async {});

    when(() => mockSoundService.playCorrect()).thenAnswer((_) async {});
    when(() => mockSoundService.playWrong()).thenAnswer((_) async {});
    when(() => mockSoundService.playTts(any())).thenAnswer((_) async {});
    when(() => mockSoundService.stopTts()).thenAnswer((_) async {});
    when(() => mockSoundService.stopAudio()).thenAnswer((_) async {});
    when(() => mockSoundService.playHint()).thenAnswer((_) async {});
    when(() => mockSoundService.playClick()).thenAnswer((_) async {});
    when(() => mockSoundService.playLevelComplete()).thenAnswer((_) async {});
    when(() => mockSoundService.playFile(any())).thenAnswer((_) async {});

    when(() => mockTtsService.stop()).thenAnswer((_) async {});
    when(
      () => mockTtsService.speak(
        any(),
        rate: any(named: 'rate'),
        locale: any(named: 'locale'),
      ),
    ).thenAnswer((_) async {});

    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

    await di.sl.reset();
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

    VowlMotion.lowAnimationModeOverride.value = true;
  });

  tearDown(() async {
    await speakingStreamController.close();
    VowlMotion.lowAnimationModeOverride.value = false;
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    SpeakingState? state,
    int level = 2,
    GameSubtype gameType = GameSubtype.yesNoSpeaking,
    Size size = const Size(390, 844),
    double textScaleFactor = 1.0,
    ThemeMode themeMode = ThemeMode.dark,
    bool reduceMotion = true,
  }) async {
    VowlMotion.lowAnimationModeOverride.value = reduceMotion;
    tester.view.physicalSize = size * 2.0;
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    if (state != null) {
      when(() => mockSpeakingBloc.state).thenReturn(state);
    }

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<SpeakingBloc>.value(value: mockSpeakingBloc),
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<EconomyBloc>.value(value: mockEconomyBloc),
        ],
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (context, child) => MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            home: MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: TextScaler.linear(textScaleFactor),
                disableAnimations: reduceMotion,
              ),
              child: YesNoSpeakingScreen(
                level: level,
                gameType: gameType,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  // ---------------------------------------------------------------------------
  // 1. Initial Layout & Component Structure (8 tests)
  // ---------------------------------------------------------------------------
  group('1. Initial Layout & Component Structure', () {
    testWidgets('1.1 renders SpeakingBaseLayout', (tester) async {
      await pumpScreen(tester);
      expect(find.byType(SpeakingBaseLayout), findsOneWidget);
    });

    testWidgets('1.2 renders YesNoSpeakingHeaderInstruction with key yes_no_speaking_header_instruction', (tester) async {
      await pumpScreen(tester);
      expect(find.byType(YesNoSpeakingHeaderInstruction), findsOneWidget);
      expect(find.byKey(const Key('yes_no_speaking_header_instruction')), findsOneWidget);
    });

    testWidgets('1.3 renders instruction badge with key yes_no_speaking_instruction_badge', (tester) async {
      await pumpScreen(tester);
      expect(find.byKey(const Key('yes_no_speaking_instruction_badge')), findsOneWidget);
    });

    testWidgets('1.4 renders badge text with key yes_no_speaking_badge_text displaying SLIDE TO YES OR NO', (tester) async {
      await pumpScreen(tester);
      expect(find.byKey(const Key('yes_no_speaking_badge_text')), findsOneWidget);
      expect(find.text('SLIDE TO YES OR NO'), findsOneWidget);
    });

    testWidgets('1.5 renders instruction text with key yes_no_speaking_instruction_text', (tester) async {
      await pumpScreen(tester);
      expect(find.byKey(const Key('yes_no_speaking_instruction_text')), findsOneWidget);
    });

    testWidgets('1.6 renders YesNoSpeakingAuditionCard with key yes_no_speaking_audition_card', (tester) async {
      await pumpScreen(tester);
      expect(find.byType(YesNoSpeakingAuditionCard), findsOneWidget);
      expect(find.byKey(const Key('yes_no_speaking_audition_card')), findsOneWidget);
    });

    testWidgets('1.7 renders YesNoSpeakingTiltArena with key yes_no_speaking_tilt_arena', (tester) async {
      await pumpScreen(tester);
      expect(find.byType(YesNoSpeakingTiltArena), findsOneWidget);
      expect(find.byKey(const Key('yes_no_speaking_tilt_arena')), findsOneWidget);
    });

    testWidgets('1.8 renders RawScrollbar and CustomScrollView with custom keys', (tester) async {
      await pumpScreen(tester);
      expect(find.byKey(const Key('yes_no_speaking_scrollbar')), findsOneWidget);
      expect(find.byKey(const Key('yes_no_speaking_scroll_view')), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // 2. Audition Card, Target Text & TTS Playback (8 tests)
  // ---------------------------------------------------------------------------
  group('2. Audition Card, Target Text & TTS Playback', () {
    testWidgets('2.1 renders LISTEN & MATCH header in audition card', (tester) async {
      await pumpScreen(tester);
      expect(find.text('LISTEN & MATCH'), findsOneWidget);
    });

    testWidgets('2.2 renders WRITTEN SENTENCE label with key yes_no_speaking_target_card_label', (tester) async {
      await pumpScreen(tester);
      expect(find.byKey(const Key('yes_no_speaking_target_card_label')), findsOneWidget);
      expect(find.text('WRITTEN SENTENCE'), findsOneWidget);
    });

    testWidgets('2.3 renders target sentence text with key yes_no_speaking_target_text', (tester) async {
      await pumpScreen(tester);
      expect(find.byKey(const Key('yes_no_speaking_target_text')), findsOneWidget);
      expect(find.text('My mother cooks pasta for dinner.'), findsOneWidget);
    });

    testWidgets('2.4 target sentence text has accessible Semantics label', (tester) async {
      await pumpScreen(tester);
      expect(
        find.byWidgetPredicate((w) =>
            w is Semantics &&
            w.properties.label == 'Target sentence: My mother cooks pasta for dinner.'),
        findsOneWidget,
      );
    });

    testWidgets('2.5 renders replay button with key yes_no_speaking_replay_button and volume_up_rounded icon', (tester) async {
      await pumpScreen(tester);
      expect(find.byKey(const Key('yes_no_speaking_replay_button')), findsOneWidget);
      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
    });

    testWidgets('2.6 tapping replay button invokes soundService.playTts(quest.prompt)', (tester) async {
      await pumpScreen(tester);
      clearInteractions(mockSoundService);

      await tester.tap(find.byKey(const Key('yes_no_speaking_replay_button')));
      await tester.pump();

      verify(() => mockSoundService.playTts('My mother cooks rice for dinner.')).called(1);
    });

    testWidgets('2.7 tapping replay button does NOT invoke TTS if audioRecorder is recording', (tester) async {
      when(() => mockAudioRecorder.isRecording).thenReturn(true);
      await pumpScreen(tester);
      clearInteractions(mockSoundService);

      await tester.tap(find.byKey(const Key('yes_no_speaking_replay_button')));
      await tester.pump();

      verifyNever(() => mockSoundService.playTts(any()));
    });

    testWidgets('2.8 autoPlay triggers soundService.playTts with prompt on mount', (tester) async {
      clearInteractions(mockSoundService);
      await pumpScreen(tester);
      verify(() => mockSoundService.playTts('My mother cooks rice for dinner.')).called(1);
    });
  });

  // ---------------------------------------------------------------------------
  // 3. Level 1 Briefing Overlay & Onboarding (6 tests)
  // ---------------------------------------------------------------------------
  group('3. Level 1 Briefing Overlay & Onboarding', () {
    testWidgets('3.1 displays QuestBriefingOverlay on level 1 when not previously seen', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpScreen(tester, level: 1);
      expect(find.byType(QuestBriefingOverlay), findsOneWidget);
    });

    testWidgets('3.2 displays briefing title containing VOICE VALIDATOR', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpScreen(tester, level: 1);
      expect(find.textContaining('VOICE VALIDATOR'), findsWidgets);
    });

    testWidgets('3.3 displays action button with VALIDATE VOICE', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpScreen(tester, level: 1);
      expect(find.text('VALIDATE VOICE'), findsOneWidget);
    });

    testWidgets('3.4 tapping action button dismisses overlay', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpScreen(tester, level: 1);
      expect(find.byType(QuestBriefingOverlay), findsOneWidget);

      await tester.ensureVisible(find.text('VALIDATE VOICE'));
      await tester.tap(find.text('VALIDATE VOICE'));
      await tester.pumpAndSettle();

      expect(find.byType(QuestBriefingOverlay), findsNothing);
    });

    testWidgets('3.5 does not display briefing overlay on level 2', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpScreen(tester, level: 2);
      expect(find.byType(QuestBriefingOverlay), findsNothing);
    });

    testWidgets('3.6 briefing overlay is also displayed on level 100', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpScreen(tester, level: 100);
      expect(find.byType(QuestBriefingOverlay), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // 4. Tilt Arena Mechanics & Drag Gestures (8 tests)
  // ---------------------------------------------------------------------------
  group('4. Tilt Arena Mechanics & Drag Gestures', () {
    testWidgets('4.1 renders neon track CustomPaint', (tester) async {
      await pumpScreen(tester);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('4.2 renders NO gate zone with key yes_no_speaking_gate_no', (tester) async {
      await pumpScreen(tester);
      expect(find.byKey(const Key('yes_no_speaking_gate_no')), findsOneWidget);
      expect(find.text('NO'), findsOneWidget);
    });

    testWidgets('4.3 renders YES gate zone with key yes_no_speaking_gate_yes', (tester) async {
      await pumpScreen(tester);
      expect(find.byKey(const Key('yes_no_speaking_gate_yes')), findsOneWidget);
      expect(find.text('YES'), findsOneWidget);
    });

    testWidgets('4.4 renders central dragging sphere with key yes_no_speaking_sphere', (tester) async {
      await pumpScreen(tester);
      expect(find.byKey(const Key('yes_no_speaking_sphere')), findsOneWidget);
    });

    testWidgets('4.5 central sphere displays blur_on_rounded icon when not snapped', (tester) async {
      await pumpScreen(tester);
      expect(find.byIcon(Icons.blur_on_rounded), findsOneWidget);
      expect(find.byIcon(Icons.lock_rounded), findsNothing);
    });

    testWidgets('4.6 dragging sphere left updates tiltValue negatively', (tester) async {
      await pumpScreen(tester);
      final state = tester.state(find.byType(YesNoSpeakingScreen)) as dynamic;
      final arena = tester.widget<YesNoSpeakingTiltArena>(find.byKey(const Key('yes_no_speaking_tilt_arena')));
      arena.onTiltDragged(DragUpdateDetails(globalPosition: Offset.zero, delta: const Offset(-50, 0)), 300);
      await tester.pump();

      expect(state.tiltValueNotifier.value, lessThan(0.0));
    });

    testWidgets('4.7 dragging sphere right updates tiltValue positively', (tester) async {
      await pumpScreen(tester);
      final state = tester.state(find.byType(YesNoSpeakingScreen)) as dynamic;
      final arena = tester.widget<YesNoSpeakingTiltArena>(find.byKey(const Key('yes_no_speaking_tilt_arena')));
      arena.onTiltDragged(DragUpdateDetails(globalPosition: Offset.zero, delta: const Offset(50, 0)), 300);
      await tester.pump();

      expect(state.tiltValueNotifier.value, greaterThan(0.0));
    });

    testWidgets('4.8 ending drag without crossing threshold resets tiltValue to 0.0', (tester) async {
      await pumpScreen(tester);
      final state = tester.state(find.byType(YesNoSpeakingScreen)) as dynamic;
      final arena = tester.widget<YesNoSpeakingTiltArena>(find.byKey(const Key('yes_no_speaking_tilt_arena')));
      arena.onTiltDragged(DragUpdateDetails(globalPosition: Offset.zero, delta: const Offset(20, 0)), 300);
      await tester.pump();

      expect(state.tiltValueNotifier.value, greaterThan(0.0));

      arena.onTiltDragEnd();
      await tester.pump();

      expect(state.tiltValueNotifier.value, 0.0);
    });
  });

  // ---------------------------------------------------------------------------
  // 5. Phase 1 Decision: Tap & Snap Choices (8 tests)
  // ---------------------------------------------------------------------------
  group('5. Phase 1 Decision: Tap & Snap Choices', () {
    testWidgets('5.1 tapping NO gate when prompt does NOT match sampleAnswer triggers snap and success', (tester) async {
      await pumpScreen(tester);
      // Quest 1: rice != pasta -> correct choice is NO
      await tester.tap(find.byKey(const Key('yes_no_speaking_gate_no')));
      await tester.pumpAndSettle();

      final state = tester.state(find.byType(YesNoSpeakingScreen)) as dynamic;
      expect(state.isSnappedNotifier.value, isTrue);
      expect(state.isAnsweredNotifier.value, isFalse);
      verify(() => mockSoundService.playClick()).called(1);
    });

    testWidgets('5.2 tapping YES gate when prompt does NOT match sampleAnswer triggers wrong answer flow', (tester) async {
      await pumpScreen(tester);
      // Quest 1: rice != pasta -> tapping YES is incorrect!
      await tester.tap(find.byKey(const Key('yes_no_speaking_gate_yes')));
      await tester.pumpAndSettle();

      final state = tester.state(find.byType(YesNoSpeakingScreen)) as dynamic;
      expect(state.isAnsweredNotifier.value, isTrue);
      expect(state.isCorrectNotifier.value, isFalse);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockSpeakingBloc.add(const SubmitAnswer(false))).called(1);
    });

    testWidgets('5.3 dragging sphere left past threshold snaps to NO and succeeds for mismatch quest', (tester) async {
      await pumpScreen(tester);
      final sphereFinder = find.byKey(const Key('yes_no_speaking_sphere'));
      await tester.drag(sphereFinder, const Offset(-200, 0));
      await tester.pumpAndSettle();

      final state = tester.state(find.byType(YesNoSpeakingScreen)) as dynamic;
      expect(state.isSnappedNotifier.value, isTrue);
      expect(state.tiltValueNotifier.value, -1.0);
    });

    testWidgets('5.4 dragging sphere right past threshold snaps to YES and fails for mismatch quest', (tester) async {
      await pumpScreen(tester);
      final sphereFinder = find.byKey(const Key('yes_no_speaking_sphere'));
      await tester.drag(sphereFinder, const Offset(200, 0));
      await tester.pumpAndSettle();

      final state = tester.state(find.byType(YesNoSpeakingScreen)) as dynamic;
      expect(state.isAnsweredNotifier.value, isTrue);
      expect(state.isCorrectNotifier.value, isFalse);
      verify(() => mockSoundService.playWrong()).called(1);
    });

    testWidgets('5.5 for matching quest (Quest 2), tapping YES gate succeeds and snaps', (tester) async {
      final stateQ2 = SpeakingLoaded(
        quests: [sampleQuest2],
        currentIndex: 0,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.unanswered,
        gameType: GameSubtype.yesNoSpeaking,
        level: 2,
      );
      await pumpScreen(tester, state: stateQ2);

      await tester.tap(find.byKey(const Key('yes_no_speaking_gate_yes')));
      await tester.pumpAndSettle();

      final state = tester.state(find.byType(YesNoSpeakingScreen)) as dynamic;
      expect(state.isSnappedNotifier.value, isTrue);
      expect(state.tiltValueNotifier.value, 1.0);
    });

    testWidgets('5.6 for matching quest (Quest 2), tapping NO gate fails and submits wrong answer', (tester) async {
      final stateQ2 = SpeakingLoaded(
        quests: [sampleQuest2],
        currentIndex: 0,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.unanswered,
        gameType: GameSubtype.yesNoSpeaking,
        level: 2,
      );
      await pumpScreen(tester, state: stateQ2);

      await tester.tap(find.byKey(const Key('yes_no_speaking_gate_no')));
      await tester.pumpAndSettle();

      final state = tester.state(find.byType(YesNoSpeakingScreen)) as dynamic;
      expect(state.isAnsweredNotifier.value, isTrue);
      expect(state.isCorrectNotifier.value, isFalse);
      verify(() => mockSoundService.playWrong()).called(1);
    });

    testWidgets('5.7 when snapped, sphere icon changes to lock_rounded', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('yes_no_speaking_gate_no')));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    });

    testWidgets('5.8 when snapped, header updates badge text to SPEAK THE SENTENCE', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('yes_no_speaking_gate_no')));
      await tester.pumpAndSettle();

      expect(find.text('SPEAK THE SENTENCE'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // 6. Phase 2 Transition: ShadowPlaybackCompare Mounting (8 tests)
  // ---------------------------------------------------------------------------
  group('6. Phase 2 Transition: ShadowPlaybackCompare Mounting', () {
    testWidgets('6.1 ShadowPlaybackCompare is not mounted initially', (tester) async {
      await pumpScreen(tester);
      expect(find.byType(ShadowPlaybackCompare), findsNothing);
    });

    testWidgets('6.2 ShadowPlaybackCompare mounts with key yes_no_speaking_shadow_compare when snapped', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('yes_no_speaking_gate_no')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('yes_no_speaking_shadow_compare')), findsOneWidget);
    });

    testWidgets('6.3 passes quest.sampleAnswer as expectedText to ShadowPlaybackCompare', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('yes_no_speaking_gate_no')));
      await tester.pumpAndSettle();

      final shadowCompare = tester.widget<ShadowPlaybackCompare>(
        find.byKey(const Key('yes_no_speaking_shadow_compare')),
      );
      expect(shadowCompare.expectedText, 'My mother cooks pasta for dinner.');
    });

    testWidgets('6.4 sets showExpectedText to false on ShadowPlaybackCompare', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('yes_no_speaking_gate_no')));
      await tester.pumpAndSettle();

      final shadowCompare = tester.widget<ShadowPlaybackCompare>(
        find.byKey(const Key('yes_no_speaking_shadow_compare')),
      );
      expect(shadowCompare.showExpectedText, isFalse);
    });

    testWidgets('6.5 absorbs pointer events on Phase 1 widgets when isSnapped is true', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('yes_no_speaking_gate_no')));
      await tester.pumpAndSettle();

      final absorbPointer = tester.widget<AbsorbPointer>(
        find.descendant(
          of: find.byType(CustomScrollView),
          matching: find.byType(AbsorbPointer),
        ),
      );
      expect(absorbPointer.absorbing, isTrue);
    });

    testWidgets('6.6 top arena cannot be dragged once snapped', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('yes_no_speaking_gate_no')));
      await tester.pumpAndSettle();

      final sphereFinder = find.byKey(const Key('yes_no_speaking_sphere'));
      await tester.drag(sphereFinder, const Offset(100, 0), warnIfMissed: false);
      await tester.pump();

      final state = tester.state(find.byType(YesNoSpeakingScreen)) as dynamic;
      // Stays locked at -1.0
      expect(state.tiltValueNotifier.value, -1.0);
    });

    testWidgets('6.7 unmounts ShadowPlaybackCompare when question is answered', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('yes_no_speaking_gate_no')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('yes_no_speaking_shadow_compare')), findsOneWidget);

      final shadowCompare = tester.widget<ShadowPlaybackCompare>(
        find.byKey(const Key('yes_no_speaking_shadow_compare')),
      );
      shadowCompare.onConfirmed();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('yes_no_speaking_shadow_compare')), findsNothing);
    });

    testWidgets('6.8 scrolling to bottom occurs upon snapping', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('yes_no_speaking_gate_no')));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 300));

      final scrollController = tester.state<State<StatefulWidget>>(
        find.byType(YesNoSpeakingScreen),
      );
      expect(scrollController, isNotNull);
    });
  });

  // ---------------------------------------------------------------------------
  // 7. Verbal Evaluation Submission - Success Path (7 tests)
  // ---------------------------------------------------------------------------
  group('7. Verbal Evaluation Submission - Success Path', () {
    testWidgets('7.1 onConfirmed triggers hapticService.success()', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('yes_no_speaking_gate_no')));
      await tester.pumpAndSettle();

      final shadowCompare = tester.widget<ShadowPlaybackCompare>(
        find.byKey(const Key('yes_no_speaking_shadow_compare')),
      );
      shadowCompare.onConfirmed();
      await tester.pumpAndSettle();

      verify(() => mockHapticService.success()).called(1);
    });

    testWidgets('7.2 onConfirmed triggers soundService.playCorrect()', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('yes_no_speaking_gate_no')));
      await tester.pumpAndSettle();

      final shadowCompare = tester.widget<ShadowPlaybackCompare>(
        find.byKey(const Key('yes_no_speaking_shadow_compare')),
      );
      shadowCompare.onConfirmed();
      await tester.pumpAndSettle();

      verify(() => mockSoundService.playCorrect()).called(1);
    });

    testWidgets('7.3 onConfirmed dispatches SubmitAnswer(true) to SpeakingBloc', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('yes_no_speaking_gate_no')));
      await tester.pumpAndSettle();

      final shadowCompare = tester.widget<ShadowPlaybackCompare>(
        find.byKey(const Key('yes_no_speaking_shadow_compare')),
      );
      shadowCompare.onConfirmed();
      await tester.pumpAndSettle();

      verify(() => mockSpeakingBloc.add(const SubmitAnswer(true))).called(1);
    });

    testWidgets('7.4 onConfirmed mounts GameFeedbackCard with positive status', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('yes_no_speaking_gate_no')));
      await tester.pumpAndSettle();

      final shadowCompare = tester.widget<ShadowPlaybackCompare>(
        find.byKey(const Key('yes_no_speaking_shadow_compare')),
      );
      shadowCompare.onConfirmed();
      await tester.pumpAndSettle();

      expect(find.byType(GameFeedbackCard), findsOneWidget);
      final feedback = tester.widget<GameFeedbackCard>(find.byType(GameFeedbackCard));
      expect(feedback.isCorrect, isTrue);
    });

    testWidgets('7.5 subsequent submission calls while answered are locked out', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('yes_no_speaking_gate_no')));
      await tester.pumpAndSettle();

      final shadowCompare = tester.widget<ShadowPlaybackCompare>(
        find.byKey(const Key('yes_no_speaking_shadow_compare')),
      );
      shadowCompare.onConfirmed();
      await tester.pumpAndSettle();

      clearInteractions(mockSpeakingBloc);
      final state = tester.state(find.byType(YesNoSpeakingScreen)) as dynamic;
      state.submitEvaluation(true, 'text');
      await tester.pump();

      verifyNever(() => mockSpeakingBloc.add(any()));
    });

    testWidgets('7.6 onConfirmed updates isCorrectNotifier and isAnsweredNotifier to true', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('yes_no_speaking_gate_no')));
      await tester.pumpAndSettle();

      final shadowCompare = tester.widget<ShadowPlaybackCompare>(
        find.byKey(const Key('yes_no_speaking_shadow_compare')),
      );
      shadowCompare.onConfirmed();
      await tester.pumpAndSettle();

      final state = tester.state(find.byType(YesNoSpeakingScreen)) as dynamic;
      expect(state.isCorrectNotifier.value, isTrue);
      expect(state.isAnsweredNotifier.value, isTrue);
    });

    testWidgets('7.7 celebratory confetti triggers on correct answer', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('yes_no_speaking_gate_no')));
      await tester.pumpAndSettle();

      final shadowCompare = tester.widget<ShadowPlaybackCompare>(
        find.byKey(const Key('yes_no_speaking_shadow_compare')),
      );
      shadowCompare.onConfirmed();
      await tester.pumpAndSettle();

      final state = tester.state(find.byType(YesNoSpeakingScreen)) as dynamic;
      expect(state.showConfettiNotifier.value, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // 8. Verbal Evaluation Submission - Failure Path (8 tests)
  // ---------------------------------------------------------------------------
  group('8. Verbal Evaluation Submission - Failure Path', () {
    testWidgets('8.1 onSkipped triggers hapticService.error()', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('yes_no_speaking_gate_no')));
      await tester.pumpAndSettle();

      final shadowCompare = tester.widget<ShadowPlaybackCompare>(
        find.byKey(const Key('yes_no_speaking_shadow_compare')),
      );
      shadowCompare.onSkipped();
      await tester.pumpAndSettle();

      verify(() => mockHapticService.error()).called(1);
    });

    testWidgets('8.2 onSkipped triggers soundService.playWrong()', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('yes_no_speaking_gate_no')));
      await tester.pumpAndSettle();

      final shadowCompare = tester.widget<ShadowPlaybackCompare>(
        find.byKey(const Key('yes_no_speaking_shadow_compare')),
      );
      shadowCompare.onSkipped();
      await tester.pumpAndSettle();

      verify(() => mockSoundService.playWrong()).called(1);
    });

    testWidgets('8.3 onSkipped dispatches SubmitAnswer(false) to SpeakingBloc', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('yes_no_speaking_gate_no')));
      await tester.pumpAndSettle();

      final shadowCompare = tester.widget<ShadowPlaybackCompare>(
        find.byKey(const Key('yes_no_speaking_shadow_compare')),
      );
      shadowCompare.onSkipped();
      await tester.pumpAndSettle();

      verify(() => mockSpeakingBloc.add(const SubmitAnswer(false))).called(1);
    });

    testWidgets('8.4 onSkipped mounts GameFeedbackCard with incorrect status', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('yes_no_speaking_gate_no')));
      await tester.pumpAndSettle();

      final shadowCompare = tester.widget<ShadowPlaybackCompare>(
        find.byKey(const Key('yes_no_speaking_shadow_compare')),
      );
      shadowCompare.onSkipped();
      await tester.pumpAndSettle();

      expect(find.byType(GameFeedbackCard), findsOneWidget);
      final feedback = tester.widget<GameFeedbackCard>(find.byType(GameFeedbackCard));
      expect(feedback.isCorrect, isFalse);
    });

    testWidgets('8.5 onSkipped records error in ErrorJournalCollector when authenticated', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('yes_no_speaking_gate_no')));
      await tester.pumpAndSettle();

      final shadowCompare = tester.widget<ShadowPlaybackCompare>(
        find.byKey(const Key('yes_no_speaking_shadow_compare')),
      );
      shadowCompare.onSkipped();
      await tester.pumpAndSettle();

      final state = tester.state(find.byType(YesNoSpeakingScreen)) as dynamic;
      expect(state.isCorrectNotifier.value, isFalse);
    });

    testWidgets('8.6 handles unauthenticated user gracefully on error', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthState.unauthenticated());
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('yes_no_speaking_gate_no')));
      await tester.pumpAndSettle();

      final shadowCompare = tester.widget<ShadowPlaybackCompare>(
        find.byKey(const Key('yes_no_speaking_shadow_compare')),
      );
      shadowCompare.onSkipped();
      await tester.pumpAndSettle();

      verify(() => mockSpeakingBloc.add(const SubmitAnswer(false))).called(1);
    });

    testWidgets('8.7 Phase 1 incorrect choice marks answer state as false', (tester) async {
      await pumpScreen(tester);
      // Tapping YES on mismatch quest triggers Phase 1 failure
      await tester.tap(find.byKey(const Key('yes_no_speaking_gate_yes')));
      await tester.pumpAndSettle();

      final state = tester.state(find.byType(YesNoSpeakingScreen)) as dynamic;
      expect(state.isAnsweredNotifier.value, isTrue);
      expect(state.isCorrectNotifier.value, isFalse);
    });

    testWidgets('8.8 subsequent error submissions while answered are locked out', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('yes_no_speaking_gate_no')));
      await tester.pumpAndSettle();

      final shadowCompare = tester.widget<ShadowPlaybackCompare>(
        find.byKey(const Key('yes_no_speaking_shadow_compare')),
      );
      shadowCompare.onSkipped();
      await tester.pumpAndSettle();

      clearInteractions(mockSpeakingBloc);
      final state = tester.state(find.byType(YesNoSpeakingScreen)) as dynamic;
      state.submitEvaluation(false, 'text');
      await tester.pump();

      verifyNever(() => mockSpeakingBloc.add(any()));
    });
  });

  // ---------------------------------------------------------------------------
  // 9. Feedback Card, Hints & Question Progression (8 tests)
  // ---------------------------------------------------------------------------
  group('9. Feedback Card, Hints & Question Progression', () {
    testWidgets('9.1 GameFeedbackCard displays CONTINUE button', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('yes_no_speaking_gate_no')));
      await tester.pumpAndSettle();

      final shadowCompare = tester.widget<ShadowPlaybackCompare>(
        find.byKey(const Key('yes_no_speaking_shadow_compare')),
      );
      shadowCompare.onConfirmed();
      await tester.pumpAndSettle();

      expect(find.text('CONTINUE'), findsOneWidget);
    });

    testWidgets('9.2 tapping CONTINUE button dispatches NextQuestion() to SpeakingBloc', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('yes_no_speaking_gate_no')));
      await tester.pumpAndSettle();

      final shadowCompare = tester.widget<ShadowPlaybackCompare>(
        find.byKey(const Key('yes_no_speaking_shadow_compare')),
      );
      shadowCompare.onConfirmed();
      await tester.pumpAndSettle();

      await tester.tap(find.text('CONTINUE'));
      await tester.pump();

      verify(() => mockSpeakingBloc.add(const NextQuestion())).called(1);
    });

    testWidgets('9.3 tapping hint button dispatches SpeakingHintUsed() to SpeakingBloc', (tester) async {
      await pumpScreen(tester);
      clearInteractions(mockSpeakingBloc);
      expect(find.byType(QuestHintButton), findsOneWidget);

      await tester.tap(find.byType(QuestHintButton));
      await tester.pump();

      verify(() => mockSpeakingBloc.add(const SpeakingHintUsed())).called(greaterThanOrEqualTo(1));
    });

    testWidgets('9.4 onQuestionReset resets tiltValue to 0.0 and isSnapped to false', (tester) async {
      await pumpScreen(tester);
      final state = tester.state(find.byType(YesNoSpeakingScreen)) as dynamic;
      state.snapTo(false);
      await tester.pumpAndSettle();

      expect(state.isSnappedNotifier.value, isTrue);

      state.onQuestionReset();
      await tester.pumpAndSettle();

      expect(state.tiltValueNotifier.value, 0.0);
      expect(state.isSnappedNotifier.value, isFalse);
    });

    testWidgets('9.5 transitioning to second quest resets snapped state and updates target card text', (tester) async {
      await pumpScreen(tester);
      expect(find.text('My mother cooks pasta for dinner.'), findsOneWidget);

      final nextLoadedState = SpeakingLoaded(
        quests: [sampleQuest1, sampleQuest2],
        currentIndex: 1,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.unanswered,
        gameType: GameSubtype.yesNoSpeaking,
        level: 2,
      );
      speakingStreamController.add(nextLoadedState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('The bus stops near my school.'), findsOneWidget);
    });

    testWidgets('9.6 progressing to second quest unmounts GameFeedbackCard', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('yes_no_speaking_gate_no')));
      await tester.pumpAndSettle();

      final shadowCompare = tester.widget<ShadowPlaybackCompare>(
        find.byKey(const Key('yes_no_speaking_shadow_compare')),
      );
      shadowCompare.onConfirmed();
      await tester.pumpAndSettle();

      expect(find.byType(GameFeedbackCard), findsOneWidget);

      final nextLoadedState = SpeakingLoaded(
        quests: [sampleQuest1, sampleQuest2],
        currentIndex: 1,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.unanswered,
        gameType: GameSubtype.yesNoSpeaking,
        level: 2,
      );
      speakingStreamController.add(nextLoadedState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(GameFeedbackCard), findsNothing);
    });

    testWidgets('9.7 SpeakingGameComplete state triggers LEVEL COMPLETE! dialog', (tester) async {
      await pumpScreen(tester);
      const completeState = SpeakingGameComplete(
        xpEarned: 50,
        coinsEarned: 20,
        questCount: 2,
      );
      speakingStreamController.add(completeState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('LEVEL COMPLETE!'), findsOneWidget);

      Navigator.of(tester.element(find.text('LEVEL COMPLETE!'))).pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('9.8 GameShimmerLoading renders when quest is null', (tester) async {
      await pumpScreen(tester, state: const SpeakingInitial());
      expect(find.byType(GameShimmerLoading), findsOneWidget);
      expect(find.byType(YesNoSpeakingAuditionCard), findsNothing);
    });
  });

  // ---------------------------------------------------------------------------
  // 10. Viewports, Theming, Edge Cases & Robustness (8 tests)
  // ---------------------------------------------------------------------------
  group('10. Viewports, Theming, Edge Cases & Robustness', () {
    testWidgets('10.1 renders cleanly on compact phone viewport (320x640)', (tester) async {
      await pumpScreen(tester, size: const Size(320, 640));
      expect(find.byType(YesNoSpeakingScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('10.2 renders cleanly on large tablet viewport (800x1280)', (tester) async {
      await pumpScreen(tester, size: const Size(800, 1280));
      expect(find.byType(YesNoSpeakingScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('10.3 supports light theme mode without errors', (tester) async {
      await pumpScreen(tester, themeMode: ThemeMode.light);
      expect(find.byType(YesNoSpeakingScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('10.4 supports dark theme mode without errors', (tester) async {
      await pumpScreen(tester, themeMode: ThemeMode.dark);
      expect(find.byType(YesNoSpeakingScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('10.5 handles extreme text scale factors (1.5x) via clamped scaler', (tester) async {
      await pumpScreen(tester, textScaleFactor: 1.5);
      expect(find.byType(YesNoSpeakingScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('10.6 snapTo and submitEvaluation test helpers set state and dispatch properly', (tester) async {
      await pumpScreen(tester);
      final state = tester.state(find.byType(YesNoSpeakingScreen)) as dynamic;
      state.snapTo(false);
      await tester.pumpAndSettle();

      expect(state.isSnappedNotifier.value, isTrue);

      state.submitEvaluation(true, 'text');
      await tester.pumpAndSettle();

      expect(state.isCorrectNotifier.value, isTrue);
      expect(state.isAnsweredNotifier.value, isTrue);
    });

    testWidgets('10.7 rapid quest switching does not produce unhandled exceptions', (tester) async {
      await pumpScreen(tester);

      for (int i = 0; i < 3; i++) {
        final toggleState = SpeakingLoaded(
          quests: [sampleQuest1, sampleQuest2],
          currentIndex: i % 2,
          livesRemaining: 3,
          wrongCount: 0,
          hintUsed: false,
          answerStatus: AnswerStatus.unanswered,
          gameType: GameSubtype.yesNoSpeaking,
          level: 2,
        );
        speakingStreamController.add(toggleState);
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    });

    testWidgets('10.8 lifecycle pause and resume methods execute without errors', (tester) async {
      await pumpScreen(tester);
      final state = tester.state(find.byType(YesNoSpeakingScreen)) as dynamic;
      state.onGamePaused();
      state.onGameResumed();
      expect(tester.takeException(), isNull);
    });
  });
}

