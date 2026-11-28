import 'package:vowl/features/arena/domain/entities/arena_duel_session.dart';
import 'package:vowl/features/arena/domain/entities/arena_match_record.dart';
import 'package:vowl/features/auth/domain/entities/user_entity.dart';

abstract class ArenaRepository {
  /// Quick match: polls live Firestore queue for an opponent.
  /// If another live player is waiting, pairs immediately.
  /// Otherwise, falls back to a calibrated Computer/AI opponent via
  /// 3-Pillar Skill-Based Matchmaking (SBMM).
  Future<ArenaDuelSession> quickMatch({required UserEntity currentUser});

  /// Challenges a specific player picked from the Leaderboard as a Ghost Rival
  /// playing at their exact accuracy level.
  Future<ArenaDuelSession> challengeRivalDirectly({
    required UserEntity currentUser,
    required UserEntity rival,
    required int rivalRank,
  });

  /// Starts an instant Ghost AI rematch keeping the same AI tier & accuracy
  /// with a brand-new 7-round Hybrid Pentathlon set.
  Future<ArenaDuelSession> rematchGhostAi({
    required UserEntity currentUser,
    required String previousGuestId,
    required String previousGuestName,
    String? previousGuestPhotoUrl,
    required double previousAccuracy,
    int previousOpponentDuelWins = 0,
  });

  /// Generates a sharable room code (e.g. `VOWL-DUEL-482913`) and creates the room document.
  Future<ArenaDuelSession> createRoomCode({required UserEntity currentUser});

  /// Joins an existing room code created by a friend.
  Future<ArenaDuelSession> joinRoom({
    required String roomCode,
    required UserEntity currentUser,
  });

  /// Listens to real-time updates for an active duel room.
  Stream<ArenaDuelSession> listenToRoom(String roomCode);

  /// Submits player's quiz score, round correct count, and total response time to the room.
  Future<void> submitScore({
    required String roomCode,
    required String userId,
    required int score,
    required bool isHost,
    int correctCount = 0,
    int totalTimeMs = 0,
  });

  /// Updates live character count typed in Type Duel for PvP opponent preview.
  Future<void> updateTypingProgress({
    required String roomCode,
    required String userId,
    required int charactersTyped,
  });

  /// Streams rival's live character count in Type Duel (PvP).
  Stream<int> listenToRivalTypingProgress({
    required String roomCode,
    required String rivalId,
  });

  /// Sends a rematch request in a live PvP room using a Firestore transaction.
  /// If the rival already sent a pending request, atomically creates the rematch
  /// room instead of creating a duplicate request.
  Future<void> sendRematchRequest({
    required String roomCode,
    required String requesterId,
    required String requesterName,
  });

  /// Listens to incoming rematch request status updates on [roomCode].
  Stream<Map<String, dynamic>> listenToRematchRequest({
    required String roomCode,
  });

  /// Accepts an incoming rematch request, deducts stake, creates/joins the
  /// new rematch room, and returns the live session.
  Future<ArenaDuelSession> acceptRematch({
    required String originalRoomCode,
    required UserEntity currentUser,
  });

  /// Joins an already-created rematch room as the original requester.
  Future<ArenaDuelSession> enterAcceptedRematch({
    required String newRoomCode,
    required UserEntity currentUser,
  });

  /// Declines or expires an incoming rematch request on [roomCode].
  Future<void> declineRematch({required String roomCode});

  /// Persists a completed match record into `users/{userId}/arena_match_history`
  /// and keeps the sub-collection bounded to the latest 50 records.
  Future<void> writeMatchHistory({
    required String userId,
    required ArenaMatchRecord record,
  });

  /// Loads recent match history records for [userId].
  Future<List<ArenaMatchRecord>> getMatchHistory({
    required String userId,
    int limit = 50,
  });

  /// Completes the match, awarding 50 coins to winner or 10 coins to loser.
  Future<void> completeMatch({
    required String roomCode,
    required UserEntity currentUser,
    required bool isWinner,
    required bool isDraw,
    bool isPerfect = false,
  });

  /// Forfeits match on disconnect / rage-quit. Remaining player awarded 50 Coins.
  Future<void> forfeitMatch({required String roomCode, required String userId});

  /// Refunds the 30-coin entry stake if matchmaking or a waiting room is dissolved before the match starts.
  Future<void> refundStake({required String userId});

  /// Immediately cancels an active matchmaking search, removes any queue ticket from Firestore,
  /// and terminates background listeners for [userId].
  Future<void> cancelMatchmaking({required String userId});
}
