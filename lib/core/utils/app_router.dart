import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/locale_service.dart';
import 'package:vowl/core/utils/age_gate_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

// Modular Feature Routes
import 'package:vowl/features/auth/auth_routes.dart';
import 'package:vowl/features/kids_zone/kids_routes.dart';
import 'package:vowl/features/games/game_routes.dart';
import 'package:vowl/features/home/home_routes.dart';
import 'package:vowl/features/daily_words/daily_words_routes.dart';
import 'package:vowl/features/translation/translation_routes.dart';

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
  static const String progressDashboardRoute = '/progress-dashboard';
  static const String adminRoute = '/admin';
  static const String settingsRoute = '/settings';
  static const String leaderboardRoute = '/leaderboard';
  static const String kidsLeaderboardRoute = '/kids-leaderboard';
  static const String forgotPasswordRoute = '/forgot-password';
  static const String trophyRoomRoute = '/trophy-room';
  static const String verifyEmailRoute = '/verify-email';
  static const String ageGateRoute = '/age-gate';
  static const String levelsRoute = '/levels';
  static const String categoryGamesRoute = '/category-games';
  static const String libraryRoute = '/library';
  static const String streakRoute = '/streak';
  static const String levelRoute = '/level-details';
  static const String adventureXPRoute = '/xp-details';
  static const String questCoinsRoute = '/coins-details';
  static const String questSequenceRoute = '/quest-sequence';
  static const String scanAndLearnRoute = '/scan-and-learn';
  static const String photoVocabularyRoute = '/photo-vocabulary';
  // Daily Words
  static const String dailyWordsRoute = DailyWordsRoutes.dailyWordsRoute;
  static const String wordBankRoute = DailyWordsRoutes.wordBankRoute;

  // Translation
  static const String translateRoute = '/translate';

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
  static const String kidsHandwritingRoute = '/kids-handwriting';
  static const String kidsWeatherRoute = '/kids-weather';
  static const String kidsProfessionsRoute = '/kids-professions';
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
      ...DailyWordsRoutes.routes,
      ...translationRoutes,
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

    // 5. Age Gate check — MUST complete before entering the main app.
    if (!AgeGateService.isCompletedCached) {
      if (path != ageGateRoute) return ageGateRoute;
      return null; // Let them stay on the age gate
    }

    // 5.5. COPPA Loophole Preventer: Restrict under-16 users to Kids Zone
    if (!AgeGateService.isAdultCached) {
      final isKidsRoute = path.startsWith('/kids') || path == kidsZoneRoute;
      // Let them complete onboarding (hatching) or auth if needed.
      // We also allow settingsRoute so they can reset their age if they made a mistake.
      if (!isKidsRoute &&
          !isAuthRoute &&
          path != verifyEmailRoute &&
          path != splashRoute &&
          path != ageGateRoute &&
          path != settingsRoute &&
          path != hatchingRoute) {
        return kidsZoneRoute; // Force into Kids Zone
      }
    }

    // 6. Authenticated, verified, and age-gated — redirect away from auth/verify/root/ageGate.
    if (isAuthRoute ||
        path == verifyEmailRoute ||
        path == ageGateRoute ||
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
              5;

      if (isNewUser) {
        final name = currentUser.displayName ?? 'Traveler';
        return '$hatchingRoute?name=${Uri.encodeComponent(name)}';
      }
      // Route directly to the appropriate home based on age gate status
      return AgeGateService.isAdultCached ? homeRoute : kidsZoneRoute;
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
            );
          },
        ),
      ),
    );
  }
}
