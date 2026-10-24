import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Instruction badge banner at the top of the daily expression game screen.
class DailyExpressionHeader extends StatelessWidget {
  /// Primary theme accent color.
  final Color primaryColor;

  /// Prompt instruction text.
  final String instruction;

  /// Creates a [DailyExpressionHeader].
  const DailyExpressionHeader({
    super.key,
    required this.primaryColor,
    required this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('daily_expression_header'),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 16.r, color: primaryColor),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              instruction,
              textAlign: TextAlign.center,
              softWrap: true,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: primaryColor,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
