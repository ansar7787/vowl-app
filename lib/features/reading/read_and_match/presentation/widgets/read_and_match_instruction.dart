import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ReadAndMatchInstruction extends StatelessWidget {
  final Color primaryColor;
  final String? instruction;

  const ReadAndMatchInstruction({
    super.key,
    required this.primaryColor,
    this.instruction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final raw = (instruction ?? '').trim();
    final displayText = raw.isNotEmpty
        ? raw
        : 'Tap a word, then tap its matching meaning.';

    return Semantics(
      header: true,
      label: displayText,
      excludeSemantics: true,
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: primaryColor.withValues(alpha: isDark ? 0.12 : 0.08),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: primaryColor.withValues(alpha: isDark ? 0.25 : 0.18),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.touch_app_rounded,
                size: 15.r,
                color: primaryColor,
              ),
              SizedBox(width: 8.w),
              Flexible(
                child: Text(
                  displayText,
                  textAlign: TextAlign.center,
                  softWrap: true,
                  style: TextStyle(
                    fontFamily: 'Outfit',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.95)
                        : (primaryColor == Colors.white
                            ? const Color(0xFF1E293B)
                            : primaryColor),
                    height: 1.35,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              // Invisible counter-balance icon to keep the text optically centered
              Opacity(
                opacity: 0,
                child: Icon(
                  Icons.touch_app_rounded,
                  size: 15.r,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
