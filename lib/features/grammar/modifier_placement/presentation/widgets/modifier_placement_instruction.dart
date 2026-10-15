import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ModifierPlacementInstruction extends StatelessWidget {
  final String instructionText;
  final Color primaryColor;
  final double? horizontalMargin;

  const ModifierPlacementInstruction({
    super.key,
    required this.primaryColor,
    required this.instructionText,
    this.horizontalMargin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('modifier_placement_instruction'),
      margin: EdgeInsets.symmetric(horizontal: horizontalMargin ?? 0),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.adjust_rounded, size: 14.r, color: primaryColor),
          SizedBox(width: 12.w),
          Flexible(
            child: Text(
              instructionText.toUpperCase(),
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
    );
  }
}
