import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Objective instruction header for the Situational Response minigame.
class SituationalResponseInstruction extends StatelessWidget {
  /// Primary theme accent color.
  final Color primaryColor;

  /// Custom instruction text or fallback.
  final String? instruction;

  /// Whether dark theme styling should be applied.
  final bool isDark;

  /// Optional revealed hint text.
  final String? hint;

  /// Whether the hint has been unlocked.
  final bool hintUsed;

  /// Creates a [SituationalResponseInstruction] widget.
  const SituationalResponseInstruction({
    super.key,
    required this.primaryColor,
    required this.isDark,
    this.instruction,
    this.hint,
    this.hintUsed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
          ),
          child: Text(
            "SITUATIONAL RESPONSE",
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: primaryColor,
              letterSpacing: 1.2,
            ),
          ),
        ),
        SizedBox(height: 10.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            instruction ?? "Choose the most natural reaction for this scenario",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 15.sp,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.85)
                  : Colors.black87,
              height: 1.35,
            ),
          ),
        ),
        if (hintUsed && hint != null && hint!.isNotEmpty) ...[
          SizedBox(height: 10.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  color: Colors.amber,
                  size: 16.r,
                ),
                SizedBox(width: 6.w),
                Flexible(
                  child: Text(
                    hint!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.amber.shade200
                          : Colors.amber.shade900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
