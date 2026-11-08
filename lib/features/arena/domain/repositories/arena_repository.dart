import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/arena/domain/entities/arena_duel_session.dart';

abstract class ArenaRepository {
  /// Quick match: polls live Firestore queue for an opponent.
  /// If another live player is waiting, pairs immediately.
  /// Otherwise, falls back to a calibrated Computer/AI opponent via
  /// 3-Pillar Skill-Based Matchmaking (SBMM).
  Future<ArenaDuelSession> quickMatch({
    required UserEntity currentUser,
  });

  /// Challenges a specific player picked from the Leaderboard as a Ghost Rival
  /// playing at their exact accuracy level.
  Future<ArenaDuelSession> challengeRivalDirectly({
    required UserEntity currentUser,
    required UserEntity rival,
    required int rivalRank,
  });

  /// Generates a sharable room code (e.g. `VOWL-DUEL-882`) and creates the room document.
  Future<ArenaDuelSession> createRoomCode({
    required UserEntity currentUser,
  });

  /// Joins an existing room code created by a friend.
  Future<ArenaDuelSession> joinRoom({
    required String roomCode,
    required UserEntity currentUser,
  });

  /// Listens to real-time updates for an active duel room.
  Stream<ArenaDuelSession> listenToRoom(String roomCode);

  /// Submits player's quiz score to the room.
  Future<void> submitScore({
    required String roomCode,
    required String userId,
    required int score,
    required bool isHost,
  });

  /// Completes the match, awarding 50 coins to winner or 10 coins to loser.
  Future<void> completeMatch({
    required String roomCode,
    required UserEntity currentUser,
    required bool isWinner,
    required bool isDraw,
  });

  /// Forfeits match on disconnect / rage-quit. Remaining player awarded 50 Coins.
  Future<void> forfeitMatch({
    required String roomCode,
    required String userId,
  });

  /// Refunds the 30-coin entry stake if matchmaking or a waiting room is dissolved before the match starts.
  Future<void> refundStake({
    required String userId,
  });

  /// Immediately cancels an active matchmaking search, removes any queue ticket from Firestore,
  /// and terminates background listeners for [userId].
  Future<void> cancelMatchmaking({
    required String userId,
  });
}

