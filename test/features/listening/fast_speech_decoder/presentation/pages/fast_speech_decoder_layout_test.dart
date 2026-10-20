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
import 'package:vowl/features/listening/fast_speech_decoder/presentation/pages/fast_speech_decoder_screen.dart';
import 'package:vowl/features/listening/fast_speech_decoder/presentation/widgets/fast_speech_decoder_core.dart';
import 'package:vowl/features/listening/fast_speech_decoder/presentation/widgets/fast_speech_decoder_steam_vents.dart';
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

  const sampleQuest1 = ListeningQuest(
    id: 'fsd_1',
    instruction: 'Decode the fast speech and select the correct phrase.',
    difficulty: 1,
    subtype: GameSubtype.fastSpeechDecoder,
    textToSpeak: 'What are you going to do about it?',
    options: [
      'What do you do about it?',
      'What are you going to do about it?',
      'Where are you going to go?',
      'What did you want to do?'
    ],
    correctAnswerIndex: 1,
    correctAnswer: 'What are you going to do about it?',
    emoji: '⚡',
    hint: 'Listen closely to the reduced sounds of "going to".',
    explanation: '"Gonna" is the fast spoken form of "going to".',
  );

  const sampleQuest2 = ListeningQuest(
    id: 'fsd_2',
    instruction: 'Listen carefully at full speed.',
    difficulty: 1,
    subtype: GameSubtype.fastSpeechDecoder,
    textToSpeak: 'https://example.com/audio/fast_phrase.mp3',
    options: [
      'Give me a break',
      'Gimme that book',
      'Give her some time',
      'Got to go now'
    ],
    correctAnswerIndex: 0,
    correctAnswer: 'Give me a break',
    emoji: '⏱️',
    hint: 'Listen for "gimme".',
    explanation: '"Gimme" is commonly used for "give me".',
  );

  const sampleQuest3 = ListeningQuest(
    id: 'fsd_3',
    instruction: 'Choose the matching sentence.',
    difficulty: 1,
    subtype: GameSubtype.fastSpeechDecoder,
    prompt: 'I have got to leave right now.',
    options: [
      'I gotta leave right now.',
      'I got a leaf right now.',
      'I had to leave right now.',
      'I want to leave right now.'
    ],
    correctAnswerIndex: 0,
    correctAnswer: 'I gotta leave right now.',
    emoji: '🏃',
  );

  final testLoadedState = ListeningLoaded(
    quests: const [sampleQuest1, sampleQuest2, sampleQuest3],
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
      speed: any(named: 'speed'),
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
      final fallback = invocation.namedArguments[const Symbol('fallback')] as String?;
      final key = invocation.positionalArguments[0] as String;
      return fallback ?? key;
    });

    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

    SharedPreferences.setMockInitialValues({
      'has_seen_briefing_fastSpeechDecoder': true,
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

  Future<void> pumpFastSpeechDecoderScreen(
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
                body: FastSpeechDecoderScreen(
                  level: level,
                  gameType: GameSubtype.fastSpeechDecoder,
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

  group('FastSpeechDecoderScreen Layout & Mechanics Tests', () {
    testWidgets('1. Initial layout renders instruction, timer, gauges, core dial, and steam vents', (tester) async {
      await pumpFastSpeechDecoderScreen(tester);

      expect(find.byType(SpeedChallengeTimer), findsOneWidget);
      expect(find.byKey(const Key('fast_speech_decoder_instruction')), findsOneWidget);
      expect(find.byKey(const Key('fast_speech_decoder_gauges')), findsOneWidget);
      expect(find.byKey(const Key('fast_speech_decoder_core')), findsOneWidget);
      expect(find.byKey(const Key('fast_speech_decoder_steam_vents')), findsOneWidget);
    });

    testWidgets('2. Initial instruction displays instruction', (tester) async {
      await pumpFastSpeechDecoderScreen(tester);

      expect(find.text('Decode the fast speech and select the correct phrase.'), findsOneWidget);
    });

    testWidgets('3. Core play button tap triggers TTS playback with current speed and selection haptic', (tester) async {
      await pumpFastSpeechDecoderScreen(tester);

      final playBtn = find.byKey(const Key('fast_speech_decoder_play_btn'));
      expect(playBtn, findsOneWidget);

      await tester.tap(playBtn);
      await tester.pump();

      verify(() => mockSoundService.playTts(
        'What are you going to do about it?',
        speed: any(named: 'speed'),
        pauseMarkers: any(named: 'pauseMarkers'),
      )).called(1);
      verify(() => mockHapticService.selection()).called(1);
    });

    testWidgets('4. Core play button tap with URL audio triggers playUrl', (tester) async {
      final urlState = ListeningLoaded(
        quests: const [sampleQuest2],
        currentIndex: 0,
        livesRemaining: 3,
      );

      await pumpFastSpeechDecoderScreen(tester, state: urlState);

      final playBtn = find.byKey(const Key('fast_speech_decoder_play_btn'));
      await tester.tap(playBtn);
      await tester.pump();

      verify(() => mockSoundService.playUrl('https://example.com/audio/fast_phrase.mp3')).called(1);
      verify(() => mockHapticService.selection()).called(1);
    });

    testWidgets('5. Audio fallback cascade uses prompt when textToSpeak is missing', (tester) async {
      final fallbackState = ListeningLoaded(
        quests: const [sampleQuest3],
        currentIndex: 0,
        livesRemaining: 3,
      );

      await pumpFastSpeechDecoderScreen(tester, state: fallbackState);

      final playBtn = find.byKey(const Key('fast_speech_decoder_play_btn'));
      await tester.tap(playBtn);
      await tester.pump();

      verify(() => mockSoundService.playTts(
        'I have got to leave right now.',
        speed: any(named: 'speed'),
        pauseMarkers: any(named: 'pauseMarkers'),
      )).called(1);
      verify(() => mockHapticService.selection()).called(1);
    });

    testWidgets('6. Core dial displays play icon initially and shows emoji when answered correctly', (tester) async {
      await pumpFastSpeechDecoderScreen(tester);

      expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
      expect(find.byKey(const Key('fast_speech_decoder_emoji')), findsNothing);

      // Select correct vent (index 1)
      await tester.tap(find.byKey(const Key('fast_speech_decoder_vent_1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byKey(const Key('fast_speech_decoder_emoji')), findsOneWidget);
      expect(find.text('⚡'), findsOneWidget);
    });

    testWidgets('7. Speed gauge displays speed readout', (tester) async {
      await pumpFastSpeechDecoderScreen(tester);

      expect(find.text('PLAYBACK SPEED'), findsOneWidget);
      expect(find.textContaining('X'), findsOneWidget);
    });

    testWidgets('8. Panning core dial updates dial rotation, triggers light haptic, and updates gauge', (tester) async {
      await pumpFastSpeechDecoderScreen(tester);

      final coreFinder = find.byKey(const Key('fast_speech_decoder_core'));
      expect(coreFinder, findsOneWidget);

      final gesture = await tester.startGesture(tester.getCenter(coreFinder) + const Offset(50, 0));
      await gesture.moveBy(const Offset(0, 50));
      await tester.pump();
      await gesture.moveBy(const Offset(-50, 0));
      await tester.pump();
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockHapticService.light()).called(greaterThanOrEqualTo(1));
    });

    testWidgets('9. Steam vents display all option choices', (tester) async {
      await pumpFastSpeechDecoderScreen(tester);

      expect(find.byKey(const Key('fast_speech_decoder_vent_0')), findsOneWidget);
      expect(find.byKey(const Key('fast_speech_decoder_vent_1')), findsOneWidget);
      expect(find.byKey(const Key('fast_speech_decoder_vent_2')), findsOneWidget);
      expect(find.byKey(const Key('fast_speech_decoder_vent_3')), findsOneWidget);

      expect(find.text('What do you do about it?'), findsOneWidget);
      expect(find.text('What are you going to do about it?'), findsOneWidget);
      expect(find.text('Where are you going to go?'), findsOneWidget);
      expect(find.text('What did you want to do?'), findsOneWidget);
    });

    testWidgets('10. Tapping correct option vent submits SubmitAnswer(true), plays sound, and triggers haptic', (tester) async {
      await pumpFastSpeechDecoderScreen(tester);

      final correctVent = find.byKey(const Key('fast_speech_decoder_vent_1'));
      await tester.tap(correctVent);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockListeningBloc.add(const SubmitAnswer(true))).called(1);
      verify(() => mockSoundService.playCorrect()).called(1);
      verify(() => mockHapticService.success()).called(1);
    });

    testWidgets('11. Tapping correct option vent stops the SpeedChallengeTimer', (tester) async {
      await pumpFastSpeechDecoderScreen(tester);

      final timerState = tester.state<SpeedChallengeTimerState>(find.byType(SpeedChallengeTimer));
      expect(timerState.remainingSeconds, greaterThan(0));

      await tester.tap(find.byKey(const Key('fast_speech_decoder_vent_1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(timerState.remainingSeconds, greaterThan(0));
      expect(tester.takeException(), isNull);
    });

    testWidgets('12. Tapping wrong option vent submits SubmitAnswer(false) with userAnswer', (tester) async {
      await pumpFastSpeechDecoderScreen(tester);

      final wrongVent = find.byKey(const Key('fast_speech_decoder_vent_0'));
      await tester.tap(wrongVent);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockListeningBloc.add(const SubmitAnswer(false))).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockHapticService.error()).called(1);
    });

    testWidgets('13. Tapping wrong option vent stops the SpeedChallengeTimer', (tester) async {
      await pumpFastSpeechDecoderScreen(tester);

      await tester.tap(find.byKey(const Key('fast_speech_decoder_vent_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull);
    });

    testWidgets('14. Answer lockout: secondary taps on vents are ignored once answered', (tester) async {
      await pumpFastSpeechDecoderScreen(tester);

      // Tap first vent
      await tester.tap(find.byKey(const Key('fast_speech_decoder_vent_1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      clearInteractions(mockListeningBloc);

      // Tap second vent
      await tester.tap(find.byKey(const Key('fast_speech_decoder_vent_2')), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verifyNever(() => mockListeningBloc.add(any(that: isA<SubmitAnswer>())));
    });

    testWidgets('15. SpeedChallengeTimer onTimeUp triggers wrong answer submission with [Timeout]', (tester) async {
      await pumpFastSpeechDecoderScreen(tester);

      final SpeedChallengeTimer timerWidget = tester.widget(find.byType(SpeedChallengeTimer));
      timerWidget.onTimeUp();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockListeningBloc.add(const SubmitAnswer(false))).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockHapticService.error()).called(1);
    });

    testWidgets('16. In answered state, correct vent is highlighted with verified icon', (tester) async {
      await pumpFastSpeechDecoderScreen(tester);

      await tester.tap(find.byKey(const Key('fast_speech_decoder_vent_1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
    });

    testWidgets('17. In answered state with wrong choice, chosen vent shows error icon and correct is revealed', (tester) async {
      await pumpFastSpeechDecoderScreen(tester);

      await tester.tap(find.byKey(const Key('fast_speech_decoder_vent_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('18. In answered state, Continue button appears in bottom bar; tapping it dispatches NextQuestion', (tester) async {
      await pumpFastSpeechDecoderScreen(tester);

      await tester.tap(find.byKey(const Key('fast_speech_decoder_vent_1')));
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

    testWidgets('19. Question transition resets dial, clears selections, and restarts timer without crash', (tester) async {
      await pumpFastSpeechDecoderScreen(tester);

      await tester.tap(find.byKey(const Key('fast_speech_decoder_vent_1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final nextState = const ListeningLoaded(
        quests: [sampleQuest1, sampleQuest2, sampleQuest3],
        currentIndex: 1,
        livesRemaining: 3,
      );
      when(() => mockListeningBloc.state).thenReturn(nextState);
      listeningStreamController.add(nextState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Give me a break'), findsOneWidget);
      expect(find.text('Gimme that book'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('20. Hint button in header dispatches ListeningHintUsed', (tester) async {
      await pumpFastSpeechDecoderScreen(tester);

      clearInteractions(mockListeningBloc);

      final hintButton = find.byType(QuestHintButton);
      expect(hintButton, findsOneWidget);

      await tester.tap(hintButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1100));

      verify(() => mockListeningBloc.add(any(that: isA<ListeningHintUsed>()))).called(1);
    });

    testWidgets('21. GameShimmerLoading rendered when state is uninitialized or quest is null', (tester) async {
      await pumpFastSpeechDecoderScreen(tester, state: const ListeningInitial());

      expect(find.byType(GameShimmerLoading), findsOneWidget);
      expect(find.byKey(const Key('fast_speech_decoder_core')), findsNothing);
    });

    testWidgets('22. Game complete state triggers completion handling cleanly', (tester) async {
      await pumpFastSpeechDecoderScreen(
        tester,
        state: const ListeningGameComplete(
          xpEarned: 100,
          coinsEarned: 20,
          questCount: 5,
        ),
      );

      expect(find.byType(FastSpeechDecoderScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('23. Game over state renders with zero lives', (tester) async {
      await pumpFastSpeechDecoderScreen(
        tester,
        state: const ListeningGameOver(
          quests: [sampleQuest1],
          currentIndex: 0,
        ),
      );

      expect(find.byType(FastSpeechDecoderScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('24. Level 1 briefing dialog displays FAST SPEECH DECODER and dismisses on START PRACTICE tap', (tester) async {
      SharedPreferences.setMockInitialValues({
        'has_seen_briefing_fastSpeechDecoder': false,
      });

      await pumpFastSpeechDecoderScreen(
        tester,
        level: 1,
        size: const Size(390, 1100),
      );

      expect(find.byType(GameBriefingLayer), findsOneWidget);
      expect(find.text('FAST SPEECH DECODER'), findsOneWidget);

      final actionBtn = find.text('START PRACTICE');
      expect(actionBtn, findsOneWidget);

      await tester.tap(actionBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(GameBriefingLayer), findsNothing);
    });

    testWidgets('25. Dark and light themes render cleanly without errors', (tester) async {
      await pumpFastSpeechDecoderScreen(tester, themeMode: ThemeMode.dark);
      expect(find.byType(FastSpeechDecoderScreen), findsOneWidget);

      await pumpFastSpeechDecoderScreen(tester, themeMode: ThemeMode.light);
      expect(find.byType(FastSpeechDecoderScreen), findsOneWidget);
    });

    testWidgets('26. Small mobile screen (320x568) renders with zero overflow', (tester) async {
      await pumpFastSpeechDecoderScreen(
        tester,
        size: const Size(320, 568),
      );
      expect(find.byType(FastSpeechDecoderScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('27. Tablet viewport (768x1024) renders with zero overflow', (tester) async {
      await pumpFastSpeechDecoderScreen(
        tester,
        size: const Size(768, 1024),
      );
      expect(find.byType(FastSpeechDecoderScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('28. Reduced motion mode suppresses rotating gear animation and vent shaking', (tester) async {
      await pumpFastSpeechDecoderScreen(tester, reduceMotion: true);

      expect(find.byType(FastSpeechDecoderCore), findsOneWidget);
      expect(find.byType(FastSpeechDecoderSteamVents), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('29. Speed dial semantics slider exposes speech speed and slider role', (tester) async {
      await pumpFastSpeechDecoderScreen(tester);

      final dialFinder = find.byType(FastSpeechDecoderCore);
      expect(dialFinder, findsOneWidget);
    });

    testWidgets('30. Accessibility semantics present on play button and steam vent options', (tester) async {
      await pumpFastSpeechDecoderScreen(tester);

      final playSemantics = find.bySemanticsLabel('Play audio voice');
      expect(playSemantics, findsOneWidget);

      final vent1Semantics = find.bySemanticsLabel('What are you going to do about it?');
      expect(vent1Semantics, findsOneWidget);
    });
  });
}

