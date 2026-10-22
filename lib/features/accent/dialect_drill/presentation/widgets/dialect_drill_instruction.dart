import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DialectDrillInstruction extends StatelessWidget {
  final String instruction;
  final Color accentColor;

  const DialectDrillInstruction({
    super.key,
    required this.instruction,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: isDark ? 0.12 : 0.08),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: accentColor.withValues(alpha: isDark ? 0.25 : 0.18),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.record_voice_over_rounded,
                size: 13.r,
                color: accentColor,
              ),
              SizedBox(width: 6.w),
              Text(
                "REGIONAL DIALECT DRILL",
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w700,
                  color: accentColor,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Text(
            instruction,
            textAlign: TextAlign.center,
            softWrap: true,
            maxLines: null,
            style: TextStyle(
              fontFamily: 'Outfit',
              fontSize: 17.sp,
              fontWeight: FontWeight.w600,
              height: 1.35,
              color: Theme.of(context).colorScheme.onSurface,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ],
    );
  }
}
