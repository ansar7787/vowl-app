import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:auto_size_text/auto_size_text.dart';

class ContextualUsageRegisterMeter extends StatelessWidget {
  final int registerLevel; // 1 to 10
  final Color color;

  const ContextualUsageRegisterMeter({
    super.key,
    required this.registerLevel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String levelText;
    if (registerLevel <= 3) {
      levelText = "CASUAL";
    } else if (registerLevel <= 7) {
      levelText = "NEUTRAL";
    } else {
      levelText = "FORMAL";
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.thermostat_rounded, color: color, size: 20.r),
                  SizedBox(width: 8.w),
                  AutoSizeText(
                    "FORMALITY METER",
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                      color: color,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Text(
                  levelText,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            children: List.generate(10, (index) {
              final isActive = index < registerLevel;
              return Expanded(
                child: Container(
                  height: 8.h,
                  margin: EdgeInsets.symmetric(horizontal: 2.w),
                  decoration: BoxDecoration(
                    color: isActive ? color : color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4.r),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: color.withValues(alpha: 0.4),
                              blurRadius: 4,
                              spreadRadius: 1,
                            )
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
                "Informal",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 10.sp,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
              Text(
                "Highly Formal",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 10.sp,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2, end: 0, curve: Curves.easeOut);
  }
}
