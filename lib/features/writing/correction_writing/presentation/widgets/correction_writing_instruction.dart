import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/locale_service.dart';

class CorrectionWritingInstruction extends StatelessWidget {
  final String instruction;
  final Color primaryColor;
  final String? errorsRemainingText;

  const CorrectionWritingInstruction({
    super.key,
    required this.instruction,
    required this.primaryColor,
    this.errorsRemainingText,
  });

  @override
  Widget build(BuildContext context) {
    final baseText = context.tr(
      'games.correctionWriting_instruction',
      fallback: instruction,
    );
    final fullText = errorsRemainingText != null
        ? '$baseText (${errorsRemainingText!.toUpperCase()})'
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
          Icon(Icons.auto_fix_high_rounded, size: 20.r, color: primaryColor),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              fullText,
              textAlign: TextAlign.center,
              maxLines: null,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Icon(
            Icons.auto_fix_high_rounded,
            size: 20.r,
            color: Colors.transparent,
          ),
        ],
      ),
    );
  }
}
