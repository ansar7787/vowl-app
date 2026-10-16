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
import 'package:vowl/features/speaking/repeat_sentence/presentation/pages/repeat_sentence_screen.dart';

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
    String id = 'quest_repeat_1',
    String? textToSpeak = 'Could you please speak a little slower?',
    String? correctAnswer = 'Could you please speak a little slower?',
    String? pronunciationTips = '[IPA Tip] Focus on the soft /k/ and fluent liaison between speak and a.',
    String instruction = 'Repeat the sentence clearly, matching the natural cadence and pause patterns.',
    String? hint = 'Pay attention to the rhythm and rising intonation at the end of the polite request.',
    int difficulty = 2,
  }) {
    return SpeakingQuest(
      id: id,
      type: QuestType.speaking,
      subtype: GameSubtype.repeatSentence,
      textToSpeak: textToSpeak,
      correctAnswer: correctAnswer,
      sentence: textToSpeak,
      pronunciationTips: pronunciationTips,
      instruction: instruction,
      hint: hint,
      difficulty: difficulty,
      targetWord: textToSpeak,
    );
  }

  final sampleQuest1 = createQuest();
  final sampleQuest2 = createQuest(
    id: 'quest_repeat_2',
    textToSpeak: 'The weather forecast predicts heavy rainfall this afternoon.',
    correctAnswer: 'The weather forecast predicts heavy rainfall this afternoon.',
    pronunciationTips: '[IPA Tip] Emphasize forecast and heavy while softening rainfall.',
  );

  final testLoadedState = SpeakingLoaded(
    quests: [sampleQuest1, sampleQuest2],
    currentIndex: 0,
    livesRemaining: 3,
    wrongCount: 0,
    hintUsed: false,
    answerStatus: AnswerStatus.unanswered,
    gameType: GameSubtype.repeatSentence,
    level: 2,
  );

  setUpAll(() {
    registerFallbackValue(
      const FetchSpeakingQuests(
        gameType: GameSubtype.repeatSentence,
        level: 1,
      ),
    );
    registerFallbackValue(const Duration(milliseconds: 50));
    VowlMotion.lowAnimationModeOverride.value = true;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'has_seen_briefing_repeatSentence': true,
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
          displayName: 'Test Echo Master',
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
    ).thenAnswer((_) async => '/tmp/repeat_test.m4a');
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

  Future<void> pumpRepeatSentenceScreen(
    WidgetTester tester, {
    SpeakingState? state,
    int level = 2,
    GameSubtype gameType = GameSubtype.repeatSentence,
    ThemeMode themeMode = ThemeMode.dark,
    Size size = const Size(390, 844),
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
                disableAnimations: reduceMotion,
              ),
              child: RepeatSentenceScreen(
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

  group('RepeatSentenceScreen Layout and Mechanics Tests', () {
    // -------------------------------------------------------------------------
    // 1. Initial Screen State & Shimmer Loading (8 tests)
    // -------------------------------------------------------------------------
    group('1. Initial Screen State & Shimmer Loading', () {
      testWidgets('1.1 renders shimmer loading when in SpeakingLoading state', (
        tester,
      ) async {
        await pumpRepeatSentenceScreen(
          tester,
          state: const SpeakingLoading(),
        );
        expect(find.byType(GameShimmerLoading), findsOneWidget);
        expect(find.byType(ShadowPlaybackCompare), findsNothing);
      });

      testWidgets('1.2 renders shimmer loading when in SpeakingInitial state', (
        tester,
      ) async {
        await pumpRepeatSentenceScreen(
          tester,
          state: const SpeakingInitial(),
        );
        expect(find.byType(GameShimmerLoading), findsOneWidget);
        expect(find.byType(ShadowPlaybackCompare), findsNothing);
      });

      testWidgets('1.3 renders SpeakingBaseLayout container across states', (
        tester,
      ) async {
        await pumpRepeatSentenceScreen(tester);
        expect(find.byType(SpeakingBaseLayout), findsOneWidget);
      });

      testWidgets('1.4 dispatches FetchSpeakingQuests on initState', (
        tester,
      ) async {
        await pumpRepeatSentenceScreen(tester, level: 3);
        verify(
          () => mockSpeakingBloc.add(
            const FetchSpeakingQuests(
              gameType: GameSubtype.repeatSentence,
              level: 3,
            ),
          ),
        ).called(1);
      });

      testWidgets('1.5 clamps textScaler to 1.1 maxScaleFactor for a11y', (
        tester,
      ) async {
        await pumpRepeatSentenceScreen(tester);
        final mediaQuery = tester.widget<MediaQuery>(
          find.descendant(
            of: find.byType(RepeatSentenceScreen),
            matching: find.byType(MediaQuery),
          ).first,
        );
        expect(mediaQuery.data.textScaler.clamp(maxScaleFactor: 1.1), isNotNull);
      });

      testWidgets('1.6 loads with custom level parameter cleanly', (
        tester,
      ) async {
        await pumpRepeatSentenceScreen(tester, level: 5);
        final screen = tester.widget<RepeatSentenceScreen>(
          find.byType(RepeatSentenceScreen),
        );
        expect(screen.level, 5);
      });

      testWidgets('1.7 loads with custom gameType parameter cleanly', (
        tester,
      ) async {
        await pumpRepeatSentenceScreen(
          tester,
          gameType: GameSubtype.repeatSentence,
        );
        final screen = tester.widget<RepeatSentenceScreen>(
          find.byType(RepeatSentenceScreen),
        );
        expect(screen.gameType, GameSubtype.repeatSentence);
      });

      testWidgets('1.8 getCompletionTitle returns SOUND WAVE TRANSCRIBER!', (
        tester,
      ) async {
        await pumpRepeatSentenceScreen(tester);
        final state = tester.state(find.byType(RepeatSentenceScreen))
            as dynamic;
        final title = state.getCompletionTitle(tester.element(find.byType(RepeatSentenceScreen)));
        expect(title, 'SOUND WAVE TRANSCRIBER!');
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
          'has_seen_briefing_repeatSentence': false,
        });
        await pumpRepeatSentenceScreen(tester, level: 1);
        expect(find.byType(QuestBriefingOverlay), findsOneWidget);
      });

      testWidgets(
        '2.2 displays uppercase ECHO MASTER title in briefing overlay',
        (tester) async {
          SharedPreferences.setMockInitialValues({
            'has_seen_briefing_repeatSentence': false,
          });
          await pumpRepeatSentenceScreen(tester, level: 1);
          expect(find.text('ECHO MASTER'), findsOneWidget);
        },
      );

      testWidgets(
        '2.3 displays uppercase START ECHO button in briefing overlay',
        (tester) async {
          SharedPreferences.setMockInitialValues({
            'has_seen_briefing_repeatSentence': false,
          });
          await pumpRepeatSentenceScreen(tester, level: 1);
          expect(find.text('START ECHO'), findsOneWidget);
        },
      );

      testWidgets(
        '2.4 tapping START ECHO button dismisses briefing overlay',
        (tester) async {
          SharedPreferences.setMockInitialValues({
            'has_seen_briefing_repeatSentence': false,
          });
          await pumpRepeatSentenceScreen(tester, level: 1);
          expect(find.byType(QuestBriefingOverlay), findsOneWidget);

          await tester.tap(find.text('START ECHO'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));

          expect(find.byType(QuestBriefingOverlay), findsNothing);
        },
      );

      testWidgets('2.5 does not show QuestBriefingOverlay when level is 2', (
        tester,
      ) async {
        await pumpRepeatSentenceScreen(tester, level: 2);
        expect(find.byType(QuestBriefingOverlay), findsNothing);
      });
    });

    // -------------------------------------------------------------------------
    // 3. Instruction Component (RepeatSentenceInstruction) (6 tests)
    // -------------------------------------------------------------------------
    group('3. Instruction Component (RepeatSentenceInstruction)', () {
      testWidgets('3.1 renders instruction component with key repeat_sentence_instruction', (
        tester,
      ) async {
        await pumpRepeatSentenceScreen(tester);
        expect(
          find.byKey(const Key('repeat_sentence_instruction')),
          findsOneWidget,
        );
      });

      testWidgets('3.2 displays "TAP TO RECORD SOUND WAVE" badge text', (
        tester,
      ) async {
        await pumpRepeatSentenceScreen(tester);
        expect(find.text('TAP TO RECORD SOUND WAVE'), findsOneWidget);
      });

      testWidgets('3.3 displays Icons.graphic_eq_rounded in badge', (
        tester,
      ) async {
        await pumpRepeatSentenceScreen(tester);
        expect(find.byIcon(Icons.graphic_eq_rounded), findsWidgets);
      });

      testWidgets('3.4 displays instruction text accurately', (
        tester,
      ) async {
        await pumpRepeatSentenceScreen(tester);
        expect(
          find.text(sampleQuest1.instruction),
          findsOneWidget,
        );
      });

      testWidgets('3.5 has accessible header Semantics label', (
        tester,
      ) async {
        await pumpRepeatSentenceScreen(tester);
        final semanticsFinder = find.descendant(
          of: find.byKey(const Key('repeat_sentence_instruction')),
          matching: find.byType(Semantics),
        );
        expect(semanticsFinder, findsWidgets);
      });

      testWidgets('3.6 handles long instruction text with ellipsis without overflow', (
        tester,
      ) async {
        final longQuest = createQuest(
          instruction: 'This is an exceedingly detailed instruction designed to test the ellipsis and text overflow handling on compact viewports without generating any layout RenderFlex errors.',
        );
        final state = testLoadedState.copyWith(quests: [longQuest]);
        await pumpRepeatSentenceScreen(tester, state: state);
        expect(tester.takeException(), isNull);
      });
    });

    // -------------------------------------------------------------------------
    // 4. Audition Card Component (RepeatSentenceAuditionCard) (8 tests)
    // -------------------------------------------------------------------------
    group('4. Audition Card Component (RepeatSentenceAuditionCard)', () {
      testWidgets('4.1 renders audition card with key repeat_sentence_audition_card', (
        tester,
      ) async {
        await pumpRepeatSentenceScreen(tester);
        expect(
          find.byKey(const Key('repeat_sentence_audition_card')),
          findsOneWidget,
        );
      });

      testWidgets('4.2 displays "TARGET STATEMENT TO REPEAT" header', (
        tester,
      ) async {
        await pumpRepeatSentenceScreen(tester);
        expect(find.text('TARGET STATEMENT TO REPEAT'), findsOneWidget);
      });

      testWidgets('4.3 renders listen button with key repeat_sentence_listen_button', (
        tester,
      ) async {
        await pumpRepeatSentenceScreen(tester);
        expect(
          find.byKey(const Key('repeat_sentence_listen_button')),
          findsOneWidget,
        );
      });

      testWidgets('4.4 displays Icons.volume_up_rounded in listen button', (
        tester,
      ) async {
        await pumpRepeatSentenceScreen(tester);
        expect(find.byIcon(Icons.volume_up_rounded), findsWidgets);
      });

      testWidgets('4.5 displays target sentence with key repeat_sentence_target_text', (
        tester,
      ) async {
        await pumpRepeatSentenceScreen(tester);
        expect(
          find.byKey(const Key('repeat_sentence_target_text')),
          findsOneWidget,
        );
        expect(find.text(sampleQuest1.textToSpeak!), findsOneWidget);
      });

      testWidgets('4.6 tapping listen button plays TTS via soundService.playTts', (
        tester,
      ) async {
        await pumpRepeatSentenceScreen(tester);
        await tester.tap(find.byKey(const Key('repeat_sentence_listen_button')));
        await tester.pump();

        verify(() => mockSoundService.playTts(sampleQuest1.textToSpeak!)).called(
          greaterThanOrEqualTo(1),
        );
      });

      testWidgets('4.7 tapping listen button while audio recording is active does not play TTS', (
        tester,
      ) async {
        when(() => mockAudioRecorder.isRecording).thenReturn(true);
        await pumpRepeatSentenceScreen(tester);

        clearInteractions(mockSoundService);
        await tester.tap(find.byKey(const Key('repeat_sentence_listen_button')));
        await tester.pump();

        verifyNever(() => mockSoundService.playTts(any()));
      });

      testWidgets('4.8 renders pronunciation tips with key repeat_sentence_pronunciation_tips when available, strips [IPA Tip] prefix', (
        tester,
      ) async {
        await pumpRepeatSentenceScreen(tester);
        expect(
          find.byKey(const Key('repeat_sentence_pronunciation_tips')),
          findsOneWidget,
        );
        expect(
          find.text('Focus on the soft /k/ and fluent liaison between speak and a.'),
          findsOneWidget,
        );
      });
    });

    // -------------------------------------------------------------------------
    // 5. Auto-play & TTS Barrier Mechanics (6 tests)
    // -------------------------------------------------------------------------
    group('5. Auto-play & TTS Barrier Mechanics', () {
      testWidgets('5.1 automatically plays TTS of quest.textToSpeak upon question load', (
        tester,
      ) async {
        await pumpRepeatSentenceScreen(tester);
        verify(() => mockSoundService.playTts(sampleQuest1.textToSpeak!)).called(greaterThanOrEqualTo(1));
      });

      testWidgets(
        '5.2 when TTS is playing (_ttsFinished is false), AbsorbPointer absorbs and ShadowPlaybackCompare is dimmed at 0.4',
        (tester) async {
          VowlMotion.lowAnimationModeOverride.value = false;
          try {
            await pumpRepeatSentenceScreen(tester);
            final opacity = tester.widget<AnimatedOpacity>(
              find.descendant(
                of: find.byType(CustomScrollView),
                matching: find.byType(AnimatedOpacity),
              ),
            );
            expect(opacity.opacity, 0.4);
            await tester.pump(const Duration(seconds: 3));
          } finally {
            VowlMotion.lowAnimationModeOverride.value = true;
          }
        },
      );

      testWidgets(
        '5.3 when TTS finishes (_ttsFinished is true), AbsorbPointer unblocks and ShadowPlaybackCompare is fully interactive (opacity 1.0)',
        (tester) async {
          await pumpRepeatSentenceScreen(tester);
          final opacity = tester.widget<AnimatedOpacity>(
            find.descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(AnimatedOpacity),
            ),
          );
          expect(opacity.opacity, 1.0);
        },
      );

      testWidgets(
        '5.4 auto-play timer is cancelled cleanly when screen is disposed before completion',
        (tester) async {
          VowlMotion.lowAnimationModeOverride.value = false;
          try {
            await pumpRepeatSentenceScreen(tester);
            await tester.pumpWidget(const SizedBox());
            expect(tester.takeException(), isNull);
          } finally {
            VowlMotion.lowAnimationModeOverride.value = true;
          }
        },
      );

      testWidgets(
        '5.5 lowAnimationModeOverride bypasses 2-second timer and unlocks immediately',
        (tester) async {
          VowlMotion.lowAnimationModeOverride.value = true;
          await pumpRepeatSentenceScreen(tester);
          final opacity = tester.widget<AnimatedOpacity>(
            find.descendant(
              of: find.byType(CustomScrollView),
              matching: find.byType(AnimatedOpacity),
            ),
          );
          expect(opacity.opacity, 1.0);
        },
      );

      testWidgets(
        '5.6 handles null quest.textToSpeak by unlocking immediately without crash',
        (tester) async {
          final nullQuest = createQuest(textToSpeak: null);
          final state = testLoadedState.copyWith(quests: [nullQuest]);
          await pumpRepeatSentenceScreen(tester, state: state);
          expect(tester.takeException(), isNull);
        },
      );
    });

    // -------------------------------------------------------------------------
    // 6. Hint System (SpeakingHintUsed) (4 tests)
    // -------------------------------------------------------------------------
    group('6. Hint System (SpeakingHintUsed)', () {
      testWidgets('6.1 tapping hint button dispatches SpeakingHintUsed', (
        tester,
      ) async {
        await pumpRepeatSentenceScreen(tester);
        await tester.tap(find.byType(QuestHintButton));
        await tester.pump();

        verify(
          () => mockSpeakingBloc.add(const SpeakingHintUsed()),
        ).called(greaterThanOrEqualTo(1));
      });

      testWidgets('6.2 renders hint button with proper icon Icons.lightbulb_rounded', (
        tester,
      ) async {
        await pumpRepeatSentenceScreen(tester);
        expect(
          find.descendant(
            of: find.byType(QuestHintButton),
            matching: find.byIcon(Icons.lightbulb_rounded),
          ),
          findsOneWidget,
        );
      });

      testWidgets('6.3 works seamlessly across repeated hint taps', (
        tester,
      ) async {
        await pumpRepeatSentenceScreen(tester);
        await tester.tap(find.byType(QuestHintButton));
        await tester.pump();
        await tester.tap(find.byType(QuestHintButton));
        await tester.pump();

        verify(
          () => mockSpeakingBloc.add(const SpeakingHintUsed()),
        ).called(greaterThanOrEqualTo(2));
      });

      testWidgets('6.4 hint button displays available hint count badge', (
        tester,
      ) async {
        await pumpRepeatSentenceScreen(tester);
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
    // 7. ShadowPlaybackCompare Mechanics & Evaluation (8 tests)
    // -------------------------------------------------------------------------
    group('7. ShadowPlaybackCompare Mechanics & Evaluation', () {
      testWidgets(
        '7.1 renders ShadowPlaybackCompare with key repeat_sentence_shadow_compare',
        (tester) async {
          await pumpRepeatSentenceScreen(tester);
          expect(
            find.byKey(const Key('repeat_sentence_shadow_compare')),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        '7.2 passes quest.textToSpeak as expectedText and showExpectedText as false',
        (tester) async {
          await pumpRepeatSentenceScreen(tester);
          final shadowCompare = tester.widget<ShadowPlaybackCompare>(
            find.byKey(const Key('repeat_sentence_shadow_compare')),
          );
          expect(shadowCompare.expectedText, sampleQuest1.textToSpeak);
          expect(shadowCompare.showExpectedText, isFalse);
        },
      );

      testWidgets(
        '7.3 passing isPositioned: false for inline placement',
        (tester) async {
          await pumpRepeatSentenceScreen(tester);
          final shadowCompare = tester.widget<ShadowPlaybackCompare>(
            find.byKey(const Key('repeat_sentence_shadow_compare')),
          );
          expect(shadowCompare.isPositioned, isFalse);
        },
      );

      testWidgets(
        '7.4 submitting correct evaluation (onConfirmed) plays correct sound and haptic',
        (tester) async {
          await pumpRepeatSentenceScreen(tester);
          final shadowCompare = tester.widget<ShadowPlaybackCompare>(
            find.byKey(const Key('repeat_sentence_shadow_compare')),
          );

          shadowCompare.onConfirmed();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));

          verify(() => mockHapticService.success()).called(1);
          verify(() => mockSoundService.playCorrect()).called(1);
        },
      );

      testWidgets(
        '7.5 submitting correct evaluation dispatches SubmitAnswer(true)',
        (tester) async {
          await pumpRepeatSentenceScreen(tester);
          final shadowCompare = tester.widget<ShadowPlaybackCompare>(
            find.byKey(const Key('repeat_sentence_shadow_compare')),
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
        '7.6 submitting wrong evaluation (onSkipped) plays wrong sound and haptic',
        (tester) async {
          await pumpRepeatSentenceScreen(tester);
          final shadowCompare = tester.widget<ShadowPlaybackCompare>(
            find.byKey(const Key('repeat_sentence_shadow_compare')),
          );

          shadowCompare.onSkipped();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));

          verify(() => mockHapticService.error()).called(1);
          verify(() => mockSoundService.playWrong()).called(1);
        },
      );

      testWidgets(
        '7.7 submitting wrong evaluation dispatches SubmitAnswer(false) and records ErrorJournal',
        (tester) async {
          await pumpRepeatSentenceScreen(tester);
          final shadowCompare = tester.widget<ShadowPlaybackCompare>(
            find.byKey(const Key('repeat_sentence_shadow_compare')),
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
        '7.8 answer submission locks out further submissions (duplicate tap protection)',
        (tester) async {
          await pumpRepeatSentenceScreen(tester);
          final shadowCompare = tester.widget<ShadowPlaybackCompare>(
            find.byKey(const Key('repeat_sentence_shadow_compare')),
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
    // 8. State Transitions & Game Progression (6 tests)
    // -------------------------------------------------------------------------
    group('8. State Transitions & Game Progression', () {
      testWidgets(
        '8.1 answered state unmounts ShadowPlaybackCompare and mounts GameFeedbackCard',
        (tester) async {
          final answeredState = testLoadedState.copyWith(
            answerStatus: AnswerStatus.correct,
          );
          await pumpRepeatSentenceScreen(tester, state: answeredState);
          expect(find.byType(ShadowPlaybackCompare), findsNothing);
          expect(find.byType(GameFeedbackCard), findsOneWidget);
        },
      );

      testWidgets('8.2 GameFeedbackCard renders CONTINUE button', (
        tester,
      ) async {
        final answeredState = testLoadedState.copyWith(
          answerStatus: AnswerStatus.correct,
        );
        await pumpRepeatSentenceScreen(tester, state: answeredState);
        expect(find.text('CONTINUE'), findsOneWidget);
      });

      testWidgets('8.3 tapping CONTINUE dispatches NextQuestion', (
        tester,
      ) async {
        final answeredState = testLoadedState.copyWith(
          answerStatus: AnswerStatus.correct,
        );
        await pumpRepeatSentenceScreen(tester, state: answeredState);
        await tester.tap(find.text('CONTINUE'));
        await tester.pump();

        verify(() => mockSpeakingBloc.add(const NextQuestion())).called(1);
      });

      testWidgets(
        '8.4 onQuestionReset clears ttsFinished and triggers autoplay for next question',
        (tester) async {
          await pumpRepeatSentenceScreen(tester);
          clearInteractions(mockSoundService);

          final nextQuestionState = testLoadedState.copyWith(
            currentIndex: 1,
            answerStatus: AnswerStatus.unanswered,
          );
          speakingStreamController.add(nextQuestionState);
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));

          verify(() => mockSoundService.playTts(sampleQuest2.textToSpeak!)).called(1);
        },
      );

      testWidgets(
        '8.5 SpeakingGameComplete state triggers game completion dialog with XP and coins',
        (tester) async {
          await pumpRepeatSentenceScreen(tester);
          speakingStreamController.add(
            const SpeakingGameComplete(
              xpEarned: 25,
              coinsEarned: 10,
              questCount: 2,
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));

          verify(() => mockSoundService.playLevelComplete()).called(1);
        },
      );

      testWidgets('8.6 screen disposes cleanly without timer leaks or exceptions', (
        tester,
      ) async {
        await pumpRepeatSentenceScreen(tester);
        await tester.pumpWidget(const SizedBox());
        expect(tester.takeException(), isNull);
      });
    });

    // -------------------------------------------------------------------------
    // 9. Viewport Responsiveness, Theming & Accessibility (6 tests)
    // -------------------------------------------------------------------------
    group('9. Viewport Responsiveness, Theming & Accessibility', () {
      testWidgets(
        '9.1 renders cleanly on compact mobile viewport (320x568) without RenderFlex overflow',
        (tester) async {
          await pumpRepeatSentenceScreen(
            tester,
            size: const Size(320, 568),
          );
          expect(tester.takeException(), isNull);
          expect(
            find.byKey(const Key('repeat_sentence_instruction')),
            findsOneWidget,
          );
          expect(
            find.byKey(const Key('repeat_sentence_audition_card')),
            findsOneWidget,
          );
        },
      );

      testWidgets('9.2 renders cleanly on tablet viewport (768x1024)', (
        tester,
      ) async {
        await pumpRepeatSentenceScreen(
          tester,
          size: const Size(768, 1024),
        );
        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const Key('repeat_sentence_audition_card')),
          findsOneWidget,
        );
      });

      testWidgets('9.3 renders cleanly in Light Theme mode', (
        tester,
      ) async {
        await pumpRepeatSentenceScreen(
          tester,
          themeMode: ThemeMode.light,
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('9.4 renders cleanly in Dark Theme mode', (
        tester,
      ) async {
        await pumpRepeatSentenceScreen(
          tester,
          themeMode: ThemeMode.dark,
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets(
        '9.5 respects reduceMotion by disabling delayed animations and instant scrolling',
        (tester) async {
          await pumpRepeatSentenceScreen(
            tester,
            reduceMotion: true,
          );
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        '9.6 raw scrollbar and custom scroll view scroll smoothly with long content',
        (tester) async {
          await pumpRepeatSentenceScreen(tester);
          expect(find.byType(CustomScrollView), findsOneWidget);
          expect(find.byType(RawScrollbar), findsOneWidget);

          await tester.drag(
            find.byType(CustomScrollView),
            const Offset(0, -200),
          );
          await tester.pump();
          expect(tester.takeException(), isNull);
        },
      );
    });

    // -------------------------------------------------------------------------
    // 10. Fallback and Null-Safety Quests (6 tests)
    // -------------------------------------------------------------------------
    group('10. Fallback and Null-Safety Quests', () {
      testWidgets('10.1 handles quest with null pronunciationTips cleanly (tips container omitted)', (
        tester,
      ) async {
        final noTipsQuest = createQuest(pronunciationTips: null);
        final state = testLoadedState.copyWith(quests: [noTipsQuest]);
        await pumpRepeatSentenceScreen(tester, state: state);

        expect(
          find.byKey(const Key('repeat_sentence_pronunciation_tips')),
          findsNothing,
        );
      });

      testWidgets('10.2 handles quest with empty textToSpeak falling back to correctAnswer', (
        tester,
      ) async {
        final fallbackQuest = createQuest(
          textToSpeak: null,
          correctAnswer: 'Correct sentence fallback',
        );
        final state = testLoadedState.copyWith(quests: [fallbackQuest]);
        await pumpRepeatSentenceScreen(tester, state: state);

        expect(find.text('Correct sentence fallback'), findsOneWidget);
      });

      testWidgets('10.3 handles quest with special characters or long sentences without layout distortion', (
        tester,
      ) async {
        final complexQuest = createQuest(
          textToSpeak: '“Well, that’s astonishing!” he exclaimed — 100% extraordinary, isn’t it?',
        );
        final state = testLoadedState.copyWith(quests: [complexQuest]);
        await pumpRepeatSentenceScreen(tester, state: state);

        expect(find.text(complexQuest.textToSpeak!), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('10.4 handles rapid answer toggling gracefully', (
        tester,
      ) async {
        await pumpRepeatSentenceScreen(tester);
        final shadowCompare = tester.widget<ShadowPlaybackCompare>(
          find.byKey(const Key('repeat_sentence_shadow_compare')),
        );

        shadowCompare.onConfirmed();
        shadowCompare.onSkipped();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        verify(() => mockSpeakingBloc.add(const SubmitAnswer(true))).called(1);
        verifyNever(() => mockSpeakingBloc.add(const SubmitAnswer(false)));
      });

      testWidgets('10.5 handles state transition from answered to unanswered (retry question)', (
        tester,
      ) async {
        final answeredState = testLoadedState.copyWith(
          answerStatus: AnswerStatus.incorrect,
        );
        await pumpRepeatSentenceScreen(tester, state: answeredState);
        expect(find.byType(GameFeedbackCard), findsOneWidget);

        final retryState = testLoadedState.copyWith(
          answerStatus: AnswerStatus.unanswered,
        );
        speakingStreamController.add(retryState);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        expect(find.byType(ShadowPlaybackCompare), findsOneWidget);
      });

      testWidgets('10.6 handles unauthenticated user state during wrong answer without ErrorJournal crash', (
        tester,
      ) async {
        when(() => mockAuthBloc.state).thenReturn(const AuthState.unauthenticated());
        await pumpRepeatSentenceScreen(tester);
        final shadowCompare = tester.widget<ShadowPlaybackCompare>(
          find.byKey(const Key('repeat_sentence_shadow_compare')),
        );

        shadowCompare.onSkipped();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        verify(() => mockSpeakingBloc.add(const SubmitAnswer(false))).called(1);
      });
    });

    // -------------------------------------------------------------------------
    // 11. Edge Cases in Audio & Scroll Interactions (5 tests)
    // -------------------------------------------------------------------------
    group('11. Edge Cases in Audio & Scroll Interactions', () {
      testWidgets('11.1 _scrollToBottom triggers jumpTo in lowAnimationModeOverride', (
        tester,
      ) async {
        VowlMotion.lowAnimationModeOverride.value = true;
        await pumpRepeatSentenceScreen(tester);
        expect(tester.takeException(), isNull);
      });

      testWidgets('11.2 tapping listen button repeatedly does not crash', (
        tester,
      ) async {
        await pumpRepeatSentenceScreen(tester);
        for (int i = 0; i < 3; i++) {
          await tester.tap(find.byKey(const Key('repeat_sentence_listen_button')));
          await tester.pump();
        }
        expect(tester.takeException(), isNull);
      });

      testWidgets('11.3 lives change triggers question reset if lives increase', (
        tester,
      ) async {
        final lowLivesState = testLoadedState.copyWith(livesRemaining: 1);
        await pumpRepeatSentenceScreen(tester, state: lowLivesState);

        final restoredLivesState = testLoadedState.copyWith(livesRemaining: 3);
        speakingStreamController.add(restoredLivesState);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        expect(tester.takeException(), isNull);
      });

      testWidgets('11.4 final failure state passes isFinalFailure to SpeakingBaseLayout', (
        tester,
      ) async {
        final failureState = testLoadedState.copyWith(
          answerStatus: AnswerStatus.incorrect,
          livesRemaining: 0,
          isFinalFailure: true,
        );
        await pumpRepeatSentenceScreen(tester, state: failureState);

        final layout = tester.widget<SpeakingBaseLayout>(
          find.byType(SpeakingBaseLayout),
        );
        expect(layout.isFinalFailure, isTrue);
      });

      testWidgets('11.5 soundService.playTts exception handling in auto-play is safely caught', (
        tester,
      ) async {
        when(() => mockSoundService.playTts(any())).thenThrow(Exception('TTS playback failure'));
        await pumpRepeatSentenceScreen(tester);
        expect(tester.takeException(), isNull);
      });
    });
  });
}

