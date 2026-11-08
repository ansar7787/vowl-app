import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:vowl/features/auth/domain/constants/user_game_constants.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/arena/data/services/arena_curriculum_engine.dart';
import 'package:vowl/features/arena/data/utils/arena_ai_difficulty_engine.dart';
import 'package:vowl/features/arena/domain/entities/arena_duel_session.dart';
import 'package:vowl/features/arena/domain/repositories/arena_repository.dart';

class _ActiveQueueSearch {
  final String userId;
  final String roomCode;
  final Completer<ArenaDuelSession?> completer;
  StreamSubscription? subscription;
  bool isCanceled = false;

  _ActiveQueueSearch({
    required this.userId,
    required this.roomCode,
    required this.completer,
  });
}

class MatchmakingCanceledException implements Exception {
  final String message;
  const MatchmakingCanceledException([
    this.message = 'Matchmaking cancelled by user',
  ]);

  @override
  String toString() => message;
}

class ArenaRepositoryImpl implements ArenaRepository {
  final FirebaseFirestore _firestore;
  int _sessionConsecutiveWins = 0;
  final Map<String, _ActiveQueueSearch> _activeSearches = {};

  static const Duration _kNetworkTimeout = Duration(seconds: 10);
  static const int _kStakeCoins = 30;
  static const int _kWinnerPayout = 50;
  static const int _kLoserPayout = 10;

  ArenaRepositoryImpl([FirebaseFirestore? firestore])
    : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> cancelMatchmaking({required String userId}) async {
    final search = _activeSearches.remove(userId);
    if (search != null) {
      search.isCanceled = true;
      try {
        await search.subscription?.cancel();
      } catch (_) {}
      if (!search.completer.isCompleted) {
        search.completer.complete(null);
      }
    }
    try {
      await _firestore
          .collection('arena_queue')
          .doc(userId)
          .delete()
          .timeout(const Duration(seconds: 3));
    } catch (_) {}
  }

  @override
  Future<ArenaDuelSession> quickMatch({required UserEntity currentUser}) async {
    // 0. Ensure any stale or orphaned queue state for this user from an interrupted session is purged
    await cancelMatchmaking(userId: currentUser.id);

    // 1. Deduct entry stake (30 coins)
    await _deductEntryStake(currentUser.id);

    try {
      final seed = DateTime.now().millisecondsSinceEpoch;
      final questions =
          await ArenaCurriculumEngine.generateProgressiveQuestionsAsync(
            seed: seed,
          );

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
          final isStale =
              createdAt != null &&
              DateTime.now().difference(createdAt).inSeconds > 15;

          if (isStale) {
            // Delete stale/abandoned queue ticket to keep collection clean
            await queueRef.doc(oppDoc.id).delete();
          } else {
            final oppId = oppData['userId'] as String;
            final oppName = oppData['displayName'] as String? ?? 'Challenger';
            final oppPhoto = oppData['photoUrl'] as String?;
            final roomCode =
                oppData['roomCode'] as String? ??
                'VOWL-DUEL-${(Random().nextInt(900) + 100)}';

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

            await _firestore
                .collection('arena_rooms')
                .doc(roomCode)
                .set({
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
                })
                .timeout(_kNetworkTimeout);

            return session;
          }
        }

        // B. No human waiting: register ticket and listen for real opponent
        final myRoomCode =
            'VOWL-DUEL-${(Random.secure().nextInt(900000) + 100000)}';
        final myTicketRef = queueRef.doc(currentUser.id);
        final completer = Completer<ArenaDuelSession?>();

        final search = _ActiveQueueSearch(
          userId: currentUser.id,
          roomCode: myRoomCode,
          completer: completer,
        );
        _activeSearches[currentUser.id] = search;

        await myTicketRef.set({
          'userId': currentUser.id,
          'displayName': currentUser.safeDisplayName,
          'photoUrl': currentUser.photoUrl,
          'roomCode': myRoomCode,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (search.isCanceled) {
          await myTicketRef.delete().catchError((_) {});
          _activeSearches.remove(currentUser.id);
          throw const MatchmakingCanceledException();
        }

        final sub = _firestore
            .collection('arena_rooms')
            .doc(myRoomCode)
            .snapshots()
            .listen((snap) {
              if (search.isCanceled) return;
              if (snap.exists && snap.data()?['guestId'] != null) {
                if (!completer.isCompleted) {
                  completer.complete(_mapSession(myRoomCode, snap.data()!));
                }
              }
            });
        search.subscription = sub;

        ArenaDuelSession? liveMatched;
        try {
          // Real-world queue wait: Listen for up to 8 seconds for a real human player
          liveMatched = await completer.future.timeout(
            const Duration(seconds: 8),
          );
        } catch (_) {
          // 8-second timeout or cancelled early
        } finally {
          await sub.cancel();
          _activeSearches.remove(currentUser.id);
          try {
            await myTicketRef.delete();
          } catch (_) {}
        }

        if (search.isCanceled) {
          throw const MatchmakingCanceledException();
        }

        if (liveMatched != null) {
          return liveMatched;
        }
      } catch (e) {
        if (e is MatchmakingCanceledException) rethrow;
        // Fall through to calibrated Computer/AI opponent
      }

      // Check if user cancelled while in between checks
      final active = _activeSearches[currentUser.id];
      if (active != null && active.isCanceled) {
        throw const MatchmakingCanceledException();
      }

      // 3. Fallback: If no real human player queued within 8s, match with calibrated Computer/AI
      // via 3-Pillar Skill-Based Matchmaking (Career Win Rate + Level + Session Streak).
      final aiOpponent = ArenaAiOpponent.forPlayer(
        currentUser,
        consecutiveWins: _sessionConsecutiveWins,
      );
      final roomCode = 'VOWL-AI-${(Random().nextInt(900) + 100)}';

      return ArenaDuelSession(
        roomCode: roomCode,
        hostId: currentUser.id,
        hostName: currentUser.safeDisplayName,
        hostPhotoUrl: currentUser.photoUrl,
        guestId: aiOpponent.id,
        guestName: aiOpponent.displayName,
        guestPhotoUrl: null,
        stake: _kStakeCoins,
        pot: _kStakeCoins * 2,
        status: 'in_progress',
        isGhostRival: true,
        ghostAccuracy: aiOpponent.accuracy,
        questions: questions,
        createdAt: DateTime.now(),
      );
    } on MatchmakingCanceledException {
      // User explicitly cancelled - stake refund is handled by caller (ArenaMatchmakingScreen)
      rethrow;
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
      final questions =
          await ArenaCurriculumEngine.generateProgressiveQuestionsAsync(
            seed: seed,
          );
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
      final questions =
          await ArenaCurriculumEngine.generateProgressiveQuestionsAsync(
            seed: seed,
          );

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

      await _firestore
          .collection('arena_rooms')
          .doc(roomCode)
          .set({
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
          })
          .timeout(_kNetworkTimeout);

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

    if (data['status'] != 'waiting') {
      throw Exception('This duel room is no longer accepting challengers.');
    }

    if (data['guestId'] != null && data['guestId'] != currentUser.id) {
      throw Exception('This duel room is already full.');
    }

    await _deductEntryStake(currentUser.id);

    try {
      await docRef
          .update({
            'guestId': currentUser.id,
            'guestName': currentUser.safeDisplayName,
            'guestPhotoUrl': currentUser.photoUrl,
            'status': 'in_progress',
          })
          .timeout(_kNetworkTimeout);

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
    final cleanCode = roomCode.trim().toUpperCase();
    if (cleanCode.startsWith('VOWL-AI-') || cleanCode.startsWith('VOWL-RIVAL-')) {
      return;
    }

    try {
      final docRef = _firestore.collection('arena_rooms').doc(cleanCode);
      await docRef.update({
        isHost ? 'hostScore' : 'guestScore': score,
        'lastHeartbeat': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Silently catch for ghost/offline matches
    }
  }

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

  @override
  Future<void> completeMatch({
    required String roomCode,
    required UserEntity currentUser,
    required bool isWinner,
    required bool isDraw,
    bool isPerfect = false,
  }) async {
    if (isWinner) {
      _sessionConsecutiveWins++;
    } else if (!isDraw) {
      _sessionConsecutiveWins = 0;
    }

    final int payout;
    final String titleKey;
    if (isDraw) {
      payout = _kStakeCoins; // 30 back to each
      titleKey = 'coin_history.arena_duel_refund';
    } else if (isWinner) {
      payout = isPerfect
          ? (_kWinnerPayout + 10)
          : _kWinnerPayout; // 60 if 5/5 perfect, 50 if win
      titleKey = isPerfect
          ? 'coin_history.arena_duel_perfect'
          : 'coin_history.arena_duel_win';
    } else {
      payout = _kLoserPayout; // 10 to loser
      titleKey = 'coin_history.arena_duel_consolation';
    }

    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.id)
          .get()
          .timeout(_kNetworkTimeout);
      final rawHistory =
          (userDoc.data()?['coinHistory'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [];
      final updatedHistory = _recordCoinHistory(
        rawHistory,
        titleKey: titleKey,
        amount: payout,
        isEarned: true,
      );

      // Wire duel XP into recentActivities so it appears in Adventure XP screen
      final rawActivities =
          (userDoc.data()?['recentActivities'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [];
      if (isWinner) {
        rawActivities.insert(0, <String, dynamic>{
          'titleKey': 'activity.quest_completed',
          'gameType': 'arenaDuel',
          'xpEarned': 5,
          'coinsEarned': payout,
          'timestamp': Timestamp.now(),
          'type': 'quest',
        });
      }
      final updatedActivities =
          rawActivities.length > UserGameConstants.kActivityHistoryLimit
          ? rawActivities.sublist(0, UserGameConstants.kActivityHistoryLimit)
          : rawActivities;

      // Wire duel XP into dailyXpHistory so the Adventure XP chart reflects today's XP
      Map<String, int>? updatedDailyXpHistory;
      if (isWinner) {
        final rawDailyXp = Map<String, int>.from(
          (userDoc.data()?['dailyXpHistory'] as Map?)?.cast<String, int>() ??
              {},
        );
        final now = DateTime.now();
        final todayKey =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
        rawDailyXp[todayKey] = (rawDailyXp[todayKey] ?? 0) + 5;
        if (rawDailyXp.length > UserGameConstants.kDailyXpHistoryLimit) {
          final sortedKeys = rawDailyXp.keys.toList()..sort();
          final toRemove =
              sortedKeys.length - UserGameConstants.kDailyXpHistoryLimit;
          for (var i = 0; i < toRemove; i++) {
            rawDailyXp.remove(sortedKeys[i]);
          }
        }
        updatedDailyXpHistory = rawDailyXp;
      }

      // Update user profile in Firestore
      final userRef = _firestore.collection('users').doc(currentUser.id);
      await userRef.update({
        'coins': FieldValue.increment(payout),
        if (isWinner)
          'totalExp': FieldValue.increment(5), // +5 XP TO DUEL WINNER
        if (isWinner) 'duelWins': FieldValue.increment(1),
        if (!isWinner && !isDraw) 'duelLosses': FieldValue.increment(1),
        'dailyDuelsPlayedToday': FieldValue.increment(1),
        'coinHistory': updatedHistory,
        'recentActivities': updatedActivities,
        ...updatedDailyXpHistory != null
            ? {'dailyXpHistory': updatedDailyXpHistory}
            : <String, dynamic>{},
        'lastDuelDate': FieldValue.serverTimestamp(),
        'lastRewardTimestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[ArenaRepositoryImpl] completeMatch user update error: $e');
    }

    final cleanCode = roomCode.trim().toUpperCase();
    if (!cleanCode.startsWith('VOWL-AI-') &&
        !cleanCode.startsWith('VOWL-RIVAL-')) {
      try {
        final docRef = _firestore.collection('arena_rooms').doc(cleanCode);
        await docRef.update({
          'status': 'completed',
          if (isWinner) 'winnerId': currentUser.id,
        });
      } catch (_) {}
    }
  }

  @override
  Future<void> forfeitMatch({
    required String roomCode,
    required String userId,
  }) async {
    _sessionConsecutiveWins = 0;
    final cleanCode = roomCode.trim().toUpperCase();
    if (cleanCode.startsWith('VOWL-AI-') || cleanCode.startsWith('VOWL-RIVAL-')) {
      return;
    }

    try {
      final docRef = _firestore.collection('arena_rooms').doc(cleanCode);
      final snap = await docRef.get().timeout(_kNetworkTimeout);
      if (snap.exists) {
        final data = snap.data();
        final status = data?['status'] as String?;
        final guestId = data?['guestId'] as String?;
        final hostId = data?['hostId'] as String?;

        // If room is still waiting and no opponent joined yet, dissolve room and refund the host
        if (status == 'waiting' && (guestId == null || guestId.isEmpty)) {
          await docRef.delete().timeout(_kNetworkTimeout);
          if (hostId == userId) {
            await _refundEntryStake(userId);
          }
          return;
        }

        await docRef.update({'status': 'abandoned'}).timeout(_kNetworkTimeout);
      }
    } catch (_) {}
  }

  Future<void> _deductEntryStake(String userId) async {
    try {
      await _firestore
          .runTransaction((transaction) async {
            final userDocRef = _firestore.collection('users').doc(userId);
            final userDoc = await transaction.get(userDocRef);
            final currentCoins =
                (userDoc.data()?['coins'] as num?)?.toInt() ?? 0;
            if (currentCoins < _kStakeCoins) {
              throw Exception('Insufficient coins for duel stake.');
            }
            final rawHistory =
                (userDoc.data()?['coinHistory'] as List<dynamic>?)
                    ?.map((e) => Map<String, dynamic>.from(e as Map))
                    .toList() ??
                [];
            final updatedHistory = _recordCoinHistory(
              rawHistory,
              titleKey: 'coin_history.arena_duel_stake',
              amount: -_kStakeCoins,
              isEarned: false,
            );
            transaction.update(userDocRef, {
              'coins': FieldValue.increment(-_kStakeCoins),
              'coinHistory': updatedHistory,
            });
          })
          .timeout(_kNetworkTimeout);
    } catch (e) {
      debugPrint('[ArenaRepositoryImpl] Deduct stake error: $e');
      rethrow;
    }
  }

  @override
  Future<void> refundStake({required String userId}) async {
    await _refundEntryStake(userId);
  }

  Future<void> _refundEntryStake(String userId) async {
    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get()
          .timeout(_kNetworkTimeout);
      final rawHistory =
          (userDoc.data()?['coinHistory'] as List<dynamic>?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [];
      final updatedHistory = _recordCoinHistory(
        rawHistory,
        titleKey: 'coin_history.arena_duel_refund',
        amount: _kStakeCoins,
        isEarned: true,
      );
      await _firestore
          .collection('users')
          .doc(userId)
          .update({
            'coins': FieldValue.increment(_kStakeCoins),
            'coinHistory': updatedHistory,
            'lastRewardTimestamp': FieldValue.serverTimestamp(),
          })
          .timeout(_kNetworkTimeout);
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
