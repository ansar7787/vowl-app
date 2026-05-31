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

import 'package:vowl/features/elite_mastery/story_builder/presentation/pages/story_builder_map.dart'
    as sb_map;
import 'package:vowl/features/elite_mastery/idiom_match/presentation/pages/idiom_match_map.dart'
    as im_map;
import 'package:vowl/features/elite_mastery/speed_spelling/presentation/pages/speed_spelling_map.dart'
    as ss_map;
import 'package:vowl/features/elite_mastery/accent_shadowing/presentation/pages/accent_shadowing_map.dart'
    as as_map;

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
      path: '/story-builder-map',
      pageBuilder: (context, state) => fadeTransitionPage(
        child: const sb_map.StoryBuilderMap(),
        state: state,
      ),
    ),
    GoRoute(
      path: '/story-builder/:level',
      pageBuilder: (context, state) {
        final level = int.tryParse(state.pathParameters['level'] ?? '1') ?? 1;
        return fadeTransitionPage(
          child: AppRouterGameResolvers.getEliteMasteryScreen(GameSubtype.storyBuilder, level),
          state: state,
        );
      },
    ),
    GoRoute(
      path: '/idiom-match-map',
      pageBuilder: (context, state) => fadeTransitionPage(
        child: const im_map.IdiomMatchMap(),
        state: state,
      ),
    ),
    GoRoute(
      path: '/idiom-match/:level',
      pageBuilder: (context, state) {
        final level = int.tryParse(state.pathParameters['level'] ?? '1') ?? 1;
        return fadeTransitionPage(
          child: AppRouterGameResolvers.getEliteMasteryScreen(GameSubtype.idiomMatch, level),
          state: state,
        );
      },
    ),
    GoRoute(
      path: '/speed-spelling-map',
      pageBuilder: (context, state) => fadeTransitionPage(
        child: const ss_map.SpeedSpellingMap(),
        state: state,
      ),
    ),
    GoRoute(
      path: '/speed-spelling/:level',
      pageBuilder: (context, state) {
        final level = int.tryParse(state.pathParameters['level'] ?? '1') ?? 1;
        return fadeTransitionPage(
          child: AppRouterGameResolvers.getEliteMasteryScreen(GameSubtype.speedSpelling, level),
          state: state,
        );
      },
    ),
    GoRoute(
      path: '/accent-shadowing-map',
      pageBuilder: (context, state) => fadeTransitionPage(
        child: const as_map.AccentShadowingMap(),
        state: state,
      ),
    ),
    GoRoute(
      path: '/accent-shadowing/:level',
      pageBuilder: (context, state) {
        final level = int.tryParse(state.pathParameters['level'] ?? '1') ?? 1;
        return fadeTransitionPage(
          child: AppRouterGameResolvers.getEliteMasteryScreen(GameSubtype.accentShadowing, level),
          state: state,
        );
      },
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
