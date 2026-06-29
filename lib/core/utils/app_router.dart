import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

// Modular Feature Routes
import 'package:vowl/features/auth/auth_routes.dart';
import 'package:vowl/features/kids_zone/kids_routes.dart';
import 'package:vowl/features/games/game_routes.dart';
import 'package:vowl/features/home/home_routes.dart';

class AppRouter {
  AppRouter._(); // Non-instantiable.

  // ── Route path constants ──────────────────────────────────────────────────

  static String? pendingDeepLink;

  static const String initialRoute = '/splash';
  static const String splashRoute = '/splash';
  static const String homeRoute = '/home';
  static const String gamesRoute = '/games';
  static const String loginRoute = '/login';
  static const String signupRoute = '/signup';
  static const String premiumRoute = '/premium';
  static const String profileRoute = '/profile';
  static const String adminRoute = '/admin';
  static const String settingsRoute = '/settings';
  static const String leaderboardRoute = '/leaderboard';
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

  // ── Kids Zone routes ──────────────────────────────────────────────────────

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
  static const String kidsAdminRoute = '/kids-admin';
  static const String kidsRoomRoute = '/kids-room';
  static const String hatchingRoute = '/hatching';
  static const String vowlMascotRoute = '/vowl-mascot';

  // ── Backwards compatibility ───────────────────────────────────────────────

  static String getKidsGameTitle(String gameType) =>
      KidsRoutes.getKidsGameTitle(gameType);

  static Color getKidsGameColor(String gameType) =>
      KidsRoutes.getKidsGameColor(gameType);

  // ── Router instance ───────────────────────────────────────────────────────

  static final GoRouter router = GoRouter(
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
      ...KidsRoutes.routes,
      ...GameRoutes.routes,
      ...HomeRoutes.routes,
    ],
    // FIX (HIGH-6): Replace bare Text with an actionable error page that
    // gives the user a path back to safety instead of a dead-end screen.
    errorBuilder: (context, state) => _RouterErrorPage(path: state.uri.path),
  );

  // ── Redirect logic ────────────────────────────────────────────────────────

  static String? _redirect(BuildContext context, GoRouterState state) {
    final authState = di.sl<AuthBloc>().state;
    final isAuthenticated = authState.status == AuthStatus.authenticated;
    final isVerified = authState.user?.isEmailVerified ?? false;

    final path = state.uri.path;
    final isLoginRoute = path == loginRoute;
    final isSignupRoute = path == signupRoute;
    final isForgotPasswordRoute = path == forgotPasswordRoute;
    final isSplashRoute = path == splashRoute;
    final isAuthRoute = isLoginRoute || isSignupRoute || isForgotPasswordRoute;
    final isAllowedUnauth = isAuthRoute || isSplashRoute;

    // Splash: always allowed while auth resolves.
    if (isSplashRoute) return null;

    // 1. Auth state still unknown — send back to splash.
    if (authState.status == AuthStatus.unknown) return splashRoute;

    // 2. Logout in progress — do not redirect mid-transition.
    if (authState.status == AuthStatus.loggingOut) return null;

    // 3. Unauthenticated — must be on an allowed route.
    if (!isAuthenticated) {
      return !isAllowedUnauth ? loginRoute : null;
    }

    // 4. Authenticated but email not verified.
    if (!isVerified) {
      if (path != verifyEmailRoute) return verifyEmailRoute;
      return null;
    }

    // Process pending deep link if app cold-started from notification
    if (AppRouter.pendingDeepLink != null) {
      final link = AppRouter.pendingDeepLink!;
      AppRouter.pendingDeepLink = null;
      return link;
    }

    // 5. Authenticated + verified — redirect away from auth/verify/root.
    if (isAuthRoute || path == verifyEmailRoute || path == '/') {
      final currentUser = FirebaseAuth.instance.currentUser;
      final isNewUser = currentUser != null &&
          currentUser.metadata.creationTime != null &&
          currentUser.metadata.lastSignInTime != null &&
          currentUser.metadata.creationTime!
                  .difference(currentUser.metadata.lastSignInTime!)
                  .inSeconds
                  .abs() <
              5;

      if (isNewUser) {
        final name = currentUser.displayName ?? 'Traveler';
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
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
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
                localeService.tr('router.error.no_route_defined'),
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
                  localeService.tr('router.error.go_home'),
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
      ),
    );
  }
}
