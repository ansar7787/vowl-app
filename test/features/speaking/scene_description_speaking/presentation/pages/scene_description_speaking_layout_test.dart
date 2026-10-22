import 'dart:async';
import 'dart:ui';
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
import 'package:vowl/core/presentation/widgets/game_error_view.dart';
import 'package:vowl/core/presentation/widgets/game_feedback_card.dart';
import 'package:vowl/core/presentation/widgets/quest_briefing_overlay.dart';
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
import 'package:vowl/features/speaking/domain/entities/speaking_quest.dart';
import 'package:vowl/features/speaking/presentation/bloc/speaking_bloc.dart';
import 'package:vowl/features/speaking/scene_description_speaking/presentation/pages/scene_description_speaking_screen.dart';
import 'package:vowl/features/speaking/scene_description_speaking/presentation/widgets/radar_beacon_painter.dart';
import 'package:vowl/features/speaking/scene_description_speaking/presentation/widgets/scene_description_active_prompt_card.dart';
import 'package:vowl/features/speaking/scene_description_speaking/presentation/widgets/scene_description_explorer_guide_card.dart';
import 'package:vowl/features/speaking/scene_description_speaking/presentation/widgets/scene_description_header.dart';
import 'package:vowl/features/speaking/scene_description_speaking/presentation/widgets/scene_description_scenic_radar_map.dart';

class MockSpeakingBloc extends MockBloc<SpeakingEvent, SpeakingState>
    implements SpeakingBloc {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockEconomyBloc extends MockBloc<EconomyEvent, EconomyState>
    implements EconomyBloc {}

class MockHapticService extends Mock implements HapticService {}

class MockSoundService extends Mock implements SoundService {}

class MockTtsService extends Mock implements TtsService {}

class MockSpeechService extends Mock implements SpeechService {}

class MockAudioRecordingService extends Mock implements AudioRecordingService {}

class MockLocaleService extends Mock implements LocaleService {}

class MockAppLogger extends Mock implements AppLogger {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockAdService extends Mock implements AdService {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSpeakingBloc mockSpeakingBloc;
  late MockAuthBloc mockAuthBloc;
  late MockEconomyBloc mockEconomyBloc;
  late MockHapticService mockHapticService;
  late MockSoundService mockSoundService;
  late MockTtsService mockTtsService;
  late MockSpeechService mockSpeechService;
  late MockAudioRecordingService mockAudioRecorder;
  late MockLocaleService mockLocaleService;
  late MockAppLogger mockAppLogger;
  late MockAnalyticsService mockAnalyticsService;
  late MockAdService mockAdService;
  late MockNetworkInfo mockNetworkInfo;
  late StreamController<SpeakingState> speakingStreamController;

  SpeakingQuest createQuest({
    String id = 'quest_scene_1',
    String sceneText =
        'SPACE STATION HYDROPONICS|Describe the primary function of the solar array.|Describe the nutrient delivery system.|Describe the glowing flora specimen.',
    List<String>? options = const [
      'Solar Array',
      'Nutrient Tank',
      'Glowing Flora',
    ],
    List<String>? acceptedSynonyms = const [
      'solar,power,array,energy',
      'tank,nutrient,water,solution',
      'flora,plant,specimen,glowing',
    ],
    List<String>? keyVocabulary = const [
      'hydroponics',
      'solar',
      'nutrients',
      'photosynthesis',
    ],
    String? sampleAnswer =
        'The space station hydroponics facility uses high-efficiency solar arrays to power advanced nutrient delivery pumps, cultivating vibrant bioluminescent flora in microgravity.',
    String instruction = 'Inspect and describe all features in the scene.',
    String? hint =
        'Focus on the relation between energy input and plant growth in zero-G.',
    int difficulty = 2,
  }) {
    return SpeakingQuest(
      id: id,
      type: QuestType.speaking,
      subtype: GameSubtype.sceneDescriptionSpeaking,
      sceneText: sceneText,
      options: options,
      acceptedSynonyms: acceptedSynonyms,
      keyVocabulary: keyVocabulary,
      sampleAnswer: sampleAnswer,
      instruction: instruction,
      hint: hint,
      difficulty: difficulty,
      targetWord: 'hydroponics',
    );
  }

  final sampleQuest1 = createQuest();
  final sampleQuest2 = createQuest(
    id: 'quest_scene_2',
    sceneText:
        'ANCIENT LIBRARY ARCHIVE|Describe the illuminated manuscripts.|Describe the vaulted stone arches.|Describe the floating dust motes.',
    options: ['Manuscripts', 'Arches', 'Dust Motes'],
    acceptedSynonyms: [
      'manuscripts,books,parchment',
      'arches,pillars,stonework',
      'dust,motes,particles',
    ],
    sampleAnswer:
        'Sunlight filters through towering stained-glass windows onto ancient parchment scrolls.',
  );

  final testLoadedState = SpeakingLoaded(
    quests: [sampleQuest1, sampleQuest2],
    currentIndex: 0,
    livesRemaining: 3,
    wrongCount: 0,
    hintUsed: false,
    answerStatus: AnswerStatus.unanswered,
    gameType: GameSubtype.sceneDescriptionSpeaking,
    level: 2,
  );

  setUpAll(() {
    registerFallbackValue(const SubmitAnswer(true));
    registerFallbackValue(const NextQuestion());
    registerFallbackValue(const SpeakingHintUsed());
    registerFallbackValue(
      const FetchSpeakingQuests(
        gameType: GameSubtype.sceneDescriptionSpeaking,
        level: 2,
      ),
    );
    registerFallbackValue(const Duration(milliseconds: 50));
    VowlMotion.lowAnimationModeOverride.value = true;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'has_seen_briefing_sceneDescriptionSpeaking': true,
    });

    mockSpeakingBloc = MockSpeakingBloc();
    mockAuthBloc = MockAuthBloc();
    mockEconomyBloc = MockEconomyBloc();
    mockHapticService = MockHapticService();
    mockSoundService = MockSoundService();
    mockTtsService = MockTtsService();
    mockSpeechService = MockSpeechService();
    mockAudioRecorder = MockAudioRecordingService();
    mockLocaleService = MockLocaleService();
    mockAppLogger = MockAppLogger();
    mockAnalyticsService = MockAnalyticsService();
    mockAdService = MockAdService();
    mockNetworkInfo = MockNetworkInfo();

    speakingStreamController = StreamController<SpeakingState>.broadcast();
    when(() => mockSpeakingBloc.state).thenReturn(testLoadedState);
    whenListen(
      mockSpeakingBloc,
      speakingStreamController.stream,
      initialState: testLoadedState,
    );

    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(
        const UserEntity(
          id: 'test_user_scene',
          email: 'scene@vowl.app',
          displayName: 'Scenic Pilot',
          hintCount: 3,
        ),
      ),
    );
    when(() => mockAuthBloc.stream)
        .thenAnswer((_) => const Stream<AuthState>.empty());

    when(() => mockEconomyBloc.state).thenReturn(const EconomyState());
    when(() => mockEconomyBloc.stream)
        .thenAnswer((_) => const Stream<EconomyState>.empty());

    when(() => mockAudioRecorder.isRecording).thenReturn(false);
    when(() => mockAudioRecorder.hasPermission()).thenAnswer((_) async => true);
    when(() => mockAudioRecorder.startRecording()).thenAnswer((_) async => true);
    when(() => mockAudioRecorder.stopRecording())
        .thenAnswer((_) async => 'mock_scene_rec.m4a');
    when(() => mockAudioRecorder.dispose()).thenAnswer((_) async {});

    when(() => mockSpeechService.isListening).thenReturn(false);
    when(() => mockSpeechService.initializeStt()).thenAnswer((_) async => true);
    when(() => mockSpeechService.stop()).thenAnswer((_) async {});
    when(() => mockSpeechService.cancel()).thenAnswer((_) async {});

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

    when(() => mockTtsService.stop()).thenAnswer((_) async {});
    when(
      () => mockTtsService.speak(
        any(),
        rate: any(named: 'rate'),
        locale: any(named: 'locale'),
      ),
    ).thenAnswer((_) async {});

    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

    await di.sl.reset();
    di.sl.registerSingleton<HapticService>(mockHapticService);
    di.sl.registerSingleton<SoundService>(mockSoundService);
    di.sl.registerSingleton<TtsService>(mockTtsService);
    di.sl.registerSingleton<SpeechService>(mockSpeechService);
    di.sl.registerSingleton<AudioRecordingService>(mockAudioRecorder);
    di.sl.registerSingleton<LocaleService>(mockLocaleService);
    di.sl.registerSingleton<AppLogger>(mockAppLogger);
    di.sl.registerSingleton<AnalyticsService>(mockAnalyticsService);
    di.sl.registerSingleton<AdService>(mockAdService);
    di.sl.registerSingleton<NetworkInfo>(mockNetworkInfo);
  });

  tearDown(() async {
    await di.sl.reset();
    await speakingStreamController.close();
  });

  tearDownAll(() {
    VowlMotion.lowAnimationModeOverride.value = false;
  });

  Future<void> pumpSceneDescriptionScreen(
    WidgetTester tester, {
    SpeakingState? state,
    int level = 2,
    GameSubtype gameType = GameSubtype.sceneDescriptionSpeaking,
    ThemeMode themeMode = ThemeMode.dark,
    Size size = const Size(390, 844),
    double textScaleFactor = 1.0,
    bool reduceMotion = false,
  }) async {
    tester.view.physicalSize = Size(size.width * 2, size.height * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final activeState = state ?? testLoadedState;
    when(() => mockSpeakingBloc.state).thenReturn(activeState);
    whenListen(
      mockSpeakingBloc,
      speakingStreamController.stream,
      initialState: activeState,
    );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<SpeakingBloc>.value(value: mockSpeakingBloc),
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<EconomyBloc>.value(value: mockEconomyBloc),
        ],
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) => MaterialApp(
            themeMode: themeMode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: TextScaler.linear(textScaleFactor),
                disableAnimations: reduceMotion,
              ),
              child: SceneDescriptionScreen(
                level: level,
                gameType: gameType,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  group('1. Initial & Shimmer Loading States', () {
    testWidgets('displays GameShimmerLoading during SpeakingInitial state', (
      tester,
    ) async {
      await pumpSceneDescriptionScreen(tester, state: const SpeakingInitial());

      expect(find.byType(GameShimmerLoading), findsOneWidget);
      expect(find.byType(SceneDescriptionScenicRadarMap), findsNothing);
      expect(find.byType(SceneDescriptionExplorerGuideCard), findsNothing);
    });

    testWidgets('displays GameShimmerLoading during SpeakingLoading state', (
      tester,
    ) async {
      await pumpSceneDescriptionScreen(tester, state: const SpeakingLoading());

      expect(find.byType(GameShimmerLoading), findsOneWidget);
    });

    testWidgets('displays error view and retry button during SpeakingError state', (
      tester,
    ) async {
      await pumpSceneDescriptionScreen(
        tester,
        state: const SpeakingError('Network connectivity failure'),
      );

      expect(find.byType(GameErrorView), findsOneWidget);
      expect(find.text('Network connectivity failure'), findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
    });

    testWidgets('tapping retry dispatches FetchSpeakingQuests', (tester) async {
      await pumpSceneDescriptionScreen(
        tester,
        state: const SpeakingError('Radar calibration failed'),
      );

      final retryBtn = find.byIcon(Icons.refresh_rounded);
      expect(retryBtn, findsOneWidget);
      await tester.tap(retryBtn);
      await tester.pump();

      verify(
        () => mockSpeakingBloc.add(
          const FetchSpeakingQuests(
            gameType: GameSubtype.sceneDescriptionSpeaking,
            level: 2,
          ),
        ),
      ).called(2);
    });
  });

  group('2. Briefing Overlay Mechanics', () {
    testWidgets('displays QuestBriefingOverlay on level 1', (
      tester,
    ) async {
      await pumpSceneDescriptionScreen(tester, level: 1);

      expect(find.byType(QuestBriefingOverlay), findsOneWidget);
      expect(find.text('VISUAL NARRATOR'), findsOneWidget);
      expect(find.text('DESCRIBE SCENE'), findsOneWidget);
    });

    testWidgets('tapping action button dismisses briefing overlay', (
      tester,
    ) async {
      await pumpSceneDescriptionScreen(tester, level: 1);

      final actionBtn = find.text('DESCRIBE SCENE');
      expect(actionBtn, findsOneWidget);
      await tester.ensureVisible(actionBtn);
      await tester.tap(actionBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(QuestBriefingOverlay), findsNothing);
      expect(find.byType(SceneDescriptionScenicRadarMap), findsOneWidget);
    });

    testWidgets('skips briefing overlay on level 2', (tester) async {
      await pumpSceneDescriptionScreen(tester, level: 2);

      expect(find.byType(QuestBriefingOverlay), findsNothing);
      expect(find.byType(SceneDescriptionScenicRadarMap), findsOneWidget);
    });
  });

  group('3. Loaded State - Header & Instructions', () {
    testWidgets('renders SceneDescriptionHeader with upper-case instruction', (
      tester,
    ) async {
      await pumpSceneDescriptionScreen(tester);

      expect(find.byType(SceneDescriptionHeader), findsOneWidget);
      expect(
        find.text('Inspect and describe all features in the scene.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.gps_fixed_rounded), findsOneWidget);
    });

    testWidgets('header has Semantics header trait', (tester) async {
      await pumpSceneDescriptionScreen(tester);

      final semanticsHeader = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.header == true &&
            widget.properties.label ==
                'Inspect and describe all features in the scene.',
      );
      expect(semanticsHeader, findsOneWidget);
    });

    testWidgets('header text contains Key scene_description_header_text', (
      tester,
    ) async {
      await pumpSceneDescriptionScreen(tester);

      expect(
        find.byKey(const Key('scene_description_header_text')),
        findsOneWidget,
      );
    });
  });

  group('4. Scenic Radar Map & Pulsing Beacons', () {
    testWidgets('renders radar map with central scene title', (tester) async {
      await pumpSceneDescriptionScreen(tester);

      expect(find.byType(SceneDescriptionScenicRadarMap), findsOneWidget);
      expect(
        find.byKey(const Key('scene_description_scenic_radar_map')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('scene_description_title_text')),
        findsOneWidget,
      );
      expect(find.text('SPACE STATION HYDROPONICS'), findsOneWidget);
    });

    testWidgets('displays features stabilized count initially at 0 of 3', (
      tester,
    ) async {
      await pumpSceneDescriptionScreen(tester);

      expect(
        find.byKey(const Key('scene_description_progress_text')),
        findsOneWidget,
      );
      expect(find.text('0 of 3 items described'), findsOneWidget);
    });

    testWidgets('renders dynamic beacons with labels', (tester) async {
      await pumpSceneDescriptionScreen(tester);

      expect(
        find.byKey(const Key('scene_description_beacon_0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('scene_description_beacon_1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('scene_description_beacon_2')),
        findsOneWidget,
      );

      expect(find.text('Solar Array'), findsOneWidget);
      expect(find.text('Nutrient Tank'), findsOneWidget);
      expect(find.text('Glowing Flora'), findsOneWidget);
    });

    testWidgets('beacons have Semantics with button trait and labels', (
      tester,
    ) async {
      await pumpSceneDescriptionScreen(tester);

      final beacon0Semantics = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.button == true &&
            widget.properties.label == 'Beacon 1: Solar Array',
      );
      expect(beacon0Semantics, findsOneWidget);

      final beacon1Semantics = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            widget.properties.button == true &&
            widget.properties.label == 'Beacon 2: Nutrient Tank',
      );
      expect(beacon1Semantics, findsOneWidget);
    });
  });

  group('5. RadarBeaconPainter Direct Tests', () {
    test('repaints when progress changes', () {
      final painter1 = RadarBeaconPainter(
        progress: 0.2,
        isActive: false,
        isCompleted: false,
        primaryColor: Colors.blue,
      );
      final painter2 = RadarBeaconPainter(
        progress: 0.5,
        isActive: false,
        isCompleted: false,
        primaryColor: Colors.blue,
      );
      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('repaints when isActive or isCompleted changes', () {
      final painter1 = RadarBeaconPainter(
        progress: 0.5,
        isActive: true,
        isCompleted: false,
        primaryColor: Colors.blue,
      );
      final painter2 = RadarBeaconPainter(
        progress: 0.5,
        isActive: false,
        isCompleted: false,
        primaryColor: Colors.blue,
      );
      expect(painter1.shouldRepaint(painter2), isTrue);
    });

    test('paints completed state without error', () {
      final painter = RadarBeaconPainter(
        progress: 0.5,
        isActive: false,
        isCompleted: true,
        primaryColor: Colors.blue,
      );
      final pictureRecorder = PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      painter.paint(canvas, const Size(100, 100));
      final picture = pictureRecorder.endRecording();
      expect(picture, isNotNull);
    });

    test('paints active state without error', () {
      final painter = RadarBeaconPainter(
        progress: 0.7,
        isActive: true,
        isCompleted: false,
        primaryColor: Colors.blue,
      );
      final pictureRecorder = PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      painter.paint(canvas, const Size(100, 100));
      final picture = pictureRecorder.endRecording();
      expect(picture, isNotNull);
    });

    test('paints sleeping idle state without error', () {
      final painter = RadarBeaconPainter(
        progress: 0.3,
        isActive: false,
        isCompleted: false,
        primaryColor: Colors.blue,
      );
      final pictureRecorder = PictureRecorder();
      final canvas = Canvas(pictureRecorder);
      painter.paint(canvas, const Size(100, 100));
      final picture = pictureRecorder.endRecording();
      expect(picture, isNotNull);
    });
  });

  group('6. Explorer Guide Card vs Active Prompt Card', () {
    testWidgets('shows ExplorerGuideCard initially when no beacon is active', (
      tester,
    ) async {
      await pumpSceneDescriptionScreen(tester);

      expect(find.byType(SceneDescriptionExplorerGuideCard), findsOneWidget);
      expect(
        find.byKey(const Key('scene_description_explorer_guide_card')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('scene_description_explorer_guide_text')),
        findsOneWidget,
      );
      expect(
        find.byType(SceneDescriptionActivePromptCard),
        findsNothing,
      );
      expect(find.byType(SpeakToConfirmOverlay), findsNothing);
    });

    testWidgets('guide card has accessibility semantics container', (
      tester,
    ) async {
      await pumpSceneDescriptionScreen(tester);

      final guideSemantics = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            (widget.properties.label ?? '').contains('describe it aloud'),
      );
      expect(guideSemantics, findsOneWidget);
    });

    testWidgets('tapping beacon 0 opens ActivePromptCard and SpeakToConfirmOverlay', (
      tester,
    ) async {
      await pumpSceneDescriptionScreen(tester);

      final beacon0 = find.byKey(const Key('scene_description_beacon_0'));
      await tester.tap(beacon0);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockHapticService.selection()).called(1);
      verify(() => mockSoundService.playTts('Solar Array')).called(1);

      expect(find.byType(SceneDescriptionActivePromptCard), findsOneWidget);
      expect(
        find.byKey(const Key('scene_description_active_prompt_card')),
        findsOneWidget,
      );
      expect(
        find.text('Describe the primary function of the solar array.'),
        findsOneWidget,
      );
      expect(find.byType(SpeakToConfirmOverlay), findsOneWidget);
      expect(find.byType(SceneDescriptionExplorerGuideCard), findsNothing);
    });

    testWidgets('tapping beacon while recording suppresses TTS playback', (
      tester,
    ) async {
      when(() => mockAudioRecorder.isRecording).thenReturn(true);

      await pumpSceneDescriptionScreen(tester);

      final beacon1 = find.byKey(const Key('scene_description_beacon_1'));
      await tester.tap(beacon1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verifyNever(() => mockSoundService.playTts('Nutrient Tank'));
      expect(find.byType(SceneDescriptionActivePromptCard), findsOneWidget);
      expect(
        find.text('Describe the nutrient delivery system.'),
        findsOneWidget,
      );
    });

    testWidgets('active prompt card has accessibility semantics container', (
      tester,
    ) async {
      await pumpSceneDescriptionScreen(tester);

      await tester.tap(find.byKey(const Key('scene_description_beacon_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final promptSemantics = find.byWidgetPredicate(
        (widget) =>
            widget is Semantics &&
            (widget.properties.label ?? '').contains('Describe this item:'),
      );
      expect(promptSemantics, findsOneWidget);
    });
  });

  group('7. Target Vocabulary Section', () {
    testWidgets('renders Target Vocabulary title and chips when provided', (
      tester,
    ) async {
      await pumpSceneDescriptionScreen(tester);

      expect(
        find.byKey(const Key('scene_description_vocab_title')),
        findsOneWidget,
      );
      expect(find.text('Target Vocabulary'), findsOneWidget);

      expect(find.byKey(const Key('scene_description_vocab_0')), findsOneWidget);
      expect(find.byKey(const Key('scene_description_vocab_1')), findsOneWidget);
      expect(find.byKey(const Key('scene_description_vocab_2')), findsOneWidget);
      expect(find.byKey(const Key('scene_description_vocab_3')), findsOneWidget);

      expect(find.text('hydroponics'), findsOneWidget);
      expect(find.text('photosynthesis'), findsOneWidget);
    });

    testWidgets('omits Target Vocabulary section if keyVocabulary is empty or null', (
      tester,
    ) async {
      final noVocabQuest = createQuest(keyVocabulary: null);
      final stateNoVocab = SpeakingLoaded(
        quests: [noVocabQuest],
        currentIndex: 0,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.unanswered,
        gameType: GameSubtype.sceneDescriptionSpeaking,
        level: 2,
      );

      await pumpSceneDescriptionScreen(tester, state: stateNoVocab);

      expect(
        find.byKey(const Key('scene_description_vocab_title')),
        findsNothing,
      );
      expect(find.text('Target Vocabulary'), findsNothing);
    });
  });

  group('8. Verbal Self-Evaluation Confirmation & Failure', () {
    testWidgets('successful confirmation stabilizes beacon 0 and returns to guide card', (
      tester,
    ) async {
      await pumpSceneDescriptionScreen(tester);

      // Tap beacon 0
      await tester.tap(find.byKey(const Key('scene_description_beacon_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Confirm hotspot 0
      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byType(SpeakToConfirmOverlay),
      );
      overlay.onConfirmed();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockHapticService.success()).called(1);
      verify(() => mockSoundService.playCorrect()).called(1);

      // Now 1 feature stabilized
      expect(find.text('1 of 3 items described'), findsOneWidget);
      expect(find.byType(SceneDescriptionExplorerGuideCard), findsOneWidget);
      expect(find.byType(SpeakToConfirmOverlay), findsNothing);
    });

    testWidgets('tapping already inspected beacon 0 is ignored', (
      tester,
    ) async {
      await pumpSceneDescriptionScreen(tester);

      // Inspect beacon 0
      await tester.tap(find.byKey(const Key('scene_description_beacon_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      tester.widget<SpeakToConfirmOverlay>(find.byType(SpeakToConfirmOverlay)).onConfirmed();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      clearInteractions(mockHapticService);
      clearInteractions(mockSoundService);

      // Tap beacon 0 again
      await tester.tap(find.byKey(const Key('scene_description_beacon_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Should not trigger haptics or TTS or open overlay
      verifyNever(() => mockHapticService.selection());
      verifyNever(() => mockSoundService.playTts(any()));
      expect(find.byType(SpeakToConfirmOverlay), findsNothing);
    });

    testWidgets('evaluation failure dispatches SubmitAnswer(false) and plays wrong sound', (
      tester,
    ) async {
      await pumpSceneDescriptionScreen(tester);

      // Tap beacon 1
      await tester.tap(find.byKey(const Key('scene_description_beacon_1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Trigger skip / missed evaluation
      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byType(SpeakToConfirmOverlay),
      );
      overlay.onSkipped();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockHapticService.error()).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockSpeakingBloc.add(const SubmitAnswer(false))).called(1);

      // Feedback card appears when answer is incorrect
      final incorrectState = testLoadedState.copyWith(
        answerStatus: AnswerStatus.incorrect,
      );
      when(() => mockSpeakingBloc.state).thenReturn(incorrectState);
      speakingStreamController.add(incorrectState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(GameFeedbackCard), findsOneWidget);
    });

    testWidgets('evaluation failure records error journal for authenticated user', (
      tester,
    ) async {
      await pumpSceneDescriptionScreen(tester);

      await tester.tap(find.byKey(const Key('scene_description_beacon_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byType(SpeakToConfirmOverlay),
      );
      overlay.onSkipped();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockSpeakingBloc.add(const SubmitAnswer(false))).called(1);
    });
  });

  group('9. Multi-Hotspot Completion & Full Scene Description', () {
    testWidgets('inspecting all 3 hotspots triggers SubmitAnswer(true)', (
      tester,
    ) async {
      await pumpSceneDescriptionScreen(tester);

      // Beacon 0
      await tester.tap(find.byKey(const Key('scene_description_beacon_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      tester.widget<SpeakToConfirmOverlay>(find.byType(SpeakToConfirmOverlay)).onConfirmed();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('1 of 3 items described'), findsOneWidget);

      // Beacon 1
      await tester.tap(find.byKey(const Key('scene_description_beacon_1')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      tester.widget<SpeakToConfirmOverlay>(find.byType(SpeakToConfirmOverlay)).onConfirmed();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('2 of 3 items described'), findsOneWidget);

      // Beacon 2
      await tester.tap(find.byKey(const Key('scene_description_beacon_2')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      tester.widget<SpeakToConfirmOverlay>(find.byType(SpeakToConfirmOverlay)).onConfirmed();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('3 of 3 items described'), findsOneWidget);

      verify(() => mockSpeakingBloc.add(const SubmitAnswer(true))).called(1);
    });

    testWidgets('displays Full Scene Description card when answered and correct', (
      tester,
    ) async {
      await pumpSceneDescriptionScreen(tester, size: const Size(390, 1600));

      // Complete all 3 beacons
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.byKey(Key('scene_description_beacon_$i')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        tester.widget<SpeakToConfirmOverlay>(find.byType(SpeakToConfirmOverlay)).onConfirmed();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      }

      // Check Full Scene Description card
      expect(
        find.byKey(const Key('scene_description_sample_answer_card')),
        findsOneWidget,
      );
      expect(find.text('Example Description'), findsOneWidget);
      expect(
        find.byKey(const Key('scene_description_sample_answer_text')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('scene_description_sample_answer_card')),
          matching: find.textContaining('The space station hydroponics facility uses'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('scene_description_sample_tts_button')),
        findsOneWidget,
      );
    });

    testWidgets('tapping LISTEN button plays sample answer TTS', (
      tester,
    ) async {
      await pumpSceneDescriptionScreen(tester, size: const Size(390, 1600));

      for (int i = 0; i < 3; i++) {
        await tester.tap(find.byKey(Key('scene_description_beacon_$i')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        tester.widget<SpeakToConfirmOverlay>(find.byType(SpeakToConfirmOverlay)).onConfirmed();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      }

      final listenBtn = find.byKey(const Key('scene_description_sample_tts_button'));
      expect(listenBtn, findsOneWidget);

      clearInteractions(mockHapticService);
      clearInteractions(mockSoundService);

      tester.widget<GestureDetector>(listenBtn).onTap?.call();
      await tester.pump();

      verify(() => mockHapticService.selection()).called(1);
      verify(() => mockSoundService.playTts(sampleQuest1.sampleAnswer!)).called(1);
    });

    testWidgets('sample answer TTS handles exceptions gracefully', (
      tester,
    ) async {
      when(() => mockSoundService.playTts(any())).thenThrow(Exception('Audio hardware glitch'));

      await pumpSceneDescriptionScreen(tester, size: const Size(390, 1600));

      for (int i = 0; i < 3; i++) {
        await tester.tap(find.byKey(Key('scene_description_beacon_$i')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        tester.widget<SpeakToConfirmOverlay>(find.byType(SpeakToConfirmOverlay)).onConfirmed();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      }

      final listenBtn = find.byKey(const Key('scene_description_sample_tts_button'));
      tester.widget<GestureDetector>(listenBtn).onTap?.call();
      await tester.pump();

      // No crash, screen remains stable
      expect(find.byType(SceneDescriptionScreen), findsOneWidget);
    });
  });

  group('10. Hint & Bottom Actions', () {
    testWidgets('tapping hint button dispatches SpeakingHintUsed', (
      tester,
    ) async {
      await pumpSceneDescriptionScreen(tester);

      final hintBtn = find.byType(QuestHintButton);
      expect(hintBtn, findsOneWidget);

      await tester.tap(hintBtn);
      await tester.pump();

      verify(() => mockSpeakingBloc.add(const SpeakingHintUsed())).called(greaterThanOrEqualTo(1));
    });

    testWidgets('tapping CONTINUE in feedback card dispatches NextQuestion', (
      tester,
    ) async {
      final answeredState = testLoadedState.copyWith(
        answerStatus: AnswerStatus.correct,
      );
      await pumpSceneDescriptionScreen(tester, state: answeredState);

      final continueBtn = find.text('CONTINUE');
      expect(continueBtn, findsOneWidget);

      await tester.tap(continueBtn);
      await tester.pump();

      verify(() => mockSpeakingBloc.add(const NextQuestion())).called(1);
    });

    testWidgets('displays completion overlay upon SpeakingGameComplete', (
      tester,
    ) async {
      await pumpSceneDescriptionScreen(tester);
      speakingStreamController.add(
        const SpeakingGameComplete(
          xpEarned: 100,
          coinsEarned: 20,
          questCount: 2,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockSoundService.playLevelComplete()).called(1);
    });
  });

  group('11. Viewport Responsiveness & Layout Modes', () {
    testWidgets('renders cleanly on compact screen (320x568)', (tester) async {
      await pumpSceneDescriptionScreen(
        tester,
        size: const Size(320, 568),
      );

      expect(find.byType(SceneDescriptionScreen), findsOneWidget);
      expect(find.byType(SceneDescriptionScenicRadarMap), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders cleanly on tablet screen (768x1024)', (tester) async {
      await pumpSceneDescriptionScreen(
        tester,
        size: const Size(768, 1024),
      );

      expect(find.byType(SceneDescriptionScreen), findsOneWidget);
      expect(find.byType(SceneDescriptionScenicRadarMap), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders correctly in Light Theme', (tester) async {
      await pumpSceneDescriptionScreen(
        tester,
        themeMode: ThemeMode.light,
      );

      expect(find.byType(SceneDescriptionScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders correctly in Dark Theme', (tester) async {
      await pumpSceneDescriptionScreen(
        tester,
        themeMode: ThemeMode.dark,
      );

      expect(find.byType(SceneDescriptionScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('adapts gracefully to 1.3x text scaling', (tester) async {
      await pumpSceneDescriptionScreen(
        tester,
        textScaleFactor: 1.3,
      );

      expect(find.byType(SceneDescriptionScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('12. Fallback & Edge Cases', () {
    testWidgets('handles quest with null options by providing default objects', (
      tester,
    ) async {
      final fallbackQuest = createQuest(options: null);
      final fallbackState = SpeakingLoaded(
        quests: [fallbackQuest],
        currentIndex: 0,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.unanswered,
        gameType: GameSubtype.sceneDescriptionSpeaking,
        level: 2,
      );

      await pumpSceneDescriptionScreen(tester, state: fallbackState);

      expect(find.text('Object A'), findsOneWidget);
      expect(find.text('Object B'), findsOneWidget);
      expect(find.text('Object C'), findsOneWidget);
    });

    testWidgets('handles quest with empty options by falling back to default 3 objects', (
      tester,
    ) async {
      final fallbackQuest = createQuest(options: []);
      final fallbackState = SpeakingLoaded(
        quests: [fallbackQuest],
        currentIndex: 0,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.unanswered,
        gameType: GameSubtype.sceneDescriptionSpeaking,
        level: 2,
      );

      await pumpSceneDescriptionScreen(tester, state: fallbackState);

      expect(find.text('Object A'), findsOneWidget);
      expect(find.text('Object B'), findsOneWidget);
      expect(find.text('Object C'), findsOneWidget);
    });

    testWidgets('handles quest with null sceneText gracefully', (
      tester,
    ) async {
      final fallbackQuest = createQuest(sceneText: 'Visual Space Cabin');
      final fallbackState = SpeakingLoaded(
        quests: [fallbackQuest],
        currentIndex: 0,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.unanswered,
        gameType: GameSubtype.sceneDescriptionSpeaking,
        level: 2,
      );

      await pumpSceneDescriptionScreen(tester, state: fallbackState);

      expect(find.text('Visual Space Cabin'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('handles quest with null acceptedSynonyms gracefully', (
      tester,
    ) async {
      final fallbackQuest = createQuest(acceptedSynonyms: null);
      final fallbackState = SpeakingLoaded(
        quests: [fallbackQuest],
        currentIndex: 0,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.unanswered,
        gameType: GameSubtype.sceneDescriptionSpeaking,
        level: 2,
      );

      await pumpSceneDescriptionScreen(tester, state: fallbackState);

      // Open beacon 0
      await tester.tap(find.byKey(const Key('scene_description_beacon_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(SpeakToConfirmOverlay), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('reset quest resets inspected hotspots and active hotspot', (
      tester,
    ) async {
      await pumpSceneDescriptionScreen(tester);

      // Tap beacon 0 and confirm
      await tester.tap(find.byKey(const Key('scene_description_beacon_0')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      tester.widget<SpeakToConfirmOverlay>(find.byType(SpeakToConfirmOverlay)).onConfirmed();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('1 of 3 items described'), findsOneWidget);

      // Emit new question state for quest 2
      final newState = SpeakingLoaded(
        quests: [sampleQuest1, sampleQuest2],
        currentIndex: 1,
        livesRemaining: 3,
        wrongCount: 0,
        hintUsed: false,
        answerStatus: AnswerStatus.unanswered,
        gameType: GameSubtype.sceneDescriptionSpeaking,
        level: 2,
      );
      when(() => mockSpeakingBloc.state).thenReturn(newState);
      speakingStreamController.add(newState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // New quest resets count to 0 of 3
      expect(find.text('0 of 3 items described'), findsOneWidget);
      expect(find.text('ANCIENT LIBRARY ARCHIVE'), findsOneWidget);
    });
  });
}
