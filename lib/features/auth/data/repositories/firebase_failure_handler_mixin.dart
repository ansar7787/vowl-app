import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
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
mixin FirebaseFailureHandlerMixin {
  Failure handleFirebaseException(dynamic e) {
    if (e is firebase_auth.FirebaseAuthException) {
      switch (e.code) {
        case 'network-request-failed':
        case 'unavailable':
          return const NetworkFailure(
            'No internet connection. Please verify your network.',
          );
        default:
          return AuthFailure(e.code);
      }
    }

    if (e is FirebaseException) {
      switch (e.code) {
        case 'unavailable':
        case 'network-request-failed':
          return const NetworkFailure(
            'Network connection failed. Operating in offline mode.',
          );
        default:
          return ServerFailure(
            'Database operation failed: ${e.message ?? e.code}',
          );
      }
    }

    final errStr = e.toString();
    if (errStr.contains('SocketException') ||
        errStr.contains('NetworkError') ||
        errStr.contains('XMLHttpRequest')) {
      return const NetworkFailure(
        'Network unreachable. Please check your connection.',
      );
    }

    return ServerFailure(errStr);
  }
}
