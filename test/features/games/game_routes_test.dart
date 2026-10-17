import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/presentation/pages/quest_sequence_page.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';
import 'package:vowl/core/utils/app_logger.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/accent/minimal_pairs/presentation/pages/minimal_pairs_screen.dart';
import 'package:vowl/features/accent/presentation/bloc/accent_bloc.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/elite_mastery/presentation/bloc/elite_mastery_bloc.dart';
import 'package:vowl/features/elite_mastery/story_builder/presentation/pages/story_builder_screen.dart';
import 'package:vowl/features/games/game_routes.dart';
import 'package:vowl/features/grammar/grammar_quest/presentation/pages/grammar_quest_screen.dart';
import 'package:vowl/features/grammar/presentation/bloc/grammar_bloc.dart';
import 'package:vowl/features/home/presentation/pages/category_games_page.dart';
import 'package:vowl/features/listening/audio_multiple_choice/presentation/pages/audio_multiple_choice_screen.dart';
import 'package:vowl/features/listening/presentation/bloc/listening_bloc.dart';
import 'package:vowl/features/profile/presentation/pages/adventure_level_screen.dart';
import 'package:vowl/features/profile/presentation/pages/adventure_xp_screen.dart';
import 'package:vowl/features/profile/presentation/pages/quest_coins_screen.dart';
import 'package:vowl/features/reading/presentation/bloc/reading_bloc.dart';
import 'package:vowl/features/reading/read_and_answer/presentation/pages/read_and_answer_screen.dart';
import 'package:vowl/features/roleplay/branching_dialogue/presentation/pages/branching_dialogue_screen.dart';
import 'package:vowl/features/roleplay/presentation/bloc/roleplay_bloc.dart';
import 'package:vowl/features/speaking/presentation/bloc/speaking_bloc.dart';
import 'package:vowl/features/speaking/repeat_sentence/presentation/pages/repeat_sentence_screen.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/pages/flashcards_screen.dart';
import 'package:vowl/features/vocabulary/presentation/bloc/vocabulary_bloc.dart';
import 'package:vowl/features/writing/presentation/bloc/writing_bloc.dart';
import 'package:vowl/features/writing/sentence_builder/presentation/pages/sentence_builder_screen.dart';

class MockBuildContext extends Mock implements BuildContext {}

class MockGoRouterState extends Mock implements GoRouterState {}

class MockAuthBloc extends Mock implements AuthBloc {}

class MockAppLogger extends Mock implements AppLogger {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockBuildContext mockContext;
  late MockAuthBloc mockAuthBloc;
  late MockAppLogger mockLogger;

  setUp(() {
    mockContext = MockBuildContext();
    mockAuthBloc = MockAuthBloc();
    mockLogger = MockAppLogger();

    if (di.sl.isRegistered<AuthBloc>()) di.sl.unregister<AuthBloc>();
    if (di.sl.isRegistered<AppLogger>()) di.sl.unregister<AppLogger>();

    di.sl.registerSingleton<AuthBloc>(mockAuthBloc);
    di.sl.registerSingleton<AppLogger>(mockLogger);

    when(() => mockAuthBloc.state).thenReturn(
      AuthState.authenticated(
        const UserEntity(
          id: 'test_user_1',
          email: 'test@vowl.app',
          displayName: 'Tester',
        ),
      ),
    );
  });

  tearDown(() {
    if (di.sl.isRegistered<AuthBloc>()) di.sl.unregister<AuthBloc>();
    if (di.sl.isRegistered<AppLogger>()) di.sl.unregister<AppLogger>();
  });

  GoRouterState createMockState(String url) {
    final state = MockGoRouterState();
    final uri = Uri.parse(url);
    when(() => state.uri).thenReturn(uri);
    when(() => state.pageKey).thenReturn(ValueKey(url));
    return state;
  }

  GoRoute findRoute(String path) {
    return GameRoutes.routes
        .whereType<GoRoute>()
        .firstWhere((r) => r.path == path);
  }

  group('GameRoutes - Static Constants & Route Declarations', () {
    test('declares expected standard route constants', () {
      expect(GameRoutes.categoryGamesRoute, equals('/category-games'));
      expect(GameRoutes.levelRoute, equals('/level-details'));
      expect(GameRoutes.adventureXPRoute, equals('/xp-details'));
      expect(GameRoutes.questCoinsRoute, equals('/coins-details'));
      expect(GameRoutes.questSequenceRoute, equals('/quest-sequence'));
    });

    test('declares all 7 required game route paths', () {
      final paths = GameRoutes.routes.whereType<GoRoute>().map((r) => r.path).toList();

      expect(paths, contains('/game'));
      expect(paths, contains('/levels'));
      expect(paths, contains('/category-games'));
      expect(paths, contains('/level-details'));
      expect(paths, contains('/xp-details'));
      expect(paths, contains('/coins-details'));
      expect(paths, contains('/quest-sequence'));
      expect(paths.length, equals(7));
    });
  });

  group('GameRoutes - /game Route Resolution Across All Categories', () {
    final gameRoute = findRoute('/game');

    test('resolves reading category with default readAndAnswer screen', () {
      final state = createMockState('/game?category=reading&level=2');
      final page = gameRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<BlocProvider<ReadingBloc>>());
      final blocProvider = page.child as BlocProvider<ReadingBloc>;
      expect(blocProvider.child, isA<ReadAndAnswerScreen>());
      final screen = blocProvider.child as ReadAndAnswerScreen;
      expect(screen.level, equals(2));
      expect(screen.gameType, equals(GameSubtype.readAndAnswer));
    });

    test('resolves writing category with sentenceBuilder screen', () {
      final state = createMockState('/game?category=writing&gameType=sentenceBuilder&level=3');
      final page = gameRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<BlocProvider<WritingBloc>>());
      final blocProvider = page.child as BlocProvider<WritingBloc>;
      expect(blocProvider.child, isA<SentenceBuilderScreen>());
      final screen = blocProvider.child as SentenceBuilderScreen;
      expect(screen.level, equals(3));
      expect(screen.gameType, equals(GameSubtype.sentenceBuilder));
    });

    test('resolves speaking category with repeatSentence screen', () {
      final state = createMockState('/game?category=speaking&gameType=repeatSentence&level=4');
      final page = gameRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<BlocProvider<SpeakingBloc>>());
      final blocProvider = page.child as BlocProvider<SpeakingBloc>;
      expect(blocProvider.child, isA<RepeatSentenceScreen>());
      final screen = blocProvider.child as RepeatSentenceScreen;
      expect(screen.level, equals(4));
      expect(screen.gameType, equals(GameSubtype.repeatSentence));
    });

    test('resolves grammar category with grammarQuest screen', () {
      final state = createMockState('/game?category=grammar&gameType=grammarQuest&level=1');
      final page = gameRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<BlocProvider<GrammarBloc>>());
      final blocProvider = page.child as BlocProvider<GrammarBloc>;
      expect(blocProvider.child, isA<GrammarQuestScreen>());
      final screen = blocProvider.child as GrammarQuestScreen;
      expect(screen.level, equals(1));
      expect(screen.gameType, equals(GameSubtype.grammarQuest));
    });

    test('resolves listening category with audioMultipleChoice screen', () {
      final state = createMockState('/game?category=listening&gameType=audioMultipleChoice&level=5');
      final page = gameRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<BlocProvider<ListeningBloc>>());
      final blocProvider = page.child as BlocProvider<ListeningBloc>;
      expect(blocProvider.child, isA<AudioMultipleChoiceScreen>());
      final screen = blocProvider.child as AudioMultipleChoiceScreen;
      expect(screen.level, equals(5));
      expect(screen.gameType, equals(GameSubtype.audioMultipleChoice));
    });

    test('resolves roleplay category with branchingDialogue screen', () {
      final state = createMockState('/game?category=roleplay&gameType=branchingDialogue&level=2');
      final page = gameRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<BlocProvider<RoleplayBloc>>());
      final blocProvider = page.child as BlocProvider<RoleplayBloc>;
      expect(blocProvider.child, isA<BranchingDialogueScreen>());
      final screen = blocProvider.child as BranchingDialogueScreen;
      expect(screen.level, equals(2));
      expect(screen.gameType, equals(GameSubtype.branchingDialogue));
    });

    test('resolves accent category with minimalPairs screen', () {
      final state = createMockState('/game?category=accent&gameType=minimalPairs&level=3');
      final page = gameRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<BlocProvider<AccentBloc>>());
      final blocProvider = page.child as BlocProvider<AccentBloc>;
      expect(blocProvider.child, isA<MinimalPairsScreen>());
      final screen = blocProvider.child as MinimalPairsScreen;
      expect(screen.level, equals(3));
      expect(screen.gameType, equals(GameSubtype.minimalPairs));
    });

    test('resolves vocabulary category with flashcards screen', () {
      final state = createMockState('/game?category=vocabulary&gameType=flashcards&level=2');
      final page = gameRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<BlocProvider<VocabularyBloc>>());
      final blocProvider = page.child as BlocProvider<VocabularyBloc>;
      expect(blocProvider.child, isA<FlashcardsScreen>());
      final screen = blocProvider.child as FlashcardsScreen;
      expect(screen.level, equals(2));
      expect(screen.gameType, equals(GameSubtype.flashcards));
    });

    test('resolves elite mastery category with storyBuilder screen', () {
      final state = createMockState('/game?category=elitemastery&gameType=storyBuilder&level=1');
      final page = gameRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<BlocProvider<EliteMasteryBloc>>());
      final blocProvider = page.child as BlocProvider<EliteMasteryBloc>;
      expect(blocProvider.child, isA<StoryBuilderScreen>());
      final screen = blocProvider.child as StoryBuilderScreen;
      expect(screen.level, equals(1));
      expect(screen.gameType, equals(GameSubtype.storyBuilder));
    });

    test('resolves elite_mastery (with underscore) category properly', () {
      final state = createMockState('/game?category=elite_mastery&gameType=storyBuilder&level=2');
      final page = gameRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<BlocProvider<EliteMasteryBloc>>());
      final blocProvider = page.child as BlocProvider<EliteMasteryBloc>;
      expect(blocProvider.child, isA<StoryBuilderScreen>());
      final screen = blocProvider.child as StoryBuilderScreen;
      expect(screen.level, equals(2));
      expect(screen.gameType, equals(GameSubtype.storyBuilder));
    });

    test('supports subtype parameter as alias for gameType', () {
      final state = createMockState('/game?category=writing&subtype=sentenceBuilder&level=2');
      final page = gameRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      final blocProvider = page.child as BlocProvider<WritingBloc>;
      expect(blocProvider.child, isA<SentenceBuilderScreen>());
    });

    test('handles case-insensitivity in category parameter', () {
      final state = createMockState('/game?category=READING&level=1');
      final page = gameRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      final blocProvider = page.child as BlocProvider<ReadingBloc>;
      expect(blocProvider.child, isA<ReadAndAnswerScreen>());
    });

    test('falls back gracefully to reading category when unknown category provided', () {
      final state = createMockState('/game?category=unknown_galaxy&level=2');
      final page = gameRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<BlocProvider<ReadingBloc>>());
      final blocProvider = page.child as BlocProvider<ReadingBloc>;
      expect(blocProvider.child, isA<ReadAndAnswerScreen>());
    });

    test('falls back to category default subtype when unknown gameType provided', () {
      final state = createMockState('/game?category=accent&gameType=nonexistent_drill&level=1');
      final page = gameRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      final blocProvider = page.child as BlocProvider<AccentBloc>;
      expect(blocProvider.child, isA<MinimalPairsScreen>());
    });

    test('defaults to level 1 when level parameter is missing or non-numeric', () {
      final stateMissing = createMockState('/game?category=reading');
      final pageMissing = gameRoute.pageBuilder!(mockContext, stateMissing) as CustomTransitionPage;
      final screenMissing = (pageMissing.child as BlocProvider<ReadingBloc>).child as ReadAndAnswerScreen;
      expect(screenMissing.level, equals(1));

      final stateInvalid = createMockState('/game?category=reading&level=abc');
      final pageInvalid = gameRoute.pageBuilder!(mockContext, stateInvalid) as CustomTransitionPage;
      final screenInvalid = (pageInvalid.child as BlocProvider<ReadingBloc>).child as ReadAndAnswerScreen;
      expect(screenInvalid.level, equals(1));
    });
  });

  group('GameRoutes - /levels Route Resolution', () {
    final levelsRoute = findRoute('/levels');

    test('resolves ModernCategoryMap with specified category and gameType', () {
      final state = createMockState('/levels?category=vocabulary&gameType=flashcards');
      final page = levelsRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<ModernCategoryMap>());
      final mapWidget = page.child as ModernCategoryMap;
      expect(mapWidget.categoryId, equals('vocabulary'));
      expect(mapWidget.gameType, equals('flashcards'));
      expect(mapWidget.key, equals(const ValueKey('vocabulary_flashcards')));
    });

    test('defaults category to reading and gameType to readAndAnswer when params omitted', () {
      final state = createMockState('/levels');
      final page = levelsRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<ModernCategoryMap>());
      final mapWidget = page.child as ModernCategoryMap;
      expect(mapWidget.categoryId, equals('reading'));
      expect(mapWidget.gameType, equals('readAndAnswer'));
      expect(mapWidget.key, equals(const ValueKey('reading_readAndAnswer')));
    });
  });

  group('GameRoutes - /category-games Route Resolution', () {
    final catGamesRoute = findRoute(GameRoutes.categoryGamesRoute);

    test('resolves CategoryGamesPage with explicit categoryId', () {
      final state = createMockState('/category-games?category=listening');
      final page = catGamesRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<CategoryGamesPage>());
      final catWidget = page.child as CategoryGamesPage;
      expect(catWidget.categoryId, equals('listening'));
    });

    test('defaults categoryId to speaking when parameter omitted', () {
      final state = createMockState('/category-games');
      final page = catGamesRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<CategoryGamesPage>());
      final catWidget = page.child as CategoryGamesPage;
      expect(catWidget.categoryId, equals('speaking'));
    });
  });

  group('GameRoutes - Profile, XP, Coins and Sequence Pages', () {
    test('resolves /level-details to AdventureLevelScreen', () {
      final route = findRoute(GameRoutes.levelRoute);
      final state = createMockState('/level-details');
      final page = route.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<AdventureLevelScreen>());
    });

    test('resolves /xp-details to AdventureXPScreen', () {
      final route = findRoute(GameRoutes.adventureXPRoute);
      final state = createMockState('/xp-details');
      final page = route.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<AdventureXPScreen>());
    });

    test('resolves /coins-details to VowlCoinsScreen', () {
      final route = findRoute(GameRoutes.questCoinsRoute);
      final state = createMockState('/coins-details');
      final page = route.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<VowlCoinsScreen>());
    });

    test('resolves /quest-sequence with authenticated user quests', () {
      final route = findRoute(GameRoutes.questSequenceRoute);
      final state = createMockState('/quest-sequence?id=daily_duo');
      final page = route.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<QuestSequencePage>());
      final sequencePage = page.child as QuestSequencePage;
      expect(sequencePage.sequenceId, equals('daily_duo'));
      expect(sequencePage.quests, isA<List<GameQuest>>());
    });

    test('resolves /quest-sequence with empty quests if user is unauthenticated', () {
      when(() => mockAuthBloc.state).thenReturn(
        const AuthState.unauthenticated(),
      );

      final route = findRoute(GameRoutes.questSequenceRoute);
      final state = createMockState('/quest-sequence?id=speed_run');
      final page = route.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<QuestSequencePage>());
      final sequencePage = page.child as QuestSequencePage;
      expect(sequencePage.sequenceId, equals('speed_run'));
      expect(sequencePage.quests, isEmpty);
    });
  });
}

