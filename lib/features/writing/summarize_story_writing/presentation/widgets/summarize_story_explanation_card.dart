import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/writing/domain/entities/writing_quest.dart';
import 'package:vowl/core/utils/locale_service.dart';

class SummarizeStoryExplanationCard extends StatelessWidget {
  final WritingQuest quest;
  final bool isCorrect;
  final Color primaryColor;
  final bool isDark;

  const SummarizeStoryExplanationCard({
    super.key,
    required this.quest,
    required this.isCorrect,
    required this.primaryColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final displayColor = isCorrect
        ? (isDark ? Colors.greenAccent : const Color(0xFF16A34A))
        : (isDark ? Colors.redAccent : const Color(0xFFDC2626));

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: displayColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: displayColor.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          Icon(isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded, color: displayColor, size: 36.r),
          SizedBox(height: 10.h),
          Text(
            isCorrect ? context.tr('games.correct').toUpperCase() : context.tr('games.incorrect_caps'),
            style: TextStyle(fontFamily: 'Outfit', 
              fontSize: 15.sp,
              fontWeight: FontWeight.w900,
              color: displayColor,
              letterSpacing: 2,
            ),
          ),
          if (quest.explanation != null) ...[
            SizedBox(height: 10.h),
            Text(
              quest.explanation!,
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Outfit', 
                fontSize: 12.sp,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ],
      ),
    ).animate().shimmer(duration: 2.seconds);
  }
}
