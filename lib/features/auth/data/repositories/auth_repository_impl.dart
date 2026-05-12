import 'package:flutter/foundation.dart';
import 'package:dartz/dartz.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
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
    return _firebaseAuth.userChanges().asyncExpand((firebaseUser) {
      if (firebaseUser == null) {
        return Stream.value(null);
      }
      return _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .snapshots()
          .handleError((error) {
            final errorStr = error.toString();
            if (errorStr.contains('PERMISSION_DENIED') || 
                errorStr.contains('permission-denied')) {
              debugPrint('AuthRepository: Firestore permission denied (expected during logout).');
              return;
            }
            throw error;
          })
          .map((doc) {
        try {
          if (doc.exists && doc.data() != null) {
            final userModel = UserModel.fromMap(doc.data()!);
            return userModel.copyWith(
              isEmailVerified: firebaseUser.emailVerified,
            );
          } else {
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
        } catch (e, stack) {
          debugPrint('Error in AuthRepository.user stream mapping: $e');
          debugPrint(stack.toString());
          return null;
        }
      });
    });
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
        // Update Display Name
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

        // Save to Firestore
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
  Future<Either<Failure, void>> updateUserCoins(
    int amountChange, {
    String? title,
    bool? isEarned,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        final docRef = _firestore.collection('users').doc(user.uid);

        if (title != null) {
          final doc = await docRef.get();
          if (doc.exists && doc.data() != null) {
            final data = doc.data()!;
            List<Map<String, dynamic>> history = [];
            if (data['coinHistory'] != null) {
              history = List<Map<String, dynamic>>.from(data['coinHistory']);
            }

            final entry = {
              'title': title,
              'amount': amountChange,
              'isEarned': isEarned ?? (amountChange > 0),
              'date': DateTime.now().toIso8601String(),
            };

            history.insert(0, entry);
            if (history.length > 10) history.removeLast();

            await docRef.update({
              'coins': FieldValue.increment(amountChange),
              'coinHistory': history,
            });
            return const Right(null);
          }
        }

        // Fallback for simple increment without history
        await docRef.update({'coins': FieldValue.increment(amountChange)});
        return const Right(null);
      } else {
        return Left(AuthFailure('User not logged in'));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateUserRewards({
    required String gameType,
    required int level,
    required int xpIncrease,
    required int coinIncrease,
    bool isDoubleReward = false,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return Left(AuthFailure('User not logged in'));

      final docRef = _firestore.collection('users').doc(user.uid);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        if (!doc.exists || doc.data() == null) {
          throw Exception('User data not found');
        }

        final data = doc.data()!;
        Map<String, int> dailyHistory = {};
        List<Map<String, dynamic>> activities = [];
        Map<String, List<int>> completedLevels = {};
        Map<String, int> unlockedLevels = {};

        if (data['dailyXpHistory'] != null) {
          dailyHistory = Map<String, int>.from(data['dailyXpHistory']);
        }
        if (data['recentActivities'] != null) {
          activities = List<Map<String, dynamic>>.from(
            data['recentActivities'],
          );
        }
        if (data['completedLevels'] != null) {
          completedLevels = (data['completedLevels'] as Map<String, dynamic>)
              .map((key, value) => MapEntry(key, List<int>.from(value)));
        }
        if (data['unlockedLevels'] != null) {
          unlockedLevels = Map<String, int>.from(data['unlockedLevels']);
        }

        // Replay Check (Coin Deflation & 50% XP)
        final categoryCompleted = completedLevels[gameType] ?? [];
        final bool isReplay = categoryCompleted.contains(level);

        // Apply Multipliers
        double xpMultiplier = 1.0;
        if (data['hasPermanentXPBoost'] == true) xpMultiplier *= 1.1;

        final doubleXPExpiry = data['doubleXPExpiry'] != null
            ? (data['doubleXPExpiry'] as Timestamp).toDate()
            : null;
        if (doubleXPExpiry != null &&
            doubleXPExpiry.isAfter(DateTime.now())) {
          xpMultiplier *= 2.0;
        }

        final baseXp = isReplay ? (xpIncrease * 0.5) : xpIncrease;
        final finalXpIncrease = (baseXp * xpMultiplier).round();

        // Mark as Completed if not replay
        if (!isReplay) {
          categoryCompleted.add(level);
          completedLevels[gameType] = categoryCompleted;
        }

        // Update Daily XP
        final now = DateTime.now();
        final todayKey =
            "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
        final currentDaily = dailyHistory[todayKey] ?? 0;
        dailyHistory[todayKey] = currentDaily + finalXpIncrease;

        // Add Activity
        final newActivity = {
          'title': 'Quest Completed',
          'subtitle': '+$finalXpIncrease XP · +$coinIncrease Coins',
          'timestamp': Timestamp.now(),
          'type': 'quest',
        };
        activities.insert(0, newActivity);
        if (activities.length > 10) {
          activities = activities.sublist(0, 10);
        }

        // Apply Multiplier for Premium Users or Level 100+
        int finalCoinIncrease = (isReplay && !isDoubleReward) ? 0 : coinIncrease;
        final userExp = data['totalExp'] as int? ?? 0;
        final userLevel = (userExp / 100).floor() + 1;

        if (!isReplay && (data['isPremium'] == true || userLevel >= 100)) {
          finalCoinIncrease = coinIncrease * 2;
        }

        // Detect if it's a Kids Zone game to update kidsCoins
        final kidsGames = {
          'alphabet', 'numbers', 'colors', 'shapes', 'animals',
          'fruits', 'family', 'school', 'verbs', 'routine',
          'emotions', 'prepositions', 'phonics', 'day_night',
          'nature', 'home_kids', 'food_kids', 'transport',
          'time', 'opposites', 'body', 'clothing',
        };
        final isKidsGame = kidsGames.contains(gameType);

        // Unlock next level if applicable
        final currentUnlocked = unlockedLevels[gameType] ?? 1;
        if (level >= currentUnlocked) {
          unlockedLevels[gameType] = level + 1;
        }

        // Update history list
        List<Map<String, dynamic>> history = [];
        if (data['coinHistory'] != null) {
          history = List<Map<String, dynamic>>.from(data['coinHistory']);
        }

        final entry = {
          'title': 'Quest Reward - ${gameType.toUpperCase()}',
          'amount': finalCoinIncrease,
          'isEarned': true,
          'date': DateTime.now().toIso8601String(),
        };

        history.insert(0, entry);
        if (history.length > 10) history.removeLast();

        transaction.update(docRef, {
          'totalExp': (userExp + finalXpIncrease),
          isKidsGame ? 'kidsCoins' : 'coins': FieldValue.increment(
            finalCoinIncrease,
          ),
          'coinHistory': history,
          'dailyXpHistory': dailyHistory,
          'recentActivities': activities,
          'completedLevels': completedLevels,
          'unlockedLevels': unlockedLevels,
        });
      });

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }


  @override
  Future<Either<Failure, void>> useHint() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        final docRef = _firestore.collection('users').doc(user.uid);
        
        return await _firestore.runTransaction((transaction) async {
          // FORCE server read in transaction
          final snapshot = await transaction.get(docRef);
          if (!snapshot.exists) return Left(ServerFailure('User data not found'));
          
          final hintCount = snapshot.data()?['hintCount'] ?? 0;
          if (hintCount > 0) {
            debugPrint('AuthRepository: Atomic Hint Decrement (Transaction) triggered.');
            transaction.update(docRef, {'hintCount': FieldValue.increment(-1)});
            return const Right(null);
          } else {
            debugPrint('AuthRepository: Hint decrement FAILED: No hints available.');
            return Left(ServerFailure('No hints available'));
          }
        });
      }
      return Left(AuthFailure('User not logged in'));
    } catch (e) {
      debugPrint('AuthRepository: useHint ERROR: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> purchaseHint(int cost, int hintAmount) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        final docRef = _firestore.collection('users').doc(user.uid);
        final doc = await docRef.get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          final coins = data['coins'] ?? 0;
          if (coins >= cost) {
            // Update history list
            List<Map<String, dynamic>> history = [];
            if (data['coinHistory'] != null) {
              history = List<Map<String, dynamic>>.from(data['coinHistory']);
            }

            final entry = {
              'title': 'Purchased Hint Pack',
              'amount': -cost,
              'isEarned': false,
              'date': DateTime.now().toIso8601String(),
            };

            history.insert(0, entry);
            if (history.length > 10) history.removeLast();

            await docRef.update({
              'coins': FieldValue.increment(-cost),
              'hintCount': FieldValue.increment(hintAmount),
              'coinHistory': history,
            });
            return const Right(null);
          } else {
            return Left(ServerFailure('Not enough coins'));
          }
        }
        return Left(ServerFailure('User data not found'));
      }
      return Left(AuthFailure('User not logged in'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateCategoryStats(
    String categoryId,
    bool isCorrect,
  ) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        final docRef = _firestore.collection('users').doc(user.uid);
        final doc = await docRef.get();

        Map<String, int> currentStats = {};
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          if (data['categoryStats'] != null) {
            currentStats = Map<String, int>.from(data['categoryStats']);
          }
        }

        int currentScore = currentStats[categoryId] ?? 50;
        int newScore = isCorrect ? currentScore + 10 : currentScore - 10;
        if (newScore > 100) newScore = 100;
        if (newScore < 0) newScore = 0;

        currentStats[categoryId] = newScore;

        await docRef.update({'categoryStats': currentStats});
        return const Right(null);
      } else {
        return Left(AuthFailure('User not logged in'));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateUnlockedLevel(
    String categoryId,
    int newLevel,
  ) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        final docRef = _firestore.collection('users').doc(user.uid);
        final doc = await docRef.get();

        Map<String, int> unlockedLevels = {};
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          if (data['unlockedLevels'] != null) {
            unlockedLevels = Map<String, int>.from(data['unlockedLevels']);
          }
        }

        final currentUnlocked = unlockedLevels[categoryId] ?? 1;
        if (newLevel > currentUnlocked) {
          unlockedLevels[categoryId] = newLevel;
          await docRef.update({'unlockedLevels': unlockedLevels});
        }
        return const Right(null);
      } else {
        return Left(AuthFailure('User not logged in'));
      }
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<void> awardBadge(String badgeId) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'badges': FieldValue.arrayUnion([badgeId]),
        });
      }
    } catch (e) {
      // Log error or handle as needed
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
  Future<Either<Failure, void>> updateUser(UserEntity user) async {
    try {
      final docRef = _firestore.collection('users').doc(user.id);
      final userModel = UserModel(
        id: user.id,
        email: user.email,
        displayName: user.displayName,
        photoUrl: user.photoUrl,
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
      );

      await docRef.set(userModel.toMap(), SetOptions(merge: true));
      return const Right(null);
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

  @override
  Future<Either<Failure, void>> claimDailyGift() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        final docRef = _firestore.collection('users').doc(user.uid);
        final doc = await docRef.get();

        if (doc.exists && doc.data() != null) {
          final userData = UserModel.fromMap(doc.data()!);

          final now = DateTime.now();
          final lastGift = userData.lastDailyRewardDate;
          final bool available = lastGift == null ||
              lastGift.year != now.year ||
              lastGift.month != now.month ||
              lastGift.day != now.day;

          if (!available) {
            return Left(AuthFailure('Daily gift already claimed today'));
          }

          final reward = 50 + (now.day % 5) * 10; // Varied reward
          await docRef.update({
            'coins': FieldValue.increment(reward),
            'lastDailyRewardDate': Timestamp.now(),
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

  @override
  Future<Either<Failure, String>> updateProfilePicture(String filePath) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return Left(ServerFailure('User not authenticated'));

      final file = File(filePath);
      final ref = _storage.ref().child('profile_pics').child('${user.uid}.jpg');

      // Upload file
      await ref.putFile(file);
      final downloadUrl = await ref.getDownloadURL();

      // Update Firebase Auth
      await user.updatePhotoURL(downloadUrl);

      // Update Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'photoUrl': downloadUrl,
      });

      return Right(downloadUrl);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateDisplayName(String displayName) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) return Left(ServerFailure('User not authenticated'));

      // Update Firebase Auth
      await user.updateDisplayName(displayName);

      // Update Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'displayName': displayName,
      });

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> awardKidsSticker(String stickerId) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'kidsStickers': FieldValue.arrayUnion([stickerId]),
        });
        return const Right(null);
      }
      return Left(AuthFailure('User not logged in'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateKidsMascot(String mascotId) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'kidsMascot': mascotId,
        });
        return const Right(null);
      }
      return Left(AuthFailure('User not logged in'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> buyKidsAccessory(
    String accessoryId,
    int cost,
  ) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        final docRef = _firestore.collection('users').doc(user.uid);
        await _firestore.runTransaction((transaction) async {
          final snapshot = await transaction.get(docRef);
          if (!snapshot.exists) throw Exception("User not found");

          final data = snapshot.data()!;
          final currentCoins = (data['kidsCoins'] as num?)?.toInt() ?? 0;
          final owned = List<String>.from(data['kidsOwnedAccessories'] ?? []);

          if (owned.contains(accessoryId)) {
            // Already owned, skip
            return;
          }

          if (currentCoins < cost) {
            throw Exception("Not enough Kids Coins");
          }

          transaction.update(docRef, {
            'kidsCoins': currentCoins - cost,
            'kidsOwnedAccessories': FieldValue.arrayUnion([accessoryId]),
          });
        });
        return const Right(null);
      }
      return Left(AuthFailure('User not logged in'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> equipKidsAccessory(String? accessoryId) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'kidsEquippedAccessory': accessoryId,
        });
        return const Right(null);
      }
      return Left(AuthFailure('User not logged in'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> repairStreak(int cost) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        final docRef = _firestore.collection('users').doc(user.uid);
        await _firestore.runTransaction((transaction) async {
          final snapshot = await transaction.get(docRef);
          if (!snapshot.exists) throw Exception("User not found");
          final currentCoins =
              (snapshot.data()?['coins'] as num?)?.toInt() ?? 0;
          if (currentCoins < cost) throw Exception("Not enough coins");

          // To repair, we simply set currentStreak back to something meaningful?
          // Actually, the repair happens when they miss a day.
          // For now, let's assume repair sets currentStreak to lastStreak + 1 or similar.
          // But we don't store lastStreak.
          // Simplest repair: If streak is 1 (just reset), set it to something higher?
          // Better logic: The caller provides the new streak value or we just increment it.
          // Let's just deduct coins and let the Bloc handle the entity state update if possible,
          // OR we can do it here if we have enough info.
          // Since we are in a transaction, let's just do the coin deduction and the caller will update the entity.
          // Actually, if we want it to be atomic:
          final history = List<Map<String, dynamic>>.from(
            snapshot.data()?['coinHistory'] ?? [],
          );
          final entry = {
            'title': 'Repaired Streak',
            'amount': -cost,
            'isEarned': false,
            'date': DateTime.now().toIso8601String(),
          };
          history.insert(0, entry);
          if (history.length > 10) history.removeLast();

          transaction.update(docRef, {
            'coins': currentCoins - cost,
            'coinHistory': history,
            // Logic for repair: if they just reset to 1 today, maybe we cannot know what it was.
            // But usually, repair is called immediately after a reset.
          });
        });
        return const Right(null);
      }
      return Left(AuthFailure('User not logged in'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> purchaseStreakFreeze(int cost) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        final docRef = _firestore.collection('users').doc(user.uid);
        await _firestore.runTransaction((transaction) async {
          final doc = await transaction.get(docRef);
          if (!doc.exists || doc.data() == null) {
            throw Exception('User data not found');
          }

          final data = doc.data()!;
          final currentCoins = (data['coins'] as num?)?.toInt() ?? 0;
          if (currentCoins < cost) throw Exception('Not enough coins');

          List<Map<String, dynamic>> history = [];
          if (data['coinHistory'] != null) {
            history = List<Map<String, dynamic>>.from(data['coinHistory']);
          }

          final entry = {
            'title': 'Purchased Streak Freeze',
            'amount': -cost,
            'isEarned': false,
            'date': DateTime.now().toIso8601String(),
          };

          history.insert(0, entry);
          if (history.length > 10) history.removeLast();

          transaction.update(docRef, {
            'coins': currentCoins - cost,
            'streakFreezes': FieldValue.increment(1),
            'coinHistory': history,
          });
        });
        return const Right(null);
      }
      return Left(AuthFailure('User not logged in'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> activateDoubleXP(int cost) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        final docRef = _firestore.collection('users').doc(user.uid);
        await _firestore.runTransaction((transaction) async {
          final doc = await transaction.get(docRef);
          if (!doc.exists || doc.data() == null) {
            throw Exception('User data not found');
          }

          final data = doc.data()!;
          final currentCoins = (data['coins'] as num?)?.toInt() ?? 0;
          if (currentCoins < cost) throw Exception('Not enough coins');

          List<Map<String, dynamic>> history = [];
          if (data['coinHistory'] != null) {
            history = List<Map<String, dynamic>>.from(data['coinHistory']);
          }

          final entry = {
            'title': 'Purchased Double XP',
            'amount': -cost,
            'isEarned': false,
            'date': DateTime.now().toIso8601String(),
          };

          history.insert(0, entry);
          if (history.length > 10) history.removeLast();

          final expiry = DateTime.now().add(const Duration(hours: 24));
          transaction.update(docRef, {
            'coins': currentCoins - cost,
            'doubleXP': 1,
            'doubleXPExpiry': Timestamp.fromDate(expiry),
            'coinHistory': history,
          });
        });
        return const Right(null);
      }
      return Left(AuthFailure('User not logged in'));
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
        // 1. Delete Firestore document first while user still has permissions
        await _firestore.collection('users').doc(uid).delete();

        // 2. Delete Profile Picture from Storage (if it exists)
        try {
          await _storage.ref().child('profile_pics').child('$uid.jpg').delete();
        } catch (e) {
          debugPrint('No profile pic to delete or error: $e');
        }

        // 3. Delete Firebase Auth user last (as this invalidates the token)
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

  @override
  Future<Either<Failure, void>> awardKidsCoins(int amount) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'kidsCoins': FieldValue.increment(amount),
        });
        return const Right(null);
      }
      return Left(AuthFailure('User not logged in'));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> claimDailyChest(int amount) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        final docRef = _firestore.collection('users').doc(user.uid);
        debugPrint('AuthRepository: Atomic Daily Chest (Transaction) triggered for ${user.uid} (Amount: $amount)');
        
        return await _firestore.runTransaction((transaction) async {
          transaction.update(docRef, {
            'coins': FieldValue.increment(amount),
            'lastDailyRewardDate': Timestamp.now(),
          });
          return const Right(null);
        });
      }
      return Left(AuthFailure('User not logged in'));
    } catch (e) {
      debugPrint('AuthRepository: Daily Chest ERROR: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> claimKidsDailyReward(int amount) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user != null) {
        final docRef = _firestore.collection('users').doc(user.uid);
        debugPrint('AuthRepository: Atomic Kids Reward (Transaction) triggered for ${user.uid}');
        
        return await _firestore.runTransaction((transaction) async {
          transaction.update(docRef, {
            'kidsCoins': FieldValue.increment(amount),
            'lastKidsDailyRewardDate': Timestamp.now(),
          });
          return const Right(null);
        });
      }
      return Left(AuthFailure('User not logged in'));
    } catch (e) {
      debugPrint('AuthRepository: Kids Reward ERROR: $e');
      return Left(ServerFailure(e.toString()));
    }
  }
}
