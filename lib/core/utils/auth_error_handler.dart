import 'package:firebase_auth/firebase_auth.dart';

/// Translates raw Firebase / system authentication errors into localisation
/// keys that callers resolve via `context.tr(key)`.
///
/// ### Migration from hardcoded strings
/// The previous API returned raw English strings directly. The new API returns
/// localisation keys, enabling all 18 supported languages to display native
/// error messages.
///
/// ### Usage
/// ```dart
/// // In a widget that has BuildContext:
/// final key = AuthErrorHandler.getKey(error);
/// final message = context.tr(key);
/// CustomSnackBar.show(context: context, message: message, type: CustomSnackBarType.error);
/// ```
///
/// translation.
class AuthErrorHandler {
  AuthErrorHandler._(); // Non-instantiable.

  // ── Localisation key constants ────────────────────────────────────────────
  // FIX (HIGH-1): These keys are returned instead of raw English strings,
  // allowing the presentation layer to call context.tr(key) in the user's
  // language. Previously all 18 language users received English error text.

  static const String _kInvalidCredential = 'auth.error.invalid_credential';
  static const String _kEmailInUse = 'auth.error.email_already_in_use';
  static const String _kInvalidEmail = 'auth.error.invalid_email';
  static const String _kWeakPassword = 'auth.error.weak_password';
  static const String _kNetworkFailed = 'auth.error.network_failed';
  static const String _kTooManyRequests = 'auth.error.too_many_requests';
  static const String _kPermissionDenied = 'auth.error.permission_denied';
  static const String _kUserDisabled = 'auth.error.user_disabled';
  static const String _kRequiresRecentLogin =
      'auth.error.requires_recent_login';
  static const String _kCredentialInUse = 'auth.error.credential_in_use';
  static const String _kSignInCancelled = 'auth.error.sign_in_cancelled';
  static const String _kAccountExistsWithDifferentCredential =
      'auth.error.account_exists_with_different_credential';
  static const String _kGeneric = 'auth.error.generic';

  // ── Public API ────────────────────────────────────────────────────────────

  /// Returns a localisation key for the given authentication error.
  ///
  /// Call `context.tr(AuthErrorHandler.getKey(error))` in the presentation
  /// layer to display the error in the user's language.
  ///
  /// Accepts [FirebaseAuthException], [FirebaseException], [String], or `null`.
  static String getKey(dynamic error) {
    if (error == null) return _kGeneric;

    final String errorString;
    if (error is FirebaseAuthException) {
      errorString = '${error.code} ${error.message ?? ''}';
    } else if (error is FirebaseException) {
      errorString = '${error.code} ${error.message ?? ''}';
    } else {
      errorString = error.toString();
    }

    return _classify(errorString.toLowerCase());
  }

  static String _classify(String clean) {
    // 1. Invalid credentials / wrong password
    if (clean.contains('invalid-credential') ||
        clean.contains('invalid-login-credentials') ||
        clean.contains('wrong-password') ||
        clean.contains('user-not-found')) {
      return _kInvalidCredential;
    }

    // 2. Email already registered
    if (clean.contains('email-already-in-use') ||
        clean.contains('already-registered') ||
        clean.contains('email_already_in_use')) {
      return _kEmailInUse;
    }

    // 3. Malformed email
    if (clean.contains('invalid-email') || clean.contains('invalid_email')) {
      return _kInvalidEmail;
    }

    // 4. Weak password
    if (clean.contains('weak-password') || clean.contains('weak_password')) {
      return _kWeakPassword;
    }

    // 5. Network connectivity
    if (clean.contains('network-request-failed') ||
        clean.contains('network_request_failed') ||
        clean.contains('network-error') ||
        clean.contains('network_error')) {
      return _kNetworkFailed;
    }

    // 6. Rate limiting
    if (clean.contains('too-many-requests') ||
        clean.contains('too_many_requests')) {
      return _kTooManyRequests;
    }

    // 7. Firestore permission / database sync
    if (clean.contains('permission-denied') ||
        clean.contains('permission_denied')) {
      return _kPermissionDenied;
    }

    // 8. Disabled account
    if (clean.contains('user-disabled') || clean.contains('user_disabled')) {
      return _kUserDisabled;
    }

    // 9. Re-authentication required
    if (clean.contains('requires-recent-login') ||
        clean.contains('requires_recent_login')) {
      return _kRequiresRecentLogin;
    }

    // 10. Credential already linked to another account
    if (clean.contains('credential-already-in-use') ||
        clean.contains('credential_already_in_use')) {
      return _kCredentialInUse;
    }

    // 11. User cancelled the flow
    if (clean.contains('canceled') ||
        clean.contains('cancelled') ||
        clean.contains('aborted-by-user') ||
        clean.contains('sign_in_canceled')) {
      return _kSignInCancelled;
    }

    // 12. Account exists with different credential
    if (clean.contains('account-exists-with-different-credential') ||
        clean.contains('account_exists_with_different_credential')) {
      return _kAccountExistsWithDifferentCredential;
    }

    return _kGeneric;
  }


}
