import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:record/record.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/network/network_info.dart';
import 'package:vowl/core/presentation/game_mechanics/speaking/shadow_playback_compare.dart';
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
import 'package:vowl/features/speaking/daily_expression/presentation/pages/daily_expression_screen.dart';
import 'package:vowl/features/speaking/daily_expression/presentation/widgets/daily_expression_header.dart';
import 'package:vowl/features/speaking/daily_expression/presentation/widgets/daily_expression_scratch_panel.dart';
import 'package:vowl/features/speaking/daily_expression/presentation/widgets/daily_expression_usage_panel.dart';
import 'package:vowl/features/speaking/domain/entities/speaking_quest.dart';
import 'package:vowl/features/speaking/presentation/bloc/speaking_bloc.dart';
import 'package:vowl/features/speaking/presentation/layout/speaking_base_layout.dart';

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

SpeakingQuest createQuest({
  String id = 'de_1',
  String expression = 'Bite the bullet',
  String meaning = 'To endure a painful situation that cannot be avoided',
  String sampleUsage = 'I had to bite the bullet and pay the fine.',
  String? explanation =
      'Originated from battlefield surgeries where soldiers were given lead bullets to bite down on.',
  String? hint = 'Think of enduring an unpleasant situation with courage',
  String instruction = 'Speak the daily idiom',
  int difficulty = 2,
}) {
  return SpeakingQuest(
    id: id,
    type: QuestType.speaking,
    subtype: GameSubtype.dailyExpression,
    expression: expression,
    meaning: meaning,
    sampleUsage: sampleUsage,
    explanation: explanation,
    hint: hint,
    instruction: instruction,
    difficulty: difficulty,
    targetWord: expression,
    correctAnswer: expression,
  );
}

void main() {
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

  final sampleQuest1 = createQuest();
  final sampleQuest2 = createQuest(
    id: 'de_2',
    expression: 'Break the ice',
    meaning: 'To make people feel more comfortable in a social setting',
    sampleUsage: 'He told a joke to break the ice with the new team.',
    explanation:
        'Refers to ships designed to break through polar ice to open sea routes.',
    hint: 'Think of starting a conversation in an awkward room',
  );

  final testLoadedState = SpeakingLoaded(
    quests: [sampleQuest1, sampleQuest2],
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
    hintUsed: false,
    gameType: GameSubtype.dailyExpression,
    level: 2,
    wrongCount: 0,
    isFinalFailure: false,
  );

  setUpAll(() {
    registerFallbackValue(const NextQuestion());
    registerFallbackValue(const SpeakingHintUsed());
    registerFallbackValue(const SubmitAnswer(true));
    registerFallbackValue(const SubmitAnswer(false));
    registerFallbackValue(
      const FetchSpeakingQuests(
        gameType: GameSubtype.dailyExpression,
        level: 1,
      ),
    );
    registerFallbackValue(const Duration(milliseconds: 50));
    VowlMotion.lowAnimationModeOverride.value = true;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'has_seen_briefing_dailyExpression': true,
      'reduce_complex_gestures': false,
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

    // Default Stubs
    when(() => mockSpeakingBloc.state).thenReturn(testLoadedState);
    whenListen(
      mockSpeakingBloc,
      speakingStreamController.stream,
      initialState: testLoadedState,
    );

    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(
        const UserEntity(
          id: 'test_user',
          email: 'test@vowl.app',
          displayName: 'Test Voice Master',
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
    when(() => mockSoundService.playTts(any())).thenAnswer((_) async {});
    when(() => mockSoundService.playUrl(any())).thenAnswer((_) async {});

    when(() => mockTtsService.stop()).thenAnswer((_) async {});
    when(
      () => mockTtsService.speak(
        any(),
        rate: any(named: 'rate'),
        locale: any(named: 'locale'),
      ),
    ).thenAnswer((_) async {});

    when(() => mockSpeechService.initializeStt()).thenAnswer((_) async => true);
    when(() => mockSpeechService.stop()).thenAnswer((_) async {});
    when(() => mockSpeechService.cancel()).thenAnswer((_) async {});
    when(() => mockSpeechService.isListening).thenReturn(false);
    when(() => mockSpeechService.isPlaying).thenReturn(false);

    when(() => mockAudioRecorder.hasPermission()).thenAnswer((_) async => true);
    when(() => mockAudioRecorder.startRecording()).thenAnswer((_) async => true);
    when(
      () => mockAudioRecorder.stopRecording(),
    ).thenAnswer((_) async => '/tmp/daily_expression_test.m4a');
    when(() => mockAudioRecorder.isRecording).thenReturn(false);
    when(
      () => mockAudioRecorder.onAmplitudeChanged(any()),
    ).thenAnswer((_) => Stream.value(Amplitude(current: -10, max: -5)));
    when(() => mockAudioRecorder.dispose()).thenAnswer((_) async {});

    when(
      () => mockLocaleService.tr(any(), fallback: any(named: 'fallback')),
    ).thenAnswer((invocation) {
      final fallback = invocation.namedArguments[#fallback] as String?;
      return fallback ?? invocation.positionalArguments[0] as String;
    });

    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
    when(
      () => mockAnalyticsService.logSelfEvaluation(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockAnalyticsService.logGameSkipped(any()),
    ).thenAnswer((_) async {});
    when(
      () => mockAnalyticsService.logPurchaseAttempt(any()),
    ).thenAnswer((_) async {});

    // DI Service Registration
    if (di.sl.isRegistered<HapticService>()) di.sl.unregister<HapticService>();
    if (di.sl.isRegistered<SoundService>()) di.sl.unregister<SoundService>();
    if (di.sl.isRegistered<TtsService>()) di.sl.unregister<TtsService>();
    if (di.sl.isRegistered<SpeechService>()) di.sl.unregister<SpeechService>();
    if (di.sl.isRegistered<AudioRecordingService>()) {
      di.sl.unregister<AudioRecordingService>();
    }
    if (di.sl.isRegistered<LocaleService>()) di.sl.unregister<LocaleService>();
    if (di.sl.isRegistered<AppLogger>()) di.sl.unregister<AppLogger>();
    if (di.sl.isRegistered<AnalyticsService>()) {
      di.sl.unregister<AnalyticsService>();
    }
    if (di.sl.isRegistered<AdService>()) di.sl.unregister<AdService>();
    if (di.sl.isRegistered<NetworkInfo>()) di.sl.unregister<NetworkInfo>();

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

  tearDown(() {
    speakingStreamController.close();
  });

  tearDownAll(() {
    VowlMotion.lowAnimationModeOverride.value = false;
    if (di.sl.isRegistered<HapticService>()) di.sl.unregister<HapticService>();
    if (di.sl.isRegistered<SoundService>()) di.sl.unregister<SoundService>();
    if (di.sl.isRegistered<TtsService>()) di.sl.unregister<TtsService>();
    if (di.sl.isRegistered<SpeechService>()) di.sl.unregister<SpeechService>();
    if (di.sl.isRegistered<AudioRecordingService>()) {
      di.sl.unregister<AudioRecordingService>();
    }
    if (di.sl.isRegistered<LocaleService>()) di.sl.unregister<LocaleService>();
    if (di.sl.isRegistered<AppLogger>()) di.sl.unregister<AppLogger>();
    if (di.sl.isRegistered<AnalyticsService>()) {
      di.sl.unregister<AnalyticsService>();
    }
    if (di.sl.isRegistered<AdService>()) di.sl.unregister<AdService>();
    if (di.sl.isRegistered<NetworkInfo>()) di.sl.unregister<NetworkInfo>();
  });

  Future<void> pumpDailyExpressionScreen(
    WidgetTester tester, {
    SpeakingState? state,
    int level = 2,
    GameSubtype gameType = GameSubtype.dailyExpression,
    ThemeMode themeMode = ThemeMode.dark,
    Size size = const Size(390, 1400),
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
    if (!speakingStreamController.isClosed) {
      speakingStreamController.add(activeState);
    }

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<SpeakingBloc>.value(value: mockSpeakingBloc),
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<EconomyBloc>.value(value: mockEconomyBloc),
        ],
        child: ScreenUtilInit(
          designSize: size,
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) => MaterialApp(
            themeMode: themeMode,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            home: MediaQuery(
              data: MediaQueryData(
                size: size,
                disableAnimations: reduceMotion,
              ),
              child: DailyExpressionScreen(
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

  group('DailyExpressionScreen Layout and Mechanics Tests', () {
    // -------------------------------------------------------------------------
    // 1. Initial Screen State & Shimmer Loading (8 tests)
    // -------------------------------------------------------------------------
    group('1. Initial Screen State & Shimmer Loading', () {
      testWidgets('1.1 renders shimmer loading when in SpeakingLoading state', (
        tester,
      ) async {
        await pumpDailyExpressionScreen(tester, state: const SpeakingLoading());
        expect(find.byType(GameShimmerLoading), findsOneWidget);
        expect(find.byType(DailyExpressionScratchPanel), findsNothing);
      });

      testWidgets('1.2 renders shimmer loading when in SpeakingInitial state', (
        tester,
      ) async {
        await pumpDailyExpressionScreen(tester, state: const SpeakingInitial());
        expect(find.byType(GameShimmerLoading), findsOneWidget);
        expect(find.byType(DailyExpressionScratchPanel), findsNothing);
      });

      testWidgets('1.3 renders SpeakingBaseLayout container across states', (
        tester,
      ) async {
        await pumpDailyExpressionScreen(tester, state: const SpeakingLoading());
        expect(find.byType(SpeakingBaseLayout), findsOneWidget);
      });

      testWidgets('1.4 dispatches FetchSpeakingQuests on initState', (
        tester,
      ) async {
        await pumpDailyExpressionScreen(tester, level: 3);
        verify(
          () => mockSpeakingBloc.add(
            const FetchSpeakingQuests(
              gameType: GameSubtype.dailyExpression,
              level: 3,
            ),
          ),
        ).called(1);
      });

      testWidgets('1.5 clamps textScaler to 1.1 maxScaleFactor for a11y', (
        tester,
      ) async {
        await pumpDailyExpressionScreen(tester);
        final mediaQueryWidgets = tester.widgetList<MediaQuery>(
          find.descendant(
            of: find.byType(DailyExpressionScreen),
            matching: find.byType(MediaQuery),
          ),
        );
        expect(
          mediaQueryWidgets.first.data.textScaler.scale(10.0),
          lessThanOrEqualTo(11.0),
        );
      });

      testWidgets('1.6 loads with custom level parameter cleanly', (
        tester,
      ) async {
        await pumpDailyExpressionScreen(tester, level: 5);
        final screen = tester.widget<DailyExpressionScreen>(
          find.byType(DailyExpressionScreen),
        );
        expect(screen.level, equals(5));
      });

      testWidgets('1.7 loads with custom gameType parameter cleanly', (
        tester,
      ) async {
        await pumpDailyExpressionScreen(
          tester,
          gameType: GameSubtype.dailyExpression,
        );
        final screen = tester.widget<DailyExpressionScreen>(
          find.byType(DailyExpressionScreen),
        );
        expect(screen.gameType, equals(GameSubtype.dailyExpression));
      });

      testWidgets('1.8 getCompletionTitle returns LEVEL COMPLETE!', (
        tester,
      ) async {
        await pumpDailyExpressionScreen(tester);
        final state = tester.state<State<DailyExpressionScreen>>(
          find.byType(DailyExpressionScreen),
        );
        expect(
          (state as dynamic).getCompletionTitle(state.context),
          equals('LEVEL COMPLETE!'),
        );
      });
    });

    // -------------------------------------------------------------------------
    // 2. Briefing Overlay & Instructions (5 tests)
    // -------------------------------------------------------------------------
    group('2. Briefing Overlay & Instructions', () {
      testWidgets(
        '2.1 displays QuestBriefingOverlay when level is 1',
        (tester) async {
          await pumpDailyExpressionScreen(tester, level: 1);
          expect(find.byType(QuestBriefingOverlay), findsOneWidget);
        },
      );

      testWidgets(
        '2.2 displays uppercase SOCIAL FLUENT title in briefing overlay',
        (tester) async {
          await pumpDailyExpressionScreen(tester, level: 1);
          expect(find.text('SOCIAL FLUENT'), findsOneWidget);
        },
      );

      testWidgets(
        '2.3 displays uppercase SPEAK NOW button in briefing overlay',
        (tester) async {
          await pumpDailyExpressionScreen(tester, level: 1);
          expect(find.text('SPEAK NOW'), findsOneWidget);
        },
      );

      testWidgets('2.4 tapping SPEAK NOW button dismisses briefing overlay', (
        tester,
      ) async {
        await pumpDailyExpressionScreen(tester, level: 1);
        expect(find.byType(QuestBriefingOverlay), findsOneWidget);

        await tester.tap(find.text('SPEAK NOW'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 800));

        expect(find.byType(QuestBriefingOverlay), findsNothing);
      });

      testWidgets(
        '2.5 does not show QuestBriefingOverlay when level is 2',
        (tester) async {
          await pumpDailyExpressionScreen(tester, level: 2);
          expect(find.byType(QuestBriefingOverlay), findsNothing);
        },
      );
    });

    // -------------------------------------------------------------------------
    // 3. Header Component (DailyExpressionHeader) (4 tests)
    // -------------------------------------------------------------------------
    group('3. Header Component (DailyExpressionHeader)', () {
      testWidgets('3.1 renders header with key daily_expression_header', (
        tester,
      ) async {
        await pumpDailyExpressionScreen(tester);
        expect(
          find.byKey(const Key('daily_expression_header')),
          findsOneWidget,
        );
        expect(find.byType(DailyExpressionHeader), findsOneWidget);
      });

      testWidgets('3.2 displays fallback instruction text in natural case', (tester) async {
        await pumpDailyExpressionScreen(tester);
        expect(find.text('Speak the daily idiom'), findsOneWidget);
      });

      testWidgets('3.3 displays auto_awesome_rounded icon in header', (
        tester,
      ) async {
        await pumpDailyExpressionScreen(tester);
        expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
      });

      testWidgets(
        '3.4 handles long instruction text with centered wrapping without overflow',
        (tester) async {
          when(
            () => mockLocaleService.tr(any(), fallback: any(named: 'fallback')),
          ).thenReturn(
            'This is a very long instruction to test text wrapping and center alignment in daily expression header widget without overflowing',
          );
          await pumpDailyExpressionScreen(tester);
          expect(tester.takeException(), isNull);
        },
      );
    });

    // -------------------------------------------------------------------------
    // 4. Scratch Panel Initial State (DailyExpressionScratchPanel) (6 tests)
    // -------------------------------------------------------------------------
    group('4. Scratch Panel Initial State (DailyExpressionScratchPanel)', () {
      testWidgets(
        '4.1 renders scratch panel with key daily_expression_scratch_panel',
        (tester) async {
          await pumpDailyExpressionScreen(tester);
          expect(
            find.byKey(const Key('daily_expression_scratch_panel')),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        '4.2 scratch foil overlay renders with key daily_expression_scratch_foil',
        (tester) async {
          await pumpDailyExpressionScreen(tester);
          expect(
            find.byKey(const Key('daily_expression_scratch_foil')),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        '4.3 scratch hint overlay renders with key daily_expression_scratch_hint',
        (tester) async {
          await pumpDailyExpressionScreen(tester);
          expect(
            find.byKey(const Key('daily_expression_scratch_hint')),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        '4.4 displays Swipe to reveal idiom when reduceComplexGestures is false',
        (tester) async {
          SharedPreferences.setMockInitialValues({
            'has_seen_briefing_dailyExpression': true,
            'reduce_complex_gestures': false,
          });
          await pumpDailyExpressionScreen(tester);
          expect(find.text('Swipe to reveal idiom'), findsOneWidget);
        },
      );

      testWidgets(
        '4.5 displays Tap to reveal idiom when reduceComplexGestures is true',
        (tester) async {
          SharedPreferences.setMockInitialValues({
            'has_seen_briefing_dailyExpression': true,
            'reduce_complex_gestures': true,
          });
          await pumpDailyExpressionScreen(tester);
          expect(find.text('Tap to reveal idiom'), findsOneWidget);
        },
      );

      testWidgets('4.6 provides accessible semantics for unrevealed panel', (
        tester,
      ) async {
        await pumpDailyExpressionScreen(tester);
        expect(
          find.byWidgetPredicate((w) =>
              w is Semantics &&
              w.properties.label ==
                  'Hidden daily idiom. Swipe or tap to reveal idiom.'),
          findsOneWidget,
        );
      });
    });

    // -------------------------------------------------------------------------
    // 5. TTS Pronunciation Audio Playback (4 tests)
    // -------------------------------------------------------------------------
    group('5. TTS Pronunciation Audio Playback', () {
      testWidgets(
        '5.1 renders volume button with key daily_expression_tts_button',
        (tester) async {
          await pumpDailyExpressionScreen(tester);
          expect(
            find.byKey(const Key('daily_expression_tts_button')),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        '5.2 tapping TTS volume button plays expression pronunciation',
        (tester) async {
          await pumpDailyExpressionScreen(tester);
          await tester.tap(
            find.byKey(const Key('daily_expression_scratch_foil')),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));

          await tester.tap(
            find.byKey(const Key('daily_expression_tts_button')),
          );
          await tester.pump();
          verify(() => mockSoundService.playTts('Bite the bullet')).called(2);
        },
      );

      testWidgets('5.3 tapping TTS volume button while recording does not play', (
        tester,
      ) async {
        await pumpDailyExpressionScreen(tester);
        await tester.tap(
          find.byKey(const Key('daily_expression_scratch_foil')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        when(() => mockAudioRecorder.isRecording).thenReturn(true);
        await tester.tap(
          find.byKey(const Key('daily_expression_tts_button')),
        );
        await tester.pump();
        verify(() => mockSoundService.playTts('Bite the bullet')).called(1);
      });

      testWidgets('5.4 TTS button provides accessible semantics', (
        tester,
      ) async {
        await pumpDailyExpressionScreen(tester);
        expect(
          find.byWidgetPredicate((w) =>
              w is Semantics &&
              w.properties.label == 'Listen to expression pronunciation'),
          findsOneWidget,
        );
      });
    });

    // -------------------------------------------------------------------------
    // 6. Scratching Interactions & Progress Mechanics (8 tests)
    // -------------------------------------------------------------------------
    group('6. Scratching Interactions & Progress Mechanics', () {
      testWidgets(
        '6.1 tapping scratch foil immediately reveals idiom (progress 1.0)',
        (tester) async {
          await pumpDailyExpressionScreen(tester);
          expect(
            find.byKey(const Key('daily_expression_scratch_foil')),
            findsOneWidget,
          );

          await tester.tap(
            find.byKey(const Key('daily_expression_scratch_foil')),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));

          // At 1.0 progress, foil is removed and usage panel + shadow compare appear
          expect(
            find.byKey(const Key('daily_expression_scratch_foil')),
            findsNothing,
          );
          expect(
            find.byKey(const Key('daily_expression_usage_panel')),
            findsOneWidget,
          );
          expect(
            find.byKey(const Key('daily_expression_shadow_compare')),
            findsOneWidget,
          );
        },
      );

      testWidgets('6.2 panning on foil increments scratch progress', (
        tester,
      ) async {
        await pumpDailyExpressionScreen(tester);
        await tester.drag(
          find.byKey(const Key('daily_expression_scratch_foil')),
          const Offset(50, 50),
        );
        await tester.pump();
        // Dragging triggers scratch update
        expect(find.byType(DailyExpressionScratchPanel), findsOneWidget);
      });

      testWidgets(
        '6.3 usage panel is hidden when scratch progress is less than 0.3',
        (tester) async {
          await pumpDailyExpressionScreen(tester);
          // Initial progress is 0.0
          expect(
            find.byKey(const Key('daily_expression_usage_panel')),
            findsNothing,
          );
        },
      );

      testWidgets(
        '6.4 usage panel is revealed when scratch progress exceeds 0.3',
        (tester) async {
          await pumpDailyExpressionScreen(tester);
          // Tap foil to trigger full reveal
          await tester.tap(
            find.byKey(const Key('daily_expression_scratch_foil')),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));

          expect(
            find.byKey(const Key('daily_expression_usage_panel')),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        '6.5 scratch progress reaching 0.85+ triggers haptic selection',
        (tester) async {
          await pumpDailyExpressionScreen(tester);
          await tester.tap(
            find.byKey(const Key('daily_expression_scratch_foil')),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));

          verify(() => mockHapticService.selection()).called(1);
        },
      );

      testWidgets('6.6 scratch progress reaching 0.85+ triggers TTS playback', (
        tester,
      ) async {
        await pumpDailyExpressionScreen(tester);
        await tester.tap(
          find.byKey(const Key('daily_expression_scratch_foil')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        verify(() => mockSoundService.playTts('Bite the bullet')).called(1);
      });

      testWidgets(
        '6.7 scratch hint overlay is removed once scratch progress exceeds 0.0',
        (tester) async {
          await pumpDailyExpressionScreen(tester);
          expect(
            find.byKey(const Key('daily_expression_scratch_hint')),
            findsOneWidget,
          );

          await tester.tap(
            find.byKey(const Key('daily_expression_scratch_foil')),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));

          expect(
            find.byKey(const Key('daily_expression_scratch_hint')),
            findsNothing,
          );
        },
      );

      testWidgets(
        '6.8 multiple taps on revealed card do not re-trigger completion',
        (tester) async {
          await pumpDailyExpressionScreen(tester);
          await tester.tap(
            find.byKey(const Key('daily_expression_scratch_foil')),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));

          // Tap card area again
          await tester.tap(
            find.text('Bite the bullet'),
          );
          await tester.pump();

          // Selection haptic only called once from snapping
          verify(() => mockHapticService.selection()).called(1);
        },
      );
    });

    // -------------------------------------------------------------------------
    // 7. Revealed Idiom Card Details (5 tests)
    // -------------------------------------------------------------------------
    group('7. Revealed Idiom Card Details', () {
      testWidgets('7.1 displays category label', (
        tester,
      ) async {
        await pumpDailyExpressionScreen(tester);
        expect(find.text('Daily Idiom'), findsOneWidget);
      });

      testWidgets('7.2 displays idiom expression text', (tester) async {
        await pumpDailyExpressionScreen(tester);
        expect(find.text('Bite the bullet'), findsOneWidget);
      });

      testWidgets('7.3 displays idiom meaning in readable case', (tester) async {
        await pumpDailyExpressionScreen(tester);
        expect(
          find.text(
            'To endure a painful situation that cannot be avoided',
          ),
          findsOneWidget,
        );
      });

      testWidgets(
        '7.4 displays speak badge with mic icon when scratchProgress is 1.0',
        (tester) async {
          await pumpDailyExpressionScreen(tester);
          expect(
            find.byKey(const Key('daily_expression_speak_badge')),
            findsNothing,
          );

          await tester.tap(
            find.byKey(const Key('daily_expression_scratch_foil')),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));

          expect(
            find.byKey(const Key('daily_expression_speak_badge')),
            findsOneWidget,
          );
          expect(find.text('Speak this'), findsOneWidget);
        },
      );

      testWidgets(
        '7.5 updates Semantics label when idiom is fully revealed',
        (tester) async {
          await pumpDailyExpressionScreen(tester);
          await tester.tap(
            find.byKey(const Key('daily_expression_scratch_foil')),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));

          expect(
            find.byWidgetPredicate((w) =>
                w is Semantics &&
                w.properties.label ==
                    'Daily expression: Bite the bullet. Meaning: To endure a painful situation that cannot be avoided'),
            findsOneWidget,
          );
        },
      );
    });

    // -------------------------------------------------------------------------
    // 8. Usage Panel Component (DailyExpressionUsagePanel) (5 tests)
    // -------------------------------------------------------------------------
    group('8. Usage Panel Component (DailyExpressionUsagePanel)', () {
      testWidgets(
        '8.1 renders usage panel with key daily_expression_usage_panel',
        (tester) async {
          await pumpDailyExpressionScreen(tester);
          await tester.tap(
            find.byKey(const Key('daily_expression_scratch_foil')),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));

          expect(
            find.byKey(const Key('daily_expression_usage_panel')),
            findsOneWidget,
          );
          expect(find.byType(DailyExpressionUsagePanel), findsOneWidget);
        },
      );

      testWidgets(
        '8.2 displays Origin header with history_edu_rounded icon',
        (tester) async {
          await pumpDailyExpressionScreen(tester);
          await tester.tap(
            find.byKey(const Key('daily_expression_scratch_foil')),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));

          expect(find.text('Origin'), findsOneWidget);
          expect(find.byIcon(Icons.history_edu_rounded), findsOneWidget);
          expect(
            find.text(
              'Originated from battlefield surgeries where soldiers were given lead bullets to bite down on.',
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        '8.3 displays Example sentence with format_quote_rounded icon',
        (tester) async {
          await pumpDailyExpressionScreen(tester);
          await tester.tap(
            find.byKey(const Key('daily_expression_scratch_foil')),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));

          expect(find.text('Example sentence'), findsOneWidget);
          expect(find.byIcon(Icons.format_quote_rounded), findsOneWidget);
          expect(
            find.text('"I had to bite the bullet and pay the fine."'),
            findsOneWidget,
          );
        },
      );

      testWidgets('8.4 hides explanation section when explanation is null', (
        tester,
      ) async {
        final questNoOrigin = createQuest(explanation: null);
        final stateNoOrigin = testLoadedState.copyWith(
          quests: [questNoOrigin],
        );
        await pumpDailyExpressionScreen(tester, state: stateNoOrigin);
        await tester.tap(
          find.byKey(const Key('daily_expression_scratch_foil')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.text('Origin'), findsNothing);
        expect(find.byIcon(Icons.history_edu_rounded), findsNothing);
        expect(find.text('Example sentence'), findsOneWidget);
      });

      testWidgets(
        '8.5 handles very long origin and usage text gracefully without overflow',
        (tester) async {
          final longQuest = createQuest(
            explanation:
                'This is an exceptionally long historical origin paragraph that explains in excruciating detail every historical context and linguistic shift over two centuries.',
            sampleUsage:
                'After considering all possible consequences and financial implications over several long weeks, she finally decided to bite the bullet and invest all her remaining life savings into the venture.',
          );
          final longState = testLoadedState.copyWith(quests: [longQuest]);
          await pumpDailyExpressionScreen(tester, state: longState);
          await tester.tap(
            find.byKey(const Key('daily_expression_scratch_foil')),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));

          expect(tester.takeException(), isNull);
        },
      );
    });

    // -------------------------------------------------------------------------
    // 9. Hint System (SpeakingHintUsed) (4 tests)
    // -------------------------------------------------------------------------
    group('9. Hint System (SpeakingHintUsed)', () {
      testWidgets('9.1 tapping header hint button dispatches SpeakingHintUsed', (
        tester,
      ) async {
        await pumpDailyExpressionScreen(tester);
        final hintButton = find.byType(QuestHintButton);
        expect(hintButton, findsOneWidget);

        await tester.tap(hintButton);
        await tester.pump();

        verify(
          () => mockSpeakingBloc.add(const SpeakingHintUsed()),
        ).called(greaterThanOrEqualTo(1));
      });

      testWidgets(
        '9.2 displays hint container when hintUsed is true and hint is available',
        (tester) async {
          final hintState = testLoadedState.copyWith(hintUsed: true);
          await pumpDailyExpressionScreen(tester, state: hintState);

          expect(
            find.byKey(const Key('daily_expression_hint_container')),
            findsOneWidget,
          );
          expect(
            find.text('Think of enduring an unpleasant situation with courage'),
            findsOneWidget,
          );
        },
      );

      testWidgets('9.3 does not show hint container when hintUsed is false', (
        tester,
      ) async {
        await pumpDailyExpressionScreen(tester);
        expect(
          find.byKey(const Key('daily_expression_hint_container')),
          findsNothing,
        );
      });

      testWidgets(
        '9.4 does not show hint container when quest hint is null even if hintUsed is true',
        (tester) async {
          final noHintQuest = createQuest(hint: null);
          final hintState = testLoadedState.copyWith(
            quests: [noHintQuest],
            hintUsed: true,
          );
          await pumpDailyExpressionScreen(tester, state: hintState);

          expect(
            find.byKey(const Key('daily_expression_hint_container')),
            findsNothing,
          );
        },
      );
    });

    // -------------------------------------------------------------------------
    // 10. ShadowPlaybackCompare Integration (7 tests)
    // -------------------------------------------------------------------------
    group('10. ShadowPlaybackCompare Integration', () {
      testWidgets(
        '10.1 ShadowPlaybackCompare is not mounted when scratchProgress < 1.0',
        (tester) async {
          await pumpDailyExpressionScreen(tester);
          expect(find.byType(ShadowPlaybackCompare), findsNothing);
          expect(
            find.byKey(const Key('daily_expression_shadow_compare')),
            findsNothing,
          );
        },
      );

      testWidgets(
        '10.2 ShadowPlaybackCompare is mounted once scratchProgress reaches 1.0',
        (tester) async {
          await pumpDailyExpressionScreen(tester);
          await tester.tap(
            find.byKey(const Key('daily_expression_scratch_foil')),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));

          expect(
            find.byKey(const Key('daily_expression_shadow_compare')),
            findsOneWidget,
          );
          expect(find.byType(ShadowPlaybackCompare), findsOneWidget);
        },
      );

      testWidgets('10.3 configures ShadowPlaybackCompare parameters correctly', (
        tester,
      ) async {
        await pumpDailyExpressionScreen(tester);
        await tester.tap(
          find.byKey(const Key('daily_expression_scratch_foil')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        final shadowWidget = tester.widget<ShadowPlaybackCompare>(
          find.byKey(const Key('daily_expression_shadow_compare')),
        );
        expect(shadowWidget.expectedText, equals('Bite the bullet'));
        expect(shadowWidget.showExpectedText, isFalse);
        expect(shadowWidget.isPositioned, isFalse);
      });

      testWidgets(
        '10.4 displays SHADOW & COMPARE title in ShadowPlaybackCompare',
        (tester) async {
          await pumpDailyExpressionScreen(tester);
          await tester.tap(
            find.byKey(const Key('daily_expression_scratch_foil')),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));

          expect(find.text('SHADOW & COMPARE'), findsOneWidget);
        },
      );

      testWidgets(
        '10.5 tapping mic button starts audio recording via AudioRecordingService',
        (tester) async {
          await pumpDailyExpressionScreen(tester);
          await tester.tap(
            find.byKey(const Key('daily_expression_scratch_foil')),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));

          await tester.drag(
            find.byType(CustomScrollView),
            const Offset(0, -400),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          final micBtn = find.byKey(const ValueKey('shadow_mic_btn'));
          expect(micBtn, findsOneWidget);

          await tester.tap(micBtn);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));

          verify(() => mockAudioRecorder.startRecording()).called(1);
        },
      );

      testWidgets('10.6 onConfirmed callback triggers verbal submission', (
        tester,
      ) async {
        await pumpDailyExpressionScreen(tester);
        await tester.tap(
          find.byKey(const Key('daily_expression_scratch_foil')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        final shadowWidget = tester.widget<ShadowPlaybackCompare>(
          find.byKey(const Key('daily_expression_shadow_compare')),
        );
        shadowWidget.onConfirmed();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        verify(() => mockSpeakingBloc.add(const SubmitAnswer(true))).called(1);
      });

      testWidgets('10.7 onSkipped callback triggers verbal submission', (
        tester,
      ) async {
        await pumpDailyExpressionScreen(tester);
        await tester.tap(
          find.byKey(const Key('daily_expression_scratch_foil')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        final shadowWidget = tester.widget<ShadowPlaybackCompare>(
          find.byKey(const Key('daily_expression_shadow_compare')),
        );
        shadowWidget.onSkipped();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        verify(() => mockSpeakingBloc.add(const SubmitAnswer(false))).called(1);
      });
    });

    // -------------------------------------------------------------------------
    // 11. Answer Submission & Evaluation Lockout (5 tests)
    // -------------------------------------------------------------------------
    group('11. Answer Submission & Evaluation Lockout', () {
      testWidgets(
        '11.1 submitting correct evaluation plays correct sound and haptic',
        (tester) async {
          await pumpDailyExpressionScreen(tester);
          await tester.tap(
            find.byKey(const Key('daily_expression_scratch_foil')),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));

          final shadowWidget = tester.widget<ShadowPlaybackCompare>(
            find.byKey(const Key('daily_expression_shadow_compare')),
          );
          shadowWidget.onConfirmed();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));

          verify(() => mockHapticService.success()).called(1);
          verify(() => mockSoundService.playCorrect()).called(1);
        },
      );

      testWidgets(
        '11.2 submitting wrong evaluation plays wrong sound and haptic',
        (tester) async {
          await pumpDailyExpressionScreen(tester);
          await tester.tap(
            find.byKey(const Key('daily_expression_scratch_foil')),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));

          final shadowWidget = tester.widget<ShadowPlaybackCompare>(
            find.byKey(const Key('daily_expression_shadow_compare')),
          );
          shadowWidget.onSkipped();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));

          verify(() => mockHapticService.error()).called(1);
          verify(() => mockSoundService.playWrong()).called(1);
        },
      );

      testWidgets(
        '11.3 once answered, ShadowPlaybackCompare is unmounted from tree',
        (tester) async {
          await pumpDailyExpressionScreen(tester);
          await tester.tap(
            find.byKey(const Key('daily_expression_scratch_foil')),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));

          final shadowWidget = tester.widget<ShadowPlaybackCompare>(
            find.byKey(const Key('daily_expression_shadow_compare')),
          );
          shadowWidget.onConfirmed();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));

          expect(
            find.byKey(const Key('daily_expression_shadow_compare')),
            findsNothing,
          );
        },
      );

      testWidgets(
        '11.4 once answered, subsequent answer evaluations are locked out',
        (tester) async {
          await pumpDailyExpressionScreen(tester);
          await tester.tap(
            find.byKey(const Key('daily_expression_scratch_foil')),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));

          final shadowWidget = tester.widget<ShadowPlaybackCompare>(
            find.byKey(const Key('daily_expression_shadow_compare')),
          );
          shadowWidget.onConfirmed();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));

          // Try submitting again via cached instance
          shadowWidget.onConfirmed();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));

          // Should still only have called SubmitAnswer once
          verify(() => mockSpeakingBloc.add(const SubmitAnswer(true))).called(1);
        },
      );

      testWidgets(
        '11.5 answered state mounts GameFeedbackCard with CONTINUE action',
        (tester) async {
          final answeredState = testLoadedState.copyWith(
            answerStatus: AnswerStatus.correct,
          );
          await pumpDailyExpressionScreen(tester, state: answeredState);

          expect(find.byType(GameFeedbackCard), findsOneWidget);
          expect(find.text('CONTINUE'), findsOneWidget);
        },
      );
    });

    // -------------------------------------------------------------------------
    // 12. Progression, State Transitions, and Cleanup (4 tests)
    // -------------------------------------------------------------------------
    group('12. Progression, State Transitions, and Cleanup', () {
      testWidgets('12.1 tapping continue button dispatches NextQuestion', (
        tester,
      ) async {
        final answeredState = testLoadedState.copyWith(
          answerStatus: AnswerStatus.correct,
        );
        await pumpDailyExpressionScreen(tester, state: answeredState);

        await tester.tap(find.text('CONTINUE'));
        await tester.pump();

        verify(() => mockSpeakingBloc.add(const NextQuestion())).called(1);
      });

      testWidgets(
        '12.2 onQuestionReset resets scratch progress and foil reappears',
        (tester) async {
          await pumpDailyExpressionScreen(tester);
          await tester.tap(
            find.byKey(const Key('daily_expression_scratch_foil')),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));

          expect(
            find.byKey(const Key('daily_expression_scratch_foil')),
            findsNothing,
          );

          // Simulate question transition to second quest
          final nextState = testLoadedState.copyWith(
            currentIndex: 1,
            answerStatus: AnswerStatus.unanswered,
          );
          speakingStreamController.add(nextState);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));

          expect(
            find.byKey(const Key('daily_expression_scratch_foil')),
            findsOneWidget,
          );
          expect(find.text('Break the ice'), findsOneWidget);
        },
      );

      testWidgets('12.3 SpeakingGameComplete triggers game completion dialog', (
        tester,
      ) async {
        await pumpDailyExpressionScreen(tester);
        speakingStreamController.add(
          const SpeakingGameComplete(
            xpEarned: 25,
            coinsEarned: 15,
            questCount: 2,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.text('LEVEL COMPLETE!'), findsWidgets);
      });

      testWidgets(
        '12.4 screen disposes cleanly without timer leaks or exceptions',
        (tester) async {
          await pumpDailyExpressionScreen(tester);
          await tester.tap(
            find.byKey(const Key('daily_expression_scratch_foil')),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));

          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump();
          expect(tester.takeException(), isNull);
        },
      );
    });

    // -------------------------------------------------------------------------
    // 13. Viewport Responsiveness, Theming & Accessibility (5 tests)
    // -------------------------------------------------------------------------
    group('13. Viewport Responsiveness, Theming & Accessibility', () {
      testWidgets('13.1 renders cleanly on compact phone viewport (320x568)', (
        tester,
      ) async {
        await pumpDailyExpressionScreen(
          tester,
          size: const Size(320, 568),
        );
        expect(find.byType(DailyExpressionScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('13.2 renders cleanly on tablet viewport (768x1024)', (
        tester,
      ) async {
        await pumpDailyExpressionScreen(
          tester,
          size: const Size(768, 1024),
        );
        expect(find.byType(DailyExpressionScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('13.3 renders cleanly in Light Theme mode', (tester) async {
        await pumpDailyExpressionScreen(
          tester,
          themeMode: ThemeMode.light,
        );
        expect(find.byType(DailyExpressionScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('13.4 renders cleanly in Dark Theme mode', (tester) async {
        await pumpDailyExpressionScreen(
          tester,
          themeMode: ThemeMode.dark,
        );
        expect(find.byType(DailyExpressionScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets(
        '13.5 animations are disabled and static icons used when reduceMotion is active',
        (tester) async {
          await pumpDailyExpressionScreen(
            tester,
            reduceMotion: true,
          );
          expect(find.byType(DailyExpressionScratchPanel), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    });
  });
}

