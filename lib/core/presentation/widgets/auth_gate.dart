import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/pages/login_page.dart';
import 'package:vowl/features/home/presentation/pages/home_screen.dart';

/// Authentication gate that resolves the root widget based on [AuthBloc] state.
///
/// Transitions are smoothed with a 400 ms [FadeTransition]. Each branch is
/// keyed so [AnimatedSwitcher] detects the screen change correctly.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      // Narrow the rebuild scope: only rebuild when [status] changes.
      buildWhen: (prev, curr) => prev.status != curr.status,
      builder: (context, state) {
        final Widget activeScreen = switch (state.status) {
          AuthStatus.authenticated => const HomeScreen(
            key: ValueKey('auth_authenticated'),
          ),
          AuthStatus.unauthenticated => const LoginPage(
            key: ValueKey('auth_unauthenticated'),
          ),
          _ => const _LoadingScreen(),
        };

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: activeScreen,
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Loading screen — shown while auth state is resolving.
// ---------------------------------------------------------------------------

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    // BUG FIX (THEME USAGE): previously hardcoded `Colors.white`
    // regardless of theme, so dark-mode users saw a jarring white flash
    // while auth state resolved, inconsistent with the app's full
    // dark-mode support (AppTheme/ThemeCubit). Uses the exact same dark
    // scaffold color (Slate 900) already used consistently across this
    // codebase's other full-screen states (NoInternetPage,
    // InsecureDeviceScreen, GlobalErrorBoundary) rather than introducing
    // a new color.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      key: const ValueKey('auth_loading'),
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      body: const Center(
        child: RepaintBoundary(
          child: ShimmerLoading.circular(width: 50, height: 50),
        ),
      ),
    );
  }
}
