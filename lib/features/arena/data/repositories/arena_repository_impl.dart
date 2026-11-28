import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:vowl/core/utils/coin_ledger_helper.dart';
import 'package:vowl/features/arena/data/services/arena_curriculum_engine.dart';
import 'package:vowl/features/arena/data/utils/arena_ai_difficulty_engine.dart';
import 'package:vowl/features/arena/domain/entities/arena_challenge.dart';
import 'package:vowl/features/arena/domain/entities/arena_duel_session.dart';
import 'package:vowl/features/arena/domain/entities/arena_match_record.dart';
import 'package:vowl/features/arena/domain/repositories/arena_repository.dart';
import 'package:vowl/features/auth/domain/constants/user_game_constants.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

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
  final Random _secureRandom;
  int _sessionConsecutiveWins = 0;
  final Map<String, _ActiveQueueSearch> _activeSearches = {};

  static const Duration _kNetworkTimeout = Duration(seconds: 10);
  static const int _kMaxRoomCodeAttempts = 5;
  static const int _kStakeCoins = 30;
  static const int _kWinnerPayout = 50;
  static const int _kLoserPayout = 10;
  static const int _kMaxMatchHistoryCount = 50;

  ArenaRepositoryImpl([FirebaseFirestore? firestore, Random? secureRandom])
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _secureRandom = secureRandom ?? Random.secure();

  String _generateRoomCode([String prefix = 'VOWL-DUEL']) {
    final code = _secureRandom.nextInt(900000) + 100000;
    return '$prefix-$code';
  }

  int _virtualWinsForAiTier(ArenaAiDifficultyTier tier) {
    switch (tier) {
      case ArenaAiDifficultyTier.easy:
        return 2;
      case ArenaAiDifficultyTier.medium:
        return 8;
      case ArenaAiDifficultyTier.hard:
        return 20;
    }
  }

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
    // 0. Ensure any stale or orphaned queue state for this user is purged
    await cancelMatchmaking(userId: currentUser.id);

    // 1. Deduct entry stake (30 coins)
    await _deductEntryStake(currentUser.id);

    try {
      final seed = DateTime.now().millisecondsSinceEpoch;
      final challenges = await ArenaCurriculumEngine.generateHybridPentathlon(
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
            await queueRef.doc(oppDoc.id).delete();
          } else {
            final oppId = oppData['userId'] as String;
            final oppName = oppData['displayName'] as String? ?? 'Challenger';
            final oppPhoto = oppData['photoUrl'] as String?;
            final oppWins = (oppData['duelWins'] as num?)?.toInt() ?? 0;
            final roomCode =
                oppData['roomCode'] as String? ?? _generateRoomCode();

            bool claimed = false;
            try {
              await _firestore.runTransaction((tx) async {
                final freshSnap = await tx.get(queueRef.doc(oppDoc.id));
                if (freshSnap.exists) {
                  tx.delete(queueRef.doc(oppDoc.id));
                  claimed = true;
                }
              }).timeout(const Duration(seconds: 3));
            } catch (_) {
              claimed = false;
            }

            if (claimed) {
              final session = ArenaDuelSession(
                roomCode: roomCode,
                hostId: oppId,
                hostName: oppName,
                hostPhotoUrl: oppPhoto,
                guestId: currentUser.id,
                guestName: currentUser.safeDisplayName,
                guestPhotoUrl: currentUser.photoUrl,
                hostDuelWins: oppWins,
                guestDuelWins: currentUser.duelWins,
                stake: _kStakeCoins,
                pot: _kStakeCoins * 2,
                status: 'in_progress',
                challenges: challenges,
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
                    'hostDuelWins': oppWins,
                    'guestId': currentUser.id,
                    'guestName': currentUser.safeDisplayName,
                    'guestPhotoUrl': currentUser.photoUrl,
                    'guestDuelWins': currentUser.duelWins,
                    'stake': _kStakeCoins,
                    'pot': _kStakeCoins * 2,
                    'status': 'in_progress',
                    'hostScore': 0,
                    'guestScore': 0,
                    'hostCorrectCount': 0,
                    'guestCorrectCount': 0,
                    'hostTotalTimeMs': 0,
                    'guestTotalTimeMs': 0,
                    'challenges': challenges.map((c) => c.toMap()).toList(),
                    'createdAt': FieldValue.serverTimestamp(),
                  })
                  .timeout(_kNetworkTimeout);

              return session;
            }
          }
        }

        // B. No human waiting: register ticket and listen for real opponent
        final myRoomCode = _generateRoomCode();
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
          'duelWins': currentUser.duelWins,
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

      final active = _activeSearches[currentUser.id];
      if (active != null && active.isCanceled) {
        throw const MatchmakingCanceledException();
      }

      // 3. Fallback: calibrated Computer/AI opponent via 3-Pillar SBMM
      final aiOpponent = ArenaAiOpponent.forPlayer(
        currentUser,
        consecutiveWins: _sessionConsecutiveWins,
      );
      final roomCode = _generateRoomCode('VOWL-AI');

      return ArenaDuelSession(
        roomCode: roomCode,
        hostId: currentUser.id,
        hostName: currentUser.safeDisplayName,
        hostPhotoUrl: currentUser.photoUrl,
        guestId: aiOpponent.id,
        guestName: aiOpponent.displayName,
        guestPhotoUrl: null,
        hostDuelWins: currentUser.duelWins,
        guestDuelWins: _virtualWinsForAiTier(aiOpponent.tier),
        stake: _kStakeCoins,
        pot: _kStakeCoins * 2,
        status: 'in_progress',
        isGhostRival: true,
        ghostAccuracy: aiOpponent.accuracy,
        challenges: challenges,
        createdAt: DateTime.now(),
      );
    } on MatchmakingCanceledException {
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
      final challenges = await ArenaCurriculumEngine.generateHybridPentathlon(
        seed: seed,
      );
      final accuracy = (0.95 - (rivalRank * 0.015)).clamp(0.65, 0.95);

      final roomCode = _generateRoomCode('VOWL-RIVAL');
      return ArenaDuelSession(
        roomCode: roomCode,
        hostId: currentUser.id,
        hostName: currentUser.safeDisplayName,
        hostPhotoUrl: currentUser.photoUrl,
        guestId: rival.id,
        guestName: rival.safeDisplayName,
        guestPhotoUrl: rival.photoUrl,
        hostDuelWins: currentUser.duelWins,
        guestDuelWins: rival.duelWins,
        stake: _kStakeCoins,
        pot: _kStakeCoins * 2,
        status: 'in_progress',
        isGhostRival: true,
        ghostAccuracy: accuracy,
        challenges: challenges,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      await _refundEntryStake(currentUser.id);
      rethrow;
    }
  }

  @override
  Future<ArenaDuelSession> rematchGhostAi({
    required UserEntity currentUser,
    required String previousGuestId,
    required String previousGuestName,
    String? previousGuestPhotoUrl,
    required double previousAccuracy,
    int previousOpponentDuelWins = 0,
  }) async {
    await _deductEntryStake(currentUser.id);

    try {
      final seed = DateTime.now().millisecondsSinceEpoch;
      final challenges = await ArenaCurriculumEngine.generateHybridPentathlon(
        seed: seed,
      );
      final prefix = previousGuestId.startsWith('computer_')
          ? 'VOWL-AI'
          : 'VOWL-RIVAL';
      final roomCode = _generateRoomCode(prefix);

      return ArenaDuelSession(
        roomCode: roomCode,
        hostId: currentUser.id,
        hostName: currentUser.safeDisplayName,
        hostPhotoUrl: currentUser.photoUrl,
        guestId: previousGuestId,
        guestName: previousGuestName,
        guestPhotoUrl: previousGuestPhotoUrl,
        hostDuelWins: currentUser.duelWins,
        guestDuelWins: previousOpponentDuelWins,
        stake: _kStakeCoins,
        pot: _kStakeCoins * 2,
        status: 'in_progress',
        isGhostRival: true,
        ghostAccuracy: previousAccuracy,
        challenges: challenges,
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
      final seed = DateTime.now().millisecondsSinceEpoch;
      final challenges = await ArenaCurriculumEngine.generateHybridPentathlon(
        seed: seed,
      );
      final challengeMaps = challenges.map((c) => c.toMap()).toList();

      String? allocatedRoomCode;
      for (var attempt = 0; attempt < _kMaxRoomCodeAttempts; attempt++) {
        final candidate = _generateRoomCode();
        final docRef = _firestore.collection('arena_rooms').doc(candidate);

        final created = await _firestore
            .runTransaction<bool>((tx) async {
              final existing = await tx.get(docRef);
              if (existing.exists) {
                return false;
              }
              tx.set(docRef, {
                'roomCode': candidate,
                'hostId': currentUser.id,
                'hostName': currentUser.safeDisplayName,
                'hostPhotoUrl': currentUser.photoUrl,
                'hostDuelWins': currentUser.duelWins,
                'stake': _kStakeCoins,
                'pot': _kStakeCoins * 2,
                'status': 'waiting',
                'hostScore': 0,
                'guestScore': 0,
                'hostCorrectCount': 0,
                'guestCorrectCount': 0,
                'hostTotalTimeMs': 0,
                'guestTotalTimeMs': 0,
                'challenges': challengeMaps,
                'createdAt': FieldValue.serverTimestamp(),
              });
              return true;
            })
            .timeout(_kNetworkTimeout);

        if (created) {
          allocatedRoomCode = candidate;
          break;
        }
      }

      if (allocatedRoomCode == null) {
        throw Exception(
          'Could not generate a unique room code. Please try again.',
        );
      }

      return ArenaDuelSession(
        roomCode: allocatedRoomCode,
        hostId: currentUser.id,
        hostName: currentUser.safeDisplayName,
        hostPhotoUrl: currentUser.photoUrl,
        hostDuelWins: currentUser.duelWins,
        stake: _kStakeCoins,
        pot: _kStakeCoins * 2,
        status: 'waiting',
        challenges: challenges,
        createdAt: DateTime.now(),
      );
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
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(docRef);
        if (!snap.exists || snap.data() == null) {
          throw Exception('Duel room $cleanCode not found.');
        }
        final roomData = snap.data()!;
        if (roomData['status'] != 'waiting' ||
            (roomData['guestId'] != null &&
                roomData['guestId'] != currentUser.id)) {
          throw Exception('This duel room is already full.');
        }
        tx.update(docRef, {
          'guestId': currentUser.id,
          'guestName': currentUser.safeDisplayName,
          'guestPhotoUrl': currentUser.photoUrl,
          'guestDuelWins': currentUser.duelWins,
          'status': 'in_progress',
        });
      }).timeout(_kNetworkTimeout);

      final updatedSnap = await docRef.get().timeout(_kNetworkTimeout);
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
    int correctCount = 0,
    int totalTimeMs = 0,
    bool finished = false,
  }) async {
    final cleanCode = roomCode.trim().toUpperCase();
    if (cleanCode.startsWith('VOWL-AI-') ||
        cleanCode.startsWith('VOWL-RIVAL-')) {
      return;
    }

    try {
      final docRef = _firestore.collection('arena_rooms').doc(cleanCode);
      await docRef.update({
        isHost ? 'hostScore' : 'guestScore': score,
        isHost ? 'hostCorrectCount' : 'guestCorrectCount': correctCount,
        isHost ? 'hostTotalTimeMs' : 'guestTotalTimeMs': totalTimeMs,
        if (finished) (isHost ? 'hostFinished' : 'guestFinished'): true,
        'lastHeartbeat': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Silently catch for ghost/offline matches
    }
  }

  @override
  Future<void> updateTypingProgress({
    required String roomCode,
    required String userId,
    required int charactersTyped,
    int roundIndex = 0,
  }) async {
    final cleanCode = roomCode.trim().toUpperCase();
    if (cleanCode.startsWith('VOWL-AI-') ||
        cleanCode.startsWith('VOWL-RIVAL-') ||
        userId.isEmpty) {
      return;
    }
    try {
      await _firestore
          .collection('arena_rooms')
          .doc(cleanCode)
          .collection('liveProgress')
          .doc(userId)
          .set({
            'charactersTyped': charactersTyped,
            'roundIndex': roundIndex,
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (_) {}
  }

  @override
  Stream<int> listenToRivalTypingProgress({
    required String roomCode,
    required String rivalId,
    int? roundIndex,
  }) {
    final cleanCode = roomCode.trim().toUpperCase();
    if (cleanCode.startsWith('VOWL-AI-') ||
        cleanCode.startsWith('VOWL-RIVAL-') ||
        rivalId.isEmpty) {
      return const Stream.empty();
    }
    return _firestore
        .collection('arena_rooms')
        .doc(cleanCode)
        .collection('liveProgress')
        .doc(rivalId)
        .snapshots()
        .map((snap) {
          if (!snap.exists || snap.data() == null) return 0;
          final data = snap.data()!;
          if (roundIndex != null) {
            final docRound = (data['roundIndex'] as num?)?.toInt();
            if (docRound != roundIndex) return 0;
          }
          return (data['charactersTyped'] as num?)?.toInt() ?? 0;
        });
  }

  DocumentReference<Map<String, dynamic>> _rematchDocRef(String roomCode) {
    return _firestore
        .collection('arena_rooms')
        .doc(roomCode.trim().toUpperCase())
        .collection('rematch')
        .doc('request');
  }

  @override
  Future<void> sendRematchRequest({
    required String roomCode,
    required String requesterId,
    required String requesterName,
  }) async {
    final cleanCode = roomCode.trim().toUpperCase();
    final rematchRef = _rematchDocRef(cleanCode);
    final origRoomRef = _firestore.collection('arena_rooms').doc(cleanCode);

    // Pre-generate hybrid challenges outside transaction cleanly
    final seed = DateTime.now().millisecondsSinceEpoch;
    final challenges = await ArenaCurriculumEngine.generateHybridPentathlon(
      seed: seed,
    );
    final challengeMaps = challenges.map((c) => c.toMap()).toList();
    final candidateNewRoomCode = _generateRoomCode();

    await _firestore.runTransaction((tx) async {
      final existing = await tx.get(rematchRef);
      if (existing.exists && existing.data() != null) {
        final data = existing.data()!;
        final status = data['status'] as String?;
        final existingRequesterId = data['requesterId'] as String?;

        // Mutual simultaneous tap race condition → auto-accept!
        if (status == 'pending' &&
            existingRequesterId != null &&
            existingRequesterId != requesterId) {
          final origSnap = await tx.get(origRoomRef);
          if (origSnap.exists && origSnap.data() != null) {
            final orig = origSnap.data()!;
            final newRoomRef =
                _firestore.collection('arena_rooms').doc(candidateNewRoomCode);
            tx.set(newRoomRef, {
              'roomCode': candidateNewRoomCode,
              'rematchFromRoomCode': cleanCode,
              'hostId': orig['hostId'],
              'hostName': orig['hostName'],
              'hostPhotoUrl': orig['hostPhotoUrl'],
              'hostDuelWins': orig['hostDuelWins'] ?? 0,
              'guestId': orig['guestId'],
              'guestName': orig['guestName'],
              'guestPhotoUrl': orig['guestPhotoUrl'],
              'guestDuelWins': orig['guestDuelWins'] ?? 0,
              'stake': _kStakeCoins,
              'pot': _kStakeCoins * 2,
              'status': 'in_progress',
              'hostScore': 0,
              'guestScore': 0,
              'hostCorrectCount': 0,
              'guestCorrectCount': 0,
              'hostTotalTimeMs': 0,
              'guestTotalTimeMs': 0,
              'hostFinished': false,
              'guestFinished': false,
              'challenges': challengeMaps,
              'createdAt': FieldValue.serverTimestamp(),
            });
            tx.update(rematchRef, {
              'status': 'accepted',
              'newRoomCode': candidateNewRoomCode,
              'acceptedBy': requesterId,
            });
            return;
          }
        }
      }

      tx.set(rematchRef, {
        'requesterId': requesterId,
        'requesterName': requesterName,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }).timeout(_kNetworkTimeout);
  }

  @override
  Stream<Map<String, dynamic>> listenToRematchRequest({
    required String roomCode,
  }) {
    final cleanCode = roomCode.trim().toUpperCase();
    if (cleanCode.startsWith('VOWL-AI-') ||
        cleanCode.startsWith('VOWL-RIVAL-')) {
      return const Stream.empty();
    }
    return _rematchDocRef(cleanCode)
        .snapshots()
        .where((snap) => snap.exists && snap.data() != null)
        .map((snap) => snap.data()!);
  }

  @override
  Future<ArenaDuelSession> acceptRematch({
    required String originalRoomCode,
    required UserEntity currentUser,
  }) async {
    final cleanOrigCode = originalRoomCode.trim().toUpperCase();
    final origSnap = await _firestore
        .collection('arena_rooms')
        .doc(cleanOrigCode)
        .get()
        .timeout(_kNetworkTimeout);
    if (!origSnap.exists || origSnap.data() == null) {
      throw Exception('Original duel room not found.');
    }

    await _deductEntryStake(currentUser.id);

    try {
      final orig = origSnap.data()!;
      final seed = DateTime.now().millisecondsSinceEpoch;
      final challenges = await ArenaCurriculumEngine.generateHybridPentathlon(
        seed: seed,
      );
      final challengeMaps = challenges.map((c) => c.toMap()).toList();
      final newRoomCode = _generateRoomCode();

      final newRoomRef = _firestore.collection('arena_rooms').doc(newRoomCode);
      final rematchRef = _rematchDocRef(cleanOrigCode);

      await _firestore.runTransaction((tx) async {
        final rematchSnap = await tx.get(rematchRef);
        final existingNewCode =
            rematchSnap.data()?['newRoomCode'] as String?;
        if (rematchSnap.exists &&
            rematchSnap.data()?['status'] == 'accepted' &&
            existingNewCode != null &&
            existingNewCode.isNotEmpty) {
          // Room already auto-created via simultaneous accept
          return;
        }

        tx.set(newRoomRef, {
          'roomCode': newRoomCode,
          'rematchFromRoomCode': cleanOrigCode,
          'hostId': orig['hostId'],
          'hostName': orig['hostName'],
          'hostPhotoUrl': orig['hostPhotoUrl'],
          'hostDuelWins': orig['hostDuelWins'] ?? 0,
          'guestId': orig['guestId'],
          'guestName': orig['guestName'],
          'guestPhotoUrl': orig['guestPhotoUrl'],
          'guestDuelWins': orig['guestDuelWins'] ?? 0,
          'stake': _kStakeCoins,
          'pot': _kStakeCoins * 2,
          'status': 'in_progress',
          'hostScore': 0,
          'guestScore': 0,
          'hostCorrectCount': 0,
          'guestCorrectCount': 0,
          'hostTotalTimeMs': 0,
          'guestTotalTimeMs': 0,
          'hostFinished': false,
          'guestFinished': false,
          'challenges': challengeMaps,
          'createdAt': FieldValue.serverTimestamp(),
        });

        tx.set(rematchRef, {
          'status': 'accepted',
          'newRoomCode': newRoomCode,
          'acceptedBy': currentUser.id,
        }, SetOptions(merge: true));
      }).timeout(_kNetworkTimeout);

      // Re-fetch rematch request to guarantee exact winning room code
      final finalRematch = await rematchRef.get().timeout(_kNetworkTimeout);
      final winningCode =
          (finalRematch.data()?['newRoomCode'] as String?) ?? newRoomCode;
      final createdRoomSnap = await _firestore
          .collection('arena_rooms')
          .doc(winningCode)
          .get()
          .timeout(_kNetworkTimeout);
      return _mapSession(winningCode, createdRoomSnap.data()!);
    } catch (e) {
      await _refundEntryStake(currentUser.id);
      rethrow;
    }
  }

  @override
  Future<ArenaDuelSession> enterAcceptedRematch({
    required String newRoomCode,
    required UserEntity currentUser,
  }) async {
    final cleanCode = newRoomCode.trim().toUpperCase();
    await _deductEntryStake(currentUser.id);
    try {
      final snap = await _firestore
          .collection('arena_rooms')
          .doc(cleanCode)
          .get()
          .timeout(_kNetworkTimeout);
      if (!snap.exists || snap.data() == null) {
        throw Exception('Rematch room $cleanCode not found.');
      }
      return _mapSession(cleanCode, snap.data()!);
    } catch (e) {
      await _refundEntryStake(currentUser.id);
      rethrow;
    }
  }

  @override
  Future<void> declineRematch({required String roomCode}) async {
    try {
      await _rematchDocRef(roomCode).set({
        'status': 'declined',
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  @override
  Future<void> writeMatchHistory({
    required String userId,
    required ArenaMatchRecord record,
  }) async {
    if (userId.isEmpty) return;
    try {
      final historyColl = _firestore
          .collection('users')
          .doc(userId)
          .collection('arena_match_history');
      final newDocRef = historyColl.doc(record.id);

      // Fetch existing records ordered newest-first to enforce 50-doc cap atomically
      final existingSnap = await historyColl
          .orderBy('timestamp', descending: true)
          .get()
          .timeout(_kNetworkTimeout);

      final batch = _firestore.batch();
      batch.set(newDocRef, record.toMap());

      if (existingSnap.docs.length >= _kMaxMatchHistoryCount) {
        final overflowDocs = existingSnap.docs.skip(_kMaxMatchHistoryCount - 1);
        for (final doc in overflowDocs) {
          if (doc.id != record.id) {
            batch.delete(doc.reference);
          }
        }
      }

      await batch.commit().timeout(_kNetworkTimeout);
    } catch (e) {
      debugPrint('[ArenaRepositoryImpl] writeMatchHistory error: $e');
    }
  }

  @override
  Future<List<ArenaMatchRecord>> getMatchHistory({
    required String userId,
    int limit = 50,
  }) async {
    if (userId.isEmpty) return const [];
    try {
      final snap = await _firestore
          .collection('users')
          .doc(userId)
          .collection('arena_match_history')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get()
          .timeout(_kNetworkTimeout);
      return snap.docs
          .map((d) => ArenaMatchRecord.fromMap(d.data(), docId: d.id))
          .toList();
    } catch (e) {
      debugPrint('[ArenaRepositoryImpl] getMatchHistory error: $e');
      return const [];
    }
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
      payout = _kStakeCoins;
      titleKey = 'coin_history.arena_duel_refund';
    } else if (isWinner) {
      payout = isPerfect ? (_kWinnerPayout + 10) : _kWinnerPayout;
      titleKey = isPerfect
          ? 'coin_history.arena_duel_perfect'
          : 'coin_history.arena_duel_win';
    } else {
      payout = _kLoserPayout;
      titleKey = 'coin_history.arena_duel_consolation';
    }

    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.id)
          .get()
          .timeout(_kNetworkTimeout);
      final rawHistory = CoinLedgerHelper.parseMapList(
        userDoc.data()?['coinHistory'],
      );
      final updatedHistory = CoinLedgerHelper.recordEntry(
        rawHistory,
        titleKey: titleKey,
        amount: payout,
        isEarned: true,
      );

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

      final now = DateTime.now();
      final lastDuel =
          (userDoc.data()?['lastDuelDate'] as Timestamp?)?.toDate();
      final isSameCalendarDay = lastDuel != null &&
          lastDuel.year == now.year &&
          lastDuel.month == now.month &&
          lastDuel.day == now.day;
      final int newDailyDuels = isSameCalendarDay
          ? (((userDoc.data()?['dailyDuelsPlayedToday'] as num?)?.toInt() ??
                    0) +
                1)
          : 1;

      final userRef = _firestore.collection('users').doc(currentUser.id);
      await userRef.update({
        'coins': FieldValue.increment(payout),
        if (isWinner) 'totalExp': FieldValue.increment(5),
        if (isWinner) 'duelWins': FieldValue.increment(1),
        if (!isWinner && !isDraw) 'duelLosses': FieldValue.increment(1),
        'dailyDuelsPlayedToday': newDailyDuels,
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
    if (cleanCode.startsWith('VOWL-AI-') ||
        cleanCode.startsWith('VOWL-RIVAL-')) {
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
            final rawHistory = CoinLedgerHelper.parseMapList(
              userDoc.data()?['coinHistory'],
            );
            final updatedHistory = CoinLedgerHelper.recordEntry(
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
      final rawHistory = CoinLedgerHelper.parseMapList(
        userDoc.data()?['coinHistory'],
      );
      final updatedHistory = CoinLedgerHelper.recordEntry(
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
    // Support new 'challenges' key first, fallback to legacy 'questions' key.
    final rawChallenges =
        (data['challenges'] as List<dynamic>?) ??
        (data['questions'] as List<dynamic>?) ??
        [];
    final challenges = rawChallenges
        .map(
          (c) =>
              ArenaChallenge.tryFromMap(Map<String, dynamic>.from(c as Map)),
        )
        .whereType<ArenaChallenge>()
        .toList();

    return ArenaDuelSession(
      roomCode: roomCode,
      hostId: data['hostId'] as String? ?? '',
      hostName: data['hostName'] as String? ?? 'Host',
      hostPhotoUrl: data['hostPhotoUrl'] as String?,
      guestId: data['guestId'] as String?,
      guestName: data['guestName'] as String?,
      guestPhotoUrl: data['guestPhotoUrl'] as String?,
      hostDuelWins: (data['hostDuelWins'] as num?)?.toInt() ?? 0,
      guestDuelWins: (data['guestDuelWins'] as num?)?.toInt() ?? 0,
      stake: (data['stake'] as num?)?.toInt() ?? _kStakeCoins,
      pot: (data['pot'] as num?)?.toInt() ?? (_kStakeCoins * 2),
      status: data['status'] as String? ?? 'in_progress',
      hostScore: (data['hostScore'] as num?)?.toInt() ?? 0,
      guestScore: (data['guestScore'] as num?)?.toInt() ?? 0,
      hostCorrectCount: (data['hostCorrectCount'] as num?)?.toInt() ?? 0,
      guestCorrectCount: (data['guestCorrectCount'] as num?)?.toInt() ?? 0,
      hostTotalTimeMs: (data['hostTotalTimeMs'] as num?)?.toInt() ?? 0,
      guestTotalTimeMs: (data['guestTotalTimeMs'] as num?)?.toInt() ?? 0,
      hostFinished: data['hostFinished'] as bool? ?? false,
      guestFinished: data['guestFinished'] as bool? ?? false,
      winnerId: data['winnerId'] as String?,
      challenges: challenges,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastHeartbeat: (data['lastHeartbeat'] as Timestamp?)?.toDate(),
    );
  }
}
