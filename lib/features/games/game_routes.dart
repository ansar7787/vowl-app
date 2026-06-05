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


class GameRoutes {
  static const String categoryGamesRoute = '/category-games';
  static const String levelRoute = '/level-details';
  static const String adventureXPRoute = '/xp-details';
  static const String questCoinsRoute = '/coins-details';
  static const String questSequenceRoute = '/quest-sequence';

  static final List<RouteBase> routes = [
    GoRoute(
      path: '/game',
      pageBuilder: (context, state) {
        final category = state.uri.queryParameters['category'] ?? 'reading';
        final level = int.tryParse(state.uri.queryParameters['level'] ?? '1') ?? 1;
        final gameTypeStr = state.uri.queryParameters['gameType'] ?? state.uri.queryParameters['subtype'];

        Widget screen;
        switch (category.toLowerCase()) {
          case 'reading':
            final gameType = gameTypeStr != null
                ? GameSubtype.values.firstWhere(
                    (e) => e.name.toLowerCase() == gameTypeStr.toLowerCase(),
                    orElse: () => GameSubtype.readAndAnswer,
                  )
                : GameSubtype.readAndAnswer;
            screen = AppRouterGameResolvers.getReadingScreen(gameType, level);
            break;
          case 'writing':
            final gameType = gameTypeStr != null
                ? GameSubtype.values.firstWhere(
                    (e) => e.name.toLowerCase() == gameTypeStr.toLowerCase(),
                    orElse: () => GameSubtype.sentenceBuilder,
                  )
                : GameSubtype.sentenceBuilder;
            screen = AppRouterGameResolvers.getWritingScreen(gameType, level);
            break;
          case 'speaking':
            final gameType = gameTypeStr != null
                ? GameSubtype.values.firstWhere(
                    (e) => e.name.toLowerCase() == gameTypeStr.toLowerCase(),
                    orElse: () => GameSubtype.repeatSentence,
                  )
                : GameSubtype.repeatSentence;
            screen = AppRouterGameResolvers.getSpeakingScreen(gameType, level);
            break;
          case 'grammar':
            final gameType = gameTypeStr != null
                ? GameSubtype.values.firstWhere(
                    (e) => e.name.toLowerCase() == gameTypeStr.toLowerCase(),
                    orElse: () => GameSubtype.grammarQuest,
                  )
                : GameSubtype.grammarQuest;
            screen = AppRouterGameResolvers.getGrammarScreen(gameType, level);
            break;
          case 'roleplay':
            final gameType = gameTypeStr != null
                ? GameSubtype.values.firstWhere(
                    (e) => e.name.toLowerCase() == gameTypeStr.toLowerCase(),
                    orElse: () => GameSubtype.branchingDialogue,
                  )
                : GameSubtype.branchingDialogue;
            screen = AppRouterGameResolvers.getRoleplayScreen(gameType, level);
            break;
          case 'accent':
            final gameType = gameTypeStr != null
                ? GameSubtype.values.firstWhere(
                    (e) => e.name.toLowerCase() == gameTypeStr.toLowerCase(),
                    orElse: () => GameSubtype.minimalPairs,
                  )
                : GameSubtype.minimalPairs;
            screen = AppRouterGameResolvers.getAccentScreen(gameType, level);
            break;
          case 'listening':
            final gameType = gameTypeStr != null
                ? GameSubtype.values.firstWhere(
                    (e) => e.name.toLowerCase() == gameTypeStr.toLowerCase(),
                    orElse: () => GameSubtype.audioMultipleChoice,
                  )
                : GameSubtype.audioMultipleChoice;
            screen = AppRouterGameResolvers.getListeningScreen(gameType, level);
            break;
          case 'vocabulary':
            final gameType = gameTypeStr != null
                ? GameSubtype.values.firstWhere(
                    (e) => e.name.toLowerCase() == gameTypeStr.toLowerCase(),
                    orElse: () => GameSubtype.flashcards,
                  )
                : GameSubtype.flashcards;
            screen = AppRouterGameResolvers.getVocabularyScreen(gameType, level);
            break;
          case 'elitemastery':
            final gameType = gameTypeStr != null
                ? GameSubtype.values.firstWhere(
                    (e) => e.name.toLowerCase() == gameTypeStr.toLowerCase(),
                    orElse: () => GameSubtype.storyBuilder,
                  )
                : GameSubtype.storyBuilder;
            screen = AppRouterGameResolvers.getEliteMasteryScreen(gameType, level);
            break;
          default:
            screen = AppRouterGameResolvers.getReadingScreen(GameSubtype.readAndAnswer, level);
        }
        return fadeTransitionPage(child: screen, state: state);
      },
    ),
    GoRoute(
      path: '/levels',
      pageBuilder: (context, state) {
        final categoryId = state.uri.queryParameters['category'] ?? 'reading';
        final gameType = state.uri.queryParameters['gameType'] ?? 'readAndAnswer';

        return fadeTransitionPage(
          child: ModernCategoryMap(
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
      pageBuilder: (context, state) => fadeTransitionPage(
        child: const AdventureLevelScreen(),
        state: state,
      ),
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
