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

  String get _displayInstruction {
    final raw = instruction?.trim();
    if (raw == null || raw.isEmpty) {
      return 'Choose the correct modal verb';
    }
    final upper = raw.toUpperCase();
    if (upper == 'CALIBRATE THE MODAL DIAL' ||
        upper == 'CALIBRATE MODAL DIAL' ||
        upper == 'CHOOSE THE MODAL' ||
        upper == 'SELECT THE MODAL') {
      return 'Choose the correct modal verb';
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final text = _displayInstruction;

    return Center(
      child: Container(
        key: const ValueKey('modals_selection_instruction'),
        margin: EdgeInsets.symmetric(horizontal: horizontalMargin ?? 24.w),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: primaryColor.withValues(alpha: 0.22),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.tune_rounded,
              size: 15.sp,
              color: primaryColor,
            ),
            SizedBox(width: 8.w),
            Flexible(
              child: Text(
                text,
                textAlign: TextAlign.center,
                softWrap: true,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                  letterSpacing: 0.2,
                  height: 1.35,
                ),
              ),
            ),
            // Symmetric spacer to keep multi-line or single-line text visually centered
            SizedBox(width: 8.w + 15.sp),
          ],
        ),
      ),
    );
  }
}
