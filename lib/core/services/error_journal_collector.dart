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
        );

        logs.add(jsonEncode(entry.toJson()));
        
        if (logs.length > maxEntries) {
          logs.removeAt(0); // Prune oldest
        }
        
        await prefs.setStringList(_localKey, logs);
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
      };

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('errorJournal')
          .add(entryMap);
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
            .map((str) => ErrorJournalEntry.fromJson(jsonDecode(str)))
            .toList();

        if (filterGameType != null && filterGameType.isNotEmpty) {
          entries = entries.where((e) => e.gameType == filterGameType).toList();
        }

        // Sort descending (newest first)
        entries.sort((a, b) => (b.timestamp ?? DateTime.now())
            .compareTo(a.timestamp ?? DateTime.now()));

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
          final decoded = jsonDecode(str);
          return decoded['id'] != entryId;
        }).toList();

        await prefs.setStringList(_localKey, filteredLogs);
        return;
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('errorJournal')
          .doc(entryId)
          .delete();
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
        return;
      }

      final collection = _firestore
          .collection('users')
          .doc(userId)
          .collection('errorJournal');

      var snapshot = await collection.limit(500).get();

      while (snapshot.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        snapshot = await collection.limit(500).get();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ErrorJournal] Failed to clear all: $e');
      }
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gameType': gameType,
      'question': question,
      'userAnswer': userAnswer,
      'correctAnswer': correctAnswer,
      'level': level,
      'timestamp': timestamp?.toIso8601String(),
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
    );
  }
}
