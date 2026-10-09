import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/locale_service.dart';

class FixTheSentenceInstruction extends StatelessWidget {
  final bool isWiped;
  final Color primaryColor;
  final String instruction;
  final String? errorType;

  const FixTheSentenceInstruction({
    super.key,
    required this.isWiped,
    required this.primaryColor,
    required this.instruction,
    this.errorType,
  });

  @override
  Widget build(BuildContext context) {
    final baseText = isWiped
        ? "Select the correct replacement word"
        : context.tr('games.fixTheSentence_instruction', fallback: instruction);

    final fullText = errorType != null
        ? '$baseText (${errorType!.toUpperCase()})'
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
          Icon(Icons.auto_fix_normal_rounded, size: 20.r, color: primaryColor),
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
            Icons.auto_fix_normal_rounded,
            size: 20.r,
            color: Colors.transparent,
          ),
        ],
      ),
    );
  }
}
