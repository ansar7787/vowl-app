import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Card providing a detailed pedagogical explanation of the listening inference.
class ListeningInferenceExplanation extends StatelessWidget {
  /// Explanation text describing the logic behind the correct deduction.
  final String explanation;

  /// Theme accent color.
  final Color color;

  /// Creates a [ListeningInferenceExplanation] card.
  const ListeningInferenceExplanation({
    super.key,
    required this.explanation,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (explanation.trim().isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 8.h, bottom: 16.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.14 : 0.07),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.32 : 0.2),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_rounded,
                color: color,
                size: 18.r,
              ),
              SizedBox(width: 8.w),
              Text(
                "Explanation",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            explanation,
            softWrap: true,
            overflow: TextOverflow.visible,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14.sp,
              fontWeight: FontWeight.w400,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.92)
                  : const Color(0xFF1E293B),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
