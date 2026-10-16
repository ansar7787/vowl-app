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
import 'package:vowl/core/presentation/game_mechanics/speaking/speak_to_confirm_overlay.dart';
import 'package:vowl/core/presentation/widgets/game_feedback_card.dart';
import 'package:vowl/core/presentation/widgets/quest_hint_button.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/analytics_service.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/audio_recording_service.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/speech_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/features/vocabulary/idioms/presentation/pages/idioms_screen.dart';
import 'package:vowl/features/vocabulary/idioms/presentation/widgets/idioms_chat_bubbles.dart';
import 'package:vowl/features/vocabulary/idioms/presentation/widgets/idioms_option_chip.dart';
import 'package:vowl/features/vocabulary/idioms/presentation/widgets/idioms_origin_card.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';

class MockVocabularyBloc extends MockBloc<VocabularyEvent, VocabularyState>
    implements VocabularyBloc {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockEconomyBloc extends MockBloc<EconomyEvent, EconomyState>
    implements EconomyBloc {}

class MockHapticService extends Mock implements HapticService {}

class MockSoundService extends Mock implements SoundService {}

class MockTtsService extends Mock implements TtsService {}

class MockAudioRecordingService extends Mock implements AudioRecordingService {}

class MockSpeechService extends Mock implements SpeechService {}

class MockLocaleService extends Mock implements LocaleService {}

class MockAppLogger extends Mock implements AppLogger {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockAdService extends Mock implements AdService {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

class FakeVocabularyEvent extends Fake implements VocabularyEvent {}

class FakeVocabularyState extends Fake implements VocabularyState {}

class FakeEconomyEvent extends Fake implements EconomyEvent {}

class FakeEconomyState extends Fake implements EconomyState {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  late MockVocabularyBloc mockVocabularyBloc;
  late MockAuthBloc mockAuthBloc;
  late MockEconomyBloc mockEconomyBloc;
  late MockHapticService mockHapticService;
  late MockSoundService mockSoundService;
  late MockTtsService mockTtsService;
  late MockAudioRecordingService mockAudioRecordingService;
  late MockSpeechService mockSpeechService;
  late MockLocaleService mockLocaleService;
  late MockAppLogger mockAppLogger;
  late MockAnalyticsService mockAnalyticsService;
  late MockAdService mockAdService;
  late MockNetworkInfo mockNetworkInfo;
  late StreamController<VocabularyState> vocabularyStreamController;

  VocabularyQuest createQuest({
    String id = 'quest_idiom_1',
    String instruction = 'Decipher the idiom transmission.',
    String correctAnswer = 'Bite the bullet',
    List<String> options = const [
      'Bite the bullet',
      'Break a leg',
      'Piece of cake',
      'Spill the beans',
    ],
    String? topicEmoji = '🤐 🔫',
    String? hint = 'To endure a painful situation with courage.',
    String? origin =
        'Soldiers used to bite on a lead bullet during battlefield surgery without anesthesia.',
    String? literalVsFigurative =
        'Literal: Champing on ammunition. Figurative: Facing hardship with stoic grit.',
    String? contextSentence =
        'She decided to bite the bullet and have the difficult conversation.',
    String? explanation =
        'Bite the bullet means to accept something unpleasant because it is inevitable.',
    int difficulty = 1,
  }) {
    return VocabularyQuest(
      id: id,
      type: QuestType.vocabulary,
      subtype: GameSubtype.idioms,
      instruction: instruction,
      correctAnswer: correctAnswer,
      options: options,
      topicEmoji: topicEmoji,
      hint: hint,
      origin: origin,
      literalVsFigurative: literalVsFigurative,
      contextSentence: contextSentence,
      explanation: explanation,
      difficulty: difficulty,
    );
  }

  final sampleQuest1 = createQuest();

  final sampleQuest2 = createQuest(
    id: 'quest_idiom_2',
    correctAnswer: 'Break a leg',
    options: [
      'Break a leg',
      'Under the weather',
      'Cold feet',
      'Call it a day',
    ],
    topicEmoji: '🎭 🦵',
    hint: 'Good luck before a theatrical performance.',
    origin:
        'In ancient theatre, bowing deeply might break the visual line of the leg.',
    literalVsFigurative:
        'Literal: Fracturing a bone. Figurative: Wishing someone good performance luck.',
    contextSentence: 'The director told the actors to break a leg before opening night.',
  );

  final sampleMinimalQuest = createQuest(
    id: 'quest_idiom_min',
    correctAnswer: 'On the fence',
    options: ['On the fence', 'Over the moon'],
    topicEmoji: '',
    hint: '',
    origin: '',
    literalVsFigurative: null,
    contextSentence: '',
  );

  final testLoadedState = VocabularyLoaded(
    quests: [sampleQuest1, sampleQuest2],
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
    wrongCount: 0,
    hintUsed: false,
    isFinalFailure: false,
  );

  setUpAll(() {
    registerFallbackValue(FakeVocabularyEvent());
    registerFallbackValue(FakeVocabularyState());
    registerFallbackValue(FakeEconomyEvent());
    registerFallbackValue(FakeEconomyState());
    registerFallbackValue(const SubmitAnswer(true));
    registerFallbackValue(const SubmitAnswer(false));
    registerFallbackValue(const NextQuestion());
    registerFallbackValue(const VocabularyHintUsed());
    registerFallbackValue(
      const FetchVocabularyQuests(gameType: GameSubtype.idioms, level: 1),
    );
    registerFallbackValue(
      const FetchVocabularyQuests(gameType: GameSubtype.idioms, level: 2),
    );
  });

  setUp(() {
    VowlMotion.lowAnimationModeOverride.value = true;

    mockVocabularyBloc = MockVocabularyBloc();
    mockAuthBloc = MockAuthBloc();
    mockEconomyBloc = MockEconomyBloc();
    mockHapticService = MockHapticService();
    mockSoundService = MockSoundService();
    mockTtsService = MockTtsService();
    mockAudioRecordingService = MockAudioRecordingService();
    mockSpeechService = MockSpeechService();
    mockLocaleService = MockLocaleService();
    mockAppLogger = MockAppLogger();
    mockAnalyticsService = MockAnalyticsService();
    mockAdService = MockAdService();
    mockNetworkInfo = MockNetworkInfo();

    vocabularyStreamController = StreamController<VocabularyState>.broadcast();

    when(() => mockVocabularyBloc.state).thenReturn(testLoadedState);
    when(
      () => mockVocabularyBloc.stream,
    ).thenAnswer((_) => vocabularyStreamController.stream);

    when(() => mockEconomyBloc.state).thenReturn(const EconomyState());
    when(
      () => mockEconomyBloc.stream,
    ).thenAnswer((_) => const Stream<EconomyState>.empty());
    when(() => mockEconomyBloc.add(any())).thenReturn(null);

    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(
        const UserEntity(
          id: 'test_user_id',
          email: 'test@vowl.app',
          displayName: 'Idioms Master',
          hintCount: 3,
        ),
      ),
    );
    when(
      () => mockAuthBloc.stream,
    ).thenAnswer((_) => const Stream<AuthState>.empty());

    when(
      () => mockLocaleService.tr(
        any(),
        fallback: any(named: 'fallback'),
        args: any(named: 'args'),
      ),
    ).thenAnswer(
      (inv) =>
          inv.namedArguments[#fallback] as String? ??
          inv.positionalArguments.first as String,
    );

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});
    when(() => mockHapticService.heavy()).thenAnswer((_) async {});
    when(() => mockHapticService.warning()).thenAnswer((_) async {});

    when(() => mockSoundService.stopAudio()).thenAnswer((_) async {});
    when(() => mockSoundService.stopTts()).thenAnswer((_) async {});
    when(
      () => mockSoundService.playTts(
        any(),
        speed: any(named: 'speed'),
        locale: any(named: 'locale'),
      ),
    ).thenAnswer((_) async {});
    when(() => mockSoundService.playCorrect()).thenAnswer((_) async {});
    when(() => mockSoundService.playWrong()).thenAnswer((_) async {});
    when(() => mockSoundService.playHint()).thenAnswer((_) async {});
    when(() => mockSoundService.playClick()).thenAnswer((_) async {});
    when(() => mockSoundService.playLevelComplete()).thenAnswer((_) async {});
    when(() => mockSoundService.playFile(any())).thenAnswer((_) async {});

    when(() => mockTtsService.stop()).thenAnswer((_) async {});
    when(
      () => mockTtsService.speak(
        any(),
        rate: any(named: 'rate'),
        locale: any(named: 'locale'),
        pauseMarkers: any(named: 'pauseMarkers'),
      ),
    ).thenAnswer((_) async {});

    when(() => mockAudioRecordingService.isRecording).thenReturn(false);
    when(() => mockAudioRecordingService.hasPermission()).thenAnswer((_) async => true);
    when(() => mockAudioRecordingService.startRecording()).thenAnswer((_) async => true);
    when(() => mockAudioRecordingService.stopRecording()).thenAnswer((_) async => 'fake_recording.m4a');
    when(() => mockAudioRecordingService.dispose()).thenAnswer((_) async {});

    when(() => mockSpeechService.isListening).thenReturn(false);
    when(() => mockSpeechService.isPlaying).thenReturn(false);
    when(() => mockSpeechService.stop()).thenAnswer((_) async {});
    when(() => mockSpeechService.cancel()).thenAnswer((_) async {});
    when(() => mockSpeechService.initializeStt()).thenAnswer((_) async => true);

    when(() => mockAnalyticsService.logSelfEvaluation(any())).thenAnswer((_) async {});

    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    di.sl.registerSingleton<HapticService>(mockHapticService);

    if (di.sl.isRegistered<SoundService>()) {
      di.sl.unregister<SoundService>();
    }
    di.sl.registerSingleton<SoundService>(mockSoundService);

    if (di.sl.isRegistered<TtsService>()) {
      di.sl.unregister<TtsService>();
    }
    di.sl.registerSingleton<TtsService>(mockTtsService);

    if (di.sl.isRegistered<AudioRecordingService>()) {
      di.sl.unregister<AudioRecordingService>();
    }
    di.sl.registerSingleton<AudioRecordingService>(mockAudioRecordingService);

    if (di.sl.isRegistered<SpeechService>()) {
      di.sl.unregister<SpeechService>();
    }
    di.sl.registerSingleton<SpeechService>(mockSpeechService);

    if (di.sl.isRegistered<LocaleService>()) {
      di.sl.unregister<LocaleService>();
    }
    di.sl.registerSingleton<LocaleService>(mockLocaleService);

    if (di.sl.isRegistered<AppLogger>()) {
      di.sl.unregister<AppLogger>();
    }
    di.sl.registerSingleton<AppLogger>(mockAppLogger);

    if (di.sl.isRegistered<AnalyticsService>()) {
      di.sl.unregister<AnalyticsService>();
    }
    di.sl.registerSingleton<AnalyticsService>(mockAnalyticsService);

    if (di.sl.isRegistered<AdService>()) {
      di.sl.unregister<AdService>();
    }
    di.sl.registerSingleton<AdService>(mockAdService);

    if (di.sl.isRegistered<NetworkInfo>()) {
      di.sl.unregister<NetworkInfo>();
    }
    di.sl.registerSingleton<NetworkInfo>(mockNetworkInfo);
  });

  tearDown(() {
    vocabularyStreamController.close();
    if (di.sl.isRegistered<HapticService>()) {
      di.sl.unregister<HapticService>();
    }
    if (di.sl.isRegistered<SoundService>()) {
      di.sl.unregister<SoundService>();
    }
    if (di.sl.isRegistered<TtsService>()) {
      di.sl.unregister<TtsService>();
    }
    if (di.sl.isRegistered<AudioRecordingService>()) {
      di.sl.unregister<AudioRecordingService>();
    }
    if (di.sl.isRegistered<SpeechService>()) {
      di.sl.unregister<SpeechService>();
    }
    if (di.sl.isRegistered<LocaleService>()) {
      di.sl.unregister<LocaleService>();
    }
    if (di.sl.isRegistered<AppLogger>()) {
      di.sl.unregister<AppLogger>();
    }
    if (di.sl.isRegistered<AnalyticsService>()) {
      di.sl.unregister<AnalyticsService>();
    }
    if (di.sl.isRegistered<AdService>()) {
      di.sl.unregister<AdService>();
    }
    if (di.sl.isRegistered<NetworkInfo>()) {
      di.sl.unregister<NetworkInfo>();
    }
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    VocabularyState? state,
    Size size = const Size(390, 844),
    ThemeMode themeMode = ThemeMode.dark,
    int level = 2,
    double textScale = 1.0,
    bool disableAnimations = true,
  }) async {
    tester.view.physicalSize = Size(size.width * 2, size.height * 2);
    tester.view.devicePixelRatio = 2.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final targetState = state ?? testLoadedState;
    when(() => mockVocabularyBloc.state).thenReturn(targetState);

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<VocabularyBloc>.value(value: mockVocabularyBloc),
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<EconomyBloc>.value(value: mockEconomyBloc),
        ],
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) => MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            home: MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: TextScaler.linear(textScale),
                disableAnimations: disableAnimations,
              ),
              child: Scaffold(
                body: IdiomsScreen(
                  level: level,
                  gameType: GameSubtype.idioms,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('Group 1: Initial Screen Layout & Phase 1 Presentation', () {
    testWidgets('renders IdiomsScreen and initializes quests fetch', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(find.byType(IdiomsScreen), findsOneWidget);
      expect(find.text('EMOJIFY: SECURE CHANNEL'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);

      verify(
        () => mockVocabularyBloc.add(
          const FetchVocabularyQuests(
            gameType: GameSubtype.idioms,
            level: 2,
          ),
        ),
      ).called(1);
    });

    testWidgets('displays incoming transmission and sender avatar', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(find.text('INCOMING TRANSMISSION...'), findsOneWidget);
      expect(find.byIcon(Icons.psychology_alt_rounded), findsOneWidget);
    });

    testWidgets('displays emoji clues and hint text message in chat', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(find.byType(IdiomsStrangerMessage), findsOneWidget);
      expect(find.text('🤐 🔫'), findsOneWidget);

      expect(find.byType(IdiomsStrangerTextMessage), findsOneWidget);
      expect(
        find.text('To endure a painful situation with courage.'),
        findsOneWidget,
      );
    });

    testWidgets('renders all option chips with uppercase text', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(find.byType(IdiomsOptionChip), findsNWidgets(4));
      expect(find.text('BITE THE BULLET'), findsOneWidget);
      expect(find.text('BREAK A LEG'), findsOneWidget);
      expect(find.text('PIECE OF CAKE'), findsOneWidget);
      expect(find.text('SPILL THE BEANS'), findsOneWidget);
    });

    testWidgets('Phase 2 elements are not visible before Phase 1 passes', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(find.byType(IdiomsOriginCard), findsNothing);
      expect(find.byType(SpeakToConfirmOverlay), findsNothing);
    });
  });

  group('Group 2: Phase 1 Option Selection & Visual Feedback', () {
    testWidgets('selecting incorrect option submits wrong answer after delay', (
      tester,
    ) async {
      await pumpScreen(tester);

      // Tap wrong option
      await tester.tap(find.text('BREAK A LEG'));
      await tester.pump();

      // Selected message appears in chat
      expect(find.byType(IdiomsUserMessage), findsOneWidget);
      expect(find.text('BREAK A LEG'), findsWidgets);

      // Elapse 650ms timer
      await tester.pump(const Duration(milliseconds: 650));

      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockHapticService.error()).called(1);
      verify(
        () => mockVocabularyBloc.add(const SubmitAnswer(false)),
      ).called(1);

      // Shows failure transmission
      expect(
        find.text('DECRYPTION FAILED. RE-EVALUATE SEQUENCE.'),
        findsOneWidget,
      );
      // Phase 2 remains hidden
      expect(find.byType(IdiomsOriginCard), findsNothing);
    });

    testWidgets('selecting correct option advances to Phase 2 with success haptics', (
      tester,
    ) async {
      await pumpScreen(tester);

      // Tap correct option
      await tester.tap(find.text('BITE THE BULLET'));
      await tester.pump();

      // Elapse 650ms timer
      await tester.pump(const Duration(milliseconds: 650));

      verify(() => mockHapticService.success()).called(1);

      // Elapse scroll animation timer
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 600));

      // Phase 2 components now mounted
      expect(find.byType(IdiomsOriginCard), findsOneWidget);
      expect(find.byType(SpeakToConfirmOverlay), findsOneWidget);
    });

    testWidgets('tapping options is ignored when answer is already being processed', (
      tester,
    ) async {
      await pumpScreen(tester);

      // Tap first option
      await tester.tap(find.text('BITE THE BULLET'));
      await tester.pump();

      // Tap another option immediately before timer finishes
      await tester.tap(find.text('PIECE OF CAKE'), warnIfMissed: false);
      await tester.pump();

      // Elapse submit timer and scroll animation timers
      await tester.pump(const Duration(milliseconds: 650));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 600));

      // Only first selection was processed
      expect(find.text('BITE THE BULLET'), findsWidgets);
    });
  });

  group('Group 3: Phase 2 Origin Card & Speak-To-Confirm Overlay', () {
    testWidgets('displays origin story and literal vs figurative breakdown', (
      tester,
    ) async {
      await pumpScreen(tester);

      // Pass phase 1
      await tester.tap(find.text('BITE THE BULLET'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 650));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('IDIOM ORIGIN'), findsOneWidget);
      expect(
        find.text(
          'Soldiers used to bite on a lead bullet during battlefield surgery without anesthesia.',
        ),
        findsOneWidget,
      );
      expect(find.text('LITERAL VS FIGURATIVE'), findsOneWidget);
      expect(
        find.text(
          'Literal: Champing on ammunition. Figurative: Facing hardship with stoic grit.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('confirming pronunciation in Phase 2 submits correct answer', (
      tester,
    ) async {
      await pumpScreen(tester);

      // Pass phase 1
      await tester.tap(find.text('BITE THE BULLET'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 650));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(SpeakToConfirmOverlay), findsOneWidget);

      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byType(SpeakToConfirmOverlay),
      );
      overlay.onConfirmed();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockHapticService.success()).called(greaterThanOrEqualTo(1));
      verify(() => mockSoundService.playCorrect()).called(1);
      verify(() => mockVocabularyBloc.add(const SubmitAnswer(true))).called(1);
    });

    testWidgets('skipping verbal confirmation in Phase 2 submits wrong answer', (
      tester,
    ) async {
      await pumpScreen(tester);

      // Pass phase 1
      await tester.tap(find.text('BITE THE BULLET'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 650));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(SpeakToConfirmOverlay), findsOneWidget);

      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byType(SpeakToConfirmOverlay),
      );
      overlay.onSkipped();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockHapticService.error()).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockVocabularyBloc.add(const SubmitAnswer(false))).called(1);
    });
  });

  group('Group 4: Hint System & Audio Lifecycle', () {
    testWidgets('tapping header hint button dispatches VocabularyHintUsed', (
      tester,
    ) async {
      await pumpScreen(tester);

      final hintButton = find.byType(QuestHintButton);
      expect(hintButton, findsOneWidget);

      await tester.tap(hintButton);
      await tester.pump();

      verify(() => mockVocabularyBloc.add(const VocabularyHintUsed())).called(1);
    });
  });

  group('Group 5: State Progression, Dialogs & Error Handling', () {
    testWidgets('displays GameShimmerLoading when state is uninitialized', (
      tester,
    ) async {
      const emptyState = VocabularyInitial();
      await pumpScreen(tester, state: emptyState);

      expect(find.byType(GameShimmerLoading), findsOneWidget);
    });

    testWidgets('renders GameFeedbackCard on correct answer and CONTINUE dispatches NextQuestion', (
      tester,
    ) async {
      await pumpScreen(tester);

      // Pass phase 1
      await tester.tap(find.text('BITE THE BULLET'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 650));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 600));

      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byType(SpeakToConfirmOverlay),
      );
      overlay.onConfirmed();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Emit answered state
      final answeredState = testLoadedState.copyWith(
        answerStatus: AnswerStatus.correct,
      );
      vocabularyStreamController.add(answeredState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(GameFeedbackCard), findsOneWidget);
      final continueBtn = find.text('CONTINUE');
      expect(continueBtn, findsOneWidget);

      await tester.tap(continueBtn);
      await tester.pump();

      verify(() => mockVocabularyBloc.add(const NextQuestion())).called(1);
    });

    testWidgets('renders GameFeedbackCard on wrong answer with TRY AGAIN', (
      tester,
    ) async {
      await pumpScreen(tester);

      // Select wrong option in phase 1
      await tester.tap(find.text('BREAK A LEG'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 650));

      final wrongState = testLoadedState.copyWith(
        answerStatus: AnswerStatus.incorrect,
        wrongCount: 1,
      );
      vocabularyStreamController.add(wrongState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(GameFeedbackCard), findsOneWidget);
      expect(find.text('TRY AGAIN'), findsWidgets);
    });

    testWidgets('advancing to next question resets Phase 1 & 2 state cleanly', (
      tester,
    ) async {
      await pumpScreen(tester);

      // Advance to quest 2
      final nextQuestState = testLoadedState.copyWith(
        currentIndex: 1,
        answerStatus: AnswerStatus.unanswered,
      );
      vocabularyStreamController.add(nextQuestState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // New emoji clues and options for quest 2
      expect(find.text('🎭 🦵'), findsOneWidget);
      expect(find.text('BREAK A LEG'), findsOneWidget);
      expect(find.byType(IdiomsOriginCard), findsNothing);
    });

    testWidgets('VocabularyGameComplete state displays LEVEL COMPLETE dialog and disposes cleanly', (
      tester,
    ) async {
      await pumpScreen(tester);

      const completeState = VocabularyGameComplete(
        xpEarned: 100,
        coinsEarned: 50,
        questCount: 2,
      );
      vocabularyStreamController.add(completeState);
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('LEVEL COMPLETE!'), findsOneWidget);

      Navigator.of(tester.element(find.text('LEVEL COMPLETE!'))).pop();
      await tester.pump(const Duration(milliseconds: 500));
    });
  });

  group('Group 6: Viewport Responsiveness, Theming & Accessibility', () {
    testWidgets('renders on compact mobile screen (320x568) without overflow', (
      tester,
    ) async {
      await pumpScreen(tester, size: const Size(320, 568));

      expect(find.byType(IdiomsScreen), findsOneWidget);
      expect(find.text('EMOJIFY: SECURE CHANNEL'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders on tablet screen (768x1024) with responsive layout', (
      tester,
    ) async {
      await pumpScreen(tester, size: const Size(768, 1024));

      expect(find.byType(IdiomsScreen), findsOneWidget);
      expect(find.text('EMOJIFY: SECURE CHANNEL'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders in landscape orientation (800x480) without overflow', (
      tester,
    ) async {
      await pumpScreen(tester, size: const Size(800, 480));

      expect(find.byType(IdiomsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('adapts to high text scale (1.5x) gracefully', (
      tester,
    ) async {
      await pumpScreen(tester, textScale: 1.5);

      expect(find.byType(IdiomsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly in light theme mode', (tester) async {
      await pumpScreen(tester, themeMode: ThemeMode.light);

      expect(find.byType(IdiomsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('handles minimal quest data gracefully without crash', (
      tester,
    ) async {
      final minimalState = VocabularyLoaded(
        quests: [sampleMinimalQuest],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.unanswered,
        wrongCount: 0,
        hintUsed: false,
        isFinalFailure: false,
      );

      await pumpScreen(tester, state: minimalState);
      expect(find.byType(IdiomsScreen), findsOneWidget);
      expect(find.text('ON THE FENCE'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

