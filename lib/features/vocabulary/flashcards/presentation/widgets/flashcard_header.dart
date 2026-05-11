import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vowl/core/presentation/themes/level_theme_helper.dart';
import 'package:flutter_animate/flutter_animate.dart';

class FlashcardHeader extends StatelessWidget {
  final int level;
  final double progress;
  final int lives;
  final int streak;
  final ThemeResult theme;
  final bool isDark;
  final VoidCallback onBack;

  const FlashcardHeader({
    super.key,
    required this.level,
    required this.progress,
    required this.lives,
    required this.streak,
    required this.theme,
    required this.isDark,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Row(
        children: [
          // Back Button
          IconButton(
            onPressed: onBack,
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              size: 20.r,
            ),
          ),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'LEVEL $level',
                        style: GoogleFonts.outfit(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          letterSpacing: 1.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "${(progress * 100).toInt()}%",
                          style: GoogleFonts.outfit(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white.withValues(alpha: 0.8) : const Color(0xFF0F172A).withValues(alpha: 0.7),
                          ),
                        ),
                        if (streak > 0) ...[
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              "🔥 $streak",
                              style: GoogleFonts.outfit(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w900,
                                color: Colors.orange,
                              ),
                            ),
                          ).animate().scale().shake(),
                        ],
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        Container(
                          height: 6.h,
                          width: constraints.maxWidth,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(3.r),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          width: constraints.maxWidth * progress.clamp(0.0, 1.0),
                          height: 6.h,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white : theme.primaryColor,
                            borderRadius: BorderRadius.circular(3.r),
                            boxShadow: [
                              BoxShadow(
                                color: (isDark ? Colors.white : theme.primaryColor).withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          
          SizedBox(width: 15.w),
          
          // Lifelines
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 16.r),
                SizedBox(width: 4.w),
                Text(
                  '$lives',
                  style: GoogleFonts.outfit(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
