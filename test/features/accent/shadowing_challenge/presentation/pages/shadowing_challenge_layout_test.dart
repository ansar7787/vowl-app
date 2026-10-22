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
import 'package:vowl/core/utils/analytics_service.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/audio_recording_service.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/speech_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/accent/domain/entities/accent_quest.dart';
import 'package:vowl/features/accent/presentation/bloc/accent_bloc.dart';
import 'package:vowl/features/accent/shadowing_challenge/presentation/pages/shadowing_challenge_screen.dart';
import 'package:vowl/features/accent/shadowing_challenge/presentation/widgets/shadowing_challenge_dialogue_list.dart';
import 'package:vowl/features/accent/shadowing_challenge/presentation/widgets/shadowing_challenge_instruction.dart';
import 'package:vowl/features/accent/shadowing_challenge/presentation/widgets/shadowing_challenge_prompt_card.dart';
import 'package:vowl/features/accent/shadowing_challenge/presentation/widgets/shadowing_challenge_pulse_speaker.dart';
import 'package:vowl/features/accent/shadowing_challenge/presentation/widgets/shadowing_challenge_speed_slider.dart';
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

class MockSpeechService extends Mock implements SpeechService {}

class MockAudioRecordingService extends Mock implements AudioRecordingService {}

class MockLocaleService extends Mock implements LocaleService {}

class MockAppLogger extends Mock implements AppLogger {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

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
  late MockSpeechService mockSpeechService;
  late MockAudioRecordingService mockAudioRecorder;
  late MockLocaleService mockLocaleService;
  late MockAppLogger mockLogger;
  late MockAnalyticsService mockAnalyticsService;

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
    id: 'ACC_SC_L1_Q1',
    instruction: 'Listen carefully and shadow the speaker phrase.',
    difficulty: 1,
    subtype: GameSubtype.shadowingChallenge,
    word: 'Could you pass the salt please?',
    textToSpeak: 'Could you pass the salt please?',
    phoneticHint: '/kʊd juː pɑːs ðə sɒlt pliːz/',
    options: [
      'Could you pass the salt please?',
      'Could you pass the soup please?',
    ],
    correctAnswerIndex: 0,
    hint: 'Pay attention to the vowel sounds in "salt".',
    explanation: 'Notice the smooth linking between "could" and "you".',
  );

  const testQuest2 = AccentQuest(
    id: 'ACC_SC_L1_Q2',
    instruction: 'Listen carefully and shadow the speaker phrase.',
    difficulty: 1,
    subtype: GameSubtype.shadowingChallenge,
    word: 'What time is the next train?',
    textToSpeak: 'What time is the next train?',
    phoneticHint: '/wɒt taɪm ɪz ðə nekst treɪn/',
    options: [
      'What time is the next train?',
      'What time is the last train?',
    ],
    correctAnswerIndex: 0,
    hint: 'Listen for "next" versus "last".',
    explanation: 'Clear t-glottaling before consonant onset.',
  );

  const testLoadedState = AccentLoaded(
    quests: [testQuest1, testQuest2],
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
    gameType: GameSubtype.shadowingChallenge,
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
    mockSpeechService = MockSpeechService();
    mockAudioRecorder = MockAudioRecordingService();
    mockLocaleService = MockLocaleService();
    mockLogger = MockAppLogger();
    mockAnalyticsService = MockAnalyticsService();

    VowlMotion.lowAnimationModeOverride.value = true;

    SharedPreferences.setMockInitialValues({
      'has_seen_briefing_shadowingChallenge': true,
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
    when(
      () => mockSoundService.playTts(
        any(),
        speed: any(named: 'speed'),
      ),
    ).thenAnswer((_) async {});
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

    when(() => mockSpeechService.initializeStt()).thenAnswer((_) async => true);
    when(() => mockSpeechService.stop()).thenAnswer((_) async {});
    when(() => mockSpeechService.cancel()).thenAnswer((_) async {});
    when(() => mockSpeechService.isListening).thenReturn(false);
    when(() => mockSpeechService.isPlaying).thenReturn(false);

    when(() => mockAudioRecorder.hasPermission()).thenAnswer((_) async => true);
    when(() => mockAudioRecorder.startRecording()).thenAnswer((_) async => true);
    when(
      () => mockAudioRecorder.stopRecording(),
    ).thenAnswer((_) async => '/tmp/audio_shadow.m4a');
    when(() => mockAudioRecorder.isRecording).thenReturn(false);
    when(
      () => mockAudioRecorder.onAmplitudeChanged(any()),
    ).thenAnswer((_) => Stream.value(Amplitude(current: -10, max: -5)));
    when(() => mockAudioRecorder.dispose()).thenAnswer((_) async {});

    when(() => mockAnalyticsService.logSelfEvaluation(any())).thenAnswer((_) async {});
    when(() => mockAnalyticsService.logGameSkipped(any())).thenAnswer((_) async {});

    await di.sl.reset();

    di.sl.registerSingleton<HapticService>(mockHapticService);
    di.sl.registerSingleton<SoundService>(mockSoundService);
    di.sl.registerSingleton<TtsService>(mockTtsService);
    di.sl.registerSingleton<SpeechService>(mockSpeechService);
    di.sl.registerSingleton<AudioRecordingService>(mockAudioRecorder);
    di.sl.registerSingleton<LocaleService>(mockLocaleService);
    di.sl.registerSingleton<AppLogger>(mockLogger);
    di.sl.registerSingleton<AnalyticsService>(mockAnalyticsService);
  });

  tearDown(() async {
    VowlMotion.lowAnimationModeOverride.value = false;
    await di.sl.reset();
  });

  Future<void> pumpShadowingChallenge(
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
            home: ShadowingChallengeScreen(level: level),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('ShadowingChallengeScreen - Component Layout & Initial State', () {
    testWidgets('renders all initial UI components cleanly', (tester) async {
      await pumpShadowingChallenge(tester);

      expect(find.byType(ShadowingChallengeInstruction), findsOneWidget);
      expect(
        find.text('Listen carefully and shadow the speaker phrase.'),
        findsOneWidget,
      );
      expect(find.byType(ShadowingChallengePromptCard), findsOneWidget);
      expect(find.text('Could you pass the salt please?'), findsWidgets);
      expect(find.text('/kʊd juː pɑːs ðə sɒlt pliːz/'), findsOneWidget);
      expect(find.byType(ShadowingChallengePulseSpeaker), findsOneWidget);
      expect(find.text('Listen'), findsOneWidget);
      expect(find.byType(ShadowingChallengeSpeedSlider), findsOneWidget);
      expect(find.text('1.00x'), findsOneWidget);
      expect(find.byType(ShadowingChallengeDialogueList), findsOneWidget);

      // Phase 2 overlay shouldn't be visible in initial unanswered state
      expect(find.byType(ShadowPlaybackCompare), findsNothing);
    });

    testWidgets('tapping pulse speaker triggers TTS audio and selection haptics at selected speed', (tester) async {
      await pumpShadowingChallenge(tester);

      final speakerBtn = find.byKey(const ValueKey('shadowing_speaker_btn'));
      expect(speakerBtn, findsOneWidget);

      await tester.tap(speakerBtn);
      await tester.pump();

      verify(() => mockHapticService.selection()).called(1);
      verify(() => mockSoundService.playTts(
            'Could you pass the salt please?',
            speed: any(named: 'speed'),
          )).called(1);
    });

    testWidgets('changing speed slider updates speed multiplier display and subsequent TTS', (tester) async {
      await pumpShadowingChallenge(tester);

      final slider = find.byKey(const ValueKey('shadowing_speed_slider'));
      expect(slider, findsOneWidget);

      // Drag to slow speed (0.75x)
      await tester.drag(slider, const Offset(-100, 0));
      await tester.pumpAndSettle();

      expect(find.text('0.75x'), findsOneWidget);

      final speakerBtn = find.byKey(const ValueKey('shadowing_speaker_btn'));
      await tester.tap(speakerBtn);
      await tester.pump();

      verify(() => mockSoundService.playTts(
            'Could you pass the salt please?',
            speed: 0.4 * 0.75,
          )).called(1);
    });

    testWidgets('tapping hint button dispatches AccentHintUsed without duplicates', (tester) async {
      await pumpShadowingChallenge(tester);

      final hintBtn = find.byType(QuestHintButton);
      expect(hintBtn, findsOneWidget);

      await tester.tap(hintBtn);
      await tester.pump();

      verify(() => mockAccentBloc.add(any(that: isA<AccentHintUsed>()))).called(1);
    });

    testWidgets('renders GameShimmerLoading when in AccentInitial state', (tester) async {
      await pumpShadowingChallenge(tester, state: const AccentInitial());

      expect(find.byType(GameShimmerLoading), findsOneWidget);
      expect(find.byType(ShadowingChallengeDialogueList), findsNothing);
    });
  });

  group('ShadowingChallengeScreen - Phase 1 Dialogue Selection Flow', () {
    testWidgets('tapping wrong dialogue bubble triggers error audio/haptics and submits wrong answer', (tester) async {
      await pumpShadowingChallenge(tester);

      // Find which option is wrong
      final opt0Text = (tester.widget(find.descendant(
        of: find.byKey(const ValueKey('shadowing_option_0')),
        matching: find.byType(Text),
      ).first) as Text).data;

      final wrongIndex = opt0Text == 'Could you pass the salt please?' ? 1 : 0;
      final wrongOption = find.byKey(ValueKey('shadowing_option_$wrongIndex'));

      await tester.tap(wrongOption);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockHapticService.error()).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockAccentBloc.add(const SubmitAnswer(false))).called(1);

      // Phase 2 overlay remains unmounted
      expect(find.byType(ShadowPlaybackCompare), findsNothing);
    });

    testWidgets('tapping correct dialogue bubble advances to Stage 2 verbal evaluation without early answer submission', (tester) async {
      await pumpShadowingChallenge(tester);

      final opt0Text = (tester.widget(find.descendant(
        of: find.byKey(const ValueKey('shadowing_option_0')),
        matching: find.byType(Text),
      ).first) as Text).data;

      final correctIndex = opt0Text == 'Could you pass the salt please?' ? 0 : 1;
      final correctOption = find.byKey(ValueKey('shadowing_option_$correctIndex'));

      await tester.tap(correctOption);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockHapticService.success()).called(1);
      verify(() => mockSoundService.playCorrect()).called(1);
      verifyNever(() => mockAccentBloc.add(const SubmitAnswer(true)));

      // Instruction changes to stage 2 recording prompt
      expect(
        find.text('Great job! Now record yourself saying the phrase.'),
        findsOneWidget,
      );

      // Scroll down to bring ShadowPlaybackCompare into view
      await tester.drag(
        find.byType(CustomScrollView),
        const Offset(0, -600),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ShadowPlaybackCompare), findsOneWidget);
    });

    testWidgets('interaction lockout prevents secondary taps once answered', (tester) async {
      await pumpShadowingChallenge(tester);

      final opt0Text = (tester.widget(find.descendant(
        of: find.byKey(const ValueKey('shadowing_option_0')),
        matching: find.byType(Text),
      ).first) as Text).data;

      final wrongIndex = opt0Text == 'Could you pass the salt please?' ? 1 : 0;
      final correctIndex = opt0Text == 'Could you pass the salt please?' ? 0 : 1;

      // Submit wrong answer
      final wrongOption = find.byKey(ValueKey('shadowing_option_$wrongIndex'));
      await tester.tap(wrongOption);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockAccentBloc.add(const SubmitAnswer(false))).called(1);

      // Further taps on correct option are ignored
      final correctOption = find.byKey(ValueKey('shadowing_option_$correctIndex'));
      await tester.tap(correctOption, warnIfMissed: false);
      await tester.pump();

      verifyNever(() => mockAccentBloc.add(const SubmitAnswer(true)));
    });
  });

  group('ShadowingChallengeScreen - Phase 2 Speaking & Shadow Comparison Flow', () {
    testWidgets('recording audio and confirming "Nailed It" dispatches AccentSpeakConfirmed(5) and SubmitAnswer(true)', (tester) async {
      await pumpShadowingChallenge(tester);

      // Advance stage 1
      final opt0Text = (tester.widget(find.descendant(
        of: find.byKey(const ValueKey('shadowing_option_0')),
        matching: find.byType(Text),
      ).first) as Text).data;
      final correctIndex = opt0Text == 'Could you pass the salt please?' ? 0 : 1;

      await tester.tap(find.byKey(ValueKey('shadowing_option_$correctIndex')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Scroll down to ShadowPlaybackCompare
      await tester.drag(
        find.byType(CustomScrollView),
        const Offset(0, -600),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final micBtn = find.byKey(const ValueKey('shadow_mic_btn'));
      expect(micBtn, findsOneWidget);

      // Start recording
      await tester.tap(micBtn);
      await tester.pump();
      await tester.runAsync(
        () async => await Future.delayed(const Duration(milliseconds: 600)),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Stop recording
      await tester.tap(micBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Comparison phase is now visible
      expect(find.byKey(const ValueKey('comparison_phase')), findsOneWidget);

      await tester.drag(
        find.byType(CustomScrollView),
        const Offset(0, -400),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final nailedItBtn = find.text('Nailed It');
      expect(nailedItBtn, findsOneWidget);
      await tester.tap(nailedItBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockHapticService.success()).called(2); // 1 for option, 1 for speak
      verify(() => mockSoundService.playCorrect()).called(2);
      verify(() => mockAccentBloc.add(const AccentSpeakConfirmed(5))).called(1);
      verify(() => mockAccentBloc.add(const SubmitAnswer(true))).called(1);
    });

    testWidgets('evaluating "Needs Work" triggers error feedback and SubmitAnswer(false)', (tester) async {
      await pumpShadowingChallenge(tester);

      // Advance stage 1
      final opt0Text = (tester.widget(find.descendant(
        of: find.byKey(const ValueKey('shadowing_option_0')),
        matching: find.byType(Text),
      ).first) as Text).data;
      final correctIndex = opt0Text == 'Could you pass the salt please?' ? 0 : 1;

      await tester.tap(find.byKey(ValueKey('shadowing_option_$correctIndex')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Scroll down to ShadowPlaybackCompare
      await tester.drag(
        find.byType(CustomScrollView),
        const Offset(0, -600),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final micBtn = find.byKey(const ValueKey('shadow_mic_btn'));
      await tester.tap(micBtn);
      await tester.pump();
      await tester.runAsync(
        () async => await Future.delayed(const Duration(milliseconds: 600)),
      );
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(micBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      // Comparison phase is now visible
      expect(find.byKey(const ValueKey('comparison_phase')), findsOneWidget);

      await tester.drag(
        find.byType(CustomScrollView),
        const Offset(0, -400),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final needsWorkBtn = find.text('Needs Work');
      expect(needsWorkBtn, findsOneWidget);
      await tester.tap(needsWorkBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockHapticService.error()).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockAccentBloc.add(const SubmitAnswer(false))).called(1);
    });

    testWidgets('tapping continue button when answered dispatches NextQuestion', (tester) async {
      await pumpShadowingChallenge(tester);

      // Submit wrong answer to become answered
      final opt0Text = (tester.widget(find.descendant(
        of: find.byKey(const ValueKey('shadowing_option_0')),
        matching: find.byType(Text),
      ).first) as Text).data;
      final wrongIndex = opt0Text == 'Could you pass the salt please?' ? 1 : 0;

      await tester.tap(find.byKey(ValueKey('shadowing_option_$wrongIndex')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final continueBtn = find.text('TRY AGAIN');
      expect(continueBtn, findsOneWidget);

      await tester.tap(continueBtn);
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockAccentBloc.add(const NextQuestion())).called(1);
    });
  });

  group('ShadowingChallengeScreen - Briefing, Small Screens & Accessibility', () {
    testWidgets('renders and dismisses GameBriefingLayer on Level 1', (tester) async {
      SharedPreferences.setMockInitialValues({
        'has_seen_briefing_shadowingChallenge': false,
      });

      await pumpShadowingChallenge(tester, level: 1, height: 1300);

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

    testWidgets('instruction text has centered alignment and wraps properly without ellipsis', (tester) async {
      const longInstructionQuest = AccentQuest(
        id: 'ACC_SC_LONG',
        instruction: 'Listen carefully to the full sentence and shadow every word with natural linking.',
        difficulty: 1,
        subtype: GameSubtype.shadowingChallenge,
        word: 'Could you pass the salt please?',
        textToSpeak: 'Could you pass the salt please?',
        options: ['Could you pass the salt please?', 'Could you pass the soup please?'],
        correctAnswerIndex: 0,
      );

      const longState = AccentLoaded(
        quests: [longInstructionQuest],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
        gameType: GameSubtype.shadowingChallenge,
        level: 2,
        hintUsed: false,
        wrongCount: 0,
        isFinalFailure: false,
      );

      await pumpShadowingChallenge(tester, state: longState);

      final instructionFinder = find.descendant(
        of: find.byType(ShadowingChallengeInstruction),
        matching: find.byType(Text),
      );
      expect(instructionFinder, findsOneWidget);

      final instructionText = tester.widget<Text>(instructionFinder);
      expect(instructionText.textAlign, TextAlign.center);
      expect(instructionText.overflow, isNot(TextOverflow.ellipsis));
      expect(instructionText.softWrap, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly on small device (320x568) in dark theme without overflow', (tester) async {
      await pumpShadowingChallenge(
        tester,
        themeMode: ThemeMode.dark,
        width: 320,
        height: 568,
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(ShadowingChallengePromptCard), findsOneWidget);
      expect(find.byType(ShadowingChallengeDialogueList), findsOneWidget);

      // Verify prompt card and dialogue options do not have ellipsis
      final promptTextFinder = find.descendant(
        of: find.byType(ShadowingChallengePromptCard),
        matching: find.text('Could you pass the salt please?'),
      );
      final promptText = tester.widget<Text>(promptTextFinder);
      expect(promptText.overflow, isNot(TextOverflow.ellipsis));
      expect(promptText.softWrap, isTrue);
    });

    testWidgets('respects reduced motion when lowAnimationModeOverride is enabled', (tester) async {
      VowlMotion.lowAnimationModeOverride.value = true;

      await pumpShadowingChallenge(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(ShadowingChallengeScreen), findsOneWidget);

      final speakerBtn = find.byKey(const ValueKey('shadowing_speaker_btn'));
      await tester.tap(speakerBtn);
      await tester.pump();

      verify(() => mockSoundService.playTts(
            'Could you pass the salt please?',
            speed: any(named: 'speed'),
          )).called(1);
    });
  });
}

