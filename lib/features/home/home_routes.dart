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
import 'package:vowl/features/settings/presentation/pages/about_screen.dart';
import 'package:vowl/features/home/presentation/pages/vowl_mascot_screen.dart';
import 'package:vowl/features/premium/presentation/pages/premium_screen.dart';
import 'package:vowl/features/home/presentation/pages/streak_screen.dart';
import 'package:vowl/features/home/presentation/pages/quest_library_page.dart';
import 'package:vowl/features/profile/presentation/pages/trophy_room_screen.dart';
import 'package:vowl/features/profile/presentation/pages/progress_dashboard_screen.dart';
import 'package:vowl/features/profile/presentation/pages/review_mistakes_screen.dart';

import 'package:vowl/features/scan_and_learn/presentation/pages/scan_and_learn_screen.dart';
import 'package:vowl/features/photo_vocabulary/presentation/pages/photo_vocabulary_screen.dart';

import 'package:vowl/core/utils/app_router.dart';

/// Central route registry configuring root tabs, navigation shells, and deep links for Home.
class HomeRoutes {
  HomeRoutes._(); // Prevent instantiation of utility class

  /// Splash screen route path.
  static const String splashRoute = '/splash';

  /// Home dashboard route path.
  static const String homeRoute = '/home';

  /// Games hub route path.
  static const String gamesRoute = '/games';

  /// Premium subscription paywall route path.
  static const String premiumRoute = '/premium';

  /// User profile screen route path.
  static const String profileRoute = '/profile';

  /// Settings and configuration route path.
  static const String settingsRoute = '/settings';

  /// App info and legal screen route path.
  static const String aboutRoute = '/about';

  /// Competitive leaderboard route path.
  static const String leaderboardRoute = '/leaderboard';

  /// Curriculum quest library route path.
  static const String libraryRoute = '/library';

  /// Streak calendar and stats route path.
  static const String streakRoute = '/streak';

  /// Post-onboarding pet hatching route path.
  static const String hatchingRoute = '/hatching';

  /// Companion mascot showcase and customization route path.
  static const String vowlMascotRoute = '/vowl-mascot';

  /// Achievements and trophies route path.
  static const String trophyRoomRoute = '/trophy-room';

  /// Vision-based ML scan-and-learn route path.
  static const String scanAndLearnRoute = '/scan-and-learn';

  /// Visual photo vocabulary route path.
  static const String photoVocabularyRoute = '/photo-vocabulary';

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

  /// Global list of route definitions for the main application shell and pages.
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
      path: aboutRoute,
      pageBuilder: (context, state) =>
          fadeTransitionPage(child: const AboutScreen(), state: state),
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
    GoRoute(
      path: AppRouter.progressDashboardRoute,
      pageBuilder: (context, state) => fadeTransitionPage(
        child: const ProgressDashboardScreen(),
        state: state,
      ),
    ),
    GoRoute(
      path: AppRouter.reviewMistakesRoute,
      pageBuilder: (context, state) =>
          fadeTransitionPage(child: const ReviewMistakesScreen(), state: state),
    ),
    GoRoute(
      path: scanAndLearnRoute,
      pageBuilder: (context, state) =>
          fadeTransitionPage(child: const ScanAndLearnScreen(), state: state),
    ),
    GoRoute(
      path: photoVocabularyRoute,
      pageBuilder: (context, state) => fadeTransitionPage(
        child: const PhotoVocabularyScreen(),
        state: state,
      ),
    ),
    GoRoute(
      path: AppRouter.kidsLeaderboardRoute,
      pageBuilder: (context, state) => fadeTransitionPage(
        child: const LeaderboardScreen(isKids: true),
        state: state,
      ),
    ),
  ];
}
