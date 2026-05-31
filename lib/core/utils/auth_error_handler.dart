class AuthErrorHandler {
  static String getMessage(String error) {
    final cleanMsg = error.toLowerCase();

    // 1. Google Auth Sign-in Conflicts or Invalid credentials
    if (cleanMsg.contains('invalid-credential') || 
        cleanMsg.contains('invalid-login-credentials') ||
        cleanMsg.contains('wrong-password') ||
        cleanMsg.contains('user-not-found')) {
      return 'Incorrect email or password. If you signed up using Google, please try logging in with the Google Sign-In button!';
    }

    // 2. Email registration conflicts
    if (cleanMsg.contains('email-already-in-use') ||
        cleanMsg.contains('already-registered') ||
        cleanMsg.contains('email_already_in_use')) {
      return 'This email is already registered. Try logging in or resetting your password!';
    }

    // 3. Email formatting
    if (cleanMsg.contains('invalid-email') || cleanMsg.contains('invalid_email')) {
      return 'Please enter a valid email address (e.g., traveler@vowl.com).';
    }

    // 4. Password strength constraints
    if (cleanMsg.contains('weak-password') || cleanMsg.contains('weak_password')) {
      return 'Please choose a stronger password. It should be at least 6 characters long.';
    }

    // 5. Network connectivity issues
    if (cleanMsg.contains('network-request-failed') ||
        cleanMsg.contains('network_request_failed') ||
        cleanMsg.contains('network-error') ||
        cleanMsg.contains('network_error')) {
      return 'We couldn\'t connect to our servers. Please check your internet connection!';
    }

    // 6. Rate limits & spam prevention
    if (cleanMsg.contains('too-many-requests') || cleanMsg.contains('too_many_requests')) {
      return 'Too many login attempts. Please wait a moment and try again!';
    }

    // 7. Security & Database Sync issues
    if (cleanMsg.contains('permission-denied') || cleanMsg.contains('permission_denied')) {
      return 'We encountered a database sync issue. Please try signing up again!';
    }

    if (cleanMsg.contains('user-disabled') || cleanMsg.contains('user_disabled')) {
      return 'This account has been disabled. Please reach out to Vowl Support.';
    }

    if (cleanMsg.contains('requires-recent-login') || cleanMsg.contains('requires_recent_login')) {
      return 'For your security, please sign out and sign in again before continuing.';
    }

    if (cleanMsg.contains('credential-already-in-use') || cleanMsg.contains('credential_already_in_use')) {
      return 'This Google account is already linked with another email address.';
    }

    // 8. Cancellations
    if (cleanMsg.contains('canceled') || 
        cleanMsg.contains('cancelled') || 
        cleanMsg.contains('aborted-by-user') || 
        cleanMsg.contains('sign_in_canceled')) {
      return 'Sign in was cancelled.';
    }

    // Fallback message
    return 'Authentication issue. Please try again or contact Vowl Support!';
  }
}
