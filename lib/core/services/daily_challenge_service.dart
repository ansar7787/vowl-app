import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service responsible for loading daily challenges and practice mode curriculum.
///
/// Loads isolated split curriculum files from `assets/curriculum/daily_challenges/`.
class DailyChallengeService {
  static const String _wordMixerCurriculumPath =
      'assets/curriculum/daily_challenges/word_mixer_curriculum.json';
  static const String _wordSnapCurriculumPath =
      'assets/curriculum/daily_challenges/word_snap_curriculum.json';

  static List<dynamic>? _cachedMixerItems;
  static List<dynamic>? _cachedSnapItems;
  static List<dynamic>? _cachedHandwritingItems;

  /// Returns today's Word Mixer puzzle based on day offset.
  static Future<Map<String, dynamic>?> getTodayWordMixer() async {
    final list = await _loadMixerList();
    if (list.isEmpty) return null;
    final index = _getTodayIndex(list.length);
    return Map<String, dynamic>.from(list[index] as Map);
  }

  /// Returns a random Word Mixer puzzle for practice mode.
  static Future<Map<String, dynamic>?> getRandomWordMixer() async {
    final list = await _loadMixerList();
    if (list.isEmpty) return null;
    final index = (DateTime.now().microsecondsSinceEpoch) % list.length;
    return Map<String, dynamic>.from(list[index] as Map);
  }

  /// Returns today's Word Snap puzzle based on day offset.
  static Future<Map<String, dynamic>?> getTodayWordSnap() async {
    final list = await _loadSnapList();
    if (list.isEmpty) return null;
    final index = _getTodayIndex(list.length);
    return Map<String, dynamic>.from(list[index] as Map);
  }

  /// Returns a random Word Snap puzzle for practice mode.
  static Future<Map<String, dynamic>?> getRandomWordSnap() async {
    final list = await _loadSnapList();
    if (list.isEmpty) return null;
    final index = (DateTime.now().microsecondsSinceEpoch) % list.length;
    return Map<String, dynamic>.from(list[index] as Map);
  }

  /// Returns today's Handwriting puzzle based on day offset.
  static Future<Map<String, dynamic>?> getTodayHandwriting() async {
    final list = await _loadHandwritingList();
    if (list.isEmpty) return null;
    final index = _getTodayIndex(list.length);
    return Map<String, dynamic>.from(list[index] as Map);
  }

  /// Returns a random Handwriting puzzle for practice mode.
  static Future<Map<String, dynamic>?> getRandomHandwriting() async {
    final list = await _loadHandwritingList();
    if (list.isEmpty) return null;
    final index = (DateTime.now().microsecondsSinceEpoch) % list.length;
    return Map<String, dynamic>.from(list[index] as Map);
  }

  static int _getTodayIndex(int totalCount) {
    if (totalCount <= 0) return 0;
    final now = DateTime.now();
    final epoch = DateTime(2024, 1, 1);
    final daysSinceEpoch = now.difference(epoch).inDays;
    return daysSinceEpoch.abs() % totalCount;
  }

  static Future<List<dynamic>> _loadMixerList() async {
    if (_cachedMixerItems != null) return _cachedMixerItems!;

    try {
      final jsonStr = await rootBundle.loadString(_wordMixerCurriculumPath);
      final dynamic decoded = await Isolate.run(() => jsonDecode(jsonStr));
      if (decoded is Map<String, dynamic> && decoded.containsKey('items')) {
        _cachedMixerItems = decoded['items'] as List<dynamic>;
        return _cachedMixerItems!;
      } else if (decoded is List) {
        _cachedMixerItems = decoded;
        return _cachedMixerItems!;
      }
    } catch (e) {
      debugPrint(
        '[DailyChallengeService] Failed to load Word Mixer curriculum: $e',
      );
    }

    return const [];
  }

  static Future<List<dynamic>> _loadSnapList() async {
    if (_cachedSnapItems != null) return _cachedSnapItems!;

    try {
      final jsonStr = await rootBundle.loadString(_wordSnapCurriculumPath);
      final dynamic decoded = await Isolate.run(() => jsonDecode(jsonStr));
      if (decoded is Map<String, dynamic> && decoded.containsKey('items')) {
        _cachedSnapItems = decoded['items'] as List<dynamic>;
        return _cachedSnapItems!;
      } else if (decoded is List) {
        _cachedSnapItems = decoded;
        return _cachedSnapItems!;
      }
    } catch (e) {
      debugPrint(
        '[DailyChallengeService] Failed to load Word Snap curriculum: $e',
      );
    }

    return const [];
  }

  static Future<List<dynamic>> _loadHandwritingList() async {
    if (_cachedHandwritingItems != null) return _cachedHandwritingItems!;

    try {
      final List<dynamic> allQuests = [];
      for (int i = 1; i <= 20; i++) {
        try {
          final path =
              'assets/curriculum/daily_challenges/handwriting/handwriting_batch_$i.json';
          final jsonStr = await rootBundle.loadString(path);
          final dynamic decoded = jsonDecode(jsonStr);
          if (decoded is List) {
            for (final levelObj in decoded) {
              if (levelObj is Map && levelObj['quests'] is List) {
                allQuests.addAll(levelObj['quests'] as List);
              }
            }
          }
        } catch (_) {}
      }
      if (allQuests.isNotEmpty) {
        _cachedHandwritingItems = allQuests;
        return _cachedHandwritingItems!;
      }
    } catch (e) {
      debugPrint(
        '[DailyChallengeService] Failed to load Handwriting curriculum: $e',
      );
    }

    return const [];
  }
}
