import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsignin;
import 'package:vowl/features/auth/data/models/user_model.dart';

/// Data source interface handling direct backend network API integrations for
/// authentication.
///
/// All methods throw raw [FirebaseAuthException] or [FirebaseException] on
/// failure; translation into typed [Failure] domain objects is the
/// responsibility of the repository layer.
abstract class AuthRemoteDataSource {
  /// Creates a new Firebase Auth account, sets the display name, and
  /// provisions the initial Firestore user document.
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
  });

  /// Signs in with email/password and returns the **full** user profile
  /// fetched from Firestore (not just the auth credential fields).
  Future<UserModel> logInWithEmail({
    required String email,
    required String password,
  });

  /// Initiates a Google Sign-In flow and provisions a Firestore document for
  /// first-time Google users.
  Future<void> logInWithGoogle();

  /// Signs out from Firebase Auth and, best-effort, from the Google provider.
  Future<void> logOut();
}

/// Concrete implementation of [AuthRemoteDataSource] utilizing Firebase Auth,
/// Firestore, and Google Sign-In.
///
/// All dependencies are fully injectable for test isolation.
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth;
  final gsignin.GoogleSignIn _googleSignIn;
  final FirebaseFirestore _firestore;

  AuthRemoteDataSourceImpl({
    FirebaseAuth? firebaseAuth,
    gsignin.GoogleSignIn? googleSignIn,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _googleSignIn = googleSignIn ?? gsignin.GoogleSignIn(),
       _firestore = firestore ?? FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // signUp
  // ---------------------------------------------------------------------------

  @override
  Future<UserModel> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final firebaseUser = credential.user!;

    // Persist the display name in Firebase Auth for downstream consumers
    // (e.g., profile screens that read from FirebaseAuth.currentUser).
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

    await _firestore.collection('users').doc(newUser.id).set(newUser.toMap());

    return newUser;
  }

  // ---------------------------------------------------------------------------
  // logInWithEmail
  // ---------------------------------------------------------------------------

  @override
  Future<UserModel> logInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final firebaseUser = credential.user!;

    // Fetch the full Firestore profile so the caller receives real user data
    // (coins, XP, streak, etc.) immediately — not just the auth credential
    // fields. The real-time stream will keep it current afterwards.
    try {
      final doc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(
          doc.data()!,
        ).copyWith(isEmailVerified: firebaseUser.emailVerified);
      }
    } catch (e) {
      // If the Firestore fetch fails (e.g., offline), fall through to the
      // minimal model. The persistent stream in AuthRepositoryImpl will
      // deliver the full profile once connectivity is restored.
      if (kDebugMode) {
        debugPrint(
          'AuthRemoteDataSource: Firestore fetch after email login failed: $e',
        );
      }
    }

    // Fallback: return a minimal model built from auth credentials only.
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

  // ---------------------------------------------------------------------------
  // logInWithGoogle
  // ---------------------------------------------------------------------------

  @override
  Future<void> logInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'aborted-by-user',
        message: 'Google sign-in was cancelled by the user.',
      );
    }

    final googleAuth = await googleUser.authentication;

    // accessToken is not guaranteed on all platforms (notably iOS can return
    // null). idToken alone is sufficient for Firebase credential creation when
    // accessToken is absent.
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken, // may be null — Firebase handles it
      idToken: googleAuth.idToken,
    );

    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    final user = userCredential.user;

    if (user != null) {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (!userDoc.exists) {
        final newUser = UserModel(
          id: user.uid,
          email: user.email ?? '',
          displayName: user.displayName,
          photoUrl: user.photoURL,
          isAdmin: false,
          lastLoginDate: DateTime.now(),
          currentStreak: 1,
          dailyXpHistory: const {},
          recentActivities: const [],
        );
        await _firestore.collection('users').doc(user.uid).set(newUser.toMap());
      }
    }
  }

  // ---------------------------------------------------------------------------
  // logOut
  // ---------------------------------------------------------------------------

  @override
  Future<void> logOut() async {
    // Best-effort: clear the Google provider session. This can fail when the
    // user originally signed in via email/password (no Google session exists)
    // or when the device is offline.
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'AuthRemoteDataSource: Google sign-out failed (non-critical): $e',
        );
      }
    }

    // Firebase Auth sign-out must always succeed; propagate any exception.
    await _firebaseAuth.signOut();
  }
}
