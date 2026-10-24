import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Instruction pill guiding the learner to tap where connected words link in continuous speech.
class WordLinkingInstruction extends StatelessWidget {
  /// Theme accent color.
  final Color color;

  /// Raw instruction prompt.
  final String instruction;

  /// Creates a [WordLinkingInstruction] widget.
  const WordLinkingInstruction({
    super.key,
    required this.color,
    required this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final text = instruction.trim().isEmpty
        ? "Tap where two words link together"
        : instruction.trim();

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxWidth: 420.w),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.25 : 0.2),
          width: 1.2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.link_rounded, size: 15.r, color: color),
              SizedBox(width: 6.w),
              Text(
                "Word Linking",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: color,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            text,
            textAlign: TextAlign.center,
            softWrap: true,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 15.sp,
              fontWeight: FontWeight.w500,
              height: 1.35,
              color: isDark ? AppColors.slate200 : AppColors.slate800,
            ),
          ),
        ],
      ),
    );
  }
}
