import 'package:vowl/features/auth/domain/entities/user_entity.dart';

class LocalSmartTutor {
  /// Analyzes the user's category stats and returns the ID of the category
  /// that needs the most improvement.
  ///
  /// Logic:
  /// 1. If no stats exist, returns 'reading' as default.
  /// 2. Finds the category with the lowest accuracy score.
  /// 3. If multiple have the same low score, picks one via round-robin based on level.
  /// 4. If all scores are high (>80%), suggests 'challenge' (or rotates normally).
  String suggestNextQuestCategory(UserEntity user) {
    if (user.categoryStats.isEmpty) {
      return 'reading';
    }

    String weakestCategory = 'reading';
    int lowestScore = 101; // Max is 100

    user.categoryStats.forEach((category, score) {
      if (score < lowestScore) {
        lowestScore = score;
        weakestCategory = category;
      }
    });

    // If the user determines they are proficient in everything (>80%),
    // we can use a rotation based on level to keep it varied.
    if (lowestScore > 80) {
      return _getRotatedCategory(user.level);
    }

    return weakestCategory;
  }

  String _getRotatedCategory(int level) {
    int remainder = level % 4;
    switch (remainder) {
      case 1:
        return 'reading';
      case 2:
        return 'writing';
      case 3:
        return 'speaking';
      default:
        return 'grammar';
    }
  }

  /// Updates the stats map with a new result.
  /// Returns a new map to be saved to the user entity.
  Map<String, int> calculateNewStats(
    Map<String, int> currentStats,
    String categoryId,
    bool isCorrect,
  ) {
    final Map<String, int> newStats = Map.from(currentStats);
    final int currentScore = newStats[categoryId] ?? 50; // Start neutral at 50

    // Simple moving average-ish approach for "Current Mastery"
    // If correct, +5. If wrong, -5. Clamped between 0 and 100.
    int newScore = isCorrect ? currentScore + 10 : currentScore - 10;
    if (newScore > 100) newScore = 100;
    if (newScore < 0) newScore = 0;

    newStats[categoryId] = newScore;
    return newStats;
  }
}
