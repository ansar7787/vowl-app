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
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_fix_high_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              context.tr(
                'games.describeSituationWriting_instruction',
                fallback: instruction ?? "EXPAND EMOJIS TO INJECT NARRATIVE KEYWORDS",
              ),
              textAlign: TextAlign.center,
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
