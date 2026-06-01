import 'dart:math';
import 'dart:typed_data';

/// Abstract contract defining the Text similarity and speech comparison helper.
///
/// Decouples scoring algorithms from calling evaluation systems, satisfying SOLID principles.
abstract class TextSimilarityHelper {
  /// Factory mapping constructor supporting seamless backwards compatibility for callers.
  factory TextSimilarityHelper() = TextSimilarityHelperImpl;

  /// Backward-compatible static delegation method to normalize text strings.
  static String normalize(String text) => TextSimilarityHelperImpl().normalizeText(text);

  /// Backward-compatible static delegation method to calculate Levenshtein distances.
  static int levenshteinDistance(String s, String t) => TextSimilarityHelperImpl().calculateLevenshteinDistance(s, t);

  /// Backward-compatible static delegation method to calculate Levenshtein similarities.
  static double levenshteinSimilarity(String s1, String s2) => TextSimilarityHelperImpl().calculateLevenshteinSimilarity(s1, s2);

  /// Backward-compatible static delegation method to calculate word match scores.
  static double wordMatchScore(String spoken, String target) => TextSimilarityHelperImpl().calculateWordMatchScore(spoken, target);

  /// Backward-compatible static delegation method to retrieve matched index arrays.
  static Set<int> getMatchedIndices(String spoken, String target) => TextSimilarityHelperImpl().findMatchedIndices(spoken, target);

  /// Backward-compatible static delegation method to evaluate sufficiency thresholds.
  static bool isMatch(String spoken, String target, {double threshold = 0.80}) =>
      TextSimilarityHelperImpl().checkIsMatch(spoken, target, threshold: threshold);

  /// Normalizes text for comparison by lowercasing and removing punctuation.
  String normalizeText(String text);

  /// Calculates the Levenshtein distance between two strings using typed Int32List memory arrays.
  int calculateLevenshteinDistance(String s, String t);

  /// Calculates similarity score between 0.0 and 1.0 based on Levenshtein distance.
  double calculateLevenshteinSimilarity(String s1, String s2);

  /// Calculates word-based match score.
  double calculateWordMatchScore(String spoken, String target);

  /// Returns the indices of target words that are present in the spoken text.
  Set<int> findMatchedIndices(String spoken, String target);

  /// Determines if the spoken text matches the target text sufficiently.
  bool checkIsMatch(String spoken, String target, {double threshold = 0.80});
}

/// Concrete implementation of [TextSimilarityHelper] utilizing highly optimized typing layouts.
class TextSimilarityHelperImpl implements TextSimilarityHelper {
  const TextSimilarityHelperImpl();

  @override
  String normalizeText(String text) {
    return text.toLowerCase().replaceAll(RegExp(r"[^\w\s]"), "").trim();
  }

  @override
  int calculateLevenshteinDistance(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    // Use zero-GC Int32List typing layout rather than dynamic heap lists
    final Int32List v0 = Int32List(t.length + 1);
    for (int i = 0; i <= t.length; i++) {
      v0[i] = i;
    }
    final Int32List v1 = Int32List(t.length + 1);

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < t.length; j++) {
        final int cost = (s[i] == t[j]) ? 0 : 1;
        v1[j + 1] = [v1[j] + 1, v0[j + 1] + 1, v0[j] + cost].reduce((a, b) => a < b ? a : b);
      }
      for (int j = 0; j <= t.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v0[t.length];
  }

  @override
  double calculateLevenshteinSimilarity(String s1, String s2) {
    if (s1.isEmpty && s2.isEmpty) return 1.0;
    final int distance = calculateLevenshteinDistance(s1, s2);
    return 1.0 - (distance / max(s1.length, s2.length));
  }

  @override
  double calculateWordMatchScore(String spoken, String target) {
    final spokenWords = spoken.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toSet();
    final targetWords = target.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    
    if (targetWords.isEmpty) return spokenWords.isEmpty ? 1.0 : 0.0;

    int matches = 0;
    for (final String word in targetWords) {
      if (spokenWords.contains(word)) {
        matches++;
      }
    }
    
    return matches / targetWords.length;
  }

  @override
  Set<int> findMatchedIndices(String spoken, String target) {
    final String s = normalizeText(spoken);
    final String t = normalizeText(target);
    
    final spokenWords = s.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toSet();
    final targetWords = t.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    
    final Set<int> matchedIndices = {};
    for (int i = 0; i < targetWords.length; i++) {
      if (spokenWords.contains(targetWords[i])) {
        matchedIndices.add(i);
      }
    }
    return matchedIndices;
  }

  @override
  bool checkIsMatch(String spoken, String target, {double threshold = 0.80}) {
    final String s = normalizeText(spoken);
    final String t = normalizeText(target);

    if (s == t) return true;
    if (s.isEmpty || t.isEmpty) return false;

    // Direct containment is a strong signal
    if (s.contains(t) || t.contains(s)) {
      final double lengthRatio = min(s.length, t.length) / max(s.length, t.length);
      if (lengthRatio > 0.6) return true;
    }

    final double levScore = calculateLevenshteinSimilarity(s, t);
    final double wordScore = calculateWordMatchScore(s, t);

    // Guard: If spoken text is significantly shorter than target, reject
    final double lengthRatio = min(s.length, t.length) / max(s.length, t.length);
    if (lengthRatio < 0.3) return false;

    // Weighted score bias: Word match is more critical for speech comprehension
    final double combinedScore = (levScore * 0.3) + (wordScore * 0.7);

    return combinedScore >= threshold;
  }
}
