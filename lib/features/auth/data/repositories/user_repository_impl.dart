import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:vowl/core/error/failures.dart';
import 'package:vowl/features/auth/data/models/user_model.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/auth/domain/repositories/user_repository.dart';

class UserRepositoryImpl implements UserRepository {
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
        badges: user.badges,
        streakFreezes: user.streakFreezes,
        hintCount: user.hintCount,
        hintPacks: user.hintPacks,
        doubleXP: user.doubleXP,
        doubleXPExpiry: user.doubleXPExpiry,
        dailyXpHistory: user.dailyXpHistory,
        recentActivities: user.recentActivities,
        completedLevels: user.completedLevels,
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
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateDisplayName(String displayName) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return Left(ServerFailure('User not authenticated'));

      await user.updateDisplayName(displayName);

      await _firestore.collection('users').doc(user.uid).update({
        'displayName': displayName,
      });

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> updateProfilePicture(String filePath) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return Left(ServerFailure('User not authenticated'));

      final file = File(filePath);
      final ref = _storage.ref().child('profile_pics').child('${user.uid}.jpg');

      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();

      await user.updatePhotoURL(downloadUrl);

      await _firestore.collection('users').doc(user.uid).update({
        'photoUrl': downloadUrl,
      });

      return Right(downloadUrl);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> claimVipGift() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        final docRef = _firestore.collection('users').doc(user.uid);
        final doc = await docRef.get();

        if (doc.exists && doc.data() != null) {
          final userData = UserModel.fromMap(doc.data()!);

          if (!userData.isPremium) {
            return Left(AuthFailure('User is not premium'));
          }

          await docRef.update({
            'coins': FieldValue.increment(100),
            'lastVipGiftDate': Timestamp.now(),
          });
          return const Right(null);
        }
        return Left(AuthFailure('User data not found'));
      } else {
        return Left(AuthFailure('User not logged in'));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
