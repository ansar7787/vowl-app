import 'package:dartz/dartz.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

/// Domain contract for authentication operations.
///
/// Implementations expose a persistent [user] stream that merges Firebase Auth
/// state with real-time Firestore profile changes. Because the stream is backed
/// by long-lived subscriptions, every implementation **must** be disposed when
/// the DI container tears down (typically on app exit or hot-restart in tests).
abstract class AuthRepository {
  /// Continuous stream of the currently authenticated [UserEntity], or [null]
  /// when no user is signed in. Emits on every Firebase Auth state change and
  /// on every Firestore profile update.
  Stream<UserEntity?> get user;

  /// Creates a new account, sets the display name, and provisions the initial
  /// Firestore profile document.
  Future<Either<Failure, UserEntity>> signUp({
    required String name,
    required String email,
    required String password,
  });

  /// Signs in with email and password.
  ///
  /// On success returns the full [UserEntity] fetched from Firestore (not just
  /// auth credential fields). The persistent [user] stream remains authoritative
  /// for real-time updates after sign-in.
  Future<Either<Failure, UserEntity>> logInWithEmail({
    required String email,
    required String password,
  });

  /// Initiates a Google Sign-In OAuth flow. Returns true if the user is new.
  Future<Either<Failure, bool>> logInWithGoogle();

  /// Signs out from Firebase Auth and clears any cached provider sessions.
  Future<Either<Failure, void>> logOut();

  /// Dispatches a password-reset email to [email].
  Future<Either<Failure, void>> sendPasswordResetEmail(String email);

  /// Sends an email verification to the currently signed-in user's address.
  Future<Either<Failure, void>> sendEmailVerification();

  /// Forces a reload of the Firebase Auth user record (useful after verifying
  /// an email to have [isEmailVerified] updated immediately).
  Future<Either<Failure, void>> reloadUser();

  /// Returns the currently authenticated [UserEntity] from Firestore, or
  /// [null] if no user is signed in. Falls back to the in-device cache when
  /// the network is unavailable.
  Future<Either<Failure, UserEntity?>> getCurrentUser();

  /// Permanently deletes the authenticated user's account, Firestore document,
  /// and Storage assets, then clears local preferences.
  ///
  /// Returns [AuthFailure('requires-recent-login')] when Firebase Auth requires
  /// the user to re-authenticate before deletion can proceed.
  Future<Either<Failure, void>> deleteAccount();

  /// Releases all internal stream subscriptions and closes the broadcast
  /// [StreamController].
  ///
  /// Must be called when the repository is torn down (e.g., by the DI
  /// container's dispose callback). Subsequent calls to [user] after [dispose]
  /// will throw a [StateError].
  void dispose();
}
