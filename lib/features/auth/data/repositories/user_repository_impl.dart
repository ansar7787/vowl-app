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
/// [updateUser] serialises the full [UserEntity] via [UserModel.toMap] and
/// performs a [SetOptions(merge: true)] write. This means null fields explicitly
/// overwrite the corresponding server values — intended behaviour when the
/// caller provides a complete entity snapshot. For partial field updates prefer
/// the targeted methods ([updateDisplayName], [updateProfilePicture]) which only
/// write the affected fields.
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
      final userModel = UserModel(
        id: user.id,
        email: user.email,
        displayName: user.displayName,
        photoUrl: user.photoUrl,
        fcmToken: user.fcmToken,
        coins: user.coins,
        totalExp: user.totalExp,
        isAdmin: user.isAdmin,
        currentStreak: user.currentStreak,
        lastLoginDate: user.lastLoginDate,
        isEmailVerified: user.isEmailVerified,
        isPremium: user.isPremium,
        premiumExpiryDate: user.premiumExpiryDate,
        categoryStats: user.categoryStats,
        unlockedLevels: user.unlockedLevels,
        completedLevels: user.completedLevels,
        badges: user.badges,
        streakFreezes: user.streakFreezes,
        hintCount: user.hintCount,
        hintPacks: user.hintPacks,
        doubleXP: user.doubleXP,
        doubleXPExpiry: user.doubleXPExpiry,
        dailyXpHistory: user.dailyXpHistory,
        recentActivities: user.recentActivities,
        lastVipGiftDate: user.lastVipGiftDate,
        lastDailyRewardDate: user.lastDailyRewardDate,
        lastKidsDailyRewardDate: user.lastKidsDailyRewardDate,
        kidsCoins: user.kidsCoins,
        kidsStickers: user.kidsStickers,
        kidsMascot: user.kidsMascot,
        kidsEquippedSticker: user.kidsEquippedSticker,
        kidsOwnedAccessories: user.kidsOwnedAccessories,
        kidsEquippedAccessory: user.kidsEquippedAccessory,
        kidsOwnedFurniture: user.kidsOwnedFurniture,
        kidsEquippedFurniture: user.kidsEquippedFurniture,
        vowlMascot: user.vowlMascot,
        vowlEquippedAccessory: user.vowlEquippedAccessory,
        vowlOwnedAccessories: user.vowlOwnedAccessories,
        vowlOwnedMascots: user.vowlOwnedMascots,
        claimedStreakMilestones: user.claimedStreakMilestones,
        claimedLevelMilestones: user.claimedLevelMilestones,
        coinHistory: user.coinHistory,
        hasPermanentXPBoost: user.hasPermanentXPBoost,
        lastFreeSpinDate: user.lastFreeSpinDate,
        lastAdSpinDate: user.lastAdSpinDate,
        adSpinsUsedToday: user.adSpinsUsedToday,
      );

      await docRef.set(userModel.toMap(), SetOptions(merge: true));
      return const Right(null);
    } catch (e) {
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
      if (user == null) return Left(ServerFailure('User not authenticated'));

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
      if (user == null) return Left(ServerFailure('User not authenticated'));

      final file = File(filePath);
      final ref = _storage.ref().child('profile_pics').child('${user.uid}.jpg');

      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();

      await Future.wait([
        user.updatePhotoURL(downloadUrl),
        _firestore.collection('users').doc(user.uid).update({
          'photoUrl': downloadUrl,
        }),
      ]);

      return Right(downloadUrl);
    } catch (e) {
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
      if (user == null) return Left(AuthFailure('User not logged in'));

      final docRef = _firestore.collection('users').doc(user.uid);

      return await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists || doc.data() == null) {
          return Left(AuthFailure('User data not found'));
        }

        final userData = UserModel.fromMap(doc.data()!);

        if (!userData.isPremium) {
          return Left(AuthFailure('User is not premium'));
        }

        final now = DateTime.now();
        final lastGift = userData.lastVipGiftDate;
        final bool available =
            lastGift == null ||
            lastGift.year != now.year ||
            lastGift.month != now.month ||
            lastGift.day != now.day;

        if (!available) {
          return Left(AuthFailure('Daily VIP gift already claimed today'));
        }

        transaction.update(docRef, {
          'coins': FieldValue.increment(UserGameConstants.kVipDailyGiftReward),
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

  // Retained for future use; production logging should be routed through an
  // injected Logger rather than debugPrint.
  // ignore: unused_element
  void _log(String message) {
    if (kDebugMode) debugPrint(message);
  }
}
