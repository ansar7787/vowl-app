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
import 'package:vowl/features/accent/connected_speech/presentation/pages/connected_speech_screen.dart';
import 'package:vowl/features/accent/connected_speech/presentation/widgets/connected_speech_instruction.dart';
import 'package:vowl/features/accent/connected_speech/presentation/widgets/connected_speech_linker_cards.dart';
import 'package:vowl/features/accent/connected_speech/presentation/widgets/connected_speech_prompt_card.dart';
import 'package:vowl/features/accent/connected_speech/presentation/widgets/connected_speech_pulse_speaker.dart';
import 'package:vowl/features/accent/domain/entities/accent_quest.dart';
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
    id: 'ACC_CS_L1_Q1',
    instruction: 'Identify the connected speech linking rule.',
    difficulty: 1,
    subtype: GameSubtype.connectedSpeech,
    word: 'black cat',
    spokenForm: 'bla-kat',
    phenomenonType: 'Consonant Assimilation',
    textToSpeak: 'The black cat crossed the street.',
    options: ['bla-kat', 'black-cat'],
    correctAnswerIndex: 0,
    hint: 'Listen closely to the merged consonant sound.',
    explanation:
        'When "black" meets "cat", the k sound merges into a single held consonant.',
  );

  const testQuest2 = AccentQuest(
    id: 'ACC_CS_L1_Q2',
    instruction: 'Select the natural linking form.',
    difficulty: 1,
    subtype: GameSubtype.connectedSpeech,
    word: 'stop talking',
    spokenForm: 'stop-talking',
    phenomenonType: 'Stop Release',
    textToSpeak: 'Please stop talking for a moment.',
    options: ['stah-talking', 'stop-talking'],
    correctAnswerIndex: 1,
    hint: 'Notice whether the p sound is fully exploded or unreleased.',
    explanation: 'In natural speech, the p is unreleased before the t sound.',
  );

  const testLoadedState = AccentLoaded(
    quests: [testQuest1, testQuest2],
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
    gameType: GameSubtype.connectedSpeech,
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
      'has_seen_briefing_connectedSpeech': true,
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

  Future<void> pumpConnectedSpeech(
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
            home: ConnectedSpeechScreen(
              level: level,
              gameType: GameSubtype.connectedSpeech,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  group('ConnectedSpeechScreen - Layout & Initial UI', () {
    testWidgets('renders all core UI elements initially', (tester) async {
      await pumpConnectedSpeech(tester);

      expect(find.byType(ConnectedSpeechInstruction), findsOneWidget);
      expect(
        find.textContaining('IDENTIFY THE CONNECTED SPEECH LINKING RULE'),
        findsOneWidget,
      );

      expect(find.byType(ConnectedSpeechPromptCard), findsOneWidget);
      expect(find.text('TARGET PHRASE'), findsOneWidget);
      expect(find.text('BLACK CAT'), findsOneWidget);

      expect(find.byType(ConnectedSpeechPulseSpeaker), findsOneWidget);
      expect(find.text('HEAR PHRASE'), findsOneWidget);

      expect(find.byType(ConnectedSpeechLinkerCards), findsOneWidget);
      expect(find.text('bla-kat'), findsOneWidget);
      expect(find.text('black-cat'), findsOneWidget);

      // Stage 2 ShadowPlaybackCompare should not be visible yet
      expect(find.byType(ShadowPlaybackCompare), findsNothing);
    });

    testWidgets('tapping pulse speaker triggers TTS audio and selection haptics', (
      tester,
    ) async {
      await pumpConnectedSpeech(tester);

      final speakerBtn = find.byKey(
        const ValueKey('connected_speech_speaker'),
      );
      expect(speakerBtn, findsOneWidget);

      await tester.tap(speakerBtn);
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockHapticService.selection()).called(1);
      verify(
        () => mockSoundService.playTts('The black cat crossed the street.'),
      ).called(1);
    });
  });

  group('ConnectedSpeechScreen - Stage 1 Selection Flow', () {
    testWidgets(
      'selecting wrong linker card triggers error audio/haptics and SubmitAnswer(false)',
      (tester) async {
        await pumpConnectedSpeech(tester);

        final wrongCard = find.byKey(const ValueKey('linker_card_1'));
        expect(wrongCard, findsOneWidget);

        await tester.tap(wrongCard);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        verify(() => mockHapticService.error()).called(1);
        verify(() => mockSoundService.playWrong()).called(1);
        verify(() => mockAccentBloc.add(const SubmitAnswer(false))).called(1);
      },
    );

    testWidgets(
      'selecting correct linker card advances to stage 2 without submitting answer yet',
      (tester) async {
        await pumpConnectedSpeech(tester);

        final correctCard = find.byKey(const ValueKey('linker_card_0'));
        expect(correctCard, findsOneWidget);

        await tester.tap(correctCard);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        verify(() => mockHapticService.selection()).called(1);
        verifyNever(() => mockAccentBloc.add(const SubmitAnswer(true)));

        // Scroll down to bring ShadowPlaybackCompare into viewport
        await tester.drag(
          find.byType(CustomScrollView),
          const Offset(0, -600),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.byType(ShadowPlaybackCompare), findsOneWidget);
        expect(find.text('SHADOW & COMPARE'), findsOneWidget);
      },
    );
  });

  group('ConnectedSpeechScreen - Stage 2 Verbal Evaluation Flow', () {
    testWidgets(
      'confirming verbal evaluation ("Nailed It") awards bonus coins and dispatches SubmitAnswer(true)',
      (tester) async {
        await pumpConnectedSpeech(tester);

        // Advance past stage 1
        await tester.tap(find.byKey(const ValueKey('linker_card_0')));
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

        // Tap the mic to record
        final micButton = find.byType(AnimatedContainer);
        expect(micButton, findsWidgets);

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

        // Now comparison controls are shown
        final nailedItBtn = find.text('Nailed It');
        expect(nailedItBtn, findsOneWidget);
        await tester.tap(nailedItBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1000));

        verify(() => mockHapticService.success()).called(1);
        verify(() => mockSoundService.playCorrect()).called(1);
        verify(
          () => mockAccentBloc.add(const AccentSpeakConfirmed(5)),
        ).called(1);
        verify(() => mockAccentBloc.add(const SubmitAnswer(true))).called(1);

        await tester.pump(const Duration(seconds: 2));
      },
    );

    testWidgets(
      'skipping verbal evaluation ("Needs Work") triggers error audio/haptics and SubmitAnswer(false)',
      (tester) async {
        await pumpConnectedSpeech(tester);

        // Advance past stage 1
        await tester.tap(find.byKey(const ValueKey('linker_card_0')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        // Scroll down to reveal ShadowPlaybackCompare
        await tester.drag(
          find.byType(CustomScrollView),
          const Offset(0, -600),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Start recording
        final micIcon = find.byIcon(Icons.mic_rounded);
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

        // Tap 'Needs Work'
        final needsWorkBtn = find.text('Needs Work');
        expect(needsWorkBtn, findsOneWidget);
        await tester.tap(needsWorkBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1000));

        verify(() => mockHapticService.error()).called(1);
        verify(() => mockSoundService.playWrong()).called(1);
        verify(() => mockAccentBloc.add(const SubmitAnswer(false))).called(1);

        await tester.pump(const Duration(seconds: 2));
      },
    );
  });

  group('ConnectedSpeechScreen - Interaction Lockout & State Controls', () {
    testWidgets('locks interaction once answered preventing subsequent taps', (
      tester,
    ) async {
      await pumpConnectedSpeech(tester);

      // Submit wrong answer
      await tester.tap(find.byKey(const ValueKey('linker_card_1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockAccentBloc.add(const SubmitAnswer(false))).called(1);

      // Tap again on option 0
      await tester.tap(
        find.byKey(const ValueKey('linker_card_0')),
        warnIfMissed: false,
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Should not dispatch any further answers
      verifyNever(() => mockAccentBloc.add(const SubmitAnswer(true)));
    });

    testWidgets('tapping continue button dispatches NextQuestion', (
      tester,
    ) async {
      await pumpConnectedSpeech(tester);

      // Advance past Stage 1
      await tester.tap(find.byKey(const ValueKey('linker_card_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Scroll to ShadowPlaybackCompare
      await tester.drag(
        find.byType(CustomScrollView),
        const Offset(0, -600),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Record and complete
      final micIcon = find.byIcon(Icons.mic_rounded);
      await tester.tap(micIcon);
      await tester.pump();
      await tester.runAsync(
        () async => await Future.delayed(const Duration(milliseconds: 600)),
      );
      await tester.pump(const Duration(milliseconds: 100));

      final stopRecordingBtn = find.bySemanticsLabel('Stop recording');
      await tester.tap(stopRecordingBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Scroll down to center comparison buttons
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

    testWidgets('tapping hint button in header dispatches AccentHintUsed', (
      tester,
    ) async {
      await pumpConnectedSpeech(tester);

      final hintButton = find.byType(QuestHintButton);
      expect(hintButton, findsOneWidget);

      await tester.tap(hintButton);
      await tester.pump(const Duration(milliseconds: 300));

      verify(
        () => mockAccentBloc.add(any(that: isA<AccentHintUsed>())),
      ).called(1);
    });

    testWidgets('renders GameShimmerLoading on AccentInitial state', (
      tester,
    ) async {
      await pumpConnectedSpeech(tester, state: const AccentInitial());

      expect(find.byType(GameShimmerLoading), findsOneWidget);
      expect(find.byType(ConnectedSpeechPromptCard), findsNothing);
    });

    testWidgets('renders and dismisses GameBriefingLayer on Level 1', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        'has_seen_briefing_connectedSpeech': false,
      });

      await pumpConnectedSpeech(tester, level: 1, height: 1100);

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

    testWidgets('resets state on question transition', (tester) async {
      final stateController = StreamController<AccentState>.broadcast();
      when(
        () => mockAccentBloc.stream,
      ).thenAnswer((_) => stateController.stream);

      await pumpConnectedSpeech(tester);

      // Select correct answer for quest 1
      await tester.tap(find.byKey(const ValueKey('linker_card_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Transition to quest 2
      const quest2State = AccentLoaded(
        quests: [testQuest1, testQuest2],
        currentIndex: 1,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
        gameType: GameSubtype.connectedSpeech,
        level: 2,
        hintUsed: false,
        wrongCount: 0,
        isFinalFailure: false,
      );
      when(() => mockAccentBloc.state).thenReturn(quest2State);
      stateController.add(quest2State);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Second quest prompt is now displayed
      expect(find.text('STOP TALKING'), findsOneWidget);
      expect(find.text('stah-talking'), findsOneWidget);
      expect(find.text('stop-talking'), findsOneWidget);

      await stateController.close();
    });
  });

  group('ConnectedSpeechScreen - Theme & Responsiveness', () {
    testWidgets('renders cleanly in dark theme mode', (tester) async {
      await pumpConnectedSpeech(tester, themeMode: ThemeMode.dark);

      expect(find.byType(ConnectedSpeechPromptCard), findsOneWidget);
      expect(find.byType(ConnectedSpeechPulseSpeaker), findsOneWidget);
      expect(find.byType(ConnectedSpeechLinkerCards), findsOneWidget);
    });

    testWidgets(
      'renders without RenderFlex overflow on small 320dp screen width',
      (tester) async {
        await pumpConnectedSpeech(tester, width: 320, height: 568);

        expect(tester.takeException(), isNull);
        expect(find.byType(ConnectedSpeechPromptCard), findsOneWidget);
        expect(find.byType(ConnectedSpeechPulseSpeaker), findsOneWidget);
        expect(find.byType(ConnectedSpeechLinkerCards), findsOneWidget);
      },
    );

    testWidgets(
      'reveals written vs spoken comparison and phenomenon tag in prompt card when answered',
      (tester) async {
        await pumpConnectedSpeech(tester);

        // Advance past stage 1
        await tester.tap(find.byKey(const ValueKey('linker_card_0')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        expect(find.text('WRITTEN'), findsOneWidget);
        expect(find.text('SPOKEN'), findsOneWidget);
        expect(find.text('BLA-KAT'), findsOneWidget);
        expect(find.text('CONSONANT ASSIMILATION'), findsOneWidget);
      },
    );
  });
}

