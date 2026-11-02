import 'package:flutter/foundation.dart';

/// Single multiple-choice question inside an Arena Duel.
@immutable
class ArenaQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;

  const ArenaQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
  });

  Map<String, dynamic> toMap() {
    return {
      'question': question,
      'options': options,
      'correctIndex': correctIndex,
      'explanation': explanation,
    };
  }

  factory ArenaQuestion.fromMap(Map<String, dynamic> map) {
    return ArenaQuestion(
      question: map['question'] as String? ?? '',
      options: (map['options'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      correctIndex: (map['correctIndex'] as num?)?.toInt() ?? 0,
      explanation: map['explanation'] as String? ?? '',
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
  final String? winnerId;
  final bool isGhostRival;
  final double ghostAccuracy;
  final List<ArenaQuestion> questions;
  final DateTime createdAt;
  final DateTime? lastHeartbeat;

  const ArenaDuelSession({
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
    this.winnerId,
    this.isGhostRival = false,
    this.ghostAccuracy = 0.8,
    required this.questions,
    required this.createdAt,
    this.lastHeartbeat,
  });

  bool get isCompleted => status == 'completed' || status == 'abandoned';
  bool get isInProgress => status == 'in_progress';
  bool get isWaiting => status == 'waiting';

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
    String? winnerId,
    bool? isGhostRival,
    double? ghostAccuracy,
    List<ArenaQuestion>? questions,
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
      winnerId: winnerId ?? this.winnerId,
      isGhostRival: isGhostRival ?? this.isGhostRival,
      ghostAccuracy: ghostAccuracy ?? this.ghostAccuracy,
      questions: questions ?? this.questions,
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
      'winnerId': winnerId,
      'isGhostRival': isGhostRival,
      'ghostAccuracy': ghostAccuracy,
      'questions': questions.map((q) => q.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'lastHeartbeat': lastHeartbeat?.toIso8601String(),
    };
  }
}
