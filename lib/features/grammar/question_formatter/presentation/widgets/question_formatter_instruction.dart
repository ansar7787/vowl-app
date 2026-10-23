import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class QuestionFormatterInstruction extends StatelessWidget {
  final Color primaryColor;
  final String? instruction;
  final bool isCompact;

  const QuestionFormatterInstruction({
    super.key,
    required this.primaryColor,
    this.instruction,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveInstruction =
        (instruction != null && instruction!.trim().isNotEmpty)
        ? instruction!
        : "Turn the statement into a question";

    return Container(
      key: const ValueKey('question_formatter_instruction'),
      padding: EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: isCompact ? 7.h : 9.h,
      ),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.2),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.cached_rounded,
            size: isCompact ? 14.r : 16.r,
            color: primaryColor,
          ),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              effectiveInstruction,
              textAlign: TextAlign.center,
              softWrap: true,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: isCompact ? 12.5.sp : 13.5.sp,
                fontWeight: FontWeight.w600,
                color: primaryColor,
                letterSpacing: 0.2,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
