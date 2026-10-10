import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:vowl/core/presentation/widgets/scale_button.dart';

class OpinionWritingIdeaCard extends StatelessWidget {
  final String text;
  final Color primaryColor;
  final bool isDark;
  final bool isDragging;
  final VoidCallback? onTap;

  const OpinionWritingIdeaCard({
    super.key,
    required this.text,
    required this.primaryColor,
    required this.isDark,
    this.isDragging = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleButton(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
          boxShadow: isDragging
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.2),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 2.h),
              child: Icon(
                Icons.drag_indicator_rounded,
                color: isDark ? Colors.white38 : Colors.black26,
                size: 20.w,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                  height: 1.5,
                ),
              ),
            ),
            if (onTap != null && !isDragging) ...[
              SizedBox(width: 12.w),
              Padding(
                padding: EdgeInsets.only(top: 2.h),
                child: Icon(
                  Icons.add_circle_outline,
                  color: primaryColor.withValues(alpha: 0.6),
                  size: 20.w,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class OpinionWritingDraftedCard extends StatelessWidget {
  final String text;
  final Color primaryColor;
  final bool isDark;
  final bool isAnswered;
  final bool isCorrectOption;
  final VoidCallback onRemove;

  const OpinionWritingDraftedCard({
    super.key,
    required this.text,
    required this.primaryColor,
    required this.isDark,
    required this.isAnswered,
    required this.isCorrectOption,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : primaryColor.withValues(alpha: 0.05);
    Color borderColor = primaryColor.withValues(alpha: 0.3);
    Color textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    IconData iconData = Icons.remove_circle_outline;
    Color iconColor = primaryColor;

    if (isAnswered) {
      if (isCorrectOption) {
        bgColor = Colors.green.withValues(alpha: 0.1);
        borderColor = Colors.green;
        iconData = Icons.check_circle;
        iconColor = Colors.green;
      } else {
        bgColor = Colors.red.withValues(alpha: 0.1);
        borderColor = Colors.red;
        iconData = Icons.cancel;
        iconColor = Colors.red;
      }
    }

    return ScaleButton(
      onTap: onRemove,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: borderColor, width: isAnswered ? 2 : 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                  height: 1.5,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Padding(
              padding: EdgeInsets.only(top: 2.h),
              child: Icon(iconData, color: iconColor, size: 22.w),
            ),
          ],
        ),
      ),
    );
  }
}
