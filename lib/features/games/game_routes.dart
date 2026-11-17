import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/app_router_game_resolvers.dart';
import 'package:vowl/core/utils/navigation_helpers.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/home/presentation/pages/category_games_page.dart';
import 'package:vowl/features/profile/presentation/pages/adventure_level_screen.dart';
import 'package:vowl/features/profile/presentation/pages/adventure_xp_screen.dart';
import 'package:vowl/features/profile/presentation/pages/quest_coins_screen.dart';
import 'package:vowl/core/presentation/pages/quest_sequence_page.dart';
import 'package:vowl/core/presentation/phases/learn_phase_scaffold.dart';
import 'package:vowl/core/presentation/phases/practice_phase_scaffold.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/pages/flashcards_learn_screen.dart';
import 'package:vowl/features/vocabulary/flashcards/presentation/pages/flashcards_practice_screen.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/pages/synonym_search_learn_screen.dart';
import 'package:vowl/features/vocabulary/synonym_search/presentation/pages/synonym_search_practice_screen.dart';
import 'package:vowl/features/vocabulary/antonym_search/presentation/pages/antonym_search_learn_screen.dart';
import 'package:vowl/features/vocabulary/antonym_search/presentation/pages/antonym_search_practice_screen.dart';
import 'package:vowl/features/vocabulary/context_clues/presentation/pages/context_clues_learn_screen.dart';
import 'package:vowl/features/vocabulary/context_clues/presentation/pages/context_clues_practice_screen.dart';
import 'package:vowl/features/vocabulary/phrasal_verbs/presentation/pages/phrasal_verbs_learn_screen.dart';
import 'package:vowl/features/vocabulary/phrasal_verbs/presentation/pages/phrasal_verbs_practice_screen.dart';
import 'package:vowl/features/vocabulary/idioms/presentation/pages/idioms_learn_screen.dart';
import 'package:vowl/features/vocabulary/idioms/presentation/pages/idioms_practice_screen.dart';
import 'package:vowl/features/vocabulary/academic_word/presentation/pages/academic_word_learn_screen.dart';
import 'package:vowl/features/vocabulary/academic_word/presentation/pages/academic_word_practice_screen.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/discovery_helper.dart';
import 'package:vowl/core/utils/toll_gate_helper.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

// ---------------------------------------------------------------------------
// Private: configuration descriptor for each game category.
//
// FIX (HIGH-3): Replaces the 9-case switch statement. Adding a new category
// now requires a single map entry instead of copy-pasting ~10 lines.
// Routing is O(1) map lookup vs O(n) sequential case evaluation.
// ---------------------------------------------------------------------------

typedef _ScreenFactory = Widget Function(GameSubtype subtype, int level);

class _CategoryConfig {
  const _CategoryConfig({required this.defaultSubtype, required this.factory});

  final GameSubtype defaultSubtype;
  final _ScreenFactory factory;
}

/// Central routing configuration and game screen resolvers for all curriculum games.
///
/// Provides declarative [GoRoute] definitions and O(1) map-based screen
/// resolution across reading, writing, listening, speaking, grammar, vocabulary,
/// accent, roleplay, and elite mastery.
class GameRoutes {
  GameRoutes._(); // Non-instantiable utility class.

  /// Route path for category-specific game list screens.
  static const String categoryGamesRoute = '/category-games';

  /// Route path for level detail dialogs and views.
  static const String levelRoute = '/level-details';

  /// Route path for adventure XP breakdown views.
  static const String adventureXPRoute = '/xp-details';

  /// Route path for quest coins details and shop navigation.
  static const String questCoinsRoute = '/coins-details';

  /// Route path for multi-step quest sequence runners.
  static const String questSequenceRoute = '/quest-sequence';

  /// Route path for the Learn phase.
  static const String learnRoute = '/learn';

  /// Route path for the Practice phase.
  static const String practiceRoute = '/practice';

  // ---------------------------------------------------------------------------
  // Category → (default GameSubtype, screen factory) mapping.
  // ---------------------------------------------------------------------------
  static final Map<String, _CategoryConfig> _categoryConfigs = {
    'reading': _CategoryConfig(
      defaultSubtype: GameSubtype.readAndAnswer,
      factory: AppRouterGameResolvers.getReadingScreen,
    ),
    'writing': _CategoryConfig(
      defaultSubtype: GameSubtype.sentenceBuilder,
      factory: AppRouterGameResolvers.getWritingScreen,
    ),
    'speaking': _CategoryConfig(
      defaultSubtype: GameSubtype.repeatSentence,
      factory: AppRouterGameResolvers.getSpeakingScreen,
    ),
    'grammar': _CategoryConfig(
      defaultSubtype: GameSubtype.grammarQuest,
      factory: AppRouterGameResolvers.getGrammarScreen,
    ),
    'roleplay': _CategoryConfig(
      defaultSubtype: GameSubtype.branchingDialogue,
      factory: AppRouterGameResolvers.getRoleplayScreen,
    ),
    'accent': _CategoryConfig(
      defaultSubtype: GameSubtype.minimalPairs,
      factory: AppRouterGameResolvers.getAccentScreen,
    ),
    'listening': _CategoryConfig(
      defaultSubtype: GameSubtype.audioMultipleChoice,
      factory: AppRouterGameResolvers.getListeningScreen,
    ),
    'vocabulary': _CategoryConfig(
      defaultSubtype: GameSubtype.flashcards,
      factory: AppRouterGameResolvers.getVocabularyScreen,
    ),
    'elitemastery': _CategoryConfig(
      defaultSubtype: GameSubtype.storyBuilder,
      factory: AppRouterGameResolvers.getEliteMasteryScreen,
    ),
    'elite_mastery': _CategoryConfig(
      defaultSubtype: GameSubtype.storyBuilder,
      factory: AppRouterGameResolvers.getEliteMasteryScreen,
    ),
  };

  // ---------------------------------------------------------------------------
  // Resolves a game screen from URL query parameters.
  // Falls back to reading/readAndAnswer for unknown categories.
  // ---------------------------------------------------------------------------
  static Widget _resolveGameScreen({
    required String category,
    required String? gameTypeStr,
    required int level,
  }) {
    final normalized = category
        .toLowerCase()
        .replaceAll('_', '')
        .replaceAll(' ', '');
    final config =
        _categoryConfigs[normalized] ??
        _categoryConfigs[category.toLowerCase()] ??
        _categoryConfigs['reading']!;

    final subtype = gameTypeStr != null
        ? GameSubtype.values.firstWhere(
            (e) => e.name.toLowerCase() == gameTypeStr.toLowerCase(),
            orElse: () => config.defaultSubtype,
          )
        : config.defaultSubtype;

    return config.factory(subtype, level);
  }

  // ---------------------------------------------------------------------------
  // Route definitions
  // ---------------------------------------------------------------------------
  /// Declarative [RouteBase] definitions registered with GoRouter.
  static final List<RouteBase> routes = [
    GoRoute(
      path: '/game',
      redirect: (context, state) {
        final authBloc =
            di.sl.isRegistered<AuthBloc>() ? di.sl<AuthBloc>() : null;
        final user = authBloc?.state.user;
        final gameTypeStr = state.uri.queryParameters['gameType'] ??
            state.uri.queryParameters['subtype'];
        final level =
            int.tryParse(state.uri.queryParameters['level'] ?? '1') ?? 1;

        if (gameTypeStr != null &&
            TollGateHelper.isTollGate(
              user: user,
              gameType: gameTypeStr,
              level: level,
            )) {
          final category =
              state.uri.queryParameters['category'] ?? 'reading';
          return '${AppRouter.levelsRoute}?category=${Uri.encodeQueryComponent(category)}&gameType=${Uri.encodeQueryComponent(gameTypeStr)}';
        }
        return null;
      },
      pageBuilder: (context, state) {
        final category = state.uri.queryParameters['category'] ?? 'reading';
        final level =
            int.tryParse(state.uri.queryParameters['level'] ?? '1') ?? 1;
        final gameTypeStr =
            state.uri.queryParameters['gameType'] ??
            state.uri.queryParameters['subtype'];

        final screen = _resolveGameScreen(
          category: category,
          gameTypeStr: gameTypeStr,
          level: level,
        );

        return fadeTransitionPage(child: screen, state: state);
      },
    ),

    GoRoute(
      path: '/levels',
      pageBuilder: (context, state) {
        final categoryId = state.uri.queryParameters['category'] ?? 'reading';
        final gameType =
            state.uri.queryParameters['gameType'] ?? 'readAndAnswer';

        return fadeTransitionPage(
          child: ModernCategoryMap(
            key: ValueKey('${categoryId}_$gameType'),
            gameType: gameType,
            categoryId: categoryId,
          ),
          state: state,
        );
      },
    ),

    GoRoute(
      path: categoryGamesRoute,
      pageBuilder: (context, state) => fadeTransitionPage(
        child: CategoryGamesPage(
          categoryId: state.uri.queryParameters['category'] ?? 'speaking',
        ),
        state: state,
      ),
    ),

    GoRoute(
      path: levelRoute,
      pageBuilder: (context, state) =>
          fadeTransitionPage(child: const AdventureLevelScreen(), state: state),
    ),

    GoRoute(
      path: adventureXPRoute,
      pageBuilder: (context, state) =>
          fadeTransitionPage(child: const AdventureXPScreen(), state: state),
    ),

    GoRoute(
      path: questCoinsRoute,
      pageBuilder: (context, state) =>
          fadeTransitionPage(child: const VowlCoinsScreen(), state: state),
    ),

    GoRoute(
      path: questSequenceRoute,
      pageBuilder: (context, state) {
        final sequenceId = state.uri.queryParameters['id'] ?? 'daily_workout';
        UserEntity? user;
        try {
          user = context.read<AuthBloc>().state.user;
        } catch (_) {
          try {
            user = di.sl<AuthBloc>().state.user;
          } catch (_) {}
        }
        final quests = user != null
            ? DiscoveryHelper.getQuestsForSequence(sequenceId, user)
            : <GameQuest>[];

        return fadeTransitionPage(
          child: QuestSequencePage(sequenceId: sequenceId, quests: quests),
          state: state,
        );
      },
    ),

    GoRoute(
      path: learnRoute,
      pageBuilder: (context, state) {
        final category = state.uri.queryParameters['category'] ?? 'vocabulary';
        final gameType = state.uri.queryParameters['gameType'] ?? 'flashcards';
        final level = int.tryParse(state.uri.queryParameters['level'] ?? '1') ?? 1;

        if (gameType.toLowerCase() == 'flashcards') {
          return fadeTransitionPage(
            child: FlashcardsLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'synonymsearch') {
          return fadeTransitionPage(
            child: SynonymSearchLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'antonymsearch') {
          return fadeTransitionPage(
            child: AntonymSearchLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'contextclues') {
          return fadeTransitionPage(
            child: ContextCluesLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'phrasalverbs') {
          return fadeTransitionPage(
            child: PhrasalVerbsLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'idioms') {
          return fadeTransitionPage(
            child: IdiomsLearnScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'academicword') {
          return fadeTransitionPage(
            child: AcademicWordLearnScreen(level: level),
            state: state,
          );
        }

        return fadeTransitionPage(
          child: LearnPhaseScaffold(
            title: '$gameType Discovery',
            gameType: gameType,
            level: level,
            onComplete: () {
              final targetPractice = '$practiceRoute?category=${Uri.encodeQueryComponent(category)}&gameType=${Uri.encodeQueryComponent(gameType)}&level=$level';
              context.pushReplacement(targetPractice);
            },
            child: Center(
              child: Text(
                'Learn Phase: $category / $gameType (Level $level)',
                style: const TextStyle(fontFamily: 'Outfit'),
              ),
            ),
          ),
          state: state,
        );
      },
    ),

    GoRoute(
      path: practiceRoute,
      pageBuilder: (context, state) {
        final category = state.uri.queryParameters['category'] ?? 'vocabulary';
        final gameType = state.uri.queryParameters['gameType'] ?? 'flashcards';
        final level = int.tryParse(state.uri.queryParameters['level'] ?? '1') ?? 1;

        if (gameType.toLowerCase() == 'flashcards') {
          return fadeTransitionPage(
            child: FlashcardsPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'synonymsearch') {
          return fadeTransitionPage(
            child: SynonymSearchPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'antonymsearch') {
          return fadeTransitionPage(
            child: AntonymSearchPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'contextclues') {
          return fadeTransitionPage(
            child: ContextCluesPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'phrasalverbs') {
          return fadeTransitionPage(
            child: PhrasalVerbsPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'idioms') {
          return fadeTransitionPage(
            child: IdiomsPracticeScreen(level: level),
            state: state,
          );
        }
        if (gameType.toLowerCase() == 'academicword') {
          return fadeTransitionPage(
            child: AcademicWordPracticeScreen(level: level),
            state: state,
          );
        }

        return fadeTransitionPage(
          child: PracticePhaseScaffold(
            title: '$gameType Gym',
            gameType: gameType,
            level: level,
            currentExerciseIndex: 0,
            totalExercises: 1,
            onComplete: () {
              final targetTest = '/game?category=${Uri.encodeQueryComponent(category)}&gameType=${Uri.encodeQueryComponent(gameType)}&level=$level';
              context.pushReplacement(targetTest);
            },
            child: Center(
              child: Text(
                'Practice Phase: $category / $gameType (Level $level)',
                style: const TextStyle(fontFamily: 'Outfit'),
              ),
            ),
          ),
          state: state,
        );
      },
    ),
  ];
}
