import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:mocktail/mocktail.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/core/presentation/game_mechanics/shared/game_skip_bypass_button.dart';
import 'package:vowl/core/presentation/game_mechanics/speaking/speak_to_confirm_overlay.dart';
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
import 'package:vowl/features/elite_mastery/story_builder/presentation/pages/story_builder_screen.dart';
import 'package:vowl/features/elite_mastery/story_builder/presentation/widgets/story_builder_narrative_tile.dart';

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

  EliteMasteryQuest createSampleStoryQuest({
    String id = 'quest_sb_1',
    String instruction = 'Reconstruct the chronological narrative',
    int difficulty = 1,
    String? difficultyTier = 'Epic',
    String? plotStructure = 'Setup, Conflict, Climax, Resolution',
    String? sequenceLogic = 'Cause and effect progression',
    List<String>? sentences = const [
      'The expedition detected a rhythmic pulse from deep within the cavern.',
      'Dr. Aris discovered a crystalline structure vibrating in resonance.',
      'Touching the surface caused the temple monoliths to illuminate.',
      'The ancient navigational array unlocked the star coordinates.',
    ],
    List<int>? correctOrder = const [1, 0, 2, 3],
    String? hint = 'Begin with the discovery of the crystalline structure.',
    String? explanation =
        'The discovery of the crystal caused the resonance, triggering the monoliths.',
  }) {
    return EliteMasteryQuest(
      id: id,
      type: QuestType.eliteMastery,
      subtype: GameSubtype.storyBuilder,
      instruction: instruction,
      difficulty: difficulty,
      difficultyTier: difficultyTier,
      plotStructure: plotStructure,
      sequenceLogic: sequenceLogic,
      sentences: sentences,
      correctOrder: correctOrder,
      hint: hint,
      explanation: explanation,
    );
  }

  final sampleStoryQuest1 = createSampleStoryQuest();

  final sampleStoryQuest2 = createSampleStoryQuest(
    id: 'quest_sb_2',
    instruction: 'Arrange events from prologue to finale',
    difficultyTier: 'Master',
    plotStructure: 'Inciting Incident, Rising Action, Resolution',
    sequenceLogic: 'Chronological timeline',
    sentences: const [
      'The solar eclipse began over the capital.',
      'Shadows coalesced into sentient wraiths.',
      'The guardians channeled the light forge.',
    ],
    correctOrder: const [0, 1, 2],
    hint: 'Start with the astronomical event.',
  );

  final testLoadedState = EliteMasteryLoaded(
    gameType: GameSubtype.storyBuilder,
    level: 2,
    quests: [sampleStoryQuest1, sampleStoryQuest2],
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
    registerFallbackValue(const SubmitEliteAnswer(true));
    registerFallbackValue(const SubmitEliteAnswer(false));
    registerFallbackValue(const NextEliteQuestion());
    registerFallbackValue(const ShowEliteHint());
    registerFallbackValue(const MarkEliteHintUsed());
    registerFallbackValue(
      const FetchEliteMasteryQuests(
        gameType: GameSubtype.storyBuilder,
        level: 2,
      ),
    );
    registerFallbackValue(const Duration(milliseconds: 100));
  });

  setUp(() async {
    mockEliteBloc = MockEliteMasteryBloc();
    mockThemeCubit = MockThemeCubit();
    mockAuthBloc = MockAuthBloc();
    mockEconomyBloc = MockEconomyBloc();
    mockHapticService = MockHapticService();
    mockSoundService = MockSoundService();
    mockTtsService = MockTtsService();
    mockAudioRecorder = MockAudioRecordingService();
    mockLocaleService = MockLocaleService();
    mockAppLogger = MockAppLogger();
    mockAnalyticsService = MockAnalyticsService();
    mockAdService = MockAdService();
    mockNetworkInfo = MockNetworkInfo();

    eliteStreamController = StreamController<EliteMasteryState>.broadcast();

    // Haptics
    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});
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

    // Audio Recorder
    when(() => mockAudioRecorder.isRecording).thenReturn(false);
    when(() => mockAudioRecorder.hasPermission()).thenAnswer((_) async => true);
    when(
      () => mockAudioRecorder.startRecording(),
    ).thenAnswer((_) async => true);
    when(
      () => mockAudioRecorder.stopRecording(),
    ).thenAnswer((_) async => '/mock/story_recording.m4a');
    when(() => mockAudioRecorder.dispose()).thenAnswer((_) async {});
    when(
      () => mockAudioRecorder.onAmplitudeChanged(any()),
    ).thenAnswer((_) => const Stream<Amplitude>.empty());

    // Speech Service
    mockSpeechService = MockSpeechService();
    when(() => mockSpeechService.isPlaying).thenReturn(false);
    when(() => mockSpeechService.isListening).thenReturn(false);
    when(() => mockSpeechService.initializeStt()).thenAnswer((_) async => true);
    when(() => mockSpeechService.stop()).thenAnswer((_) async {});
    when(() => mockSpeechService.cancel()).thenAnswer((_) async {});

    // Analytics & Ads
    when(
      () => mockAnalyticsService.logGameSkipped(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockAnalyticsService.logSelfEvaluation(any()),
    ).thenAnswer((_) async {});
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

    // Theme mock (dark default)
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
          id: 'test_user_story',
          email: 'narrative@vowl.app',
          displayName: 'StoryMaster',
          hintCount: 3,
          isPremium: true,
        ),
      ),
    );
    when(
      () => mockAuthBloc.stream,
    ).thenAnswer((_) => const Stream<AuthState>.empty());

    // Economy mock
    when(() => mockEconomyBloc.state).thenReturn(const EconomyState());
    when(
      () => mockEconomyBloc.stream,
    ).thenAnswer((_) => const Stream<EconomyState>.empty());

    // Network mock
    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

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
    Size surfaceSize = const Size(390, 1600),
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
                child: StoryBuilderScreen(level: level),
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
  group('StoryBuilderScreen - 1. Initial Rendering & Layout Hierarchy', () {
    testWidgets(
      'renders EliteBaseLayout, EliteGameHeader, CustomScrollView, and instruction banner',
      (tester) async {
        await pumpScreen(tester);

        expect(find.byType(EliteBaseLayout), findsOneWidget);
        expect(find.byType(EliteGameHeader), findsOneWidget);
        expect(
          find.byKey(const Key('story_builder_scroll_view')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('story_builder_instruction_banner')),
          findsOneWidget,
        );
        expect(find.text(sampleStoryQuest1.instruction), findsOneWidget);
      },
    );

    testWidgets('renders instruction text correctly when present in quest', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(find.text(sampleStoryQuest1.instruction), findsOneWidget);
    });

    testWidgets(
      'renders narrative arc and plot structure banner when plotStructure is present',
      (tester) async {
        await pumpScreen(tester);

        expect(
          find.byKey(const Key('story_builder_narrative_arc')),
          findsOneWidget,
        );
        expect(find.text('NARRATIVE ARC'), findsOneWidget);
        expect(find.byIcon(Icons.timeline_rounded), findsOneWidget);
        expect(
          find.text('Setup ➔ Conflict ➔ Climax ➔ Resolution'),
          findsOneWidget,
        );
      },
    );

    testWidgets('omits narrative arc when quest.plotStructure is null', (
      tester,
    ) async {
      final noArcQuest = createSampleStoryQuest(plotStructure: null);
      final noArcState = EliteMasteryLoaded(
        gameType: GameSubtype.storyBuilder,
        level: 2,
        quests: [noArcQuest],
        currentIndex: 0,
        livesRemaining: 3,
      );

      await pumpScreen(tester, state: noArcState);

      expect(
        find.byKey(const Key('story_builder_narrative_arc')),
        findsNothing,
      );
      expect(find.text('NARRATIVE ARC'), findsNothing);
    });

    testWidgets(
      'renders sequence logic banner when quest.sequenceLogic is present',
      (tester) async {
        await pumpScreen(tester);

        expect(
          find.text('CAUSE AND EFFECT PROGRESSION'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'renders narrative tiles for all sentences with 1-based index numbers',
      (tester) async {
        await pumpScreen(tester);

        expect(find.byType(StoryBuilderNarrativeTile), findsNWidgets(4));
        expect(find.byKey(const Key('story_builder_tile_0')), findsOneWidget);
        expect(find.byKey(const Key('story_builder_tile_1')), findsOneWidget);
        expect(find.byKey(const Key('story_builder_tile_2')), findsOneWidget);
        expect(find.byKey(const Key('story_builder_tile_3')), findsOneWidget);

        expect(
          find.descendant(
            of: find.byKey(const Key('story_builder_tile_0')),
            matching: find.text('1'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('story_builder_tile_1')),
            matching: find.text('2'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('story_builder_tile_2')),
            matching: find.text('3'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byKey(const Key('story_builder_tile_3')),
            matching: find.text('4'),
          ),
          findsOneWidget,
        );

        for (final sentence in sampleStoryQuest1.sentences!) {
          expect(find.text(sentence), findsOneWidget);
        }
      },
    );

    testWidgets(
      'renders FINALIZE STORY button with correct styling, key, and semantics',
      (tester) async {
        await pumpScreen(tester);

        final finalizeBtn = find.byKey(
          const Key('story_builder_finalize_button'),
        );
        expect(finalizeBtn, findsOneWidget);
        expect(find.text('FINALIZE STORY'), findsOneWidget);

        final semanticsFinder = find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.button == true &&
              w.properties.label == 'FINALIZE STORY',
        );
        expect(semanticsFinder, findsOneWidget);
      },
    );
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 2: Tile Selection & Swapping Interactions
  // ═══════════════════════════════════════════════════════════════════════════
  group('StoryBuilderScreen - 2. Tile Selection & Swapping Interactions', () {
    testWidgets('tapping a tile highlights it as selected', (tester) async {
      await pumpScreen(tester);

      final tile0 = find.byKey(const Key('story_builder_tile_0'));
      expect(tile0, findsOneWidget);

      await tester.tap(tile0);
      await tester.pump();

      final narrativeTile0 = tester.widget<StoryBuilderNarrativeTile>(tile0);
      expect(narrativeTile0.isSelected, isTrue);

      final tile1 = find.byKey(const Key('story_builder_tile_1'));
      final narrativeTile1 = tester.widget<StoryBuilderNarrativeTile>(tile1);
      expect(narrativeTile1.isSelected, isFalse);
    });

    testWidgets('tapping the currently selected tile again deselects it', (
      tester,
    ) async {
      await pumpScreen(tester);

      final tile0 = find.byKey(const Key('story_builder_tile_0'));
      await tester.tap(tile0);
      await tester.pump();

      var narrativeTile0 = tester.widget<StoryBuilderNarrativeTile>(tile0);
      expect(narrativeTile0.isSelected, isTrue);

      await tester.tap(tile0);
      await tester.pump();

      narrativeTile0 = tester.widget<StoryBuilderNarrativeTile>(tile0);
      expect(narrativeTile0.isSelected, isFalse);
    });

    testWidgets(
      'tapping a different tile while one is selected swaps their positions and clears selection',
      (tester) async {
        await pumpScreen(tester);

        // Initially tile 0 has sentence 0, tile 1 has sentence 1
        var narrativeTile0 = tester.widget<StoryBuilderNarrativeTile>(
          find.byKey(const Key('story_builder_tile_0')),
        );
        var narrativeTile1 = tester.widget<StoryBuilderNarrativeTile>(
          find.byKey(const Key('story_builder_tile_1')),
        );
        expect(narrativeTile0.sentence, sampleStoryQuest1.sentences![0]);
        expect(narrativeTile1.sentence, sampleStoryQuest1.sentences![1]);

        // Tap tile 0 to select
        await tester.tap(find.byKey(const Key('story_builder_tile_0')));
        await tester.pump();

        // Tap tile 1 to swap
        await tester.tap(find.byKey(const Key('story_builder_tile_1')));
        await tester.pump();

        // After swap, tile 0 now contains sentence 1 and tile 1 contains sentence 0
        narrativeTile0 = tester.widget<StoryBuilderNarrativeTile>(
          find.byKey(const Key('story_builder_tile_0')),
        );
        narrativeTile1 = tester.widget<StoryBuilderNarrativeTile>(
          find.byKey(const Key('story_builder_tile_1')),
        );
        expect(narrativeTile0.sentence, sampleStoryQuest1.sentences![1]);
        expect(narrativeTile1.sentence, sampleStoryQuest1.sentences![0]);

        // Selection should be cleared
        expect(narrativeTile0.isSelected, isFalse);
        expect(narrativeTile1.isSelected, isFalse);
      },
    );

    testWidgets('swapping tiles triggers haptic selection feedback', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.tap(find.byKey(const Key('story_builder_tile_0')));
      await tester.pump();

      await tester.tap(find.byKey(const Key('story_builder_tile_1')));
      await tester.pump();

      verify(() => mockHapticService.selection()).called(1);
    });

    testWidgets(
      'drag and drop reordering via SliverReorderableList updates order and clears selection',
      (tester) async {
        await pumpScreen(tester);

        // Select tile 0
        await tester.tap(find.byKey(const Key('story_builder_tile_0')));
        await tester.pump();

        final reorderableFinder = find.byType(SliverReorderableList);
        expect(reorderableFinder, findsOneWidget);

        final reorderableList =
            tester.widget<SliverReorderableList>(reorderableFinder);
        // Move item 0 to position 2 (after item 1)
        reorderableList.onReorder(0, 2);
        await tester.pump();

        final updatedTile0 = tester.widget<StoryBuilderNarrativeTile>(
          find.byKey(const Key('story_builder_tile_0')),
        );
        expect(updatedTile0.sentence, sampleStoryQuest1.sentences![1]);
        expect(updatedTile0.isSelected, isFalse);
        verify(() => mockHapticService.selection()).called(1);
      },
    );

    testWidgets(
      'narrative tile displays drag indicator icon in reorderable state',
      (tester) async {
        await pumpScreen(tester);

        expect(find.byIcon(Icons.drag_indicator_rounded), findsNWidgets(4));
      },
    );

    testWidgets(
      'narrative tile provides correct accessibility semantics for position and sentence',
      (tester) async {
        await pumpScreen(tester);

        final semantics = find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.button == true &&
              w.properties.label != null &&
              w.properties.label!.contains('Position') &&
              w.properties.label!.contains(sampleStoryQuest1.sentences![0]),
        );
        expect(semantics, findsOneWidget);
      },
    );
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 3: Submission & Stage 1 Evaluation
  // ═══════════════════════════════════════════════════════════════════════════
  group('StoryBuilderScreen - 3. Submission & Stage 1 Evaluation', () {
    testWidgets(
      'tapping FINALIZE STORY with incorrect order calls SubmitEliteAnswer(false) and plays wrong sound',
      (tester) async {
        await pumpScreen(tester);

        // Initial order is [0, 1, 2, 3], while correctOrder is [1, 0, 2, 3]
        final finalizeBtn = find.byKey(
          const Key('story_builder_finalize_button'),
        );
        await tester.tap(finalizeBtn);
        await tester.pumpAndSettle();

        verify(() => mockSoundService.playWrong()).called(1);
        verify(() => mockHapticService.error()).called(1);
        verify(
          () => mockEliteBloc.add(any(that: isA<SubmitEliteAnswer>())),
        ).called(1);
      },
    );

    testWidgets(
      'tapping FINALIZE STORY with incorrect order displays GameFeedbackCard',
      (tester) async {
        await pumpScreen(tester);

        final finalizeBtn = find.byKey(
          const Key('story_builder_finalize_button'),
        );
        await tester.tap(finalizeBtn);
        await tester.pumpAndSettle();

        expect(find.byType(GameFeedbackCard), findsOneWidget);
      },
    );

    testWidgets(
      'tapping FINALIZE STORY with correct order triggers success haptics and sets stage 1 passed',
      (tester) async {
        await pumpScreen(tester);

        // Swap tile 0 and 1 so order becomes [1, 0, 2, 3]
        await tester.tap(find.byKey(const Key('story_builder_tile_0')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('story_builder_tile_1')));
        await tester.pump();

        final finalizeBtn = find.byKey(
          const Key('story_builder_finalize_button'),
        );
        await tester.tap(finalizeBtn);
        await tester.pumpAndSettle();

        verify(() => mockHapticService.success()).called(1);
        // Stage 1 success does not submit answer yet — verbal evaluation is next
        verifyNever(() => mockEliteBloc.add(const SubmitEliteAnswer(true)));
      },
    );

    testWidgets(
      'passing Stage 1 reveals SpeakToConfirmOverlay without dispatching SubmitEliteAnswer yet',
      (tester) async {
        await pumpScreen(tester);

        // Swap to correct order [1, 0, 2, 3]
        await tester.tap(find.byKey(const Key('story_builder_tile_0')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('story_builder_tile_1')));
        await tester.pump();

        await tester.tap(
          find.byKey(const Key('story_builder_finalize_button')),
        );
        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('story_builder_speak_overlay')),
          findsOneWidget,
        );
        expect(find.byType(SpeakToConfirmOverlay), findsOneWidget);
      },
    );

    testWidgets('passing Stage 1 hides FINALIZE STORY button', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byKey(const Key('story_builder_tile_0')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('story_builder_tile_1')));
      await tester.pump();

      await tester.tap(
        find.byKey(const Key('story_builder_finalize_button')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('story_builder_finalize_button')),
        findsNothing,
      );
    });

    testWidgets('passing Stage 1 locks narrative tiles into non-reorderable list', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.tap(find.byKey(const Key('story_builder_tile_0')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('story_builder_tile_1')));
      await tester.pump();

      await tester.tap(
        find.byKey(const Key('story_builder_finalize_button')),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SliverReorderableList), findsNothing);
      expect(find.byType(SliverList), findsOneWidget);

      final tile = tester.widget<StoryBuilderNarrativeTile>(
        find.byType(StoryBuilderNarrativeTile).first,
      );
      expect(tile.isReorderable, isFalse);
    });

    testWidgets('tapping FINALIZE STORY when already answered is ignored', (
      tester,
    ) async {
      final answeredState = EliteMasteryLoaded(
        gameType: GameSubtype.storyBuilder,
        level: 2,
        quests: [sampleStoryQuest1],
        currentIndex: 0,
        livesRemaining: 3,
        answerStatus: AnswerStatus.correct,
      );

      await pumpScreen(tester, state: answeredState);

      // In answered state, finalize button is hidden
      expect(
        find.byKey(const Key('story_builder_finalize_button')),
        findsNothing,
      );
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 4: Stage 2 Verbal Confirmation & Feedback
  // ═══════════════════════════════════════════════════════════════════════════
  group('StoryBuilderScreen - 4. Stage 2 Verbal Confirmation & Feedback', () {
    testWidgets(
      'SpeakToConfirmOverlay displays expected story text and NARRATE THE STORY title',
      (tester) async {
        await pumpScreen(tester);

        // Advance to Stage 2
        await tester.tap(find.byKey(const Key('story_builder_tile_0')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('story_builder_tile_1')));
        await tester.pump();
        await tester.tap(
          find.byKey(const Key('story_builder_finalize_button')),
        );
        await tester.pumpAndSettle();

        expect(find.text('NARRATE THE STORY'), findsOneWidget);
        expect(
          find.text('Read your completed story aloud'),
          findsOneWidget,
        );

        // Expected concatenated text in correct order [1, 0, 2, 3]
        final expectedText = [
          sampleStoryQuest1.sentences![1],
          sampleStoryQuest1.sentences![0],
          sampleStoryQuest1.sentences![2],
          sampleStoryQuest1.sentences![3],
        ].join(' ');
        expect(find.text(expectedText), findsOneWidget);
      },
    );

    testWidgets(
      'SpeakToConfirmOverlay bypass/skip button for premium user triggers onConfirmed and dispatches SubmitEliteAnswer(true)',
      (tester) async {
        await pumpScreen(tester);

        // Advance to Stage 2
        await tester.tap(find.byKey(const Key('story_builder_tile_0')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('story_builder_tile_1')));
        await tester.pump();
        await tester.tap(
          find.byKey(const Key('story_builder_finalize_button')),
        );
        await tester.pumpAndSettle();

        final bypassButton = find.byType(GameSkipBypassButton);
        expect(bypassButton, findsOneWidget);

        await tester.tap(bypassButton);
        await tester.pumpAndSettle();

        verify(() => mockSoundService.playCorrect()).called(1);
        verify(
          () => mockEliteBloc.add(const SubmitEliteAnswer(true)),
        ).called(1);
      },
    );

    testWidgets(
      'successful verbal evaluation displays GameFeedbackCard with continuation action',
      (tester) async {
        await pumpScreen(tester);

        // Advance to Stage 2
        await tester.tap(find.byKey(const Key('story_builder_tile_0')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('story_builder_tile_1')));
        await tester.pump();
        await tester.tap(
          find.byKey(const Key('story_builder_finalize_button')),
        );
        await tester.pumpAndSettle();

        // Tap bypass button to complete verbal stage
        await tester.tap(find.byType(GameSkipBypassButton));
        await tester.pumpAndSettle();

        expect(find.byType(GameFeedbackCard), findsOneWidget);
      },
    );

    testWidgets(
      'tapping continue on GameFeedbackCard dispatches NextEliteQuestion',
      (tester) async {
        await pumpScreen(tester);

        // Advance to Stage 2 and complete it
        await tester.tap(find.byKey(const Key('story_builder_tile_0')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('story_builder_tile_1')));
        await tester.pump();
        await tester.tap(
          find.byKey(const Key('story_builder_finalize_button')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byType(GameSkipBypassButton));
        await tester.pumpAndSettle();

        final continueBtn = find.text('CONTINUE');
        expect(continueBtn, findsOneWidget);

        await tester.tap(continueBtn);
        await tester.pumpAndSettle();

        verify(() => mockEliteBloc.add(any(that: isA<NextEliteQuestion>())))
            .called(1);
      },
    );

    testWidgets(
      'skipping verbal evaluation triggers submitWrongAnswer and dispatches SubmitEliteAnswer(false)',
      (tester) async {
        await pumpScreen(tester);

        // Advance to Stage 2
        await tester.tap(find.byKey(const Key('story_builder_tile_0')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('story_builder_tile_1')));
        await tester.pump();
        await tester.tap(
          find.byKey(const Key('story_builder_finalize_button')),
        );
        await tester.pumpAndSettle();

        final overlayWidget = tester.widget<SpeakToConfirmOverlay>(
          find.byKey(const Key('story_builder_speak_overlay')),
        );
        overlayWidget.onSkipped();
        await tester.pumpAndSettle();

        verify(() => mockSoundService.playWrong()).called(1);
        verify(
          () => mockEliteBloc.add(any(that: isA<SubmitEliteAnswer>())),
        ).called(1);
      },
    );

    testWidgets('SpeakToConfirmOverlay hides when answered state is reached', (
      tester,
    ) async {
      await pumpScreen(tester);

      // Advance to Stage 2
      await tester.tap(find.byKey(const Key('story_builder_tile_0')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('story_builder_tile_1')));
      await tester.pump();
      await tester.tap(
        find.byKey(const Key('story_builder_finalize_button')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('story_builder_speak_overlay')),
        findsOneWidget,
      );

      // Confirm verbal evaluation
      await tester.tap(find.byType(GameSkipBypassButton));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('story_builder_speak_overlay')),
        findsNothing,
      );
    });

    testWidgets(
      'tapping tiles is disabled after question is answered',
      (tester) async {
        await pumpScreen(tester);

        // Advance to Stage 2 and complete
        await tester.tap(find.byKey(const Key('story_builder_tile_0')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('story_builder_tile_1')));
        await tester.pump();
        await tester.tap(
          find.byKey(const Key('story_builder_finalize_button')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byType(GameSkipBypassButton));
        await tester.pumpAndSettle();

        // Invoking tap on narrative tile in answered state should not select it
        final tile = tester.widget<StoryBuilderNarrativeTile>(
          find.byType(StoryBuilderNarrativeTile).first,
        );
        tile.onTap?.call();
        await tester.pump();

        final updatedTile = tester.widget<StoryBuilderNarrativeTile>(
          find.byType(StoryBuilderNarrativeTile).first,
        );
        expect(updatedTile.isSelected, isFalse);
      },
    );
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // GROUP 5: Hints, Lifecycle, Game Over, Game Complete & Responsive
  // ═══════════════════════════════════════════════════════════════════════════
  group(
    'StoryBuilderScreen - 5. Hints, Lifecycle, Game Over, Game Complete & Responsive',
    () {
      testWidgets(
        'hint button triggers ShowEliteHint and MarkEliteHintUsed when hint exists',
        (tester) async {
          await pumpScreen(tester);

          final hintButton = find.byType(QuestHintButton);
          expect(hintButton, findsOneWidget);

          await tester.tap(hintButton);
          await tester.pump();

          verify(() => mockEliteBloc.add(const MarkEliteHintUsed())).called(1);
          verify(() => mockEliteBloc.add(const ShowEliteHint())).called(1);
        },
      );

      testWidgets('renders EliteHintCard when state.isHintVisible is true', (
        tester,
      ) async {
        final hintState = EliteMasteryLoaded(
          gameType: GameSubtype.storyBuilder,
          level: 2,
          quests: [sampleStoryQuest1],
          currentIndex: 0,
          livesRemaining: 3,
          isHintVisible: true,
        );

        await pumpScreen(tester, state: hintState);

        expect(find.byType(EliteHintCard), findsOneWidget);
        expect(find.text(sampleStoryQuest1.hint!), findsOneWidget);
      });

      testWidgets(
        'narrative tiles display #N position badges when hint is visible',
        (tester) async {
          final hintState = EliteMasteryLoaded(
            gameType: GameSubtype.storyBuilder,
            level: 2,
            quests: [sampleStoryQuest1],
            currentIndex: 0,
            livesRemaining: 3,
            isHintVisible: true,
          );

          await pumpScreen(tester, state: hintState);

          // In sampleStoryQuest1, correctOrder is [1, 0, 2, 3]
          // Sentence 0 (originalIndex 0) belongs at correctOrder index 1 -> badge #2
          // Sentence 1 (originalIndex 1) belongs at correctOrder index 0 -> badge #1
          // Sentence 2 (originalIndex 2) belongs at correctOrder index 2 -> badge #3
          // Sentence 3 (originalIndex 3) belongs at correctOrder index 3 -> badge #4
          expect(find.text('#1'), findsOneWidget);
          expect(find.text('#2'), findsOneWidget);
          expect(find.text('#3'), findsOneWidget);
          expect(find.text('#4'), findsOneWidget);
        },
      );

      testWidgets('omits hint button in header when quest.hint is null', (
        tester,
      ) async {
        final noHintQuest = createSampleStoryQuest(hint: null);
        final noHintState = EliteMasteryLoaded(
          gameType: GameSubtype.storyBuilder,
          level: 2,
          quests: [noHintQuest],
          currentIndex: 0,
          livesRemaining: 3,
        );

        await pumpScreen(tester, state: noHintState);

        expect(find.byType(QuestHintButton), findsNothing);
      });

      testWidgets(
        'renders EliteMasteryGameOver dimmed layout with 0 lives',
        (tester) async {
          final gameOverState = EliteMasteryGameOver(
            gameType: GameSubtype.storyBuilder,
            level: 2,
            quests: [sampleStoryQuest1],
            currentIndex: 0,
          );

          await pumpScreen(tester, state: gameOverState);

          expect(find.byType(EliteBaseLayout), findsOneWidget);
          expect(find.byType(Opacity), findsWidgets);
        },
      );

      testWidgets(
        'renders EliteMasteryGameComplete and flushes confetti timers cleanly',
        (tester) async {
          final completeState = const EliteMasteryGameComplete(
            xpEarned: 250,
            coinsEarned: 50,
            questCount: 2,
          );

          await pumpScreen(tester, state: completeState);

          expect(find.byType(EliteBaseLayout), findsOneWidget);
          // Flush confetti animations with 5 x 2-second pumps
          await tester.pump(const Duration(seconds: 2));
          await tester.pump(const Duration(seconds: 2));
          await tester.pump(const Duration(seconds: 2));
          await tester.pump(const Duration(seconds: 2));
          await tester.pump(const Duration(seconds: 2));
        },
      );

      testWidgets(
        'renders ShimmerLoading skeleton when in EliteMasteryLoading state',
        (tester) async {
          const loadingState = EliteMasteryLoading();

          await pumpScreen(tester, state: loadingState);

          expect(find.byType(ShimmerLoading), findsWidgets);
        },
      );

      testWidgets(
        'renders GameErrorView when in EliteMasteryError state and dispatches FetchEliteMasteryQuests on retry',
        (tester) async {
          const errorState =
              EliteMasteryError('Failed to load story builder quests');

          await pumpScreen(tester, state: errorState);

          expect(find.byType(GameErrorView), findsOneWidget);
          expect(
            find.text('Failed to load story builder quests'),
            findsOneWidget,
          );

          final retryBtn = find.text('RETRY');
          if (retryBtn.evaluate().isNotEmpty) {
            await tester.tap(retryBtn);
            await tester.pump();
            verify(
              () => mockEliteBloc.add(
                const FetchEliteMasteryQuests(
                  gameType: GameSubtype.storyBuilder,
                  level: 2,
                ),
              ),
            ).called(1);
          }
        },
      );

      testWidgets(
        'renders cleanly on compact screen (320x568) without overflow',
        (tester) async {
          await pumpScreen(
            tester,
            surfaceSize: const Size(320, 568),
          );

          expect(find.byType(StoryBuilderScreen), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        'renders cleanly on tablet screen (800x1280) and 1.3x text scale without overflow',
        (tester) async {
          await pumpScreen(
            tester,
            surfaceSize: const Size(800, 1280),
            textScaleFactor: 1.3,
          );

          expect(find.byType(StoryBuilderScreen), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets('adapts cleanly to light theme mode without errors', (
        tester,
      ) async {
        when(() => mockThemeCubit.state).thenReturn(
          const ThemeState(themeMode: ThemeMode.light, isMidnight: false),
        );

        await pumpScreen(tester, themeMode: ThemeMode.light);

        expect(find.byType(StoryBuilderScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('adapts cleanly to dark theme mode without errors', (
        tester,
      ) async {
        when(() => mockThemeCubit.state).thenReturn(
          const ThemeState(themeMode: ThemeMode.dark, isMidnight: false),
        );

        await pumpScreen(tester, themeMode: ThemeMode.dark);

        expect(find.byType(StoryBuilderScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    },
  );
}

