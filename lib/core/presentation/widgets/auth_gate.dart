import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vowl/core/presentation/widgets/shimmer_loading.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/auth/presentation/pages/login_page.dart';
import 'package:vowl/features/home/presentation/pages/home_screen.dart';

/// An authentication gate with premium animated transitions and state keying.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        Widget activeScreen;

        if (state.status == AuthStatus.authenticated) {
          activeScreen = const HomeScreen(key: ValueKey('auth_authenticated'));
        } else if (state.status == AuthStatus.unauthenticated) {
          activeScreen = const LoginPage(key: ValueKey('auth_unauthenticated'));
        } else {
          activeScreen = const Scaffold(
            key: ValueKey('auth_loading'),
            body: Center(
              child: RepaintBoundary(
                child: ShimmerLoading.circular(width: 50, height: 50),
              ),
            ),
          );
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          child: activeScreen,
        );
      },
    );
  }
}
