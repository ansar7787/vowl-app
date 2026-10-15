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
import 'package:vowl/core/presentation/game_mechanics/speaking/shadow_playback_compare.dart';
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
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/accent/domain/entities/accent_quest.dart';
import 'package:vowl/features/accent/minimal_pairs/presentation/pages/minimal_pairs_screen.dart';
import 'package:vowl/features/accent/minimal_pairs/presentation/widgets/minimal_pairs_drone_option.dart';
import 'package:vowl/features/accent/minimal_pairs/presentation/widgets/minimal_pairs_instruction.dart';
import 'package:vowl/features/accent/minimal_pairs/presentation/widgets/minimal_pairs_mouth_diagram.dart';
import 'package:vowl/features/accent/minimal_pairs/presentation/widgets/minimal_pairs_speaker_core.dart';
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
    id: 'ACC_MP_L1_Q1',
    instruction: 'Listen carefully and select the word you hear.',
    difficulty: 1,
    subtype: GameSubtype.minimalPairs,
    word1: 'ship',
    ipa1: '/ʃɪp/',
    word2: 'sheep',
    ipa2: '/ʃiːp/',
    correctAnswer: 'ship',
    correctAnswerIndex: 0,
    textToSpeak: 'ship',
    mouthPosition: 'Relaxed lips, short vowel sound.',
    hint: 'Notice the vowel length difference.',
    explanation: 'Short /ɪ/ in ship vs long /iː/ in sheep.',
  );

  const testQuest2 = AccentQuest(
    id: 'ACC_MP_L1_Q2',
    instruction: 'Listen carefully and select the word you hear.',
    difficulty: 1,
    subtype: GameSubtype.minimalPairs,
    word1: 'bat',
    ipa1: '/bæt/',
    word2: 'bet',
    ipa2: '/bɛt/',
    correctAnswer: 'bet',
    correctAnswerIndex: 1,
    textToSpeak: 'bet',
    mouthPosition: 'Mouth half open, mid-front vowel.',
    hint: 'Listen for the open vs mid vowel.',
    explanation: 'Open /æ/ in bat vs mid /ɛ/ in bet.',
  );

  const testLoadedState = AccentLoaded(
    quests: [testQuest1, testQuest2],
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
    gameType: GameSubtype.minimalPairs,
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
    mockAudioRecorder = MockAudioRecordingService();
    mockLocaleService = MockLocaleService();
    mockLogger = MockAppLogger();
    mockAnalyticsService = MockAnalyticsService();
    mockAdService = MockAdService();

    VowlMotion.lowAnimationModeOverride.value = true;

    SharedPreferences.setMockInitialValues({
      'has_seen_briefing_minimalPairs': true,
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
    when(() => mockSoundService.playTts(any())).thenAnswer((_) async {});
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

    await di.sl.reset();

    di.sl.registerSingleton<HapticService>(mockHapticService);
    di.sl.registerSingleton<SoundService>(mockSoundService);
    di.sl.registerSingleton<TtsService>(mockTtsService);
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

  Future<void> pumpMinimalPairs(
    WidgetTester tester, {
    AccentState? state,
    int level = 2,
    ThemeMode themeMode = ThemeMode.light,
    double width = 390,
    double height = 844,
  }) async {
    if (state != null) {
      when(() => mockAccentBloc.state).thenReturn(state);
    }

    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

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
            home: MinimalPairsScreen(level: level),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Finder findCorrectDrone(WidgetTester tester) {
    final drone0 = tester.widget<MinimalPairsDroneOption>(
      find.ancestor(
        of: find.byKey(const ValueKey('minimal_pairs_drone_0')),
        matching: find.byType(MinimalPairsDroneOption),
      ),
    );
    if (drone0.index == drone0.correctIndex) {
      return find.byKey(const ValueKey('minimal_pairs_drone_0'));
    } else {
      return find.byKey(const ValueKey('minimal_pairs_drone_1'));
    }
  }

  Finder findWrongDrone(WidgetTester tester) {
    final drone0 = tester.widget<MinimalPairsDroneOption>(
      find.ancestor(
        of: find.byKey(const ValueKey('minimal_pairs_drone_0')),
        matching: find.byType(MinimalPairsDroneOption),
      ),
    );
    if (drone0.index != drone0.correctIndex) {
      return find.byKey(const ValueKey('minimal_pairs_drone_0'));
    } else {
      return find.byKey(const ValueKey('minimal_pairs_drone_1'));
    }
  }

  group('MinimalPairsScreen - Component Layout & Initial State', () {
    testWidgets('renders all essential elements in initial state', (tester) async {
      await pumpMinimalPairs(tester);

      expect(find.byType(MinimalPairsInstruction), findsOneWidget);
      expect(
        find.text('LISTEN CAREFULLY AND SELECT THE WORD YOU HEAR.'),
        findsOneWidget,
      );
      expect(find.byType(MinimalPairsSpeakerCore), findsOneWidget);
      expect(find.byType(MinimalPairsDroneOption), findsNWidgets(2));
      expect(find.text('SHIP'), findsOneWidget);
      expect(find.text('SHEEP'), findsOneWidget);
      expect(find.text('/ʃɪp/'), findsOneWidget);
      expect(find.text('/ʃiːp/'), findsOneWidget);

      // Phase 2 components must NOT be visible yet
      expect(find.byType(MinimalPairsMouthDiagram), findsNothing);
      expect(find.byType(ShadowPlaybackCompare), findsNothing);
    });

    testWidgets('tapping speaker core triggers TTS audio playback and selection haptics', (tester) async {
      await pumpMinimalPairs(tester);

      final speakerBtn = find.byKey(const ValueKey('minimal_pairs_speaker_btn'));
      expect(speakerBtn, findsOneWidget);

      await tester.tap(speakerBtn);
      await tester.pump();

      verify(() => mockHapticService.selection()).called(1);
      verify(() => mockSoundService.playTts('ship')).called(1);
    });

    testWidgets('tapping hint button triggers AccentHintUsed event', (tester) async {
      await pumpMinimalPairs(tester);

      final hintBtn = find.byType(QuestHintButton);
      expect(hintBtn, findsOneWidget);

      await tester.tap(hintBtn);
      await tester.pump();

      verify(() => mockAccentBloc.add(any(that: isA<AccentHintUsed>()))).called(1);
    });

    testWidgets('renders shimmer loading when in AccentInitial state', (tester) async {
      await pumpMinimalPairs(
        tester,
        state: const AccentInitial(),
      );

      expect(find.byType(GameShimmerLoading), findsOneWidget);
      expect(find.byType(MinimalPairsSpeakerCore), findsNothing);
    });
  });

  group('MinimalPairsScreen - Phase 1 Drone Selection Flow', () {
    testWidgets('tapping wrong drone triggers error audio/haptics and submits incorrect answer', (tester) async {
      await pumpMinimalPairs(tester);

      final wrongDrone = findWrongDrone(tester);
      await tester.tap(wrongDrone);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockHapticService.error()).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockAccentBloc.add(const SubmitAnswer(false))).called(1);

      // Phase 2 components should still not be visible
      expect(find.byType(MinimalPairsMouthDiagram), findsNothing);
      expect(find.byType(ShadowPlaybackCompare), findsNothing);
    });

    testWidgets('tapping correct drone advances to stage 2 without submitting answer yet', (tester) async {
      await pumpMinimalPairs(tester);

      final correctDrone = findCorrectDrone(tester);
      await tester.tap(correctDrone);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockHapticService.success()).called(1);
      verify(() => mockSoundService.playCorrect()).called(1);
      verifyNever(() => mockAccentBloc.add(const SubmitAnswer(true)));

      // Instruction changes to stage 2 prompt
      expect(
        find.text('GREAT JOB! NOW CONFIRM BY SPEAKING THE WORD.'),
        findsOneWidget,
      );

      // Mouth diagram appears in phase 2
      expect(find.byType(MinimalPairsMouthDiagram), findsOneWidget);
      expect(find.text('MOUTH POSITION'), findsOneWidget);
      expect(find.text('Relaxed lips, short vowel sound.'), findsOneWidget);

      // Scroll down to bring ShadowPlaybackCompare into viewport
      await tester.drag(
        find.byType(CustomScrollView),
        const Offset(0, -600),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ShadowPlaybackCompare), findsOneWidget);
      expect(find.text('SHADOW & COMPARE'), findsOneWidget);
    });

    testWidgets('interaction lockout prevents further drone taps after answering', (tester) async {
      await pumpMinimalPairs(tester);

      // Submit wrong answer
      final wrongDrone = findWrongDrone(tester);
      await tester.tap(wrongDrone);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockAccentBloc.add(const SubmitAnswer(false))).called(1);

      // Further taps on correct drone are ignored
      final correctDrone = findCorrectDrone(tester);
      await tester.tap(correctDrone, warnIfMissed: false);
      await tester.pump();

      verifyNever(() => mockAccentBloc.add(const SubmitAnswer(true)));
    });
  });

  group('MinimalPairsScreen - Phase 2 Speaking & Self-Evaluation Flow', () {
    testWidgets('confirming verbal evaluation ("Nailed It") awards bonus coins and dispatches SubmitAnswer(true)', (tester) async {
      await pumpMinimalPairs(tester);

      // Advance stage 1
      await tester.tap(findCorrectDrone(tester));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Scroll down to reveal ShadowPlaybackCompare
      await tester.drag(
        find.byType(CustomScrollView),
        const Offset(0, -600),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ShadowPlaybackCompare), findsOneWidget);

      // Tap mic to start recording
      final micIcon = find.byIcon(Icons.mic_rounded);
      expect(micIcon, findsOneWidget);
      await tester.tap(micIcon);
      await tester.pump();
      await tester.runAsync(
        () async => await Future.delayed(const Duration(milliseconds: 600)),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Stop recording
      final stopRecordingBtn = find.bySemanticsLabel('Stop recording');
      expect(stopRecordingBtn, findsOneWidget);
      await tester.tap(stopRecordingBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Scroll down slightly more so comparison controls are centered
      await tester.drag(
        find.byType(CustomScrollView),
        const Offset(0, -300),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Evaluation buttons shown
      final nailedItBtn = find.text('Nailed It');
      expect(nailedItBtn, findsOneWidget);
      await tester.tap(nailedItBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));

      verify(() => mockHapticService.success()).called(2); // 1 for drone, 1 for nailed it
      verify(() => mockSoundService.playCorrect()).called(2);
      verify(() => mockAccentBloc.add(const AccentSpeakConfirmed(5))).called(1);
      verify(() => mockAccentBloc.add(const SubmitAnswer(true))).called(1);

      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('evaluating "Needs Work" triggers error audio/haptics and SubmitAnswer(false)', (tester) async {
      await pumpMinimalPairs(tester);

      // Advance stage 1
      await tester.tap(findCorrectDrone(tester));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Scroll down to reveal ShadowPlaybackCompare
      await tester.drag(
        find.byType(CustomScrollView),
        const Offset(0, -600),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Tap mic to record
      final micIcon = find.byIcon(Icons.mic_rounded);
      await tester.tap(micIcon);
      await tester.pump();
      await tester.runAsync(
        () async => await Future.delayed(const Duration(milliseconds: 600)),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Stop recording
      final stopRecordingBtn = find.bySemanticsLabel('Stop recording');
      await tester.tap(stopRecordingBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Scroll down slightly
      await tester.drag(
        find.byType(CustomScrollView),
        const Offset(0, -300),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final needsWorkBtn = find.text('Needs Work');
      expect(needsWorkBtn, findsOneWidget);
      await tester.tap(needsWorkBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1000));

      verify(() => mockHapticService.error()).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockAccentBloc.add(const SubmitAnswer(false))).called(1);

      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('tapping continue button when answered dispatches NextQuestion', (tester) async {
      await pumpMinimalPairs(tester);

      // Advance stage 1
      await tester.tap(findCorrectDrone(tester));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Scroll down to reveal ShadowPlaybackCompare
      await tester.drag(
        find.byType(CustomScrollView),
        const Offset(0, -600),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Tap mic to record
      final micIcon = find.byIcon(Icons.mic_rounded);
      await tester.tap(micIcon);
      await tester.pump();
      await tester.runAsync(
        () async => await Future.delayed(const Duration(milliseconds: 600)),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Stop recording
      final stopRecordingBtn = find.bySemanticsLabel('Stop recording');
      await tester.tap(stopRecordingBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Scroll down slightly to reveal eval controls
      await tester.drag(
        find.byType(CustomScrollView),
        const Offset(0, -300),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap Nailed It to trigger correct answer submission and reveal feedback card
      final nailedItBtn = find.text('Nailed It');
      await tester.tap(nailedItBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final continueBtn = find.text('CONTINUE');
      expect(continueBtn, findsOneWidget);

      await tester.tap(continueBtn);
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockAccentBloc.add(const NextQuestion())).called(1);
    });
  });

  group('MinimalPairsScreen - Briefing, Small Screens & Accessibility', () {
    testWidgets('renders and dismisses GameBriefingLayer on Level 1', (tester) async {
      SharedPreferences.setMockInitialValues({
        'has_seen_briefing_minimalPairs': false,
      });

      await pumpMinimalPairs(tester, level: 1, height: 1100);

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
    });

    testWidgets('renders cleanly on small device (320x568) in dark theme without overflow', (tester) async {
      await pumpMinimalPairs(
        tester,
        themeMode: ThemeMode.dark,
        width: 320,
        height: 568,
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(MinimalPairsSpeakerCore), findsOneWidget);
      expect(find.byType(MinimalPairsDroneOption), findsNWidgets(2));
    });

    testWidgets('respects reduced motion when lowAnimationModeOverride is enabled', (tester) async {
      VowlMotion.lowAnimationModeOverride.value = true;

      await pumpMinimalPairs(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(MinimalPairsScreen), findsOneWidget);

      // Tapping speaker core still functions normally
      final speakerBtn = find.byKey(const ValueKey('minimal_pairs_speaker_btn'));
      await tester.tap(speakerBtn);
      await tester.pump();

      verify(() => mockSoundService.playTts('ship')).called(1);
    });
  });
}

