import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:vowl/core/utils/locale_service.dart';

class WritingEmailInstruction extends StatelessWidget {
  final Color primaryColor;
  final String? instruction;
  final String? formalityLevel;

  const WritingEmailInstruction({
    super.key,
    required this.primaryColor,
    this.instruction,
    this.formalityLevel,
  });

  @override
  Widget build(BuildContext context) {
    final baseText = context.tr(
      'games.writingEmail_instruction',
      fallback: instruction ?? "Arrange the email into the correct order.",
    );
    final fullText = formalityLevel != null
        ? '$baseText (${formalityLevel!.toUpperCase()})'
        : baseText;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.terminal_rounded, size: 20.r, color: primaryColor),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              fullText,
              textAlign: TextAlign.center,
              maxLines: null,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
                color: primaryColor,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Icon(Icons.terminal_rounded, size: 20.r, color: Colors.transparent),
        ],
      ),
    );
  }
}
