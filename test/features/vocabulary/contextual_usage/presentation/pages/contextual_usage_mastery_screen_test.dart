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
import 'package:vowl/core/utils/audio_recording_service.dart';
import 'package:vowl/core/utils/speech_service.dart';
import 'package:vowl/core/theme/app_theme.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
import 'package:vowl/core/utils/ad_service.dart';
import 'package:vowl/core/utils/analytics_service.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/sound_service.dart';
import 'package:vowl/core/utils/tts_service.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/bloc/economy_bloc.dart';
import 'package:vowl/features/vocabulary/domain/entities/vocabulary_quest.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:vowl/features/vocabulary/contextual_usage/presentation/pages/contextual_usage_mastery_screen.dart';
import 'package:vowl/features/vocabulary/contextual_usage/presentation/widgets/contextual_usage_card.dart';

class MockVocabularyBloc extends MockBloc<VocabularyEvent, VocabularyState>
    implements VocabularyBloc {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockEconomyBloc extends MockBloc<EconomyEvent, EconomyState>
    implements EconomyBloc {}

class MockHapticService extends Mock implements HapticService {}

class MockSoundService extends Mock implements SoundService {}

class MockTtsService extends Mock implements TtsService {}

class MockLocaleService extends Mock implements LocaleService {}

class MockAppLogger extends Mock implements AppLogger {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockAdService extends Mock implements AdService {}

class MockNetworkInfo extends Mock implements NetworkInfo {}

class MockAudioRecordingService extends Mock
    implements AudioRecordingService {}

class MockSpeechService extends Mock implements SpeechService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockVocabularyBloc mockVocabularyBloc;
  late MockAuthBloc mockAuthBloc;
  late MockEconomyBloc mockEconomyBloc;
  late MockHapticService mockHapticService;
  late MockSoundService mockSoundService;
  late MockTtsService mockTtsService;
  late MockLocaleService mockLocaleService;
  late MockAppLogger mockAppLogger;
  late MockAnalyticsService mockAnalyticsService;
  late MockAdService mockAdService;
  late MockNetworkInfo mockNetworkInfo;
  late MockAudioRecordingService mockAudioRecorder;
  late MockSpeechService mockSpeechService;
  late StreamController<VocabularyState> vocabularyStreamController;

  const testQuest = VocabularyQuest(
    id: 'VOC_CONTEXTUAL_L2_Q1',
    type: QuestType.vocabulary,
    subtype: GameSubtype.contextualUsage,
    word: 'BORROW',
    correctAnswer: 'BORROW',
    options: ['LEND', 'RENT', 'BORROW', 'LOAN'],
    instruction: 'Select the word that best completes the sentence.',
    hint: 'Think about who is receiving the item temporarily.',
    explanation: 'Borrow means receiving temporarily.',
    prompt: "Could I _____ your pen? I'll give it back after class.",
    contextSentence: "Could I borrow your pen? I'll give it back after class.",
    registerLevel: 1,
    difficulty: 1,
  );

  const testLoadedState = VocabularyLoaded(
    quests: [testQuest],
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
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    vocabularyStreamController = StreamController<VocabularyState>.broadcast();

    mockVocabularyBloc = MockVocabularyBloc();
    mockAuthBloc = MockAuthBloc();
    mockEconomyBloc = MockEconomyBloc();
    mockHapticService = MockHapticService();
    mockSoundService = MockSoundService();
    mockTtsService = MockTtsService();
    mockLocaleService = MockLocaleService();
    mockAppLogger = MockAppLogger();
    mockAnalyticsService = MockAnalyticsService();
    mockAdService = MockAdService();
    mockNetworkInfo = MockNetworkInfo();
    mockAudioRecorder = MockAudioRecordingService();
    mockSpeechService = MockSpeechService();

    when(() => mockVocabularyBloc.state).thenReturn(testLoadedState);
    whenListen(
      mockVocabularyBloc,
      vocabularyStreamController.stream,
      initialState: testLoadedState,
    );

    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(
        const UserEntity(
          id: 'test_user_ctx',
          email: 'ctx@vowl.app',
          displayName: 'Context Specialist',
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
    when(() => mockAudioRecorder.stopRecording()).thenAnswer((_) async => '/tmp/ctx.m4a');
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
    di.sl.registerSingleton<LocaleService>(mockLocaleService);
    di.sl.registerSingleton<AppLogger>(mockAppLogger);
    di.sl.registerSingleton<AnalyticsService>(mockAnalyticsService);
    di.sl.registerSingleton<AdService>(mockAdService);
    di.sl.registerSingleton<NetworkInfo>(mockNetworkInfo);
    di.sl.registerSingleton<AudioRecordingService>(mockAudioRecorder);
    di.sl.registerSingleton<SpeechService>(mockSpeechService);

    VowlMotion.lowAnimationModeOverride.value = true;
  });

  tearDown(() async {
    await vocabularyStreamController.close();
    VowlMotion.lowAnimationModeOverride.value = false;
  });

  Widget buildTestableWidget(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, _) => MultiBlocProvider(
        providers: [
          BlocProvider<VocabularyBloc>.value(value: mockVocabularyBloc),
          BlocProvider<AuthBloc>.value(value: mockAuthBloc),
          BlocProvider<EconomyBloc>.value(value: mockEconomyBloc),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              disableAnimations: true,
            ),
            child: Scaffold(body: child),
          ),
        ),
      ),
    );
  }

  group('ContextualUsageMasteryScreen', () {
    testWidgets(
        'renders Stage 1 card, passes stage 1, reveals Bonus XP Arena, and banks win',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844) * 2.0;
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestableWidget(
          const ContextualUsageMasteryScreen(level: 2),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ContextualUsageMasteryScreen), findsOneWidget);
      expect(find.byType(ContextualUsageCard), findsOneWidget);

      // Tap Borrow option chip (formatted display word)
      final correctChip = find.text('Borrow');
      expect(correctChip, findsWidgets);
      await tester.tap(correctChip.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      // Stage 1 passed -> Bonus XP Arena appears!
      expect(find.textContaining('BONUS XP ARENA'), findsOneWidget);
      final bankButton =
          find.byKey(const Key('contextual_usage_bonus_bank_button'));
      expect(bankButton, findsOneWidget);
      await tester.ensureVisible(bankButton);

      // Tap Bank Win button (+50 XP bonus, 0 hearts deducted)
      await tester.tap(bankButton, warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify answer was submitted as victory to bloc
      verify(() => mockVocabularyBloc.add(const SubmitAnswer(true))).called(1);
    });
  });
}
