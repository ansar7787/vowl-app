import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'clause_card.dart';
import 'connector_slot.dart';

/// Puzzle layout stacking the first clause, connection drop target slot, and second clause.
class ClausePuzzleView extends StatelessWidget {
  /// First clause string.
  final String firstClause;

  /// Second clause string.
  final String secondClause;

  /// Selected connector text, or `null`.
  final String? selectedConnector;

  /// Evaluation outcome of the answer (`null` if pending).
  final bool? isCorrect;

  /// Whether dark theme styling should be rendered.
  final bool isDark;

  /// Whether midnight contrast mode is active.
  final bool isMidnight;

  /// Theme accent color.
  final Color primaryColor;

  /// Creates a [ClausePuzzleView] widget.
  const ClausePuzzleView({
    super.key,
    required this.firstClause,
    required this.secondClause,
    this.selectedConnector,
    this.isCorrect,
    required this.isDark,
    this.isMidnight = false,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (firstClause.isNotEmpty) ...[
          ClauseCard(
            text: firstClause,
            isDark: isDark,
            isMidnight: isMidnight,
            primaryColor: primaryColor,
          ).animate().fadeIn().slideY(begin: 0.1),
          SizedBox(height: 16.h),
        ],
        ConnectorSlot(
          connector: selectedConnector,
          isCorrect: isCorrect == true,
          isWrong: isCorrect == false,
          primaryColor: primaryColor,
        ).animate().scale(delay: 200.ms),
        if (secondClause.isNotEmpty) ...[
          SizedBox(height: 16.h),
          ClauseCard(
            text: secondClause,
            isDark: isDark,
            isMidnight: isMidnight,
            primaryColor: primaryColor,
          ).animate().fadeIn(delay: 400.ms).slideY(begin: -0.1),
        ],
      ],
    );
  }
}
