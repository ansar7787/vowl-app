import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

// Modular Feature Routes
import 'package:vowl/features/auth/auth_routes.dart';
import 'package:vowl/features/kids_zone/kids_routes.dart';
import 'package:vowl/features/games/game_routes.dart';
import 'package:vowl/features/home/home_routes.dart';

class AppRouter {
  // Global Route String Constants for backwards compatibility
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

  // Backwards compatibility methods
  static String getKidsGameTitle(String gameType) => KidsRoutes.getKidsGameTitle(gameType);
  static Color getKidsGameColor(String gameType) => KidsRoutes.getKidsGameColor(gameType);

  static final GoRouter router = GoRouter(
    initialLocation: initialRoute,
    observers: [
      // Safe guard preventing unhandled FirebaseExceptions during unit tests or mock runs
      if (Firebase.apps.isNotEmpty)
        FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
    ],
    refreshListenable: _StreamListenable(di.sl<AuthBloc>().stream),
    redirect: (context, state) {
      final authState = di.sl<AuthBloc>().state;
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final isVerified = authState.user?.isEmailVerified ?? false;

      final isLoginRoute = state.uri.path == loginRoute;
      final isSignupRoute = state.uri.path == signupRoute;
      final isForgotPasswordRoute = state.uri.path == forgotPasswordRoute;
      final isSplashRoute = state.uri.path == splashRoute;

      if (isSplashRoute) return null;

      final isAuthRoute =
          isLoginRoute || isSignupRoute || isForgotPasswordRoute;

      // 1. Wait for Auth State (Prevent early redirect during initialization)
      if (authState.status == AuthStatus.unknown) {
        return isSplashRoute ? null : splashRoute;
      }

      // 2. Prevent premature redirect during logging out transition
      if (authState.status == AuthStatus.loggingOut) {
        return null;
      }

      // 3. Handle Unauthenticated Users
      if (!isAuthenticated) {
        if (!isAuthRoute && !isSplashRoute) {
          return loginRoute;
        }
        return null;
      } else {
        // Handle Authenticated Users
        if (!isVerified) {
          // If they are not verified, they must stay on the verification screen
          if (state.uri.path != verifyEmailRoute && !isAuthRoute) {
            return verifyEmailRoute;
          }
          return null;
        } else {
          // If they are verified and try to access auth or verification screens, send them home
          if (isAuthRoute || state.uri.path == verifyEmailRoute) {
            return homeRoute;
          }
        }
      }
      return null;
    },
    routes: [
      // Merge all modular decentralized feature routes
      ...AuthRoutes.routes,
      ...KidsRoutes.routes,
      ...GameRoutes.routes,
      ...HomeRoutes.routes,
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('No route defined for ${state.uri.path}')),
    ),
  );
}

class _StreamListenable extends ChangeNotifier {
  final Stream stream;
  late final StreamSubscription subscription;

  _StreamListenable(this.stream) {
    subscription = stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }
}
