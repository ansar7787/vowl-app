import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vowl/features/daily_words/domain/entities/daily_word.dart';
import 'package:vowl/features/daily_words/domain/entities/word_progress.dart';

/// Manages the Daily 10 Words feature: loading daily word sets from local
/// JSON assets, persisting learned-word progress, and implementing the
/// Leitner spaced-repetition scheduling algorithm.
///
/// **Zero server cost** — all data is local JSON + SharedPreferences.
class DailyWordsService {
  // ── Constants ───────────────────────────────────────────────────────────────

  /// Total number of day files available in the corpus.
  static const int totalDays = 1000;

  /// Maximum words per day for free users.
  static const int freeWordLimit = 5;

  /// Maximum words per day for premium users.
  static const int premiumWordLimit = 10;

  /// SharedPreferences keys.
  static const String _keyCurrentDay = 'daily_words_current_day';
  static const String _keyLastOpenDate = 'daily_words_last_open_date';
  static const String _keyWordBank = 'daily_words_bank';
  static const String _keyStreak = 'daily_words_streak';
  static const String _keyLongestStreak = 'daily_words_longest_streak';
  static const String _keyTotalWordsLearned = 'daily_words_total_learned';

  /// Leitner box → days until next review.
  static const List<int> _leitnerIntervals = [0, 1, 3, 7, 14, 30];

  // ── Cached state ────────────────────────────────────────────────────────────

  int _currentDay = 1;
  int _streak = 0;
  int _longestStreak = 0;
  int _totalWordsLearned = 0;
  String _lastOpenDate = '';
  DailyWordSet? _cachedWordSet;
  Map<String, WordProgress> _wordBank = {};

  // ── Public getters ──────────────────────────────────────────────────────────

  int get currentDay => _currentDay;
  int get streak => _streak;
  int get longestStreak => _longestStreak;
  int get totalWordsLearned => _totalWordsLearned;
  int get wordBankSize => _wordBank.length;
  DailyWordSet? get todaysWords => _cachedWordSet;

  /// All words in the user's Word Bank, sorted by most-recently-learned first.
  List<WordProgress> get wordBankEntries {
    final entries = _wordBank.values.toList()
      ..sort((a, b) => b.learnedDate.compareTo(a.learnedDate));
    return entries;
  }

  /// Words due for spaced-repetition review today.
  List<WordProgress> get wordsForReview {
    final today = _todayString();
    return _wordBank.values.where((wp) {
      if (wp.box >= _leitnerIntervals.length) return false; // mastered
      if (wp.nextReviewDate.isEmpty) return true; // never reviewed
      return wp.nextReviewDate.compareTo(today) <= 0;
    }).toList();
  }

  // ── Initialisation ──────────────────────────────────────────────────────────

  /// Loads persisted state from SharedPreferences. Call once at app start.
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentDay = prefs.getInt(_keyCurrentDay) ?? 1;
      _lastOpenDate = prefs.getString(_keyLastOpenDate) ?? '';
      _streak = prefs.getInt(_keyStreak) ?? 0;
      _longestStreak = prefs.getInt(_keyLongestStreak) ?? 0;
      _totalWordsLearned = prefs.getInt(_keyTotalWordsLearned) ?? 0;

      // Load word bank
      final bankJson = prefs.getString(_keyWordBank);
      if (bankJson != null && bankJson.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(bankJson);
        _wordBank = decoded.map(
          (key, value) => MapEntry(
            key,
            WordProgress.fromJson(value as Map<String, dynamic>),
          ),
        );
      }

      // Handle daily rollover
      await _checkDailyRollover();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('DailyWordsService: init failed: $e');
      }
    }
  }

  // ── Day rollover ────────────────────────────────────────────────────────────

  Future<void> _checkDailyRollover() async {
    final today = _todayString();
    if (_lastOpenDate == today) return; // Already opened today

    if (_lastOpenDate.isNotEmpty) {
      // Check if yesterday was the last open date (streak continues)
      final lastDate = DateTime.tryParse(_lastOpenDate);
      final todayDate = DateTime.now();
      if (lastDate != null) {
        final diff = todayDate.difference(lastDate).inDays;
        if (diff == 1) {
          // Consecutive day — increment streak
          _streak++;
        } else if (diff > 1) {
          // Streak broken
          _streak = 1;
        }
      }
    } else {
      // First ever open
      _streak = 1;
    }

    if (_streak > _longestStreak) {
      _longestStreak = _streak;
    }

    _lastOpenDate = today;
    await _persist();
  }

  // ── Load today's words ──────────────────────────────────────────────────────

  /// Loads the current day's word set from local JSON assets.
  ///
  /// Returns a [DailyWordSet] or `null` if the file doesn't exist.
  /// The [isPremium] flag controls whether the user gets 5 or 10 words.
  Future<DailyWordSet?> loadTodaysWords({bool isPremium = false}) async {
    try {
      // Ensure day is within bounds
      final day = _currentDay.clamp(1, totalDays);
      // Calculate batch range (10 days per file)
      // Day 1-10 -> batch 1 (001_010)
      // Day 11-20 -> batch 2 (011_020)
      final batchIndex = ((day - 1) ~/ 10) + 1;
      final startDay = (batchIndex - 1) * 10 + 1;
      final endDay = batchIndex * 10;

      final paddedStart = startDay.toString().padLeft(3, '0');
      final paddedEnd = endDay.toString().padLeft(3, '0');
      final path =
          'assets/curriculum/daily_words/daily_words_${paddedStart}_$paddedEnd.json';

      final jsonString = await rootBundle.loadString(path);
      if (jsonString.isEmpty) return null;

      // Parse in isolate for UI smoothness (follows AssetQuestService pattern)
      final batchData = await compute(_parseWordBatchInIsolate, jsonString);
      if (batchData == null) return null;

      // Find the specific day
      final data = batchData.days.firstWhere(
        (d) => d.day == day,
        orElse: () => batchData.days.first,
      );

      // Apply word limit based on subscription status
      final limit = isPremium ? premiumWordLimit : freeWordLimit;
      final limitedWords = data.words.length > limit
          ? data.words.sublist(0, limit)
          : data.words;

      _cachedWordSet = DailyWordSet(
        day: data.day,
        theme: data.theme,
        words: limitedWords,
      );

      return _cachedWordSet;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('DailyWordsService: Failed to load day $_currentDay: $e');
      }
      return null;
    }
  }

  // ── Word completion ─────────────────────────────────────────────────────────

  /// Marks a word as "learned" and adds it to the Word Bank.
  ///
  /// If the word already exists in the bank, this is a no-op.
  Future<void> markWordLearned(DailyWord word) async {
    if (_wordBank.containsKey(word.id)) return;

    final today = _todayString();
    final nextReview = _calculateNextReview(
      today,
      1,
    ); // Box 1 = review tomorrow

    _wordBank[word.id] = WordProgress(
      wordId: word.id,
      word: word.word,
      learnedDate: today,
      reviewCount: 0,
      box: 1,
      nextReviewDate: nextReview,
      lastScore: 0,
    );

    _totalWordsLearned++;
    await _persist();
  }

  /// Records a review result for a word in the spaced-repetition system.
  ///
  /// If [correct] is true, the word advances to the next Leitner box.
  /// If false, it drops back to box 1 for immediate re-learning.
  Future<void> recordReview(String wordId, {required bool correct}) async {
    final existing = _wordBank[wordId];
    if (existing == null) return;

    final today = _todayString();
    int newBox;
    if (correct) {
      newBox = (existing.box + 1).clamp(0, _leitnerIntervals.length - 1);
    } else {
      newBox = 1; // Drop back to box 1
    }

    final nextReview = newBox < _leitnerIntervals.length
        ? _calculateNextReview(today, _leitnerIntervals[newBox])
        : ''; // Mastered — no more reviews needed

    _wordBank[wordId] = existing.copyWith(
      box: newBox,
      reviewCount: existing.reviewCount + 1,
      nextReviewDate: nextReview,
      lastScore: correct ? (existing.lastScore + 1).clamp(0, 5) : 0,
    );

    await _persist();
  }

  /// Completes today's learning session and advances to the next day.
  Future<void> completeDailySession() async {
    if (_currentDay < totalDays) {
      _currentDay++;
    }
    await _persist();
  }

  // ── Word Bank search ────────────────────────────────────────────────────────

  /// Searches the Word Bank for words matching the [query].
  ///
  /// Returns up to [limit] results. For free users, only the last 50 words
  /// are searchable.
  List<WordProgress> searchWordBank(
    String query, {
    int limit = 50,
    bool isPremium = false,
  }) {
    if (query.isEmpty) {
      final entries = wordBankEntries;
      if (!isPremium && entries.length > 50) {
        return entries.sublist(0, 50);
      }
      return entries.take(limit).toList();
    }

    final lowerQuery = query.toLowerCase();
    var results =
        _wordBank.values
            .where((wp) => wp.word.toLowerCase().contains(lowerQuery))
            .toList()
          ..sort((a, b) => b.learnedDate.compareTo(a.learnedDate));

    if (!isPremium && results.length > 50) {
      results = results.sublist(0, 50);
    }

    return results.take(limit).toList();
  }

  // ── Statistics ──────────────────────────────────────────────────────────────

  /// Returns a map of mastery statistics.
  Map<String, int> get masteryStats {
    int newCount = 0;
    int learningCount = 0;
    int reviewingCount = 0;
    int masteredCount = 0;

    for (final wp in _wordBank.values) {
      if (wp.box == 0) {
        newCount++;
      } else if (wp.box <= 2) {
        learningCount++;
      } else if (wp.box < _leitnerIntervals.length) {
        reviewingCount++;
      } else {
        masteredCount++;
      }
    }

    return {
      'new': newCount,
      'learning': learningCount,
      'reviewing': reviewingCount,
      'mastered': masteredCount,
      'total': _wordBank.length,
    };
  }

  // ── Reset ───────────────────────────────────────────────────────────────────

  /// Resets all daily words progress. Called on account deletion / logout.
  Future<void> reset() async {
    _currentDay = 1;
    _streak = 0;
    _longestStreak = 0;
    _totalWordsLearned = 0;
    _lastOpenDate = '';
    _cachedWordSet = null;
    _wordBank.clear();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyCurrentDay);
      await prefs.remove(_keyLastOpenDate);
      await prefs.remove(_keyWordBank);
      await prefs.remove(_keyStreak);
      await prefs.remove(_keyLongestStreak);
      await prefs.remove(_keyTotalWordsLearned);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('DailyWordsService: reset failed: $e');
      }
    }
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _calculateNextReview(String fromDate, int daysToAdd) {
    final date = DateTime.tryParse(fromDate) ?? DateTime.now();
    final next = date.add(Duration(days: daysToAdd));
    return '${next.year}-${next.month.toString().padLeft(2, '0')}-${next.day.toString().padLeft(2, '0')}';
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyCurrentDay, _currentDay);
      await prefs.setString(_keyLastOpenDate, _lastOpenDate);
      await prefs.setInt(_keyStreak, _streak);
      await prefs.setInt(_keyLongestStreak, _longestStreak);
      await prefs.setInt(_keyTotalWordsLearned, _totalWordsLearned);

      // Persist word bank as JSON string
      final bankMap = _wordBank.map(
        (key, value) => MapEntry(key, value.toJson()),
      );
      await prefs.setString(_keyWordBank, jsonEncode(bankMap));
    } catch (e) {
      if (kDebugMode) {
        debugPrint('DailyWordsService: persist failed: $e');
      }
    }
  }
}

/// Top-level isolate function for parsing daily word JSON files.
/// Must be a top-level or static function for `compute()`.
DailyWordBatch? _parseWordBatchInIsolate(String jsonString) {
  try {
    if (jsonString.trim().isEmpty) return null;
    final Map<String, dynamic> data = jsonDecode(jsonString);
    return DailyWordBatch.fromJson(data);
  } catch (e) {
    return null;
  }
}
