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
import 'package:vowl/features/vocabulary/antonym_search/presentation/pages/antonym_search_screen.dart';
import 'package:vowl/features/vocabulary/antonym_search/presentation/widgets/antonym_gradient_scale.dart';
import 'package:vowl/features/vocabulary/antonym_search/presentation/widgets/antonym_nebula_core.dart';
import 'package:vowl/features/vocabulary/antonym_search/presentation/widgets/antonym_option_shard.dart';
import 'package:vowl/features/vocabulary/antonym_search/presentation/widgets/antonym_instruction_header.dart';
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
    String id = 'quest_antonym_1',
    String word = 'transparent',
    String correctAnswer = 'opaque',
    List<String> options = const ['opaque', 'lucid', 'vague', 'clear'],
    String instruction = 'Match the word to its true opposite.',
    List<String>? gradientScale = const [
      'transparent',
      'translucent',
      'cloudy',
      'opaque',
    ],
    String? explanation =
        'Transparent describes light passing through clearly; opaque blocks light entirely.',
    String? hint = 'Blocks light and cannot be seen through.',
    int difficulty = 1,
  }) {
    return VocabularyQuest(
      id: id,
      type: QuestType.vocabulary,
      subtype: GameSubtype.antonymSearch,
      word: word,
      correctAnswer: correctAnswer,
      options: options,
      instruction: instruction,
      gradientScale: gradientScale,
      explanation: explanation,
      hint: hint,
      difficulty: difficulty,
    );
  }

  final sampleQuest1 = createQuest();

  final sampleQuest2 = createQuest(
    id: 'quest_antonym_2',
    word: 'scarce',
    correctAnswer: 'abundant',
    options: ['abundant', 'rare', 'sparse', 'limited'],
    instruction: 'Select the precise antonym.',
    gradientScale: ['depleted', 'scarce', 'adequate', 'abundant'],
    explanation:
        'Scarce means present in insufficient quantities, while abundant denotes plentiful supply.',
    hint: 'Existing or available in large quantities.',
  );

  final sampleMinimalQuest = const VocabularyQuest(
    id: 'quest_antonym_minimal',
    type: QuestType.vocabulary,
    subtype: GameSubtype.antonymSearch,
    word: 'hostile',
    correctAnswer: 'friendly',
    options: ['friendly', 'belligerent'],
    instruction: 'Match opposite.',
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
        gameType: GameSubtype.antonymSearch,
        level: 2,
      ),
    );
    registerFallbackValue(sampleQuest1);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'has_seen_briefing_antonymSearch': true,
    });

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
          id: 'test_user_vocab',
          email: 'vocab@vowl.app',
          displayName: 'Vocab Explorer',
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
    ).thenAnswer((_) async => '/tmp/antonym_test.m4a');
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
    VocabularyState? state,
    int level = 2,
    GameSubtype gameType = GameSubtype.antonymSearch,
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
              child: AntonymSearchScreen(level: level, gameType: gameType),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('1. Initial Screen & Layout Setup', () {
    testWidgets('1.1 renders MATCH TO OPPOSITE header in AntonymNebulaCore', (
      tester,
    ) async {
      await pumpScreen(tester);
      expect(find.text('MATCH TO OPPOSITE'), findsOneWidget);
    });

    testWidgets('1.2 renders target word in AntonymNebulaCore', (tester) async {
      await pumpScreen(tester);
      expect(find.text('TRANSPARENT'), findsOneWidget);
      expect(find.byType(AntonymNebulaCore), findsOneWidget);
    });

    testWidgets('1.3 renders all 4 option shards from quest options', (
      tester,
    ) async {
      await pumpScreen(tester);
      expect(find.byType(AntonymOptionShard), findsNWidgets(4));
      expect(find.text('OPAQUE'), findsOneWidget);
      expect(find.text('LUCID'), findsOneWidget);
      expect(find.text('VAGUE'), findsOneWidget);
      expect(find.text('CLEAR'), findsOneWidget);
    });

    testWidgets('1.4 renders minimal quest with 2 option shards cleanly', (
      tester,
    ) async {
      final state = testLoadedState.copyWith(quests: [sampleMinimalQuest]);
      await pumpScreen(tester, state: state);
      expect(find.byType(AntonymOptionShard), findsNWidgets(2));
      expect(find.text('HOSTILE'), findsOneWidget);
      expect(find.text('FRIENDLY'), findsOneWidget);
      expect(find.text('BELLIGERENT'), findsOneWidget);
    });

    testWidgets('1.5 dispatches FetchVocabularyQuests on mount', (tester) async {
      await pumpScreen(tester, level: 3);
      verify(
        () => mockVocabularyBloc.add(
          const FetchVocabularyQuests(
            gameType: GameSubtype.antonymSearch,
            level: 3,
          ),
        ),
      ).called(1);
    });

    testWidgets(
      '1.6 displays briefing dialog on level 1 and dismisses on BEGIN SEARCH tap',
      (tester) async {
        await pumpScreen(tester, level: 1);
        final startBtn = find.text('BEGIN SEARCH');
        expect(startBtn, findsOneWidget);
        await tester.ensureVisible(startBtn);
        await tester.pumpAndSettle();
        await tester.tap(startBtn);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('BEGIN SEARCH'), findsNothing);
      },
    );
  });

  group('2. Phase 1: Tap-to-Select & Core Fusion Mechanics', () {
    testWidgets('2.1 tapping an option shard triggers light haptic', (
      tester,
    ) async {
      await pumpScreen(tester);
      final shard = find.text('OPAQUE');
      await tester.tap(shard);
      await tester.pump(const Duration(milliseconds: 50));
      verify(() => mockHapticService.light()).called(1);
    });

    testWidgets('2.2 tapping core without selecting any shard is a safe no-op', (
      tester,
    ) async {
      await pumpScreen(tester);
      final core = find.byType(AntonymNebulaCore);
      await tester.tap(core);
      await tester.pump(const Duration(milliseconds: 350));
      verifyNever(() => mockVocabularyBloc.add(any(that: isA<SubmitAnswer>())));
    });

    testWidgets(
      '2.3 selecting correct shard and tapping core fuses shard and advances to Phase 2',
      (tester) async {
        await pumpScreen(tester);

        // Tap correct shard (OPAQUE)
        await tester.tap(find.text('OPAQUE'));
        await tester.pump(const Duration(milliseconds: 50));

        // Tap central core to fuse
        await tester.tap(find.byType(AntonymNebulaCore));
        // Wait for tap animation (300ms) and scroll timer (300ms)
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pump(const Duration(milliseconds: 300));

        // Triggers selection haptic for Phase 1 success
        verify(() => mockHapticService.selection()).called(1);

        // Phase 2 widgets are mounted
        expect(find.byType(SpeakToConfirmOverlay), findsOneWidget);
        expect(find.byType(AntonymGradientScale), findsOneWidget);
      },
    );

    testWidgets(
      '2.4 selecting incorrect shard and tapping core triggers wrong answer',
      (tester) async {
        await pumpScreen(tester);

        // Tap wrong shard (LUCID)
        await tester.tap(find.text('LUCID'));
        await tester.pump(const Duration(milliseconds: 50));

        // Tap central core
        await tester.tap(find.byType(AntonymNebulaCore));
        await tester.pump(const Duration(milliseconds: 350));

        // Verifies wrong answer dispatched
        verify(() => mockVocabularyBloc.add(const SubmitAnswer(false))).called(1);
        verify(() => mockSoundService.playWrong()).called(1);
        verify(() => mockHapticService.error()).called(1);
      },
    );

    testWidgets(
      '2.5 tapping already selected correct shard fuses shard directly and advances to Phase 2',
      (tester) async {
        await pumpScreen(tester);

        // Tap once to select
        await tester.tap(find.text('OPAQUE'));
        await tester.pump(const Duration(milliseconds: 50));

        // Tap second time to confirm directly without needing to tap core
        await tester.tap(find.text('OPAQUE'));
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pump(const Duration(milliseconds: 300));

        // Verifies Phase 2 reached
        expect(find.byType(SpeakToConfirmOverlay), findsOneWidget);
        expect(find.byType(AntonymGradientScale), findsOneWidget);
      },
    );

    testWidgets(
      '2.6 renders AntonymInstructionHeader with centered instruction text',
      (tester) async {
        await pumpScreen(tester);

        expect(find.byType(AntonymInstructionHeader), findsOneWidget);
        final header = tester.widget<AntonymInstructionHeader>(
          find.byType(AntonymInstructionHeader),
        );
        expect(header.instruction, isNotEmpty);

        final textWidgets = tester.widgetList<Text>(
          find.descendant(
            of: find.byType(AntonymInstructionHeader),
            matching: find.byType(Text),
          ),
        );
        for (final textWidget in textWidgets) {
          expect(textWidget.textAlign, equals(TextAlign.center));
        }

        // Verify hint is NOT rendered in instruction header (hints belong to hint button)
        expect(find.text(sampleQuest1.hint!), findsNothing);
      },
    );
  });

  group('3. Phase 1: Drag-and-Drop Fusion Mechanics', () {
    testWidgets('3.1 dragging shard toward center fuses when dropped in zone', (
      tester,
    ) async {
      await pumpScreen(tester);

      final shard = find.text('OPAQUE');
      // Drag shard towards the center of the screen
      final gesture = await tester.startGesture(tester.getCenter(shard));
      await gesture.moveBy(const Offset(20, 20));
      await tester.pump(const Duration(milliseconds: 20));
      await gesture.moveBy(const Offset(70, 160));
      await tester.pump(const Duration(milliseconds: 20));

      await gesture.up();
      // Pump immediately so the second sliver mounts and maxScrollExtent is calculated
      await tester.pump();
      // Wait for scroll timer (300ms) and full scroll animation (600ms)
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockHapticService.selection()).called(greaterThanOrEqualTo(1));
      expect(find.byType(AntonymGradientScale), findsOneWidget);
      expect(find.byType(SpeakToConfirmOverlay), findsOneWidget);
    });

    testWidgets('3.2 dragging shard and releasing far from center snaps back', (
      tester,
    ) async {
      await pumpScreen(tester);

      final shard = find.text('OPAQUE');
      final gesture = await tester.startGesture(tester.getCenter(shard));
      await gesture.moveBy(const Offset(0, 25));
      await tester.pump(const Duration(milliseconds: 20));
      await gesture.moveBy(const Offset(0, -15));
      await tester.pump(const Duration(milliseconds: 20));

      await gesture.up();
      await tester.pump(const Duration(milliseconds: 100));

      // Shard snapped back, light haptic triggered on snap
      verify(() => mockHapticService.light()).called(greaterThanOrEqualTo(1));
      // Not advanced to Phase 2
      expect(find.byType(SpeakToConfirmOverlay), findsNothing);
    });

    testWidgets(
      '3.3 dragging incorrect shard into center zone submits wrong answer',
      (tester) async {
        await pumpScreen(tester);

        final shard = find.text('LUCID');
        final gesture = await tester.startGesture(tester.getCenter(shard));
        await gesture.moveBy(const Offset(-20, 20));
        await tester.pump(const Duration(milliseconds: 20));
        await gesture.moveBy(const Offset(-70, 160));
        await tester.pump(const Duration(milliseconds: 20));

        await gesture.up();
        await tester.pump(const Duration(milliseconds: 100));

        verify(() => mockVocabularyBloc.add(const SubmitAnswer(false))).called(1);
        verify(() => mockSoundService.playWrong()).called(1);
        verify(() => mockHapticService.error()).called(1);
      },
    );
  });

  group('4. Phase 2: Explanation, Gradient Scale & Verbal Overlay', () {
    Future<void> advanceToPhase2(WidgetTester tester) async {
      await pumpScreen(tester);
      await tester.tap(find.text('OPAQUE'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byType(AntonymNebulaCore));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('4.1 renders AntonymGradientScale with gradient items', (
      tester,
    ) async {
      await advanceToPhase2(tester);
      expect(find.byType(AntonymGradientScale), findsOneWidget);
      expect(find.text('TRANSPARENT'), findsWidgets);
      expect(find.text('OPAQUE'), findsWidgets);
    });

    testWidgets('4.2 renders pedagogical explanation card with lightbulb icon', (
      tester,
    ) async {
      await advanceToPhase2(tester);
      expect(find.byIcon(Icons.lightbulb_outline_rounded), findsOneWidget);
      expect(
        find.text(
          'Transparent describes light passing through clearly; opaque blocks light entirely.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('4.3 renders SpeakToConfirmOverlay with formatted displayText', (
      tester,
    ) async {
      await advanceToPhase2(tester);
      expect(find.byType(SpeakToConfirmOverlay), findsOneWidget);
      expect(find.text('TRANSPARENT   ↔   OPAQUE'), findsOneWidget);
    });

    testWidgets(
      '4.4 SpeakToConfirmOverlay is padded with horizontal margins preventing edge touching',
      (tester) async {
        await advanceToPhase2(tester);
        final overlayFinder = find.byType(SpeakToConfirmOverlay);
        expect(overlayFinder, findsOneWidget);

        final paddingParentFinder = find.ancestor(
          of: overlayFinder,
          matching: find.byType(Padding),
        );
        expect(paddingParentFinder, findsWidgets);

        final overlayRect = tester.getRect(overlayFinder);
        // Screen width is 390; overlay must not touch the edges (at least 16.0 margin)
        expect(overlayRect.left, greaterThanOrEqualTo(16.0));
        expect(overlayRect.right, lessThanOrEqualTo(390.0 - 16.0));
      },
    );
  });

  group('5. Phase 2: Verbal Evaluation Submission (Success & Failure)', () {
    Future<void> advanceToPhase2(WidgetTester tester) async {
      await pumpScreen(tester);
      await tester.tap(find.text('OPAQUE'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byType(AntonymNebulaCore));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets(
      '5.1 confirming in SpeakToConfirmOverlay dispatches SubmitAnswer(true) with audio/haptic',
      (tester) async {
        await advanceToPhase2(tester);

        final overlay = tester.widget<SpeakToConfirmOverlay>(
          find.byType(SpeakToConfirmOverlay),
        );
        overlay.onConfirmed();
        await tester.pump(const Duration(milliseconds: 100));

        verify(() => mockVocabularyBloc.add(const SubmitAnswer(true))).called(1);
        verify(() => mockSoundService.playCorrect()).called(1);
        verify(() => mockHapticService.success()).called(1);
      },
    );

    testWidgets(
      '5.2 skipping in SpeakToConfirmOverlay dispatches SubmitAnswer(false) with error audio/haptic',
      (tester) async {
        await advanceToPhase2(tester);

        final overlay = tester.widget<SpeakToConfirmOverlay>(
          find.byType(SpeakToConfirmOverlay),
        );
        overlay.onSkipped();
        await tester.pump(const Duration(milliseconds: 100));

        verify(() => mockVocabularyBloc.add(const SubmitAnswer(false))).called(1);
        verify(() => mockSoundService.playWrong()).called(1);
        verify(() => mockHapticService.error()).called(1);
      },
    );
  });

  group('6. Interaction Lockout & Duplicate Prevention', () {
    testWidgets('6.1 once answered, tapping shards is locked out', (
      tester,
    ) async {
      await pumpScreen(tester);
      // Advance to Phase 2
      await tester.tap(find.text('OPAQUE'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byType(AntonymNebulaCore));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 300));

      // Submit correct answer
      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byType(SpeakToConfirmOverlay),
      );
      overlay.onConfirmed();
      await tester.pump(const Duration(milliseconds: 100));

      clearInteractions(mockVocabularyBloc);

      // Verify Phase 1 is locked out with IgnorePointer
      final ignorePointer = tester.widget<IgnorePointer>(
        find.descendant(
          of: find.byType(AntonymSearchScreen),
          matching: find.byType(IgnorePointer),
        ).first,
      );
      expect(ignorePointer.ignoring, isTrue);
    });

    testWidgets('6.2 once answered, subsequent confirm taps are locked out', (
      tester,
    ) async {
      await pumpScreen(tester);
      // Advance to Phase 2
      await tester.tap(find.text('OPAQUE'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byType(AntonymNebulaCore));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 300));

      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byType(SpeakToConfirmOverlay),
      );
      // First confirm
      overlay.onConfirmed();
      await tester.pump(const Duration(milliseconds: 50));

      // Second confirm
      overlay.onConfirmed();
      await tester.pump(const Duration(milliseconds: 50));

      verify(() => mockVocabularyBloc.add(const SubmitAnswer(true))).called(1);
    });
  });

  group('7. Progression, State Transitions & Cleanup', () {
    testWidgets('7.1 answered state mounts GameFeedbackCard with CONTINUE button', (
      tester,
    ) async {
      await pumpScreen(tester);
      await tester.tap(find.text('OPAQUE'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byType(AntonymNebulaCore));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 300));

      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byType(SpeakToConfirmOverlay),
      );
      overlay.onConfirmed();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(GameFeedbackCard), findsOneWidget);
      expect(find.text('CONTINUE'), findsOneWidget);
    });

    testWidgets('7.2 tapping CONTINUE dispatches NextQuestion', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.text('OPAQUE'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byType(AntonymNebulaCore));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 300));

      final overlay = tester.widget<SpeakToConfirmOverlay>(
        find.byType(SpeakToConfirmOverlay),
      );
      overlay.onConfirmed();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('CONTINUE'));
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => mockVocabularyBloc.add(const NextQuestion())).called(1);
    });

    testWidgets('7.3 tapping header hint button dispatches VocabularyHintUsed', (
      tester,
    ) async {
      await pumpScreen(tester);
      final hintButton = find.byType(QuestHintButton);
      expect(hintButton, findsOneWidget);
      await tester.tap(hintButton);
      await tester.pump(const Duration(milliseconds: 100));
      verify(() => mockVocabularyBloc.add(const VocabularyHintUsed())).called(greaterThanOrEqualTo(1));
    });

    testWidgets(
      '7.4 transitioning to second quest resets state and displays second word',
      (tester) async {
        await pumpScreen(tester);
        expect(find.text('TRANSPARENT'), findsOneWidget);

        final updatedState = testLoadedState.copyWith(
          currentIndex: 1,
          answerStatus: AnswerStatus.unanswered,
        );
        vocabularyStreamController.add(updatedState);
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('SCARCE'), findsOneWidget);
        expect(find.text('ABUNDANT'), findsOneWidget);
        expect(find.byType(SpeakToConfirmOverlay), findsNothing);
      },
    );

    testWidgets('7.5 VocabularyGameComplete state triggers LEVEL COMPLETE dialog', (
      tester,
    ) async {
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

      // Dismiss dialog to ensure all internal periodic timers are canceled
      Navigator.of(tester.element(find.text('LEVEL COMPLETE!'))).pop();
      await tester.pump(const Duration(milliseconds: 500));
    });

    testWidgets('7.6 renders GameShimmerLoading when quests are loading/null', (
      tester,
    ) async {
      const loadingState = VocabularyLoading();
      await pumpScreen(tester, state: loadingState);
      expect(find.byType(GameShimmerLoading), findsOneWidget);
    });

    testWidgets('7.7 screen disposes cleanly without timer leaks', (
      tester,
    ) async {
      await pumpScreen(tester);
      expect(find.byType(AntonymSearchScreen), findsOneWidget);
    });
  });

  group('8. Viewport Responsiveness, Theming & Accessibility', () {
    testWidgets('8.1 renders cleanly on compact mobile viewport (320x568)', (
      tester,
    ) async {
      await pumpScreen(tester, size: const Size(320, 568));
      expect(tester.takeException(), isNull);
      expect(find.byType(AntonymNebulaCore), findsOneWidget);
      expect(find.byType(AntonymOptionShard), findsNWidgets(4));
    });

    testWidgets('8.2 renders cleanly on tablet viewport (768x1024)', (
      tester,
    ) async {
      await pumpScreen(tester, size: const Size(768, 1024));
      expect(tester.takeException(), isNull);
      expect(find.byType(AntonymNebulaCore), findsOneWidget);
    });

    testWidgets('8.3 renders cleanly in Light Theme mode', (tester) async {
      await pumpScreen(tester, themeMode: ThemeMode.light);
      expect(tester.takeException(), isNull);
      expect(find.byType(AntonymNebulaCore), findsOneWidget);
    });

    testWidgets('8.4 renders cleanly in Dark Theme mode', (tester) async {
      await pumpScreen(tester, themeMode: ThemeMode.dark);
      expect(tester.takeException(), isNull);
      expect(find.byType(AntonymNebulaCore), findsOneWidget);
    });

    testWidgets('8.5 supports text scaling up to 1.5x cleanly', (tester) async {
      await pumpScreen(tester, textScaleFactor: 1.5);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      '8.6 suppresses repeating animations when disableAnimations is true',
      (tester) async {
        await pumpScreen(tester, reduceMotion: true);
        await tester.pumpAndSettle();
        expect(find.byType(AntonymNebulaCore), findsOneWidget);
      },
    );
  });
}
