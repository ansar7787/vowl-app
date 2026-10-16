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
import 'package:vowl/core/utils/speech_service.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/features/vocabulary/contextual_usage/presentation/pages/contextual_usage_screen.dart';
import 'package:vowl/features/vocabulary/contextual_usage/presentation/widgets/contextual_usage_card.dart';
import 'package:vowl/features/vocabulary/contextual_usage/presentation/widgets/contextual_usage_option_chip.dart';
import 'package:vowl/features/vocabulary/contextual_usage/presentation/widgets/contextual_usage_register_meter.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  late MockVocabularyBloc mockVocabularyBloc;
  late MockAuthBloc mockAuthBloc;
  late MockEconomyBloc mockEconomyBloc;
  late MockHapticService mockHapticService;
  late MockSoundService mockSoundService;
  late MockTtsService mockTtsService;
  late MockAudioRecordingService mockAudioRecorder;
  late MockSpeechService mockSpeechService;
  late MockLocaleService mockLocaleService;
  late MockAppLogger mockAppLogger;
  late MockAnalyticsService mockAnalyticsService;
  late MockAdService mockAdService;
  late MockNetworkInfo mockNetworkInfo;
  late StreamController<VocabularyState> vocabularyStreamController;

  VocabularyQuest createQuest({
    String id = 'quest_contextual_1',
    String word = 'BORROW',
    String prompt = "Could I _____ your pen? I'll give it back after class.",
    String correctAnswer = 'BORROW',
    List<String> options = const ['LEND', 'RENT', 'BORROW', 'LOAN'],
    String instruction = 'Select the word that best completes the sentence.',
    int registerLevel = 2,
    String nuanceDifference =
        'Borrow means to take temporarily; lend means to give temporarily.',
    String usageExample = "May I borrow your textbook for the evening?",
    String explanation =
        'Borrow means to take something temporarily, intending to return it.',
    String hint =
        'Think about whether the speaker wants to receive something temporarily.',
    int difficulty = 1,
  }) {
    return VocabularyQuest(
      id: id,
      type: QuestType.vocabulary,
      subtype: GameSubtype.contextualUsage,
      word: word,
      prompt: prompt,
      correctAnswer: correctAnswer,
      options: options,
      instruction: instruction,
      registerLevel: registerLevel,
      nuanceDifference: nuanceDifference,
      usageExample: usageExample,
      explanation: explanation,
      hint: hint,
      difficulty: difficulty,
    );
  }

  final sampleQuest1 = createQuest();

  final sampleQuest2 = createQuest(
    id: 'quest_contextual_2',
    word: 'LEND',
    prompt: 'My sister offered to _____ me some money until payday.',
    correctAnswer: 'LEND',
    options: ['BORROW', 'LEND', 'OWE', 'GIVE'],
    instruction: 'Complete the sentence with the appropriate word.',
    registerLevel: 3,
    nuanceDifference: 'Lend refers to the person providing the money.',
    usageExample: 'I can lend you twenty dollars until tomorrow.',
    hint: 'Ask yourself who is doing the giving here.',
  );

  final sampleMinimalQuest = const VocabularyQuest(
    id: 'quest_contextual_minimal',
    type: QuestType.vocabulary,
    subtype: GameSubtype.contextualUsage,
    word: 'ADAPT',
    prompt: 'Species must _____ to survive in changing environments.',
    correctAnswer: 'ADAPT',
    options: ['ADAPT', 'ADOPT'],
    instruction: 'Choose the best word.',
    difficulty: 2,
  );

  final testLoadedState = VocabularyLoaded(
    quests: [sampleQuest1, sampleQuest2],
    currentIndex: 0,
    livesRemaining: 3,
    wrongCount: 0,
    hintUsed: false,
    answerStatus: AnswerStatus.unanswered,
  );

  setUpAll(() {
    registerFallbackValue(const SubmitAnswer(true));
    registerFallbackValue(const SubmitAnswer(false));
    registerFallbackValue(const NextQuestion());
    registerFallbackValue(const VocabularyHintUsed());
    registerFallbackValue(
      const FetchVocabularyQuests(
        gameType: GameSubtype.contextualUsage,
        level: 2,
      ),
    );
    registerFallbackValue(sampleQuest1);
  });

  setUp(() async {
    mockVocabularyBloc = MockVocabularyBloc();
    mockAuthBloc = MockAuthBloc();
    mockEconomyBloc = MockEconomyBloc();
    mockHapticService = MockHapticService();
    mockSoundService = MockSoundService();
    mockTtsService = MockTtsService();
    mockAudioRecorder = MockAudioRecordingService();
    mockSpeechService = MockSpeechService();
    mockLocaleService = MockLocaleService();
    mockAppLogger = MockAppLogger();
    mockAnalyticsService = MockAnalyticsService();
    mockAdService = MockAdService();
    mockNetworkInfo = MockNetworkInfo();

    vocabularyStreamController = StreamController<VocabularyState>.broadcast();

    when(() => mockVocabularyBloc.state).thenReturn(testLoadedState);
    whenListen(
      mockVocabularyBloc,
      vocabularyStreamController.stream,
      initialState: testLoadedState,
    );

    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(
        const UserEntity(
          id: 'test_user_contextual',
          email: 'contextual@vowl.app',
          displayName: 'Contextual Learner',
          hintCount: 3,
        ),
      ),
    );
    when(() => mockAuthBloc.stream)
        .thenAnswer((_) => const Stream<AuthState>.empty());

    when(() => mockEconomyBloc.state).thenReturn(const EconomyState());
    when(() => mockEconomyBloc.stream)
        .thenAnswer((_) => const Stream<EconomyState>.empty());

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});
    when(() => mockHapticService.heavy()).thenAnswer((_) async {});

    when(() => mockSoundService.playCorrect()).thenAnswer((_) async {});
    when(() => mockSoundService.playWrong()).thenAnswer((_) async {});
    when(() => mockSoundService.playTts(any())).thenAnswer((_) async {});
    when(() => mockSoundService.stopTts()).thenAnswer((_) async {});
    when(() => mockSoundService.stopAudio()).thenAnswer((_) async {});
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
      ),
    ).thenAnswer((_) async {});

    when(() => mockAudioRecorder.hasPermission()).thenAnswer((_) async => true);
    when(() => mockAudioRecorder.startRecording()).thenAnswer((_) async => true);
    when(
      () => mockAudioRecorder.stopRecording(),
    ).thenAnswer((_) async => '/tmp/contextual_test.m4a');
    when(() => mockAudioRecorder.isRecording).thenReturn(false);
    when(() => mockAudioRecorder.dispose()).thenAnswer((_) async {});

    when(() => mockSpeechService.initializeStt()).thenAnswer((_) async => true);
    when(() => mockSpeechService.stop()).thenAnswer((_) async {});
    when(() => mockSpeechService.cancel()).thenAnswer((_) async {});
    when(() => mockSpeechService.isListening).thenReturn(false);
    when(() => mockSpeechService.isPlaying).thenReturn(false);

    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

    await di.sl.reset();
    di.sl.registerSingleton<HapticService>(mockHapticService);
    di.sl.registerSingleton<SoundService>(mockSoundService);
    di.sl.registerSingleton<TtsService>(mockTtsService);
    di.sl.registerSingleton<AudioRecordingService>(mockAudioRecorder);
    di.sl.registerSingleton<SpeechService>(mockSpeechService);
    di.sl.registerSingleton<LocaleService>(mockLocaleService);
    di.sl.registerSingleton<AppLogger>(mockAppLogger);
    di.sl.registerSingleton<AnalyticsService>(mockAnalyticsService);
    di.sl.registerSingleton<AdService>(mockAdService);
    di.sl.registerSingleton<NetworkInfo>(mockNetworkInfo);

    VowlMotion.lowAnimationModeOverride.value = true;
  });

  tearDown(() async {
    await vocabularyStreamController.close();
    VowlMotion.lowAnimationModeOverride.value = false;
    if (di.sl.isRegistered<HapticService>()) di.sl.unregister<HapticService>();
    if (di.sl.isRegistered<SoundService>()) di.sl.unregister<SoundService>();
    if (di.sl.isRegistered<TtsService>()) di.sl.unregister<TtsService>();
    if (di.sl.isRegistered<AudioRecordingService>()) {
      di.sl.unregister<AudioRecordingService>();
    }
    if (di.sl.isRegistered<SpeechService>()) {
      di.sl.unregister<SpeechService>();
    }
    if (di.sl.isRegistered<LocaleService>()) di.sl.unregister<LocaleService>();
    if (di.sl.isRegistered<AppLogger>()) di.sl.unregister<AppLogger>();
    if (di.sl.isRegistered<AnalyticsService>()) {
      di.sl.unregister<AnalyticsService>();
    }
    if (di.sl.isRegistered<AdService>()) di.sl.unregister<AdService>();
    if (di.sl.isRegistered<NetworkInfo>()) di.sl.unregister<NetworkInfo>();
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    VocabularyState? state,
    int level = 2,
    GameSubtype gameType = GameSubtype.contextualUsage,
    Size size = const Size(390, 844),
    double textScaleFactor = 1.0,
    ThemeMode themeMode = ThemeMode.dark,
    bool reduceMotion = true,
  }) async {
    VowlMotion.lowAnimationModeOverride.value = reduceMotion;
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
          builder: (context, child) => MaterialApp(
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,
            home: MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: TextScaler.linear(textScaleFactor),
                disableAnimations: reduceMotion,
              ),
              child: ContextualUsageScreen(level: level, gameType: gameType),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('1. Initial Screen & Layout Setup', () {
    testWidgets('1.1 renders ContextualUsageCard with question prompt', (
      tester,
    ) async {
      await pumpScreen(tester);
      expect(find.byType(ContextualUsageCard), findsOneWidget);
      expect(find.textContaining('Could I'), findsOneWidget);
    });

    testWidgets('1.2 renders instruction banner in uppercase', (tester) async {
      await pumpScreen(tester);
      expect(
        find.text('SELECT THE WORD THAT BEST COMPLETES THE SENTENCE.'),
        findsOneWidget,
      );
    });

    testWidgets('1.3 renders all option chips from quest options', (
      tester,
    ) async {
      await pumpScreen(tester);
      expect(find.byType(ContextualUsageOptionChip), findsNWidgets(4));
      expect(find.text('LEND'), findsWidgets);
      expect(find.text('RENT'), findsWidgets);
      expect(find.text('BORROW'), findsWidgets);
      expect(find.text('LOAN'), findsWidgets);
    });

    testWidgets('1.4 renders minimal quest with 2 options cleanly', (
      tester,
    ) async {
      final minimalState = testLoadedState.copyWith(
        quests: [sampleMinimalQuest],
        currentIndex: 0,
      );
      await pumpScreen(tester, state: minimalState);
      expect(find.byType(ContextualUsageCard), findsOneWidget);
      expect(find.textContaining('Species must'), findsOneWidget);
      expect(find.byType(ContextualUsageOptionChip), findsNWidgets(2));
      expect(find.text('ADAPT'), findsWidgets);
      expect(find.text('ADOPT'), findsWidgets);
    });

    testWidgets('1.5 dispatches FetchVocabularyQuests on mount', (tester) async {
      await pumpScreen(tester, level: 3);
      verify(
        () => mockVocabularyBloc.add(
          const FetchVocabularyQuests(
            gameType: GameSubtype.contextualUsage,
            level: 3,
          ),
        ),
      ).called(1);
    });

    testWidgets(
      '1.6 displays briefing dialog on level 1 and dismisses on BEGIN tap',
      (tester) async {
        await pumpScreen(tester, level: 1);
        final startBtn = find.text('BEGIN SEARCH');
        final beginBtn = find.text('START SEARCH');
        final anyBtn = startBtn.evaluate().isNotEmpty
            ? startBtn
            : (beginBtn.evaluate().isNotEmpty ? beginBtn : find.text('BEGIN'));
        if (anyBtn.evaluate().isNotEmpty) {
          await tester.ensureVisible(anyBtn);
          await tester.pumpAndSettle();
          await tester.tap(anyBtn);
          await tester.pump(const Duration(milliseconds: 300));
        }
      },
    );
  });

  group('2. Phase 1: Tap-to-Answer Option Selection', () {
    testWidgets('2.1 tapping option chip updates selected state visually', (
      tester,
    ) async {
      await pumpScreen(tester);
      final chip = find.text('BORROW').first;
      await tester.tap(chip);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final chipWidget = tester.widget<ContextualUsageOptionChip>(
        find.widgetWithText(ContextualUsageOptionChip, 'BORROW'),
      );
      expect(chipWidget.isSelected, isTrue);

      // Drain remaining timers
      await tester.pump(const Duration(milliseconds: 650));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets(
      '2.2 tapping correct option triggers success haptic and advances to Phase 2',
      (tester) async {
        await pumpScreen(tester);

        await tester.tap(find.text('BORROW').first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 650));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pump(const Duration(milliseconds: 300));

        verify(() => mockHapticService.success()).called(1);
        expect(find.byType(ContextualUsageRegisterMeter), findsOneWidget);
        expect(find.byType(SpeakToConfirmOverlay), findsOneWidget);
      },
    );

    testWidgets(
      '2.3 tapping incorrect option submits wrong answer with error sound & haptic',
      (tester) async {
        await pumpScreen(tester);

        await tester.tap(find.text('LEND').first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 650));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        verify(
          () => mockVocabularyBloc.add(
            any(that: isA<SubmitAnswer>().having((e) => e.isCorrect, 'isCorrect', false)),
          ),
        ).called(1);
        verify(() => mockSoundService.playWrong()).called(1);
        verify(() => mockHapticService.error()).called(1);
      },
    );

    testWidgets('2.4 tapping option chip while already answered is locked out', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.tap(find.text('BORROW').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Attempt second tap during evaluation
      await tester.tap(find.text('RENT').first, warnIfMissed: false);
      await tester.pump();

      // Drain timers
      await tester.pump(const Duration(milliseconds: 650));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 300));

      final chipWidget = tester.widget<ContextualUsageOptionChip>(
        find.widgetWithText(ContextualUsageOptionChip, 'RENT'),
      );
      expect(chipWidget.isSelected, isFalse);
    });
  });

  group('3. Phase 2: ContextualUsageRegisterMeter & SpeakToConfirmOverlay', () {
    Future<void> advanceToPhase2(WidgetTester tester) async {
      await pumpScreen(tester);
      await tester.tap(find.text('BORROW').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 650));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets(
      '3.1 renders ContextualUsageRegisterMeter with FORMALITY METER and CASUAL tag',
      (tester) async {
        await advanceToPhase2(tester);
        expect(find.byType(ContextualUsageRegisterMeter), findsOneWidget);
        expect(find.text('FORMALITY METER'), findsOneWidget);
        expect(find.text('CASUAL'), findsOneWidget);
      },
    );

    testWidgets(
      '3.2 renders 10-step level bar reflecting registerLevel in RegisterMeter',
      (tester) async {
        await advanceToPhase2(tester);
        expect(find.text('Informal'), findsOneWidget);
        expect(find.text('Highly Formal'), findsOneWidget);
      },
    );

    testWidgets(
      '3.3 renders NUANCE card when nuanceDifference is provided',
      (tester) async {
        await advanceToPhase2(tester);
        expect(find.text('NUANCE'), findsOneWidget);
        expect(
          find.text('Borrow means to take temporarily; lend means to give temporarily.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '3.4 renders usage example quote in RegisterMeter',
      (tester) async {
        await advanceToPhase2(tester);
        expect(
          find.text('"May I borrow your textbook for the evening?"'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '3.5 renders SpeakToConfirmOverlay with completed target sentence',
      (tester) async {
        await advanceToPhase2(tester);
        expect(find.byType(SpeakToConfirmOverlay), findsOneWidget);
        final overlay = tester.widget<SpeakToConfirmOverlay>(
          find.byType(SpeakToConfirmOverlay),
        );
        expect(
          overlay.expectedText,
          "Could I BORROW your pen? I'll give it back after class.",
        );
      },
    );
  });

  group('4. Phase 2: Final Evaluation Submission (Success & Failure)', () {
    Future<void> advanceToPhase2(WidgetTester tester) async {
      await pumpScreen(tester);
      await tester.tap(find.text('BORROW').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 650));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets(
      '4.1 confirming verbal evaluation in SpeakToConfirmOverlay dispatches SubmitAnswer(true)',
      (tester) async {
        await advanceToPhase2(tester);

        clearInteractions(mockHapticService);
        final overlay = tester.widget<SpeakToConfirmOverlay>(
          find.byType(SpeakToConfirmOverlay),
        );
        overlay.onConfirmed();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        verify(() => mockVocabularyBloc.add(const SubmitAnswer(true))).called(1);
        verify(() => mockSoundService.playCorrect()).called(1);
        verify(() => mockHapticService.success()).called(1);
      },
    );

    testWidgets(
      '4.2 skipping verbal evaluation in SpeakToConfirmOverlay dispatches SubmitAnswer(false)',
      (tester) async {
        await advanceToPhase2(tester);

        final overlay = tester.widget<SpeakToConfirmOverlay>(
          find.byType(SpeakToConfirmOverlay),
        );
        overlay.onSkipped();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        verify(
          () => mockVocabularyBloc.add(
            any(that: isA<SubmitAnswer>().having((e) => e.isCorrect, 'isCorrect', false)),
          ),
        ).called(1);
        verify(() => mockSoundService.playWrong()).called(1);
        verify(() => mockHapticService.error()).called(1);
      },
    );

    testWidgets('4.3 final submission mounts GameFeedbackCard', (
      tester,
    ) async {
      await advanceToPhase2(tester);

      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byType(SpeakToConfirmOverlay),
      );
      overlay.onConfirmed();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(GameFeedbackCard), findsOneWidget);
    });
  });

  group('5. Interaction Lockout, Retry & Navigation', () {
    testWidgets('5.1 once answered, tapping option chips is locked out', (
      tester,
    ) async {
      await pumpScreen(tester);
      // Advance to Phase 2
      await tester.tap(find.text('BORROW').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 650));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 300));

      // Final submit
      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byType(SpeakToConfirmOverlay),
      );
      overlay.onConfirmed();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      clearInteractions(mockVocabularyBloc);
      clearInteractions(mockHapticService);

      // Verify tapping option chip does nothing
      final chip = find.text('RENT').first;
      await tester.tap(chip, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 100));

      verifyNever(() => mockHapticService.success());
      verifyNever(() => mockVocabularyBloc.add(any()));
    });

    testWidgets('5.2 answered state mounts GameFeedbackCard with CONTINUE button', (
      tester,
    ) async {
      await pumpScreen(tester);
      await tester.tap(find.text('BORROW').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 650));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 300));

      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byType(SpeakToConfirmOverlay),
      );
      overlay.onConfirmed();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(GameFeedbackCard), findsOneWidget);
      expect(find.text('CONTINUE'), findsOneWidget);
    });

    testWidgets('5.3 tapping CONTINUE on correct answer dispatches NextQuestion', (
      tester,
    ) async {
      await pumpScreen(tester);
      await tester.tap(find.text('BORROW').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 650));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 300));

      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byType(SpeakToConfirmOverlay),
      );
      overlay.onConfirmed();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.text('CONTINUE'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      verify(() => mockVocabularyBloc.add(const NextQuestion())).called(1);
    });

    testWidgets(
      '5.4 tapping TRY AGAIN on wrong answer (non-final failure) resets for retry',
      (tester) async {
        await pumpScreen(tester);
        await tester.tap(find.text('LEND').first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 650));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        final feedbackCard = find.byType(GameFeedbackCard);
        expect(feedbackCard, findsOneWidget);

        final retryBtn = find.text('TRY AGAIN');
        expect(retryBtn, findsOneWidget);

        await tester.tap(retryBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        // Did not dispatch NextQuestion because it allows retry
        verifyNever(() => mockVocabularyBloc.add(const NextQuestion()));
      },
    );

    testWidgets(
      '5.5 tapping SEE RESULTS on final failure dispatches NextQuestion',
      (tester) async {
        await pumpScreen(tester);
        // Tap wrong answer
        await tester.tap(find.text('LEND').first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 650));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        // When bloc transitions to final failure state (lives = 0)
        final failedState = testLoadedState.copyWith(
          wrongCount: 3,
          livesRemaining: 0,
          isFinalFailure: true,
          answerStatus: AnswerStatus.incorrect,
        );
        when(() => mockVocabularyBloc.state).thenReturn(failedState);
        vocabularyStreamController.add(failedState);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byType(GameFeedbackCard), findsOneWidget);
        await tester.tap(find.text('SEE RESULTS'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        verify(() => mockVocabularyBloc.add(const NextQuestion())).called(1);
      },
    );
  });

  group('6. Progression, State Transitions & Cleanup', () {
    testWidgets('6.1 tapping header hint button dispatches VocabularyHintUsed', (
      tester,
    ) async {
      await pumpScreen(tester);
      final hintButton = find.byType(QuestHintButton);
      expect(hintButton, findsOneWidget);
      await tester.tap(hintButton);
      await tester.pump(const Duration(milliseconds: 100));
      verify(
        () => mockVocabularyBloc.add(const VocabularyHintUsed()),
      ).called(greaterThanOrEqualTo(1));
    });

    testWidgets('6.2 hint state renders custom hint text in base layout', (
      tester,
    ) async {
      final hintState = testLoadedState.copyWith(hintUsed: true);
      await pumpScreen(tester, state: hintState);
      expect(find.byType(ContextualUsageScreen), findsOneWidget);
    });

    testWidgets(
      '6.3 transitioning to second quest resets state and displays second prompt',
      (tester) async {
        await pumpScreen(tester);

        final nextState = testLoadedState.copyWith(
          currentIndex: 1,
          answerStatus: AnswerStatus.unanswered,
        );
        when(() => mockVocabularyBloc.state).thenReturn(nextState);
        vocabularyStreamController.add(nextState);

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.textContaining('My sister offered to'), findsOneWidget);
      },
    );

    testWidgets(
      '6.4 VocabularyGameComplete state triggers LEVEL COMPLETE dialog and disposes cleanly',
      (tester) async {
        await pumpScreen(tester);

        vocabularyStreamController.add(
          const VocabularyGameComplete(
            xpEarned: 50,
            coinsEarned: 15,
            questCount: 2,
          ),
        );
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('LEVEL COMPLETE!'), findsOneWidget);

        // Clean up completion dialog to avoid pending periodic timers
        Navigator.of(tester.element(find.text('LEVEL COMPLETE!'))).pop();
        await tester.pump(const Duration(milliseconds: 100));
      },
    );

    testWidgets('6.5 renders GameShimmerLoading when quests are loading/null', (
      tester,
    ) async {
      const loadingState = VocabularyLoading();
      await pumpScreen(tester, state: loadingState);
      expect(find.byType(GameShimmerLoading), findsOneWidget);
    });

    testWidgets('6.6 screen disposes cleanly without timer leaks', (
      tester,
    ) async {
      await pumpScreen(tester);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });

  group('7. Viewport Responsiveness, Theming & Accessibility', () {
    testWidgets('7.1 renders cleanly on compact mobile viewport (320x568)', (
      tester,
    ) async {
      await pumpScreen(tester, size: const Size(320, 568));
      expect(tester.takeException(), isNull);
      expect(find.byType(ContextualUsageCard), findsOneWidget);
      expect(find.byType(ContextualUsageOptionChip), findsNWidgets(4));
    });

    testWidgets('7.2 renders cleanly on tablet viewport (768x1024)', (
      tester,
    ) async {
      await pumpScreen(tester, size: const Size(768, 1024));
      expect(tester.takeException(), isNull);
      expect(find.byType(ContextualUsageCard), findsOneWidget);
      expect(find.byType(ContextualUsageOptionChip), findsNWidgets(4));
    });

    testWidgets('7.3 renders cleanly in Light Theme mode', (tester) async {
      await pumpScreen(tester, themeMode: ThemeMode.light);
      expect(tester.takeException(), isNull);
      expect(find.byType(ContextualUsageCard), findsOneWidget);
    });

    testWidgets('7.4 renders cleanly in Dark Theme mode', (tester) async {
      await pumpScreen(tester, themeMode: ThemeMode.dark);
      expect(tester.takeException(), isNull);
      expect(find.byType(ContextualUsageCard), findsOneWidget);
    });

    testWidgets('7.5 supports text scaling up to 1.5x cleanly', (tester) async {
      await pumpScreen(tester, textScaleFactor: 1.5);
      expect(tester.takeException(), isNull);
      expect(find.byType(ContextualUsageCard), findsOneWidget);
    });

    testWidgets(
      '7.6 suppresses repeating animations when disableAnimations is true',
      (tester) async {
        await pumpScreen(tester, reduceMotion: true);
        expect(tester.takeException(), isNull);
        expect(find.byType(ContextualUsageCard), findsOneWidget);
      },
    );
  });
}
