import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Formality register meter and nuance explanation card for contextual usage quests.
class ContextualUsageRegisterMeter extends StatelessWidget {
  /// Formality rating index ranging from 1 (Casual) to 10 (Formal).
  final int? registerLevel; // 1 to 10

  /// Pedagogical explanation clarifying subtle semantic nuances.
  final String? nuanceDifference;

  /// Full sentence demonstrating authentic usage in context.
  final String? usageExample;

  /// Theme accent color for meter bars, icons, and highlights.
  final Color color;

  /// Creates a [ContextualUsageRegisterMeter] widget.
  const ContextualUsageRegisterMeter({
    super.key,
    this.registerLevel,
    this.nuanceDifference,
    this.usageExample,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String levelText = "";
    if (registerLevel != null) {
      if (registerLevel! <= 3) {
        levelText = "Casual";
      } else if (registerLevel! <= 7) {
        levelText = "Neutral";
      } else {
        levelText = "Formal";
      }
    }

    final container = Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.25 : 0.2),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (registerLevel != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.tune_rounded,
                        color: color,
                        size: 18.r,
                      ),
                      SizedBox(width: 8.w),
                      Flexible(
                        child: Text(
                          "Formality Level",
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Outfit',
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: color,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? 0.18 : 0.1),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    levelText,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            Row(
              children: List.generate(10, (index) {
                final isActive = index < registerLevel!;
                return Expanded(
                  child: Container(
                    height: 6.h,
                    margin: EdgeInsets.symmetric(horizontal: 2.w),
                    decoration: BoxDecoration(
                      color: isActive
                          ? color
                          : color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(3.r),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.3),
                                blurRadius: 3,
                                spreadRadius: 0.5,
                              ),
                            ]
                          : null,
                    ),
                  ),
                );
              }),
            ),
            SizedBox(height: 8.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Casual",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                Text(
                  "Formal",
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
              ],
            ),
          ],

          if (nuanceDifference != null) ...[
            SizedBox(height: 16.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: 14.w,
                vertical: 10.h,
              ),
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.1 : 0.05),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: color.withValues(alpha: isDark ? 0.2 : 0.15),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Context & Nuance",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w600,
                      color: color,
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    nuanceDifference!,
                    softWrap: true,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w400,
                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (usageExample != null) ...[
            SizedBox(height: 16.h),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 2.h),
                  child: Icon(
                    Icons.format_quote_rounded,
                    color: color,
                    size: 18.r,
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    "\"$usageExample\"",
                    softWrap: true,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      height: 1.45,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    if (reduceMotion) return container;
    return container
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0, curve: Curves.easeOut);
  }
}
