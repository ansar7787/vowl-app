import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart';

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
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/features/writing/describe_situation_writing/presentation/pages/describe_situation_writing_screen.dart';
import 'package:vowl/features/writing/describe_situation_writing/presentation/widgets/describe_situation_constellation_map.dart';
import 'package:vowl/features/writing/describe_situation_writing/presentation/widgets/describe_situation_instruction.dart';
import 'package:vowl/features/writing/describe_situation_writing/presentation/widgets/describe_situation_prompt_card.dart';
import 'package:vowl/features/writing/describe_situation_writing/presentation/widgets/describe_situation_writing_area.dart';
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

class MockSpeechService extends Mock implements SpeechService {}

class MockLocaleService extends Mock implements LocaleService {}

class MockAppLogger extends Mock implements AppLogger {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockAdService extends Mock implements AdService {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

class MockLanguageIdService extends Mock implements LanguageIdService {}

class MockAudioRecordingService extends Mock implements AudioRecordingService {}

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
  late MockSpeechService mockSpeechService;
  late MockLocaleService mockLocaleService;
  late MockAppLogger mockAppLogger;
  late MockAnalyticsService mockAnalyticsService;
  late MockAdService mockAdService;
  late MockNetworkInfo mockNetworkInfo;
  late MockLanguageIdService mockLanguageIdService;
  late MockAudioRecordingService mockAudioRecorder;
  late StreamController<WritingState> writingStreamController;

  WritingQuest createQuest({
    String id = 'quest_dsw_1',
    String instruction = 'Describe the unfolding situation using the keyword boosters.',
    String situation = 'A deep-sea hydrothermal vent is discovered in the abyssal zone.',
    List<String> emojis = const ['🌍', '💧', '🔬', '🚀'],
    Map<String, List<String>> keywords = const {
      '0': ['VENTING', 'MAGMA', 'PLUME'],
      '1': ['OCEANIC', 'THERMAL', 'PRESSURE'],
      '2': ['MINERAL', 'CHEMICAL', 'HYDROUS'],
      '3': ['CREATURE', 'BENTHIC', 'ABYSSAL'],
    },
    int minWords = 15,
    String? modelAnswer = 'The benthic creatures thrive near the deep oceanic hydrothermal vent despite immense pressure.',
    int difficulty = 2,
    String hint = 'Focus on how the thermal heat supports strange life forms.',
    String explanation = 'Describing dynamic situations develops contextual descriptive fluency.',
  }) {
    return WritingQuest(
      id: id,
      type: QuestType.writing,
      subtype: GameSubtype.describeSituationWriting,
      instruction: instruction,
      situation: situation,
      emojis: emojis,
      keywords: keywords,
      minWords: minWords,
      modelAnswer: modelAnswer,
      difficulty: difficulty,
      hint: hint,
      explanation: explanation,
    );
  }

  final sampleQuest1 = createQuest();

  final sampleQuest2 = createQuest(
    id: 'quest_dsw_2',
    situation: 'An astronaut steps out of the airlock into deep space.',
    emojis: ['👨‍🚀', '🌌', '🛰️', '✨'],
    keywords: {
      '0': ['HELMET', 'TETHER', 'SPACESUIT'],
      '1': ['GALAXY', 'SILENCE', 'HORIZON'],
    },
    minWords: 12,
  );

  final testLoadedState = WritingLoaded(
    quests: [sampleQuest1, sampleQuest2],
    currentIndex: 0,
    livesRemaining: 3,
    wrongCount: 0,
    hintUsed: false,
    answerStatus: AnswerStatus.unanswered,
    gameType: GameSubtype.describeSituationWriting,
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
        gameType: GameSubtype.describeSituationWriting,
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
    mockSpeechService = MockSpeechService();
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

    // Speech Service
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

    // Language ID
    when(() => mockLanguageIdService.identifyLanguage(any()))
        .thenAnswer((_) async => 'en');

    // Audio Recorder
    when(() => mockAudioRecorder.hasPermission()).thenAnswer((_) async => true);
    when(() => mockAudioRecorder.startRecording()).thenAnswer((_) async => true);
    when(() => mockAudioRecorder.stopRecording())
        .thenAnswer((_) async => '/tmp/audio_test.m4a');
    when(() => mockAudioRecorder.isRecording).thenReturn(false);

    // Analytics & Ad mocks
    when(() => mockAnalyticsService.logGameSkipped(any())).thenAnswer((_) async {});
    when(
      () => mockAdService.showRewardedAd(
        context: any(named: 'context'),
        isPremium: any(named: 'isPremium'),
        onUserEarnedReward: any(named: 'onUserEarnedReward'),
        onDismissed: any(named: 'onDismissed'),
      ),
    ).thenAnswer((inv) async {
      final onEarned = inv.namedArguments[#onUserEarnedReward] as dynamic;
      onEarned?.call(RewardItem(1, 'coin'));
    });

    // Auth mock
    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(
        const UserEntity(
          id: 'narrator_1',
          email: 'narrator@vowl.app',
          displayName: 'Narrator',
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
    di.sl.registerSingleton<SpeechService>(mockSpeechService);
    di.sl.registerSingleton<LocaleService>(mockLocaleService);
    di.sl.registerSingleton<AppLogger>(mockAppLogger);
    di.sl.registerSingleton<AnalyticsService>(mockAnalyticsService);
    di.sl.registerSingleton<AdService>(mockAdService);
    di.sl.registerSingleton<NetworkInfo>(mockNetworkInfo);
    di.sl.registerSingleton<LanguageIdService>(mockLanguageIdService);
    di.sl.registerSingleton<AudioRecordingService>(mockAudioRecorder);

    VowlMotion.lowAnimationModeOverride.value = true;
  });

  tearDown(() async {
    await writingStreamController.close();
    VowlMotion.lowAnimationModeOverride.value = false;
    if (di.sl.isRegistered<HapticService>()) di.sl.unregister<HapticService>();
    if (di.sl.isRegistered<SoundService>()) di.sl.unregister<SoundService>();
    if (di.sl.isRegistered<TtsService>()) di.sl.unregister<TtsService>();
    if (di.sl.isRegistered<SpeechService>()) di.sl.unregister<SpeechService>();
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
                child: DescribeSituationScreen(level: level),
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

  Future<void> scrollAndTapSubmitButton(WidgetTester tester) async {
    final messengerFinder = find.byType(ScaffoldMessenger);
    if (messengerFinder.evaluate().isNotEmpty) {
      tester.state<ScaffoldMessengerState>(messengerFinder).clearSnackBars();
      await tester.pump();
    }
    await tester.drag(
      find.byKey(const Key('describe_situation_scroll_view')),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();
    final submitButton = find.byKey(const Key('describe_situation_submit_button'));
    if (submitButton.evaluate().isNotEmpty) {
      await tester.tap(submitButton, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  group('DescribeSituationScreen - 1. Initial Rendering & Layout', () {
    testWidgets('renders all essential components in normal mode (level 2)', (
      tester,
    ) async {
      await pumpScreen(tester, level: 2);

      expect(find.byType(WritingBaseLayout), findsOneWidget);
      expect(find.byType(DescribeSituationInstruction), findsOneWidget);
      expect(find.byType(DescribeSituationPromptCard), findsOneWidget);
      expect(find.byType(DescribeSituationWritingArea), findsOneWidget);
      expect(find.byType(DescribeSituationConstellationMap), findsOneWidget);
      expect(
        find.byKey(const Key('describe_situation_submit_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('describe_situation_scroll_view')),
        findsOneWidget,
      );
      expect(find.text('SUBMIT DESCRIPTION'), findsOneWidget);
      expect(find.text('SITUATION PROMPT'), findsOneWidget);
      expect(
        find.text(
          'A deep-sea hydrothermal vent is discovered in the abyssal zone.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders all category emoji circles', (tester) async {
      await pumpScreen(tester, level: 2);

      for (int i = 0; i < sampleQuest1.emojis!.length; i++) {
        expect(find.byKey(Key('describe_situation_emoji_$i')), findsOneWidget);
        expect(find.text(sampleQuest1.emojis![i]), findsOneWidget);
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
            gameType: GameSubtype.describeSituationWriting,
            level: 2,
          ),
        ),
      ).called(1);
    });
  });

  group('DescribeSituationScreen - 2. Emoji Expansion & Keyword Injection', () {
    testWidgets('tapping an emoji expands its keyword booster list', (
      tester,
    ) async {
      await pumpScreen(tester, level: 2);

      // Initially, no keyword chips are rendered
      expect(find.text('TAP A KEYWORD TO ADD:'), findsNothing);

      // Tap first emoji (index 0)
      final emoji0 = find.byKey(const Key('describe_situation_emoji_0'));
      await tester.tap(emoji0);
      await tester.pumpAndSettle();

      verify(() => mockHapticService.selection()).called(1);
      expect(find.text('TAP A KEYWORD TO ADD:'), findsOneWidget);
      expect(find.text('VENTING'), findsOneWidget);
      expect(find.text('MAGMA'), findsOneWidget);
      expect(find.text('PLUME'), findsOneWidget);
    });

    testWidgets('tapping the same emoji again collapses the keyword list', (
      tester,
    ) async {
      await pumpScreen(tester, level: 2);

      final emoji0 = find.byKey(const Key('describe_situation_emoji_0'));
      await tester.tap(emoji0);
      await tester.pumpAndSettle();
      expect(find.text('TAP A KEYWORD TO ADD:'), findsOneWidget);

      await tester.tap(emoji0);
      await tester.pumpAndSettle();
      expect(find.text('TAP A KEYWORD TO ADD:'), findsNothing);
    });

    testWidgets('tapping a keyword injects it into text field and updates booster count', (
      tester,
    ) async {
      await pumpScreen(tester, level: 2);

      expect(find.text('Keywords used: 0'), findsOneWidget);

      // Expand emoji 0
      final emoji0 = find.byKey(const Key('describe_situation_emoji_0'));
      await tester.tap(emoji0);
      await tester.pumpAndSettle();

      // Tap keyword VENTING -> injected capitalized as first word
      final keywordVenting = find.byKey(const Key('describe_situation_keyword_VENTING'));
      await tester.tap(keywordVenting);
      await tester.pump();

      verify(() => mockHapticService.selection()).called(2);
      expect(find.text('Venting'), findsOneWidget);
      expect(find.text('Keywords used: 1'), findsOneWidget);
    });
  });

  group('DescribeSituationScreen - 3. Live Typing & Validation Rules', () {
    testWidgets('typing updates word count live', (tester) async {
      await pumpScreen(tester, level: 2);

      expect(find.text('0 / 15 words'), findsOneWidget);

      final inputField = find.byKey(
        const Key('describe_situation_input_field'),
      );
      await tester.enterText(
        inputField,
        'One two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen.',
      );
      await tester.pump();

      expect(find.text('15 / 15 words'), findsOneWidget);
    });

    testWidgets('submitting empty text does not submit', (tester) async {
      await pumpScreen(tester, level: 2);

      await scrollAndTapSubmitButton(tester);

      verifyNever(() => mockWritingBloc.add(const SubmitAnswer(true)));
      verifyNever(() => mockWritingBloc.add(const SubmitAnswer(false)));
    });

    testWidgets('warns if text does not start with capital letter', (
      tester,
    ) async {
      await pumpScreen(tester, level: 2);

      final inputField = find.byKey(
        const Key('describe_situation_input_field'),
      );
      await tester.enterText(
        inputField,
        'the benthic submarine explored the deep oceanic trench discovering strange creatures thriving in darkness.',
      );
      await tester.pump();

      await scrollAndTapSubmitButton(tester);

      expect(
        find.text(
          'Please start your description with a capital letter. (2 tries left)',
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
        const Key('describe_situation_input_field'),
      );
      await tester.enterText(
        inputField,
        'The benthic submarine explored the deep oceanic trench discovering strange creatures thriving in darkness',
      );
      await tester.pump();

      await scrollAndTapSubmitButton(tester);

      expect(
        find.text(
          'Please end your description with proper punctuation (., !, or ?). (2 tries left)',
        ),
        findsOneWidget,
      );
      verify(() => mockHapticService.warning()).called(1);
    });

    testWidgets('warns if word count is less than minWords (15)', (
      tester,
    ) async {
      await pumpScreen(tester, level: 2);

      final inputField = find.byKey(
        const Key('describe_situation_input_field'),
      );
      await tester.enterText(
        inputField,
        'The benthic creatures live here.',
      );
      await tester.pump();

      await scrollAndTapSubmitButton(tester);

      expect(
        find.text('Keep writing! You need at least 15 words. (2 tries left)'),
        findsOneWidget,
      );
      verify(() => mockHapticService.selection()).called(1);
    });

    testWidgets('warns if fewer than 2 narrative keywords are used', (
      tester,
    ) async {
      await pumpScreen(tester, level: 2);

      final inputField = find.byKey(
        const Key('describe_situation_input_field'),
      );
      // Only 1 keyword: "benthic"
      await tester.enterText(
        inputField,
        'The benthic submarine explored the mysterious deep trench while observers recorded every detail with high resolution lenses.',
      );
      await tester.pump();

      await scrollAndTapSubmitButton(tester);

      expect(
        find.text(
          'Please include at least 2 keywords from the emojis! (2 tries left)',
        ),
        findsOneWidget,
      );
      verify(() => mockHapticService.warning()).called(1);
    });

    testWidgets('warns if text lacks word variety', (tester) async {
      await pumpScreen(tester, level: 2);

      final inputField = find.byKey(
        const Key('describe_situation_input_field'),
      );
      // Repeated words
      await tester.enterText(
        inputField,
        'The benthic oceanic benthic oceanic benthic oceanic benthic oceanic benthic oceanic benthic oceanic benthic oceanic deep.',
      );
      await tester.pump();

      await scrollAndTapSubmitButton(tester);

      expect(
        find.text(
          'Your description lacks variety. Try using different words! (2 tries left)',
        ),
        findsOneWidget,
      );
      verify(() => mockHapticService.warning()).called(1);
    });

    testWidgets('warns if description is just a list of keywords without glue words', (
      tester,
    ) async {
      await pumpScreen(tester, level: 2);

      final inputField = find.byKey(
        const Key('describe_situation_input_field'),
      );
      // Chaining booster keywords together (word salad)
      await tester.enterText(
        inputField,
        'Venting magma plume oceanic thermal pressure mineral chemical hydrous creature benthic abyssal venting magma plume oceanic.',
      );
      await tester.pump();

      await scrollAndTapSubmitButton(tester);

      expect(
        find.text(
          'This looks like a list of keywords! Please write full, complete sentences connecting the words. (2 tries left)',
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
        const Key('describe_situation_input_field'),
      );

      // Strike 1
      await tester.enterText(inputField, 'strike one invalid low count');
      await tester.pump();
      await scrollAndTapSubmitButton(tester);

      // Strike 2
      await tester.enterText(inputField, 'strike two invalid low count');
      await tester.pump();
      await scrollAndTapSubmitButton(tester);

      // Strike 3
      await tester.enterText(inputField, 'strike three invalid low count');
      await tester.pump();
      await scrollAndTapSubmitButton(tester);

      verify(() => mockWritingBloc.add(const SubmitAnswer(false))).called(1);
    });
  });

  group('DescribeSituationScreen - 4. Language ID & Gibberish Detection', () {
    testWidgets('warns if language is detected as non-English', (
      tester,
    ) async {
      when(() => mockLanguageIdService.identifyLanguage(any()))
          .thenAnswer((_) async => 'fr');

      await pumpScreen(tester, level: 2);

      final inputField = find.byKey(
        const Key('describe_situation_input_field'),
      );
      await tester.enterText(
        inputField,
        'The benthic submarine explored the deep oceanic trench discovering strange creatures thriving in deep darkness.',
      );
      await tester.pump();

      await scrollAndTapSubmitButton(tester);

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
        const Key('describe_situation_input_field'),
      );
      await tester.enterText(
        inputField,
        'The benthic submarine explored the deep oceanic trench with aaaaaaaabbbbbb screaming loud in the abyss.',
      );
      await tester.pump();

      await scrollAndTapSubmitButton(tester);

      expect(
        find.text('No keyboard mashing allowed! Please write real words.'),
        findsOneWidget,
      );
    });
  });

  group('DescribeSituationScreen - 5. Validation Success & Speak To Confirm (Stage 2)', () {
    testWidgets('valid narrative entry reveals SpeakToConfirmOverlay', (
      tester,
    ) async {
      await pumpScreen(tester, level: 2);

      final inputField = find.byKey(
        const Key('describe_situation_input_field'),
      );
      await tester.enterText(
        inputField,
        'The benthic submarine explored the deep oceanic trench discovering strange creatures thriving in deep darkness.',
      );
      await tester.pump();

      await scrollAndTapSubmitButton(tester);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      verify(() => mockHapticService.success()).called(1);
      verify(() => mockSoundService.playCorrect()).called(1);

      expect(find.byType(SpeakToConfirmOverlay), findsOneWidget);
      expect(find.text('NOW SAY IT'), findsOneWidget);
      expect(
        find.byKey(const Key('describe_situation_submit_button')),
        findsNothing,
      );
    });

    testWidgets('confirming speech in SpeakToConfirmOverlay dispatches SubmitAnswer(true)', (
      tester,
    ) async {
      await pumpScreen(tester, level: 2);

      final inputField = find.byKey(
        const Key('describe_situation_input_field'),
      );
      await tester.enterText(
        inputField,
        'The benthic submarine explored the deep oceanic trench discovering strange creatures thriving in deep darkness.',
      );
      await tester.pump();

      await scrollAndTapSubmitButton(tester);
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
        const Key('describe_situation_input_field'),
      );
      await tester.enterText(
        inputField,
        'The benthic submarine explored the deep oceanic trench discovering strange creatures thriving in deep darkness.',
      );
      await tester.pump();

      await scrollAndTapSubmitButton(tester);
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

  group('DescribeSituationScreen - 6. Feedback, Navigation & Reset', () {
    testWidgets('displays feedback card and model answer when answered correctly', (
      tester,
    ) async {
      final answeredCorrect = testLoadedState.copyWith(
        answerStatus: AnswerStatus.correct,
      );

      await pumpScreen(tester, state: answeredCorrect, level: 2);

      expect(find.byType(GameFeedbackCard), findsOneWidget);
      expect(find.text('MODEL ANSWER'), findsOneWidget);
      expect(
        find.text(
          'The benthic creatures thrive near the deep oceanic hydrothermal vent despite immense pressure.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('tapping CONTINUE dispatches NextQuestion', (tester) async {
      final answeredState = testLoadedState.copyWith(
        answerStatus: AnswerStatus.correct,
      );

      await pumpScreen(tester, state: answeredState, level: 2);

      final continueBtn = find.text('CONTINUE');
      expect(continueBtn, findsOneWidget);
      await tester.tap(continueBtn);
      await tester.pump();

      verify(() => mockWritingBloc.add(const NextQuestion())).called(1);
    });

    testWidgets('tapping Hint button dispatches WritingHintUsed', (
      tester,
    ) async {
      await pumpScreen(tester, level: 2);

      final hintBtn = find.byType(QuestHintButton);
      expect(hintBtn, findsOneWidget);
      await tester.tap(hintBtn);
      await tester.pump();

      verify(() => mockWritingBloc.add(const WritingHintUsed())).called(1);
    });

    testWidgets('onQuestionReset resets controller and state on new question', (
      tester,
    ) async {
      await pumpScreen(tester, level: 2);

      final inputField = find.byKey(
        const Key('describe_situation_input_field'),
      );
      await tester.enterText(inputField, 'Some previous entered text.');
      await tester.pump();

      expect(find.text('Some previous entered text.'), findsOneWidget);

      // Transition to next question
      final nextQuestState = testLoadedState.copyWith(
        currentIndex: 1,
        answerStatus: AnswerStatus.unanswered,
      );
      writingStreamController.add(nextQuestState);
      when(() => mockWritingBloc.state).thenReturn(nextQuestState);
      await tester.pumpAndSettle();

      expect(find.text('0 / 12 words'), findsOneWidget);
      expect(find.text('Keywords used: 0'), findsOneWidget);
    });
  });

  group('DescribeSituationScreen - 7. Completion, Game Over & Error Journal', () {
    testWidgets('shows completion dialog on WritingGameComplete', (
      tester,
    ) async {
      await pumpScreen(tester, level: 2);

      const completeState = WritingGameComplete(
        xpEarned: 50,
        coinsEarned: 20,
        questCount: 2,
        gameType: GameSubtype.describeSituationWriting,
        level: 2,
      );

      writingStreamController.add(completeState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('LEVEL COMPLETE!'), findsOneWidget);

      final completeFinder = find.text('LEVEL COMPLETE!');
      if (completeFinder.evaluate().isNotEmpty) {
        Navigator.of(tester.element(completeFinder)).pop();
        await tester.pump(const Duration(milliseconds: 500));
      }
    });

    testWidgets('handles WritingGameOver without crash', (tester) async {
      await pumpScreen(tester, level: 2);

      final gameOverState = WritingGameOver(
        quests: [sampleQuest1],
        currentIndex: 0,
        gameType: GameSubtype.describeSituationWriting,
        level: 2,
      );
      writingStreamController.add(gameOverState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(DescribeSituationScreen), findsOneWidget);

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
            id: 'narrator_auth_err',
            email: 'err@vowl.app',
            displayName: 'Narrator Error',
          ),
        ),
      );

      await pumpScreen(tester, level: 2);

      final inputField = find.byKey(
        const Key('describe_situation_input_field'),
      );

      // 3 strikes
      for (int i = 0; i < 3; i++) {
        await tester.enterText(inputField, 'strike $i invalid');
        await tester.pump();
        await scrollAndTapSubmitButton(tester);
      }

      verify(() => mockWritingBloc.add(const SubmitAnswer(false))).called(1);
    });
  });

  group('DescribeSituationScreen - 8. Responsiveness & Accessibility', () {
    testWidgets('renders properly on small screen (320x568)', (tester) async {
      await pumpScreen(
        tester,
        level: 2,
        surfaceSize: const Size(320, 568),
      );

      expect(find.byType(DescribeSituationScreen), findsOneWidget);
      expect(find.byType(DescribeSituationInstruction), findsOneWidget);
      expect(find.byType(DescribeSituationWritingArea), findsOneWidget);
    });

    testWidgets('renders properly on tablet screen (800x1280)', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        level: 2,
        surfaceSize: const Size(800, 1280),
      );

      expect(find.byType(DescribeSituationScreen), findsOneWidget);
      expect(find.byType(DescribeSituationPromptCard), findsOneWidget);
      expect(find.byType(DescribeSituationConstellationMap), findsOneWidget);
    });

    testWidgets('renders with 1.3x high text scale without overflow', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        level: 2,
        textScaleFactor: 1.3,
      );

      expect(find.byType(DescribeSituationScreen), findsOneWidget);
      expect(find.byType(DescribeSituationWritingArea), findsOneWidget);
    });

    testWidgets('renders properly in light theme', (tester) async {
      await pumpScreen(
        tester,
        level: 2,
        themeMode: ThemeMode.light,
      );

      expect(find.byType(DescribeSituationScreen), findsOneWidget);
      expect(find.text('SUBMIT DESCRIPTION'), findsOneWidget);
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
