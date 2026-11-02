import 'package:vowl/features/auth/domain/entities/user_entity.dart';
import 'package:vowl/features/arena/domain/entities/arena_duel_session.dart';

abstract class ArenaRepository {
  /// Quick match: polls live Firestore queue for 3 seconds.
  /// If another live player is waiting, pairs immediately.
  /// Otherwise, falls back instantly to a Ghost Rival chosen from [leaderboardUsers]
  /// playing at their real accuracy rating (0-second wait time!).
  Future<ArenaDuelSession> quickMatch({
    required UserEntity currentUser,
    required List<UserEntity> leaderboardUsers,
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
}

