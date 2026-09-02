/// Shared validation utilities for the auth feature.
///
/// ### Why this exists
/// The email regex was previously duplicated 6 times across
/// login_widgets.dart, signup_widgets.dart, forgot_password_widgets.dart,
/// login_cubit.dart, signup_cubit.dart, and forgot_password_cubit.dart.
/// This single source of truth eliminates drift risk and reduces byte count.
abstract final class AuthValidators {
  /// Compiled once — reused across all auth forms and cubits.
  ///
  /// Accepts modern long-form TLDs (.academy, .international, etc.)
  /// via the `{2,}` suffix. Permits hyphens and dots in the local part.
  static final emailRegex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,}$');

  /// Minimum password length enforced by both client-side validators
  /// and the Firebase Auth backend.
  static const int minPasswordLength = 6;

  /// Minimum display-name length.
  static const int minNameLength = 2;
}
