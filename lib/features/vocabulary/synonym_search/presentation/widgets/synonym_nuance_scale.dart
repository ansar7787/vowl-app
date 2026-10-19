import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:vowl/core/theme/app_colors.dart';
import 'package:vowl/core/theme/vowl_motion.dart';

class SynonymNuanceScale extends StatelessWidget {
  final String targetWord;
  final String synonymWord;
  final String explanation;
  final Color primaryColor;

  const SynonymNuanceScale({
    super.key,
    required this.targetWord,
    required this.synonymWord,
    required this.explanation,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = VowlMotion.shouldReduceMotion(context);
    final content = Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: EdgeInsets.all(18.r),
            decoration: BoxDecoration(
              color: isDark
                  ? primaryColor.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: isDark
                    ? primaryColor.withValues(alpha: 0.25)
                    : Colors.white.withValues(alpha: 0.9),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.2)
                      : primaryColor.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Badge
                Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 5.h,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.balance_rounded,
                          color: primaryColor,
                          size: 15.r,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'NUANCE DIFFERENCE',
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 10.5.sp,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 18.h),

                // The Spectrum Scale
                Row(
                  children: [
                    // Target Word
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              targetWord.toUpperCase(),
                              maxLines: 1,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.85)
                                    : AppColors.slate700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Container(
                            height: 3.h,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white24
                                  : Colors.black12,
                              borderRadius: BorderRadius.circular(2.r),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Connection / Slider node
                    Expanded(
                      flex: 2,
                      child: Padding(
                        padding: EdgeInsets.only(top: 20.h),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 2.h,
                                color: primaryColor.withValues(alpha: 0.3),
                              ),
                            ),
                            Builder(
                              builder: (context) {
                                Widget sliderDot = Container(
                                  width: 10.r,
                                  height: 10.r,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: primaryColor,
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryColor.withValues(
                                          alpha: 0.4,
                                        ),
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                );
                                if (!reduceMotion) {
                                  sliderDot = sliderDot
                                      .animate(
                                        onPlay: (c) =>
                                            c.repeat(reverse: true),
                                      )
                                      .scale(
                                        begin: const Offset(1, 1),
                                        end: const Offset(1.2, 1.2),
                                        duration: 1.seconds,
                                      );
                                }
                                return sliderDot;
                              },
                            ),
                            Expanded(
                              child: Container(
                                height: 2.h,
                                color: primaryColor.withValues(alpha: 0.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Synonym Word
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              synonymWord.toUpperCase(),
                              maxLines: 1,
                              style: TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w700,
                                color: primaryColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Container(
                            height: 3.h,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  primaryColor.withValues(alpha: 0.3),
                                  primaryColor,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(2.r),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 18.h),

                // The Nuance Description
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.25)
                        : Colors.white.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: isDark ? Colors.white12 : AppColors.slate200,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.tips_and_updates_rounded,
                        color: primaryColor,
                        size: 20.r,
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          explanation,
                          softWrap: true,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13.5.sp,
                            height: 1.45,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.9)
                                : AppColors.slate800,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (reduceMotion) {
      return content;
    }

    return content
        .animate()
        .fadeIn(duration: 500.ms, curve: Curves.easeOut)
        .slideY(begin: 0.15, end: 0, curve: Curves.easeOut, duration: 500.ms);
  }
}
