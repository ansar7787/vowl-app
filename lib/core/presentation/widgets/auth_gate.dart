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
    return const Scaffold(
      key: ValueKey('auth_loading'),
      backgroundColor: Colors.white,
      body: Center(
        child: RepaintBoundary(
          child: ShimmerLoading.circular(width: 50, height: 50),
        ),
      ),
    );
  }
}
