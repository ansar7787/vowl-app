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
import 'package:vowl/core/presentation/widgets/tts_speaker_button_widget.dart';
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
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/controllers/synonym_grid_builder.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/pages/synonym_search_mastery_screen.dart';

class _MockVocabularyBloc extends MockBloc<VocabularyEvent, VocabularyState>
    implements VocabularyBloc {}

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _MockEconomyBloc extends MockBloc<EconomyEvent, EconomyState>
    implements EconomyBloc {}

class _MockHapticService extends Mock implements HapticService {}

class _MockSoundService extends Mock implements SoundService {}

class _MockTtsService extends Mock implements TtsService {}

class _MockAudioRecordingService extends Mock
    implements AudioRecordingService {}

class _MockSpeechService extends Mock implements SpeechService {}

class _MockLocaleService extends Mock implements LocaleService {}

class _MockAppLogger extends Mock implements AppLogger {}

class _MockAnalyticsService extends Mock implements AnalyticsService {}

class _MockAdService extends Mock implements AdService {}

class _MockNetworkInfo extends Mock implements NetworkInfo {}

class _FakeVocabularyEvent extends Fake implements VocabularyEvent {}

class _FakeVocabularyState extends Fake implements VocabularyState {}

class _FakeEconomyEvent extends Fake implements EconomyEvent {}

class _FakeEconomyState extends Fake implements EconomyState {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockVocabularyBloc mockVocabularyBloc;
  late _MockAuthBloc mockAuthBloc;
  late _MockEconomyBloc mockEconomyBloc;
  late _MockHapticService mockHapticService;
  late _MockSoundService mockSoundService;
  late _MockTtsService mockTtsService;
  late _MockAudioRecordingService mockAudioRecorder;
  late _MockSpeechService mockSpeechService;
  late _MockLocaleService mockLocaleService;
  late _MockAppLogger mockAppLogger;
  late _MockAnalyticsService mockAnalyticsService;
  late _MockAdService mockAdService;
  late _MockNetworkInfo mockNetworkInfo;
  late StreamController<VocabularyState> streamController;

  const quest1 = VocabularyQuest(
    id: 'VOC_SYNONYMSEARCH_L1_Q1',
    type: QuestType.vocabulary,
    subtype: GameSubtype.synonymSearch,
    instruction: 'Find and trace the synonym.',
    word: 'Big',
    definition: 'Of considerable size, amount, or scale.',
    synonym: 'Large',
    correctAnswer: 'Large',
    correctAnswerIndex: 2,
    options: ['Tiny', 'Narrow', 'Large', 'Short'],
    contextSentence: 'The elephant is a very ___ animal.',
    usageExample: 'A large crowd waited outside the gates.',
    explanation: "'Large' matches 'big' for measurable physical size.",
    hint: "Look for the factual size word used in 'large crowd'.",
    difficulty: 1,
  );

  const quest2 = VocabularyQuest(
    id: 'VOC_SYNONYMSEARCH_L1_Q2',
    type: QuestType.vocabulary,
    subtype: GameSubtype.synonymSearch,
    instruction: 'Find and trace the synonym.',
    word: 'Happy',
    definition: 'Feeling pleasure or contentment.',
    synonym: 'Glad',
    correctAnswer: 'Glad',
    correctAnswerIndex: 1,
    options: ['Angry', 'Glad', 'Tired', 'Late'],
    contextSentence: 'I am so ___ that we finished early.',
    usageExample: 'She felt glad about the warm welcome.',
    explanation: "'Glad' matches warm polite pleasure.",
    hint: 'Four letters starting with G.',
    difficulty: 1,
  );

  final initialLoaded = const VocabularyLoaded(
    quests: [quest1, quest2],
    currentIndex: 0,
    livesRemaining: 3,
    wrongCount: 0,
    hintUsed: false,
    hintsAvailable: 2,
    answerStatus: AnswerStatus.unanswered,
  );

  setUpAll(() {
    registerFallbackValue(_FakeVocabularyEvent());
    registerFallbackValue(_FakeVocabularyState());
    registerFallbackValue(_FakeEconomyEvent());
    registerFallbackValue(_FakeEconomyState());
    registerFallbackValue(const SubmitAnswer(true));
    registerFallbackValue(const SubmitAnswer(false));
  });

  setUp(() async {
    VowlMotion.lowAnimationModeOverride.value = true;
    SharedPreferences.setMockInitialValues({
      'has_seen_briefing_synonymSearch': true,
    });
    await di.sl.reset();

    mockVocabularyBloc = _MockVocabularyBloc();
    mockAuthBloc = _MockAuthBloc();
    mockEconomyBloc = _MockEconomyBloc();
    mockHapticService = _MockHapticService();
    mockSoundService = _MockSoundService();
    mockTtsService = _MockTtsService();
    mockAudioRecorder = _MockAudioRecordingService();
    mockSpeechService = _MockSpeechService();
    mockLocaleService = _MockLocaleService();
    mockAppLogger = _MockAppLogger();
    mockAnalyticsService = _MockAnalyticsService();
    mockAdService = _MockAdService();
    mockNetworkInfo = _MockNetworkInfo();
    streamController = StreamController<VocabularyState>.broadcast();

    when(() => mockVocabularyBloc.state).thenReturn(initialLoaded);
    whenListen(
      mockVocabularyBloc,
      streamController.stream,
      initialState: initialLoaded,
    );

    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(
        const UserEntity(
          id: 'u1',
          email: 'u1@vowl.app',
          displayName: 'Learner',
          hintCount: 3,
        ),
      ),
    );
    when(
      () => mockAuthBloc.stream,
    ).thenAnswer((_) => const Stream<AuthState>.empty());
    when(() => mockEconomyBloc.state).thenReturn(const EconomyState());
    when(
      () => mockEconomyBloc.stream,
    ).thenAnswer((_) => const Stream<EconomyState>.empty());

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

    when(
      () => mockTtsService.isSpeakingNotifier,
    ).thenReturn(ValueNotifier<bool>(false));
    when(
      () => mockTtsService.preWarm(locale: any(named: 'locale')),
    ).thenAnswer((_) async {});
    when(() => mockTtsService.stop()).thenAnswer((_) async {});
    when(
      () => mockTtsService.speak(
        any(),
        rate: any(named: 'rate'),
        locale: any(named: 'locale'),
      ),
    ).thenAnswer((_) async {});

    when(() => mockAudioRecorder.hasPermission()).thenAnswer((_) async => true);
    when(
      () => mockAudioRecorder.startRecording(),
    ).thenAnswer((_) async => true);
    when(
      () => mockAudioRecorder.stopRecording(),
    ).thenAnswer((_) async => '/tmp/t.m4a');
    when(() => mockAudioRecorder.isRecording).thenReturn(false);
    when(() => mockAudioRecorder.dispose()).thenAnswer((_) async {});
    when(() => mockSpeechService.initializeStt()).thenAnswer((_) async => true);
    when(() => mockSpeechService.stop()).thenAnswer((_) async {});
    when(() => mockSpeechService.cancel()).thenAnswer((_) async {});
    when(() => mockSpeechService.isListening).thenReturn(false);
    when(() => mockSpeechService.isPlaying).thenReturn(false);
    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

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
  });

  tearDown(() async {
    await streamController.close();
    VowlMotion.lowAnimationModeOverride.value = false;
    await di.sl.reset();
  });

  Future<void> pumpMastery(WidgetTester tester, {int level = 1}) async {
    tester.view.physicalSize = const Size(780, 1688);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<VocabularyBloc>.value(value: mockVocabularyBloc),
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<EconomyBloc>.value(value: mockEconomyBloc),
        ],
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, _) => MaterialApp(
            theme: AppTheme.lightTheme,
            home: SynonymSearchMasteryScreen(level: level),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('SynonymSearchMasteryScreen', () {
    test('SynonymSearchMasteryScreen typedef aliases SynonymSearchScreen', () {
      const screen = SynonymSearchMasteryScreen(level: 1);
      expect(screen, isA<SynonymSearchScreen>());
    });

    testWidgets(
      'hydrates grid immediately from VocabularyLoaded with non-spoiler TTS',
      (tester) async {
        await pumpMastery(tester);

        expect(find.byKey(const Key('synonym_word_grid')), findsOneWidget);
        expect(find.text('Big'), findsOneWidget);
        expect(find.text('Ready'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);

        final ttsWidget = tester.widget<TtsSpeakerButtonWidget>(
          find.byKey(const Key('mastery_nonspoiler_tts')),
        );
        expect(ttsWidget.text, contains('Big'));
        expect(ttsWidget.text.toLowerCase(), isNot(contains('large')));
        expect(ttsWidget.text, isNot(contains('crowd waited')));

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 300));
      },
    );

    testWidgets(
      'solves board via tap-to-trace, increments combo, and dispatches SubmitAnswer(true)',
      (tester) async {
        await pumpMastery(tester);

        final grid = SynonymGridBuilder.build(
          questId: quest1.id,
          correctAnswer: quest1.correctAnswer!,
          options: quest1.options!,
        );

        for (final cellIdx in grid.targetPathIndices) {
          final cellFinder = find.byKey(Key('grid_cell_$cellIdx'));
          await tester.ensureVisible(cellFinder);
          await tester.pump();
          await tester.tap(cellFinder);
          await tester.pump();
        }

        await tester.pump(const Duration(milliseconds: 300));
        verify(
          () => mockVocabularyBloc.add(const SubmitAnswer(true)),
        ).called(1);
        expect(find.text('x1'), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 300));
      },
    );

    testWidgets(
      'timer expiry dispatches SubmitAnswer(false) and resets combo cleanly',
      (tester) async {
        await pumpMastery(tester, level: 1);

        // Level 1 A2 word 'Large' -> 28s countdown
        await tester.pump(const Duration(seconds: 29));
        await tester.pump(const Duration(milliseconds: 300));

        verify(
          () => mockVocabularyBloc.add(const SubmitAnswer(false)),
        ).called(1);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 300));
      },
    );

    testWidgets(
      'supports continuous pointer drag-tracing across grid cells without scroll stealing',
      (tester) async {
        await pumpMastery(tester);

        final grid = SynonymGridBuilder.build(
          questId: quest1.id,
          correctAnswer: quest1.correctAnswer!,
          options: quest1.options!,
        );
        final path = grid.targetPathIndices;
        final firstCell = find.byKey(Key('grid_cell_${path.first}'));
        await tester.ensureVisible(firstCell);
        await tester.pump();

        final gesture = await tester.startGesture(tester.getCenter(firstCell));
        await tester.pump();
        for (int i = 1; i < path.length; i++) {
          final nextCenter = tester.getCenter(
            find.byKey(Key('grid_cell_${path[i]}')),
          );
          await gesture.moveTo(nextCenter);
          await tester.pump(const Duration(milliseconds: 16));
        }
        await gesture.up();
        await tester.pump(const Duration(milliseconds: 300));

        verify(
          () => mockVocabularyBloc.add(const SubmitAnswer(true)),
        ).called(1);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 300));
      },
    );

    testWidgets(
      'resets traced path cleanly when restarting Quest 0 via VocabularyLoading -> VocabularyLoaded',
      (tester) async {
        await pumpMastery(tester);

        final grid = SynonymGridBuilder.build(
          questId: quest1.id,
          correctAnswer: quest1.correctAnswer!,
          options: quest1.options!,
        );
        final cellFinder = find.byKey(
          Key('grid_cell_${grid.targetPathIndices.first}'),
        );
        await tester.ensureVisible(cellFinder);
        await tester.tap(cellFinder);
        await tester.pump();

        expect(find.textContaining('Word:'), findsOneWidget);

        // Simulate Pause -> Restart returning back to Quest 0
        when(
          () => mockVocabularyBloc.state,
        ).thenReturn(const VocabularyLoading());
        streamController.add(const VocabularyLoading());
        await tester.pump();

        when(() => mockVocabularyBloc.state).thenReturn(initialLoaded);
        streamController.add(initialLoaded);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Slide or tap nearby letters'), findsOneWidget);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 300));
      },
    );
  });
}
