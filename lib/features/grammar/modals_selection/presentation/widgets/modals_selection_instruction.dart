import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ModalsSelectionInstruction extends StatelessWidget {
  final Color primaryColor;
  final String? instruction;
  final double? horizontalMargin;

  const ModalsSelectionInstruction({
    super.key,
    required this.primaryColor,
    this.instruction,
    this.horizontalMargin,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        key: const ValueKey('modals_selection_instruction'),
        margin: EdgeInsets.symmetric(horizontal: horizontalMargin ?? 24.w),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.av_timer_rounded, size: 14.r, color: primaryColor),
            SizedBox(width: 8.w),
            Flexible(
              child: Text(
                instruction ?? "CALIBRATE THE MODAL DIAL",
                textAlign: TextAlign.center,
                maxLines: 2,
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
      ),
    );
  }
}
