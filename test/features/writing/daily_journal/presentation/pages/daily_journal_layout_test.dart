import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/core/presentation/game_mechanics/speaking/speak_to_confirm_overlay.dart';
import 'package:vowl/core/presentation/widgets/game_feedback_card.dart';
import 'package:vowl/core/presentation/widgets/quest_briefing_overlay.dart';
import 'package:vowl/core/presentation/widgets/quest_hint_button.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
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
import 'package:vowl/core/utils/ml_services/language_id_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/speech_service.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/features/writing/daily_journal/presentation/pages/daily_journal_screen.dart';
import 'package:vowl/features/writing/daily_journal/presentation/widgets/daily_journal_booster_tokens.dart';
import 'package:vowl/features/writing/daily_journal/presentation/widgets/daily_journal_instruction.dart';
import 'package:vowl/features/writing/daily_journal/presentation/widgets/daily_journal_prompt.dart';
import 'package:vowl/features/writing/daily_journal/presentation/widgets/daily_journal_scratch_area.dart';
import 'package:vowl/features/writing/domain/entities/writing_quest.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_bloc.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_event.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_state.dart';
import 'package:vowl/features/writing/presentation/layout/writing_base_layout.dart';

class MockWritingBloc extends MockBloc<WritingEvent, WritingState>
    implements WritingBloc {}

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

class MockLanguageIdService extends Mock implements LanguageIdService {}

class MockAudioRecordingService extends Mock implements AudioRecordingService {}

class MockSpeechService extends Mock implements SpeechService {}

class FakeWritingEvent extends Fake implements WritingEvent {}

class FakeWritingState extends Fake implements WritingState {}

class FakeEconomyEvent extends Fake implements EconomyEvent {}

class FakeEconomyState extends Fake implements EconomyState {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  late MockWritingBloc mockWritingBloc;
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
  late MockLanguageIdService mockLanguageIdService;
  late MockAudioRecordingService mockAudioRecorder;
  late MockSpeechService mockSpeechService;
  late StreamController<WritingState> writingStreamController;

  WritingQuest createQuest({
    String id = 'quest_dj_1',
    String instruction = 'Write a journal entry using the target words.',
    String prompt =
        'Imagine you are descending into the Mariana Trench in a research submersible. Describe what you see and feel as the light fades.',
    List<String> promptQuestions = const [
      'What sounds do you hear inside the cabin?',
      'What strange creatures appear in the dark abyss?',
    ],
    List<String> options = const ['submersible', 'mariana', 'trench'],
    String hint = 'Focus on vivid sensory details and atmospheric tension.',
    String explanation =
        'Journaling helps integrate new vocabulary into natural context.',
    int difficulty = 1,
    String? sampleAnswer =
        'The submersible descended deep into the dark mariana trench to explore the ocean.',
    String? context = 'Deep Sea Expedition',
  }) {
    return WritingQuest(
      id: id,
      type: QuestType.writing,
      subtype: GameSubtype.dailyJournal,
      instruction: instruction,
      difficulty: difficulty,
      prompt: prompt,
      promptQuestions: promptQuestions,
      options: options,
      hint: hint,
      explanation: explanation,
      sampleAnswer: sampleAnswer,
      context: context,
    );
  }

  final sampleQuest1 = createQuest();

  final sampleQuest2 = createQuest(
    id: 'quest_dj_2',
    instruction: 'Write a reflection about your morning walk.',
    prompt: 'Describe the sights, sounds, and fresh air of an early sunrise walk.',
    promptQuestions: ['How did the morning light feel?'],
    options: ['sunrise', 'horizon', 'breeze'],
  );

  final testLoadedState = WritingLoaded(
    quests: [sampleQuest1, sampleQuest2],
    currentIndex: 0,
    livesRemaining: 3,
    wrongCount: 0,
    hintUsed: false,
    answerStatus: AnswerStatus.unanswered,
    gameType: GameSubtype.dailyJournal,
    level: 2,
  );

  setUpAll(() {
    registerFallbackValue(FakeWritingEvent());
    registerFallbackValue(FakeWritingState());
    registerFallbackValue(FakeEconomyEvent());
    registerFallbackValue(FakeEconomyState());
    registerFallbackValue(const SubmitAnswer(true));
    registerFallbackValue(const SubmitAnswer(false));
    registerFallbackValue(const NextQuestion());
    registerFallbackValue(const WritingHintUsed());
    registerFallbackValue(
      const FetchWritingQuests(
        gameType: GameSubtype.dailyJournal,
        level: 2,
      ),
    );
    registerFallbackValue(const EconomyAddCoinsRequested(5));
    registerFallbackValue(ListenMode.dictation);
  });

  setUp(() async {
    mockWritingBloc = MockWritingBloc();
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
    mockLanguageIdService = MockLanguageIdService();
    mockAudioRecorder = MockAudioRecordingService();

    writingStreamController = StreamController<WritingState>.broadcast();

    // Haptics
    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});
    when(() => mockHapticService.warning()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});
    when(() => mockHapticService.heavy()).thenAnswer((_) async {});

    // Sounds
    when(() => mockSoundService.playCorrect()).thenAnswer((_) async {});
    when(() => mockSoundService.playWrong()).thenAnswer((_) async {});
    when(() => mockSoundService.stopAudio()).thenAnswer((_) async {});
    when(() => mockSoundService.stopTts()).thenAnswer((_) async {});
    when(() => mockSoundService.playHint()).thenAnswer((_) async {});
    when(() => mockSoundService.playClick()).thenAnswer((_) async {});
    when(() => mockSoundService.playLevelComplete()).thenAnswer((_) async {});
    when(() => mockSoundService.playFile(any())).thenAnswer((_) async {});

    // TTS
    when(() => mockTtsService.stop()).thenAnswer((_) async {});
    when(
      () => mockTtsService.speak(
        any(),
        rate: any(named: 'rate'),
        locale: any(named: 'locale'),
      ),
    ).thenAnswer((_) async {});

    // Language ID
    when(() => mockLanguageIdService.identifyLanguage(any()))
        .thenAnswer((_) async => 'en');

    // Audio Recorder
    when(() => mockAudioRecorder.hasPermission()).thenAnswer((_) async => true);
    when(() => mockAudioRecorder.startRecording()).thenAnswer((_) async => true);
    when(() => mockAudioRecorder.stopRecording())
        .thenAnswer((_) async => '/tmp/audio_test.m4a');
    when(() => mockAudioRecorder.isRecording).thenReturn(false);

    // Speech Service
    mockSpeechService = MockSpeechService();
    when(() => mockSpeechService.isListening).thenReturn(false);
    when(() => mockSpeechService.isPlaying).thenReturn(false);
    when(() => mockSpeechService.initializeStt()).thenAnswer((_) async => true);
    when(() => mockSpeechService.stop()).thenAnswer((_) async {});
    when(() => mockSpeechService.cancel()).thenAnswer((_) async {});
    when(() => mockSpeechService.listen(
          onResult: any(named: 'onResult'),
          onDone: any(named: 'onDone'),
          onSoundLevelChange: any(named: 'onSoundLevelChange'),
          localeId: any(named: 'localeId'),
          pauseFor: any(named: 'pauseFor'),
          listenMode: any(named: 'listenMode'),
        )).thenAnswer((_) async {});

    // Analytics & Ad mocks
    when(() => mockAnalyticsService.logGameSkipped(any())).thenAnswer((_) async {});
    when(
      () => mockAdService.showRewardedAd(
        context: any(named: 'context'),
        isPremium: any(named: 'isPremium'),
        onUserEarnedReward: any(named: 'onUserEarnedReward'),
        onDismissed: any(named: 'onDismissed'),
      ),
    ).thenAnswer((inv) {
      final onEarned = inv.namedArguments[#onUserEarnedReward] as dynamic;
      onEarned?.call(RewardItem(1, 'coin'));
    });

    // Auth mock
    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(
        const UserEntity(
          id: 'local',
          email: 'scribe@vowl.app',
          displayName: 'Wordsmith',
          hintCount: 3,
          isPremium: false,
        ),
      ),
    );
    when(() => mockAuthBloc.stream)
        .thenAnswer((_) => const Stream<AuthState>.empty());

    // Economy mock
    when(() => mockEconomyBloc.state).thenReturn(const EconomyState());
    when(() => mockEconomyBloc.stream)
        .thenAnswer((_) => const Stream<EconomyState>.empty());

    // Network mock
    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

    // Writing Bloc default state
    when(() => mockWritingBloc.state).thenReturn(testLoadedState);
    when(
      () => mockWritingBloc.stream,
    ).thenAnswer((_) => writingStreamController.stream);

    await di.sl.reset();
    di.sl.registerSingleton<HapticService>(mockHapticService);
    di.sl.registerSingleton<SoundService>(mockSoundService);
    di.sl.registerSingleton<TtsService>(mockTtsService);
    di.sl.registerSingleton<LocaleService>(mockLocaleService);
    di.sl.registerSingleton<AppLogger>(mockAppLogger);
    di.sl.registerSingleton<AnalyticsService>(mockAnalyticsService);
    di.sl.registerSingleton<AdService>(mockAdService);
    di.sl.registerSingleton<NetworkInfo>(mockNetworkInfo);
    di.sl.registerSingleton<LanguageIdService>(mockLanguageIdService);
    di.sl.registerSingleton<AudioRecordingService>(mockAudioRecorder);
    di.sl.registerSingleton<SpeechService>(mockSpeechService);

    VowlMotion.lowAnimationModeOverride.value = true;
  });

  tearDown(() async {
    await writingStreamController.close();
    VowlMotion.lowAnimationModeOverride.value = false;
    if (di.sl.isRegistered<HapticService>()) di.sl.unregister<HapticService>();
    if (di.sl.isRegistered<SoundService>()) di.sl.unregister<SoundService>();
    if (di.sl.isRegistered<TtsService>()) di.sl.unregister<TtsService>();
    if (di.sl.isRegistered<LocaleService>()) di.sl.unregister<LocaleService>();
    if (di.sl.isRegistered<AppLogger>()) di.sl.unregister<AppLogger>();
    if (di.sl.isRegistered<AnalyticsService>()) {
      di.sl.unregister<AnalyticsService>();
    }
    if (di.sl.isRegistered<AdService>()) di.sl.unregister<AdService>();
    if (di.sl.isRegistered<NetworkInfo>()) di.sl.unregister<NetworkInfo>();
    if (di.sl.isRegistered<LanguageIdService>()) {
      di.sl.unregister<LanguageIdService>();
    }
    if (di.sl.isRegistered<AudioRecordingService>()) {
      di.sl.unregister<AudioRecordingService>();
    }
    if (di.sl.isRegistered<SpeechService>()) {
      di.sl.unregister<SpeechService>();
    }
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    WritingState? state,
    int level = 2,
    ThemeMode themeMode = ThemeMode.dark,
    double textScaleFactor = 1.0,
    Size surfaceSize = const Size(390, 844),
    bool settle = true,
  }) async {
    tester.view.physicalSize = surfaceSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    if (state != null) {
      when(() => mockWritingBloc.state).thenReturn(state);
    }

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<WritingBloc>.value(value: mockWritingBloc),
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<EconomyBloc>.value(value: mockEconomyBloc),
        ],
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) {
            return MaterialApp(
              themeMode: themeMode,
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              home: MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(textScaleFactor),
                ),
                child: DailyJournalScreen(level: level),
              ),
            );
          },
        ),
      ),
    );

    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> scrollAndTapSaveButton(WidgetTester tester) async {
    final messengerFinder = find.byType(ScaffoldMessenger);
    if (messengerFinder.evaluate().isNotEmpty) {
      tester.state<ScaffoldMessengerState>(messengerFinder).clearSnackBars();
      await tester.pump();
    }
    await tester.drag(
      find.byKey(const Key('daily_journal_scroll_view')),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();
    final saveButton = find.byKey(const Key('daily_journal_save_button'));
    if (saveButton.evaluate().isNotEmpty) {
      await tester.tap(saveButton, warnIfMissed: false);
      await tester.pump();
    }
  }

  group('DailyJournalScreen - 1. Initial Rendering & Layout', () {
    testWidgets('renders all essential components in normal mode (level 2)', (
      tester,
    ) async {
      await pumpScreen(tester, level: 2);

      expect(find.byType(WritingBaseLayout), findsOneWidget);
      expect(find.byType(DailyJournalInstruction), findsOneWidget);
      expect(find.byType(DailyJournalPrompt), findsOneWidget);
      expect(find.byType(DailyJournalBoosterTokens), findsOneWidget);
      expect(find.byType(DailyJournalScratchArea), findsOneWidget);
      expect(
        find.byKey(const Key('daily_journal_save_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('daily_journal_scroll_view')),
        findsOneWidget,
      );
      expect(find.text('SAVE ENTRY'), findsOneWidget);
      expect(find.text('Guiding Questions'), findsOneWidget);
      expect(
        find.text('• What sounds do you hear inside the cabin?'),
        findsOneWidget,
      );
    });

    testWidgets('renders all booster tokens', (tester) async {
      await pumpScreen(tester, level: 2);

      for (final kw in sampleQuest1.options!) {
        expect(find.byKey(Key('daily_journal_token_$kw')), findsOneWidget);
        expect(find.text(kw), findsOneWidget);
      }
    });

    testWidgets('renders shimmer loading when in initial state', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        state: WritingInitial(),
        level: 2,
        settle: false,
      );

      expect(find.byType(GameShimmerLoading), findsOneWidget);
    });

    testWidgets('dispatches FetchWritingQuests on init', (tester) async {
      await pumpScreen(tester, level: 2);

      verify(
        () => mockWritingBloc.add(
          const FetchWritingQuests(
            gameType: GameSubtype.dailyJournal,
            level: 2,
          ),
        ),
      ).called(1);
    });
  });

  group('DailyJournalScreen - 2. Live Text Input & Booster Token State', () {
    testWidgets('typing updates word count and progress bar live', (
      tester,
    ) async {
      await pumpScreen(tester, level: 2);

      expect(find.text('0 words'), findsOneWidget);

      final inputField = find.byKey(
        const Key('daily_journal_input_field'),
      );
      await tester.enterText(
        inputField,
        'One two three four five six seven eight nine ten.',
      );
      await tester.pump();

      expect(find.text('10 words'), findsOneWidget);
    });

    testWidgets('typing target words activates booster tokens', (
      tester,
    ) async {
      await pumpScreen(tester, level: 2);

      final inputField = find.byKey(
        const Key('daily_journal_input_field'),
      );
      await tester.enterText(
        inputField,
        'The submersible explored the deep.',
      );
      await tester.pump();

      // "submersible" should be activated -> has check icon
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('tapping an unactivated booster token speaks word and displays info snackbar', (
      tester,
    ) async {
      await pumpScreen(tester, level: 2);

      final tokenFinder = find.byKey(
        const Key('daily_journal_token_submersible'),
      );
      await tester.ensureVisible(tokenFinder);
      await tester.tap(tokenFinder);
      await tester.pump();

      verify(() => mockTtsService.speak('submersible')).called(1);
      expect(
        find.text(
          "Type 'submersible' in your journal entry to activate this token!",
        ),
        findsOneWidget,
      );
    });

    testWidgets('tapping an activated booster token speaks word and displays success snackbar', (
      tester,
    ) async {
      await pumpScreen(tester, level: 2);

      final inputField = find.byKey(
        const Key('daily_journal_input_field'),
      );
      await tester.enterText(
        inputField,
        'The submersible plunged downward.',
      );
      await tester.pump();

      final tokenFinder = find.byKey(
        const Key('daily_journal_token_submersible'),
      );
      await tester.ensureVisible(tokenFinder);
      await tester.tap(tokenFinder);
      await tester.pump();

      verify(() => mockTtsService.speak('submersible')).called(1);
      expect(
        find.text("'submersible' is already activated! Great job."),
        findsOneWidget,
      );
    });
  });

  group('DailyJournalScreen - 3. Validation Rules & Strike System', () {
    testWidgets('submitting empty text does not submit', (tester) async {
      await pumpScreen(tester, level: 2);

      await scrollAndTapSaveButton(tester);

      verifyNever(() => mockWritingBloc.add(const SubmitAnswer(true)));
      verifyNever(() => mockWritingBloc.add(const SubmitAnswer(false)));
    });

    testWidgets('warns if text does not start with capital letter', (
      tester,
    ) async {
      await pumpScreen(tester, level: 2);

      final inputField = find.byKey(
        const Key('daily_journal_input_field'),
      );
      await tester.enterText(
        inputField,
        'the submersible descended deep into the mariana trench today.',
      );
      await tester.pump();

      await scrollAndTapSaveButton(tester);

      expect(
        find.text(
          'Please start your journal entry with a capital letter. (2 tries left)',
        ),
        findsOneWidget,
      );
      verify(() => mockHapticService.warning()).called(1);
    });

    testWidgets('warns if text does not end with proper punctuation', (
      tester,
    ) async {
      await pumpScreen(tester, level: 2);

      final inputField = find.byKey(
        const Key('daily_journal_input_field'),
      );
      await tester.enterText(
        inputField,
        'The submersible descended deep into the mariana trench today',
      );
      await tester.pump();

      await scrollAndTapSaveButton(tester);

      expect(
        find.text(
          'Please end your entry with proper punctuation (e.g., full stop). (2 tries left)',
        ),
        findsOneWidget,
      );
      verify(() => mockHapticService.warning()).called(1);
    });

    testWidgets('warns if word count is less than 10 words', (tester) async {
      await pumpScreen(tester, level: 2);

      final inputField = find.byKey(
        const Key('daily_journal_input_field'),
      );
      await tester.enterText(
        inputField,
        'The submersible explored Mariana.',
      );
      await tester.pump();

      await scrollAndTapSaveButton(tester);

      expect(
        find.text(
          'Keep writing! A valid journal entry requires at least 10 words. (2 tries left)',
        ),
        findsOneWidget,
      );
      verify(() => mockHapticService.selection()).called(1);
    });

    testWidgets('warns if fewer than 2 target keywords are used', (
      tester,
    ) async {
      await pumpScreen(tester, level: 2);

      final inputField = find.byKey(
        const Key('daily_journal_input_field'),
      );
      // Only 1 target keyword: "submersible"
      await tester.enterText(
        inputField,
        'The submersible was very quiet as we looked through the thick glass viewport.',
      );
      await tester.pump();

      await scrollAndTapSaveButton(tester);

      expect(
        find.text(
          'Use at least 2 target words to complete your entry! (2 tries left)',
        ),
        findsOneWidget,
      );
      verify(() => mockHapticService.warning()).called(1);
    });

    testWidgets('3 consecutive failures triggers wrong answer submission', (
      tester,
    ) async {
      await pumpScreen(tester, level: 2);

      final inputField = find.byKey(
        const Key('daily_journal_input_field'),
      );

      // Strike 1
      await tester.enterText(inputField, 'lower case sentence here without count');
      await tester.pump();
      await scrollAndTapSaveButton(tester);

      // Strike 2
      await tester.enterText(inputField, 'lower case sentence here strike two');
      await tester.pump();
      await scrollAndTapSaveButton(tester);

      // Strike 3
      await tester.enterText(inputField, 'lower case sentence here strike three');
      await tester.pump();
      await scrollAndTapSaveButton(tester);

      // 3 strikes -> submitWrongAnswer called
      verify(() => mockWritingBloc.add(const SubmitAnswer(false))).called(1);
    });
  });

  group('DailyJournalScreen - 4. Language ID & Gibberish Detection', () {
    testWidgets('warns if language is detected as non-English', (
      tester,
    ) async {
      when(() => mockLanguageIdService.identifyLanguage(any()))
          .thenAnswer((_) async => 'es');

      await pumpScreen(tester, level: 2);

      final inputField = find.byKey(
        const Key('daily_journal_input_field'),
      );
      await tester.enterText(
        inputField,
        'The submersible descended deep into the dark mariana trench to explore.',
      );
      await tester.pump();

      await scrollAndTapSaveButton(tester);

      expect(
        find.text(
          'Your answer must be written in English. Please write a natural sentence! (2 tries left)',
        ),
        findsOneWidget,
      );
    });

    testWidgets('warns on keyboard mashing via GibberishDetectorService', (
      tester,
    ) async {
      await pumpScreen(tester, level: 2);

      final inputField = find.byKey(
        const Key('daily_journal_input_field'),
      );
      await tester.enterText(
        inputField,
        'The submersible descended into the mariana trench with aaaaaaaabbbbbb screaming loud.',
      );
      await tester.pump();

      await scrollAndTapSaveButton(tester);

      expect(
        find.text('No keyboard mashing allowed! Please write real words.'),
        findsOneWidget,
      );
    });
  });

  group('DailyJournalScreen - 5. Validation Success & Speak To Confirm (Stage 2)', () {
    testWidgets('valid journal entry reveals SpeakToConfirmOverlay', (
      tester,
    ) async {
      await pumpScreen(tester, level: 2);

      final inputField = find.byKey(
        const Key('daily_journal_input_field'),
      );
      await tester.enterText(
        inputField,
        'The submersible descended deep into the dark mariana trench to explore the ocean.',
      );
      await tester.pump();

      await scrollAndTapSaveButton(tester);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      verify(() => mockHapticService.success()).called(1);
      verify(() => mockSoundService.playCorrect()).called(1);

      expect(find.byType(SpeakToConfirmOverlay), findsOneWidget);
      expect(find.text('NOW SAY IT'), findsOneWidget);
      // Save button is hidden when speak to confirm is showing
      expect(find.byKey(const Key('daily_journal_save_button')), findsNothing);
    });

    testWidgets('confirming speech in SpeakToConfirmOverlay dispatches SubmitAnswer(true)', (
      tester,
    ) async {
      await pumpScreen(tester, level: 2);

      final inputField = find.byKey(
        const Key('daily_journal_input_field'),
      );
      await tester.enterText(
        inputField,
        'The submersible descended deep into the dark mariana trench to explore the ocean.',
      );
      await tester.pump();

      await scrollAndTapSaveButton(tester);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byType(SpeakToConfirmOverlay),
      );
      overlay.onConfirmed();
      await tester.pump();

      verify(() => mockWritingBloc.add(const SubmitAnswer(true))).called(1);
    });

    testWidgets('skipping speech in SpeakToConfirmOverlay also submits answer', (
      tester,
    ) async {
      await pumpScreen(tester, level: 2);

      final inputField = find.byKey(
        const Key('daily_journal_input_field'),
      );
      await tester.enterText(
        inputField,
        'The submersible descended deep into the dark mariana trench to explore the ocean.',
      );
      await tester.pump();

      await scrollAndTapSaveButton(tester);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byType(SpeakToConfirmOverlay),
      );
      overlay.onSkipped();
      await tester.pump();

      verify(() => mockWritingBloc.add(const SubmitAnswer(true))).called(1);
    });
  });

  group('DailyJournalScreen - 6. Feedback, Navigation & Reset', () {
    testWidgets('displays feedback card when answered correctly', (
      tester,
    ) async {
      final answeredCorrect = testLoadedState.copyWith(
        answerStatus: AnswerStatus.correct,
      );

      await pumpScreen(tester, state: answeredCorrect, level: 2);

      expect(find.byType(GameFeedbackCard), findsOneWidget);
      expect(find.text('CONTINUE'), findsOneWidget);
    });

    testWidgets('tapping CONTINUE dispatches NextQuestion', (tester) async {
      final answeredCorrect = testLoadedState.copyWith(
        answerStatus: AnswerStatus.correct,
      );

      await pumpScreen(tester, state: answeredCorrect, level: 2);

      final continueButton = find.text('CONTINUE');
      await tester.tap(continueButton);
      await tester.pump();

      verify(() => mockWritingBloc.add(const NextQuestion())).called(1);
    });

    testWidgets('tapping Hint button dispatches WritingHintUsed', (
      tester,
    ) async {
      await pumpScreen(tester, level: 2);

      final hintButton = find.byType(QuestHintButton);
      expect(hintButton, findsOneWidget);

      await tester.tap(hintButton);
      await tester.pump();

      verify(() => mockWritingBloc.add(const WritingHintUsed())).called(1);
    });

    testWidgets('onQuestionReset resets controller and progress on new question', (
      tester,
    ) async {
      await pumpScreen(tester, level: 2);

      final inputField = find.byKey(
        const Key('daily_journal_input_field'),
      );
      await tester.enterText(inputField, 'Some journal text here for test.');
      await tester.pump();

      // Now emit next question
      final nextQuestionState = WritingLoaded(
        quests: [sampleQuest1, sampleQuest2],
        currentIndex: 1,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.unanswered,
        gameType: GameSubtype.dailyJournal,
        level: 2,
      );

      writingStreamController.add(nextQuestionState);
      when(() => mockWritingBloc.state).thenReturn(nextQuestionState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('0 words'), findsOneWidget);
    });
  });

  group('DailyJournalScreen - 7. Completion, Game Over & Error Journal', () {
    testWidgets('shows completion dialog on WritingGameComplete', (
      tester,
    ) async {
      await pumpScreen(tester, level: 2);

      writingStreamController.add(
        const WritingGameComplete(
          xpEarned: 100,
          coinsEarned: 25,
          questCount: 2,
          gameType: GameSubtype.dailyJournal,
          level: 2,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('LEVEL COMPLETE!'), findsOneWidget);

      // Clean up dialog
      Navigator.of(tester.element(find.text('LEVEL COMPLETE!'))).pop();
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('handles WritingGameOver without crash', (tester) async {
      await pumpScreen(tester, level: 2);

      writingStreamController.add(
        WritingGameOver(
          quests: [sampleQuest1],
          currentIndex: 0,
          gameType: GameSubtype.dailyJournal,
          level: 2,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(WritingBaseLayout), findsOneWidget);

      final giveUpFinder = find.text('GIVE UP');
      if (giveUpFinder.evaluate().isNotEmpty) {
        Navigator.of(tester.element(giveUpFinder)).pop();
        await tester.pump(const Duration(milliseconds: 500));
      }
    });

    testWidgets('records to ErrorJournal when answering incorrectly as authenticated user', (
      tester,
    ) async {
      when(() => mockAuthBloc.state).thenReturn(
        AuthState.authenticated(
          const UserEntity(
            id: 'authed_user_1',
            email: 'user@test.com',
            displayName: 'Grammar Master',
          ),
        ),
      );

      await pumpScreen(tester, level: 2);

      final inputField = find.byKey(
        const Key('daily_journal_input_field'),
      );

      // 3 strikes
      for (int i = 0; i < 3; i++) {
        await tester.enterText(inputField, 'strike $i invalid');
        await tester.pump();
        await scrollAndTapSaveButton(tester);
      }

      verify(() => mockWritingBloc.add(const SubmitAnswer(false))).called(1);
    });
  });

  group('DailyJournalScreen - 8. Responsiveness & Accessibility', () {
    testWidgets('renders properly on small screen (320x568)', (tester) async {
      await pumpScreen(
        tester,
        level: 2,
        surfaceSize: const Size(320, 568),
      );

      expect(find.byType(DailyJournalScreen), findsOneWidget);
      expect(find.byType(DailyJournalInstruction), findsOneWidget);
      expect(find.byType(DailyJournalScratchArea), findsOneWidget);
    });

    testWidgets('renders properly on tablet screen (800x1280)', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        level: 2,
        surfaceSize: const Size(800, 1280),
      );

      expect(find.byType(DailyJournalScreen), findsOneWidget);
      expect(find.byType(DailyJournalPrompt), findsOneWidget);
    });

    testWidgets('renders with 1.3x high text scale without overflow', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        level: 2,
        textScaleFactor: 1.3,
      );

      expect(find.byType(DailyJournalScreen), findsOneWidget);
    });

    testWidgets('renders properly in light theme', (tester) async {
      await pumpScreen(
        tester,
        level: 2,
        themeMode: ThemeMode.light,
      );

      expect(find.byType(DailyJournalScreen), findsOneWidget);
    });

    testWidgets('briefing overlay shows at level 1 and dismisses on tap', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        level: 1,
        surfaceSize: const Size(390, 1000),
      );

      expect(find.byType(QuestBriefingOverlay), findsOneWidget);

      final startButton = find.descendant(
        of: find.byType(QuestBriefingOverlay),
        matching: find.byType(ScaleButton),
      );
      await tester.ensureVisible(startButton);
      await tester.tap(startButton);
      await tester.pumpAndSettle();

      expect(find.byType(QuestBriefingOverlay), findsNothing);
    });
  });
}

