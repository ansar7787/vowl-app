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
import 'package:vowl/features/speaking/speak_opposite/presentation/pages/speak_opposite_screen.dart';
import 'package:vowl/features/speaking/speak_opposite/presentation/widgets/speak_opposite_parser.dart';
import 'package:vowl/features/speaking/speak_opposite/presentation/widgets/speak_opposite_positive_pole_panel.dart';

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
    String id = 'quest_opposite_1',
    String textToSpeak = 'The soup on the stove is too *hot* to eat right now.',
    String? correctAnswer = 'cold',
    List<String>? acceptedSynonyms = const ['cold', 'freezing', 'chilly'],
    String instruction = 'Speak the opposite of the highlighted word.',
    String? hint = 'Think of low temperature.',
    int difficulty = 2,
  }) {
    return SpeakingQuest(
      id: id,
      type: QuestType.speaking,
      subtype: GameSubtype.speakOpposite,
      textToSpeak: textToSpeak,
      correctAnswer: correctAnswer,
      acceptedSynonyms: acceptedSynonyms,
      instruction: instruction,
      hint: hint,
      difficulty: difficulty,
    );
  }

  final sampleQuest1 = createQuest();
  final sampleQuest2 = createQuest(
    id: 'quest_opposite_2',
    textToSpeak: 'The room was completely *dark* before turning on the lamp.',
    correctAnswer: 'bright',
    acceptedSynonyms: ['bright', 'light', 'illuminated'],
    instruction: 'Speak the opposite of dark.',
    hint: 'Full of light.',
  );

  final testLoadedState = SpeakingLoaded(
    quests: [sampleQuest1, sampleQuest2],
    currentIndex: 0,
    livesRemaining: 3,
    wrongCount: 0,
    hintUsed: false,
    answerStatus: AnswerStatus.unanswered,
    gameType: GameSubtype.speakOpposite,
    level: 2,
  );

  setUpAll(() {
    registerFallbackValue(const SubmitAnswer(true));
    registerFallbackValue(const NextQuestion());
    registerFallbackValue(const SpeakingHintUsed());
    registerFallbackValue(
      const FetchSpeakingQuests(
        gameType: GameSubtype.speakOpposite,
        level: 2,
      ),
    );
    registerFallbackValue(const Duration(milliseconds: 50));
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'has_seen_briefing_speakOpposite': true,
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
          id: 'test_user_opposite',
          email: 'opposite@vowl.app',
          displayName: 'Antonym Pilot',
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
        .thenAnswer((_) async => 'mock_opposite_rec.m4a');
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
    GameSubtype gameType = GameSubtype.speakOpposite,
    Size size = const Size(390, 844),
    double textScaleFactor = 1.0,
    ThemeMode themeMode = ThemeMode.dark,
    bool reduceMotion = false,
  }) async {
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
              child: SpeakOppositeScreen(
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

    testWidgets('1.2 renders SpeakOppositePositivePolePanel', (tester) async {
      await pumpScreen(tester);
      expect(find.byType(SpeakOppositePositivePolePanel), findsOneWidget);
    });

    testWidgets('1.3 renders key speak_opposite_positive_pole_panel', (tester) async {
      await pumpScreen(tester);
      expect(find.byKey(const Key('speak_opposite_positive_pole_panel')), findsOneWidget);
    });

    testWidgets('1.4 renders GIVEN WORD label with key speak_opposite_given_word_label', (tester) async {
      await pumpScreen(tester);
      expect(find.byKey(const Key('speak_opposite_given_word_label')), findsOneWidget);
      expect(find.text('GIVEN WORD'), findsOneWidget);
    });

    testWidgets('1.5 renders target word container with key speak_opposite_target_word_container', (tester) async {
      await pumpScreen(tester);
      expect(find.byKey(const Key('speak_opposite_target_word_container')), findsOneWidget);
    });

    testWidgets('1.6 renders target word text with key speak_opposite_target_word_text', (tester) async {
      await pumpScreen(tester);
      expect(find.byKey(const Key('speak_opposite_target_word_text')), findsOneWidget);
      expect(find.text('hot'), findsOneWidget);
    });

    testWidgets('1.7 renders listen button with key speak_opposite_listen_button', (tester) async {
      await pumpScreen(tester);
      expect(find.byKey(const Key('speak_opposite_listen_button')), findsOneWidget);
    });

    testWidgets('1.8 renders RawScrollbar and CustomScrollView with custom keys', (tester) async {
      await pumpScreen(tester);
      expect(find.byKey(const Key('speak_opposite_scrollbar')), findsOneWidget);
      expect(find.byKey(const Key('speak_opposite_scroll_view')), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // 2. Parser Logic & Data Binding (8 tests)
  // ---------------------------------------------------------------------------
  group('2. Parser Logic & Data Binding', () {
    testWidgets('2.1 parses asterisks word into targetWord hot', (tester) async {
      final parsed = SpeakOppositeParser.parseQuestTexts(
        textToSpeak: 'The soup is *hot*.',
        fallbackInstruction: 'Opposite of hot',
      );
      expect(parsed.targetWord, 'hot');
    });

    testWidgets('2.2 strips asterisks from textToSpeak into clean contextText', (tester) async {
      final parsed = SpeakOppositeParser.parseQuestTexts(
        textToSpeak: 'The soup is *hot*.',
        fallbackInstruction: 'Opposite of hot',
      );
      expect(parsed.contextText, 'The soup is hot.');
    });

    testWidgets('2.3 handles empty textToSpeak by falling back to fallbackInstruction', (tester) async {
      final parsed = SpeakOppositeParser.parseQuestTexts(
        textToSpeak: '',
        fallbackInstruction: 'big',
      );
      expect(parsed.targetWord, 'big');
      expect(parsed.contextText, '');
    });

    testWidgets('2.4 handles textToSpeak without asterisks by using entire string', (tester) async {
      final parsed = SpeakOppositeParser.parseQuestTexts(
        textToSpeak: 'ancient',
        fallbackInstruction: 'ancient',
      );
      expect(parsed.targetWord, 'ancient');
      expect(parsed.contextText, '');
    });

    testWidgets('2.5 renders targetWord parsed from quest', (tester) async {
      await pumpScreen(tester);
      expect(find.text('hot'), findsOneWidget);
    });

    testWidgets('2.6 renders contextText in italic style below targetWord', (tester) async {
      await pumpScreen(tester);
      expect(find.byKey(const Key('speak_opposite_context_text')), findsOneWidget);
      expect(find.text('The soup on the stove is too hot to eat right now.'), findsOneWidget);
    });

    testWidgets('2.7 does not render contextText widget when contextText is empty', (tester) async {
      final questNoContext = createQuest(
        textToSpeak: 'huge',
        correctAnswer: 'tiny',
      );
      final stateNoContext = SpeakingLoaded(
        quests: [questNoContext],
        currentIndex: 0,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.unanswered,
        gameType: GameSubtype.speakOpposite,
        level: 2,
      );
      await pumpScreen(tester, state: stateNoContext);
      expect(find.byKey(const Key('speak_opposite_context_text')), findsNothing);
      expect(find.text('huge'), findsOneWidget);
    });

    testWidgets('2.8 renders GameShimmerLoading when quest is null', (tester) async {
      await pumpScreen(tester, state: const SpeakingInitial());
      expect(find.byType(GameShimmerLoading), findsOneWidget);
      expect(find.byType(SpeakOppositePositivePolePanel), findsNothing);
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

    testWidgets('3.2 displays briefing title ANTONYM ORATOR', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpScreen(tester, level: 1);
      expect(find.text('ANTONYM ORATOR'), findsOneWidget);
    });

    testWidgets('3.3 displays action button with text SPEAK OPPOSITE', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpScreen(tester, level: 1);
      expect(find.text('SPEAK OPPOSITE'), findsOneWidget);
    });

    testWidgets('3.4 tapping action button dismisses overlay', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpScreen(tester, level: 1);
      expect(find.byType(QuestBriefingOverlay), findsOneWidget);

      await tester.ensureVisible(find.text('SPEAK OPPOSITE'));
      await tester.tap(find.text('SPEAK OPPOSITE'));
      await tester.pumpAndSettle();

      expect(find.byType(QuestBriefingOverlay), findsNothing);
    });

    testWidgets('3.5 does not display briefing overlay on level 2', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpScreen(tester, level: 2);
      expect(find.byType(QuestBriefingOverlay), findsNothing);
    });

    testWidgets('3.6 has_seen_briefing flag prevents overlay display on level 1', (tester) async {
      SharedPreferences.setMockInitialValues({
        'has_seen_briefing_speakOpposite': true,
      });
      await pumpScreen(tester, level: 1);
      expect(find.byType(QuestBriefingOverlay), findsNothing);
    });
  });

  // ---------------------------------------------------------------------------
  // 4. TTS Audio Playback & Microphone Controls (8 tests)
  // ---------------------------------------------------------------------------
  group('4. TTS Audio Playback & Microphone Controls', () {
    testWidgets('4.1 tapping listen button calls soundService.playTts(targetWord)', (tester) async {
      await pumpScreen(tester);
      clearInteractions(mockSoundService);

      await tester.tap(find.byKey(const Key('speak_opposite_listen_button')));
      await tester.pump();

      verify(() => mockSoundService.playTts('hot')).called(1);
    });

    testWidgets('4.2 tapping listen button does NOT play TTS if audioRecorder.isRecording is true', (tester) async {
      when(() => mockAudioRecorder.isRecording).thenReturn(true);
      await pumpScreen(tester);
      clearInteractions(mockSoundService);

      await tester.tap(find.byKey(const Key('speak_opposite_listen_button')));
      await tester.pump();

      verifyNever(() => mockSoundService.playTts(any()));
    });

    testWidgets('4.3 listen button has volume_up_rounded icon', (tester) async {
      await pumpScreen(tester);
      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
    });

    testWidgets('4.4 listen button has accessible Semantics label', (tester) async {
      await pumpScreen(tester);
      final semantics = find.ancestor(
        of: find.byKey(const Key('speak_opposite_listen_button')),
        matching: find.byType(Semantics),
      );
      expect(semantics, findsWidgets);
    });

    testWidgets('4.5 target word has accessible Semantics label', (tester) async {
      await pumpScreen(tester);
      expect(
        find.bySemanticsLabel('Target word to find opposite: hot'),
        findsOneWidget,
      );
    });

    testWidgets('4.6 mic hint row renders with key speak_opposite_mic_hint', (tester) async {
      await pumpScreen(tester);
      expect(find.byKey(const Key('speak_opposite_mic_hint')), findsOneWidget);
      expect(find.text('Hold mic to say the opposite'), findsOneWidget);
    });

    testWidgets('4.7 mic hint contains mic_rounded icon', (tester) async {
      await pumpScreen(tester);
      expect(find.byIcon(Icons.mic_rounded), findsWidgets);
    });

    testWidgets('4.8 school_rounded icon renders beside GIVEN WORD label', (tester) async {
      await pumpScreen(tester);
      expect(find.byIcon(Icons.school_rounded), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // 5. AutoPlay Mechanics & TTS Barrier (_ttsFinished) (8 tests)
  // ---------------------------------------------------------------------------
  group('5. AutoPlay Mechanics & TTS Barrier (_ttsFinished)', () {
    testWidgets('5.1 autoPlay triggers soundService.playTts on quest mount', (tester) async {
      clearInteractions(mockSoundService);
      await pumpScreen(tester);
      verify(() => mockSoundService.playTts('hot')).called(1);
    });

    testWidgets('5.2 under lowAnimationModeOverride, _ttsFinished is immediately true', (tester) async {
      VowlMotion.lowAnimationModeOverride.value = true;
      await pumpScreen(tester);

      final absorbPointer = tester.widget<AbsorbPointer>(
        find.descendant(
          of: find.byType(CustomScrollView),
          matching: find.byType(AbsorbPointer),
        ),
      );
      expect(absorbPointer.absorbing, isFalse);
    });

    testWidgets('5.3 under lowAnimationModeOverride, opacity is 1.0', (tester) async {
      VowlMotion.lowAnimationModeOverride.value = true;
      await pumpScreen(tester);

      final animatedOpacity = tester.widget<AnimatedOpacity>(
        find.descendant(
          of: find.byType(CustomScrollView),
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(animatedOpacity.opacity, 1.0);
    });

    testWidgets('5.4 without lowAnimationModeOverride, autoPlayTimer sets _ttsFinished after timer', (tester) async {
      VowlMotion.lowAnimationModeOverride.value = false;
      await pumpScreen(tester);
      await tester.pump(const Duration(seconds: 3));

      final absorbPointer = tester.widget<AbsorbPointer>(
        find.descendant(
          of: find.byType(CustomScrollView),
          matching: find.byType(AbsorbPointer),
        ),
      );
      expect(absorbPointer.absorbing, isFalse);
    });

    testWidgets('5.5 reduced motion via disableAnimations sets _ttsFinished to true', (tester) async {
      VowlMotion.lowAnimationModeOverride.value = false;
      await pumpScreen(tester, reduceMotion: true);

      final absorbPointer = tester.widget<AbsorbPointer>(
        find.descendant(
          of: find.byType(CustomScrollView),
          matching: find.byType(AbsorbPointer),
        ),
      );
      expect(absorbPointer.absorbing, isFalse);
    });

    testWidgets('5.6 empty quest targetWord sets _ttsFinished to true immediately', (tester) async {
      final emptyQuest = createQuest(textToSpeak: '', instruction: '');
      final emptyState = SpeakingLoaded(
        quests: [emptyQuest],
        currentIndex: 0,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.unanswered,
        gameType: GameSubtype.speakOpposite,
        level: 2,
      );
      await pumpScreen(tester, state: emptyState);

      final absorbPointer = tester.widget<AbsorbPointer>(
        find.descendant(
          of: find.byType(CustomScrollView),
          matching: find.byType(AbsorbPointer),
        ),
      );
      expect(absorbPointer.absorbing, isFalse);
    });

    testWidgets('5.7 multiple audio triggers safely cancel prior timers', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('speak_opposite_listen_button')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('speak_opposite_listen_button')));
      await tester.pump();

      verify(() => mockSoundService.playTts('hot')).called(greaterThanOrEqualTo(2));
    });

    testWidgets('5.8 autoPlay does not trigger if answerStatus is answered', (tester) async {
      clearInteractions(mockSoundService);
      final answeredState = SpeakingLoaded(
        quests: [sampleQuest1],
        currentIndex: 0,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.correct,
        gameType: GameSubtype.speakOpposite,
        level: 2,
      );
      await pumpScreen(tester, state: answeredState);
      verifyNever(() => mockSoundService.playTts(any()));
    });
  });

  // ---------------------------------------------------------------------------
  // 6. SpeakToConfirmOverlay Configuration & Properties (8 tests)
  // ---------------------------------------------------------------------------
  group('6. SpeakToConfirmOverlay Configuration & Properties', () {
    testWidgets('6.1 renders SpeakToConfirmOverlay with key speak_opposite_speak_to_confirm_overlay', (tester) async {
      await pumpScreen(tester);
      expect(
        find.byKey(const Key('speak_opposite_speak_to_confirm_overlay')),
        findsOneWidget,
      );
    });

    testWidgets('6.2 sets hideExpectedText to true so answer is not revealed', (tester) async {
      await pumpScreen(tester);
      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byKey(const Key('speak_opposite_speak_to_confirm_overlay')),
      );
      expect(overlay.hideExpectedText, isTrue);
    });

    testWidgets('6.3 sets allowSkip to false', (tester) async {
      await pumpScreen(tester);
      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byKey(const Key('speak_opposite_speak_to_confirm_overlay')),
      );
      expect(overlay.allowSkip, isFalse);
    });

    testWidgets('6.4 sets title to SAY THE OPPOSITE', (tester) async {
      await pumpScreen(tester);
      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byKey(const Key('speak_opposite_speak_to_confirm_overlay')),
      );
      expect(overlay.title, 'SAY THE OPPOSITE');
      expect(find.text('SAY THE OPPOSITE'), findsOneWidget);
    });

    testWidgets('6.5 sets subtitle to Hold the mic and speak aloud', (tester) async {
      await pumpScreen(tester);
      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byKey(const Key('speak_opposite_speak_to_confirm_overlay')),
      );
      expect(overlay.subtitle, 'Hold the mic and speak aloud');
      expect(find.text('Hold the mic and speak aloud'), findsOneWidget);
    });

    testWidgets('6.6 passes acceptedAntonyms into acceptedSynonyms of overlay', (tester) async {
      await pumpScreen(tester);
      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byKey(const Key('speak_opposite_speak_to_confirm_overlay')),
      );
      expect(overlay.acceptedSynonyms, ['cold', 'freezing', 'chilly']);
      expect(overlay.expectedText, 'cold');
    });

    testWidgets('6.7 falls back to cleaned correctAnswer when acceptedSynonyms is empty', (tester) async {
      final questNoSynonyms = createQuest(
        acceptedSynonyms: [],
        correctAnswer: 'cold!',
      );
      final stateNoSynonyms = SpeakingLoaded(
        quests: [questNoSynonyms],
        currentIndex: 0,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.unanswered,
        gameType: GameSubtype.speakOpposite,
        level: 2,
      );
      await pumpScreen(tester, state: stateNoSynonyms);
      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byKey(const Key('speak_opposite_speak_to_confirm_overlay')),
      );
      expect(overlay.acceptedSynonyms, ['cold']);
      expect(overlay.expectedText, 'cold');
    });

    testWidgets('6.8 unmounts SpeakToConfirmOverlay when question is answered', (tester) async {
      await pumpScreen(tester);
      expect(find.byKey(const Key('speak_opposite_speak_to_confirm_overlay')), findsOneWidget);

      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byKey(const Key('speak_opposite_speak_to_confirm_overlay')),
      );
      overlay.onConfirmed();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('speak_opposite_speak_to_confirm_overlay')), findsNothing);
    });
  });

  // ---------------------------------------------------------------------------
  // 7. Verbal Evaluation Submission - Success Path (7 tests)
  // ---------------------------------------------------------------------------
  group('7. Verbal Evaluation Submission - Success Path', () {
    testWidgets('7.1 onConfirmed triggers hapticService.success()', (tester) async {
      await pumpScreen(tester);
      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byKey(const Key('speak_opposite_speak_to_confirm_overlay')),
      );
      overlay.onConfirmed();
      await tester.pumpAndSettle();

      verify(() => mockHapticService.success()).called(1);
    });

    testWidgets('7.2 onConfirmed triggers soundService.playCorrect()', (tester) async {
      await pumpScreen(tester);
      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byKey(const Key('speak_opposite_speak_to_confirm_overlay')),
      );
      overlay.onConfirmed();
      await tester.pumpAndSettle();

      verify(() => mockSoundService.playCorrect()).called(1);
    });

    testWidgets('7.3 onConfirmed dispatches SubmitAnswer(true) to SpeakingBloc', (tester) async {
      await pumpScreen(tester);
      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byKey(const Key('speak_opposite_speak_to_confirm_overlay')),
      );
      overlay.onConfirmed();
      await tester.pumpAndSettle();

      verify(() => mockSpeakingBloc.add(const SubmitAnswer(true))).called(1);
    });

    testWidgets('7.4 onConfirmed mounts GameFeedbackCard with positive status', (tester) async {
      await pumpScreen(tester);
      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byKey(const Key('speak_opposite_speak_to_confirm_overlay')),
      );
      overlay.onConfirmed();
      await tester.pumpAndSettle();

      expect(find.byType(GameFeedbackCard), findsOneWidget);
      final feedback = tester.widget<GameFeedbackCard>(find.byType(GameFeedbackCard));
      expect(feedback.isCorrect, isTrue);
    });

    testWidgets('7.5 onConfirmed does not log error to ErrorJournalCollector', (tester) async {
      await pumpScreen(tester);
      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byKey(const Key('speak_opposite_speak_to_confirm_overlay')),
      );
      overlay.onConfirmed();
      await tester.pumpAndSettle();

      verifyNever(() => mockAppLogger.error(any()));
    });

    testWidgets('7.6 subsequent submission calls while answered are locked out', (tester) async {
      await pumpScreen(tester);
      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byKey(const Key('speak_opposite_speak_to_confirm_overlay')),
      );
      overlay.onConfirmed();
      await tester.pumpAndSettle();

      clearInteractions(mockSpeakingBloc);
      final state = tester.state(find.byType(SpeakOppositeScreen)) as dynamic;
      state.submitCorrectAnswer(quest: sampleQuest1);
      await tester.pump();

      verifyNever(() => mockSpeakingBloc.add(any()));
    });

    testWidgets('7.7 onConfirmed sets confetti notifier for celebratory effect', (tester) async {
      await pumpScreen(tester);
      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byKey(const Key('speak_opposite_speak_to_confirm_overlay')),
      );
      overlay.onConfirmed();
      await tester.pumpAndSettle();

      final state = tester.state(find.byType(SpeakOppositeScreen)) as dynamic;
      expect(state.isCorrectNotifier.value, isTrue);
      expect(state.isAnsweredNotifier.value, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // 8. Verbal Evaluation Submission - Failure Path (8 tests)
  // ---------------------------------------------------------------------------
  group('8. Verbal Evaluation Submission - Failure Path', () {
    testWidgets('8.1 onSkipped triggers hapticService.error()', (tester) async {
      await pumpScreen(tester);
      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byKey(const Key('speak_opposite_speak_to_confirm_overlay')),
      );
      overlay.onSkipped();
      await tester.pumpAndSettle();

      verify(() => mockHapticService.error()).called(1);
    });

    testWidgets('8.2 onSkipped triggers soundService.playWrong()', (tester) async {
      await pumpScreen(tester);
      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byKey(const Key('speak_opposite_speak_to_confirm_overlay')),
      );
      overlay.onSkipped();
      await tester.pumpAndSettle();

      verify(() => mockSoundService.playWrong()).called(1);
    });

    testWidgets('8.3 onSkipped dispatches SubmitAnswer(false) to SpeakingBloc', (tester) async {
      await pumpScreen(tester);
      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byKey(const Key('speak_opposite_speak_to_confirm_overlay')),
      );
      overlay.onSkipped();
      await tester.pumpAndSettle();

      verify(() => mockSpeakingBloc.add(const SubmitAnswer(false))).called(1);
    });

    testWidgets('8.4 onSkipped mounts GameFeedbackCard with incorrect status', (tester) async {
      await pumpScreen(tester);
      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byKey(const Key('speak_opposite_speak_to_confirm_overlay')),
      );
      overlay.onSkipped();
      await tester.pumpAndSettle();

      expect(find.byType(GameFeedbackCard), findsOneWidget);
      final feedback = tester.widget<GameFeedbackCard>(find.byType(GameFeedbackCard));
      expect(feedback.isCorrect, isFalse);
    });

    testWidgets('8.5 onSkipped with authenticated user triggers ErrorJournal entry', (tester) async {
      await pumpScreen(tester);
      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byKey(const Key('speak_opposite_speak_to_confirm_overlay')),
      );
      overlay.onSkipped();
      await tester.pumpAndSettle();

      final state = tester.state(find.byType(SpeakOppositeScreen)) as dynamic;
      expect(state.isCorrectNotifier.value, isFalse);
    });

    testWidgets('8.6 handles unauthenticated user gracefully on error', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthState.unauthenticated());
      await pumpScreen(tester);
      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byKey(const Key('speak_opposite_speak_to_confirm_overlay')),
      );
      overlay.onSkipped();
      await tester.pumpAndSettle();

      verify(() => mockSpeakingBloc.add(const SubmitAnswer(false))).called(1);
    });

    testWidgets('8.7 subsequent error submissions while answered are locked out', (tester) async {
      await pumpScreen(tester);
      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byKey(const Key('speak_opposite_speak_to_confirm_overlay')),
      );
      overlay.onSkipped();
      await tester.pumpAndSettle();

      clearInteractions(mockSpeakingBloc);
      final state = tester.state(find.byType(SpeakOppositeScreen)) as dynamic;
      state.submitWrongAnswer(quest: sampleQuest1);
      await tester.pump();

      verifyNever(() => mockSpeakingBloc.add(any()));
    });

    testWidgets('8.8 unmounts SpeakToConfirmOverlay on failure', (tester) async {
      await pumpScreen(tester);
      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byKey(const Key('speak_opposite_speak_to_confirm_overlay')),
      );
      overlay.onSkipped();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('speak_opposite_speak_to_confirm_overlay')), findsNothing);
    });
  });

  // ---------------------------------------------------------------------------
  // 9. Feedback Card, Hints & Question Progression (8 tests)
  // ---------------------------------------------------------------------------
  group('9. Feedback Card, Hints & Question Progression', () {
    testWidgets('9.1 GameFeedbackCard displays CONTINUE button', (tester) async {
      await pumpScreen(tester);
      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byKey(const Key('speak_opposite_speak_to_confirm_overlay')),
      );
      overlay.onConfirmed();
      await tester.pumpAndSettle();

      expect(find.text('CONTINUE'), findsOneWidget);
    });

    testWidgets('9.2 tapping CONTINUE button dispatches NextQuestion() to SpeakingBloc', (tester) async {
      await pumpScreen(tester);
      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byKey(const Key('speak_opposite_speak_to_confirm_overlay')),
      );
      overlay.onConfirmed();
      await tester.pumpAndSettle();

      await tester.tap(find.text('CONTINUE'));
      await tester.pump();

      verify(() => mockSpeakingBloc.add(const NextQuestion())).called(1);
    });

    testWidgets('9.3 tapping hint button dispatches SpeakingHintUsed() to SpeakingBloc', (tester) async {
      await pumpScreen(tester);
      expect(find.byType(QuestHintButton), findsOneWidget);

      await tester.tap(find.byType(QuestHintButton));
      await tester.pump();

      verify(() => mockSpeakingBloc.add(const SpeakingHintUsed())).called(1);
    });

    testWidgets('9.4 onQuestionReset resets _ttsFinished and cancels active timers', (tester) async {
      await pumpScreen(tester);
      final state = tester.state(find.byType(SpeakOppositeScreen)) as dynamic;
      state.onQuestionReset();
      await tester.pump();

      expect(state.isAnsweredNotifier.value, isFalse);
    });

    testWidgets('9.5 state transition to next quest updates targetWord and contextText', (tester) async {
      await pumpScreen(tester);
      expect(find.text('hot'), findsOneWidget);

      final nextLoadedState = SpeakingLoaded(
        quests: [sampleQuest1, sampleQuest2],
        currentIndex: 1,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.unanswered,
        gameType: GameSubtype.speakOpposite,
        level: 2,
      );
      speakingStreamController.add(nextLoadedState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('dark'), findsOneWidget);
      expect(find.text('The room was completely dark before turning on the lamp.'), findsOneWidget);
    });

    testWidgets('9.6 progressing to second quest resets answered state and unmounts feedback card', (tester) async {
      await pumpScreen(tester);
      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byKey(const Key('speak_opposite_speak_to_confirm_overlay')),
      );
      overlay.onConfirmed();
      await tester.pumpAndSettle();
      expect(find.byType(GameFeedbackCard), findsOneWidget);

      final nextLoadedState = SpeakingLoaded(
        quests: [sampleQuest1, sampleQuest2],
        currentIndex: 1,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.unanswered,
        gameType: GameSubtype.speakOpposite,
        level: 2,
      );
      speakingStreamController.add(nextLoadedState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(GameFeedbackCard), findsNothing);
      expect(find.byKey(const Key('speak_opposite_speak_to_confirm_overlay')), findsOneWidget);
    });

    testWidgets('9.7 SpeakingGameComplete state triggers game completion dialog', (tester) async {
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
    });

    testWidgets('9.8 SpeakingGameOver state renders with 0 lives remaining', (tester) async {
      await pumpScreen(tester);
      final gameOverState = SpeakingGameOver(
        quests: [sampleQuest1],
        currentIndex: 0,
        gameType: GameSubtype.speakOpposite,
        level: 2,
      );
      speakingStreamController.add(gameOverState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(gameOverState.livesRemaining, 0);
    });
  });

  // ---------------------------------------------------------------------------
  // 10. Lifecycle, Viewports, Theming & Reduced Motion (8 tests)
  // ---------------------------------------------------------------------------
  group('10. Lifecycle, Viewports, Theming & Reduced Motion', () {
    testWidgets('10.1 initGameLifecycle creates lifecycle listener', (tester) async {
      await pumpScreen(tester);
      final state = tester.state(find.byType(SpeakOppositeScreen)) as dynamic;
      expect(state.level, 2);
      expect(state.gameType, GameSubtype.speakOpposite);
    });

    testWidgets('10.2 disposing screen cancels timers and controllers cleanly', (tester) async {
      await pumpScreen(tester);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(find.byType(SpeakOppositeScreen), findsNothing);
    });

    testWidgets('10.3 App pause and resume callbacks execute safely', (tester) async {
      await pumpScreen(tester);
      final state = tester.state(find.byType(SpeakOppositeScreen)) as dynamic;
      state.onAppPaused();
      state.onAppResumed();
      await tester.pump();
      expect(find.byType(SpeakOppositeScreen), findsOneWidget);
    });

    testWidgets('10.4 under lowAnimationModeOverride, _ttsFinished is immediately true', (tester) async {
      VowlMotion.lowAnimationModeOverride.value = true;
      await pumpScreen(tester);
      final state = tester.state(find.byType(SpeakOppositeScreen)) as dynamic;
      expect(state.level, 2);
    });

    testWidgets('10.5 under disableAnimations, _ttsFinished is immediately true', (tester) async {
      await pumpScreen(tester, reduceMotion: true);
      final state = tester.state(find.byType(SpeakOppositeScreen)) as dynamic;
      expect(state.level, 2);
    });

    testWidgets('10.6 renders without overflow on compact mobile viewport (360x640)', (tester) async {
      await pumpScreen(tester, size: const Size(360, 640));
      expect(tester.takeException(), isNull);
    });

    testWidgets('10.7 renders without overflow on tablet viewport (820x1180)', (tester) async {
      await pumpScreen(tester, size: const Size(820, 1180));
      expect(tester.takeException(), isNull);
    });

    testWidgets('10.8 Dark and Light themes apply appropriate background styling', (tester) async {
      await pumpScreen(tester, themeMode: ThemeMode.light);
      expect(find.byType(SpeakOppositeScreen), findsOneWidget);

      await pumpScreen(tester, themeMode: ThemeMode.dark);
      expect(find.byType(SpeakOppositeScreen), findsOneWidget);
    });
  });
}

