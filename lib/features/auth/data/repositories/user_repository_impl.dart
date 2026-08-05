import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/features/auth/data/models/user_model.dart';
import 'package:vowl/features/auth/data/repositories/firebase_failure_handler_mixin.dart';
import 'package:vowl/features/auth/domain/constants/user_game_constants.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/domain/repositories/user_repository.dart';

/// Concrete implementation of [UserRepository] managing user profile updates,
/// profile picture storage, and VIP daily reward claims.
///
/// ### updateUser note
/// [updateUser] serialises the full [UserEntity] via [UserModel.fromEntity]
/// then [UserModel.toMap], and performs a [SetOptions(merge: true)] write.
/// This means null fields explicitly overwrite the corresponding server
/// values — intended behaviour when the caller provides a complete entity
/// snapshot. For partial field updates prefer the targeted methods
/// ([updateDisplayName], [updateProfilePicture]) which only write the
/// affected fields.
class UserRepositoryImpl
    with FirebaseFailureHandlerMixin
    implements UserRepository {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  UserRepositoryImpl({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance;

  // ---------------------------------------------------------------------------
  // updateUser
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, void>> updateUser(UserEntity user) async {
    try {
      final docRef = _firestore.collection('users').doc(user.id);
      // UserModel.fromEntity is the single source of truth for the
      // entity→model field mapping (see its doc comment) — previously this
      // method hand-listed all ~48 fields itself, which meant a field added
      // to UserEntity in the future could silently never get persisted here
      // unless someone remembered to also update this call site.
      final userModel = UserModel.fromEntity(user);

      await docRef.set(userModel.toMap(), SetOptions(merge: true));
      return const Right(null);
    } catch (e) {
      _log('UserRepository: updateUser failed for ${user.id}: $e');
      return Left(handleFirebaseException(e));
    }
  }

  // ---------------------------------------------------------------------------
  // updateDisplayName
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, void>> updateDisplayName(String displayName) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return Left(ServerFailure('user-not-authenticated'));

      await Future.wait([
        user.updateDisplayName(displayName),
        _firestore.collection('users').doc(user.uid).update({
          'displayName': displayName,
        }),
      ]);

      return const Right(null);
    } catch (e) {
      return Left(handleFirebaseException(e));
    }
  }

  // ---------------------------------------------------------------------------
  // updateProfilePicture
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, String>> updateProfilePicture(String filePath) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return Left(ServerFailure('user-not-authenticated'));

      final file = File(filePath);

      // Deliberately no extension on the storage path: it stays stable
      // (`profile_pics/{uid}`) no matter what format the source image is,
      // so re-uploading a PNG after a JPG (or vice versa) overwrites the
      // same object instead of leaving the old one orphaned in Storage
      // forever. The Content-Type header — which is what actually matters
      // for correct rendering and for any image-processing Storage
      // extension keyed off it — is set explicitly from the source file's
      // real extension via [_contentTypeForPath], instead of relying on
      // Storage's own filename-based guess (which previously always guessed
      // "image/jpeg" because the path itself was hardcoded to end in .jpg,
      // regardless of what the user actually picked).
      final ref = _storage.ref().child('profile_pics').child(user.uid);
      final metadata = SettableMetadata(
        contentType: _contentTypeForPath(filePath),
      );

      await ref.putFile(file, metadata);
      final downloadUrl = await ref.getDownloadURL();

      await Future.wait([
        user.updatePhotoURL(downloadUrl),
        _firestore.collection('users').doc(user.uid).update({
          'photoUrl': downloadUrl,
        }),
      ]);

      return Right(downloadUrl);
    } catch (e) {
      _log('UserRepository: updateProfilePicture failed: $e');
      return Left(handleFirebaseException(e));
    }
  }

  // ---------------------------------------------------------------------------
  // claimVipGift
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, void>> claimVipGift() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return Left(AuthFailure('user-not-logged-in'));

      final docRef = _firestore.collection('users').doc(user.uid);

      return await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists || doc.data() == null) {
          return Left(AuthFailure('user-data-not-found'));
        }

        final userData = UserModel.fromMap(doc.data()!);

        if (!userData.isPremium) {
          _log('UserRepository: claimVipGift rejected — user is not premium.');
          return Left(AuthFailure('user-not-premium'));
        }

        final now = DateTime.now();
        final lastGift = userData.lastVipGiftDate;
        final bool available =
            lastGift == null || !_isSameCalendarDay(lastGift, now);

        if (!available) {
          _log(
            'UserRepository: claimVipGift rejected — already claimed today.',
          );
          return Left(AuthFailure('vip-gift-already-claimed'));
        }

        transaction.update(docRef, {
          'coins': FieldValue.increment(UserGameConstants.kVipDailyGiftReward),
          'coinHistory': _recordCoinHistory(
            _parseMapList(doc.data()!['coinHistory']),
            titleKey: 'coin_history.vip_gift',
            amount: UserGameConstants.kVipDailyGiftReward,
            isEarned: true,
          ),
          'lastVipGiftDate': Timestamp.now(),
        });
        return const Right<Failure, void>(null);
      });
    } catch (e) {
      return Left(handleFirebaseException(e));
    }
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Maps a file's extension to its `Content-Type`, defaulting to
  /// `image/jpeg` for anything unrecognized (profile pictures are always
  /// picked through an image picker/cropper upstream, so an unknown
  /// extension here means "assume a photo," not "reject the upload").
  static const Map<String, String> _kImageContentTypes = {
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'heic': 'image/heic',
    'heif': 'image/heif',
    'webp': 'image/webp',
    'gif': 'image/gif',
  };

  static String _contentTypeForPath(String filePath) {
    final dotIndex = filePath.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == filePath.length - 1) {
      return 'image/jpeg';
    }
    final extension = filePath.substring(dotIndex + 1).toLowerCase();
    return _kImageContentTypes[extension] ?? 'image/jpeg';
  }

  /// True if [a] and [b] fall on the same calendar day (year/month/day) in
  /// local time. Used by the various "claim once per day" guards.
  static bool _isSameCalendarDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Debug-only log helper. Produces no output in release builds.
  void _log(String message) {
    if (kDebugMode) debugPrint(message);
  }

  /// Parses a Firestore list of coin-history entries defensively. Local
  /// counterpart to the equivalent helper in ShopRepositoryImpl — Dart's
  /// per-file privacy means neither can import the other's.
  static List<Map<String, dynamic>> _parseMapList(dynamic raw) {
    if (raw == null) return <Map<String, dynamic>>[];
    return (raw as List<dynamic>)
        .whereType<Map<Object?, Object?>>()
        .map((m) => m.map((k, v) => MapEntry(k.toString(), v)))
        .toList();
  }

  /// Prepends a coin-history entry and trims to the configured retention
  /// limit.
  static List<Map<String, dynamic>> _recordCoinHistory(
    List<Map<String, dynamic>> existing, {
    required String titleKey,
    required int amount,
    required bool isEarned,
  }) {
    final updated = List<Map<String, dynamic>>.from(existing)
      ..insert(0, {
        'titleKey': titleKey,
        'amount': amount,
        'isEarned': isEarned,
        'date': DateTime.now().toIso8601String(),
      });
    if (updated.length > UserGameConstants.kActivityHistoryLimit) {
      return updated.sublist(0, UserGameConstants.kActivityHistoryLimit);
    }
    return updated;
  }
}
