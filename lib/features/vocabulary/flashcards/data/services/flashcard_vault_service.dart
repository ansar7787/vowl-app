import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

/// Memory retention status classifying the forgetting curve.
enum RetentionGrade {
  strong, // >= 80%
  fading, // 50% - 79%
  critical, // < 50%
}

/// Persistent record of a mastered vocabulary word in the Lexicon Vault.
class FlashcardVaultEntry {
  final String word;
  final int level;
  final DateTime lastTestedAt;
  final int repetitionCount;
  final double stabilityHours;

  const FlashcardVaultEntry({
    required this.word,
    required this.level,
    required this.lastTestedAt,
    required this.repetitionCount,
    required this.stabilityHours,
  });

  /// Computes memory retention using the Ebbinghaus forgetting curve:
  /// R = e^(-t / S), where t is elapsed time in hours and S is memory stability.
  double get retention {
    final elapsedHours =
        DateTime.now().difference(lastTestedAt).inMinutes / 60.0;
    if (elapsedHours <= 0) return 1.0;
    final s = stabilityHours <= 0 ? 24.0 : stabilityHours;
    final r = exp(-elapsedHours / s);
    return r.clamp(0.0, 1.0);
  }

  /// Percentage value from 0 to 100 for UI indicators.
  int get retentionPercentage => (retention * 100).round();

  /// Retention health classification.
  RetentionGrade get grade {
    final r = retention;
    if (r >= 0.80) return RetentionGrade.strong;
    if (r >= 0.50) return RetentionGrade.fading;
    return RetentionGrade.critical;
  }

  Map<String, dynamic> toJson() => {
    'word': word,
    'level': level,
    'lastTestedAt': lastTestedAt.toIso8601String(),
    'repetitionCount': repetitionCount,
    'stabilityHours': stabilityHours,
  };

  factory FlashcardVaultEntry.fromJson(Map<String, dynamic> json) {
    return FlashcardVaultEntry(
      word: json['word'] as String? ?? '',
      level: (json['level'] as num?)?.toInt() ?? 1,
      lastTestedAt:
          DateTime.tryParse(json['lastTestedAt'] as String? ?? '') ??
          DateTime.now(),
      repetitionCount: (json['repetitionCount'] as num?)?.toInt() ?? 1,
      stabilityHours: (json['stabilityHours'] as num?)?.toDouble() ?? 24.0,
    );
  }
}

/// Spaced repetition & memory decay service for the Vocabulary Flashcards game.
///
/// Prevents the competitor flaw of "mastered once and forgotten" by mathematically
/// tracking memory decay and surfacing words due for active recall.
class FlashcardVaultService {
  static const String storageKey = 'vowl_flashcard_vault_records_v1';
  final SharedPreferences? _prefsInstance;

  FlashcardVaultService([this._prefsInstance]);

  Future<SharedPreferences> _getPrefs() async {
    return _prefsInstance ?? await SharedPreferences.getInstance();
  }

  /// Records a successful mastery event for a target word.
  Future<void> recordMastery(
    String word,
    int level, {
    bool perfect = true,
  }) async {
    if (word.trim().isEmpty) return;
    final cleanWord = word.trim().toUpperCase();
    final prefs = await _getPrefs();
    final rawJson = prefs.getString(storageKey);
    Map<String, dynamic> vaultMap = <String, dynamic>{};
    if (rawJson != null && rawJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawJson);
        if (decoded is Map) {
          vaultMap = Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        vaultMap = <String, dynamic>{};
      }
    }

    final existingJson = vaultMap[cleanWord] as Map<String, dynamic>?;

    if (existingJson != null) {
      final existing = FlashcardVaultEntry.fromJson(existingJson);
      final newCount = existing.repetitionCount + 1;
      final multiplier = perfect ? 2.5 : 1.5;
      final newStability = (existing.stabilityHours * multiplier).clamp(
        24.0,
        8760.0,
      ); // Up to 1 year

      final updated = FlashcardVaultEntry(
        word: cleanWord,
        level: level,
        lastTestedAt: DateTime.now(),
        repetitionCount: newCount,
        stabilityHours: newStability,
      );
      vaultMap[cleanWord] = updated.toJson();
    } else {
      final baseStability = perfect ? 48.0 : 24.0;
      final entry = FlashcardVaultEntry(
        word: cleanWord,
        level: level,
        lastTestedAt: DateTime.now(),
        repetitionCount: 1,
        stabilityHours: baseStability,
      );
      vaultMap[cleanWord] = entry.toJson();
    }

    await prefs.setString(storageKey, jsonEncode(vaultMap));
  }

  /// Retrieves all vault entries, sorted by lowest retention first.
  Future<List<FlashcardVaultEntry>> getVaultEntries() async {
    final prefs = await _getPrefs();
    final rawJson = prefs.getString(storageKey);
    if (rawJson == null || rawJson.isEmpty) return const [];

    try {
      final Map<String, dynamic> vaultMap = Map<String, dynamic>.from(
        jsonDecode(rawJson) as Map,
      );
      final entries = vaultMap.values
          .map((v) => FlashcardVaultEntry.fromJson(v as Map<String, dynamic>))
          .toList();

      entries.sort((a, b) => a.retention.compareTo(b.retention));
      return entries;
    } catch (_) {
      return const [];
    }
  }

  /// Returns words whose retention has decayed below [threshold] (default 0.60).
  Future<List<FlashcardVaultEntry>> getWordsDueForReview({
    double threshold = 0.60,
  }) async {
    final entries = await getVaultEntries();
    return entries.where((e) => e.retention < threshold).toList();
  }

  /// Retrieves a specific word entry or null if unrecorded.
  Future<FlashcardVaultEntry?> getEntry(String word) async {
    final cleanWord = word.trim().toUpperCase();
    final prefs = await _getPrefs();
    final rawJson = prefs.getString(storageKey);
    if (rawJson == null) return null;

    try {
      final Map<String, dynamic> vaultMap = Map<String, dynamic>.from(
        jsonDecode(rawJson) as Map,
      );
      final entryJson = vaultMap[cleanWord] as Map<String, dynamic>?;
      if (entryJson == null) return null;
      return FlashcardVaultEntry.fromJson(entryJson);
    } catch (_) {
      return null;
    }
  }

  /// Clears all stored entries (primarily for testing or reset flows).
  Future<void> clearVault() async {
    final prefs = await _getPrefs();
    await prefs.remove(storageKey);
  }
}
