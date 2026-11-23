import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents a persistent spaced repetition memory record for a morphological root.
class MistakeVaultRecord {
  final String rootWord;
  final int mistakeCount;
  final int consecutiveCorrect;
  final int intervalDays;
  final int nextReviewEpoch;

  const MistakeVaultRecord({
    required this.rootWord,
    required this.mistakeCount,
    required this.consecutiveCorrect,
    required this.intervalDays,
    required this.nextReviewEpoch,
  });

  bool get isDue => DateTime.now().millisecondsSinceEpoch >= nextReviewEpoch;
  bool get isMastered => consecutiveCorrect >= 3;

  Map<String, dynamic> toJson() => {
    'rootWord': rootWord,
    'mistakeCount': mistakeCount,
    'consecutiveCorrect': consecutiveCorrect,
    'intervalDays': intervalDays,
    'nextReviewEpoch': nextReviewEpoch,
  };

  factory MistakeVaultRecord.fromJson(Map<String, dynamic> json) =>
      MistakeVaultRecord(
        rootWord: json['rootWord'] as String? ?? '',
        mistakeCount: json['mistakeCount'] as int? ?? 1,
        consecutiveCorrect: json['consecutiveCorrect'] as int? ?? 0,
        intervalDays: json['intervalDays'] as int? ?? 1,
        nextReviewEpoch: json['nextReviewEpoch'] as int? ?? 0,
      );
}

/// Persistent Spaced Repetition (SRS) vault for Word Formation mistakes.
///
/// Ensures words failed in previous sessions are persistently rescheduled across
/// days (1 day ➔ 3 days ➔ 7 days) until the learner achieves 3 consecutive flawless recalls.
class WordFormationMistakeVault {
  static const String _keyPrefix = 'wf_vault_root_';
  static const String _rootsListKey = 'wf_vault_tracked_roots';

  final SharedPreferences? _prefs;

  WordFormationMistakeVault([this._prefs]);

  Future<SharedPreferences> _getPrefs() async =>
      _prefs ?? await SharedPreferences.getInstance();

  /// Records a missed attempt for a root word, resetting consecutive correct streak
  /// and setting the review due date to 1 day from now (or immediately in local revenge).
  Future<void> recordMistake(String rootWord) async {
    final root = rootWord.trim().toUpperCase();
    if (root.isEmpty) return;

    final prefs = await _getPrefs();
    final existing = await getRecord(root);

    final newCount = (existing?.mistakeCount ?? 0) + 1;
    final now = DateTime.now();
    final nextReview = now.add(const Duration(days: 1)).millisecondsSinceEpoch;

    final updated = MistakeVaultRecord(
      rootWord: root,
      mistakeCount: newCount,
      consecutiveCorrect: 0,
      intervalDays: 1,
      nextReviewEpoch: nextReview,
    );

    await prefs.setString('$_keyPrefix$root', jsonEncode(updated.toJson()));
    await _addToTrackedRoots(prefs, root);
  }

  /// Records a successful recall, advancing the spaced repetition interval.
  Future<void> recordSuccess(String rootWord) async {
    final root = rootWord.trim().toUpperCase();
    if (root.isEmpty) return;

    final prefs = await _getPrefs();
    final existing = await getRecord(root);
    if (existing == null) return;

    final newStreak = existing.consecutiveCorrect + 1;
    int nextInterval = 1;
    if (newStreak == 1) {
      nextInterval = 3; // 3 days
    } else if (newStreak == 2) {
      nextInterval = 7; // 7 days
    } else {
      nextInterval = 30; // Mastered
    }

    final nextReview = DateTime.now().add(Duration(days: nextInterval)).millisecondsSinceEpoch;

    final updated = MistakeVaultRecord(
      rootWord: root,
      mistakeCount: existing.mistakeCount,
      consecutiveCorrect: newStreak,
      intervalDays: nextInterval,
      nextReviewEpoch: nextReview,
    );

    await prefs.setString('$_keyPrefix$root', jsonEncode(updated.toJson()));
  }

  /// Retrieves the SRS record for a given root word.
  Future<MistakeVaultRecord?> getRecord(String rootWord) async {
    final root = rootWord.trim().toUpperCase();
    final prefs = await _getPrefs();
    final raw = prefs.getString('$_keyPrefix$root');
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return MistakeVaultRecord.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  /// Checks if a root word is actively due for a spaced review challenge.
  Future<bool> isReviewDue(String rootWord) async {
    final record = await getRecord(rootWord);
    if (record == null) return false;
    return record.isDue && !record.isMastered;
  }

  /// Returns all root words currently due for spaced review.
  Future<List<String>> getDueReviewRoots() async {
    final prefs = await _getPrefs();
    final tracked = prefs.getStringList(_rootsListKey) ?? [];
    final List<String> due = [];

    for (final root in tracked) {
      if (await isReviewDue(root)) {
        due.add(root);
      }
    }
    return due;
  }

  Future<void> _addToTrackedRoots(SharedPreferences prefs, String root) async {
    final tracked = prefs.getStringList(_rootsListKey) ?? [];
    if (!tracked.contains(root)) {
      tracked.add(root);
      await prefs.setStringList(_rootsListKey, tracked);
    }
  }

  /// Resets the vault (primarily for testing and cache wiping).
  Future<void> clearVault() async {
    final prefs = await _getPrefs();
    final tracked = prefs.getStringList(_rootsListKey) ?? [];
    for (final root in tracked) {
      await prefs.remove('$_keyPrefix$root');
    }
    await prefs.remove(_rootsListKey);
  }
}
