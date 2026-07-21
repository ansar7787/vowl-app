import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/app_router_game_resolvers.dart';
import 'package:vowl/core/utils/navigation_helpers.dart';
import 'package:vowl/core/presentation/widgets/games/maps/modern_category_map.dart';
import 'package:vowl/features/home/presentation/pages/category_games_page.dart';
import 'package:vowl/features/profile/presentation/pages/adventure_level_screen.dart';
import 'package:vowl/features/profile/presentation/pages/adventure_xp_screen.dart';
import 'package:vowl/features/profile/presentation/pages/quest_coins_screen.dart';
import 'package:vowl/core/presentation/pages/quest_sequence_page.dart';
import 'package:vowl/core/utils/discovery_helper.dart';
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

class GameRoutes {
  GameRoutes._(); // Non-instantiable utility class.

  static const String categoryGamesRoute = '/category-games';
  static const String levelRoute = '/level-details';
  static const String adventureXPRoute = '/xp-details';
  static const String questCoinsRoute = '/coins-details';
  static const String questSequenceRoute = '/quest-sequence';

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
    final config =
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
  static final List<RouteBase> routes = [
    GoRoute(
      path: '/game',
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
        final sequenceId = state.uri.queryParameters['id'] ?? 'daily_duo';
        final user = di.sl<AuthBloc>().state.user;
        final quests = user != null
            ? DiscoveryHelper.getQuestsForSequence(sequenceId, user)
            : <GameQuest>[];

        return fadeTransitionPage(
          child: QuestSequencePage(sequenceId: sequenceId, quests: quests),
          state: state,
        );
      },
    ),
  ];
}
