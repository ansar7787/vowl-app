import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/utils/locale_service.dart';

class DescribeSituationInstruction extends StatelessWidget {
  final Color primaryColor;
  final String? instruction;

  const DescribeSituationInstruction({
    super.key,
    required this.primaryColor,
    this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.auto_fix_high_rounded, size: 18.r, color: primaryColor),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              context.tr(
                'games.describeSituationWriting_instruction',
                fallback:
                    instruction ?? "Expand emojis to inject narrative keywords",
              ),
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
          Icon(
            Icons.auto_fix_high_rounded,
            size: 18.r,
            color: Colors.transparent,
          ),
        ],
      ),
    );
  }
}
