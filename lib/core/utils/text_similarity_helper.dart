import 'dart:math';

class TextSimilarityHelper {
  /// Normalizes text for comparison by lowercasing and removing punctuation.
  static String normalize(String text) {
    return text.toLowerCase().replaceAll(RegExp(r"[^\w\s]"), "").trim();
  }

  /// Calculates the Levenshtein distance between two strings.
  static int levenshteinDistance(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<int> v0 = List<int>.generate(t.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < t.length; j++) {
        int cost = (s[i] == t[j]) ? 0 : 1;
        v1[j + 1] = [v1[j] + 1, v0[j + 1] + 1, v0[j] + cost].reduce((a, b) => a < b ? a : b);
      }
      for (int j = 0; j < t.length + 1; j++) {
        v0[j] = v1[j];
      }
    }
    return v0[t.length];
  }

  /// Calculates similarity score between 0.0 and 1.0 based on Levenshtein distance.
  static double levenshteinSimilarity(String s1, String s2) {
    if (s1.isEmpty && s2.isEmpty) return 1.0;
    int distance = levenshteinDistance(s1, s2);
    return 1.0 - (distance / max(s1.length, s2.length));
  }

  /// Calculates word-based match score.
  /// Returns percentage of target words found in spoken text.
  static double wordMatchScore(String spoken, String target) {
    final spokenWords = spoken.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toSet();
    final targetWords = target.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    
    if (targetWords.isEmpty) return spokenWords.isEmpty ? 1.0 : 0.0;

    int matches = 0;
    for (var word in targetWords) {
      if (spokenWords.contains(word)) {
        matches++;
      }
    }
    
    return matches / targetWords.length;
  }

  /// Returns the indices of target words that are present in the spoken text.
  static Set<int> getMatchedIndices(String spoken, String target) {
    final s = normalize(spoken);
    final t = normalize(target);
    
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

  /// Determines if the spoken text matches the target text sufficiently.
  /// Uses a combination of Levenshtein similarity and Word Match score.
  static bool isMatch(String spoken, String target, {double threshold = 0.80}) {
    final s = normalize(spoken);
    final t = normalize(target);

    if (s == t) return true;
    if (s.isEmpty || t.isEmpty) return false;

    // Direct containment is usually a strong signal
    if (s.contains(t) || t.contains(s)) {
      // If it's a short phrase, containment is enough.
      // If it's long, we check if the length difference is reasonable.
      double lengthRatio = min(s.length, t.length) / max(s.length, t.length);
      if (lengthRatio > 0.6) return true;
    }

    final levScore = levenshteinSimilarity(s, t);
    final wordScore = wordMatchScore(s, t);

    // Safety: If the spoken text is significantly shorter than the target, it's not a match.
    // This prevents background noise or a single accidental word from passing a long sentence.
    double lengthRatio = min(s.length, t.length) / max(s.length, t.length);
    if (lengthRatio < 0.3) return false;

    // Weighted score: Word match is often more important for meaning in STT.
    double combinedScore = (levScore * 0.3) + (wordScore * 0.7);

    return combinedScore >= threshold;
  }
}
