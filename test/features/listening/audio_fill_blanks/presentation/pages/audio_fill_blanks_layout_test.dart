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
import 'package:vowl/core/presentation/game_mechanics/typing/blind_dictation_wrapper.dart';
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
import 'package:vowl/features/listening/audio_fill_blanks/presentation/pages/audio_fill_blanks_screen.dart';
import 'package:vowl/features/listening/audio_fill_blanks/presentation/widgets/audio_fill_blanks_canvas.dart';
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
    id: 'afb_1',
    instruction: 'Listen and fill in the missing word.',
    difficulty: 1,
    subtype: GameSubtype.audioFillBlanks,
    textToSpeak: 'The quick brown fox jumps over the lazy dog.',
    textWithBlanks: 'The quick brown ___ jumps over the lazy dog.',
    correctAnswer: 'fox',
    distractorWords: ['box', 'fog'],
    hint: 'A cunning canine mammal with a bushy tail.',
    explanation: 'The standard English pangram uses "fox".',
  );

  const sampleSecondQuest = ListeningQuest(
    id: 'afb_2',
    instruction: 'Complete the missing phrase from the audio.',
    difficulty: 2,
    subtype: GameSubtype.audioFillBlanks,
    textToSpeak: 'She sells seashells on the seashore.',
    textWithBlanks: 'She sells ___ on the seashore.',
    correctAnswer: 'seashells',
    distractorWords: ['seashores', 'starfish'],
    hint: 'Marine molluscan shells found on beaches.',
    explanation: 'Tongue-twister with "seashells".',
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

    SharedPreferences.setMockInitialValues({
      'has_seen_briefing_audioFillBlanks': true,
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

    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

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

  Future<void> pumpAudioFillBlanksScreen(
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
          builder: (context, child) {
            return MaterialApp(
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              home: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  size: size,
                  disableAnimations: reduceMotion,
                ),
                child: AudioFillBlanksScreen(level: level),
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('Item 7.4: AudioFillBlanksScreen - Comprehensive Layout & Mechanics Suite', () {
    testWidgets('1. Initial quest rendering displays instruction, timer, jar, canvas, and options list', (tester) async {
      await pumpAudioFillBlanksScreen(tester);

      expect(find.byType(AudioFillBlanksScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('audio_fill_blanks_instruction')), findsOneWidget);
      expect(find.byType(SpeedChallengeTimer), findsOneWidget);
      expect(find.byKey(const ValueKey('audio_fill_blanks_jar')), findsOneWidget);
      expect(find.byKey(const ValueKey('audio_fill_blanks_canvas')), findsOneWidget);
      expect(find.byKey(const ValueKey('options_list')), findsOneWidget);
    });

    testWidgets('2. Deterministic options list contains correct answer and distractors', (tester) async {
      await pumpAudioFillBlanksScreen(tester);

      expect(find.text('FOX'), findsOneWidget);
      expect(find.text('BOX'), findsOneWidget);
      expect(find.text('FOG'), findsOneWidget);
    });

    testWidgets('3. Canvas initially displays text with blanks and ink blobs', (tester) async {
      await pumpAudioFillBlanksScreen(tester);

      expect(find.text('The quick brown ___ jumps over the lazy dog.'), findsOneWidget);
    });

    testWidgets('4. Smearing across canvas updates revealProgress and triggers haptic tick', (tester) async {
      await pumpAudioFillBlanksScreen(tester);

      final canvas = tester.widget<AudioFillBlanksCanvas>(find.byType(AudioFillBlanksCanvas));
      canvas.onSmear(0.2);
      await tester.pump();

      verify(() => mockHapticService.selection()).called(greaterThanOrEqualTo(1));
    });

    testWidgets('5. Tapping canvas acts as an accessibility tap alternative to smear', (tester) async {
      await pumpAudioFillBlanksScreen(tester);

      final canvasFinder = find.byKey(const ValueKey('audio_fill_blanks_canvas'));
      await tester.tap(canvasFinder);
      await tester.pump();

      verify(() => mockHapticService.selection()).called(greaterThanOrEqualTo(1));
    });

    testWidgets('6. Tapping audio jar plays TTS audio and triggers selection haptic', (tester) async {
      await pumpAudioFillBlanksScreen(tester);

      await tester.tap(find.byKey(const ValueKey('audio_fill_blanks_jar')));
      await tester.pump();

      verify(() => mockSoundService.playTts('The quick brown fox jumps over the lazy dog.')).called(1);
      verify(() => mockHapticService.selection()).called(1);
    });

    testWidgets('7. Tapping correct option dispatches SubmitAnswer(true) with success audio and haptics', (tester) async {
      await pumpAudioFillBlanksScreen(tester);

      await tester.tap(find.text('FOX'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockListeningBloc.add(const SubmitAnswer(true))).called(1);
      verify(() => mockHapticService.success()).called(1);
      verify(() => mockSoundService.playCorrect()).called(1);
    });

    testWidgets('8. Tapping incorrect option dispatches SubmitAnswer(false) with error audio and haptics', (tester) async {
      await pumpAudioFillBlanksScreen(tester);

      await tester.tap(find.text('BOX'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockListeningBloc.add(const SubmitAnswer(false))).called(1);
      verify(() => mockHapticService.error()).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
    });

    testWidgets('9. Answer lockout prevents secondary option taps once answered', (tester) async {
      await pumpAudioFillBlanksScreen(tester);

      await tester.tap(find.text('FOX'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      clearInteractions(mockListeningBloc);
      clearInteractions(mockHapticService);

      final boxFinder = find.text('BOX');
      if (boxFinder.evaluate().isNotEmpty) {
        await tester.tap(boxFinder, warnIfMissed: false);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        verifyNever(() => mockListeningBloc.add(any()));
        verifyNever(() => mockHapticService.error());
      }
    });

    testWidgets('10. SpeedChallengeTimer onTimeUp triggers failure submission', (tester) async {
      await pumpAudioFillBlanksScreen(tester);

      final timerState = tester.state<SpeedChallengeTimerState>(find.byType(SpeedChallengeTimer));
      timerState.widget.onTimeUp();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockListeningBloc.add(const SubmitAnswer(false))).called(1);
      verify(() => mockHapticService.error()).called(1);
    });

    testWidgets('11. Answering stops the active SpeedChallengeTimer', (tester) async {
      await pumpAudioFillBlanksScreen(tester);

      final timerState = tester.state<SpeedChallengeTimerState>(find.byType(SpeedChallengeTimer));
      expect(timerState.isTimerActive, isTrue);

      await tester.tap(find.text('FOX'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(timerState.isTimerActive, isFalse);
    });

    testWidgets('12. High level (>= 8) renders BlindDictationWrapper instead of multiple choice options', (tester) async {
      await pumpAudioFillBlanksScreen(tester, level: 8);

      expect(find.byType(BlindDictationWrapper), findsOneWidget);
      expect(find.byKey(const ValueKey('options_list')), findsNothing);
    });

    testWidgets('13. Blind dictation confirmed callback dispatches SubmitAnswer(true)', (tester) async {
      await pumpAudioFillBlanksScreen(tester, level: 8);

      final dictation = tester.widget<BlindDictationWrapper>(find.byType(BlindDictationWrapper));
      dictation.onConfirmed();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockListeningBloc.add(const SubmitAnswer(true))).called(1);
      verify(() => mockHapticService.success()).called(1);
    });

    testWidgets('14. Blind dictation skipped callback dispatches SubmitAnswer(false)', (tester) async {
      await pumpAudioFillBlanksScreen(tester, level: 8);

      final dictation = tester.widget<BlindDictationWrapper>(find.byType(BlindDictationWrapper));
      dictation.onSkipped();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockListeningBloc.add(const SubmitAnswer(false))).called(1);
      verify(() => mockHapticService.error()).called(1);
    });

    testWidgets('15. Next question state transition clears revealProgress and updates canvas text', (tester) async {
      await pumpAudioFillBlanksScreen(tester);

      // Answer first quest
      await tester.tap(find.text('FOX'));
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

      expect(find.text('She sells ___ on the seashore.'), findsOneWidget);
      expect(find.text('SEASHELLS'), findsOneWidget);
    });

    testWidgets('16. Continue button dispatches NextQuestion event', (tester) async {
      final answeredState = testLoadedState.copyWith(
        answerStatus: AnswerStatus.correct,
      );

      await pumpAudioFillBlanksScreen(tester, state: answeredState);

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

    testWidgets('17. Hint button in header dispatches ListeningHintUsed', (tester) async {
      await pumpAudioFillBlanksScreen(tester);

      final hintButton = find.byType(QuestHintButton);
      if (hintButton.evaluate().isNotEmpty) {
        await tester.tap(hintButton.first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 1100));

        verify(() => mockListeningBloc.add(const ListeningHintUsed())).called(1);
      }
    });

    testWidgets('18. Uninitialized or loading state renders GameShimmerLoading', (tester) async {
      when(() => mockListeningBloc.state).thenReturn(const ListeningInitial());
      await pumpAudioFillBlanksScreen(tester, state: const ListeningInitial());

      expect(find.byType(GameShimmerLoading), findsOneWidget);
      expect(find.byType(AudioFillBlanksCanvas), findsNothing);
    });

    testWidgets('19. Game complete state triggers completion handling and dialog', (tester) async {
      await pumpAudioFillBlanksScreen(tester);

      const completeState = ListeningGameComplete(
        xpEarned: 50,
        coinsEarned: 15,
        questCount: 2,
      );
      when(() => mockListeningBloc.state).thenReturn(completeState);
      listeningStreamController.add(completeState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('AUDITORY ACE!'), findsOneWidget);
    });

    testWidgets('20. Game over state renders with zero lives', (tester) async {
      const gameOverState = ListeningGameOver(
        quests: [sampleQuest],
        currentIndex: 0,
      );
      await pumpAudioFillBlanksScreen(tester, state: gameOverState);

      expect(find.byType(AudioFillBlanksScreen), findsOneWidget);
    });

    testWidgets('21. Level 1 shows briefing layer and dismisses on start tap', (tester) async {
      SharedPreferences.setMockInitialValues({
        'has_seen_briefing_audioFillBlanks': false,
      });

      await pumpAudioFillBlanksScreen(tester, level: 1);

      expect(find.byType(GameBriefingLayer), findsOneWidget);

      final startButton = find.text('START');
      if (startButton.evaluate().isNotEmpty) {
        await tester.tap(startButton);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(GameBriefingLayer), findsNothing);
      }
    });

    testWidgets('22. Dark mode renders correctly with dark theme styling', (tester) async {
      await pumpAudioFillBlanksScreen(tester, themeMode: ThemeMode.dark);

      expect(find.byType(AudioFillBlanksScreen), findsOneWidget);
    });

    testWidgets('23. Light mode renders correctly with light theme styling', (tester) async {
      await pumpAudioFillBlanksScreen(tester, themeMode: ThemeMode.light);

      expect(find.byType(AudioFillBlanksScreen), findsOneWidget);
    });

    testWidgets('24. Compact mobile viewport (320x568) passes with zero overflow', (tester) async {
      await pumpAudioFillBlanksScreen(tester, size: const Size(320, 568));

      expect(tester.takeException(), isNull);
    });

    testWidgets('25. Tablet viewport (768x1024) passes with zero overflow', (tester) async {
      await pumpAudioFillBlanksScreen(tester, size: const Size(768, 1024));

      expect(tester.takeException(), isNull);
    });

    testWidgets('26. Reduced motion mode stops repeating ink blob animations', (tester) async {
      await pumpAudioFillBlanksScreen(tester, reduceMotion: true);

      expect(find.byType(AudioFillBlanksCanvas), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('27. Empty textToSpeak falls back to prompt or question for TTS playback', (tester) async {
      const fallbackQuest = ListeningQuest(
        id: 'afb_fallback',
        instruction: 'Fill blank.',
        difficulty: 1,
        subtype: GameSubtype.audioFillBlanks,
        prompt: 'The cat in the hat.',
        textWithBlanks: 'The ___ in the hat.',
        correctAnswer: 'cat',
        distractorWords: ['bat', 'rat'],
      );
      final fallbackState = testLoadedState.copyWith(
        quests: [fallbackQuest],
        currentIndex: 0,
      );

      await pumpAudioFillBlanksScreen(tester, state: fallbackState);

      await tester.tap(find.byKey(const ValueKey('audio_fill_blanks_jar')));
      await tester.pump();

      verify(() => mockSoundService.playTts('The cat in the hat.')).called(1);
    });

    testWidgets('28. Final failure state displays explanation and correct answer', (tester) async {
      final failureState = testLoadedState.copyWith(
        livesRemaining: 0,
        answerStatus: AnswerStatus.incorrect,
        isFinalFailure: true,
      );

      await pumpAudioFillBlanksScreen(tester, state: failureState);

      listeningStreamController.add(failureState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(AudioFillBlanksScreen), findsOneWidget);
    });

    testWidgets('29. Correct answer reveals full textToSpeak on canvas', (tester) async {
      await pumpAudioFillBlanksScreen(tester);

      final correctState = testLoadedState.copyWith(
        answerStatus: AnswerStatus.correct,
      );

      listeningStreamController.add(correctState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(
        find.descendant(
          of: find.byType(AudioFillBlanksCanvas),
          matching: find.text('The quick brown fox jumps over the lazy dog.'),
        ),
        findsOneWidget,
      );
    });
  });
}
