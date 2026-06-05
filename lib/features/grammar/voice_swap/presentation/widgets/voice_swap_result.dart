import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/domain/entities/game_quest.dart';

class VoiceSwapResult extends StatelessWidget {
  final bool isCorrect;
  final GameQuest quest;
  final bool isDark;

  const VoiceSwapResult({
    super.key,
    required this.isCorrect,
    required this.quest,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final displayColor = isCorrect ? Colors.greenAccent : Colors.redAccent;
    final String correctVoice =
        quest.correctAnswerCategory ?? quest.correctAnswer ?? "Unknown";

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Container(
        padding: EdgeInsets.all(24.r),
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
              isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: displayColor,
              size: 40.r,
            ),
            SizedBox(height: 12.h),
            Text(
              isCorrect ? "CORRECT!" : "INCORRECT",
              style: TextStyle(fontFamily: 'Outfit', 
                fontSize: 16.sp,
                fontWeight: FontWeight.w900,
                color: displayColor,
                letterSpacing: 2,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              "This sentence is in the ${correctVoice.toUpperCase()} voice.",
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Outfit', 
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: displayColor,
              ),
            ),
            if (quest.explanation != null) ...[
              SizedBox(height: 12.h),
              Text(
                quest.explanation!,
                textAlign: TextAlign.center,
                style: TextStyle(fontFamily: 'Outfit', 
                  fontSize: 13.sp,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().shimmer(duration: 2.seconds);
  }
}
