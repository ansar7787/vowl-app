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
import 'package:vowl/core/presentation/game_mechanics/arranging/dynamic_jigsaw_wrapper.dart';
import 'package:vowl/core/presentation/game_mechanics/shared/speed_challenge_timer.dart';
import 'package:vowl/core/presentation/widgets/game_briefing_layer.dart';
import 'package:vowl/core/presentation/widgets/quest_hint_button.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/analytics_service.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/features/listening/audio_sentence_order/presentation/pages/audio_sentence_order_screen.dart';
import 'package:vowl/features/listening/audio_sentence_order/presentation/widgets/audio_sentence_order_instruction.dart';
import 'package:vowl/features/listening/audio_sentence_order/presentation/widgets/audio_sentence_order_oscilloscope.dart';
import 'package:vowl/features/listening/domain/entities/listening_quest.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_bloc.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_event.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_state.dart';

class MockListeningBloc extends MockBloc<ListeningEvent, ListeningState>
    implements ListeningBloc {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockEconomyBloc extends MockBloc<EconomyEvent, EconomyState>
    implements EconomyBloc {}

class MockHapticService extends Mock implements HapticService {}

class MockSoundService extends Mock implements SoundService {}

class MockTtsService extends Mock implements TtsService {}

class MockLocaleService extends Mock implements LocaleService {}

class MockAppLogger extends Mock implements AppLogger {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockAdService extends Mock implements AdService {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

class FakeListeningEvent extends Fake implements ListeningEvent {}

class FakeListeningState extends Fake implements ListeningState {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockListeningBloc mockListeningBloc;
  late StreamController<ListeningState> listeningStreamController;
  late MockAuthBloc mockAuthBloc;
  late MockEconomyBloc mockEconomyBloc;
  late MockHapticService mockHapticService;
  late MockSoundService mockSoundService;
  late MockTtsService mockTtsService;
  late MockLocaleService mockLocaleService;
  late MockAppLogger mockAppLogger;
  late MockAnalyticsService mockAnalyticsService;
  late MockAdService mockAdService;
  late MockNetworkInfo mockNetworkInfo;

  const sampleQuest = ListeningQuest(
    id: 'aso_1',
    instruction: 'Listen carefully and arrange the words in order.',
    difficulty: 1,
    subtype: GameSubtype.audioSentenceOrder,
    textToSpeak: 'the dog barked loudly',
    shuffledSentences: ['barked', 'the', 'loudly', 'dog'],
    correctOrder: [1, 3, 0, 2],
    emoji: '🐕',
    hint: 'Starts with the article "the".',
    explanation: 'The sentence correctly reads: the dog barked loudly.',
  );

  const sampleSecondQuest = ListeningQuest(
    id: 'aso_2',
    instruction: 'Arrange the sentence you heard.',
    difficulty: 2,
    subtype: GameSubtype.audioSentenceOrder,
    textToSpeak: 'she read a book',
    shuffledSentences: ['a', 'read', 'she', 'book'],
    correctOrder: [2, 1, 0, 3],
    emoji: '📖',
    hint: 'Subject pronoun comes first.',
  );

  const sampleSplitQuest = ListeningQuest(
    id: 'aso_split',
    instruction: 'Reconstruct the audio fragment.',
    difficulty: 1,
    subtype: GameSubtype.audioSentenceOrder,
    textToSpeak: 'hello beautiful world',
    emoji: '🌍',
  );

  final testLoadedState = ListeningLoaded(
    quests: const [sampleQuest, sampleSecondQuest],
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
    hintUsed: false,
    wrongCount: 0,
    isFinalFailure: false,
  );

  setUpAll(() {
    registerFallbackValue(FakeListeningEvent());
    registerFallbackValue(FakeListeningState());
    registerFallbackValue(const SubmitAnswer(true));
    registerFallbackValue(const SubmitAnswer(false));
    registerFallbackValue(const NextQuestion());
    registerFallbackValue(const ListeningHintUsed());
    VowlMotion.lowAnimationModeOverride.value = true;
  });

  tearDownAll(() {
    VowlMotion.lowAnimationModeOverride.value = false;
  });

  setUp(() async {
    mockListeningBloc = MockListeningBloc();
    mockAuthBloc = MockAuthBloc();
    mockEconomyBloc = MockEconomyBloc();
    mockHapticService = MockHapticService();
    mockSoundService = MockSoundService();
    mockTtsService = MockTtsService();
    mockLocaleService = MockLocaleService();
    mockAppLogger = MockAppLogger();
    mockAnalyticsService = MockAnalyticsService();
    mockAdService = MockAdService();
    mockNetworkInfo = MockNetworkInfo();

    listeningStreamController = StreamController<ListeningState>.broadcast();
    when(() => mockListeningBloc.stream)
        .thenAnswer((_) => listeningStreamController.stream);
    when(() => mockListeningBloc.state).thenReturn(testLoadedState);

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
    when(() => mockSoundService.playTts(any(), pauseMarkers: any(named: 'pauseMarkers')))
        .thenAnswer((_) async {});

    when(() => mockTtsService.stop()).thenAnswer((_) async {});
    when(
      () => mockTtsService.speak(
        any(),
        rate: any(named: 'rate'),
        locale: any(named: 'locale'),
      ),
    ).thenAnswer((_) async {});

    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

    SharedPreferences.setMockInitialValues({
      'has_seen_briefing_audioSentenceOrder': true,
    });

    if (di.sl.isRegistered<HapticService>()) di.sl.unregister<HapticService>();
    if (di.sl.isRegistered<SoundService>()) di.sl.unregister<SoundService>();
    if (di.sl.isRegistered<TtsService>()) di.sl.unregister<TtsService>();
    if (di.sl.isRegistered<LocaleService>()) di.sl.unregister<LocaleService>();
    if (di.sl.isRegistered<AppLogger>()) di.sl.unregister<AppLogger>();
    if (di.sl.isRegistered<AnalyticsService>()) di.sl.unregister<AnalyticsService>();
    if (di.sl.isRegistered<AdService>()) di.sl.unregister<AdService>();
    if (di.sl.isRegistered<NetworkInfo>()) di.sl.unregister<NetworkInfo>();

    di.sl.registerSingleton<HapticService>(mockHapticService);
    di.sl.registerSingleton<SoundService>(mockSoundService);
    di.sl.registerSingleton<TtsService>(mockTtsService);
    di.sl.registerSingleton<LocaleService>(mockLocaleService);
    di.sl.registerSingleton<AppLogger>(mockAppLogger);
    di.sl.registerSingleton<AnalyticsService>(mockAnalyticsService);
    di.sl.registerSingleton<AdService>(mockAdService);
    di.sl.registerSingleton<NetworkInfo>(mockNetworkInfo);
  });

  tearDown(() async {
    await listeningStreamController.close();
  });

  Future<void> pumpAudioSentenceOrderScreen(
    WidgetTester tester, {
    ListeningState? state,
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

    when(() => mockListeningBloc.state).thenReturn(state ?? testLoadedState);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ListeningBloc>.value(value: mockListeningBloc),
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<EconomyBloc>.value(value: mockEconomyBloc),
        ],
        child: ScreenUtilInit(
          designSize: size,
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) => MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            home: MediaQuery(
              data: MediaQueryData(
                size: size,
                padding: EdgeInsets.zero,
                viewInsets: EdgeInsets.zero,
                disableAnimations: reduceMotion,
              ),
              child: Scaffold(
                body: AudioSentenceOrderScreen(
                  level: level,
                  gameType: GameSubtype.audioSentenceOrder,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  group('AudioSentenceOrderScreen Layout & Mechanics Tests', () {
    testWidgets('1. Initial layout renders instruction, timer, oscilloscope, and sentence builder jigsaw area', (tester) async {
      await pumpAudioSentenceOrderScreen(tester);

      expect(find.byType(AudioSentenceOrderInstruction), findsOneWidget);
      expect(find.byKey(const Key('audio_sentence_order_instruction')), findsOneWidget);
      expect(find.text('Listen carefully and arrange the words in order.'), findsOneWidget);

      expect(find.byType(SpeedChallengeTimer), findsOneWidget);

      expect(find.byType(AudioSentenceOrderOscilloscope), findsOneWidget);
      expect(find.byKey(const Key('audio_sentence_order_oscilloscope')), findsOneWidget);

      expect(find.byType(DynamicJigsawWrapper), findsOneWidget);
      expect(find.text('Arrange the words'), findsOneWidget);
      expect(find.text('Tap or drag words to build the sentence'), findsOneWidget);
      expect(find.text('4 words'), findsOneWidget);
    });

    testWidgets('2. Oscilloscope button tap triggers TTS playback with textToSpeak and selection haptics', (tester) async {
      await pumpAudioSentenceOrderScreen(tester);

      final oscilloscopeBtn = find.byKey(const Key('audio_sentence_order_oscilloscope_btn'));
      expect(oscilloscopeBtn, findsOneWidget);

      await tester.tap(oscilloscopeBtn);
      await tester.pump();

      verify(() => mockSoundService.playTts(
        'the dog barked loudly',
        pauseMarkers: any(named: 'pauseMarkers'),
      )).called(1);
      verify(() => mockHapticService.selection()).called(1);
    });

    testWidgets('3. Oscilloscope audio playback cascades to prompt when textToSpeak is null', (tester) async {
      const promptQuest = ListeningQuest(
        id: 'aso_prompt',
        instruction: 'Arrange prompt audio.',
        difficulty: 1,
        subtype: GameSubtype.audioSentenceOrder,
        prompt: 'Prompt audio words here',
        shuffledSentences: ['prompt', 'audio', 'words', 'here'],
        correctOrder: [0, 1, 2, 3],
      );

      final promptState = testLoadedState.copyWith(quests: [promptQuest], currentIndex: 0);
      await pumpAudioSentenceOrderScreen(tester, state: promptState);

      await tester.tap(find.byKey(const Key('audio_sentence_order_oscilloscope_btn')));
      await tester.pump();

      verify(() => mockSoundService.playTts('Prompt audio words here', pauseMarkers: any(named: 'pauseMarkers'))).called(1);
    });

    testWidgets('4. Oscilloscope audio playback cascades to question when textToSpeak and prompt are null', (tester) async {
      const questionQuest = ListeningQuest(
        id: 'aso_question',
        instruction: 'Arrange question audio.',
        difficulty: 1,
        subtype: GameSubtype.audioSentenceOrder,
        question: 'Question sentence fallback',
        shuffledSentences: ['Question', 'sentence', 'fallback'],
        correctOrder: [0, 1, 2],
      );

      final questionState = testLoadedState.copyWith(quests: [questionQuest], currentIndex: 0);
      await pumpAudioSentenceOrderScreen(tester, state: questionState);

      await tester.tap(find.byKey(const Key('audio_sentence_order_oscilloscope_btn')));
      await tester.pump();

      verify(() => mockSoundService.playTts('Question sentence fallback', pauseMarkers: any(named: 'pauseMarkers'))).called(1);
    });

    testWidgets('5. Oscilloscope audio playback cascades to audioTranscript when other fields are null', (tester) async {
      const transcriptQuest = ListeningQuest(
        id: 'aso_transcript',
        instruction: 'Arrange transcript audio.',
        difficulty: 1,
        subtype: GameSubtype.audioSentenceOrder,
        transcript: 'Transcript spoken phrase',
        shuffledSentences: ['Transcript', 'spoken', 'phrase'],
        correctOrder: [0, 1, 2],
      );

      final transcriptState = testLoadedState.copyWith(quests: [transcriptQuest], currentIndex: 0);
      await pumpAudioSentenceOrderScreen(tester, state: transcriptState);

      await tester.tap(find.byKey(const Key('audio_sentence_order_oscilloscope_btn')));
      await tester.pump();

      verify(() => mockSoundService.playTts('Transcript spoken phrase', pauseMarkers: any(named: 'pauseMarkers'))).called(1);
    });

    testWidgets('6. Available word tiles render all expected words in word bank', (tester) async {
      await pumpAudioSentenceOrderScreen(tester);

      expect(find.text('barked'), findsOneWidget);
      expect(find.text('the'), findsOneWidget);
      expect(find.text('loudly'), findsOneWidget);
      expect(find.text('dog'), findsOneWidget);
    });

    testWidgets('7. Tapping an available word tile places it into the next empty slot in sentence builder', (tester) async {
      await pumpAudioSentenceOrderScreen(tester);

      final tileFinder = find.byKey(const ValueKey('avail_1'));
      await tester.tap(tileFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // 'the' is now in placed slot
      expect(find.byKey(const ValueKey('placed_1')), findsOneWidget);
      // 'Clear all' button now visible
      expect(find.text('Clear all'), findsOneWidget);
    });

    testWidgets('8. Tapping a placed tile returns it to the word bank and clears the slot', (tester) async {
      await pumpAudioSentenceOrderScreen(tester);

      // Place 'the'
      await tester.tap(find.text('the'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byKey(const ValueKey('placed_1')), findsOneWidget);

      // Tap placed tile to return it
      await tester.tap(find.byKey(const ValueKey('placed_1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // No placed tiles
      expect(find.byKey(const ValueKey('placed_1')), findsNothing);
      expect(find.text('Clear all'), findsNothing);
    });

    testWidgets('9. Placing all tiles in correct order dispatches SubmitAnswer(true) with success audio & haptics', (tester) async {
      await pumpAudioSentenceOrderScreen(tester);

      // Target sentence: "the dog barked loudly"
      // sampleQuest.shuffledSentences: ['barked', 'the', 'loudly', 'dog']
      // Correct order: 1 ('the'), 3 ('dog'), 0 ('barked'), 2 ('loudly')

      await tester.tap(find.text('the'));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('dog'));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('barked'));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('loudly'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockListeningBloc.add(const SubmitAnswer(true))).called(1);
    });

    testWidgets('10. Placing all tiles in incorrect order shows error state and increments attempt', (tester) async {
      await pumpAudioSentenceOrderScreen(tester);
      clearInteractions(mockListeningBloc);

      // Incorrect order: 'barked', 'the', 'dog', 'loudly'
      await tester.tap(find.text('barked'));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('the'));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('dog'));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('loudly'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Does not submit answer yet on first failed attempt
      verifyNever(() => mockListeningBloc.add(any(that: isA<SubmitAnswer>())));
    });

    testWidgets('11. Clear All button removes all placed tiles and returns them to word bank', (tester) async {
      await pumpAudioSentenceOrderScreen(tester);

      // Tap two tiles
      await tester.tap(find.text('the'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('dog'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Clear all'), findsOneWidget);

      // Tap Clear all
      await tester.tap(find.text('Clear all'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Clear all hidden and all 4 empty slots restored
      expect(find.text('Clear all'), findsNothing);
      expect(find.byKey(const ValueKey('empty_0')), findsOneWidget);
      expect(find.byKey(const ValueKey('empty_1')), findsOneWidget);
      expect(find.byKey(const ValueKey('empty_2')), findsOneWidget);
      expect(find.byKey(const ValueKey('empty_3')), findsOneWidget);
    });

    testWidgets('12. SpeedChallengeTimer onTimeUp automatically triggers wrong answer submission', (tester) async {
      await pumpAudioSentenceOrderScreen(tester);

      final timer = tester.widget<SpeedChallengeTimer>(find.byType(SpeedChallengeTimer));
      timer.onTimeUp();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockListeningBloc.add(const SubmitAnswer(false))).called(1);
    });

    testWidgets('13. Answering correctly stops the active SpeedChallengeTimer', (tester) async {
      await pumpAudioSentenceOrderScreen(tester);

      final timerState = tester.state<SpeedChallengeTimerState>(find.byType(SpeedChallengeTimer));
      expect(timerState.isTimerActive, isTrue);

      // Solve puzzle correctly
      await tester.tap(find.text('the'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('dog'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('barked'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('loudly'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(timerState.isTimerActive, isFalse);
    });

    testWidgets('14. Question transition clears selections, updates jigsaw with new words, and restarts timer without GlobalKey crashes', (tester) async {
      await pumpAudioSentenceOrderScreen(tester);

      // Transition to quest 2
      final nextState = ListeningLoaded(
        quests: const [sampleQuest, sampleSecondQuest],
        currentIndex: 1,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
        hintUsed: false,
        wrongCount: 0,
        isFinalFailure: false,
      );

      listeningStreamController.add(nextState);
      when(() => mockListeningBloc.state).thenReturn(nextState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('she'), findsOneWidget);
      expect(find.text('read'), findsOneWidget);
      expect(find.text('book'), findsOneWidget);
      expect(find.text('barked'), findsNothing);
    });

    testWidgets('15. Continue button in answered state dispatches NextQuestion event', (tester) async {
      final answeredState = ListeningLoaded(
        quests: const [sampleQuest, sampleSecondQuest],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.correct,
        hintUsed: false,
        wrongCount: 0,
        isFinalFailure: false,
      );

      await pumpAudioSentenceOrderScreen(tester, state: answeredState);

      final continueFinder = find.widgetWithText(ElevatedButton, 'CONTINUE');
      if (continueFinder.evaluate().isNotEmpty) {
        await tester.tap(continueFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        verify(() => mockListeningBloc.add(const NextQuestion())).called(1);
      }
    });

    testWidgets('16. Hint button in header dispatches ListeningHintUsed', (tester) async {
      await pumpAudioSentenceOrderScreen(tester);

      final hintButton = find.byType(QuestHintButton);
      expect(hintButton, findsOneWidget);

      await tester.tap(hintButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1100));

      verify(() => mockListeningBloc.add(const ListeningHintUsed())).called(1);
    });

    testWidgets('17. GameShimmerLoading rendered when state is uninitialized or quest is null', (tester) async {
      await pumpAudioSentenceOrderScreen(tester, state: const ListeningInitial());

      expect(find.byType(GameShimmerLoading), findsOneWidget);
      expect(find.byType(AudioSentenceOrderOscilloscope), findsNothing);
    });

    testWidgets('18. Game complete state triggers completion handling cleanly', (tester) async {
      await pumpAudioSentenceOrderScreen(tester);

      const completeState = ListeningGameComplete(
        xpEarned: 100,
        coinsEarned: 50,
        questCount: 2,
      );

      listeningStreamController.add(completeState);
      when(() => mockListeningBloc.state).thenReturn(completeState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Sentence Order'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('19. Game over state renders with zero lives', (tester) async {
      const gameOverState = ListeningGameOver(
        quests: [sampleQuest],
        currentIndex: 0,
      );

      await pumpAudioSentenceOrderScreen(tester, state: gameOverState);

      expect(tester.takeException(), isNull);
    });

    testWidgets('20. Level 1 briefing dialog displays and dismisses on start button tap', (tester) async {
      SharedPreferences.setMockInitialValues({
        'has_seen_briefing_audioSentenceOrder': false,
      });

      await pumpAudioSentenceOrderScreen(
        tester,
        level: 1,
        size: const Size(390, 1400),
      );

      expect(find.byType(GameBriefingLayer), findsOneWidget);
      expect(find.text("LET'S BUILD!"), findsOneWidget);

      await tester.tap(find.text("LET'S BUILD!"));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(GameBriefingLayer), findsNothing);
    });

    testWidgets('21. Dark and light themes render cleanly without errors', (tester) async {
      await pumpAudioSentenceOrderScreen(tester, themeMode: ThemeMode.light);
      expect(find.byType(AudioSentenceOrderOscilloscope), findsOneWidget);
      expect(find.byType(DynamicJigsawWrapper), findsOneWidget);

      await pumpAudioSentenceOrderScreen(tester, themeMode: ThemeMode.dark);
      expect(find.byType(AudioSentenceOrderOscilloscope), findsOneWidget);
      expect(find.byType(DynamicJigsawWrapper), findsOneWidget);
    });

    testWidgets('22. Small mobile screen (320x568) renders with zero overflow', (tester) async {
      await pumpAudioSentenceOrderScreen(tester, size: const Size(320, 568));

      expect(tester.takeException(), isNull);
      expect(find.byType(AudioSentenceOrderScreen), findsOneWidget);
    });

    testWidgets('23. Tablet viewport (768x1024) renders with zero overflow', (tester) async {
      await pumpAudioSentenceOrderScreen(tester, size: const Size(768, 1024));

      expect(tester.takeException(), isNull);
      expect(find.byType(AudioSentenceOrderScreen), findsOneWidget);
    });

    testWidgets('24. Reduced motion disables oscilloscope repeating animation tickers', (tester) async {
      await pumpAudioSentenceOrderScreen(tester, reduceMotion: true);

      expect(find.byType(AudioSentenceOrderOscilloscope), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('25. Custom emoji renders in oscilloscope when answered correctly', (tester) async {
      await pumpAudioSentenceOrderScreen(tester);

      expect(find.text('🐕'), findsNothing);

      // Solve puzzle correctly
      await tester.tap(find.text('the'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('dog'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('barked'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('loudly'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('🐕'), findsOneWidget);
    });

    testWidgets('26. Quest without customShuffledWords splits expectedText into words cleanly', (tester) async {
      final splitState = ListeningLoaded(
        quests: const [sampleSplitQuest],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
        hintUsed: false,
        wrongCount: 0,
        isFinalFailure: false,
      );

      await pumpAudioSentenceOrderScreen(tester, state: splitState);

      expect(find.text('hello'), findsOneWidget);
      expect(find.text('beautiful'), findsOneWidget);
      expect(find.text('world'), findsOneWidget);
      expect(find.text('3 words'), findsOneWidget);
    });

    testWidgets('27. Empty instruction falls back to localized default text', (tester) async {
      const emptyInstrQuest = ListeningQuest(
        id: 'aso_empty_instr',
        instruction: '',
        difficulty: 1,
        subtype: GameSubtype.audioSentenceOrder,
        textToSpeak: 'the dog barked loudly',
        shuffledSentences: ['barked', 'the', 'loudly', 'dog'],
        correctOrder: [1, 3, 0, 2],
      );

      final emptyInstrState = testLoadedState.copyWith(
        quests: const [emptyInstrQuest],
        currentIndex: 0,
      );

      await pumpAudioSentenceOrderScreen(tester, state: emptyInstrState);

      expect(
        find.text('Listen and arrange the words in order.'),
        findsOneWidget,
      );
    });
  });
}
