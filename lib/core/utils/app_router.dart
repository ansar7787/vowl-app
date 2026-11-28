import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/onboarding_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

// Modular Feature Routes
import 'package:vowl/features/auth/auth_routes.dart';
import 'package:vowl/features/games/game_routes.dart';
import 'package:vowl/features/home/home_routes.dart';
import 'package:vowl/features/daily_words/daily_words_routes.dart';
import 'package:vowl/features/translation/translation_routes.dart';

/// Central declarative application router configuring all modular feature routes,
/// navigation redirects (auth gates, age gates), deep-linking, and analytics observers.
class AppRouter {
  AppRouter._(); // Non-instantiable.

  /// Global navigator key for the root Navigator, allowing full-screen modal overlays
  /// and dialogs to be pushed above the bottom navigation shell.
  static final GlobalKey<NavigatorState> rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'rootNavigator');

  // ── Route path constants ──────────────────────────────────────────────────

  /// Pending deep-link destination URL to route to once initialization finishes.
  static String? pendingDeepLink;

  static const String initialRoute = '/splash';
  static const String splashRoute = '/splash';
  static const String onboardingRoute = AuthRoutes.onboardingRoute;
  static const String homeRoute = '/home';
  static const String gamesRoute = '/games';
  static const String loginRoute = '/login';
  static const String signupRoute = '/signup';
  static const String premiumRoute = '/premium';
  static const String profileRoute = '/profile';
  static const String progressDashboardRoute = '/progress-dashboard';
  static const String settingsRoute = '/settings';
  static const String leaderboardRoute = '/leaderboard';
  static const String ranksRoute = '/ranks';
  static const String forgotPasswordRoute = '/forgot-password';
  static const String trophyRoomRoute = '/trophy-room';
  static const String verifyEmailRoute = '/verify-email';
  static const String levelsRoute = '/levels';
  static const String categoryGamesRoute = '/category-games';
  static const String libraryRoute = '/library';
  static const String streakRoute = '/streak';
  static const String levelRoute = '/level-details';
  static const String adventureXPRoute = '/xp-details';
  static const String questCoinsRoute = '/coins-details';
  static const String questSequenceRoute = '/quest-sequence';
  static const String referralRoute = '/referral';
  static const String arenaRoute = '/arena';
  static const String arenaHistoryRoute = '/arena-history';
  static const String duelRoute = '/duel/:roomCode';
  static const String inviteRoute = '/invite/:code';

  // Daily Words
  static const String dailyWordsRoute = DailyWordsRoutes.dailyWordsRoute;
  static const String wordBankRoute = DailyWordsRoutes.wordBankRoute;

  // Translation
  static const String translateRoute = '/translate';

  static const String hatchingRoute = '/hatching';
  static const String vowlMascotRoute = '/vowl-mascot';

  // ── Router instance ───────────────────────────────────────────────────────

  /// The global [GoRouter] instance configured with observers, redirects, and routes.
  static final GoRouter router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: initialRoute,
    observers: [
      // Guard: FirebaseAnalyticsObserver is only attached when Firebase is
      // initialised, preventing crashes in unit tests that don't boot Firebase.
      if (Firebase.apps.isNotEmpty)
        FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
    ],
    // Refreshes the router whenever the AuthBloc stream emits a new state,
    // triggering the redirect logic below.
    refreshListenable: _StreamListenable(di.sl<AuthBloc>().stream),
    redirect: _redirect,
    routes: [
      ...AuthRoutes.routes,
      ...GameRoutes.routes,
      ...HomeRoutes.routes,
      ...DailyWordsRoutes.routes,
      ...translationRoutes,
    ],
    // FIX (HIGH-6): Replace bare Text with an actionable error page that
    // gives the user a path back to safety instead of a dead-end screen.
    errorBuilder: (context, state) => _RouterErrorPage(path: state.uri.path),
  );

  // ── Deep-link normalization ───────────────────────────────────────────────

  /// Normalizes incoming deep links across custom schemes (e.g. `vowl://invite/CODE`,
  /// `vowl://vowl.in/invite/CODE`, `vowl:///invite/CODE`) and HTTPS App Links
  /// (`https://vowl.in/invite/CODE`) into canonical internal route paths.
  static String? normalizeDeepLink(Uri uri) {
    if (uri.scheme == 'vowl') {
      final host = uri.host.toLowerCase();
      // Handle custom scheme format where path segments are parsed as host:
      // e.g. vowl://invite/CODE or vowl://invite?code=CODE
      if (host == 'invite') {
        final queryCode = uri.queryParameters['code']?.trim();
        final pathCode = uri.path.replaceAll('/', '').trim();
        final code = (queryCode != null && queryCode.isNotEmpty)
            ? queryCode
            : pathCode;
        return code.isNotEmpty ? '/invite/$code' : referralRoute;
      }
      // e.g. vowl://duel/ROOM123 or vowl://duel?code=ROOM123
      if (host == 'duel' || host == 'arena') {
        final queryCode = uri.queryParameters['roomCode']?.trim() ??
            uri.queryParameters['code']?.trim();
        final pathCode = uri.path.replaceAll('/', '').trim();
        final room = (queryCode != null && queryCode.isNotEmpty)
            ? queryCode
            : pathCode;
        return room.isNotEmpty ? '/duel/$room' : arenaRoute;
      }
      // e.g. vowl://verify-email
      if (host == 'verify-email') {
        return verifyEmailRoute;
      }
      // e.g. vowl://login
      if (host == 'login') {
        return loginRoute;
      }
      // e.g. vowl://referral
      if (host == 'referral') {
        return referralRoute;
      }
      // Standard authority format: vowl://vowl.in/invite?code=CODE
      if (uri.path == '/invite' && uri.queryParameters.containsKey('code')) {
        final code = uri.queryParameters['code']!.trim();
        if (code.isNotEmpty) return '/invite/$code';
      }
      // Standard authority format: vowl://vowl.in/duel?code=ROOM
      if (uri.path == '/duel' &&
          (uri.queryParameters.containsKey('code') ||
              uri.queryParameters.containsKey('roomCode'))) {
        final room = (uri.queryParameters['roomCode'] ??
                uri.queryParameters['code'])!
            .trim();
        if (room.isNotEmpty) return '/duel/$room';
      }
      // Standard authority format: vowl://vowl.in/invite/CODE or vowl:///invite/CODE
      if (uri.path.isNotEmpty && uri.path != '/') {
        return uri.path;
      }
    } else if (uri.scheme == 'https' || uri.scheme == 'http') {
      // e.g. https://vowl.in/invite?code=CODE
      if (uri.path == '/invite' && uri.queryParameters.containsKey('code')) {
        final code = uri.queryParameters['code']!.trim();
        if (code.isNotEmpty) return '/invite/$code';
      }
      // e.g. https://vowl.in/duel?code=ROOM
      if (uri.path == '/duel' &&
          (uri.queryParameters.containsKey('code') ||
              uri.queryParameters.containsKey('roomCode'))) {
        final room = (uri.queryParameters['roomCode'] ??
                uri.queryParameters['code'])!
            .trim();
        if (room.isNotEmpty) return '/duel/$room';
      }
      if (uri.path.isNotEmpty && uri.path != '/') {
        return uri.path;
      }
    }
    return null;
  }

  // ── Redirect logic ────────────────────────────────────────────────────────

  static String? _redirect(BuildContext context, GoRouterState state) {
    // 0. Normalize incoming deep link if present
    final normalized = normalizeDeepLink(state.uri);
    final path = normalized ?? state.uri.path;

    final authState = di.sl<AuthBloc>().state;
    final isAuthenticated = authState.status == AuthStatus.authenticated;
    final isVerified = authState.user?.isEmailVerified ?? false;

    final isOnboardingRoute = path == onboardingRoute;
    final isLoginRoute = path == loginRoute;
    final isSignupRoute = path == signupRoute;
    final isForgotPasswordRoute = path == forgotPasswordRoute;
    final isSplashRoute = path == splashRoute;

    final isAuthRoute = isLoginRoute || isSignupRoute || isForgotPasswordRoute;
    final isAllowedUnauth = isAuthRoute || isSplashRoute || isOnboardingRoute;

    // Splash: always allowed while auth resolves.
    if (isSplashRoute) return null;

    // 1. Auth state still unknown — send back to splash.
    if (authState.status == AuthStatus.unknown) return splashRoute;

    // 2. Logout in progress — do not redirect mid-transition.
    if (authState.status == AuthStatus.loggingOut) return null;

    // 3. Unauthenticated — capture duel/invite deep links before forcing onboarding/login.
    if (!isAuthenticated) {
      if (path.startsWith('/duel/') || path.startsWith('/invite/')) {
        AppRouter.pendingDeepLink = path;
      }
      if (!OnboardingService.isCompletedCached) {
        return isOnboardingRoute ? null : onboardingRoute;
      }
      return !isAllowedUnauth ? loginRoute : null;
    }

    // 4. Authenticated but email not verified.
    if (!isVerified) {
      if (path != verifyEmailRoute) return verifyEmailRoute;
      return null;
    }

    // Process pending deep link if app cold-started from notification or unauth state
    if (AppRouter.pendingDeepLink != null) {
      final link = AppRouter.pendingDeepLink!;
      AppRouter.pendingDeepLink = null;
      return link;
    }

    // Redirect to canonical path if an external deep link arrived with non-canonical URI
    if (normalized != null && normalized != state.uri.path) {
      return normalized;
    }

    // 5. Authenticated and verified — redirect away from auth/verify/root.
    if (isAuthRoute ||
        path == verifyEmailRoute ||
        path == '/') {
      // FIX (TESTABILITY): resolve FirebaseAuth through the DI container,
      // like every other dependency this method reads (`di.sl<AuthBloc>()`
      // above), rather than the static `FirebaseAuth.instance` singleton
      // accessor. Same object at runtime (di_core.dart registers
      // `FirebaseAuth.instance` under this type), but this path is now
      // mockable in router/widget tests without needing a real Firebase app.
      final currentUser = di.sl<FirebaseAuth>().currentUser;
      final isNewUser =
          currentUser != null &&
          currentUser.metadata.creationTime != null &&
          currentUser.metadata.lastSignInTime != null &&
          currentUser.metadata.creationTime!
                  .difference(currentUser.metadata.lastSignInTime!)
                  .inSeconds
                  .abs() <
              60;

      if (isNewUser) {
        final authName = authState.user?.displayName;
        final name = (authName != null && authName.trim().isNotEmpty)
            ? authName
            : (currentUser.displayName ?? 'Traveler');
        return '$hatchingRoute?name=${Uri.encodeComponent(name)}';
      }
      return homeRoute;
    }

    return null;
  }
}

// ---------------------------------------------------------------------------
// Private: stream-based ChangeNotifier for GoRouter.refreshListenable
// ---------------------------------------------------------------------------

class _StreamListenable extends ChangeNotifier {
  final Stream stream;
  late final StreamSubscription _subscription;

  _StreamListenable(this.stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Private: Proper error page
// FIX (HIGH-6): Previously the errorBuilder returned Scaffold(body: Center(
// child: Text(...))) with no recovery action. Users who landed on an unknown
// route were completely stuck. This page provides the path, an explanation,
// and a "Go Home" button.
// ---------------------------------------------------------------------------

class _RouterErrorPage extends StatelessWidget {
  final String path;
  const _RouterErrorPage({required this.path});

  @override
  Widget build(BuildContext context) {
    final localeService = di.sl<LocaleService>();
    return Scaffold(
      body: SafeArea(
        // FIX (RESPONSIVENESS/ACCESSIBILITY/LOCALIZATION): a fixed Column
        // centered directly in the viewport overflows at large accessibility
        // text-scale factors (up to 3.0x) or with longer translations of the
        // error copy, on small phones (320x568) - same class of issue fixed
        // on the other standalone status pages in this app (NoInternetPage,
        // InsecureDeviceScreen). LayoutBuilder + SingleChildScrollView +
        // ConstrainedBox(minHeight) preserves the exact current centered
        // look whenever content fits, and only scrolls (instead of
        // overflowing) when it doesn't.
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 24.h),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 48.h,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.explore_off_rounded,
                      size: 64.r,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      localeService.tr(
                        'router.error.no_route_defined',
                        fallback: 'No route defined',
                      ),
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      path,
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 13.sp,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 40.h),
                    ElevatedButton.icon(
                      onPressed: () => context.go(AppRouter.homeRoute),
                      icon: const Icon(Icons.home_rounded),
                      label: Text(
                        localeService.tr(
                          'router.error.go_home',
                          fallback: 'Go Home',
                        ),
                        style: const TextStyle(
                          fontFamily: 'Outfit',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 52.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
