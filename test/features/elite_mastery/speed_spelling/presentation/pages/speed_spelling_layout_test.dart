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
import 'package:vowl/core/presentation/widgets/game_error_view.dart';
import 'package:vowl/core/presentation/widgets/quest_hint_button.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/theme/theme_cubit.dart';
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
import 'package:vowl/features/elite_mastery/domain/entities/elite_mastery_quest.dart';
import 'package:vowl/features/elite_mastery/presentation/bloc/elite_mastery_bloc.dart';
import 'package:vowl/features/elite_mastery/presentation/layout/elite_base_layout.dart';
import 'package:vowl/core/presentation/widgets/game_feedback_card.dart';
import 'package:vowl/features/elite_mastery/presentation/widgets/elite_game_header.dart';
import 'package:vowl/features/elite_mastery/presentation/widgets/elite_hint_card.dart';
import 'package:vowl/features/elite_mastery/speed_spelling/presentation/pages/speed_spelling_screen.dart';
import 'package:vowl/features/elite_mastery/speed_spelling/presentation/widgets/speed_spelling_character_deck.dart';
import 'package:vowl/features/elite_mastery/speed_spelling/presentation/widgets/speed_spelling_input_field.dart';

class MockEliteMasteryBloc
    extends MockBloc<EliteMasteryEvent, EliteMasteryState>
    implements EliteMasteryBloc {}

class MockThemeCubit extends MockCubit<ThemeState> implements ThemeCubit {}

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

class FakeEliteMasteryEvent extends Fake implements EliteMasteryEvent {}

class FakeEliteMasteryState extends Fake implements EliteMasteryState {}

class FakeAuthEvent extends Fake implements AuthEvent {}

class FakeAuthState extends Fake implements AuthState {}

class FakeEconomyEvent extends Fake implements EconomyEvent {}

class FakeEconomyState extends Fake implements EconomyState {}

class FakeThemeState extends Fake implements ThemeState {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  late MockEliteMasteryBloc mockEliteBloc;
  late MockThemeCubit mockThemeCubit;
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
  late StreamController<EliteMasteryState> eliteStreamController;

  EliteMasteryQuest createSampleSpeedQuest({
    String id = 'quest_sp_1',
    String instruction = 'Spell the word as quickly as possible',
    int difficulty = 1,
    String word = 'RHYTHM',
    String? difficultyTier = 'Rare',
    String? hint = 'Regulated succession of strong and weak musical elements.',
    String? explanation = 'Rhythm has no traditional vowels except y.',
  }) {
    return EliteMasteryQuest(
      id: id,
      type: QuestType.eliteMastery,
      subtype: GameSubtype.speedSpelling,
      instruction: instruction,
      difficulty: difficulty,
      word: word,
      difficultyTier: difficultyTier,
      hint: hint,
      explanation: explanation,
    );
  }

  final sampleSpeedQuest1 = createSampleSpeedQuest();

  final sampleSpeedQuest2 = createSampleSpeedQuest(
    id: 'quest_sp_2',
    instruction: 'Listen and spell',
    word: 'PHARAOH',
    difficultyTier: 'Advanced',
    hint: 'Ancient Egyptian ruler.',
  );

  final testLoadedState = EliteMasteryLoaded(
    gameType: GameSubtype.speedSpelling,
    level: 2,
    quests: [sampleSpeedQuest1, sampleSpeedQuest2],
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
  );

  setUpAll(() {
    registerFallbackValue(FakeEliteMasteryEvent());
    registerFallbackValue(FakeEliteMasteryState());
    registerFallbackValue(FakeAuthEvent());
    registerFallbackValue(FakeAuthState());
    registerFallbackValue(FakeEconomyEvent());
    registerFallbackValue(FakeEconomyState());
    registerFallbackValue(FakeThemeState());
  });

  setUp(() async {
    eliteStreamController = StreamController<EliteMasteryState>.broadcast();

    mockEliteBloc = MockEliteMasteryBloc();
    mockThemeCubit = MockThemeCubit();
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

    // Haptics & Sounds
    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});
    when(() => mockHapticService.heavy()).thenAnswer((_) async {});
    when(() => mockSoundService.playClick()).thenAnswer((_) async {});
    when(() => mockSoundService.playCorrect()).thenAnswer((_) async {});
    when(() => mockSoundService.playWrong()).thenAnswer((_) async {});
    when(() => mockSoundService.playHint()).thenAnswer((_) async {});
    when(() => mockSoundService.playLevelComplete()).thenAnswer((_) async {});
    when(() => mockSoundService.stopAudio()).thenAnswer((_) async {});
    when(() => mockSoundService.stopTts()).thenAnswer((_) async {});
    when(() => mockSoundService.playFile(any())).thenAnswer((_) async {});
    when(
      () => mockSoundService.playTts(any(), speed: any(named: 'speed')),
    ).thenAnswer((_) async {});

    // TTS
    when(() => mockTtsService.speak(any())).thenAnswer((_) async {});
    when(() => mockTtsService.stop()).thenAnswer((_) async {});

    // Theme mock
    when(
      () => mockThemeCubit.state,
    ).thenReturn(const ThemeState(themeMode: ThemeMode.dark, isMidnight: false));
    when(
      () => mockThemeCubit.stream,
    ).thenAnswer((_) => const Stream<ThemeState>.empty());

    // Auth mock (premium user)
    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(
        const UserEntity(
          id: 'test_user_id',
          email: 'speed@vowl.app',
          displayName: 'SpeedMaster',
          hintCount: 3,
          isPremium: true,
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

    // Ads mock
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

    // Elite Bloc default state
    when(() => mockEliteBloc.state).thenReturn(testLoadedState);
    when(
      () => mockEliteBloc.stream,
    ).thenAnswer((_) => eliteStreamController.stream);

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
    await eliteStreamController.close();
    VowlMotion.lowAnimationModeOverride.value = false;
    if (di.sl.isRegistered<HapticService>()) di.sl.unregister<HapticService>();
    if (di.sl.isRegistered<SoundService>()) di.sl.unregister<SoundService>();
    if (di.sl.isRegistered<TtsService>()) di.sl.unregister<TtsService>();
    if (di.sl.isRegistered<AudioRecordingService>()) {
      di.sl.unregister<AudioRecordingService>();
    }
    if (di.sl.isRegistered<SpeechService>()) di.sl.unregister<SpeechService>();
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
    EliteMasteryState? state,
    int level = 2,
    ThemeMode themeMode = ThemeMode.dark,
    double textScaleFactor = 1.0,
    Size surfaceSize = const Size(390, 844),
  }) async {
    tester.view.physicalSize = surfaceSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    if (state != null) {
      when(() => mockEliteBloc.state).thenReturn(state);
    }

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<EliteMasteryBloc>.value(value: mockEliteBloc),
          BlocProvider<ThemeCubit>.value(value: mockThemeCubit),
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
                  disableAnimations: true,
                ),
                child: SpeedSpellingScreen(level: level),
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 1: Initial Rendering & Layout Hierarchy
  // ═══════════════════════════════════════════════════════════════════════════
  group('SpeedSpellingScreen - 1. Initial Rendering & Layout Hierarchy', () {
    testWidgets('renders EliteBaseLayout, EliteGameHeader, CustomScrollView and instruction banner', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(find.byType(EliteBaseLayout), findsOneWidget);
      expect(find.byType(EliteGameHeader), findsOneWidget);
      expect(
        find.byKey(const Key('speed_spelling_scroll_view')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('speed_spelling_instruction_banner')),
        findsOneWidget,
      );
      expect(find.text(sampleSpeedQuest1.instruction), findsOneWidget);
    });

    testWidgets('renders replay audio button with volume icon when quest.word is present', (
      tester,
    ) async {
      await pumpScreen(tester);

      final replayBtn = find.byKey(
        const Key('speed_spelling_replay_audio_button'),
      );
      expect(replayBtn, findsOneWidget);
      expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
    });

    testWidgets('omits replay audio button when quest.word is null', (
      tester,
    ) async {
      final noWordQuest = EliteMasteryQuest(
        id: 'no_word_quest',
        type: QuestType.eliteMastery,
        subtype: GameSubtype.speedSpelling,
        instruction: 'Spell the word',
        difficulty: 1,
        word: null,
      );
      final noWordState = EliteMasteryLoaded(
        gameType: GameSubtype.speedSpelling,
        level: 2,
        quests: [noWordQuest],
        currentIndex: 0,
        livesRemaining: 3,
      );

      await pumpScreen(tester, state: noWordState);

      expect(
        find.byKey(const Key('speed_spelling_replay_audio_button')),
        findsNothing,
      );
    });

    testWidgets('renders difficulty tier badge with correct tier label and icon', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(
        find.byKey(const Key('speed_spelling_difficulty_badge')),
        findsOneWidget,
      );
      expect(find.text('RARE'), findsOneWidget);
      expect(find.byIcon(Icons.local_fire_department_rounded), findsOneWidget);
    });

    testWidgets('renders Advanced difficulty tier badge with star half icon', (
      tester,
    ) async {
      final advState = EliteMasteryLoaded(
        gameType: GameSubtype.speedSpelling,
        level: 2,
        quests: [sampleSpeedQuest2],
        currentIndex: 0,
        livesRemaining: 3,
      );

      await pumpScreen(tester, state: advState);

      expect(find.text('ADVANCED'), findsOneWidget);
      expect(find.byIcon(Icons.star_half_rounded), findsOneWidget);
    });

    testWidgets('renders speed bonus timer countdown bar and SPEED BONUS label', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(find.text('SPEED BONUS'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('renders SpeedSpellingInputField and SpeedSpellingCharacterDeck', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(find.byType(SpeedSpellingInputField), findsOneWidget);
      expect(
        find.byKey(const Key('speed_spelling_input_field')),
        findsOneWidget,
      );
      expect(find.byType(SpeedSpellingCharacterDeck), findsOneWidget);
      expect(
        find.byKey(const Key('speed_spelling_character_deck')),
        findsOneWidget,
      );
    });

    testWidgets('automatically plays TTS on initial post-frame load', (
      tester,
    ) async {
      await pumpScreen(tester);

      verify(() => mockTtsService.speak('RHYTHM')).called(1);
    });

    testWidgets('tapping audio replay button triggers TTS speech for target word', (
      tester,
    ) async {
      await pumpScreen(tester);

      clearInteractions(mockTtsService);

      await tester.tap(
        find.byKey(const Key('speed_spelling_replay_audio_button')),
      );
      await tester.pump();

      verify(() => mockTtsService.speak('RHYTHM')).called(1);
    });

    testWidgets('renders ShimmerLoading when EliteMasteryLoading is active', (
      tester,
    ) async {
      const loadingState = EliteMasteryLoading();
      await pumpScreen(tester, state: loadingState);

      expect(find.byType(ShimmerLoading), findsWidgets);
    });

    testWidgets('renders GameErrorView on EliteMasteryError and retries on tap', (
      tester,
    ) async {
      const errorState = EliteMasteryError('Failed to load speed spelling');
      await pumpScreen(tester, state: errorState);

      expect(find.byType(GameErrorView), findsOneWidget);
      expect(find.text('Failed to load speed spelling'), findsOneWidget);

      final retryBtn = find.text('RETRY');
      if (retryBtn.evaluate().isNotEmpty) {
        await tester.tap(retryBtn);
        await tester.pump();
        verify(
          () => mockEliteBloc.add(
            const FetchEliteMasteryQuests(
              gameType: GameSubtype.speedSpelling,
              level: 2,
            ),
          ),
        ).called(greaterThanOrEqualTo(1));
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 2: Input Field, Letter Tapping & Deck Interactions
  // ═══════════════════════════════════════════════════════════════════════════
  group('SpeedSpellingScreen - 2. Input Field, Letter Tapping & Deck Interactions', () {
    testWidgets('tapping letter tiles appends characters to input field and triggers light haptic', (
      tester,
    ) async {
      await pumpScreen(tester);

      // Tap tile 0
      final tile0 = find.byKey(const Key('speed_spelling_tile_0'));
      expect(tile0, findsOneWidget);

      await tester.tap(tile0);
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockHapticService.light()).called(1);

      // Input field now has 1 character
      final inputField = tester.widget<SpeedSpellingInputField>(
        find.byType(SpeedSpellingInputField),
      );
      expect(inputField.currentInput.length, 1);
    });

    testWidgets('tapping empty/used tile in deck does nothing and does not duplicate', (
      tester,
    ) async {
      await pumpScreen(tester);

      final tile0 = find.byKey(const Key('speed_spelling_tile_0'));
      await tester.tap(tile0);
      await tester.pump(const Duration(milliseconds: 100));

      clearInteractions(mockHapticService);

      // Tap tile 0 again (now it is empty string)
      await tester.tap(tile0, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 100));

      verifyNever(() => mockHapticService.light());

      final inputField = tester.widget<SpeedSpellingInputField>(
        find.byType(SpeedSpellingInputField),
      );
      expect(inputField.currentInput.length, 1);
    });

    testWidgets('backspace button is hidden when input is empty and visible when input has text', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(
        find.byKey(const Key('speed_spelling_backspace_button')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('speed_spelling_clear_button')),
        findsNothing,
      );

      // Tap tile 0
      await tester.tap(find.byKey(const Key('speed_spelling_tile_0')));
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.byKey(const Key('speed_spelling_backspace_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('speed_spelling_clear_button')),
        findsOneWidget,
      );
    });

    testWidgets('tapping backspace button removes last character and restores it to character deck', (
      tester,
    ) async {
      await pumpScreen(tester);

      // Tap tile 0
      await tester.tap(find.byKey(const Key('speed_spelling_tile_0')));
      await tester.pump(const Duration(milliseconds: 100));

      // Tap backspace
      final backspace = find.byKey(
        const Key('speed_spelling_backspace_button'),
      );
      await tester.tap(backspace);
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockHapticService.selection()).called(1);

      final inputField = tester.widget<SpeedSpellingInputField>(
        find.byType(SpeedSpellingInputField),
      );
      expect(inputField.currentInput, '');

      // Backspace and clear buttons are hidden again
      expect(
        find.byKey(const Key('speed_spelling_backspace_button')),
        findsNothing,
      );
    });

    testWidgets('tapping clear button clears all typed characters and restores deck', (
      tester,
    ) async {
      await pumpScreen(tester);

      // Tap tiles 0, 1, 2
      await tester.tap(find.byKey(const Key('speed_spelling_tile_0')));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byKey(const Key('speed_spelling_tile_1')));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byKey(const Key('speed_spelling_tile_2')));
      await tester.pump(const Duration(milliseconds: 100));

      var inputField = tester.widget<SpeedSpellingInputField>(
        find.byType(SpeedSpellingInputField),
      );
      expect(inputField.currentInput.length, 3);

      // Tap clear
      final clearBtn = find.byKey(const Key('speed_spelling_clear_button'));
      await tester.tap(clearBtn);
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockHapticService.selection()).called(1);

      inputField = tester.widget<SpeedSpellingInputField>(
        find.byType(SpeedSpellingInputField),
      );
      expect(inputField.currentInput, '');
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 3: Submission & Answer Evaluation
  // ═══════════════════════════════════════════════════════════════════════════
  group('SpeedSpellingScreen - 3. Submission & Answer Evaluation', () {
    testWidgets('submit button is rendered with disabled opacity when input length is incomplete', (
      tester,
    ) async {
      await pumpScreen(tester);

      final submitBtnFinder = find.byKey(
        const Key('speed_spelling_submit_button'),
      );
      expect(submitBtnFinder, findsOneWidget);

      final opacityWidget = tester.widget<Opacity>(
        find.ancestor(of: submitBtnFinder, matching: find.byType(Opacity)),
      );
      expect(opacityWidget.opacity, 0.5);

      // Tapping disabled submit button does nothing
      await tester.tap(submitBtnFinder, warnIfMissed: false);
      await tester.pump();

      verifyNever(() => mockEliteBloc.add(any(that: isA<SubmitEliteAnswer>())));
    });

    testWidgets('filling all letters enables submit button (opacity 1.0)', (
      tester,
    ) async {
      await pumpScreen(tester);

      // Word 'RHYTHM' has 6 letters -> tap all 6 tiles
      for (int i = 0; i < 6; i++) {
        await tester.tap(find.byKey(Key('speed_spelling_tile_$i')));
        await tester.pump(const Duration(milliseconds: 50));
      }

      final submitBtnFinder = find.byKey(
        const Key('speed_spelling_submit_button'),
      );
      final opacityWidget = tester.widget<Opacity>(
        find.ancestor(of: submitBtnFinder, matching: find.byType(Opacity)),
      );
      expect(opacityWidget.opacity, 1.0);
    });

    testWidgets('submitting correct spelling triggers success haptics, correct sound, and SubmitEliteAnswer(true)', (
      tester,
    ) async {
      await pumpScreen(tester);

      // Type the exact target word letters in sequence by finding the tile that contains each character
      final word = sampleSpeedQuest1.word!;
      final deck = tester.widget<SpeedSpellingCharacterDeck>(
        find.byType(SpeedSpellingCharacterDeck),
      );
      final currentChars = List<String>.from(deck.shuffledChars);

      for (int i = 0; i < word.length; i++) {
        final char = word[i];
        final index = currentChars.indexOf(char);
        expect(index, isNot(-1));
        currentChars[index] = ""; // mark consumed

        await tester.tap(find.byKey(Key('speed_spelling_tile_$index')));
        await tester.pump(const Duration(milliseconds: 50));
      }

      // Tap SUBMIT
      await tester.tap(find.byKey(const Key('speed_spelling_submit_button')));
      await tester.pumpAndSettle();

      verify(() => mockHapticService.success()).called(1);
      verify(() => mockSoundService.playCorrect()).called(1);
      verify(() => mockEliteBloc.add(const SubmitEliteAnswer(true))).called(1);
    });

    testWidgets('submitting wrong spelling triggers error haptics, wrong sound, and SubmitEliteAnswer(false)', (
      tester,
    ) async {
      await pumpScreen(tester);

      // Intentionally tap tiles in order 0, 1, 2, 3, 4, 5 without matching word
      // If by chance the shuffle was identical, reverse it
      final word = sampleSpeedQuest1.word!;
      final deck = tester.widget<SpeedSpellingCharacterDeck>(
        find.byType(SpeedSpellingCharacterDeck),
      );
      final currentChars = List<String>.from(deck.shuffledChars);

      // Make sure the typed string != word
      List<int> tapOrder = [0, 1, 2, 3, 4, 5];
      final spelled = tapOrder.map((idx) => currentChars[idx]).join();
      if (spelled.toLowerCase() == word.toLowerCase()) {
        tapOrder = [5, 4, 3, 2, 1, 0];
      }

      for (final idx in tapOrder) {
        await tester.tap(find.byKey(Key('speed_spelling_tile_$idx')));
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.tap(find.byKey(const Key('speed_spelling_submit_button')));
      await tester.pumpAndSettle();

      verify(() => mockHapticService.error()).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockEliteBloc.add(const SubmitEliteAnswer(false))).called(1);
    });

    testWidgets('once answered, submit button is hidden', (tester) async {
      await pumpScreen(tester);

      for (int i = 0; i < 6; i++) {
        await tester.tap(find.byKey(Key('speed_spelling_tile_$i')));
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.tap(find.byKey(const Key('speed_spelling_submit_button')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('speed_spelling_submit_button')),
        findsNothing,
      );
    });

    testWidgets('input field renders correct glow when isCorrect is true', (
      tester,
    ) async {
      await pumpScreen(tester);

      final word = sampleSpeedQuest1.word!;
      final deck = tester.widget<SpeedSpellingCharacterDeck>(
        find.byType(SpeedSpellingCharacterDeck),
      );
      final currentChars = List<String>.from(deck.shuffledChars);

      for (int i = 0; i < word.length; i++) {
        final char = word[i];
        final index = currentChars.indexOf(char);
        currentChars[index] = "";
        await tester.tap(find.byKey(Key('speed_spelling_tile_$index')));
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.tap(find.byKey(const Key('speed_spelling_submit_button')));
      await tester.pumpAndSettle();

      final input = tester.widget<SpeedSpellingInputField>(
        find.byType(SpeedSpellingInputField),
      );
      expect(input.isCorrect, true);
      expect(input.isAnswered, true);
    });

    testWidgets('speed bonus timer expiration triggers submitWrongAnswer', (
      tester,
    ) async {
      await pumpScreen(tester);

      // Advance clock past 30 seconds to trigger timer onEnd
      await tester.pump(const Duration(seconds: 31));
      await tester.pumpAndSettle();

      verify(() => mockHapticService.error()).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockEliteBloc.add(const SubmitEliteAnswer(false))).called(1);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 4: Game Lifecycle, Hints & State Transitions
  // ═══════════════════════════════════════════════════════════════════════════
  group('SpeedSpellingScreen - 4. Game Lifecycle, Hints & State Transitions', () {
    testWidgets('tapping hint button dispatches MarkEliteHintUsed and ShowEliteHint', (
      tester,
    ) async {
      await pumpScreen(tester);

      final hintBtn = find.byType(QuestHintButton);
      expect(hintBtn, findsOneWidget);

      await tester.tap(hintBtn);
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockEliteBloc.add(const MarkEliteHintUsed())).called(1);
      verify(() => mockEliteBloc.add(const ShowEliteHint())).called(1);
    });

    testWidgets('displays EliteHintCard when isHintVisible is true', (
      tester,
    ) async {
      final hintState = EliteMasteryLoaded(
        gameType: GameSubtype.speedSpelling,
        level: 2,
        quests: [sampleSpeedQuest1],
        currentIndex: 0,
        livesRemaining: 3,
        isHintVisible: true,
      );

      await pumpScreen(tester, state: hintState);

      expect(find.byType(EliteHintCard), findsOneWidget);
      expect(find.text(sampleSpeedQuest1.hint!), findsOneWidget);
    });

    testWidgets('omits hint button when quest.hint is null', (
      tester,
    ) async {
      final noHintQuest = EliteMasteryQuest(
        id: 'no_hint_sp',
        type: QuestType.eliteMastery,
        subtype: GameSubtype.speedSpelling,
        instruction: 'Spell the word',
        difficulty: 1,
        word: 'RHYTHM',
        hint: null,
      );
      final noHintState = EliteMasteryLoaded(
        gameType: GameSubtype.speedSpelling,
        level: 2,
        quests: [noHintQuest],
        currentIndex: 0,
        livesRemaining: 3,
      );

      await pumpScreen(tester, state: noHintState);

      expect(find.byType(QuestHintButton), findsNothing);
    });

    testWidgets('GameFeedbackCard appears on answered; tapping continue dispatches NextEliteQuestion', (
      tester,
    ) async {
      await pumpScreen(tester);

      // Submit correct answer
      final word = sampleSpeedQuest1.word!;
      final deck = tester.widget<SpeedSpellingCharacterDeck>(
        find.byType(SpeedSpellingCharacterDeck),
      );
      final currentChars = List<String>.from(deck.shuffledChars);

      for (int i = 0; i < word.length; i++) {
        final char = word[i];
        final index = currentChars.indexOf(char);
        currentChars[index] = "";
        await tester.tap(find.byKey(Key('speed_spelling_tile_$index')));
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.tap(find.byKey(const Key('speed_spelling_submit_button')));
      await tester.pumpAndSettle();

      expect(find.byType(GameFeedbackCard), findsOneWidget);

      final continueBtn = find.text('CONTINUE');
      expect(continueBtn, findsOneWidget);

      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      verify(() => mockEliteBloc.add(const NextEliteQuestion())).called(1);
    });

    testWidgets('state transition to EliteMasteryGameComplete shows level complete dialog and flushes confetti', (
      tester,
    ) async {
      await pumpScreen(tester);

      const completeState = EliteMasteryGameComplete(
        xpEarned: 5,
        coinsEarned: 10,
        questCount: 3,
      );

      when(() => mockEliteBloc.state).thenReturn(completeState);
      eliteStreamController.add(completeState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('LEVEL COMPLETE!'), findsOneWidget);

      // Clean up dialog and flush confetti timer cycles
      Navigator.of(tester.element(find.text('LEVEL COMPLETE!'))).pop();
      for (int i = 0; i < 5; i++) {
        await tester.pump(const Duration(seconds: 2));
      }
    });

    testWidgets('EliteMasteryGameOver renders dimmed view with zero lives', (
      tester,
    ) async {
      const gameOverState = EliteMasteryGameOver(
        gameType: GameSubtype.speedSpelling,
        level: 2,
        quests: [],
        currentIndex: 0,
      );

      await pumpScreen(tester, state: gameOverState);

      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('gracefully handles empty quests list without throwing', (
      tester,
    ) async {
      const emptyState = EliteMasteryLoaded(
        gameType: GameSubtype.speedSpelling,
        level: 2,
        quests: [],
        currentIndex: 0,
        livesRemaining: 3,
      );

      await pumpScreen(tester, state: emptyState);

      expect(find.byType(SpeedSpellingScreen), findsOneWidget);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 5: Responsive Layout, Text Scaling & Accessibility
  // ═══════════════════════════════════════════════════════════════════════════
  group('SpeedSpellingScreen - 5. Responsive Layout, Text Scaling & Accessibility', () {
    testWidgets('renders cleanly on compact screen (320x568) without overflow', (
      tester,
    ) async {
      await pumpScreen(tester, surfaceSize: const Size(320, 568));

      expect(find.byType(SpeedSpellingScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly on tablet viewport (800x1280)', (
      tester,
    ) async {
      await pumpScreen(tester, surfaceSize: const Size(800, 1280));

      expect(find.byType(SpeedSpellingScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders properly with enlarged textScaler (1.3x)', (
      tester,
    ) async {
      await pumpScreen(tester, textScaleFactor: 1.3);

      expect(find.byType(SpeedSpellingScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('accessible semantics: letter tiles have button semantics and labels', (
      tester,
    ) async {
      await pumpScreen(tester);

      final tileSemantics = tester.getSemantics(
        find.byKey(const Key('speed_spelling_tile_0')),
      );
      expect(tileSemantics.flagsCollection.isButton, isTrue);
    });

    testWidgets('renders cleanly in light and dark theme modes', (
      tester,
    ) async {
      await pumpScreen(tester, themeMode: ThemeMode.light);

      expect(find.byType(SpeedSpellingScreen), findsOneWidget);
      expect(tester.takeException(), isNull);

      await pumpScreen(tester, themeMode: ThemeMode.dark);

      expect(find.byType(SpeedSpellingScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

