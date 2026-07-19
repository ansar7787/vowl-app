import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/presentation/widgets/pedagogical_rule_box.dart';
import 'package:vowl/features/accent/domain/entities/accent_quest.dart';

class PitchPatternMatchExplanationCard extends StatelessWidget {
  final AccentQuest quest;
  final Color color;
  final bool isDark;
  final bool? isCorrect;

  const PitchPatternMatchExplanationCard({
    super.key,
    required this.quest,
    required this.color,
    required this.isDark,
    required this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    final bool correct = isCorrect == true;
    final displayColor = correct ? Colors.greenAccent : Colors.redAccent;

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: displayColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: displayColor.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(
            correct ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: displayColor,
            size: 36.r,
          ),
          SizedBox(height: 10.h),
          Text(
            correct ? "CORRECT PITCH BLUEPRINT!" : "INCORRECT PITCH BLUEPRINT",
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 15.sp,
              fontWeight: FontWeight.w900,
              color: displayColor,
              letterSpacing: 2,
            ),
          ),
          if (quest.explanation != null) ...[
            SizedBox(height: 12.h),
            PedagogicalRuleBox(
              icon: Icons.lightbulb_outline_rounded,
              capsKey: 'games.explanation_caps',
              capsFallback: 'EXPLANATION',
              titleKey: 'games.explanation',
              titleFallback: 'Explanation',
              rule: quest.explanation!,
              shadowColor: displayColor,
              isDark: isDark,
            ),
          ],
          if (quest.emphasisRule != null) ...[
            SizedBox(height: 12.h),
            PedagogicalRuleBox(
              icon: Icons.center_focus_strong,
              capsKey: 'games.emphasis_rule_caps',
              capsFallback: 'EMPHASIS RULE',
              titleKey: 'games.emphasis_rule',
              titleFallback: 'Emphasis Rule',
              rule: quest.emphasisRule!,
              shadowColor: displayColor,
              isDark: isDark,
            ),
          ],
        ],
      ),
    ).animate().shimmer(duration: 2.seconds);
  }
}
