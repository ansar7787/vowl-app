import 'dart:convert';
import 'package:flutter/services.dart';

class DailyChallengeService {
  static const String _dataPath = 'assets/data/daily_challenges.json';

  /// Returns today's Word Mixer puzzle based on the current day of the year.
  static Future<Map<String, dynamic>?> getTodayWordMixer() async {
    return _getPuzzleForToday('word_mixer');
  }

  /// Returns today's Word Snap puzzle based on the current day of the year.
  static Future<Map<String, dynamic>?> getTodayWordSnap() async {
    return _getPuzzleForToday('word_snap');
  }

  static Map<String, dynamic>? _cachedData;

  static Future<Map<String, dynamic>?> _getPuzzleForToday(String key) async {
    try {
      if (_cachedData == null) {
        final String jsonString = await rootBundle.loadString(_dataPath);
        _cachedData = jsonDecode(jsonString);
      }

      if (!_cachedData!.containsKey(key)) return null;

      final List<dynamic> puzzles = _cachedData![key];
      if (puzzles.isEmpty) return null;

      // Calculate total days since an epoch (e.g., Jan 1, 2024)
      // This allows looping through all 1,460 items over exactly 4 years
      final now = DateTime.now();
      final epoch = DateTime(2024, 1, 1);
      final daysSinceEpoch = now.difference(epoch).inDays;

      // Use modulo to safely loop through the massive puzzle array infinitely
      final index = (daysSinceEpoch.abs()) % puzzles.length;

      return Map<String, dynamic>.from(puzzles[index]);
    } catch (e) {
      // Graceful fallback for malformed JSON or missing file
      return null;
    }
  }
}
