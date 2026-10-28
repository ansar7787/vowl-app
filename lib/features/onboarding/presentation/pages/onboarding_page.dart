import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/utils/app_router.dart';
import 'package:vowl/core/utils/haptic_service.dart';
import 'package:vowl/core/utils/injection_container.dart' as di;
import 'package:vowl/core/utils/onboarding_service.dart';
import 'package:vowl/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:vowl/features/onboarding/onboarding_screen.dart';

/// Production-grade full-screen onboarding experience presenting Vowl's core ecosystem.
///
/// Integrates the finished 4-slide layered SVG artwork with motion choreography,
/// pre-warmed vector caching, and zero-latency routing completion.
class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  Future<void> _handleComplete(
    BuildContext context, {
    bool toLogin = false,
  }) async {
    try {
      di.sl<HapticService>().light();
    } catch (_) {}

    await OnboardingService.completeOnboarding();

    if (!context.mounted) return;

    try {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
        return;
      }
      final isAuthenticated =
          di.sl.isRegistered<AuthBloc>() &&
          di.sl<AuthBloc>().state.status == AuthStatus.authenticated;

      if (toLogin) {
        context.go(AppRouter.loginRoute);
      } else if (isAuthenticated) {
        context.go(AppRouter.homeRoute);
      } else {
        context.go(AppRouter.loginRoute);
      }
    } catch (_) {
      try {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScreen(
      onSkip: () => _handleComplete(context),
      onGetStarted: () => _handleComplete(context),
      onLogin: () => _handleComplete(context, toLogin: true),
    );
  }
}
