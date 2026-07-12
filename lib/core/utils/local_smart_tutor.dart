import 'package:vowl/features/auth/domain/entities/user_entity.dart';

/// Abstract contract defining the Smart Tutor intelligence system.
///
/// Decouples the tutor recommendation algorithm from presentation layers,
/// in accordance with Clean Architecture principles.
abstract class SmartTutor {
  /// Analyzes the user's category stats and suggests the next quest category.
  String suggestNextQuestCategory(UserEntity user);

  /// Computes updated mastery scores for a category based on correct/incorrect results.
  Map<String, int> calculateNewStats(
    Map<String, int> currentStats,
    String categoryId,
    bool isCorrect,
  );
}

/// Concrete implementation of [SmartTutor] using lightweight, localized rules.
class LocalSmartTutor implements SmartTutor {
  // Mastery Score Constraints
  static const int defaultNeutralScore = 50;
  static const int maxMasteryScore = 100;
  static const int minMasteryScore = 0;
  static const int scoreStepAdjustment = 10;
  static const int proficiencyThreshold = 80;

  // Predefined Fallbacks and Rotation Collections
  static const String fallbackCategory = 'reading';
  static const List<String> rotatedCategories = [
    'grammar',
    'reading',
    'writing',
    'speaking',
  ];

  const LocalSmartTutor();

  @override
  String suggestNextQuestCategory(UserEntity user) {
    final stats = user.categoryStats;
    if (stats.isEmpty) {
      return fallbackCategory;
    }

    int lowestScore = maxMasteryScore + 1;
    final List<String> weakestCandidates = [];

    // O(N) optimized entry iteration
    for (final entry in stats.entries) {
      final category = entry.key;
      final score = entry.value;

      if (score < lowestScore) {
        lowestScore = score;
        weakestCandidates
          ..clear()
          ..add(category);
      } else if (score == lowestScore) {
        weakestCandidates.add(category);
      }
    }

    // Spec Requirement 4: Proficient in everything (>80%), rotate to vary quests.
    if (lowestScore > proficiencyThreshold) {
      return _getRotatedCategory(user.level);
    }

    // Spec Requirement 3: If multiple have same lowest score, pick via level-based round-robin rotation.
    if (weakestCandidates.length > 1) {
      final index = user.level % weakestCandidates.length;
      return weakestCandidates[index];
    }

    return weakestCandidates.first;
  }

  String _getRotatedCategory(int level) {
    // Avoid range exceptions with index clamping
    final index = level % rotatedCategories.length;
    return rotatedCategories[index];
  }

  @override
  Map<String, int> calculateNewStats(
    Map<String, int> currentStats,
    String categoryId,
    bool isCorrect,
  ) {
    final Map<String, int> newStats = Map<String, int>.from(currentStats);
    final int currentScore = newStats[categoryId] ?? defaultNeutralScore;

    // Moving mastery scoring adjustment
    final adjustment = isCorrect ? scoreStepAdjustment : -scoreStepAdjustment;
    final newScore = (currentScore + adjustment).clamp(
      minMasteryScore,
      maxMasteryScore,
    );

    newStats[categoryId] = newScore;
    return newStats;
  }
}
