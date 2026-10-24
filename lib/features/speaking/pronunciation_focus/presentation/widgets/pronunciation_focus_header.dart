import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Header banner presenting pronunciation focus title and instructions.
class PronunciationFocusHeader extends StatelessWidget {
  /// Primary theme accent color.
  final Color primaryColor;

  /// Specific pedagogical instruction text.
  final String instruction;

  /// Creates a [PronunciationFocusHeader].
  const PronunciationFocusHeader({
    super.key,
    required this.primaryColor,
    required this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final instructionColor = isDark
        ? Colors.white.withValues(alpha: 0.88)
        : const Color(0xFF334155);

    return Semantics(
      header: true,
      label: "Pronunciation Focus: $instruction",
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(24.r),
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.25),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.graphic_eq_rounded,
                  size: 15.r,
                  color: primaryColor,
                ),
                SizedBox(width: 8.w),
                Flexible(
                  child: Text(
                    "PRONUNCIATION FOCUS",
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Text(
              instruction,
              textAlign: TextAlign.center,
              softWrap: true,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
                color: instructionColor,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
