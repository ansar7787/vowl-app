import 'package:vowl/features/auth/data/datasources/auth_local_data_source.dart';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/core/utils/coin_ledger_helper.dart';
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
  final AuthLocalDataSource _localDataSource;

  /// Creates a [UserRepositoryImpl] instance with optional Firebase overrides.
  UserRepositoryImpl({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    AuthLocalDataSource? localDataSource,
  }) : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _storage = storage ?? FirebaseStorage.instance,
       _localDataSource = localDataSource ?? AuthLocalDataSourceImpl();

  // ---------------------------------------------------------------------------
  // updateUser
  // ---------------------------------------------------------------------------

  @override
  Future<Either<Failure, void>> updateUser(UserEntity user) async {
    try {
      final effectiveUid = user.id.trim().isNotEmpty
          ? user.id.trim()
          : _firebaseAuth.currentUser?.uid;
      if (effectiveUid == null || effectiveUid.isEmpty) {
        return Left(ServerFailure('user-not-authenticated'));
      }
      final docRef = _firestore.collection('users').doc(effectiveUid);
      final userModel = UserModel.fromEntity(user);
      final newMap = userModel.toMap();

      // Differential update: Determine exactly which fields changed
      // compared to the cached local profile (or existing server document).
      // Writing all ~48 fields unconditionally trips strict Firestore security
      // rules (rate limits, key limits, duel stats, VIP guards) even when only
      // benign fields (streak, lastLoginDate, mascot, accessories) are updated.
      final cachedUser = await _localDataSource.getCachedUser();
      Map<String, dynamic>? oldMap = cachedUser?.toMap();

      if (oldMap == null) {
        try {
          final snapshot = await docRef.get(
            const GetOptions(source: Source.serverAndCache),
          );
          if (snapshot.exists && snapshot.data() != null) {
            oldMap = snapshot.data();
          }
        } catch (_) {}
      }

      final Map<String, dynamic> updatePayload = {};
      if (oldMap != null) {
        for (final entry in newMap.entries) {
          final key = entry.key;
          final newVal = entry.value;
          final oldVal = oldMap[key];

          // Preserve active device FCM push token when merging domain entities
          // where fcmToken was not tracked in memory.
          if (key == 'fcmToken' && newVal == null) {
            continue;
          }

          if (!_areValuesEqual(newVal, oldVal)) {
            updatePayload[key] = newVal;
          }
        }
      } else {
        updatePayload.addAll(newMap);
        if (updatePayload['fcmToken'] == null) {
          updatePayload.remove('fcmToken');
        }
      }

      // If no fields actually changed, complete immediately and update local cache.
      if (updatePayload.isEmpty) {
        await _localDataSource.cacheUser(userModel);
        return const Right(null);
      }

      // Only stamp `lastRewardTimestamp` if totalExp or coins actually changed
      if (updatePayload.containsKey('totalExp') ||
          updatePayload.containsKey('coins')) {
        updatePayload['lastRewardTimestamp'] = FieldValue.serverTimestamp();
      }

      await docRef.set(updatePayload, SetOptions(merge: true));
      await _localDataSource.cacheUser(userModel);
      return const Right(null);
    } catch (e) {
      _log('UserRepository: updateUser failed for ${user.id}: $e');
      return Left(handleFirebaseException(e));
    }
  }

  static bool _areValuesEqual(dynamic a, dynamic b) {
    if (identical(a, b)) return true;
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a is Timestamp && b is Timestamp) {
      return a == b;
    }
    if (a is DateTime && b is DateTime) {
      return a.isAtSameMomentAs(b);
    }
    if (a is Timestamp && b is DateTime) {
      return a.toDate().isAtSameMomentAs(b);
    }
    if (a is DateTime && b is Timestamp) {
      return a.isAtSameMomentAs(b.toDate());
    }
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (int i = 0; i < a.length; i++) {
        if (!_areValuesEqual(a[i], b[i])) return false;
      }
      return true;
    }
    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final key in a.keys) {
        if (!b.containsKey(key)) return false;
        if (!_areValuesEqual(a[key], b[key])) return false;
      }
      return true;
    }
    return a == b;
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

        final userData = UserModel.fromMap(doc.data()!, doc.id);

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
          'lastRewardTimestamp': FieldValue.serverTimestamp(),
          'coinHistory': CoinLedgerHelper.recordEntry(
            CoinLedgerHelper.parseMapList(doc.data()!['coinHistory']),
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
  /// local time. Normalizes both instances with `.toLocal()` to prevent
  /// time-zone skew between UTC timestamps and device local time around midnight.
  static bool _isSameCalendarDay(DateTime a, DateTime b) {
    final la = a.toLocal();
    final lb = b.toLocal();
    return la.year == lb.year && la.month == lb.month && la.day == lb.day;
  }

  /// Debug-only log helper. Produces no output in release builds.
  void _log(String message) {
    if (kDebugMode) debugPrint(message);
  }
}
