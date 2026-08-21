import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// A lightweight, fire-and-forget service that captures wrong answers
/// across all 100 games and persists them to Firestore for review.
///
/// Usage in any BLoC:
/// ```dart
/// if (!isCorrect) {
///   ErrorJournalCollector.record(
///     userId: user.id,
///     gameType: 'grammarQuest',
///     question: quest.question ?? quest.instruction,
///     userAnswer: selectedOption,
///     correctAnswer: quest.correctAnswer ?? '',
///     level: state.level,
///   );
/// }
/// ```
class ErrorJournalCollector {
  ErrorJournalCollector._();

  static final _firestore = FirebaseFirestore.instance;

  /// Maximum number of error journal entries to keep per user.
  /// Oldest entries are pruned when this limit is exceeded.
  static const int maxEntries = 200;

  /// Records a wrong answer to Firestore under `users/{uid}/errorJournal`.
  /// This is fire-and-forget — errors are silently swallowed so it never
  /// disrupts gameplay.
  static Future<void> record({
    required String userId,
    required String gameType,
    required String question,
    required String userAnswer,
    required String correctAnswer,
    required int level,
  }) async {
    try {
      if (userId.isEmpty || question.isEmpty) return;

      final entry = {
        'gameType': gameType,
        'question': question,
        'userAnswer': userAnswer,
        'correctAnswer': correctAnswer,
        'level': level,
        'timestamp': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('errorJournal')
          .add(entry);
    } catch (e) {
      // Silent — never disrupt gameplay for analytics
      debugPrint('[ErrorJournal] Failed to record: $e');
    }
  }

  /// Fetches the most recent [limit] error journal entries for a user,
  /// ordered by timestamp descending (newest first).
  static Future<List<ErrorJournalEntry>> fetch({
    required String userId,
    int limit = 50,
    String? filterGameType,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('users')
          .doc(userId)
          .collection('errorJournal')
          .orderBy('timestamp', descending: true)
          .limit(limit);

      if (filterGameType != null && filterGameType.isNotEmpty) {
        query = query.where('gameType', isEqualTo: filterGameType);
      }

      final snapshot = await query.get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ErrorJournalEntry(
          id: doc.id,
          gameType: data['gameType'] as String? ?? '',
          question: data['question'] as String? ?? '',
          userAnswer: data['userAnswer'] as String? ?? '',
          correctAnswer: data['correctAnswer'] as String? ?? '',
          level: (data['level'] as num?)?.toInt() ?? 1,
          timestamp: (data['timestamp'] as Timestamp?)?.toDate(),
        );
      }).toList();
    } catch (e) {
      debugPrint('[ErrorJournal] Failed to fetch: $e');
      return [];
    }
  }

  /// Clears a specific entry (user reviewed and understands the mistake).
  static Future<void> dismiss({
    required String userId,
    required String entryId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('errorJournal')
          .doc(entryId)
          .delete();
    } catch (e) {
      debugPrint('[ErrorJournal] Failed to dismiss: $e');
    }
  }

  /// Clears all error journal entries for a user.
  static Future<void> clearAll({required String userId}) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('errorJournal')
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('[ErrorJournal] Failed to clear all: $e');
    }
  }
}

/// Immutable data class representing a single error journal entry.
@immutable
class ErrorJournalEntry {
  final String id;
  final String gameType;
  final String question;
  final String userAnswer;
  final String correctAnswer;
  final int level;
  final DateTime? timestamp;

  const ErrorJournalEntry({
    required this.id,
    required this.gameType,
    required this.question,
    required this.userAnswer,
    required this.correctAnswer,
    required this.level,
    this.timestamp,
  });
}
