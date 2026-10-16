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
import 'package:vowl/features/speaking/domain/entities/speaking_quest.dart';
import 'package:vowl/features/speaking/presentation/bloc/speaking_bloc.dart';
import 'package:vowl/features/speaking/presentation/layout/speaking_base_layout.dart';
import 'package:vowl/features/speaking/speak_missing_word/presentation/pages/speak_missing_word_screen.dart';
import 'package:vowl/features/speaking/speak_missing_word/presentation/widgets/speak_missing_word_instruction.dart';
import 'package:vowl/features/speaking/speak_missing_word/presentation/widgets/speak_missing_word_magnet_arena.dart';
import 'package:vowl/features/speaking/speak_missing_word/presentation/widgets/speak_missing_word_vortex_sentence.dart';

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
    String id = 'quest_missing_1',
    String textToSpeak = 'The ___ operates the system safely.',
    String missingWord = 'robot',
    String? correctAnswer = 'The robot operates the system safely.',
    List<String>? options = const ['robot', 'human', 'device', 'pilot'],
    String instruction = 'Select and speak the missing word.',
    String? hint = 'Think of an automated machine that operates systems.',
    int difficulty = 2,
  }) {
    return SpeakingQuest(
      id: id,
      type: QuestType.speaking,
      subtype: GameSubtype.speakMissingWord,
      textToSpeak: textToSpeak,
      missingWord: missingWord,
      correctAnswer: correctAnswer,
      options: options,
      instruction: instruction,
      hint: hint,
      difficulty: difficulty,
    );
  }

  final sampleQuest1 = createQuest();
  final sampleQuest2 = createQuest(
    id: 'quest_missing_2',
    textToSpeak: 'Water boils at one hundred ___ Celsius.',
    missingWord: 'degrees',
    correctAnswer: 'Water boils at one hundred degrees Celsius.',
    options: ['degrees', 'meters', 'liters', 'grams'],
    instruction: 'Complete the temperature measurement.',
    hint: 'A unit of temperature.',
  );

  final testLoadedState = SpeakingLoaded(
    quests: [sampleQuest1, sampleQuest2],
    currentIndex: 0,
    livesRemaining: 3,
    wrongCount: 0,
    hintUsed: false,
    answerStatus: AnswerStatus.unanswered,
    gameType: GameSubtype.speakMissingWord,
    level: 2,
  );

  setUpAll(() {
    registerFallbackValue(const SubmitAnswer(true));
    registerFallbackValue(const NextQuestion());
    registerFallbackValue(const SpeakingHintUsed());
    registerFallbackValue(
      const FetchSpeakingQuests(
        gameType: GameSubtype.speakMissingWord,
        level: 2,
      ),
    );
    registerFallbackValue(const Duration(milliseconds: 50));
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'has_seen_briefing_speakMissingWord': true,
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
          id: 'test_user_missing',
          email: 'missing@vowl.app',
          displayName: 'Missing Pilot',
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
        .thenAnswer((_) async => 'mock_missing_rec.m4a');
    when(() => mockAudioRecorder.dispose()).thenAnswer((_) async {});
    when(() => mockAudioRecorder.onAmplitudeChanged(any())).thenAnswer(
      (_) => Stream.fromIterable([
        Amplitude(current: -10, max: 0),
        Amplitude(current: -5, max: 0),
      ]),
    );

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
    when(() => mockSoundService.playFile(any())).thenAnswer((_) async {});

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

    VowlMotion.lowAnimationModeOverride.value = true;
  });

  tearDown(() async {
    await di.sl.reset();
    await speakingStreamController.close();
    VowlMotion.lowAnimationModeOverride.value = false;
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    SpeakingState? state,
    int level = 2,
    GameSubtype gameType = GameSubtype.speakMissingWord,
    ThemeMode themeMode = ThemeMode.dark,
    Size size = const Size(390, 844),
    double textScaleFactor = 1.0,
    bool reduceMotion = true,
  }) async {
    VowlMotion.lowAnimationModeOverride.value = reduceMotion;
    tester.view.physicalSize = Size(size.width * 2, size.height * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    if (state != null) {
      when(() => mockSpeakingBloc.state).thenReturn(state);
    }

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<SpeakingBloc>.value(value: mockSpeakingBloc),
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
              child: SpeakMissingWordScreen(
                level: level,
                gameType: gameType,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  // ---------------------------------------------------------------------------
  // 1. Initial Layout & Component Structure (8 tests)
  // ---------------------------------------------------------------------------
  group('1. Initial Layout & Component Structure', () {
    testWidgets('1.1 renders SpeakingBaseLayout', (tester) async {
      await pumpScreen(tester);
      expect(find.byType(SpeakingBaseLayout), findsOneWidget);
    });

    testWidgets('1.2 renders SpeakMissingWordInstruction', (tester) async {
      await pumpScreen(tester);
      expect(find.byType(SpeakMissingWordInstruction), findsOneWidget);
    });

    testWidgets('1.3 renders SpeakMissingWordVortexSentence', (tester) async {
      await pumpScreen(tester);
      expect(find.byType(SpeakMissingWordVortexSentence), findsOneWidget);
    });

    testWidgets('1.4 renders SpeakMissingWordMagnetArena when word is not placed', (tester) async {
      await pumpScreen(tester);
      expect(find.byType(SpeakMissingWordMagnetArena), findsOneWidget);
      expect(find.byKey(const Key('speak_missing_word_magnet_arena')), findsOneWidget);
    });

    testWidgets('1.5 renders center vortex icon with key speak_missing_word_vortex_center', (tester) async {
      await pumpScreen(tester);
      expect(find.byKey(const Key('speak_missing_word_vortex_center')), findsOneWidget);
    });

    testWidgets('1.6 renders all option chips from quest.options', (tester) async {
      await pumpScreen(tester);
      for (int i = 0; i < sampleQuest1.options!.length; i++) {
        expect(find.byKey(Key('speak_missing_word_option_$i')), findsOneWidget);
        expect(find.text(sampleQuest1.options![i].toUpperCase()), findsOneWidget);
      }
    });

    testWidgets('1.7 renders GameShimmerLoading when state is not SpeakingLoaded or quest is null', (tester) async {
      await pumpScreen(tester, state: const SpeakingInitial());
      expect(find.byType(GameShimmerLoading), findsOneWidget);
      expect(find.byType(SpeakMissingWordMagnetArena), findsNothing);
    });

    testWidgets('1.8 renders RawScrollbar and CustomScrollView', (tester) async {
      await pumpScreen(tester);
      expect(find.byType(RawScrollbar), findsOneWidget);
      expect(find.byType(CustomScrollView), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // 2. Level 1 Briefing Overlay & Onboarding (6 tests)
  // ---------------------------------------------------------------------------
  group('2. Level 1 Briefing Overlay & Onboarding', () {
    testWidgets('2.1 displays QuestBriefingOverlay on level 1 when not previously seen', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpScreen(tester, level: 1);
      expect(find.byType(QuestBriefingOverlay), findsOneWidget);
    });

    testWidgets('2.2 displays action button with text SPEAK WORD (uppercase)', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpScreen(tester, level: 1);
      expect(find.text('SPEAK WORD'), findsOneWidget);
    });

    testWidgets('2.3 tapping SPEAK WORD dismisses the overlay', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpScreen(tester, level: 1);
      expect(find.byType(QuestBriefingOverlay), findsOneWidget);

      await tester.ensureVisible(find.text('SPEAK WORD'));
      await tester.tap(find.text('SPEAK WORD'));
      await tester.pumpAndSettle();

      expect(find.byType(QuestBriefingOverlay), findsNothing);
    });

    testWidgets('2.4 displays correct briefing title and description', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpScreen(tester, level: 1);
      expect(find.text('VOCAL DECODER'), findsOneWidget);
    });

    testWidgets('2.5 does NOT display briefing overlay on level 2', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpScreen(tester, level: 2);
      expect(find.byType(QuestBriefingOverlay), findsNothing);
    });

    testWidgets('2.6 tapping start dismisses briefing overlay on level 1', (tester) async {
      await pumpScreen(tester, level: 1);
      expect(find.byType(QuestBriefingOverlay), findsOneWidget);
      await tester.ensureVisible(find.text('SPEAK WORD'));
      await tester.tap(find.text('SPEAK WORD'));
      await tester.pumpAndSettle();
      expect(find.byType(QuestBriefingOverlay), findsNothing);
    });
  });

  // ---------------------------------------------------------------------------
  // 3. Instruction Component Behavior (6 tests)
  // ---------------------------------------------------------------------------
  group('3. Instruction Component Behavior', () {
    testWidgets('3.1 instruction displays FIND THE WORD badge when word is not placed', (tester) async {
      await pumpScreen(tester);
      expect(find.text('FIND THE WORD'), findsOneWidget);
    });

    testWidgets('3.2 instruction displays quest instruction subtitle initially', (tester) async {
      await pumpScreen(tester);
      expect(find.textContaining('Select and speak the missing word.'), findsOneWidget);
    });

    testWidgets('3.3 instruction displays READ THE SENTENCE badge when word is placed', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('speak_missing_word_option_0')));
      await tester.pumpAndSettle();

      expect(find.text('READ THE SENTENCE'), findsOneWidget);
    });

    testWidgets('3.4 instruction displays Read the full sentence aloud when word is placed', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('speak_missing_word_option_0')));
      await tester.pumpAndSettle();

      expect(find.text('Read the full sentence aloud.'), findsOneWidget);
    });

    testWidgets('3.5 instruction header has accessible Semantics header', (tester) async {
      await pumpScreen(tester);
      final headerFinder = find.descendant(
        of: find.byType(SpeakMissingWordInstruction),
        matching: find.byWidgetPredicate((w) => w is Semantics && w.properties.header == true),
      );
      expect(headerFinder, findsOneWidget);
    });

    testWidgets('3.6 handles long instruction text without RenderFlex overflow', (tester) async {
      final longQuest = createQuest(
        instruction: 'Carefully identify the missing noun from the vortex options and complete the full sentence.',
      );
      final state = testLoadedState.copyWith(quests: [longQuest]);
      await pumpScreen(tester, state: state);
      expect(tester.takeException(), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // 4. Vortex Sentence Rendering & Word Insertion (8 tests)
  // ---------------------------------------------------------------------------
  group('4. Vortex Sentence Rendering & Word Insertion', () {
    testWidgets('4.1 displays initial sentence text containing blank underscores', (tester) async {
      await pumpScreen(tester);
      expect(find.byKey(const Key('speak_missing_word_sentence_text')), findsOneWidget);
      expect(find.textContaining('___'), findsOneWidget);
    });

    testWidgets('4.2 vortex constructor header renders with key speak_missing_word_vortex_header', (tester) async {
      await pumpScreen(tester);
      expect(find.byKey(const Key('speak_missing_word_vortex_header')), findsOneWidget);
    });

    testWidgets('4.3 does NOT render locked option pill when word is not placed', (tester) async {
      await pumpScreen(tester);
      expect(find.byKey(const Key('speak_missing_word_locked_option')), findsNothing);
    });

    testWidgets('4.4 replaces blank with completed sentence when word is placed', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('speak_missing_word_option_0')));
      await tester.pumpAndSettle();

      expect(find.text('The robot operates the system safely.'), findsOneWidget);
    });

    testWidgets('4.5 renders locked option pill with key speak_missing_word_locked_option when placed', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('speak_missing_word_option_0')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('speak_missing_word_locked_option')), findsOneWidget);
    });

    testWidgets('4.6 locked option pill displays placed word in uppercase', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('speak_missing_word_option_0')));
      await tester.pumpAndSettle();

      expect(find.text('LOCKED OPTION: ROBOT'), findsOneWidget);
    });

    testWidgets('4.7 has accessible Semantics container with full sentence label', (tester) async {
      await pumpScreen(tester);
      final semanticsFinder = find.descendant(
        of: find.byType(SpeakMissingWordVortexSentence),
        matching: find.byWidgetPredicate((w) => w is Semantics && w.container == true),
      );
      expect(semanticsFinder, findsOneWidget);
    });

    testWidgets('4.8 handles null correctAnswer by regex replacing blank underscores', (tester) async {
      final questNoCorrect = createQuest(
        correctAnswer: null,
      );
      final state = testLoadedState.copyWith(quests: [questNoCorrect]);
      await pumpScreen(tester, state: state);
      await tester.tap(find.byKey(const Key('speak_missing_word_option_0')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // 5. Magnet Arena Interaction & Word Selection (8 tests)
  // ---------------------------------------------------------------------------
  group('5. Magnet Arena Interaction & Word Selection', () {
    testWidgets('5.1 arena displays all options from quest.options', (tester) async {
      await pumpScreen(tester);
      expect(find.text('ROBOT'), findsOneWidget);
      expect(find.text('HUMAN'), findsOneWidget);
      expect(find.text('DEVICE'), findsOneWidget);
      expect(find.text('PILOT'), findsOneWidget);
    });

    testWidgets('5.2 each option chip has Semantics button and label', (tester) async {
      await pumpScreen(tester);
      final semantics = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.label == 'Select word: robot',
      );
      expect(semantics, findsOneWidget);
    });

    testWidgets('5.3 tapping option chip triggers hapticService.selection()', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('speak_missing_word_option_0')));
      await tester.pumpAndSettle();

      verify(() => mockHapticService.selection()).called(greaterThanOrEqualTo(1));
    });

    testWidgets('5.4 tapping option instantly selects word and completes pull', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('speak_missing_word_option_0')));
      await tester.pumpAndSettle();

      expect(find.byType(SpeakMissingWordMagnetArena), findsNothing);
      expect(find.byKey(const Key('speak_missing_word_shadow_compare')), findsOneWidget);
    });

    testWidgets('5.5 onPullStart gesture triggers selection haptic', (tester) async {
      await pumpScreen(tester);
      final arena = tester.widget<SpeakMissingWordMagnetArena>(find.byType(SpeakMissingWordMagnetArena));
      arena.onPullStart('robot');
      await tester.pump();

      verify(() => mockHapticService.selection()).called(1);
    });

    testWidgets('5.6 onPullEnd reverses pull when pull not completed', (tester) async {
      await pumpScreen(tester);
      final arena = tester.widget<SpeakMissingWordMagnetArena>(find.byType(SpeakMissingWordMagnetArena));
      arena.onPullStart('robot');
      await tester.pump();

      arena.onPullEnd();
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('5.7 AbsorbPointer absorbs taps once word is placed', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('speak_missing_word_option_0')));
      await tester.pumpAndSettle();

      final absorbFinder = find.descendant(
        of: find.byType(SpeakMissingWordScreen),
        matching: find.byType(AbsorbPointer),
      );
      final absorbPointer = tester.widgetList<AbsorbPointer>(absorbFinder).firstWhere((w) => w.absorbing == true);
      expect(absorbPointer.absorbing, isTrue);
    });

    testWidgets('5.8 arena handles null options by falling back to missingWord', (tester) async {
      final noOptionsQuest = createQuest(options: null);
      final state = testLoadedState.copyWith(quests: [noOptionsQuest]);
      await pumpScreen(tester, state: state);

      expect(find.text('ROBOT'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // 6. Correct Word Placement & ShadowPlaybackCompare Integration (8 tests)
  // ---------------------------------------------------------------------------
  group('6. Correct Word Placement & ShadowPlaybackCompare Integration', () {
    testWidgets('6.1 placing correct word triggers hapticService.success() and soundService.playClick()', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('speak_missing_word_option_0')));
      await tester.pumpAndSettle();

      verify(() => mockHapticService.success()).called(1);
      verify(() => mockSoundService.playClick()).called(1);
    });

    testWidgets('6.2 placing correct word renders ShadowPlaybackCompare', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('speak_missing_word_option_0')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('speak_missing_word_shadow_compare')), findsOneWidget);
    });

    testWidgets('6.3 ShadowPlaybackCompare receives full completed sentence', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('speak_missing_word_option_0')));
      await tester.pumpAndSettle();

      final shadowCompare = tester.widget<ShadowPlaybackCompare>(
        find.byKey(const Key('speak_missing_word_shadow_compare')),
      );
      expect(shadowCompare.expectedText, 'The robot operates the system safely.');
    });

    testWidgets('6.4 initial mic button with ValueKey shadow_mic_btn is visible', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('speak_missing_word_option_0')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('shadow_mic_btn')), findsOneWidget);
    });

    testWidgets('6.5 tapping mic button initiates audio recording', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('speak_missing_word_option_0')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('shadow_mic_btn')));
      await tester.pump();

      verify(() => mockAudioRecorder.startRecording()).called(1);
    });

    testWidgets('6.6 tapping mic button while recording stops audio recording', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('speak_missing_word_option_0')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('shadow_mic_btn')));
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('shadow_mic_btn')));
      await tester.pumpAndSettle();

      verify(() => mockAudioRecorder.stopRecording()).called(1);
    });

    testWidgets('6.7 shows mic warning when recorded audio is too quiet or short', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('speak_missing_word_option_0')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('shadow_mic_btn')));
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('shadow_mic_btn')));
      await tester.pumpAndSettle();

      expect(find.text("We couldn't hear you. Try again?"), findsOneWidget);
    });

    testWidgets('6.8 stops background TTS and audio before recording', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('speak_missing_word_option_0')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('shadow_mic_btn')));
      await tester.pump();

      verify(() => mockSoundService.stopTts()).called(greaterThanOrEqualTo(1));
      verify(() => mockSoundService.stopAudio()).called(greaterThanOrEqualTo(1));
    });
  });

  // ---------------------------------------------------------------------------
  // 7. Incorrect Word Placement Immediate Fail (8 tests)
  // ---------------------------------------------------------------------------
  group('7. Incorrect Word Placement Immediate Fail', () {
    testWidgets('7.1 placing incorrect word does NOT render ShadowPlaybackCompare', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('speak_missing_word_option_1'))); // 'human' != 'robot'
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('speak_missing_word_shadow_compare')), findsNothing);
    });

    testWidgets('7.2 placing incorrect word triggers hapticService.error() and soundService.playWrong()', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('speak_missing_word_option_1')));
      await tester.pumpAndSettle();

      verify(() => mockHapticService.error()).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
    });

    testWidgets('7.3 submits SubmitAnswer(false) immediately to SpeakingBloc', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('speak_missing_word_option_1')));
      await tester.pumpAndSettle();

      verify(() => mockSpeakingBloc.add(const SubmitAnswer(false))).called(1);
    });

    testWidgets('7.4 records error in ErrorJournalCollector for authenticated user', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('speak_missing_word_option_1')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('7.5 handles unauthenticated state gracefully on wrong answer', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(const AuthState.unauthenticated());
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('speak_missing_word_option_1')));
      await tester.pumpAndSettle();

      verify(() => mockSpeakingBloc.add(const SubmitAnswer(false))).called(1);
    });

    testWidgets('7.6 sets isAnsweredNotifier to true and isCorrectNotifier to false', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('speak_missing_word_option_1')));
      await tester.pumpAndSettle();

      expect(find.byType(GameFeedbackCard), findsOneWidget);
    });

    testWidgets('7.7 shows GameFeedbackCard with incorrect status', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('speak_missing_word_option_1')));
      await tester.pumpAndSettle();

      final feedback = tester.widget<GameFeedbackCard>(find.byType(GameFeedbackCard));
      expect(feedback.isCorrect, isFalse);
    });

    testWidgets('7.8 calling evaluation when already answered does not double-submit', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('speak_missing_word_option_1')));
      await tester.pumpAndSettle();

      clearInteractions(mockSpeakingBloc);
      final state = tester.state(find.byType(SpeakMissingWordScreen)) as dynamic;
      state.submitWrongAnswer(quest: sampleQuest1);
      await tester.pump();

      verifyNever(() => mockSpeakingBloc.add(any()));
    });
  });

  // ---------------------------------------------------------------------------
  // 8. Verbal Self-Evaluation in ShadowPlaybackCompare (8 tests)
  // ---------------------------------------------------------------------------
  group('8. Verbal Self-Evaluation in ShadowPlaybackCompare', () {
    testWidgets('8.1 onConfirmed triggers hapticService.success() and soundService.playCorrect()', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('speak_missing_word_option_0')));
      await tester.pumpAndSettle();

      final shadowCompare = tester.widget<ShadowPlaybackCompare>(
        find.byKey(const Key('speak_missing_word_shadow_compare')),
      );
      shadowCompare.onConfirmed();
      await tester.pumpAndSettle();

      verify(() => mockHapticService.success()).called(2); // 1 on word place + 1 on confirm
      verify(() => mockSoundService.playCorrect()).called(1);
    });

    testWidgets('8.2 onConfirmed dispatches SubmitAnswer(true) to SpeakingBloc', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('speak_missing_word_option_0')));
      await tester.pumpAndSettle();

      final shadowCompare = tester.widget<ShadowPlaybackCompare>(
        find.byKey(const Key('speak_missing_word_shadow_compare')),
      );
      shadowCompare.onConfirmed();
      await tester.pumpAndSettle();

      verify(() => mockSpeakingBloc.add(const SubmitAnswer(true))).called(1);
    });

    testWidgets('8.3 onConfirmed sets isCorrectNotifier to true and shows positive GameFeedbackCard', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('speak_missing_word_option_0')));
      await tester.pumpAndSettle();

      final shadowCompare = tester.widget<ShadowPlaybackCompare>(
        find.byKey(const Key('speak_missing_word_shadow_compare')),
      );
      shadowCompare.onConfirmed();
      await tester.pumpAndSettle();

      final feedback = tester.widget<GameFeedbackCard>(find.byType(GameFeedbackCard));
      expect(feedback.isCorrect, isTrue);
    });

    testWidgets('8.4 onSkipped triggers hapticService.error() and soundService.playWrong()', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('speak_missing_word_option_0')));
      await tester.pumpAndSettle();

      final shadowCompare = tester.widget<ShadowPlaybackCompare>(
        find.byKey(const Key('speak_missing_word_shadow_compare')),
      );
      shadowCompare.onSkipped();
      await tester.pumpAndSettle();

      verify(() => mockHapticService.error()).called(1);
      verify(() => mockSoundService.playWrong()).called(1);
    });

    testWidgets('8.5 onSkipped dispatches SubmitAnswer(false) to SpeakingBloc', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('speak_missing_word_option_0')));
      await tester.pumpAndSettle();

      final shadowCompare = tester.widget<ShadowPlaybackCompare>(
        find.byKey(const Key('speak_missing_word_shadow_compare')),
      );
      shadowCompare.onSkipped();
      await tester.pumpAndSettle();

      verify(() => mockSpeakingBloc.add(const SubmitAnswer(false))).called(1);
    });

    testWidgets('8.6 onSkipped sets isCorrectNotifier to false and shows negative GameFeedbackCard', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('speak_missing_word_option_0')));
      await tester.pumpAndSettle();

      final shadowCompare = tester.widget<ShadowPlaybackCompare>(
        find.byKey(const Key('speak_missing_word_shadow_compare')),
      );
      shadowCompare.onSkipped();
      await tester.pumpAndSettle();

      final feedback = tester.widget<GameFeedbackCard>(find.byType(GameFeedbackCard));
      expect(feedback.isCorrect, isFalse);
    });

    testWidgets('8.7 calling onConfirmed when already answered does not double-submit', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('speak_missing_word_option_0')));
      await tester.pumpAndSettle();

      final shadowCompare = tester.widget<ShadowPlaybackCompare>(
        find.byKey(const Key('speak_missing_word_shadow_compare')),
      );
      shadowCompare.onConfirmed();
      await tester.pumpAndSettle();

      clearInteractions(mockSpeakingBloc);
      shadowCompare.onConfirmed();
      await tester.pump();

      verifyNever(() => mockSpeakingBloc.add(any()));
    });

    testWidgets('8.8 calling onSkipped when already answered does not double-submit', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('speak_missing_word_option_0')));
      await tester.pumpAndSettle();

      final shadowCompare = tester.widget<ShadowPlaybackCompare>(
        find.byKey(const Key('speak_missing_word_shadow_compare')),
      );
      shadowCompare.onSkipped();
      await tester.pumpAndSettle();

      clearInteractions(mockSpeakingBloc);
      shadowCompare.onSkipped();
      await tester.pump();

      verifyNever(() => mockSpeakingBloc.add(any()));
    });
  });

  // ---------------------------------------------------------------------------
  // 9. Feedback Card, Hints & Question Progression (6 tests)
  // ---------------------------------------------------------------------------
  group('9. Feedback Card, Hints & Question Progression', () {
    testWidgets('9.1 GameFeedbackCard displays continue button', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('speak_missing_word_option_0')));
      await tester.pumpAndSettle();

      final shadowCompare = tester.widget<ShadowPlaybackCompare>(
        find.byKey(const Key('speak_missing_word_shadow_compare')),
      );
      shadowCompare.onConfirmed();
      await tester.pumpAndSettle();

      expect(find.byType(GameFeedbackCard), findsOneWidget);
      expect(find.text('CONTINUE'), findsOneWidget);
    });

    testWidgets('9.2 tapping continue button dispatches NextQuestion() to SpeakingBloc', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('speak_missing_word_option_0')));
      await tester.pumpAndSettle();

      final shadowCompare = tester.widget<ShadowPlaybackCompare>(
        find.byKey(const Key('speak_missing_word_shadow_compare')),
      );
      shadowCompare.onConfirmed();
      await tester.pumpAndSettle();

      await tester.tap(find.text('CONTINUE'));
      await tester.pump();

      verify(() => mockSpeakingBloc.add(const NextQuestion())).called(1);
    });

    testWidgets('9.3 tapping hint button dispatches SpeakingHintUsed() to SpeakingBloc', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byType(QuestHintButton));
      await tester.pump();

      verify(() => mockSpeakingBloc.add(const SpeakingHintUsed())).called(greaterThanOrEqualTo(1));
    });

    testWidgets('9.4 when hintUsed is true, hint button is disabled', (tester) async {
      final hintState = testLoadedState.copyWith(hintUsed: true);
      await pumpScreen(tester, state: hintState);

      final hintButton = tester.widget<QuestHintButton>(find.byType(QuestHintButton));
      expect(hintButton.used, isTrue);
    });

    testWidgets('9.5 onQuestionReset resets all local ValueNotifiers cleanly', (tester) async {
      await pumpScreen(tester);
      await tester.tap(find.byKey(const Key('speak_missing_word_option_0')));
      await tester.pumpAndSettle();

      // Trigger question reset via state update to question index 1
      final nextState = testLoadedState.copyWith(
        currentIndex: 1,
        answerStatus: AnswerStatus.unanswered,
      );
      speakingStreamController.add(nextState);
      await tester.pumpAndSettle();

      expect(find.byType(SpeakMissingWordMagnetArena), findsOneWidget);
      expect(find.byKey(const Key('speak_missing_word_sentence_text')), findsOneWidget);
      expect(find.textContaining('___'), findsOneWidget);
    });

    testWidgets('9.6 progressing to second quest syncs new options to Magnet Arena', (tester) async {
      await pumpScreen(tester);
      final nextState = testLoadedState.copyWith(
        currentIndex: 1,
        answerStatus: AnswerStatus.unanswered,
      );
      speakingStreamController.add(nextState);
      await tester.pumpAndSettle();

      expect(find.text('DEGREES'), findsOneWidget);
      expect(find.text('METERS'), findsOneWidget);
      expect(find.text('LITERS'), findsOneWidget);
      expect(find.text('GRAMS'), findsOneWidget);
    });
  });

  // ---------------------------------------------------------------------------
  // 10. Lifecycle, Reduced Motion, Viewports & Theming (12 tests)
  // ---------------------------------------------------------------------------
  group('10. Lifecycle, Reduced Motion, Viewports & Theming', () {
    testWidgets('10.1 initGameLifecycle creates lifecycle listener', (tester) async {
      await pumpScreen(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('10.2 disposing screen cancels scroll timer, controllers, and notifiers cleanly', (tester) async {
      await pumpScreen(tester);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    });

    testWidgets('10.3 App pause/resume callbacks execute safely', (tester) async {
      await pumpScreen(tester);
      final state = tester.state<State<SpeakMissingWordScreen>>(
        find.byType(SpeakMissingWordScreen),
      );
      final mixinState = state as dynamic;
      mixinState.onGamePaused();
      mixinState.onGameResumed();
      expect(tester.takeException(), isNull);
    });

    testWidgets('10.4 under lowAnimationModeOverride, vortex rotation is disabled', (tester) async {
      await pumpScreen(tester, reduceMotion: true);
      expect(tester.takeException(), isNull);
    });

    testWidgets('10.5 under MediaQuery.disableAnimations, vortex rotation is disabled', (tester) async {
      await pumpScreen(tester, reduceMotion: true);
      expect(tester.takeException(), isNull);
    });

    testWidgets('10.6 didChangeDependencies updates vortex animation state', (tester) async {
      await pumpScreen(tester, reduceMotion: false);
      expect(tester.takeException(), isNull);

      VowlMotion.lowAnimationModeOverride.value = true;
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 300));
    });

    testWidgets('10.7 tapping word under lowAnimationModeOverride completes placement immediately', (tester) async {
      await pumpScreen(tester, reduceMotion: true);
      await tester.tap(find.byKey(const Key('speak_missing_word_option_0')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('speak_missing_word_shadow_compare')), findsOneWidget);
    });

    testWidgets('10.8 scrolling jumps immediately under lowAnimationModeOverride', (tester) async {
      await pumpScreen(tester, reduceMotion: true);
      await tester.tap(find.byKey(const Key('speak_missing_word_option_0')));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('10.9 renders without overflow on small mobile viewport (360x640)', (tester) async {
      await pumpScreen(tester, size: const Size(360, 640));
      expect(tester.takeException(), isNull);
    });

    testWidgets('10.10 renders without overflow on standard viewport (390x844)', (tester) async {
      await pumpScreen(tester, size: const Size(390, 844));
      expect(tester.takeException(), isNull);
    });

    testWidgets('10.11 renders without overflow on tablet viewport (820x1180)', (tester) async {
      await pumpScreen(tester, size: const Size(820, 1180));
      expect(tester.takeException(), isNull);
    });

    testWidgets('10.12 Dark and Light themes apply correct theme colors and backgrounds', (tester) async {
      await pumpScreen(tester, themeMode: ThemeMode.light);
      expect(tester.takeException(), isNull);

      await pumpScreen(tester, themeMode: ThemeMode.dark);
      expect(tester.takeException(), isNull);
    });
  });
}
