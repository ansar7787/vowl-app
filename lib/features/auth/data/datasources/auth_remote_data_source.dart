import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsignin;
import 'package:vowl/features/auth/data/models/user_model.dart';

/// Data source interface handling direct backend network API integrations for authentication.
abstract class AuthRemoteDataSource {
  Future<UserModel> signUp({required String email, required String password});
  Future<UserModel> logInWithEmail({
    required String email,
    required String password,
  });
  Future<void> logInWithGoogle();
  Future<void> logOut();
}

/// Concrete implementation of [AuthRemoteDataSource] utilizing Firebase and Google Sign-in.
///
/// Refactored to allow fully injectable instances of [FirebaseFirestore] for test isolation,
/// and enhanced with robust, non-blocking sign-out sequences.
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

  @override
  Future<UserModel> signUp({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final newUser = UserModel(
      id: credential.user!.uid,
      email: credential.user!.email ?? '',
      isAdmin: false,
      dailyXpHistory: const {},
      recentActivities: const [],
    );

    // Create Firestore document with injected db reference
    await _firestore
        .collection('users')
        .doc(newUser.id)
        .set(newUser.toMap());

    return newUser;
  }

  @override
  Future<UserModel> logInWithEmail({
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return UserModel(
      id: credential.user!.uid,
      email: credential.user!.email ?? '',
      dailyXpHistory: const {},
      recentActivities: const [],
    );
  }

  @override
  Future<void> logInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'aborted-by-user',
        message: 'Google sign in was canceled',
      );
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    final user = userCredential.user;

    if (user != null) {
      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();
      if (!userDoc.exists) {
        final newUser = UserModel(
          id: user.uid,
          email: user.email ?? '',
          displayName: user.displayName,
          photoUrl: user.photoURL,
          isAdmin: false,
          dailyXpHistory: const {},
          recentActivities: const [],
        );
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(newUser.toMap());
      }
    }
  }

  @override
  Future<void> logOut() async {
    // Guarantees non-blocking local session sign out even if network-based provider logout fails
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Silently swallow Google provider clearing faults
    }
    await _firebaseAuth.signOut();
  }
}
