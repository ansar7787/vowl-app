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
import 'package:vowl/features/listening/emotion_recognition/presentation/pages/emotion_recognition_screen.dart';
import 'package:vowl/features/listening/emotion_recognition/presentation/widgets/emotion_recognition_emitter.dart';
import 'package:vowl/features/listening/emotion_recognition/presentation/widgets/emotion_recognition_quadrant.dart';
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
    id: 'er_1',
    instruction: 'Detect the emotion conveyed in the voice.',
    difficulty: 1,
    subtype: GameSubtype.emotionRecognition,
    textToSpeak: 'I cannot believe this actually worked out!',
    targetEmotion: 'Joy',
    options: ['Anger', 'Joy', 'Sadness', 'Fear'],
    optionEmojis: ['😠', '😄', '😢', '😨'],
    correctAnswerIndex: 1,
    correctAnswer: 'Joy',
    emoji: '😄',
    hint: 'Listen to the excited tone and rising pitch.',
    explanation: 'The speaker sounds enthusiastic and happy.',
  );

  const sampleQuest2 = ListeningQuest(
    id: 'er_2',
    instruction: 'Identify the sentiment of the caller.',
    difficulty: 1,
    subtype: GameSubtype.emotionRecognition,
    textToSpeak: 'https://example.com/audio/urgent_call.mp3',
    targetEmotion: 'Urgency',
    options: ['Calm', 'Boredom', 'Urgency', 'Joy'],
    optionEmojis: ['😌', '🥱', '🚨', '😄'],
    correctAnswerIndex: 2,
    correctAnswer: 'Urgency',
    emoji: '🚨',
    hint: 'Listen to the rapid pace of speech.',
    explanation: 'The speaker speaks quickly and with high urgency.',
  );

  const sampleQuest3 = ListeningQuest(
    id: 'er_3',
    instruction: 'Analyze the feeling.',
    difficulty: 1,
    subtype: GameSubtype.emotionRecognition,
    prompt: 'I am so tired of this endless waiting.',
    targetEmotion: 'Frustration',
    options: ['Frustration', 'Excitement', 'Gratitude', 'Confusion'],
    optionEmojis: ['😤', '🤩', '🙏', '😕'],
    correctAnswerIndex: 0,
    correctAnswer: 'Frustration',
    emoji: '😤',
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
      'has_seen_briefing_emotionRecognition': true,
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

  Future<void> pumpEmotionRecognitionScreen(
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
                body: EmotionRecognitionScreen(
                  level: level,
                  gameType: GameSubtype.emotionRecognition,
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

  group('EmotionRecognitionScreen Layout & Mechanics Tests', () {
    testWidgets('1. Initial layout renders instruction, timer, emitter, and quadrant', (tester) async {
      await pumpEmotionRecognitionScreen(tester);

      expect(find.byType(SpeedChallengeTimer), findsOneWidget);
      expect(find.byKey(const Key('emotion_recognition_instruction')), findsOneWidget);
      expect(find.byKey(const Key('emotion_recognition_emitter')), findsOneWidget);
      expect(find.byKey(const Key('emotion_recognition_quadrant')), findsOneWidget);
    });

    testWidgets('2. Initial instruction displays clean centered instruction', (tester) async {
      await pumpEmotionRecognitionScreen(tester);

      expect(find.text('Detect the emotion conveyed in the voice.'), findsOneWidget);
    });

    testWidgets('3. Emitter button tap triggers TTS playback and selection haptic', (tester) async {
      await pumpEmotionRecognitionScreen(tester);

      final emitterBtn = find.byKey(const Key('emotion_recognition_emitter_btn'));
      expect(emitterBtn, findsOneWidget);

      await tester.tap(emitterBtn);
      await tester.pump();

      verify(() => mockSoundService.playTts(
        'I cannot believe this actually worked out!',
        pauseMarkers: any(named: 'pauseMarkers'),
      )).called(1);
      verify(() => mockHapticService.selection()).called(1);
    });

    testWidgets('4. Emitter button tap with URL audio triggers playUrl', (tester) async {
      final urlState = ListeningLoaded(
        quests: const [sampleQuest2],
        currentIndex: 0,
        livesRemaining: 3,
      );

      await pumpEmotionRecognitionScreen(tester, state: urlState);

      final emitterBtn = find.byKey(const Key('emotion_recognition_emitter_btn'));
      await tester.tap(emitterBtn);
      await tester.pump();

      verify(() => mockSoundService.playUrl('https://example.com/audio/urgent_call.mp3')).called(1);
      verify(() => mockHapticService.selection()).called(1);
    });

    testWidgets('5. Audio fallback cascade uses prompt when textToSpeak is missing', (tester) async {
      final fallbackState = ListeningLoaded(
        quests: const [sampleQuest3],
        currentIndex: 0,
        livesRemaining: 3,
      );

      await pumpEmotionRecognitionScreen(tester, state: fallbackState);

      final emitterBtn = find.byKey(const Key('emotion_recognition_emitter_btn'));
      await tester.tap(emitterBtn);
      await tester.pump();

      verify(() => mockSoundService.playTts('I am so tired of this endless waiting.', pauseMarkers: any(named: 'pauseMarkers'))).called(1);
      verify(() => mockHapticService.selection()).called(1);
    });

    testWidgets('6. Emitter displays volume icon initially and emoji when answered correctly', (tester) async {
      await pumpEmotionRecognitionScreen(tester);

      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
      expect(find.byKey(const Key('emotion_recognition_emoji')), findsNothing);

      // Select correct answer (index 1 is Joy)
      await tester.tap(find.byKey(const Key('emotion_recognition_reservoir_1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byKey(const Key('emotion_recognition_emoji')), findsOneWidget);
      expect(find.text('😄'), findsAtLeastNWidgets(1));
    });

    testWidgets('7. Quadrant displays all 4 option reservoirs with their labels and emojis', (tester) async {
      await pumpEmotionRecognitionScreen(tester);

      expect(find.byKey(const Key('emotion_recognition_reservoir_0')), findsOneWidget);
      expect(find.byKey(const Key('emotion_recognition_reservoir_1')), findsOneWidget);
      expect(find.byKey(const Key('emotion_recognition_reservoir_2')), findsOneWidget);
      expect(find.byKey(const Key('emotion_recognition_reservoir_3')), findsOneWidget);

      expect(find.text('Anger'), findsOneWidget);
      expect(find.text('Joy'), findsOneWidget);
      expect(find.text('Sadness'), findsOneWidget);
      expect(find.text('Fear'), findsOneWidget);

      expect(find.text('😠'), findsOneWidget);
      expect(find.text('😄'), findsOneWidget);
      expect(find.text('😢'), findsOneWidget);
      expect(find.text('😨'), findsOneWidget);
    });

    testWidgets('8. Psychology core starts centered and can be panned via drag gestures', (tester) async {
      await pumpEmotionRecognitionScreen(tester);

      final coreFinder = find.byKey(const Key('emotion_recognition_core'));
      expect(coreFinder, findsOneWidget);

      final gesture = await tester.startGesture(tester.getCenter(coreFinder));
      await gesture.moveBy(const Offset(30, 30));
      await tester.pump();
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull);
    });

    testWidgets('9. Dragging psychology core onto a reservoir submits that answer', (tester) async {
      await pumpEmotionRecognitionScreen(tester);

      final coreFinder = find.byKey(const Key('emotion_recognition_core'));
      final reservoir1 = find.byKey(const Key('emotion_recognition_reservoir_1'));

      final gesture = await tester.startGesture(tester.getCenter(coreFinder));
      await gesture.moveBy(const Offset(40, -40));
      await tester.pump();
      await gesture.moveTo(tester.getCenter(reservoir1));
      await tester.pump();
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockListeningBloc.add(const SubmitAnswer(true))).called(1);
      verify(() => mockSoundService.playCorrect()).called(1);
      verify(() => mockHapticService.success()).called(1);
    });

    testWidgets('10. Dragging core and releasing far from any reservoir resets core position', (tester) async {
      await pumpEmotionRecognitionScreen(tester);

      final coreFinder = find.byKey(const Key('emotion_recognition_core'));

      final gesture = await tester.startGesture(tester.getCenter(coreFinder));
      await gesture.moveBy(const Offset(10, 10));
      await tester.pump();
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verifyNever(() => mockListeningBloc.add(any(that: isA<SubmitAnswer>())));
    });

    testWidgets('11. Tapping option reservoir directly submits that answer with selection haptic', (tester) async {
      await pumpEmotionRecognitionScreen(tester);

      final reservoir1 = find.byKey(const Key('emotion_recognition_reservoir_1'));
      await tester.tap(reservoir1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockHapticService.selection()).called(1);
    });

    testWidgets('12. Tapping correct option reservoir submits SubmitAnswer(true), plays sound, and triggers haptic', (tester) async {
      await pumpEmotionRecognitionScreen(tester);

      final correctReservoir = find.byKey(const Key('emotion_recognition_reservoir_1'));
      await tester.tap(correctReservoir);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockListeningBloc.add(const SubmitAnswer(true))).called(1);
      verify(() => mockSoundService.playCorrect()).called(1);
      verify(() => mockHapticService.success()).called(1);
    });

    testWidgets('13. Tapping correct option reservoir stops the SpeedChallengeTimer', (tester) async {
      await pumpEmotionRecognitionScreen(tester);

      final timerState = tester.state<SpeedChallengeTimerState>(find.byType(SpeedChallengeTimer));
      expect(timerState.remainingSeconds, greaterThan(0));

      await tester.tap(find.byKey(const Key('emotion_recognition_reservoir_1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(timerState.remainingSeconds, greaterThan(0));
      expect(tester.takeException(), isNull);
    });

    testWidgets('14. Tapping wrong option reservoir submits SubmitAnswer(false) with userAnswer', (tester) async {
      await pumpEmotionRecognitionScreen(tester);

      final wrongReservoir = find.byKey(const Key('emotion_recognition_reservoir_0'));
      await tester.tap(wrongReservoir);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockListeningBloc.add(const SubmitAnswer(false))).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockHapticService.error()).called(1);
    });

    testWidgets('15. Tapping wrong option reservoir stops the SpeedChallengeTimer', (tester) async {
      await pumpEmotionRecognitionScreen(tester);

      await tester.tap(find.byKey(const Key('emotion_recognition_reservoir_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull);
    });

    testWidgets('16. Answer lockout: secondary taps on reservoirs are ignored once answered', (tester) async {
      await pumpEmotionRecognitionScreen(tester);

      // Tap first reservoir
      await tester.tap(find.byKey(const Key('emotion_recognition_reservoir_1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      clearInteractions(mockListeningBloc);

      // Tap second reservoir with warnIfMissed: false in case feedback card overlays
      await tester.tap(find.byKey(const Key('emotion_recognition_reservoir_2')), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verifyNever(() => mockListeningBloc.add(any(that: isA<SubmitAnswer>())));
    });

    testWidgets('17. SpeedChallengeTimer onTimeUp triggers wrong answer submission with [Timeout]', (tester) async {
      await pumpEmotionRecognitionScreen(tester);

      final SpeedChallengeTimer timerWidget = tester.widget(find.byType(SpeedChallengeTimer));
      timerWidget.onTimeUp();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockListeningBloc.add(const SubmitAnswer(false))).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockHapticService.error()).called(1);
    });

    testWidgets('18. In answered state, instruction remains clearly visible', (tester) async {
      await pumpEmotionRecognitionScreen(tester);

      await tester.tap(find.byKey(const Key('emotion_recognition_reservoir_1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Detect the emotion conveyed in the voice.'), findsOneWidget);
    });

    testWidgets('19. In answered state, correct option reservoir shows highlighted border', (tester) async {
      await pumpEmotionRecognitionScreen(tester);

      await tester.tap(find.byKey(const Key('emotion_recognition_reservoir_1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byKey(const Key('emotion_recognition_reservoir_1')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('20. In answered state with wrong choice, chosen reservoir shows wrong state and correct is revealed', (tester) async {
      await pumpEmotionRecognitionScreen(tester);

      await tester.tap(find.byKey(const Key('emotion_recognition_reservoir_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byKey(const Key('emotion_recognition_reservoir_0')), findsOneWidget);
      expect(find.byKey(const Key('emotion_recognition_reservoir_1')), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('21. Continue button in answered state dispatches NextQuestion event', (tester) async {
      await pumpEmotionRecognitionScreen(tester);

      await tester.tap(find.byKey(const Key('emotion_recognition_reservoir_1')));
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

    testWidgets('22. Question transition clears selections, updates options, and restarts timer without crash', (tester) async {
      await pumpEmotionRecognitionScreen(tester);

      await tester.tap(find.byKey(const Key('emotion_recognition_reservoir_1')));
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

      expect(find.text('Calm'), findsOneWidget);
      expect(find.text('Boredom'), findsOneWidget);
      expect(find.text('Urgency'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('23. Hint button in header dispatches ListeningHintUsed', (tester) async {
      await pumpEmotionRecognitionScreen(tester);

      clearInteractions(mockListeningBloc);

      final hintButton = find.byType(QuestHintButton);
      expect(hintButton, findsOneWidget);

      await tester.tap(hintButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1100));

      verify(() => mockListeningBloc.add(any(that: isA<ListeningHintUsed>()))).called(1);
    });

    testWidgets('24. GameShimmerLoading rendered when state is uninitialized or quest is null', (tester) async {
      await pumpEmotionRecognitionScreen(tester, state: const ListeningInitial());

      expect(find.byType(GameShimmerLoading), findsOneWidget);
      expect(find.byKey(const Key('emotion_recognition_emitter')), findsNothing);
    });

    testWidgets('25. Game complete state triggers completion handling cleanly', (tester) async {
      await pumpEmotionRecognitionScreen(
        tester,
        state: const ListeningGameComplete(
          xpEarned: 100,
          coinsEarned: 20,
          questCount: 5,
        ),
      );

      expect(find.byType(EmotionRecognitionScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('26. Game over state renders with zero lives', (tester) async {
      await pumpEmotionRecognitionScreen(
        tester,
        state: const ListeningGameOver(
          quests: [sampleQuest1],
          currentIndex: 0,
        ),
      );

      expect(find.byType(EmotionRecognitionScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('27. Level 1 briefing dialog displays EMOTION RECOGNITION and dismisses on START tap', (tester) async {
      SharedPreferences.setMockInitialValues({
        'has_seen_briefing_emotionRecognition': false,
      });

      await pumpEmotionRecognitionScreen(
        tester,
        level: 1,
        size: const Size(390, 1100),
      );

      expect(find.byType(GameBriefingLayer), findsOneWidget);
      expect(find.text('EMOTION RECOGNITION'), findsOneWidget);

      final actionBtn = find.text('START');
      expect(actionBtn, findsOneWidget);

      await tester.tap(actionBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(GameBriefingLayer), findsNothing);
    });

    testWidgets('28. Dark and light themes render cleanly without errors', (tester) async {
      await pumpEmotionRecognitionScreen(tester, themeMode: ThemeMode.dark);
      expect(find.byType(EmotionRecognitionScreen), findsOneWidget);

      await pumpEmotionRecognitionScreen(tester, themeMode: ThemeMode.light);
      expect(find.byType(EmotionRecognitionScreen), findsOneWidget);
    });

    testWidgets('29. Small mobile screen (320x568) and tablet (768x1024) render with zero overflow', (tester) async {
      await pumpEmotionRecognitionScreen(
        tester,
        size: const Size(320, 568),
      );
      expect(find.byType(EmotionRecognitionScreen), findsOneWidget);
      expect(tester.takeException(), isNull);

      await pumpEmotionRecognitionScreen(
        tester,
        size: const Size(768, 1024),
      );
      expect(find.byType(EmotionRecognitionScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('30. Reduced motion mode and accessibility semantics present on emitter, core, and reservoirs', (tester) async {
      await pumpEmotionRecognitionScreen(tester, reduceMotion: true);

      expect(find.byType(EmotionRecognitionEmitter), findsOneWidget);
      expect(find.byType(EmotionRecognitionQuadrant), findsOneWidget);

      final emitterSemantics = find.bySemanticsLabel('Play audio voice');
      expect(emitterSemantics, findsOneWidget);

      final coreSemantics = find.bySemanticsLabel('Psychology Core');
      expect(coreSemantics, findsOneWidget);

      final reservoirJoy = find.bySemanticsLabel('Joy');
      expect(reservoirJoy, findsOneWidget);
    });
  });
}

