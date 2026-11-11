import 'package:flutter/material.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Represents a validated, structured Handwriting puzzle for Daily Challenges.
@immutable
class HandwritingPuzzle {
  final String id;
  final int level;
  final String instruction;
  final String target;
  final String hint;
  final String explanation;
  final String funFact;
  final String difficultyLabel;
  final Color difficultyColor;

  const HandwritingPuzzle({
    required this.id,
    required this.level,
    required this.instruction,
    required this.target,
    required this.hint,
    required this.explanation,
    required this.funFact,
    required this.difficultyLabel,
    required this.difficultyColor,
  });

  bool get hasHint => hint.trim().isNotEmpty;
  bool get hasExplanation => explanation.trim().isNotEmpty;
  bool get hasFunFact => funFact.trim().isNotEmpty;

  /// Creates a [HandwritingPuzzle] from curriculum map JSON.
  factory HandwritingPuzzle.fromMap(Map<String, dynamic> map) {
    final rawId = map['id']?.toString() ?? 'HW_1';
    final level = map['level'] is int
        ? map['level'] as int
        : int.tryParse('${map['level']}') ?? 1;

    final instruction = (map['instruction'] as String? ?? '').trim();
    final question = (map['question'] as String? ?? '').trim();
    final correctAnswer = (map['correctAnswer'] as String? ?? '').trim();
    final directTarget = (map['target'] as String? ?? '').trim();
    final target = question.isNotEmpty
        ? question
        : (correctAnswer.isNotEmpty ? correctAnswer : directTarget);

    final hint = (map['hint'] as String? ?? '').trim();
    final explanation = (map['explanation'] as String? ?? '').trim();
    final funFact = (map['funFact'] as String? ?? '').trim();

    final String difficultyLabel;
    final Color difficultyColor;
    if (level <= 50) {
      difficultyLabel = 'Foundational';
      difficultyColor = AppColors.emerald500;
    } else if (level <= 130) {
      difficultyLabel = 'Intermediate';
      difficultyColor = AppColors.amber500;
    } else {
      difficultyLabel = 'Mastery';
      difficultyColor = AppColors.rose500;
    }

    return HandwritingPuzzle(
      id: rawId,
      level: level,
      instruction: instruction,
      target: target,
      hint: hint,
      explanation: explanation,
      funFact: funFact,
      difficultyLabel: difficultyLabel,
      difficultyColor: difficultyColor,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'level': level,
      'instruction': instruction,
      'question': target,
      'correctAnswer': target,
      'hint': hint,
      'explanation': explanation,
      'funFact': funFact,
    };
  }
}
