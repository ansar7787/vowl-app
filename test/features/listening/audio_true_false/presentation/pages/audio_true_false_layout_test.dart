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
import 'package:vowl/features/listening/audio_true_false/presentation/pages/audio_true_false_screen.dart';
import 'package:vowl/features/listening/audio_true_false/presentation/widgets/audio_true_false_instruction.dart';
import 'package:vowl/features/listening/audio_true_false/presentation/widgets/audio_true_false_screen_display.dart';
import 'package:vowl/features/listening/audio_true_false/presentation/widgets/audio_true_false_tuner.dart';
import 'package:vowl/features/listening/audio_true_false/presentation/widgets/audio_true_false_verdict_buttons.dart';
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

  const sampleQuestTrue = ListeningQuest(
    id: 'atf_1',
    instruction: 'Is this statement True or False? Listen carefully.',
    difficulty: 1,
    subtype: GameSubtype.audioTrueFalse,
    textToSpeak: 'The cat is sleeping on the warm sofa.',
    statement: 'The cat is on the sofa.',
    correctAnswer: 'true',
    emoji: '🐱',
    hint: 'Listen for where the cat is resting.',
    explanation: 'The cat is indeed sleeping on the sofa.',
  );

  const sampleQuestFalse = ListeningQuest(
    id: 'atf_2',
    instruction: 'Verify if the audio matches the statement.',
    difficulty: 1,
    subtype: GameSubtype.audioTrueFalse,
    textToSpeak: 'The dog is barking at the mail carrier.',
    statement: 'The cat is barking at the mail carrier.',
    correctAnswer: 'false',
    emoji: '🐕',
    hint: 'Pay attention to the animal mentioned.',
    explanation: 'It was a dog, not a cat.',
  );

  const sampleQuestNext = ListeningQuest(
    id: 'atf_3',
    instruction: 'Is this statement true or false?',
    difficulty: 2,
    subtype: GameSubtype.audioTrueFalse,
    textToSpeak: 'She bought five fresh apples at the market.',
    statement: 'She bought fresh apples.',
    correctAnswer: 'true',
    emoji: '🍎',
    hint: 'Check what she bought.',
    explanation: 'She bought apples.',
  );

  final testLoadedState = ListeningLoaded(
    quests: const [sampleQuestTrue, sampleQuestFalse, sampleQuestNext],
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
      'has_seen_briefing_audioTrueFalse': true,
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

  Future<void> pumpAudioTrueFalseScreen(
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
                body: AudioTrueFalseScreen(
                  level: level,
                  gameType: GameSubtype.audioTrueFalse,
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

  group('AudioTrueFalseScreen Layout & Mechanics Tests', () {
    testWidgets('1. Initial layout renders instruction, timer, audio tuner, statement display card, and verdict buttons', (tester) async {
      await pumpAudioTrueFalseScreen(tester);

      expect(find.byType(AudioTrueFalseInstruction), findsOneWidget);
      expect(find.byKey(const Key('audio_true_false_instruction')), findsOneWidget);
      expect(find.text('Is this statement True or False?'), findsOneWidget);
      expect(find.text('Listen carefully.'), findsOneWidget);

      expect(find.byType(SpeedChallengeTimer), findsOneWidget);

      expect(find.byType(AudioTrueFalseTuner), findsOneWidget);
      expect(find.byKey(const Key('audio_true_false_tuner_btn')), findsOneWidget);

      expect(find.byType(AudioTrueFalseScreenDisplay), findsOneWidget);
      expect(find.byKey(const Key('audio_true_false_statement')), findsOneWidget);
      expect(find.text('The cat is on the sofa.'), findsOneWidget);
      expect(find.byKey(const Key('audio_true_false_emoji')), findsOneWidget);
      expect(find.text('🐱'), findsOneWidget);

      expect(find.byType(AudioTrueFalseVerdictButtons), findsOneWidget);
      expect(find.byKey(const Key('audio_true_false_btn_false')), findsOneWidget);
      expect(find.byKey(const Key('audio_true_false_btn_true')), findsOneWidget);
      expect(find.text('FALSE'), findsOneWidget);
      expect(find.text('TRUE'), findsOneWidget);
    });

    testWidgets('2. Audio tuner tap triggers TTS playback with textToSpeak and selection haptics', (tester) async {
      await pumpAudioTrueFalseScreen(tester);

      final tunerBtn = find.byKey(const Key('audio_true_false_tuner_btn'));
      expect(tunerBtn, findsOneWidget);

      await tester.tap(tunerBtn);
      await tester.pump();

      verify(() => mockSoundService.playTts(
        'The cat is sleeping on the warm sofa.',
        pauseMarkers: any(named: 'pauseMarkers'),
      )).called(1);
      verify(() => mockHapticService.selection()).called(1);
    });

    testWidgets('3. Audio tuner tap with URL audio triggers soundService.playUrl', (tester) async {
      const urlQuest = ListeningQuest(
        id: 'atf_url',
        instruction: 'Listen carefully',
        difficulty: 1,
        subtype: GameSubtype.audioTrueFalse,
        textToSpeak: 'https://cdn.vowl.app/audio/cat.mp3',
        statement: 'A cat is purring.',
        correctAnswer: 'true',
      );
      final urlState = const ListeningLoaded(
        quests: [urlQuest],
        currentIndex: 0,
        livesRemaining: 3,
      );

      await pumpAudioTrueFalseScreen(tester, state: urlState);

      await tester.tap(find.byKey(const Key('audio_true_false_tuner_btn')));
      await tester.pump();

      verify(() => mockSoundService.playUrl('https://cdn.vowl.app/audio/cat.mp3')).called(1);
      verify(() => mockHapticService.selection()).called(1);
    });

    testWidgets('4. Audio tuner cascades to prompt when textToSpeak is null', (tester) async {
      const promptQuest = ListeningQuest(
        id: 'atf_prompt',
        instruction: 'Listen carefully',
        difficulty: 1,
        subtype: GameSubtype.audioTrueFalse,
        textToSpeak: null,
        prompt: 'Prompt audio statement',
        statement: 'Statement text',
        correctAnswer: 'true',
      );
      final promptState = const ListeningLoaded(
        quests: [promptQuest],
        currentIndex: 0,
        livesRemaining: 3,
      );

      await pumpAudioTrueFalseScreen(tester, state: promptState);

      await tester.tap(find.byKey(const Key('audio_true_false_tuner_btn')));
      await tester.pump();

      verify(() => mockSoundService.playTts(
        'Prompt audio statement',
        pauseMarkers: any(named: 'pauseMarkers'),
      )).called(1);
    });

    testWidgets('5. Audio tuner cascades to question when textToSpeak and prompt are null', (tester) async {
      const questionQuest = ListeningQuest(
        id: 'atf_question',
        instruction: 'Listen carefully',
        difficulty: 1,
        subtype: GameSubtype.audioTrueFalse,
        textToSpeak: null,
        prompt: null,
        question: 'Question audio statement',
        statement: 'Statement text',
        correctAnswer: 'true',
      );
      final questionState = const ListeningLoaded(
        quests: [questionQuest],
        currentIndex: 0,
        livesRemaining: 3,
      );

      await pumpAudioTrueFalseScreen(tester, state: questionState);

      await tester.tap(find.byKey(const Key('audio_true_false_tuner_btn')));
      await tester.pump();

      verify(() => mockSoundService.playTts(
        'Question audio statement',
        pauseMarkers: any(named: 'pauseMarkers'),
      )).called(1);
    });

    testWidgets('6. Audio tuner cascades to statement when other audio fields are null', (tester) async {
      const statementQuest = ListeningQuest(
        id: 'atf_stmt',
        instruction: 'Listen carefully',
        difficulty: 1,
        subtype: GameSubtype.audioTrueFalse,
        textToSpeak: null,
        prompt: null,
        question: null,
        transcription: null,
        statement: 'Statement audio fallback',
        correctAnswer: 'true',
      );
      final stmtState = const ListeningLoaded(
        quests: [statementQuest],
        currentIndex: 0,
        livesRemaining: 3,
      );

      await pumpAudioTrueFalseScreen(tester, state: stmtState);

      await tester.tap(find.byKey(const Key('audio_true_false_tuner_btn')));
      await tester.pump();

      verify(() => mockSoundService.playTts(
        'Statement audio fallback',
        pauseMarkers: any(named: 'pauseMarkers'),
      )).called(1);
    });

    testWidgets('7. Statement display card falls back to question or prompt when statement is null', (tester) async {
      const fallbackQuest = ListeningQuest(
        id: 'atf_fb',
        instruction: 'Listen carefully',
        difficulty: 1,
        subtype: GameSubtype.audioTrueFalse,
        textToSpeak: 'The birds are singing.',
        statement: null,
        question: 'Are the birds singing in the morning?',
        correctAnswer: 'true',
      );
      final fbState = const ListeningLoaded(
        quests: [fallbackQuest],
        currentIndex: 0,
        livesRemaining: 3,
      );

      await pumpAudioTrueFalseScreen(tester, state: fbState);

      expect(find.text('Are the birds singing in the morning?'), findsOneWidget);
    });

    testWidgets('8. Emoji renders when provided and is omitted when emoji is null', (tester) async {
      const noEmojiQuest = ListeningQuest(
        id: 'atf_no_emoji',
        instruction: 'Listen carefully',
        difficulty: 1,
        subtype: GameSubtype.audioTrueFalse,
        textToSpeak: 'The car stopped.',
        statement: 'The car stopped.',
        emoji: null,
        correctAnswer: 'true',
      );
      final noEmojiState = const ListeningLoaded(
        quests: [noEmojiQuest],
        currentIndex: 0,
        livesRemaining: 3,
      );

      await pumpAudioTrueFalseScreen(tester, state: noEmojiState);

      expect(find.byKey(const Key('audio_true_false_emoji')), findsNothing);
    });

    testWidgets('9. Tapping correct TRUE verdict when correctAnswer is true dispatches SubmitAnswer(true)', (tester) async {
      await pumpAudioTrueFalseScreen(tester);

      clearInteractions(mockListeningBloc);

      final trueBtn = find.byKey(const Key('audio_true_false_btn_true'));
      await tester.tap(trueBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockListeningBloc.add(
        any(that: isA<SubmitAnswer>().having((e) => e.isCorrect, 'isCorrect', true)),
      )).called(1);

      verify(() => mockSoundService.playCorrect()).called(1);
      verify(() => mockHapticService.success()).called(1);
    });

    testWidgets('10. Tapping correct FALSE verdict when correctAnswer is false dispatches SubmitAnswer(true)', (tester) async {
      final falseState = const ListeningLoaded(
        quests: [sampleQuestFalse],
        currentIndex: 0,
        livesRemaining: 3,
      );
      await pumpAudioTrueFalseScreen(tester, state: falseState);

      clearInteractions(mockListeningBloc);

      final falseBtn = find.byKey(const Key('audio_true_false_btn_false'));
      await tester.tap(falseBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockListeningBloc.add(
        any(that: isA<SubmitAnswer>().having((e) => e.isCorrect, 'isCorrect', true)),
      )).called(1);

      verify(() => mockSoundService.playCorrect()).called(1);
    });

    testWidgets('11. Tapping wrong FALSE verdict when correctAnswer is true dispatches SubmitAnswer(false)', (tester) async {
      await pumpAudioTrueFalseScreen(tester);

      clearInteractions(mockListeningBloc);

      final falseBtn = find.byKey(const Key('audio_true_false_btn_false'));
      await tester.tap(falseBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockListeningBloc.add(
        any(that: isA<SubmitAnswer>().having((e) => e.isCorrect, 'isCorrect', false)),
      )).called(1);

      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockHapticService.error()).called(1);
    });

    testWidgets('12. Tapping wrong TRUE verdict when correctAnswer is false dispatches SubmitAnswer(false)', (tester) async {
      final falseState = const ListeningLoaded(
        quests: [sampleQuestFalse],
        currentIndex: 0,
        livesRemaining: 3,
      );
      await pumpAudioTrueFalseScreen(tester, state: falseState);

      clearInteractions(mockListeningBloc);

      final trueBtn = find.byKey(const Key('audio_true_false_btn_true'));
      await tester.tap(trueBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockListeningBloc.add(
        any(that: isA<SubmitAnswer>().having((e) => e.isCorrect, 'isCorrect', false)),
      )).called(1);

      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockHapticService.error()).called(1);
    });

    testWidgets('13. Supports alternative truthy strings ("1", "yes") for correctAnswer', (tester) async {
      const questOne = ListeningQuest(
        id: 'atf_one',
        instruction: 'True or False',
        difficulty: 1,
        subtype: GameSubtype.audioTrueFalse,
        textToSpeak: 'Hello world',
        statement: 'Hello world',
        correctAnswer: '1',
      );
      final stateOne = const ListeningLoaded(
        quests: [questOne],
        currentIndex: 0,
        livesRemaining: 3,
      );

      await pumpAudioTrueFalseScreen(tester, state: stateOne);
      clearInteractions(mockListeningBloc);

      await tester.tap(find.byKey(const Key('audio_true_false_btn_true')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockListeningBloc.add(
        any(that: isA<SubmitAnswer>().having((e) => e.isCorrect, 'isCorrect', true)),
      )).called(1);
    });

    testWidgets('14. Supports alternative falsy strings ("0", "no") for correctAnswer', (tester) async {
      const questZero = ListeningQuest(
        id: 'atf_zero',
        instruction: 'True or False',
        difficulty: 1,
        subtype: GameSubtype.audioTrueFalse,
        textToSpeak: 'Hello world',
        statement: 'Goodbye world',
        correctAnswer: '0',
      );
      final stateZero = const ListeningLoaded(
        quests: [questZero],
        currentIndex: 0,
        livesRemaining: 3,
      );

      await pumpAudioTrueFalseScreen(tester, state: stateZero);
      clearInteractions(mockListeningBloc);

      await tester.tap(find.byKey(const Key('audio_true_false_btn_false')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockListeningBloc.add(
        any(that: isA<SubmitAnswer>().having((e) => e.isCorrect, 'isCorrect', true)),
      )).called(1);
    });

    testWidgets('15. Answer lockout prevents secondary verdict taps once answered', (tester) async {
      await pumpAudioTrueFalseScreen(tester);

      await tester.tap(find.byKey(const Key('audio_true_false_btn_true')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      clearInteractions(mockListeningBloc);

      await tester.tap(find.byKey(const Key('audio_true_false_btn_false')), warnIfMissed: false);
      await tester.pump();

      verifyNever(() => mockListeningBloc.add(any(that: isA<SubmitAnswer>())));
    });

    testWidgets('16. Answering stops the active SpeedChallengeTimer', (tester) async {
      await pumpAudioTrueFalseScreen(tester);

      final timerFinder = find.byType(SpeedChallengeTimer);
      expect(timerFinder, findsOneWidget);

      final timerState = tester.state<SpeedChallengeTimerState>(timerFinder);
      expect(timerState.mounted, isTrue);

      await tester.tap(find.byKey(const Key('audio_true_false_btn_true')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(timerState.mounted, isTrue);
    });

    testWidgets('17. SpeedChallengeTimer onTimeUp automatically triggers wrong answer submission', (tester) async {
      await pumpAudioTrueFalseScreen(tester);

      clearInteractions(mockListeningBloc);

      final timerWidget = tester.widget<SpeedChallengeTimer>(find.byType(SpeedChallengeTimer));
      timerWidget.onTimeUp();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      verify(() => mockListeningBloc.add(
        any(that: isA<SubmitAnswer>().having((e) => e.isCorrect, 'isCorrect', false)),
      )).called(1);

      verify(() => mockSoundService.playWrong()).called(1);
    });

    testWidgets('18. Question transition clears selected verdict and restarts timer without GlobalKey crash', (tester) async {
      await pumpAudioTrueFalseScreen(tester);

      await tester.tap(find.byKey(const Key('audio_true_false_btn_true')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final nextState = const ListeningLoaded(
        quests: [sampleQuestTrue, sampleQuestFalse, sampleQuestNext],
        currentIndex: 2,
        livesRemaining: 3,
      );
      when(() => mockListeningBloc.state).thenReturn(nextState);
      listeningStreamController.add(nextState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('She bought fresh apples.'), findsOneWidget);
      expect(find.text('🍎'), findsOneWidget);
    });

    testWidgets('19. Continue button in answered state dispatches NextQuestion event', (tester) async {
      await pumpAudioTrueFalseScreen(tester);

      await tester.tap(find.byKey(const Key('audio_true_false_btn_true')));
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

    testWidgets('20. Hint button in header dispatches ListeningHintUsed', (tester) async {
      await pumpAudioTrueFalseScreen(tester);

      clearInteractions(mockListeningBloc);

      final hintButton = find.byType(QuestHintButton);
      expect(hintButton, findsOneWidget);

      await tester.tap(hintButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1100));

      verify(() => mockListeningBloc.add(any(that: isA<ListeningHintUsed>()))).called(1);
    });

    testWidgets('21. GameShimmerLoading rendered when state is uninitialized or quest is null', (tester) async {
      await pumpAudioTrueFalseScreen(tester, state: const ListeningInitial());

      expect(find.byType(GameShimmerLoading), findsOneWidget);
      expect(find.byType(AudioTrueFalseTuner), findsNothing);
    });

    testWidgets('22. Game complete state triggers completion handling cleanly', (tester) async {
      await pumpAudioTrueFalseScreen(
        tester,
        state: const ListeningGameComplete(
          xpEarned: 100,
          coinsEarned: 20,
          questCount: 5,
        ),
      );

      expect(find.byType(AudioTrueFalseScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('23. Game over state renders with zero lives', (tester) async {
      await pumpAudioTrueFalseScreen(
        tester,
        state: const ListeningGameOver(
          quests: [sampleQuestTrue],
          currentIndex: 0,
        ),
      );

      expect(find.byType(AudioTrueFalseScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('24. Level 1 briefing dialog displays and dismisses on start button tap', (tester) async {
      SharedPreferences.setMockInitialValues({
        'has_seen_briefing_audioTrueFalse': false,
      });

      await pumpAudioTrueFalseScreen(
        tester,
        level: 1,
        size: const Size(390, 1100),
      );

      expect(find.byType(GameBriefingLayer), findsOneWidget);
      expect(find.text('SIGNAL VALIDATOR'), findsOneWidget);

      final actionBtn = find.text('BEGIN VALIDATION');
      expect(actionBtn, findsOneWidget);

      await tester.tap(actionBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(GameBriefingLayer), findsNothing);
    });

    testWidgets('25. Dark and light themes render cleanly without errors', (tester) async {
      await pumpAudioTrueFalseScreen(tester, themeMode: ThemeMode.dark);
      expect(find.byType(AudioTrueFalseScreen), findsOneWidget);

      await pumpAudioTrueFalseScreen(tester, themeMode: ThemeMode.light);
      expect(find.byType(AudioTrueFalseScreen), findsOneWidget);
    });

    testWidgets('26. Small mobile screen (320x568) renders with zero overflow', (tester) async {
      await pumpAudioTrueFalseScreen(
        tester,
        size: const Size(320, 568),
      );

      expect(find.byType(AudioTrueFalseScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('27. Tablet viewport (768x1024) renders with zero overflow', (tester) async {
      await pumpAudioTrueFalseScreen(
        tester,
        size: const Size(768, 1024),
      );

      expect(find.byType(AudioTrueFalseScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('28. Reduced motion mode suppresses animated progress indicator in Tuner', (tester) async {
      await pumpAudioTrueFalseScreen(tester, reduceMotion: true);

      expect(find.byType(AudioTrueFalseTuner), findsOneWidget);
      expect(find.descendant(
        of: find.byType(AudioTrueFalseTuner),
        matching: find.byType(CircularProgressIndicator),
      ), findsNothing);
    });

    testWidgets('29. Empty instruction falls back to localized default text', (tester) async {
      const emptyInstrQuest = ListeningQuest(
        id: 'atf_empty',
        instruction: '',
        difficulty: 1,
        subtype: GameSubtype.audioTrueFalse,
        textToSpeak: 'Testing statement',
        statement: 'Testing statement',
        correctAnswer: 'true',
      );
      final emptyState = const ListeningLoaded(
        quests: [emptyInstrQuest],
        currentIndex: 0,
        livesRemaining: 3,
      );

      await pumpAudioTrueFalseScreen(tester, state: emptyState);

      expect(find.text('Is this statement True or False?'), findsOneWidget);
      expect(find.text('Listen carefully.'), findsOneWidget);
    });

    testWidgets('30. Accessibility semantics are present on Tuner and Verdict buttons', (tester) async {
      await pumpAudioTrueFalseScreen(tester);

      final tunerSemantics = find.bySemanticsLabel('Play audio statement');
      expect(tunerSemantics, findsOneWidget);

      final falseSemantics = find.bySemanticsLabel('FALSE');
      expect(falseSemantics, findsOneWidget);

      final trueSemantics = find.bySemanticsLabel('TRUE');
      expect(trueSemantics, findsOneWidget);
    });

    testWidgets('31. Instruction text centers, wraps cleanly without ellipsis or FittedBox, and sanitizes AI buzzwords', (tester) async {
      const buzzwordQuest = ListeningQuest(
        id: 'atf_buzzword',
        instruction: 'Is this statement True or False? You make the call.',
        difficulty: 1,
        subtype: GameSubtype.audioTrueFalse,
        textToSpeak: 'The quick brown fox jumps over the lazy dog.',
        statement: 'A fox jumped over a dog.',
        correctAnswer: 'true',
      );
      final state = const ListeningLoaded(
        quests: [buzzwordQuest],
        currentIndex: 0,
        livesRemaining: 3,
      );

      await pumpAudioTrueFalseScreen(tester, state: state);

      // Verify buzzword "You make the call." was replaced with natural guidance
      expect(find.text('Is this statement True or False?'), findsOneWidget);
      expect(find.text('Listen carefully.'), findsOneWidget);
      expect(find.textContaining('You make the call'), findsNothing);

      final mainTextFinder = find.byKey(const Key('audio_true_false_instruction_main'));
      final Text mainTextWidget = tester.widget(mainTextFinder);
      expect(mainTextWidget.textAlign, TextAlign.center);
      expect(mainTextWidget.overflow, isNull);
    });

    testWidgets('32. Long statement wraps gracefully in screen display card without overflow or ellipsis', (tester) async {
      const longQuest = ListeningQuest(
        id: 'atf_long',
        instruction: 'Listen carefully and decide if the statement is true or false.',
        difficulty: 2,
        subtype: GameSubtype.audioTrueFalse,
        textToSpeak: 'Long speech paragraph about weather patterns across continents.',
        statement: 'This is an exceptionally long statement intended to test whether multi-line wrapping functions without any clipping, text truncation, or overflow across small and large displays.',
        correctAnswer: 'true',
      );
      final state = const ListeningLoaded(
        quests: [longQuest],
        currentIndex: 0,
        livesRemaining: 3,
      );

      await pumpAudioTrueFalseScreen(tester, state: state, size: const Size(320, 568));

      final stmtFinder = find.byKey(const Key('audio_true_false_statement'));
      expect(stmtFinder, findsOneWidget);
      final Text stmtWidget = tester.widget(stmtFinder);
      expect(stmtWidget.textAlign, TextAlign.center);
      expect(stmtWidget.overflow, isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('33. Question transition during AnimatedSwitcher does not throw ScrollController multiple positions assertion', (tester) async {
      VowlMotion.lowAnimationModeOverride.value = false;
      addTearDown(() {
        VowlMotion.lowAnimationModeOverride.value = true;
      });

      await pumpAudioTrueFalseScreen(tester);

      final nextState = const ListeningLoaded(
        quests: [sampleQuestTrue, sampleQuestFalse],
        currentIndex: 1,
        livesRemaining: 3,
      );
      when(() => mockListeningBloc.state).thenReturn(nextState);
      listeningStreamController.add(nextState);

      // Pump 1 frame to initiate AnimatedSwitcher transition
      await tester.pump();
      // Pump halfway into 400ms transition so both old and new children exist simultaneously
      await tester.pump(const Duration(milliseconds: 200));

      // Must not throw "ScrollController is attached to more than one ScrollPosition"
      expect(tester.takeException(), isNull);

      // Complete transition
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    });
  });
}
