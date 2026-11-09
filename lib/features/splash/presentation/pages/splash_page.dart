import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/features/auth/data/models/user_model.dart';
import 'package:vowl/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';

/// Initial routing gatekeeper that holds the native splash screen until
/// authentication state resolves, routing seamlessly to either the home dashboard
/// or login screen without visual flashing or infinite offline freezes.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _hasNavigated = false;
  Timer? _failsafeTimer;

  @override
  void initState() {
    super.initState();

    // Check auth status as soon as the first frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkNavigation();
    });

    // PRODUCTION FAILSAFE:
    // Guarantees that the app NEVER gets stuck on the splash screen under any
    // circumstances (offline launch, slow I/O, delayed Firestore snapshots).
    // If auth state has not resolved within 2.5 seconds, force navigation based
    // on locally cached credentials.
    _failsafeTimer = Timer(const Duration(milliseconds: 2500), () {
      if (!mounted || _hasNavigated) return;
      _forceFallbackNavigation();
    });
  }

  @override
  void dispose() {
    _failsafeTimer?.cancel();
    super.dispose();
  }

  Future<void> _forceFallbackNavigation() async {
    if (_hasNavigated) return;
    _hasNavigated = true;
    _failsafeTimer?.cancel();

    // Ensure native splash is dropped
    FlutterNativeSplash.remove();

    final authBloc = context.read<AuthBloc>();
    final authState = authBloc.state;

    if (authState.status == AuthStatus.authenticated) {
      context.go(AppRouter.homeRoute);
      return;
    }

    // Inspect direct local FirebaseAuth instance (cached offline on device)
    final currentUser = di.sl<firebase_auth.FirebaseAuth>().currentUser;
    if (currentUser != null) {
      try {
        final cached = await di.sl<AuthLocalDataSource>().getCachedUser();
        if (cached != null && cached.id == currentUser.uid) {
          authBloc.add(
            AuthUserChanged(
              cached.copyWith(
                isEmailVerified:
                    currentUser.emailVerified || cached.isEmailVerified,
              ),
            ),
          );
        } else {
          // Cold-start on reinstalled app: fetch authoritative Firestore profile
          // before routing to avoid flashing stale OAuth credentials
          UserModel? authoritativeUser;
          try {
            final doc = await FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .get()
                .timeout(const Duration(seconds: 2));
            if (doc.exists && doc.data() != null) {
              authoritativeUser = UserModel.fromMap(doc.data()!, doc.id).copyWith(
                isEmailVerified: currentUser.emailVerified,
              );
              await di.sl<AuthLocalDataSource>().cacheUser(authoritativeUser);
            }
          } catch (_) {}

          authBloc.add(
            AuthUserChanged(
              authoritativeUser ??
                  UserModel(
                    id: currentUser.uid,
                    email: currentUser.email ?? '',
                    displayName: currentUser.displayName,
                    photoUrl: currentUser.photoURL,
                    isEmailVerified: currentUser.emailVerified,
                    dailyXpHistory: const {},
                    recentActivities: const [],
                  ),
            ),
          );
        }
      } catch (_) {
        authBloc.add(const AuthRefreshUser());
      }
      if (mounted) {
        context.go(AppRouter.homeRoute);
      }
    } else {
      authBloc.add(const AuthUserChanged(null));
      if (mounted) {
        context.go(AppRouter.homeRoute);
      }
    }
  }

  void _checkNavigation() {
    if (_hasNavigated) return;

    final authState = context.read<AuthBloc>().state;
    if (authState.status == AuthStatus.unknown) {
      // Auth is still resolving; BlocListener will catch the transition.
      return;
    }

    _hasNavigated = true;
    _failsafeTimer?.cancel();

    // Drop native splash and route to the appropriate screen
    FlutterNativeSplash.remove();

    // Drop native splash and let GoRouter redirect logic route to Home or Login
    context.go(AppRouter.homeRoute);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.slate900 : Colors.white;

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status != AuthStatus.unknown) {
          _checkNavigation();
        }
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
          systemNavigationBarColor: backgroundColor,
          systemNavigationBarIconBrightness: isDark
              ? Brightness.light
              : Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: backgroundColor,
          // Branded fallback UI: if native splash is removed while routing completes,
          // user sees the authentic Vowl splash logo and spinner instead of a blank screen.
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/vowl_splash_logo.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppColors.indigo500, AppColors.blue500],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.indigo500.withValues(
                            alpha: isDark ? 0.40 : 0.25,
                          ),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'V',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.indigo500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
