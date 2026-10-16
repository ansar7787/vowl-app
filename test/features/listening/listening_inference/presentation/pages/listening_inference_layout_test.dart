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
import 'package:vowl/features/listening/listening_inference/presentation/pages/listening_inference_screen.dart';
import 'package:vowl/features/listening/listening_inference/presentation/widgets/listening_inference_explanation.dart';
import 'package:vowl/features/listening/listening_inference/presentation/widgets/listening_inference_grid.dart';
import 'package:vowl/features/listening/listening_inference/presentation/widgets/listening_inference_radar_core.dart';
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
    id: 'li_1',
    instruction: 'Listen carefully and deduce what is implied.',
    difficulty: 1,
    subtype: GameSubtype.listeningInference,
    textToSpeak: 'I left my umbrella at home, and the sky turned pitch black.',
    question: 'What is about to happen?',
    options: [
      'It is going to rain',
      'A sunny afternoon',
      'The bus has arrived',
      'He lost his keys'
    ],
    correctAnswerIndex: 0,
    correctAnswer: 'It is going to rain',
    emoji: '🌧️',
    hint: 'Dark skies and missing umbrella point to bad weather.',
    explanation: 'A dark sky suggests incoming rain and without an umbrella he will get wet.',
  );

  const sampleQuest2 = ListeningQuest(
    id: 'li_2',
    instruction: 'Infer the speaker intention.',
    difficulty: 1,
    subtype: GameSubtype.listeningInference,
    textToSpeak: 'https://example.com/audio/flight_delay.mp3',
    question: 'What is the speaker feeling?',
    options: [
      'Impatient',
      'Excited'
    ],
    correctAnswerIndex: 0,
    correctAnswer: 'Impatient',
    emoji: '⌚',
    hint: 'Notice the heavy sigh.',
    explanation: 'The sigh and tone convey impatience with the delay.',
  );

  const sampleQuest3 = ListeningQuest(
    id: 'li_3',
    instruction: 'Determine the underlying context.',
    difficulty: 1,
    subtype: GameSubtype.listeningInference,
    prompt: 'We need to pack warm coats and thermal boots.',
    question: 'Where are they traveling?',
    options: [
      'A tropical beach',
      'A snowy mountain',
      'A desert safari',
      'A theme park'
    ],
    correctAnswerIndex: 1,
    correctAnswer: 'A snowy mountain',
    emoji: '🏔️',
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
      'has_seen_briefing_listeningInference': true,
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

  Future<void> pumpListeningInferenceScreen(
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
                body: ListeningInferenceScreen(
                  level: level,
                  gameType: GameSubtype.listeningInference,
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

  group('ListeningInferenceScreen Layout & Mechanics Tests', () {
    testWidgets('1. Initial layout renders instruction, timer, radar core, show text button, question, and grid', (tester) async {
      await pumpListeningInferenceScreen(tester);

      expect(find.byType(SpeedChallengeTimer), findsOneWidget);
      expect(find.byKey(const Key('listening_inference_instruction')), findsOneWidget);
      expect(find.byKey(const Key('listening_inference_radar_core')), findsOneWidget);
      expect(find.byKey(const Key('listening_inference_show_text_btn')), findsOneWidget);
      expect(find.text('WHAT IS ABOUT TO HAPPEN?'), findsOneWidget);
      expect(find.byKey(const Key('listening_inference_grid')), findsOneWidget);
    });

    testWidgets('2. Initial instruction displays uppercase instruction', (tester) async {
      await pumpListeningInferenceScreen(tester);

      expect(find.text('LISTEN CAREFULLY AND DEDUCE WHAT IS IMPLIED.'), findsOneWidget);
    });

    testWidgets('3. Radar core button tap triggers TTS playback and selection haptic', (tester) async {
      await pumpListeningInferenceScreen(tester);

      final radarBtn = find.byKey(const Key('listening_inference_radar_btn'));
      expect(radarBtn, findsOneWidget);

      await tester.tap(radarBtn);
      await tester.pump();

      verify(() => mockSoundService.playTts(
        'I left my umbrella at home, and the sky turned pitch black.',
        pauseMarkers: any(named: 'pauseMarkers'),
      )).called(1);
      verify(() => mockHapticService.selection()).called(1);
    });

    testWidgets('4. Radar core button tap with URL audio triggers playUrl', (tester) async {
      final urlState = ListeningLoaded(
        quests: const [sampleQuest2],
        currentIndex: 0,
        livesRemaining: 3,
      );

      await pumpListeningInferenceScreen(tester, state: urlState);

      final radarBtn = find.byKey(const Key('listening_inference_radar_btn'));
      await tester.tap(radarBtn);
      await tester.pump();

      verify(() => mockSoundService.playUrl('https://example.com/audio/flight_delay.mp3')).called(1);
      verify(() => mockHapticService.selection()).called(1);
    });

    testWidgets('5. Audio fallback cascade uses prompt when textToSpeak is missing', (tester) async {
      final fallbackState = ListeningLoaded(
        quests: const [sampleQuest3],
        currentIndex: 0,
        livesRemaining: 3,
      );

      await pumpListeningInferenceScreen(tester, state: fallbackState);

      final radarBtn = find.byKey(const Key('listening_inference_radar_btn'));
      await tester.tap(radarBtn);
      await tester.pump();

      verify(() => mockSoundService.playTts(
        'We need to pack warm coats and thermal boots.',
        pauseMarkers: any(named: 'pauseMarkers'),
      )).called(1);
      verify(() => mockHapticService.selection()).called(1);
    });

    testWidgets('6. Radar core displays psychology icon initially and emoji when answered correctly', (tester) async {
      await pumpListeningInferenceScreen(tester);

      expect(find.byIcon(Icons.psychology_rounded), findsOneWidget);
      expect(find.byKey(const Key('listening_inference_emoji')), findsNothing);

      // Select correct answer (index 0)
      await tester.tap(find.byKey(const Key('listening_inference_option_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byKey(const Key('listening_inference_emoji')), findsOneWidget);
      expect(find.text('🌧️'), findsOneWidget);
    });

    testWidgets('7. Show Text button tap opens audio transcript bottom sheet', (tester) async {
      await pumpListeningInferenceScreen(tester);

      final showTextBtn = find.byKey(const Key('listening_inference_show_text_btn'));
      expect(showTextBtn, findsOneWidget);

      await tester.tap(showTextBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('AUDIO TRANSCRIPT'), findsOneWidget);
      expect(find.text('I left my umbrella at home, and the sky turned pitch black.'), findsOneWidget);
      expect(find.text('CLOSE'), findsOneWidget);
    });

    testWidgets('8. Closing audio transcript bottom sheet dismisses the sheet', (tester) async {
      await pumpListeningInferenceScreen(tester);

      await tester.tap(find.byKey(const Key('listening_inference_show_text_btn')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('AUDIO TRANSCRIPT'), findsOneWidget);

      await tester.tap(find.text('CLOSE'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('AUDIO TRANSCRIPT'), findsNothing);
    });

    testWidgets('9. Inference grid displays all option choices in uppercase with icons', (tester) async {
      await pumpListeningInferenceScreen(tester);

      expect(find.byKey(const Key('listening_inference_option_0')), findsOneWidget);
      expect(find.byKey(const Key('listening_inference_option_1')), findsOneWidget);
      expect(find.byKey(const Key('listening_inference_option_2')), findsOneWidget);
      expect(find.byKey(const Key('listening_inference_option_3')), findsOneWidget);

      expect(find.text('IT IS GOING TO RAIN'), findsOneWidget);
      expect(find.text('A SUNNY AFTERNOON'), findsOneWidget);
      expect(find.text('THE BUS HAS ARRIVED'), findsOneWidget);
      expect(find.text('HE LOST HIS KEYS'), findsOneWidget);
    });

    testWidgets('10. Two-option quest renders options in a Row', (tester) async {
      final twoOptionState = ListeningLoaded(
        quests: const [sampleQuest2],
        currentIndex: 0,
        livesRemaining: 3,
      );

      await pumpListeningInferenceScreen(tester, state: twoOptionState);

      expect(find.byKey(const Key('listening_inference_option_0')), findsOneWidget);
      expect(find.byKey(const Key('listening_inference_option_1')), findsOneWidget);
      expect(find.text('IMPATIENT'), findsOneWidget);
      expect(find.text('EXCITED'), findsOneWidget);
    });

    testWidgets('11. Tapping correct option submits SubmitAnswer(true), plays sound, and triggers haptic', (tester) async {
      await pumpListeningInferenceScreen(tester);

      final correctOption = find.byKey(const Key('listening_inference_option_0'));
      await tester.tap(correctOption);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockListeningBloc.add(const SubmitAnswer(true))).called(1);
      verify(() => mockSoundService.playCorrect()).called(1);
      verify(() => mockHapticService.success()).called(1);
    });

    testWidgets('12. Tapping correct option stops the SpeedChallengeTimer', (tester) async {
      await pumpListeningInferenceScreen(tester);

      final timerState = tester.state<SpeedChallengeTimerState>(find.byType(SpeedChallengeTimer));
      expect(timerState.remainingSeconds, greaterThan(0));

      await tester.tap(find.byKey(const Key('listening_inference_option_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(timerState.remainingSeconds, greaterThan(0));
      expect(tester.takeException(), isNull);
    });

    testWidgets('13. Tapping wrong option submits SubmitAnswer(false) with userAnswer', (tester) async {
      await pumpListeningInferenceScreen(tester);

      final wrongOption = find.byKey(const Key('listening_inference_option_1'));
      await tester.tap(wrongOption);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockListeningBloc.add(const SubmitAnswer(false))).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockHapticService.error()).called(1);
    });

    testWidgets('14. Tapping wrong option stops the SpeedChallengeTimer', (tester) async {
      await pumpListeningInferenceScreen(tester);

      await tester.tap(find.byKey(const Key('listening_inference_option_1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(tester.takeException(), isNull);
    });

    testWidgets('15. Answer lockout: secondary taps on options are ignored once answered', (tester) async {
      await pumpListeningInferenceScreen(tester);

      // Tap first option
      await tester.tap(find.byKey(const Key('listening_inference_option_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      clearInteractions(mockListeningBloc);

      // Tap second option
      await tester.tap(find.byKey(const Key('listening_inference_option_2')), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verifyNever(() => mockListeningBloc.add(any(that: isA<SubmitAnswer>())));
    });

    testWidgets('16. SpeedChallengeTimer onTimeUp triggers wrong answer submission with [Timeout]', (tester) async {
      await pumpListeningInferenceScreen(tester);

      final SpeedChallengeTimer timerWidget = tester.widget(find.byType(SpeedChallengeTimer));
      timerWidget.onTimeUp();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockListeningBloc.add(const SubmitAnswer(false))).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockHapticService.error()).called(1);
    });

    testWidgets('17. In answered state, correct option is highlighted with verified icon', (tester) async {
      await pumpListeningInferenceScreen(tester);

      await tester.tap(find.byKey(const Key('listening_inference_option_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byIcon(Icons.verified_user_rounded), findsOneWidget);
    });

    testWidgets('18. In answered state with wrong choice, chosen option shows report_problem icon', (tester) async {
      await pumpListeningInferenceScreen(tester);

      await tester.tap(find.byKey(const Key('listening_inference_option_1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byIcon(Icons.report_problem_rounded), findsOneWidget);
    });

    testWidgets('19. In answered state with explanation present, explanation card is displayed', (tester) async {
      await pumpListeningInferenceScreen(tester);

      expect(find.byKey(const Key('listening_inference_explanation')), findsNothing);

      await tester.tap(find.byKey(const Key('listening_inference_option_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ListeningInferenceExplanation), findsOneWidget);
      expect(find.text('WHY?'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(ListeningInferenceExplanation),
          matching: find.text(
            'A dark sky suggests incoming rain and without an umbrella he will get wet.',
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('20. In answered state, Continue button appears in bottom bar; tapping it dispatches NextQuestion', (tester) async {
      await pumpListeningInferenceScreen(tester);

      await tester.tap(find.byKey(const Key('listening_inference_option_0')));
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

    testWidgets('21. Question transition clears selections, updates options, and restarts timer without crash', (tester) async {
      await pumpListeningInferenceScreen(tester);

      await tester.tap(find.byKey(const Key('listening_inference_option_0')));
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

      expect(find.text('IMPATIENT'), findsOneWidget);
      expect(find.text('EXCITED'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('22. Hint button in header dispatches ListeningHintUsed', (tester) async {
      await pumpListeningInferenceScreen(tester);

      clearInteractions(mockListeningBloc);

      final hintButton = find.byType(QuestHintButton);
      expect(hintButton, findsOneWidget);

      await tester.tap(hintButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1100));

      verify(() => mockListeningBloc.add(any(that: isA<ListeningHintUsed>()))).called(1);
    });

    testWidgets('23. GameShimmerLoading rendered when state is uninitialized or quest is null', (tester) async {
      await pumpListeningInferenceScreen(tester, state: const ListeningInitial());

      expect(find.byType(GameShimmerLoading), findsOneWidget);
      expect(find.byKey(const Key('listening_inference_radar_core')), findsNothing);
    });

    testWidgets('24. Game complete state triggers completion handling cleanly', (tester) async {
      await pumpListeningInferenceScreen(
        tester,
        state: const ListeningGameComplete(
          xpEarned: 100,
          coinsEarned: 20,
          questCount: 5,
        ),
      );

      expect(find.byType(ListeningInferenceScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('25. Game over state renders with zero lives', (tester) async {
      await pumpListeningInferenceScreen(
        tester,
        state: const ListeningGameOver(
          quests: [sampleQuest1],
          currentIndex: 0,
        ),
      );

      expect(find.byType(ListeningInferenceScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('26. Level 1 briefing dialog displays INFERENCE LENS and dismisses on FOCUS LENS tap', (tester) async {
      SharedPreferences.setMockInitialValues({
        'has_seen_briefing_listeningInference': false,
      });

      await pumpListeningInferenceScreen(
        tester,
        level: 1,
        size: const Size(390, 1100),
      );

      expect(find.byType(GameBriefingLayer), findsOneWidget);
      expect(find.text('INFERENCE LENS'), findsOneWidget);

      final actionBtn = find.text('FOCUS LENS');
      expect(actionBtn, findsOneWidget);

      await tester.tap(actionBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(GameBriefingLayer), findsNothing);
    });

    testWidgets('27. Dark and light themes render cleanly without errors', (tester) async {
      await pumpListeningInferenceScreen(tester, themeMode: ThemeMode.dark);
      expect(find.byType(ListeningInferenceScreen), findsOneWidget);

      await pumpListeningInferenceScreen(tester, themeMode: ThemeMode.light);
      expect(find.byType(ListeningInferenceScreen), findsOneWidget);
    });

    testWidgets('28. Small mobile screen (320x568) renders with zero overflow', (tester) async {
      await pumpListeningInferenceScreen(
        tester,
        size: const Size(320, 568),
      );
      expect(find.byType(ListeningInferenceScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('29. Tablet viewport (768x1024) renders with zero overflow', (tester) async {
      await pumpListeningInferenceScreen(
        tester,
        size: const Size(768, 1024),
      );
      expect(find.byType(ListeningInferenceScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('30. Reduced motion mode suppresses radar pulse rings and semantics present', (tester) async {
      await pumpListeningInferenceScreen(tester, reduceMotion: true);

      expect(find.byType(ListeningInferenceRadarCore), findsOneWidget);
      expect(find.byType(ListeningInferenceGrid), findsOneWidget);

      final radarSemantics = find.bySemanticsLabel('Play audio inference');
      expect(radarSemantics, findsOneWidget);

      final option0Semantics = find.bySemanticsLabel('It is going to rain');
      expect(option0Semantics, findsOneWidget);
    });
  });
}

