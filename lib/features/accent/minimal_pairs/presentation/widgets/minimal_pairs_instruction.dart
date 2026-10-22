import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class MinimalPairsInstruction extends StatelessWidget {
  final Color color;
  final String? instruction;

  const MinimalPairsInstruction({
    super.key,
    required this.color,
    this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final String text = (instruction?.trim().isNotEmpty == true)
        ? instruction!.toUpperCase()
        : "LISTEN AND CHOOSE WHAT YOU HEAR";

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: color.withValues(alpha: isDark ? 0.25 : 0.18),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.hearing_rounded, size: 16.r, color: color),
          SizedBox(width: 8.w),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              softWrap: true,
              maxLines: null,
              style: TextStyle(
                fontFamily: 'Outfit',
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.8,
                height: 1.25,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          // Symmetrical invisible icon to guarantee true visual centering even when text wraps onto 2 lines
          Icon(Icons.hearing_rounded, size: 16.r, color: Colors.transparent),
        ],
      ),
    );
  }
}
