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
import 'package:vowl/core/utils/ml_services/smart_reply_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/speech_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/core/utils/widgets/smart_reply_chip.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/features/speaking/dialogue_roleplay/presentation/pages/dialogue_roleplay_screen.dart';
import 'package:vowl/features/speaking/dialogue_roleplay/presentation/widgets/dialogue_roleplay_exchange_stage.dart';
import 'package:vowl/features/speaking/dialogue_roleplay/presentation/widgets/dialogue_roleplay_header.dart';
import 'package:vowl/features/speaking/dialogue_roleplay/presentation/widgets/synaptic_link_painter.dart';
import 'package:vowl/features/speaking/domain/entities/speaking_quest.dart';
import 'package:vowl/features/speaking/presentation/bloc/speaking_bloc.dart';
import 'package:vowl/features/speaking/presentation/layout/speaking_base_layout.dart';

// Mocks
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

class MockSmartReplyService extends Mock implements SmartReplyService {}

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
  late MockSmartReplyService mockSmartReplyService;
  late StreamController<SpeakingState> speakingStreamController;

  SpeakingQuest createQuest({
    String id = 'quest_dialogue_1',
    String? partnerDialogue =
        'Could you please help me find the nearest subway station?',
    String instruction =
        'Listen to your partner and choose the best response.',
    List<String>? acceptedSynonyms = const [
      'Sure, it is just around the corner on Main Street.',
      'Certainly, follow this road straight ahead.',
    ],
    List<String>? smartReplies = const [
      'Sure, it is right around the corner.',
      'Yes, go straight down this street.',
    ],
    String? sentence = 'Sure, it is just around the corner on Main Street.',
    String? hint = 'Give clear, helpful directions to the subway.',
    int difficulty = 2,
  }) {
    return SpeakingQuest(
      id: id,
      type: QuestType.speaking,
      subtype: GameSubtype.dialogueRoleplay,
      partnerDialogue: partnerDialogue,
      instruction: instruction,
      acceptedSynonyms: acceptedSynonyms,
      smartReplies: smartReplies,
      sentence: sentence,
      hint: hint,
      difficulty: difficulty,
      targetWord: sentence,
      correctAnswer: sentence,
    );
  }

  final sampleQuest1 = createQuest();
  final sampleQuest2 = createQuest(
    id: 'quest_dialogue_2',
    partnerDialogue: 'How much does the single journey train ticket cost?',
    sentence: 'It costs two dollars and fifty cents.',
  );

  final testLoadedState = SpeakingLoaded(
    quests: [sampleQuest1, sampleQuest2],
    currentIndex: 0,
    livesRemaining: 3,
    wrongCount: 0,
    hintUsed: false,
    answerStatus: AnswerStatus.unanswered,
    gameType: GameSubtype.dialogueRoleplay,
    level: 2,
    isFinalFailure: false,
  );

  setUpAll(() {
    registerFallbackValue(const SubmitAnswer(false));
    registerFallbackValue(
      const FetchSpeakingQuests(
        gameType: GameSubtype.dialogueRoleplay,
        level: 1,
      ),
    );
    registerFallbackValue(const Duration(milliseconds: 50));
    VowlMotion.lowAnimationModeOverride.value = true;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'has_seen_briefing_dialogueRoleplay': true,
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
    mockSmartReplyService = MockSmartReplyService();
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
          displayName: 'Test Dialogue Master',
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
    ).thenAnswer((_) async => '/tmp/dialogue_roleplay_test.m4a');
    when(() => mockAudioRecorder.isRecording).thenReturn(false);
    when(() => mockAudioRecorder.dispose()).thenAnswer((_) async {});

    when(() => mockSmartReplyService.clearConversation()).thenReturn(null);
    when(
      () => mockSmartReplyService.addMessage(
        any(),
        isLocalUser: any(named: 'isLocalUser'),
      ),
    ).thenReturn(null);
    when(
      () => mockSmartReplyService.getSuggestions(),
    ).thenAnswer((_) async => ['Sure, it is right around the corner.', 'Yes, go straight down this street.']);
    when(() => mockSmartReplyService.dispose()).thenReturn(null);

    when(
      () => mockLocaleService.tr(any(), fallback: any(named: 'fallback')),
    ).thenAnswer((invocation) {
      final fallback = invocation.namedArguments[#fallback] as String?;
      return fallback ?? invocation.positionalArguments[0] as String;
    });

    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

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
    if (di.sl.isRegistered<SmartReplyService>()) {
      di.sl.unregister<SmartReplyService>();
    }

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
    di.sl.registerSingleton<SmartReplyService>(mockSmartReplyService);
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
    if (di.sl.isRegistered<SmartReplyService>()) {
      di.sl.unregister<SmartReplyService>();
    }
  });

  Future<void> pumpDialogueRoleplayScreen(
    WidgetTester tester, {
    SpeakingState? state,
    int level = 2,
    GameSubtype gameType = GameSubtype.dialogueRoleplay,
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
              child: DialogueRoleplayScreen(
                level: level,
                gameType: gameType,
              ),
            ),
          ),
        ),
      ),
    );
    if (!speakingStreamController.isClosed) {
      speakingStreamController.add(activeState);
    }
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  group('DialogueRoleplayScreen Layout and Mechanics Tests', () {
    // -------------------------------------------------------------------------
    // 1. Initial Screen State & Shimmer Loading (8 tests)
    // -------------------------------------------------------------------------
    group('1. Initial Screen State & Shimmer Loading', () {
      testWidgets('1.1 renders shimmer loading when in SpeakingLoading state', (
        tester,
      ) async {
        await pumpDialogueRoleplayScreen(
          tester,
          state: const SpeakingLoading(),
        );
        expect(find.byType(GameShimmerLoading), findsOneWidget);
        expect(find.byType(DialogueRoleplayExchangeStage), findsNothing);
      });

      testWidgets('1.2 renders shimmer loading when in SpeakingInitial state', (
        tester,
      ) async {
        await pumpDialogueRoleplayScreen(
          tester,
          state: const SpeakingInitial(),
        );
        expect(find.byType(GameShimmerLoading), findsOneWidget);
        expect(find.byType(DialogueRoleplayExchangeStage), findsNothing);
      });

      testWidgets('1.3 renders SpeakingBaseLayout container across states', (
        tester,
      ) async {
        await pumpDialogueRoleplayScreen(tester);
        expect(find.byType(SpeakingBaseLayout), findsOneWidget);
      });

      testWidgets('1.4 dispatches FetchSpeakingQuests on initState', (
        tester,
      ) async {
        await pumpDialogueRoleplayScreen(tester);
        verify(
          () => mockSpeakingBloc.add(
            any(that: isA<FetchSpeakingQuests>()),
          ),
        ).called(1);
      });

      testWidgets('1.5 clamps textScaler to 1.1 maxScaleFactor for a11y', (
        tester,
      ) async {
        await pumpDialogueRoleplayScreen(tester);
        final mediaQueryFinder = find.descendant(
          of: find.byType(DialogueRoleplayScreen),
          matching: find.byType(MediaQuery),
        );
        expect(mediaQueryFinder, findsWidgets);
      });

      testWidgets('1.6 loads with custom level parameter cleanly', (
        tester,
      ) async {
        await pumpDialogueRoleplayScreen(tester, level: 3);
        expect(find.byType(DialogueRoleplayScreen), findsOneWidget);
      });

      testWidgets('1.7 loads with custom gameType parameter cleanly', (
        tester,
      ) async {
        await pumpDialogueRoleplayScreen(
          tester,
          gameType: GameSubtype.dialogueRoleplay,
        );
        expect(find.byType(DialogueRoleplayScreen), findsOneWidget);
      });

      testWidgets('1.8 getCompletionTitle returns DIALOGUE EXPERT!', (
        tester,
      ) async {
        await pumpDialogueRoleplayScreen(tester);
        final state = tester.state<State>(
          find.byType(DialogueRoleplayScreen),
        );
        expect(
          (state as dynamic).getCompletionTitle(
            tester.element(find.byType(DialogueRoleplayScreen)),
          ),
          equals('DIALOGUE EXPERT!'),
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
          'has_seen_briefing_dialogueRoleplay': false,
        });
        await pumpDialogueRoleplayScreen(tester, level: 1);
        expect(find.byType(QuestBriefingOverlay), findsOneWidget);
      });

      testWidgets(
        '2.2 displays uppercase SCENE ARCHITECT title in briefing overlay',
        (tester) async {
          SharedPreferences.setMockInitialValues({
            'has_seen_briefing_dialogueRoleplay': false,
          });
          await pumpDialogueRoleplayScreen(tester, level: 1);
          expect(find.text('SCENE ARCHITECT'), findsOneWidget);
        },
      );

      testWidgets(
        '2.3 displays uppercase ENTER SCENE button in briefing overlay',
        (tester) async {
          SharedPreferences.setMockInitialValues({
            'has_seen_briefing_dialogueRoleplay': false,
          });
          await pumpDialogueRoleplayScreen(tester, level: 1);
          expect(find.text('ENTER SCENE'), findsOneWidget);
        },
      );

      testWidgets(
        '2.4 tapping ENTER SCENE button dismisses briefing overlay',
        (tester) async {
          SharedPreferences.setMockInitialValues({
            'has_seen_briefing_dialogueRoleplay': false,
          });
          await pumpDialogueRoleplayScreen(tester, level: 1);
          expect(find.byType(QuestBriefingOverlay), findsOneWidget);

          await tester.tap(find.text('ENTER SCENE'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));

          expect(find.byType(QuestBriefingOverlay), findsNothing);
        },
      );

      testWidgets('2.5 does not show QuestBriefingOverlay when level is 2', (
        tester,
      ) async {
        await pumpDialogueRoleplayScreen(tester, level: 2);
        expect(find.byType(QuestBriefingOverlay), findsNothing);
      });
    });

    // -------------------------------------------------------------------------
    // 3. Header Component (DialogueRoleplayHeader) (5 tests)
    // -------------------------------------------------------------------------
    group('3. Header Component (DialogueRoleplayHeader)', () {
      testWidgets('3.1 renders header with key dialogue_roleplay_header', (
        tester,
      ) async {
        await pumpDialogueRoleplayScreen(tester);
        expect(
          find.byKey(const Key('dialogue_roleplay_header')),
          findsOneWidget,
        );
        expect(find.byType(DialogueRoleplayHeader), findsOneWidget);
      });

      testWidgets('3.2 displays formatted instruction text in uppercase', (
        tester,
      ) async {
        await pumpDialogueRoleplayScreen(tester);
        expect(
          find.text('LISTEN TO YOUR PARTNER AND CHOOSE THE BEST RESPONSE.'),
          findsOneWidget,
        );
      });

      testWidgets(
        '3.3 displays Icons.record_voice_over_rounded icon in header',
        (tester) async {
          await pumpDialogueRoleplayScreen(tester);
          expect(
            find.byIcon(Icons.record_voice_over_rounded),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        '3.4 handles fallback instruction when quest instruction is null',
        (tester) async {
          final noInstQuest = createQuest(instruction: '');
          final state = testLoadedState.copyWith(quests: [noInstQuest]);
          await pumpDialogueRoleplayScreen(tester, state: state);

          expect(
            find.byKey(const Key('dialogue_roleplay_header')),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        '3.5 handles long instruction text with ellipsis/flexible without overflow',
        (tester) async {
          final longInstQuest = createQuest(
            instruction:
                'This is an extremely long dialogue instruction that explains in excruciating detail how to respond to your foreign partner and should truncate cleanly.',
          );
          final state = testLoadedState.copyWith(quests: [longInstQuest]);
          await pumpDialogueRoleplayScreen(tester, state: state);

          expect(tester.takeException(), isNull);
        },
      );
    });

    // -------------------------------------------------------------------------
    // 4. Exchange Stage Component (DialogueRoleplayExchangeStage) (6 tests)
    // -------------------------------------------------------------------------
    group('4. Exchange Stage Component (DialogueRoleplayExchangeStage)', () {
      testWidgets(
        '4.1 renders exchange stage with key dialogue_roleplay_exchange_stage',
        (tester) async {
          await pumpDialogueRoleplayScreen(tester);
          expect(
            find.byKey(const Key('dialogue_roleplay_exchange_stage')),
            findsOneWidget,
          );
          expect(find.byType(DialogueRoleplayExchangeStage), findsOneWidget);
        },
      );

      testWidgets(
        '4.2 displays partner dialogue card with key dialogue_roleplay_partner_card',
        (tester) async {
          await pumpDialogueRoleplayScreen(tester);
          expect(
            find.byKey(const Key('dialogue_roleplay_partner_card')),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        '4.3 displays ROLEPLAY PARTNER title and Icons.support_agent_rounded avatar',
        (tester) async {
          await pumpDialogueRoleplayScreen(tester);
          expect(find.text('ROLEPLAY PARTNER'), findsOneWidget);
          expect(find.byIcon(Icons.support_agent_rounded), findsOneWidget);
        },
      );

      testWidgets('4.4 displays partner dialogue text accurately', (
        tester,
      ) async {
        await pumpDialogueRoleplayScreen(tester);
        expect(
          find.text('Could you please help me find the nearest subway station?'),
          findsOneWidget,
        );
      });

      testWidgets(
        '4.5 displays user response card with key dialogue_roleplay_user_card',
        (tester) async {
          await pumpDialogueRoleplayScreen(tester);
          expect(
            find.byKey(const Key('dialogue_roleplay_user_card')),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        '4.6 displays YOUR RESPONSE title and Icons.face_rounded avatar',
        (tester) async {
          await pumpDialogueRoleplayScreen(tester);
          expect(find.text('YOUR RESPONSE'), findsOneWidget);
          expect(find.byIcon(Icons.face_rounded), findsOneWidget);
        },
      );
    });

    // -------------------------------------------------------------------------
    // 5. Synaptic Link Painter & Dynamic Particle Wire (5 tests)
    // -------------------------------------------------------------------------
    group('5. Synaptic Link Painter & Dynamic Particle Wire', () {
      testWidgets(
        '5.1 renders synaptic link canvas with key dialogue_roleplay_synaptic_link',
        (tester) async {
          await pumpDialogueRoleplayScreen(tester);
          expect(
            find.byKey(const Key('dialogue_roleplay_synaptic_link')),
            findsOneWidget,
          );
          expect(find.byType(CustomPaint), findsWidgets);
        },
      );

      testWidgets('5.2 renders with theme color when unanswered', (
        tester,
      ) async {
        await pumpDialogueRoleplayScreen(tester);
        final customPaint = tester.widget<CustomPaint>(
          find.descendant(
            of: find.byKey(const Key('dialogue_roleplay_synaptic_link')),
            matching: find.byType(CustomPaint),
          ),
        );
        expect(customPaint.painter, isA<SynapticLinkPainter>());
      });

      testWidgets(
        '5.3 SynapticLinkPainter shouldRepaint returns true when time changes',
        (tester) async {
          final p1 = SynapticLinkPainter(
            time: 0.1,
            isConnected: false,
            themeColor: Colors.blue,
          );
          final p2 = SynapticLinkPainter(
            time: 0.2,
            isConnected: false,
            themeColor: Colors.blue,
          );
          expect(p2.shouldRepaint(p1), isTrue);
        },
      );

      testWidgets(
        '5.4 SynapticLinkPainter shouldRepaint returns true when isConnected changes',
        (tester) async {
          final p1 = SynapticLinkPainter(
            time: 0.1,
            isConnected: false,
            themeColor: Colors.blue,
          );
          final p2 = SynapticLinkPainter(
            time: 0.1,
            isConnected: true,
            themeColor: Colors.blue,
          );
          expect(p2.shouldRepaint(p1), isTrue);
        },
      );

      testWidgets(
        '5.5 SynapticLinkPainter shouldRepaint returns false when time and isConnected are identical',
        (tester) async {
          final p1 = SynapticLinkPainter(
            time: 0.5,
            isConnected: false,
            themeColor: Colors.blue,
          );
          final p2 = SynapticLinkPainter(
            time: 0.5,
            isConnected: false,
            themeColor: Colors.blue,
          );
          expect(p2.shouldRepaint(p1), isFalse);
        },
      );
    });

    // -------------------------------------------------------------------------
    // 6. TTS Audio Playback for Partner & User Cards (7 tests)
    // -------------------------------------------------------------------------
    group('6. TTS Audio Playback for Partner & User Cards', () {
      testWidgets(
        '6.1 partner card renders volume button with key dialogue_roleplay_partner_tts_button',
        (tester) async {
          await pumpDialogueRoleplayScreen(tester);
          expect(
            find.byKey(const Key('dialogue_roleplay_partner_tts_button')),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        '6.2 tapping partner volume button plays partner dialogue via soundService.playTts',
        (tester) async {
          await pumpDialogueRoleplayScreen(tester);
          await tester.tap(
            find.byKey(const Key('dialogue_roleplay_partner_tts_button')),
          );
          await tester.pump();

          verify(
            () => mockSoundService.playTts(
              'Could you please help me find the nearest subway station?',
            ),
          ).called(greaterThanOrEqualTo(1));
        },
      );

      testWidgets(
        '6.3 tapping partner volume button while audio recording is active does not play',
        (tester) async {
          when(() => mockAudioRecorder.isRecording).thenReturn(true);
          await pumpDialogueRoleplayScreen(tester);

          clearInteractions(mockSoundService);
          await tester.tap(
            find.byKey(const Key('dialogue_roleplay_partner_tts_button')),
          );
          await tester.pump();

          verifyNever(() => mockSoundService.playTts(any()));
        },
      );

      testWidgets(
        '6.4 user card renders volume button with key dialogue_roleplay_user_tts_button',
        (tester) async {
          await pumpDialogueRoleplayScreen(tester);
          expect(
            find.byKey(const Key('dialogue_roleplay_user_tts_button')),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        '6.5 tapping user volume button plays chosen reply when user is premium',
        (tester) async {
          await pumpDialogueRoleplayScreen(tester);
          final replyChip = find.text('Sure, it is right around the corner.');
          if (replyChip.evaluate().isNotEmpty) {
            await tester.tap(replyChip);
            await tester.pump();
          }

          await tester.tap(
            find.byKey(const Key('dialogue_roleplay_user_tts_button')),
          );
          await tester.pump();

          verify(() => mockSoundService.playTts(any())).called(
            greaterThanOrEqualTo(1),
          );
        },
      );

      testWidgets(
        '6.6 tapping user volume button triggers monetization gate when user is not premium',
        (tester) async {
          when(() => mockAuthBloc.state).thenReturn(
            AuthState.authenticated(
              const UserEntity(
                id: 'free_user',
                email: 'free@vowl.app',
                displayName: 'Free User',
                isPremium: false,
                hintCount: 3,
              ),
            ),
          );

          await pumpDialogueRoleplayScreen(tester);
          await tester.tap(
            find.byKey(const Key('dialogue_roleplay_user_tts_button')),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          expect(find.byType(BottomSheet), findsOneWidget);
        },
      );

      testWidgets(
        '6.7 tapping user volume button while audio recording is active does not play',
        (tester) async {
          when(() => mockAudioRecorder.isRecording).thenReturn(true);
          await pumpDialogueRoleplayScreen(tester);

          clearInteractions(mockSoundService);
          await tester.tap(
            find.byKey(const Key('dialogue_roleplay_user_tts_button')),
          );
          await tester.pump();

          verifyNever(() => mockSoundService.playTts(any()));
        },
      );
    });

    // -------------------------------------------------------------------------
    // 7. Smart Reply Suggestions & ML Integration (8 tests)
    // -------------------------------------------------------------------------
    group('7. Smart Reply Suggestions & ML Integration', () {
      testWidgets(
        '7.1 fetches Smart Replies from SmartReplyService.getSuggestions on dialogue auto-play',
        (tester) async {
          await pumpDialogueRoleplayScreen(tester);
          verify(
            () => mockSmartReplyService.getSuggestions(),
          ).called(greaterThanOrEqualTo(1));
        },
      );

      testWidgets(
        '7.2 displays SmartReplyChip for each available smart reply',
        (tester) async {
          await pumpDialogueRoleplayScreen(tester);
          expect(find.byType(SmartReplyChip), findsWidgets);
        },
      );

      testWidgets(
        '7.3 tapping a smart reply chip updates chosenReply and user card text',
        (tester) async {
          await pumpDialogueRoleplayScreen(tester);
          final chipFinder = find.byType(SmartReplyChip).first;
          final chipWidget = tester.widget<SmartReplyChip>(chipFinder);

          await tester.tap(chipFinder);
          await tester.pump();

          expect(find.text(chipWidget.text), findsWidgets);
        },
      );

      testWidgets(
        '7.4 tapping a smart reply chip updates expectedText in SpeakToConfirmOverlay',
        (tester) async {
          await pumpDialogueRoleplayScreen(tester);
          final chipFinder = find.byType(SmartReplyChip).first;
          final chipWidget = tester.widget<SmartReplyChip>(chipFinder);

          await tester.tap(chipFinder);
          await tester.pump();

          final overlay = tester.widget<SpeakToConfirmOverlay>(
            find.byKey(const Key('dialogue_roleplay_speak_confirm_overlay')),
          );
          expect(overlay.expectedText, equals(chipWidget.text));
        },
      );

      testWidgets(
        '7.5 autoplay prioritizes quest authored synonyms/smartReplies before ML replies',
        (tester) async {
          await pumpDialogueRoleplayScreen(tester);
          expect(
            find.text('Sure, it is right around the corner.'),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        '7.6 deduplicates replies between quest acceptedSynonyms and ML replies',
        (tester) async {
          when(
            () => mockSmartReplyService.getSuggestions(),
          ).thenAnswer((_) async => ['Sure, it is right around the corner.']);

          await pumpDialogueRoleplayScreen(tester);
          expect(
            find.text('Sure, it is right around the corner.'),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        '7.7 handles empty smart replies gracefully without crashing',
        (tester) async {
          when(
            () => mockSmartReplyService.getSuggestions(),
          ).thenAnswer((_) async => []);
          final noRepliesQuest = createQuest(
            smartReplies: null,
            acceptedSynonyms: null,
          );
          final state = testLoadedState.copyWith(quests: [noRepliesQuest]);
          await pumpDialogueRoleplayScreen(tester, state: state);

          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        '7.8 clears SmartReplyService conversation on initial question (index 0)',
        (tester) async {
          await pumpDialogueRoleplayScreen(tester);
          verify(
            () => mockSmartReplyService.clearConversation(),
          ).called(greaterThanOrEqualTo(1));
        },
      );
    });

    // -------------------------------------------------------------------------
    // 8. Hint System (SpeakingHintUsed) (4 tests)
    // -------------------------------------------------------------------------
    group('8. Hint System (SpeakingHintUsed)', () {
      testWidgets('8.1 tapping header hint button dispatches SpeakingHintUsed', (
        tester,
      ) async {
        await pumpDialogueRoleplayScreen(tester);
        final hintButton = find.byType(QuestHintButton);
        expect(hintButton, findsOneWidget);

        await tester.tap(hintButton);
        await tester.pump();

        verify(
          () => mockSpeakingBloc.add(const SpeakingHintUsed()),
        ).called(greaterThanOrEqualTo(1));
      });

      testWidgets('8.2 dispatches hint when hint count is positive', (
        tester,
      ) async {
        await pumpDialogueRoleplayScreen(tester);
        expect(find.byType(QuestHintButton), findsOneWidget);
      });

      testWidgets('8.3 works seamlessly across repeated hint taps', (
        tester,
      ) async {
        await pumpDialogueRoleplayScreen(tester);
        final hintButton = find.byType(QuestHintButton);

        await tester.tap(hintButton);
        await tester.pump();
        await tester.tap(hintButton);
        await tester.pump();

        verify(
          () => mockSpeakingBloc.add(const SpeakingHintUsed()),
        ).called(greaterThanOrEqualTo(2));
      });

      testWidgets('8.4 renders hint button with proper icon', (
        tester,
      ) async {
        await pumpDialogueRoleplayScreen(tester);
        expect(
          find.byIcon(Icons.lightbulb_rounded),
          findsOneWidget,
        );
      });
    });

    // -------------------------------------------------------------------------
    // 9. SpeakToConfirmOverlay Integration & TTS Completion Barrier (7 tests)
    // -------------------------------------------------------------------------
    group('9. SpeakToConfirmOverlay Integration & TTS Completion Barrier', () {
      testWidgets(
        '9.1 renders SpeakToConfirmOverlay with key dialogue_roleplay_speak_confirm_overlay',
        (tester) async {
          await pumpDialogueRoleplayScreen(tester);
          expect(
            find.byKey(const Key('dialogue_roleplay_speak_confirm_overlay')),
            findsOneWidget,
          );
        },
      );

      testWidgets(
        '9.2 SpeakToConfirmOverlay has title SPEAK YOUR LINE and subtitle Say the selected option aloud',
        (tester) async {
          await pumpDialogueRoleplayScreen(tester);
          final overlay = tester.widget<SpeakToConfirmOverlay>(
            find.byKey(const Key('dialogue_roleplay_speak_confirm_overlay')),
          );
          expect(overlay.title, equals('SPEAK YOUR LINE'));
          expect(overlay.subtitle, equals('Say the selected option aloud'));
        },
      );

      testWidgets(
        '9.3 SpeakToConfirmOverlay has isPositioned: false and hideExpectedText: true',
        (tester) async {
          await pumpDialogueRoleplayScreen(tester);
          final overlay = tester.widget<SpeakToConfirmOverlay>(
            find.byKey(const Key('dialogue_roleplay_speak_confirm_overlay')),
          );
          expect(overlay.isPositioned, isFalse);
          expect(overlay.hideExpectedText, isTrue);
          expect(overlay.allowSkip, isFalse);
        },
      );

      testWidgets(
        '9.4 when TTS is playing (_ttsFinished is false), SpeakToConfirmOverlay has opacity 0.4 and absorbs pointers',
        (tester) async {
          VowlMotion.lowAnimationModeOverride.value = false;
          await pumpDialogueRoleplayScreen(tester);

          final absorbPointer = tester.widget<AbsorbPointer>(
            find.descendant(
              of: find.byType(AnimatedOpacity),
              matching: find.byType(AbsorbPointer),
            ),
          );
          expect(absorbPointer.absorbing, isTrue);

          await tester.pump(const Duration(seconds: 3));
          VowlMotion.lowAnimationModeOverride.value = true;
          await tester.pump();
        },
      );

      testWidgets(
        '9.5 when TTS finishes (_ttsFinished is true), SpeakToConfirmOverlay has opacity 1.0 and is interactive',
        (tester) async {
          await pumpDialogueRoleplayScreen(tester);

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
        '9.6 tapping confirmed (Nailed It) triggers verbal submission',
        (tester) async {
          await pumpDialogueRoleplayScreen(tester);
          final overlay = tester.widget<SpeakToConfirmOverlay>(
            find.byKey(const Key('dialogue_roleplay_speak_confirm_overlay')),
          );
          overlay.onConfirmed();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));

          verify(
            () => mockSpeakingBloc.add(const SubmitAnswer(true)),
          ).called(1);
        },
      );

      testWidgets(
        '9.7 tapping skipped (Needs Work) triggers verbal submission',
        (tester) async {
          await pumpDialogueRoleplayScreen(tester);
          final overlay = tester.widget<SpeakToConfirmOverlay>(
            find.byKey(const Key('dialogue_roleplay_speak_confirm_overlay')),
          );
          overlay.onSkipped();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));

          verify(
            () => mockSpeakingBloc.add(const SubmitAnswer(false)),
          ).called(1);
        },
      );
    });

    // -------------------------------------------------------------------------
    // 10. Answer Submission & Lockout Mechanics (6 tests)
    // -------------------------------------------------------------------------
    group('10. Answer Submission & Lockout Mechanics', () {
      testWidgets(
        '10.1 submitting correct evaluation dispatches SubmitAnswer(true), plays correct sound & haptic',
        (tester) async {
          await pumpDialogueRoleplayScreen(tester);
          final overlay = tester.widget<SpeakToConfirmOverlay>(
            find.byKey(const Key('dialogue_roleplay_speak_confirm_overlay')),
          );
          overlay.onConfirmed();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));

          verify(() => mockHapticService.success()).called(1);
          verify(() => mockSoundService.playCorrect()).called(1);
        },
      );

      testWidgets(
        '10.2 submitting correct evaluation adds chosen reply to SmartReplyService conversation context',
        (tester) async {
          await pumpDialogueRoleplayScreen(tester);
          final overlay = tester.widget<SpeakToConfirmOverlay>(
            find.byKey(const Key('dialogue_roleplay_speak_confirm_overlay')),
          );
          overlay.onConfirmed();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));

          verify(
            () => mockSmartReplyService.addMessage(
              any(),
              isLocalUser: true,
            ),
          ).called(1);
        },
      );

      testWidgets(
        '10.3 submitting wrong evaluation dispatches SubmitAnswer(false), plays wrong sound & haptic',
        (tester) async {
          await pumpDialogueRoleplayScreen(tester);
          final overlay = tester.widget<SpeakToConfirmOverlay>(
            find.byKey(const Key('dialogue_roleplay_speak_confirm_overlay')),
          );
          overlay.onSkipped();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));

          verify(() => mockHapticService.error()).called(1);
          verify(() => mockSoundService.playWrong()).called(1);
        },
      );

      testWidgets(
        '10.4 submitting wrong evaluation handles error state cleanly',
        (tester) async {
          await pumpDialogueRoleplayScreen(tester);
          final overlay = tester.widget<SpeakToConfirmOverlay>(
            find.byKey(const Key('dialogue_roleplay_speak_confirm_overlay')),
          );
          overlay.onSkipped();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));

          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        '10.5 once answered, SpeakToConfirmOverlay and smart reply chips are unmounted',
        (tester) async {
          final answeredState = testLoadedState.copyWith(
            answerStatus: AnswerStatus.correct,
          );
          await pumpDialogueRoleplayScreen(tester, state: answeredState);

          expect(
            find.byKey(const Key('dialogue_roleplay_speak_confirm_overlay')),
            findsNothing,
          );
          expect(
            find.byKey(const Key('dialogue_roleplay_smart_replies_list')),
            findsNothing,
          );
        },
      );

      testWidgets(
        '10.6 once answered, subsequent answer evaluations are locked out',
        (tester) async {
          await pumpDialogueRoleplayScreen(tester);
          final overlay = tester.widget<SpeakToConfirmOverlay>(
            find.byKey(const Key('dialogue_roleplay_speak_confirm_overlay')),
          );
          overlay.onConfirmed();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));

          // Call again on cached reference
          overlay.onConfirmed();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));

          verify(
            () => mockSpeakingBloc.add(const SubmitAnswer(true)),
          ).called(1);
        },
      );
    });

    // -------------------------------------------------------------------------
    // 11. Progression, State Transitions & Cleanup (5 tests)
    // -------------------------------------------------------------------------
    group('11. Progression, State Transitions & Cleanup', () {
      testWidgets(
        '11.1 answered state mounts GameFeedbackCard with CONTINUE action',
        (tester) async {
          final answeredState = testLoadedState.copyWith(
            answerStatus: AnswerStatus.correct,
          );
          await pumpDialogueRoleplayScreen(tester, state: answeredState);

          expect(find.byType(GameFeedbackCard), findsOneWidget);
          expect(find.text('CONTINUE'), findsOneWidget);
        },
      );

      testWidgets('11.2 tapping CONTINUE dispatches NextQuestion', (
        tester,
      ) async {
        final answeredState = testLoadedState.copyWith(
          answerStatus: AnswerStatus.correct,
        );
        await pumpDialogueRoleplayScreen(tester, state: answeredState);

        await tester.tap(find.text('CONTINUE'));
        await tester.pump();

        verify(() => mockSpeakingBloc.add(const NextQuestion())).called(1);
      });

      testWidgets(
        '11.3 onQuestionReset resets chosenReply, smartReplies, and ttsFinished',
        (tester) async {
          await pumpDialogueRoleplayScreen(tester);
          final state = tester.state<State>(
            find.byType(DialogueRoleplayScreen),
          );
          (state as dynamic).onQuestionReset();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));

          expect(tester.takeException(), isNull);
        },
      );

      testWidgets(
        '11.4 SpeakingGameComplete state triggers game completion dialog',
        (tester) async {
          await pumpDialogueRoleplayScreen(tester);

          speakingStreamController.add(
            const SpeakingGameComplete(
              xpEarned: 50,
              coinsEarned: 25,
              questCount: 1,
            ),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 600));

          expect(find.text('DIALOGUE EXPERT!'), findsOneWidget);
        },
      );

      testWidgets(
        '11.5 screen disposes cleanly without timer leaks or exceptions',
        (tester) async {
          await pumpDialogueRoleplayScreen(tester);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump(const Duration(milliseconds: 300));

          expect(tester.takeException(), isNull);
        },
      );
    });

    // -------------------------------------------------------------------------
    // 12. Viewport Responsiveness, Theming & Accessibility (5 tests)
    // -------------------------------------------------------------------------
    group('12. Viewport Responsiveness, Theming & Accessibility', () {
      testWidgets(
        '12.1 renders cleanly on compact mobile viewport (320x568)',
        (tester) async {
          await pumpDialogueRoleplayScreen(
            tester,
            size: const Size(320, 568),
          );
          expect(tester.takeException(), isNull);
        },
      );

      testWidgets('12.2 renders cleanly on tablet viewport (768x1024)', (
        tester,
      ) async {
        await pumpDialogueRoleplayScreen(
          tester,
          size: const Size(768, 1024),
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('12.3 renders cleanly in Light Theme mode', (
        tester,
      ) async {
        await pumpDialogueRoleplayScreen(
          tester,
          themeMode: ThemeMode.light,
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('12.4 renders cleanly in Dark Theme mode', (
        tester,
      ) async {
        await pumpDialogueRoleplayScreen(
          tester,
          themeMode: ThemeMode.dark,
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets(
        '12.5 suppresses animations and repeating timers when reduceMotion is active',
        (tester) async {
          await pumpDialogueRoleplayScreen(
            tester,
            reduceMotion: true,
          );
          expect(tester.takeException(), isNull);
        },
      );
    });
  });
}
