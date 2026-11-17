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
import 'package:vowl/features/vocabulary/idioms/presentation/pages/idioms_mastery_screen.dart';
import 'package:vowl/features/vocabulary/idioms/presentation/widgets/idioms_option_chip.dart';
import 'package:vowl/features/vocabulary/idioms/presentation/widgets/idioms_origin_card.dart';
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

class FakeVocabularyEvent extends Fake implements VocabularyEvent {}

class FakeVocabularyState extends Fake implements VocabularyState {}

class FakeEconomyEvent extends Fake implements EconomyEvent {}

class FakeEconomyState extends Fake implements EconomyState {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({
    'has_seen_briefing_idioms': true,
  });

  late MockVocabularyBloc mockVocabularyBloc;
  late MockAuthBloc mockAuthBloc;
  late MockEconomyBloc mockEconomyBloc;
  late MockHapticService mockHapticService;
  late MockSoundService mockSoundService;
  late MockTtsService mockTtsService;
  late MockAudioRecordingService mockAudioRecordingService;
  late MockSpeechService mockSpeechService;
  late MockLocaleService mockLocaleService;
  late MockAppLogger mockAppLogger;
  late MockAnalyticsService mockAnalyticsService;
  late MockAdService mockAdService;
  late MockNetworkInfo mockNetworkInfo;
  late StreamController<VocabularyState> vocabularyStreamController;

  const testQuest = VocabularyQuest(
    id: 'VOC_IDIOMS_L1_Q1',
    type: QuestType.vocabulary,
    subtype: GameSubtype.idioms,
    word: 'PIECE OF CAKE',
    correctAnswer: 'PIECE OF CAKE',
    options: ['PIECE OF CAKE', 'HIT THE ROAD', 'BREAK THE ICE', 'SAVE FOR A RAINY DAY'],
    instruction: 'Select the idiom that matches the meaning.',
    hint: "It's about food, but not about eating.",
    explanation: "'Piece of cake' describes a task that takes almost no effort.",
    literalVsFigurative:
        'Literal: A slice of dessert | Figurative: Something effortless to accomplish.',
    contextSentence: 'Don\'t stress about the test — it\'ll be a piece of cake.',
    topicEmoji: '🍰😌',
    origin: 'Recorded in American English since the 1930s.',
    difficulty: 1,
  );

  final testLoadedState = VocabularyLoaded(
    quests: const [testQuest],
    currentIndex: 0,
    livesRemaining: 3,
    answerStatus: AnswerStatus.unanswered,
    wrongCount: 0,
    hintUsed: false,
    isFinalFailure: false,
  );

  setUpAll(() {
    registerFallbackValue(FakeVocabularyEvent());
    registerFallbackValue(FakeVocabularyState());
    registerFallbackValue(FakeEconomyEvent());
    registerFallbackValue(FakeEconomyState());
    registerFallbackValue(const SubmitAnswer(true));
    registerFallbackValue(const SubmitAnswer(false));
    registerFallbackValue(const NextQuestion());
    registerFallbackValue(
      const FetchVocabularyQuests(gameType: GameSubtype.idioms, level: 2),
    );
  });

  setUp(() async {
    VowlMotion.lowAnimationModeOverride.value = true;

    mockVocabularyBloc = MockVocabularyBloc();
    mockAuthBloc = MockAuthBloc();
    mockEconomyBloc = MockEconomyBloc();
    mockHapticService = MockHapticService();
    mockSoundService = MockSoundService();
    mockTtsService = MockTtsService();
    mockAudioRecordingService = MockAudioRecordingService();
    mockSpeechService = MockSpeechService();
    mockLocaleService = MockLocaleService();
    mockAppLogger = MockAppLogger();
    mockAnalyticsService = MockAnalyticsService();
    mockAdService = MockAdService();
    mockNetworkInfo = MockNetworkInfo();

    vocabularyStreamController = StreamController<VocabularyState>.broadcast();

    when(() => mockVocabularyBloc.state).thenReturn(testLoadedState);
    when(() => mockVocabularyBloc.stream)
        .thenAnswer((_) => vocabularyStreamController.stream);

    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(
        const UserEntity(
          id: 'test_user_1',
          email: 'test@vowl.app',
          displayName: 'Mastery Tester',
        ),
      ),
    );
    when(() => mockAuthBloc.stream).thenAnswer(
      (_) => Stream.value(
        AuthState.authenticated(
          const UserEntity(
            id: 'test_user_1',
            email: 'test@vowl.app',
            displayName: 'Mastery Tester',
          ),
        ),
      ),
    );

    when(() => mockEconomyBloc.state).thenReturn(const EconomyState());
    when(() => mockEconomyBloc.stream)
        .thenAnswer((_) => Stream.value(const EconomyState()));

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});
    when(() => mockSoundService.playCorrect(comboStep: any(named: 'comboStep')))
        .thenAnswer((_) async {});
    when(() => mockSoundService.playWrong()).thenAnswer((_) async {});
    when(() => mockSoundService.stopTts()).thenAnswer((_) async {});
    when(() => mockSoundService.stopAudio()).thenAnswer((_) async {});
    when(() => mockTtsService.stop()).thenAnswer((_) async {});
    when(() => mockTtsService.speak(any())).thenAnswer((_) async {});
    when(() => mockSpeechService.isListening).thenReturn(false);
    when(() => mockSpeechService.isPlaying).thenReturn(false);
    when(() => mockSpeechService.stop()).thenAnswer((_) async {});
    when(() => mockSpeechService.cancel()).thenAnswer((_) async {});
    when(() => mockSpeechService.initializeStt()).thenAnswer((_) async => true);
    when(() => mockAudioRecordingService.isRecording).thenReturn(false);
    when(() => mockLocaleService.currentLocale).thenReturn(const Locale('en'));
    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

    await di.sl.reset();
    di.sl.registerSingleton<HapticService>(mockHapticService);
    di.sl.registerSingleton<SoundService>(mockSoundService);
    di.sl.registerSingleton<TtsService>(mockTtsService);
    di.sl.registerSingleton<AudioRecordingService>(mockAudioRecordingService);
    di.sl.registerSingleton<SpeechService>(mockSpeechService);
    di.sl.registerSingleton<LocaleService>(mockLocaleService);
    di.sl.registerSingleton<AppLogger>(mockAppLogger);
    di.sl.registerSingleton<AnalyticsService>(mockAnalyticsService);
    di.sl.registerSingleton<AdService>(mockAdService);
    di.sl.registerSingleton<NetworkInfo>(mockNetworkInfo);
  });

  tearDown(() async {
    await vocabularyStreamController.close();
    await di.sl.reset();
  });

  Widget buildTestableWidget(Widget child) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<VocabularyBloc>.value(value: mockVocabularyBloc),
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        BlocProvider<EconomyBloc>.value(value: mockEconomyBloc),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, _) => MaterialApp(
          theme: AppTheme.darkTheme,
          home: child,
        ),
      ),
    );
  }

  group('IdiomsMasteryScreen', () {
    testWidgets(
        'Stage 1: renders emoji clues and chips, answers correctly, unlocks Stage 2 bonus arena',
        (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestableWidget(
          const IdiomsMasteryScreen(level: 2),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(IdiomsMasteryScreen), findsOneWidget);
      expect(find.text('PIECE OF CAKE'), findsWidgets);

      // Tap correct IdiomsOptionChip
      final chipFinder = find.widgetWithText(IdiomsOptionChip, 'PIECE OF CAKE');
      expect(chipFinder, findsOneWidget);
      await tester.tap(chipFinder);
      await tester.pump();

      // Elapse submit timer & scroll animation timers
      await tester.pump(const Duration(milliseconds: 650));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump(const Duration(milliseconds: 650));

      // Stage 2 Bonus Arena revealed
      expect(
        find.textContaining('BONUS XP ARENA'),
        findsOneWidget,
      );
      expect(find.byType(IdiomsOriginCard), findsOneWidget);
      expect(find.byType(SpeakToConfirmOverlay), findsOneWidget);

      // Verify penalty-free skip in Mastery mode
      final overlayFinder = find.byType(SpeakToConfirmOverlay);
      expect(overlayFinder, findsOneWidget);
      final overlay = tester.widget<SpeakToConfirmOverlay>(overlayFinder);

      overlay.onSkipped.call();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verifies that SubmitAnswer(true) was dispatched on skip (banking victory with 0 penalty)
      verify(() => mockVocabularyBloc.add(any(that: isA<SubmitAnswer>()
          .having((e) => e.isCorrect, 'isCorrect', true)))).called(1);
    });
  });
}
