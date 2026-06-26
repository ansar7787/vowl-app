import 'package:go_router/go_router.dart';
import 'package:vowl/core/utils/navigation_helpers.dart';
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/splash/presentation/pages/splash_page.dart';
import 'package:vowl/features/onboarding/presentation/pages/hatching_page.dart';
import 'package:vowl/features/home/presentation/pages/main_wrapper.dart';
import 'package:vowl/features/home/presentation/pages/home_screen.dart';
import 'package:vowl/features/games/presentation/pages/games_screen.dart';
import 'package:vowl/features/leaderboard/presentation/pages/leaderboard_screen.dart';
import 'package:vowl/features/profile/presentation/pages/profile_screen.dart';
import 'package:vowl/features/settings/presentation/pages/settings_screen.dart';
import 'package:vowl/features/home/presentation/pages/vowl_mascot_screen.dart';
import 'package:vowl/features/premium/presentation/pages/premium_screen.dart';
import 'package:vowl/features/home/presentation/pages/streak_screen.dart';
import 'package:vowl/features/home/presentation/pages/quest_library_page.dart';
import 'package:vowl/features/profile/presentation/pages/trophy_room_screen.dart';

class HomeRoutes {
  HomeRoutes._(); // Prevent instantiation of utility class

  static const String splashRoute = '/splash';
  static const String homeRoute = '/home';
  static const String gamesRoute = '/games';
  static const String premiumRoute = '/premium';
  static const String profileRoute = '/profile';

  static const String settingsRoute = '/settings';
  static const String leaderboardRoute = '/leaderboard';
  static const String libraryRoute = '/library';
  static const String streakRoute = '/streak';
  static const String hatchingRoute = '/hatching';
  static const String vowlMascotRoute = '/vowl-mascot';
  static const String trophyRoomRoute = '/trophy-room';

  // Deep links (e.g. /hatching?name=...) carry untrusted, remotely/user
  // suppliable input. Capped length + trim prevents a pathological query
  // param from forcing oversized text layout on the hatching screen.
  static const int _maxDeepLinkNameLength = 30;

  static String _sanitizeDeepLinkName(String? raw, String fallback) {
    if (raw == null) return fallback;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return fallback;
    return trimmed.length > _maxDeepLinkNameLength
        ? trimmed.substring(0, _maxDeepLinkNameLength)
        : trimmed;
  }

  static final List<RouteBase> routes = [
    GoRoute(path: splashRoute, builder: (context, state) => const SplashPage()),
    GoRoute(
      path: hatchingRoute,
      builder: (context, state) {
        final fallback = context.tr(
          'routes.default_traveler_name',
          fallback: 'Traveler',
        );
        final name = _sanitizeDeepLinkName(
          state.uri.queryParameters['name'],
          fallback,
        );
        return HatchingPage(userName: name);
      },
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return MainWrapper(navigationShell: navigationShell);
      },
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: homeRoute,
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: gamesRoute,
              builder: (context, state) => const GamesScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: leaderboardRoute,
              builder: (context, state) => const LeaderboardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: profileRoute,
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: settingsRoute,
      pageBuilder: (context, state) =>
          fadeTransitionPage(child: const SettingsScreen(), state: state),
    ),
    GoRoute(
      path: vowlMascotRoute,
      pageBuilder: (context, state) =>
          fadeTransitionPage(child: const VowlMascotScreen(), state: state),
    ),
    GoRoute(
      path: libraryRoute,
      pageBuilder: (context, state) =>
          fadeTransitionPage(child: const QuestLibraryPage(), state: state),
    ),
    GoRoute(
      path: premiumRoute,
      pageBuilder: (context, state) =>
          fadeTransitionPage(child: const PremiumScreen(), state: state),
    ),
    GoRoute(
      path: streakRoute,
      pageBuilder: (context, state) =>
          fadeTransitionPage(child: const StreakScreen(), state: state),
    ),

    GoRoute(
      path: trophyRoomRoute,
      pageBuilder: (context, state) =>
          fadeTransitionPage(child: const TrophyRoomScreen(), state: state),
    ),
  ];
}
