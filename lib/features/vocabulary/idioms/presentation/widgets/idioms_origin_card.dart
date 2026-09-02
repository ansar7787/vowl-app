import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:auto_size_text/auto_size_text.dart';

class IdiomsOriginCard extends StatelessWidget {
  final String? origin;
  final String? literalVsFigurative;
  final String? contextSentence;
  final Color color;

  const IdiomsOriginCard({
    super.key,
    this.origin,
    this.literalVsFigurative,
    this.contextSentence,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (origin != null && origin!.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.history_edu_rounded, color: color, size: 20.r),
                    SizedBox(width: 8.w),
                    AutoSizeText(
                      "IDIOM ORIGIN",
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
                SizedBox(height: 12.h),
                Text(
                  origin!,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.black87,
                    height: 1.4,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],

              if (literalVsFigurative != null) ...[
                SizedBox(height: 16.h),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: color.withValues(alpha: 0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "LITERAL VS FIGURATIVE",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w800,
                          color: color,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        literalVsFigurative!,
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white70 : Colors.black87,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (contextSentence != null) ...[
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Icon(Icons.format_quote_rounded, color: color, size: 20.r),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        "\"$contextSentence\"",
                        style: TextStyle(
                          fontFamily: 'Outfit',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.2, end: 0, curve: Curves.easeOut);
  }
}
