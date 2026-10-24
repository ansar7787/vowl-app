import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Context prompt badge displaying the current target detail to locate or answer.
class DetailSpotlightPrompt extends StatelessWidget {
  /// Whether the question has already been answered.
  final bool isAnswered;

  /// Target detail label or answer string.
  final String detail;

  /// Theme accent color.
  final Color color;

  /// Creates a [DetailSpotlightPrompt] badge.
  const DetailSpotlightPrompt({
    super.key,
    required this.isAnswered,
    required this.detail,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: 320.w),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          isAnswered ? "Answer: $detail" : "Drag the spotlight to find the answer",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Outfit',
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: color,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
