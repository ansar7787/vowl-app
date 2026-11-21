import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/presentation/widgets/game_error_view.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/core/theme/vowl_motion.dart';
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
import 'package:vowl/features/vocabulary/presentation/layout/vocabulary_base_layout.dart';
import 'package:vowl/features/vocabulary/topic_vocab/presentation/pages/topic_vocab_screen.dart';
import 'package:vowl/features/vocabulary/topic_vocab/presentation/widgets/topic_vocab_mind_map.dart';

class MockVocabularyBloc extends MockBloc<VocabularyEvent, VocabularyState> implements VocabularyBloc {}
class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}
class MockEconomyBloc extends MockBloc<EconomyEvent, EconomyState> implements EconomyBloc {}
class MockHapticService extends Mock implements HapticService {}
class MockSoundService extends Mock implements SoundService {}
class MockTtsService extends Mock implements TtsService {}
class MockLocaleService extends Mock implements LocaleService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockVocabularyBloc mockVocabularyBloc;
  late MockAuthBloc mockAuthBloc;
  late MockEconomyBloc mockEconomyBloc;
  late MockHapticService mockHapticService;
  late MockSoundService mockSoundService;
  late MockTtsService mockTtsService;
  late MockLocaleService mockLocaleService;
  late StreamController<VocabularyState> vocabularyStreamController;

  final testQuest = VocabularyQuest(
    id: 'VOC_TOPICVOCAB_L1_LAYOUT_Q1',
    instruction: 'Fuse the matching topic clusters before time expires!',
    difficulty: 1,
    topicEmoji: '🏷️',
    topicBuckets: const ['Intense Heat', 'Extreme Cold'],
    options: const ['Boiling', 'Scorching', 'Steaming', 'Freezing', 'Icy', 'Chilly'],
    correctAnswer:
        'Intense Heat:Boiling, Intense Heat:Scorching, Intense Heat:Steaming, Extreme Cold:Freezing, Extreme Cold:Icy, Extreme Cold:Chilly',
    relatedWords: const ['Boiling: Liquid heated to 100C', 'Freezing: Ice at 0C'],
    explanation: 'Heat terms vs Cold terms.',
  );

  setUpAll(() {
    registerFallbackValue(const SubmitAnswer(true));
    registerFallbackValue(const SubmitAnswer(false));
    registerFallbackValue(const NextQuestion());
    registerFallbackValue(const RetryCurrentQuestion());
  });

  setUp(() async {
    VowlMotion.lowAnimationModeOverride.value = true;
    SharedPreferences.setMockInitialValues({
      'has_seen_briefing_topicVocab': true,
    });

    mockVocabularyBloc = MockVocabularyBloc();
    mockAuthBloc = MockAuthBloc();
    mockEconomyBloc = MockEconomyBloc();
    mockHapticService = MockHapticService();
    mockSoundService = MockSoundService();
    mockTtsService = MockTtsService();
    mockLocaleService = MockLocaleService();

    vocabularyStreamController = StreamController<VocabularyState>.broadcast();

    final initialLoaded = VocabularyLoaded(
      quests: [testQuest],
      currentIndex: 0,
      livesRemaining: 3,
      answerStatus: AnswerStatus.unanswered,
    );

    when(() => mockVocabularyBloc.state).thenReturn(initialLoaded);
    whenListen(
      mockVocabularyBloc,
      vocabularyStreamController.stream,
      initialState: initialLoaded,
    );

    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.light()).thenAnswer((_) async {});
    when(() => mockHapticService.heavy()).thenAnswer((_) async {});
    when(() => mockHapticService.warning()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});

    when(() => mockSoundService.playCorrect()).thenAnswer((_) async {});
    when(() => mockSoundService.playCorrect(comboStep: any(named: 'comboStep'))).thenAnswer((_) async {});
    when(() => mockSoundService.playWrong()).thenAnswer((_) async {});
    when(() => mockSoundService.playSoftWrong()).thenAnswer((_) async {});
    when(() => mockSoundService.stopAudio()).thenAnswer((_) async {});
    when(() => mockSoundService.stopTts()).thenAnswer((_) async {});

    when(() => mockTtsService.stop()).thenAnswer((_) async {});
    when(() => mockTtsService.preWarm()).thenAnswer((_) async {});
    when(() => mockTtsService.speak(any(), rate: any(named: 'rate'), locale: any(named: 'locale')))
        .thenAnswer((_) async {});

    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(
        const UserEntity(
          id: 'test_user_topic',
          email: 'topic@vowl.app',
          displayName: 'Topic Master',
          hintCount: 3,
        ),
      ),
    );
    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream<AuthState>.empty());

    when(() => mockEconomyBloc.state).thenReturn(const EconomyState());
    when(() => mockEconomyBloc.stream).thenAnswer((_) => const Stream<EconomyState>.empty());

    await di.sl.reset();
    di.sl.registerSingleton<HapticService>(mockHapticService);
    di.sl.registerSingleton<SoundService>(mockSoundService);
    di.sl.registerSingleton<TtsService>(mockTtsService);
    di.sl.registerSingleton<LocaleService>(mockLocaleService);
  });

  tearDown(() {
    VowlMotion.lowAnimationModeOverride.value = false;
    vocabularyStreamController.close();
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
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(body: child),
          ),
        ),
      ),
    );
  }

  group('TopicVocabScreen Layout & States', () {
    testWidgets('displays ShimmerLoading during VocabularyLoading state', (tester) async {
      when(() => mockVocabularyBloc.state).thenReturn(const VocabularyLoading());

      await tester.pumpWidget(buildTestableWidget(const TopicVocabScreen(level: 1)));
      await tester.pump();
      expect(find.byType(ShimmerLoading), findsWidgets);
    });

    testWidgets('displays GameErrorView on VocabularyError with retry button', (tester) async {
      when(() => mockVocabularyBloc.state).thenReturn(const VocabularyError('Network Failure'));

      await tester.pumpWidget(buildTestableWidget(const TopicVocabScreen(level: 1)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(GameErrorView), findsOneWidget);
      expect(find.text('Network Failure'), findsOneWidget);

      await tester.tap(find.text('TRY AGAIN'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      verify(() => mockVocabularyBloc.add(any(that: isA<FetchVocabularyQuests>()))).called(2);
    });

    testWidgets('renders TopicVocabMindMap inside feedback when answer is submitted', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const TopicVocabScreen(level: 1)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Emit answered state
      vocabularyStreamController.add(
        VocabularyLoaded(
          quests: [testQuest],
          currentIndex: 0,
          livesRemaining: 3,
          answerStatus: AnswerStatus.correct,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(TopicVocabMindMap), findsOneWidget);
      expect(find.textContaining('Boiling'), findsWidgets);
    });

    testWidgets('renders TRY AGAIN on incorrect answer and onContinue dispatches RetryCurrentQuestion', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const TopicVocabScreen(level: 1)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final incorrectState = VocabularyLoaded(
        quests: [testQuest],
        currentIndex: 0,
        livesRemaining: 2,
        answerStatus: AnswerStatus.incorrect,
        isFinalFailure: false,
      );
      when(() => mockVocabularyBloc.state).thenReturn(incorrectState);
      vocabularyStreamController.add(incorrectState);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('TRY AGAIN'), findsOneWidget);

      final baseLayout = tester.widget<VocabularyBaseLayout>(find.byType(VocabularyBaseLayout));
      baseLayout.onContinue();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockVocabularyBloc.add(any(that: isA<RetryCurrentQuestion>()))).called(1);
    });
  });
}
