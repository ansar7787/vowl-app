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

  /// Total number of day files available in the corpus (75 files x 10 days = 750 days).
  static const int totalDays = 750;

  /// Maximum words per day for free users.
  static const int freeWordLimit = 5;

  /// Maximum words per day for premium users.
  static const int premiumWordLimit = 10;

  /// SharedPreferences keys.
  static const String _keyCurrentDay = 'daily_words_current_day';
  static const String _keyLastOpenDate = 'daily_words_last_open_date';
  static const String _keyLastCompletedDate = 'daily_words_last_completed_date';
  static const String _keyCompletedDay = 'daily_words_completed_day';
  static const String _keyWordBank = 'daily_words_bank';
  static const String _keyStreak = 'daily_words_streak';
  static const String _keyLongestStreak = 'daily_words_longest_streak';
  static const String _keyTotalWordsLearned = 'daily_words_total_learned';

  /// Leitner box → days until next review.
  static const List<int> _leitnerIntervals = [0, 1, 3, 7, 14, 30];

  // ── Cached state ────────────────────────────────────────────────────────────

  bool _isInitialized = false;
  int _currentDay = 1;
  int _completedDay = 0;
  int _streak = 0;
  int _longestStreak = 0;
  int _totalWordsLearned = 0;
  String _lastOpenDate = '';
  String _lastCompletedDate = '';
  DailyWordSet? _cachedWordSet;
  Map<String, WordProgress> _wordBank = {};

  // ── Public getters ──────────────────────────────────────────────────────────

  bool get isInitialized => _isInitialized;
  int get currentDay => _currentDay;
  int get completedDay => _completedDay;
  String get lastCompletedDate => _lastCompletedDate;
  bool get isTodayCompleted => _lastCompletedDate == _todayString();

  /// Clamped/wrapped day guaranteed to fall in the range 1..[totalDays].
  static int calculateEffectiveDay(int day) => ((day - 1) % totalDays) + 1;

  int get effectiveDay => calculateEffectiveDay(_currentDay);

  int get streak => _streak;
  int get longestStreak => _longestStreak;
  int get totalWordsLearned => _totalWordsLearned;
  int get wordBankSize => _wordBank.length;
  DailyWordSet? get todaysWords => _cachedWordSet;

  /// Returns whether a word exists in the Word Bank and has been learned (Box >= 1).
  /// O(1) hash map lookup.
  bool isWordLearned(String wordId) {
    final entry = _wordBank[wordId];
    return entry != null && entry.box > 0;
  }

  /// Returns whether a word has any entry in the Word Bank (even Box 0 / Needs Review).
  bool hasWordEntry(String wordId) => _wordBank.containsKey(wordId);

  /// All words in the user's Word Bank, sorted by most-recently-learned first.
  List<WordProgress> get wordBankEntries {
    final entries = _wordBank.values.toList()
      ..sort((a, b) => b.learnedDate.compareTo(a.learnedDate));
    return entries;
  }

  /// Current date formatted as YYYY-MM-DD.
  String get todayDateString => _todayString();

  /// Returns whether a word was completed or practiced in today's session.
  bool isWordLearnedToday(String wordId) {
    final entry = _wordBank[wordId];
    if (entry != null && entry.learnedDate == _todayString()) return true;
    if (isTodayCompleted &&
        _cachedWordSet != null &&
        _cachedWordSet!.words.any((w) => w.id == wordId)) {
      return true;
    }
    return false;
  }

  /// All words completed or learned in today's daily session.
  List<WordProgress> get todayWords {
    final today = _todayString();
    final entries = _wordBank.values.where((wp) {
      if (wp.learnedDate == today) return true;
      if (isTodayCompleted &&
          _cachedWordSet != null &&
          _cachedWordSet!.words.any((w) => w.id == wp.wordId)) {
        return true;
      }
      return false;
    }).toList();
    entries.sort((a, b) => b.learnedDate.compareTo(a.learnedDate));
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
    if (_isInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentDay = prefs.getInt(_keyCurrentDay) ?? 1;
      _completedDay = prefs.getInt(_keyCompletedDay) ?? 0;
      _lastOpenDate = prefs.getString(_keyLastOpenDate) ?? '';
      _lastCompletedDate = prefs.getString(_keyLastCompletedDate) ?? '';
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
      _isInitialized = true;
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
      // Calendar-day comparison avoids 24h duration edge cases.
      final lastDate = DateTime.tryParse(_lastOpenDate);
      final todayDate = DateTime.now();
      if (lastDate != null) {
        final lastCalendarDay = DateTime(
          lastDate.year,
          lastDate.month,
          lastDate.day,
        );
        final todayCalendarDay = DateTime(
          todayDate.year,
          todayDate.month,
          todayDate.day,
        );
        final diff = todayCalendarDay.difference(lastCalendarDay).inDays;
        if (diff == 1) {
          // Consecutive calendar day — increment streak
          _streak++;
        } else if (diff > 1) {
          // One or more days missed — reset streak
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
  /// If today's session is already completed, loads the completed day's words so
  /// the learner can practice today's words again without advancing early.
  Future<DailyWordSet?> loadTodaysWords({bool isPremium = false}) async {
    final targetDay = isTodayCompleted && _completedDay > 0
        ? _completedDay
        : _currentDay;
    final wordSet = await loadWordsForDay(targetDay, isPremium: isPremium);
    _cachedWordSet = wordSet;
    return wordSet;
  }

  /// Loads words for any specific curriculum day.
  Future<DailyWordSet?> loadWordsForDay(
    int targetDay, {
    bool isPremium = false,
  }) async {
    try {
      final day = calculateEffectiveDay(targetDay);
      final batchIndex = ((day - 1) ~/ 10) + 1;
      final startDay = (batchIndex - 1) * 10 + 1;
      final endDay = batchIndex * 10;

      final paddedStart = startDay.toString().padLeft(3, '0');
      final paddedEnd = endDay.toString().padLeft(3, '0');
      final path =
          'assets/curriculum/daily_words/daily_words_${paddedStart}_$paddedEnd.json';

      final jsonString = await rootBundle.loadString(path);
      if (jsonString.isEmpty) return null;

      final batchData = await compute(_parseWordBatchInIsolate, jsonString);
      if (batchData == null) return null;

      final data = batchData.days.firstWhere(
        (d) => d.day == day,
        orElse: () => batchData.days.first,
      );

      final wordSet = DailyWordSet(
        day: data.day,
        theme: data.theme,
        words: data.words,
      );

      return wordSet;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('DailyWordsService: Failed to load day $targetDay: $e');
      }
      return null;
    }
  }

  // ── Word completion ─────────────────────────────────────────────────────────

  /// Marks a word as learned (Box 1) or mastered (Box 3) and adds it to the Word Bank.
  ///
  /// If [mastered] is true (e.g. user passed Phase 2 Type-to-Confirm test),
  /// the word is directly placed into Box 3 (Mastered).
  /// If [mastered] is false (e.g. user skipped the typing test), it enters Box 1 (Learning).
  Future<void> markWordLearned(DailyWord word, {bool mastered = false}) async {
    final existing = _wordBank[word.id];
    final targetBox = mastered ? 3 : 1;
    if (existing != null && existing.box >= targetBox) return;

    final today = _todayString();
    final nextReview = targetBox >= 3
        ? '' // Mastered — recall verified!
        : _calculateNextReview(today, 1); // Box 1 = review tomorrow

    final isNewLearn = existing == null || existing.box == 0;
    _wordBank[word.id] = WordProgress(
      wordId: word.id,
      word: word.word,
      learnedDate: (existing != null && existing.learnedDate.isNotEmpty)
          ? existing.learnedDate
          : today,
      reviewCount: (existing?.reviewCount ?? 0) + (mastered ? 1 : 0),
      box: targetBox,
      nextReviewDate: nextReview,
      lastScore: mastered ? 3 : 1,
    );

    if (isNewLearn) {
      _totalWordsLearned++;
    }
    await _persist();
  }

  /// Records a word as needing review (Box 0) when user skips or taps "Review Later".
  ///
  /// Keeps progression without falsely incrementing [totalWordsLearned].
  Future<void> markWordNeedsReview(DailyWord word) async {
    final existing = _wordBank[word.id];
    if (existing != null && existing.box > 0) {
      // Word was previously learned in an earlier session; preserve mastery
      return;
    }

    final today = _todayString();
    _wordBank[word.id] = WordProgress(
      wordId: word.id,
      word: word.word,
      learnedDate: (existing != null && existing.learnedDate.isNotEmpty)
          ? existing.learnedDate
          : today,
      reviewCount: existing?.reviewCount ?? 0,
      box: 0, // Box 0 = Needs Review
      nextReviewDate: today,
      lastScore: 0,
    );

    await _persist();
  }

  /// Records a review result for a word in the spaced-repetition system.
  ///
  /// If [promoteToMastered] is true (e.g. user successfully passed "Test for Mastery" in Word Bank),
  /// the word is promoted directly to Box 3 (Mastered).
  /// If [correct] is true, the word advances to the next Leitner box.
  /// If false, it drops back to box 1 for immediate re-learning.
  Future<void> recordReview(
    String wordId, {
    required bool correct,
    bool promoteToMastered = false,
  }) async {
    final existing = _wordBank[wordId];
    if (existing == null) return;

    final today = _todayString();
    int newBox;
    if (promoteToMastered && correct) {
      newBox = 3; // Promoted straight to Mastered!
    } else if (correct) {
      newBox = (existing.box + 1).clamp(0, _leitnerIntervals.length - 1);
    } else {
      newBox = 1; // Drop back to box 1
    }

    final nextReview = newBox >= 3
        ? '' // Mastered — no more reviews needed
        : _calculateNextReview(today, _leitnerIntervals[newBox]);

    _wordBank[wordId] = existing.copyWith(
      box: newBox,
      reviewCount: existing.reviewCount + 1,
      nextReviewDate: nextReview,
      lastScore: correct ? (existing.lastScore + 1).clamp(0, 5) : 0,
    );

    await _persist();
  }

  /// Completes today's learning session and advances to the next day.
  /// Unbounded progression seamlessly enters multi-year mastery cycles (e.g. Day 751 = Cycle 2, Lesson 1).
  Future<void> completeDailySession() async {
    final today = _todayString();
    if (_lastCompletedDate == today) {
      // Already completed today! This is a replay session.
      // Do not increment _currentDay again or overwrite _completedDay.
      return;
    }
    _lastCompletedDate = today;
    _completedDay = _currentDay;
    _currentDay++;
    await _persist();
  }

  // ── Word Bank search ────────────────────────────────────────────────────────

  /// Searches the Word Bank for words matching the [query].
  ///
  /// Returns up to [limit] results. For free users, only the last 50 words
  /// are searchable.
  List<WordProgress> searchWordBank(
    String query, {
    int limit = 1000,
    bool isPremium = false,
  }) {
    if (query.isEmpty) {
      final entries = wordBankEntries;
      if (!isPremium && entries.length > 50) {
        return entries.sublist(0, 50);
      }
      return entries.length > limit ? entries.sublist(0, limit) : entries;
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

  // ── Word details lookup ─────────────────────────────────────────────────────

  /// Retrieves full word details (phonetic, definition, example) for a word ID.
  Future<DailyWord?> getWordDetails(String wordId) async {
    if (_cachedWordSet != null) {
      for (final w in _cachedWordSet!.words) {
        if (w.id == wordId) return w;
      }
    }

    final numStr = wordId.replaceAll(RegExp(r'[^0-9]'), '');
    final num = int.tryParse(numStr);
    if (num == null || num <= 0) return null;

    final day = ((num - 1) ~/ 10) + 1;
    final wordSet = await loadWordsForDay(day, isPremium: true);
    if (wordSet != null) {
      for (final w in wordSet.words) {
        if (w.id == wordId) return w;
      }
    }
    return null;
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
        reviewingCount++;
      } else if (wp.box == 1) {
        learningCount++;
      } else if (wp.box == 2) {
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
    _isInitialized = false;
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
      await prefs.setInt(_keyCompletedDay, _completedDay);
      await prefs.setString(_keyLastOpenDate, _lastOpenDate);
      await prefs.setString(_keyLastCompletedDate, _lastCompletedDate);
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
