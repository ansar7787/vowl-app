import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/navigation_helpers.dart';
import 'package:vowl/features/kids_zone/presentation/bloc/kids_bloc.dart';
import 'package:vowl/features/kids_zone/presentation/pages/sticker_book_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/mascot_selection_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/kids_zone_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/kids_level_map.dart';
import 'package:vowl/features/kids_zone/presentation/pages/games/alphabet_game_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/games/numbers_game_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/games/colors_game_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/games/shapes_game_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/games/animals_game_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/games/fruits_game_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/games/family_game_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/games/school_game_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/games/verbs_game_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/games/routine_game_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/games/emotions_game_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/games/prepositions_game_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/games/phonics_game_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/games/time_game_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/games/opposites_game_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/games/day_night_game_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/games/nature_game_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/games/home_game_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/games/food_game_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/games/transport_game_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/games/body_parts_game_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/games/clothing_game_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/buddy_boutique_screen.dart';
import 'package:vowl/features/kids_zone/presentation/pages/kids_room_screen.dart';

class KidsRoutes {
  static const String kidsZoneRoute = '/kids-zone';
  static const String kidsLevelMapRoute = '/kids/map/:gameType';
  static const String kidsAlphabetRoute = '/kids-alphabet';
  static const String kidsNumbersRoute = '/kids-numbers';
  static const String kidsColorsRoute = '/kids-colors';
  static const String kidsShapesRoute = '/kids-shapes';
  static const String kidsAnimalsRoute = '/kids-animals';
  static const String kidsFruitsRoute = '/kids-fruits';
  static const String kidsFamilyRoute = '/kids-family';
  static const String kidsSchoolRoute = '/kids-school';
  static const String kidsVerbsRoute = '/kids-verbs';
  static const String kidsStickerBookRoute = '/kids-stickers';
  static const String kidsMascotSelectionRoute = '/kids-mascot';
  static const String kidsRoutineRoute = '/kids-routine';
  static const String kidsEmotionsRoute = '/kids-emotions';
  static const String kidsPrepositionsRoute = '/kids-prepositions';
  static const String kidsPhonicsRoute = '/kids-phonics';
  static const String kidsTimeRoute = '/kids-time';
  static const String kidsOppositesRoute = '/kids-opposites';
  static const String kidsDayNightRoute = '/kids-day-night';
  static const String kidsNatureRoute = '/kids-nature';
  static const String kidsHomeRoute = '/kids-home';
  static const String kidsFoodRoute = '/kids-food';
  static const String kidsTransportRoute = '/kids-transport';
  static const String kidsBodyPartsRoute = '/kids-body-parts';
  static const String kidsClothingRoute = '/kids-clothing';
  static const String kidsBuddyBoutiqueRoute = '/kids-zone/boutique';
  static const String kidsRoomRoute = '/kids-room';

  static String getKidsGameTitle(String gameType) {
    switch (gameType) {
      case 'alphabet': return 'Alphabet';
      case 'numbers': return 'Numbers';
      case 'colors': return 'Colors';
      case 'shapes': return 'Shapes';
      case 'animals': return 'Animals';
      case 'fruits': return 'Fruits';
      case 'family': return 'Family';
      case 'school': return 'School';
      case 'verbs': return 'Verbs';
      case 'routine': return 'Routine';
      case 'emotions': return 'Emotions';
      case 'prepositions': return 'Prepositions';
      case 'phonics': return 'Phonics';
      case 'jumble': return 'Jumble';
      case 'time': return 'Time';
      case 'opposites': return 'Opposites';
      case 'day_night': return 'Day/Night';
      case 'nature': return 'Nature';
      case 'home': return 'Home';
      case 'food': return 'Food';
      case 'transport': return 'Transport';
      case 'body_parts': return 'Body Parts';
      case 'clothing': return 'Clothing';
      default: return 'Kids Game';
    }
  }

  static Color getKidsGameColor(String gameType) {
    switch (gameType) {
      case 'alphabet': return const Color(0xFFF43F5E);
      case 'numbers': return const Color(0xFF0EA5E9);
      case 'colors': return const Color(0xFFF59E0B);
      case 'shapes': return const Color(0xFF10B981);
      case 'animals': return const Color(0xFF6366F1);
      case 'fruits': return const Color(0xFFEF4444);
      case 'family': return const Color(0xFFEC4899);
      case 'school': return const Color(0xFFF59E0B);
      case 'verbs': return const Color(0xFF8B5CF6);
      case 'routine': return const Color(0xFFF97316);
      case 'emotions': return const Color(0xFF06B6D4);
      case 'prepositions': return const Color(0xFF64748B);
      case 'phonics': return const Color(0xFFFFCC00);
      case 'jumble': return const Color(0xFFF43F5E);
      case 'time': return const Color(0xFF333333);
      case 'opposites': return const Color(0xFF94A3B8);
      case 'day_night': return const Color(0xFF1E293B);
      case 'nature': return const Color(0xFF16A34A);
      case 'home': return const Color(0xFFD946EF);
      case 'food': return const Color(0xFFFB923C);
      case 'transport': return const Color(0xFF2563EB);
      case 'body_parts': return const Color(0xFFF43F5E);
      case 'clothing': return const Color(0xFF8B5CF6);
      default: return Colors.blue;
    }
  }

  static Widget _getKidsBlocWrapper(Widget child) {
    return BlocProvider<KidsBloc>(
      create: (context) => di.sl<KidsBloc>(),
      child: child,
    );
  }

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
            final primaryColor = extra?['primaryColor'] as Color? ?? Colors.blue;

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
              primaryColor: extra?['primaryColor'] as Color? ?? getKidsGameColor(gameType),
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
          AlphabetGameScreen(level: state.extra as int? ?? 1),
        ),
        state: state,
      ),
    ),
    GoRoute(
      path: kidsNumbersRoute,
      pageBuilder: (context, state) => fadeTransitionPage(
        child: _getKidsBlocWrapper(
          NumbersGameScreen(level: state.extra as int? ?? 1),
        ),
        state: state,
      ),
    ),
    GoRoute(
      path: kidsColorsRoute,
      pageBuilder: (context, state) => fadeTransitionPage(
        child: _getKidsBlocWrapper(
          ColorsGameScreen(level: state.extra as int? ?? 1),
        ),
        state: state,
      ),
    ),
    GoRoute(
      path: kidsShapesRoute,
      pageBuilder: (context, state) => fadeTransitionPage(
        child: _getKidsBlocWrapper(
          ShapesGameScreen(level: state.extra as int? ?? 1),
        ),
        state: state,
      ),
    ),
    GoRoute(
      path: kidsAnimalsRoute,
      pageBuilder: (context, state) => fadeTransitionPage(
        child: _getKidsBlocWrapper(
          AnimalsGameScreen(level: state.extra as int? ?? 1),
        ),
        state: state,
      ),
    ),
    GoRoute(
      path: kidsFruitsRoute,
      pageBuilder: (context, state) => fadeTransitionPage(
        child: _getKidsBlocWrapper(
          FruitsGameScreen(level: state.extra as int? ?? 1),
        ),
        state: state,
      ),
    ),
    GoRoute(
      path: kidsFamilyRoute,
      pageBuilder: (context, state) => fadeTransitionPage(
        child: _getKidsBlocWrapper(
          FamilyGameScreen(level: state.extra as int? ?? 1),
        ),
        state: state,
      ),
    ),
    GoRoute(
      path: kidsSchoolRoute,
      pageBuilder: (context, state) => fadeTransitionPage(
        child: _getKidsBlocWrapper(
          SchoolGameScreen(level: state.extra as int? ?? 1),
        ),
        state: state,
      ),
    ),
    GoRoute(
      path: kidsVerbsRoute,
      pageBuilder: (context, state) => fadeTransitionPage(
        child: _getKidsBlocWrapper(
          VerbsGameScreen(level: state.extra as int? ?? 1),
        ),
        state: state,
      ),
    ),
    GoRoute(
      path: kidsRoutineRoute,
      pageBuilder: (context, state) => fadeTransitionPage(
        child: _getKidsBlocWrapper(
          RoutineGameScreen(level: state.extra as int? ?? 1),
        ),
        state: state,
      ),
    ),
    GoRoute(
      path: kidsEmotionsRoute,
      pageBuilder: (context, state) => fadeTransitionPage(
        child: _getKidsBlocWrapper(
          EmotionsGameScreen(level: state.extra as int? ?? 1),
        ),
        state: state,
      ),
    ),
    GoRoute(
      path: kidsPrepositionsRoute,
      pageBuilder: (context, state) => fadeTransitionPage(
        child: _getKidsBlocWrapper(
          PrepositionsGameScreen(level: state.extra as int? ?? 1),
        ),
        state: state,
      ),
    ),
    GoRoute(
      path: kidsPhonicsRoute,
      pageBuilder: (context, state) => fadeTransitionPage(
        child: _getKidsBlocWrapper(
          PhonicsGameScreen(level: state.extra as int? ?? 1),
        ),
        state: state,
      ),
    ),
    GoRoute(
      path: kidsTimeRoute,
      pageBuilder: (context, state) => fadeTransitionPage(
        child: _getKidsBlocWrapper(
          TimeGameScreen(level: state.extra as int? ?? 1),
        ),
        state: state,
      ),
    ),
    GoRoute(
      path: kidsOppositesRoute,
      pageBuilder: (context, state) => fadeTransitionPage(
        child: _getKidsBlocWrapper(
          OppositesGameScreen(level: state.extra as int? ?? 1),
        ),
        state: state,
      ),
    ),
    GoRoute(
      path: kidsDayNightRoute,
      pageBuilder: (context, state) => fadeTransitionPage(
        child: _getKidsBlocWrapper(
          DayNightGameScreen(level: state.extra as int? ?? 1),
        ),
        state: state,
      ),
    ),
    GoRoute(
      path: kidsNatureRoute,
      pageBuilder: (context, state) => fadeTransitionPage(
        child: _getKidsBlocWrapper(
          NatureGameScreen(level: state.extra as int? ?? 1),
        ),
        state: state,
      ),
    ),
    GoRoute(
      path: kidsHomeRoute,
      pageBuilder: (context, state) => fadeTransitionPage(
        child: _getKidsBlocWrapper(
          HomeGameScreen(level: state.extra as int? ?? 1),
        ),
        state: state,
      ),
    ),
    GoRoute(
      path: kidsFoodRoute,
      pageBuilder: (context, state) => fadeTransitionPage(
        child: _getKidsBlocWrapper(
          FoodGameScreen(level: state.extra as int? ?? 1),
        ),
        state: state,
      ),
    ),
    GoRoute(
      path: kidsTransportRoute,
      pageBuilder: (context, state) => fadeTransitionPage(
        child: _getKidsBlocWrapper(
          TransportGameScreen(level: state.extra as int? ?? 1),
        ),
        state: state,
      ),
    ),
    GoRoute(
      path: kidsBodyPartsRoute,
      pageBuilder: (context, state) => fadeTransitionPage(
        child: _getKidsBlocWrapper(
          BodyPartsGameScreen(level: state.extra as int? ?? 1),
        ),
        state: state,
      ),
    ),
    GoRoute(
      path: kidsClothingRoute,
      pageBuilder: (context, state) => fadeTransitionPage(
        child: _getKidsBlocWrapper(
          ClothingGameScreen(level: state.extra as int? ?? 1),
        ),
        state: state,
      ),
    ),
    GoRoute(
      path: kidsRoomRoute,
      pageBuilder: (context, state) =>
          fadeTransitionPage(child: const KidsRoomScreen(), state: state),
    ),
  ];
}
