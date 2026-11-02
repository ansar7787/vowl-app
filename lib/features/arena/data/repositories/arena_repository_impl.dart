import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:vowl/features/auth/data/models/user_model.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/arena/data/utils/arena_question_generator.dart';
import 'package:vowl/features/arena/domain/entities/arena_duel_session.dart';
import 'package:vowl/features/arena/domain/repositories/arena_repository.dart';

class ArenaRepositoryImpl implements ArenaRepository {
  final FirebaseFirestore _firestore;

  static const Duration _kNetworkTimeout = Duration(seconds: 10);
  static const int _kStakeCoins = 30;
  static const int _kWinnerPayout = 50;
  static const int _kLoserPayout = 10;

  ArenaRepositoryImpl([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<ArenaDuelSession> quickMatch({
    required UserEntity currentUser,
    required List<UserEntity> leaderboardUsers,
  }) async {
    // 1. Deduct entry stake (30 coins)
    await _deductEntryStake(currentUser.id);

    try {
      final seed = DateTime.now().millisecondsSinceEpoch;
      final questions = await ArenaQuestionGenerator.generateQuestionsAsync(seed: seed);

      try {
        final queueRef = _firestore.collection('arena_queue');

        // A. Check if a human challenger is already waiting in queue
        final activeQueue = await queueRef
            .where('userId', isNotEqualTo: currentUser.id)
            .limit(1)
            .get()
            .timeout(const Duration(seconds: 2));

        if (activeQueue.docs.isNotEmpty) {
          final oppDoc = activeQueue.docs.first;
          final oppData = oppDoc.data();
          final createdAt = (oppData['createdAt'] as Timestamp?)?.toDate();
          final isStale = createdAt != null &&
              DateTime.now().difference(createdAt).inSeconds > 15;

          if (isStale) {
            // Delete stale/abandoned queue ticket to keep collection clean
            await queueRef.doc(oppDoc.id).delete();
          } else {
            final oppId = oppData['userId'] as String;
            final oppName = oppData['displayName'] as String? ?? 'Challenger';
            final oppPhoto = oppData['photoUrl'] as String?;
            final roomCode = oppData['roomCode'] as String? ?? 'VOWL-DUEL-${(Random().nextInt(900) + 100)}';

            // Delete from queue and form live room
            await queueRef.doc(oppDoc.id).delete();

            final session = ArenaDuelSession(
              roomCode: roomCode,
              hostId: oppId,
              hostName: oppName,
              hostPhotoUrl: oppPhoto,
              guestId: currentUser.id,
              guestName: currentUser.safeDisplayName,
              guestPhotoUrl: currentUser.photoUrl,
              stake: _kStakeCoins,
              pot: _kStakeCoins * 2,
              status: 'in_progress',
              questions: questions,
              createdAt: DateTime.now(),
            );

            await _firestore.collection('arena_rooms').doc(roomCode).set({
              'roomCode': roomCode,
              'hostId': oppId,
              'hostName': oppName,
              'hostPhotoUrl': oppPhoto,
              'guestId': currentUser.id,
              'guestName': currentUser.safeDisplayName,
              'guestPhotoUrl': currentUser.photoUrl,
              'stake': _kStakeCoins,
              'pot': _kStakeCoins * 2,
              'status': 'in_progress',
              'hostScore': 0,
              'guestScore': 0,
              'questions': questions.map((q) => q.toMap()).toList(),
              'createdAt': FieldValue.serverTimestamp(),
            }).timeout(_kNetworkTimeout);

            return session;
          }
        } else {
          // B. No human waiting: register ticket and listen for 3s
          final myRoomCode = 'VOWL-DUEL-${(Random().nextInt(900) + 100)}';
          final myTicketRef = queueRef.doc(currentUser.id);
          await myTicketRef.set({
            'userId': currentUser.id,
            'displayName': currentUser.safeDisplayName,
            'photoUrl': currentUser.photoUrl,
            'roomCode': myRoomCode,
            'createdAt': FieldValue.serverTimestamp(),
          });

          final completer = Completer<ArenaDuelSession?>();
          final sub = _firestore
              .collection('arena_rooms')
              .doc(myRoomCode)
              .snapshots()
              .listen((snap) {
            if (snap.exists && snap.data()?['guestId'] != null) {
              if (!completer.isCompleted) {
                completer.complete(_mapSession(myRoomCode, snap.data()!));
              }
            }
          });

          ArenaDuelSession? liveMatched;
          try {
            liveMatched = await completer.future.timeout(const Duration(seconds: 3));
          } catch (_) {
            // 3-second timeout: no human joined
          } finally {
            await sub.cancel();
            try {
              await myTicketRef.delete();
            } catch (_) {}
          }

          if (liveMatched != null) {
            return liveMatched;
          }
        }
      } catch (_) {
        // Fall through to 3-second smart fallback
      }

      // 3. Fallback: Select real player from Leaderboard as Ghost Rival (0s wait time!)
      var candidates = leaderboardUsers.where((u) => u.id != currentUser.id).toList();
      if (candidates.isEmpty) {
        try {
          final cacheDoc = await _firestore.collection('leaderboard_cache').doc('global').get();
          final rawUsers = cacheDoc.data()?['users'];
          if (cacheDoc.exists && rawUsers is List) {
            final list = rawUsers
                .whereType<Map>()
                .map((u) => UserModel.fromMap(Map<String, dynamic>.from(u)))
                .where((u) => u.id.isNotEmpty && u.id != currentUser.id)
                .toList();
            if (list.isNotEmpty) candidates = list;
          }
        } catch (_) {}
      }

      final rival = candidates.isNotEmpty
          ? candidates[Random().nextInt(candidates.length)]
          : null;

      final rivalName = rival?.safeDisplayName ?? 'Global Challenger';
      final rivalPhoto = rival?.photoUrl;
      final rivalRank = (rival != null && candidates.isNotEmpty)
          ? candidates.indexOf(rival) + 1
          : 10;
      final accuracy = (0.90 - (rivalRank * 0.01)).clamp(0.65, 0.95);

      final roomCode = 'VOWL-GHOST-${(Random().nextInt(900) + 100)}';
      return ArenaDuelSession(
        roomCode: roomCode,
        hostId: currentUser.id,
        hostName: currentUser.safeDisplayName,
        hostPhotoUrl: currentUser.photoUrl,
        guestId: rival?.id ?? 'ghost_challenger',
        guestName: rivalName,
        guestPhotoUrl: rivalPhoto,
        stake: _kStakeCoins,
        pot: _kStakeCoins * 2,
        status: 'in_progress',
        isGhostRival: true,
        ghostAccuracy: accuracy,
        questions: questions,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      await _refundEntryStake(currentUser.id);
      rethrow;
    }
  }

  @override
  Future<ArenaDuelSession> challengeRivalDirectly({
    required UserEntity currentUser,
    required UserEntity rival,
    required int rivalRank,
  }) async {
    await _deductEntryStake(currentUser.id);

    try {
      final seed = DateTime.now().millisecondsSinceEpoch;
      final questions = await ArenaQuestionGenerator.generateQuestionsAsync(seed: seed);
      final accuracy = (0.95 - (rivalRank * 0.015)).clamp(0.65, 0.95);

      final roomCode = 'VOWL-RIVAL-${(Random().nextInt(900) + 100)}';
      return ArenaDuelSession(
        roomCode: roomCode,
        hostId: currentUser.id,
        hostName: currentUser.safeDisplayName,
        hostPhotoUrl: currentUser.photoUrl,
        guestId: rival.id,
        guestName: rival.safeDisplayName,
        guestPhotoUrl: rival.photoUrl,
        stake: _kStakeCoins,
        pot: _kStakeCoins * 2,
        status: 'in_progress',
        isGhostRival: true,
        ghostAccuracy: accuracy,
        questions: questions,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      await _refundEntryStake(currentUser.id);
      rethrow;
    }
  }

  @override
  Future<ArenaDuelSession> createRoomCode({
    required UserEntity currentUser,
  }) async {
    await _deductEntryStake(currentUser.id);

    try {
      final roomCode = 'VOWL-DUEL-${(Random().nextInt(900) + 100)}';
      final seed = DateTime.now().millisecondsSinceEpoch;
      final questions = await ArenaQuestionGenerator.generateQuestionsAsync(seed: seed);

      final session = ArenaDuelSession(
        roomCode: roomCode,
        hostId: currentUser.id,
        hostName: currentUser.safeDisplayName,
        hostPhotoUrl: currentUser.photoUrl,
        stake: _kStakeCoins,
        pot: _kStakeCoins * 2,
        status: 'waiting',
        questions: questions,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('arena_rooms').doc(roomCode).set({
        'roomCode': roomCode,
        'hostId': currentUser.id,
        'hostName': currentUser.safeDisplayName,
        'hostPhotoUrl': currentUser.photoUrl,
        'stake': _kStakeCoins,
        'pot': _kStakeCoins * 2,
        'status': 'waiting',
        'hostScore': 0,
        'guestScore': 0,
        'questions': questions.map((q) => q.toMap()).toList(),
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(_kNetworkTimeout);

      return session;
    } catch (e) {
      await _refundEntryStake(currentUser.id);
      rethrow;
    }
  }

  @override
  Future<ArenaDuelSession> joinRoom({
    required String roomCode,
    required UserEntity currentUser,
  }) async {
    final cleanCode = roomCode.trim().toUpperCase();
    final docRef = _firestore.collection('arena_rooms').doc(cleanCode);
    final snapshot = await docRef.get().timeout(_kNetworkTimeout);

    if (!snapshot.exists || snapshot.data() == null) {
      throw Exception('Duel room $cleanCode not found.');
    }

    final data = snapshot.data()!;
    final hostId = data['hostId'] as String;

    if (hostId == currentUser.id) {
      // Re-joining own room
      return _mapSession(cleanCode, data);
    }

    if (data['guestId'] != null && data['guestId'] != currentUser.id) {
      throw Exception('This duel room is already full.');
    }

    await _deductEntryStake(currentUser.id);

    try {
      await docRef.update({
        'guestId': currentUser.id,
        'guestName': currentUser.safeDisplayName,
        'guestPhotoUrl': currentUser.photoUrl,
        'status': 'in_progress',
      }).timeout(_kNetworkTimeout);

      final updatedSnap = await docRef.get();
      return _mapSession(cleanCode, updatedSnap.data()!);
    } catch (e) {
      await _refundEntryStake(currentUser.id);
      rethrow;
    }
  }

  @override
  Stream<ArenaDuelSession> listenToRoom(String roomCode) {
    return _firestore
        .collection('arena_rooms')
        .doc(roomCode.trim().toUpperCase())
        .snapshots()
        .where((snap) => snap.exists && snap.data() != null)
        .map((snap) => _mapSession(snap.id, snap.data()!));
  }

  @override
  Future<void> submitScore({
    required String roomCode,
    required String userId,
    required int score,
    required bool isHost,
  }) async {
    try {
      final docRef = _firestore.collection('arena_rooms').doc(roomCode.trim().toUpperCase());
      await docRef.update({
        isHost ? 'hostScore' : 'guestScore': score,
        'lastHeartbeat': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Silently catch for ghost/offline matches
    }
  }

  @override
  Future<void> completeMatch({
    required String roomCode,
    required UserEntity currentUser,
    required bool isWinner,
    required bool isDraw,
  }) async {
    final int payout;
    if (isDraw) {
      payout = _kStakeCoins; // 30 back to each
    } else if (isWinner) {
      payout = _kWinnerPayout; // 50 to winner
    } else {
      payout = _kLoserPayout; // 10 to loser
    }

    // Update user profile in Firestore
    final userRef = _firestore.collection('users').doc(currentUser.id);
    await userRef.update({
      'coins': FieldValue.increment(payout),
      if (isWinner) 'duelWins': FieldValue.increment(1),
      if (!isWinner && !isDraw) 'duelLosses': FieldValue.increment(1),
      'dailyDuelsPlayedToday': FieldValue.increment(1),
      'lastDuelDate': FieldValue.serverTimestamp(),
      'lastRewardTimestamp': FieldValue.serverTimestamp(),
    });

    try {
      final docRef = _firestore.collection('arena_rooms').doc(roomCode.trim().toUpperCase());
      await docRef.update({
        'status': 'completed',
        if (isWinner) 'winnerId': currentUser.id,
      });
    } catch (_) {}
  }

  @override
  Future<void> forfeitMatch({
    required String roomCode,
    required String userId,
  }) async {
    try {
      final docRef = _firestore.collection('arena_rooms').doc(roomCode.trim().toUpperCase());
      await docRef.update({
        'status': 'abandoned',
      });
    } catch (_) {}
  }

  Future<void> _deductEntryStake(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get().timeout(_kNetworkTimeout);
      final currentCoins = (userDoc.data()?['coins'] as num?)?.toInt() ?? 0;
      if (currentCoins < _kStakeCoins) {
        throw Exception('Insufficient coins for duel stake.');
      }
      await _firestore.collection('users').doc(userId).update({
        'coins': FieldValue.increment(-_kStakeCoins),
      }).timeout(_kNetworkTimeout);
    } catch (e) {
      debugPrint('[ArenaRepositoryImpl] Deduct stake error: $e');
      rethrow;
    }
  }

  Future<void> _refundEntryStake(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'coins': FieldValue.increment(_kStakeCoins),
      }).timeout(_kNetworkTimeout);
    } catch (e) {
      debugPrint('[ArenaRepositoryImpl] Refund stake error: $e');
    }
  }

  ArenaDuelSession _mapSession(String roomCode, Map<String, dynamic> data) {
    final rawQuestions = (data['questions'] as List<dynamic>?) ?? [];
    final questions = rawQuestions
        .map((q) => ArenaQuestion.fromMap(Map<String, dynamic>.from(q as Map)))
        .toList();

    return ArenaDuelSession(
      roomCode: roomCode,
      hostId: data['hostId'] as String? ?? '',
      hostName: data['hostName'] as String? ?? 'Host',
      hostPhotoUrl: data['hostPhotoUrl'] as String?,
      guestId: data['guestId'] as String?,
      guestName: data['guestName'] as String?,
      guestPhotoUrl: data['guestPhotoUrl'] as String?,
      stake: (data['stake'] as num?)?.toInt() ?? _kStakeCoins,
      pot: (data['pot'] as num?)?.toInt() ?? (_kStakeCoins * 2),
      status: data['status'] as String? ?? 'in_progress',
      hostScore: (data['hostScore'] as num?)?.toInt() ?? 0,
      guestScore: (data['guestScore'] as num?)?.toInt() ?? 0,
      winnerId: data['winnerId'] as String?,
      questions: questions,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastHeartbeat: (data['lastHeartbeat'] as Timestamp?)?.toDate(),
    );
  }
}

