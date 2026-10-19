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
import 'package:vowl/core/presentation/widgets/game_feedback_card.dart';
import 'package:vowl/core/presentation/widgets/quest_hint_button.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
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
import 'package:vowl/features/vocabulary/topic_vocab/presentation/pages/topic_vocab_screen.dart';
import 'package:vowl/features/vocabulary/topic_vocab/presentation/widgets/topic_batch_counter.dart';
import 'package:vowl/features/vocabulary/topic_vocab/presentation/widgets/topic_containment_bin.dart';
import 'package:vowl/features/vocabulary/topic_vocab/presentation/widgets/topic_draggable_core.dart';
import 'package:vowl/features/vocabulary/topic_vocab/presentation/widgets/topic_machine_head.dart';

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
  late StreamController<VocabularyState> vocabularyStreamController;

  VocabularyQuest createTopicQuest({
    String id = 'quest_topic_1',
    String word = 'Science vs Art',
    String correctAnswer = 'Science:physics,Art:painting',
    List<String> options = const ['physics', 'painting'],
    List<String> topicBuckets = const ['Science', 'Art'],
    String? topicEmoji = '🔬',
    String instruction = 'SORT WORDS INTO CORRECT TOPIC',
    String? explanation = 'Physics is science, painting is art.',
    String? hint = 'Classify by their academic domain.',
    int difficulty = 1,
  }) {
    return VocabularyQuest(
      id: id,
      type: QuestType.vocabulary,
      subtype: GameSubtype.topicVocab,
      word: word,
      correctAnswer: correctAnswer,
      options: options,
      topicBuckets: topicBuckets,
      topicEmoji: topicEmoji,
      instruction: instruction,
      explanation: explanation,
      hint: hint,
      difficulty: difficulty,
    );
  }

  // Pure Left Sort quest: regardless of shuffle, every option belongs to Science (Bucket 0)
  VocabularyQuest createAllScienceQuest({
    String id = 'quest_topic_all_science',
    String word = 'All Science',
    String correctAnswer = 'Science:physics,Science:biology,Science:chemistry',
    List<String> options = const ['physics', 'biology', 'chemistry'],
    List<String> topicBuckets = const ['Science', 'Art'],
    String? topicEmoji = '🧪',
    String instruction = 'SORT TO SCIENCE',
    String? hint = 'Everything belongs to Science',
  }) {
    return VocabularyQuest(
      id: id,
      type: QuestType.vocabulary,
      subtype: GameSubtype.topicVocab,
      word: word,
      correctAnswer: correctAnswer,
      options: options,
      topicBuckets: topicBuckets,
      topicEmoji: topicEmoji,
      instruction: instruction,
      hint: hint,
      difficulty: 1,
    );
  }

  // Pure Right Sort quest: regardless of shuffle, every option belongs to Art (Bucket 1)
  VocabularyQuest createAllArtQuest({
    String id = 'quest_topic_all_art',
    String word = 'All Art',
    String correctAnswer = 'Art:painting,Art:sculpture',
    List<String> options = const ['painting', 'sculpture'],
    List<String> topicBuckets = const ['Science', 'Art'],
    String? topicEmoji = '🎨',
    String instruction = 'SORT TO ART',
    String? hint = 'Everything belongs to Art',
  }) {
    return VocabularyQuest(
      id: id,
      type: QuestType.vocabulary,
      subtype: GameSubtype.topicVocab,
      word: word,
      correctAnswer: correctAnswer,
      options: options,
      topicBuckets: topicBuckets,
      topicEmoji: topicEmoji,
      instruction: instruction,
      hint: hint,
      difficulty: 1,
    );
  }

  final defaultQuest = createTopicQuest();
  final testLoadedState = VocabularyLoaded(
    quests: [defaultQuest],
    currentIndex: 0,
    livesRemaining: 3,
    wrongCount: 0,
  );

  setUpAll(() {
    registerFallbackValue(const SubmitAnswer(true));
    registerFallbackValue(const SubmitAnswer(false));
    registerFallbackValue(const NextQuestion());
    registerFallbackValue(const VocabularyHintUsed());
    registerFallbackValue(
      const FetchVocabularyQuests(
        gameType: GameSubtype.topicVocab,
        level: 2,
      ),
    );
    registerFallbackValue(const RestoreLife());
    registerFallbackValue(const EconomyAddCoinsRequested(10));
  });

  setUp(() async {
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

    vocabularyStreamController = StreamController<VocabularyState>.broadcast();

    // Haptic mocks
    when(() => mockHapticService.selection()).thenAnswer((_) async {});
    when(() => mockHapticService.success()).thenAnswer((_) async {});
    when(() => mockHapticService.error()).thenAnswer((_) async {});

    // Sound mocks
    when(() => mockSoundService.playCorrect()).thenAnswer((_) async {});
    when(() => mockSoundService.playWrong()).thenAnswer((_) async {});
    when(() => mockSoundService.playHint()).thenAnswer((_) async {});
    when(() => mockSoundService.playClick()).thenAnswer((_) async {});
    when(() => mockSoundService.stopAudio()).thenAnswer((_) async {});
    when(() => mockSoundService.playLevelComplete()).thenAnswer((_) async {});

    // TTS mock
    when(() => mockTtsService.stop()).thenAnswer((_) async {});
    when(
      () => mockTtsService.speak(
        any(),
        rate: any(named: 'rate'),
        locale: any(named: 'locale'),
      ),
    ).thenAnswer((_) async {});

    // Auth mock
    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(
        const UserEntity(
          id: 'test_user_topic',
          email: 'topic@vowl.app',
          displayName: 'Quantum Sorter',
          hintCount: 3,
        ),
      ),
    );
    when(() => mockAuthBloc.stream)
        .thenAnswer((_) => const Stream<AuthState>.empty());

    // Economy mock
    when(() => mockEconomyBloc.state).thenReturn(const EconomyState());
    when(() => mockEconomyBloc.stream)
        .thenAnswer((_) => const Stream<EconomyState>.empty());

    // Default BLoC mock
    when(() => mockVocabularyBloc.state).thenReturn(testLoadedState);
    when(() => mockVocabularyBloc.stream)
        .thenAnswer((_) => vocabularyStreamController.stream);

    // Network mock
    when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);

    // Dependency injection
    di.sl.reset();
    di.sl.registerLazySingleton<HapticService>(() => mockHapticService);
    di.sl.registerLazySingleton<SoundService>(() => mockSoundService);
    di.sl.registerLazySingleton<TtsService>(() => mockTtsService);
    di.sl.registerLazySingleton<LocaleService>(() => mockLocaleService);
    di.sl.registerLazySingleton<AppLogger>(() => mockAppLogger);
    di.sl.registerLazySingleton<AnalyticsService>(() => mockAnalyticsService);
    di.sl.registerLazySingleton<AdService>(() => mockAdService);
    di.sl.registerLazySingleton<NetworkInfo>(() => mockNetworkInfo);

    SharedPreferences.setMockInitialValues({});
    VowlMotion.lowAnimationModeOverride.value = true;
  });

  tearDown(() async {
    await vocabularyStreamController.close();
    VowlMotion.lowAnimationModeOverride.value = false;
    di.sl.reset();
  });

  Future<void> pumpTopicScreen(
    WidgetTester tester, {
    VocabularyState? initialState,
    Size size = const Size(390, 844),
    double textScale = 1.0,
    ThemeMode themeMode = ThemeMode.dark,
    int level = 2,
  }) async {
    tester.view.physicalSize = Size(size.width * 2, size.height * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    if (initialState != null) {
      when(() => mockVocabularyBloc.state).thenReturn(initialState);
    }

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(390, 844),
        minTextAdapt: true,
        builder: (context, child) {
          return MultiBlocProvider(
            providers: [
              BlocProvider<VocabularyBloc>.value(value: mockVocabularyBloc),
              BlocProvider<AuthBloc>.value(value: mockAuthBloc),
              BlocProvider<EconomyBloc>.value(value: mockEconomyBloc),
            ],
            child: MaterialApp(
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: themeMode,
              home: MediaQuery(
                data: MediaQueryData(
                  size: size,
                  textScaler: TextScaler.linear(textScale),
                  disableAnimations: true,
                ),
                child: TopicVocabScreen(
                  level: level,
                  gameType: GameSubtype.topicVocab,
                ),
              ),
            ),
          );
        },
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Finder findLeftBin() => find.byType(TopicContainmentBin).first;
  Finder findRightBin() => find.byType(TopicContainmentBin).last;

  group('Group 1: Component Rendering & Initial State', () {
    testWidgets('renders TopicVocabScreen with VocabularyLoaded state', (tester) async {
      await pumpTopicScreen(tester);
      expect(find.byType(TopicVocabScreen), findsOneWidget);
    });

    testWidgets('displays TopicBatchCounter with initial count (0 / total)', (tester) async {
      await pumpTopicScreen(tester);
      expect(find.byType(TopicBatchCounter), findsOneWidget);
      expect(find.textContaining('0 / 2'), findsOneWidget);
    });

    testWidgets('displays instruction banner with instruction text', (tester) async {
      await pumpTopicScreen(tester);
      expect(find.textContaining('SORT WORDS INTO CORRECT TOPIC'), findsOneWidget);
    });

    testWidgets('displays TopicMachineHead with topic emoji', (tester) async {
      await pumpTopicScreen(tester);
      expect(find.byType(TopicMachineHead), findsOneWidget);
      expect(find.text('🔬'), findsOneWidget);
    });

    testWidgets('displays left containment bin with bucket label and Semantics action', (tester) async {
      await pumpTopicScreen(tester);
      expect(find.text('SCIENCE'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == 'Sort into Science',
        ),
        findsOneWidget,
      );
    });

    testWidgets('displays right containment bin with bucket label and Semantics action', (tester) async {
      await pumpTopicScreen(tester);
      expect(find.text('ART'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == 'Sort into Art',
        ),
        findsOneWidget,
      );
    });

    testWidgets('displays initial TopicDraggableWord matching one of the options', (tester) async {
      await pumpTopicScreen(tester);
      expect(find.byType(TopicDraggableWord), findsOneWidget);
      final wordFinder = find.byType(TopicDraggableWord);
      final wordWidget = tester.widget<TopicDraggableWord>(wordFinder);
      expect(['physics', 'painting'].contains(wordWidget.word), isTrue);
    });

    testWidgets('displays tutorial arrows on initial mount before any action', (tester) async {
      await pumpTopicScreen(tester);
      expect(find.byIcon(Icons.touch_app_rounded), findsWidgets);
      expect(find.byIcon(Icons.keyboard_double_arrow_left_rounded), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_double_arrow_right_rounded), findsOneWidget);
    });

    testWidgets('displays GameShimmerLoading when state is VocabularyLoading', (tester) async {
      await pumpTopicScreen(tester, initialState: const VocabularyLoading());
      expect(find.byType(GameShimmerLoading), findsOneWidget);
    });
  });

  group('Group 2: Containment Bin Sorting Mechanics (Tap-to-Sort)', () {
    testWidgets('tapping left containment bin sorts word belonging to left bucket', (tester) async {
      final scienceQuest = createAllScienceQuest();
      await pumpTopicScreen(
        tester,
        initialState: VocabularyLoaded(
          quests: [scienceQuest],
          currentIndex: 0,
          livesRemaining: 3,
          wrongCount: 0,
        ),
      );

      // Tap left bin (Science)
      await tester.tap(findLeftBin());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockSoundService.playCorrect()).called(1);
    });

    testWidgets('sorting a word advances currentWordIndex and updates batch counter', (tester) async {
      final scienceQuest = createAllScienceQuest();
      await pumpTopicScreen(
        tester,
        initialState: VocabularyLoaded(
          quests: [scienceQuest],
          currentIndex: 0,
          livesRemaining: 3,
          wrongCount: 0,
        ),
      );

      expect(find.textContaining('0 / 3'), findsOneWidget);

      await tester.tap(findLeftBin());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('1 / 3'), findsOneWidget);
    });

    testWidgets('sorted word appears inside the destination containment bin word list', (tester) async {
      final scienceQuest = createAllScienceQuest();
      await pumpTopicScreen(
        tester,
        initialState: VocabularyLoaded(
          quests: [scienceQuest],
          currentIndex: 0,
          livesRemaining: 3,
          wrongCount: 0,
        ),
      );

      // Find initial word being displayed
      final draggableWord = tester.widget<TopicDraggableWord>(
        find.byType(TopicDraggableWord),
      );
      final sortedWordUpper = draggableWord.word.toUpperCase();

      // Tap left bin
      await tester.tap(findLeftBin());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // After sorting, word is now in bin 0
      final leftBinFinder = find.ancestor(
        of: find.text('SCIENCE'),
        matching: find.byType(TopicContainmentBin),
      );
      final binWidget = tester.widget<TopicContainmentBin>(leftBinFinder);
      expect(binWidget.words.contains(draggableWord.word), isTrue);
      expect(find.text(sortedWordUpper), findsWidgets);
    });

    testWidgets('tapping wrong containment bin triggers wrong answer flow', (tester) async {
      final scienceQuest = createAllScienceQuest();
      await pumpTopicScreen(
        tester,
        initialState: VocabularyLoaded(
          quests: [scienceQuest],
          currentIndex: 0,
          livesRemaining: 3,
          wrongCount: 0,
        ),
      );

      // Tap right bin (Art) which is WRONG for a science word
      await tester.tap(findRightBin());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockSoundService.playWrong()).called(greaterThanOrEqualTo(1));
      verify(() => mockHapticService.error()).called(greaterThanOrEqualTo(1));
    });

    testWidgets('wrong sort dispatches SubmitAnswer(false) with quest and user answer', (tester) async {
      final scienceQuest = createAllScienceQuest();
      await pumpTopicScreen(
        tester,
        initialState: VocabularyLoaded(
          quests: [scienceQuest],
          currentIndex: 0,
          livesRemaining: 3,
          wrongCount: 0,
        ),
      );

      await tester.tap(findRightBin());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockVocabularyBloc.add(const SubmitAnswer(false))).called(1);
    });

    testWidgets('tapping right containment bin sorts word belonging to right bucket', (tester) async {
      final artQuest = createAllArtQuest();
      await pumpTopicScreen(
        tester,
        initialState: VocabularyLoaded(
          quests: [artQuest],
          currentIndex: 0,
          livesRemaining: 3,
          wrongCount: 0,
        ),
      );

      await tester.tap(findRightBin());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockSoundService.playCorrect()).called(1);
    });

    testWidgets('completing all words in the batch dispatches SubmitAnswer(true)', (tester) async {
      final artQuest = createAllArtQuest(); // options: ['painting', 'sculpture'], length 2
      await pumpTopicScreen(
        tester,
        initialState: VocabularyLoaded(
          quests: [artQuest],
          currentIndex: 0,
          livesRemaining: 3,
          wrongCount: 0,
        ),
      );

      // Sort word 1
      await tester.tap(findRightBin());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Sort word 2 (completes the batch)
      await tester.tap(findRightBin());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockHapticService.success()).called(greaterThanOrEqualTo(1));
      verify(() => mockVocabularyBloc.add(const SubmitAnswer(true))).called(1);
    });
  });

  group('Group 3: Draggable Word Flick Mechanics (Swipe-to-Sort)', () {
    testWidgets('dragging word left with offset < -60 triggers left sort', (tester) async {
      final scienceQuest = createAllScienceQuest();
      await pumpTopicScreen(
        tester,
        initialState: VocabularyLoaded(
          quests: [scienceQuest],
          currentIndex: 0,
          livesRemaining: 3,
          wrongCount: 0,
        ),
      );

      final draggable = find.byType(TopicDraggableWord);
      await tester.drag(draggable, const Offset(-100, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockSoundService.playCorrect()).called(1);
    });

    testWidgets('dragging word right with offset > 60 triggers right sort', (tester) async {
      final artQuest = createAllArtQuest();
      await pumpTopicScreen(
        tester,
        initialState: VocabularyLoaded(
          quests: [artQuest],
          currentIndex: 0,
          livesRemaining: 3,
          wrongCount: 0,
        ),
      );

      final draggable = find.byType(TopicDraggableWord);
      await tester.drag(draggable, const Offset(100, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockSoundService.playCorrect()).called(1);
    });

    testWidgets('flinging word with velocity < -500 triggers left flick', (tester) async {
      final scienceQuest = createAllScienceQuest();
      await pumpTopicScreen(
        tester,
        initialState: VocabularyLoaded(
          quests: [scienceQuest],
          currentIndex: 0,
          livesRemaining: 3,
          wrongCount: 0,
        ),
      );

      final draggable = find.byType(TopicDraggableWord);
      await tester.fling(draggable, const Offset(-200, 0), 1000);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockSoundService.playCorrect()).called(1);
    });

    testWidgets('flinging word with velocity > 500 triggers right flick', (tester) async {
      final artQuest = createAllArtQuest();
      await pumpTopicScreen(
        tester,
        initialState: VocabularyLoaded(
          quests: [artQuest],
          currentIndex: 0,
          livesRemaining: 3,
          wrongCount: 0,
        ),
      );

      final draggable = find.byType(TopicDraggableWord);
      await tester.fling(draggable, const Offset(200, 0), 1000);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockSoundService.playCorrect()).called(1);
    });

    testWidgets('small drag under threshold does not trigger sorting', (tester) async {
      final scienceQuest = createAllScienceQuest();
      await pumpTopicScreen(
        tester,
        initialState: VocabularyLoaded(
          quests: [scienceQuest],
          currentIndex: 0,
          livesRemaining: 3,
          wrongCount: 0,
        ),
      );

      final draggable = find.byType(TopicDraggableWord);
      // Small drag that does not exceed offset 60 or velocity 500
      await tester.drag(draggable, const Offset(-15, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // No sound played, still at word index 0
      verifyNever(() => mockSoundService.playCorrect());
      verifyNever(() => mockSoundService.playWrong());
      expect(find.textContaining('0 / 3'), findsOneWidget);
    });
  });

  group('Group 4: Hint System & Guidance', () {
    testWidgets('tapping hint button activates hint state in controller', (tester) async {
      final scienceQuest = createAllScienceQuest();
      await pumpTopicScreen(
        tester,
        initialState: VocabularyLoaded(
          quests: [scienceQuest],
          currentIndex: 0,
          livesRemaining: 3,
          wrongCount: 0,
        ),
      );

      final hintButton = find.byType(QuestHintButton);
      expect(hintButton, findsOneWidget);

      await tester.tap(hintButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockSoundService.playHint()).called(1);
    });

    testWidgets('target containment bin highlights with active hint when hint is active', (tester) async {
      final scienceQuest = createAllScienceQuest();
      await pumpTopicScreen(
        tester,
        initialState: VocabularyLoaded(
          quests: [scienceQuest],
          currentIndex: 0,
          livesRemaining: 3,
          wrongCount: 0,
        ),
      );

      final hintButton = find.byType(QuestHintButton);
      await tester.tap(hintButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final leftBinFinder = find.ancestor(
        of: find.text('SCIENCE'),
        matching: find.byType(TopicContainmentBin),
      );
      final leftBin = tester.widget<TopicContainmentBin>(leftBinFinder);
      expect(leftBin.isHinted, isTrue);

      final rightBinFinder = find.ancestor(
        of: find.text('ART'),
        matching: find.byType(TopicContainmentBin),
      );
      final rightBin = tester.widget<TopicContainmentBin>(rightBinFinder);
      expect(rightBin.isHinted, isFalse);
    });

    testWidgets('successfully sorting the hinted word resets hint state', (tester) async {
      final scienceQuest = createAllScienceQuest();
      await pumpTopicScreen(
        tester,
        initialState: VocabularyLoaded(
          quests: [scienceQuest],
          currentIndex: 0,
          livesRemaining: 3,
          wrongCount: 0,
        ),
      );

      // Activate hint
      final hintButton = find.byType(QuestHintButton);
      await tester.tap(hintButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Sort word into Science
      await tester.tap(findLeftBin());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // After sort, left bin is no longer hinted
      final leftBinFinder = find.ancestor(
        of: find.text('SCIENCE'),
        matching: find.byType(TopicContainmentBin),
      );
      final leftBinWidget = tester.widget<TopicContainmentBin>(leftBinFinder);
      expect(leftBinWidget.isHinted, isFalse);
    });
  });

  group('Group 5: Answer State, Feedback & Question Reset', () {
    testWidgets('correct batch completion renders GameFeedbackCard with success styling', (tester) async {
      final artQuest = createAllArtQuest();
      await pumpTopicScreen(
        tester,
        initialState: VocabularyLoaded(
          quests: [artQuest],
          currentIndex: 0,
          livesRemaining: 3,
          wrongCount: 0,
        ),
      );

      // Sort word 1
      await tester.tap(findRightBin());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      // Sort word 2
      await tester.tap(findRightBin());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(GameFeedbackCard), findsOneWidget);
      final feedback = tester.widget<GameFeedbackCard>(find.byType(GameFeedbackCard));
      expect(feedback.isCorrect, isTrue);
    });

    testWidgets('feedback card continue button dispatches NextQuestion() event', (tester) async {
      final artQuest = createAllArtQuest();
      await pumpTopicScreen(
        tester,
        initialState: VocabularyLoaded(
          quests: [artQuest],
          currentIndex: 0,
          livesRemaining: 3,
          wrongCount: 0,
        ),
      );

      await tester.tap(findRightBin());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(findRightBin());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Find continue button
      final continueButton = find.text('CONTINUE');
      expect(continueButton, findsOneWidget);
      await tester.tap(continueButton);
      await tester.pump();

      verify(() => mockVocabularyBloc.add(const NextQuestion())).called(1);
    });

    testWidgets('incorrect sort renders GameFeedbackCard with failure styling', (tester) async {
      final scienceQuest = createAllScienceQuest();
      await pumpTopicScreen(
        tester,
        initialState: VocabularyLoaded(
          quests: [scienceQuest],
          currentIndex: 0,
          livesRemaining: 3,
          wrongCount: 0,
        ),
      );

      await tester.tap(findRightBin());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(GameFeedbackCard), findsOneWidget);
      final feedback = tester.widget<GameFeedbackCard>(find.byType(GameFeedbackCard));
      expect(feedback.isCorrect, isFalse);
    });

    testWidgets('emitting new VocabularyLoaded state resets controller and bins', (tester) async {
      final quest1 = createAllScienceQuest(id: 'q1');
      final quest2 = createAllArtQuest(id: 'q2');

      await pumpTopicScreen(
        tester,
        initialState: VocabularyLoaded(
          quests: [quest1, quest2],
          currentIndex: 0,
          livesRemaining: 3,
          wrongCount: 0,
        ),
      );

      // Sort word into Science on quest 1
      await tester.tap(findLeftBin());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.textContaining('1 / 3'), findsOneWidget);

      // Emit new loaded state with quest 2
      vocabularyStreamController.add(
        VocabularyLoaded(
          quests: [quest1, quest2],
          currentIndex: 1,
          livesRemaining: 3,
          wrongCount: 0,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Controller should now reflect quest 2 with 0 / 2 progress
      expect(find.textContaining('0 / 2'), findsOneWidget);
      expect(find.text('🎨'), findsOneWidget);
    });

    testWidgets('does not process bin taps once already answered', (tester) async {
      final scienceQuest = createAllScienceQuest();
      await pumpTopicScreen(
        tester,
        initialState: VocabularyLoaded(
          quests: [scienceQuest],
          currentIndex: 0,
          livesRemaining: 3,
          wrongCount: 0,
        ),
      );

      // Wrong sort to finish game
      await tester.tap(findRightBin());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => mockSoundService.playWrong()).called(greaterThanOrEqualTo(1));

      // Attempt tapping again
      await tester.tap(findRightBin(), warnIfMissed: false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Should not call sound or bloc again
      verifyNever(() => mockSoundService.playCorrect());
      verifyNever(() => mockSoundService.playWrong());
    });
  });

  group('Group 6: Responsive Layout & Accessibility', () {
    testWidgets('renders without overflow on compact screen (320x568)', (tester) async {
      await pumpTopicScreen(tester, size: const Size(320, 568));
      expect(tester.takeException(), isNull);
      expect(find.byType(TopicVocabScreen), findsOneWidget);
    });

    testWidgets('renders properly on tablet screen (768x1024)', (tester) async {
      await pumpTopicScreen(tester, size: const Size(768, 1024));
      expect(tester.takeException(), isNull);
      expect(find.byType(TopicVocabScreen), findsOneWidget);
    });

    testWidgets('renders properly in landscape orientation (800x480)', (tester) async {
      await pumpTopicScreen(tester, size: const Size(800, 480));
      expect(tester.takeException(), isNull);
      expect(find.byType(TopicVocabScreen), findsOneWidget);
    });

    testWidgets('renders properly with large text scale factor (1.5x)', (tester) async {
      await pumpTopicScreen(tester, textScale: 1.5);
      expect(tester.takeException(), isNull);
      expect(find.byType(TopicVocabScreen), findsOneWidget);
    });

    testWidgets('supports both dark theme and light theme styling', (tester) async {
      await pumpTopicScreen(tester, themeMode: ThemeMode.light);
      expect(tester.takeException(), isNull);
      expect(find.byType(TopicVocabScreen), findsOneWidget);

      await pumpTopicScreen(tester, themeMode: ThemeMode.dark);
      expect(tester.takeException(), isNull);
      expect(find.byType(TopicVocabScreen), findsOneWidget);
    });

    testWidgets('containment bins have accessible Semantics labels', (tester) async {
      await pumpTopicScreen(tester);
      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == 'Sort into Science',
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is Semantics && w.properties.label == 'Sort into Art',
        ),
        findsOneWidget,
      );
    });
  });
}
