import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SentenceCorrectionInstruction extends StatelessWidget {
  final Color primaryColor;
  final String instruction;

  const SentenceCorrectionInstruction({
    super.key,
    required this.primaryColor,
    this.instruction = "INITIATE LINGUISTIC SCAN",
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('sentence_correction_instruction'),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.biotech_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Flexible(
            child: Text(
              instruction,
              key: const ValueKey('sentence_correction_instruction_text'),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 10.sp,
                fontWeight: FontWeight.w900,
                color: primaryColor,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
