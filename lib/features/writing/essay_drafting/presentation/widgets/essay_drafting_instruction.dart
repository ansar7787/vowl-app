import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EssayDraftingInstruction extends StatelessWidget {
  final Color primaryColor;
  final String instruction;

  const EssayDraftingInstruction({
    super.key,
    required this.primaryColor,
    required this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 2.h),
            child: Icon(Icons.architecture_rounded, size: 20.r, color: primaryColor),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              instruction,
              textAlign: TextAlign.center,
              maxLines: null,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w400,
                height: 1.4,
                color: primaryColor,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Icon(
            Icons.architecture_rounded,
            size: 20.r,
            color: Colors.transparent,
          ),
        ],
      ),
    );
  }
}
