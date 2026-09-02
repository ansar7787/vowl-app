import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:auto_size_text/auto_size_text.dart';

class CollocationsWrongPairs extends StatelessWidget {
  final List<String> wrongCollocations;
  final Color color;

  const CollocationsWrongPairs({
    super.key,
    required this.wrongCollocations,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final warningColor = Colors.redAccent.shade200;

    return Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: warningColor.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: warningColor,
                    size: 20.r,
                  ),
                  SizedBox(width: 8.w),
                  AutoSizeText(
                    "COMMON MISTAKES",
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w800,
                      color: warningColor,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: wrongCollocations.map((word) {
                  return Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: warningColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(
                        color: warningColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.close_rounded,
                          color: warningColor,
                          size: 12.r,
                        ),
                        SizedBox(width: 4.w),
                        Text(
                          word,
                          style: TextStyle(
                            decoration: TextDecoration.lineThrough,
                            decorationColor: warningColor.withValues(
                              alpha: 0.5,
                            ),
                            fontFamily: 'Outfit',
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.2, end: 0, curve: Curves.easeOut);
  }
}
