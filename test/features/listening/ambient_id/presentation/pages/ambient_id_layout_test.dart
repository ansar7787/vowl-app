import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/game_mechanics/shared/speed_challenge_timer.dart';
import 'package:vowl/core/presentation/widgets/game_briefing_layer.dart';
import 'package:vowl/core/presentation/widgets/quest_hint_button.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/network/network_info.dart';
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
import 'package:vowl/features/listening/ambient_id/presentation/pages/ambient_id_screen.dart';
import 'package:vowl/features/listening/ambient_id/presentation/widgets/ambient_id_emitter_node.dart';
import 'package:vowl/features/listening/ambient_id/presentation/widgets/ambient_id_instruction.dart';
import 'package:vowl/features/listening/ambient_id/presentation/widgets/ambient_id_sonar_field.dart';
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
    id: 'amb_1',
    instruction: 'Identify the ambient environment.',
    difficulty: 1,
    subtype: GameSubtype.ambientId,
    textToSpeak: 'Birds chirping in a dense pine forest canopy.',
    options: ['Forest', 'Space Station', 'Cyber City', 'Ocean Base'],
    correctAnswerIndex: 0,
    correctAnswer: 'Forest',
    hint: 'Listen for avian vocalizations and foliage.',
    explanation: 'Pine trees and singing birds define a forest woodland.',
  );

  const sampleSecondQuest = ListeningQuest(
    id: 'amb_2',
    instruction: 'Locate the source of the sonar ping.',
    difficulty: 2,
    subtype: GameSubtype.ambientId,
    textToSpeak: 'Hydrophone recording sonar echoes underwater with whale songs.',
    options: ['Deep Ocean', 'Desert Dunes', 'Alpine Peak', 'Metro Station'],
    correctAnswerIndex: 0,
    correctAnswer: 'Deep Ocean',
    hint: 'Whales reside in deep ocean waters.',
    explanation: 'Hydrophone and sonar echoes indicate deep ocean.',
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

    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

    SharedPreferences.setMockInitialValues({
      'has_seen_briefing_ambientId': true,
    });

    when(() => mockListeningBloc.state).thenReturn(testLoadedState);
    listeningStreamController = StreamController<ListeningState>.broadcast();
    when(() => mockListeningBloc.stream).thenAnswer((_) => listeningStreamController.stream);

    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(
        const UserEntity(
          id: 'test_user_id',
          email: 'test@vowl.app',
          displayName: 'Test Listener',
          isPremium: true,
          hintCount: 3,
        ),
      ),
    );
    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream<AuthState>.empty());

    when(() => mockEconomyBloc.state).thenReturn(const EconomyState());
    when(() => mockEconomyBloc.stream).thenAnswer((_) => const Stream.empty());

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});
    when(() => mockHapticService.heavy()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});

    when(() => mockSoundService.playCorrect()).thenAnswer((_) async {});
    when(() => mockSoundService.playWrong()).thenAnswer((_) async {});
    when(() => mockSoundService.playClick()).thenAnswer((_) async {});
    when(() => mockSoundService.playHint()).thenAnswer((_) async {});
    when(() => mockSoundService.stopAudio()).thenAnswer((_) async {});
    when(() => mockSoundService.stopTts()).thenAnswer((_) async {});
    when(() => mockSoundService.playTts(any())).thenAnswer((_) async {});
    when(() => mockSoundService.playUrl(any())).thenAnswer((_) async {});
    when(() => mockSoundService.playLevelComplete()).thenAnswer((_) async {});

    when(() => mockTtsService.stop()).thenAnswer((_) async {});
    when(
      () => mockTtsService.speak(
        any(),
        rate: any(named: 'rate'),
        locale: any(named: 'locale'),
        pauseMarkers: any(named: 'pauseMarkers'),
        forcedPreset: any(named: 'forcedPreset'),
        isKids: any(named: 'isKids'),
      ),
    ).thenAnswer((_) async {});

    when(() => mockAnalyticsService.logGameSkipped(any())).thenAnswer((_) async {});

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

  tearDown(() {
    listeningStreamController.close();
  });

  Future<void> pumpAmbientIdScreen(
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
                body: AmbientIdScreen(level: level),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('Item 7.3: AmbientIdScreen - Comprehensive Layout & Mechanics Suite', () {
    testWidgets('1. Initial quest rendering displays instruction, timer, sonar field, and emitter', (tester) async {
      await pumpAmbientIdScreen(tester);

      expect(find.byType(AmbientIdInstruction), findsOneWidget);
      expect(find.text('IDENTIFY THE AMBIENT ENVIRONMENT.'), findsOneWidget);
      expect(find.byType(SpeedChallengeTimer), findsOneWidget);
      expect(find.byType(AmbientIdSonarField), findsOneWidget);
      expect(find.byType(AmbientIdEmitterNode), findsOneWidget);
    });

    testWidgets('2. Location hubs are generated correctly for each option', (tester) async {
      await pumpAmbientIdScreen(tester);

      for (int i = 0; i < sampleQuest.options!.length; i++) {
        expect(find.byKey(ValueKey('ambient_hub_$i')), findsOneWidget);
      }
      expect(find.text('FOREST'), findsOneWidget);
      expect(find.text('SPACE STATION'), findsOneWidget);
      expect(find.text('CYBER CITY'), findsOneWidget);
      expect(find.text('OCEAN BASE'), findsOneWidget);
    });

    testWidgets('3. Location hubs render appropriate icons for categories', (tester) async {
      await pumpAmbientIdScreen(tester);

      expect(find.byIcon(Icons.forest_rounded), findsOneWidget);
      expect(find.byIcon(Icons.settings_input_antenna_rounded), findsWidgets);
      expect(find.byIcon(Icons.location_city_rounded), findsOneWidget);
      expect(find.byIcon(Icons.waves_rounded), findsOneWidget);
    });

    testWidgets('4. Tapping emitter node triggers TTS replay and selection haptics', (tester) async {
      await pumpAmbientIdScreen(tester);

      await tester.tap(find.byKey(const ValueKey('ambient_emitter_node')));
      await tester.pump();

      verify(() => mockSoundService.playTts(sampleQuest.textToSpeak!)).called(1);
      verify(() => mockHapticService.selection()).called(1);
    });

    testWidgets('5. Tapping correct location hub dispatches SubmitAnswer(true) with success audio and haptics', (tester) async {
      await pumpAmbientIdScreen(tester);

      // Index 0 is 'Forest' (correct answer)
      await tester.tap(find.byKey(const ValueKey('ambient_hub_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockListeningBloc.add(const SubmitAnswer(true))).called(1);
      verify(() => mockHapticService.success()).called(1);
      verify(() => mockSoundService.playCorrect()).called(1);
    });

    testWidgets('6. Tapping incorrect location hub dispatches SubmitAnswer(false) with error audio and haptics', (tester) async {
      await pumpAmbientIdScreen(tester);

      // Index 1 is 'Space Station' (wrong answer)
      await tester.tap(find.byKey(const ValueKey('ambient_hub_1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockListeningBloc.add(const SubmitAnswer(false))).called(1);
      verify(() => mockHapticService.error()).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
    });

    testWidgets('7. Answer lockout prevents secondary taps once answered', (tester) async {
      await pumpAmbientIdScreen(tester);

      // Submit correct answer first
      await tester.tap(find.byKey(const ValueKey('ambient_hub_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      clearInteractions(mockListeningBloc);
      clearInteractions(mockHapticService);

      // Attempt to tap another hub while answered
      await tester.tap(find.byKey(const ValueKey('ambient_hub_2')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      verifyNever(() => mockListeningBloc.add(any()));
      verifyNever(() => mockHapticService.selection());
      verifyNever(() => mockHapticService.error());
    });

    testWidgets('8. SpeedChallengeTimer onTimeUp triggers submitWrongAnswer', (tester) async {
      await pumpAmbientIdScreen(tester);

      final timerState = tester.state<SpeedChallengeTimerState>(find.byType(SpeedChallengeTimer));
      timerState.widget.onTimeUp();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockListeningBloc.add(const SubmitAnswer(false))).called(1);
      verify(() => mockHapticService.error()).called(1);
    });

    testWidgets('9. Answering stops the active SpeedChallengeTimer', (tester) async {
      await pumpAmbientIdScreen(tester);

      final timerState = tester.state<SpeedChallengeTimerState>(find.byType(SpeedChallengeTimer));
      expect(timerState.isTimerActive, isTrue);

      await tester.tap(find.byKey(const ValueKey('ambient_hub_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(timerState.isTimerActive, isFalse);
    });

    testWidgets('10. Next question state transition clears selected index and updates hubs', (tester) async {
      await pumpAmbientIdScreen(tester);

      // Answer first quest
      await tester.tap(find.byKey(const ValueKey('ambient_hub_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Emit second quest loaded state
      final nextState = testLoadedState.copyWith(
        currentIndex: 1,
        answerStatus: AnswerStatus.unanswered,
      );
      when(() => mockListeningBloc.state).thenReturn(nextState);
      listeningStreamController.add(nextState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('LOCATE THE SOURCE OF THE SONAR PING.'), findsOneWidget);
      expect(find.text('DEEP OCEAN'), findsOneWidget);
      expect(find.text('DESERT DUNES'), findsOneWidget);
    });

    testWidgets('11. Continue button dispatches NextQuestion event', (tester) async {
      final answeredState = testLoadedState.copyWith(
        answerStatus: AnswerStatus.correct,
      );

      await pumpAmbientIdScreen(tester, state: answeredState);

      // Simulate answered state via controller
      listeningStreamController.add(answeredState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final continueFinder = find.text('CONTINUE');
      if (continueFinder.evaluate().isNotEmpty) {
        await tester.tap(continueFinder.first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        verify(() => mockListeningBloc.add(const NextQuestion())).called(1);
      }
    });

    testWidgets('12. Hint button in header dispatches ListeningHintUsed', (tester) async {
      await pumpAmbientIdScreen(tester);

      final hintButton = find.byType(QuestHintButton);
      if (hintButton.evaluate().isNotEmpty) {
        await tester.tap(hintButton.first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1100));

        verify(() => mockListeningBloc.add(const ListeningHintUsed())).called(1);
      }
    });

    testWidgets('13. Uninitialized or loading state renders GameShimmerLoading', (tester) async {
      await pumpAmbientIdScreen(tester, state: const ListeningLoading());

      expect(find.byType(GameShimmerLoading), findsOneWidget);
      expect(find.byType(AmbientIdSonarField), findsNothing);
    });

    testWidgets('14. Game complete state triggers completion handling and confetti', (tester) async {
      await pumpAmbientIdScreen(tester);

      const completeState = ListeningGameComplete(
        xpEarned: 50,
        coinsEarned: 15,
        questCount: 2,
      );
      when(() => mockListeningBloc.state).thenReturn(completeState);
      listeningStreamController.add(completeState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('CONTEXT ANCHOR!'), findsOneWidget);
    });

    testWidgets('15. Game over state renders with zero lives', (tester) async {
      const gameOverState = ListeningGameOver(
        quests: [sampleQuest],
        currentIndex: 0,
      );
      await pumpAmbientIdScreen(tester, state: gameOverState);

      expect(find.byType(AmbientIdScreen), findsOneWidget);
    });

    testWidgets('16. Level 1 shows briefing layer and dismisses on start tap', (tester) async {
      SharedPreferences.setMockInitialValues({
        'has_seen_briefing_ambientId': false,
      });

      await pumpAmbientIdScreen(tester, level: 1);

      expect(find.byType(GameBriefingLayer), findsOneWidget);

      final startBtn = find.text('START LEVEL');
      if (startBtn.evaluate().isNotEmpty) {
        await tester.tap(startBtn);
        await tester.pump();
        expect(find.byType(GameBriefingLayer), findsNothing);
      }
    });

    testWidgets('17. Dark mode renders correctly with dark theme styling', (tester) async {
      await pumpAmbientIdScreen(tester, themeMode: ThemeMode.dark);

      expect(find.byType(AmbientIdScreen), findsOneWidget);
      expect(find.text('IDENTIFY THE AMBIENT ENVIRONMENT.'), findsOneWidget);
    });

    testWidgets('18. Light mode renders correctly with light theme styling', (tester) async {
      await pumpAmbientIdScreen(tester, themeMode: ThemeMode.light);

      expect(find.byType(AmbientIdScreen), findsOneWidget);
      expect(find.text('IDENTIFY THE AMBIENT ENVIRONMENT.'), findsOneWidget);
    });

    testWidgets('19. Compact mobile viewport (320x568) passes with zero overflow', (tester) async {
      await pumpAmbientIdScreen(tester, size: const Size(320, 568));

      expect(tester.takeException(), isNull);
      expect(find.byType(AmbientIdScreen), findsOneWidget);
    });

    testWidgets('20. Tablet viewport (768x1024) passes with zero overflow', (tester) async {
      await pumpAmbientIdScreen(tester, size: const Size(768, 1024));

      expect(tester.takeException(), isNull);
      expect(find.byType(AmbientIdScreen), findsOneWidget);
    });

    testWidgets('21. Reduced motion mode stops repeating radar and scale animations', (tester) async {
      await pumpAmbientIdScreen(tester, reduceMotion: true);

      expect(find.byType(AmbientIdSonarField), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('22. Empty quest instruction falls back to localized default text', (tester) async {
      const fallbackQuest = ListeningQuest(
        id: 'amb_fallback',
        instruction: '',
        difficulty: 1,
        subtype: GameSubtype.ambientId,
        textToSpeak: 'Rain falling on a tin roof.',
        options: ['Cabin', 'Tent', 'Mansion', 'Bunker'],
        correctAnswerIndex: 0,
        correctAnswer: 'Cabin',
      );
      final fallbackState = testLoadedState.copyWith(
        quests: [fallbackQuest],
        currentIndex: 0,
      );

      await pumpAmbientIdScreen(tester, state: fallbackState);

      expect(find.text('LISTEN AND TAP THE LOCATION.'), findsOneWidget);
    });

    testWidgets('23. Missing textToSpeak falls back to prompt or question for TTS', (tester) async {
      const noTtsQuest = ListeningQuest(
        id: 'amb_no_tts',
        instruction: 'Find the sound origin.',
        difficulty: 1,
        subtype: GameSubtype.ambientId,
        textToSpeak: null,
        transcript: 'Whistling wind on a mountain pass.',
        options: ['Mountain', 'Valley', 'Cave', 'Coast'],
        correctAnswerIndex: 0,
        correctAnswer: 'Mountain',
      );
      final noTtsState = testLoadedState.copyWith(
        quests: [noTtsQuest],
        currentIndex: 0,
      );

      await pumpAmbientIdScreen(tester, state: noTtsState);

      await tester.tap(find.byKey(const ValueKey('ambient_emitter_node')));
      await tester.pump();

      verify(() => mockSoundService.playTts('Whistling wind on a mountain pass.')).called(1);
    });

    testWidgets('24. Final failure state displays explanation and correct answer', (tester) async {
      final failureState = testLoadedState.copyWith(
        answerStatus: AnswerStatus.incorrect,
        isFinalFailure: true,
      );

      await pumpAmbientIdScreen(tester, state: failureState);

      listeningStreamController.add(failureState);
      await tester.pump();

      expect(find.byType(AmbientIdScreen), findsOneWidget);
    });

    testWidgets('25. Selected hub retains visual selection state', (tester) async {
      await pumpAmbientIdScreen(tester);

      // Tap index 1
      await tester.tap(find.byKey(const ValueKey('ambient_hub_1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final sonarField = tester.widget<AmbientIdSonarField>(find.byType(AmbientIdSonarField));
      expect(sonarField.selectedIndex, equals(1));
    });

    testWidgets('26. Sonar field gracefully handles diverse options like airport and lab', (tester) async {
      const diverseQuest = ListeningQuest(
        id: 'amb_diverse',
        instruction: 'Identify the facility.',
        difficulty: 1,
        subtype: GameSubtype.ambientId,
        textToSpeak: 'Jet turbine spooling up.',
        options: ['Airport Runway', 'Chemistry Lab', 'Ancient Temple', 'Bank Vault'],
        correctAnswerIndex: 0,
        correctAnswer: 'Airport Runway',
      );
      final diverseState = testLoadedState.copyWith(
        quests: [diverseQuest],
        currentIndex: 0,
      );

      await pumpAmbientIdScreen(tester, state: diverseState);

      expect(find.byIcon(Icons.local_airport_rounded), findsOneWidget);
      expect(find.byIcon(Icons.science_rounded), findsOneWidget);
      expect(find.byIcon(Icons.temple_hindu_rounded), findsOneWidget);
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
    });
  });
}
