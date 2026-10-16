import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/core/presentation/game_mechanics/speaking/speak_to_confirm_overlay.dart';
import 'package:vowl/core/presentation/widgets/game_feedback_card.dart';
import 'package:vowl/core/presentation/widgets/quest_briefing_overlay.dart';
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
import 'package:vowl/features/speaking/domain/entities/speaking_quest.dart';
import 'package:vowl/features/speaking/presentation/bloc/speaking_bloc.dart';
import 'package:vowl/features/speaking/situation_speaking/presentation/pages/situation_speaking_screen.dart';
import 'package:vowl/features/speaking/situation_speaking/presentation/widgets/situation_speaking_briefing_card.dart';
import 'package:vowl/features/speaking/situation_speaking/presentation/widgets/situation_speaking_header.dart';

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
    String id = 'quest_situation_1',
    String situationText =
        'You are at a busy coffee shop and the barista accidentally gives you whole milk instead of oat milk. Politely ask for a replacement.',
    String correctAnswer =
        'Excuse me, I ordered oat milk instead of whole milk. Could you please remake this?',
    String textToSpeak =
        'Excuse me, I ordered oat milk instead of whole milk. Could you please remake this?',
    List<String>? acceptedSynonyms = const [
      'excuse me',
      'remake',
      'oat milk',
      'coffee',
    ],
    String instruction = 'Listen to the situation and speak your response.',
    String? hint =
        'Use a polite opener like "Excuse me" and clarify the milk preference.',
    int difficulty = 2,
  }) {
    return SpeakingQuest(
      id: id,
      type: QuestType.speaking,
      subtype: GameSubtype.situationSpeaking,
      situationText: situationText,
      correctAnswer: correctAnswer,
      textToSpeak: textToSpeak,
      acceptedSynonyms: acceptedSynonyms,
      instruction: instruction,
      hint: hint,
      difficulty: difficulty,
    );
  }

  final sampleQuest1 = createQuest();
  final sampleQuest2 = createQuest(
    id: 'quest_situation_2',
    situationText:
        'Your flight has been delayed by three hours and you will miss your connecting flight. Ask the gate agent for rebooking options.',
    correctAnswer:
        'Hello, my flight was delayed and I will miss my connection. Can you assist me with rebooking?',
    textToSpeak:
        'Hello, my flight was delayed and I will miss my connection. Can you assist me with rebooking?',
    acceptedSynonyms: [
      'flight delayed',
      'miss connection',
      'rebooking',
      'agent',
    ],
    hint: 'State the delay problem clearly and inquire about alternate flights.',
  );

  final testLoadedState = SpeakingLoaded(
    quests: [sampleQuest1, sampleQuest2],
    currentIndex: 0,
    livesRemaining: 3,
    wrongCount: 0,
    hintUsed: false,
    answerStatus: AnswerStatus.unanswered,
    gameType: GameSubtype.situationSpeaking,
    level: 2,
  );

  setUpAll(() {
    registerFallbackValue(const SubmitAnswer(true));
    registerFallbackValue(const NextQuestion());
    registerFallbackValue(const SpeakingHintUsed());
    registerFallbackValue(
      const FetchSpeakingQuests(
        gameType: GameSubtype.situationSpeaking,
        level: 2,
      ),
    );
    registerFallbackValue(const Duration(milliseconds: 50));
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'has_seen_briefing_situationSpeaking': true,
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
          id: 'test_user_situation',
          email: 'situation@vowl.app',
          displayName: 'Situation Pilot',
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
        .thenAnswer((_) async => 'mock_situation_rec.m4a');
    when(() => mockAudioRecorder.dispose()).thenAnswer((_) async {});

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
    await di.sl.reset();
    await speakingStreamController.close();
    VowlMotion.lowAnimationModeOverride.value = false;
  });

  Future<void> pumpSituationSpeakingScreen(
    WidgetTester tester, {
    SpeakingState? state,
    int level = 2,
    GameSubtype gameType = GameSubtype.situationSpeaking,
    ThemeMode themeMode = ThemeMode.dark,
    Size size = const Size(390, 844),
    double textScaleFactor = 1.0,
    bool reduceMotion = true,
  }) async {
    VowlMotion.lowAnimationModeOverride.value = reduceMotion;
    tester.view.physicalSize = Size(size.width * 2, size.height * 2);
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
              child: SituationSpeakingScreen(
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

  group('Group 1: Initial Layout & Speaking States', () {
    testWidgets('renders GameShimmerLoading on SpeakingInitial state', (
      tester,
    ) async {
      await pumpSituationSpeakingScreen(
        tester,
        state: const SpeakingInitial(),
      );

      expect(find.byType(GameShimmerLoading), findsOneWidget);
      expect(find.byType(SituationSpeakingHeader), findsNothing);
      expect(find.byType(SituationSpeakingBriefingCard), findsNothing);
    });

    testWidgets('renders GameShimmerLoading on SpeakingLoading state', (
      tester,
    ) async {
      await pumpSituationSpeakingScreen(
        tester,
        state: const SpeakingLoading(),
      );

      expect(find.byType(GameShimmerLoading), findsOneWidget);
      expect(find.byType(SituationSpeakingHeader), findsNothing);
      expect(find.byType(SituationSpeakingBriefingCard), findsNothing);
    });

    testWidgets(
      'renders SituationSpeakingHeader and BriefingCard on SpeakingLoaded',
      (tester) async {
        await pumpSituationSpeakingScreen(tester);

        expect(find.byType(GameShimmerLoading), findsNothing);
        expect(find.byType(SituationSpeakingHeader), findsOneWidget);
        expect(find.byType(SituationSpeakingBriefingCard), findsOneWidget);
        expect(find.byKey(const Key('situation_speaking_header')), findsOneWidget);
        expect(
          find.byKey(const Key('situation_speaking_briefing_card')),
          findsOneWidget,
        );
      },
    );

    testWidgets('propagates level and gameType correctly to the screen', (
      tester,
    ) async {
      await pumpSituationSpeakingScreen(
        tester,
        level: 3,
        gameType: GameSubtype.situationSpeaking,
      );

      expect(find.byType(SituationSpeakingScreen), findsOneWidget);
      final screen = tester.widget<SituationSpeakingScreen>(
        find.byType(SituationSpeakingScreen),
      );
      expect(screen.level, 3);
      expect(screen.gameType, GameSubtype.situationSpeaking);
    });

    testWidgets('displays custom quest instruction text', (tester) async {
      final customQuest = createQuest(
        instruction: 'State your complaint clearly and politely.',
      );
      final state = testLoadedState.copyWith(quests: [customQuest]);

      await pumpSituationSpeakingScreen(tester, state: state);

      expect(
        find.text('STATE YOUR COMPLAINT CLEARLY AND POLITELY.'),
        findsOneWidget,
      );
    });

    testWidgets('handles SpeakingGameOver state cleanly without crash', (
      tester,
    ) async {
      await pumpSituationSpeakingScreen(tester);

      speakingStreamController.add(
        SpeakingGameOver(
          quests: [sampleQuest1, sampleQuest2],
          currentIndex: 0,
          gameType: GameSubtype.situationSpeaking,
          level: 2,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(SituationSpeakingScreen), findsOneWidget);
    });

    testWidgets(
      'handles SpeakingGameComplete state triggering celebration dialog',
      (tester) async {
        await pumpSituationSpeakingScreen(tester);

        speakingStreamController.add(
          const SpeakingGameComplete(
            xpEarned: 25,
            coinsEarned: 10,
            questCount: 2,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('LEVEL COMPLETE!'), findsOneWidget);
      },
    );
  });

  group('Group 2: Level 1 Briefing Layer', () {
    testWidgets('mounts GameBriefingLayer on Level 1', (tester) async {
      SharedPreferences.setMockInitialValues({});

      await pumpSituationSpeakingScreen(tester, level: 1);

      expect(find.byType(QuestBriefingOverlay), findsOneWidget);
      expect(find.text('SITUATION SPEAKING'), findsOneWidget);
      expect(find.text('START SITUATION'), findsOneWidget);
    });

    testWidgets(
      'displays scenario rules in QuestBriefingOverlay on Level 1',
      (tester) async {
        SharedPreferences.setMockInitialValues({});

        await pumpSituationSpeakingScreen(tester, level: 1);

        expect(find.text('Listen to the scenario context'), findsOneWidget);
        expect(find.text('Think about what you would say'), findsOneWidget);
        expect(find.text('Hold the mic and speak naturally'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping "Start Situation" button dismisses briefing overlay',
      (tester) async {
        SharedPreferences.setMockInitialValues({});

        await pumpSituationSpeakingScreen(tester, level: 1);

        expect(find.byType(QuestBriefingOverlay), findsOneWidget);

        final startBtn = find.text('START SITUATION');
        expect(startBtn, findsOneWidget);
        await tester.ensureVisible(startBtn);
        await tester.tap(startBtn);

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(QuestBriefingOverlay), findsNothing);
        expect(find.byType(SituationSpeakingBriefingCard), findsOneWidget);
      },
    );

    testWidgets('bypasses briefing overlay on Level 2 or higher', (
      tester,
    ) async {
      await pumpSituationSpeakingScreen(tester, level: 2);

      expect(find.byType(QuestBriefingOverlay), findsNothing);
      expect(find.byType(SituationSpeakingBriefingCard), findsOneWidget);
    });
  });

  group('Group 3: SituationSpeakingHeader Component', () {
    testWidgets('renders header with icon, uppercase text, and Semantics', (
      tester,
    ) async {
      await pumpSituationSpeakingScreen(tester);

      final headerFinder = find.byKey(const Key('situation_speaking_header'));
      expect(headerFinder, findsOneWidget);

      final iconFinder = find.byIcon(Icons.record_voice_over_rounded);
      expect(iconFinder, findsOneWidget);

      final textFinder = find.byKey(
        const Key('situation_speaking_header_text'),
      );
      expect(textFinder, findsOneWidget);

      final textWidget = tester.widget<Text>(textFinder);
      expect(textWidget.data, 'LISTEN TO THE SITUATION AND SPEAK YOUR RESPONSE.');
      expect(textWidget.maxLines, 2);
      expect(textWidget.overflow, TextOverflow.ellipsis);
    });

    testWidgets('has Semantics header set to true', (tester) async {
      await pumpSituationSpeakingScreen(tester);

      final headerSemantics = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.header == true,
      );
      expect(headerSemantics, findsOneWidget);
    });

    testWidgets(
      'displays fallback instruction when quest instruction is empty',
      (tester) async {
        final questNoInstruction = createQuest(instruction: '');
        final state = testLoadedState.copyWith(quests: [questNoInstruction]);

        await pumpSituationSpeakingScreen(tester, state: state);

        expect(
          find.byKey(const Key('situation_speaking_header_text')),
          findsOneWidget,
        );
      },
    );

    testWidgets('handles extremely long instruction without RenderFlex overflow', (
      tester,
    ) async {
      final longInstructionQuest = createQuest(
        instruction:
            'This is an exceptionally detailed and long instruction designed to test the layout bounds and ellipsis formatting of the SituationSpeakingHeader under constrained viewport conditions.',
      );
      final state = testLoadedState.copyWith(quests: [longInstructionQuest]);

      await pumpSituationSpeakingScreen(tester, state: state);

      expect(tester.takeException(), isNull);
      expect(
        find.byKey(const Key('situation_speaking_header_text')),
        findsOneWidget,
      );
    });
  });

  group('Group 4: SituationSpeakingBriefingCard & Typewriter Mechanics', () {
    testWidgets('renders briefing card with container, title and icon', (
      tester,
    ) async {
      await pumpSituationSpeakingScreen(tester);

      expect(
        find.byKey(const Key('situation_speaking_briefing_card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('situation_speaking_briefing_title')),
        findsOneWidget,
      );
      expect(find.text('SCENARIO BRIEFING'), findsOneWidget);
      expect(find.byIcon(Icons.assignment_late_rounded), findsOneWidget);
    });

    testWidgets('displays situation text inside briefing card body', (
      tester,
    ) async {
      await pumpSituationSpeakingScreen(tester);

      final bodyFinder = find.byKey(
        const Key('situation_speaking_body_text'),
      );
      expect(bodyFinder, findsOneWidget);
      final textWidget = tester.widget<Text>(bodyFinder);
      expect(
        textWidget.data,
        contains('You are at a busy coffee shop and the barista accidentally'),
      );
    });

    testWidgets(
      'in standard motion, typewriter runs and displays partial text initially',
      (tester) async {
        VowlMotion.lowAnimationModeOverride.value = false;

        await pumpSituationSpeakingScreen(
          tester,
          reduceMotion: false,
        );

        expect(
          find.byKey(const Key('situation_speaking_briefing_card')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('situation_speaking_typewriter_text')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'tapping briefing card immediately finishes typewriter and plays success haptic',
      (tester) async {
        VowlMotion.lowAnimationModeOverride.value = false;

        await pumpSituationSpeakingScreen(
          tester,
          reduceMotion: false,
        );

        final cardFinder = find.byKey(
          const Key('situation_speaking_briefing_card_gesture'),
        );
        expect(cardFinder, findsOneWidget);

        await tester.tap(cardFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));

        verify(() => mockHapticService.success()).called(1);
        expect(
          find.byKey(const Key('situation_speaking_confirm_overlay')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'in reduced motion mode, typewriter finishes immediately on mount',
      (tester) async {
        await pumpSituationSpeakingScreen(tester, reduceMotion: true);

        expect(
          find.byKey(const Key('situation_speaking_body_text')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('situation_speaking_confirm_overlay')),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'renders fallback situation description when situationText is null',
      (tester) async {
        final questNoSituation = SpeakingQuest(
          id: 'q_no_situation',
          instruction: 'Speak now',
          difficulty: 1,
          situationText: null,
          correctAnswer: 'Hello',
        );
        final state = testLoadedState.copyWith(quests: [questNoSituation]);

        await pumpSituationSpeakingScreen(tester, state: state);

        expect(find.text('Situation description.'), findsOneWidget);
      },
    );

    testWidgets(
      'handles empty situationText string safely without range exception',
      (tester) async {
        final questEmptySituation = createQuest(situationText: '');
        final state = testLoadedState.copyWith(quests: [questEmptySituation]);

        await pumpSituationSpeakingScreen(tester, state: state);

        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const Key('situation_speaking_body_text')),
          findsOneWidget,
        );
      },
    );
  });

  group('Group 5: Scenario Audio Playback & TTS Lockout', () {
    testWidgets(
      'TTS button is mounted once briefing completes with volume icon',
      (tester) async {
        await pumpSituationSpeakingScreen(tester);

        final ttsFinder = find.byKey(
          const Key('situation_speaking_tts_button'),
        );
        expect(ttsFinder, findsOneWidget);
        expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
      },
    );

    testWidgets('TTS button has accessible Semantics label', (tester) async {
      await pumpSituationSpeakingScreen(tester);

      final ttsSemantics = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.button == true &&
            widget.properties.label == 'Listen to scenario briefing audio',
      );
      expect(ttsSemantics, findsOneWidget);
    });

    testWidgets(
      'tapping TTS button triggers soundService.playTts with situationText',
      (tester) async {
        await pumpSituationSpeakingScreen(tester);

        final ttsFinder = find.byKey(
          const Key('situation_speaking_tts_button'),
        );
        expect(ttsFinder, findsOneWidget);

        final scaleBtn = tester.widget<ScaleButton>(ttsFinder);
        scaleBtn.onTap?.call();
        await tester.pump();

        verify(
          () => mockSoundService.playTts(
            'You are at a busy coffee shop and the barista accidentally gives you whole milk instead of oat milk. Politely ask for a replacement.',
          ),
        ).called(1);
      },
    );

    testWidgets(
      'tapping TTS button does NOT play audio when audio recorder is actively recording',
      (tester) async {
        when(() => mockAudioRecorder.isRecording).thenReturn(true);

        await pumpSituationSpeakingScreen(tester);

        final ttsFinder = find.byKey(
          const Key('situation_speaking_tts_button'),
        );
        expect(ttsFinder, findsOneWidget);

        final scaleBtn = tester.widget<ScaleButton>(ttsFinder);
        scaleBtn.onTap?.call();
        await tester.pump();

        verifyNever(() => mockSoundService.playTts(any()));
      },
    );

    testWidgets('TTS button remains visible and accessible in answered state', (
      tester,
    ) async {
      final answeredState = testLoadedState.copyWith(
        answerStatus: AnswerStatus.correct,
      );

      await pumpSituationSpeakingScreen(tester, state: answeredState);

      expect(
        find.byKey(const Key('situation_speaking_tts_button')),
        findsOneWidget,
      );
    });
  });

  group('Group 6: Grammar Guide & Hint System', () {
    testWidgets('hint container is hidden when hintUsed is false', (
      tester,
    ) async {
      await pumpSituationSpeakingScreen(tester);

      expect(
        find.byKey(const Key('situation_speaking_hint_container')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('situation_speaking_hint_text')),
        findsNothing,
      );
    });

    testWidgets(
      'hint container mounts and displays hint text when hintUsed is true',
      (tester) async {
        final hintState = testLoadedState.copyWith(hintUsed: true);

        await pumpSituationSpeakingScreen(tester, state: hintState);

        final hintContainerFinder = find.byKey(
          const Key('situation_speaking_hint_container'),
        );
        expect(hintContainerFinder, findsOneWidget);

        final hintTextFinder = find.byKey(
          const Key('situation_speaking_hint_text'),
        );
        expect(hintTextFinder, findsOneWidget);

        expect(find.text('SPEAKING GUIDE'), findsOneWidget);
        expect(
          find.text(
            'Use a polite opener like "Excuse me" and clarify the milk preference.',
          ),
          findsOneWidget,
        );
        expect(find.byIcon(Icons.lightbulb_outline_rounded), findsOneWidget);
      },
    );

    testWidgets('hint container has container Semantics label with hint text', (
      tester,
    ) async {
      final hintState = testLoadedState.copyWith(hintUsed: true);

      await pumpSituationSpeakingScreen(tester, state: hintState);

      final hintSemantics = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.container == true &&
            (widget.properties.label?.contains('Speaking guide hint: Use a polite opener') ?? false),
      );
      expect(hintSemantics, findsOneWidget);
    });

    testWidgets(
      'tapping app bar QuestHintButton dispatches SpeakingHintUsed event',
      (tester) async {
        await pumpSituationSpeakingScreen(tester);

        final hintButtonFinder = find.byType(QuestHintButton);
        expect(hintButtonFinder, findsOneWidget);

        await tester.tap(hintButtonFinder);
        await tester.pump();

        verify(
          () => mockSpeakingBloc.add(const SpeakingHintUsed()),
        ).called(greaterThanOrEqualTo(1));
      },
    );

    testWidgets('handles quest with null hint cleanly without mounting hint container', (
      tester,
    ) async {
      final questNoHint = createQuest(hint: null);
      final hintState = testLoadedState.copyWith(
        quests: [questNoHint],
        hintUsed: true,
      );

      await pumpSituationSpeakingScreen(tester, state: hintState);

      expect(
        find.byKey(const Key('situation_speaking_hint_container')),
        findsNothing,
      );
    });
  });

  group('Group 7: SpeakToConfirmOverlay Integration', () {
    testWidgets(
      'overlay mounts once briefing is complete with title and subtitle',
      (tester) async {
        await pumpSituationSpeakingScreen(tester);

        final overlayFinder = find.byKey(
          const Key('situation_speaking_confirm_overlay'),
        );
        expect(overlayFinder, findsOneWidget);

        final overlayWidget = tester.widget<SpeakToConfirmOverlay>(
          overlayFinder,
        );
        expect(overlayWidget.title, 'SPEAK THE SITUATION');
        expect(overlayWidget.subtitle, 'Hold the microphone to answer');
        expect(overlayWidget.hideExpectedText, isTrue);
        expect(overlayWidget.allowSkip, isFalse);
      },
    );

    testWidgets('overlay receives expectedText matching quest correctAnswer', (
      tester,
    ) async {
      await pumpSituationSpeakingScreen(tester);

      final overlayWidget = tester.widget<SpeakToConfirmOverlay>(
        find.byKey(const Key('situation_speaking_confirm_overlay')),
      );
      expect(
        overlayWidget.expectedText,
        'Excuse me, I ordered oat milk instead of whole milk. Could you please remake this?',
      );
    });

    testWidgets('overlay receives acceptedSynonyms list', (tester) async {
      await pumpSituationSpeakingScreen(tester);

      final overlayWidget = tester.widget<SpeakToConfirmOverlay>(
        find.byKey(const Key('situation_speaking_confirm_overlay')),
      );
      expect(overlayWidget.acceptedSynonyms, contains('oat milk'));
      expect(overlayWidget.acceptedSynonyms, contains('excuse me'));
    });

    testWidgets(
      'overlay falls back to textToSpeak when correctAnswer is null',
      (tester) async {
        final questNoCorrect = SpeakingQuest(
          id: 'q_no_correct',
          instruction: 'Speak',
          difficulty: 1,
          correctAnswer: null,
          textToSpeak: 'Text to speak fallback',
          situationText: 'Situation',
        );
        final state = testLoadedState.copyWith(quests: [questNoCorrect]);

        await pumpSituationSpeakingScreen(tester, state: state);

        final overlayWidget = tester.widget<SpeakToConfirmOverlay>(
          find.byKey(const Key('situation_speaking_confirm_overlay')),
        );
        expect(overlayWidget.expectedText, 'Text to speak fallback');
      },
    );

    testWidgets(
      'overlay falls back to empty string when both correctAnswer and textToSpeak are null',
      (tester) async {
        final questNulls = SpeakingQuest(
          id: 'q_nulls',
          instruction: 'Speak',
          difficulty: 1,
          correctAnswer: null,
          textToSpeak: null,
          situationText: 'Situation',
        );
        final state = testLoadedState.copyWith(quests: [questNulls]);

        await pumpSituationSpeakingScreen(tester, state: state);

        final overlayWidget = tester.widget<SpeakToConfirmOverlay>(
          find.byKey(const Key('situation_speaking_confirm_overlay')),
        );
        expect(overlayWidget.expectedText, '');
      },
    );
  });

  group('Group 8: Verbal Evaluation & Scoring Mechanics', () {
    testWidgets(
      'tapping "Nailed It" (onConfirmed) dispatches SubmitAnswer(true) with success sound & haptics',
      (tester) async {
        await pumpSituationSpeakingScreen(tester);

        final overlayWidget = tester.widget<SpeakToConfirmOverlay>(
          find.byKey(const Key('situation_speaking_confirm_overlay')),
        );

        clearInteractions(mockHapticService);
        clearInteractions(mockSoundService);
        clearInteractions(mockSpeakingBloc);

        overlayWidget.onConfirmed();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));

        verify(() => mockHapticService.success()).called(1);
        verify(() => mockSoundService.playCorrect()).called(1);
        verify(() => mockSpeakingBloc.add(const SubmitAnswer(true))).called(1);
      },
    );

    testWidgets(
      'tapping "Needs Work" (onSkipped) dispatches SubmitAnswer(false) with error sound & haptics',
      (tester) async {
        await pumpSituationSpeakingScreen(tester);

        final overlayWidget = tester.widget<SpeakToConfirmOverlay>(
          find.byKey(const Key('situation_speaking_confirm_overlay')),
        );

        clearInteractions(mockHapticService);
        clearInteractions(mockSoundService);
        clearInteractions(mockSpeakingBloc);

        overlayWidget.onSkipped();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));

        verify(() => mockHapticService.error()).called(1);
        verify(() => mockSoundService.playWrong()).called(1);
        verify(() => mockSpeakingBloc.add(const SubmitAnswer(false))).called(1);
      },
    );

    testWidgets(
      'duplicate tap lockout prevents secondary evaluations once answered',
      (tester) async {
        await pumpSituationSpeakingScreen(tester);

        final overlayWidget = tester.widget<SpeakToConfirmOverlay>(
          find.byKey(const Key('situation_speaking_confirm_overlay')),
        );

        overlayWidget.onConfirmed();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        overlayWidget.onConfirmed();
        overlayWidget.onSkipped();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        verify(() => mockSpeakingBloc.add(const SubmitAnswer(true))).called(1);
        verifyNever(() => mockSpeakingBloc.add(const SubmitAnswer(false)));
      },
    );
  });

  group('Group 9: Answered State & Question Progression', () {
    testWidgets('overlay unmounts once answered', (tester) async {
      await pumpSituationSpeakingScreen(tester);

      expect(
        find.byKey(const Key('situation_speaking_confirm_overlay')),
        findsOneWidget,
      );

      final overlayWidget = tester.widget<SpeakToConfirmOverlay>(
        find.byKey(const Key('situation_speaking_confirm_overlay')),
      );
      overlayWidget.onConfirmed();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.byKey(const Key('situation_speaking_confirm_overlay')),
        findsNothing,
      );
    });

    testWidgets(
      'GameFeedbackCard mounts in answered state with CONTINUE button',
      (tester) async {
        final answeredState = testLoadedState.copyWith(
          answerStatus: AnswerStatus.correct,
        );

        await pumpSituationSpeakingScreen(tester, state: answeredState);

        expect(find.byType(GameFeedbackCard), findsOneWidget);
        expect(find.text('CONTINUE'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping CONTINUE button in GameFeedbackCard dispatches NextQuestion event',
      (tester) async {
        final answeredState = testLoadedState.copyWith(
          answerStatus: AnswerStatus.correct,
        );

        await pumpSituationSpeakingScreen(tester, state: answeredState);

        final continueBtn = find.text('CONTINUE');
        expect(continueBtn, findsOneWidget);

        await tester.tap(continueBtn);
        await tester.pump();

        verify(() => mockSpeakingBloc.add(const NextQuestion())).called(1);
      },
    );

    testWidgets(
      'advancing to question 2 updates situationText, hint and expectedText',
      (tester) async {
        await pumpSituationSpeakingScreen(tester);

        expect(
          find.textContaining('You are at a busy coffee shop'),
          findsOneWidget,
        );

        final question2State = testLoadedState.copyWith(
          currentIndex: 1,
          hintUsed: false,
          answerStatus: AnswerStatus.unanswered,
        );

        speakingStreamController.add(question2State);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          find.textContaining('Your flight has been delayed by three hours'),
          findsOneWidget,
        );

        final overlayWidget = tester.widget<SpeakToConfirmOverlay>(
          find.byKey(const Key('situation_speaking_confirm_overlay')),
        );
        expect(
          overlayWidget.expectedText,
          'Hello, my flight was delayed and I will miss my connection. Can you assist me with rebooking?',
        );
      },
    );
  });

  group('Group 10: Viewport Responsiveness, Theme & Motion Modes', () {
    testWidgets(
      'renders cleanly without RenderFlex overflow on compact mobile (320x568)',
      (tester) async {
        await pumpSituationSpeakingScreen(
          tester,
          size: const Size(320, 568),
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(SituationSpeakingHeader), findsOneWidget);
        expect(find.byType(SituationSpeakingBriefingCard), findsOneWidget);
      },
    );

    testWidgets(
      'renders cleanly without RenderFlex overflow on tablet viewport (768x1024)',
      (tester) async {
        await pumpSituationSpeakingScreen(
          tester,
          size: const Size(768, 1024),
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(SituationSpeakingHeader), findsOneWidget);
        expect(find.byType(SituationSpeakingBriefingCard), findsOneWidget);
      },
    );

    testWidgets('renders cleanly under Light Theme', (tester) async {
      await pumpSituationSpeakingScreen(
        tester,
        themeMode: ThemeMode.light,
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(SituationSpeakingBriefingCard), findsOneWidget);
    });

    testWidgets('renders cleanly under Dark Theme', (tester) async {
      await pumpSituationSpeakingScreen(
        tester,
        themeMode: ThemeMode.dark,
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(SituationSpeakingBriefingCard), findsOneWidget);
    });

    testWidgets(
      'clamps extreme text scale (1.3x) safely to 1.1x without overflow',
      (tester) async {
        await pumpSituationSpeakingScreen(
          tester,
          textScaleFactor: 1.3,
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(SituationSpeakingHeader), findsOneWidget);
        expect(find.byType(SituationSpeakingBriefingCard), findsOneWidget);
      },
    );

    testWidgets(
      'RawScrollbar and CustomScrollView allow vertical scrolling when expanded',
      (tester) async {
        await pumpSituationSpeakingScreen(tester);

        expect(find.byType(CustomScrollView), findsOneWidget);
        expect(find.byType(RawScrollbar), findsOneWidget);

        await tester.drag(find.byType(CustomScrollView), const Offset(0, -100));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 150));

        expect(tester.takeException(), isNull);
      },
    );
  });
}
