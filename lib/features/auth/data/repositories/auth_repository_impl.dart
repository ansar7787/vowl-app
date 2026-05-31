import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:vowl/features/auth/data/models/user_model.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _remoteDataSource = remoteDataSource,
       _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  @override
  Stream<UserEntity?> get user {
    late StreamController<UserEntity?> controller;
    StreamSubscription<firebase_auth.User?>? authSubscription;
    StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? firestoreSubscription;

    void cancelFirestore() {
      firestoreSubscription?.cancel();
      firestoreSubscription = null;
    }

    controller = StreamController<UserEntity?>.broadcast(
      onListen: () {
        authSubscription = _firebaseAuth.userChanges().listen(
          (firebaseUser) {
            cancelFirestore();

            if (firebaseUser == null) {
              controller.add(null);
              return;
            }

            firestoreSubscription = _firestore
                .collection('users')
                .doc(firebaseUser.uid)
                .snapshots()
                .listen(
              (doc) {
                try {
                  if (doc.exists && doc.data() != null) {
                    final userModel = UserModel.fromMap(doc.data()!);
                    controller.add(
                      userModel.copyWith(
                        isEmailVerified: firebaseUser.emailVerified,
                      ),
                    );
                  } else {
                    controller.add(
                      UserModel(
                        id: firebaseUser.uid,
                        email: firebaseUser.email ?? '',
                        displayName: firebaseUser.displayName,
                        photoUrl: firebaseUser.photoURL,
                        isEmailVerified: firebaseUser.emailVerified,
                        dailyXpHistory: const {},
                        recentActivities: const [],
                      ),
                    );
                  }
                } catch (e, stack) {
                  debugPrint('Error in AuthRepository.user stream mapping: $e');
                  debugPrint(stack.toString());
                  controller.add(null);
                }
              },
              onError: (error) {
                final errorStr = error.toString();
                if (errorStr.contains('PERMISSION_DENIED') ||
                    errorStr.contains('permission-denied')) {
                  debugPrint(
                    'AuthRepository: Firestore permission denied (expected during logout).',
                  );
                  controller.add(null);
                  return;
                }
                controller.addError(error);
              },
            );
          },
          onError: (error) {
            controller.addError(error);
          },
        );
      },
      onCancel: () {
        cancelFirestore();
        authSubscription?.cancel();
      },
    );

    return controller.stream;
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      final user = await _mapFirebaseUserToUserEntity(firebaseUser);
      return Right(user);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  Future<UserEntity?> _mapFirebaseUserToUserEntity(
    firebase_auth.User? firebaseUser,
  ) async {
    if (firebaseUser == null) return null;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get(const GetOptions(source: Source.server));
      if (doc.exists) {
        final user = UserModel.fromMap(doc.data()!);
        return user.copyWith(isEmailVerified: firebaseUser.emailVerified);
      } else {
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
        await _firestore
            .collection('users')
            .doc(newUser.id)
            .set(newUser.toMap());
        return newUser;
      }
    } catch (e, stack) {
      debugPrint('Error in _mapFirebaseUserToUserEntity: $e');
      debugPrint(stack.toString());
      return null;
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        await firebaseUser.updateDisplayName(name);

        final newUser = UserModel(
          id: firebaseUser.uid,
          email: email,
          displayName: name,
          photoUrl: firebaseUser.photoURL,
          lastLoginDate: DateTime.now(),
          currentStreak: 1,
          dailyXpHistory: const {},
          recentActivities: const [],
        );

        await _firestore
            .collection('users')
            .doc(newUser.id)
            .set(newUser.toMap());

        return Right(newUser);
      } else {
        return Left(ServerFailure('User creation failed'));
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(AuthFailure(e.code));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
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
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(AuthFailure(e.code));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logInWithGoogle() async {
    try {
      await _remoteDataSource.logInWithGoogle();
      return const Right(null);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(AuthFailure(e.code));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> logOut() async {
    try {
      await _remoteDataSource.logOut();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return const Right(null);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(AuthFailure(e.code));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> sendEmailVerification() async {
    try {
      await _firebaseAuth.currentUser?.sendEmailVerification();
      return const Right(null);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(AuthFailure(e.code));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> reloadUser() async {
    try {
      await _firebaseAuth.currentUser?.reload();
      return const Right(null);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Left(AuthFailure(e.code));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        final uid = user.uid;
        await _firestore.collection('users').doc(uid).delete();

        try {
          await _storage.ref().child('profile_pics').child('$uid.jpg').delete();
        } catch (e) {
          debugPrint('No profile pic to delete or error: $e');
        }

        await user.delete();
        
        return const Right(null);
      }
      return Left(AuthFailure('User not logged in'));
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return Left(AuthFailure('requires-recent-login'));
      }
      return Left(AuthFailure(e.code));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
