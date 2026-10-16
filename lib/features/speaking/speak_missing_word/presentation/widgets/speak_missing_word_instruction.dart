import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SpeakMissingWordInstruction extends StatelessWidget {
  final Color primaryColor;
  final bool isWordPlaced;
  final String instruction;

  const SpeakMissingWordInstruction({
    super.key,
    required this.primaryColor,
    required this.isWordPlaced,
    required this.instruction,
  });

  @override
  Widget build(BuildContext context) {
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
              border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome_rounded, size: 12.r, color: primaryColor),
                SizedBox(width: 8.w),
                Flexible(
                  child: Text(
                    isWordPlaced ? "READ THE SENTENCE" : "FIND THE WORD",
                    key: const Key('speak_missing_word_instruction_title'),
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w900,
                      color: primaryColor,
                      letterSpacing: 2.0,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            isWordPlaced
                ? "Read the full sentence aloud."
                : "$instruction\n(Tap or hold a word to select)",
            key: const Key('speak_missing_word_instruction_subtitle'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}
