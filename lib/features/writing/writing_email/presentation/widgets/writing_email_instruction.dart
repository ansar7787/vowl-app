import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:vowl/core/utils/locale_service.dart';

class WritingEmailInstruction extends StatelessWidget {
  final Color primaryColor;
  final String? instruction;

  const WritingEmailInstruction({
    super.key, 
    required this.primaryColor,
    this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.terminal_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Flexible(
            child: Text(
              context.tr(
                'games.writingEmail_instruction',
                fallback: instruction ?? "Arrange the email into the correct order.",
              ).toUpperCase(),
              textAlign: TextAlign.center,
              maxLines: null,
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
