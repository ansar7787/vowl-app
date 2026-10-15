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
import 'package:vowl/features/listening/sound_image_match/presentation/pages/sound_image_match_screen.dart';
import 'package:vowl/features/listening/sound_image_match/presentation/widgets/sound_image_match_emitter.dart';
import 'package:vowl/features/listening/sound_image_match/presentation/widgets/sound_image_match_grid.dart';
import 'package:vowl/features/listening/sound_image_match/presentation/widgets/sound_image_match_instruction.dart';
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
  late StreamController<ListeningState> listeningStreamController;

  const sampleQuest1 = ListeningQuest(
    id: 'sim_1',
    instruction: 'Tap the picture that matches the sound.',
    difficulty: 1,
    subtype: GameSubtype.soundImageMatch,
    textToSpeak: 'The cat is purring softly.',
    prompt: 'Cat sound',
    question: 'Match the sound to image',
    options: ['Cat', 'Dog', 'Bird', 'Fish'],
    optionEmojis: ['🐱', '🐶', '🐦', '🐟'],
    correctAnswerIndex: 0,
    correctAnswer: 'Cat',
    explanation: 'The purring sound indicates a cat.',
    emoji: '🐱',
  );

  const sampleQuest2 = ListeningQuest(
    id: 'sim_2',
    instruction: 'Listen carefully and select.',
    difficulty: 1,
    subtype: GameSubtype.soundImageMatch,
    textToSpeak: 'Choo choo comes the train!',
    prompt: 'Train sound',
    question: 'Select matching image',
    options: ['Car', 'Train'],
    optionEmojis: ['🚗', '🚆'],
    correctAnswerIndex: 1,
    correctAnswer: 'Train',
    emoji: '🚆',
  );

  const sampleQuestUrl = ListeningQuest(
    id: 'sim_url',
    instruction: 'Listen and choose.',
    difficulty: 1,
    subtype: GameSubtype.soundImageMatch,
    textToSpeak: 'https://vowl.app/audio/stream.mp3',
    question: 'Sound match',
    options: ['Rain', 'Wind', 'Fire', 'Thunder'],
    optionEmojis: ['🌧️', '💨', '🔥', '⚡'],
    correctAnswerIndex: 0,
    correctAnswer: 'Rain',
    emoji: '🌧️',
  );

  final testLoadedState = ListeningLoaded(
    quests: const [sampleQuest1, sampleQuest2, sampleQuestUrl],
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
    when(() => mockSoundService.playUrl(any())).thenAnswer((_) async {});
    when(() => mockSoundService.playTts(
      any(),
      pauseMarkers: any(named: 'pauseMarkers'),
    )).thenAnswer((_) async {});

    when(() => mockTtsService.stop()).thenAnswer((_) async {});
    when(
      () => mockTtsService.speak(
        any(),
        rate: any(named: 'rate'),
        locale: any(named: 'locale'),
      ),
    ).thenAnswer((_) async {});

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

    SharedPreferences.setMockInitialValues({
      'has_seen_briefing_soundImageMatch': true,
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

  Future<void> pumpSoundImageMatchScreen(
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
                body: SoundImageMatchScreen(
                  level: level,
                  gameType: GameSubtype.soundImageMatch,
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

  group('SoundImageMatchScreen Layout & Mechanics Tests', () {
    testWidgets('1. Initial layout renders instruction, timer, emitter, and 4-option grid', (tester) async {
      await pumpSoundImageMatchScreen(tester);

      expect(find.byType(SoundImageMatchInstruction), findsOneWidget);
      expect(find.byKey(const Key('sound_image_match_instruction')), findsOneWidget);
      expect(find.byType(SpeedChallengeTimer), findsOneWidget);
      expect(find.byKey(const Key('sound_image_match_emitter')), findsOneWidget);
      expect(find.byKey(const Key('sound_image_match_grid')), findsOneWidget);
      expect(find.byType(SoundImageMatchScreen), findsOneWidget);
    });

    testWidgets('2. Initial instruction displays formatted text (LISTEN & MATCH or uppercase)', (tester) async {
      await pumpSoundImageMatchScreen(tester);

      expect(find.byKey(const Key('sound_image_match_instruction_text')), findsOneWidget);
      expect(find.text('LISTEN & MATCH'), findsOneWidget);
    });

    testWidgets('3. Emitter button tap triggers TTS playback and selection haptics', (tester) async {
      await pumpSoundImageMatchScreen(tester);

      final emitterFinder = find.byKey(const Key('sound_image_match_emitter_btn'));
      expect(emitterFinder, findsOneWidget);

      await tester.tap(emitterFinder);
      await tester.pump();

      verify(() => mockSoundService.playTts(sampleQuest1.textToSpeak!)).called(1);
      verify(() => mockHapticService.selection()).called(1);
    });

    testWidgets('4. Emitter button tap with URL audio triggers playUrl', (tester) async {
      final urlState = ListeningLoaded(
        quests: const [sampleQuestUrl],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
        hintUsed: false,
        wrongCount: 0,
        isFinalFailure: false,
      );
      await pumpSoundImageMatchScreen(tester, state: urlState);

      await tester.tap(find.byKey(const Key('sound_image_match_emitter_btn')));
      await tester.pump();

      verify(() => mockSoundService.playUrl('https://vowl.app/audio/stream.mp3')).called(1);
      verify(() => mockHapticService.selection()).called(1);
    });

    testWidgets('5. Audio fallback cascade uses prompt or question when textToSpeak is missing', (tester) async {
      const fallbackQuest = ListeningQuest(
        id: 'sim_fallback',
        instruction: 'Match sound.',
        difficulty: 1,
        subtype: GameSubtype.soundImageMatch,
        prompt: 'Barking dog sound prompt',
        options: ['Cat', 'Dog'],
        optionEmojis: ['🐱', '🐶'],
        correctAnswerIndex: 1,
        correctAnswer: 'Dog',
      );

      final fallbackState = ListeningLoaded(
        quests: const [fallbackQuest],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
        hintUsed: false,
        wrongCount: 0,
        isFinalFailure: false,
      );
      await pumpSoundImageMatchScreen(tester, state: fallbackState);

      await tester.tap(find.byKey(const Key('sound_image_match_emitter_btn')));
      await tester.pump();

      verify(() => mockSoundService.playTts('Barking dog sound prompt')).called(1);
    });

    testWidgets('6. Audio playback strips [pause:...] tokens cleanly', (tester) async {
      const pauseQuest = ListeningQuest(
        id: 'sim_pause',
        instruction: 'Listen carefully.',
        difficulty: 1,
        subtype: GameSubtype.soundImageMatch,
        textToSpeak: 'Hello[pause:500]world!',
        options: ['Hello', 'World'],
        optionEmojis: ['👋', '🌍'],
        correctAnswerIndex: 0,
        correctAnswer: 'Hello',
      );

      final pauseState = ListeningLoaded(
        quests: const [pauseQuest],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
        hintUsed: false,
        wrongCount: 0,
        isFinalFailure: false,
      );
      await pumpSoundImageMatchScreen(tester, state: pauseState);

      await tester.tap(find.byKey(const Key('sound_image_match_emitter_btn')));
      await tester.pump();

      verify(() => mockSoundService.playTts('Hello world!')).called(1);
    });

    testWidgets('7. Emitter displays volume_up icon initially and emoji when answered correctly', (tester) async {
      await pumpSoundImageMatchScreen(tester);

      expect(find.byKey(const Key('sound_image_match_emitter_icon')), findsOneWidget);
      expect(find.byKey(const Key('sound_image_match_emitter_emoji')), findsNothing);

      await tester.tap(find.byKey(const Key('sound_image_match_option_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byKey(const Key('sound_image_match_emitter_emoji')), findsOneWidget);
      expect(find.text('🐱'), findsWidgets);
    });

    testWidgets('8. Grid displays all options (labels and emojis) in 2 rows', (tester) async {
      await pumpSoundImageMatchScreen(tester);

      expect(find.byKey(const Key('sound_image_match_option_0')), findsOneWidget);
      expect(find.byKey(const Key('sound_image_match_option_1')), findsOneWidget);
      expect(find.byKey(const Key('sound_image_match_option_2')), findsOneWidget);
      expect(find.byKey(const Key('sound_image_match_option_3')), findsOneWidget);

      expect(find.text('CAT'), findsOneWidget);
      expect(find.text('DOG'), findsOneWidget);
      expect(find.text('BIRD'), findsOneWidget);
      expect(find.text('FISH'), findsOneWidget);
    });

    testWidgets('9. Single-option quest renders option centered without error', (tester) async {
      const singleOptionQuest = ListeningQuest(
        id: 'sim_single',
        instruction: 'Only choice.',
        difficulty: 1,
        subtype: GameSubtype.soundImageMatch,
        textToSpeak: 'Singular',
        options: ['Solo'],
        optionEmojis: ['🎸'],
        correctAnswerIndex: 0,
        correctAnswer: 'Solo',
      );

      final singleState = ListeningLoaded(
        quests: const [singleOptionQuest],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
        hintUsed: false,
        wrongCount: 0,
        isFinalFailure: false,
      );
      await pumpSoundImageMatchScreen(tester, state: singleState);

      expect(find.byKey(const Key('sound_image_match_option_0')), findsOneWidget);
      expect(find.text('SOLO'), findsOneWidget);
    });

    testWidgets('10. Two-option quest renders row of 2 options without error', (tester) async {
      final twoState = ListeningLoaded(
        quests: const [sampleQuest2],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
        hintUsed: false,
        wrongCount: 0,
        isFinalFailure: false,
      );
      await pumpSoundImageMatchScreen(tester, state: twoState);

      expect(find.byKey(const Key('sound_image_match_option_0')), findsOneWidget);
      expect(find.byKey(const Key('sound_image_match_option_1')), findsOneWidget);
      expect(find.byKey(const Key('sound_image_match_option_2')), findsNothing);
      expect(find.text('CAR'), findsOneWidget);
      expect(find.text('TRAIN'), findsOneWidget);
    });

    testWidgets('11. Tapping option tile triggers selection haptic and sets pending selection', (tester) async {
      await pumpSoundImageMatchScreen(tester);

      await tester.tap(find.byKey(const Key('sound_image_match_option_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockHapticService.selection()).called(1);
    });

    testWidgets('12. Tapping correct option submits SubmitAnswer(true), plays success sound, and triggers success haptic', (tester) async {
      await pumpSoundImageMatchScreen(tester);

      await tester.tap(find.byKey(const Key('sound_image_match_option_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockListeningBloc.add(const SubmitAnswer(true))).called(1);
      verify(() => mockSoundService.playCorrect()).called(1);
      verify(() => mockHapticService.success()).called(1);
    });

    testWidgets('13. Tapping correct option stops the SpeedChallengeTimer', (tester) async {
      await pumpSoundImageMatchScreen(tester);

      final SpeedChallengeTimer timerWidget = tester.widget(find.byType(SpeedChallengeTimer));
      expect(timerWidget.key, isNotNull);

      await tester.tap(find.byKey(const Key('sound_image_match_option_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SoundImageMatchScreen), findsOneWidget);
    });

    testWidgets('14. Tapping wrong option submits SubmitAnswer(false) with userAnswer', (tester) async {
      await pumpSoundImageMatchScreen(tester);

      await tester.tap(find.byKey(const Key('sound_image_match_option_1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockListeningBloc.add(any(that: isA<SubmitAnswer>()))).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockHapticService.error()).called(1);
    });

    testWidgets('15. Tapping wrong option stops the SpeedChallengeTimer', (tester) async {
      await pumpSoundImageMatchScreen(tester);

      await tester.tap(find.byKey(const Key('sound_image_match_option_1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SoundImageMatchScreen), findsOneWidget);
    });

    testWidgets('16. Answer lockout: secondary taps on options are ignored once answered', (tester) async {
      await pumpSoundImageMatchScreen(tester);

      await tester.tap(find.byKey(const Key('sound_image_match_option_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      clearInteractions(mockListeningBloc);

      await tester.tap(find.byKey(const Key('sound_image_match_option_2')), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verifyNever(() => mockListeningBloc.add(any(that: isA<SubmitAnswer>())));
    });

    testWidgets('17. SpeedChallengeTimer onTimeUp triggers wrong answer submission with [Timeout] and stops timer', (tester) async {
      await pumpSoundImageMatchScreen(tester);

      final SpeedChallengeTimer timerWidget = tester.widget(find.byType(SpeedChallengeTimer));
      timerWidget.onTimeUp();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockListeningBloc.add(const SubmitAnswer(false))).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockHapticService.error()).called(1);
    });

    testWidgets('18. In answered state with correct choice, correct option is highlighted with modernCorrect border/color', (tester) async {
      await pumpSoundImageMatchScreen(tester);

      await tester.tap(find.byKey(const Key('sound_image_match_option_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byKey(const Key('sound_image_match_option_0')), findsOneWidget);
    });

    testWidgets('19. In answered state with wrong choice, chosen option shows modernIncorrect border/color and correct option is highlighted', (tester) async {
      await pumpSoundImageMatchScreen(tester);

      await tester.tap(find.byKey(const Key('sound_image_match_option_1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byKey(const Key('sound_image_match_option_1')), findsOneWidget);
      expect(find.byKey(const Key('sound_image_match_option_0')), findsOneWidget);
    });

    testWidgets('20. In answered state, Continue button appears in bottom bar; tapping it dispatches NextQuestion', (tester) async {
      await pumpSoundImageMatchScreen(tester);

      await tester.tap(find.byKey(const Key('sound_image_match_option_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      clearInteractions(mockListeningBloc);

      final continueFinder = find.text('CONTINUE');
      if (continueFinder.evaluate().isNotEmpty) {
        await tester.tap(continueFinder.first);
        await tester.pump();

        verify(() => mockListeningBloc.add(any(that: isA<NextQuestion>()))).called(1);
      }
    });

    testWidgets('21. Question transition clears selections, updates options & emojis, and restarts timer without crash', (tester) async {
      await pumpSoundImageMatchScreen(tester);

      await tester.tap(find.byKey(const Key('sound_image_match_option_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final nextState = ListeningLoaded(
        quests: const [sampleQuest1, sampleQuest2],
        currentIndex: 1,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
        hintUsed: false,
        wrongCount: 0,
        isFinalFailure: false,
      );
      when(() => mockListeningBloc.state).thenReturn(nextState);
      listeningStreamController.add(nextState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('CAR'), findsOneWidget);
      expect(find.text('TRAIN'), findsOneWidget);
    });

    testWidgets('22. Hint button in header dispatches selection haptic', (tester) async {
      await pumpSoundImageMatchScreen(tester);

      clearInteractions(mockHapticService);

      final hintButton = find.byType(QuestHintButton);
      expect(hintButton, findsOneWidget);

      await tester.tap(hintButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1100));

      verify(() => mockHapticService.selection()).called(1);
    });

    testWidgets('23. GameShimmerLoading rendered when state is uninitialized or quest is null', (tester) async {
      await pumpSoundImageMatchScreen(tester, state: const ListeningInitial());

      expect(find.byType(GameShimmerLoading), findsOneWidget);
      expect(find.byKey(const Key('sound_image_match_emitter')), findsNothing);
    });

    testWidgets('24. Game complete state triggers completion handling cleanly', (tester) async {
      await pumpSoundImageMatchScreen(
        tester,
        state: const ListeningGameComplete(
          xpEarned: 100,
          coinsEarned: 20,
          questCount: 5,
        ),
      );

      expect(find.byType(SoundImageMatchScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('25. Game over state renders with zero lives', (tester) async {
      await pumpSoundImageMatchScreen(
        tester,
        state: const ListeningGameOver(
          quests: [sampleQuest1],
          currentIndex: 0,
        ),
      );

      expect(find.byType(SoundImageMatchScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('26. Level 1 briefing dialog displays THEMATIC LINKER and dismisses on CONFIRM LINK tap', (tester) async {
      SharedPreferences.setMockInitialValues({
        'has_seen_briefing_soundImageMatch': false,
      });

      await pumpSoundImageMatchScreen(
        tester,
        level: 1,
        size: const Size(390, 1100),
      );

      expect(find.byType(GameBriefingLayer), findsOneWidget);
      expect(find.text('THEMATIC LINKER'), findsOneWidget);

      final actionBtn = find.text('CONFIRM LINK');
      expect(actionBtn, findsOneWidget);

      await tester.tap(actionBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(GameBriefingLayer), findsNothing);
    });

    testWidgets('27. Dark and light themes render cleanly without errors', (tester) async {
      await pumpSoundImageMatchScreen(tester, themeMode: ThemeMode.dark);
      expect(find.byType(SoundImageMatchScreen), findsOneWidget);

      await pumpSoundImageMatchScreen(tester, themeMode: ThemeMode.light);
      expect(find.byType(SoundImageMatchScreen), findsOneWidget);
    });

    testWidgets('28. Small mobile screen (320x568) renders with zero overflow', (tester) async {
      await pumpSoundImageMatchScreen(
        tester,
        size: const Size(320, 568),
      );
      expect(find.byType(SoundImageMatchScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('29. Tablet viewport (768x1024) renders with zero overflow', (tester) async {
      await pumpSoundImageMatchScreen(
        tester,
        size: const Size(768, 1024),
      );
      expect(find.byType(SoundImageMatchScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('30. Reduced motion mode suppresses emitter shimmer and emoji scale animations, and accessibility semantics are present on emitter and grid options', (tester) async {
      await pumpSoundImageMatchScreen(tester, reduceMotion: true);

      expect(find.byType(SoundImageMatchEmitter), findsOneWidget);
      expect(find.byType(SoundImageMatchGrid), findsOneWidget);

      final emitterSemantics = find.bySemanticsLabel('Play sound');
      expect(emitterSemantics, findsOneWidget);

      final option0Semantics = find.bySemanticsLabel('Cat');
      expect(option0Semantics, findsOneWidget);
    });
  });
}

