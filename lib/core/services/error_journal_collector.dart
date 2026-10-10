import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A lightweight, fire-and-forget service that captures wrong answers
/// across all 100 games and persists them to Firestore (or locally for guests) for review.
class ErrorJournalCollector {
  ErrorJournalCollector._();

  static final _firestore = FirebaseFirestore.instance;
  static const String _localKey = 'vowl_local_error_journal';

  /// A global notifier that increments whenever the journal is modified.
  /// UI components can listen to this to refresh their counts dynamically.
  static final ValueNotifier<int> updateNotifier = ValueNotifier(0);

  /// Maximum number of error journal entries to keep per user.
  static const int maxEntries = 200;

  /// Records a wrong answer to Firestore under `users/{uid}/errorJournal`
  /// or to local storage if the user is a guest ('local').
  static Future<void> record({
    required String userId,
    required String gameType,
    required String question,
    required String userAnswer,
    required String correctAnswer,
    required int level,
    List<String>? options,
  }) async {
    try {
      if (userId.isEmpty || question.isEmpty) return;

      final now = DateTime.now();

      if (userId == 'local') {
        // Local Guest Storage
        final prefs = await SharedPreferences.getInstance();
        final List<String> logs = prefs.getStringList(_localKey) ?? [];

        final entry = ErrorJournalEntry(
          id: now.millisecondsSinceEpoch.toString(),
          gameType: gameType,
          question: question,
          userAnswer: userAnswer,
          correctAnswer: correctAnswer,
          level: level,
          timestamp: now,
          options: options,
        );

        // Deduplicate: Remove older instance of the same question if it exists
        logs.removeWhere((log) {
          try {
            final decoded = jsonDecode(log) as Map<String, dynamic>;
            return decoded['question'] == question &&
                decoded['correctAnswer'] == correctAnswer &&
                decoded['gameType'] == gameType &&
                decoded['level'] == level;
          } catch (_) {
            return false;
          }
        });

        logs.add(jsonEncode(entry.toJson()));

        if (logs.length > maxEntries) {
          logs.removeAt(0); // Prune oldest
        }

        await prefs.setStringList(_localKey, logs);
        updateNotifier.value++;
        return;
      }

      // Authenticated Cloud Storage
      final entryMap = {
        'gameType': gameType,
        'question': question,
        'userAnswer': userAnswer,
        'correctAnswer': correctAnswer,
        'level': level,
        'timestamp': FieldValue.serverTimestamp(),
        if (options != null && options.isNotEmpty) 'options': options,
      };

      // Create a deterministic document ID to deduplicate identical questions.
      // If the user gets the same question wrong again, it will just overwrite
      // the existing document and update the timestamp, bumping it to the top.
      final String uniqueString =
          '${gameType}_${level}_${question}_$correctAnswer';
      // base64UrlEncode is safe for Firestore paths (no slashes)
      final String docId = base64UrlEncode(utf8.encode(uniqueString));

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('errorJournal')
          .doc(docId)
          .set(entryMap, SetOptions(merge: true));

      updateNotifier.value++;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ErrorJournal] Failed to record: $e');
      }
    }
  }

  /// Fetches the most recent [limit] error journal entries.
  static Future<List<ErrorJournalEntry>> fetch({
    required String userId,
    int limit = 50,
    String? filterGameType,
  }) async {
    try {
      if (userId == 'local') {
        final prefs = await SharedPreferences.getInstance();
        final List<String> logs = prefs.getStringList(_localKey) ?? [];

        var entries = logs
            .map(
              (str) => ErrorJournalEntry.fromJson(
                jsonDecode(str) as Map<String, dynamic>,
              ),
            )
            .toList();

        if (filterGameType != null && filterGameType.isNotEmpty) {
          entries = entries.where((e) => e.gameType == filterGameType).toList();
        }

        // Sort descending (newest first)
        entries.sort(
          (a, b) => (b.timestamp ?? DateTime.now()).compareTo(
            a.timestamp ?? DateTime.now(),
          ),
        );

        return entries.take(limit).toList();
      }

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
          options: data['options'] != null
              ? List<String>.from(data['options'] as List)
              : null,
        );
      }).toList();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ErrorJournal] Failed to fetch: $e');
      }
      return [];
    }
  }

  /// Clears a specific entry (user reviewed and understands the mistake).
  static Future<void> dismiss({
    required String userId,
    required String entryId,
  }) async {
    try {
      if (userId == 'local') {
        final prefs = await SharedPreferences.getInstance();
        final List<String> logs = prefs.getStringList(_localKey) ?? [];

        final filteredLogs = logs.where((str) {
          final decoded = jsonDecode(str) as Map<String, dynamic>;
          return decoded['id'] != entryId;
        }).toList();

        await prefs.setStringList(_localKey, filteredLogs);
        updateNotifier.value++;
        return;
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('errorJournal')
          .doc(entryId)
          .delete();

      updateNotifier.value++;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ErrorJournal] Failed to dismiss: $e');
      }
    }
  }

  /// Clears all error journal entries.
  static Future<void> clearAll({required String userId}) async {
    try {
      if (userId == 'local') {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_localKey);
        updateNotifier.value++;
        return;
      }

      final collection = _firestore
          .collection('users')
          .doc(userId)
          .collection('errorJournal');

      // Cap iterations to prevent unbounded billing if document count is
      // artificially inflated via direct Firestore writes.
      // 10 batches × 500 docs = 5000 max deletes — more than enough for
      // legitimate use (maxEntries is 200).
      var snapshot = await collection.limit(500).get();
      int iterations = 0;
      const maxIterations = 10;

      while (snapshot.docs.isNotEmpty && iterations < maxIterations) {
        final batch = _firestore.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        iterations++;
        if (iterations < maxIterations) {
          snapshot = await collection.limit(500).get();
        }
      }

      updateNotifier.value++;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ErrorJournal] Failed to clear all: $e');
      }
    }
  }

  /// Clears all error journal entries for a specific game and level.
  /// Called when a user successfully completes a level, proving they've mastered the content.
  static Future<void> clearLevelMistakes({
    required String userId,
    required String gameType,
    required int level,
  }) async {
    try {
      if (userId == 'local') {
        final prefs = await SharedPreferences.getInstance();
        final List<String> logs = prefs.getStringList(_localKey) ?? [];

        final filteredLogs = logs.where((str) {
          final decoded = jsonDecode(str) as Map<String, dynamic>;
          return !(decoded['gameType'] == gameType &&
              decoded['level'] == level);
        }).toList();

        await prefs.setStringList(_localKey, filteredLogs);
        updateNotifier.value++;
        return;
      }

      final collection = _firestore
          .collection('users')
          .doc(userId)
          .collection('errorJournal');

      final snapshot = await collection
          .where('gameType', isEqualTo: gameType)
          .where('level', isEqualTo: level)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        updateNotifier.value++;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ErrorJournal] Failed to clear level mistakes: $e');
      }
    }
  }

  /// Returns the count of error journal entries without downloading full documents.
  /// Uses Firestore aggregation query for authenticated users, avoids bandwidth waste.
  static Future<int> count({required String userId}) async {
    try {
      if (userId == 'local') {
        final prefs = await SharedPreferences.getInstance();
        final List<String> logs = prefs.getStringList(_localKey) ?? [];
        return logs.length;
      }

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('errorJournal')
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ErrorJournal] Failed to count: $e');
      }
      return 0;
    }
  }

  /// Converts a camelCase gameType enum name to a human-readable label.
  /// e.g., 'syllableStress' → 'Syllable Stress', 'readAndAnswer' → 'Read And Answer'
  static String humanReadableName(String gameType) {
    if (gameType.isEmpty) return gameType;
    final result = gameType.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(0)}',
    );
    // Capitalize first letter
    return result[0].toUpperCase() + result.substring(1);
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
  final List<String>? options;

  const ErrorJournalEntry({
    required this.id,
    required this.gameType,
    required this.question,
    required this.userAnswer,
    required this.correctAnswer,
    required this.level,
    this.timestamp,
    this.options,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gameType': gameType,
      'question': question,
      'userAnswer': userAnswer,
      'correctAnswer': correctAnswer,
      'level': level,
      'timestamp': timestamp?.toIso8601String(),
      if (options != null) 'options': options,
    };
  }

  factory ErrorJournalEntry.fromJson(Map<String, dynamic> json) {
    return ErrorJournalEntry(
      id: json['id'] as String? ?? '',
      gameType: json['gameType'] as String? ?? '',
      question: json['question'] as String? ?? '',
      userAnswer: json['userAnswer'] as String? ?? '',
      correctAnswer: json['correctAnswer'] as String? ?? '',
      level: json['level'] as int? ?? 1,
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp'] as String)
          : null,
      options: json['options'] != null
          ? List<String>.from(json['options'])
          : null,
    );
  }
}
