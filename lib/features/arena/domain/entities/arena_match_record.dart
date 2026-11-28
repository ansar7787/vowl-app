import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:vowl/features/arena/domain/entities/arena_challenge.dart';
import 'package:vowl/features/arena/domain/entities/arena_rank.dart';

/// Immutable record of a completed 1v1 Arena match stored under
/// `users/{userId}/arena_match_history/{matchId}`.
@immutable
class ArenaMatchRecord {
  final String id;
  final String roomCode;
  final String opponentName;
  final String? opponentPhotoUrl;
  final ArenaRank opponentRank;
  final bool isGhostRival;
  final String result; // 'win' | 'loss' | 'draw'
  final int myScore;
  final int rivalScore;
  final int myCorrectCount;
  final int rivalCorrectCount;
  final int myTotalTimeMs;
  final int rivalTotalTimeMs;
  final List<ArenaRoundResult> rounds;
  final DateTime timestamp;

  const ArenaMatchRecord({
    required this.id,
    required this.roomCode,
    required this.opponentName,
    this.opponentPhotoUrl,
    this.opponentRank = ArenaRank.recruit,
    this.isGhostRival = false,
    required this.result,
    required this.myScore,
    required this.rivalScore,
    required this.myCorrectCount,
    required this.rivalCorrectCount,
    this.myTotalTimeMs = 0,
    this.rivalTotalTimeMs = 0,
    this.rounds = const [],
    required this.timestamp,
  });

  bool get isWin => result == 'win';
  bool get isDraw => result == 'draw';
  bool get isLoss => result == 'loss';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'roomCode': roomCode,
      'opponentName': opponentName,
      if (opponentPhotoUrl != null) 'opponentPhotoUrl': opponentPhotoUrl,
      'opponentRank': opponentRank.key,
      'isGhostRival': isGhostRival,
      'result': result,
      'myScore': myScore,
      'rivalScore': rivalScore,
      'myCorrectCount': myCorrectCount,
      'rivalCorrectCount': rivalCorrectCount,
      'myTotalTimeMs': myTotalTimeMs,
      'rivalTotalTimeMs': rivalTotalTimeMs,
      'rounds': rounds.map((r) => r.toMap()).toList(),
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory ArenaMatchRecord.fromMap(Map<String, dynamic> map, {String? docId}) {
    final rawTs = map['timestamp'];
    DateTime parsedTime;
    if (rawTs is Timestamp) {
      parsedTime = rawTs.toDate();
    } else if (rawTs is DateTime) {
      parsedTime = rawTs;
    } else if (rawTs is String) {
      parsedTime = DateTime.tryParse(rawTs) ?? DateTime.now();
    } else {
      parsedTime = DateTime.now();
    }

    final rawRounds = (map['rounds'] as List<dynamic>?) ?? const [];
    final rounds = rawRounds
        .map((e) => ArenaRoundResult.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();

    return ArenaMatchRecord(
      id: (map['id'] as String?)?.isNotEmpty == true
          ? map['id'] as String
          : (docId ?? ''),
      roomCode: map['roomCode'] as String? ?? '',
      opponentName: map['opponentName'] as String? ?? 'Challenger',
      opponentPhotoUrl: map['opponentPhotoUrl'] as String?,
      opponentRank: ArenaRankExt.fromKey(map['opponentRank'] as String?),
      isGhostRival: map['isGhostRival'] as bool? ?? false,
      result: map['result'] as String? ?? 'loss',
      myScore: (map['myScore'] as num?)?.toInt() ?? 0,
      rivalScore: (map['rivalScore'] as num?)?.toInt() ?? 0,
      myCorrectCount: (map['myCorrectCount'] as num?)?.toInt() ?? 0,
      rivalCorrectCount: (map['rivalCorrectCount'] as num?)?.toInt() ?? 0,
      myTotalTimeMs: (map['myTotalTimeMs'] as num?)?.toInt() ?? 0,
      rivalTotalTimeMs: (map['rivalTotalTimeMs'] as num?)?.toInt() ?? 0,
      rounds: rounds,
      timestamp: parsedTime,
    );
  }
}
