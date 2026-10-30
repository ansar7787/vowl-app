import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:vowl/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:vowl/features/auth/data/models/user_model.dart';
import 'package:vowl/features/auth/data/repositories/firebase_failure_handler_mixin.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/domain/repositories/auth_repository.dart';

/// Concrete implementation of [AuthRepository] orchestrating user sessions via
/// Firebase Auth, local persistent disk cache, and Firestore.
///
/// ### Offline-First Architecture
/// When the app opens without internet:
/// 1. Immediately checks [FirebaseAuth.currentUser] and local disk cache
///    ([AuthLocalDataSource]). If authenticated, emits the cached [UserModel]
///    immediately (in 0ms) so the splash screen dismisses and gameplay starts.
/// 2. Firestore listeners use [includeMetadataChanges: true] so cached Firestore
///    documents are emitted immediately without waiting for server network ping.
/// 3. Offline errors from Firestore snapshots fall back gracefully to the
///    cached user instead of emitting stream errors that hang the app.
class AuthRepositoryImpl
    with FirebaseFailureHandlerMixin
    implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final AuthLocalDataSource _localDataSource;
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

  /// Creates an [AuthRepositoryImpl] instance with required data sources and Firebase services.
  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    AuthLocalDataSource? localDataSource,
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    FirebaseMessaging? firebaseMessaging,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource ?? AuthLocalDataSourceImpl(),
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
    // 1. Emit cached/current user state immediately so the app never stalls on startup
    _emitInitialUserState();

    // 2. Listen for subsequent auth state changes
    _authSubscription = _firebaseAuth.userChanges().listen(
      _onAuthStateChanged,
      onError: (Object error, StackTrace stack) {
        _log('AuthRepository: auth stream error: $error');
        final current = _firebaseAuth.currentUser;
        if (current != null) {
          _fallbackToCachedOrMinimal(current);
        } else {
          _emit(null);
        }
      },
    );
  }

  /// Instantly resolves the initial user state from local disk or FirebaseAuth credentials.
  Future<void> _emitInitialUserState() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      _emit(null);
      return;
    }

    try {
      final cached = await _localDataSource.getCachedUser();
      if (cached != null && cached.id == firebaseUser.uid) {
        _emit(
          cached.copyWith(
            isEmailVerified:
                firebaseUser.emailVerified || cached.isEmailVerified,
          ),
        );
      } else {
        _emit(_minimalUserFrom(firebaseUser));
      }
    } catch (_) {
      _emit(_minimalUserFrom(firebaseUser));
    }

    _subscribeToFirestore(firebaseUser);
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

  /// Adds [value] to [_userStreamController] unless it has already been closed.
  void _emit(UserEntity? value) {
    if (_userStreamController.isClosed) return;
    _userStreamController.add(value);
  }

  // ---------------------------------------------------------------------------
  // Auth state handler
  // ---------------------------------------------------------------------------

  void _onAuthStateChanged(firebase_auth.User? firebaseUser) {
    _firestoreSubscription?.cancel();
    _firestoreSubscription = null;

    if (firebaseUser == null) {
      _localDataSource.clearCachedUser();
      _emit(null);
      return;
    }

    _subscribeToFirestore(firebaseUser);
  }

  void _subscribeToFirestore(firebase_auth.User firebaseUser) {
    _firestoreSubscription?.cancel();
    _firestoreSubscription = _firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .snapshots(includeMetadataChanges: true)
        .listen(
          (doc) => _onFirestoreSnapshot(doc, firebaseUser),
          onError: (Object error) => _onFirestoreError(error, firebaseUser),
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
        final userModel = UserModel.fromMap(doc.data()!, doc.id);
        final resolvedUser = userModel.copyWith(
          isEmailVerified:
              firebaseUser.emailVerified || userModel.isEmailVerified,
        );
        _localDataSource.cacheUser(resolvedUser);
        _emit(resolvedUser);
      } else {
        _fallbackToCachedOrMinimal(firebaseUser);
      }
    } catch (e, stack) {
      _log('AuthRepository: Firestore snapshot mapping error: $e\n$stack');
      _fallbackToCachedOrMinimal(firebaseUser);
    }
  }

  // ---------------------------------------------------------------------------
  // Firestore error handler
  // ---------------------------------------------------------------------------

  void _onFirestoreError(Object error, firebase_auth.User firebaseUser) {
    final errStr = error.toString();
    if (errStr.contains('PERMISSION_DENIED') ||
        errStr.contains('permission-denied')) {
      _log(
        'AuthRepository: Firestore permission denied (expected during logout).',
      );
      _localDataSource.clearCachedUser();
      _emit(null);
      return;
    }

    _log(
      'AuthRepository: Firestore stream error (offline resilience triggered): $error',
    );
    // Offline resilience: NEVER let a network error deadlock the app in AuthStatus.unknown.
    // Fall back to cached user so the user can play seamlessly offline.
    _fallbackToCachedOrMinimal(firebaseUser);
  }

  Future<void> _fallbackToCachedOrMinimal(
    firebase_auth.User firebaseUser,
  ) async {
    try {
      final cached = await _localDataSource.getCachedUser();
      if (cached != null && cached.id == firebaseUser.uid) {
        final effectiveName = (cached.displayName != null &&
                cached.displayName!.trim().isNotEmpty)
            ? cached.displayName
            : (firebaseUser.displayName != null &&
                    firebaseUser.displayName!.trim().isNotEmpty
                ? firebaseUser.displayName
                : null);

        final resolvedUser = cached.copyWith(
          isEmailVerified:
              firebaseUser.emailVerified || cached.isEmailVerified,
          displayName: effectiveName,
        );
        // Self-heal to Firestore in background so missing document is created
        try {
          final map = resolvedUser.toMap();
          map['lastRewardTimestamp'] = FieldValue.serverTimestamp();
          _firestore
              .collection('users')
              .doc(resolvedUser.id)
              .set(map, SetOptions(merge: true))
              .catchError((_) {});
        } catch (_) {}
        _emit(resolvedUser);
        return;
      }
    } catch (_) {}
    _emit(_minimalUserFrom(firebaseUser));
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

      // 1. Online-first with fast timeout: fetch authoritative fresh profile from Firestore
      try {
        final doc = await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .get()
            .timeout(const Duration(seconds: 3));

        if (doc.exists && doc.data() != null) {
          try {
            final user = UserModel.fromMap(
              doc.data()!,
              doc.id,
            ).copyWith(isEmailVerified: firebaseUser.emailVerified);
            await _localDataSource.cacheUser(user);
            return Right(user);
          } catch (e, stack) {
            _log('AuthRepository: getCurrentUser parse error: $e\n$stack');
          }
        }
      } catch (e) {
        _log('AuthRepository: Remote getCurrentUser failed or timed out: $e');
      }

      // 2. Offline fallback: load cached user profile from persistent disk storage
      final cached = await _localDataSource.getCachedUser();
      if (cached != null && cached.id == firebaseUser.uid) {
        return Right(
          cached.copyWith(
            isEmailVerified: firebaseUser.emailVerified || cached.isEmailVerified,
          ),
        );
      }

      // Firestore document missing — provision it and return the new entity.
      final effectiveName = (cached != null &&
              cached.id == firebaseUser.uid &&
              cached.displayName != null &&
              cached.displayName!.trim().isNotEmpty)
          ? cached.displayName
          : firebaseUser.displayName;
      final effectiveEmail = (cached != null &&
              cached.id == firebaseUser.uid &&
              cached.email.trim().isNotEmpty)
          ? cached.email
          : (firebaseUser.email ?? '');

      final newUser = (cached != null && cached.id == firebaseUser.uid)
          ? cached.copyWith(
              isEmailVerified:
                  firebaseUser.emailVerified || cached.isEmailVerified,
              displayName: effectiveName,
            )
          : UserModel(
              id: firebaseUser.uid,
              email: effectiveEmail,
              displayName: effectiveName,
              photoUrl: firebaseUser.photoURL,
              lastLoginDate: DateTime.now(),
              currentStreak: 1,
              isEmailVerified: firebaseUser.emailVerified,
              dailyXpHistory: const {},
              recentActivities: const [],
            );
      try {
        final map = newUser.toMap();
        map['lastRewardTimestamp'] = FieldValue.serverTimestamp();
        await _firestore
            .collection('users')
            .doc(newUser.id)
            .set(map, SetOptions(merge: true));
        await _localDataSource.cacheUser(newUser);
      } catch (e) {
        _log('AuthRepository: getCurrentUser provisioning write failed: $e');
      }
      return Right(newUser);
    } catch (e) {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser != null) {
        final cached = await _localDataSource.getCachedUser();
        if (cached != null && cached.id == firebaseUser.uid) {
          return Right(
            cached.copyWith(isEmailVerified: firebaseUser.emailVerified || cached.isEmailVerified),
          );
        }
        return Right(_minimalUserFrom(firebaseUser));
      }
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
      final userModel = await _remoteDataSource.signUp(
        name: name,
        email: email,
        password: password,
      );
      await _localDataSource.cacheUser(userModel);
      _emit(userModel);
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
      await _localDataSource.cacheUser(userModel);
      return Right(userModel);
    } catch (e) {
      return Left(handleFirebaseException(e));
    }
  }

  @override
  Future<Either<Failure, bool>> logInWithGoogle() async {
    try {
      final isNewUser = await _remoteDataSource.logInWithGoogle();
      final current = _firebaseAuth.currentUser;
      if (current != null) {
        final model = UserModel(
          id: current.uid,
          email: current.email ?? '',
          displayName: current.displayName,
          photoUrl: current.photoURL,
          lastLoginDate: DateTime.now(),
          currentStreak: 1,
          dailyXpHistory: const {},
          recentActivities: const [],
        );
        await _localDataSource.cacheUser(model);
      }
      return Right(isNewUser);
    } catch (e) {
      return Left(handleFirebaseException(e));
    }
  }

  @override
  Future<Either<Failure, void>> logOut() async {
    try {
      await _localDataSource.clearCachedUser();
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
      var user = _firebaseAuth.currentUser;
      if (user == null) {
        // Platform channel sync guard: if called immediately following account creation,
        // currentUser may be propagating across the native-to-Dart bridge.
        try {
          user = await _firebaseAuth
              .authStateChanges()
              .firstWhere((u) => u != null)
              .timeout(const Duration(seconds: 3));
        } catch (_) {
          user = _firebaseAuth.currentUser;
        }
      }

      if (user == null) {
        return Left(AuthFailure('user-not-authenticated'));
      }

      firebase_auth.User activeUser = user;

      // Ensure user session & token are freshly synced before dispatching
      try {
        await activeUser.reload();
        activeUser = _firebaseAuth.currentUser ?? activeUser;
      } catch (_) {}

      // Resilient email dispatch with retry:
      // Immediately after account creation, Firebase Auth backend needs a brief
      // moment to replicate the account across its mail services. Retrying with
      // backoff guarantees delivery without forcing the user to manually click Resend.
      Object? lastException;
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          await activeUser.sendEmailVerification();
          return const Right(null);
        } catch (e) {
          lastException = e;
          if (e is firebase_auth.FirebaseAuthException &&
              (e.code == 'too-many-requests' || e.code == 'quota-exceeded')) {
            break;
          }
          if (attempt < 3) {
            await Future.delayed(Duration(milliseconds: 600 * attempt));
            try {
              await activeUser.reload();
              activeUser = _firebaseAuth.currentUser ?? activeUser;
            } catch (_) {}
          }
        }
      }

      if (lastException != null) {
        return Left(handleFirebaseException(lastException));
      }
      return const Right(null);
    } catch (e) {
      return Left(handleFirebaseException(e));
    }
  }

  @override
  Future<Either<Failure, void>> reloadUser() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await user.reload();
        final refreshedUser = _firebaseAuth.currentUser;
        if (refreshedUser != null) {
          final cached = await _localDataSource.getCachedUser();
          DocumentSnapshot<Map<String, dynamic>>? doc;
          try {
            doc = await _firestore
                .collection('users')
                .doc(refreshedUser.uid)
                .get();
          } catch (_) {}

          if (doc != null && doc.exists && doc.data() != null) {
            final userModel = UserModel.fromMap(doc.data()!, doc.id);
            final effectiveName = (userModel.displayName != null &&
                    userModel.displayName!.trim().isNotEmpty)
                ? userModel.displayName
                : ((cached != null &&
                        cached.id == refreshedUser.uid &&
                        cached.displayName != null &&
                        cached.displayName!.trim().isNotEmpty)
                    ? cached.displayName
                    : refreshedUser.displayName);

            final resolvedUser = userModel.copyWith(
              displayName: effectiveName,
              isEmailVerified: refreshedUser.emailVerified,
            );
            await _localDataSource.cacheUser(resolvedUser);
            _emit(resolvedUser);
          } else {
            // Firestore doc missing: self-heal from cached user or auth credentials
            // so we NEVER emit a blank minimal user that wipes identity.
            final effectiveName = (cached != null &&
                    cached.id == refreshedUser.uid &&
                    cached.displayName != null &&
                    cached.displayName!.trim().isNotEmpty)
                ? cached.displayName
                : refreshedUser.displayName;
            final effectiveEmail = (cached != null &&
                    cached.id == refreshedUser.uid &&
                    cached.email.trim().isNotEmpty)
                ? cached.email
                : (refreshedUser.email ?? '');

            final resolvedUser = (cached != null && cached.id == refreshedUser.uid)
                ? cached.copyWith(
                    displayName: effectiveName,
                    isEmailVerified: refreshedUser.emailVerified,
                  )
                : UserModel(
                    id: refreshedUser.uid,
                    email: effectiveEmail,
                    displayName: effectiveName,
                    photoUrl: refreshedUser.photoURL,
                    lastLoginDate: DateTime.now(),
                    currentStreak: 1,
                    isEmailVerified: refreshedUser.emailVerified,
                    dailyXpHistory: const {},
                    recentActivities: const [],
                  );

            try {
              final map = resolvedUser.toMap();
              map['lastRewardTimestamp'] = FieldValue.serverTimestamp();
              await _firestore
                  .collection('users')
                  .doc(resolvedUser.id)
                  .set(map, SetOptions(merge: true));
            } catch (_) {}

            await _localDataSource.cacheUser(resolvedUser);
            _emit(resolvedUser);
          }
        }
      }
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
        return Left(AuthFailure('No authenticated user to delete.'));
      }

      _firestoreSubscription?.cancel();
      _firestoreSubscription = null;
      await _localDataSource.clearCachedUser();

      await user.delete();

      try {
        await _firebaseMessaging.deleteToken();
      } catch (e) {
        _log('DeleteAccount: FCM token deletion failed: $e');
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

  UserModel _minimalUserFrom(firebase_auth.User firebaseUser) {
    return UserModel(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      isEmailVerified: firebaseUser.emailVerified,
      lastDailyRewardDate: DateTime.now(), // Defensively prevents false startup daily reward triggers
      dailyXpHistory: const {},
      recentActivities: const [],
    );
  }

  void _log(String message) {
    if (kDebugMode) debugPrint(message);
  }
}
