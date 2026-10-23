import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Instruction header pill and badge for speak opposite challenges.
class SpeakOppositeHeader extends StatelessWidget {
  /// Primary theme accent color.
  final Color primaryColor;

  /// Specific pedagogical instruction text.
  final String? instruction;

  /// Creates a [SpeakOppositeHeader].
  const SpeakOppositeHeader({
    super.key,
    required this.primaryColor,
    this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayInstruction =
        (instruction != null && instruction!.trim().isNotEmpty)
            ? instruction!.trim()
            : 'Speak the opposite of the given word.';

    return Semantics(
      header: true,
      child: Column(
        key: const Key('speak_opposite_header'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            key: const Key('speak_opposite_badge'),
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30.r),
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.25),
                width: 1.w,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.swap_horiz_rounded,
                  size: 15.r,
                  color: primaryColor,
                ),
                SizedBox(width: 6.w),
                Text(
                  "OPPOSITE CHALLENGE",
                  key: const Key('speak_opposite_badge_text'),
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w700,
                    color: primaryColor,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Text(
              displayInstruction,
              key: const Key('speak_opposite_instruction_text'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
                height: 1.45,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.88)
                    : const Color(0xFF334155),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
