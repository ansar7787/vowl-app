import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:vowl/features/auth/data/models/user_model.dart';
import 'package:vowl/features/auth/data/repositories/firebase_failure_handler_mixin.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/domain/repositories/auth_repository.dart';

/// Concrete implementation of [AuthRepository] orchestrating user sessions via
/// Firebase Auth and Firestore.
///
/// ### User stream lifecycle
/// [_userStreamController] is a single broadcast [StreamController] backed by
/// two nested listeners:
///   1. [_firebaseAuth.userChanges()] — outer auth state.
///   2. Firestore `.snapshots()` — inner real-time profile, re-subscribed on
///      every auth state change and cancelled immediately before each re-sub.
///
/// All emissions go through [_emit]/[_emitError], which guard against the
/// controller having already been closed by [dispose] — the underlying
/// Firebase subscriptions are cancelled in [dispose] but `cancel()` is not
/// awaited (it can't be — [dispose] must stay synchronous to satisfy the
/// [AuthRepository] interface), so a callback that was already in flight can
/// still land after `close()`. Without the guard that throws
/// `StateError: Cannot add event after closing`.
///
/// All subscriptions are cancelled and the controller is closed when [dispose]
/// is called, making this safe for test environments that create/destroy
/// repository instances repeatedly.
///
/// ### deleteAccount ordering
/// We use the Firebase "Delete User Data" Extension to handle database cleanup.
/// Therefore, this repository only needs to delete the Auth account. If the
/// auth deletion fails (e.g. requires-recent-login), the user retains all their
/// data safely. Once auth deletion succeeds, the Extension wipes Firestore and Storage.
class AuthRepositoryImpl
    with FirebaseFailureHandlerMixin
    implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final FirebaseMessaging _firebaseMessaging;

  // ---------------------------------------------------------------------------
  // Stream controller & subscriptions
  // ---------------------------------------------------------------------------

  late StreamController<UserEntity?> _userStreamController;
  StreamSubscription<firebase_auth.User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _firestoreSubscription;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    FirebaseMessaging? firebaseMessaging,
  }) : _remoteDataSource = remoteDataSource,
       _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _firebaseMessaging = firebaseMessaging ?? FirebaseMessaging.instance {
    _initUserStream();
  }

  // ---------------------------------------------------------------------------
  // Stream initialisation
  // ---------------------------------------------------------------------------

  void _initUserStream() {
    _userStreamController = StreamController<UserEntity?>.broadcast(
      onListen: _startFirebaseListeners,
      onCancel: _stopAllSubscriptions,
    );
  }

  void _startFirebaseListeners() {
    _authSubscription = _firebaseAuth.userChanges().listen(
      _onAuthStateChanged,
      onError: (Object error, StackTrace stack) {
        _log('AuthRepository: auth stream error: $error');
        _emitError(error, stack);
      },
    );
  }

  void _stopAllSubscriptions() {
    _firestoreSubscription?.cancel();
    _firestoreSubscription = null;
    _authSubscription?.cancel();
    _authSubscription = null;
  }

  // ---------------------------------------------------------------------------
  // Safe stream emission — guards against emitting after dispose()
  // ---------------------------------------------------------------------------

  /// Adds [value] to [_userStreamController] unless it has already been
  /// closed. See the class doc for why this guard is necessary.
  void _emit(UserEntity? value) {
    if (_userStreamController.isClosed) return;
    _userStreamController.add(value);
  }

  /// Adds an error to [_userStreamController] unless it has already been
  /// closed.
  void _emitError(Object error, [StackTrace? stackTrace]) {
    if (_userStreamController.isClosed) return;
    _userStreamController.addError(error, stackTrace);
  }

  // ---------------------------------------------------------------------------
  // Auth state handler
  // ---------------------------------------------------------------------------

  void _onAuthStateChanged(firebase_auth.User? firebaseUser) {
    // Cancel the previous Firestore subscription before starting a new one to
    // prevent stale emissions from the previous user's document.
    _firestoreSubscription?.cancel();
    _firestoreSubscription = null;

    if (firebaseUser == null) {
      _emit(null);
      return;
    }

    _firestoreSubscription = _firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .snapshots()
        .listen(
          (doc) => _onFirestoreSnapshot(doc, firebaseUser),
          onError: (Object error) => _onFirestoreError(error),
        );
  }

  // ---------------------------------------------------------------------------
  // Firestore snapshot handler
  // ---------------------------------------------------------------------------

  void _onFirestoreSnapshot(
    DocumentSnapshot<Map<String, dynamic>> doc,
    firebase_auth.User firebaseUser,
  ) {
    try {
      if (doc.exists && doc.data() != null) {
        final userModel = UserModel.fromMap(doc.data()!);
        _emit(userModel.copyWith(isEmailVerified: firebaseUser.emailVerified));
      } else {
        // Document doesn't exist yet (e.g., Firestore write is in-flight).
        // Emit a minimal entity derived from Firebase Auth credentials.
        _emit(_minimalUserFrom(firebaseUser));
      }
    } catch (e, stack) {
      _log('AuthRepository: Firestore snapshot mapping error: $e\n$stack');
      _emit(null);
    }
  }

  // ---------------------------------------------------------------------------
  // Firestore error handler
  // ---------------------------------------------------------------------------

  void _onFirestoreError(Object error) {
    final errStr = error.toString();
    // PERMISSION_DENIED is expected immediately after logout — Firestore
    // security rules revoke access before the Firebase Auth subscription fires
    // the null event. Treat it as a normal sign-out signal.
    if (errStr.contains('PERMISSION_DENIED') ||
        errStr.contains('permission-denied')) {
      _log(
        'AuthRepository: Firestore permission denied (expected during logout).',
      );
      _emit(null);
      return;
    }
    _emitError(error);
  }

  // ---------------------------------------------------------------------------
  // AuthRepository interface
  // ---------------------------------------------------------------------------

  @override
  Stream<UserEntity?> get user => _userStreamController.stream;

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) return const Right(null);

      // Use default Source (server-and-cache) so this works both online and
      // offline. Source.server was previously used here, which caused
      // getCurrentUser() to return null for every offline app start even when
      // the user was logged in and data was cached.
      final doc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (doc.exists && doc.data() != null) {
        try {
          final user = UserModel.fromMap(
            doc.data()!,
          ).copyWith(isEmailVerified: firebaseUser.emailVerified);
          return Right(user);
        } catch (e, stack) {
          // Malformed Firestore data (bad migration, manual console edit,
          // etc). Don't block app entry over a parsing hiccup — degrade to
          // a minimal entity built from Auth credentials, the same fallback
          // AuthRemoteDataSource.logInWithEmail already uses. This is never
          // written back to Firestore, so the next successful read still
          // recovers the real profile.
          _log('AuthRepository: getCurrentUser parse error: $e\n$stack');
          return Right(_minimalUserFrom(firebaseUser));
        }
      }

      // Firestore document missing — provision it and return the new entity.
      final newUser = UserModel(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName,
        photoUrl: firebaseUser.photoURL,
        lastLoginDate: DateTime.now(),
        currentStreak: 1,
        isEmailVerified: firebaseUser.emailVerified,
        dailyXpHistory: const {},
        recentActivities: const [],
      );
      try {
        await _firestore
            .collection('users')
            .doc(newUser.id)
            .set(newUser.toMap());
      } catch (e) {
        // Non-fatal: the caller still gets a fully-formed in-memory entity;
        // the next getCurrentUser() or auth-state change retries provisioning.
        _log('AuthRepository: getCurrentUser provisioning write failed: $e');
      }
      return Right(newUser);
    } catch (e) {
      return Left(handleFirebaseException(e));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // Delegate entirely to the data source, which handles:
      // createUserWithEmailAndPassword → updateDisplayName → Firestore write.
      final userModel = await _remoteDataSource.signUp(
        name: name,
        email: email,
        password: password,
      );
      return Right(userModel);
    } catch (e) {
      return Left(handleFirebaseException(e));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> logInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userModel = await _remoteDataSource.logInWithEmail(
        email: email,
        password: password,
      );
      return Right(userModel);
    } catch (e) {
      return Left(handleFirebaseException(e));
    }
  }

  @override
  Future<Either<Failure, bool>> logInWithGoogle() async {
    try {
      final isNewUser = await _remoteDataSource.logInWithGoogle();
      return Right(isNewUser);
    } catch (e) {
      return Left(handleFirebaseException(e));
    }
  }

  @override
  Future<Either<Failure, void>> logOut() async {
    try {
      await _remoteDataSource.logOut();
      return const Right(null);
    } catch (e) {
      return Left(handleFirebaseException(e));
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return const Right(null);
    } catch (e) {
      return Left(handleFirebaseException(e));
    }
  }

  @override
  Future<Either<Failure, void>> sendEmailVerification() async {
    try {
      await _firebaseAuth.currentUser?.sendEmailVerification();
      return const Right(null);
    } catch (e) {
      return Left(handleFirebaseException(e));
    }
  }

  @override
  Future<Either<Failure, void>> reloadUser() async {
    try {
      await _firebaseAuth.currentUser?.reload();
      return const Right(null);
    } catch (e) {
      return Left(handleFirebaseException(e));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return Left(AuthFailure('user-not-logged-in'));
      }

      // STOP LISTENING to Firestore before we delete the document.
      // If we don't do this, the deletion triggers a snapshot event saying the
      // doc doesn't exist, which causes the AuthBloc to briefly emit a "fresh account"
      // state, hiding the loading overlay and flashing the Home Screen.
      _firestoreSubscription?.cancel();
      _firestoreSubscription = null;

      // Step 1 — Delete the Firebase Auth account
      //
      // Because we use the Firebase "Delete User Data" Extension on the server,
      // we only need to delete the Auth account here. The extension will automatically
      // detect the deletion and securely wipe the user's Firestore and Storage data
      // using Admin privileges in the background.
      //
      // If this fails with `requires-recent-login`, the user is prompted to
      // log in again to finalize the deletion. Since no data was deleted yet,
      // the user experiences zero data loss or ghost-account bugs.
      await user.delete();

      // Step 2 — Unregister the device from Firebase Cloud Messaging
      // This ensures that even if they sign up again, the old device token
      // is completely invalidated and disconnected from the server.
      try {
        await _firebaseMessaging.deleteToken();
      } catch (e) {
        _log('DeleteAccount: FCM token deletion failed: $e');
      }

      // Step 3 — Clear all locally-persisted preferences so they don't bleed
      // into a subsequent user session on the same device.
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
      } catch (e) {
        _log(
          'DeleteAccount: SharedPreferences clear failed (non-critical): $e',
        );
      }

      return const Right(null);
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return Left(AuthFailure('requires-recent-login'));
      }
      return Left(handleFirebaseException(e));
    } catch (e) {
      return Left(handleFirebaseException(e));
    }
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _stopAllSubscriptions();
    if (!_userStreamController.isClosed) {
      _userStreamController.close();
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Builds a minimal [UserModel] from Firebase Auth credential fields alone
  /// (no Firestore data). Used as a non-destructive fallback — never written
  /// back to Firestore, so the real profile is recovered as soon as a
  /// subsequent read succeeds.
  UserModel _minimalUserFrom(firebase_auth.User firebaseUser) {
    return UserModel(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      isEmailVerified: firebaseUser.emailVerified,
      dailyXpHistory: const {},
      recentActivities: const [],
    );
  }

  /// Debug-only log helper. Produces no output in release builds.
  void _log(String message) {
    if (kDebugMode) debugPrint(message);
  }
}
