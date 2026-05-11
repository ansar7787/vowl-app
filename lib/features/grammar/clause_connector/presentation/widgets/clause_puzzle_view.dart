import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'clause_card.dart';
import 'connector_slot.dart';

class ClausePuzzleView extends StatelessWidget {
  final String firstClause;
  final String secondClause;
  final String? selectedConnector;
  final bool? isCorrect;
  final bool isDark;
  final bool isMidnight;
  final Color primaryColor;

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
