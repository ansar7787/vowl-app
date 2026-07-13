import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:vowl/core/error/failures.dart';

/// Shared mixin providing uniform Firebase exception → typed [Failure] translation
/// across all repository implementations.
///
/// Previously, an identical `_handleException` method was copy-pasted verbatim
/// into [AuthRepositoryImpl], [GamificationRepositoryImpl], [ShopRepositoryImpl],
/// and [UserRepositoryImpl]. This mixin is the single source of truth.
///
/// Priority resolution order:
///   1. [firebase_auth.FirebaseAuthException] → [AuthFailure] or [NetworkFailure]
///   2. [FirebaseException] (Firestore / Storage) → [ServerFailure] or [NetworkFailure]
///   3. Socket / network string pattern → [NetworkFailure]
///   4. Generic catch-all → [ServerFailure]
///
/// ### Failure payload contract — codes, not sentences
/// Every [Failure] returned here carries a short, stable, machine-readable
/// **code** (e.g. `'wrong-password'`, `'network-request-failed'`,
/// `'unexpected-error'`) rather than a hardcoded English sentence. This data
/// layer has no [BuildContext] and therefore cannot localize user-facing
/// text — only the presentation layer (which owns `AppLocalizations`) can. A
/// hardcoded English message baked in here can *never* be shown correctly in
/// any of the app's other languages, no matter what the presentation layer
/// does with it.
///
/// Presentation code should map each code to a localized string with a
/// generic fallback for anything unrecognized, e.g.:
/// ```dart
/// String messageFor(BuildContext context, Failure f) {
///   final l10n = AppLocalizations.of(context)!;
///   switch (f.message) { // the failure's code
///     case 'wrong-password': return l10n.errorWrongPassword;
///     case 'network-request-failed': return l10n.errorNoConnection;
///     case 'insufficient-coins': return l10n.errorInsufficientCoins;
///     default: return l10n.errorSomethingWentWrong;
///   }
/// }
/// ```
/// This presentation-layer mapper lives outside this feature slice and isn't
/// included here — see the review notes for the full list of codes now
/// produced across the auth/gamification/shop/user repositories.
mixin FirebaseFailureHandlerMixin {
  static const String _kUnexpectedErrorCode = 'unexpected-error';
  static const String _kNetworkUnreachableCode = 'network-unreachable';

  Failure handleFirebaseException(dynamic e) {
    if (e is firebase_auth.FirebaseAuthException) {
      if (_isNetworkErrorCode(e.code)) {
        return NetworkFailure(e.code);
      }
      return AuthFailure(e.code);
    }

    if (e is FirebaseException) {
      if (_isNetworkErrorCode(e.code)) {
        return NetworkFailure(e.code);
      }
      return ServerFailure(e.code);
    }

    final errStr = e.toString();
    if (_looksLikeNetworkError(errStr)) {
      return const NetworkFailure(_kNetworkUnreachableCode);
    }

    // Never surface raw exception internals to callers — they can't be
    // localized, and stringifying an arbitrary exception risks leaking
    // implementation details (stack-adjacent text, internal identifiers)
    // into whatever the presentation layer does with `failure.message`.
    // Log the real error for debug-time triage; return a stable generic
    // code otherwise.
    if (kDebugMode) {
      debugPrint('FirebaseFailureHandlerMixin: unclassified exception: $e');
    }
    return ServerFailure(_kUnexpectedErrorCode);
  }

  bool _isNetworkErrorCode(String code) =>
      code == 'network-request-failed' || code == 'unavailable';

  bool _looksLikeNetworkError(String errStr) =>
      errStr.contains('SocketException') ||
      errStr.contains('NetworkError') ||
      errStr.contains('XMLHttpRequest');
}
