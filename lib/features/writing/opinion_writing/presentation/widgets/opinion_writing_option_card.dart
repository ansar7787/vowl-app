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
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
            width: 1.0,
          ),
          boxShadow: isDragging
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.drag_indicator_rounded,
              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
              size: 20.r,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                text,
                softWrap: true,
                maxLines: null,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                  height: 1.45,
                ),
              ),
            ),
            if (onTap != null && !isDragging) ...[
              SizedBox(width: 12.w),
              Icon(
                Icons.add_circle_outline_rounded,
                color: primaryColor.withValues(alpha: 0.7),
                size: 20.r,
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
  final VoidCallback? onRemove;

  const OpinionWritingDraftedCard({
    super.key,
    required this.text,
    required this.primaryColor,
    required this.isDark,
    required this.isAnswered,
    required this.isCorrectOption,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor = isDark
        ? primaryColor.withValues(alpha: 0.08)
        : primaryColor.withValues(alpha: 0.06);
    Color borderColor = primaryColor.withValues(alpha: 0.35);
    Color textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    IconData iconData = Icons.remove_circle_outline_rounded;
    Color iconColor = primaryColor;

    if (isAnswered) {
      if (isCorrectOption) {
        bgColor = const Color(0xFF22C55E).withValues(alpha: 0.1);
        borderColor = const Color(0xFF22C55E);
        iconData = Icons.check_circle_rounded;
        iconColor = const Color(0xFF22C55E);
      } else {
        bgColor = const Color(0xFFEF4444).withValues(alpha: 0.1);
        borderColor = const Color(0xFFEF4444);
        iconData = Icons.cancel_rounded;
        iconColor = const Color(0xFFEF4444);
      }
    }

    return ScaleButton(
      onTap: onRemove,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: borderColor,
            width: isAnswered ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                text,
                softWrap: true,
                maxLines: null,
                style: TextStyle(
                  fontFamily: 'Outfit',
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                  height: 1.45,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Icon(
              iconData,
              color: iconColor,
              size: 20.r,
            ),
          ],
        ),
      ),
    );
  }
}
