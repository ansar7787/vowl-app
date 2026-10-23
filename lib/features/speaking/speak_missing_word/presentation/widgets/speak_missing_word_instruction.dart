import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/theme/app_colors.dart';

/// Header instruction pill and prompt text for missing word speaking exercises.
class SpeakMissingWordInstruction extends StatelessWidget {
  /// Primary theme accent color.
  final Color primaryColor;

  /// Whether the missing word candidate has been chosen and slotted.
  final bool isWordPlaced;

  /// Pedagogical instruction prompt text.
  final String instruction;

  /// Creates a [SpeakMissingWordInstruction].
  const SpeakMissingWordInstruction({
    super.key,
    required this.primaryColor,
    required this.isWordPlaced,
    required this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtitleColor = isDark ? Colors.white70 : AppColors.slate600;

    final resolvedInstruction = instruction.trim().isNotEmpty
        ? instruction
        : "Choose the missing word and read the sentence aloud.";

    return Semantics(
      header: true,
      child: Column(
        key: const Key('speak_missing_word_instruction'),
        children: [
          Container(
            key: const Key('speak_missing_word_instruction_badge'),
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30.r),
              border: Border.all(color: primaryColor.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isWordPlaced
                      ? Icons.record_voice_over_rounded
                      : Icons.spellcheck_rounded,
                  size: 14.r,
                  color: primaryColor,
                ),
                SizedBox(width: 8.w),
                Flexible(
                  child: Text(
                    isWordPlaced ? "READ THE SENTENCE" : "FIND THE WORD",
                    key: const Key('speak_missing_word_instruction_title'),
                    textAlign: TextAlign.center,
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
          Text(
            isWordPlaced
                ? "Read the full sentence aloud."
                : resolvedInstruction,
            key: const Key('speak_missing_word_instruction_subtitle'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: subtitleColor,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
