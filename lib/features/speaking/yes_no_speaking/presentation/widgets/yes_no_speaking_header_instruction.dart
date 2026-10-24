import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Header instruction pill indicating slider and speaking status for yes/no exercises.
class YesNoSpeakingHeaderInstruction extends StatelessWidget {
  /// Primary theme accent color.
  final Color primaryColor;

  /// Whether the physics slider has snapped into Yes or No.
  final bool isSnapped;

  /// Optional specific instruction text override.
  final String? instruction;

  /// Creates a [YesNoSpeakingHeaderInstruction].
  const YesNoSpeakingHeaderInstruction({
    super.key,
    required this.primaryColor,
    required this.isSnapped,
    this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      header: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            key: const Key('yes_no_speaking_instruction_badge'),
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30.r),
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.25),
                width: 1.2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isSnapped ? Icons.mic_rounded : Icons.swap_horiz_rounded,
                  size: 14.r,
                  color: primaryColor,
                ),
                SizedBox(width: 6.w),
                Flexible(
                  child: Text(
                    isSnapped ? "SPEAK THE SENTENCE" : "SLIDE TO YES OR NO",
                    key: const Key('yes_no_speaking_badge_text'),
                    softWrap: true,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                      color: primaryColor,
                      letterSpacing: 0.6,
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
              isSnapped
                  ? "Great! Tap the microphone below and read the sentence aloud."
                  : (instruction != null && instruction!.trim().isNotEmpty
                      ? instruction!
                      : "Listen to the audio. Does it match the sentence below? Choose Yes or No."),
              key: const Key('yes_no_speaking_instruction_text'),
              textAlign: TextAlign.center,
              softWrap: true,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
                height: 1.45,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.85)
                    : AppColors.slate700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
