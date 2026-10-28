import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/widgets/auth_gate.dart';
import 'package:vowl/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:vowl/features/auth/presentation/pages/login_page.dart';
import 'package:vowl/features/auth/presentation/pages/signup_page.dart';
import 'package:vowl/features/auth/presentation/pages/verify_email_page.dart';
import 'package:vowl/features/auth/presentation/pages/age_gate_screen.dart';
import 'package:vowl/features/onboarding/presentation/pages/onboarding_page.dart';

/// Route definitions for the authentication feature module.
///
/// ### Route constants
/// Path constants are defined here as the canonical source. [AppRouter] (core)
/// references these same strings to keep routing DRY. If routes need to change,
/// update here and [AppRouter] together.
abstract final class AuthRoutes {
  /// Route path for the full-screen onboarding experience.
  static const String onboardingRoute = '/onboarding';

  /// Route path for the login page.
  static const String loginRoute = '/login';

  /// Route path for the user registration page.
  static const String signupRoute = '/signup';

  /// Route path for the password recovery page.
  static const String forgotPasswordRoute = '/forgot-password';

  /// Route path for the email address verification page.
  static const String verifyEmailRoute = '/verify-email';

  /// Route path for the age verification gate screen.
  static const String ageGateRoute = '/age-gate';

  /// List of go_router route specifications for authentication flows.
  static final List<RouteBase> routes = [
    GoRoute(path: '/', builder: (context, state) => const AuthGate()),
    GoRoute(
      path: onboardingRoute,
      builder: (context, state) => const OnboardingPage(),
    ),
    GoRoute(path: loginRoute, builder: (context, state) => const LoginPage()),
    GoRoute(path: signupRoute, builder: (context, state) => const SignUpPage()),
    GoRoute(
      path: forgotPasswordRoute,
      builder: (context, state) => const ForgotPasswordPage(),
    ),
    GoRoute(
      path: verifyEmailRoute,
      builder: (context, state) => const VerifyEmailPage(),
    ),
    GoRoute(
      path: ageGateRoute,
      builder: (context, state) => const AgeGateScreen(),
    ),
  ];
}
