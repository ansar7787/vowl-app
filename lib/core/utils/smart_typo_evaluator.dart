import 'package:flutter/material.dart';

class SmartTypoEvaluator {
  /// Compares two strings using a Levenshtein edit distance algorithm.
  /// Returns a TextSpan that highlights correct letters in green, and wrong characters in red.
  /// We cannot insert missing characters into the TextSpan because TextEditingController 
  /// requires the TextSpan length to exactly match the text length.
  static TextSpan buildDiffSpan(
    String actual,
    String expected, {
    required TextStyle baseStyle,
    required Color correctColor,
    required Color incorrectColor,
  }) {
    if (actual.isEmpty) {
      return TextSpan(text: actual, style: baseStyle);
    }

    final n = actual.length;
    final m = expected.length;
    final dp = List.generate(n + 1, (i) => List.filled(m + 1, 0));

    for (int i = 0; i <= n; i++) { dp[i][0] = i; }
    for (int j = 0; j <= m; j++) { dp[0][j] = j; }

    for (int i = 1; i <= n; i++) {
      for (int j = 1; j <= m; j++) {
        final cost = (actual[i - 1].toLowerCase() == expected[j - 1].toLowerCase()) ? 0 : 1;
        
        final deleteCost = dp[i - 1][j] + 1;
        final insertCost = dp[i][j - 1] + 1;
        final subCost = dp[i - 1][j - 1] + cost;
        
        dp[i][j] = [deleteCost, insertCost, subCost].reduce((a, b) => a < b ? a : b);
      }
    }

    int i = n;
    int j = m;
    final isCorrect = List.filled(n, false);

    while (i > 0 || j > 0) {
      if (i > 0 && j > 0 && actual[i - 1].toLowerCase() == expected[j - 1].toLowerCase() && dp[i][j] == dp[i - 1][j - 1]) {
        isCorrect[i - 1] = true;
        i--;
        j--;
      } else if (i > 0 && j > 0 && dp[i][j] == dp[i - 1][j - 1] + 1) {
        // Substitution
        isCorrect[i - 1] = false;
        i--;
        j--;
      } else if (j > 0 && dp[i][j] == dp[i][j - 1] + 1) {
        // Missing character in actual (Insertion to expected)
        j--;
      } else if (i > 0 && dp[i][j] == dp[i - 1][j] + 1) {
        // Extra character in actual (Deletion from expected)
        isCorrect[i - 1] = false;
        i--;
      } else {
        // Fallback to avoid infinite loops in edge cases
        if (i > 0) { isCorrect[i - 1] = false; i--; }
        if (j > 0) j--;
      }
    }

    // Edge case: if everything they typed is technically correct but they failed, 
    // it means they missed characters. We underline the last character to hint at missing text.
    final bool onlyMissingChars = !isCorrect.contains(false) && actual.length < expected.length;

    final children = <TextSpan>[];
    for (int k = 0; k < n; k++) {
      children.add(
        TextSpan(
          text: actual[k],
          style: baseStyle.copyWith(
            color: isCorrect[k] ? correctColor : incorrectColor,
            fontWeight: isCorrect[k] ? FontWeight.normal : FontWeight.bold,
            decoration: (onlyMissingChars && k == n - 1) 
                ? TextDecoration.underline 
                : (isCorrect[k] ? TextDecoration.none : TextDecoration.lineThrough),
            decorationColor: incorrectColor,
            decorationStyle: TextDecorationStyle.wavy,
          ),
        ),
      );
    }

    return TextSpan(children: children);
  }
}
