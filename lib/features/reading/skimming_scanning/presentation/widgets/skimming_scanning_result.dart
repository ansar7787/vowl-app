import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/features/reading/domain/entities/reading_quest.dart';

class SkimmingScanningResult extends StatelessWidget {
  final ReadingQuest quest;
  final bool isCorrect;
  final bool isDark;

  const SkimmingScanningResult({
    super.key,
    required this.quest,
    required this.isCorrect,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final displayColor = isCorrect ? Colors.greenAccent : Colors.redAccent;

    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: displayColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: displayColor.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        children: [
          Icon(
            isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded, 
            color: displayColor, 
            size: 36.r,
          ),
          SizedBox(height: 10.h),
          Text(
            isCorrect ? "CORRECT!" : "INCORRECT",
            style: GoogleFonts.outfit(
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
              style: GoogleFonts.outfit(
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
