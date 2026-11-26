import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted record of a synonym pair where the learner struggled or missed.
@immutable
class SynonymWeakWordEntry {
  final int level;
  final String baseWord;
  final String synonym;
  final int misses;
  final int updatedAtMs;

  const SynonymWeakWordEntry({
    required this.level,
    required this.baseWord,
    required this.synonym,
    required this.misses,
    required this.updatedAtMs,
  });

  String get pairKey =>
      '${baseWord.trim().toLowerCase()}__${synonym.trim().toLowerCase()}';

  factory SynonymWeakWordEntry.fromJson(Map<String, dynamic> json) =>
      SynonymWeakWordEntry(
        level: json['level'] as int? ?? 1,
        baseWord: json['baseWord'] as String? ?? '',
        synonym: json['synonym'] as String? ?? '',
        misses: json['misses'] as int? ?? 1,
        updatedAtMs: json['updatedAtMs'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
    'level': level,
    'baseWord': baseWord,
    'synonym': synonym,
    'misses': misses,
    'updatedAtMs': updatedAtMs,
  };
}

/// Lightweight local persistence for tricky synonym pairs across sessions.
class SynonymWeakWordsStore {
  const SynonymWeakWordsStore._();

  static const String _storageKey = 'vowl_synonym_weak_words_v1';
  static const int _maxEntries = 20;

  static List<SynonymWeakWordEntry> _memoryCache = const [];

  @visibleForTesting
  static Future<void> resetForTest() async {
    _memoryCache = const [];
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (_) {}
  }

  /// Loads stored tricky pairs ordered by highest priority (misses, recency).
  static Future<List<SynonymWeakWordEntry>> loadWeakPairs({
    int? excludeLevel,
    int limit = 3,
  }) async {
    final entries = await _readAll();
    final filtered = entries.where((e) {
      if (e.baseWord.trim().isEmpty || e.synonym.trim().isEmpty) return false;
      if (excludeLevel != null && e.level == excludeLevel) return false;
      return true;
    }).toList();
    return filtered.take(limit).toList();
  }

  /// Records a struggle/miss for a pair so future Learn sessions can reinforce it.
  static Future<void> recordWeakPair({
    required int level,
    required String baseWord,
    required String synonym,
  }) async {
    final cleanBase = baseWord.trim();
    final cleanSyn = synonym.trim();
    if (cleanBase.isEmpty || cleanSyn.isEmpty) return;

    final entries = List<SynonymWeakWordEntry>.from(await _readAll());
    final now = DateTime.now().millisecondsSinceEpoch;
    final key = '${cleanBase.toLowerCase()}__${cleanSyn.toLowerCase()}';
    final idx = entries.indexWhere((e) => e.pairKey == key);
    if (idx >= 0) {
      final existing = entries[idx];
      entries[idx] = SynonymWeakWordEntry(
        level: level > 0 ? level : existing.level,
        baseWord: cleanBase,
        synonym: cleanSyn,
        misses: existing.misses + 1,
        updatedAtMs: now,
      );
    } else {
      entries.add(
        SynonymWeakWordEntry(
          level: level.clamp(1, 200),
          baseWord: cleanBase,
          synonym: cleanSyn,
          misses: 1,
          updatedAtMs: now,
        ),
      );
    }

    entries.sort((a, b) {
      final byMiss = b.misses.compareTo(a.misses);
      if (byMiss != 0) return byMiss;
      return b.updatedAtMs.compareTo(a.updatedAtMs);
    });
    await _writeAll(entries.take(_maxEntries).toList());
  }

  /// Reduces or clears weakness weight once the learner reviews a pair cleanly.
  static Future<void> markReviewed({
    required String baseWord,
    required String synonym,
  }) async {
    final key =
        '${baseWord.trim().toLowerCase()}__${synonym.trim().toLowerCase()}';
    final entries = List<SynonymWeakWordEntry>.from(await _readAll());
    final idx = entries.indexWhere((e) => e.pairKey == key);
    if (idx < 0) return;

    final existing = entries[idx];
    if (existing.misses <= 1) {
      entries.removeAt(idx);
    } else {
      entries[idx] = SynonymWeakWordEntry(
        level: existing.level,
        baseWord: existing.baseWord,
        synonym: existing.synonym,
        misses: existing.misses - 1,
        updatedAtMs: existing.updatedAtMs,
      );
    }
    await _writeAll(entries);
  }

  static Future<List<SynonymWeakWordEntry>> _readAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        _memoryCache = decoded
            .map(
              (e) => SynonymWeakWordEntry.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList();
      }
    } catch (_) {}
    return _memoryCache;
  }

  static Future<void> _writeAll(List<SynonymWeakWordEntry> entries) async {
    _memoryCache = List.unmodifiable(entries);
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(entries.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (_) {}
  }
}
