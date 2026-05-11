import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';
import 'grammar_heart_count.dart';

class GrammarTopBar extends StatelessWidget {
  final int level;
  final int currentIndex;
  final int totalQuests;
  final double progress;
  final int livesRemaining;
  final bool isDark;
  final bool isMidnight;
  final Color primaryColor;

  const GrammarTopBar({
    super.key,
    required this.level,
    required this.currentIndex,
    required this.totalQuests,
    required this.progress,
    required this.livesRemaining,
    required this.isDark,
    this.isMidnight = false,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 60.h, 20.w, 10.h),
      child: Row(
        children: [
          ScaleButton(
            onTap: () => context.pop(),
            child: Container(
              padding: EdgeInsets.all(10.r),
              decoration: BoxDecoration(
                color: isMidnight 
                    ? Colors.white.withValues(alpha: 0.15)
                    : (isDark ? Colors.white10 : Colors.black12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                size: 24.r,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Level $level",
                      style: GoogleFonts.outfit(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    Text(
                      "${currentIndex + 1} / $totalQuests",
                      style: GoogleFonts.outfit(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20.r),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 12.h,
                    backgroundColor: isMidnight 
                        ? Colors.white10 
                        : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 12.w),
          GrammarHeartCount(lives: livesRemaining),
        ],
      ),
    );
  }
}
