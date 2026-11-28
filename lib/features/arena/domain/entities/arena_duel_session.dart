import 'package:flutter/foundation.dart';
import 'package:vowl/features/arena/domain/entities/arena_challenge.dart';

/// Single multiple-choice question inside an Arena Duel.
/// Kept for backward compat — new code should use [ArenaChallenge].
@immutable
class ArenaQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final String? discipline;
  final String? difficulty; // "easy", "medium", "hard"

  const ArenaQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    this.discipline,
    this.difficulty,
  });

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'options': options,
      'correctIndex': correctIndex,
      'explanation': explanation,
      if (discipline != null) 'discipline': discipline,
      if (difficulty != null) 'difficulty': difficulty,
    };
  }

  factory ArenaQuestion.fromMap(Map<String, dynamic> map) {
    return ArenaQuestion(
      question: map['question'] as String? ?? '',
      options:
          (map['options'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      correctIndex: (map['correctIndex'] as num?)?.toInt() ?? 0,
      explanation: map['explanation'] as String? ?? '',
      discipline: map['discipline'] as String?,
      difficulty: map['difficulty'] as String?,
    );
  }
}

/// Represents the active state of a 1v1 PvP staking duel room.
@immutable
class ArenaDuelSession {
  final String roomCode;
  final String hostId;
  final String hostName;
  final String? hostPhotoUrl;
  final String? guestId;
  final String? guestName;
  final String? guestPhotoUrl;
  final int stake;
  final int pot;
  final String status; // 'waiting', 'in_progress', 'completed', 'abandoned'
  final int hostScore;
  final int guestScore;
  final int hostCorrectCount;
  final int guestCorrectCount;
  final int hostTotalTimeMs;
  final int guestTotalTimeMs;
  final bool hostFinished;
  final bool guestFinished;
  final String? winnerId;
  final bool isGhostRival;
  final double ghostAccuracy;
  final int hostDuelWins;
  final int guestDuelWins;
  final List<ArenaChallenge> challenges;
  final DateTime createdAt;
  final DateTime? lastHeartbeat;

  ArenaDuelSession({
    required this.roomCode,
    required this.hostId,
    required this.hostName,
    this.hostPhotoUrl,
    this.guestId,
    this.guestName,
    this.guestPhotoUrl,
    this.stake = 30,
    this.pot = 60,
    required this.status,
    this.hostScore = 0,
    this.guestScore = 0,
    this.hostCorrectCount = 0,
    this.guestCorrectCount = 0,
    this.hostTotalTimeMs = 0,
    this.guestTotalTimeMs = 0,
    this.hostFinished = false,
    this.guestFinished = false,
    this.winnerId,
    this.isGhostRival = false,
    this.ghostAccuracy = 0.8,
    this.hostDuelWins = 0,
    this.guestDuelWins = 0,
    List<ArenaChallenge>? challenges,
    @Deprecated('Use challenges instead') List<ArenaQuestion>? questions,
    required this.createdAt,
    this.lastHeartbeat,
  }) : challenges =
            challenges ??
            (questions != null
                ? questions.map(ArenaChallenge.fromLegacyQuestion).toList()
                : const []);

  bool get isCompleted => status == 'completed' || status == 'abandoned';
  bool get isInProgress => status == 'in_progress';
  bool get isWaiting => status == 'waiting';
  bool get bothPlayersFinished => hostFinished && guestFinished;
  bool didFinish(String userId) => isHost(userId) ? hostFinished : guestFinished;

  /// Deprecated backward compat — returns only MCQ challenges as ArenaQuestion.
  @Deprecated('Use challenges instead')
  List<ArenaQuestion> get questions => challenges
      .where((c) => c.mechanic == ArenaMechanicType.mcq)
      .map((c) => c.toLegacyQuestion())
      .toList();

  /// Returns the total number of rounds (all mechanic types).
  int get totalRounds => challenges.length;

  /// Returns true if [userId] is the host of this duel room.
  bool isHost(String userId) => hostId == userId;

  /// Resolves the opponent's display name relative to [currentUserId].
  String opponentName(String currentUserId) {
    if (hostId == currentUserId) {
      return guestName ?? 'Challenger';
    }
    return hostName;
  }

  /// Resolves the opponent's photo URL relative to [currentUserId].
  String? opponentPhotoUrl(String currentUserId) {
    if (hostId == currentUserId) {
      return guestPhotoUrl;
    }
    return hostPhotoUrl;
  }

  /// Resolves the current player's display name relative to [currentUserId].
  String myName(String currentUserId) {
    if (hostId == currentUserId) {
      return hostName;
    }
    return guestName ?? 'You';
  }

  /// Resolves the current player's photo URL relative to [currentUserId].
  String? myPhotoUrl(String currentUserId) {
    if (hostId == currentUserId) {
      return hostPhotoUrl;
    }
    return guestPhotoUrl;
  }

  /// Resolves the opponent's current score relative to [currentUserId].
  int opponentScore(String currentUserId) {
    return isHost(currentUserId) ? guestScore : hostScore;
  }

  /// Resolves the current player's score relative to [currentUserId].
  int mySessionScore(String currentUserId) {
    return isHost(currentUserId) ? hostScore : guestScore;
  }

  /// Resolves the opponent's correct count relative to [currentUserId].
  int opponentCorrectCount(String currentUserId) {
    return isHost(currentUserId) ? guestCorrectCount : hostCorrectCount;
  }

  /// Resolves the opponent's total response time in ms relative to [currentUserId].
  int opponentTotalTimeMs(String currentUserId) {
    return isHost(currentUserId) ? guestTotalTimeMs : hostTotalTimeMs;
  }

  /// Resolves the opponent's lifetime duel wins relative to [currentUserId].
  int opponentDuelWins(String currentUserId) {
    return isHost(currentUserId) ? guestDuelWins : hostDuelWins;
  }

  /// Resolves the current player's lifetime duel wins relative to [currentUserId].
  int myDuelWins(String currentUserId) {
    return isHost(currentUserId) ? hostDuelWins : guestDuelWins;
  }

  ArenaDuelSession copyWith({
    String? roomCode,
    String? hostId,
    String? hostName,
    String? hostPhotoUrl,
    String? guestId,
    String? guestName,
    String? guestPhotoUrl,
    int? stake,
    int? pot,
    String? status,
    int? hostScore,
    int? guestScore,
    int? hostCorrectCount,
    int? guestCorrectCount,
    int? hostTotalTimeMs,
    int? guestTotalTimeMs,
    bool? hostFinished,
    bool? guestFinished,
    String? winnerId,
    bool? isGhostRival,
    double? ghostAccuracy,
    int? hostDuelWins,
    int? guestDuelWins,
    List<ArenaChallenge>? challenges,
    DateTime? createdAt,
    DateTime? lastHeartbeat,
  }) {
    return ArenaDuelSession(
      roomCode: roomCode ?? this.roomCode,
      hostId: hostId ?? this.hostId,
      hostName: hostName ?? this.hostName,
      hostPhotoUrl: hostPhotoUrl ?? this.hostPhotoUrl,
      guestId: guestId ?? this.guestId,
      guestName: guestName ?? this.guestName,
      guestPhotoUrl: guestPhotoUrl ?? this.guestPhotoUrl,
      stake: stake ?? this.stake,
      pot: pot ?? this.pot,
      status: status ?? this.status,
      hostScore: hostScore ?? this.hostScore,
      guestScore: guestScore ?? this.guestScore,
      hostCorrectCount: hostCorrectCount ?? this.hostCorrectCount,
      guestCorrectCount: guestCorrectCount ?? this.guestCorrectCount,
      hostTotalTimeMs: hostTotalTimeMs ?? this.hostTotalTimeMs,
      guestTotalTimeMs: guestTotalTimeMs ?? this.guestTotalTimeMs,
      hostFinished: hostFinished ?? this.hostFinished,
      guestFinished: guestFinished ?? this.guestFinished,
      winnerId: winnerId ?? this.winnerId,
      isGhostRival: isGhostRival ?? this.isGhostRival,
      ghostAccuracy: ghostAccuracy ?? this.ghostAccuracy,
      hostDuelWins: hostDuelWins ?? this.hostDuelWins,
      guestDuelWins: guestDuelWins ?? this.guestDuelWins,
      challenges: challenges ?? this.challenges,
      createdAt: createdAt ?? this.createdAt,
      lastHeartbeat: lastHeartbeat ?? this.lastHeartbeat,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roomCode': roomCode,
      'hostId': hostId,
      'hostName': hostName,
      'hostPhotoUrl': hostPhotoUrl,
      'guestId': guestId,
      'guestName': guestName,
      'guestPhotoUrl': guestPhotoUrl,
      'stake': stake,
      'pot': pot,
      'status': status,
      'hostScore': hostScore,
      'guestScore': guestScore,
      'hostCorrectCount': hostCorrectCount,
      'guestCorrectCount': guestCorrectCount,
      'hostTotalTimeMs': hostTotalTimeMs,
      'guestTotalTimeMs': guestTotalTimeMs,
      'hostFinished': hostFinished,
      'guestFinished': guestFinished,
      'winnerId': winnerId,
      'isGhostRival': isGhostRival,
      'ghostAccuracy': ghostAccuracy,
      'hostDuelWins': hostDuelWins,
      'guestDuelWins': guestDuelWins,
      'challenges': challenges.map((c) => c.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'lastHeartbeat': lastHeartbeat?.toIso8601String(),
    };
  }
}
