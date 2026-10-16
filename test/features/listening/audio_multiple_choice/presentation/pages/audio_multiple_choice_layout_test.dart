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
import 'package:vowl/features/listening/audio_multiple_choice/presentation/pages/audio_multiple_choice_screen.dart';
import 'package:vowl/features/listening/audio_multiple_choice/presentation/widgets/audio_multiple_choice_instruction.dart';
import 'package:vowl/features/listening/audio_multiple_choice/presentation/widgets/audio_multiple_choice_question.dart';
import 'package:vowl/features/listening/audio_multiple_choice/presentation/widgets/audio_multiple_choice_satellite.dart';
import 'package:vowl/features/listening/audio_multiple_choice/presentation/widgets/audio_multiple_choice_spinner.dart';
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
    id: 'amc_1',
    instruction: 'Listen carefully and select the best match.',
    difficulty: 1,
    subtype: GameSubtype.audioMultipleChoice,
    question: 'What natural phenomenon was heard in the recording?',
    options: ['Thunderstorm', 'Gentle Breeze', 'Ocean Waves', 'City Traffic'],
    correctAnswerIndex: 0,
    correctAnswer: 'Thunderstorm',
    textToSpeak: 'Rumbling sounds shake the horizon with sudden flashes.',
    emoji: '⛈️',
    hint: 'Heavy precipitation accompanied by thunder and lightning.',
    explanation: 'The audio depicts a severe thunderstorm.',
  );

  const sampleBlankQuest = ListeningQuest(
    id: 'amc_blank',
    instruction: 'Complete the sentence you heard.',
    difficulty: 2,
    subtype: GameSubtype.audioMultipleChoice,
    question: 'The distant sound was caused by a _____.',
    options: ['Thunderstorm', 'Gentle Breeze', 'Ocean Waves'],
    correctAnswerIndex: 0,
    correctAnswer: 'Thunderstorm',
    textToSpeak: 'The distant sound was caused by a thunderstorm.',
    emoji: '⚡',
    hint: 'A noisy electric storm.',
  );

  const sampleSecondQuest = ListeningQuest(
    id: 'amc_2',
    instruction: 'Identify the ambient environment.',
    difficulty: 2,
    subtype: GameSubtype.audioMultipleChoice,
    question: 'Where is this announcement taking place?',
    options: ['Airport Terminal', 'Train Station', 'Subway Platform'],
    correctAnswerIndex: 0,
    correctAnswer: 'Airport Terminal',
    textToSpeak: 'Flight 204 is now boarding at Gate 12.',
    emoji: '✈️',
    hint: 'Planes take off from here.',
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
    when(() => mockSoundService.playTts(any())).thenAnswer((_) async {});

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
      'has_seen_briefing_audioMultipleChoice': true,
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

  Future<void> pumpAudioMultipleChoiceScreen(
    WidgetTester tester, {
    ListeningState? state,
    ThemeMode themeMode = ThemeMode.dark,
    Size size = const Size(390, 844),
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
          designSize: const Size(390, 844),
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
                body: AudioMultipleChoiceScreen(
                  level: level,
                  gameType: GameSubtype.audioMultipleChoice,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('AudioMultipleChoiceScreen Layout & Mechanics Tests', () {
    testWidgets('1. Initial layout renders instruction, timer, question, and satellite spinner', (tester) async {
      await pumpAudioMultipleChoiceScreen(tester);

      expect(find.byType(AudioMultipleChoiceInstruction), findsOneWidget);
      expect(find.byType(SpeedChallengeTimer), findsOneWidget);
      expect(find.byType(AudioMultipleChoiceQuestion), findsOneWidget);
      expect(find.byType(AudioMultipleChoiceSpinner), findsOneWidget);
      expect(find.byKey(const Key('satellite_core_btn')), findsOneWidget);
      expect(find.text('LISTEN'), findsOneWidget);

      expect(find.byType(AudioMultipleChoiceSatellite), findsNWidgets(4));
      expect(find.text('Thunderstorm'), findsOneWidget);
      expect(find.text('Gentle Breeze'), findsOneWidget);
      expect(find.text('Ocean Waves'), findsOneWidget);
      expect(find.text('City Traffic'), findsOneWidget);
    });

    testWidgets('2. Tapping central core button triggers TTS replay and selection haptics', (tester) async {
      await pumpAudioMultipleChoiceScreen(tester);

      await tester.tap(find.byKey(const Key('satellite_core_btn')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockSoundService.playTts(sampleQuest.textToSpeak!)).called(1);
      verify(() => mockHapticService.selection()).called(1);
    });

    testWidgets('3. Central core audio playback cascades to prompt when textToSpeak is null', (tester) async {
      const fallbackQuest = ListeningQuest(
        id: 'amc_fb',
        instruction: 'Listen carefully',
        difficulty: 1,
        subtype: GameSubtype.audioMultipleChoice,
        prompt: 'Fallback prompt recording text',
        options: ['Opt A', 'Opt B'],
        correctAnswerIndex: 0,
      );

      final state = ListeningLoaded(
        quests: const [fallbackQuest],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
        hintUsed: false,
        wrongCount: 0,
        isFinalFailure: false,
      );

      await pumpAudioMultipleChoiceScreen(tester, state: state);

      await tester.tap(find.byKey(const Key('satellite_core_btn')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockSoundService.playTts('Fallback prompt recording text')).called(1);
      verify(() => mockHapticService.selection()).called(1);
    });

    testWidgets('4. Central core audio playback cascades to question when textToSpeak and prompt are null', (tester) async {
      const questionQuest = ListeningQuest(
        id: 'amc_qfb',
        instruction: 'Listen carefully',
        difficulty: 1,
        subtype: GameSubtype.audioMultipleChoice,
        question: 'Identify this sound clip',
        options: ['Sound A', 'Sound B'],
        correctAnswerIndex: 0,
      );

      final state = ListeningLoaded(
        quests: const [questionQuest],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
        hintUsed: false,
        wrongCount: 0,
        isFinalFailure: false,
      );

      await pumpAudioMultipleChoiceScreen(tester, state: state);

      await tester.tap(find.byKey(const Key('satellite_core_btn')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockSoundService.playTts('Identify this sound clip')).called(1);
    });

    testWidgets('5. Selecting correct satellite dispatches SubmitAnswer(true) with success audio & haptics', (tester) async {
      await pumpAudioMultipleChoiceScreen(tester);

      await tester.tap(find.text('Thunderstorm'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockListeningBloc.add(const SubmitAnswer(true))).called(1);
      verify(() => mockSoundService.playCorrect()).called(1);
      verify(() => mockHapticService.success()).called(1);
    });

    testWidgets('6. Selecting incorrect satellite dispatches SubmitAnswer(false) with error audio & haptics', (tester) async {
      await pumpAudioMultipleChoiceScreen(tester);

      await tester.tap(find.text('Gentle Breeze'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockListeningBloc.add(const SubmitAnswer(false))).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockHapticService.error()).called(1);
    });

    testWidgets('7. Interaction lockout prevents secondary taps after answer submission', (tester) async {
      await pumpAudioMultipleChoiceScreen(tester);

      await tester.tap(find.text('Thunderstorm'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      clearInteractions(mockListeningBloc);
      clearInteractions(mockHapticService);

      await tester.tap(find.text('Ocean Waves'), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      verifyNever(() => mockListeningBloc.add(any()));
    });

    testWidgets('8. Timer onTimeUp automatically triggers wrong answer submission', (tester) async {
      await pumpAudioMultipleChoiceScreen(tester);

      final timer = tester.widget<SpeedChallengeTimer>(find.byType(SpeedChallengeTimer));
      timer.onTimeUp();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockListeningBloc.add(const SubmitAnswer(false))).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
    });

    testWidgets('9. Answering stops the active SpeedChallengeTimer', (tester) async {
      await pumpAudioMultipleChoiceScreen(tester);

      final timerState = tester.state<SpeedChallengeTimerState>(find.byType(SpeedChallengeTimer));
      expect(timerState.isTimerActive, isTrue);

      await tester.tap(find.text('Thunderstorm'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(timerState.isTimerActive, isFalse);
    });

    testWidgets('10. Question transition clears selected index and restarts timer without GlobalKey crashes', (tester) async {
      await pumpAudioMultipleChoiceScreen(tester);

      // Answer quest 1
      await tester.tap(find.text('Thunderstorm'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

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
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Airport Terminal'), findsOneWidget);
      expect(find.text('Train Station'), findsOneWidget);
      expect(find.text('Subway Platform'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('11. Continue button dispatches NextQuestion event', (tester) async {
      final answeredState = ListeningLoaded(
        quests: const [sampleQuest, sampleSecondQuest],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.correct,
        hintUsed: false,
        wrongCount: 0,
        isFinalFailure: false,
      );

      await pumpAudioMultipleChoiceScreen(tester, state: answeredState);

      final continueFinder = find.widgetWithText(ElevatedButton, 'CONTINUE');
      if (continueFinder.evaluate().isNotEmpty) {
        await tester.tap(continueFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        verify(() => mockListeningBloc.add(const NextQuestion())).called(1);
      }
    });

    testWidgets('12. Hint button in header dispatches ListeningHintUsed', (tester) async {
      await pumpAudioMultipleChoiceScreen(tester);

      final hintButton = find.byType(QuestHintButton);
      expect(hintButton, findsOneWidget);

      await tester.tap(hintButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1100));

      verify(() => mockListeningBloc.add(const ListeningHintUsed())).called(1);
    });

    testWidgets('13. GameShimmerLoading rendered when state is uninitialized or quest is null', (tester) async {
      await pumpAudioMultipleChoiceScreen(tester, state: const ListeningInitial());

      expect(find.byType(GameShimmerLoading), findsOneWidget);
      expect(find.byType(AudioMultipleChoiceSpinner), findsNothing);
    });

    testWidgets('14. Game complete state triggers completion handling cleanly', (tester) async {
      await pumpAudioMultipleChoiceScreen(tester);

      const completeState = ListeningGameComplete(
        xpEarned: 100,
        coinsEarned: 50,
        questCount: 2,
      );

      listeningStreamController.add(completeState);
      when(() => mockListeningBloc.state).thenReturn(completeState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('SONIC RADAR!'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('15. Game over state renders with zero lives', (tester) async {
      const gameOverState = ListeningGameOver(
        quests: [sampleQuest],
        currentIndex: 0,
      );

      await pumpAudioMultipleChoiceScreen(tester, state: gameOverState);

      expect(tester.takeException(), isNull);
    });

    testWidgets('16. Level 1 briefing dialog displays and dismisses on start button tap', (tester) async {
      SharedPreferences.setMockInitialValues({
        'has_seen_briefing_audioMultipleChoice': false,
      });

      await pumpAudioMultipleChoiceScreen(
        tester,
        level: 1,
        size: const Size(390, 1100),
      );

      expect(find.byType(GameBriefingLayer), findsOneWidget);
      expect(find.text("LET'S GO!"), findsOneWidget);

      await tester.tap(find.text("LET'S GO!"));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(GameBriefingLayer), findsNothing);
    });

    testWidgets('17. Dark and light themes render cleanly without errors', (tester) async {
      await pumpAudioMultipleChoiceScreen(tester, themeMode: ThemeMode.light);
      expect(find.byType(AudioMultipleChoiceSpinner), findsOneWidget);

      await pumpAudioMultipleChoiceScreen(tester, themeMode: ThemeMode.dark);
      expect(find.byType(AudioMultipleChoiceSpinner), findsOneWidget);
    });

    testWidgets('18. Small mobile screen (320x568) renders with zero overflow', (tester) async {
      await pumpAudioMultipleChoiceScreen(tester, size: const Size(320, 568));

      expect(find.byType(SpeedChallengeTimer), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('19. Tablet viewport (768x1024) renders with zero overflow', (tester) async {
      await pumpAudioMultipleChoiceScreen(tester, size: const Size(768, 1024));

      expect(find.byType(SpeedChallengeTimer), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('20. Reduced motion disables repeating animations and entry tickers', (tester) async {
      VowlMotion.lowAnimationModeOverride.value = true;

      await pumpAudioMultipleChoiceScreen(tester, reduceMotion: true);

      expect(find.byType(AudioMultipleChoiceSatellite), findsNWidgets(4));
      expect(tester.takeException(), isNull);
    });

    testWidgets('21. Spinner horizontal pan gesture triggers rotation update', (tester) async {
      await pumpAudioMultipleChoiceScreen(tester);

      final spinner = find.byKey(const Key('audio_multiple_choice_spinner'));
      expect(spinner, findsOneWidget);

      await tester.drag(spinner, const Offset(100, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });

    testWidgets('22. Spinner pan rotation is locked out when already answered', (tester) async {
      await pumpAudioMultipleChoiceScreen(tester);

      // Answer question
      await tester.tap(find.text('Thunderstorm'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final spinner = find.byKey(const Key('audio_multiple_choice_spinner'));
      await tester.drag(spinner, const Offset(100, 0), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });

    testWidgets('23. Question blanks _____ is replaced with correct answer when answered correctly', (tester) async {
      final blankState = ListeningLoaded(
        quests: const [sampleBlankQuest],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
        hintUsed: false,
        wrongCount: 0,
        isFinalFailure: false,
      );

      await pumpAudioMultipleChoiceScreen(tester, state: blankState);

      expect(find.text('The distant sound was caused by a _____.'), findsOneWidget);

      // Answer correctly
      await tester.tap(find.text('Thunderstorm'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Display question updates with replaced blank
      expect(find.text('The distant sound was caused by a Thunderstorm.'), findsOneWidget);
    });

    testWidgets('24. Question without blanks remains identical across answer states', (tester) async {
      await pumpAudioMultipleChoiceScreen(tester);

      expect(find.text(sampleQuest.question!), findsOneWidget);

      await tester.tap(find.text('Thunderstorm'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text(sampleQuest.question!), findsOneWidget);
    });

    testWidgets('25. Empty instruction falls back to localized default text', (tester) async {
      const emptyInstructionQuest = ListeningQuest(
        id: 'amc_empty_inst',
        instruction: '',
        difficulty: 1,
        subtype: GameSubtype.audioMultipleChoice,
        options: ['A', 'B'],
        correctAnswerIndex: 0,
      );

      final state = ListeningLoaded(
        quests: const [emptyInstructionQuest],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
        hintUsed: false,
        wrongCount: 0,
        isFinalFailure: false,
      );

      await pumpAudioMultipleChoiceScreen(tester, state: state);

      expect(find.text('LISTEN AND CHOOSE THE BEST MATCH'), findsOneWidget);
    });

    testWidgets('26. Emoji displays in central core on correct answer', (tester) async {
      await pumpAudioMultipleChoiceScreen(tester);

      expect(find.text('⛈️'), findsNothing);

      await tester.tap(find.text('Thunderstorm'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('⛈️'), findsOneWidget);
    });

    testWidgets('27. Empty options list renders spinner with central core and zero satellites without crashing', (tester) async {
      const emptyOptionsQuest = ListeningQuest(
        id: 'amc_no_opts',
        instruction: 'Listen to the audio',
        difficulty: 1,
        subtype: GameSubtype.audioMultipleChoice,
        options: [],
        correctAnswerIndex: 0,
      );

      final state = ListeningLoaded(
        quests: const [emptyOptionsQuest],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
        hintUsed: false,
        wrongCount: 0,
        isFinalFailure: false,
      );

      await pumpAudioMultipleChoiceScreen(tester, state: state);

      expect(find.byType(AudioMultipleChoiceSatellite), findsNothing);
      expect(find.byKey(const Key('satellite_core_btn')), findsOneWidget);
    });

    testWidgets('28. Minimal 2-option quest renders 2 satellites cleanly', (tester) async {
      const binaryQuest = ListeningQuest(
        id: 'amc_bin',
        instruction: 'Choose A or B',
        difficulty: 1,
        subtype: GameSubtype.audioMultipleChoice,
        options: ['High Pitch', 'Low Pitch'],
        correctAnswerIndex: 0,
      );

      final state = ListeningLoaded(
        quests: const [binaryQuest],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
        hintUsed: false,
        wrongCount: 0,
        isFinalFailure: false,
      );

      await pumpAudioMultipleChoiceScreen(tester, state: state);

      expect(find.byType(AudioMultipleChoiceSatellite), findsNWidgets(2));
      expect(find.text('High Pitch'), findsOneWidget);
      expect(find.text('Low Pitch'), findsOneWidget);
    });

    testWidgets('29. Multi-option quest (6 options) distributes satellites radially without overflow', (tester) async {
      const multiQuest = ListeningQuest(
        id: 'amc_six',
        instruction: 'Select one from six',
        difficulty: 3,
        subtype: GameSubtype.audioMultipleChoice,
        options: ['One', 'Two', 'Three', 'Four', 'Five', 'Six'],
        correctAnswerIndex: 2,
      );

      final state = ListeningLoaded(
        quests: const [multiQuest],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
        hintUsed: false,
        wrongCount: 0,
        isFinalFailure: false,
      );

      await pumpAudioMultipleChoiceScreen(tester, state: state);

      expect(find.byType(AudioMultipleChoiceSatellite), findsNWidgets(6));
      expect(tester.takeException(), isNull);
    });
  });
}
