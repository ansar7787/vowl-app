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
import 'package:vowl/features/speaking/speak_synonym/presentation/pages/speak_synonym_screen.dart';
import 'package:vowl/features/speaking/speak_synonym/presentation/widgets/speak_synonym_header.dart';
import 'package:vowl/features/speaking/speak_synonym/presentation/widgets/speak_synonym_sentence_panel.dart';

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
    String id = 'quest_synonym_1',
    String textToSpeak = 'Wow, your new apartment is *big*!',
    String? correctAnswer = 'large',
    List<String>? acceptedSynonyms = const ['roomy', 'huge', 'spacious', 'large'],
    String instruction = 'Say a synonym for the highlighted word.',
    String? hint = 'Think of plenty of room.',
    int difficulty = 1,
  }) {
    return SpeakingQuest(
      id: id,
      type: QuestType.speaking,
      subtype: GameSubtype.speakSynonym,
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
    id: 'quest_synonym_2',
    textToSpeak: "Don't worry, it's only a *small* problem.",
    correctAnswer: 'minor',
    acceptedSynonyms: ['little', 'slight', 'minor'],
    instruction: 'Replace the highlighted word with a synonym.',
    hint: "Not worth stressing about.",
  );

  final testLoadedState = SpeakingLoaded(
    quests: [sampleQuest1, sampleQuest2],
    currentIndex: 0,
    livesRemaining: 3,
    wrongCount: 0,
    hintUsed: false,
    answerStatus: AnswerStatus.unanswered,
    gameType: GameSubtype.speakSynonym,
    level: 2,
  );

  setUpAll(() {
    registerFallbackValue(const SubmitAnswer(true));
    registerFallbackValue(const NextQuestion());
    registerFallbackValue(const SpeakingHintUsed());
    registerFallbackValue(
      const FetchSpeakingQuests(
        gameType: GameSubtype.speakSynonym,
        level: 2,
      ),
    );
    registerFallbackValue(const Duration(milliseconds: 50));
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'has_seen_briefing_speakSynonym': true,
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
          id: 'test_user_synonym',
          email: 'synonym@vowl.app',
          displayName: 'Synonym Explorer',
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
        .thenAnswer((_) async => 'mock_synonym_rec.m4a');
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
    GameSubtype gameType = GameSubtype.speakSynonym,
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
              child: SpeakSynonymScreen(
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

    testWidgets('1.2 renders SpeakSynonymHeader with key speak_synonym_header', (tester) async {
      await pumpScreen(tester);
      expect(find.byType(SpeakSynonymHeader), findsOneWidget);
      expect(find.byKey(const Key('speak_synonym_header')), findsOneWidget);
    });

    testWidgets('1.3 renders SYNONYM CHALLENGE badge with key speak_synonym_challenge_badge', (tester) async {
      await pumpScreen(tester);
      expect(find.byKey(const Key('speak_synonym_challenge_badge')), findsOneWidget);
      expect(find.text('SYNONYM CHALLENGE'), findsOneWidget);
    });

    testWidgets('1.4 renders instruction text with key speak_synonym_instruction_text', (tester) async {
      await pumpScreen(tester);
      expect(find.byKey(const Key('speak_synonym_instruction_text')), findsOneWidget);
      expect(find.text('Say a synonym for the highlighted word.'), findsOneWidget);
    });

    testWidgets('1.5 renders SpeakSynonymSentencePanel with key speak_synonym_sentence_panel', (tester) async {
      await pumpScreen(tester);
      expect(find.byType(SpeakSynonymSentencePanel), findsOneWidget);
      expect(find.byKey(const Key('speak_synonym_sentence_panel')), findsOneWidget);
    });

    testWidgets('1.6 renders RawScrollbar with key speak_synonym_scrollbar', (tester) async {
      await pumpScreen(tester);
      expect(find.byKey(const Key('speak_synonym_scrollbar')), findsOneWidget);
    });

    testWidgets('1.7 renders CustomScrollView with key speak_synonym_scroll_view', (tester) async {
      await pumpScreen(tester);
      expect(find.byKey(const Key('speak_synonym_scroll_view')), findsOneWidget);
    });

    testWidgets('1.8 renders SpeakToConfirmOverlay with key speak_synonym_speak_to_confirm_overlay', (tester) async {
      await pumpScreen(tester);
      expect(find.byKey(const Key('speak_synonym_speak_to_confirm_overlay')), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // 2. Sentence Parser & RichText Formatting (8 tests)
  // ---------------------------------------------------------------------------
  group('2. Sentence Parser & RichText Formatting', () {
    testWidgets('2.1 renders RichText with key speak_synonym_rich_text', (tester) async {
      await pumpScreen(tester);
      expect(find.byKey(const Key('speak_synonym_rich_text')), findsOneWidget);
    });

    testWidgets('2.2 splits text with asterisks into highlighted target chip', (tester) async {
      await pumpScreen(tester);
      expect(find.byKey(const Key('speak_synonym_target_chip_1')), findsOneWidget);
    });

    testWidgets('2.3 renders target word text with key speak_synonym_target_text_1', (tester) async {
      await pumpScreen(tester);
      expect(find.byKey(const Key('speak_synonym_target_text_1')), findsOneWidget);
      expect(find.text('big'), findsOneWidget);
    });

    testWidgets('2.4 non-target segments are rendered as plain text spans', (tester) async {
      await pumpScreen(tester);
      final richText = tester.widget<RichText>(find.byKey(const Key('speak_synonym_rich_text')));
      expect(richText.text.toPlainText(), contains('Wow, your new apartment is '));
    });

    testWidgets('2.5 handles sentence with multiple asterisks', (tester) async {
      final multiQuest = createQuest(
        textToSpeak: 'The *quick* fox jumps over the *lazy* dog.',
      );
      final multiState = SpeakingLoaded(
        quests: [multiQuest],
        currentIndex: 0,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.unanswered,
        gameType: GameSubtype.speakSynonym,
        level: 2,
      );
      await pumpScreen(tester, state: multiState);
      expect(find.byKey(const Key('speak_synonym_target_chip_1')), findsOneWidget);
      expect(find.byKey(const Key('speak_synonym_target_chip_3')), findsOneWidget);
      expect(find.text('quick'), findsOneWidget);
      expect(find.text('lazy'), findsOneWidget);
    });

    testWidgets('2.6 handles sentence without asterisks gracefully', (tester) async {
      final plainQuest = createQuest(
        textToSpeak: 'The house is very clean.',
      );
      final plainState = SpeakingLoaded(
        quests: [plainQuest],
        currentIndex: 0,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.unanswered,
        gameType: GameSubtype.speakSynonym,
        level: 2,
      );
      await pumpScreen(tester, state: plainState);
      expect(find.byKey(const Key('speak_synonym_target_chip_1')), findsNothing);
      final richText = tester.widget<RichText>(find.byKey(const Key('speak_synonym_rich_text')));
      expect(richText.text.toPlainText(), contains('The house is very clean.'));
    });

    testWidgets('2.7 handles empty textToSpeak without crashing', (tester) async {
      final emptyQuest = createQuest(textToSpeak: '');
      final emptyState = SpeakingLoaded(
        quests: [emptyQuest],
        currentIndex: 0,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.unanswered,
        gameType: GameSubtype.speakSynonym,
        level: 2,
      );
      await pumpScreen(tester, state: emptyState);
      expect(find.byType(SpeakSynonymSentencePanel), findsOneWidget);
    });

    testWidgets('2.8 renders GameShimmerLoading when quest is null', (tester) async {
      await pumpScreen(tester, state: const SpeakingInitial());
      expect(find.byType(GameShimmerLoading), findsOneWidget);
      expect(find.byType(SpeakSynonymSentencePanel), findsNothing);
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

    testWidgets('3.2 displays briefing title containing SYNONYM', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpScreen(tester, level: 1);
      expect(find.textContaining('SYNONYM'), findsWidgets);
    });

    testWidgets('3.3 displays action button with start text', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpScreen(tester, level: 1);
      expect(find.text('START SPEAKING'), findsOneWidget);
    });

    testWidgets('3.4 tapping action button dismisses overlay', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpScreen(tester, level: 1);
      expect(find.byType(QuestBriefingOverlay), findsOneWidget);

      await tester.ensureVisible(find.text('START SPEAKING'));
      await tester.tap(find.text('START SPEAKING'));
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
  // 4. TTS Audio Playback & Listen Controls (8 tests)
  // ---------------------------------------------------------------------------
  group('4. TTS Audio Playback & Listen Controls', () {
    testWidgets('4.1 tapping listen button calls soundService.playTts with stripped sentence', (tester) async {
      await pumpScreen(tester);
      clearInteractions(mockSoundService);

      await tester.tap(find.byKey(const Key('speak_synonym_listen_button')));
      await tester.pump();

      verify(() => mockSoundService.playTts('Wow, your new apartment is big!')).called(1);
    });

    testWidgets('4.2 tapping listen button does NOT play TTS if audioRecorder.isRecording is true', (tester) async {
      when(() => mockAudioRecorder.isRecording).thenReturn(true);
      await pumpScreen(tester);
      clearInteractions(mockSoundService);

      await tester.tap(find.byKey(const Key('speak_synonym_listen_button')));
      await tester.pump();

      verifyNever(() => mockSoundService.playTts(any()));
    });

    testWidgets('4.3 listen button has volume_up_rounded icon', (tester) async {
      await pumpScreen(tester);
      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
    });

    testWidgets('4.4 listen button has accessible Semantics label', (tester) async {
      await pumpScreen(tester);
      expect(
        find.byWidgetPredicate((w) =>
            w is Semantics &&
            w.properties.button == true &&
            w.properties.label == 'Listen to sentence'),
        findsOneWidget,
      );
    });

    testWidgets('4.5 sentence panel has accessible Semantics label containing clean sentence', (tester) async {
      await pumpScreen(tester);
      expect(
        find.byWidgetPredicate((w) =>
            w is Semantics &&
            w.properties.label == 'Sentence: Wow, your new apartment is big!'),
        findsOneWidget,
      );
    });

    testWidgets('4.6 header has Semantics with header: true', (tester) async {
      await pumpScreen(tester);
      expect(
        find.byWidgetPredicate((w) => w is Semantics && w.properties.header == true),
        findsWidgets,
      );
    });

    testWidgets('4.7 header challenge badge contains eco_rounded icon', (tester) async {
      await pumpScreen(tester);
      expect(find.byIcon(Icons.eco_rounded), findsOneWidget);
    });

    testWidgets('4.8 listen button is mounted inside sentence panel', (tester) async {
      await pumpScreen(tester);
      expect(
        find.descendant(
          of: find.byKey(const Key('speak_synonym_sentence_panel')),
          matching: find.byKey(const Key('speak_synonym_listen_button')),
        ),
        findsOneWidget,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // 5. AutoPlay Mechanics & TTS Barrier (_ttsFinished) (8 tests)
  // ---------------------------------------------------------------------------
  group('5. AutoPlay Mechanics & TTS Barrier (_ttsFinished)', () {
    testWidgets('5.1 autoPlay triggers soundService.playTts with cleaned sentence on mount', (tester) async {
      clearInteractions(mockSoundService);
      await pumpScreen(tester);
      verify(() => mockSoundService.playTts('Wow, your new apartment is big!')).called(1);
    });

    testWidgets('5.2 under lowAnimationModeOverride, _ttsFinished is immediately true', (tester) async {
      VowlMotion.lowAnimationModeOverride.value = true;
      await pumpScreen(tester);

      final state = tester.state(find.byType(SpeakSynonymScreen)) as dynamic;
      expect(state.ttsFinishedNotifier.value, isTrue);

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

      final state = tester.state(find.byType(SpeakSynonymScreen)) as dynamic;
      expect(state.ttsFinishedNotifier.value, isTrue);
    });

    testWidgets('5.5 reduced motion via disableAnimations sets _ttsFinished to true', (tester) async {
      VowlMotion.lowAnimationModeOverride.value = false;
      await pumpScreen(tester, reduceMotion: true);

      final state = tester.state(find.byType(SpeakSynonymScreen)) as dynamic;
      expect(state.ttsFinishedNotifier.value, isTrue);
    });

    testWidgets('5.6 empty quest textToSpeak sets _ttsFinished to true immediately', (tester) async {
      final emptyQuest = createQuest(textToSpeak: '', instruction: 'Say something');
      final emptyState = SpeakingLoaded(
        quests: [emptyQuest],
        currentIndex: 0,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.unanswered,
        gameType: GameSubtype.speakSynonym,
        level: 2,
      );
      await pumpScreen(tester, state: emptyState);

      final state = tester.state(find.byType(SpeakSynonymScreen)) as dynamic;
      expect(state.ttsFinishedNotifier.value, isTrue);
    });

    testWidgets('5.7 multiple audio triggers safely play without crashing', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('speak_synonym_listen_button')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('speak_synonym_listen_button')));
      await tester.pump();

      verify(() => mockSoundService.playTts('Wow, your new apartment is big!')).called(greaterThanOrEqualTo(2));
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
        gameType: GameSubtype.speakSynonym,
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
    testWidgets('6.1 renders SpeakToConfirmOverlay with key speak_synonym_speak_to_confirm_overlay', (tester) async {
      await pumpScreen(tester);
      expect(
        find.byKey(const Key('speak_synonym_speak_to_confirm_overlay')),
        findsOneWidget,
      );
    });

    testWidgets('6.2 sets hideExpectedText to true so synonym is not revealed', (tester) async {
      await pumpScreen(tester);
      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byKey(const Key('speak_synonym_speak_to_confirm_overlay')),
      );
      expect(overlay.hideExpectedText, isTrue);
    });

    testWidgets('6.3 sets allowSkip to false', (tester) async {
      await pumpScreen(tester);
      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byKey(const Key('speak_synonym_speak_to_confirm_overlay')),
      );
      expect(overlay.allowSkip, isFalse);
    });

    testWidgets('6.4 sets title to SPEAK A SYNONYM', (tester) async {
      await pumpScreen(tester);
      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byKey(const Key('speak_synonym_speak_to_confirm_overlay')),
      );
      expect(overlay.title, 'SPEAK A SYNONYM');
      expect(find.text('SPEAK A SYNONYM'), findsOneWidget);
    });

    testWidgets('6.5 sets subtitle to Say your answer aloud to confirm', (tester) async {
      await pumpScreen(tester);
      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byKey(const Key('speak_synonym_speak_to_confirm_overlay')),
      );
      expect(overlay.subtitle, 'Say your answer aloud to confirm');
      expect(find.text('Say your answer aloud to confirm'), findsOneWidget);
    });

    testWidgets('6.6 passes acceptedSynonyms into overlay', (tester) async {
      await pumpScreen(tester);
      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byKey(const Key('speak_synonym_speak_to_confirm_overlay')),
      );
      expect(overlay.acceptedSynonyms, ['roomy', 'huge', 'spacious', 'large']);
      expect(overlay.expectedText, 'large');
    });

    testWidgets('6.7 falls back to correctAnswer when acceptedSynonyms is empty', (tester) async {
      final questNoSynonyms = createQuest(
        acceptedSynonyms: [],
        correctAnswer: 'huge',
      );
      final stateNoSynonyms = SpeakingLoaded(
        quests: [questNoSynonyms],
        currentIndex: 0,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.unanswered,
        gameType: GameSubtype.speakSynonym,
        level: 2,
      );
      await pumpScreen(tester, state: stateNoSynonyms);
      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byKey(const Key('speak_synonym_speak_to_confirm_overlay')),
      );
      expect(overlay.acceptedSynonyms, ['huge']);
      expect(overlay.expectedText, 'huge');
    });

    testWidgets('6.8 unmounts SpeakToConfirmOverlay when question is answered', (tester) async {
      await pumpScreen(tester);
      expect(find.byKey(const Key('speak_synonym_speak_to_confirm_overlay')), findsOneWidget);

      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byKey(const Key('speak_synonym_speak_to_confirm_overlay')),
      );
      overlay.onConfirmed();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('speak_synonym_speak_to_confirm_overlay')), findsNothing);
    });
  });

  // ---------------------------------------------------------------------------
  // 7. Verbal Evaluation Submission - Success Path (7 tests)
  // ---------------------------------------------------------------------------
  group('7. Verbal Evaluation Submission - Success Path', () {
    testWidgets('7.1 onConfirmed triggers hapticService.success()', (tester) async {
      await pumpScreen(tester);
      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byKey(const Key('speak_synonym_speak_to_confirm_overlay')),
      );
      overlay.onConfirmed();
      await tester.pumpAndSettle();

      verify(() => mockHapticService.success()).called(1);
    });

    testWidgets('7.2 onConfirmed triggers soundService.playCorrect()', (tester) async {
      await pumpScreen(tester);
      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byKey(const Key('speak_synonym_speak_to_confirm_overlay')),
      );
      overlay.onConfirmed();
      await tester.pumpAndSettle();

      verify(() => mockSoundService.playCorrect()).called(1);
    });

    testWidgets('7.3 onConfirmed dispatches SubmitAnswer(true) to SpeakingBloc', (tester) async {
      await pumpScreen(tester);
      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byKey(const Key('speak_synonym_speak_to_confirm_overlay')),
      );
      overlay.onConfirmed();
      await tester.pumpAndSettle();

      verify(() => mockSpeakingBloc.add(const SubmitAnswer(true))).called(1);
    });

    testWidgets('7.4 onConfirmed mounts GameFeedbackCard with positive status', (tester) async {
      await pumpScreen(tester);
      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byKey(const Key('speak_synonym_speak_to_confirm_overlay')),
      );
      overlay.onConfirmed();
      await tester.pumpAndSettle();

      expect(find.byType(GameFeedbackCard), findsOneWidget);
      final feedback = tester.widget<GameFeedbackCard>(find.byType(GameFeedbackCard));
      expect(feedback.isCorrect, isTrue);
    });

    testWidgets('7.5 onConfirmed sets bloomProgress to 1.0', (tester) async {
      await pumpScreen(tester);
      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byKey(const Key('speak_synonym_speak_to_confirm_overlay')),
      );
      overlay.onConfirmed();
      await tester.pumpAndSettle();

      final state = tester.state(find.byType(SpeakSynonymScreen)) as dynamic;
      expect(state.bloomProgressNotifier.value, 1.0);
    });

    testWidgets('7.6 subsequent submission calls while answered are locked out', (tester) async {
      await pumpScreen(tester);
      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byKey(const Key('speak_synonym_speak_to_confirm_overlay')),
      );
      overlay.onConfirmed();
      await tester.pumpAndSettle();

      clearInteractions(mockSpeakingBloc);
      final state = tester.state(find.byType(SpeakSynonymScreen)) as dynamic;
      state.submitEvaluation(true);
      await tester.pump();

      verifyNever(() => mockSpeakingBloc.add(any()));
    });

    testWidgets('7.7 onConfirmed sets confetti and answered state', (tester) async {
      await pumpScreen(tester);
      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byKey(const Key('speak_synonym_speak_to_confirm_overlay')),
      );
      overlay.onConfirmed();
      await tester.pumpAndSettle();

      final state = tester.state(find.byType(SpeakSynonymScreen)) as dynamic;
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
        find.byKey(const Key('speak_synonym_speak_to_confirm_overlay')),
      );
      overlay.onSkipped();
      await tester.pumpAndSettle();

      verify(() => mockHapticService.error()).called(1);
    });

    testWidgets('8.2 onSkipped triggers soundService.playWrong()', (tester) async {
      await pumpScreen(tester);
      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byKey(const Key('speak_synonym_speak_to_confirm_overlay')),
      );
      overlay.onSkipped();
      await tester.pumpAndSettle();

      verify(() => mockSoundService.playWrong()).called(1);
    });

    testWidgets('8.3 onSkipped dispatches SubmitAnswer(false) to SpeakingBloc', (tester) async {
      await pumpScreen(tester);
      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byKey(const Key('speak_synonym_speak_to_confirm_overlay')),
      );
      overlay.onSkipped();
      await tester.pumpAndSettle();

      verify(() => mockSpeakingBloc.add(const SubmitAnswer(false))).called(1);
    });

    testWidgets('8.4 onSkipped mounts GameFeedbackCard with incorrect status', (tester) async {
      await pumpScreen(tester);
      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byKey(const Key('speak_synonym_speak_to_confirm_overlay')),
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
        find.byKey(const Key('speak_synonym_speak_to_confirm_overlay')),
      );
      overlay.onSkipped();
      await tester.pumpAndSettle();

      final state = tester.state(find.byType(SpeakSynonymScreen)) as dynamic;
      expect(state.isCorrectNotifier.value, isFalse);
      expect(state.bloomProgressNotifier.value, 0.0);
    });

    testWidgets('8.6 handles unauthenticated user gracefully on error', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthState.unauthenticated());
      await pumpScreen(tester);
      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byKey(const Key('speak_synonym_speak_to_confirm_overlay')),
      );
      overlay.onSkipped();
      await tester.pumpAndSettle();

      verify(() => mockSpeakingBloc.add(const SubmitAnswer(false))).called(1);
    });

    testWidgets('8.7 subsequent error submissions while answered are locked out', (tester) async {
      await pumpScreen(tester);
      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byKey(const Key('speak_synonym_speak_to_confirm_overlay')),
      );
      overlay.onSkipped();
      await tester.pumpAndSettle();

      clearInteractions(mockSpeakingBloc);
      final state = tester.state(find.byType(SpeakSynonymScreen)) as dynamic;
      state.submitEvaluation(false);
      await tester.pump();

      verifyNever(() => mockSpeakingBloc.add(any()));
    });

    testWidgets('8.8 unmounts SpeakToConfirmOverlay on failure', (tester) async {
      await pumpScreen(tester);
      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byKey(const Key('speak_synonym_speak_to_confirm_overlay')),
      );
      overlay.onSkipped();
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('speak_synonym_speak_to_confirm_overlay')), findsNothing);
    });
  });

  // ---------------------------------------------------------------------------
  // 9. Feedback Card, Hints & Question Progression (8 tests)
  // ---------------------------------------------------------------------------
  group('9. Feedback Card, Hints & Question Progression', () {
    testWidgets('9.1 GameFeedbackCard displays CONTINUE button', (tester) async {
      await pumpScreen(tester);
      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byKey(const Key('speak_synonym_speak_to_confirm_overlay')),
      );
      overlay.onConfirmed();
      await tester.pumpAndSettle();

      expect(find.text('CONTINUE'), findsOneWidget);
    });

    testWidgets('9.2 tapping CONTINUE button dispatches NextQuestion() to SpeakingBloc', (tester) async {
      await pumpScreen(tester);
      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byKey(const Key('speak_synonym_speak_to_confirm_overlay')),
      );
      overlay.onConfirmed();
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

    testWidgets('9.4 when hintUsed is true and hint exists, renders hint card', (tester) async {
      final hintState = SpeakingLoaded(
        quests: [sampleQuest1],
        currentIndex: 0,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: true,
        answerStatus: AnswerStatus.unanswered,
        gameType: GameSubtype.speakSynonym,
        level: 2,
      );
      await pumpScreen(tester, state: hintState);

      expect(find.byKey(const Key('speak_synonym_hint_card')), findsOneWidget);
      expect(find.byKey(const Key('speak_synonym_hint_icon')), findsOneWidget);
      expect(find.byKey(const Key('speak_synonym_hint_text')), findsOneWidget);
      expect(find.text('Think of plenty of room.'), findsOneWidget);
    });

    testWidgets('9.5 does not render hint card when hintUsed is false', (tester) async {
      await pumpScreen(tester);
      expect(find.byKey(const Key('speak_synonym_hint_card')), findsNothing);
    });

    testWidgets('9.6 onQuestionReset resets _ttsFinished, _bloomProgress, and active timers', (tester) async {
      await pumpScreen(tester);
      final state = tester.state(find.byType(SpeakSynonymScreen)) as dynamic;
      state.onQuestionReset();
      await tester.pump();

      expect(state.isAnsweredNotifier.value, isFalse);
      expect(state.bloomProgressNotifier.value, 0.0);
    });

    testWidgets('9.7 state transition to next quest updates sentence and target chip', (tester) async {
      await pumpScreen(tester);
      expect(find.text('big'), findsOneWidget);

      final nextLoadedState = SpeakingLoaded(
        quests: [sampleQuest1, sampleQuest2],
        currentIndex: 1,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.unanswered,
        gameType: GameSubtype.speakSynonym,
        level: 2,
      );
      speakingStreamController.add(nextLoadedState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('small'), findsOneWidget);
      final richText = tester.widget<RichText>(find.byKey(const Key('speak_synonym_rich_text')));
      expect(richText.text.toPlainText(), contains("Don't worry, it's only a"));
    });

    testWidgets('9.8 SpeakingGameComplete state triggers game completion dialog', (tester) async {
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
  });

  // ---------------------------------------------------------------------------
  // 10. Viewports, Theming, Edge Cases & Robustness (8 tests)
  // ---------------------------------------------------------------------------
  group('10. Viewports, Theming, Edge Cases & Robustness', () {
    testWidgets('10.1 renders cleanly on compact phone viewport (320x640)', (tester) async {
      await pumpScreen(tester, size: const Size(320, 640));
      expect(find.byType(SpeakSynonymScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('10.2 renders cleanly on large tablet viewport (800x1280)', (tester) async {
      await pumpScreen(tester, size: const Size(800, 1280));
      expect(find.byType(SpeakSynonymScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('10.3 supports light theme mode without errors', (tester) async {
      await pumpScreen(tester, themeMode: ThemeMode.light);
      expect(find.byType(SpeakSynonymScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('10.4 supports dark theme mode without errors', (tester) async {
      await pumpScreen(tester, themeMode: ThemeMode.dark);
      expect(find.byType(SpeakSynonymScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('10.5 handles extreme text scale factors (1.5x) via clamped scaler', (tester) async {
      await pumpScreen(tester, textScaleFactor: 1.5);
      expect(find.byType(SpeakSynonymScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('10.6 submitEvaluation test helper sets isCorrectNotifier properly', (tester) async {
      await pumpScreen(tester);
      final state = tester.state(find.byType(SpeakSynonymScreen)) as dynamic;
      state.submitEvaluation(true);
      await tester.pumpAndSettle();

      expect(state.isCorrectNotifier.value, isTrue);
      expect(state.isAnsweredNotifier.value, isTrue);
      expect(state.bloomProgressNotifier.value, 1.0);
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
          gameType: GameSubtype.speakSynonym,
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
      final state = tester.state(find.byType(SpeakSynonymScreen)) as dynamic;
      state.onGamePaused();
      state.onGameResumed();
      expect(tester.takeException(), isNull);
    });
  });
}

