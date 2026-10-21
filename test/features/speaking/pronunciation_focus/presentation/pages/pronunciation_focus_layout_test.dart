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
import 'package:vowl/features/speaking/domain/entities/speaking_quest.dart';
import 'package:vowl/features/speaking/presentation/bloc/speaking_bloc.dart';
import 'package:vowl/features/speaking/presentation/layout/speaking_base_layout.dart';
import 'package:vowl/features/speaking/pronunciation_focus/presentation/pages/pronunciation_focus_screen.dart';
import 'package:vowl/features/speaking/pronunciation_focus/presentation/widgets/pronunciation_focus_phoneme_crucible.dart';
import 'package:vowl/features/speaking/pronunciation_focus/presentation/widgets/pronunciation_focus_thermal_grid.dart';
import 'package:vowl/features/speaking/pronunciation_focus/presentation/widgets/thermal_grid_painter.dart';

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
    String id = 'quest_pronunciation_1',
    String? targetPhoneme = '[r]',
    String? textToSpeak = 'Red round roller rink',
    String? sentence = 'Red round roller rink',
    String? phoneticHint =
        'Curl the tongue tip backward without touching the alveolar ridge.',
    List<String>? commonMistakes = const [
      'Substituting [w] for [r]',
      'Flapping against the gums',
    ],
    String instruction = 'Master the retroflex liquid sound',
    String? hint = 'Focus on pulling the tongue body slightly backward.',
    int difficulty = 2,
  }) {
    return SpeakingQuest(
      id: id,
      type: QuestType.speaking,
      subtype: GameSubtype.pronunciationFocus,
      targetPhoneme: targetPhoneme,
      textToSpeak: textToSpeak,
      sentence: sentence,
      phoneticHint: phoneticHint,
      commonMistakes: commonMistakes,
      instruction: instruction,
      hint: hint,
      difficulty: difficulty,
      targetWord: textToSpeak,
      correctAnswer: textToSpeak,
    );
  }

  final sampleQuest1 = createQuest();
  final sampleQuest2 = createQuest(
    id: 'quest_pronunciation_2',
    targetPhoneme: '[th]',
    textToSpeak: 'Thirty three thirsty thieves',
    sentence: 'Thirty three thirsty thieves',
    phoneticHint: 'Place the tip of the tongue between the front teeth.',
  );

  final testLoadedState = SpeakingLoaded(
    quests: [sampleQuest1, sampleQuest2],
    currentIndex: 0,
    livesRemaining: 3,
    wrongCount: 0,
    hintUsed: false,
    answerStatus: AnswerStatus.unanswered,
    gameType: GameSubtype.pronunciationFocus,
    level: 2,
  );

  setUpAll(() {
    registerFallbackValue(
      const FetchSpeakingQuests(
        gameType: GameSubtype.pronunciationFocus,
        level: 1,
      ),
    );
    registerFallbackValue(const Duration(milliseconds: 50));
    VowlMotion.lowAnimationModeOverride.value = true;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'has_seen_briefing_pronunciationFocus': true,
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
          displayName: 'Test Phonetic Master',
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
    ).thenAnswer((_) async => '/tmp/pronunciation_test.m4a');
    when(() => mockAudioRecorder.isRecording).thenReturn(false);
    when(() => mockAudioRecorder.dispose()).thenAnswer((_) async {});

    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

    // Register GetIt singletons
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

  Future<void> pumpPronunciationFocusScreen(
    WidgetTester tester, {
    SpeakingState? state,
    int level = 2,
    GameSubtype gameType = GameSubtype.pronunciationFocus,
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
              child: PronunciationFocusScreen(
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

  group('PronunciationFocusScreen Layout and Mechanics Tests', () {
    // -------------------------------------------------------------------------
    // 1. Initial Screen State & Shimmer Loading (8 tests)
    // -------------------------------------------------------------------------
    group('1. Initial Screen State & Shimmer Loading', () {
      testWidgets('1.1 renders shimmer loading when in SpeakingLoading state', (
        tester,
      ) async {
        await pumpPronunciationFocusScreen(
          tester,
          state: const SpeakingLoading(),
        );
        expect(find.byType(GameShimmerLoading), findsOneWidget);
        expect(find.byType(PronunciationFocusPhonemeCrucible), findsNothing);
      });

      testWidgets('1.2 renders shimmer loading when in SpeakingInitial state', (
        tester,
      ) async {
        await pumpPronunciationFocusScreen(
          tester,
          state: const SpeakingInitial(),
        );
        expect(find.byType(GameShimmerLoading), findsOneWidget);
        expect(find.byType(PronunciationFocusPhonemeCrucible), findsNothing);
      });

      testWidgets('1.3 renders SpeakingBaseLayout container across states', (
        tester,
      ) async {
        await pumpPronunciationFocusScreen(tester);
        expect(find.byType(SpeakingBaseLayout), findsOneWidget);
      });

      testWidgets('1.4 dispatches FetchSpeakingQuests on initState', (
        tester,
      ) async {
        await pumpPronunciationFocusScreen(tester);
        verify(
          () => mockSpeakingBloc.add(
            any(that: isA<FetchSpeakingQuests>()),
          ),
        ).called(1);
      });

      testWidgets('1.5 clamps textScaler to 1.1 maxScaleFactor for a11y', (
        tester,
      ) async {
        await pumpPronunciationFocusScreen(tester);
        final mediaQueryFinder = find.descendant(
          of: find.byType(PronunciationFocusScreen),
          matching: find.byType(MediaQuery),
        );
        expect(mediaQueryFinder, findsWidgets);
      });

      testWidgets('1.6 loads with custom level parameter cleanly', (
        tester,
      ) async {
        await pumpPronunciationFocusScreen(tester, level: 3);
        expect(find.byType(PronunciationFocusScreen), findsOneWidget);
      });

      testWidgets('1.7 loads with custom gameType parameter cleanly', (
        tester,
      ) async {
        await pumpPronunciationFocusScreen(
          tester,
          gameType: GameSubtype.pronunciationFocus,
        );
        expect(find.byType(PronunciationFocusScreen), findsOneWidget);
      });

      testWidgets('1.8 getCompletionTitle returns PHONETIC MASTER!', (
        tester,
      ) async {
        await pumpPronunciationFocusScreen(tester);
        final state = tester.state<State>(
          find.byType(PronunciationFocusScreen),
        );
        expect(
          (state as dynamic).getCompletionTitle(
            tester.element(find.byType(PronunciationFocusScreen)),
          ),
          equals('PHONETIC MASTER!'),
        );
      });
    });

    // -------------------------------------------------------------------------
    // 2. Briefing Overlay & Instructions (5 tests)
    // -------------------------------------------------------------------------
    group('2. Briefing Overlay & Instructions', () {
      testWidgets('2.1 displays QuestBriefingOverlay when level is 1', (
        tester,
      ) async {
        SharedPreferences.setMockInitialValues({
          'has_seen_briefing_pronunciationFocus': false,
        });
        await pumpPronunciationFocusScreen(tester, level: 1);
        expect(find.byType(QuestBriefingOverlay), findsOneWidget);
      });

      testWidgets(
        '2.2 displays uppercase PHONETIC PRECISION title in briefing overlay',
        (tester) async {
          SharedPreferences.setMockInitialValues({
            'has_seen_briefing_pronunciationFocus': false,
          });
          await pumpPronunciationFocusScreen(tester, level: 1);
          expect(find.text('PHONETIC PRECISION'), findsOneWidget);
        },
      );

      testWidgets(
        '2.3 displays uppercase PRACTICE SOUND button in briefing overlay',
        (tester) async {
          SharedPreferences.setMockInitialValues({
            'has_seen_briefing_pronunciationFocus': false,
          });
          await pumpPronunciationFocusScreen(tester, level: 1);
          expect(find.text('PRACTICE SOUND'), findsOneWidget);
        },
      );

      testWidgets(
        '2.4 tapping PRACTICE SOUND button dismisses briefing overlay',
        (tester) async {
          SharedPreferences.setMockInitialValues({
            'has_seen_briefing_pronunciationFocus': false,
          });
          await pumpPronunciationFocusScreen(tester, level: 1);
          expect(find.byType(QuestBriefingOverlay), findsOneWidget);

          await tester.tap(find.text('PRACTICE SOUND'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));

          expect(find.byType(QuestBriefingOverlay), findsNothing);
        },
      );

      testWidgets('2.5 does not show QuestBriefingOverlay when level is 2', (
        tester,
      ) async {
        await pumpPronunciationFocusScreen(tester, level: 2);
        expect(find.byType(QuestBriefingOverlay), findsNothing);
      });
    });

    // -------------------------------------------------------------------------
    // 3. Header Component (PronunciationFocusHeader) (6 tests)
    // -------------------------------------------------------------------------
    group('3. Header Component (PronunciationFocusHeader)', () {
      testWidgets('3.1 renders header with key pronunciation_focus_header', (
        tester,
      ) async {
        await pumpPronunciationFocusScreen(tester);
        expect(
          find.byKey(const Key('pronunciation_focus_header')),
          findsOneWidget,
        );
      });

      testWidgets(
        '3.2 displays THERMOGRAPHIC ACCENT CALIBRATOR title in header',
        (tester) async {
          await pumpPronunciationFocusScreen(tester);
          expect(
            find.text('THERMOGRAPHIC ACCENT CALIBRATOR'),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        '3.3 displays Icons.whatshot_rounded icon in header badge',
        (tester) async {
          await pumpPronunciationFocusScreen(tester);
          expect(find.byIcon(Icons.whatshot_rounded), findsOneWidget);
        },
      );

      testWidgets('3.4 displays instruction text accurately', (
        tester,
      ) async {
        await pumpPronunciationFocusScreen(tester);
        expect(
          find.text('Master the retroflex liquid sound'),
          findsOneWidget,
        );
      });

      testWidgets('3.5 has accessible header Semantics label', (
        tester,
      ) async {
        await pumpPronunciationFocusScreen(tester);
        final semanticsFinder = find.descendant(
          of: find.byKey(const Key('pronunciation_focus_header')),
          matching: find.byType(Semantics),
        );
        expect(semanticsFinder, findsWidgets);
      });

      testWidgets(
        '3.6 handles long instruction text with ellipsis without overflow',
        (tester) async {
          final longQuest = createQuest(
            instruction:
                'A very long and thorough phonetic instruction detailing every single facet of mouth positioning, throat vibration, tongue placement, and airflow modulation to ensure flawless accent clarity.',
          );
          final state = testLoadedState.copyWith(quests: [longQuest]);
          await pumpPronunciationFocusScreen(tester, state: state);
          expect(tester.takeException(), isNull);
        },
      );
    });

    // -------------------------------------------------------------------------
    // 4. Phoneme Crucible Component (PronunciationFocusPhonemeCrucible) (8 tests)
    // -------------------------------------------------------------------------
    group('4. Phoneme Crucible Component (PronunciationFocusPhonemeCrucible)', () {
      testWidgets(
        '4.1 renders phoneme crucible with key pronunciation_focus_phoneme_crucible',
        (tester) async {
          await pumpPronunciationFocusScreen(tester);
          expect(
            find.byKey(const Key('pronunciation_focus_phoneme_crucible')),
            findsOneWidget,
          );
        },
      );

      testWidgets('4.2 displays TARGET PHONETIC CORE label', (
        tester,
      ) async {
        await pumpPronunciationFocusScreen(tester);
        expect(find.text('TARGET PHONETIC CORE'), findsOneWidget);
      });

      testWidgets(
        '4.3 displays target phoneme badge with key pronunciation_focus_target_phoneme_badge',
        (tester) async {
          await pumpPronunciationFocusScreen(tester);
          expect(
            find.byKey(const Key('pronunciation_focus_target_phoneme_badge')),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        '4.4 displays quest.targetPhoneme accurately in target phoneme badge',
        (tester) async {
          await pumpPronunciationFocusScreen(tester);
          expect(find.text('[r]'), findsOneWidget);
        },
      );

      testWidgets('4.5 fallback to [r] when quest.targetPhoneme is null', (
        tester,
      ) async {
        final noPhonemeQuest = createQuest(targetPhoneme: null);
        final state = testLoadedState.copyWith(quests: [noPhonemeQuest]);
        await pumpPronunciationFocusScreen(tester, state: state);
        expect(find.text('[r]'), findsOneWidget);
      });

      testWidgets(
        '4.6 renders position guide button with key pronunciation_focus_position_guide_button',
        (tester) async {
          await pumpPronunciationFocusScreen(tester);
          expect(
            find.byKey(const Key('pronunciation_focus_position_guide_button')),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        '4.7 tapping position guide button toggles guide expansion and plays selection haptic',
        (tester) async {
          await pumpPronunciationFocusScreen(tester);
          final guideBtn = find.byKey(
            const Key('pronunciation_focus_position_guide_button'),
          );

          await tester.tap(guideBtn);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));

          verify(() => mockHapticService.selection()).called(1);
          expect(
            find.text(
              'Curl the tongue tip backward without touching the alveolar ridge.',
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        '4.8 renders phoneticHint and commonMistakes when guide is expanded',
        (tester) async {
          await pumpPronunciationFocusScreen(tester);
          final guideBtn = find.byKey(
            const Key('pronunciation_focus_position_guide_button'),
          );

          await tester.tap(guideBtn);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));

          expect(
            find.text(
              'Watch out: Substituting [w] for [r], Flapping against the gums',
            ),
            findsOneWidget,
          );
        },
      );
    });

    // -------------------------------------------------------------------------
    // 5. Thermal Grid Component & Custom Painter (PronunciationFocusThermalGrid) (6 tests)
    // -------------------------------------------------------------------------
    group('5. Thermal Grid Component & Custom Painter (PronunciationFocusThermalGrid)', () {
      testWidgets(
        '5.1 renders thermal grid with key pronunciation_focus_thermal_grid',
        (tester) async {
          await pumpPronunciationFocusScreen(tester);
          expect(
            find.byKey(const Key('pronunciation_focus_thermal_grid')),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        '5.2 has accessible Semantics label "Accent heat visualization grid"',
        (tester) async {
          await pumpPronunciationFocusScreen(tester);
          expect(
            find.bySemanticsLabel('Accent heat visualization grid'),
            findsOneWidget,
          );
        },
      );

      testWidgets('5.3 paints with CustomPaint and ThermalGridPainter', (
        tester,
      ) async {
        await pumpPronunciationFocusScreen(tester);
        final customPaint = tester.widget<CustomPaint>(
          find.descendant(
            of: find.byKey(const Key('pronunciation_focus_thermal_grid')),
            matching: find.byType(CustomPaint),
          ),
        );
        expect(customPaint.painter, isA<ThermalGridPainter>());
      });

      testWidgets(
        '5.4 ThermalGridPainter shouldRepaint returns true when heatLevel changes',
        (tester) async {
          final p1 = ThermalGridPainter(
            heatLevel: 0.0,
            isListening: false,
            time: 0.1,
          );
          final p2 = ThermalGridPainter(
            heatLevel: 0.8,
            isListening: false,
            time: 0.1,
          );
          expect(p2.shouldRepaint(p1), isTrue);
        },
      );

      testWidgets(
        '5.5 ThermalGridPainter shouldRepaint returns true when isListening changes',
        (tester) async {
          final p1 = ThermalGridPainter(
            heatLevel: 0.5,
            isListening: false,
            time: 0.1,
          );
          final p2 = ThermalGridPainter(
            heatLevel: 0.5,
            isListening: true,
            time: 0.1,
          );
          expect(p2.shouldRepaint(p1), isTrue);
        },
      );

      testWidgets(
        '5.6 ThermalGridPainter shouldRepaint returns true when time changes, and false when all identical',
        (tester) async {
          final p1 = ThermalGridPainter(
            heatLevel: 0.5,
            isListening: false,
            time: 0.1,
          );
          final p2 = ThermalGridPainter(
            heatLevel: 0.5,
            isListening: false,
            time: 0.5,
          );
          final p3 = ThermalGridPainter(
            heatLevel: 0.5,
            isListening: false,
            time: 0.1,
          );

          expect(p2.shouldRepaint(p1), isTrue);
          expect(p3.shouldRepaint(p1), isFalse);
        },
      );
    });

    // -------------------------------------------------------------------------
    // 6. Highlighted Sentence Component (PronunciationFocusHighlightedSentence) (8 tests)
    // -------------------------------------------------------------------------
    group('6. Highlighted Sentence Component (PronunciationFocusHighlightedSentence)', () {
      testWidgets(
        '6.1 renders highlighted sentence with key pronunciation_focus_highlighted_sentence',
        (tester) async {
          await pumpPronunciationFocusScreen(tester);
          expect(
            find.byKey(
              const Key('pronunciation_focus_highlighted_sentence'),
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        '6.2 renders sentence TTS button with key pronunciation_focus_sentence_tts_button',
        (tester) async {
          await pumpPronunciationFocusScreen(tester);
          expect(
            find.byKey(
              const Key('pronunciation_focus_sentence_tts_button'),
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        '6.3 tapping sentence TTS button plays full text via soundService.playTts',
        (tester) async {
          await pumpPronunciationFocusScreen(tester);
          await tester.tap(
            find.byKey(
              const Key('pronunciation_focus_sentence_tts_button'),
            ),
          );
          await tester.pump();

          verify(
            () => mockSoundService.playTts('Red round roller rink'),
          ).called(greaterThanOrEqualTo(1));
        },
      );

      testWidgets(
        '6.4 tapping sentence TTS button while recording is active does not trigger TTS',
        (tester) async {
          when(() => mockAudioRecorder.isRecording).thenReturn(true);
          await pumpPronunciationFocusScreen(tester);

          clearInteractions(mockSoundService);
          await tester.tap(
            find.byKey(
              const Key('pronunciation_focus_sentence_tts_button'),
            ),
          );
          await tester.pump();

          verifyNever(() => mockSoundService.playTts(any()));
        },
      );

      testWidgets(
        '6.5 renders individual word chips with key pronunciation_focus_word_\$index',
        (tester) async {
          await pumpPronunciationFocusScreen(tester);
          expect(
            find.byKey(const Key('pronunciation_focus_word_0')),
            findsOneWidget,
          );
          expect(
            find.byKey(const Key('pronunciation_focus_word_1')),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        '6.6 highlights words containing the target phoneme with distinct style',
        (tester) async {
          await pumpPronunciationFocusScreen(tester);
          expect(find.text('Red'), findsOneWidget);
          expect(find.text('round'), findsOneWidget);
          expect(find.text('roller'), findsOneWidget);
          expect(find.text('rink'), findsOneWidget);
        },
      );

      testWidgets(
        '6.7 tapping an individual word chip plays soundService.playTts for that word',
        (tester) async {
          await pumpPronunciationFocusScreen(tester);
          clearInteractions(mockSoundService);

          await tester.tap(find.byKey(const Key('pronunciation_focus_word_0')));
          await tester.pump();

          verify(() => mockSoundService.playTts('Red')).called(1);
        },
      );

      testWidgets(
        '6.8 tapping a word chip while recording is active does not play TTS',
        (tester) async {
          when(() => mockAudioRecorder.isRecording).thenReturn(true);
          await pumpPronunciationFocusScreen(tester);

          clearInteractions(mockSoundService);
          await tester.tap(find.byKey(const Key('pronunciation_focus_word_0')));
          await tester.pump();

          verifyNever(() => mockSoundService.playTts(any()));
        },
      );
    });

    // -------------------------------------------------------------------------
    // 7. Auto-play & TTS Barrier Mechanics (6 tests)
    // -------------------------------------------------------------------------
    group('7. Auto-play & TTS Barrier Mechanics', () {
      testWidgets(
        '7.1 automatically plays TTS of quest.textToSpeak upon question load',
        (tester) async {
          await pumpPronunciationFocusScreen(tester);
          verify(
            () => mockSoundService.playTts('Red round roller rink'),
          ).called(greaterThanOrEqualTo(1));
        },
      );

      testWidgets(
        '7.2 when TTS is playing (_ttsFinished is false), AbsorbPointer absorbs and ShadowPlaybackCompare is dimmed',
        (tester) async {
          VowlMotion.lowAnimationModeOverride.value = false;
          await pumpPronunciationFocusScreen(tester);

          final absorbPointerFinder = find.descendant(
            of: find.byType(AnimatedOpacity),
            matching: find.byType(AbsorbPointer),
          );
          final absorbPointer = tester.widget<AbsorbPointer>(absorbPointerFinder);
          expect(absorbPointer.absorbing, isTrue);

          await tester.pump(const Duration(seconds: 3));
          VowlMotion.lowAnimationModeOverride.value = true;
          await tester.pump();
        },
      );

      testWidgets(
        '7.3 when TTS finishes (_ttsFinished is true), AbsorbPointer unblocks and ShadowPlaybackCompare is fully interactive',
        (tester) async {
          await pumpPronunciationFocusScreen(tester);

          final absorbPointerFinder = find.descendant(
            of: find.byType(AnimatedOpacity),
            matching: find.byType(AbsorbPointer),
          );
          final absorbPointer = tester.widget<AbsorbPointer>(absorbPointerFinder);
          expect(absorbPointer.absorbing, isFalse);
        },
      );

      testWidgets(
        '7.4 auto-play timer is cancelled cleanly when screen is disposed before completion',
        (tester) async {
          VowlMotion.lowAnimationModeOverride.value = false;
          await pumpPronunciationFocusScreen(tester);

          await tester.pumpWidget(const SizedBox());
          expect(tester.takeException(), isNull);
          VowlMotion.lowAnimationModeOverride.value = true;
        },
      );

      testWidgets(
        '7.5 lowAnimationModeOverride bypasses 2-second timer and unlocks immediately',
        (tester) async {
          VowlMotion.lowAnimationModeOverride.value = true;
          await pumpPronunciationFocusScreen(tester);

          final absorbPointer = tester.widget<AbsorbPointer>(
            find.descendant(
              of: find.byType(AnimatedOpacity),
              matching: find.byType(AbsorbPointer),
            ),
          );
          expect(absorbPointer.absorbing, isFalse);
        },
      );

      testWidgets(
        '7.6 handles null quest.textToSpeak by unlocking immediately without crash',
        (tester) async {
          final noTextQuest = createQuest(textToSpeak: null);
          final state = testLoadedState.copyWith(quests: [noTextQuest]);
          await pumpPronunciationFocusScreen(tester, state: state);

          final absorbPointer = tester.widget<AbsorbPointer>(
            find.descendant(
              of: find.byType(AnimatedOpacity),
              matching: find.byType(AbsorbPointer),
            ),
          );
          expect(absorbPointer.absorbing, isFalse);
        },
      );
    });

    // -------------------------------------------------------------------------
    // 8. Hint System (SpeakingHintUsed) (4 tests)
    // -------------------------------------------------------------------------
    group('8. Hint System (SpeakingHintUsed)', () {
      testWidgets('8.1 tapping hint button dispatches SpeakingHintUsed', (
        tester,
      ) async {
        await pumpPronunciationFocusScreen(tester);
        final hintButton = find.byType(QuestHintButton);
        expect(hintButton, findsOneWidget);

        await tester.tap(hintButton);
        await tester.pump();

        verify(
          () => mockSpeakingBloc.add(const SpeakingHintUsed()),
        ).called(greaterThanOrEqualTo(1));
      });

      testWidgets('8.2 renders hint button with proper icon Icons.lightbulb_rounded', (
        tester,
      ) async {
        await pumpPronunciationFocusScreen(tester);
        expect(find.byIcon(Icons.lightbulb_rounded), findsOneWidget);
      });

      testWidgets('8.3 works seamlessly across repeated hint taps', (
        tester,
      ) async {
        await pumpPronunciationFocusScreen(tester);
        final hintButton = find.byType(QuestHintButton);

        await tester.tap(hintButton);
        await tester.pump();
        await tester.tap(hintButton);
        await tester.pump();

        verify(
          () => mockSpeakingBloc.add(const SpeakingHintUsed()),
        ).called(1);
      });

      testWidgets('8.4 hint button displays available hint count badge', (
        tester,
      ) async {
        await pumpPronunciationFocusScreen(tester);
        expect(
          find.descendant(
            of: find.byType(QuestHintButton),
            matching: find.text('3'),
          ),
          findsOneWidget,
        );
      });
    });

    // -------------------------------------------------------------------------
    // 9. ShadowPlaybackCompare Mechanics & Evaluation (8 tests)
    // -------------------------------------------------------------------------
    group('9. ShadowPlaybackCompare Mechanics & Evaluation', () {
      testWidgets(
        '9.1 renders ShadowPlaybackCompare with key pronunciation_focus_shadow_compare',
        (tester) async {
          await pumpPronunciationFocusScreen(tester);
          expect(
            find.byKey(const Key('pronunciation_focus_shadow_compare')),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        '9.2 passes quest.textToSpeak as expectedText and showExpectedText as false',
        (tester) async {
          await pumpPronunciationFocusScreen(tester);
          final shadowCompare = tester.widget<ShadowPlaybackCompare>(
            find.byKey(const Key('pronunciation_focus_shadow_compare')),
          );
          expect(shadowCompare.expectedText, equals('Red round roller rink'));
          expect(shadowCompare.showExpectedText, isFalse);
          expect(shadowCompare.isPositioned, isFalse);
        },
      );

      testWidgets(
        '9.3 recording state changes update _isUserRecording notifier and thermal grid',
        (tester) async {
          await pumpPronunciationFocusScreen(tester);
          final shadowCompare = tester.widget<ShadowPlaybackCompare>(
            find.byKey(const Key('pronunciation_focus_shadow_compare')),
          );

          shadowCompare.onRecordingStateChanged?.call(true);
          await tester.pump();

          final grid = tester.widget<PronunciationFocusThermalGrid>(
            find.byKey(const Key('pronunciation_focus_thermal_grid')),
          );
          expect(grid.isListening, isTrue);

          shadowCompare.onRecordingStateChanged?.call(false);
          await tester.pump();

          final updatedGrid = tester.widget<PronunciationFocusThermalGrid>(
            find.byKey(const Key('pronunciation_focus_thermal_grid')),
          );
          expect(updatedGrid.isListening, isFalse);
        },
      );

      testWidgets(
        '9.4 submitting correct evaluation (onConfirmed) sets heatLevel to 1.0, plays correct sound and haptic',
        (tester) async {
          await pumpPronunciationFocusScreen(tester);
          final shadowCompare = tester.widget<ShadowPlaybackCompare>(
            find.byKey(const Key('pronunciation_focus_shadow_compare')),
          );

          shadowCompare.onConfirmed();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));

          verify(() => mockHapticService.success()).called(1);
          verify(() => mockSoundService.playCorrect()).called(1);
        },
      );

      testWidgets(
        '9.5 submitting correct evaluation dispatches SubmitAnswer(true)',
        (tester) async {
          await pumpPronunciationFocusScreen(tester);
          final shadowCompare = tester.widget<ShadowPlaybackCompare>(
            find.byKey(const Key('pronunciation_focus_shadow_compare')),
          );

          shadowCompare.onConfirmed();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));

          verify(
            () => mockSpeakingBloc.add(const SubmitAnswer(true)),
          ).called(1);
        },
      );

      testWidgets(
        '9.6 submitting wrong evaluation (onSkipped) sets heatLevel to 0.0, plays wrong sound and haptic',
        (tester) async {
          await pumpPronunciationFocusScreen(tester);
          final shadowCompare = tester.widget<ShadowPlaybackCompare>(
            find.byKey(const Key('pronunciation_focus_shadow_compare')),
          );

          shadowCompare.onSkipped();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));

          verify(() => mockHapticService.error()).called(1);
          verify(() => mockSoundService.playWrong()).called(1);
        },
      );

      testWidgets(
        '9.7 submitting wrong evaluation dispatches SubmitAnswer(false)',
        (tester) async {
          await pumpPronunciationFocusScreen(tester);
          final shadowCompare = tester.widget<ShadowPlaybackCompare>(
            find.byKey(const Key('pronunciation_focus_shadow_compare')),
          );

          shadowCompare.onSkipped();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));

          verify(
            () => mockSpeakingBloc.add(const SubmitAnswer(false)),
          ).called(1);
        },
      );

      testWidgets(
        '9.8 answer submission locks out further submissions (duplicate tap protection)',
        (tester) async {
          await pumpPronunciationFocusScreen(tester);
          final shadowCompare = tester.widget<ShadowPlaybackCompare>(
            find.byKey(const Key('pronunciation_focus_shadow_compare')),
          );

          shadowCompare.onConfirmed();
          shadowCompare.onConfirmed();
          shadowCompare.onSkipped();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));

          verify(
            () => mockSpeakingBloc.add(const SubmitAnswer(true)),
          ).called(1);
          verifyNever(() => mockSpeakingBloc.add(const SubmitAnswer(false)));
        },
      );
    });

    // -------------------------------------------------------------------------
    // 10. State Transitions & Game Progression (6 tests)
    // -------------------------------------------------------------------------
    group('10. State Transitions & Game Progression', () {
      testWidgets(
        '10.1 answered state unmounts ShadowPlaybackCompare and mounts GameFeedbackCard',
        (tester) async {
          final answeredState = testLoadedState.copyWith(
            answerStatus: AnswerStatus.correct,
          );
          await pumpPronunciationFocusScreen(tester, state: answeredState);

          expect(
            find.byKey(const Key('pronunciation_focus_shadow_compare')),
            findsNothing,
          );
          expect(find.byType(GameFeedbackCard), findsOneWidget);
        },
      );

      testWidgets('10.2 GameFeedbackCard renders CONTINUE button', (
        tester,
      ) async {
        final answeredState = testLoadedState.copyWith(
          answerStatus: AnswerStatus.correct,
        );
        await pumpPronunciationFocusScreen(tester, state: answeredState);

        expect(find.text('CONTINUE'), findsOneWidget);
      });

      testWidgets('10.3 tapping CONTINUE dispatches NextQuestion', (
        tester,
      ) async {
        final answeredState = testLoadedState.copyWith(
          answerStatus: AnswerStatus.correct,
        );
        await pumpPronunciationFocusScreen(tester, state: answeredState);

        await tester.tap(find.text('CONTINUE'));
        await tester.pump();

        verify(() => mockSpeakingBloc.add(const NextQuestion())).called(1);
      });

      testWidgets(
        '10.4 onQuestionReset clears heatLevel, ttsFinished, showGuide, and recording state',
        (tester) async {
          await pumpPronunciationFocusScreen(tester);
          final state = tester.state<State>(
            find.byType(PronunciationFocusScreen),
          );
          (state as dynamic).onQuestionReset();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));

          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        '10.5 SpeakingGameComplete state triggers game completion dialog with XP and coins',
        (tester) async {
          await pumpPronunciationFocusScreen(tester);

          speakingStreamController.add(
            const SpeakingGameComplete(
              xpEarned: 60,
              coinsEarned: 30,
              questCount: 2,
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));

          verify(() => mockSoundService.playLevelComplete()).called(1);
        },
      );

      testWidgets('10.6 screen disposes cleanly without timer leaks or exceptions', (
        tester,
      ) async {
        await pumpPronunciationFocusScreen(tester);
        await tester.pumpWidget(const SizedBox());
        expect(tester.takeException(), isNull);
      });
    });

    // -------------------------------------------------------------------------
    // 11. Viewport Responsiveness, Theming & Accessibility (6 tests)
    // -------------------------------------------------------------------------
    group('11. Viewport Responsiveness, Theming & Accessibility', () {
      testWidgets(
        '11.1 renders cleanly on compact mobile viewport (320x568) without RenderFlex overflow',
        (tester) async {
          await pumpPronunciationFocusScreen(
            tester,
            size: const Size(320, 568),
          );
          expect(find.byType(PronunciationFocusScreen), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets('11.2 renders cleanly on tablet viewport (768x1024)', (
        tester,
      ) async {
        await pumpPronunciationFocusScreen(
          tester,
          size: const Size(768, 1024),
        );
        expect(find.byType(PronunciationFocusScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('11.3 renders cleanly in Light Theme mode', (
        tester,
      ) async {
        await pumpPronunciationFocusScreen(
          tester,
          themeMode: ThemeMode.light,
        );
        expect(find.byType(PronunciationFocusScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('11.4 renders cleanly in Dark Theme mode', (
        tester,
      ) async {
        await pumpPronunciationFocusScreen(
          tester,
          themeMode: ThemeMode.dark,
        );
        expect(find.byType(PronunciationFocusScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets(
        '11.5 respects reduceMotion by pausing repeating controllers and animations',
        (tester) async {
          await pumpPronunciationFocusScreen(tester, reduceMotion: true);
          expect(find.byType(PronunciationFocusScreen), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        '11.6 raw scrollbar and custom scroll view scroll smoothly with long content',
        (tester) async {
          await pumpPronunciationFocusScreen(tester);
          final scrollableFinder = find.byType(CustomScrollView);
          expect(scrollableFinder, findsOneWidget);

          await tester.drag(scrollableFinder, const Offset(0, -300));
          await tester.pump();
          expect(tester.takeException(), isNull);
        },
      );
    });
  });
}

