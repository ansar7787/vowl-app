import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/accent/domain/entities/accent_quest.dart';

class ConnectedSpeechExplanationCard extends StatelessWidget {
  final AccentQuest quest;
  final Color color;
  final bool isDark;
  final bool? isCorrect;
  final bool isCompact;

  const ConnectedSpeechExplanationCard({
    super.key,
    required this.quest,
    required this.color,
    required this.isDark,
    required this.isCorrect,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool correct = isCorrect == true;
    final displayColor = correct ? Colors.greenAccent : Colors.redAccent;

    return Container(
      padding: EdgeInsets.all(isCompact ? 12.r : 20.r),
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
            size: isCompact ? 24.r : 36.r,
          ),
          SizedBox(height: isCompact ? 6.h : 10.h),
          Text(
            correct ? "CORRECT SPEECH FLOW!" : "INCORRECT SPEECH FLOW",
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: isCompact ? 12.sp : 15.sp,
              fontWeight: FontWeight.w900,
              color: displayColor,
              letterSpacing: 2,
            ),
          ),
          if (quest.explanation != null) ...[
            SizedBox(height: isCompact ? 6.h : 10.h),
            Text(
              quest.explanation!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: isCompact ? 10.sp : 12.sp,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ],
        ],
      ),
    ).animate().shimmer(duration: 2.seconds);
  }
}
