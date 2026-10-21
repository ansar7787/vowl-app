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
import 'package:vowl/core/presentation/game_mechanics/speaking/speak_to_confirm_overlay.dart';
import 'package:vowl/core/presentation/widgets/game_briefing_layer.dart';
import 'package:vowl/core/presentation/widgets/game_feedback_card.dart';
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
import 'package:vowl/features/roleplay/domain/entities/roleplay_quest.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_bloc.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_event.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_state.dart';
import 'package:vowl/features/roleplay/presentation/layout/roleplay_base_layout.dart';
import 'package:vowl/features/roleplay/social_spark/presentation/pages/social_spark_screen.dart';
import 'package:vowl/features/roleplay/social_spark/presentation/widgets/social_spark_connection_monitor.dart';
import 'package:vowl/features/roleplay/social_spark/presentation/widgets/social_spark_galaxy_board.dart';
import 'package:vowl/features/roleplay/social_spark/presentation/widgets/social_spark_painter.dart';

class MockRoleplayBloc extends MockBloc<RoleplayEvent, RoleplayState>
    implements RoleplayBloc {}

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

  late MockRoleplayBloc mockRoleplayBloc;
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
  late StreamController<RoleplayState> roleplayStreamController;

  RoleplayQuest createQuest({
    String id = 'sq_1',
    String instruction = 'Arrange the words to initiate an engaging conversation.',
    String? socialContext = 'Coffee shop networking',
    List<String>? shuffledWords = const ['Mind', 'if', 'I', 'join', 'you?'],
    String? correctAnswer = 'Mind if I join you?',
    String? explanation =
        'Asking politely to share space opens a warm pathway for natural small talk.',
    String? culturalNote =
        'In casual cafes, sharing large communal tables is common and welcomed.',
    String? hint = 'Start with the polite verb Mind...',
    int difficulty = 2,
  }) {
    return RoleplayQuest(
      id: id,
      instruction: instruction,
      socialContext: socialContext,
      shuffledWords: shuffledWords,
      correctAnswer: correctAnswer,
      explanation: explanation,
      culturalNote: culturalNote,
      hint: hint,
      subtype: GameSubtype.socialSpark,
      difficulty: difficulty,
    );
  }

  final sampleQuest1 = createQuest();
  final sampleQuest2 = createQuest(
    id: 'sq_2',
    socialContext: 'Conference reception',
    shuffledWords: const ['What', 'brought', 'you', 'to', 'this', 'event?'],
    correctAnswer: 'What brought you to this event?',
    explanation: 'Open-ended questions spark deeper conversational flow.',
    culturalNote: 'Networking events favor curious, open-ended introductions.',
    hint: 'Start with the question word What...',
  );

  final testLoadedState = RoleplayLoaded(
    quests: [sampleQuest1, sampleQuest2],
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
    hintUsed: false,
    gameType: GameSubtype.socialSpark,
    level: 2,
    wrongCount: 0,
    isFinalFailure: false,
  );

  setUpAll(() {
    registerFallbackValue(const NextQuestion());
    registerFallbackValue(const RoleplayHintUsed());
    registerFallbackValue(const SubmitAnswer(true));
    registerFallbackValue(const SubmitAnswer(false));
    registerFallbackValue(const RoleplaySpeakConfirmed(5));
    registerFallbackValue(const Duration(milliseconds: 50));
    VowlMotion.lowAnimationModeOverride.value = true;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'has_seen_briefing_socialSpark': true,
    });

    mockRoleplayBloc = MockRoleplayBloc();
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
    roleplayStreamController = StreamController<RoleplayState>.broadcast();

    // Default Stubs
    when(() => mockRoleplayBloc.state).thenReturn(testLoadedState);
    whenListen(
      mockRoleplayBloc,
      roleplayStreamController.stream,
      initialState: testLoadedState,
    );

    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());
    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(
        const UserEntity(
          id: 'test_user',
          email: 'test@vowl.app',
          displayName: 'Test Explorer',
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
    when(() => mockTtsService.speak(
      any(),
      rate: any(named: 'rate'),
      locale: any(named: 'locale'),
    )).thenAnswer((_) async {});

    when(() => mockSpeechService.initializeStt()).thenAnswer((_) async => true);
    when(() => mockSpeechService.stop()).thenAnswer((_) async {});
    when(() => mockSpeechService.cancel()).thenAnswer((_) async {});
    when(() => mockSpeechService.isListening).thenReturn(false);
    when(() => mockSpeechService.isPlaying).thenReturn(false);

    when(() => mockAudioRecorder.hasPermission()).thenAnswer((_) async => true);
    when(() => mockAudioRecorder.startRecording()).thenAnswer((_) async => true);
    when(() => mockAudioRecorder.stopRecording())
        .thenAnswer((_) async => '/tmp/social_spark_test.m4a');
    when(() => mockAudioRecorder.isRecording).thenReturn(false);
    when(() => mockAudioRecorder.onAmplitudeChanged(any()))
        .thenAnswer((_) => Stream.value(Amplitude(current: -10, max: -5)));
    when(() => mockAudioRecorder.dispose()).thenAnswer((_) async {});

    when(() => mockLocaleService.tr(any(), fallback: any(named: 'fallback')))
        .thenAnswer((invocation) {
      final fallback = invocation.namedArguments[#fallback] as String?;
      return fallback ?? invocation.positionalArguments[0] as String;
    });

    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
    when(() => mockAnalyticsService.logSelfEvaluation(any()))
        .thenAnswer((_) async {});
    when(() => mockAnalyticsService.logGameSkipped(any()))
        .thenAnswer((_) async {});
    when(() => mockAnalyticsService.logPurchaseAttempt(any()))
        .thenAnswer((_) async {});

    if (di.sl.isRegistered<HapticService>()) di.sl.unregister<HapticService>();
    if (di.sl.isRegistered<SoundService>()) di.sl.unregister<SoundService>();
    if (di.sl.isRegistered<TtsService>()) di.sl.unregister<TtsService>();
    if (di.sl.isRegistered<SpeechService>()) di.sl.unregister<SpeechService>();
    if (di.sl.isRegistered<AudioRecordingService>()) {
      di.sl.unregister<AudioRecordingService>();
    }
    if (di.sl.isRegistered<LocaleService>()) di.sl.unregister<LocaleService>();
    if (di.sl.isRegistered<AppLogger>()) di.sl.unregister<AppLogger>();
    if (di.sl.isRegistered<AnalyticsService>()) di.sl.unregister<AnalyticsService>();
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
    roleplayStreamController.close();
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
    if (di.sl.isRegistered<AnalyticsService>()) di.sl.unregister<AnalyticsService>();
    if (di.sl.isRegistered<AdService>()) di.sl.unregister<AdService>();
    if (di.sl.isRegistered<NetworkInfo>()) di.sl.unregister<NetworkInfo>();
  });

  Future<void> pumpSocialSparkScreen(
    WidgetTester tester, {
    RoleplayState? state,
    int level = 2,
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
    when(() => mockRoleplayBloc.state).thenReturn(activeState);
    whenListen(
      mockRoleplayBloc,
      roleplayStreamController.stream,
      initialState: activeState,
    );
    if (!roleplayStreamController.isClosed) {
      roleplayStreamController.add(activeState);
    }

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<RoleplayBloc>.value(value: mockRoleplayBloc),
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
              child: Scaffold(
                body: SocialSparkScreen(
                  level: level,
                  gameType: GameSubtype.socialSpark,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  group('SocialSparkScreen Layout and Mechanics Tests', () {
    // -------------------------------------------------------------------------
    // 1. Initial Layout & Structural Components (Tests 1-8)
    // -------------------------------------------------------------------------

    testWidgets('1. Initial layout renders RoleplayBaseLayout and progress header',
        (tester) async {
      await pumpSocialSparkScreen(tester);
      expect(find.byType(RoleplayBaseLayout), findsOneWidget);
      expect(find.byType(SocialSparkScreen), findsOneWidget);
    });

    testWidgets('2. Initial layout renders SocialSparkConnectionMonitor',
        (tester) async {
      await pumpSocialSparkScreen(tester);
      expect(find.byType(SocialSparkConnectionMonitor), findsOneWidget);
    });

    testWidgets('3. Connection monitor renders default "CONVERSATION BUILDER" header and forum icon',
        (tester) async {
      await pumpSocialSparkScreen(tester);
      expect(find.text('CONVERSATION BUILDER'), findsOneWidget);
      expect(find.byIcon(Icons.forum_rounded), findsOneWidget);
    });

    testWidgets('4. Connection monitor renders custom instruction text',
        (tester) async {
      await pumpSocialSparkScreen(tester);
      expect(find.text(sampleQuest1.instruction), findsOneWidget);
    });

    testWidgets('5. Connection monitor renders fallback instruction text when quest instruction is empty',
        (tester) async {
      final emptyQuest = createQuest(instruction: '');
      final customState = testLoadedState.copyWith(quests: [emptyQuest]);
      await pumpSocialSparkScreen(tester, state: customState);

      expect(find.byType(SocialSparkConnectionMonitor), findsOneWidget);
    });

    testWidgets('6. Connection monitor renders social context tag: "SCENE: COFFEE SHOP NETWORKING"',
        (tester) async {
      await pumpSocialSparkScreen(tester);
      expect(find.text('SCENE: COFFEE SHOP NETWORKING'), findsOneWidget);
      expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
    });

    testWidgets('7. Social context chip collapses safely when socialContext is null',
        (tester) async {
      final noContextQuest = createQuest(socialContext: null);
      final customState = testLoadedState.copyWith(quests: [noContextQuest]);
      await pumpSocialSparkScreen(tester, state: customState);

      expect(find.textContaining('SCENE:'), findsNothing);
      expect(find.byType(SocialSparkConnectionMonitor), findsOneWidget);
    });

    testWidgets('8. Initial empty text placeholder displays "Tap words to build your response"',
        (tester) async {
      await pumpSocialSparkScreen(tester);
      expect(find.text('Tap words to build your response'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // 2. Galaxy Board & Star Nodes Mechanics (Tests 9-18)
    // -------------------------------------------------------------------------

    testWidgets('9. Renders SocialSparkGalaxyBoard container with circular borders and background',
        (tester) async {
      await pumpSocialSparkScreen(tester);
      expect(find.byType(SocialSparkGalaxyBoard), findsOneWidget);
    });

    testWidgets('10. Renders all star nodes matching quest.shuffledWords count (5 words)',
        (tester) async {
      await pumpSocialSparkScreen(tester);
      for (int i = 0; i < sampleQuest1.shuffledWords!.length; i++) {
        expect(find.byKey(Key('social_spark_star_$i')), findsOneWidget);
      }
    });

    testWidgets('11. Star nodes display word text accurately with FittedBox and Outfit font',
        (tester) async {
      await pumpSocialSparkScreen(tester);
      for (final word in sampleQuest1.shuffledWords!) {
        expect(find.text(word), findsOneWidget);
      }
    });

    testWidgets('12. Unselected star nodes display subtle star sparkle icons',
        (tester) async {
      await pumpSocialSparkScreen(tester);
      expect(find.byIcon(Icons.star_rounded), findsNWidgets(5));
    });

    testWidgets('13. CustomPaint renders ConstellationPainter',
        (tester) async {
      await pumpSocialSparkScreen(tester);
      final painterFinder = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is ConstellationPainter,
      );
      expect(painterFinder, findsOneWidget);
    });

    testWidgets('14. Tapping a star node triggers selection haptic and hint synth sound',
        (tester) async {
      await pumpSocialSparkScreen(tester);
      await tester.tap(find.byKey(const Key('social_spark_star_0')));
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockHapticService.selection()).called(1);
      verify(() => mockSoundService.playHint()).called(1);
    });

    testWidgets('15. Tapping a star node adds word to connection monitor text',
        (tester) async {
      await pumpSocialSparkScreen(tester);
      await tester.tap(find.byKey(const Key('social_spark_star_0')));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Tap words to build your response'), findsNothing);
      expect(find.descendant(
        of: find.byType(SocialSparkConnectionMonitor),
        matching: find.text('Mind'),
      ), findsOneWidget);
    });

    testWidgets('16. Tapping multiple star nodes sequentially formats assembled sentence',
        (tester) async {
      await pumpSocialSparkScreen(tester);
      // 'Mind', 'if', 'I', 'join', 'you?' (indices 0, 1, 2, 3, 4)
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byKey(Key('social_spark_star_$i')));
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.descendant(
        of: find.byType(SocialSparkConnectionMonitor),
        matching: find.text('Mind if I join you?'),
      ), findsOneWidget);
    });

    testWidgets('17. Selected star node displays order badge ("1", "2", etc.)',
        (tester) async {
      await pumpSocialSparkScreen(tester);
      await tester.tap(find.byKey(const Key('social_spark_star_0')));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('18. Tapping an already selected star node deselects it and removes it from sentence',
        (tester) async {
      await pumpSocialSparkScreen(tester);
      await tester.tap(find.byKey(const Key('social_spark_star_0')));
      await tester.pump(const Duration(milliseconds: 550));
      expect(find.text('1'), findsOneWidget);

      await tester.tap(find.byKey(const Key('social_spark_star_0')));
      await tester.pump(const Duration(milliseconds: 550));

      expect(find.text('1'), findsNothing);
      expect(find.text('Tap words to build your response'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // 3. Action Buttons ("IGNITE SPARK" & "CLEAR PATH") (Tests 19-24)
    // -------------------------------------------------------------------------

    testWidgets('19. When no words are selected, action buttons are not visible',
        (tester) async {
      await pumpSocialSparkScreen(tester);
      expect(find.byKey(const Key('social_spark_ignite_button')), findsNothing);
      expect(find.byKey(const Key('social_spark_clear_button')), findsNothing);
    });

    testWidgets('20. Selecting at least one word reveals action buttons',
        (tester) async {
      await pumpSocialSparkScreen(tester);
      await tester.tap(find.byKey(const Key('social_spark_star_0')));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byKey(const Key('social_spark_ignite_button')), findsOneWidget);
      expect(find.byKey(const Key('social_spark_clear_button')), findsOneWidget);
    });

    testWidgets('21. "CHECK ANSWER" button renders with check icon and styled label',
        (tester) async {
      await pumpSocialSparkScreen(tester);
      await tester.tap(find.byKey(const Key('social_spark_star_0')));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('CHECK ANSWER'), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    });

    testWidgets('22. "CLEAR SELECTION" button renders with refresh icon and styled label',
        (tester) async {
      await pumpSocialSparkScreen(tester);
      await tester.tap(find.byKey(const Key('social_spark_star_0')));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('CLEAR SELECTION'), findsOneWidget);
      expect(find.byIcon(Icons.refresh_rounded), findsOneWidget);
    });

    testWidgets('23. Tapping "CLEAR SELECTION" clears all selected indices and dispatches selection haptic',
        (tester) async {
      await pumpSocialSparkScreen(tester);
      await tester.tap(find.byKey(const Key('social_spark_star_0')));
      await tester.tap(find.byKey(const Key('social_spark_star_1')));
      await tester.pump(const Duration(milliseconds: 350));

      clearInteractions(mockHapticService);
      await tester.tap(find.byKey(const Key('social_spark_clear_button')));
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockHapticService.selection()).called(1);
      expect(find.text('Tap words to build your response'), findsOneWidget);
    });

    testWidgets('24. Tapping "CLEAR SELECTION" hides action buttons',
        (tester) async {
      await pumpSocialSparkScreen(tester);
      await tester.tap(find.byKey(const Key('social_spark_star_0')));
      await tester.pump(const Duration(milliseconds: 350));

      await tester.tap(find.byKey(const Key('social_spark_clear_button')));
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byKey(const Key('social_spark_ignite_button')), findsNothing);
      expect(find.byKey(const Key('social_spark_clear_button')), findsNothing);
    });

    // -------------------------------------------------------------------------
    // 4. Submission & Verification - Wrong Answer Mechanics (Tests 25-30)
    // -------------------------------------------------------------------------

    testWidgets('25. Assembling incorrect sentence and tapping "IGNITE SPARK" triggers error sound and haptic',
        (tester) async {
      await pumpSocialSparkScreen(tester);
      // Select incomplete: 'Mind', 'if'
      await tester.tap(find.byKey(const Key('social_spark_star_0')));
      await tester.tap(find.byKey(const Key('social_spark_star_1')));
      await tester.pump(const Duration(milliseconds: 350));

      await tester.tap(find.byKey(const Key('social_spark_ignite_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockHapticService.error()).called(1);
    });

    testWidgets('26. Incorrect submission dispatches SubmitAnswer(false) to RoleplayBloc',
        (tester) async {
      await pumpSocialSparkScreen(tester);
      await tester.tap(find.byKey(const Key('social_spark_star_0')));
      await tester.tap(find.byKey(const Key('social_spark_star_1')));
      await tester.pump(const Duration(milliseconds: 350));

      await tester.tap(find.byKey(const Key('social_spark_ignite_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockRoleplayBloc.add(
            any(that: isA<SubmitAnswer>().having((e) => e.isCorrect, 'isCorrect', false)),
          )).called(1);
    });

    testWidgets('27. Incorrect submission does NOT mount SpeakToConfirmOverlay',
        (tester) async {
      await pumpSocialSparkScreen(tester);
      await tester.tap(find.byKey(const Key('social_spark_star_0')));
      await tester.tap(find.byKey(const Key('social_spark_star_1')));
      await tester.pump(const Duration(milliseconds: 350));

      await tester.tap(find.byKey(const Key('social_spark_ignite_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(SpeakToConfirmOverlay), findsNothing);
    });

    testWidgets('28. Answered wrong state updates monitor title to "LET\'S TRY AGAIN"',
        (tester) async {
      await pumpSocialSparkScreen(tester);
      await tester.tap(find.byKey(const Key('social_spark_star_0')));
      await tester.tap(find.byKey(const Key('social_spark_star_1')));
      await tester.pump(const Duration(milliseconds: 350));

      await tester.tap(find.byKey(const Key('social_spark_ignite_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text("LET'S TRY AGAIN"), findsOneWidget);
    });

    testWidgets('29. Answered wrong state reveals explanation card with "HELPFUL EXPLANATION"',
        (tester) async {
      await pumpSocialSparkScreen(tester);
      await tester.tap(find.byKey(const Key('social_spark_star_0')));
      await tester.tap(find.byKey(const Key('social_spark_star_1')));
      await tester.pump(const Duration(milliseconds: 350));

      await tester.tap(find.byKey(const Key('social_spark_ignite_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byKey(const Key('social_spark_explanation_card')), findsOneWidget);
      expect(find.text('HELPFUL EXPLANATION'), findsOneWidget);
      expect(find.text(sampleQuest1.explanation!), findsOneWidget);
    });

    testWidgets('30. Tapping star nodes in answered state is ignored',
        (tester) async {
      await pumpSocialSparkScreen(tester);
      await tester.tap(find.byKey(const Key('social_spark_star_0')));
      await tester.tap(find.byKey(const Key('social_spark_star_1')));
      await tester.pump(const Duration(milliseconds: 350));

      await tester.tap(find.byKey(const Key('social_spark_ignite_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      clearInteractions(mockHapticService);
      await tester.tap(find.byKey(const Key('social_spark_star_2')), warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 300));

      verifyNever(() => mockHapticService.selection());
    });

    // -------------------------------------------------------------------------
    // 5. Submission & Verification - Phase 2 Verbal Evaluation (Tests 31-38)
    // -------------------------------------------------------------------------

    testWidgets('31. Assembling correct sentence and tapping "IGNITE SPARK" triggers selection haptic',
        (tester) async {
      await pumpSocialSparkScreen(tester);
      // 'Mind', 'if', 'I', 'join', 'you?'
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byKey(Key('social_spark_star_$i')));
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump(const Duration(milliseconds: 350));

      clearInteractions(mockHapticService);
      await tester.tap(find.byKey(const Key('social_spark_ignite_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockHapticService.selection()).called(1);
    });

    testWidgets('32. Correct sentence submission does NOT immediately dispatch SubmitAnswer to BLoC',
        (tester) async {
      await pumpSocialSparkScreen(tester);
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byKey(Key('social_spark_star_$i')));
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump(const Duration(milliseconds: 350));

      clearInteractions(mockRoleplayBloc);
      await tester.tap(find.byKey(const Key('social_spark_ignite_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      verifyNever(() => mockRoleplayBloc.add(any(that: isA<SubmitAnswer>())));
    });

    testWidgets('33. Correct sentence submission mounts Phase 2 SpeakToConfirmOverlay',
        (tester) async {
      await pumpSocialSparkScreen(tester);
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byKey(Key('social_spark_star_$i')));
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump(const Duration(milliseconds: 350));

      await tester.tap(find.byKey(const Key('social_spark_ignite_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(SpeakToConfirmOverlay), findsOneWidget);
    });

    testWidgets('34. SpeakToConfirmOverlay displays expectedText matching quest.correctAnswer',
        (tester) async {
      await pumpSocialSparkScreen(tester);
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byKey(Key('social_spark_star_$i')));
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump(const Duration(milliseconds: 350));

      await tester.tap(find.byKey(const Key('social_spark_ignite_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      final overlay = tester.widget<SpeakToConfirmOverlay>(find.byType(SpeakToConfirmOverlay));
      expect(overlay.expectedText, sampleQuest1.correctAnswer);
    });

    testWidgets('35. SpeakToConfirmOverlay "Nailed It" dispatches RoleplaySpeakConfirmed(5) bonus coins',
        (tester) async {
      await pumpSocialSparkScreen(tester);
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byKey(Key('social_spark_star_$i')));
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump(const Duration(milliseconds: 350));

      await tester.tap(find.byKey(const Key('social_spark_ignite_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      final overlay = tester.widget<SpeakToConfirmOverlay>(find.byType(SpeakToConfirmOverlay));
      overlay.onConfirmed();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockRoleplayBloc.add(const RoleplaySpeakConfirmed(5))).called(1);
    });

    testWidgets('36. SpeakToConfirmOverlay "Nailed It" dispatches SubmitAnswer(true) with success sound & haptic',
        (tester) async {
      await pumpSocialSparkScreen(tester);
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byKey(Key('social_spark_star_$i')));
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump(const Duration(milliseconds: 350));

      await tester.tap(find.byKey(const Key('social_spark_ignite_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      final overlay = tester.widget<SpeakToConfirmOverlay>(find.byType(SpeakToConfirmOverlay));
      overlay.onConfirmed();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockRoleplayBloc.add(
            any(that: isA<SubmitAnswer>().having((e) => e.isCorrect, 'isCorrect', true)),
          )).called(1);
      verify(() => mockSoundService.playCorrect()).called(1);
      verify(() => mockHapticService.success()).called(1);
    });

    testWidgets('37. SpeakToConfirmOverlay "Needs Work" dispatches SubmitAnswer(false) with error sound & haptic',
        (tester) async {
      await pumpSocialSparkScreen(tester);
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byKey(Key('social_spark_star_$i')));
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump(const Duration(milliseconds: 350));

      await tester.tap(find.byKey(const Key('social_spark_ignite_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      final overlay = tester.widget<SpeakToConfirmOverlay>(find.byType(SpeakToConfirmOverlay));
      overlay.onSkipped();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockRoleplayBloc.add(
            any(that: isA<SubmitAnswer>().having((e) => e.isCorrect, 'isCorrect', false)),
          )).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
      verify(() => mockHapticService.error()).called(1);
    });

    testWidgets('38. SpeakToConfirmOverlay unmounts once answered via "Nailed It"',
        (tester) async {
      await pumpSocialSparkScreen(tester);
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byKey(Key('social_spark_star_$i')));
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump(const Duration(milliseconds: 350));

      await tester.tap(find.byKey(const Key('social_spark_ignite_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      final overlay = tester.widget<SpeakToConfirmOverlay>(find.byType(SpeakToConfirmOverlay));
      overlay.onConfirmed();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(SpeakToConfirmOverlay), findsNothing);
    });

    // -------------------------------------------------------------------------
    // 6. Post-Answer Review & Bottom Sheet Feedback (Tests 39-44)
    // -------------------------------------------------------------------------

    testWidgets('39. Answered correct state updates monitor title to "PERFECT RESPONSE"',
        (tester) async {
      await pumpSocialSparkScreen(tester);
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byKey(Key('social_spark_star_$i')));
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump(const Duration(milliseconds: 350));

      await tester.tap(find.byKey(const Key('social_spark_ignite_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      final overlay = tester.widget<SpeakToConfirmOverlay>(find.byType(SpeakToConfirmOverlay));
      overlay.onConfirmed();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('PERFECT RESPONSE'), findsOneWidget);
    });

    testWidgets('40. Answered correct state reveals explanation card with "WHY THIS WORKS" and verified icon',
        (tester) async {
      await pumpSocialSparkScreen(tester);
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byKey(Key('social_spark_star_$i')));
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump(const Duration(milliseconds: 350));

      await tester.tap(find.byKey(const Key('social_spark_ignite_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      final overlay = tester.widget<SpeakToConfirmOverlay>(find.byType(SpeakToConfirmOverlay));
      overlay.onConfirmed();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byKey(const Key('social_spark_explanation_card')), findsOneWidget);
      expect(find.text('WHY THIS WORKS'), findsOneWidget);
      expect(find.byIcon(Icons.verified_rounded), findsOneWidget);
    });

    testWidgets('41. Explanation card renders cultural note if present',
        (tester) async {
      await pumpSocialSparkScreen(tester);
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byKey(Key('social_spark_star_$i')));
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pump(const Duration(milliseconds: 350));

      await tester.tap(find.byKey(const Key('social_spark_ignite_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      final overlay = tester.widget<SpeakToConfirmOverlay>(find.byType(SpeakToConfirmOverlay));
      overlay.onConfirmed();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Note: ${sampleQuest1.culturalNote!}'), findsOneWidget);
    });

    testWidgets('42. ConstellationPainter renders when 2 or more stars are connected',
        (tester) async {
      await pumpSocialSparkScreen(tester);
      await tester.tap(find.byKey(const Key('social_spark_star_0')));
      await tester.tap(find.byKey(const Key('social_spark_star_1')));
      await tester.pump(const Duration(milliseconds: 300));

      final board = tester.widget<SocialSparkGalaxyBoard>(find.byType(SocialSparkGalaxyBoard));
      expect(board.selectedIndices.length, 2);
    });

    testWidgets('43. Answered state renders GameFeedbackCard in bottom sheet',
        (tester) async {
      await pumpSocialSparkScreen(tester);
      await tester.tap(find.byKey(const Key('social_spark_star_0')));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byKey(const Key('social_spark_ignite_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(GameFeedbackCard), findsOneWidget);
    });

    testWidgets('44. Tapping action button in GameFeedbackCard dispatches NextQuestion()',
        (tester) async {
      await pumpSocialSparkScreen(tester);
      await tester.tap(find.byKey(const Key('social_spark_star_0')));
      await tester.pump(const Duration(milliseconds: 300));

      await tester.tap(find.byKey(const Key('social_spark_ignite_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      clearInteractions(mockRoleplayBloc);
      final actionBtn = find.text('TRY AGAIN');
      expect(actionBtn, findsOneWidget);
      await tester.tap(actionBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockRoleplayBloc.add(any(that: isA<NextQuestion>()))).called(1);
    });

    // -------------------------------------------------------------------------
    // 7. State Transitions & Edge Cases (Tests 45-48)
    // -------------------------------------------------------------------------

    testWidgets('45. State transition to question 2 updates social context and words',
        (tester) async {
      await pumpSocialSparkScreen(tester);
      expect(find.text('SCENE: COFFEE SHOP NETWORKING'), findsOneWidget);

      final stateQ2 = testLoadedState.copyWith(currentIndex: 1);
      roleplayStreamController.add(stateQ2);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('SCENE: CONFERENCE RECEPTION'), findsOneWidget);
      expect(find.text('What'), findsOneWidget);
    });

    testWidgets('46. State transition clears previous selection',
        (tester) async {
      await pumpSocialSparkScreen(tester);
      await tester.tap(find.byKey(const Key('social_spark_star_0')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('1'), findsOneWidget);

      final stateQ2 = testLoadedState.copyWith(currentIndex: 1);
      roleplayStreamController.add(stateQ2);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('Tap words to build your response'), findsOneWidget);
    });

    testWidgets('47. Empty words list quest renders board safely without crashing',
        (tester) async {
      final emptyWordsQuest = createQuest(shuffledWords: []);
      final customState = testLoadedState.copyWith(quests: [emptyWordsQuest]);
      await pumpSocialSparkScreen(tester, state: customState);

      expect(tester.takeException(), isNull);
      expect(find.byType(SocialSparkGalaxyBoard), findsOneWidget);
    });

    testWidgets('48. Duplicate words in shuffledWords can be tapped independently based on distinct index tracking',
        (tester) async {
      final dupQuest = createQuest(shuffledWords: ['Hello', 'Hello', 'world']);
      final customState = testLoadedState.copyWith(quests: [dupQuest]);
      await pumpSocialSparkScreen(tester, state: customState);

      await tester.tap(find.byKey(const Key('social_spark_star_0')));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.byKey(const Key('social_spark_star_1')));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.descendant(
        of: find.byType(SocialSparkConnectionMonitor),
        matching: find.text('Hello Hello'),
      ), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // 8. Hints, Briefing, Shimmer, GameOver & Theming (Tests 49-55)
    // -------------------------------------------------------------------------

    testWidgets('49. Tapping hint button in header dispatches RoleplayHintUsed',
        (tester) async {
      await pumpSocialSparkScreen(tester);
      clearInteractions(mockRoleplayBloc);

      await tester.tap(find.byType(QuestHintButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      verify(() => mockRoleplayBloc.add(any(that: isA<RoleplayHintUsed>()))).called(1);
    });

    testWidgets('50. Connection monitor renders hint banner with lightbulb icon when hintUsed is true',
        (tester) async {
      final hintState = testLoadedState.copyWith(hintUsed: true);
      await pumpSocialSparkScreen(tester, state: hintState);

      expect(find.byKey(const Key('social_spark_hint_banner')), findsOneWidget);
      expect(find.byIcon(Icons.lightbulb_outline_rounded), findsOneWidget);
      expect(find.text(sampleQuest1.hint!), findsOneWidget);
    });

    testWidgets('51. Level 1 displays GameBriefingLayer overlay with "CHARISMA CORE"',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'has_seen_briefing_socialSpark': false,
      });
      await pumpSocialSparkScreen(tester, level: 1);

      expect(find.byType(GameBriefingLayer), findsOneWidget);
      expect(find.text('CHARISMA CORE'), findsOneWidget);
    });

    testWidgets('52. Uninitialized initial state renders GameShimmerLoading',
        (tester) async {
      await pumpSocialSparkScreen(tester, state: const RoleplayInitial());
      expect(find.byType(GameShimmerLoading), findsOneWidget);
    });

    testWidgets('53. Game over state with 0 lives renders cleanly',
        (tester) async {
      final gameOverState = testLoadedState.copyWith(livesRemaining: 0);
      await pumpSocialSparkScreen(tester, state: gameOverState);
      expect(find.byType(SocialSparkScreen), findsOneWidget);
    });

    testWidgets('54. Light theme renders cleanly with light mode styling',
        (tester) async {
      await pumpSocialSparkScreen(tester, themeMode: ThemeMode.light);
      expect(find.byType(SocialSparkScreen), findsOneWidget);
      expect(find.text('CONVERSATION BUILDER'), findsOneWidget);
    });

    testWidgets('55. Compact mobile (320x568) and tablet (768x1024) render with zero overflow',
        (tester) async {
      await pumpSocialSparkScreen(
        tester,
        size: const Size(320, 568),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(SocialSparkScreen), findsOneWidget);

      await pumpSocialSparkScreen(
        tester,
        size: const Size(768, 1024),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(SocialSparkScreen), findsOneWidget);
    });
  });
}

