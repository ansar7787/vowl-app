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
import 'package:vowl/features/listening/audio_fill_blanks/presentation/pages/audio_fill_blanks_learn_screen.dart';
import 'package:vowl/features/listening/audio_fill_blanks/presentation/pages/audio_fill_blanks_practice_screen.dart';
import 'package:vowl/features/listening/audio_multiple_choice/presentation/pages/audio_multiple_choice_learn_screen.dart';
import 'package:vowl/features/listening/audio_multiple_choice/presentation/pages/audio_multiple_choice_practice_screen.dart';
import 'package:vowl/features/listening/audio_sentence_order/presentation/pages/audio_sentence_order_learn_screen.dart';
import 'package:vowl/features/listening/audio_sentence_order/presentation/pages/audio_sentence_order_practice_screen.dart';
import 'package:vowl/features/listening/audio_true_false/presentation/pages/audio_true_false_learn_screen.dart';
import 'package:vowl/features/listening/audio_true_false/presentation/pages/audio_true_false_practice_screen.dart';
import 'package:vowl/features/listening/sound_image_match/presentation/pages/sound_image_match_learn_screen.dart';
import 'package:vowl/features/listening/sound_image_match/presentation/pages/sound_image_match_practice_screen.dart';
import 'package:vowl/features/listening/fast_speech_decoder/presentation/pages/fast_speech_decoder_learn_screen.dart';
import 'package:vowl/features/listening/fast_speech_decoder/presentation/pages/fast_speech_decoder_practice_screen.dart';
import 'package:vowl/features/listening/emotion_recognition/presentation/pages/emotion_recognition_learn_screen.dart';
import 'package:vowl/features/listening/emotion_recognition/presentation/pages/emotion_recognition_practice_screen.dart';
import 'package:vowl/features/listening/detail_spotlight/presentation/pages/detail_spotlight_learn_screen.dart';
import 'package:vowl/features/listening/detail_spotlight/presentation/pages/detail_spotlight_practice_screen.dart';
import 'package:vowl/features/listening/listening_inference/presentation/pages/listening_inference_learn_screen.dart';
import 'package:vowl/features/listening/listening_inference/presentation/pages/listening_inference_practice_screen.dart';
import 'package:vowl/features/listening/ambient_id/presentation/pages/ambient_id_learn_screen.dart';
import 'package:vowl/features/listening/ambient_id/presentation/pages/ambient_id_practice_screen.dart';
import 'package:vowl/features/accent/minimal_pairs/presentation/pages/minimal_pairs_learn_screen.dart';
import 'package:vowl/features/accent/minimal_pairs/presentation/pages/minimal_pairs_practice_screen.dart';
import 'package:vowl/features/accent/intonation_mimic/presentation/pages/intonation_mimic_learn_screen.dart';
import 'package:vowl/features/accent/intonation_mimic/presentation/pages/intonation_mimic_practice_screen.dart';
import 'package:vowl/features/accent/syllable_stress/presentation/pages/syllable_stress_learn_screen.dart';
import 'package:vowl/features/accent/syllable_stress/presentation/pages/syllable_stress_practice_screen.dart';
import 'package:vowl/features/accent/word_linking/presentation/pages/word_linking_learn_screen.dart';
import 'package:vowl/features/accent/word_linking/presentation/pages/word_linking_practice_screen.dart';
import 'package:vowl/features/accent/shadowing_challenge/presentation/pages/shadowing_challenge_learn_screen.dart';
import 'package:vowl/features/accent/shadowing_challenge/presentation/pages/shadowing_challenge_practice_screen.dart';
import 'package:vowl/features/accent/vowel_distinction/presentation/pages/vowel_distinction_learn_screen.dart';
import 'package:vowl/features/accent/vowel_distinction/presentation/pages/vowel_distinction_practice_screen.dart';
import 'package:vowl/features/accent/consonant_clarity/presentation/pages/consonant_clarity_learn_screen.dart';
import 'package:vowl/features/accent/consonant_clarity/presentation/pages/consonant_clarity_practice_screen.dart';
import 'package:vowl/features/accent/pitch_pattern_match/presentation/pages/pitch_pattern_match_learn_screen.dart';
import 'package:vowl/features/accent/pitch_pattern_match/presentation/pages/pitch_pattern_match_practice_screen.dart';
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
    return GameRoutes.routes.whereType<GoRoute>().firstWhere(
      (r) => r.path == path,
    );
  }

  group('GameRoutes - Static Constants & Route Declarations', () {
    test('declares expected standard route constants', () {
      expect(GameRoutes.categoryGamesRoute, equals('/category-games'));
      expect(GameRoutes.levelRoute, equals('/level-details'));
      expect(GameRoutes.adventureXPRoute, equals('/xp-details'));
      expect(GameRoutes.questCoinsRoute, equals('/coins-details'));
      expect(GameRoutes.questSequenceRoute, equals('/quest-sequence'));
      expect(GameRoutes.learnRoute, equals('/learn'));
      expect(GameRoutes.practiceRoute, equals('/practice'));
    });

    test('declares all required game route paths including learn and practice', () {
      final paths = GameRoutes.routes
          .whereType<GoRoute>()
          .map((r) => r.path)
          .toList();

      expect(paths, contains('/game'));
      expect(paths, contains('/levels'));
      expect(paths, contains('/category-games'));
      expect(paths, contains('/level-details'));
      expect(paths, contains('/xp-details'));
      expect(paths, contains('/coins-details'));
      expect(paths, contains('/quest-sequence'));
      expect(paths, contains('/learn'));
      expect(paths, contains('/practice'));
      expect(paths.length, equals(9));
    });
  });

  group('GameRoutes - /game Route Resolution Across All Categories', () {
    final gameRoute = findRoute('/game');

    test('resolves reading category with default readAndAnswer screen', () {
      final state = createMockState('/game?category=reading&level=2');
      final page =
          gameRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<BlocProvider<ReadingBloc>>());
      final blocProvider = page.child as BlocProvider<ReadingBloc>;
      expect(blocProvider.child, isA<ReadAndAnswerScreen>());
      final screen = blocProvider.child as ReadAndAnswerScreen;
      expect(screen.level, equals(2));
      expect(screen.gameType, equals(GameSubtype.readAndAnswer));
    });

    test('resolves writing category with sentenceBuilder screen', () {
      final state = createMockState(
        '/game?category=writing&gameType=sentenceBuilder&level=3',
      );
      final page =
          gameRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<BlocProvider<WritingBloc>>());
      final blocProvider = page.child as BlocProvider<WritingBloc>;
      expect(blocProvider.child, isA<SentenceBuilderScreen>());
      final screen = blocProvider.child as SentenceBuilderScreen;
      expect(screen.level, equals(3));
      expect(screen.gameType, equals(GameSubtype.sentenceBuilder));
    });

    test('resolves speaking category with repeatSentence screen', () {
      final state = createMockState(
        '/game?category=speaking&gameType=repeatSentence&level=4',
      );
      final page =
          gameRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<BlocProvider<SpeakingBloc>>());
      final blocProvider = page.child as BlocProvider<SpeakingBloc>;
      expect(blocProvider.child, isA<RepeatSentenceScreen>());
      final screen = blocProvider.child as RepeatSentenceScreen;
      expect(screen.level, equals(4));
      expect(screen.gameType, equals(GameSubtype.repeatSentence));
    });

    test('resolves grammar category with grammarQuest screen', () {
      final state = createMockState(
        '/game?category=grammar&gameType=grammarQuest&level=1',
      );
      final page =
          gameRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<BlocProvider<GrammarBloc>>());
      final blocProvider = page.child as BlocProvider<GrammarBloc>;
      expect(blocProvider.child, isA<GrammarQuestScreen>());
      final screen = blocProvider.child as GrammarQuestScreen;
      expect(screen.level, equals(1));
      expect(screen.gameType, equals(GameSubtype.grammarQuest));
    });

    test('resolves listening category with audioMultipleChoice screen', () {
      final state = createMockState(
        '/game?category=listening&gameType=audioMultipleChoice&level=5',
      );
      final page =
          gameRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<BlocProvider<ListeningBloc>>());
      final blocProvider = page.child as BlocProvider<ListeningBloc>;
      expect(blocProvider.child, isA<AudioMultipleChoiceScreen>());
      final screen = blocProvider.child as AudioMultipleChoiceScreen;
      expect(screen.level, equals(5));
      expect(screen.gameType, equals(GameSubtype.audioMultipleChoice));
    });

    test('resolves roleplay category with branchingDialogue screen', () {
      final state = createMockState(
        '/game?category=roleplay&gameType=branchingDialogue&level=2',
      );
      final page =
          gameRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<BlocProvider<RoleplayBloc>>());
      final blocProvider = page.child as BlocProvider<RoleplayBloc>;
      expect(blocProvider.child, isA<BranchingDialogueScreen>());
      final screen = blocProvider.child as BranchingDialogueScreen;
      expect(screen.level, equals(2));
      expect(screen.gameType, equals(GameSubtype.branchingDialogue));
    });

    test('resolves accent category with minimalPairs screen', () {
      final state = createMockState(
        '/game?category=accent&gameType=minimalPairs&level=3',
      );
      final page =
          gameRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<BlocProvider<AccentBloc>>());
      final blocProvider = page.child as BlocProvider<AccentBloc>;
      expect(blocProvider.child, isA<MinimalPairsScreen>());
      final screen = blocProvider.child as MinimalPairsScreen;
      expect(screen.level, equals(3));
      expect(screen.gameType, equals(GameSubtype.minimalPairs));
    });

    test('resolves vocabulary category with flashcards screen', () {
      final state = createMockState(
        '/game?category=vocabulary&gameType=flashcards&level=2',
      );
      final page =
          gameRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<BlocProvider<VocabularyBloc>>());
      final blocProvider = page.child as BlocProvider<VocabularyBloc>;
      expect(blocProvider.child, isA<FlashcardsScreen>());
      final screen = blocProvider.child as FlashcardsScreen;
      expect(screen.level, equals(2));
      expect(screen.gameType, equals(GameSubtype.flashcards));
    });

    test('resolves elite mastery category with storyBuilder screen', () {
      final state = createMockState(
        '/game?category=elitemastery&gameType=storyBuilder&level=1',
      );
      final page =
          gameRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<BlocProvider<EliteMasteryBloc>>());
      final blocProvider = page.child as BlocProvider<EliteMasteryBloc>;
      expect(blocProvider.child, isA<StoryBuilderScreen>());
      final screen = blocProvider.child as StoryBuilderScreen;
      expect(screen.level, equals(1));
      expect(screen.gameType, equals(GameSubtype.storyBuilder));
    });

    test('resolves elite_mastery (with underscore) category properly', () {
      final state = createMockState(
        '/game?category=elite_mastery&gameType=storyBuilder&level=2',
      );
      final page =
          gameRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<BlocProvider<EliteMasteryBloc>>());
      final blocProvider = page.child as BlocProvider<EliteMasteryBloc>;
      expect(blocProvider.child, isA<StoryBuilderScreen>());
      final screen = blocProvider.child as StoryBuilderScreen;
      expect(screen.level, equals(2));
      expect(screen.gameType, equals(GameSubtype.storyBuilder));
    });

    test('supports subtype parameter as alias for gameType', () {
      final state = createMockState(
        '/game?category=writing&subtype=sentenceBuilder&level=2',
      );
      final page =
          gameRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      final blocProvider = page.child as BlocProvider<WritingBloc>;
      expect(blocProvider.child, isA<SentenceBuilderScreen>());
    });

    test('handles case-insensitivity in category parameter', () {
      final state = createMockState('/game?category=READING&level=1');
      final page =
          gameRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      final blocProvider = page.child as BlocProvider<ReadingBloc>;
      expect(blocProvider.child, isA<ReadAndAnswerScreen>());
    });

    test(
      'falls back gracefully to reading category when unknown category provided',
      () {
        final state = createMockState('/game?category=unknown_galaxy&level=2');
        final page =
            gameRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

        expect(page.child, isA<BlocProvider<ReadingBloc>>());
        final blocProvider = page.child as BlocProvider<ReadingBloc>;
        expect(blocProvider.child, isA<ReadAndAnswerScreen>());
      },
    );

    test(
      'falls back to category default subtype when unknown gameType provided',
      () {
        final state = createMockState(
          '/game?category=accent&gameType=nonexistent_drill&level=1',
        );
        final page =
            gameRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

        final blocProvider = page.child as BlocProvider<AccentBloc>;
        expect(blocProvider.child, isA<MinimalPairsScreen>());
      },
    );

    test(
      'defaults to level 1 when level parameter is missing or non-numeric',
      () {
        final stateMissing = createMockState('/game?category=reading');
        final pageMissing =
            gameRoute.pageBuilder!(mockContext, stateMissing)
                as CustomTransitionPage;
        final screenMissing =
            (pageMissing.child as BlocProvider<ReadingBloc>).child
                as ReadAndAnswerScreen;
        expect(screenMissing.level, equals(1));

        final stateInvalid = createMockState(
          '/game?category=reading&level=abc',
        );
        final pageInvalid =
            gameRoute.pageBuilder!(mockContext, stateInvalid)
                as CustomTransitionPage;
        final screenInvalid =
            (pageInvalid.child as BlocProvider<ReadingBloc>).child
                as ReadAndAnswerScreen;
        expect(screenInvalid.level, equals(1));
      },
    );
  });

  group('GameRoutes - /levels Route Resolution', () {
    final levelsRoute = findRoute('/levels');

    test('resolves ModernCategoryMap with specified category and gameType', () {
      final state = createMockState(
        '/levels?category=vocabulary&gameType=flashcards',
      );
      final page =
          levelsRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<ModernCategoryMap>());
      final mapWidget = page.child as ModernCategoryMap;
      expect(mapWidget.categoryId, equals('vocabulary'));
      expect(mapWidget.gameType, equals('flashcards'));
      expect(mapWidget.key, equals(const ValueKey('vocabulary_flashcards')));
    });

    test(
      'defaults category to reading and gameType to readAndAnswer when params omitted',
      () {
        final state = createMockState('/levels');
        final page =
            levelsRoute.pageBuilder!(mockContext, state)
                as CustomTransitionPage;

        expect(page.child, isA<ModernCategoryMap>());
        final mapWidget = page.child as ModernCategoryMap;
        expect(mapWidget.categoryId, equals('reading'));
        expect(mapWidget.gameType, equals('readAndAnswer'));
        expect(mapWidget.key, equals(const ValueKey('reading_readAndAnswer')));
      },
    );
  });

  group('GameRoutes - /category-games Route Resolution', () {
    final catGamesRoute = findRoute(GameRoutes.categoryGamesRoute);

    test('resolves CategoryGamesPage with explicit categoryId', () {
      final state = createMockState('/category-games?category=listening');
      final page =
          catGamesRoute.pageBuilder!(mockContext, state)
              as CustomTransitionPage;

      expect(page.child, isA<CategoryGamesPage>());
      final catWidget = page.child as CategoryGamesPage;
      expect(catWidget.categoryId, equals('listening'));
    });

    test('defaults categoryId to speaking when parameter omitted', () {
      final state = createMockState('/category-games');
      final page =
          catGamesRoute.pageBuilder!(mockContext, state)
              as CustomTransitionPage;

      expect(page.child, isA<CategoryGamesPage>());
      final catWidget = page.child as CategoryGamesPage;
      expect(catWidget.categoryId, equals('speaking'));
    });
  });

  group('GameRoutes - Profile, XP, Coins and Sequence Pages', () {
    test('resolves /level-details to AdventureLevelScreen', () {
      final route = findRoute(GameRoutes.levelRoute);
      final state = createMockState('/level-details');
      final page =
          route.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<AdventureLevelScreen>());
    });

    test('resolves /xp-details to AdventureXPScreen', () {
      final route = findRoute(GameRoutes.adventureXPRoute);
      final state = createMockState('/xp-details');
      final page =
          route.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<AdventureXPScreen>());
    });

    test('resolves /coins-details to VowlCoinsScreen', () {
      final route = findRoute(GameRoutes.questCoinsRoute);
      final state = createMockState('/coins-details');
      final page =
          route.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<VowlCoinsScreen>());
    });

    test('resolves /quest-sequence with authenticated user quests', () {
      final route = findRoute(GameRoutes.questSequenceRoute);
      final state = createMockState('/quest-sequence?id=daily_duo');
      final page =
          route.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<QuestSequencePage>());
      final sequencePage = page.child as QuestSequencePage;
      expect(sequencePage.sequenceId, equals('daily_duo'));
      expect(sequencePage.quests, isA<List<GameQuest>>());
    });

    test(
      'resolves /quest-sequence with empty quests if user is unauthenticated',
      () {
        when(
          () => mockAuthBloc.state,
        ).thenReturn(const AuthState.unauthenticated());

        final route = findRoute(GameRoutes.questSequenceRoute);
        final state = createMockState('/quest-sequence?id=speed_run');
        final page =
            route.pageBuilder!(mockContext, state) as CustomTransitionPage;

        expect(page.child, isA<QuestSequencePage>());
        final sequencePage = page.child as QuestSequencePage;
        expect(sequencePage.sequenceId, equals('speed_run'));
        expect(sequencePage.quests, isEmpty);
      },
    );
  });

  group('GameRoutes - /game Toll Gate Redirect Guard', () {
    late GoRoute gameRoute;

    setUp(() {
      gameRoute = findRoute('/game');
    });

    test('redirects to /levels when free user attempts to access Toll Gate level', () {
      const freeUser = UserEntity(
        id: 'u_free',
        email: 'free@vowl.app',
        isPremium: false,
        unlockedLevels: {'sentenceBuilder': 3},
      );
      when(() => mockAuthBloc.state).thenReturn(AuthState.authenticated(freeUser));

      final state = createMockState(
        '/game?category=writing&gameType=sentenceBuilder&level=4',
      );
      final redirect = gameRoute.redirect!(mockContext, state);

      expect(
        redirect,
        equals('/levels?category=writing&gameType=sentenceBuilder'),
      );
    });

    test('allows access (returns null) when level is unlocked for free user', () {
      const freeUser = UserEntity(
        id: 'u_free',
        email: 'free@vowl.app',
        isPremium: false,
        unlockedLevels: {'sentenceBuilder': 3},
      );
      when(() => mockAuthBloc.state).thenReturn(AuthState.authenticated(freeUser));

      final state = createMockState(
        '/game?category=writing&gameType=sentenceBuilder&level=3',
      );
      final redirect = gameRoute.redirect!(mockContext, state);

      expect(redirect, isNull);
    });

    test('allows access (returns null) for premium user on any level', () {
      const premiumUser = UserEntity(
        id: 'u_prem',
        email: 'prem@vowl.app',
        isPremium: true,
        unlockedLevels: {'sentenceBuilder': 3},
      );
      when(() => mockAuthBloc.state).thenReturn(AuthState.authenticated(premiumUser));

      final state = createMockState(
        '/game?category=writing&gameType=sentenceBuilder&level=10',
      );
      final redirect = gameRoute.redirect!(mockContext, state);

      expect(redirect, isNull);
    });
  });

  group('GameRoutes - /learn and /practice Route Resolution', () {
    test('resolves /learn route with LearnPhaseScaffold', () {
      final learnRoute = findRoute(GameRoutes.learnRoute);
      final state = createMockState('/learn?category=vocabulary&gameType=flashcards&level=2');
      final page = learnRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<Widget>());
    });

    test('resolves /practice route with PracticePhaseScaffold', () {
      final practiceRoute = findRoute(GameRoutes.practiceRoute);
      final state = createMockState('/practice?category=vocabulary&gameType=flashcards&level=3');
      final page = practiceRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<Widget>());
    });

    test('resolves /learn route for audioFillBlanks', () {
      final learnRoute = findRoute(GameRoutes.learnRoute);
      final state = createMockState('/learn?category=listening&gameType=audioFillBlanks&level=2');
      final page = learnRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<AudioFillBlanksLearnScreen>());
    });

    test('resolves /practice route for audioFillBlanks', () {
      final practiceRoute = findRoute(GameRoutes.practiceRoute);
      final state = createMockState('/practice?category=listening&gameType=audioFillBlanks&level=2');
      final page = practiceRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<AudioFillBlanksPracticeScreen>());
    });

    test('resolves /learn route for audioMultipleChoice', () {
      final learnRoute = findRoute(GameRoutes.learnRoute);
      final state = createMockState('/learn?category=listening&gameType=audioMultipleChoice&level=3');
      final page = learnRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<AudioMultipleChoiceLearnScreen>());
    });

    test('resolves /practice route for audioMultipleChoice', () {
      final practiceRoute = findRoute(GameRoutes.practiceRoute);
      final state = createMockState('/practice?category=listening&gameType=audioMultipleChoice&level=3');
      final page = practiceRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<AudioMultipleChoicePracticeScreen>());
    });

    test('resolves /learn route for audioSentenceOrder', () {
      final learnRoute = findRoute(GameRoutes.learnRoute);
      final state = createMockState('/learn?category=listening&gameType=audioSentenceOrder&level=4');
      final page = learnRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<AudioSentenceOrderLearnScreen>());
    });

    test('resolves /practice route for audioSentenceOrder', () {
      final practiceRoute = findRoute(GameRoutes.practiceRoute);
      final state = createMockState('/practice?category=listening&gameType=audioSentenceOrder&level=4');
      final page = practiceRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<AudioSentenceOrderPracticeScreen>());
    });

    test('resolves /learn route for audioTrueFalse', () {
      final learnRoute = findRoute(GameRoutes.learnRoute);
      final state = createMockState('/learn?category=listening&gameType=audioTrueFalse&level=4');
      final page = learnRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<AudioTrueFalseLearnScreen>());
    });

    test('resolves /practice route for audioTrueFalse', () {
      final practiceRoute = findRoute(GameRoutes.practiceRoute);
      final state = createMockState('/practice?category=listening&gameType=audioTrueFalse&level=4');
      final page = practiceRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<AudioTrueFalsePracticeScreen>());
    });

    test('resolves /learn route for soundImageMatch', () {
      final learnRoute = findRoute(GameRoutes.learnRoute);
      final state = createMockState('/learn?category=listening&gameType=soundImageMatch&level=4');
      final page = learnRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<SoundImageMatchLearnScreen>());
    });

    test('resolves /practice route for soundImageMatch', () {
      final practiceRoute = findRoute(GameRoutes.practiceRoute);
      final state = createMockState('/practice?category=listening&gameType=soundImageMatch&level=4');
      final page = practiceRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<SoundImageMatchPracticeScreen>());
    });

    test('resolves /learn route for fastSpeechDecoder', () {
      final learnRoute = findRoute(GameRoutes.learnRoute);
      final state = createMockState('/learn?category=listening&gameType=fastSpeechDecoder&level=4');
      final page = learnRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<FastSpeechDecoderLearnScreen>());
    });

    test('resolves /practice route for fastSpeechDecoder', () {
      final practiceRoute = findRoute(GameRoutes.practiceRoute);
      final state = createMockState('/practice?category=listening&gameType=fastSpeechDecoder&level=4');
      final page = practiceRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<FastSpeechDecoderPracticeScreen>());
    });

    test('resolves /learn route for emotionRecognition', () {
      final learnRoute = findRoute(GameRoutes.learnRoute);
      final state = createMockState('/learn?category=listening&gameType=emotionRecognition&level=4');
      final page = learnRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<EmotionRecognitionLearnScreen>());
    });

    test('resolves /practice route for emotionRecognition', () {
      final practiceRoute = findRoute(GameRoutes.practiceRoute);
      final state = createMockState('/practice?category=listening&gameType=emotionRecognition&level=4');
      final page = practiceRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<EmotionRecognitionPracticeScreen>());
    });

    test('resolves /learn route for detailSpotlight', () {
      final learnRoute = findRoute(GameRoutes.learnRoute);
      final state = createMockState('/learn?category=listening&gameType=detailSpotlight&level=4');
      final page = learnRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<DetailSpotlightLearnScreen>());
    });

    test('resolves /practice route for detailSpotlight', () {
      final practiceRoute = findRoute(GameRoutes.practiceRoute);
      final state = createMockState('/practice?category=listening&gameType=detailSpotlight&level=4');
      final page = practiceRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<DetailSpotlightPracticeScreen>());
    });

    test('resolves /learn route for listeningInference', () {
      final learnRoute = findRoute(GameRoutes.learnRoute);
      final state = createMockState('/learn?category=listening&gameType=listeningInference&level=4');
      final page = learnRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<ListeningInferenceLearnScreen>());
    });

    test('resolves /practice route for listeningInference', () {
      final practiceRoute = findRoute(GameRoutes.practiceRoute);
      final state = createMockState('/practice?category=listening&gameType=listeningInference&level=4');
      final page = practiceRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<ListeningInferencePracticeScreen>());
    });

    test('resolves /learn route for ambientId', () {
      final learnRoute = findRoute(GameRoutes.learnRoute);
      final state = createMockState('/learn?category=listening&gameType=ambientId&level=2');
      final page = learnRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<AmbientIdLearnScreen>());
    });

    test('resolves /practice route for ambientId', () {
      final practiceRoute = findRoute(GameRoutes.practiceRoute);
      final state = createMockState('/practice?category=listening&gameType=ambientId&level=2');
      final page = practiceRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<AmbientIdPracticeScreen>());
    });

    test('resolves /learn route for minimalPairs', () {
      final learnRoute = findRoute(GameRoutes.learnRoute);
      final state = createMockState('/learn?category=accent&gameType=minimalPairs&level=3');
      final page = learnRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<MinimalPairsLearnScreen>());
    });

    test('resolves /practice route for minimalPairs', () {
      final practiceRoute = findRoute(GameRoutes.practiceRoute);
      final state = createMockState('/practice?category=accent&gameType=minimalPairs&level=3');
      final page = practiceRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<MinimalPairsPracticeScreen>());
    });

    test('resolves /learn route for intonationMimic', () {
      final learnRoute = findRoute(GameRoutes.learnRoute);
      final state = createMockState('/learn?category=accent&gameType=intonationMimic&level=5');
      final page = learnRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<IntonationMimicLearnScreen>());
    });

    test('resolves /practice route for intonationMimic', () {
      final practiceRoute = findRoute(GameRoutes.practiceRoute);
      final state = createMockState('/practice?category=accent&gameType=intonationMimic&level=5');
      final page = practiceRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<IntonationMimicPracticeScreen>());
    });

    test('resolves /learn route for syllableStress', () {
      final learnRoute = findRoute(GameRoutes.learnRoute);
      final state = createMockState('/learn?category=accent&gameType=syllableStress&level=5');
      final page = learnRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<SyllableStressLearnScreen>());
    });

    test('resolves /practice route for syllableStress', () {
      final practiceRoute = findRoute(GameRoutes.practiceRoute);
      final state = createMockState('/practice?category=accent&gameType=syllableStress&level=5');
      final page = practiceRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<SyllableStressPracticeScreen>());
    });

    test('resolves /learn route for wordLinking', () {
      final learnRoute = findRoute(GameRoutes.learnRoute);
      final state = createMockState('/learn?category=accent&gameType=wordLinking&level=5');
      final page = learnRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<WordLinkingLearnScreen>());
    });

    test('resolves /practice route for wordLinking', () {
      final practiceRoute = findRoute(GameRoutes.practiceRoute);
      final state = createMockState('/practice?category=accent&gameType=wordLinking&level=5');
      final page = practiceRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<WordLinkingPracticeScreen>());
    });

    test('resolves /learn route for shadowingChallenge', () {
      final learnRoute = findRoute(GameRoutes.learnRoute);
      final state =
          createMockState('/learn?category=accent&gameType=shadowingChallenge&level=5');
      final page = learnRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<ShadowingChallengeLearnScreen>());
    });

    test('resolves /practice route for shadowingChallenge', () {
      final practiceRoute = findRoute(GameRoutes.practiceRoute);
      final state =
          createMockState('/practice?category=accent&gameType=shadowingChallenge&level=5');
      final page = practiceRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<ShadowingChallengePracticeScreen>());
    });

    test('resolves /learn route for vowelDistinction', () {
      final learnRoute = findRoute(GameRoutes.learnRoute);
      final state =
          createMockState('/learn?category=accent&gameType=vowelDistinction&level=5');
      final page = learnRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<VowelDistinctionLearnScreen>());
    });

    test('resolves /practice route for vowelDistinction', () {
      final practiceRoute = findRoute(GameRoutes.practiceRoute);
      final state =
          createMockState('/practice?category=accent&gameType=vowelDistinction&level=5');
      final page = practiceRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<VowelDistinctionPracticeScreen>());
    });

    test('resolves /learn route for consonantClarity', () {
      final learnRoute = findRoute(GameRoutes.learnRoute);
      final state =
          createMockState('/learn?category=accent&gameType=consonantClarity&level=5');
      final page = learnRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<ConsonantClarityLearnScreen>());
    });

    test('resolves /practice route for consonantClarity', () {
      final practiceRoute = findRoute(GameRoutes.practiceRoute);
      final state =
          createMockState('/practice?category=accent&gameType=consonantClarity&level=5');
      final page = practiceRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<ConsonantClarityPracticeScreen>());
    });

    test('resolves /learn route for pitchPatternMatch', () {
      final learnRoute = findRoute(GameRoutes.learnRoute);
      final state =
          createMockState('/learn?category=accent&gameType=pitchPatternMatch&level=5');
      final page = learnRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<PitchPatternMatchLearnScreen>());
    });

    test('resolves /practice route for pitchPatternMatch', () {
      final practiceRoute = findRoute(GameRoutes.practiceRoute);
      final state =
          createMockState('/practice?category=accent&gameType=pitchPatternMatch&level=5');
      final page = practiceRoute.pageBuilder!(mockContext, state) as CustomTransitionPage;

      expect(page.child, isA<PitchPatternMatchPracticeScreen>());
    });
  });
}

