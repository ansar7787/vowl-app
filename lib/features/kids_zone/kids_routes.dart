import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/navigation_helpers.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/pages/sticker_book_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/mascot_selection_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/kids_zone_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/kids_level_map.dart';
import 'package:vowl/features/kids_zone/presentation/widgets/unified_kids_game_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/buddy_boutique_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/kids_room_screen.dart';

/// Defines the route paths and routing table for the Kids Zone feature module.
class KidsRoutes {
  /// Base route for the Kids Zone home dashboard.
  static const String kidsZoneRoute = '/kids-zone';

  /// Route template for the kids level progression map.
  static const String kidsLevelMapRoute = '/kids/map/:gameType';

  /// Route for the alphabet game.
  static const String kidsAlphabetRoute = '/kids-alphabet';

  /// Route for the numbers game.
  static const String kidsNumbersRoute = '/kids-numbers';

  /// Route for the colors game.
  static const String kidsColorsRoute = '/kids-colors';

  /// Route for the shapes game.
  static const String kidsShapesRoute = '/kids-shapes';

  /// Route for the animals game.
  static const String kidsAnimalsRoute = '/kids-animals';

  /// Route for the fruits game.
  static const String kidsFruitsRoute = '/kids-fruits';

  /// Route for the family game.
  static const String kidsFamilyRoute = '/kids-family';

  /// Route for the school game.
  static const String kidsSchoolRoute = '/kids-school';

  /// Route for the verbs game.
  static const String kidsVerbsRoute = '/kids-verbs';

  /// Route for the sticker collection book.
  static const String kidsStickerBookRoute = '/kids-stickers';

  /// Route for the mascot selection screen.
  static const String kidsMascotSelectionRoute = '/kids-mascot';

  /// Route for the daily routine game.
  static const String kidsRoutineRoute = '/kids-routine';

  /// Route for the emotions game.
  static const String kidsEmotionsRoute = '/kids-emotions';

  /// Route for the prepositions game.
  static const String kidsPrepositionsRoute = '/kids-prepositions';

  /// Route for the phonics game.
  static const String kidsPhonicsRoute = '/kids-phonics';

  /// Route for the time and clock game.
  static const String kidsTimeRoute = '/kids-time';

  /// Route for the opposites game.
  static const String kidsOppositesRoute = '/kids-opposites';

  /// Route for the day and night game.
  static const String kidsDayNightRoute = '/kids-day-night';

  /// Route for the nature game.
  static const String kidsNatureRoute = '/kids-nature';

  /// Route for the home items game.
  static const String kidsHomeRoute = '/kids-home';

  /// Route for the food items game.
  static const String kidsFoodRoute = '/kids-food';

  /// Route for the transport game.
  static const String kidsTransportRoute = '/kids-transport';

  /// Route for the body parts game.
  static const String kidsBodyPartsRoute = '/kids-body-parts';

  /// Route for the clothing game.
  static const String kidsClothingRoute = '/kids-clothing';

  /// Route for the mascot boutique shop.
  static const String kidsBuddyBoutiqueRoute = '/kids-zone/boutique';

  /// Route for the virtual buddy room.
  static const String kidsRoomRoute = '/kids-room';

  /// Route for the handwriting practice game.
  static const String kidsHandwritingRoute = '/kids-handwriting';

  /// Route for the weather game.
  static const String kidsWeatherRoute = '/kids-weather';

  /// Route for the professions game.
  static const String kidsProfessionsRoute = '/kids-professions';

  /// Resolves the user-facing display title for the specified [gameType].
  static String getKidsGameTitle(String gameType) {
    switch (gameType) {
      case 'alphabet':
        return 'Alphabet';
      case 'numbers':
        return 'Numbers';
      case 'colors':
        return 'Colors';
      case 'shapes':
        return 'Shapes';
      case 'animals':
        return 'Animals';
      case 'fruits':
        return 'Fruits';
      case 'family':
        return 'Family';
      case 'school':
        return 'School';
      case 'verbs':
        return 'Verbs';
      case 'routine':
        return 'Routine';
      case 'emotions':
        return 'Emotions';
      case 'prepositions':
        return 'Prepositions';
      case 'phonics':
        return 'Phonics';
      case 'jumble':
        return 'Jumble';
      case 'time':
        return 'Time';
      case 'opposites':
        return 'Opposites';
      case 'day_night':
        return 'Day/Night';
      case 'nature':
        return 'Nature';
      case 'home':
        return 'Home';
      case 'food':
        return 'Food';
      case 'transport':
        return 'Transport';
      case 'body_parts':
        return 'Body Parts';
      case 'clothing':
        return 'Clothing';
      case 'handwriting':
        return 'Handwriting';
      case 'weather':
        return 'Weather';
      case 'professions':
        return 'Professions';
      default:
        return 'Kids Game';
    }
  }

  /// Resolves the theme accent color for the specified [gameType].
  static Color getKidsGameColor(String gameType) {
    return LevelThemeHelper.getKidsGameColor(gameType);
  }

  static Widget _getKidsBlocWrapper(Widget child) {
    return BlocProvider<KidsBloc>(
      create: (context) => di.sl<KidsBloc>(),
      child: child,
    );
  }

  /// The declarative routing hierarchy for Kids Zone navigation.
  static final List<RouteBase> routes = [
    GoRoute(
      path: kidsZoneRoute,
      pageBuilder: (context, state) => fadeTransitionPage(
        child: BlocProvider<KidsBloc>(
          create: (context) => di.sl<KidsBloc>(),
          child: const KidsZoneScreen(),
        ),
        state: state,
      ),
      routes: [
        GoRoute(
          path: 'boutique',
          name: 'kids-boutique',
          pageBuilder: (context, state) => fadeTransitionPage(
            child: const BuddyBoutiqueScreen(),
            state: state,
          ),
        ),
        GoRoute(
          path: 'map/:gameType',
          builder: (context, state) {
            final gameType = state.pathParameters['gameType'] ?? 'alphabet';
            final extra = state.extra as Map<String, dynamic>?;
            final title = extra?['title'] as String? ?? 'Level Map';
            final primaryColor =
                extra?['primaryColor'] as Color? ?? Colors.blue;

            return BlocProvider<KidsBloc>(
              create: (context) => di.sl<KidsBloc>(),
              child: KidsLevelMap(
                gameType: gameType,
                title: title,
                primaryColor: primaryColor,
              ),
            );
          },
        ),
      ],
    ),
    GoRoute(
      path: kidsStickerBookRoute,
      pageBuilder: (context, state) =>
          fadeTransitionPage(child: const StickerBookScreen(), state: state),
    ),
    GoRoute(
      path: kidsMascotSelectionRoute,
      pageBuilder: (context, state) => fadeTransitionPage(
        child: const MascotSelectionScreen(),
        state: state,
      ),
    ),
    GoRoute(
      path: kidsLevelMapRoute,
      pageBuilder: (context, state) {
        final gameType = state.pathParameters['gameType'] ?? '';
        final extra = state.extra as Map<String, dynamic>?;

        return fadeTransitionPage(
          child: _getKidsBlocWrapper(
            KidsLevelMap(
              gameType: gameType.isEmpty
                  ? (extra?['gameType'] as String? ?? 'alphabet')
                  : gameType,
              title: extra?['title'] as String? ?? getKidsGameTitle(gameType),
              primaryColor:
                  extra?['primaryColor'] as Color? ??
                  getKidsGameColor(gameType),
            ),
          ),
          state: state,
        );
      },
    ),
    GoRoute(
      path: kidsAlphabetRoute,
      pageBuilder: (context, state) => fadeTransitionPage(
        child: _getKidsBlocWrapper(
          UnifiedKidsGameScreen(
            gameType: 'alphabet',
            level: state.extra as int? ?? 1,
          ),
        ),
        state: state,
      ),
    ),
    GoRoute(
      path: kidsNumbersRoute,
      pageBuilder: (context, state) => fadeTransitionPage(
        child: _getKidsBlocWrapper(
          UnifiedKidsGameScreen(
            gameType: 'numbers',
            level: state.extra as int? ?? 1,
          ),
        ),
        state: state,
      ),
    ),
    GoRoute(
      path: kidsColorsRoute,
      pageBuilder: (context, state) => fadeTransitionPage(
        child: _getKidsBlocWrapper(
          UnifiedKidsGameScreen(
            gameType: 'colors',
            level: state.extra as int? ?? 1,
          ),
        ),
        state: state,
      ),
    ),
    GoRoute(
      path: kidsShapesRoute,
      pageBuilder: (context, state) => fadeTransitionPage(
        child: _getKidsBlocWrapper(
          UnifiedKidsGameScreen(
            gameType: 'shapes',
            level: state.extra as int? ?? 1,
          ),
        ),
        state: state,
      ),
    ),
    GoRoute(
      path: kidsAnimalsRoute,
      pageBuilder: (context, state) => fadeTransitionPage(
        child: _getKidsBlocWrapper(
          UnifiedKidsGameScreen(
            gameType: 'animals',
            level: state.extra as int? ?? 1,
          ),
        ),
        state: state,
      ),
    ),
    GoRoute(
      path: kidsFruitsRoute,
      pageBuilder: (context, state) => fadeTransitionPage(
        child: _getKidsBlocWrapper(
          UnifiedKidsGameScreen(
            gameType: 'fruits',
            level: state.extra as int? ?? 1,
          ),
        ),
        state: state,
      ),
    ),
    GoRoute(
      path: kidsFamilyRoute,
      pageBuilder: (context, state) => fadeTransitionPage(
        child: _getKidsBlocWrapper(
          UnifiedKidsGameScreen(
            gameType: 'family',
            level: state.extra as int? ?? 1,
          ),
        ),
        state: state,
      ),
    ),
    GoRoute(
      path: kidsSchoolRoute,
      pageBuilder: (context, state) => fadeTransitionPage(
        child: _getKidsBlocWrapper(
          UnifiedKidsGameScreen(
            gameType: 'school',
            level: state.extra as int? ?? 1,
          ),
        ),
        state: state,
      ),
    ),
    GoRoute(
      path: kidsVerbsRoute,
      pageBuilder: (context, state) => fadeTransitionPage(
        child: _getKidsBlocWrapper(
          UnifiedKidsGameScreen(
            gameType: 'verbs',
            level: state.extra as int? ?? 1,
          ),
        ),
        state: state,
      ),
    ),
    GoRoute(
      path: kidsRoutineRoute,
      pageBuilder: (context, state) => fadeTransitionPage(
        child: _getKidsBlocWrapper(
          UnifiedKidsGameScreen(
            gameType: 'routine',
            level: state.extra as int? ?? 1,
          ),
        ),
        state: state,
      ),
    ),
    GoRoute(
      path: kidsEmotionsRoute,
      pageBuilder: (context, state) => fadeTransitionPage(
        child: _getKidsBlocWrapper(
          UnifiedKidsGameScreen(
            gameType: 'emotions',
            level: state.extra as int? ?? 1,
          ),
        ),
        state: state,
      ),
    ),
    GoRoute(
      path: kidsPrepositionsRoute,
      pageBuilder: (context, state) => fadeTransitionPage(
        child: _getKidsBlocWrapper(
          UnifiedKidsGameScreen(
            gameType: 'prepositions',
            level: state.extra as int? ?? 1,
          ),
        ),
        state: state,
      ),
    ),
    GoRoute(
      path: kidsPhonicsRoute,
      pageBuilder: (context, state) => fadeTransitionPage(
        child: _getKidsBlocWrapper(
          UnifiedKidsGameScreen(
            gameType: 'phonics',
            level: state.extra as int? ?? 1,
          ),
        ),
        state: state,
      ),
    ),
    GoRoute(
      path: kidsTimeRoute,
      pageBuilder: (context, state) => fadeTransitionPage(
        child: _getKidsBlocWrapper(
          UnifiedKidsGameScreen(
            gameType: 'time',
            level: state.extra as int? ?? 1,
          ),
        ),
        state: state,
      ),
    ),
    GoRoute(
      path: kidsOppositesRoute,
      pageBuilder: (context, state) => fadeTransitionPage(
        child: _getKidsBlocWrapper(
          UnifiedKidsGameScreen(
            gameType: 'opposites',
            level: state.extra as int? ?? 1,
          ),
        ),
        state: state,
      ),
    ),
    GoRoute(
      path: kidsDayNightRoute,
      pageBuilder: (context, state) => fadeTransitionPage(
        child: _getKidsBlocWrapper(
          UnifiedKidsGameScreen(
            gameType: 'day_night',
            level: state.extra as int? ?? 1,
          ),
        ),
        state: state,
      ),
    ),
    GoRoute(
      path: kidsNatureRoute,
      pageBuilder: (context, state) => fadeTransitionPage(
        child: _getKidsBlocWrapper(
          UnifiedKidsGameScreen(
            gameType: 'nature',
            level: state.extra as int? ?? 1,
          ),
        ),
        state: state,
      ),
    ),
    GoRoute(
      path: kidsHomeRoute,
      pageBuilder: (context, state) => fadeTransitionPage(
        child: _getKidsBlocWrapper(
          UnifiedKidsGameScreen(
            gameType: 'home',
            level: state.extra as int? ?? 1,
          ),
        ),
        state: state,
      ),
    ),
    GoRoute(
      path: kidsFoodRoute,
      pageBuilder: (context, state) => fadeTransitionPage(
        child: _getKidsBlocWrapper(
          UnifiedKidsGameScreen(
            gameType: 'food',
            level: state.extra as int? ?? 1,
          ),
        ),
        state: state,
      ),
    ),
    GoRoute(
      path: kidsTransportRoute,
      pageBuilder: (context, state) => fadeTransitionPage(
        child: _getKidsBlocWrapper(
          UnifiedKidsGameScreen(
            gameType: 'transport',
            level: state.extra as int? ?? 1,
          ),
        ),
        state: state,
      ),
    ),
    GoRoute(
      path: kidsBodyPartsRoute,
      pageBuilder: (context, state) => fadeTransitionPage(
        child: _getKidsBlocWrapper(
          UnifiedKidsGameScreen(
            gameType: 'body_parts',
            level: state.extra as int? ?? 1,
          ),
        ),
        state: state,
      ),
    ),
    GoRoute(
      path: kidsClothingRoute,
      pageBuilder: (context, state) => fadeTransitionPage(
        child: _getKidsBlocWrapper(
          UnifiedKidsGameScreen(
            gameType: 'clothing',
            level: state.extra as int? ?? 1,
          ),
        ),
        state: state,
      ),
    ),
    GoRoute(
      path: kidsRoomRoute,
      pageBuilder: (context, state) =>
          fadeTransitionPage(child: const KidsRoomScreen(), state: state),
    ),
    GoRoute(
      path: kidsHandwritingRoute,
      pageBuilder: (context, state) => fadeTransitionPage(
        child: _getKidsBlocWrapper(
          UnifiedKidsGameScreen(
            gameType: 'handwriting',
            level: state.extra as int? ?? 1,
          ),
        ),
        state: state,
      ),
    ),
    GoRoute(
      path: kidsWeatherRoute,
      pageBuilder: (context, state) => fadeTransitionPage(
        child: _getKidsBlocWrapper(
          UnifiedKidsGameScreen(
            gameType: 'weather',
            level: state.extra as int? ?? 1,
          ),
        ),
        state: state,
      ),
    ),
    GoRoute(
      path: kidsProfessionsRoute,
      pageBuilder: (context, state) => fadeTransitionPage(
        child: _getKidsBlocWrapper(
          UnifiedKidsGameScreen(
            gameType: 'professions',
            level: state.extra as int? ?? 1,
          ),
        ),
        state: state,
      ),
    ),
  ];
}
