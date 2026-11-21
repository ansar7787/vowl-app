import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// 2026 Arcade Speed Fuse Bar with dynamic multi-tier gradient & combo streak badge.
class FlashcardSpeedFuseBar extends StatelessWidget {
  final ValueNotifier<double> timerProgress;
  final ValueNotifier<int> comboStreak;
  final bool isDark;

  const FlashcardSpeedFuseBar({
    super.key,
    required this.timerProgress,
    required this.comboStreak,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: timerProgress,
      builder: (context, progress, _) {
        final Color fuseColor;
        final List<Color> gradientColors;

        if (progress <= 0.25) {
          fuseColor = const Color(0xFFEF4444);
          gradientColors = const [Color(0xFFEF4444), Color(0xFFF43F5E)];
        } else if (progress <= 0.5) {
          fuseColor = const Color(0xFFF59E0B);
          gradientColors = const [Color(0xFFF59E0B), Color(0xFFF97316)];
        } else {
          fuseColor = const Color(0xFF10B981);
          gradientColors = const [Color(0xFF10B981), Color(0xFF34D399)];
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.timer_rounded, size: 15.r, color: fuseColor),
                    SizedBox(width: 5.w),
                    Text(
                      'TIME LEFT',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: fuseColor,
                      ),
                    ),
                  ],
                ),
                // Combo Streak Multiplier Pill
                ValueListenableBuilder<int>(
                  valueListenable: comboStreak,
                  builder: (context, streak, _) {
                    if (streak <= 0) return const SizedBox.shrink();
                    return Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.amber.withValues(alpha: 0.3),
                            Colors.orange.withValues(alpha: 0.2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: Colors.amber.shade400,
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.amber.withValues(alpha: 0.2),
                            blurRadius: 6.r,
                          ),
                        ],
                      ),
                      child: Text(
                        '🔥 ${streak}x COMBO',
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w900,
                          color: isDark
                              ? Colors.amberAccent
                              : Colors.amber.shade900,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: 7.h),
            // Custom Multi-Tier Glowing Progress Bar
            Container(
              height: 8.h,
              decoration: BoxDecoration(
                color: isDark ? AppColors.slate800 : AppColors.slate200,
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final barWidth =
                      constraints.maxWidth * progress.clamp(0.0, 1.0);
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: barWidth,
                      height: 8.h,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: gradientColors),
                        borderRadius: BorderRadius.circular(8.r),
                        boxShadow: [
                          BoxShadow(
                            color: fuseColor.withValues(alpha: 0.45),
                            blurRadius: 6.r,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
