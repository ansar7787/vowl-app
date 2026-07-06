import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/widgets/auth_gate.dart';
import 'package:vowl/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:vowl/features/auth/presentation/pages/login_page.dart';
import 'package:vowl/features/auth/presentation/pages/signup_page.dart';
import 'package:vowl/features/auth/presentation/pages/verify_email_page.dart';
import 'package:vowl/features/auth/presentation/pages/age_gate_screen.dart';
import 'package:vowl/core/utils/app_router.dart';

/// Route definitions for the authentication feature module.
///
/// ### Route constants
/// Path constants are defined here as the canonical source. [AppRouter] (core)
/// references these same strings to keep routing DRY. If routes need to change,
/// update here and [AppRouter] together.
class AuthRoutes {
  AuthRoutes._();

  static const String loginRoute = '/login';
  static const String signupRoute = '/signup';
  static const String forgotPasswordRoute = '/forgot-password';
  static const String verifyEmailRoute = '/verify-email';

  static final List<RouteBase> routes = [
    GoRoute(path: '/', builder: (context, state) => const AuthGate()),
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
      path: AppRouter.ageGateRoute,
      builder: (context, state) => const AgeGateScreen(),
    ),
  ];
}
