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
import 'package:vowl/features/listening/detail_spotlight/presentation/pages/detail_spotlight_screen.dart';
import 'package:vowl/features/listening/detail_spotlight/presentation/widgets/detail_spotlight_dark_field.dart';
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
    id: 'ds_1',
    instruction: 'Wipe and tap what you hear in the audio.',
    difficulty: 1,
    subtype: GameSubtype.detailSpotlight,
    textToSpeak: 'The golden key was hidden inside the wooden chest.',
    prompt: 'golden key',
    targetDetail: 'golden key',
    options: ['silver coin', 'golden key', 'wooden door', 'brass bell'],
    correctAnswerIndex: 1,
    correctAnswer: 'golden key',
    emoji: '🔑',
    hint: 'Listen carefully for the key description.',
    explanation: 'The narrator mentions a golden key in the chest.',
  );

  const sampleQuest2 = ListeningQuest(
    id: 'ds_2',
    instruction: 'Find the hidden detail mentioned in the story.',
    difficulty: 1,
    subtype: GameSubtype.detailSpotlight,
    textToSpeak: 'https://example.com/audio/secret_map.mp3',
    prompt: 'secret map',
    targetDetail: 'secret map',
    options: ['compass', 'secret map', 'lantern', 'telescope'],
    correctAnswerIndex: 1,
    correctAnswer: 'secret map',
    emoji: '🗺️',
    hint: 'Listen for the navigational tool.',
    explanation: 'A secret map was discovered.',
  );

  const sampleQuest3 = ListeningQuest(
    id: 'ds_3',
    instruction: 'Identify the object.',
    difficulty: 1,
    subtype: GameSubtype.detailSpotlight,
    prompt: 'iron shield',
    targetDetail: 'iron shield',
    options: ['bronze sword', 'iron shield', 'helmet', 'bow'],
    correctAnswerIndex: 1,
    correctAnswer: 'iron shield',
    emoji: '🛡️',
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
      'has_seen_briefing_detailSpotlight': true,
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

  Future<void> pumpDetailSpotlightScreen(
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
                body: DetailSpotlightScreen(
                  level: level,
                  gameType: GameSubtype.detailSpotlight,
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

  group('DetailSpotlightScreen Layout & Mechanics Tests', () {
    testWidgets('1. Initial layout renders instruction, timer, emitter, prompt, and dark field', (tester) async {
      await pumpDetailSpotlightScreen(tester);

      expect(find.byType(SpeedChallengeTimer), findsOneWidget);
      expect(find.byKey(const Key('detail_spotlight_instruction')), findsOneWidget);
      expect(find.byKey(const Key('detail_spotlight_emitter')), findsOneWidget);
      expect(find.byKey(const Key('detail_spotlight_prompt')), findsOneWidget);
      expect(find.byKey(const Key('detail_spotlight_dark_field')), findsOneWidget);
    });

    testWidgets('2. Initial prompt displays scan text before answered', (tester) async {
      await pumpDetailSpotlightScreen(tester);

      expect(find.text('SCAN FOR AUDITORY TARGET'), findsOneWidget);
      expect(find.textContaining('TARGET:'), findsNothing);
    });

    testWidgets('3. Emitter button tap triggers TTS playback and selection haptic', (tester) async {
      await pumpDetailSpotlightScreen(tester);

      final emitterBtn = find.byKey(const Key('detail_spotlight_emitter_btn'));
      expect(emitterBtn, findsOneWidget);

      await tester.tap(emitterBtn);
      await tester.pump();

      verify(() => mockSoundService.playTts(
        'The golden key was hidden inside the wooden chest.',
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

      await pumpDetailSpotlightScreen(tester, state: urlState);

      final emitterBtn = find.byKey(const Key('detail_spotlight_emitter_btn'));
      await tester.tap(emitterBtn);
      await tester.pump();

      verify(() => mockSoundService.playUrl('https://example.com/audio/secret_map.mp3')).called(1);
      verify(() => mockHapticService.selection()).called(1);
    });

    testWidgets('5. Audio fallback cascade uses prompt when textToSpeak is missing', (tester) async {
      final fallbackState = ListeningLoaded(
        quests: const [sampleQuest3],
        currentIndex: 0,
        livesRemaining: 3,
      );

      await pumpDetailSpotlightScreen(tester, state: fallbackState);

      final emitterBtn = find.byKey(const Key('detail_spotlight_emitter_btn'));
      await tester.tap(emitterBtn);
      await tester.pump();

      verify(() => mockSoundService.playTts('iron shield', pauseMarkers: any(named: 'pauseMarkers'))).called(1);
      verify(() => mockHapticService.selection()).called(1);
    });

    testWidgets('6. Emitter displays volume icon initially and emoji when answered correctly', (tester) async {
      await pumpDetailSpotlightScreen(tester);

      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
      expect(find.byKey(const Key('detail_spotlight_emoji')), findsNothing);

      // Select correct answer
      await tester.tap(find.byKey(const Key('detail_spotlight_tile_1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const Key('detail_spotlight_emoji')), findsOneWidget);
      expect(find.text('🔑'), findsOneWidget);
    });

    testWidgets('7. Dark field displays all 4 option tiles', (tester) async {
      await pumpDetailSpotlightScreen(tester);

      expect(find.byKey(const Key('detail_spotlight_tile_0')), findsOneWidget);
      expect(find.byKey(const Key('detail_spotlight_tile_1')), findsOneWidget);
      expect(find.byKey(const Key('detail_spotlight_tile_2')), findsOneWidget);
      expect(find.byKey(const Key('detail_spotlight_tile_3')), findsOneWidget);

      expect(find.text('silver coin'), findsOneWidget);
      expect(find.text('golden key'), findsOneWidget);
      expect(find.text('wooden door'), findsOneWidget);
      expect(find.text('brass bell'), findsOneWidget);
    });

    testWidgets('8. Dragging in dark field updates spotlight position', (tester) async {
      await pumpDetailSpotlightScreen(tester);

      final darkFieldFinder = find.byKey(const Key('detail_spotlight_dark_field'));
      expect(darkFieldFinder, findsOneWidget);

      final gesture = await tester.startGesture(tester.getCenter(darkFieldFinder));
      await gesture.moveBy(const Offset(40, -30));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('9. Moving spotlight over an option triggers light haptic', (tester) async {
      await pumpDetailSpotlightScreen(tester);

      final darkFieldFinder = find.byKey(const Key('detail_spotlight_dark_field'));
      final topLeft = tester.getTopLeft(darkFieldFinder);

      // Drag to top-left tile area (around tile 0: x=16, y=40)
      final gesture = await tester.startGesture(tester.getCenter(darkFieldFinder));
      await gesture.moveTo(topLeft + const Offset(50, 80));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      verify(() => mockHapticService.light()).called(greaterThanOrEqualTo(1));
    });

    testWidgets('10. Tapping correct option tile submits correct answer, plays sound, and triggers haptic', (tester) async {
      await pumpDetailSpotlightScreen(tester);

      final correctTile = find.byKey(const Key('detail_spotlight_tile_1'));
      expect(correctTile, findsOneWidget);

      await tester.tap(correctTile);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockHapticService.selection()).called(1);
      verify(() => mockListeningBloc.add(const SubmitAnswer(true))).called(1);
      verify(() => mockSoundService.playCorrect()).called(1);
      verify(() => mockHapticService.success()).called(1);
    });

    testWidgets('11. Tapping correct option tile stops the SpeedChallengeTimer', (tester) async {
      await pumpDetailSpotlightScreen(tester);

      final timerState = tester.state<SpeedChallengeTimerState>(find.byType(SpeedChallengeTimer));
      expect(timerState.remainingSeconds, greaterThan(0));

      await tester.tap(find.byKey(const Key('detail_spotlight_tile_1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(timerState.remainingSeconds, greaterThan(0));
      expect(tester.takeException(), isNull);
    });

    testWidgets('12. Tapping wrong option tile submits wrong answer with userAnswer', (tester) async {
      await pumpDetailSpotlightScreen(tester);

      final wrongTile = find.byKey(const Key('detail_spotlight_tile_0'));
      expect(wrongTile, findsOneWidget);

      await tester.tap(wrongTile);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockHapticService.selection()).called(1);
      verify(() => mockListeningBloc.add(const SubmitAnswer(false))).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockHapticService.error()).called(1);
    });

    testWidgets('13. Tapping wrong option tile stops the SpeedChallengeTimer', (tester) async {
      await pumpDetailSpotlightScreen(tester);

      await tester.tap(find.byKey(const Key('detail_spotlight_tile_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull);
    });

    testWidgets('14. Answer lockout: secondary taps on options are ignored', (tester) async {
      await pumpDetailSpotlightScreen(tester);

      // Tap first tile
      await tester.tap(find.byKey(const Key('detail_spotlight_tile_1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      clearInteractions(mockListeningBloc);

      // Tap second tile
      await tester.tap(find.byKey(const Key('detail_spotlight_tile_2')), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verifyNever(() => mockListeningBloc.add(any(that: isA<SubmitAnswer>())));
    });

    testWidgets('15. SpeedChallengeTimer onTimeUp triggers wrong answer submission with [Timeout]', (tester) async {
      await pumpDetailSpotlightScreen(tester);

      final SpeedChallengeTimer timerWidget = tester.widget(find.byType(SpeedChallengeTimer));
      timerWidget.onTimeUp();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockListeningBloc.add(const SubmitAnswer(false))).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockHapticService.error()).called(1);
    });

    testWidgets('16. In answered state, prompt reveals target detail', (tester) async {
      await pumpDetailSpotlightScreen(tester);

      await tester.tap(find.byKey(const Key('detail_spotlight_tile_1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('TARGET: GOLDEN KEY'), findsOneWidget);
    });

    testWidgets('17. In answered state, correct option tile is highlighted', (tester) async {
      await pumpDetailSpotlightScreen(tester);

      await tester.tap(find.byKey(const Key('detail_spotlight_tile_1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final tileFinder = find.byKey(const Key('detail_spotlight_tile_1'));
      expect(tileFinder, findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('18. In answered state with wrong choice, chosen tile shows wrong state', (tester) async {
      await pumpDetailSpotlightScreen(tester);

      await tester.tap(find.byKey(const Key('detail_spotlight_tile_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final wrongTileFinder = find.byKey(const Key('detail_spotlight_tile_0'));
      expect(wrongTileFinder, findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('19. Continue button in answered state dispatches NextQuestion event', (tester) async {
      await pumpDetailSpotlightScreen(tester);

      await tester.tap(find.byKey(const Key('detail_spotlight_tile_1')));
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

    testWidgets('20. Question transition clears selected indices and restarts timer without crash', (tester) async {
      await pumpDetailSpotlightScreen(tester);

      await tester.tap(find.byKey(const Key('detail_spotlight_tile_1')));
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

      expect(find.text('compass'), findsOneWidget);
      expect(find.text('secret map'), findsOneWidget);
      expect(find.text('SCAN FOR AUDITORY TARGET'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('21. Hint button in header dispatches ListeningHintUsed', (tester) async {
      await pumpDetailSpotlightScreen(tester);

      clearInteractions(mockListeningBloc);

      final hintButton = find.byType(QuestHintButton);
      expect(hintButton, findsOneWidget);

      await tester.tap(hintButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1100));

      verify(() => mockListeningBloc.add(any(that: isA<ListeningHintUsed>()))).called(1);
    });

    testWidgets('22. GameShimmerLoading rendered when state is uninitialized or quest is null', (tester) async {
      await pumpDetailSpotlightScreen(tester, state: const ListeningInitial());

      expect(find.byType(GameShimmerLoading), findsOneWidget);
      expect(find.byKey(const Key('detail_spotlight_emitter')), findsNothing);
    });

    testWidgets('23. Game complete state triggers completion handling cleanly', (tester) async {
      await pumpDetailSpotlightScreen(
        tester,
        state: const ListeningGameComplete(
          xpEarned: 100,
          coinsEarned: 20,
          questCount: 5,
        ),
      );

      expect(find.byType(DetailSpotlightScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('24. Game over state renders with zero lives', (tester) async {
      await pumpDetailSpotlightScreen(
        tester,
        state: const ListeningGameOver(
          quests: [sampleQuest1],
          currentIndex: 0,
        ),
      );

      expect(find.byType(DetailSpotlightScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('25. Level 1 briefing dialog displays SPOTLIGHT SEARCH and dismisses on START SEARCH tap', (tester) async {
      SharedPreferences.setMockInitialValues({
        'has_seen_briefing_detailSpotlight': false,
      });

      await pumpDetailSpotlightScreen(
        tester,
        level: 1,
        size: const Size(390, 1100),
      );

      expect(find.byType(GameBriefingLayer), findsOneWidget);
      expect(find.text('SPOTLIGHT SEARCH'), findsOneWidget);

      final actionBtn = find.text('START SEARCH');
      expect(actionBtn, findsOneWidget);

      await tester.tap(actionBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(GameBriefingLayer), findsNothing);
    });

    testWidgets('26. Dark and light themes render cleanly without errors', (tester) async {
      await pumpDetailSpotlightScreen(tester, themeMode: ThemeMode.dark);
      expect(find.byType(DetailSpotlightScreen), findsOneWidget);

      await pumpDetailSpotlightScreen(tester, themeMode: ThemeMode.light);
      expect(find.byType(DetailSpotlightScreen), findsOneWidget);
    });

    testWidgets('27. Small mobile screen (320x568) renders with zero overflow', (tester) async {
      await pumpDetailSpotlightScreen(
        tester,
        size: const Size(320, 568),
      );

      expect(find.byType(DetailSpotlightScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('28. Tablet viewport (768x1024) renders with zero overflow', (tester) async {
      await pumpDetailSpotlightScreen(
        tester,
        size: const Size(768, 1024),
      );

      expect(find.byType(DetailSpotlightScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('29. Reduced motion mode suppresses animated flare in dark field', (tester) async {
      await pumpDetailSpotlightScreen(tester, reduceMotion: true);

      expect(find.byType(DetailSpotlightDarkField), findsOneWidget);
      expect(find.byIcon(Icons.flare_rounded), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('30. Accessibility semantics are present on emitter and option tiles', (tester) async {
      await pumpDetailSpotlightScreen(tester);

      final emitterSemantics = find.bySemanticsLabel('Play audio detail');
      expect(emitterSemantics, findsOneWidget);

      final option0Semantics = find.bySemanticsLabel('silver coin');
      expect(option0Semantics, findsOneWidget);

      final option1Semantics = find.bySemanticsLabel('golden key');
      expect(option1Semantics, findsOneWidget);
    });
  });
}

